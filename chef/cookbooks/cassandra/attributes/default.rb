default[:cassandra][:version]            = "0.6.8"
default[:cassandra][:max_memory]         = "4G"
default[:cassandra][:autobootstrap]      = "false"
default[:cassandra][:seed_ipaddress]     = "127.0.0.1"
default[:cassandra][:data_root]          = "/mnt/data"
default[:cassandra][:commit_root]        = "/mnt/commitlog"
default[:cassandra][:cache_root]         = "/mnt/caches"
default[:cassandra][:replication_factor] = 3
default[:cassandra][:rack_aware]         = false
default[:cassandra][:rack_properties]    = {'127.0.0.1' => 'east:r1a'}
default[:cassandra][:cluster_name]       = "default"
set_unless[:cassandra][:snapshot_minute] = rand(60)
