default.redis[:version] = "2.2.1"
default.redis[:port] = 6379
default.redis[:bind_address] = "0.0.0.0"
default.redis[:timeout] = 300
default.redis[:databases] = 16

# Don't setup a master server by default.
default.redis[:master_ip_address] = false

# max memory in MB
default.redis[:max_memory] = "250"

#  db snapshots to disk
#  after 900 sec (15 min) if at least 1 key changed
#  after 300 sec (5 min) if at least 10 keys changed
#  after 60 sec if at least 1000 keys changed

default.redis[:snapshots] = {900 => 1, 300 => 10, 60 => 1000}

set_unless[:redis][:snapshot_minute] = rand(60)
