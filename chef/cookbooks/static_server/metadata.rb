maintainer "Piick, Inc"
maintainer_email "allan@piick.com"
description "Server for static content and ssl termination in front of HAProxy."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version "0.1"

depends "nginx"
depends "munin"

%w{ debian ubuntu }.each do |os|
  supports os
end
