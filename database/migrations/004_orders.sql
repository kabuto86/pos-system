-- 004 Pesanan (5 jadual) — PELAN.md 6.C

-- qr_token unik GLOBAL dan rawak (random_bytes(16)) — order/?t=... (3.9).
-- current_order_id tanpa FK: orders dicipta selepas jadual ini (rujukan bulat).
CREATE TABLE dining_tables (
  id                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id         INT UNSIGNED NOT NULL,
  outlet_id         INT UNSIGNED NOT NULL,
  code              VARCHAR(20)  NOT NULL,
  name              VARCHAR(50)  NOT NULL,
  area              VARCHAR(50)  NULL,
  capacity          TINYINT UNSIGNED NOT NULL DEFAULT 4,
  status            ENUM('free','occupied','reserved') NOT NULL DEFAULT 'free',
  current_order_id  INT UNSIGNED NULL,
  is_active         TINYINT(1)   NOT NULL DEFAULT 1,
  sort_order        SMALLINT     NOT NULL DEFAULT 0,
  qr_token          CHAR(32)     NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_dining_tables_outlet_code (outlet_id, code),
  UNIQUE KEY uq_dining_tables_qr_token (qr_token),
  KEY idx_dining_tables_vendor_outlet (vendor_id, outlet_id),
  CONSTRAINT fk_dining_tables_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_dining_tables_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Semua jualan lalui orders, termasuk runcit (7.1).
-- opened_by NULL bila source = qr / online.
CREATE TABLE orders (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id       INT UNSIGNED NOT NULL,
  outlet_id       INT UNSIGNED NOT NULL,
  order_no        VARCHAR(30)  NOT NULL,
  business_day    DATE         NOT NULL,
  order_type      ENUM('dine_in','takeaway','counter','pickup') NOT NULL,
  table_id        INT UNSIGNED NULL,
  takeaway_no     SMALLINT UNSIGNED NULL,
  status          ENUM('awaiting_payment','pending','open','billed','paid','cancelled') NOT NULL DEFAULT 'open',
  guest_count     TINYINT UNSIGNED NULL,
  source          ENUM('staff','qr','online') NOT NULL DEFAULT 'staff',
  payment_choice  ENUM('counter','online') NULL,
  customer_name   VARCHAR(100) NULL,
  customer_phone  VARCHAR(30)  NULL,
  pickup_at       DATETIME     NULL,
  public_token    CHAR(32)     NULL,
  opened_by       INT UNSIGNED NULL,
  confirmed_by    INT UNSIGNED NULL,
  confirmed_at    DATETIME     NULL,
  terminal_id     INT UNSIGNED NULL,
  note            VARCHAR(255) NULL,
  opened_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  closed_at       DATETIME     NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_orders_outlet_day_no (outlet_id, business_day, order_no),
  UNIQUE KEY uq_orders_outlet_day_takeaway (outlet_id, business_day, takeaway_no),
  UNIQUE KEY uq_orders_public_token (public_token),
  KEY idx_orders_vendor_outlet_status (vendor_id, outlet_id, status),
  KEY idx_orders_vendor_day (vendor_id, business_day),
  KEY idx_orders_vendor_table (vendor_id, table_id),
  CONSTRAINT fk_orders_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_orders_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_orders_table FOREIGN KEY (table_id) REFERENCES dining_tables (id),
  CONSTRAINT fk_orders_opened_by FOREIGN KEY (opened_by) REFERENCES users (id),
  CONSTRAINT fk_orders_confirmed_by FOREIGN KEY (confirmed_by) REFERENCES users (id),
  CONSTRAINT fk_orders_terminal FOREIGN KEY (terminal_id) REFERENCES terminals (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Satu tiket = satu hantaran ke dapur. printed_at elak cetak berganda (9.5).
CREATE TABLE kitchen_tickets (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id     INT UNSIGNED NOT NULL,
  outlet_id     INT UNSIGNED NOT NULL,
  order_id      INT UNSIGNED NOT NULL,
  ticket_no     SMALLINT UNSIGNED NOT NULL,
  business_day  DATE         NOT NULL,
  status        ENUM('new','preparing','ready','done','cancelled') NOT NULL DEFAULT 'new',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  started_at    DATETIME     NULL,
  ready_at      DATETIME     NULL,
  printed_at    DATETIME     NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_kitchen_tickets_outlet_day_no (outlet_id, business_day, ticket_no),
  KEY idx_kitchen_tickets_vendor_outlet_status (vendor_id, outlet_id, status),
  CONSTRAINT fk_kitchen_tickets_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_kitchen_tickets_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_kitchen_tickets_order FOREIGN KEY (order_id) REFERENCES orders (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Medan nama & harga ialah SALINAN GAMBARAN, bukan rujukan (6.D nota).
-- added_by NULL untuk item yang dipesan pelanggan melalui QR / kedai online.
CREATE TABLE order_items (
  id                 INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id          INT UNSIGNED  NOT NULL,
  order_id           INT UNSIGNED  NOT NULL,
  product_id         INT UNSIGNED  NOT NULL,
  product_name       VARCHAR(150)  NOT NULL,
  icon               VARCHAR(16)   NULL,
  base_price         DECIMAL(10,2) NOT NULL,
  unit_price         DECIMAL(10,2) NOT NULL,
  variant_label      VARCHAR(255)  NULL,
  qty                DECIMAL(10,2) NOT NULL,
  paid_qty           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  line_total         DECIMAL(10,2) NOT NULL,
  status             ENUM('ordered','served','cancelled') NOT NULL DEFAULT 'ordered',
  kitchen_ticket_id  INT UNSIGNED  NULL,
  note               VARCHAR(255)  NULL,
  added_by           INT UNSIGNED  NULL,
  added_at           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_order_items_vendor_order (vendor_id, order_id),
  KEY idx_order_items_vendor_ticket (vendor_id, kitchen_ticket_id),
  CONSTRAINT fk_order_items_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products (id),
  CONSTRAINT fk_order_items_ticket FOREIGN KEY (kitchen_ticket_id) REFERENCES kitchen_tickets (id),
  CONSTRAINT fk_order_items_added_by FOREIGN KEY (added_by) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE order_item_options (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id      INT UNSIGNED  NOT NULL,
  order_item_id  INT UNSIGNED  NOT NULL,
  group_name     VARCHAR(100)  NOT NULL,
  option_label   VARCHAR(100)  NOT NULL,
  price_delta    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (id),
  KEY idx_order_item_options_vendor_item (vendor_id, order_item_id),
  CONSTRAINT fk_order_item_options_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_order_item_options_item FOREIGN KEY (order_item_id) REFERENCES order_items (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
