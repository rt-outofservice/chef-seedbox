file '/etc/timezone' do
  content "#{node['timezone']}"
end

execute 'dpkg-reconfigure -f noninteractive tzdata'