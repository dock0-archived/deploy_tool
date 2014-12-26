vm_config
========

[![Automated Build](http://img.shields.io/badge/automated-build-green.svg)](https://registry.hub.docker.com/u/dock0/vm_config/)
[![MIT Licensed](http://img.shields.io/badge/license-MIT-green.svg)](https://tldrlegal.com/license/mit-license)

My configuration for [dock0](https://github.com/dock0/dock0)

## Prerequisites

```
bundle install
```

## Usage

To deploy a VM from scratch, run the deploy script:

```
./meta/deploy.rb <hostname>
```

This will delete all existing data on the Linode, deploy new disk images, run dock0 install (via ./meta/stackscript) to load artifacts, then load the config via the vm_config container.

To update the configuration on an existing deployment, start the vm_config container on the VM and then run the configure script locally:

```
## On the VM
docker run -ti -v /run/vm/bootmnt:/run/vm/bootmnt -p 1001:22 -p 1002:80 dock0/vm_config
## On the local system
./meta/configure.rb <hostname>
```

Note that if you're managing your own iptables redirects, you'll need to add rules so that traffic on 1001 and 1002 is routed to the container:

```
iptables -t nat -A DOCK0 -p tcp -m tcp --dport 1001 -j DNAT --to-destination <container-ip>:22
iptables -t nat -A DOCK0 -p tcp -m tcp --dport 1002 -j DNAT --to-destination <container-ip>:80
```

## License

These scripts and config files are released under the MIT License. See the bundled LICENSE file for details.

