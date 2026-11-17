-- 005 Bayaran (6 jadual PELAN.md 6.D + payment_methods dari 6.F)
-- payment_methods diletak di sini kerana transactions merujuknya.

CREATE TABLE payment_methods (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id   INT UNSIGNED NOT NULL,
  code        VARCHAR(30)  NOT NULL,
  label       VARCHAR(50)  NOT NULL,
  icon        VARCHAR(40)  NULL,
  needs_cash  TINYINT(1)   NOT NULL DEFAULT 0,
  note        VARCHAR(255) NULL,
  is_active   TINYINT(1)   NOT NULL DEFAULT 1,
  sort_order  SMALLINT     NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payment_methods_vendor_code (vendor_id, code),
  CONSTRAINT fk_payment_methods_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Kunci API milik vendor, disulit (9.6). Hanya satu is_active = 1 setiap vendor
-- (dikuatkuasakan dalam SaveGatewayCredentialsJob).
CREATE TABLE vendor_payment_gateways (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id        INT UNSIGNED NOT NULL,
  gateway          ENUM('toyyibpay','billplz','senangpay','stripe') NOT NULL,
  credentials_enc  TEXT         NULL,
  is_sandbox       TINYINT(1)   NOT NULL DEFAULT 1,
  is_active        TINYINT(1)   NOT NULL DEFAULT 0,
  verified_at      DATETIME     NULL,
  updated_by       INT UNSIGNED NULL,
  updated_at       DATETIME     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vendor_gateways (vendor_id, gateway),
  CONSTRAINT fk_vendor_gateways_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_vendor_gateways_updated_by FOREIGN KEY (updated_by) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- reference rawak dihantar kepada gerbang; vendor dicari pelayan darinya (3.9)
CREATE TABLE online_payments (
  id                INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id         INT UNSIGNED  NOT NULL,
  outlet_id         INT UNSIGNED  NOT NULL,
  order_id          INT UNSIGNED  NOT NULL,
  gateway           ENUM('toyyibpay','billplz','senangpay','stripe') NOT NULL,
  reference         CHAR(32)      NOT NULL,
  gateway_bill_id   VARCHAR(100)  NULL,
  amount            DECIMAL(10,2) NOT NULL,
  currency          CHAR(3)       NOT NULL DEFAULT 'MYR',
  status            ENUM('pending','paid','failed','expired','refunded') NOT NULL DEFAULT 'pending',
  paid_at           DATETIME      NULL,
  expires_at        DATETIME      NOT NULL,
  callback_payload  TEXT          NULL,
  created_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_online_payments_reference (reference),
  UNIQUE KEY uq_online_payments_gateway_bill (gateway, gateway_bill_id),
  KEY idx_online_payments_vendor_status (vendor_id, status, expires_at),
  KEY idx_online_payments_vendor_order (vendor_id, order_id),
  CONSTRAINT fk_online_payments_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_online_payments_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_online_payments_order FOREIGN KEY (order_id) REFERENCES orders (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- terminal / shift / user NULL untuk bayaran online (tiada kaunter, tiada syif).
-- Medan gambaran disalin masuk supaya resit lama kekal betul.
CREATE TABLE transactions (
  id                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id           INT UNSIGNED  NOT NULL,
  outlet_id           INT UNSIGNED  NOT NULL,
  receipt_no          VARCHAR(30)   NOT NULL,
  business_day        DATE          NOT NULL,
  type                ENUM('sale','refund') NOT NULL DEFAULT 'sale',
  ref_transaction_id  INT UNSIGNED  NULL,
  terminal_id         INT UNSIGNED  NULL,
  shift_id            INT UNSIGNED  NULL,
  user_id             INT UNSIGNED  NULL,
  online_payment_id   INT UNSIGNED  NULL,
  order_type          ENUM('dine_in','takeaway','counter','pickup') NOT NULL,
  table_label         VARCHAR(50)   NULL,
  takeaway_no         SMALLINT UNSIGNED NULL,
  subtotal            DECIMAL(10,2) NOT NULL,
  tax_rate            DECIMAL(5,4)  NOT NULL DEFAULT 0.0000,
  tax                 DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  service_charge      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  packaging_fee       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  promo_discount      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  manual_discount     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  discount            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  discount_tax_mode   ENUM('before_tax','after_tax') NOT NULL DEFAULT 'after_tax',
  total               DECIMAL(10,2) NOT NULL,
  payment_method_id   INT UNSIGNED  NULL,
  cash_received       DECIMAL(10,2) NULL,
  change_amount       DECIMAL(10,2) NULL,
  status              ENUM('paid','void') NOT NULL DEFAULT 'paid',
  void_reason         VARCHAR(255)  NULL,
  voided_at           DATETIME      NULL,
  voided_by           INT UNSIGNED  NULL,
  created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_transactions_outlet_receipt (outlet_id, receipt_no),
  KEY idx_transactions_vendor_day (vendor_id, business_day),
  KEY idx_transactions_vendor_outlet_day (vendor_id, outlet_id, business_day),
  KEY idx_transactions_vendor_shift (vendor_id, shift_id),
  CONSTRAINT fk_transactions_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_transactions_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_transactions_ref FOREIGN KEY (ref_transaction_id) REFERENCES transactions (id),
  CONSTRAINT fk_transactions_terminal FOREIGN KEY (terminal_id) REFERENCES terminals (id),
  CONSTRAINT fk_transactions_shift FOREIGN KEY (shift_id) REFERENCES shifts (id),
  CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_transactions_online_payment FOREIGN KEY (online_payment_id) REFERENCES online_payments (id),
  CONSTRAINT fk_transactions_payment_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id),
  CONSTRAINT fk_transactions_voided_by FOREIGN KEY (voided_by) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- promotion_id tanpa FK: promosi boleh dipadam, resit tetap kekal (gambaran)
CREATE TABLE transaction_items (
  id               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id        INT UNSIGNED  NOT NULL,
  transaction_id   INT UNSIGNED  NOT NULL,
  order_item_id    INT UNSIGNED  NULL,
  product_id       INT UNSIGNED  NOT NULL,
  product_name     VARCHAR(150)  NOT NULL,
  icon             VARCHAR(16)   NULL,
  base_price       DECIMAL(10,2) NOT NULL,
  unit_price       DECIMAL(10,2) NOT NULL,
  promotion_id     INT UNSIGNED  NULL,
  promotion_name   VARCHAR(150)  NULL,
  discount_amount  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  qty              DECIMAL(10,2) NOT NULL,
  line_total       DECIMAL(10,2) NOT NULL,
  variant_label    VARCHAR(255)  NULL,
  refunded_qty     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (id),
  KEY idx_transaction_items_vendor_txn (vendor_id, transaction_id),
  KEY idx_transaction_items_vendor_product (vendor_id, product_id),
  CONSTRAINT fk_transaction_items_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_transaction_items_txn FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
  CONSTRAINT fk_transaction_items_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE transaction_item_options (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id     INT UNSIGNED  NOT NULL,
  item_id       INT UNSIGNED  NOT NULL,
  group_name    VARCHAR(100)  NOT NULL,
  option_label  VARCHAR(100)  NOT NULL,
  price_delta   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (id),
  KEY idx_transaction_item_options_vendor_item (vendor_id, item_id),
  CONSTRAINT fk_transaction_item_options_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_transaction_item_options_item FOREIGN KEY (item_id) REFERENCES transaction_items (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gabung bil: satu bayaran menutup beberapa pesanan
CREATE TABLE transaction_orders (
  vendor_id       INT UNSIGNED NOT NULL,
  transaction_id  INT UNSIGNED NOT NULL,
  order_id        INT UNSIGNED NOT NULL,
  PRIMARY KEY (transaction_id, order_id),
  KEY idx_transaction_orders_vendor_order (vendor_id, order_id),
  CONSTRAINT fk_transaction_orders_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_transaction_orders_txn FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
  CONSTRAINT fk_transaction_orders_order FOREIGN KEY (order_id) REFERENCES orders (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
