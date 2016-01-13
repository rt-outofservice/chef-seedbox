# Include library
class Chef::Recipe
  include Helper
end

# Disable firewall if exists
execute "echo y | ufw disable" do
  only_if { system 'which', 'ufw' }
end

# Reset firewall if required
if node['ufw']['reset'] == 'true'
  execute "echo y | ufw reset" do
    only_if { system 'which', 'ufw' }
  end
end

node.default['ip'] = get_default_ip
node.default['gateway'] = get_default_gw
node.default['subnet'] = calc_subnet(get_default_ip, get_default_netmask)

directory '/etc/cron.d' do
  action :create
  owner "root"
  group "root"
  mode '0764'
  not_if { File.directory?("/etc/cron.d") }
end

directory '/etc/network/if-down.d' do
  action :create
  owner "root"
  group "root"
  mode '0764'
  not_if { File.directory?("/etc/network/if-down.d") }
end

directory '/etc/network/if-up.d' do
  action :create
  owner "root"
  group "root"
  mode '0764'
  not_if { File.directory?("/etc/network/if-up.d") }
end

include_recipe 'seedbox::apt'
include_recipe 'seedbox::tools'
include_recipe 'seedbox::hostname'
include_recipe 'seedbox::timezone'
include_recipe 'seedbox::users'
include_recipe 'seedbox::ipv4-ipv6-settings'
include_recipe 'seedbox::fail2ban'

if node['openvpn']['client']['status'] == 'enable'
  include_recipe 'seedbox::openvpn-client'
  include_recipe 'seedbox::ip-routing'
end

if node['openvpn']['server']['status'] == 'enable'
  include_recipe 'seedbox::openvpn-server'
end

if node['share-server']['status'] == 'enable'
  include_recipe 'seedbox::ftp-server'
  include_recipe 'seedbox::nfs-server'
end

if node['transmission']['status'] == 'enable'
  include_recipe 'seedbox::transmission'
end

if node['sync-ftp-folders']['status'] == 'Y'
  include_recipe 'seedbox::syncing-and-backuping'
end

include_recipe 'seedbox::watchdogs'
include_recipe 'seedbox::ufw'


## LAUNCH SERVICES

# OpenVPN
if node['openvpn']['server']['status'] == 'enable' || node['openvpn']['client']['status'] == 'enable'
  service 'openvpn' do
    action [:start, :enable]
  end
  execute "echo '* * * * * root /usr/sbin/watchdogs/openvpn-watchdog.sh' >> /etc/cron.d/watchdogs"
else
  service 'openvpn' do
    action [:stop, :disable]
  end
end

# FTP/NFS-server
if node['share-server']['status'] == 'enable'
  service 'vsftpd' do
    action [:enable, :start]
  end
  service 'nfs-kernel-server' do
    action [:enable, :start]
  end
  execute "echo '* * * * * root /usr/sbin/watchdogs/vsftpd-watchdog.sh' >> /etc/cron.d/watchdogs"
  execute "echo '* * * * * root /usr/sbin/watchdogs/nfs-server-watchdog.sh' >> /etc/cron.d/watchdogs"
else
  service 'vsftpd' do
    action [:disable, :stop]
  end
  service 'nfs-kernel-server' do
    action [:disable, :stop]
  end
end

# Transmission
if node['transmission']['status'] == 'enable'
  service 'transmission-daemon' do
    action [:start, :enable]
  end
  service 'nginx' do
    action [:start, :enable]
  end
  execute "echo '* * * * * root /usr/sbin/watchdogs/transmission-watchdog.sh' >> /etc/cron.d/watchdogs"
  execute "echo '* * * * * root /usr/sbin/watchdogs/nginx-watchdog.sh' >> /etc/cron.d/watchdogs"
else
  service 'transmission-daemon' do
    action [:stop, :disable]
  end
  service 'nginx' do
    action [:stop, :disable]
  end
end

# Fail2ban
service 'fail2ban' do
    action [:start, :enable]
end

execute 'echo y | ufw enable'