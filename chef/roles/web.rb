name "web"
description "Web server"
recipes "scribed","celery","pi"

default_attributes "pi"        => { :base_dir   => "/piick/pi",    :run => true},
                   "celery"    => { :config_dir => "/piick/pi/pi", :run => false }
