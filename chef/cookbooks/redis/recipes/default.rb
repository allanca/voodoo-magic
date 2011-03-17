
remote_file "/opt/redis-#{node[:redis][:version]}.tgz" do
  source "http://redis.googlecode.com/files/redis-#{node[:redis][:version]}.tar.gz"
  mode "0644"
  not_if do File.exists?("/opt/redis-#{node[:redis][:version]}.tgz") end
end

execute "untar" do
  cwd "/opt"
  command "tar -zxf /opt/redis-#{node[:redis][:version]}.tgz"
  creates "/opt/redis-#{node[:redis][:version]}"
end

package "build-essential"
execute "install_redis" do
  cwd "/opt/redis-#{node[:redis][:version]}"
  command "/etc/init.d/redis-server stop && make && make install"
  creates "/opt/redis-#{node[:redis][:version]}/src/redis-server"
  notifies :start, "service[redis-server]"
end

link "/opt/redis" do
  to "/opt/redis-#{node[:redis][:version]}"
end

group "redis"
user "redis" do
  comment "redis admin"
  gid 'redis'
  system true
  shell "/bin/false"
end

template "/etc/init.d/redis-server" do
  source "init-deb.sh"
  owner 'root'
  group 'root'
  mode 0755
end

service "redis-server" do
  action :enable
end
  
directory "/mnt/redis" do
  owner "redis"
  group "redis"
  action :create
end

directory "/var/log/redis" do
  owner "redis"
  group "redis"
  action :create
end

file "/var/log/redis/redis-server.log" do
  owner "redis"
  group "redis"
  mode "0644"
  action :create
end

directory "/etc/redis" do
  owner "redis"
  group "redis"
end

link "/etc/redis/redis.conf" do
  to "/opt/redis/redis.conf"
  notifies :restart, resources(:service => "redis-server")
end

package "gawk"

template "/usr/local/sbin/redis-snapshot" do
   owner 'root'
   group 'root'
   mode 0755
   source "redis-snapshot.erb"
end

cron "redis-snapshot" do
  command "/usr/local/sbin/redis-snapshot"
  minute node[:redis][:snapshot_minute]
end

template "/opt/redis-#{node[:redis][:version]}/redis.conf" do
  owner "redis"
  group "redis"
  mode "0644"
  notifies :restart, resources(:service => "redis-server")
end

service "redis-server" do
  action :start
end