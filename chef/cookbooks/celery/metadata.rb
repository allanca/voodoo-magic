maintainer "Piick, Inc"
maintainer_email "allan@piick.com"
license "Apache 2.0"
description "Installs and configures celery"
version "0.1"

%w{ debian ubuntu }.each do |os|
  supports os
end
