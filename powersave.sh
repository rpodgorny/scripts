#!/bin/sh
set -e -x

for i in /sys/class/scsi_host/host*/link_power_management_policy; do
  echo med_power_with_dipm > $i
done
