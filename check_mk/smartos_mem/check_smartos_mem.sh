#!/usr/bin/env bash
# Check free memory in SmartOS
# Regards the ARC as free memory
#
# Adapted in order to work with check_mk
# Alessio Ciregia
# Based on the work of Marcus Wilhelmsson
# License: MIT
#

WARN="85"
CRIT="95"

# Function for getting and printing mem stats
getmemstats () {
        # Get stats
    declare -i pagesize=`pagesize`
        declare -i physpages=`kstat -p unix:0:system_pages:pagestotal | awk '{print $2}'`
    declare -i freepages=`kstat -p unix:0:system_pages:pagesfree | awk '{print $2}'`
    declare -i arcsize=`kstat -p zfs:0:arcstats:size | awk '{print $2}'`
    declare -i arcsizemb=$arcsize/1024/1024;

        # Convert stats to megabytes and percent
        declare -i totalmemorymb=$physpages*$pagesize/1024/1024
        declare -i freememorymb=$freepages*$pagesize/1024/1024+$arcsizemb
        declare -i usedmemorymb=$totalmemorymb-$freememorymb
        declare -i usedmempercent=`echo "$usedmemorymb*100/$totalmemorymb" | bc`
        declare -i freemempercent=100-$usedmempercent

        #Print monitoring info
        if [ $usedmempercent -lt $WARN ]; then
                echo -e "0 check_mem usedmempercent=$usedmempercent;$WARN;$CRIT OK: Total mem: $totalmemorymb MB Free mem: $freememorymb ($freemempercent%) MB Used mem: $usedmemorymb ($usedmempercent%) MB"
                exit 0

        elif [ $usedmempercent -gt $WARN ] && [ $usedmempercent -lt $CRIT ] || [ $usedmempercent -eq $WARN ]; then
                echo -e "1 check_mem usedmempercent=$usedmempercent;$WARN;$CRIT WARNING: Total mem: $totalmemorymb MB Free mem: $freememorymb ($freemempercent%) MB Used mem: $usedmemorymb ($usedmempercent%) MB"

        elif [ $usedmempercent -gt $CRIT ] || [ $usedmempercent -eq $CRIT ]; then
                echo -e "2 check_mem usedmempercent=$usedmempercent;$WARN;$CRIT CRITICAL: Total mem: $totalmemorymb MB Free mem: $freememorymb ($freemempercent%) MB Used mem: $usedmemorymb ($usedmempercent%) MB"
                exit 2
        else
                echo -e "3 check_mem - ERROR"
        fi
}


# Call function to get memory stats
getmemstats
