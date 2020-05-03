#!/bin/bash
#This script was copied from /opt/vultr/configure_jitsi.sh on a Vultr VPS that has the one-click Jitsi App
#I added lines 7-9 to allow for adding parameters on the CLI and commented lines 11-13 to force the variables to be provided on the CLI
#https://www.vultr.com/docs/one-click-jitsi
#https://www.virtjunkie.com/jitsi-jit-conferencing-tf-vultr-route53/
#https://github.com/
HOSTNAME=$1
EMAIL=$2
response=$3
# User choices
#read -ep "Please specify which domain you would like to use: " HOSTNAME
#read -ep "Please enter your email address for Let's Encrypt Registration: " EMAIL
#read -r -p "Would you like to enable password authorization? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        AUTH=1
        ;;
    *)
        AUTH=0
        ;;
esac


PROSODYPATH=/etc/prosody/conf.avail/${HOSTNAME}.cfg.lua
JITSIPATH=/etc/jitsi/meet/${HOSTNAME}-config.js
JICOFOPATH=/etc/jitsi/jicofo/sip-communicator.properties

# Remove and purge (Stop first and wait to avoid race condition)
purgeold() {        
        /opt/vultr/stopjitsi.sh
        sleep 5
        apt -y purge jigasi jitsi-meet jitsi-meet-web-config jitsi-meet-prosody jitsi-meet-turnserver jitsi-meet-web jicofo jitsi-videobridge2 jitsi*
}

# Reinstall
reinstalljitsi() {
        echo "jitsi-videobridge2 jitsi-videobridge/jvb-hostname string ${HOSTNAME}" | debconf-set-selections
        echo "jitsi-meet-web-config jitsi-meet/cert-choice string Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)" | debconf-set-selections
        apt-get -y install jitsi-meet
}

# Remove nginx defaults
wipenginx() {
        rm -f /etc/nginx/sites-enabled/default
}

# Configure Lets Encrypt
configssl(){
    systemctl restart nginx
    sed -i -e 's/echo.*Enter your email and press.*/EMAIL=$1/' /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
    sed -i -e 's/read EMAIL//'  /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
    /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh ${EMAIL}
}

configprosody() {
  AUHTLINE='authentication = "internal_plain"'
  sed -i "s/authentication\ \=\ \"anonymous\"/${AUTHLINE}/g" ${PROSODYPATH}
  cat << EOT >> ${PROSODYPATH}

VirtualHost "guest.${HOSTNAME}"
    authentication = "anonymous"
    c2s_require_encryption = false

EOT
}

configjitsi() {
        sed -i "s/\/\/\ anonymousdomain\:\ 'guest.example.com',/anonymousdomain\:\ 'guest.${HOSTNAME}',/g" ${JITSIPATH}
}

configjicofo() {
        echo "org.jitsi.jicofo.auth.URL=XMPP:${HOSTNAME}" >> ${JICOFOPATH}
}

registeruser(){
        PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo;)
        prosodyctl register admin ${HOSTNAME} ${PASSWORD}
}

restartjitsi() {
        /opt/vultr/stopjitsi.sh
        /opt/vultr/startjitsi.sh
}

completedsetup(){
    echo ""
    echo "------------------------------"
    echo "|                            |"
    echo "|   JITSI SETUP COMPLETED!   |"
    echo "|                            |"
    echo "------------------------------"
    echo "JITSI URL: https://${HOSTNAME}"
    echo ""
}

outputUser(){
    echo "USERNAME: admin"
    echo "PASSWORD: ${PASSWORD}"
    echo ""
}

# Script start

purgeold
reinstalljitsi
wipenginx
configssl
if [ "$AUTH" == "1" ]; then
    configprosody
    configjitsi
    configjicofo
    registeruser
    restartjitsi    
fi
completedsetup
if [ "$AUTH" == "1" ]; then
    outputUser
fi