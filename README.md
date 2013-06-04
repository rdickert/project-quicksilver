#Project Quicksilver
##Single-command High-Performance Drupal/LEMP Deployment

Project Quicksilver uses [Ansible](http://ansible.cc/) to provision a full, high-performance LEMP stack with [Memcached](http://www.memcached.org/), [phpMyAdmin](http://www.phpmyadmin.net/home_page/index.php), and SSMTP and a complete install of [Drupal](https://drupal.org/home) configured and running -- on a local or live virtual machine using Vagrant with a single command, often in less than 15 minutes. For more details, [read the blog post](http://robertdickert.com/blog/2013/06/03/announcing-project-quicksilver/).

##Install
* [Install VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Install Vagrant 1.2 or higher](http://downloads.vagrantup.com/)
* Set up Ubuntu 12.04 box `base` on vagrant - `vagrant box add base http://files.vagrantup.com/precise64.box`
* [Install Ansible](http://ansible.cc/docs/gettingstarted.html) (mac users may want to try [these instructions](https://weluse.de/blog/installing-ansible-on-os-x.html), and Linux users can try the [setup instructions using Pip](http://ansible.cc/docs/gettingstarted.html#via-pip)). Sorry, Ansible does not support Windows at this time[(although there are discussions about it)](https://groups.google.com/forum/#!topic/ansible-project/17YZIgArn2g), but you could run Project Quicksilver from a VirtualBox vm or a Linux server, if you have one you can ssh into.
* Set up fireball. This makes ansible much faster.

        sudo easy_install pip    
        sudo pip install pyzmq PyCrypto python-keyczar 

* Clone or Download the Project Quicksilver repo. 
* Go to your project directory and run:

        cp config-example.yml config.yml
        cp Vagrantfile-example Vagrantfile

* You will need to edit `config.yml` to add your passwords and other config details, but you can leave it unchanged if you just want to test it (it will build a single Drupal site (on the Panopoly distro on VirtualBox - to try out phpMyAdmin, you must at least set a root database password). 
* You will need to add your Digital Ocean credentials to your `Vagrantfile` if you wish to provision with it. If only using VirtualBox, you can leave it unchanged.
* If using Digital Ocean, install the [vagrant-digitalocean plugin](https://github.com/smdahlen/vagrant-digitalocean)

* Add the following to your .bashrc or .zshrc file:

        export ANSIBLE_HOSTS=~/ansible_hosts

        #Add Vagrant key for Ansible/direct ssh to vagrant on 127.0.0.1:2222
        # see http://stackoverflow.com/a/11832171/406226
        ssh-add ~/.ssh/insecure_private_key &>/dev/null

        #Configure for vagrant-digitalocean  https://github.com/smdahlen/vagrant-digitalocean\
        export SSL_CERT_FILE=/usr/local/opt/curl-ca-bundle/share/ca-bundle.crt

    (The `ssh-add` allows you and Ansible to access the vagrant vm through the vagrant user, which uses an ssh key (called insecure because the private and public keys are both publicly available) and won't take a password. If you don't do this, `ansible-playbook` commands will fail, but `vagrant provision` and `vagrant ssh` both take care of this for you, so they will still work).

##Run
###To build the full stack on a VirtualBox vm:
* Update your `config.yml` and adjust `tuning.yml` if desired.
* Place the following lines in your `ansible_hosts` file:

        [vagrant]
        127.0.0.1:2222
* From your Project Quicksilver folder, run `vagrant up`. 
* Once the playbook completes, you can go to your site at [http://localhost:8080](http://localhost:8080). phpMyAdmin is at [http://localhost:8080/phpmyadmin/](http://localhost:8080/phpmyadmin/) (please note that the trailing slash is required on VirtualBox due to port forwarding issues - on a production server, it will correctly redirect a request without the trailing slash). You can ssh in using `vagrant ssh`. If the provisioning process gets interrupted, you can rerun the playbook with `vagrant provision` - you may need to bounce the server (see below).

###To update your server's configuration

* Change your `config.yml` and/or `tuning.yml` to reflect new values. You can even add new sites or subdomains. This method *cannot* be used to delete sites/subdomains or to update them.
* run `vagrant provision`. This will skip vm instantiation and begin the playbook specified in the Vagrantfile (`configure-server.yml` by default).

###To build the full stack on Digital Ocean:
This process has a few hitches related to how new some of the integration projects are, but it still only takes a few minutes.

* Test your configuration on VirtualBox (see above). 
* From your Project Quicksilver folder, run `vagrant destroy` if necessary to remove your VirtualBox vm (Vagrant 1.2 will not run both VirtualBox and Digital Ocean vms from the same directory; a future release will fix this). 
* Run `vagrant up --provider=digital_ocean`. This will create a new droplet on Digital Ocean. At the time of this writing, the playbook fails when Ansible is called because Vagrant isn't passing Ansible the new site's IP address ([A fix is in the works.](https://github.com/mitchellh/vagrant/issues/1664))  
* In your `ansible_hosts` file, change the IP address of the `[vagrant]` entry to the address of your new droplet (unlike VirtualBox, you don't want to add a port number)
* From your Project Quicksilver folder, run `vagrant provision`
* All Vagrant commands will now work on your Digital Ocean vps. You can remove your server (and stop billing) with `vagrant destroy` - always confirm that the operation succeeded by checking your [droplets page](https://www.digitalocean.com/droplets) - add/remove operations are generally reflected there immediately. You can of course destroy the droplet on the website manually as well.

###To run Project Quicksilver playbooks on any server:
* You will need an Ubuntu 12.04 server (You can try other Debian-based Linuxes, but they have not been tested. *Non-Debian Linuxes will definitely not work.*).
* Add an account `vagrant` with `sudo` privileges that do not require a password. (This matches the account in the Ansible playbooks, even though you won't be using Vagrant)
* Set up [key-based ssh login](https://help.ubuntu.com/community/SSH/OpenSSH/Keys) from the machine that will be running the Ansible playbooks. 
* In your `ansible_hosts` file, change the IP address of the `[vagrant]` entry to the address of your target server (unlike VirtualBox, you don't want to add a port number)
* Run `ansible-playbook -u vagrant [playbook]` where [playbook] is the name of the playbook (script) you want to run. For a full stack Drupal deployment, this would be

        ansible-playbook -u vagrant configure-server.yml

###To Add a Website to an Existing Server
* The website and corresponding directory must not exist, or the playbook will do nothing. This protects your existing websites from being overwritten. If you need to replace a website, see the directions below to remove it first. You can change existing sites using Drush alone.
* Add the website details to `config.yml`. You can leave existing sites' config in place - they will be skipped.
* Run `ansible-playbook -u vagrant deploy-archives.yml` for a drush-archive install or `ansible-playbook -u vagrant deploy-distro.yml` for a new empty site. You can also safely run `configure-server.yml` or `vagrant provision` - it will run the whole playbook and correct anything not to spec.

###To Completely Remove a Website
Be warned that this playbook completely eradicates all traces of a site, removing all files, the Drush alias, the database and db user, and the Nginx configuration (and the URL will stop working). If that's what you want, though, this will do the trick. This will only work for sites installed by Project Quicksilver playbooks. Its behavior on user-created sites may be unpredictable unless you followed the exact same conventions. Please back up your files and database before running this, or they will be gone forever.

Run `ansible-playbook -u vagrant destroy-site.yml --extra-vars "site=sitename db=dbname`, where sitename is the `name` you used in the site's creation (this will be its directory name as well), and *dbname* is the `db` name you assigned (and must equal the db username in this version).

###To bounce the server
If a quicksilver playbook fails, it will not restart services that may have already been configured. If you have completed the playbook in multiple tries and the server is not working, use `bounce-server.yml` 

###Using Drush
You can use Drush from the site directory associated with the site or by using its alias, `@site`, where *site* is the name you gave it in `config.yml`. The Drush aliases are stored in `/etc/drush/`.

##Contribute
If you have suggestions for better setting values or settings to add, or if you want to add support for other Vagrant providers, server packages, or applications, pull requests are welcome. I will try to include reasonable options that a lot of people will want, but the infinite number of choices and the fact that this is intended to be easy to use will require some editorial choices. Of course, you can always fork the project.

##To-dos
* Implement SSL
* Add support to build sites from Drush make files
* Rework/Clean up Nginx config files
* Add documentation on how to generate Linux password hashes on windows/osx 
* Test/add support for additional ISPs and mail providers
* Use Ansible to wire-in memcached, etc. for distro deployments (right now, you have to edit settings.php & add Drupal module(s) manually)

##WordPress/LEMP-only
This stack was originally built for a Drupal deployment, but most of it should be useful for *any* PHP app, including WordPress. Just change the Vagrantfile so that under `config.vm.provision`, the line reads:

    ansible.playbook = "configure-lemp-only.yml"

All of the Drupal-specific tools will be omitted. You will have to create your own Nginx configuration for the sites, but the site-deployment playbooks for Drupal should be adaptable for specific applications. [Nginx has some suggested settings](http://wiki.nginx.org/WordPress), but there may be other choices out there.

##Sources
* The server implementation and technology stack for the most part follow [this series of articles from Ars Technica](http://arstechnica.com/series/web-served/).
* The directory structure and some of the code for Project Quicksilver came from [this project by @cocoy](https://github.com/cocoy/ansible-playbooks), although they have been extensively changed and added to.
* The idea of the `tuning.yml` file, the database security playbook,  and other useful pointers came from a [LAMP Ansible playbook by Four Kitchens](https://github.com/fourkitchens/server-playbooks)

##Disclaimer - Please read this!

**No Warranty:** These scripts make permanent system-level changes to your server. It is possible to overwrite or destroy websites and to make a server perform poorly or crash. Also, there could be security flaws that would expose your server to attack. Although efforts have been made to make them safe, you use them at your own risk. In addition, if you choose to use the Digital Ocean plugin, these scripts can incur usage fees. Use at your own risk.

**Additional Warning:** Version 0.1.0 is the first working version and is not fully tested. Expect there to be bugs! There could be security flaws, and this configuration is not hardened. Please evaluate the scripts for yourself and give feedback about the project so it can be improved.
