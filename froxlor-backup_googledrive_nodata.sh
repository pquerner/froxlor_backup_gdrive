#!/bin/bash
################
###  Config  ###
################
BACKUP_DIR="/root/FroxlorBACKUP/backup"
BACKUP_TO="/vps-backups/server_webhod"
MYSQL_USER="root"
MYSQL_PASSWORD="password"

# Create dir in GDrive
echo "Creating dir $BACKUP_TO on GoogleDrive"
skicka mkdir -p $BACKUP_TO
####################
### MYSQL-BACKUP ###
####################
echo "Starte Datenbank-Backup..."

databases=`mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)"`
for db in $databases; do
    mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $db > "$BACKUP_DIR/DBs/$db.sql"
done

# Archive sql backup
tar -zcf $BACKUP_DIR/tmp/backup.tar.gz $BACKUP_DIR/DBs/

# Archiv upload
echo "Upload database backup..."
skicka mkdir -p $BACKUP_TO/databases
skicka upload $BACKUP_DIR/tmp/backup.tar.gz $BACKUP_TO/databases/backup_$(date +"%Y-%m-%d_%H-%M").tar.gz

# Delete mysql backups
rm $BACKUP_DIR/DBs/*
rm $BACKUP_DIR/tmp/backup.tar.gz
echo "Database backup finishedt!"

####################
### DATA-BACKUP ###
####################
echo "Start data backup..."

# Load dirs
dirs=( $(find /var/customers/webs/ -maxdepth 1 -type d -printf '%P\n') )

# Archive, upload, delete
for dir in "${dirs[@]}"; do
        tar -zcf $BACKUP_DIR/tmp/backup.tar.gz /var/customers/webs/$dir
	skicka mkdir -p $BACKUP_TO/$dir
        skicka upload $BACKUP_DIR/tmp/backup.tar.gz $BACKUP_TO/$dir/backup_$(date +"%Y-%m-%d_%H-%M").tar.gz
        rm $BACKUP_DIR/tmp/backup.tar.gz
done

###################
### MAIL-BACKUP ###
###################
echo "Starting mail upload..."

# Archive backup
tar -zcf $BACKUP_DIR/tmp/backup.tar.gz /var/customers/mail/

# Archiv upload
echo "Uploading mail backup..."
skicka mkdir -p $BACKUP_TO/mail
skicka upload $BACKUP_DIR/tmp/backup.tar.gz $BACKUP_TO/mail/backup_$(date +"%Y-%m-%d_%H-%M").tar.gz

# Delete mail backup
rm $BACKUP_DIR/tmp/backup.tar.gz

echo "Backup finished!"
