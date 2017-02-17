
include_recipe "hops::wrap"

my_ip = my_private_ip()
nn_endpoint = private_recipe_ip("apache_hadoop", "nn") + ":#{node.apache_hadoop.nn.port}"
home = node.apache_hadoop.hdfs.user_home


hive_dir="#{home}/#{node.hive.user}/hive"
apache_hadoop_hdfs_directory "#{hive_dir}" do
  action :create_as_superuser
  owner node.hive.user
  group node.apache_hadoop.group
  mode "1770"
  not_if ". #{node.apache_hadoop.home}/sbin/set-env.sh && #{node.apache_hadoop.home}/bin/hdfs dfs -test -d #{hive_dir}"
end

tmp_dirs   = [ hive_dir, "#{hive_dir}/rsc-jars", "#{hive_dir}/rpl-jars" ] 
for d in tmp_dirs
 apache_hadoop_hdfs_directory d do
    action :create
    owner node.hive.user
    group node.apache_hadoop.group
    mode "1777"
    not_if ". #{node.apache_hadoop.home}/sbin/set-env.sh && #{node.apache_hadoop.home}/bin/hdfs dfs -test -d #{d}"
  end
end

file "#{node.hive.base_dir}/conf/hive." do
 action :delete
end

template "#{node.hive.base_dir}/conf/hive.conf" do
  source "hive.conf.erb"
  owner node.hive.user
  group node.hive.group
  mode 0655
  variables({ 
        :private_ip => my_ip,
        :nn_endpoint => nn_endpoint
           })
end


file "#{node.hive.base_dir}/conf/hive-env.sh.erb" do
 action :delete
end

template "#{node.hive.base_dir}/conf/hive-env.sh" do
  source "hive-env.sh.erb"
  owner node.hive.user
  group node.hive.group
  mode 0655
end

template "#{node.hive.base_dir}/bin/start-hive.sh" do
  source "start-hive.sh.erb"
  owner node.hive.user
  group node.hive.group
  mode 0751
end

template "#{node.hive.base_dir}/bin/stop-hive.sh" do
  source "stop-hive.sh.erb"
  owner node.hive.user
  group node.hive.group
  mode 0751
end



case node.platform
when "ubuntu"
 if node.platform_version.to_f <= 14.04
   node.override.hive.systemd = "false"
 end
end


service_name="hive"

if node.hive.systemd == "true"

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
     log_file node.hive.log
   end
end


# hive_restart "restart-hive-needed" do
#   action :restart
# end
