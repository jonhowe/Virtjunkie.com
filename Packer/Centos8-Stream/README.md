# packer-CentOS8Stream
This repo is based on work done by @eaksel here: https://github.com/eaksel/packer-CentOS8

Changes:
- Removed support for VMware Workstaiton and Virtualbox
- Added support for vSphere-ISO
- Modified image to use Centos8 Stream, since Centos8 Linux is EOL December 31, 2021

## What is packer-CentOS8Stream ?

packer-CentOS8Stream is a set of configuration files used to build an automated CentOS 8 virtual machine images using [Packer](https://www.packer.io/).
This Packer configuration file allows you to build images for VMware Workstation and Oracle VM VirtualBox.

## Prerequisites

- [Packer](https://www.packer.io/downloads.html)
  - <https://www.packer.io/intro/getting-started/install.html>
  - [vCenter Server]

## How to use Packer

Commands to create an automated VM image:

To create a CentOS 8 VM image using VMware Workstation use the following commands:

<!---
TODO: Modify the below info to only include vsphere-iso
-->
```cmd
cd c:\packer-CentOS8Stream
packer build -var-file=centos8-vars.json centos8.json
```

To create a CentOS 8 VM image using Oracle VM VirtualBox use the following commands:

```cmd
cd c:\packer-CentOS8Stream
packer build -only=virtualbox-iso centos8.json
```

*If you omit the keyword "-only=" both the Workstation and Virtualbox VMs will be created.*

By default the .iso of CentOS 8 is pulled from <http://miroir.univ-paris13.fr/centos/8/isos/x86_64/CentOS-8.1.1911-x86_64-boot.iso>

You can change the URL to one closer to your build server. To do so change the **"iso_url"** parameter in the **"variables"** section of the centos8.json file.

```json
{
  "variables": {
      "iso_url": "http://miroir.univ-paris13.fr/centos/8/isos/x86_64/CentOS-8.1.1911-x86_64-boot.iso"
}
```

## Keyboard configuration

By default the keyboard is set to be US qwerty.
To switch it to something else edit the following file:

- ./http/ks.cfg

Set the `keyboard` parameter as desired, for example: `keyboard --vckeymap=fr --xlayouts='fr'`

## Default credentials

The default credentials for this VM image are:

|Username|Password|
|--------|--------|
|packer|packer|
|root|packer|
