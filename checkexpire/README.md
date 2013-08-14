# checkexpire.sh


Nagios plugin to compare the slave and the master DNS nameservers SOA records

## Description

This script uses dig to query two dns servers and to compare the SOA record.
Useful to check if a slave zone is not in sync with the master.

## Usage

```./checkexpire.sh -m masterns.ip -s slavens.ip [-v]```

### Examples

NRPE

```command[check_dnsexpire]=/usr/lib/nagios/plugins/checkexpire.sh -m 10.96.11.144 -s localhost```

