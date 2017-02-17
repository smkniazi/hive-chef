default.livy.user                    = node.hadoop_spark.user
default.livy.group                   = node.hadoop_spark.group

default.livy.version                 = "0.3.0-SNAPSHOT"
default.livy.url                     = "#{node.download_url}/livy-server-#{node.livy.version}.zip"
default.livy.port                    = "8998"
default.livy.dir                     = "/srv"
default.livy.home                    =  node.livy.dir + "/livy-server-" + node.livy.version
default.livy.base_dir                =  node.livy.dir + "/livy-server" 
default.livy.keystore                = "#{node.kagent.base_dir}/node_server_keystore.jks"
default.livy.keystore_password       = node.hopsworks.master.password

default.livy.pid_file                = "/tmp/livy.pid"
default.livy.log                     = "#{node.livy.base_dir}/livy.log"

default.livy.systemd                 = "true"
