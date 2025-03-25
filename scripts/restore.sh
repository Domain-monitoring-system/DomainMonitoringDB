#!/bin/bash
# PostgreSQL restore script for Domain Monitoring System
# Usage: ./restore.sh backup_file

# Default database connection parameters
DB_NAME=${DB_NAME:-"monidb"}
DB_USER=${DB_USER:-"moniuser"}
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"5432"}

# Log file
LOG_FILE="./restore_log.txt"

# Check for backup file argument
if [ -z "$1" ]; then
  echo "Error: No backup file specified!"
  echo "Usage: ./restore.sh backup_file"
  exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Starting database restore at $(date)" | tee -a $LOG_FILE
echo "Backup file: $BACKUP_FILE" | tee -a $LOG_FILE

# Confirm before proceeding
echo "WARNING: This will overwrite the current database '$DB_NAME'!"
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled." | tee -a $LOG_FILE
  exit 0
fi

# Determine file type and restore accordingly
if [[ "$BACKUP_FILE" == *.pgdump ]]; then
  # Custom format backup
  echo "Restoring from custom format backup..." | tee -a $LOG_FILE
  PGPASSWORD=$DB_PASSWORD pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --clean --if-exists "$BACKUP_FILE"
  RESTORE_STATUS=$?
elif [[ "$BACKUP_FILE" == *.sql ]]; then
  # SQL dump
  echo "Restoring from SQL dump..." | tee -a $LOG_FILE
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < "$BACKUP_FILE"
  RESTORE_STATUS=$?
elif [[ "$BACKUP_FILE" == *.gz ]]; then
  # Compressed SQL dump
  echo "Restoring from compressed SQL dump..." | tee -a $LOG_FILE
  gunzip -c "$BACKUP_FILE" | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
  RESTORE_STATUS=$?
else
  echo "Error: Unrecognized backup file format: $BACKUP_FILE" | tee -a $LOG_FILE
  echo "Supported formats: .sql, .gz, .pgdump" | tee -a $LOG_FILE
  exit 1
fi

# Output status
if [ $RESTORE_STATUS -eq 0 ]; then
  echo "Database restore completed successfully." | tee -a $LOG_FILE
else
  echo "Error: Database restore failed with status $RESTORE_STATUS!" | tee -a $LOG_FILE
  exit 1
fi

echo "Restore completed at $(date)" | tee -a $LOG_FILE
echo "====================" | tee -a $LOG_FILE