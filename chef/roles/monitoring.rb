name "monitoring"
description "The munin and nagios hosts."
recipes "munin::server", "nagios::server", "postfix"
