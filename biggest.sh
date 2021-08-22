#!/bin/sh

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

R="john.smith@example.com alert@example.slack.com"

ES="https://vpc-es-endpoint.us-west-2.es.amazonaws.com"
H="Authorization: Basic XXXXXXXXXXXXXXX"

#SIZE=`curl -s -H "$H" -X GET $ES/_cat/indices/_hot | awk '/gb$/ {print substr($NF,1,length($NF)-2)}' | sort -n | tail -n1`
SIZE=`curl -s -H "$H" -X GET $ES/_cat/indices/_hot | grep gb$ | sort -nk10 | tail -n10 | awk '{i[$3]=substr($NF,1,length($NF)-2)/$5; if (max < i[$3]) max=i[$3]} END {print max}'`

if [ ${SIZE%.*} -gt 100 ]
then
  echo "CRITICAL: Biggest Index Size is $SIZE on $ES" | mail -s "CRITICAL: Biggest Index Size is $SIZE" -r $R
  exit $STATE_CRITICAL
elif [ ${SIZE%.*} -gt 90 ]
then
  echo "WARNING: Biggest Index Size is $SIZE on $ES" | mail -s "WARNING: Biggest Index Size is $SIZE" -r $R
  exit $STATE_WARNING
else
  echo "OK: Biggest Index Size is $SIZE!"
  exit $STATE_OK
fi
