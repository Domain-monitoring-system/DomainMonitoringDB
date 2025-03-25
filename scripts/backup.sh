#!/bin/bash
# PostgreSQL backup script for Domain Monitoring System
# Usage: ./backup.sh [backup_dir]

# Default backup directory
BACKUP_DIR=${1:-"./backups"}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_NAME=${DB_NAME:-"monidb"}
DB_USER=${DB_USER:-"moniuser"}
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"5432"}

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Log file for backup operations
LOG_FILE="$BACKUP_DIR/backup_log.txt"

echo "Starting database backup at $(date)" | tee -a $LOG_FILE

# 1. Create a SQL dump
echo "Creating SQL dump..." | tee -a $LOG_FILE
SQL_BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME > $SQL_BACKUP_FILE

if [ $? -eq 0 ]; then
  echo "SQL dump completed successfully: $SQL_BACKUP_FILE" | tee -a $LOG_FILE
  # Compress the SQL file
  gzip $SQL_BACKUP_FILE
  echo "SQL dump compressed: ${SQL_BACKUP_FILE}.gz" | tee -a $LOG_FILE
else
  echo "Error: SQL dump failed!" | tee -a $LOG_FILE
  exit 1
fi

# 2. Optionally create a custom format backup (better for selective restores)
echo "Creating custom format backup..." | tee -a $LOG_FILE
CUSTOM_BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.pgdump"
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -Fc $DB_NAME > $CUSTOM_BACKUP_FILE

if [ $? -eq 0 ]; then
  echo "Custom format backup completed successfully: $CUSTOM_BACKUP_FILE" | tee -a $LOG_FILE
else
  echo "Error: Custom format backup failed!" | tee -a $LOG_FILE
  # Continue anyway since we have the SQL dump
fi

# Clean up old backups (keep last 10)
echo "Cleaning up old backups..." | tee -a $LOG_FILE
ls -t $BACKUP_DIR/*.gz | tail -n +11 | xargs -r rm
ls -t $BACKUP_DIR/*.pgdump | tail -n +11 | xargs -r rm

echo "Backup completed at $(date)" | tee -a $LOG_FILE
echo "====================" | tee -a $LOG_FILE

# Summary
echo "Backup Summary:"
echo "SQL Backup: ${SQL_BACKUP_FILE}.gz"
echo "Custom Backup: $CUSTOM_BACKUP_FILE"
echo "Log: $LOG_FILE"