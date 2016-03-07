#!/usr/bin/bash

# Add nagios user
htpasswd -c -b -s /etc/nagios/passwd ${NAGIOS_USER} ${NAGIOS_PASSWORD}

# Generate command config
python /opt/rhmap/make-nagios-commands-cfg.py

# Generate fhservices config
python /opt/rhmap/make-nagios-fhservices-cfg.py

/usr/bin/supervisord
