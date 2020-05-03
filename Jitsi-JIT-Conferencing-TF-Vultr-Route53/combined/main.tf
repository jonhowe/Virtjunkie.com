#main.tf
#https://www.virtjunkie.com/jitsi-jit-conferencing-tf-vultr-route53/
#https://github.com/

#Conifugre the Vultr provider
provider "vultr" {
  api_key = var.vultr_api_key
  rate_limit = 700
  retry_limit = 3
}

#Configure the AWS Provider
provider "aws" {
  #profile    = "default"
  #shared_credentials_file = "/home/jhowe/storage/btsync/folders/Sync/awscredentials/credentials"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

#https://www.terraform.io/docs/providers/aws/d/route53_zone.html
data "aws_route53_zone" "selected" {
  name         = "${var.domain}."
  private_zone = false
}

#Provision Vultr Server
resource "vultr_server" "my_server" {
    plan_id = var.vultr_plan_id
    region_id = var.vultr_region
    app_id = var.vultr_app_id
    label = "${var.hostname}.${var.domain}"
    tag = var.vultr_tag
    hostname = "${var.hostname}.${var.domain}"
    enable_ipv6 = false
    auto_backup = false
    ddos_protection = false
    notify_activate = false

    connection {
        type     = "ssh"
        user     = "root"
        
        #https://www.terraform.io/docs/providers/vultr/r/server.html#default_password
        password = self.default_password

        #https://www.terraform.io/docs/provisioners/connection.html#the-self-object
        host     = self.main_ip
    }

    provisioner "local-exec" {
      command = "echo SSH to this server with the command: ssh root@${vultr_server.my_server.main_ip} with the password '${vultr_server.my_server.default_password}'"
    }
}

#Create the Route 53 A Record
#https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "conference" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.hostname}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["${vultr_server.my_server.main_ip}"]
}

#This null resource exists to handle configuration of the Vultr VPS after Route 53
resource "null_resource" "jitsi_config" {
    
    connection {
        type     = "ssh"
        user     = "root"
        
        #https://www.terraform.io/docs/providers/vultr/r/server.html#default_password
        password = vultr_server.my_server.default_password

        #https://www.terraform.io/docs/provisioners/connection.html#the-self-object
        host     = vultr_server.my_server.main_ip
    }

    provisioner "file" {
        source      = "./configure_jitsi_param.sh"
        destination = "/root/configure_jitsi_param.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /root/configure_jitsi_param.sh",
            "/root/configure_jitsi_param.sh ${var.hostname}.${var.domain} ${var.email} y"
        ]
    }
}