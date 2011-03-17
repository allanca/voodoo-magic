#!/usr/bin/env python
# encoding: utf-8
"""
fabfile.py

Copyright (c) 2010 Piick.com, Inc. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""


from __future__ import with_statement

from fabric.api import *
from fabric.decorators import *
from fabric.network import *
from fabric.utils import *
import boto
import functools
import json
import logging
import random
import socket
import subprocess
import sys
import time


CHEF_SERVER_IP = {'staging': '10.114.186.6', 'production': '10.249.118.84'}

AMI = {
    '10.10': {
        32: {'ebs': 'ami-ccf405a5', 'ec2': 'ami-a6f504cf'}, 
        64: {'ebs': 'ami-cef405a7', 'ec2': 'ami-08f40561'}
    },
    '10.04': {
        32: {'ebs': 'ami-a2f405cb', 'ec2': 'ami-88f504e1'}, 
        64: {'ebs': 'ami-b8f405d1', 'ec2': 'ami-f8f40591'}
    }
}

ZONES     = ['us-east-1a', 'us-east-1b', 'us-east-1c', 'us-east-1d']

logging.basicConfig(level=logging.INFO)
require('aws_account_id', 'aws_access_key', 'aws_secret_key', 'key_filename')

ec2 = boto.connect_ec2(env.aws_access_key, env.aws_secret_key)


def _get_hosts_by_regex(regex):
    rsvps = ec2.get_all_instances()
    lst = []
    for rsvp in rsvps:
      for inst in rsvp.instances:
        if inst.state == 'running' and re.search(regex, inst.tags['Name']):
          lst.append(inst.public_dns_name)
    return lst

def _attach_hosts(host_list, func):
    @wraps(func)
    def inner_decorator(*args, **kwargs):
        return func(*args, **kwargs)
    inner_decorator.hosts = list(host_list)
    return inner_decorator

def chef_role(roles):
    if isinstance(roles, basestring):
        roles = [roles]
    hosts = []
    for role in roles:
        role = '[^-]+' if role == '*' else role
        role_regex = '^'+ env.app_environment +'.*?-'+ role + '-'
        hosts += _get_hosts_by_regex(role_regex)
    return functools.partial(_attach_hosts, hosts)


def psh(idx=None):
    rsvps = ec2.get_all_instances()
    lst = []
    instances = [inst for rsvp in rsvps for inst in rsvp.instances]
    for instance in instances:
        if instance.state != 'running': 
            continue
        try:
            print "%d.\t%s%s%s" % (len(lst), instance.tags['Name'], 
                                   ' '* (48 - len(instance.tags['Name'])), 
                                   instance.public_dns_name)
            lst.append(instance)
        except (KeyError, AttributeError):
            continue
    
    while True:
        try:
            idx = int(idx or raw_input(": "))
            subprocess.call(["ssh", "-i", env.psh_key_filename, 
                             "-o", "StrictHostKeyChecking=no",
                             "-o", "PasswordAuthentication=no",
                             "%s@%s" % (env.psh_user, lst[idx].public_dns_name)],
                             stdin=sys.stdin, stdout=sys.stdout)
            break    
        except IndexError:
            idx = None
            print "No such instance. Please try again."
            continue
        except ValueError:
            print "Exiting..."
            break


@chef_role('*')
def fix_hosts(environment):
    sudo('echo "%s chef" >> /etc/hosts' % CHEF_SERVER_IP[environment])


@chef_role('*')
def chef_run():
    with settings(warn_only=True):
        sudo('chef-client -V')


@chef_role('chef')
def chef_update():
    local('git push')
    sudo('su ubuntu -c "cd ~/systems/chef; git pull; rake roles; knife cookbook upload -a"')


@chef_role('*')
def patch():
    sudo('apt-get update -y')
    sudo('export DEBIAN_FRONTEND=noninteractive; apt-get upgrade -y')


@chef_role('cache')
def mc_restart():
    sudo('/etc/init.d/memcached restart')


@chef_role('database')
def db_restart():
    sudo('/etc/init.d/cassandra restart')


def pack(commit="HEAD"):
    with cd(src_path):
        commit_date, commit_hash = _commit_info(commit)
        commit_name = "%s_%s" % (commit_date, commit_hash)
        if os.path.isfile(build_path + '/%s.tgz' % commit_name):
            return commit_name
        commit_path = build_path + '/' + commit_name
        local('mkdir -p %s' % commit_path)
        local('git archive %s pi scripts | tar x -C %s' %
              (commit_hash, commit_path))
        compile(commit_path + '/pi')
       
        local('git clone git://github.com/Piick/tornado.git %s/tornado' %
              commit_path)
       
        local('tar -C %s -czvf %s/%s.tgz .' % (commit_path, build_path,
                                               commit_name))
        local('rm -rf %s' % commit_path)
    return commit_name


@chef_role(('loadbalancer', 'web', 'async'))
def deploy(commit="HEAD", config_data={}):
   
    commit_name = pack(commit)
    put(build_path + '/%s.tgz' % commit_name, '/tmp/')
   
    with settings(warn_only=True):
        sudo('cp /piick/pi/pi/config.py /piick/config.%s.py' % commit_name)
        sudo('cp /piick/pi/pi/celeryconfig.py /piick/celeryconfig.%s.py' % commit_name)

    sudo('rm -rf /piick/pi; mkdir -p /piick/pi')
    sudo('rm -rf /piick/tornado')
    with cd('/piick/pi'):
        sudo('mv /tmp/%s.tgz /piick' % commit_name)
        sudo('tar xvzf /piick/%s.tgz' % commit_name)
        sudo('touch /piick/pi/pi/pi.py')
        sudo('mv /piick/pi/tornado /piick/tornado')
       
    with cd('/piick/tornado'):
        sudo('python setup.py install')
   
    with settings(warn_only=True):
        sudo('cp /piick/config.%s.py /piick/pi/pi/config.py' % commit_name)
        sudo('cp /piick/celeryconfig.%s.py /piick/pi/pi/celeryconfig.py' % commit_name)

    restart()


def compile(dir):
    compile_js(os.path.join(dir, 'static/js'))
    compile_py(dir)


def compile_py(dir):
    for root, dirs, files in os.walk(dir):
        for name in files:
            if name.endswith('.py'):
                # TODO: implement python linting
                pass
            else:
                pass


def compile_js(dir):
    for filename in os.listdir(dir):
        if re.findall('[^a-zA-Z]min[^a-zA-Z]', filename) or \
           not filename.endswith('.js'):
            continue
        fullpath = os.path.join(dir, filename)
        if os.path.isfile(fullpath):
            minify_js(os.path.join(dir, filename), fullpath)
        elif os.path.isdir(fullpath):
            min_filename = filename[:-3] + '.min.js'
            source_js_files = [os.path.join(fullpath, file)
                               for file in os.listdir(fullpath)
                               if file.endswith('.js')]
            minify_js(os.path.join(dir, min_filename), *source_js_files)


def minify_js(target_filename, *source_filenames):
    print target_filename, source_filenames
    js = []
    for js_file in source_filenames:
        with open(js_file) as f:
            js.append(f.read())
    js = '\n'.join(js)

    print "Javascript compilation: %s" % js_file
    params = urllib.urlencode((
        ('compilation_level', 'SIMPLE_OPTIMIZATIONS'),
        ('output_format', 'json'),
        ('output_info', 'compiled_code'),
        ('output_info', 'warnings'),
        ('output_info', 'errors'),
        ('output_info', 'statistics'),
        ('warning_level', 'default'),
        ('js_code', js),
    ))
   
    # Always use the following value for the Content-type header.
    headers = { "Content-type": "application/x-www-form-urlencoded" }
    conn = httplib.HTTPConnection('closure-compiler.appspot.com')
    conn.request('POST', '/compile', params, headers)
    response = conn.getresponse()
    try:
        body = response.read()
        out = json.loads(body)
    except ValueError:
        print "Unable to compile javascript. Closure API failed."
        return
    finally:
        conn.close()

    # Print any JS errors.
    if 'errors' in out:
        for error in out['errors']:
            print "Error: %d:%d %s\n%s\n" % (error['lineno'], error['charno'],
                                             error['error'], error['line'])
        print "Javascript errors in %s. Unable to continue." % js_file
        exit(1)

    if 'warnings' in out:
        for error in out['warnings']:
            print "Warn: %d:%d %s\n%s\n" % (error['lineno'], error['charno'],
                                            error['warning'],
                                            error.get('line', ''))
       
    if 'serverErrors' in out:
        for error in out['serverErrors']:
            print "Javascript compiler error %d: %s" % \
                  (error['code'], error['error'])
        return
   
    with open(target_filename, 'w+') as f:
        f.write(out['compiledCode'])
       
    print "Javascript minification %s: %d to %d" % \
          (js_file, out['statistics']['originalSize'],
           out['statistics']['compressedSize'])


@chef_role('*')
def configure(environment, run_chef=True):
    put('chef/config/client.rb', '/tmp/client.rb')
    put('chef/certificates/%s.pem' % environment, '/tmp/validation.pem')
    sudo('mkdir -p /etc/chef')
    sudo('mv /tmp/client.rb /etc/chef')
    sudo('mv /tmp/validation.pem /etc/chef')
    sudo('echo "%s chef" >> /etc/hosts' % CHEF_SERVER_IP[environment])

    sudo('apt-get install -y curl')
    sudo('echo deb http://apt.opscode.com/ lucid main >'
         '/etc/apt/sources.list.d/opscode.list')
    sudo('curl http://apt.opscode.com/packages@opscode.com.gpg.key |'
         ' apt-key add -')
    sudo('apt-get update')

    sudo('export DEBIAN_FRONTEND=noninteractive;'
         'apt-get install -y rubygems ohai chef libshadow-ruby1.8')

    sudo('pkill chef-client')
    if run_chef:
        sudo('/etc/init.d/chef-client start')


def database(count, key, environment="production", ec2_type=None, zones=ZONES):
    ec2_type = ec2_type or 'm1.large'
    count = int(count)
    chef_data = {'cassandra': {'cluster_name': environment}}
    db = start_instances(1, key, 'database,databasemaster', environment, 
                         ec2_type, chef_data=chef_data)
    if count > 1:
        safe_zones = list(set(zones) - set((db[0].placement,)))
        db += start_instances(count - 1, key, 'database,databaseslave', 
                              environment, ec2_type, chef_data=chef_data, 
                              zones=safe_zones)
    return db


def loadbalancer(key, environment="production", ec2_type=None):
    ec2_type = ec2_type or 'm1.small'
    def associate_elastic_ip(instance):
        address = ec2.allocate_address()
        address.associate(instance.id)
        print "Load Balancer created with %s" % address
    # Start two balancers to have a hot spare ready in case of primary failure.
    instances = start_instances(2, key, 'loadbalancer', environment, ec2_type,
                                zones=ZONES)
    # Only associate one with an elastic IP that will be the primary.
    _call_on_instances(instances[:1], associate_elastic_ip)
    return instances


def cluster(web_count, db_count, async_count, key, environment, ec2_type=None):
    monitor = start_instances(1, key, 'monitoring', environment, ebs=True, 
                              ec2_type=ec2_type)
    log     = start_instances(1, key, 'log', environment, ebs=True, 
                              ec2_type=ec2_type)
    cache   = start_instances(1, key, 'cache', environment, ec2_type=ec2_type)
    if int(async_count) == 1:
        queue = async = start_instances(1, key, 'queue,async', environment, 
                                        ec2_type=ec2_type)
    else:
        queue = start_instances(1, key, 'queue', environment, ec2_type=ec2_type)
        async = start_instances(async_count, key, 'async', environment, 
                                ec2_type=ec2_type)
    db      = database(db_count, key, environment, ec2_type=ec2_type)
    web     = start_instances(web_count, key, 'web', environment, zones=ZONES,
                              ec2_type=ec2_type)
    lb      = loadbalancer(key, environment, ec2_type=ec2_type)

    print 'Cluster created for environment: %s' % environment
    def print_inst(insts, name):
        for inst in insts:
            print '\t%s instance:\t%s\t%s' % \
                  (name, inst.tags['Name'], inst.ip_address)
    print_inst(web, "Web")
    print_inst(db, "Database")
    print_inst(cache, "Cache")
    print_inst(async, "Async")
    print_inst(queue, "Queue")
    print_inst(log, "Log")
    print_inst(monitor, "Monitoring")
    print_inst(lb, "LoadBalancer")
    
    return list(set(lb + log + cache + db + web + queue + async + monitor))


def start_instances(instance_count, key, chef_roles="", 
                    environment="production", ec2_type=None, ebs=False, 
                    zones=ZONES, chef_data={}, do_config=True, ami=None):
    ec2_type = ec2_type or 'm1.small'
    instance_count = int(instance_count)
    if instance_count <= 0:
        return []
    
    bits = 32 if ec2_type == 'm1.small' else 64
    ebs = ebs or ec2_type == 't1.micro' # t1.micro requires ebs
    ami = ami or AMI['10.10'][bits]['ebs' if ebs else 'ec2']
    security_groups = chef_roles.split(',') + ['default']
    image = ec2.get_all_images(image_ids=[ami])[0]

    logging.info("Starting %s instances using Ubuntu 10.10 %d-bit AMI."
                 " EBS boot is %s." % (instance_count, bits, ebs))

    zones = zones.split(',') if isinstance(zones, str) else zones
    random.shuffle(zones)
    inst_bins = _bin(instance_count, len(zones))

    instances = []
    for bin, zone in zip(inst_bins, zones):
        if bin <= 0: continue
        
        nodetype = '-'.join(([environment] if environment else []) + 
                            sorted(chef_roles.split(',')))
        user_data = _chef_data(chef_roles, nodetype, environment, 
                               **chef_data)
        rsvp = None
        tried_zones = set()
        while rsvp is None and len(tried_zones) < len(zones):
            try:
                rsvp = image.run(bin, bin, key_name=key, user_data=user_data, 
                                 security_groups=security_groups, 
                                 placement=zone, instance_type=ec2_type)
            except boto.exception.BotoServerError, e:
                tried_zones.add(zone)
                zone = random.choice(list(set(zones) - tried_zones)) 
        instances.extend(rsvp.instances)
        logging.info("Started %d instances in zone %s: %s" %
                     (bin, rsvp.instances[0].placement, 
                      ", ".join([i.id for i in rsvp.instances])))

    _wait_on_instances_state(instances,'running')
    
    for inst in instances:
        zone = inst.placement.split('-')
        name = '-'.join((nodetype, (zone[0][0] + zone[1][0] + zone[2]), 
                         inst.id[2:]))
        inst.add_tag('Name', name)
        inst.add_tag('Environment', environment)
    
    _wait_on_instances_ssh(instances)
    if do_config:
        _call_on_instances(instances, configure, environment)

    return instances


def terminate_instances(instances):
    for instance in instances:
        instance.terminate()
    logging.info('Stopping %s instances' % len(instances))

def _chef_data(roles, nodetype, environment, **kwargs):
    run_list = ['base', environment] + roles.split(',')
    data = {
        'attributes': {
            'run_list': ['role[%s]' % r for r in run_list],
            'assigned_domain': 'piick.me',
            'app_environment': environment,
        },
        "node_type": nodetype,
        "validation_client_name": "chef-validator",
        "chef_server": "http://chef:4000"
    }
    data['attributes'].update(kwargs)
    return json.dumps(data)    


def _bin(count, bins, start=0):
    return [count//bins + (1 if i < count % bins else 0) for i in xrange(bins)]


def _wait_on_instances_state(instances, state='running'):
    instances_ready = 0
    while instances_ready < len(instances):
        for i in range(10):
            instances_ready = 0
            for instance in instances:
                try:
                    instance.update()
                except boto.exception.EC2ResponseError:
                    continue
                if instance.state == state:
                    instances_ready += 1
            time.sleep(1)
            if instances_ready == len(instances):
                break
        logging.info('%d of %d instances %s' % 
                     (instances_ready, len(instances), state))


def _wait_on_instances_ssh(instances):
    instances_ready = 0
    while instances_ready < len(instances):
        for i in range(10):
            instances_ready = 0
            for instance in instances:
                if _test_ssh(instance):
                    instances_ready += 1
            if instances_ready == len(instances):
                break
            time.sleep(1)
        logging.info('%d of %d instances accept connections' % 
                     (instances_ready, len(instances)))
    time.sleep(10)


def _call_on_instances(instances, command, *args, **kwargs):
    _host_string = env.host_string
    for instance in instances:
        # Paramiko barfs on unicode strings. Convert to ascii.
        env.host_string = str(instance.public_dns_name)
        # Make 3 attempts at the command before giving up.
        for attempt in range(3):
            try:
                puts('Running "%s"' % command.__name__)
                command(*args, **kwargs)
                break
            except Exception, e:
                print e
                continue
    env.host_string = _host_string


def _test_ssh(instance):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.settimeout(1)
        sock.connect((instance.public_dns_name, 22))
        subprocess.check_call(["ssh", 
                               "-o", "StrictHostKeyChecking=no",
                               "-o", "PasswordAuthentication=no",
                               "-o", "ConnectTimeout=1",
                               "-i", env.key_filename,
                               "ubuntu@" + instance.public_dns_name, "uname"])
        return True
    except subprocess.CalledProcessError:
        return False
    except socket.timeout:
        return False
    except socket.error, e:
        return False
    finally:
        sock.close()
    return False





def build_ami(key, bits, ebs, environment='production', os='10.10'):
    ebs = (ebs == 'True')
    bits = int(bits)
    ami = AMI[os][bits]['ebs' if ebs else 'ec2']
    if bits == '32':
        i = start_instances(1, key, 'default', ebs=ebs, ec2_type='m1.small', 
                            do_config=False, ami=ami)
    else:
        i = start_instances(1, key, 'default', ebs=ebs, ec2_type='m1.large', 
                            do_config=False, ami=ami)

    def prep_ami():
        run('export HISTSIZE=0')
        sudo('export HISTSIZE=0')
        sudo('echo "Ubuntu %s AMI customized for Piick use with Chef on %s" >>'
             '/etc/motd.tail' % (os, CHEF_SERVER_IP[environment]))
        sudo('echo "deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ maverick multiverse" >> /etc/apt/sources.list')
        sudo('echo "deb-src http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ maverick multiverse" >> /etc/apt/sources.list')
        sudo('echo "deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ maverick-updates multiverse" >> /etc/apt/sources.list')
        sudo('echo "deb-src http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ maverick-updates multiverse" >> /etc/apt/sources.list')
        sudo('echo "deb http://security.ubuntu.com/ubuntu maverick-security multiverse" >> /etc/apt/sources.list')
        sudo('echo "deb-src http://security.ubuntu.com/ubuntu maverick-security multiverse" >> /etc/apt/sources.list')
        sudo('apt-get update')

    def bundle_ami():
        sudo('apt-get install -y ec2-ami-tools')
        
        sudo('mkdir -p /mnt/ec2')
        put('~/.ec2/pk-N7Z57PKWQMTEOFH2FD5KBQIZMNK4NAOB.pem','/tmp/pk.pem')
        put('~/.ec2/cert-N7Z57PKWQMTEOFH2FD5KBQIZMNK4NAOB.pem','/tmp/cert.pem')
        sudo('cp /tmp/*.pem /mnt/ec2')
        
        arch = 'i386' if bits == 32 else 'x86_64'
        name = ("ubuntu-%s-chef-0.9.8-%s" % (os, arch)) +('-ebs' if ebs else '')

        sudo('ec2-bundle-vol -c /mnt/ec2/cert.pem -k /mnt/ec2/pk.pem '
             '--user "%s" -r %s -p %s' % (env.aws_account_id, arch, name))
        sudo('ec2-upload-bundle -b ubuntu.piick.com '
             '-m /tmp/%s.manifest.xml -a "%s" -s "%s"'
             % (name, env.aws_access_key, env.aws_secret_key))
        local('ec2-register -C ~/.ec2/cert-N7Z57PKWQMTEOFH2FD5KBQIZMNK4NAOB.pem'
              ' -K ~/.ec2/pk-N7Z57PKWQMTEOFH2FD5KBQIZMNK4NAOB.pem'
              ' ubuntu.piick.com/%s.manifest.xml -n %s -a %s'
              % (name, name, arch), False)
    
    for attempt in range(5):
        try:
            _call_on_instances(i, prep_ami)
            _call_on_instances(i, functools.partial(configure, run_chef=False))
            _call_on_instances(i, bundle_ami)
            break
        except Exception, e:
            print e
            continue
    
    terminate_instances(i)
