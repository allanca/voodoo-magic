#!/bin/bash
# 390675623411
echo "Setting up firewall for EC2 account   " $1
ec2-add-group async -d async
ec2-add-group cache -d cache
ec2-authorize cache -P tcp -p 11211 -o web -u $1
ec2-authorize cache -P tcp -p 11211 -o async -u $1
ec2-add-group database -d database
ec2-add-group databasemaster -d databasemaster
ec2-add-group databaseslave -d databaseslave
ec2-authorize database -P tcp -p 7000 -o database -u $1
ec2-authorize database -P tcp -p 9160 -o web -u $1
ec2-authorize database -P tcp -p 9160 -o log -u $1
ec2-authorize database -P tcp -p 9160 -o database -u $1
ec2-authorize database -P tcp -p 9160 -o async -u $1
ec2-authorize database -P tcp -p 10036 -o web -u $1
ec2-authorize database -P tcp -p 10036 -o database -u $1
ec2-authorize database -P tcp -p 10036 -o async -u $1
ec2-authorize database -P tcp -p 6379 -o web -u $1
ec2-authorize database -P tcp -p 6379 -o async -u $1
ec2-authorize default -P tcp -p 4949 -o monitoring -u $1
ec2-authorize default -P tcp -p 5666-5667 -o monitoring -u $1
ec2-authorize default -P tcp -p 22 -o monitoring -u $1
ec2-authorize default -P icmp -t -1:-1 -o monitoring -u $1
ec2-add-group loadbalancer -d loadbalancer
ec2-authorize loadbalancer -P tcp -p 80 -s "0.0.0.0/0"
ec2-authorize loadbalancer -P tcp -p 443 -s "0.0.0.0/0"
ec2-authorize loadbalancer -P tcp -p 8080 -o loadbalancer -u $1
ec2-add-group log -d log
ec2-authorize log -P tcp -p 1463 -o web -u $1
ec2-authorize log -P tcp -p 1463 -o async -u $1
ec2-add-group monitoring -d monitoring
ec2-authorize monitoring -P tcp -p 4949 -o default -u $1
ec2-authorize monitoring -P tcp -p 5667 -o default -u $1
ec2-add-group queue -d queue
ec2-authorize queue -P tcp -p 5672 -o web -u $1
ec2-authorize queue -P tcp -p 5672 -o async -u $1
ec2-add-group web -d web
ec2-authorize web -P tcp -p 8000-9000 -o loadbalancer -u $1
ec2-authorize web -P tcp -p 8000 -o monitoring -u $1
ec2-add-group production -d production

