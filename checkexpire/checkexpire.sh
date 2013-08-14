#!/bin/bash

VERSION="0.1"

DIRECTORY=$(cd `dirname $0` && pwd)

DOMAINSFILE="$DIRECTORY/domains.txt"

DNSSRV=$1
DNSMAS=$2

GLOBALEL=0
GLOBALELDIF=0

MESS=""

DIG="/usr/bin/dig +time=2 +tries=1 +short"

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

STATE=$STATE_OK

usage()
{
cat << EOF
version: $VERSION

usage: $0 -m <masterns> -s <slavens> [-v]

OPTIONS:
   -h      Show this message
   -m     Master NS
   -s	   Slave NS
   -v      Verbose

DOMAINS FILE:
   crate a file $DOMAINSFILE containing the domains to check, one per line

EOF
}

if [ ! -f $DOMAINSFILE ]
then
  echo "File $DOMAINSFILE not found"
  usage
  exit $STATE_UNKNOWN
fi

while getopts ":s:m:vh" opt; do
  case $opt in
    s)
      DNSSRV=$OPTARG
      ;;
    m)
      DNSMAS=$OPTARG
      ;;
    v)
      _V=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit $STATE_UNKNOWN
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit $STATE_UNKNOWN
      ;;
  esac
done

if [[ -z $DNSSRV ]] || [[ -z $DNSMAS ]] 
then
     usage
     exit $STATE_UNKNOWN
fi

function log () {
    if [[ $_V -eq 1 ]]; then
        echo "$@"
    fi
}

while read domain
do

  if [[ $domain =~ ^\#.* ]]
  then 
    log Ignore $domain
    continue
  fi

  SLAVE=`$DIG @$DNSSRV $domain SOA`

  EL=$?

  if [ $EL -eq 0 ]
  then
    if [[ -z $SLAVE ]]
    then
      log WARN NO Answer $DNSSRV $domain
      MESS="$MESS WARN NO Answer $DNSSRV $domain --"
      GLOBALEL=3
      STATE=$STATE_CRITICAL
    else
      log OK $DNSSRV $domain
      #MESS="$MESS OK $DNSSRV $domain --"
    fi
  else
    log WARN $DNSSRV $domain
    MESS="$MESS WARN $DNSSRV $domain --"
    GLOBALEL=1
    STATE=$STATE_CRITICAL
  fi

  MASTER=`$DIG @$DNSMAS $domain SOA`

  EL2=$?

  log SLAVE $SLAVE
  log MASTER $MASTER
#  log $EL2

  if [ $EL2 -eq 0 ]
  then
    if [ "$SLAVE" == "$MASTER" ]
    then
      log OK diff $DNSSRV $DNSMAS $domain SOA
      #MESS="$MESS OK diff $DNSSRV $DNSMAS $domain SOA --"
    else
      log WARN diff $DNSSRV $DNSMAS $domain SOA
      MESS="$MESS WARN diff $DNSSRV vs $DNSMAS $domain SOA --"
      log $MASTER -- $SLAVE
      GLOBALELDIF=1
      STATE=$STATE_WARNING
    fi
  else
    log PROBLEM contacting $DNSMAS
    MESS="$MESS PROBLEM contacting $DNSMAS --"
    GLOBALELDIF=2
    STATE=$STATE_WARNING
  fi

  log ""

done < <(cat $DOMAINSFILE)

log "Final Response EL $GLOBALEL"
log "Final Difference EL $GLOBALELDIF"

if [[ -z $MESS ]]
then
  echo "All seems to be okay"
else
  echo $MESS
fi

#echo $STATE
exit $STATE
