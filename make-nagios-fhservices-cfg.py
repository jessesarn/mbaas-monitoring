#!/usr/bin/env python

import os

from jinja2 import Environment, FileSystemLoader, Template

fh_services_ping = ['fh-mbaas', 'fh-messaging', 'fh-metrics', 'fh-statsd']
fh_services_health = ['fh-mbaas', 'fh-messaging', 'fh-metrics']

mbaas_admin_email = os.getenv('MBAAS_ADMIN_EMAIL', 'root@localhost')
mbaas_router_dns = os.getenv('MBAAS_ROUTER_DNS', 'mbaas.localhost')

template_file = '/opt/rhmap/fhservices.cfg.j2'
nagios_config_filename = '/etc/nagios/conf.d/fhservices.cfg'

template_basename = os.path.basename(template_file)
template_dirname = os.path.dirname(template_file)

j2env = Environment(loader=FileSystemLoader(template_dirname), trim_blocks=True)
j2template = j2env.get_template(template_basename)

j2renderedouput = j2template.render(fh_services_ping = fh_services_ping,
									fh_services_health = fh_services_health,
                                    mbaas_router_dns=mbaas_router_dns,
                                    mbaas_admin_email=mbaas_admin_email)

with open(nagios_config_filename, 'wb') as nagios_config_file:
    nagios_config_file.write(j2renderedouput)
