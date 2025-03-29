#!/bin/bash

#This script will run as a cron job to backup the xwiki database each night.
#It will create a backup with a time stamp, which will be copied to /mnt/storage/backups/xwiki/
#A separate cron job will remove old backups after a specified time

#Get the name of the wikijs postgres pod
xwiki_db_pod_str=$(kubectl get pods -n xwiki -l=app=xwiki-postgres --no-headers -o custom-columns=":metadata.name")
xwiki_app_pod_str=$(kubectl get pods -n xwiki -l=app=xwiki --no-headers -o custom-columns=":metadata.name")

#Space Separated List of Databases to Dump
#DATABASE="xwiki d1 d3"
NAMESPACE=xwiki
DATABASE="xwiki"
DBUSER=xwiki
DBPASS=xwiki

#Backup Directory
BACKUPDIR=/var/backups

#XWIKI data folder
DATAFOLDER=/usr/local/xwiki/data/
#Location of the webapps folder for your tomcat installation
WEBAPPDIR=/usr/local/tomcat/webapps
#What context (dir) does your application deploy to
DEPLOYCONTEXT=ROOT

DEPLOYDIR=${WEBAPPDIR}/${DEPLOYCONTEXT}
DATE=$(date '+%Y-%m-%d')
echo "Making date Directories"
kubectl exec -it -n ${NAMESPACE} $xwiki_db_pod_str -- /bin/bash -c "mkdir -p ${BACKUPDIR}/${DATE}"
kubectl exec -it -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "mkdir -p ${BACKUPDIR}/${DATE}"

#backup postgres
echo "Backing up postgres"
kubectl exec -it -n ${NAMESPACE} $xwiki_db_pod_str -- /bin/bash -c "pg_dump ${DATABASE} -U ${DBUSER} -F t | /bin/gzip > ${BACKUPDIR}/${DATE}/${DATABASE}.sql.gz"

echo "Backing up Data"
#Backup Exteral Data Storage
kubectl exec -it -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/tar -C ${DATAFOLDER}/../ -zcf ${BACKUPDIR}/${DATE}/data.tar.gz data"

#Backing Java Keystore
#/bin/cp /srv/tomcat6/.keystore ${BACKUPDIR}/${DATE}/.keystore

echo "Backing up xwiki configuration"
kubectl exec -it -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/cp ${DEPLOYDIR}/WEB-INF/hibernate.cfg.xml ${BACKUPDIR}/${DATE}/hibernate.cfg.xml"
kubectl exec -it -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/cp ${DEPLOYDIR}/WEB-INF/xwiki.cfg ${BACKUPDIR}/${DATE}/xwiki.cfg"
kubectl exec -it -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/cp ${DEPLOYDIR}/WEB-INF/xwiki.properties ${BACKUPDIR}/${DATE}/xwiki.properties"

#Backup Deploy Context
echo "Backing Deploy Context"
kubectl exec -it -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/tar -C ${DEPLOYDIR}/../ -zcf ${BACKUPDIR}/${DATE}/ROOT.tar.gz ROOT"