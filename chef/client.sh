#!/bin/bash
    apt-get install -y curl
    echo deb http://apt.opscode.com/ lucid main > /etc/apt/sources.list.d/opscode.list
    curl http://apt.opscode.com/packages@opscode.com.gpg.key | apt-key add -
    apt-get update
    apt-get -y upgrade
    apt-get install -y rubygems ohai chef libshadow-ruby1.8
    
    /usr/bin/chef-client -d -i 3600 -s 600
