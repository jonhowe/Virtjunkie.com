#__      ___      _       _             _    _      
#\ \    / (_)    | |     | |           | |  (_)     
# \ \  / / _ _ __| |_    | |_   _ _ __ | | ___  ___ 
#  \ \/ / | | '__| __|   | | | | | '_ \| |/ / |/ _ \
#   \  /  | | |  | || |__| | |_| | | | |   <| |  __/
#    \/   |_|_|   \__\____/ \__,_|_| |_|_|\_\_|\___|
                                                  
#Jon Howe
#https://www.virtjunkie.com/Poor-Mans-AutoDeploy
#https://github.com/jonhowe/Virtjunkie.com/tree/master/PoorMansAutoDeploy

import os, csv, subprocess

CSVPATH = '/ListOfHosts.csv'

#Gets all mac addresses of interfaces
MAC=subprocess.check_output("esxcli network ip interface list |grep MAC | cut -d ' ' -f 6",shell=True)
                                                                                                                                                                                                                                                                                    
MACADDR = MAC.split()
print("MAC Addresses:")
print(MACADDR)

#Open the CSV file
with open(CSVPATH, 'rt') as csvFile:
        csvReader = csv.reader(csvFile)
        #Process the CSV file, row by row
        for csvRow in csvReader:
                #Check to see if the Mac Address of vmnic0 (IE: MACADDR[0]) matches the row in the CSV we are looking at
                if ((MACADDR[0]).decode('utf-8')) == csvRow[1]:
                        #print("esxcli system hostname set --fqdn=" + csvRow[0])
                        #print("esxcli network ip interface ipv4 set --interface-name=vmk0 --ipv4=" + csvRow[2] + " --netmask=" + csvRow[3] + " --type=static")
                        
                        #Set the hostname to the value in the CSV
                        os.system("esxcli system hostname set --fqdn=" + csvRow[0])
                        
                        #Set the IP Address and Netmask of vmk0
                        os.system("esxcli network ip interface ipv4 set --interface-name=vmk0 --ipv4=" + csvRow[2] + " --netmask=" + csvRow[3] + " --type=static")
                        
                        #Add the default gateway
                        os.system("esxcfg-route " + csvRow[4])
                        
                        #Add the desired VLAN for the Management Network on the vSwitch that gets created by default (vSwitch0)
                        os.system("esxcfg-vswitch -p 'Management Network' -v " + csvRow[5] + " vSwitch0")
