#!/usr/bin/env bash

#wget -qO- get.docker.com | sudo sh -

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
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce
apt-get install -y net-tools
usermod -aG docker vagrant

#iptables stuff
apt-get -y install debconf-utils
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get -y install iptables-persistent
iptables -A FORWARD -i eth2 -j ACCEPT
iptables -A FORWARD -o eth2 -j ACCEPT
iptables -A FORWARD -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables-save # Write rules to /etc/sysconfig/iptables
echo "1" > /proc/sys/net/ipv4/ip_forward
iptables-save > /etc/iptables/rules.v4
echo "Existing iptables rules:============================================================================"
iptables-save
echo "===================================================================================================="

wget -qO- https://github.com/docker/machine/releases/download/v0.13.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && \
chmod +x /tmp/docker-machine && \
sudo cp /tmp/docker-machine /usr/local/bin/docker-machine

#kolla-ansible stuff
apt-get update
apt-get install -y curl python-pip python-dev libffi-dev gcc libssl-dev python-selinux git
wget -qO- https://bootstrap.pypa.io/get-pip.py | python -
pip install -U git+git://github.com/ansible/ansible.git@devel
apt-get install -y ntp
pip install git+git://github.com/openstack/kolla-ansible.git@stable/pike --upgrade
rm -Rf /etc/kolla
mkdir -p /etc/kolla
cp -R /provisioning/kolla/globals.yml /etc/kolla/globals.yml
cp -R /provisioning/kolla/passwords.yml /etc/kolla/passwords.yml
cp -R /provisioning/kolla/multinode.ini /etc/kolla/multinode
kolla-genpwd

#OpenStacks stuff
pip install python-openstackclient
pip install python-magnumclient
pip install python-cinderclient
pip install python-glanceclient


ips=(
  "10.55.1.2"
  "10.55.1.3"
  "10.55.1.4"
  "10.55.1.5"
)

hostnames=(
  "jump"
  "control1"
  "compute1"
  "compute2"
)

for i in "${!ips[@]}"; do
  sudo ssh-keygen -R ${ips[${i}]}
  sudo ssh-keygen -R ${hostnames[${i}]}
  sudo ssh-keyscan ${hostnames[${i}]} >> ${HOME}/.ssh/known_hosts
  sudo ssh-keyscan ${hostnames[${i}]} >> ${HOME}/.ssh/known_hosts
  sudo ssh-keyscan ${ips[${i}]} >> /root/.ssh/known_hosts
  sudo ssh-keyscan ${hostnames[${i}]} >> /root/.ssh/known_hosts
done

for i in "${!ips[@]}"; do
  if [ "${hostnames[${i}]}" == "jump" ]; then
    sudo cp /root/.ssh/known_hosts /home/vagrant/.ssh/known_hosts
    sudo chown vagrant:vagrant /home/vagrant/.ssh -R
  else
    sudo scp /root/.ssh/known_hosts root@${hostnames[${i}]}:/root/.ssh/known_hosts
    sudo scp /root/.ssh/known_hosts root@${hostnames[${i}]}:/home/vagrant/.ssh/known_hosts
    ssh -t root@${hostnames[${i}]} sudo chown vagrant:vagrant /home/vagrant/.ssh -R
  fi
done

for i in "${!ips[@]}"; do
  docker-machine rm -f ${hostnames[${i}]}
  docker-machine create --driver generic --engine-opt host=fd:// --generic-ssh-key=${HOME}/.ssh/id_rsa --generic-ssh-user=vagrant --generic-ip-address=${ips[${i}]} ${hostnames[${i}]}
done
