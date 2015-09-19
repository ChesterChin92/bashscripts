#!/bin/bash
set -e

device_index=0

usage () {
cat << EOF
`basename $0` --help|-h
 - display usage of this script
`basename $0` -p <#polls>
 - poll the system for # of times (each poll is 1s lapse)
For example,
`basename $0` -f polltxt -p 2 -d timer
EOF
}
if [ $# -lt 2 ]; then
 usage
 exit 0
fi

if [ "$1" == "--help" -o "$1" == "-h" ]; then
 usage
 exit 0
fi

#if [ "$1" == "-p" ]; then
# poll_count=$2
#fi

while getopts "f:p:d:m:hv" opt; do
 case $opt in
 h) usage
  exit 0
  ;;
 v) echo "version = $VERSION "
  exit 0
  ;;
 f) input_file=$OPTARG
  ;;
 p) poll_count=$OPTARG
  ;;
 d) #device_name=$OPTARG
    devices_arr[$device_index]=$OPTARG
    device_index=$(( $device_index + 1 ))
  ;;
 m) cpu_mask=$OPTARG
  ;;
 *) usage
  exit 1
  ;;
 esac
done

report () {
cat << EOF
========
CPU INFO
========
Cpu Count:   CPUCOUNT
model name:  MODELNAME
cpu MHz:     CPUMHZ
===============
interrupt count
===============
//usb1: USBINT
//eth0: ETHINT //substituted by below
DEVNAME1: DEVINT1
DEVNAME2: DEVINT2
DEVNAME3: DEVINT3
===============
System Memory
==============
MemTotal(kB): TOTALCOUNT
MemFree (kB): FREECOUNT
Active  (kB): ACTIVECOUNT
Created at `date` for POLLCOUNT poll(s).
EOF
}
cpu_count=`cat /proc/cpuinfo | grep processor | wc -l`
model_name=`cat /proc/cpuinfo | grep "model name" -m 1 | cut -d":" -f2`
cpu_mhz=`cat /proc/cpuinfo | grep "cpu MHz" -m 1 | cut -d":" -f2`

get_dev_intr () 
{
 snap=`cat /proc/interrupts | grep $1 | cut -c6-`
 total_count=0
 for cpu in `seq 1 $cpu_count`
 do
  int_count=`echo $snap | cut -d' ' -f${cpu}`
  total_count=$(($total_count+$int_count))
 done
 echo ${total_count}
}

get_dev_mem () 
{
 snap=`cat /proc/meminfo | grep "$1:" | cut -d':' -f2 | sed -e "s# kB##g"`
 echo $snap
}

for i in `seq 1 $poll_count`
do
 #eth0_int[$i]=`get_dev_intr "eth0"`
 for (( a=0; a<$device_index; a++ ))
 do
   echo "element $a = ${devices_arr[${a}]}" >&2
   dev_int[$i,$a]=`get_dev_intr "${devices_arr[${a}]}"`
   echo "dev_int[$i,$a] = ${dev_int[$i,$a]}" >&2
 done
 #dev_name[$i]=`get_dev_intr "$device_name"`
 mem_total[$i]=`get_dev_mem "MemTotal"`
 mem_free[$i]=`get_dev_mem "MemFree"`
 mem_active[$i]=`get_dev_mem "Active"`
 sleep 1
 echo ""
done
report | sed -e "s#CPUCOUNT#$cpu_count#g" \
 -e "s#MODELNAME#$model_name#g" \
 -e "s#CPUMHZ#$cpu_mhz#g" \
 -e "s#DEVINT1#${dev_int[1,0]} ${dev_int[2,0]} ${dev_int[3,0]} ${dev_int[4,0]} ${dev_int[5,0]}#g" \
 -e "s#DEVINT2#${dev_int[1,1]} ${dev_int[2,1]} ${dev_int[3,1]} ${dev_int[4,1]} ${dev_int[5,1]}#g" \
 -e "s#DEVINT3#${dev_int[1,2]} ${dev_int[2,2]} ${dev_int[3,2]} ${dev_int[4,2]} ${dev_int[5,2]}#g" \
 -e "s#TOTALCOUNT#${mem_total[*]}#g" \
 -e "s#FREECOUNT#${mem_free[*]}#g" \
 -e "s#ACTIVECOUNT#${mem_active[*]}#g" \
 -e "s#DEVNAME1#${devices_arr[0]}#g" \
 -e "s#DEVNAME2#${devices_arr[1]}#g" \
 -e "s#DEVNAME3#${devices_arr[2]}#g" \
 -e "s#POLLCOUNT#$poll_count#g" > $input_file
exit 0

