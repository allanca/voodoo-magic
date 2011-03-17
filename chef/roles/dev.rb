name "dev"
description "Dev environment keys and accounts"

override_attributes :ec2        => {:access_key => "",
                                    :secret_key => ""},
                    :postfix    => {:sendgrid_username => "", 
                                    :sendgrid_password => "",
                                    :myorigin => "localhost"},
                    :pi         => {:run => false, :base_url => "piick.lan", :base_dir => "/piick/pi"},
                    :cassandra  => {:replication_factor => 1},
                    :haproxy    => {:check_inter => "3600s",
                                    :check_fastinter => "100ms",
                                    :check_downinter => "100ms"},
                    :redis      => {:max_memory => "350"}
