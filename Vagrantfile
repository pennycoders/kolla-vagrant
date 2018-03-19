# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'

unless Vagrant.has_plugin?('vagrant-vbguest') and Vagrant.has_plugin?('vagrant-disksize') and Vagrant.has_plugin?('landrush')
  unless Vagrant.has_plugin?('vagrant-vbguest')
    puts 'Installing vbguest plugin....'
    %x[vagrant plugin install vagrant-vbguest]
  end

  unless Vagrant.has_plugin?('vagrant-disksize')
    puts 'Installing disksize plugin.....'
    %x[vagrant plugin install vagrant-disksize]
  end
  
  unless Vagrant.has_plugin?('landrush')
    puts 'Installing landrush plugin.....'
    %x[vagrant plugin install landrush]
  end
  
  puts 'The plugins have been installed successfully. Please run vagrant up one more time'
  abort
end

if File.exists?(File.expand_path "./config.json")
    globalConfig = JSON.parse(File.read(File.expand_path "./config.json"))
    settings = JSON.parse(File.read(File.expand_path "./config.json"))
end
if defined? settings and settings['machines'].any?

  unless globalConfig.key?('host_disks_folder_path') and defined? globalConfig['host_disks_folder_path']
    puts 'Please define your host_disks_folder_path within config.json and run vagrant up once more'
    abort
  end

  hostnames = Array["127.0.0.1  localhost", "127.0.1.1  jump"]
  settings['machines'].each { |name, settings|
    hostnames.push("#{settings['networks'][0]['options']['ip']}  #{name}")
  }

  hostsFileLines = hostnames.join("\n")

  settings['machines'].each { |name, settings|
      Vagrant.configure("2") do |config|
         config.vm.define "#{name}", primary: settings['primary'] do |vmConfig|
             vmConfig.landrush.enabled = true
             vmConfig.vm.box = "#{settings['box']}"
             vmConfig.vm.box_check_update = settings['box_check_update']

             #if settings.key?('disk_size_gb') and defined? settings['disk_size_gb']
             #  vmConfig.disksize.size = "#{settings['disk_size_gb']}GB"
             #end

             if settings.key?('synced_folders') and settings['synced_folders'].any?
                settings['synced_folders'].each { |syncedFolder|
                  vmConfig.vm.synced_folder "#{syncedFolder['host']}", "#{syncedFolder['guest']}"
                }
             end
             if settings.key?('networks') and settings['networks'].any?
                settings['networks'].each { | networkSettings |
                  vmConfig.vm.network(networkSettings['type'], **networkSettings['options'].map { |arg, val| [arg.to_sym, val] }.to_h)
                }
             end
             if settings.key?('forwarded_ports') and settings['forwarded_ports'].any?
                settings['forwarded_ports'].each { | forwardedPortSettings |
                  vmConfig.vm.network('forwarded_port', **forwardedPortSettings.map { |arg, val| [arg.to_sym, val] }.to_h)
                }
             end

             vmConfig.vm.provider "virtualbox" do |virtualBox|
                virtualBox.gui = settings['gui']
                virtualBox.name = "#{name}"
                virtualBox.cpus = settings['vmConfig']['cpus']
                virtualBox.memory = settings['vmConfig']['memory']

                if settings['vmConfig'].key?('customizations') and settings['vmConfig']['customizations'].any?
                  settings['vmConfig']['customizations'].each { |customization|
                    virtualBox.customize ["#{customization['cmd']}", :id, "#{customization['param']}", "#{customization['value']}"]
                  }
                end

                if settings['vmConfig'].key?('disks') and settings['vmConfig']['disks'].any?
                  settings['vmConfig']['disks'].each_with_index { |diskConfig, diskIndex|
                    unless File.exist?("#{globalConfig['host_disks_folder_path']}/#{name}_#{diskConfig['name']}.vmdk")
                      virtualBox.customize ['createhd', '--filename', "#{globalConfig['host_disks_folder_path']}/#{name}_#{diskConfig['name']}.vmdk", '--size', diskConfig['size_mb']]
                    end
                    virtualBox.customize ['storageattach', :id, '--storagectl', "SATA Controller", '--port', diskIndex + 1, '--device',0, '--type', 'hdd', '--medium', "#{globalConfig['host_disks_folder_path']}/#{name}_#{diskConfig['name']}.vmdk"]
                  }
                end

             end

             if defined? hostnames and hostnames.any? and defined? hostsFileLines
               vmConfig.vm.provision "shell", inline: <<-SHELL
                 echo "#{hostsFileLines}" > /etc/hosts
                 echo "#{name}" > /etc/hostname
               SHELL
             end

             if File.exist?("./provisioning_scripts/#{name}/init.sh")
                        vmConfig.vm.provision "shell", path: "./provisioning_scripts/#{name}/init.sh"
             end
         end
      end
  }
else
    # All Vagrant configuration is done below. The "2" in Vagrant.configure
    # configures the configuration version (we support older styles for
    # backwards compatibility). Please don't change it unless you know what
    # you're doing.
    Vagrant.configure("2") do |config|
      # The most common configuration options are documented and commented below.
      # For a complete reference, please see the online documentation at
      # https://docs.vagrantup.com.

      # Every Vagrant development environment requires a box. You can search for
      # boxes at https://vagrantcloud.com/search.
      config.vm.box = "debian/stretch64"

      # Disable automatic box update checking. If you disable this, then
      # boxes will only be checked for updates when the user runs
      # `vagrant box outdated`. This is not recommended.
      # config.vm.box_check_update = false

      # Create a forwarded port mapping which allows access to a specific port
      # within the machine from a port on the host machine. In the example below,
      # accessing "localhost:8080" will access port 80 on the guest machine.
      # NOTE: This will enable public access to the opened port
      # config.vm.network "forwarded_port", guest: 80, host: 8080

      # Create a forwarded port mapping which allows accessX to a specific port
      # within the machine from a port on the host machine and only allow access
      # via 127.0.0.1 to disable public access
      # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

      # Create a private network, which allows host-only access to the machine
      # using a specific IP.
      # config.vm.network "private_network", ip: "192.168.33.10"

      # Create a public network, which generally matched to bridged network.
      # Bridged networks make the machine appear as another physical device on
      # your network.
      # config.vm.network "public_network"

      # Share an additional folder to the guest VM. The first argument is
      # the path on the host to the actual folder. The second argument is
      # the path on the guest to mount the folder. And the optional third
      # argument is a set of non-required options.
      # config.vm.synced_folder "../data", "/vagrant_data"

      # Provider-specific configuration so you can fine-tune various
      # backing providers for Vagrant. These expose provider-specific options.
      # Example for VirtualBox:
      #
      # config.vm.provider "virtualbox" do |vb|
      #   # Display the VirtualBox GUI when booting the machine
      #   vb.gui = true
      #
      #   # Customize the amount of memory on the VM:
      #   vb.memory = "1024"
      # end
      #
      # View the documentation for the provider you are using for more
      # information on available options.

      # Enable provisioning with a shell script. Additional provisioners such as
      # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
      # documentation for more information about their specific syntax and use.
      # config.vm.provision "shell", inline: <<-SHELL
      #   apt-get update
      #   apt-get install -y apache2
      # SHELL
    end
end
