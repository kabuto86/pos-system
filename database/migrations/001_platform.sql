-- 001 Platform & langganan (11 jadual) — PELAN.md 6.A
-- Peraturan pelari: satu kenyataan berakhir dengan ';' di hujung baris.
-- Migrasi TIDAK disunting selepas di-commit; ubah skema = fail baharu.

CREATE TABLE languages (
  code         VARCHAR(5)   NOT NULL,
  name         VARCHAR(50)  NOT NULL,
  native_name  VARCHAR(50)  NOT NULL,
  is_active    TINYINT(1)   NOT NULL DEFAULT 1,
  is_default   TINYINT(1)   NOT NULL DEFAULT 0,
  sort_order   SMALLINT     NOT NULL DEFAULT 0,
  PRIMARY KEY (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE translations (
  language_code    VARCHAR(5)   NOT NULL,
  translation_key  VARCHAR(150) NOT NULL,
  value            TEXT         NOT NULL,
  PRIMARY KEY (language_code, translation_key),
  CONSTRAINT fk_translations_language FOREIGN KEY (language_code) REFERENCES languages (code) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE vendors (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code           VARCHAR(20)  NOT NULL,
  name           VARCHAR(150) NOT NULL,
  business_type  ENUM('retail','restaurant') NOT NULL,
  status         ENUM('trial','active','suspended','cancelled') NOT NULL DEFAULT 'trial',
  phone          VARCHAR(30)  NULL,
  address        VARCHAR(255) NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vendors_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- shop_slug unik GLOBAL: s/{shop_slug} dicari tanpa tahu vendor (3.9, 9.7)
CREATE TABLE outlets (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id   INT UNSIGNED NOT NULL,
  code        VARCHAR(20)  NOT NULL,
  name        VARCHAR(150) NOT NULL,
  address     VARCHAR(255) NULL,
  phone       VARCHAR(30)  NULL,
  shop_slug   VARCHAR(60)  NULL,
  is_active   TINYINT(1)   NOT NULL DEFAULT 1,
  opened_at   DATE         NULL,
  closed_at   DATE         NULL,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_outlets_vendor_code (vendor_id, code),
  UNIQUE KEY uq_outlets_shop_slug (shop_slug),
  CONSTRAINT fk_outlets_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE plans (
  id                        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  code                      VARCHAR(30)   NOT NULL,
  name                      VARCHAR(100)  NOT NULL,
  base_price                DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  price_per_outlet          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  max_outlets               INT UNSIGNED  NOT NULL DEFAULT 1,
  max_terminals_per_outlet  INT UNSIGNED  NOT NULL DEFAULT 1,
  max_users                 INT UNSIGNED  NOT NULL DEFAULT 5,
  max_products              INT UNSIGNED  NOT NULL DEFAULT 100,
  is_active                 TINYINT(1)    NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_plans_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Harga kedai berperingkat (9.2). to_outlet NULL = tiada had atas
CREATE TABLE plan_outlet_tiers (
  id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  plan_id      INT UNSIGNED  NOT NULL,
  from_outlet  INT UNSIGNED  NOT NULL,
  to_outlet    INT UNSIGNED  NULL,
  unit_price   DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tiers_plan_from (plan_id, from_outlet),
  CONSTRAINT fk_tiers_plan FOREIGN KEY (plan_id) REFERENCES plans (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Peringkat platform, tiada vendor_id (9.4)
CREATE TABLE modules (
  code                    VARCHAR(30)  NOT NULL,
  name_key                VARCHAR(150) NOT NULL,
  description_key         VARCHAR(150) NOT NULL,
  is_core                 TINYINT(1)   NOT NULL DEFAULT 0,
  requires_business_type  ENUM('any','retail','restaurant') NOT NULL DEFAULT 'any',
  sort_order              SMALLINT     NOT NULL DEFAULT 0,
  PRIMARY KEY (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE plan_modules (
  plan_id      INT UNSIGNED NOT NULL,
  module_code  VARCHAR(30)  NOT NULL,
  PRIMARY KEY (plan_id, module_code),
  CONSTRAINT fk_plan_modules_plan FOREIGN KEY (plan_id) REFERENCES plans (id) ON DELETE CASCADE,
  CONSTRAINT fk_plan_modules_module FOREIGN KEY (module_code) REFERENCES modules (code) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE subscriptions (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id           INT UNSIGNED NOT NULL,
  plan_id             INT UNSIGNED NOT NULL,
  status              ENUM('trial','active','past_due','cancelled') NOT NULL DEFAULT 'trial',
  started_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  trial_ends_at       DATETIME     NULL,
  current_period_end  DATETIME     NULL,
  cancelled_at        DATETIME     NULL,
  note                VARCHAR(255) NULL,
  PRIMARY KEY (id),
  KEY idx_subscriptions_vendor_status (vendor_id, status),
  CONSTRAINT fk_subscriptions_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_subscriptions_plan FOREIGN KEY (plan_id) REFERENCES plans (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE invoices (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id     INT UNSIGNED  NOT NULL,
  invoice_no    VARCHAR(30)   NOT NULL,
  period_start  DATE          NOT NULL,
  period_end    DATE          NOT NULL,
  subtotal      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  tax           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  status        ENUM('draft','issued','paid','void') NOT NULL DEFAULT 'draft',
  issued_at     DATETIME      NULL,
  due_at        DATETIME      NULL,
  paid_at       DATETIME      NULL,
  note          VARCHAR(255)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoices_no (invoice_no),
  KEY idx_invoices_vendor_period (vendor_id, period_start),
  CONSTRAINT fk_invoices_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Salinan gambaran: unit_price sendiri, bukan rujukan plan_outlet_tiers (9.3)
CREATE TABLE invoice_lines (
  id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  invoice_id   INT UNSIGNED  NOT NULL,
  description  VARCHAR(255)  NOT NULL,
  outlet_id    INT UNSIGNED  NULL,
  qty          DECIMAL(10,2) NOT NULL DEFAULT 1.00,
  unit_price   DECIMAL(10,2) NOT NULL,
  amount       DECIMAL(10,2) NOT NULL,
  is_prorated  TINYINT(1)    NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_invoice_lines_invoice (invoice_id),
  CONSTRAINT fk_invoice_lines_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
  CONSTRAINT fk_invoice_lines_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
