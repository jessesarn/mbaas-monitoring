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
 echo "Usage:"
 echo " -w <warn>    Warning threshold (default 0)"
 echo " -c <crit>    Critical threshold (default 0)"
 echo " -A <action>  Action as defined"
 echo " -U <url>     OpenShift master url"
 echo " -S <svc>     OpenShift service name"
 echo " -h           Show this message"
 echo "Example: $0 -U https://local.feedhenry.io:8443 -A connect -S mongodb-server -w 0 -c 0"
}

WARN=0
CRIT=0
ACTION=
SVC=mongodb-service
URL=$OPENSHIFT_MASTER_URL
while getopts "h:w:c:A:S:U:" OPTION
do
 case $OPTION in
  h) usage; exit $NAGIOS_UNKNOWN ;;
  w) WARN=$OPTARG ;;
  c) CRIT=$OPTARG ;;
  A) ACTION=$OPTARG ;;
  S) SVC=$OPTARG ;;
  U) URL=$OPTARG ;;
  ?) usage; exit $NAGIOS_UNKNOWN ;;
 esac
done

if [[ -z $ACTION ]]; then
 usage; exit $NAGIOS_UNKNOWN
fi

if [[ -z $URL ]]; then
  echo "OpenShift Master URL not provided, ensure that environment variable is set or specify url parameter (-U)"
  exit $NAGIOS_UNKNOWN
fi

#
# Use serviceaccount info to inspect kubernetes for connection information
#

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
NAMESPACE="$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)"

SVCINFO=`curl -sSk -H "Authorization: Bearer $TOKEN" $URL/api/v1/namespaces/$NAMESPACE/services/$SVC | jq '.spec.ports[0].port, .spec.selector.name | @text' -r`
PORT=`echo $SVCINFO | awk '{print $1}'`
SELECTOR=`echo $SVCINFO | awk '{print $2}'`

MONGO_PASS=`curl -sSk -H "Authorization: Bearer $TOKEN" $URL/api/v1/namespaces/$NAMESPACE/pods?labelSelector=name=$SELECTOR | jq --raw-output '.items[0].spec.containers[].env[] | select(.name == "MONGODB_ADMIN_PASSWORD") | .value'`

if [[ -z $CRIT ]]; then
	echo "Unable to determine admin password for mongodb"
	exit $NAGIOS_UNKNOWN;
fi

$NAGIOS_PLUGINS/check_mongodb.py -H $SVC -P $PORT -C $CRIT -W $WARN -A $ACTION -u admin -p $MONGO_PASS

exit $?