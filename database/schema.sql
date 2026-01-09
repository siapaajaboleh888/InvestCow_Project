-- InvestCow Database Schema
-- Version: 3.0 (DevOps Optimized)
-- Description: Centralized schema for InvestCow Platform

CREATE DATABASE IF NOT EXISTS investcow_app
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE investcow_app;

-- 1. Users Table (Fintech Ready)
CREATE TABLE IF NOT EXISTS users (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email         VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name  VARCHAR(120) NOT NULL,
  role          ENUM('admin', 'user') DEFAULT 'user',
  balance       DECIMAL(20, 2) DEFAULT 0.00,
  locale        VARCHAR(16)  NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- 2. Products Table (With Transparency Features)
CREATE TABLE IF NOT EXISTS products (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name              VARCHAR(120) NOT NULL,
  ticker_code       VARCHAR(10) DEFAULT 'COW',
  description       TEXT NULL,
  image_url         VARCHAR(255) NULL,
  price             DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
  prev_price        DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
  target_price      DECIMAL(15, 2) NULL,
  -- Transparency Columns
  current_weight    DECIMAL(10, 2) DEFAULT 300.00,
  price_per_kg      DECIMAL(15, 2) DEFAULT 65000.00,
  daily_growth_rate DECIMAL(5, 4) DEFAULT 0.0100,
  health_score      INT DEFAULT 100,
  market_sentiment  VARCHAR(255) NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- 3. Product Prices (For Real-time OHLC Charts)
CREATE TABLE IF NOT EXISTS product_prices (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id  BIGINT UNSIGNED NOT NULL,
  price_open  DECIMAL(15, 2),
  price_high  DECIMAL(15, 2),
  price_low   DECIMAL(15, 2),
  price_close DECIMAL(15, 2),
  volume      INT DEFAULT 0,
  timestamp   DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pp_product_id (product_id),
  KEY idx_pp_timestamp (timestamp),
  CONSTRAINT fk_pp_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 4. Portfolios Table
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

-- 5. Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id        BIGINT UNSIGNED NOT NULL,
  product_id     BIGINT UNSIGNED NOT NULL,
  type           ENUM('BUY', 'SELL', 'TOPUP') NOT NULL,
  amount         DECIMAL(20, 2) NOT NULL,
  quantity       DECIMAL(18, 6) DEFAULT 0,
  price_at_trx   DECIMAL(18, 6) DEFAULT 0,
  occurred_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note           VARCHAR(255) NULL,
  PRIMARY KEY (id),
  KEY idx_tx_user_id (user_id),
  KEY idx_tx_product_id (product_id),
  CONSTRAINT fk_tx_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_tx_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
