service 'fail2ban' do
    action :stop
end

template '/etc/fail2ban/jail.local' do
  source 'fail2ban-jails.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

execute 'ChangeAcionBanCommand' do
  command "grep -q '^actionban = .*$' /etc/fail2ban/action.d/ufw.conf && sed -ie 's/^actionban = .*$/actionban = ufw insert 1 deny from <ip> to any/' /etc/fail2ban/action.d/ufw.conf || echo 'actionban = ufw insert 1 deny from <ip> to any' >> /etc/fail2ban/action.d/ufw.conf"
end

execute 'ChangeAcionUnbanCommand' do
  command "grep -q '^actionunban = .*$' /etc/fail2ban/action.d/ufw.conf && sed -ie 's/^actionunban = .*$/actionunban = ufw delete deny from <ip> to any/' /etc/fail2ban/action.d/ufw.conf || echo 'actionunban = ufw delete deny from <ip> to any' >> /etc/fail2ban/action.d/ufw.conf"
end

execute "printf '%s\n%s' '[Definition]' 'failregex = <HOST> - .*\"GET.*HTTP.*\" 401 \d*' > /etc/fail2ban/filter.d/nginx-401.conf"

execute "echo '* * * * * root /usr/sbin/watchdogs/fail2ban-watchdog.sh' >> /etc/cron.d/watchdogs"