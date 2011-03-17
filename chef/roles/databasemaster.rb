name "databasemaster"
description "Database master role. One database machine is the master. The rest autobootstrap from this one."
recipes "cassandra", "redis"
