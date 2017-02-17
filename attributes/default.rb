default.hive.user                    = node.apache_hadoop.user
default.hive.group                   = node.apache_hadoop.group

# apache-hive-2.2.0-SNAPSHOT-bin.tar.gz
default.hive.version                 = "2.2.0-SNAPSHOT"
default.hive.url                     = "#{node.download_url}/apache-hive-#{node.hive.version}-bin.tar.gz"
default.hive.port                    = "2222"
default.hive.dir                     = "/srv"
default.hive.home                    =  node.hive.dir + "/hive-server-" + node.hive.version
default.hive.base_dir                =  node.hive.dir + "/hive-server" 
default.hive.keystore                = "#{node.kagent.base_dir}/node_server_keystore.jks"
default.hive.keystore_password       = node.hopsworks.master.password

default.hive.pid_file                = "/tmp/hive.pid"
default.hive.log                     = "#{node.hive.base_dir}/hive.log"

default.hive.systemd                 = "true"
