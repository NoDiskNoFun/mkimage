#!/bin/bash

 function create_loop_devices() {
 	if ! test -e /dev/loop-control; then
 	  display_alert "creating loop control device" "/dev/loop-control"
 	  run_host_command_logged mknod /dev/loop-control c 10 237
 	fi

 	local i
 	for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
 	if ! test -e /dev/loop${i}; then
 	  display_alert "creating loop device" "/dev/loop${i}"
 	  run_host_command_logged mknod /dev/loop${i} b 7 ${i}
 	fi
 	done
 }

 function dolosetup(){
 	local loopdev=$1
 	local image_file=$2
 	if test -z "${image_file}"; then
 	  exit_with_error "image file not specified"
 	fi
 	if ! test -e $image_file; then
 	  exit_with_error "image file ${image_file} not found"
 	fi

 	if test -z "${loopdev}"; then
 	  exit_with_error "loop device not specified"
 	fi
 	display_alert "loop device" "${loopdev}" "debug"
 	if ! test -e ${loopdev}; then
 	  exit_with_error "image file ${loopdev} not found"
 	fi

 	run_host_command_logged losetup -P ${loopdev} ${image_file}
 	#check that loop device is linked
 	local lochk=$(losetup -j ${image_file} |sed 's/: .*$//')
 	if test "${lochk}" != "${loopdev}" ; then
 	  exit_with_error "losetup unable to setup ${loopdev}"
 	fi

 	# drop the first line, as this is our loopdev itself, but we only want the child partitions
 	local partitions=$(lsblk --raw --output "MAJ:MIN" --noheadings ${loopdev} | tail -n +2)
 	if echo ${partitions} | egrep -q "[[:digit:]]:[[:digit:]].*" ; then
 	  local counter=1
 	  for i in $partitions; do
 	    local maj=$(echo $i | cut -d: -f1)
 	    local min=$(echo $i | cut -d: -f2)
 	    display_alert "partition" "${loopdev}p${counter} b ${maj} ${min}" "debug"
 	    if [ ! -e "${loopdev}p${counter}" ]; then
 	      display_alert "create partition loop device" "${loopdev}p${counter} b ${maj} ${min}"
 	      mknod ${loopdev}p${counter} b ${maj} ${min}
 	    fi
 	    counter=$((counter + 1))
 	  done
 	else
 	  exit_with_error "cannot get MAJ:MIN ${maj}:${min} from lsblk"
 	fi
 }

 $1 $2 $3
