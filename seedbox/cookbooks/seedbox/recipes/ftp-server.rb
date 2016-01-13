package 'vsftpd'

node.default['share-server']['ftp']['password_hash'] = gen_passwd_hash(node['share-server']['ftp']['password'])

user "#{node['share-server']['ftp']['username']}" do
  action :modify
  password "#{node['share-server']['ftp']['password_hash']}"
end

template '/etc/vsftpd.conf' do
  source 'ftp-server-config.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

execute "openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.key -out /etc/ssl/private/vsftpd.crt -subj '/C=RU/ST=Moscow/L=Moscow/O=SweetHome/CN=seedbox'"

## Add fail2ban jail
file '/var/log/vsftpd.log' do
  owner 'root'
  mode '644'
end

execute "printf '\n\n%s\n%s\n%s\n%s\n%s' '[vsftpd]' 'enabled = true' 'action = ufw' 'filter = vsftpd' 'logpath = /var/log/vsftpd.log' >> /etc/fail2ban/jail.local"

service 'vsftpd' do
  action :stop
end

# Add FTPS-server credentials to info-file
execute "printf '\n\n%s\n%s' '[FTP-server]' 'ftps://#{node['share-server']['ftp']['username']}:#{node['share-server']['ftp']['password']}@#{node['ip']}:#{node['share-server']['ftp']['port']}/' >> /tmp/credentials"