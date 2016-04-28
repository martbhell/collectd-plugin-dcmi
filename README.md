# collectd-plugin-dcmi

Collectd plugin to provide system data retrieved from DCMI (Data
Center Management Interface).  Currently only the power consumption
and inlet air temperature are retrieved.

Tested on HP G6 (Opteron), G7 (Xeon Westmere), Gen8 (Xeon Ivy Bridge),
HP SL4510 Gen9 and Dell ? (Xeon Haswell) machines.

Uses freeipmi to retrieve the sensor readings from localhost.
