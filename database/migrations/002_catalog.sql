-- 002 Katalog (5 jadual) — PELAN.md 6.B
-- Produk di peringkat vendor; harga & stok boleh ditindih per kedai (product_outlets).

CREATE TABLE categories (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id        INT UNSIGNED NOT NULL,
  name             VARCHAR(100) NOT NULL,
  sort_order       SMALLINT     NOT NULL DEFAULT 0,
  is_active        TINYINT(1)   NOT NULL DEFAULT 1,
  send_to_kitchen  TINYINT(1)   NOT NULL DEFAULT 1,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_vendor_name (vendor_id, name),
  CONSTRAINT fk_categories_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- barcode & sku unik PER VENDOR (3.5). NULL dibenarkan berbilang.
CREATE TABLE products (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id      INT UNSIGNED  NOT NULL,
  category_id    INT UNSIGNED  NULL,
  name           VARCHAR(150)  NOT NULL,
  icon           VARCHAR(16)   NULL,
  image_path     VARCHAR(255)  NULL,
  barcode        VARCHAR(64)   NULL,
  sku            VARCHAR(64)   NULL,
  price          DECIMAL(10,2) NOT NULL,
  cost_price     DECIMAL(10,2) NULL,
  unit           VARCHAR(20)   NOT NULL DEFAULT 'pcs',
  is_tax_exempt  TINYINT(1)    NOT NULL DEFAULT 0,
  is_active      TINYINT(1)    NOT NULL DEFAULT 1,
  sort_order     SMALLINT      NOT NULL DEFAULT 0,
  created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_products_vendor_barcode (vendor_id, barcode),
  UNIQUE KEY uq_products_vendor_sku (vendor_id, sku),
  KEY idx_products_vendor_category (vendor_id, category_id),
  KEY idx_products_vendor_name (vendor_id, name),
  CONSTRAINT fk_products_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stok sentiasa per kedai. price_override NULL = guna products.price.
CREATE TABLE product_outlets (
  vendor_id       INT UNSIGNED  NOT NULL,
  outlet_id       INT UNSIGNED  NOT NULL,
  product_id      INT UNSIGNED  NOT NULL,
  price_override  DECIMAL(10,2) NULL,
  stock           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  min_stock       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_available    TINYINT(1)    NOT NULL DEFAULT 1,
  PRIMARY KEY (outlet_id, product_id),
  KEY idx_product_outlets_vendor_product (vendor_id, product_id),
  CONSTRAINT fk_product_outlets_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_product_outlets_outlet FOREIGN KEY (outlet_id) REFERENCES outlets (id),
  CONSTRAINT fk_product_outlets_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- `code` wajib kekal: makeLineId() bergantung padanya untuk kunci troli stabil
CREATE TABLE variation_groups (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id    INT UNSIGNED NOT NULL,
  product_id   INT UNSIGNED NOT NULL,
  code         VARCHAR(40)  NOT NULL,
  name         VARCHAR(100) NOT NULL,
  type         ENUM('single','multi') NOT NULL DEFAULT 'single',
  is_required  TINYINT(1)   NOT NULL DEFAULT 0,
  sort_order   SMALLINT     NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_variation_groups_product_code (product_id, code),
  KEY idx_variation_groups_vendor_product (vendor_id, product_id),
  CONSTRAINT fk_variation_groups_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_variation_groups_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE variation_options (
  id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  vendor_id    INT UNSIGNED  NOT NULL,
  group_id     INT UNSIGNED  NOT NULL,
  code         VARCHAR(40)   NOT NULL,
  label        VARCHAR(100)  NOT NULL,
  price_delta  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  sort_order   SMALLINT      NOT NULL DEFAULT 0,
  is_active    TINYINT(1)    NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_variation_options_group_code (group_id, code),
  KEY idx_variation_options_vendor_group (vendor_id, group_id),
  CONSTRAINT fk_variation_options_vendor FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  CONSTRAINT fk_variation_options_group FOREIGN KEY (group_id) REFERENCES variation_groups (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
