USE storage_health;
SET @db=DATABASE();

-- Add new scan fields if missing.
SET @sql=(SELECT IF(COUNT(*)=0,'ALTER TABLE scans ADD COLUMN health_score TINYINT UNSIGNED NULL, ADD COLUMN self_test_status VARCHAR(255) NULL, ADD COLUMN smart_enabled TINYINT(1) NULL','SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='scans' AND COLUMN_NAME='health_score');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

CREATE TABLE IF NOT EXISTS partitions (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, hostname VARCHAR(255) NOT NULL, device_id INT NULL,
 disk_number INT NULL, partition_number INT NULL, drive_letter VARCHAR(10), device_path VARCHAR(255),
 label VARCHAR(255), filesystem VARCHAR(50), partition_type VARCHAR(100), gpt_type VARCHAR(100),
 mount_point VARCHAR(255), size_bytes BIGINT UNSIGNED NULL, free_bytes BIGINT UNSIGNED NULL,
 usage_percent DECIMAL(6,2) NULL, health VARCHAR(100), recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_part_host(hostname), INDEX idx_part_recorded(recorded_at)
) ENGINE=InnoDB;
