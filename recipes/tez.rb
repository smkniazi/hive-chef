# Create configuration file
template "#{node.tez.conf_dir}/tez-site.xml" do
  source "tez-site.xml.erb"
  owner node.tez.user
  group node.tez.group
  mode 0655
end

# Set environment variables
magic_shell_environment 'TEZ_CONF_DIR' do
  value "#{node.tez.conf_dir}"
end

magic_shell_environment 'TEZ_JARS' do
  value "#{node.tez.base_dir}"
end

magic_shell_environment 'HADOOP_CLASSPATH' do
  value "$HADOOP_CLASSPATH:$TEZ_CONF_DIR:$TEZ_JARS/*:$TEZ_JARS/lib/*"
end

