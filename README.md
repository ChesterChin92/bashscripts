# bashscripts
# Author : Chester Chin

This is a program to pull simple data from computer, use it to understand what is hapenning in the machine.

Sample Usage for poll_exer
./poll_exer.sh -f polltxt -p 5 -d timer -d eth -d ahci

Sample Usage for poll_exer_v2
./poll_exer_v2.sh -p 6 -d timer -d wifi -d eth -d usb -f mypolls

Take note that the script may not work on all computer because as I develop I did not include any consideration to handle all devices.

Hence if the program gives you an error try not to poll so many device typically USB and WIFI. (If you are running VM)
