#https://www.virtjunkie.com/vmware-provisioning-using-hashicorp-terraform/
#https://github.com/jonhowe/Virtjunkie.com/tree/master/Terraform

vsphere_server = "vcenter.home.lab"

vsphere_user = "administrator@vsphere.local"

vsphere_password = "VMware1!"

adminpassword = "terraform" 

datacenter = "Datacenter"

datastore = "vsanDatastore" 

cluster = "Cluster"

portgroup = "100-LabNetwork" 

domain_name = "home.lab"

default_gw = "172.16.1.1" 

template_name = "WS19-TPL" 

vm_name = "WS19-1" 

vm_ip = "172.16.1.150"

vm_cidr = 24

vcpu_count = 1

memory = 1024 