template "#{node.hive2.base_dir}/bin/start-hivecleaner.sh" do
  source "start-hivecleaner.sh.erb"
  owner node.hops.hdfs.user
  group node.hops.group
  mode 0751
end

template "#{node.hive2.base_dir}/bin/stop-hivecleaner.sh" do
  source "stop-hivecleaner.sh.erb"
  owner node.hops.hdfs.user
  group node.hops.group
  mode 0751
end

service_name="hivecleaner"

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
    log_file node.hive2.metastore.log
  end
end

