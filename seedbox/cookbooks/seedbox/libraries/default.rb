module Helper
  begin
    gem "ruby-ip" 
  rescue LoadError
      system("/opt/chef/embedded/bin/gem install ruby-ip")
      Gem.clear_paths
  end

  require 'ip'
  require 'ipaddress'
  require 'open-uri'

  def get_addr (addr)
    cidr = IP.new(addr)
    return Hash['ip' => cidr.to_addr, 'mask' => cidr.netmask.to_s]
  end

  def get_default_int
    ip = get_default_ip
    return `netstat -ie | grep -B1 "#{ip}" | head -n1 | awk '{print $1}'`.gsub("\n", "")
  end

  def get_default_ip
    return remote_ip = open('http://whatismyip.akamai.com').read.gsub("\n", "")
  end
  
  def get_default_netmask
    int = get_default_int
    return `ifconfig #{int} | grep Mask | cut -d":" -f4`
  end
  
  def get_default_gw
    gw = `ip route show 0.0.0.0/0 | awk '{print $3}'`.gsub("\n", "")
    if /^\d+\.\d+\.\d+\.\d+$/.match(gw)
      return gw
    else
      return '0.0.0.0'
    end
  end
  
  def calc_subnet(ip, mask)
    addr = IPAddress "#{ip}/#{mask}"
    return addr.network.to_string
  end
  
  def gen_passwd_hash(str)
    return `openssl passwd -1 $(echo '#{str}')`.gsub("\n", "")
  end
end