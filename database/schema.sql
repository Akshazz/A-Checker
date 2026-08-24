CREATE DATABASE IF NOT EXISTS storage_health CHARACTER SET utf8mb4;
USE storage_health;

CREATE TABLE IF NOT EXISTS devices (
 id INT AUTO_INCREMENT PRIMARY KEY,
 hostname VARCHAR(255) NOT NULL, device_path VARCHAR(255) NOT NULL,
 model VARCHAR(255), serial_number VARCHAR(255), interface_type VARCHAR(50),
 drive_type VARCHAR(20), first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
 last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY unique_device (hostname, serial_number, device_path),
 INDEX idx_host(hostname)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS scans (
 id INT AUTO_INCREMENT PRIMARY KEY, device_id INT NOT NULL,
 scan_date DATETIME DEFAULT CURRENT_TIMESTAMP, health_status VARCHAR(20) DEFAULT 'UNKNOWN',
 health_score TINYINT UNSIGNED DEFAULT NULL, temperature_c INT DEFAULT NULL,
 power_on_hours BIGINT DEFAULT NULL, reallocated_sector_count BIGINT DEFAULT NULL,
 pending_sector_count BIGINT DEFAULT NULL, uncorrectable_sector_count BIGINT DEFAULT NULL,
 wear_level_percent TINYINT UNSIGNED DEFAULT NULL, self_test_status VARCHAR(255) DEFAULT NULL,
 smart_enabled TINYINT(1) DEFAULT NULL, raw_smart_json LONGTEXT,
 FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE CASCADE,
 INDEX idx_device_date(device_id,scan_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS partitions (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, hostname VARCHAR(255) NOT NULL,
 device_id INT NULL, disk_number INT NULL, partition_number INT NULL,
 drive_letter VARCHAR(10), device_path VARCHAR(255), label VARCHAR(255),
 filesystem VARCHAR(50), partition_type VARCHAR(100), gpt_type VARCHAR(100),
 mount_point VARCHAR(255), size_bytes BIGINT UNSIGNED NULL, free_bytes BIGINT UNSIGNED NULL,
 usage_percent DECIMAL(6,2) NULL, health VARCHAR(100), recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_part_host(hostname), INDEX idx_part_recorded(recorded_at),
 FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_keys (
 id INT AUTO_INCREMENT PRIMARY KEY, label VARCHAR(100) NOT NULL,
 api_key VARCHAR(64) NOT NULL UNIQUE, created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
INSERT INTO api_keys(label,api_key) VALUES('default-agent-key','__API_KEY__');
