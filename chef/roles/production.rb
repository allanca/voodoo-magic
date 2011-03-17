name "production"
description "Production environment keys and accounts"
recipes "ec2", "users::sysadmins", "sudo", "munin::client", "nagios::client"

override_attributes :postfix    => {:sendgrid_username => "", 
                                    :sendgrid_password => ""},
                    :ec2        => {:access_key => "",
                                    :secret_key => ""},
                    :nagios     => {:notifications_enabled => 1},
                    :redis      => {:max_memory => "1024"}
