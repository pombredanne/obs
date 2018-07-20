#!/bin/sh
(
sysctl -n hw.model 
sysctl -n machdep.cpu.brand_string | sed 's/.*) //;s/ CPU.*//'
system_profiler SPDisplaysDataType | grep 'Chipset Model' | sed 's/.*: //' 
) | tr '\012' ';' | sed 's/;$//;s/;/; /g'
