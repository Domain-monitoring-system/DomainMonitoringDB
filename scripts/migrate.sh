#!/bin/bash
# Database migration script for Domain Monitoring System
# Usage: ./migrate.sh [migration_file]

# Default database connection parameters
DB_NAME=${DB_NAME:-"monidb"}
DB_USER=${DB_USER:-"moniuser"}
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"5432"}

# Directory containing migrations
MIGRATIONS_DIR="../migrations"

# Check if specific migration file was provided
if [ -n "$1" ]; then
    # Apply specific migration
    MIGRATION_FILE="$1"
    
    if [ ! -f "$MIGRATION_FILE" ]; then
        echo "Error: Migration file not found: $MIGRATION_FILE"
        exit 1
    fi
    
    echo "Applying migration: $MIGRATION_FILE"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -a -f "$MIGRATION_FILE"
    
    if [ $? -eq 0 ]; then
        echo "Migration applied successfully."
    else
        echo "Error: Migration failed!"
        exit 1
    fi
else
    # Create migrations table if it doesn't exist
    echo "Ensuring migration tracking table exists..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME << EOF
    CREATE TABLE IF NOT EXISTS schema_migrations (
        version VARCHAR(50) PRIMARY KEY,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
EOF
    
    # Get list of applied migrations
    echo "Checking for applied migrations..."
    APPLIED_MIGRATIONS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT version FROM schema_migrations ORDER BY version;")
    
    # Get list of all migration files
    echo "Finding available migrations..."
    MIGRATION_FILES=$(ls -1 $MIGRATIONS_DIR/*.sql | sort)
    
    # Apply each migration that hasn't been applied yet
    for MIGRATION_FILE in $MIGRATION_FILES; do
        # Extract version from filename (YYYYMMDD_description.sql -> YYYYMMDD)
        VERSION=$(basename $MIGRATION_FILE | cut -d'_' -f1)
        
        # Check if this migration has already been applied
        if echo "$APPLIED_MIGRATIONS" | grep -q "$VERSION"; then
            echo "Migration $VERSION already applied, skipping."
            continue
        fi
        
        echo "Applying migration: $MIGRATION_FILE (version $VERSION)"
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -a -f "$MIGRATION_FILE"
        
        if [ $? -eq 0 ]; then
            # Record this migration as applied
            PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "INSERT INTO schema_migrations (version) VALUES ('$VERSION');"
            echo "Migration $VERSION applied successfully."
        else
            echo "Error: Migration $VERSION failed!"
            exit 1
        fi
    done
    
    echo "All migrations applied successfully."
fi