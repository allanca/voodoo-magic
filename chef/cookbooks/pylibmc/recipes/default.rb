#
# Cookbook Name:: pylibmc
# Recipe:: default
#

# Install libmemcached
include_recipe "build"
include_recipe "memcached"

remote_file "/opt/libmemcached-0.40.tar.gz" do
  source "http://launchpadlibrarian.net/45148485/libmemcached-0.40.tar.gz"
  mode "0644"
  not_if do File.exists?("/opt/libmemcached-0.40.tar.gz") end
end

execute "untar" do
  cwd "/opt"
  command "tar -zxf libmemcached-0.40.tar.gz"
  creates "/opt/libmemcached-0.40"  
end

execute "make" do
  cwd "/opt/libmemcached-0.40"
  command "./configure && make all install"
  not_if do File.exists?("/usr/lib/libmemcached.so") end
end

link "/usr/lib/libmemcached.so" do
  to "/usr/local/lib/libmemcached.so"
end
link "/usr/lib/libmemcachedutil.so" do
  to "/usr/local/lib/libmemcachedutil.so"
end
link "/usr/lib/libmemcachedprotocol.so" do
  to "/usr/local/lib/libmemcachedprotocol.so"
end


# Setup pylibmc
package "python-dev"
package "python-setuptools"

package "zlibc"
package "zlib1g-dev"

remote_file "/opt/pylibmc-1.1.1.tar.gz" do
  source "http://pypi.python.org/packages/source/p/pylibmc/pylibmc-1.1.1.tar.gz#md5=e43c54e285f8d937a3f1a916256ecc85"
  mode "0644"
  not_if do File.exists?("/opt/pylibmc-1.1.1.tar.gz") end
end

execute "untar" do
  cwd "/opt"
  command "tar -zxf pylibmc-1.1.1.tar.gz"
  creates "/opt/pylibmc-1.1.1"
end

execute "makepylibmc" do
  cwd "/opt/pylibmc-1.1.1"
  command "python setup.py install"
  action :run
end
