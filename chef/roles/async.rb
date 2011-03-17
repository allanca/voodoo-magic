name "async"
description "Does async processing out of the critical path. All notification sending is async through postfix."
recipes "celery","scribed","postfix","pi"

default_attributes  "pi"        => { :base_dir   => "/piick/pi",    :run => false},
                    "celery"    => { :config_dir => "/piick/pi/pi", :run => true }
