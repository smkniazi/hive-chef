default.hive2.user                    = node.apache_hadoop.user
default.hive2.group                   = node.apache_hadoop.group

# apache-hive2-2.2.0-SNAPSHOT-bin.tar.gz
default.hive2.version                 = "2.2.0-SNAPSHOT"
default.hive2.url                     = "#{node.download_url}/apache-hive-#{node.hive2.version}-bin.tar.gz"
default.hive2.port                    = "2222"
default.hive2.dir                     = "/srv"
default.hive2.home                    =  node.hive2.dir + "/hive-server-" + node.hive2.version
default.hive2.base_dir                =  node.hive2.dir + "/hive-server" 
default.hive2.keystore                = "#{node.kagent.base_dir}/node_server_keystore.jks"
default.hive2.keystore_password       = node.hopsworks.master.password

default.hive2.mysql_user              = "hive"
default.hive2.mysql_password          = "hive"

default.hive2.pid_file                = "/tmp/hive.pid"
default.hive2.log                     = "#{node.hive2.base_dir}/hive.log"

default.hive2.systemd                 = "true"
