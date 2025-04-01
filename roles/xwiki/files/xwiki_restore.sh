#!/bin/bash

#This script will restore xwiki from a backup

NAMESPACE=xwiki
DATABASE="xwiki"
DBUSER=xwiki
DBPASS=xwiki
#XWIKI data folder
DATAFOLDER=/usr/local/xwiki/data/

#Backup Directory
BACKUPDIR=/var/backups

#DEPLOY Directory
DEPLOYDIR=${WEBAPPDIR}/${DEPLOYCONTEXT}

#Get the name of the wikijs postgres pod
xwiki_db_pod_str=$(kubectl get pods -n xwiki -l=app=xwiki-postgres --no-headers -o custom-columns=":metadata.name")
xwiki_app_pod_str=$(kubectl get pods -n xwiki -l=app=xwiki --no-headers -o custom-columns=":metadata.name")

#Check for latest backup in /mnt/storage/xwiki/backup/
latest_backup_date="$(ls -t /mnt/storage/xwiki/backup/ | head -1)"

##########   RESTORE POSTGRES DATABASE   ##########
#Decompress latest postgres database backup but keep original
kubectl exec -i -n ${NAMESPACE} $xwiki_db_pod_str -- /bin/bash -c "gzip -dk ${BACKUPDIR}/${latest_backup_date}/${DATABASE}.sql.gz"

#Drop postgres database
kubectl exec -i -n ${NAMESPACE} $xwiki_db_pod_str -- /bin/bash -c "dropdb -U ${DBUSER} ${DATABASE} -f"

#Create postgres database
kubectl exec -i -n ${NAMESPACE} $xwiki_db_pod_str -- /bin/bash -c "createdb -U ${DBUSER} ${DATABASE}"

#Restore postgres database
sudo chown 999:nogroup /mnt/storage/xwiki/postgres
kubectl exec -i -n ${NAMESPACE} $xwiki_db_pod_str -- /bin/bash -c "pg_restore -U ${DBUSER} -d ${DATABASE} ${BACKUPDIR}/${latest_backup_date}/${DATABASE}.sql"
sudo chown nobody:nogroup /mnt/storage/xwiki/postgres

##########  RESTORE DATA  ##########
#Decompress Data archive and extract to Data path
kubectl exec -i -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/tar -xzf ${BACKUPDIR}/${latest_backup_date}/data.tar.gz -C ${DATAFOLDER}/../"

#Remove old Data folder
#kubectl exec -it -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "rm -r ${DATAFOLDER}"

#Restore Data backup folder
#kubectl exec -it -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "cp -r ${BACKUPDIR}/${latest_backup_date}/data ${DATAFOLDER}/../"

##########   RESTORE XWIKI CONFIGURATION   ##########
kubectl exec -i -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/cp ${BACKUPDIR}/${latest_backup_date}/hibernate.cfg.xml ${DEPLOYDIR}/WEB-INF/hibernate.cfg.xml"
kubectl exec -i -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/cp ${BACKUPDIR}/${latest_backup_date}/xwiki.cfg ${DEPLOYDIR}/WEB-INF/xwiki.cfg"
kubectl exec -i -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/cp ${BACKUPDIR}/${latest_backup_date}/xwiki.properties ${DEPLOYDIR}/WEB-INF/xwiki.properties"
kubectl exec -i -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/cp ${BACKUPDIR}/${latest_backup_date}/classes/logback.xml ${DEPLOYDIR}/WEB-INF/classes/logback.xml"
kubectl exec -i -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/cp -r ${BACKUPDIR}/${latest_backup_date}/observation/ ${DEPLOYDIR}/WEB-INF/"

##########   RESTORE Deploy Context   ##########
kubectl exec -i -n ${NAMESPACE} $xwiki_app_pod_str -- /bin/bash -c "/bin/tar -xzf ${BACKUPDIR}/${latest_backup_date}/ROOT.tar.gz -C ${DEPLOYDIR}/../"

#Cleanup
kubectl exec -i -n ${NAMESPACE} $xwiki_db_pod_str -- /bin/bash -c "rm ${BACKUPDIR}/${latest_backup_date}/${DATABASE}.sql"
