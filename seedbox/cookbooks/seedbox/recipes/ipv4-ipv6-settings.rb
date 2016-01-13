## DISABLE IPv6 STACK
execute "echo 'net.ipv6.conf.all.disable_ipv6=1' >> /etc/sysctl.conf" do
  not_if "cat /etc/sysctl.conf | grep -E '^net.ipv6.conf.all.disable_ipv6=1'"
end

execute "echo 'net.ipv6.conf.default.disable_ipv6=1' >> /etc/sysctl.conf" do
  not_if "cat /etc/sysctl.conf | grep -E '^net.ipv6.conf.default.disable_ipv6=1'"
end


# Need to check here if interfaces exist
execute "echo 'net.ipv6.conf.lo.disable_ipv6=1' >> /etc/sysctl.conf" do
  not_if "cat /etc/sysctl.conf | grep -E '^net.ipv6.conf.lo.disable_ipv6=1'"
end

execute "echo 'net.ipv6.conf.eth0.disable_ipv6=1' >> /etc/sysctl.conf" do
  not_if "cat /etc/sysctl.conf | grep -E '^net.ipv6.conf.eth0.disable_ipv6=1'"
end


## ENABLE IPv4 FORWARDING
execute 'echo 1 > /proc/sys/net/ipv4/ip_forward' do
  not_if 'grep 1 /proc/sys/net/ipv4/ip_forward'
end

execute "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf" do
  not_if "cat /etc/sysctl.conf | grep -E '^net.ipv4.ip_forward=1'"
end

execute 'sysctl -p' do
  ignore_failure true
end