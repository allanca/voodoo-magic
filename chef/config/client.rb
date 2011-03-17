# Chef Client Config File

require 'ohai'
require 'json'

o = Ohai::System.new
o.all_plugins
chef_config = JSON.parse(o[:ec2][:userdata])
if chef_config.kind_of?(Array)
  chef_config = chef_config[o[:ec2][:ami_launch_index]]
end

log_level        :info
log_location     "/var/log/chef/client.log"
chef_server_url  chef_config["chef_server"]
registration_url chef_config["chef_server"]
openid_url       chef_config["chef_server"]
template_url     chef_config["chef_server"]
remotefile_url   chef_config["chef_server"]
search_url       chef_config["chef_server"]
role_url         chef_config["chef_server"]
client_url       chef_config["chef_server"]

zone = o[:ec2][:placement_availability_zone].split('-')
node_name        chef_config["node_type"] +'-'+
                 (zone[0][0,1] + zone[1][0,1] + zone[2]) +'-'+
                 o[:ec2][:instance_id].slice(2..-1)

# Some first-run setup. Pull run list, node name, and other settings 
# from the ec2 user data.
unless File.exists?("/etc/chef/client.pem")
  if chef_config.has_key?("attributes")
    chef_config["attributes"]["assigned_hostname"] = node_name
    File.open("/etc/chef/client-config.json", "w") do |f|
      f.print(JSON.pretty_generate(chef_config["attributes"]))
    end
    json_attribs "/etc/chef/client-config.json"
  end
end

validation_key "/etc/chef/validation.pem"
validation_client_name chef_config["validation_client_name"]

Mixlib::Log::Formatter.show_time = true
