#
# Cookbook Name:: scribe
# Recipe:: default
#

include_recipe "thrift"
package "libboost-filesystem-dev"

remote_file "/opt/scribe-2.2.tar.gz" do
  source "http://github.com/downloads/facebook/scribe/scribe-2.2.tar.gz"
  mode "0644"
  not_if do File.exists?("/opt/scribe-2.2.tar.gz") end
end

execute "untar" do
  cwd "/opt"
  command "tar -zxf scribe-2.2.tar.gz"
  creates "/opt/scribe"
  action :run
end

bash "install_scribe" do
  cwd "/opt/scribe"
  code <<-EOH
    sh bootstrap.sh 
    ./configure --prefix=/opt/scribe --with-thriftpath=/opt/thrift --with-fb303path=/opt/fb303
    make install
    cd lib/py
    python setup.py install
  EOH
  not_if { FileTest.exists?("/usr/local/bin/scribed") }
end

directory "/var/log/scribe" do
  owner 'root'
  group 'users'
  mode 0775
end

directory "/etc/scribed" do
  owner 'root'
  group 'root'
  mode 0755
end

begin
  scribe_server = search(:node, "role:log AND app_environment:#{node['app_environment']}").first[:ipaddress]
rescue NoMethodError, Chef::Exception
  scribe_server = node[:scribed][:scribe_host]
end
template "/etc/scribed/scribe.conf" do
  owner 'root'
  group 'root'
  mode 0644
  source "scribe.conf"
  variables({
    :scribe_server => scribe_server
  })
end

template "/etc/init.d/scribed" do
  owner 'root'
  group 'root'
  mode 0755
  source "scribed.erb"
end

service "scribed" do
  supports :status => true, :restart => true
  action [:enable, :start]
end
