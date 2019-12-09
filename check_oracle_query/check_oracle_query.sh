#!/bin/bash

ORACLE_HOME=/usr/local/instantclient_12_1
PATH=$ORACLE_HOME:$PATH
LD_LIBRARY_PATH=$ORACLE_HOME
export ORACLE_HOME
export LD_LIBRARY_PATH
export PATH

print_help()
{
    cat <<EOF
Usage: H:u:w:p:s:n:q:e:h

A Nagios Plugin that checks SL500 library

Options:
  -h    --help          print this help message
  TODO

Examples:
  TODO

EOF
}


SHORTOPTS="H:u:w:p:s:n:q:e:h"
LONGOPTS="host,user,pass,port,sid,nagiosid,query,expected,help"

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
            oraclehost=$2
            shift 2
            ;;
        -u)
            user=$2
            shift 2
            ;;
        -w)
            password=$2
            shift 2
            ;;
        -p)
            port=$2
            shift 2
            ;;
        -s)
            sid=$2
            shift 2
            ;;
        -n)
            nagiosid=$2
            shift 2
            ;;
        -e)
            expected=$2
            shift 2
            ;;
        -q)
            query=$2
            shift 2
            ;;
        -q)
            query=$2
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

if [ -z ${oraclehost} ] || [ -z ${user} ] || [ -z ${password} ] || [ -z ${port} ] || [ -z ${sid} ] || [ -z ${nagiosid} ] || [ -z "${expected}" ] || [ -z "${query}" ]
then
        echo "Please set all the options"
        print_help
fi

FILECONTROLLO=/tmp/controllo${nagiosid}.$$
NAGERR=0

touch ${FILECONTROLLO}

sqlplus -L ${user}/${password}@"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(Host=${oraclehost})(Port=${port}))(CONNECT_DATA=(SID=${sid})))" &> ${FILECONTROLLO} <<EOF
set pages 0
whenever sqlerror exit sql.sqlcode;
set echo off
set heading off
set numw 20
SPOOL ${FILECONTROLLO}
${query};
SPOOL OFF
exit
EOF

EL=$?

if [ $EL -eq 0 ]
then

  grep -q -E "${expected}" ${FILECONTROLLO}
  EL=$?

  if [ $EL -eq 0 ]
  then

    NAGERR=0
    MSG="OK"

  else

    NAGERR=1
    MSG="Connessione a Oracle ok ma query non ritorna il risultato atteso"

  fi

else

  MSG="Errore connessione a Oracle"
  NAGERR=2

fi

ORAMSG=`grep -E "ORA-.*:" ${FILECONTROLLO}`

[ -f ${FILECONTROLLO} ] && rm -f ${FILECONTROLLO}

echo ${MSG} $ORAMSG
exit ${NAGERR}
