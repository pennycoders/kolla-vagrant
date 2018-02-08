### Prerequisites:

1. Oracle VirtualBox - [Download](https://www.virtualbox.org/wiki/Downloads)
2. Ruby
3. Vagrant - [Info/Download](https://www.vagrantup.com/downloads.html)
4. Vagrant vbguest plugin - [Info/Download](https://github.com/dotless-de/vagrant-vbguest)
5. ruby json module - run the following commands to install:
```bash
sudo apt-get install ruby-dev
sudo gem install json --no-ri --no-rdoc
```

### Getting Started:

1. Edit the ./config.json file according to your needs (Pay special atention to the absolute paths, ip addresses and forwarded ports) 
The "host_disks_folder_path" is one of them. this is where the disk files are stored
2. Edit the ./provisioning_scripts/kolla/globals.yml and ./provisioning_scripts/kolla/multinode.ini according
to your config.json file
3. Run the following command to fire up the OpenStack Dev. environment:
```bash
vagrant up
```
4. Run the following commands to ssh into the jump node and get started with the kolla-ansible:
```bash
sudo su
kolla-ansible prechecks -i /provisioning/kolla/multinode.ini
kolla-ansible pull -i /provisioning/kolla/multinode.ini
```
Assuming that all the images were pulled successfully, run the following command:
```bash
kolla-ansible deploy -i /provisioning/kolla/multinode.ini
```
4. That's it, enjoy kolla-ansible.

#### TIPS:
1. The ./provisioning_scripts repository within the vagrant-setup git repository is mapped to /provisioning on each host. So, whatever files you
need to access from the guest machines, just place them there.
2. In order to update the kolla-specific configuration (globals.yml), just edit it on the host(your workstation) - you can find it ./provisioning/kolla/globals.yml,
and then run the following command on the jump host:
    ```bash
    cp /provisioning/kolla/globals.yml /etc/kolla/globals.yml
    ```