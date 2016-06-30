################################
# GLOBALS
################################
# Nagios exit codes
NAGIOS_OK=0
NAGIOS_WARN=1
NAGIOS_CRIT=2
NAGIOS_UNKNOWN=3
 
################################
# FUNCTIONS
################################
usage() {
 echo "Usage: $0 -w <warn> -c <crit> [-m <usage|inodes>] [-h]"
 echo " -w <warn> Warning threshold percentage (e.g. 80)"
 echo " -c <crit> Critical threshold percentage (e.g. 90)"
 echo " -m <mode> Check mode (usage or inodes)"
 echo " -h        Show this message"
 echo "Example: $0 -w 85 -c 95"
}

################################
# ARGUMENT PROCESSING
################################
THRESH_WARN=
THRESH_CRIT=
CHECK_MODE=usage
while getopts “hw:c:m:” OPTION
do
 case $OPTION in
  h) usage; exit $NAGIOS_UNKNOWN ;;
  w) THRESH_WARN=$OPTARG ;;
  c) THRESH_CRIT=$OPTARG ;;
  m) CHECK_MODE=$OPTARG ;;
  ?) usage; exit $NAGIOS_UNKNOWN ;;
 esac
done
 
if [[ -z $THRESH_WARN ]] || [[ -z $THRESH_CRIT ]]; then
 usage; exit $NAGIOS_UNKNOWN
fi

TEMP_FILE=`mktemp`
NAMESPACE=`cat /var/run/secrets/kubernetes.io/serviceaccount/namespace`

if [ "$CHECK_MODE" = "usage" ]; then
	DF_CMD="df -x tmpfs"
elif [ "$CHECK_MODE" = "inodes" ]; then
	DF_CMD="df -i -x tmpfs"
else
	echo "Unknown check mode specified"
	usage; exit $NAGIOS_UNKNOWN
fi

for pod in `kubectl get pod --no-headers --namespace="$NAMESPACE" | awk '{print $1}'`; do
	kubectl exec --namespace="$NAMESPACE" -it $pod -- bash -c "$DF_CMD | grep -v Filesystem" | while IFS=; read line; do
		echo -e "$NAMESPACE\t$pod\t$line" >> $TEMP_FILE
	done
done

declare -a RESULT_ARR=()

COUNT_WARN=0
COUNT_CRIT=0
COUNT_OK=0

CURR=1

while IFS='' read -r line || [[ -n "$line" ]]; do
	NS=$( echo $line | awk '{print $1}' )
	POD=$( echo $line | awk '{print $2}' )
	VOL=$( echo $line | awk '{print $8}' | tr -cd "[:print:]" )
	PCT=$( echo $line | awk '{print $7}' | cut -d"%" -f1 )

	if [ "$PCT" -gt "$THRESH_CRIT" ]; then
		COUNT_CRIT=$((COUNT_CRIT + 1))
		STATUS="CRIT"
	elif [ "$PCT" -gt "$THRESH_WARN" ]; then
		COUNT_WARN=$((COUNT_WARN + 1))
		STATUS="WARN"
	else
		COUNT_OK=$((COUNT_OK + 1))
		STATUS="OK"
	fi

	RESULT_ARR[$CURR]="$STATUS: $NS/$POD:$VOL - $PCT% used"

	CURR=$((CURR + 1))
done < "$TEMP_FILE"

rm "$TEMP_FILE"

if [ $COUNT_CRIT -gt 0 ]; then
	echo "CRIT: Disk $CHECK_MODE on $COUNT_CRIT volumes are over the critical threshold"
	printf '%s\n' "${RESULT_ARR[@]}"
	exit $NAGIOS_CRIT
elif [ $COUNT_WARN -gt 0 ]; then
	echo "CRIT: Disk $CHECK_MODE on $COUNT_WARN volumes are over the warning threshold"
	printf '%s\n' "${RESULT_ARR[@]}"
	exit $NAGIOS_WARN
else
	echo "OK: Disk $CHECK_MODE on all $COUNT_OK volumes are OK"
	printf '%s\n' "${RESULT_ARR[@]}"
	exit $NAGIOS_OK
fi
