# Domain Monitoring System - Database

This repository contains the database schema and database management scripts for the Domain Monitoring System.

## Overview

The Domain Monitoring System uses PostgreSQL as its primary database to store:
- User accounts and authentication information
- Domain monitoring configurations
- Domain scan results

## Repository Structure

```
domain-monitor-db/
├── schema/
│   └── schema.sql           # Main database schema definition
├── scripts/
│   ├── backup.sh            # Database backup script 
│   └── restore.sh           # Database restore script
├── .gitignore
└── README.md                # This file
```

## Prerequisites

### PostgreSQL Requirements

- PostgreSQL 12.0 or higher
- psql command-line client installed

### System Requirements

- Linux/Mac OS X/Windows
- 1GB RAM minimum for database server
- 10GB disk space recommended for data and logs

## Installation

### Install PostgreSQL

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

#### CentOS/RHEL
```bash
sudo yum install -y postgresql-server postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### macOS
```bash
brew install postgresql
brew services start postgresql
```

### Create Database

1. Log into PostgreSQL as the postgres user:
   ```bash
   sudo -u postgres psql
   ```

2. Create a database and user:
   ```sql
   CREATE DATABASE monidb;
   CREATE USER moniuser WITH ENCRYPTED PASSWORD 'your_secure_password';
   GRANT ALL PRIVILEGES ON DATABASE monidb TO moniuser;
   ```

3. Connect to the new database:
   ```sql
   \c monidb
   ```

## Schema Setup

1. Apply the schema to your PostgreSQL database:
   ```bash
   psql -U moniuser -d monidb -a -f schema/schema.sql
   ```

2. Verify the installation:
   ```bash
   psql -U moniuser -d monidb -c "\dt"
   ```
   You should see the tables defined in the schema.

## Database Schema

### Tables

#### `users`
Stores user account information:
- `user_id`: Unique identifier (primary key)
- `username`: Username for login (email address)
- `password`: User password (should be encrypted in production)
- `full_name`: User's full name (optional)
- `is_google_user`: Boolean flag for Google authentication
- `profile_picture`: URL to user profile picture (for Google users)
- `created_at`: Timestamp of account creation

#### `scans`
Stores domain monitoring scan results:
- `scan_id`: Unique identifier for each scan (primary key)
- `user_id`: Reference to the user who owns this domain
- `url`: Domain URL being monitored
- `status_code`: HTTP status result (OK/FAILED)
- `ssl_status`: SSL certificate status (valid/failed)
- `expiration_date`: SSL certificate expiration date
- `issuer`: SSL certificate issuer name
- `last_scan_time`: Timestamp of the last scan

### Future Schema Considerations

In future versions, consider adding:

#### `scheduled_tasks`
For storing scheduled monitoring tasks:
- `task_id`: Unique identifier for each task
- `user_id`: Reference to the task owner
- `type`: Task type (hourly, daily)
- `interval`: For hourly tasks - interval in hours
- `time`: For daily tasks - time to run
- `next_run`: Next scheduled execution time
- `job_id`: Reference to the scheduler job

## Database Maintenance

### Backup

To backup the database:
```bash
cd scripts
./backup.sh [optional_backup_directory]
```

This creates both SQL and binary format backups with timestamps.

### Restore

To restore from a backup:
```bash
cd scripts
./restore.sh path/to/backup_file
```

## Integration with Application

This database is designed to work with:
- The backend service located in the domain-monitor-backend repository
- The deployment configuration in the domain-monitor-deploy repository

### Environment Configuration

The application connects to this database using the following environment variables:
- `DB_NAME`: Database name (default: monidb)
- `DB_USER`: Database username (default: moniuser)
- `DB_PASSWORD`: Database user password
- `DB_HOST`: Database host (default: localhost)
- `DB_PORT`: Database port (default: 5432)

## Development Guidelines

### Naming Conventions

- Table names: lowercase, plural form (e.g., `users`, `scans`)
- Column names: lowercase, snake_case (e.g., `user_id`, `last_scan_time`)
- Primary keys: table name in singular form + `_id` (e.g., `user_id`, `scan_id`)
- Foreign keys: referenced table in singular form + `_id` (e.g., `user_id`)
- Indexes: `idx_` + table name + `_` + column name(s)

## Troubleshooting

### Common Issues

#### Connection Refused
```
psql: error: could not connect to server: Connection refused
```
- Check if PostgreSQL is running: `sudo systemctl status postgresql`
- Verify PostgreSQL is listening on the expected port: `sudo netstat -plunt | grep postgres`

#### Authentication Failed
```
psql: error: FATAL: password authentication failed for user "moniuser"
```
- Verify the correct password is being used
- Check pg_hba.conf for proper authentication method

#### Permission Denied
```
ERROR: permission denied for table users
```
- Verify the user has appropriate privileges: 
  ```sql
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO moniuser;
  ```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -am 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Submit a pull request

## License

[MIT License](LICENSE)