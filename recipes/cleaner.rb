template "/etc/environment_cleaner" do
  source "environment_cleaner.erb"
  owner "root"
  group "root"
  mode 0664
end


service_name="hivecleaner"
case node.platform_family
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
else
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
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

if node.kagent.enabled == "true"
  kagent_config service_name do
    service service_name
    log_file node.hive2.metastore.log
  end
end

