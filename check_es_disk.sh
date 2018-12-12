#!/bin/sh

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

if [ $# -lt 2 ]
then
  echo "Usage: $0 <host> <port>"
  exit 3
fi

HOST="$1"
PORT="$2"

if ! curl -s -XGET "http://${HOST}:${PORT}/_cat/allocation?s=disk.avail:desc" >/dev/null
then
  echo "ES Not Available"
  exit $STATE_UNKNOWN
fi

DU=`curl -s -XGET "http://${HOST}:${PORT}/_cat/allocation?s=disk.avail:desc" | tail -n1 | awk '{print $6}'`

if [ $DU -gt 90 ]
then
  echo "CRITICAL: Disk Usage is ${DU}%!"
  exit $STATE_CRITICAL
elif [ $DU -gt 80 ]
then
  echo "WARNING: Disk Usage is ${DU}%!"
  exit $STATE_WARNING
else
  echo "OK: Disk Usage is ${DU}%!"
  exit $STATE_OK
fi
