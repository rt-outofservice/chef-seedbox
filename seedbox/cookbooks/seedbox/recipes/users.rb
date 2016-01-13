chef_gem "ruby-shadow" do
  compile_time false
end

chef_gem "rubysl-securerandom" do
  compile_time false
end

## ssh user ##
user 'rt' do
  supports :manage_home => true
  home '/home/rt'
  shell '/bin/bash'
  uid '9000'
  password SecureRandom.urlsafe_base64
  not_if "grep -E '^rt:' /etc/passwd"
end

directory '/home/rt/.ssh' do
  owner 'rt'
  group 'rt'
  mode '0700'
  action :create
end

package 'sudo'

group 'sudo' do
  action :modify
  members 'rt'
  append true
end

execute 'SudoNoPassowrd' do
  command "echo '%sudo   ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/nopasswd; chmod 0444 /etc/sudoers.d/nopasswd; chown root:root /etc/sudoers.d/nopasswd"
  not_if "grep '%sudo   ALL=(ALL:ALL) NOPASSWD:ALL' /etc/sudoers.d/nopasswd"
end

execute "AddPublicKey" do
  command "echo #{node['ssh']['public_key']} >> /home/rt/.ssh/authorized_keys; chmod 600 /home/rt/.ssh/authorized_keys; chown rt:rt /home/rt/.ssh/authorized_keys"
  not_if "grep #{node['ssh']['public_key']} /home/rt/.ssh/authorized_keys"
end

# Add ssh credentials to info-file
execute "printf '\n\n%s\n%s' '[SSH-server]' 'ssh -p #{node['ssh']['port']} rt@#{node['ip']}' >> /tmp/credentials"
## ------ ##

## ftp/nfs users ##
user "#{node['share-server']['ftp']['username']}" do
  supports :manage_home => true
  home "/home/#{node['share-server']['ftp']['username']}"
  shell '/bin/bash'
  uid '9010'
  password SecureRandom.urlsafe_base64
  not_if "grep -E '^#{node['share-server']['ftp']['username']}:' /etc/passwd"
end

directory "/home/#{node['share-server']['ftp']['username']}/.ssh" do
  owner "#{node['share-server']['ftp']['username']}"
  group "#{node['share-server']['ftp']['username']}"
  mode '0700'
  action :create
end

execute "AddPublicKey" do
  command "echo #{node['ssh']['public_key']} >> /home/#{node['share-server']['ftp']['username']}/.ssh/authorized_keys; chmod 600 /home/#{node['share-server']['ftp']['username']}/.ssh/authorized_keys; chown #{node['share-server']['ftp']['username']}:#{node['share-server']['ftp']['username']} /home/#{node['share-server']['ftp']['username']}/.ssh/authorized_keys"
  not_if "grep #{node['ssh']['public_key']} /home/#{node['share-server']['ftp']['username']}/.ssh/authorized_keys"
end

## duplicity user ##
user 'duplicity' do
  supports :manage_home => true
  home '/home/duplicity'
  shell '/bin/bash'
  uid '9015'
  password SecureRandom.urlsafe_base64
  not_if "grep -E '^duplicity:' /etc/passwd"
end

directory '/home/duplicity/.ssh' do
  owner 'duplicity'
  group 'duplicity'
  mode '0700'
  action :create
end

execute "AddPublicKey" do
  command "echo #{node['ssh']['public_key']} >> /home/duplicity/.ssh/authorized_keys; chmod 600 /home/duplicity/.ssh/authorized_keys; chown duplicity:duplicity /home/duplicity/.ssh/authorized_keys"
  not_if "grep #{node['ssh']['public_key']} /home/duplicity/.ssh/authorized_keys"
end

## ------ ##

template '/etc/ssh/sshd_config' do
  source 'sshd-config.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

user 'root' do
  action :modify
  password SecureRandom.urlsafe_base64
end

service 'ssh' do
  action :restart
end