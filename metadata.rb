name             "hive"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2"
description      'Installs/Configures Hive Server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"
source_url       "https://github.com/hopshadoop/hive-chef"



depends          "hadoop_spark"
depends          "ndb"
depends          "hops"
depends          "apache_hadoop"
depends          "kagent"
depends          "java"

recipe           "install", "Installs a Hive2 Server"
recipe           "default", "Starts  a Hive  Server"
recipe           "purge", "Removes and deletes an installed Hive Server"

attribute "java/jdk_version",
          :description =>  "Jdk version",
          :type => 'string'

attribute "java/install_flavor",
          :description =>  "Oracle (default) or openjdk",
          :type => 'string'

attribute "hive/user",
          :description => "User to install/run as",
          :type => 'string'

attribute "hive/dir",
          :description => "base dir for installation",
          :type => 'string'

attribute "hive/version",
          :dscription => "hive.version",
          :type => "string"

attribute "hive/url",
          :dscription => "hive.url",
          :type => "string"

attribute "hive/port",
          :dscription => "hive.port",
          :type => "string"

attribute "hive/home",
          :dscription => "hive.home",
          :type => "string"

attribute "hive/keystore",
          :dscription => "ivy.keystore",
          :type => "string"

attribute "hive/keystore_password",
          :dscription => "ivy.keystore_password",
          :type => "string"

attribute "hive/default/private_ips",
          :description => "Set ip addresses",
          :type => "array"

