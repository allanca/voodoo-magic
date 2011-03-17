#!/usr/bin/env bash
apt-get install -y ruby ruby1.8-dev libopenssl-ruby1.8 rdoc ri irb build-essential wget ssl-cert

cd /opt
wget http://rubyforge.org/frs/download.php/69365/rubygems-1.3.6.tgz
tar zxf rubygems-1.3.6.tgz
cd rubygems-1.3.6
sudo ruby setup.rb
sudo ln -sfv /usr/bin/gem1.8 /usr/bin/gem

sudo gem sources -r http://gems.rubyforge.org/
sudo gem sources -a http://rubygems.org/
gem install chef --no-ri --no-rdoc

wget http://piick.com/chef/solo.rb

echo '{"run_list":["role[base]","role[web]","role[dev]","role[database]"]}' >> dna.json
chef-solo -c solo.rb -j dna.json -r http://piick.com/chef/chef.tgz
