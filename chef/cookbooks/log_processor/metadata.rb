maintainer "Piick, Inc"
maintainer_email "allan@piick.com"
description "Processes and reports from the scribe logs"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version "0.1"

depends "pycassa"

%w{ debian ubuntu }.each do |os|
  supports os
end
