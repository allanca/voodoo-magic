#
# Cookbook Name:: munin
# Definition:: cassandra_munin_plugin
#
# Copyright 2010, Piick, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


define :cassandra_munin_plugin, :plugin_config => "/etc/munin/plugins", :plugin_dir => "/usr/share/munin/plugins", :create_file => false, :enable => true do

  include_recipe "munin::client"

  plugin = params[:plugin] ? params[:plugin] : params[:name]

  if params[:create_file]
    cookbook_file "#{params[:plugin_dir]}/cassandra_#{plugin}.conf" do
      cookbook "munin"
      source "plugins/cassandra/#{plugin}.conf"
      owner "root"
      group "root"
      mode 0664
    end
  end

  cookbook_file "#{params[:plugin_dir]}/jmx_" do
    cookbook "munin"
    source "plugins/cassandra/jmx_"
    owner "root"
    group "root"
    mode 0755
  end

  cookbook_file "#{params[:plugin_dir]}/jmxquery.jar" do
    cookbook "munin"
    source "plugins/cassandra/jmxquery.jar"
    owner "root"
    group "root"
    mode 0664
  end

  cookbook_file "#{params[:plugin_config]}/../plugin-conf.d/cassandra.conf" do
    cookbook "munin"
    source "cassandra.conf"
    owner "root"
    group "root"
    mode 0644
  end

  link "#{params[:plugin_config]}/cassandra_#{plugin}" do
    to "#{params[:plugin_dir]}/jmx_"
    if params[:enable]
      action :create
    else
      action :delete
    end
    notifies :restart, resources(:service => "munin-node")
  end

end
