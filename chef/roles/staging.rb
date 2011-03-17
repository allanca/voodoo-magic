name "staging"
description "Staging environment keys and accounts"
recipes "ec2" #, "users::sysadmins", "sudo", "munin::client", "nagios::client"

override_attributes :ec2        => {:access_key => "",
                                    :secret_key => ""},
                    :postfix    => {:sendgrid_username => "", 
                                    :sendgrid_password => ""},
                    :redis      => {:max_memory => "1024"}
