template "/etc/network/if-down.d/routes" do
  source 'routes.erb'
  owner "root"
  group "root"
  mode '0764'
end

template "/etc/network/if-up.d/routes" do
  source 'routes.erb'
  owner "root"
  group "root"
  mode '0764'
end

execute '/etc/network/if-up.d/routes'