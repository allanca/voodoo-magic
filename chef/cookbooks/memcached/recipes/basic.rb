require_recipe "memcached"

service "memcached" do
  action :enable
  supports :restart => true, :reload => true
end

template node[:memcached][:conf_path] do
  source "memcached.conf.erb"  
  notifies :restart, resources(:service => "memcached")
  variables(:max_memory => node[:memcached][:max_memory],
            :port => node[:memcached][:port],
            :user => node[:memcached][:user],
            :max_connections => node[:memcached][:max_connections],
            :log_path => node[:memcached][:log_path])
end

service "memcached" do
  action :start
end

if node.attribute?('munin')
  require_recipe "munin"

  munin_plugin "memcached_bytes_" do
    create_file true
  end

  munin_plugin "memcached_connections_" do
    create_file true
  end

  munin_plugin "memcached_hits_" do
    create_file true
  end

  munin_plugin "memcached_items_" do
    create_file true
  end

  munin_plugin "memcached_requests_" do
    create_file true
  end

  munin_plugin "memcached_responsetime_" do
    create_file true
  end

  munin_plugin "memcached_traffic_" do
    create_file true
  end
end