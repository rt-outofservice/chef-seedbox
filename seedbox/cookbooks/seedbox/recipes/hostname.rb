execute "sed -ie \"s/$(cat /etc/hostname)/#{node['new-hostname']}/\" /etc/hosts"
execute "echo '#{node['new-hostname']}' > /etc/hostname"

# Add new hostname to info-file
execute "printf '\n\n%s\n%s' '[Hostname]' '#{node['new-hostname']}' >> /tmp/credentials"