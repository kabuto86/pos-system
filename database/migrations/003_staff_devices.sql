-- 003 Pengguna, peranti & syif (4 jadual) — PELAN.md 6.F, 4

-- email unik GLOBAL: ia mengenal pasti pengguna sebelum sistem tahu vendor (3.5, 4).
-- Kakitangan PIN sahaja tiada e-mel; MySQL benarkan berbilang NULL dalam UNIQUE.
CREATE TABLE users (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id        INT UNSIGNED NULL,
  email            VARCHAR(190) NULL,
  password_hash    VARCHAR(255) NULL,
  pin_hash         VARCHAR(255) NULL,
  full_name        VARCHAR(150) NOT NULL,
  role             ENUM('superadmin','admin','cashier','waiter') NOT NULL,
  outlet_id        INT UNSIGNED NULL,
  language         VARCHAR(5)   NULL,
  is_active        TINYINT(1)   NOT NULL DEFAULT 1,
  failed_attempts  TINYINT UNSIGNED NOT NULL DEFAULT 0,
  locked_until     DATETIME     NULL,
  last_login_at    DATETIME     NULL,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_vendor_outlet_role (vendor_id, outlet_id, role),
  CONSTRAINT fk_users_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_users_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_users_language FOREIGN KEY (language) REFERENCES languages (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tiada vendor_id: semasa cubaan log masuk, vendor belum diketahui
CREATE TABLE login_attempts (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email         VARCHAR(190) NULL,
  ip_address    VARCHAR(45)  NOT NULL,
  user_agent    VARCHAR(255) NULL,
  success       TINYINT(1)   NOT NULL DEFAULT 0,
  attempted_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_login_attempts_email (email, attempted_at),
  KEY idx_login_attempts_ip (ip_address, attempted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- device_token_hash: SHA-256 token kuki peranti berdaftar (4.3).
-- Token mentah hanya dalam kuki; pangkalan data simpan hash sahaja.
CREATE TABLE terminals (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id          INT UNSIGNED NOT NULL,
  outlet_id          INT UNSIGNED NOT NULL,
  code               VARCHAR(20)  NOT NULL,
  name               VARCHAR(100) NOT NULL,
  type               ENUM('cashier','waiter','kitchen') NOT NULL DEFAULT 'cashier',
  receipt_prefix     VARCHAR(10)  NOT NULL,
  auto_print         TINYINT(1)   NOT NULL DEFAULT 0,
  device_token_hash  CHAR(64)     NULL,
  registered_at      DATETIME     NULL,
  registered_by      INT UNSIGNED NULL,
  is_active          TINYINT(1)   NOT NULL DEFAULT 1,
  last_seen_at       DATETIME     NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_terminals_outlet_code (outlet_id, code),
  UNIQUE KEY uq_terminals_device_token (device_token_hash),
  KEY idx_terminals_vendor_outlet (vendor_id, outlet_id),
  CONSTRAINT fk_terminals_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_terminals_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_terminals_registered_by FOREIGN KEY (registered_by) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE shifts (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id      INT UNSIGNED  NOT NULL,
  outlet_id      INT UNSIGNED  NOT NULL,
  terminal_id    INT UNSIGNED  NOT NULL,
  user_id        INT UNSIGNED  NOT NULL,
  business_day   DATE          NOT NULL,
  opened_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  opening_float  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  closed_at      DATETIME      NULL,
  closing_cash   DECIMAL(10,2) NULL,
  expected_cash  DECIMAL(10,2) NULL,
  variance       DECIMAL(10,2) NULL,
  status         ENUM('open','closed') NOT NULL DEFAULT 'open',
  note           VARCHAR(255)  NULL,
  PRIMARY KEY (id),
  KEY idx_shifts_vendor_outlet_day (vendor_id, outlet_id, business_day),
  KEY idx_shifts_vendor_terminal_status (vendor_id, terminal_id, status),
  CONSTRAINT fk_shifts_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_shifts_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_shifts_terminal FOREIGN KEY (terminal_id) REFERENCES terminals (id),
  CONSTRAINT fk_shifts_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
