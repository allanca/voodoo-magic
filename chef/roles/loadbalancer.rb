name "loadbalancer"
description "Balances incoming traffic to the web nodes."
recipes "haproxy::app_lb", "static_server"

default_attributes "haproxy"   => { :listen_port => 8080 },
                   "nginx"     => { :keepalive_timeout => "65", 
                                    :worker_connections => "2048",
                                    :worker_processes => "1" }

