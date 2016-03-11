FROM centos:centos7

EXPOSE 8080

ADD sendEmail-epel-7.repo /etc/yum.repos.d/

RUN yum install -y epel-release && \
    yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflags=nodocs install httpd \
                                           nagios \
                                           telnet \
                                           supervisor \
                                           python-jinja2 \
                                           nagios-plugins-all \
                                           sendEmail \
                                           perl-Net-SSLeay \
                                           perl-IO-Socket-SSL && \
    yum clean all && \
    mkdir -p /opt/rhmap/ && \
    sed -i -e 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf && \
    sed -i -e 's|DocumentRoot "/var/www/html"|DocumentRoot "/usr/share/nagios/html"|' -e 's|<Directory "/var/www">|<Directory "/usr/share/nagios/html">|' /etc/httpd/conf/httpd.conf && \
    touch /supervisord.log supervisord.pid && \
    mkdir -p /var/log/nagios/rw/ && \
    mkdir -p /var/log/nagios/spool && \
    mkdir -p /var/log/nagios/spool/checkresults && \
    chmod -R 777 /supervisord.log /supervisord.pid /var/log/nagios \
                    /etc/httpd /etc/passwd /var/log /etc/nagios /usr/lib64/nagios /var/spool/nagios /run /usr/share/httpd /usr/share/nagios && \
    sed -i -e 's|cfg_file=/etc/nagios/objects/localhost.cfg||' /etc/nagios/nagios.cfg

ADD supervisord.conf /etc/supervisord.conf
ADD make-nagios-fhservices-cfg.py /opt/rhmap/make-nagios-fhservices-cfg.py
ADD make-nagios-commands-cfg.py /opt/rhmap/make-nagios-commands-cfg.py
ADD fhservices.cfg.j2 /opt/rhmap/fhservices.cfg.j2
ADD commands.cfg.j2 /opt/rhmap/commands.cfg.j2

ADD start.sh start.sh
CMD ["./start.sh"]
