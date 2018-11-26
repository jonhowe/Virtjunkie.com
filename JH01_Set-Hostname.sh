#!/bin/bash

echo "Server will reboot after this process completes" |& tee -a /var/log/oscustomization.log
echo "Current hostname is $(hostname). Hostname will be changed to $1" |& tee -a /var/log/oscustomization.log
hostnamectl set-hostname $1
reboot now
