#https://www.virtjunkie.com/vmware-provisioning-using-hashicorp-terraform/
#https://github.com/jonhowe/Virtjunkie.com/tree/master/Terraform
variable "vsphere_server" {
  description = "vsphere server for the environment - EXAMPLE: vcenter01.hosted.local"
  default     = "vcenter.corp.lab"
}

variable "vsphere_user" {
  description = "vsphere server for the environment - EXAMPLE: vsphereuser"
  default     = "administrator@vsphere.local"
}

variable "vsphere_password" {
  description = "vsphere server password for the environment"
  default     = "VMware1!"
}

variable "adminpassword" { 
    default = "terraform" 
    description = "Administrator password for windows builds"
}

variable "datacenter" { 
    default = "Datacenter"
    description = "Datacenter name in vCenter"
}

variable "datastore" { 
    default = "vsanDatastore" 
    description = "datastore name in vCenter"
}

variable "cluster" { 
    default = "Cluster" 
    description = "Cluster name in vCenter"
}

variable "portgroup" { 
    default = "VM Network" 
    description = "Port Group new VM(s) will use"
}

variable "domain_name" { 
    default = "contoso.lan"
    description = "Domain Search name"
}
variable "default_gw" { 
    default = "172.16.1.1" 
    description = "Default Gateway"
}

variable "template_name" { 
    default = "Windows2019" 
    description = "VMware Template Name"
}

variable "vm_name" { 
    default = "WS19-1" 
    description = "New VM Name"

}

variable "vm_ip" { 
    default = "172.16.1.150" 
    description = "IP Address to assign to VM"
}

variable "vm_cidr" { 
    default = 24 
    description = "CIDR Block for VM"
}

variable "vcpu_count" { 
    default = 1 
    description = "How many vCPUs do you want?"
}

variable "memory" { 
    default = 1024 
    description = "RAM in MB"
}