maintainer "Piick, Inc"
maintainer_email "allan@piick.com"
license "Apache 2.0"
description "Installs and configures pycassa"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version "0.1"
depends "build"
 
%w{ debian ubuntu }.each do |os|
  supports os
end
