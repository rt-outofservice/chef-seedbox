directory '/usr/sbin/watchdogs' do
  action :create
  not_if { File.directory?('/usr/sbin/watchdogs') }
end

template '/usr/sbin/watchdogs/fail2ban-watchdog.sh' do
  source 'watchdogs/fail2ban-watchdog.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

template '/usr/sbin/watchdogs/nfs-server-watchdog.sh' do
  source 'watchdogs/nfs-server-watchdog.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

template '/usr/sbin/watchdogs/nginx-watchdog.sh' do
  source 'watchdogs/nginx-watchdog.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

template '/usr/sbin/watchdogs/openvpn-watchdog.sh' do
  source 'watchdogs/openvpn-watchdog.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

template '/usr/sbin/watchdogs/transmission-watchdog.sh' do
  source 'watchdogs/transmission-watchdog.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

template '/usr/sbin/watchdogs/vsftpd-watchdog.sh' do
  source 'watchdogs/vsftpd-watchdog.erb'
  owner 'root'
  group 'root'
  mode '0744'
end