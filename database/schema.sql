-- Storage Health Monitor - Database Schema
-- Import this via phpMyAdmin (XAMPP) or:
--   mysql -u root -p < schema.sql

CREATE DATABASE IF NOT EXISTS storage_health CHARACTER SET utf8mb4;
USE storage_health;

CREATE TABLE IF NOT EXISTS devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    device_path VARCHAR(255) NOT NULL,      -- e.g. /dev/sda, \\.\PhysicalDrive0
    model VARCHAR(255) DEFAULT NULL,
    serial_number VARCHAR(255) DEFAULT NULL,
    interface_type VARCHAR(50) DEFAULT NULL, -- SATA, NVMe, USB, SCSI
    drive_type VARCHAR(20) DEFAULT NULL,     -- HDD, SSD, FLASH
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_device (hostname, serial_number, device_path)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS scans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    scan_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    health_status VARCHAR(20) DEFAULT 'UNKNOWN',   -- PASSED, FAILED, WARNING, UNKNOWN
    temperature_c INT DEFAULT NULL,
    power_on_hours INT DEFAULT NULL,
    reallocated_sector_count INT DEFAULT NULL,
    pending_sector_count INT DEFAULT NULL,
    uncorrectable_sector_count INT DEFAULT NULL,
    wear_level_percent INT DEFAULT NULL,           -- SSD/flash life remaining
    raw_smart_json LONGTEXT DEFAULT NULL,           -- full smartctl -a --json output
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    INDEX idx_device_date (device_id, scan_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    api_key VARCHAR(64) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- __API_KEY__ is replaced automatically by setup.sh / setup.ps1 with a fresh
-- random key at install time. If importing this file by hand instead, swap
-- __API_KEY__ for your own random string first.
INSERT INTO api_keys (label, api_key) VALUES ('default-agent-key', '__API_KEY__');
