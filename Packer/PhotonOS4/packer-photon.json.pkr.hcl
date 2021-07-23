variable "iso_file" {
  type    = string
  default = ""
}

variable "iso_sha1sum" {
  type    = string
  default = ""
}

variable "product_version" {
  type    = string
  default = ""
}

variable "root_password" {
  type    = string
  default = "2RQrZ83i79N6szpvZNX6"
}

variable "disk_size" {
  type    = number
  default = 20480
}

variable "memory_size" {
  type    = number
  default = 768
}

variable "CPUs" {
  type    = number
  default = 1
}

variable "vcenter_server" {
  type    = string
  description = "FQDN of the vCenter to connect to"
  default = null
}

variable "vcenter_username" {
  type    = string
  description = "Username used to connect to `vcenter_server`"
  default = null
}

variable "vcenter_password" {
  type    = string
  description = "Password used long with `vcenter_username` to connect to `vcenter_server`"
  default = null
}

variable "vcenter_datacenter" {
  type    = string
  description = "Datacenter to work in" #https://www.packer.io/docs/builders/vsphere/vsphere-iso#working-with-clusters-and-hosts
  default = null
}

variable "vcenter_insecure_connection" {
  type    = bool
  default = true
  description = "Allow for untrusted SSL certificates?"
}

variable "vcenter_folder" {
  type    = string
  description = "Folder to store VM"
  default = null
}

variable "vcenter_cluster" {
  type    = string
  description = "Cluster to store VM in" #https://www.packer.io/docs/builders/vsphere/vsphere-iso#working-with-clusters-and-hosts
  default = null
}

variable "vcenter_datastore" {
  type    = string
  description = "Datastore to store template in"
  default = null
}

variable "vcenter_portgroup" {
  type    = string
  description = "Port group name to attach to VM"
  default = null
}

variable "vmname" {
  type  = string
  description = "Name of the VM or Box"
  default = null
}

source "vsphere-iso" "vmware-template" {
  #Boot Info
  iso_checksum         = "${var.iso_sha1sum}"
  iso_url              = "${var.iso_file}"
  boot_command         = ["<esc><wait>", "vmlinuz initrd=initrd.img root=/dev/ram0 loglevel=3 ks=cdrom:/isolinux/nable_ks.cfg insecure_installation=1 photon.media=cdrom", "<enter>"]
  boot_wait            = "5s"
  cd_files             = ["./scripts"]

  #vSphere Configuration
  vcenter_server              = "${var.vcenter_server}"
  username                    = "${var.vcenter_username}"
  password                    = "${var.vcenter_password}"
  datacenter                  = "${var.vcenter_datacenter}"
  insecure_connection         = "${var.vcenter_insecure_connection}"
  folder                      = "${var.vcenter_folder}"
  cluster                     = "${var.vcenter_cluster}"
  datastore                   = "${var.vcenter_datastore}"
  

  #VM Info
  vm_name              = "${var.vmname}"
  vm_version           = "19" #https://kb.vmware.com/s/article/1003746
  guest_os_type        = "vmwarePhoton64Guest" #https://code.vmware.com/apis/358/vsphere/doc/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html

  #Disk Configuration
  disk_controller_type = ["pvscsi"]
  storage {    
    disk_size            = var.disk_size
  }

  #VM Spec's
  RAM                  = var.memory_size
  CPUs                 = var.CPUs

  #Network Configuration
  network_adapters {
    network = "${var.vcenter_portgroup}"
    network_card = "vmxnet3"
  }

  #SSH Settings
  ssh_password         = "${var.root_password}"
  ssh_username         = "root"
  ssh_timeout          = "60m"

  #Misc Settings
  shutdown_command     = "shutdown -h now"
  RAM_reserve_all      = true

  #Template Configuration
  convert_to_template  = true
  create_snapshot      = true
  remove_cdrom         = true
}

build {
  sources = [
    "source.vsphere-iso.vmware-template"
  ]

  provisioner "shell" {
    script = "scripts/photon-package_provisioning.sh"
  }

  provisioner "shell" {
    only   = ["source.vsphere-iso.vmware-template"]
    script = "scripts/photon-vsphere-template-user_provisioning.sh"
  }

  provisioner "shell" {
    only = ["source.vsphere-iso.vmware-template"]
    script = "scripts/photon-vsphere-template-tools.sh"
  }

  provisioner "shell" {
    inline = ["sed -i '/linux/ s/$/ net.ifnames=0/' /boot/grub2/grub.cfg"]
  }

  provisioner "shell" {
    inline = ["echo 'GRUB_CMDLINE_LINUX=\"net.ifnames=0\"' >> /etc/default/grub"]
  }

  provisioner "shell" {
    script = "scripts/photon-security_check.sh"
  }

  provisioner "shell" {
    inline = ["sed -i 's/OS/Linux/' /etc/photon-release"]
  }
}
