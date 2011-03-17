#
# Cookbook Name:: Log_processor
# Recipe:: default
#

include_recipe "pycassa"

package "python-mysqldb"

## Send an email with a list of requests sorted by response time descending.
cookbook_file "/usr/local/bin/stat_access" do
  source "stat_access"
  mode "0755"
  owner "root"
  group "root"
end
  
cron "stat_access" do
  command "/usr/local/bin/stat_access `find /var/log/scribe/access |sort | tail -n 3 | head -n -2` 'allan@piick.com,corey@piick.com'"
  minute "5"
end


## Process counter logs into the mysql stats db
database_servers = (search(:node, "role:database AND app_environment:#{node[:app_environment]}").collect {|x| x[:ipaddress]}) or node[:pi][:database_servers]
template "/usr/local/bin/stat_counter" do
  source "stat_counter.erb"
  mode "0755"
  owner "root"
  group "root"
  variables(
    :database_servers => database_servers
  )
end
  
cron "stat_counter" do
  command "/usr/local/bin/stat_counter"
  minute "5"
end

## Send alerts when there are errors on the server
cookbook_file "/usr/local/bin/stat_error" do
  source "stat_error"
  mode "0755"
  owner "root"
  group "root"
end
  
cron "stat_error" do
  command "/usr/local/bin/stat_error 'allan@piick.com,corey@piick.com,jason@piick.com'"
  minute "*/5"
end


## Setup the mysql server to accept processed log data
package "phpmyadmin"
package "ruby-dev"

Gem.clear_paths # needed for Chef to find the gem...
require 'mysql' # requires the mysql gem

mysql_database "create stats database" do
  host "localhost"
  username "root"
  password node[:mysql][:server_root_password]
  database "stats"
  action :create_db
end
