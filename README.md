deploy_tool
========

[![Automated Build](http://img.shields.io/badge/automated-build-green.svg)](https://hub.docker.com/r/dock0/deploy_tool/)
[![Build Status](https://img.shields.io/circleci/project/dock0/deploy_tool/master.svg)](https://circleci.com/gh/dock0/deploy_tool)
[![MIT Licensed](http://img.shields.io/badge/license-MIT-green.svg)](https://tldrlegal.com/license/mit-license)

My configuration for [dock0](https://github.com/dock0/dock0)

## Overview

This contains the dock0 configuration necessary to build config bundles (all the instance-specific bits of a VM):

* config.yaml -- global configuration for all VMs
* configs/$HOSTNAME.yaml -- VM-specific data
* templates -- templates for networking and similar
* scripts -- scripts to use for building config image. Contains code that generates docker auto-start scripts
* docker -- templates and env file scripts for container auto-start

This also contains the meta/ directory for the deploy_tool Docker container, which handles receiving a config tarball on the VM's side, as well as initial provisioning:

* image-build.rb -- builds [Linode Image](https://www.linode.com/api/image) that has the necessary code loaded to build a VM
* stackscript -- StackScript used to bootstrap the image in image-build.rb. It installs some needed packages and then lays down the dock0.service to complete provisioning on next boot.

* deploy.rb -- Uses built Linode Image to rebuild a VM, including calling configure.rb to push up a config tarball
* configure.rb -- Pushes up a tarball to the VM with its configuration

* Dockerfile -- defines the docker container that knows how to receive the tarball
* flag -- simple service used by container to signal that it's alive over HTTP
* lurker -- simple service used to wait for the tarball and then kill the container

## Prerequisites

```
bundle install
```

## Usage

To rebuild the Image that's used to bootstrap deployments:

```
./meta/image-build.rb <hostname>
```

To deploy a VM, run the deploy script:

```
./meta/deploy.rb <hostname>
```

This will delete all existing data on the Linode, deploy new disk images, run dock0 install (via ./meta/stackscript) to load artifacts, then load the config via the deploy_tool container.

To update the configuration on an existing deployment, start the deploy_tool container on the VM and then run the configure script locally:

```
## On the VM
docker run -ti -v /run/vm/bootmnt:/run/vm/bootmnt -p 1001:22 -p 1002:80 dock0/deploy_tool
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

