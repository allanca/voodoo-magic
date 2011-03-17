name "databaseslave"
description "Database slave role. All but one database nodes are slaves."
recipes "cassandra::slave", "redis::slave"

