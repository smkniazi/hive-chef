include_attribute "kagent"
include_attribute "ndb"
include_attribute "apache_hadoop"
include_attribute "kzookeeper"

default.hive2.user                    = "hive"
default.hive2.group                   = node.apache_hadoop.group
default.hive2.version                 = "2.2.0-SNAPSHOT"
default.hive2.url                     = "#{node.download_url}/apache-hive-#{node.hive2.version}-bin.tar.gz"
default.hive2.port                    = "2222"
default.hive2.dir                     = "/srv"
default.hive2.home                    =  node.hive2.dir + "/apache-hive-" + node.hive2.version + "-bin"
default.hive2.base_dir                =  node.hive2.dir + "/apache-hive" 
default.hive2.keystore                = "#{node.kagent.base_dir}/node_server_keystore.jks"
default.hive2.keystore_password       = "changeit"

default.hive2.mysql_user              = "hive"
default.hive2.mysql_password          = "hive"

default.hive2.server2.pid_file        = "/tmp/hive.pid"
default.hive2.metastore.pid_file      = "/tmp/hive.pid"
default.hive2.metastore.log           = "#{node.hive2.base_dir}/hive-metastore.log"
default.hive2.sever2.log              = "#{node.hive2.base_dir}/hive-server2.log"
default.hive2.systemd                 = "true"
