-- Domain Monitoring System - Consolidated Schema

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,   -- Updated to 255 characters
    password TEXT NOT NULL,                  -- Using TEXT type from original schema
    full_name VARCHAR(255),                  -- Updated to 255 characters
    is_google_user BOOLEAN DEFAULT FALSE,
    profile_picture TEXT,                    -- Using TEXT type from original schema (renamed from picture)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create scans table to store domain monitoring results
CREATE TABLE IF NOT EXISTS scans (
    scan_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    url VARCHAR(512) NOT NULL,               -- Updated to 512 characters for longer URLs
    status_code VARCHAR(50),                 -- Updated to 50 characters
    ssl_status VARCHAR(50),                  -- Updated to 50 characters
    expiration_date VARCHAR(50),             -- Updated to 50 characters
    issuer TEXT,                             -- Using TEXT type from original schema
    last_scan_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE,
    CONSTRAINT unique_user_url 
        UNIQUE (user_id, url)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_scans_user_id ON scans(user_id);
CREATE INDEX IF NOT EXISTS idx_scans_url ON scans(url);

-- Add comments to tables and columns for documentation
COMMENT ON TABLE users IS 'Stores user account information';
COMMENT ON COLUMN users.user_id IS 'Unique identifier for each user';
COMMENT ON COLUMN users.username IS 'Username for login (email address)';
COMMENT ON COLUMN users.password IS 'User password (should be encrypted in production)';
COMMENT ON COLUMN users.is_google_user IS 'True if user authenticated via Google OAuth';
COMMENT ON COLUMN users.profile_picture IS 'URL to user profile picture (for Google users)';

COMMENT ON TABLE scans IS 'Stores domain monitoring scan results';
COMMENT ON COLUMN scans.scan_id IS 'Unique identifier for each scan';
COMMENT ON COLUMN scans.user_id IS 'Reference to the user who owns this domain';
COMMENT ON COLUMN scans.url IS 'Domain URL being monitored';
COMMENT ON COLUMN scans.status_code IS 'HTTP status result (OK/FAILED)';
COMMENT ON COLUMN scans.ssl_status IS 'SSL certificate status (valid/failed)';
COMMENT ON COLUMN scans.expiration_date IS 'SSL certificate expiration date';
COMMENT ON COLUMN scans.issuer IS 'SSL certificate issuer name';
COMMENT ON COLUMN scans.last_scan_time IS 'Timestamp of the last scan';