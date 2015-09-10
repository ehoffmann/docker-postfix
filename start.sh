#! /bin/bash

echo "$ARG"
#USER=`echo "$ARG" | cut -d":" -f1`
USER=manu
echo "    >> adding user: $USER"
useradd -s /bin/bash $USER
echo "manu:manu" | chpasswd
if [ ! -d /var/spool/mail/$USER ]
then
  mkdir /var/spool/mail/$USER
fi
chown -R $USER:mail /var/spool/mail/$USER
chmod -R a=rwx /var/spool/mail/$USER
chmod -R o=- /var/spool/mail/$USER

service rsyslog start
service saslauthd start
service postfix start
sleep 5
tail -f /var/log/mail.log
