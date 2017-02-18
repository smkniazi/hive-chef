
include_recipe "hops::wrap"

my_ip = my_private_ip()
nn_endpoint = private_recipe_ip("apache_hadoop", "nn") + ":#{node.apache_hadoop.nn.port}"

zk_ips = private_recipe_ips('kzookeeper', 'default')
zk_endpoints = zk_ips.join(",")


home = node.apache_hadoop.hdfs.user_home

zk_endpoint = private_recipe_ip("zookeeper", "nn") + ":#{node.apache_hadoop.nn.port}"

magic_shell_environment 'HADOOP_HOME' do
  value "#{node.apache_hadoop.base_dir}"
end

magic_shell_environment 'HIVE_HOME' do
  value "#{node.hive2.base_dir}"
end

magic_shell_environment 'PATH' do
  value "$PATH:#{node.apache_hadoop.base_dir}/bin"
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
    owner node.apache_hadoop.yarn.user
    group node.apache_hadoop.group
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
        :zk_endpoints => zk_endpoints        
           })
end


file "#{node.hive.base_dir}/conf/hive-env.sh.erb" do
 action :delete
end

template "#{node.hive.base_dir}/conf/hive-env.sh" do
  source "hive-env.sh.erb"
  owner node.hive2.user
  group node.hive2.group
  mode 0655
end

template "#{node.hive.base_dir}/bin/start-hive.sh" do
  source "start-hive.sh.erb"
  owner node.hive2.user
  group node.hive2.group
  mode 0751
end

template "#{node.hive.base_dir}/bin/stop-hive.sh" do
  source "stop-hive.sh.erb"
  owner node.hive2.user
  group node.hive2.group
  mode 0751
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
     not_if "#{node.ndb.scripts_dir}/mysql-client.sh -e \"SHOW DATABASES\" | grep metastore|
end




case node.platform
when "ubuntu"
 if node.platform_version.to_f <= 14.04
   node.override.hive2.systemd = "false"
 end
end


service_name="hive"

if node.hive2.systemd == "true"

  service service_name do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  case node.platform_family
  when "rhel"
    systemd_script = "/usr/lib/systemd/system/#{service_name}.service" 
  else
    systemd_script = "/lib/systemd/system/#{service_name}.service"
  end

  template systemd_script do
    source "#{service_name}.service.erb"
    owner "root"
    group "root"
    mode 0754
if node.services.enabled == "true"
    notifies :enable, resources(:service => service_name)
end
    notifies :start, resources(:service => service_name), :immediately
  end

  kagent_config "reload_#{service_name}" do
    action :systemd_reload
  end  

else #sysv

  service service_name do
    provider Chef::Provider::Service::Init::Debian
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  template "/etc/init.d/#{service_name}" do
    source "#{service_name}.erb"
    owner "root"
    group "root"
    mode 0754
if node.services.enabled == "true"
    notifies :enable, resources(:service => service_name)
end
    notifies :start, resources(:service => service_name), :immediately
  end

end


if node.kagent.enabled == "true" 
   kagent_config service_name do
     service service_name
     log_file node.hive2.log
   end
end




#CREATE EXTERNAL TABLE wlslog(time_stamp STRING, category STRING, type STRING, servername STRING, code STRING, msg STRING)
#ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' STORED AS TEXTFILE LOCATION 'hdfs://${nn_endpoint}/wlslog';

# hive_restart "restart-hive-needed" do
#   action :restart
# end
