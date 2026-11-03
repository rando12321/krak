-- MySQL 8.0+ / MariaDB 10.4+ (XAMPP). Apply to a NEW database. Legacy tables require explicit export/import.
CREATE TABLE IF NOT EXISTS users (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 username VARCHAR(128) NOT NULL UNIQUE,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 last_login DATETIME(6) NULL,
 status VARCHAR(16) NOT NULL DEFAULT 'active',
 level VARCHAR(16) NOT NULL DEFAULT 'GOLD_II',
 browser_access BOOLEAN NOT NULL DEFAULT TRUE,
 connection_limit INT NOT NULL DEFAULT 2,
 CHECK (status IN ('active','blocked')),
 CHECK (connection_limit > 0)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS license_keys (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 key_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
 user_id BIGINT UNSIGNED NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 expires_at DATETIME(6) NULL,
 activated_at DATETIME(6) NULL,
 last_used DATETIME(6) NULL,
 status VARCHAR(16) NOT NULL DEFAULT 'active',
 max_activations INT NOT NULL DEFAULT 1,
 FOREIGN KEY (user_id) REFERENCES users(id),
 INDEX (user_id), INDEX (expires_at),
 CHECK (status IN ('active','revoked')),
 CHECK (max_activations > 0)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS license_activations (
 license_id BIGINT UNSIGNED NOT NULL,
 device_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY (license_id, device_hash),
 FOREIGN KEY (license_id) REFERENCES license_keys(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS sessions (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 user_id BIGINT UNSIGNED NOT NULL,
 license_id BIGINT UNSIGNED NOT NULL,
 session_token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
 access_token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
 flash_token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 expires_at DATETIME(6) NOT NULL,
 ip_address VARCHAR(45) NOT NULL,
 device_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
 FOREIGN KEY (user_id) REFERENCES users(id),
 FOREIGN KEY (license_id) REFERENCES license_keys(id),
 INDEX (expires_at), INDEX (license_id), INDEX (user_id),
 INDEX sessions_device (user_id,license_id,device_hash,expires_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS audit_logs (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 user_id BIGINT UNSIGNED NULL,
 action VARCHAR(100) NOT NULL,
 ip_address VARCHAR(45) NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 FOREIGN KEY (user_id) REFERENCES users(id),
 INDEX (user_id,created_at), INDEX (created_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS user_data (
 user_id BIGINT UNSIGNED PRIMARY KEY,
 menu JSON NULL,
 map_data LONGBLOB NULL,
 soft_data LONGBLOB NULL,
 FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;
