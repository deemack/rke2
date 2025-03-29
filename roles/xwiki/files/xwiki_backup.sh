#!/bin/bash

#This script will run as a cron job to backup the xwiki database each night.
#It will create a backup with a time stamp, which will be copied to /mnt/storage/backups/xwiki/
#A separate cron job will remove old backups after a specified time

#Get the name of the wikijs postgres pod
pod_str=$(kubectl get pods -n xwiki -l=app=xwiki-postgres --no-headers -o custom-columns=":metadata.name")

#Space Separated List of Databases to Dump
#DATABASE="xwiki d1 d3"
NAMESPACE=xwiki
DATABASE="xwiki"
DBUSER=xwiki
DBPASS=xwiki

#XWIKI data folder
DATAFOLDER=/usr/local/xwiki/data/
#Location of the webapps folder for your tomcat installation
WEBAPPDIR=/usr/local/tomcat/webapps
#What context (dir) does your application deploy to
DEPLOYCONTEXT=ROOT

DEPLOYDIR=${WEBAPPDIR}/${DEPLOYCONTEXT}
DATE=$(date '+%Y-%m-%d')
mkdir /var/lib/postgresql/data/${DATE}

#backup postgres
kubectl exec -it -n ${NAMESPACE} $pod_str -- /bin/bash -c "pg_dump ${DATABASE} -U ${DBUSER} -F t | /bin/gzip > /var/lib/postgresql/data/${DATE}/${DATABASE}.sql.gz"

echo "Backing up Data"
#Backup Exteral Data Storage
/bin/tar -C ${DATAFOLDER}/../ -zcf ./${DATE}/data.tar.gz data

#Backing Java Keystore
/bin/cp /srv/tomcat6/.keystore ./${DATE}/.keystore

echo "Backing up xwiki configuration"
/bin/cp ${DEPLOYDIR}/WEB-INF/hibernate.cfg.xml ./${DATE}/hibernate.cfg.xml
/bin/cp ${DEPLOYDIR}/WEB-INF/xwiki.cfg ./${DATE}/xwiki.cfg
/bin/cp ${DEPLOYDIR}/WEB-INF/xwiki.properties ./${DATE}/xwiki.properties

#Backup Deploy Context
echo "Backing UP deploy Context"
/bin/tar -C ${DEPLOYDIR}/../ -zcf ./${DATE}/ROOT.tar.gz ROOT

echo "DONE"


kubectl exec -it -n xwiki $pod_str -- /bin/bash -c "pg_dump xwiki -U xwiki -F t > /var/lib/postgresql/data/$d-xwikibackup.tar"

# Copy the backup to the /mnt/storage/backup/wikijs location on the 2TB SSD.
cp -n /mnt/storage/xwiki/postgres/*xwikibackup* /mnt/storage/xwiki/backup