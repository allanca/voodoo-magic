#
# Cookbook Name:: Celery
# Recipe:: default
#

package "python-setuptools"
package "supervisor"
easy_install_package "celery"

execute "restartcelery" do
	command "supervisorctl reread; supervisorctl update; supervisorctl restart celery; supervisorctl restart celerybeat"
  action :nothing
end

if node[:celery][:run] then
  template "/etc/supervisor/conf.d/celeryd.conf" do
      source "celeryd.conf.erb"
      mode 0755
      owner "root"
      group "root"
  end
end

service "supervisor" do
  supports :status => true, :restart => true
end

directory node[:celery][:config_dir] do
  owner 'root'
  group 'users'
  mode 0775
  recursive true
end

begin
  queue_host = search(:node, "role:queue AND app_environment:#{node['app_environment']}").first[:ipaddress]
rescue NoMethodError, Chef::Exception
  queue_host = node[:celery][:queue_host]
end
template node[:celery][:config_dir] + "/celeryconfig.py" do
  source "celeryconfig.py.erb"
  mode 0644
  owner "root"
  group "root"
  variables(
    :queue_host => queue_host
  )
  notifies :run, resources(:execute => 'restartcelery')
end
