#
# Cookbook Name:: pycassa
# Recipe:: default
#

remote_file "/opt/pycassa-0.3.0.tar.gz" do
  source "http://github.com/downloads/pycassa/pycassa/pycassa-0.3.0.tar.gz"
  mode "0644"
  not_if do File.exists?("/opt/pycassa-0.3.0.tar.gz") end
end

execute "untar" do
  cwd "/opt"
  command "tar -zxf pycassa-0.3.0.tar.gz"
  creates "/opt/pycassa-0.3.0"  
end

execute "makepycassa" do
  cwd "/opt/pycassa-0.3.0"
  command "python setup.py --cassandra install"
  action :run
end
