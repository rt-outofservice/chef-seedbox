#!/usr/bin/env bash

EASY_RSA_PATH='/root/easy-rsa'

# Prepare files and folders
# for old Debian where easy-rsa is a part of openvpn package
# cp -pr /usr/share/doc/openvpn/examples/easy-rsa/2.0 $EASY_RSA_PATH
make-cadir $EASY_RSA_PATH
cd $EASY_RSA_PATH

# Create necessary files and folders
if [ ! -f vars ]; then
    touch vars
fi

if [ ! -f vars.bak ]; then
    mv vars vars.bak
fi

# Parse command line arguments
for i in "$@"
do
case $i in
    -h|--help)
    echo "Usage: ./certificates.sh --country=RU --province=Moscow --city=Moscow --org=Home --email=test@gmail.com --server-name=server-name --client-name=client1,client2,client3"
    shift
    ;;
    --country=*)
    KEY_COUNTRY="${i#*=}"
    shift
    ;;
    --province=*)
    KEY_PROVINCE="${i#*=}"
    shift
    ;;
    --city=*)
    KEY_CITY="${i#*=}"
    shift
    ;;
    --org=*)
    KEY_ORG="${i#*=}"
    shift
    ;;
    --email=*)
    KEY_EMAIL="${i#*=}"
    shift
    ;;
    --server-name=*)
    SERVER_NAME="${i#*=}"
    shift
    ;;
    --client-name=*)
    CLIENT_NAME="${i#*=}"
    shift
    ;;
esac
done

# Exit if variables are empty
if [ -z "$KEY_COUNTRY" ]; then
  echo "Error! KEY_COUNTRY variable is empty. Exit."
fi
if [ -z "$KEY_PROVINCE" ]; then
  echo "Error! KEY_PROVINCE variable is empty. Exit."
fi
if [ -z "$KEY_CITY" ]; then
  echo "Error! KEY_CITY variable is empty. Exit."
fi
if [ -z "$KEY_ORG" ]; then
  echo "Error! KEY_ORG variable is empty. Exit."
fi
if [ -z "$KEY_EMAIL" ]; then
  echo "Error! KEY_EMAIL variable is empty. Exit."
fi
if [ -z "$SERVER_NAME" ]; then
  echo "Error! SERVER_NAME variable is empty. Exit."
fi
if [ -z "$CLIENT_NAME" ]; then
  echo "Error! CLIENT_NAME variable is empty. Exit."
fi

# Hack for whichopensslcnf
if [ ! -f $EASY_RSA_PATH/openssl.cnf ]; then
  ln -s `find $EASY_RSA_PATH -name 'openssl*' | grep 'openssl-1\.[0-9]\.[0-9]\.cnf' | head -n1` $EASY_RSA_PATH/openssl.cnf
fi

# Set parameters
echo -e "export KEY_COUNTRY='$KEY_COUNTRY' \n
export KEY_PROVINCE='$KEY_PROVINCE' \n
export KEY_CITY='$KEY_CITY' \n
export KEY_ORG='$KEY_ORG' \n
export KEY_EMAIL='$KEY_EMAIL' \n" >> vars

echo -e "export EASY_RSA='$EASY_RSA_PATH' \n
export OPENSSL='openssl' \n
export PKCS11TOOL='pkcs11-tool' \n
export GREP="grep" \n
export KEY_CONFIG=`$EASY_RSA_PATH/whichopensslcnf $EASY_RSA_PATH` \n
export KEY_DIR='$EASY_RSA_PATH/keys' \n
export KEY_SIZE=2048 \n
export CA_EXPIRE=3650 \n
export KEY_EXPIRE=3650" >> vars

# Generate server certificates and keys
source ./vars
./clean-all
./build-ca --batch
./build-key-server --batch "$SERVER_NAME"
./build-dh
openvpn --genkey --secret $EASY_RSA_PATH/keys/ta.key

# Generate client certificates and keys and pack to archives
IFS=',' read -ra ADDR <<< "$CLIENT_NAME"
for i in "${ADDR[@]}"; do
  if [ -z $i ]; then
    continue
  fi
      
  ./build-key --batch $i
  cp /etc/openvpn/client.ovpn /tmp/$i.ovpn
  sed -i -e "s/client.key/$i.key/g" /tmp/$i.ovpn
  sed -i -e "s/client.crt/$i.crt/g" /tmp/$i.ovpn
  mkdir -p /home/rt/$i
  cp {$EASY_RSA_PATH/keys/ca.crt,$EASY_RSA_PATH/keys/$i.key,$EASY_RSA_PATH/keys/$i.crt,/tmp/$i.ovpn,$EASY_RSA_PATH/keys/ta.key} /home/rt/$i
done

# Move server certificates
cd $EASY_RSA_PATH/keys
cp {ca.crt,$SERVER_NAME.crt,$SERVER_NAME.key,ta.key,dh2048.pem} /etc/openvpn
mv {ca.crt,ca.key,$SERVER_NAME.crt,$SERVER_NAME.key,ta.key,dh2048.pem} /home/rt/
chown -R rt:rt /home/rt/*
rm $EASY_RSA_PATH/keys/*