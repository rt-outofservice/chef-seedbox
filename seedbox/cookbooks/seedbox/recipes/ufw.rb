package 'ufw'

node.default['net-interface'] = get_default_int

## DISABLE
execute 'echo y | ufw disable'

## SET DEFAULT POLICY
execute 'IPv6Disable' do
  command "grep -q '^IPV6=\w*$' /etc/default/ufw && sed -ie 's/^IPV6=yes$/IPV6=no/' /etc/default/ufw || echo 'IPV6=no' >> /etc/default/ufw"
end

execute 'SetInputPolicy' do
  command "grep -q '^DEFAULT_INPUT_POLICY=\w*$' /etc/default/ufw && sed -ie 's/^DEFAULT_INPUT_POLICY=\w*$/DEFAULT_INPUT_POLICY=DROP/' /etc/default/ufw || echo 'DEFAULT_INPUT_POLICY=DROP' >> /etc/default/ufw"
end

execute 'SetOutputPolicy' do
  command "grep -q '^DEFAULT_OUTPUT_POLICY=\w*$' /etc/default/ufw && sed -ie 's/^DEFAULT_OUTPUT_POLICY=\w*$/DEFAULT_OUTPUT_POLICY=DROP/' /etc/default/ufw || echo 'DEFAULT_OUTPUT_POLICY=DROP' >> /etc/default/ufw"
end

execute 'SetForwardPolicy' do
  command "grep -q '^DEFAULT_FORWARD_POLICY=\w*$' /etc/default/ufw && sed -ie 's/^DEFAULT_FORWARD_POLICY=\w*$/DEFAULT_FORWARD_POLICY=ACCEPT/' /etc/default/ufw || echo 'DEFAULT_FORWARD_POLICY=ACCEPT' >> /etc/default/ufw"
end


## SET BEFORE RULES
execute 'RemoveCommit' do
  command "sed -ie '/COMMIT/d' /etc/ufw/before.rules"
end

execute 'AllowOutboundICMP' do
  command "printf '\n%s\n%s\n%s\n' '-A ufw-before-output -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT' '-A ufw-before-output -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT' 'COMMIT' >> /etc/ufw/before.rules"
  not_if "grep '-A ufw-before-output -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT' /etc/ufw/before.rules"
end

execute 'EnableMasquerading' do
  command "printf '\n%s\n%s\n%s\n' '*nat' ':POSTROUTING ACCEPT [0:0]' '-A POSTROUTING -s #{node['openvpn']['server']['client-subnet']} -o #{node['net-interface']} -j MASQUERADE' >> /etc/ufw/before.rules"
  not_if "grep '-A POSTROUTING -s #{node['openvpn']['server']['client-subnet']} -o #{node['net-interface']} -j MASQUERADE' /etc/ufw/before.rules"
end

execute 'AddCommit' do
  command "echo 'COMMIT' >> /etc/ufw/before.rules"
end


## SET RULES 

# APT
execute 'ufw allow out http'
execute 'ufw allow out https'
execute 'ufw allow out 53'

# GIT
execute 'ufw allow out git'

# SSH
execute "ufw allow #{node['ssh']['port']}/tcp"

# OpenVPN-server
if node['openvpn']['server']['status'] == 'enable'
  execute "ufw allow #{node['openvpn']['server']['port']}/udp"
  execute 'ufw allow out on tun0'
  execute 'ufw allow in on tun0'
end

# OpenVPN-client
if node['openvpn']['client']['status'] == 'enable'
  execute "ufw allow out #{node['openvpn']['client']['server-port']}/udp"
  execute 'ufw allow out on tun0'
  execute 'ufw allow in on tun0'
end

# Transmission
if node['transmission']['status'] == 'enable'
  if node['transmission']['available-from-internet'] == 'Y'
    execute "ufw allow https"
  end
end

# FTP-server
if node['share-server']['status'] == 'enable'
  if node['share-server']['ftp']['available-from-internet'] == 'Y'
    execute "ufw allow #{node['share-server']['ftp']['port']}/tcp"
    execute "ufw allow 11000:11010/tcp"
  end
end