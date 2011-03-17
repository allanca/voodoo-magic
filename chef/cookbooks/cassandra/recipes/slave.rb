require_recipe "cassandra"

node[:cassandra][:autobootstrap] = "true"

begin
  node[:cassandra][:seed_ipaddress] = (search(:node, "role:databasemaster AND app_environment:#{node[:app_environment]}").first[:ipaddress])
rescue Chef::Exception
end

template "/etc/cassandra/storage-conf.xml" do
  owner 'root'
  group 'root'
  mode 0644
  source "storage-conf.xml.erb"
  notifies :restart, resources(:service => "cassandra")
end
