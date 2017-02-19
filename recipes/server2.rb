include_recipe "hive2::_configure"


template "#{node.hive2.base_dir}/bin/start-hiveserver2.sh" do
  source "start-hiveserver2.sh.erb"
  owner node.hive2.user
  group node.hive2.group
  mode 0751
end

template "#{node.hive2.base_dir}/bin/stop-hiveserver2.sh" do
  source "stop-hiveserver2.sh.erb"
  owner node.hive2.user
  group node.hive2.group
  mode 0751
end

service_name="hiveserver2"

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
    log_file node.hive2.server2.log
  end
end

