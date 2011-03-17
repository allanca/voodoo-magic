#
# Cookbook Name:: cassandra
# Recipe:: default
#

package "openjdk-6-jre"
package "jsvc"

directory "#{node[:cassandra][:commit_root]}" do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

directory "#{node[:cassandra][:data_root]}" do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

remote_file "/opt/cassandra-#{node[:cassandra][:version]}.tgz" do
  source "http://apache.cs.utah.edu/cassandra/#{node[:cassandra][:version]}/apache-cassandra-#{node[:cassandra][:version]}-bin.tar.gz"
  mode "0644"
  not_if do File.exists?("/opt/cassandra-#{node[:cassandra][:version]}.tgz") end
end

execute "untar" do
  cwd "/opt"
  command "tar -zxf cassandra-#{node[:cassandra][:version]}.tgz"
  creates "/opt/apache-cassandra-#{node[:cassandra][:version]}"  
  action :run
end

link "/usr/share/cassandra" do
  to "/opt/apache-cassandra-#{node[:cassandra][:version]}/lib"
end

link "/etc/cassandra" do
  to "/opt/apache-cassandra-#{node[:cassandra][:version]}/conf"
end

template "/etc/init.d/cassandra" do
  owner 'root'
  group 'root'
  mode 0755
  source "init.erb"
end

service "cassandra" do
  supports :status => true, :restart => true
  action :enable
end

template "/etc/cassandra/log4j.properties" do
  owner 'root'
  group 'root'
  mode 0644
  source "log4j.properties.erb"
  notifies :restart, resources(:service => "cassandra")
end

template "/etc/cassandra/rack.properties" do
  owner 'root'
  group 'root'
  mode 0644
  source "rack.properties.erb"
  notifies :restart, resources(:service => "cassandra")
end

template "/etc/default/cassandra" do
  owner 'root'
  group 'root'
  mode 0644
  source "default.erb"
  notifies :restart, resources(:service => "cassandra")
end

template "/etc/cassandra/storage-conf.xml" do
  owner 'root'
  group 'root'
  mode 0644
  source "storage-conf.xml.erb"
  notifies :restart, resources(:service => "cassandra")
end

## Setup hourly backups
package "python-pip"
execute "install boto" do
  command "pip install --upgrade boto"
end

template "/usr/local/sbin/cassandra-snapshot" do
   owner 'root'
   group 'root'
   mode 0755
   source "cassandra-snapshot.erb"
end

cron "cassandra-snapshot" do
  command "/usr/local/sbin/cassandra-snapshot"
  minute node[:cassandra][:snapshot_minute]
end


## Setup munin monitoring

if node.attribute?('munin')
  include_recipe "munin"

  %w{ compactions_bytes compactions_pending flush_stage_pending hh_pending jvm_cpu jvm_memory ops_pending storageproxy_latency storageproxy_ops }.each do |metric|
    cassandra_munin_plugin metric do
      create_file true
    end
  end

  %w{ HintsColumnFamily }.each do |cf|
    columnfamily_munin_plugin cf do
      keyspace "system"
    end
  end

  %w{ User Line LineItem Followers Leaders Product ProductGraph Alert Activity }.each do |cf|
    columnfamily_munin_plugin cf do
      keyspace "piick"
    end
  end
end