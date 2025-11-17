-- MySQL schema for investcow_app
-- Compatible with MySQL 8.0 (dbngin) and TablePlus
-- Run in TablePlus: open connection -> create database investcow_app -> run this file.

-- Create database (idempotent pattern)
CREATE DATABASE IF NOT EXISTS investcow_app
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE investcow_app;

-- Users
CREATE TABLE IF NOT EXISTS users (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email         VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name  VARCHAR(120) NOT NULL,
  locale        VARCHAR(16)  NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Sessions (optional for future backend auth)
CREATE TABLE IF NOT EXISTS sessions (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NOT NULL,
  token        CHAR(64) NOT NULL UNIQUE,
  expires_at   DATETIME NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_sessions_user_id (user_id),
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Preferences (key-value per user)
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id     BIGINT UNSIGNED NOT NULL,
  pref_key    VARCHAR(64) NOT NULL,
  pref_value  JSON NULL,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, pref_key),
  CONSTRAINT fk_prefs_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Example business entities (customize as needed)
-- Portfolios
CREATE TABLE IF NOT EXISTS portfolios (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NOT NULL,
  name         VARCHAR(120) NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_portfolios_user_id (user_id),
  CONSTRAINT fk_portfolios_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Transactions
CREATE TABLE IF NOT EXISTS transactions (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  portfolio_id   BIGINT UNSIGNED NOT NULL,
  type           ENUM('buy','sell','deposit','withdraw') NOT NULL,
  symbol         VARCHAR(32) NOT NULL,
  quantity       DECIMAL(18,6) NOT NULL,
  price          DECIMAL(18,6) NOT NULL,
  occurred_at    DATETIME NOT NULL,
  note           VARCHAR(255) NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tx_portfolio_id (portfolio_id),
  KEY idx_tx_symbol (symbol),
  CONSTRAINT fk_tx_portfolio FOREIGN KEY (portfolio_id)
    REFERENCES portfolios(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Audit log
CREATE TABLE IF NOT EXISTS audit_logs (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     BIGINT UNSIGNED NULL,
  action      VARCHAR(64) NOT NULL,
  payload     JSON NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_user_id (user_id),
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;
