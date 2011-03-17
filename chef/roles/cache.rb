name "cache"
description "Data caching node. Memcache."
recipes "memcached::basic"

default_attributes "memcached" => { :max_memory => 1024*4 }
