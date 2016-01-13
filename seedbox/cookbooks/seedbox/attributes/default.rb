### CONSTANTS ###
default['timezone'] = 'Europe/Warsaw'

default['ssh']['port'] = '2235'
default['ssh']['public_key'] = ''

default['openvpn']['server']['port'] = '1300'
default['openvpn']['server']['client-subnet'] = '172.16.0.0/24'
default['openvpn']['client']['server-port'] = '1300'

default['share-server']['ftp']['port'] = '2021'
default['share-server']['ftp']['username'] = 'share'

default['ufw']['reset'] = 'true' # at the beginning reset all firewall rules if exist


#################


# HOSTNAME
default['new-hostname'] = 'vpn1-public'


## TRANSMISSION CONFIGURATION
default['transmission']['password'] = ''
default['transmission']['available-from-internet'] = 'Y'


## FTP/NFS-server
default['share-server']['ftp']['password'] = ''
default['share-server']['ftp']['available-from-internet'] = 'Y'


## OPENVPN SERVER CONFIGURATION
default['openvpn']['server']['certificates'] = {
  'country'     => 'PL',
  'province'    => 'Warsaw',
  'city'        => 'Warsaw',
  'org'         => 'SweetHome',
  'email'       => 'email@anonymous.com',
  'server-name' => 'server',
  'vpn-clients' => {'seedbox'  => '172.16.0.5'}}


## SYNCING AND BACKUPING FTP FOLDERS (REMOTE TO LOCAL)
# enable mirroring remote ftp-servers to /home/share/
default['sync-ftp-folders']['status'] = 'N'
default['sync-ftp-folders']['remote-credentials'] = [
 {'host'       => '',
  'port'       => '2021',
  'username'   => 'share',
  'password'   => ''}]

# enable local incremental backup of /home/share/* to /home/duplicity
default['backup-shared-folder']['status'] = 'N'


## STATUS OF SERVICES
# The node can act as vpn-server or vpn-client but not both
default['openvpn']['server']['status'] = 'enable'
default['openvpn']['client']['status'] = 'disable'

default['transmission']['status']      = 'enable'
default['share-server']['status']      = 'enable'