name "log"
description "Receives and archives log streams."
recipes "scribed","postfix","build","ruby","mysql::server","log_processor"

default_attributes "scribed" => { :is_host => true }

