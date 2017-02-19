include_recipe "hops::wrap"

my_ip = my_private_ip()
nn_endpoint = private_recipe_ip("apache_hadoop", "nn") + ":#{node.apache_hadoop.nn.port}"

zk_ips = private_recipe_ips('kzookeeper', 'default')
zk_endpoints = zk_ips.join(",")

mysql_endpoint = private_recipe_ip("ndb", "mysqld") + ":#{node.ndb.mysql_port}"

metastore_ip = private_recipe_ip("hive2", "metastore")

case node.platform
when "ubuntu"
  if node.platform_version.to_f <= 14.04
    node.override.hive2.systemd = "false"
  end
end

home = "/user/" + node.hive2.user

magic_shell_environment 'HADOOP_HOME' do
  value "#{node.apache_hadoop.base_dir}"
end

magic_shell_environment 'HIVE_HOME' do
  value "#{node.hive2.base_dir}"
end

magic_shell_environment 'PATH' do
  value "$PATH:#{node.apache_hadoop.base_dir}/bin:#{node.hive2.base_dir}/bin"
end


cookbook_file "#{node.hive2.base_dir}/lib/mysql-connector-java-5.1.40-bin.jar" do
  source "mysql-connector-java-5.1.40-bin.jar"
  owner node.hive2.user
  group node.apache_hadoop.group
  mode "0644"
end

hive_dir="#{home}/#{node.hive2.user}/hive"
#tmp_dirs   = [ hive_dir, hive_dir + "/warehouse", "/wlslog" ]
tmp_dirs   = [ hive_dir, hive_dir + "/warehouse" ]
for d in tmp_dirs
  apache_hadoop_hdfs_directory d do
    action :create_as_superuser
    owner node.hive2.user
    group node.hive2.group
    mode "1770"
    not_if ". #{node.apache_hadoop.home}/sbin/set-env.sh && #{node.apache_hadoop.home}/bin/hdfs dfs -test -d #{d}"
  end
end

file "#{node.hive2.base_dir}/conf/hive-site.xml" do
  action :delete
end

template "#{node.hive2.base_dir}/conf/hive-site.xml" do
  source "hive-site.xml.erb"
  owner node.hive2.user
  group node.hive2.group
  mode 0655
  variables({ 
              :private_ip => my_ip,
              :nn_endpoint => nn_endpoint,
              :mysql_endpoint => mysql_endpoint,
              :metastore_ip => metastore_ip,
              :zk_endpoints => zk_endpoints        
            })
end


file "#{node.hive2.base_dir}/conf/hive-env.sh.erb" do
  action :delete
end

template "#{node.hive2.base_dir}/conf/hive-env.sh" do
  source "hive-env.sh.erb"
  owner node.hive2.user
  group node.hive2.group
  mode 0655
end


hive_downloaded = node.hive2.base_dir + "/.hive_setup"
bash 'setup-hive' do
  user "root"
  group node.hive2.group
  code <<-EOH
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"CREATE USER '#{node.hive2.mysql_user}'@'localhost' IDENTIFIED BY '#{node.hive2.mysql_password}'\"
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"REVOKE ALL PRIVILEGES, GRANT OPTION FROM '#{node.hive2.mysql_user}'@'localhost'\"
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"CREATE DATABASE IF NOT EXISTS metastore CHARACTER SET latin1\"
        #{node.ndb.scripts_dir}/mysql-client.sh metastore -e \"SOURCE #{node.hive2.base_dir}/scripts/metastore/upgrade/mysql/hive-schema-2.2.0.mysql.sql\"
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE ON metastore.* TO '#{node.hive2.mysql_user}'@'localhost'\"
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"FLUSH PRIVILEGES\"
#       #{node.hive2.base_dir}/bin/schematool -dbType mysql -initSchema
        EOH
  not_if "#{node.ndb.scripts_dir}/mysql-client.sh -e \"SHOW DATABASES\" | grep metastore|"
end
