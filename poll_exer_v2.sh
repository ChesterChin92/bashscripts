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
	dev_arr[$device_index]=$(echo ${OPTARG} )
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
  total_count=$(( $total_count+$int_count ))
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
   dev_int2[$a]=`get_dev_intr "${devices_arr[${a}]}"`
   echo "dev_arr = ${dev_arr[$a]}" >&2
   dev_int_all=$( printf "%s:" "${dev_int2[@]}" )
   echo "dev_int_all1 = ${dev_int_all}" >&2
 done
 echo "overall dev_arr = ${dev_arr[@]}" >&2
 dev_arr_all=$( printf "%s:" "${dev_arr[@]}" )
 echo "all of dev_arr = ${dev_arr_all}" >&2
 dev_int_all_arr[$i]=${dev_int_all}
 dev_int_all2=$( printf "%s," "${dev_int_all_arr[@]}" )
 echo "dev_int_all2 = ${dev_int_all2}" >&2
 #dev_name[$i]=`get_dev_intr "$device_name"`
 mem_total[$i]=`get_dev_mem "MemTotal"`
 mem_total_all=$( printf "%s," "${mem_total[@]}" )
 mem_free[$i]=`get_dev_mem "MemFree"`
 mem_free_all=$( printf "%s," "${mem_free[@]}" )
 mem_active[$i]=`get_dev_mem "Active"`
 mem_active_all=$( printf "%s," "${mem_active[@]}" )
 sleep 1
 echo ""
done
echo "all mem total = ${mem_total_all}" >&2
echo "all mem free = ${mem_free_all}" >&2
echo "all mem active = ${mem_active_all}" >&2
#report | sed -e "s#CPUCOUNT#$cpu_count#g" \
# -e "s#MODELNAME#$model_name#g" \
# -e "s#CPUMHZ#$cpu_mhz#g" \
# -e "s#TOTALCOUNT#${mem_total[*]}#g" \
# -e "s#FREECOUNT#${mem_free[*]}#g" \
# -e "s#ACTIVECOUNT#${mem_active[*]}#g" \
# -e "s#DEVNAME1#${devices_arr[0]}#g" \
# -e "s#DEVNAME2#${devices_arr[1]}#g" \
# -e "s#DEVNAME3#${devices_arr[2]}#g" \
# -e "s#POLLCOUNT#$poll_count#g" > $input_file

#awk -v npolls=$poll_count -v cpus=$cpu_count -v another_var=3.142 '
#BEGIN {
#  print("in awk");
#  print("argc = " ARGC);
#  print("npolls = " npolls);
#  print("cpus = " cpus);
#  print("another var = " another_var);
  #system("snap=`cat /proc/meminfo | grep \"$1:\" | cut -d':' -f2 | sed -e \"s# kB##g\"`");
  #system("echo $snap");
#  exit;
#}'

awk -v npolls="$poll_count" -v polltxt="$input_file" -v ndevices="$device_index" -v array_dev="${dev_arr_all}" -v array_dev_int="${dev_int_all2}" -v array_mem_total="${mem_total_all}" -v array_mem_free="${mem_free_all}" -v array_mem_active="${mem_active_all}" -v awk_cpu_count="${cpu_count}" -v awk_model_name="${model_name}" -v awk_cpu_mhz="${cpu_mhz}" '

function get_all_polls_for_a_device(device_index,overall_polls)
{
  all_polls_of_device="";
  split(overall_polls,each_poll_dev_int,",");
  displayed_poll=1;
  for (m in each_poll_dev_int)
  {
    if (each_poll_dev_int[m]=="")
      continue;
    split(each_poll_dev_int[m],poll_per_dev,":");
	device_index_temp=1;
    for (n in poll_per_dev)
    {
      if (poll_per_dev[n]=="")
        continue;
	  if (device_index_temp==device_index)
	  {
	    all_polls_of_device=all_polls_of_device displayed_poll ". " poll_per_dev[n] "   ";
		displayed_poll++;
		break;
	  }
	  else
	  {
	    device_index_temp++;
      }
    }
  }
  return all_polls_of_device;
}

function get_all_polls_for_memory(memory_polls)
{
  all_polls_of_memory="";
  split(memory_polls,individual_memory_poll,",");
  for (m in individual_memory_poll)
  {
    if (individual_memory_poll[m]=="")
      continue;
    all_polls_of_memory=all_polls_of_memory m ". " individual_memory_poll[m] "   ";
  }
  return all_polls_of_memory;
}

BEGIN {
  print "in awk" > polltxt;
  print("in awk");
  print("argc = " ARGC);
  print("npolls = " npolls);
  print("poll_file = " polltxt);
  print("array of devices = " array_dev);
  print("total devices = " ndevices);
  
  print "=========" > polltxt;
  print "CPU INFO" > polltxt;
  print "=========" > polltxt;
  print "CPU Count: " awk_cpu_count > polltxt;
  print "Model name: " awk_model_name > polltxt;
  print "CPU MHz: " awk_cpu_mhz > polltxt;
  print "" > polltxt;
  print "===============" > polltxt;
  print "Interrupt Count" > polltxt;
  print "===============" > polltxt;
  
  split(array_dev,each_dev,":");
  split(array_dev_int,each_poll_dev_int,",");
  #for (m in each_poll_dev_int)
  #{
  #  if (each_poll_dev_int[m]=="")
  #    continue;
  #  split(each_poll_dev_int[m],poll_per_dev,":");
  #  print "Poll " m ":" > polltxt;
  #  for (n in poll_per_dev)
  #  {
  #    if (poll_per_dev[n]=="")
  #      continue;
  #    print "  " each_dev[n] ": " poll_per_dev[n] > polltxt;
  #  }
  #}
  #print "================" > polltxt;
  for (m in each_dev)
  {
    if (each_dev[m]=="")
	  continue;
    print "  " each_dev[m] ": " get_all_polls_for_a_device(m,array_dev_int) > polltxt;
  }
  
  print "" > polltxt;
  print "==============" > polltxt;
  print "System Memory" > polltxt;
  print "==============" > polltxt;
  
  #split(array_mem_total,each_poll_mem_total,",");
  #split(array_mem_free,each_poll_mem_free,",");
  #split(array_mem_active,each_poll_mem_active,",");  
  #for (j in each_poll_mem_total)
  #{
  #  if (each_poll_mem_total[j]=="")
  #    continue;
  #  print "Poll " j ":" > polltxt;
  #  print "  MemTotal (kB): " each_poll_mem_total[j] > polltxt;
  #  print "  MemFree (kB): " each_poll_mem_free[j] > polltxt;
  #  print "  MemActive (kB): " each_poll_mem_active[j] > polltxt;
  #}
  #print "=================" > polltxt;
  print "  MemTotal (kB): " get_all_polls_for_memory(array_mem_total) > polltxt;
  print "  MemFree (kB): " get_all_polls_for_memory(array_mem_free) > polltxt;
  print "  MemActive (kB): " get_all_polls_for_memory(array_mem_active) > polltxt;
  
  #x="'"`date`"'"
  x='"\"`date`\""';
  print "" > polltxt;
  print "Created at " x " for " npolls " poll(s)." > polltxt;  

  exit;
}'

#awk '{
#  #sn="'"`cat /proc/interrupts | grep timer | cut -c6-`"'"
#  sn='"\"`cat /proc/interrupts | grep timer | cut -c6-`\""';	#error: causes "runaway string constant".
#  print "try, sn = "sn;
#  exit;
#}'

awk ' BEGIN{
x="'"`date`"'"
printf "try, %s\n",x
exit;
}'

#ref:
### I've used a comma as a separator; use whatever is appropriate
#array=$( printf "%s," "${add_ct_arr[@]}" )
#awk -v add_ct_arr="$array" 'BEGIN { split(add_ct_arr,ct_array,",") }
#...'

#ref: runaway string constant
#Problem: awk -F":"  'OFS = ":"{ $1 = "'$NewTitle'" ; print $0 } ' Database.txt> Database2.txt
#Solution1: awk -F":" -v var="$new_title" 'OFS = ":"{ $1 = var ; print $0 }' testfile
#Solution2: $1 = '"\"$NewTitle\""'
