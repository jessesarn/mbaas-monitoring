#!/usr/bin/env python

import os

from jinja2 import Environment, FileSystemLoader, Template

smtp_server = os.getenv('SMTP_SERVER', 'localhost')
smtp_from_address = os.getenv('SMTP_FROM_ADDRESS', 'root@localhost')

template_file = '/opt/rhmap/commands.cfg.j2'
nagios_config_filename = '/etc/nagios/objects/commands.cfg'

template_basename = os.path.basename(template_file)
template_dirname = os.path.dirname(template_file)

j2env = Environment(loader=FileSystemLoader(template_dirname), trim_blocks=True)
j2template = j2env.get_template(template_basename)

j2renderedouput = j2template.render(smtp_from_address=smtp_from_address,
                                    smtp_server=smtp_server)

with open(nagios_config_filename, 'wb') as nagios_config_file:
    nagios_config_file.write(j2renderedouput)
