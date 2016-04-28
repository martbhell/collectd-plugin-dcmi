#!/bin/bash

#    Fetch power consumption and inlet temperature, forward it to collectd
#    Copyright (C) 2016  Janne Blomqvist
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-60}"

# In principle DCMI is nice in that it provides a tighter specified subset of IPMI.
# For power consumption, this seems to work.
# However, for temperature readings, in practice:
# - some systems report incorrect record id's with
#   ipmi-dcmi --get-dcmi-sensor-info
# - others don't report at all.
# - Yet others report errors for
#   ipmitool dcmi get_temp_reading
# - ipmi-sensors generally works but different systems have different
#   sensors and different sensor names for the equivalent sensors. In
#   the end, we're only interested in the inlet temperature. So first
#   try to figure out the record id of the inlet temperature sensor.

inlet_id=0
while read line
do
    IFSORIG=$IFS
    IFS=","; declare -a arr=($line)
    IFS=$IFSORIG
    id=${arr[0]}
    descr=${arr[1]}
    # HP G6 calls the inlet temperature "External Environment Temperature"
    if [[ $descr == *"Inlet"*  ||  $descr == "External Environment"* ]]; then
	inlet_id=$id
    fi
done < <(sudo ipmi-sensors --interpret-oem-data -b --shared-sensors --ignore-not-available-sensors --entity-sensor-names -t Temperature --comma-separated-output --no-header-output)


while :; do
    while read line
    do
	IFSORIG=$IFS
	IFS=":"; declare -a a1=($line)
	IFS=$IFSORIG
	a2=(${a1[1]})
	pwr=${a2[0]}
	break
    done < <(sudo ipmi-dcmi --get-system-power-statistics)
    [[ ! -z $pwr ]] && echo "PUTVAL \"$HOSTNAME/dcmi/current-power\" interval=$INTERVAL N:$pwr"

    if [[ $inlet_id -ne 0 ]]; then
	while read line
	do
	    IFSORIG=$IFS
	    IFS=","; declare -a arr=($line)
	    IFS=$IFSORIG
	    val=${arr[3]}
	    echo "PUTVAL \"$HOSTNAME/dcmi/inlet-temperature\" interval=$INTERVAL N:$val"
	done < <(sudo ipmi-sensors --interpret-oem-data -b --shared-sensors --ignore-not-available-sensors -r $inlet_id --comma-separated-output --no-header-output)
    fi

    sleep "$INTERVAL"
done
