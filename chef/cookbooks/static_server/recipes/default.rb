#
# Cookbook Name:: Static_server
# Recipe:: default
#

## Configure nginx
include_recipe "nginx"

template "#{node[:nginx][:dir]}/sites-available/piick" do
  source "piick.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => 'nginx')
end
cert = node[:app_environment] || 'development'
cookbook_file "#{node[:nginx][:dir]}/conf.d/piick.crt" do
  source "#{cert}.crt"
  owner "root"
  group "root"
  mode "0640"
  notifies :restart, resources(:service => 'nginx')
end
cookbook_file "#{node[:nginx][:dir]}/conf.d/piick.key" do
  source "#{cert}.key"
  owner "root"
  group "root"
  mode "0640"
  notifies :restart, resources(:service => 'nginx')
end

nginx_site "piick" do
  enable true
end

## Disable nginx default site which might be named 000-default 
## or default depending on the version
nginx_site "000-default" do
  enable false
end
nginx_site "default" do
  enable false
end

if node.attribute?("munin")
  include_recipe "munin"

  munin_plugin "nginx_memory" do
    create_file true
  end

  munin_plugin "nginx_request"  do
    create_file true
  end

  munin_plugin "nginx_status"  do
    create_file true
  end
end