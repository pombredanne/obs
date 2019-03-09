#!/bin/sh
# Output single-line hardware description
#   model ; cpu ; RAM ; disk ; GPU

model() {
   if test -d /Library
   then
      sysctl -n hw.model
   else
      sudo dmidecode -s system-manufacturer | sed 's/ Inc\.//' | tr '\012' ' '
      sudo dmidecode -s system-product-name | sed 's/Precision Tower //'
   fi
}

cpu() {
   if test -d /Library
   then
      sysctl -n machdep.cpu.brand_string | sed 's/.*) //;s/ CPU.*//'
   else
      cat /proc/cpuinfo | grep 'model name' | sed 's/.*: //;s/(R)//;s/(TM)//;s/ CPU//;s/Core //' | sort -u
   fi
}

ram() {
   if test -d /Library
   then
      sysctl -n hw.memsize | awk '{printf "%sG\n", $1 / (1024*1024*1024)'}
   else
      free -h | awk '/Mem:/ {print $2}'
   fi
}

disk() {
   if test -d /Library
   then
      diskutil info disk0 | grep 'Media Name' | sed 's/.*://;s/^ *//'
   else
      device=$(df / | grep dev | sed 's, .*,,;s,/dev/,,;s/p[0-9]*$//')
      cat /sys/block/$device/device/model
   fi
}

gpu() {
   if test -d /Library
   then
      system_profiler SPDisplaysDataType | grep 'Chipset Model' | sed 's/.*: //'
   else
      lspci | grep VGA | sed 's/.*: //;s/Corporation //;s/ (rev.*)//'
   fi
}

(
   model
   cpu
   ram
   disk
   gpu
) | sed 's/  *$//' | tr '\012' ';' | sed 's/;$/|/;s/;/; /g' | tr '|' '\012'
