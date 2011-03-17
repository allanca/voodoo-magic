#!/bin/bash

echo;echo "Installing Vagrant";echo
sudo gem install vagrant

echo;echo "Downloading and adding ubuntu base box. This may take some time.";echo
vagrant box add vagrant-ubuntu-10.10-amd64 http://files.piick.com/piick-ubuntu-10.10-amd64.box

echo;echo "Setting up the development server";echo
cd vagrant
vagrant up
vagrant ssh
