#!/bin/bash

# This script will run as a cron job to backup the xwiki database each night.
# It will create a backup with a time stamp, which will be copied to /mnt/storage/backups/xwiki/
# A separate cron job will remove old backups after a specified time

# Get the name of the wikijs postgres pod
pod_str=$(kubectl get pods -n xwiki -l=app=xwiki-postgres --no-headers -o custom-columns=":metadata.name")

# Create backup and append date stamp
d=$(date +%Y-%m-%d-%H.%M.%S)
kubectl exec -it -n xwiki $pod_str -- /bin/bash -c "pg_dump xwiki -U xwiki -F t > /var/lib/postgresql/data/$d-xwikibackup.tar"

# Copy the backup to the /mnt/storage/backup/wikijs location on the 2TB SSD.
cp -n /mnt/storage/xwiki/postgres/*xwikibackup* /mnt/storage/xwiki/backup