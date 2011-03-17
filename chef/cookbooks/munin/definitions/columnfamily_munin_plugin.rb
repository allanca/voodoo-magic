#
# Cookbook Name:: munin
# Definition:: columnfamily_munin_plugin
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


define :columnfamily_munin_plugin, :keyspace => "piick", :plugin_dir => "/usr/share/munin/plugins", :enable => true do

  include_recipe "munin::client"

  %w{ keycache livesize rowcache latency ops sstables }.each do |metric|
    cassandra_munin_plugin "#{params[:keyspace]}.#{params[:name]}_#{metric}"

    template "#{params[:plugin_dir]}/cassandra_#{params[:keyspace]}.#{params[:name]}_#{metric}.conf" do
      cookbook "munin"
      source "cassandra/standard1_#{metric}.conf.erb"
      owner "root"
      group "root"
      mode 0755
      variables(
        :keyspace => params[:keyspace],
        :cf => params[:name]
      )
    end
  end

end
