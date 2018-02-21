#!/bin/sh
# Install Docker CE Ubuntu AMI

# set -e
set -x
export APT_LISTCHANGES_FRONTEND=mail
export DEBIAN_FRONTEND=noninteractive
apt-get remove -qy docker docker-engine

apt-get install -yq \
    -o DPkg::options::='--force-confdef' -o Dpkg::Options::='--force-confold' \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get -yq dist-upgrade -o DPkg::options::='--force-confdef' -o Dpkg::Options::='--force-confold'
apt-get install -yq docker-ce -o DPkg::options::='--force-confdef' -o Dpkg::Options::='--force-confold'

groupadd docker
usermod -aG docker ubuntu

mkdir -p /etc/systemd/system/docker.service.d

cat <<EOT >> /etc/systemd/system/docker.service.d/docker_api.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375 --experimental --metrics-addr 0.0.0.0:4999
EOT

systemctl enable docker

