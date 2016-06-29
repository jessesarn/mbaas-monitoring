#!/bin/bash
######################################################################
#
# Nagios wrapper plugin to retrieve mongo admin password from
# same project where nagios is located and then perform the
# check requested
#
# Copyright (c) 2016, FeedHenry Ltd. All rights reserved.
#
######################################################################

# Nagios exit codes
NAGIOS_OK=0
NAGIOS_WARN=1
NAGIOS_CRIT=2
NAGIOS_UNKNOWN=3

################################
# FUNCTIONS
################################
usage() {
 echo "Usage: $0 -w <warn> -c <crit> [-h]"
 echo " -w <warn>    Warning threshold (default 0)"
 echo " -c <crit>    Critical threshold (default 0)"
 echo " -H <host>    Mongo hostname/ip (default mongo-service)"
 echo " -P <port>    Mongo service port (default 27017)"
 echo " -A <action>  Action as defined"
 echo " -h           Show this message"
 echo "Example: $0 -H mongo-service -P 27017 -A connect -w 0 -c 0"
}

WARN=0
CRIT=0
HOST=mongo-service
PORT=27017
ACTION=
while getopts "hw:c:" OPTION
do
 case $OPTION in
  h) usage; exit $NAGIOS_UNKNOWN ;;
  w) WARN=$OPTARG ;;
  c) CRIT=$OPTARG ;;
  H) HOST=$OPTARG ;;
  P) PORT=$OPTARG ;;
  A) ACTION=$OPTARG ;;
  ?) usage; exit $NAGIOS_UNKNOWN ;;
 esac
done

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

MONGO_PASS=`curl -sSk -H "Authorization: Bearer $TOKEN" https://local.feedhenry.io:8443/api/v1/namespaces/dev-mbaas/pods?labelSelector=name=mongodb-replica | jq --raw-output '.items[0].spec.containers[].env[] | select(.name == "MONGODB_ADMIN_PASSWORD") | .value'`

$USER1$/nagios-plugin-mongodb/check_mongodb.py -H $HOST -P $PORT -C $CRIT -W $WARN -A $ACTION -u admin -p $MONGO_PASS

exit $?