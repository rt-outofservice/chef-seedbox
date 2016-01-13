## SPLIT CIDR NETWORK FROM ATTRIBUTES TO IP AND SUBNET
node.default['openvpn']['server']['client-ip'] = get_addr(node['openvpn']['server']['client-subnet'])['ip']
node.default['openvpn']['server']['client-mask'] = get_addr(node['openvpn']['server']['client-subnet'])['mask']

node.default['openvpn']['client']['server-ip'] = get_default_ip

## INSTALL PACKAGES
package 'openvpn'

service 'openvpn' do
  action :stop
end

package 'easy-rsa' do
  ignore_failure true
end


## OPENVPN SERVER CONFIGURAITON
template '/etc/openvpn/server.conf' do
  source 'openvpn-server-config.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/openvpn/client.ovpn' do
  source 'openvpn-client-config.erb'
  owner 'root'
  group 'root'
  mode '0644'
end


## GENERATE CERTIFICATES AND CONFIGURATIONS FOR CLIENTS
directory '/etc/openvpn/ccd' do
  action :create
  not_if { File.directory?('/etc/openvpn/ccd') }
end

execute 'rm -rf /etc/openvpn/ccd/*'
execute 'rm -rf /home/rt/*'

template '/tmp/certificates.sh' do
  source 'openvpn-certificates.sh'
  owner 'root'
  group 'root'
  mode '0744'
end

# Create client configuration files to provide static IP-addresses and generate certificates
ruby_block 'CreateClientsConfFiles' do
  block do
    clients = ''
    node['openvpn']['server']['certificates']['vpn-clients'].each_pair do |key, value|
      clients = clients + key.to_s + ','

      if value != ''
        File.open("/etc/openvpn/ccd/#{key}", 'w') {|file| file.write("ifconfig-push #{value} 255.255.255.255\n"+";topology subnet\n"+";push \"topology subnet\"\\\n")}
      end
    end
    system("/tmp/certificates.sh --country=#{node['openvpn']['server']['certificates']['country']} --province=#{node['openvpn']['server']['certificates']['province']} --city=#{node['openvpn']['server']['certificates']['city']} --org=#{node['openvpn']['server']['certificates']['org']} --email=#{node['openvpn']['server']['certificates']['email']} --server-name=#{node['openvpn']['server']['certificates']['server-name']} --client-name=#{clients}")
  end
end

# Add OpenVPN-server credentials to info-file
execute "printf '\n\n%s\n%s\n%s\n%s' '[OpenVPN-server]' 'Enabled.' 'To download client credentials run:' 'scp -P #{node['ssh']['port']} -r rt@#{node['ip']}:/home/rt/* ~/Downloads/; ssh -p #{node['ssh']['port']} rt@#{node['ip']} \"rm -rf /home/rt/*\"' >> /tmp/credentials"