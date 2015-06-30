#README

Tested on linux centos

You have to download and unzip instantclient-sqlplus-linux and instantclient-basiclite-linux from
http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html
And place it anywhere useful on your Nagios server.

In the script you need to change ORACLE_HOME accordingly to your environment.

### Examples

```./check_oracle_query.sh -H 192.168.1.10 -u user -w pass -p 1521 -s SID -n ID -q "select * from table" -e "^[1-9].* rows selected"```

```./check_oracle_query.sh -H 10.0.0.47 -u user -w pass -p 1521 -s SID01 -n ID1 -q "select * from dual" -e "^X"```
