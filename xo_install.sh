#!/bin/bash

# Check if we were effectively run as root
[ $EUID = 0 ] || { echo "This script needs to be run as root!"; exit 1; }

# Check for 1GB Memory
totalk=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
if [ "$totalk" -lt "1000000" ]; then echo "XOCE Requires at least 1GB Memory!"; exit 1; fi 

distro=$(/usr/bin/lsb_release -is)
if [ "$distro" = "Ubuntu" ]; then /usr/bin/add-apt-repository multiverse; fi

xo_branch="master"
xo_server="https://github.com/vatesfr/xen-orchestra"
n_repo="https://raw.githubusercontent.com/visionmedia/n/master/bin/n"
yarn_repo="deb https://dl.yarnpkg.com/debian/ stable main"
yarn_gpg="https://dl.yarnpkg.com/debian/pubkey.gpg"
n_location="/usr/local/bin/n"
xo_server_dir="/opt/xen-orchestra"
systemd_service_dir="/lib/systemd/system"
xo_service="orchestra"

# Ensures that Yarn dependencies are installed
/usr/bin/apt-get update
/usr/bin/apt-get --yes install git curl apt-transport-https gnupg

#Install yarn
cd /opt

                                       
/usr/bin/curl -sS $yarn_gpg | apt-key add -
echo "$yarn_repo" | tee /etc/apt/sources.list.d/yarn.list
/usr/bin/apt-get update
/usr/bin/apt-get install --yes yarn

# Install n
/usr/bin/curl -o $n_location $n_repo
/bin/chmod +x $n_location

# Install node via n
n 8.16

# Symlink node directories
ln -s /usr/bin/node /usr/local/bin/node

# Install XO dependencies
/usr/bin/apt-get install --yes build-essential redis-server libpng-dev git python-minimal libvhdi-utils nfs-common lvm2 cifs-utils 

/usr/bin/git clone -b $xo_branch $xo_server

cd $xo_server_dir
/usr/bin/yarn
/usr/bin/yarn build

cd packages/xo-server
cp sample.config.toml .xo-server.toml

#Create node_modules directory if doesn't exist
mkdir -p /usr/local/lib/node_modules/

# Symlink all plugins
for source in $(ls -d /opt/xen-orchestra/packages/xo-server-*); do
    ln -s "$source" /usr/local/lib/node_modules/
done

# Check if forever is installed. If not install it and report.
if [ ! -f "/usr/local/bin/forever" ]; then
  echo "Installing forever..."
  yarn global add forever
  if [ -f "/usr/local/bin/forever" ]; then
    echo "forever was successfully installed..."
  fi
fi
# Check if forever-service is installed. If not install it and report.
if [ ! -f "/usr/local/bin/forever-service" ]; then
  echo "Installing forever-service..."
  yarn global add forever-service
  if [ -f "/usr/local/bin/forever-service" ]; then
    echo "forever-service was successfully installed..."
  fi
fi
# Check if orchestra service is installed. If not install it and report.
if [ ! -f "/etc/init.d/${xo_service}" ]; then
echo "Installing Orchestra Service..."
cd ${xo_server_dir}/packages/xo-server/bin && forever-service install ${xo_service} -r root -s xo-server
  if [ -f "/etc/init.d/${xo_service}" ]; then
  echo "Orhcestra Service was successfully installed..."
fi
# Start the Xen Orchestra Service
service ${xo_service} start

# Give default install details to the user
echo ""
echo ""
echo "Installation complete, open a browser to:" && hostname -I && echo "" && echo "Default Login:"admin@admin.net" Password:"admin"" && echo "" && echo "Don't forget to change your password!"

