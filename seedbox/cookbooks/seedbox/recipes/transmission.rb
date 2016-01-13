package 'transmission-daemon'

package 'nginx' do
  action :install
  ignore_failure true
end

service 'transmission-daemon' do
  action :stop
end

service 'nginx' do
  action :stop
end

file '/etc/nginx/sites-enabled/default' do
  action :delete
end

directory "/home/#{node['share-server']['ftp']['username']}/downloads" do
  action :create
  owner "#{node['share-server']['ftp']['username']}"
  group "#{node['share-server']['ftp']['username']}"
  mode '0764'
  not_if { File.directory?("/home/#{node['share-server']['ftp']['username']}/downloads") }
end

directory "/home/#{node['share-server']['ftp']['username']}/torrents" do
  action :create
  owner "#{node['share-server']['ftp']['username']}"
  group "#{node['share-server']['ftp']['username']}"
  mode '0764'
  not_if { File.directory?("/home/#{node['share-server']['ftp']['username']}/torrents") }
end

execute "mkdir -p /home/#{node['share-server']['ftp']['username']}/.config/transmission-daemon/resume; mkdir -p /home/#{node['share-server']['ftp']['username']}/.config/transmission-daemon/torrents; chown -R #{node['share-server']['ftp']['username']}:#{node['share-server']['ftp']['username']} /home/#{node['share-server']['ftp']['username']}"

directory '/var/lib/transmission-daemon' do
  action :delete
  recursive true
end

file '/etc/transmission-daemon/settings.json' do
  action :delete
end

template "/home/#{node['share-server']['ftp']['username']}/.config/transmission-daemon/settings.json" do
  source 'transmission-settings.erb'
  owner "#{node['share-server']['ftp']['username']}"
  group "#{node['share-server']['ftp']['username']}"
  mode '0664'
end

user 'debian-transmission' do
  action :remove
end

link '/etc/transmission-daemon/settings.json' do
  to "/home/#{node['share-server']['ftp']['username']}/.config/transmission-daemon/settings.json"
  owner "#{node['share-server']['ftp']['username']}"
end

template '/lib/systemd/system/transmission-daemon.service' do
  source 'transmission-systemd.erb'
  mode '644'
end

execute 'ReloadSystemD' do
  command 'systemctl daemon-reload'
end

execute "echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf" do
  not_if "cat /etc/sysctl.conf | grep -E '^net.core.rmem_max = 16777216'"
end

execute "echo 'net.core.wmem_max = 4194304' >> /etc/sysctl.conf" do
  not_if "cat /etc/sysctl.conf | grep -E '^net.core.wmem_max = 4194304'"
end

execute 'sysctl -p' do
  ignore_failure true
end

## Configure nginx as reverse proxy
template '/etc/nginx/sites-available/transmission' do
  source 'nginx-transmission-host.erb'
  mode '644'
end

execute "openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/transmission.key -out /etc/ssl/private/transmission.crt -subj '/C=RU/ST=Moscow/L=Moscow/O=SweetHome/CN=seedbox'"

link '/etc/nginx/sites-enabled/transmission' do
  to '/etc/nginx/sites-available/transmission'
end

## Add fail2ban jail

directory "/var/log/nginx" do
  action :create
  owner "www-data"
  group "adm"
  mode '0740'
  not_if { File.directory?("/var/log/nginx") }
end

file '/var/log/nginx/transmission_access.log' do
  owner 'root'
  mode '644'
end

execute "printf '\n\n%s\n%s\n%s\n%s\n%s' '[nginx-401]' 'enabled = true' 'action = ufw' 'filter = nginx-401' 'logpath = /var/log/nginx/transmission_access.log' >> /etc/fail2ban/jail.local"

# Add transmission credentials to info-file
execute "printf '\n\n%s\n%s' '[Transmission]' 'https://transmission:#{node['transmission']['password']}@#{node['ip']}/transmission/web' >> /tmp/credentials"
