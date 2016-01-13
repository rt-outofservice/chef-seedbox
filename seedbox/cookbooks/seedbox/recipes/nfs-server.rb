package 'nfs-kernel-server'
package 'nfs-common'

file '/etc/exports' do
  content "/home/#{node['share-server']['ftp']['username']}   #{node['openvpn']['server']['client-subnet']}(rw,all_squash,anonuid=9010,anongid=9010,async,insecure,no_subtree_check)"
end

execute 'SetNFSStatDPort' do
  command "grep -q '^STATDOPTS=.*$' /etc/default/nfs-common && sed -ie 's/^STATDOPTS=.*$/STATDOPTS=\"--port 4000\"/' /etc/default/nfs-common || echo 'STATDOPTS=\"--port 4000\"' >> /etc/default/nfs-common"
end

execute 'SetNFSMountDPort' do
  command "grep -q '^RPCMOUNTDOPTS=.*$' /etc/default/nfs-kernel-server && sed -ie 's/^RPCMOUNTDOPTS=.*$/RPCMOUNTDOPTS=\"--manage-gids -p 4002\"/' /etc/default/nfs-kernel-server || echo 'RPCMOUNTDOPTS=\"--manage-gids -p 4002\"' >> /etc/default/nfs-kernel-server"
end

file '/etc/modprobe.d/options.conf' do
  content 'options lockd nlm_udpport=4001 nlm_tcpport=4001'
end

service 'nfs-kernel-server' do
  action :stop
end 

# Add NFS-server credentials to info-file
execute "printf '\n\n%s\n%s' '[NFS-server]' 'Enabled. Available only through OpenVPN' >> /tmp/credentials"