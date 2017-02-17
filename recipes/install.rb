include_recipe "java"

include_recipe "hops::wrap"

my_ip = my_private_ip()

group node.hive.group do
  action :create
  not_if "getent group #{node.hive.group}"
end

user node.hive.user do
  home "/home/#{node.hive.user}"
  action :create
  system true
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node.hive.user}"
end

group node.hive.group do
  action :modify
  members ["#{node.hive.user}"]
  append true
end


package_url = "#{node.hive.url}"
base_package_filename = File.basename(package_url)
cached_package_filename = "/tmp/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "#{node.hive.user}"
  mode "0644"
  action :create_if_missing
end

# Extract Hive
hive_downloaded = "#{node.hive.home}/.hive_extracted_#{node.hive.version}"

bash 'extract-hive' do
        user "root"
        group node.hive.group
        code <<-EOH
                set -e
                tar zxf #{cached_package_filename} -d /tmp
                mv /tmp/hive-server-#{node.hive.version} #{node.hive.dir}
                # remove old symbolic link, if any
                rm -f #{node.hive.base_dir}
                ln -s #{node.hive.home} #{node.hive.base_dir}
                chown -R #{node.hive.user}:#{node.hive.group} #{node.hive.home}
                chown -R #{node.hive.user}:#{node.hive.group} #{node.hive.base_dir}
                touch #{hive_downloaded}
                chown -R #{node.hive.user}:#{node.hive.group} #{hive_downloaded}
        EOH
     not_if { ::File.exists?( "#{hive_downloaded}" ) }
end



