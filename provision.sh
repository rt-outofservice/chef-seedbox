#! /usr/bin/env bash

# Default variables
user=root
sudo=''
port=22
remote_port=2235
path=$(pwd)
chef_url='https://opscode-omnibus-packages.s3.amazonaws.com/debian/6/x86_64/chef_12.5.1-1_amd64.deb'

# Parse command line arguments
for i in "$@"
do
case $i in
    -h|--help)
    printf '%s\n%s\n' 'Usage: ./provision.sh --ip=127.0.0.1 --cookbook=cookbook1,cookbook2 [OPTIONAL: --user=username (default: root) --port=25 (default: 22)]' 'Note: if user is different from root then all commands will be executed with sudo.'
    shift
    exit
    ;;
    --ip=*)
    ip="${i#*=}"
    shift
    ;;
    --user=*)
    user="${i#*=}"
    shift
    ;;
    --port=*)
    port="${i#*=}"
    shift
    ;;
    --cookbook=*)
    cookbook="${i#*=}"
    shift
    ;;
esac
done

# Check required variables
if [ -z "$ip" ]; then
  echo "Error! IP-address is empty. Exit."
fi

if [ -z "$cookbook" ]; then
  echo "Error! Cookbook is empty. Exit."
fi

# Upload cookbook
scp -P $port -r "$path" $user@$ip:/tmp

# If user is different from root use sudo
if [ "$user" != "root" ]; then
  sudo=sudo
fi

ssh -t $user@$ip -p $port bash -c "'
  $sudo apt-get update
  $sudo apt-get -y install wget
  wget -O /tmp/chef-client.deb $chef_url
  $sudo dpkg -i /tmp/chef-client.deb
  rm /tmp/chef-client.deb
  
  if [ ! -d /tmp/$(echo $path | grep -oE '[0-9A-z\-]*$') ]; then
    mkdir -p /tmp/$(echo $path | grep -oE '[0-9A-z\-]*$')
    wget -O /tmp/$(echo $path | grep -oE '[0-9A-z\-]*$') $path
  fi

  cd /tmp/$(echo $path | grep -oE '[0-9A-z\-]*$')/seedbox
  
  $sudo chef-client -L /tmp/chef-client.log -z -o $cookbook
  
  $sudo rm -rf /tmp/$(echo $path | grep -oE '[0-9A-z\-]*$')
  exit 
'"

printf '\n######################'
ssh rt@$ip -p $remote_port 'sudo cat /tmp/credentials; sudo rm /tmp/credentials'
printf '\n\n######################\n'

ssh rt@$ip -p $remote_port 'sudo shutdown -r now'
