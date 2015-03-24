## Description

This check makes the inventory of the active zones on a Solaris or SmartOS global zone and it raise a warning if a zone is not in the running state.

## Installation

Put the file `agent/check_zones` in the `check_mk_agent/plugins` directory in the check_mk agent machine (in the global zone).

Put the `server/zones` file in the `/opt/omd/versions/1.20/share/check_mk/checks/` directory on the Nagios machine.
