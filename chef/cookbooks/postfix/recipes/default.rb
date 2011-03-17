package "libsasl2-modules"

package "postfix" do
  action :upgrade
end

package "postfix-pcre"

directory "/etc/postfix/virtual" do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

service "postfix" do
  action [:enable]
  supports :restart => true, :reload => true
end

template "/etc/postfix/main.cf" do
  source "main.cf.erb"
  mode 0644
  notifies :restart, resources(:service => "postfix")
end

service "postfix" do
  action :start
end