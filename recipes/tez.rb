
template "#{node.tez.base_dir}/conf/tez-site.xml" do
  source "tez-site.xml.erb"
  owner node.tez.user
  group node.tez.group
  mode 0655
end


