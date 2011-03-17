require_recipe "redis"

begin
  node[:redis][:slave] = {:master_ip => (search(:node, "role:databasemaster AND app_environment:#{node[:app_environment]}").first[:ipaddress])}
rescue Chef::Exception
end

template "/opt/redis-#{node[:redis][:version]}/redis.conf" do
  owner "redis"
  group "redis"
  mode "0644"
  notifies :restart, resources(:service => "redis-server")
end
