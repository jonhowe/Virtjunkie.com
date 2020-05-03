#variables.tf
#https://www.virtjunkie.com/jitsi-jit-conferencing-tf-vultr-route53/
#https://github.com/

variable "vultr_api_key" {
    description = "API Key Used by Vultr (https://my.vultr.com/settings/#settingsapi)"
}

variable "vultr_region" {
    description = "Vultr Region Selection (curl https://api.vultr.com/v1/regions/availability?DCID=1)"
    default = 1
}

variable "vultr_plan_id" {
    description = "Vultr Plan for the VPS to use (curl https://api.vultr.com/v1/plans/list)"
    default = 202
}

variable "vultr_tag" {
    description = "Vultr Tag to apply to the new VPS"
    default = "jitsi-conference"
}

variable "vultr_app_id" {
    description = "Vultr App to pre-install. This should always be '47', if jitsi is being provisioned (curl https://api.vultr.com/v1/app/list)"
    default = 47
}

variable "hostname" {
    description = "Hostname to be used"
    default = "conferences"
}

variable "email" {
    description = "email to be used for let's encrypt acme config"
    default = "john.doe@email.com"
}

variable "domain" {
    description = "domain to be used"
    default = "aremyj.am"
}

variable "aws_access_key" {
    description = "AWS Access Key - get it here: (https://console.aws.amazon.com/iam/home?#security_credential)"
}

variable "aws_secret_key" {
    description = "AWS Secret Key - get it here: (https://console.aws.amazon.com/iam/home?#security_credential)"
}

variable "aws_region" {
    description = "AWS Region"
    default = "us-east-1"
}