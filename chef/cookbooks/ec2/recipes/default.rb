package "htop"

bootstrap_fqdn = "#{node[:assigned_hostname]}.#{node[:assigned_domain]}"

bash "Add hosts entry for current node" do
  code "echo '#{node[:ipaddress]} #{bootstrap_fqdn}' >> /etc/hosts"
  not_if "grep '#{node[:ipaddress]} #{bootstrap_fqdn}' /etc/hosts"
end

bash "Set domain name" do
  code "echo #{node[:assigned_domain]} > /etc/domainname"
  not_if "grep #{node[:assigned_domain]} /etc/domainname"
end

bash "Set hostname" do
  code "echo #{bootstrap_fqdn} > /etc/hostname"
  not_if "grep #{bootstrap_fqdn} /etc/hostname"
end

bash "Set mailname for postfix" do
  code "echo #{bootstrap_fqdn} > /etc/mailname"
  not_if "grep #{node[:assigned_hostname]} /etc/mailname"
end

execute "Set hostname" do
  command "start hostname"
  only_if { `hostname -f` != bootstrap_fqdn }
end


## Setup the poor-man's dns script

package "python-pip"
execute "install boto" do
  command "pip install --upgrade boto"
end

cookbook_file "/usr/local/sbin/ec2-hosts" do
   owner 'root'
   group 'root'
   mode 0755
   source "ec2-hosts"
end
 
cron "ec2-hosts" do
  command "/usr/local/sbin/ec2-hosts #{node[:ec2][:access_key]} #{node[:ec2][:secret_key]} > /etc/hosts"
  minute "*/5"
end
