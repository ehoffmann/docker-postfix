FROM debian:jessie

# pre config
RUN echo mail > /etc/hostname; \
    echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt; \
    echo "postfix postfix/mailname string mail.example.com" >> preseed.txt

# load pre config for apt
RUN debconf-set-selections preseed.txt

# lang
RUN apt-get update
#RUN apt-get install -y language-pack-en
#RUN update-locale LANG=en_US.UTF-8

# install
RUN apt-get install -y \
#    opendkim \
#    mailutils \
#    opendkim-tools \
#    sasl2-bin \
#    telnet \
    rsyslog

RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y postfix sasl2-bin vim

RUN postconf -e "mynetworks = 127.0.0.0/8 192.0.0.0/8 0.0.0.0/0 [::ffff:127.0.0.0]/104 [::1]/128"
RUN postconf -e smtpd_sasl_auth_enable=yes
RUN postconf -e smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination
RUN postconf -e broken_sasl_auth_clients=yes

ADD postfix.pem /etc/ssl/private/postfix.pem
ADD postfix.pub /etc/ssl/certs/postfix.pub

RUN chmod o= /etc/ssl/private/postfix.pem
RUN postconf -e smtpd_tls_key_file=/etc/ssl/private/postfix.pem
RUN postconf -e smtpd_tls_cert_file=/etc/ssl/certs/postfix.pub
# openssl req -new -x509 -days 3650 -nodes -out /etc/ssl/certs/postfix.pem -keyout /etc/ssl/private/postfix.pem
# openssl s_client -tls1 -starttls smtp -connect smtp.gmail.com:587 -servername smtp.gmail.com 2>/dev/null | openssl x509 -text -noout
#
# Config Sasl2
RUN sed -i 's/^START=.*/START=yes/g' /etc/default/saslauthd; \
    sed -i 's/^MECHANISMS=.*/MECHANISMS="shadow"/g' /etc/default/saslauthd

RUN echo "pwcheck_method: saslauthd" > /etc/postfix/sasl/smtpd.conf; \
    echo "mech_list: PLAIN LOGIN" >> /etc/postfix/sasl/smtpd.conf; \
    echo "saslauthd_path: /var/run/saslauthd/mux" >> /etc/postfix/sasl/smtpd.conf

# postfix settings
RUN postconf -e smtpd_sasl_auth_enable="yes"; \
    postconf -e smtpd_recipient_restrictions="permit_mynetworks permit_sasl_authenticated reject_unauth_destination"; \
    postconf -e smtpd_helo_restrictions="permit_sasl_authenticated, permit_mynetworks, reject_invalid_hostname, reject_unauth_pipelining, reject_non_fqdn_hostname"

# add user postfix to sasl group
RUN adduser postfix sasl

# chroot saslauthd fix
RUN sed -i 's/^OPTIONS=/#OPTIONS=/g' /etc/default/saslauthd; \
    echo 'OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"' >> /etc/default/saslauthd

# add user
EXPOSE 25

ADD start.sh /start.sh
RUN chmod +x /start.sh
ENTRYPOINT ["/start.sh"]
