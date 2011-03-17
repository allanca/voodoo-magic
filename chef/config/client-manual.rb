# Chef Client Config File

require 'ohai'
require 'json'

o = Ohai::System.new
o.all_plugins
# chef_config = JSON.parse(o[:ec2][:userdata])
# if chef_config.kind_of?(Array)
#   chef_config = chef_config[o[:ec2][:ami_launch_index]]
# end

log_level        :info
log_location     "/var/log/chef/client.log"
chef_server_url  "http://10.212.165.177:4000"
registration_url "http://10.212.165.177:4000"
openid_url       "http://10.212.165.177:4000"
template_url     "http://10.212.165.177:4000"
remotefile_url   "http://10.212.165.177:4000"
search_url       "http://10.212.165.177:4000"
role_url         "http://10.212.165.177:4000"
client_url       "http://10.212.165.177:4000"

node_name        o[:ec2][:instance_id]

# if chef_config.has_key?("validation_key")
#   unless File.exists?("/etc/chef/client.pem")
#     File.open("/etc/chef/validation.pem", "w") do |f|
#       f.print(chef_config["validation_key"])
#     end
#   end
# end
# 
# if chef_config.has_key?("attributes")
#   File.open("/etc/chef/client-config.json", "w") do |f|
#     f.print(JSON.pretty_generate(chef_config["attributes"]))
#   end
# end
json_attribs "/etc/chef/client-config.json"

validation_key "/etc/chef/validation.pem"
validation_client_name "chef-validator"

Mixlib::Log::Formatter.show_time = true
