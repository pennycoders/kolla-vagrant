#!/usr/bin/env bash

#wget -qO- get.docker.com | sudo sh -
#sudo usermod -aG docker vagrant
#echo -e  'y\n'|ssh-keygen -b 8192 -f ./provisioning_scripts/vagrant -t rsa -N '' -o
cp -R /provisioning/ssh_keys /root/.ssh
cp -R /provisioning/ssh_keys/id_rsa /home/vagrant/.ssh/id_rsa
cp -R /provisioning/ssh_keys/id_rsa.pub /home/vagrant/.ssh/id_rsa.pub
chown root:root /root/.ssh -R
chmod go-rwxs /root/.ssh -R
chmod u+rwxs /root/.ssh -R
chown vagrant:vagrant /home/vagrant/.ssh -R
chmod go-rwxs /home/vagrant/.ssh -R
chmod u+rwxs /home/vagrant/.ssh -R
echo $(cat /provisioning/ssh_keys/id_rsa.pub) >> /root/.ssh/authorized_keys
echo $(cat /provisioning/ssh_keys/id_rsa.pub) >> /home/vagrant/.ssh/authorized_keys

echo "HDD STUFF====================================================================="
# Extend the HDD space...
apt-get install -y parted
if grep -q "LABEL=dockerstorage" "/etc/fstab"; then
   echo "Docker store directory already extended..."
else
   echo "Mounting docker directory at /var/lib/docker...."
   parted -s /dev/sdb mklabel gpt
   parted -a opt -s /dev/sdb mkpart primary ext4 0% 100%
   mkfs.ext4 -L dockerstorage /dev/sdb1
   mkdir -p /var/lib/docker
   echo "LABEL=dockerstorage /var/lib/docker ext4 defaults 0 2" >> /etc/fstab
   mount -a
fi
df -h
echo "HDD STUFF====================================================================="

#Docker stuff
#apt-get install -y apt-transport-https ca-certificates curl software-properties-common
#curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
#add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
#apt-get update
#apt-get install -y docker-ce
apt-get install -y net-tools
usermod -aG docker vagrant

#Kolla-ansible stuff
wget -qO- https://bootstrap.pypa.io/get-pip.py | python -
pip install -U docker
mkdir -p /etc/kolla/config/nova

mkdir -p /etc/kolla/config/nova
cat << EOF > /etc/kolla/config/nova/nova-compute.conf
[libvirt]
virt_type = qemu
cpu_mode = none
EOF
