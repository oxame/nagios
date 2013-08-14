#!/bin/sh

SNMPGETPATH="/usr/bin/snmpget"
SNMPGETOPTIONS="-t 1 -r 5"
SNMPGET="${SNMPGETPATH} ${SNMPGETOPTIONS}"


STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

version=0.1
progname=$(basename $0)

avalilabe_checks="fan | temp | robot | cap | controller | toplevel | load | liblsmstatus"

print_help()
{
    cat <<EOF

Usage: check_sl500.sh -H <host> -v <version> -c <community> -k <kind>

A Nagios Plugin that checks SL500 library

Options:
  -h 	--help	 	print this help message
  -V 	--version	print version and license
  -H			host to check		
  -v			SNMP version (currently only 2c)
  -c			SNMP community
  -k			kind of check: ${avalilabe_checks}
  -d			print debug lines
  
Examples:

To check drive temperature status
  $ ./check_sl500.sh -H 192.168.0.2 -v 2c -c public -k temp

Report bugs and enanchements to <alessio@ftgm.it>
EOF
} #

print_version()
{
    cat <<EOF

$progname $version - nagios plugin for Sun StorageTek(TM) SL500 Modular Library System

Written by Alessio Ciregia (alessio@ftgm.it) 
Fondazione Toscana Gabriele Monasterio per la Ricerca Medica e di Sanità Pubblica 
CNR - Regione Toscana

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
EOF
} #

SHORTOPTS="H:v:c:k:dhV"
LONGOPTS="host,version,community,kind,debug,help,version"

if $(getopt -T >/dev/null 2>&1) ; [ $? = 4 ] ; then # New longopts getopt.
    OPTS=$(getopt -o $SHORTOPTS --long $LONGOPTS -n "${progname}" -- "$@")
else # Old classic getopt.
    # Special handling for --help and --version on old getopt.
    case $1 in --help) print_help ; exit 0 ;; esac
    case $1 in --version) print_version ; exit 0 ;; esac
    OPTS=$(getopt $SHORTOPTS "$@")
fi

if [ $? -ne 0 ]; then
    print_help;
    exit 1
fi

eval set -- "${OPTS}"

if test $# -le 1
then
    print_help
    exit 1;
fi;

snmp_host="0.0.0.0"
snmp_version="2c"
snmp_community="public"
while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            print_help
            exit 0
            ;;
        -V|--version)
            print_version
            exit 0
            ;;
        -H)
            snmp_host=$2
            shift 2
            ;;
        -v)
			   snmp_version="2c"
            shift 2
            ;;    
        -c)
            snmp_community=$2
            shift 2
            ;;
        -k)
	    		kind=$2
            shift 2
       	    ;;
        -d)
        		debug="yes"
        		shift
        		;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal Error: option processing error: $1" 1>&2
            exit 1
            ;;
    esac
done

if [ "${snmp_version}" = "2c" ]
then
	SNMPGET="${SNMPGET} -v ${snmp_version} -c ${snmp_community} ${snmp_host}"
fi

verbose()
{
	if [ "${debug}" = "yes" ]
	then
		echo $@
	fi
}

kind_fan() 
{
	oid_fan_count=".1.3.6.1.4.1.1211.1.15.4.5.0"
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_fan_count}"
	fancount=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${fancount}"
	i=1
	result=""
	state=${STATE_OK}
	while [ $i -le ${fancount} ]; do
		oid_fan_name=".1.3.6.1.4.1.1211.1.15.4.6.1.2"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_fan_name}.$i"
      fanname="`${SNMPGETCMD}`"
      verbose "command=${SNMPGETCMD}" "result=${fanname}"
		oid_fan=.1.3.6.1.4.1.1211.1.15.4.6.1.3
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_fan}.$i"
		fanstatus="`${SNMPGETCMD}`"
		verbose "command=${SNMPGETCMD}" "result=${fanstatus}"
		if [ ${fanstatus} -ne 2 ]
		then
			result="${result} $fanname CRIT ${fanstatus} -"
			state=$STATE_CRITICAL
		else
			result="${result} $fanname OK ${fanstatus} - "
		fi
		
		i=`expr $i + 1`
	done	
	
	echo ${result}
	exit ${state}
}


kind_temp()
{
	oid_temp_count=".1.3.6.1.4.1.1211.1.15.4.3.0"
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_temp_count}"
	tempcount=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${tempcount}"
	i=1
	state=$STATE_OK
	result=""
	while [ $i -le ${tempcount} ]; do
		oid_temp_name=".1.3.6.1.4.1.1211.1.15.4.4.1.2"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_temp_name}.$i"
		tempname=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${tempname}"
	
		oid_temp_warnthreshold=".1.3.6.1.4.1.1211.1.15.4.4.1.5"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_temp_warnthreshold}.$i"
		tempwarnthreshold=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${tempwarnthreshold}"
	
		oid_temp_failthershold=".1.3.6.1.4.1.1211.1.15.4.4.1.6"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_temp_failthershold}.$i"
		tempfailthreshold=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${tempfailthreshold}"
	
		oid_temp_value=".1.3.6.1.4.1.1211.1.15.4.4.1.3"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_temp_value}.$i"
		tempvalue=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${tempvalue}"
		
		# Low thresholds by 3 degree (rise an alarm before threshold is reached)
		tempwarnthresholdcrit=`expr ${tempwarnthreshold} - 3`
		tempfailthresholdcrit=`expr ${tempfailthreshold} - 3`
		verbose "Low threshold ${tempwarnthresholdcrit} High ${tempfailthresholdcrit}"
		
		if [ ${tempvalue} -lt ${tempwarnthresholdcrit} ]
		then
			result="${result} ${tempname} OK ${tempvalue} - "
		elif [ ${tempvalue} -gt ${tempwarnthresholdcrit} -a ${tempvalue} -lt ${tempfailthresholdcrit} ]
		then
			state=$STATE_WARNING
			result="${result} ${tempname} WARNING ${tempvalue}"
		else
			state=$STATE_CRITICAL
			result="${result} ${tempname} CRITICAL ${tempvalue}"
		fi
		
		i=`expr $i + 1`
	done
	
	echo ${result}
	exit ${state}
} 

kind_robot()
{
	oid_robot_count=".1.3.6.1.4.1.1211.1.15.4.9.0"
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_robot_count}"
	robotcount=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${robotcount}"
	i=1
	state=$STATE_OK
	result=""
	while [ $i -le $robotcount ]; do
		robot_id="$i"
		oid_robot_status=".1.3.6.1.4.1.1211.1.15.4.10.1.8"
		# Robot operational status in enumerated form OK (0), Error (1), Warning (2), Info (3), Trace (4)
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_robot_status}.$i"
		robot_status=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${robot_status}"
		case ${robot_status} in
			0)
				result="${result} robot${robot_id} OK ${robot_status} - "
				;;
			1)
				state=$STATE_CRITICAL
				result="${result} robot${robot_id} Error ${robot_status} - "
				;;
			2)
				state=$STATE_WARNING
				result="${result} robot${robot_id} Warning ${robot_status} - "
				;;
			3)
				state=$STATE_WARNING
				result="${result} robot${robot_id} Warning ${robot_status} - "
				;;
			4)
				state=$STATE_WARNING
				result="${result} robot${robot_id} Warning ${robot_status} - "
				;;
			*)
				state=$STATE_UNKNOWN
				result="${result} robot${robot_id} UNKNOWN - "
				;;
		esac
		
		i=`expr $i + 1`
	done
	
	echo ${result}
	exit ${state}
}

kind_controller()
{
	oid_controller_count=".1.3.6.1.4.1.1211.1.15.4.13.0"
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_controller_count}"
	controllercount=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${controllercount}"
	i=1
	state=$STATE_OK
	result=""
	while [ $i -le ${controllercount} ]; do
		oid_controller_sn=".1.3.6.1.4.1.1211.1.15.4.14.1.3"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_controller_sn}.$i"
		controller_sn=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${controller_sn}"
		
		oid_controller_status=".1.3.6.1.4.1.1211.1.15.4.14.1.4"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_controller_status}.$i"
		controller_status=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${controller_status}"
		
		case ${controller_status} in
			0)
				result="${result} controllerSN ${controller_sn} status OK ${controller_status} -"
				;;
			*)
				state=$STATE_CRITICAL
				result="${result} controllerSN ${controller_sn} status CRIT ${controller_status} -"
				;;
		esac
		
		oid_controller_status_enum=".1.3.6.1.4.1.1211.1.15.4.14.1.7"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_controller_status_enum}.$i"
		controller_status_enum=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${controller_status_enum}"
		
		case ${controller_status_enum} in
			0)
				result="${result} controllerSN ${controller_sn} statusenum OK ${controller_status_enum} -"
				;;
			*)
				state=$STATE_CRITICAL
				result="${result} controllerSN ${controller_sn} statusenum CRIT ${controller_status_enum} -"
				;;
		esac
		
		i=`expr $i + 1`
	done
	
	echo ${result}
	exit ${state}
}

kind_cap()
{
	oid_cap_count=".1.3.6.1.4.1.1211.1.15.4.19.0"
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_cap_count}"
	capcount=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${capcount}"
	i=1
	state=$STATE_OK
	result=""
	while [ $i -le $capcount ]; do
		oid_cap_address=".1.3.6.1.4.1.1211.1.15.4.20.1.2"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_cap_address}.$i"
		cap_address=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${cap_address}"
		
		# slCapAccessStateEnum Access state of the CAP presented as an enumeration Unknown (1), Open (2), Close (3)
		oid_cap_accessstate=".1.3.6.1.4.1.1211.1.15.4.20.1.4"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_cap_accessstate}.$i"
		cap_accessstate=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${cap_accessstate}"
		case ${cap_accessstate} in
			3)
				result="${result} cap ${cap_address} access state Close ${cap_accessstate} -"
				;;
			2)
				state=$STATE_WARNING
				result="${result} cap ${cap_address} access state Open ${cap_accessstate} -"
				;;
			1)
				state=$STATE_CRITICAL
				result="${result} cap ${cap_address} access state Unknown ${cap_accessstate} -"
				;;
			*)
				state=$STATE_UNKNOWN
				result="${result} cap ${cap_address} access state UNKNOWN"
				;;
		esac
		
		
		# slCapStatusEnum Operational status of the CAP presented as an enumeration OK (0), Error (1), Warning (2), Info (3), Trace (4)
		oid_cap_statusenum=".1.3.6.1.4.1.1211.1.15.4.20.1.6"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_cap_statusenum}.$i"
		cap_statusenum=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=$cap_statusenum"
		case ${cap_statusenum} in
			0)
				result="${result} cap ${cap_address} statusenum OK $cap_statusenum -"
				;;
			1)
				state=$STATE_CRITICAL
				result="${result} cap ${cap_address} statusenum Error $cap_statusenum -"
				;;
			2)
				state=$STATE_CRITICAL
				result="${result} cap ${cap_address} statusenum Warning $cap_statusenum -"
				;;
			3)
				state=$STATE_CRITICAL
				result="${result} cap ${cap_address} statusenum Info $cap_statusenum -"
				;;
			4)
				state=$STATE_CRITICAL
				result="${result} cap ${cap_address} statusenum Trace $cap_statusenum -"
				;;
			*)
				state=$STATE_UNKNOWN
				result="${result} cap ${cap_address} statusenum UNKNOWN"
				;;
		esac
		
		oid_cap_state=".1.3.6.1.4.1.1211.1.15.4.20.1.5"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_cap_state}.$i"
		cap_state=`${SNMPGETCMD}`
		verbose "command=${SNMPGETCMD}" "result=${cap_state}"
		
		if [ "${cap_state}" != "closed" ]
		then
			state=$STATE_WARNING
			result="${result} cap ${cap_address} state ${cap_state}"
		else
			result="${result} cap ${cap_address} state ${cap_state}"
		fi
		
		i=`expr $i + 1`
	done
	
	echo ${result}
	exit ${state}
}

kind_load()
{
	oid_load1=".1.3.6.1.4.1.2021.10.1.3.1"
	oid_load5=".1.3.6.1.4.1.2021.10.1.3.2"
	oid_load15=".1.3.6.1.4.1.2021.10.1.3.3"
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_load1}"
	load1=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${load1}"
	
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_load5}"
	load5=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${load5}"
	
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_load15}"
	load15=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${load15}"

	load_warn_thresholds="15,10,5"
	load_crit_thresholds="30,25,20"
	
	verbose `printf "%.0f\n" ${load1}` -gt `echo $load_warn_thresholds | awk -F , '{ print $1 }'`
	verbose `printf "%.0f\n" ${load5}` -gt `echo $load_warn_thresholds | awk -F , '{ print $2 }'`
	verbose `printf "%.0f\n" ${load15}` -gt `echo $load_warn_thresholds | awk -F , '{ print $3 }'`
	verbose `printf "%.0f\n" ${load1}` -gt `echo $load_crit_thresholds | awk -F , '{ print $1 }'`
	verbose `printf "%.0f\n" ${load5}` -gt `echo $load_crit_thresholds | awk -F , '{ print $2 }'`
	verbose `printf "%.0f\n" ${load15}` -gt `echo $load_crit_thresholds | awk -F , '{ print $3 }'`
	
	
	if [ `printf "%.0f\n" ${load1}` -gt `echo $load_crit_thresholds | awk -F , '{ print $1 }'` \
			-o `printf "%.0f\n" ${load5}` -gt `echo $load_crit_thresholds | awk -F , '{ print $2 }'` \
			-o `printf "%.0f\n" ${load15}` -gt `echo $load_crit_thresholds | awk -F , '{ print $3 }'` ]
	then
		verbose Crit
		state=$STATE_CRITICAL
		result="Critical: Very high load ${load1},${load5},${load15}"
	elif [ `printf "%.0f\n" ${load1}` -gt `echo $load_warn_thresholds | awk -F , '{ print $1 }'` \
			-o `printf "%.0f\n" ${load5}` -gt `echo $load_warn_thresholds | awk -F , '{ print $2 }'` \
			-o `printf "%.0f\n" ${load15}` -gt `echo $load_warn_thresholds | awk -F , '{ print $3 }'` ]
	then
		verbose Warn	
		state=$STATE_WARNING
		result="Warning: High load ${load1},${load5},${load15}"
	else
		verbose OK
		state=$STATE_OK
		result="Load OK ${load1},${load5},${load15}"
	fi
	
	echo ${result}
	exit ${state}
	
}


kind_toplevel() 
{
	# Library overall condition
	oid_toplevel_condition="1.3.6.1.4.1.1211.1.15.3.4.0"
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_toplevel_condition}"
	toplevel_condition=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${toplevel_condition}"
	i=1
	if [ ${toplevel_condition} -ne 0 ]
	then
		result="Library overall condition not normal ${toplevel_condition}"
		state=$STATE_CRITICAL
	else
		result="Library overall condition normal ${toplevel_condition}"
	fi
		
	echo ${result}
	exit ${state}
}


kind_LibLSMStatus() 
{
	oid_LibLSMCount=".1.3.6.1.4.1.1211.1.15.3.9.1.0"
	SNMPGETCMD="${SNMPGET} -Ovq ${oid_LibLSMCount}"
	LibLSMCount=`${SNMPGETCMD}`
	verbose "command=${SNMPGETCMD}" "result=${LibLSMCount}"
	i=1
	result=""
	state=${STATE_OK}
	while [ $i -le ${LibLSMCount} ]; do
		oid_slLibLSMStatus=".1.3.6.1.4.1.1211.1.15.3.9.2.1.2"
		SNMPGETCMD="${SNMPGET} -Ovq ${oid_slLibLSMStatus}.$i"
      slLibLSMStatus="`${SNMPGETCMD}`"
      verbose "command=${SNMPGETCMD}" "result=${slLibLSMStatus}"
		if [ ${slLibLSMStatus} != "\"available\"" ]
		then
			result="${result} LibLSM.$i CRIT ${slLibLSMStatus} -"
			state=$STATE_CRITICAL
		else
			result="${result} LibLSM.$i OK ${slLibLSMStatus} - "
		fi
		
		i=`expr $i + 1`
	done	
	
	echo ${result}
	exit ${state}
}


######
######

case ${kind} in
	"fan")
			kind_fan
			;;
	"temp")
			kind_temp
			;;
	"robot")
			kind_robot
			;;
	"controller")
			kind_controller
			;;
	"cap")
			kind_cap
			;;
	"load")
			kind_load
			;;
	"toplevel")
			kind_toplevel
			;;
	"liblsmstatus")
			kind_LibLSMStatus
			;;
	*)
			echo "You must specify the check you want to perform: \"-k [ ${avalilabe_checks} ]\""
			;;
esac
