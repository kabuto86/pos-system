-- 006 Promosi (4 jadual) — PELAN.md 6.E
-- Dicipta sekarang walaupun UI dibina di Fasa 10 (7.4).

CREATE TABLE promotions (
  id                        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id                 INT UNSIGNED  NOT NULL,
  name                      VARCHAR(150)  NOT NULL,
  code                      VARCHAR(30)   NULL,
  type                      ENUM('product_price','product_percent','category_percent','bill_percent','bill_fixed','buy_x_get_y') NOT NULL,
  value                     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  buy_qty                   SMALLINT UNSIGNED NULL,
  get_qty                   SMALLINT UNSIGNED NULL,
  get_product_id            INT UNSIGNED  NULL,
  starts_on                 DATE          NULL,
  ends_on                   DATE          NULL,
  time_start                TIME          NULL,
  time_end                  TIME          NULL,
  days_of_week              CHAR(7)       NOT NULL DEFAULT '1111111',
  min_qty                   SMALLINT UNSIGNED NULL,
  min_spend                 DECIMAL(10,2) NULL,
  max_uses                  INT UNSIGNED  NULL,
  used_count                INT UNSIGNED  NOT NULL DEFAULT 0,
  max_uses_per_transaction  SMALLINT UNSIGNED NULL,
  priority                  SMALLINT      NOT NULL DEFAULT 0,
  is_stackable              TINYINT(1)    NOT NULL DEFAULT 0,
  is_active                 TINYINT(1)    NOT NULL DEFAULT 1,
  created_by                INT UNSIGNED  NULL,
  created_at                DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_promotions_vendor_code (vendor_id, code),
  KEY idx_promotions_vendor_active_dates (vendor_id, is_active, starts_on, ends_on),
  CONSTRAINT fk_promotions_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_promotions_get_product FOREIGN KEY (get_product_id) REFERENCES products (id) ON DELETE SET NULL,
  CONSTRAINT fk_promotions_created_by FOREIGN KEY (created_by) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE promotion_products (
  vendor_id     INT UNSIGNED NOT NULL,
  promotion_id  INT UNSIGNED NOT NULL,
  product_id    INT UNSIGNED NOT NULL,
  PRIMARY KEY (promotion_id, product_id),
  KEY idx_promotion_products_vendor_product (vendor_id, product_id),
  CONSTRAINT fk_promotion_products_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_promotion_products_promotion FOREIGN KEY (promotion_id) REFERENCES promotions (id) ON DELETE CASCADE,
  CONSTRAINT fk_promotion_products_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE promotion_categories (
  vendor_id     INT UNSIGNED NOT NULL,
  promotion_id  INT UNSIGNED NOT NULL,
  category_id   INT UNSIGNED NOT NULL,
  PRIMARY KEY (promotion_id, category_id),
  KEY idx_promotion_categories_vendor_category (vendor_id, category_id),
  CONSTRAINT fk_promotion_categories_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_promotion_categories_promotion FOREIGN KEY (promotion_id) REFERENCES promotions (id) ON DELETE CASCADE,
  CONSTRAINT fk_promotion_categories_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Nama & jenis disalin masuk; promotion_id tanpa FK supaya resit kekal
-- walaupun promosi dipadam (13 dalam PELAN.md 14).
CREATE TABLE transaction_promotions (
  id               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id        INT UNSIGNED  NOT NULL,
  transaction_id   INT UNSIGNED  NOT NULL,
  promotion_id     INT UNSIGNED  NULL,
  promotion_name   VARCHAR(150)  NOT NULL,
  promotion_type   VARCHAR(30)   NOT NULL,
  discount_amount  DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_transaction_promotions_vendor_txn (vendor_id, transaction_id),
  KEY idx_transaction_promotions_vendor_promo (vendor_id, promotion_id),
  CONSTRAINT fk_transaction_promotions_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_transaction_promotions_txn FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
