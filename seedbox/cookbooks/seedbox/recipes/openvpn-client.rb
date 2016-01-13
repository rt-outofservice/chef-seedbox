package 'openvpn'

service 'openvpn' do
  action :stop
end

# OpenVPN certs and keys supply
template '/etc/openvpn/seedbox.conf' do
  source 'openvpn/client-configuration/seedbox.ovpn'
  owner 'root'
  group 'root'
  mode '0600'
end

template '/etc/openvpn/ca.crt' do
  source 'openvpn/client-configuration/ca.crt'
  owner 'root'
  group 'root'
  mode '0600'
end

template '/etc/openvpn/seedbox.crt' do
  source 'openvpn/client-configuration/seedbox.crt'
  owner 'root'
  group 'root'
  mode '0600'
end

template '/etc/openvpn/seedbox.key' do
  source 'openvpn/client-configuration/seedbox.key'
  owner 'root'
  group 'root'
  mode '0600'
end

template '/etc/openvpn/ta.key' do
  source 'openvpn/client-configuration/ta.key'
  owner 'root'
  group 'root'
  mode '0600'
end

# Add OpenVPN-client credentials to info-file
execute "printf \"\n\n%s\n%s\n%s\" \"[OpenVPN-client]\" \"Enabled.\" \"Connected to $(grep -oE 'remote.+' /etc/openvpn/seedbox.conf | awk '{ print $2}')\" >> /tmp/credentials"