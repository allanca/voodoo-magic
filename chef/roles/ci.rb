name "ci"
description "Hudson server"
recipes "scribed","celery","pi"

default_attributes "pi"        => { :base_dir => "/piick/pi", :run => true},
                   "scribed"   => { :scribe_host => 'localhost' }
