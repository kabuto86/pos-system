-- 007 Operasi (3 jadual baki PELAN.md 6.F)

-- ref_* tanpa FK: log pergerakan kekal walaupun rujukan dibatalkan
CREATE TABLE stock_movements (
  id                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id           INT UNSIGNED  NOT NULL,
  outlet_id           INT UNSIGNED  NOT NULL,
  product_id          INT UNSIGNED  NOT NULL,
  type                ENUM('sale','refund','void','restock','adjustment') NOT NULL,
  qty_change          DECIMAL(10,2) NOT NULL,
  balance_after       DECIMAL(10,2) NOT NULL,
  ref_transaction_id  INT UNSIGNED  NULL,
  ref_order_id        INT UNSIGNED  NULL,
  user_id             INT UNSIGNED  NULL,
  note                VARCHAR(255)  NULL,
  created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_stock_movements_vendor_outlet_product (vendor_id, outlet_id, product_id, created_at),
  CONSTRAINT fk_stock_movements_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_stock_movements_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_stock_movements_product FOREIGN KEY (product_id) REFERENCES products (id),
  CONSTRAINT fk_stock_movements_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- outlet_id NULL = nilai lalai vendor; baris dengan outlet_id menindihnya.
-- MySQL tidak benarkan lajur NULL dalam PRIMARY KEY, jadi keunikan
-- (vendor, kedai, kunci) dijaga melalui outlet_scope = IFNULL(outlet_id, 0).
CREATE TABLE settings (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id      INT UNSIGNED NOT NULL,
  outlet_id      INT UNSIGNED NULL,
  outlet_scope   INT UNSIGNED AS (IFNULL(outlet_id, 0)) STORED,
  setting_key    VARCHAR(60)  NOT NULL,
  setting_value  TEXT         NULL,
  updated_at     DATETIME     NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by     INT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_settings_scope_key (vendor_id, outlet_scope, setting_key),
  CONSTRAINT fk_settings_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_settings_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_settings_updated_by FOREIGN KEY (updated_by) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE activity_logs (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id    INT UNSIGNED NOT NULL,
  user_id      INT UNSIGNED NULL,
  action       VARCHAR(60)  NOT NULL,
  entity       VARCHAR(60)  NULL,
  entity_id    INT UNSIGNED NULL,
  detail_json  TEXT         NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_activity_logs_vendor_created (vendor_id, created_at),
  CONSTRAINT fk_activity_logs_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_activity_logs_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
