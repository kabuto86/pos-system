-- KedaiPOS: skema pangkalan data (40 jadual)
-- DIJANA oleh `php database/migrate.php dump`. Jangan sunting.
-- Sumber kebenaran: database/migrations/. Migrasi terakhir: 007_operations

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE `activity_logs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `action` varchar(60) NOT NULL,
  `entity` varchar(60) DEFAULT NULL,
  `entity_id` int(10) unsigned DEFAULT NULL,
  `detail_json` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_activity_logs_vendor_created` (`vendor_id`,`created_at`),
  KEY `fk_activity_logs_user` (`user_id`),
  CONSTRAINT `fk_activity_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_activity_logs_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` smallint(6) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `send_to_kitchen` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_categories_vendor_name` (`vendor_id`,`name`),
  CONSTRAINT `fk_categories_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `dining_tables` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `area` varchar(50) DEFAULT NULL,
  `capacity` tinyint(3) unsigned NOT NULL DEFAULT 4,
  `status` enum('free','occupied','reserved') NOT NULL DEFAULT 'free',
  `current_order_id` int(10) unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` smallint(6) NOT NULL DEFAULT 0,
  `qr_token` char(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dining_tables_outlet_code` (`outlet_id`,`code`),
  UNIQUE KEY `uq_dining_tables_qr_token` (`qr_token`),
  KEY `idx_dining_tables_vendor_outlet` (`vendor_id`,`outlet_id`),
  CONSTRAINT `fk_dining_tables_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_dining_tables_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `invoices` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `invoice_no` varchar(30) NOT NULL,
  `period_start` date NOT NULL,
  `period_end` date NOT NULL,
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tax` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `status` enum('draft','issued','paid','void') NOT NULL DEFAULT 'draft',
  `issued_at` datetime DEFAULT NULL,
  `due_at` datetime DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_invoices_no` (`invoice_no`),
  KEY `idx_invoices_vendor_period` (`vendor_id`,`period_start`),
  CONSTRAINT `fk_invoices_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `invoice_lines` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `invoice_id` int(10) unsigned NOT NULL,
  `description` varchar(255) NOT NULL,
  `outlet_id` int(10) unsigned DEFAULT NULL,
  `qty` decimal(10,2) NOT NULL DEFAULT 1.00,
  `unit_price` decimal(10,2) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `is_prorated` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_invoice_lines_invoice` (`invoice_id`),
  KEY `fk_invoice_lines_outlet` (`outlet_id`),
  CONSTRAINT `fk_invoice_lines_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_invoice_lines_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kitchen_tickets` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `ticket_no` smallint(5) unsigned NOT NULL,
  `business_day` date NOT NULL,
  `status` enum('new','preparing','ready','done','cancelled') NOT NULL DEFAULT 'new',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `started_at` datetime DEFAULT NULL,
  `ready_at` datetime DEFAULT NULL,
  `printed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_kitchen_tickets_outlet_day_no` (`outlet_id`,`business_day`,`ticket_no`),
  KEY `idx_kitchen_tickets_vendor_outlet_status` (`vendor_id`,`outlet_id`,`status`),
  KEY `fk_kitchen_tickets_order` (`order_id`),
  CONSTRAINT `fk_kitchen_tickets_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  CONSTRAINT `fk_kitchen_tickets_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_kitchen_tickets_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `languages` (
  `code` varchar(5) NOT NULL,
  `name` varchar(50) NOT NULL,
  `native_name` varchar(50) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `sort_order` smallint(6) NOT NULL DEFAULT 0,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `login_attempts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(190) DEFAULT NULL,
  `ip_address` varchar(45) NOT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `success` tinyint(1) NOT NULL DEFAULT 0,
  `attempted_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_login_attempts_email` (`email`,`attempted_at`),
  KEY `idx_login_attempts_ip` (`ip_address`,`attempted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `modules` (
  `code` varchar(30) NOT NULL,
  `name_key` varchar(150) NOT NULL,
  `description_key` varchar(150) NOT NULL,
  `is_core` tinyint(1) NOT NULL DEFAULT 0,
  `requires_business_type` enum('any','retail','restaurant') NOT NULL DEFAULT 'any',
  `sort_order` smallint(6) NOT NULL DEFAULT 0,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `online_payments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `gateway` enum('toyyibpay','billplz','senangpay','stripe') NOT NULL,
  `reference` char(32) NOT NULL,
  `gateway_bill_id` varchar(100) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'MYR',
  `status` enum('pending','paid','failed','expired','refunded') NOT NULL DEFAULT 'pending',
  `paid_at` datetime DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `callback_payload` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_online_payments_reference` (`reference`),
  UNIQUE KEY `uq_online_payments_gateway_bill` (`gateway`,`gateway_bill_id`),
  KEY `idx_online_payments_vendor_status` (`vendor_id`,`status`,`expires_at`),
  KEY `idx_online_payments_vendor_order` (`vendor_id`,`order_id`),
  KEY `fk_online_payments_outlet` (`outlet_id`),
  KEY `fk_online_payments_order` (`order_id`),
  CONSTRAINT `fk_online_payments_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  CONSTRAINT `fk_online_payments_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_online_payments_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orders` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `order_no` varchar(30) NOT NULL,
  `business_day` date NOT NULL,
  `order_type` enum('dine_in','takeaway','counter','pickup') NOT NULL,
  `table_id` int(10) unsigned DEFAULT NULL,
  `takeaway_no` smallint(5) unsigned DEFAULT NULL,
  `status` enum('awaiting_payment','pending','open','billed','paid','cancelled') NOT NULL DEFAULT 'open',
  `guest_count` tinyint(3) unsigned DEFAULT NULL,
  `source` enum('staff','qr','online') NOT NULL DEFAULT 'staff',
  `payment_choice` enum('counter','online') DEFAULT NULL,
  `customer_name` varchar(100) DEFAULT NULL,
  `customer_phone` varchar(30) DEFAULT NULL,
  `pickup_at` datetime DEFAULT NULL,
  `public_token` char(32) DEFAULT NULL,
  `opened_by` int(10) unsigned DEFAULT NULL,
  `confirmed_by` int(10) unsigned DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `terminal_id` int(10) unsigned DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `opened_at` datetime NOT NULL DEFAULT current_timestamp(),
  `closed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orders_outlet_day_no` (`outlet_id`,`business_day`,`order_no`),
  UNIQUE KEY `uq_orders_outlet_day_takeaway` (`outlet_id`,`business_day`,`takeaway_no`),
  UNIQUE KEY `uq_orders_public_token` (`public_token`),
  KEY `idx_orders_vendor_outlet_status` (`vendor_id`,`outlet_id`,`status`),
  KEY `idx_orders_vendor_day` (`vendor_id`,`business_day`),
  KEY `idx_orders_vendor_table` (`vendor_id`,`table_id`),
  KEY `fk_orders_table` (`table_id`),
  KEY `fk_orders_opened_by` (`opened_by`),
  KEY `fk_orders_confirmed_by` (`confirmed_by`),
  KEY `fk_orders_terminal` (`terminal_id`),
  CONSTRAINT `fk_orders_confirmed_by` FOREIGN KEY (`confirmed_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_orders_opened_by` FOREIGN KEY (`opened_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_orders_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_orders_table` FOREIGN KEY (`table_id`) REFERENCES `dining_tables` (`id`),
  CONSTRAINT `fk_orders_terminal` FOREIGN KEY (`terminal_id`) REFERENCES `terminals` (`id`),
  CONSTRAINT `fk_orders_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `product_id` int(10) unsigned NOT NULL,
  `product_name` varchar(150) NOT NULL,
  `icon` varchar(16) DEFAULT NULL,
  `base_price` decimal(10,2) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `variant_label` varchar(255) DEFAULT NULL,
  `qty` decimal(10,2) NOT NULL,
  `paid_qty` decimal(10,2) NOT NULL DEFAULT 0.00,
  `line_total` decimal(10,2) NOT NULL,
  `status` enum('ordered','served','cancelled') NOT NULL DEFAULT 'ordered',
  `kitchen_ticket_id` int(10) unsigned DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `added_by` int(10) unsigned DEFAULT NULL,
  `added_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_order_items_vendor_order` (`vendor_id`,`order_id`),
  KEY `idx_order_items_vendor_ticket` (`vendor_id`,`kitchen_ticket_id`),
  KEY `fk_order_items_order` (`order_id`),
  KEY `fk_order_items_product` (`product_id`),
  KEY `fk_order_items_ticket` (`kitchen_ticket_id`),
  KEY `fk_order_items_added_by` (`added_by`),
  CONSTRAINT `fk_order_items_added_by` FOREIGN KEY (`added_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  CONSTRAINT `fk_order_items_ticket` FOREIGN KEY (`kitchen_ticket_id`) REFERENCES `kitchen_tickets` (`id`),
  CONSTRAINT `fk_order_items_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_item_options` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `order_item_id` int(10) unsigned NOT NULL,
  `group_name` varchar(100) NOT NULL,
  `option_label` varchar(100) NOT NULL,
  `price_delta` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `idx_order_item_options_vendor_item` (`vendor_id`,`order_item_id`),
  KEY `fk_order_item_options_item` (`order_item_id`),
  CONSTRAINT `fk_order_item_options_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_item_options_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `outlets` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `shop_slug` varchar(60) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `opened_at` date DEFAULT NULL,
  `closed_at` date DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_outlets_vendor_code` (`vendor_id`,`code`),
  UNIQUE KEY `uq_outlets_shop_slug` (`shop_slug`),
  CONSTRAINT `fk_outlets_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `payment_methods` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `code` varchar(30) NOT NULL,
  `label` varchar(50) NOT NULL,
  `icon` varchar(40) DEFAULT NULL,
  `needs_cash` tinyint(1) NOT NULL DEFAULT 0,
  `note` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` smallint(6) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_payment_methods_vendor_code` (`vendor_id`,`code`),
  CONSTRAINT `fk_payment_methods_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `plans` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL,
  `base_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `price_per_outlet` decimal(10,2) NOT NULL DEFAULT 0.00,
  `max_outlets` int(10) unsigned NOT NULL DEFAULT 1,
  `max_terminals_per_outlet` int(10) unsigned NOT NULL DEFAULT 1,
  `max_users` int(10) unsigned NOT NULL DEFAULT 5,
  `max_products` int(10) unsigned NOT NULL DEFAULT 100,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plans_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `plan_modules` (
  `plan_id` int(10) unsigned NOT NULL,
  `module_code` varchar(30) NOT NULL,
  PRIMARY KEY (`plan_id`,`module_code`),
  KEY `fk_plan_modules_module` (`module_code`),
  CONSTRAINT `fk_plan_modules_module` FOREIGN KEY (`module_code`) REFERENCES `modules` (`code`) ON DELETE CASCADE,
  CONSTRAINT `fk_plan_modules_plan` FOREIGN KEY (`plan_id`) REFERENCES `plans` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `plan_outlet_tiers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `plan_id` int(10) unsigned NOT NULL,
  `from_outlet` int(10) unsigned NOT NULL,
  `to_outlet` int(10) unsigned DEFAULT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tiers_plan_from` (`plan_id`,`from_outlet`),
  CONSTRAINT `fk_tiers_plan` FOREIGN KEY (`plan_id`) REFERENCES `plans` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `products` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `category_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `icon` varchar(16) DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `barcode` varchar(64) DEFAULT NULL,
  `sku` varchar(64) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `cost_price` decimal(10,2) DEFAULT NULL,
  `unit` varchar(20) NOT NULL DEFAULT 'pcs',
  `is_tax_exempt` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` smallint(6) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_products_vendor_barcode` (`vendor_id`,`barcode`),
  UNIQUE KEY `uq_products_vendor_sku` (`vendor_id`,`sku`),
  KEY `idx_products_vendor_category` (`vendor_id`,`category_id`),
  KEY `idx_products_vendor_name` (`vendor_id`,`name`),
  KEY `fk_products_category` (`category_id`),
  CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_products_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_outlets` (
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `product_id` int(10) unsigned NOT NULL,
  `price_override` decimal(10,2) DEFAULT NULL,
  `stock` decimal(10,2) NOT NULL DEFAULT 0.00,
  `min_stock` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_available` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`outlet_id`,`product_id`),
  KEY `idx_product_outlets_vendor_product` (`vendor_id`,`product_id`),
  KEY `fk_product_outlets_product` (`product_id`),
  CONSTRAINT `fk_product_outlets_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_product_outlets_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_product_outlets_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promotions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `name` varchar(150) NOT NULL,
  `code` varchar(30) DEFAULT NULL,
  `type` enum('product_price','product_percent','category_percent','bill_percent','bill_fixed','buy_x_get_y') NOT NULL,
  `value` decimal(10,2) NOT NULL DEFAULT 0.00,
  `buy_qty` smallint(5) unsigned DEFAULT NULL,
  `get_qty` smallint(5) unsigned DEFAULT NULL,
  `get_product_id` int(10) unsigned DEFAULT NULL,
  `starts_on` date DEFAULT NULL,
  `ends_on` date DEFAULT NULL,
  `time_start` time DEFAULT NULL,
  `time_end` time DEFAULT NULL,
  `days_of_week` char(7) NOT NULL DEFAULT '1111111',
  `min_qty` smallint(5) unsigned DEFAULT NULL,
  `min_spend` decimal(10,2) DEFAULT NULL,
  `max_uses` int(10) unsigned DEFAULT NULL,
  `used_count` int(10) unsigned NOT NULL DEFAULT 0,
  `max_uses_per_transaction` smallint(5) unsigned DEFAULT NULL,
  `priority` smallint(6) NOT NULL DEFAULT 0,
  `is_stackable` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_promotions_vendor_code` (`vendor_id`,`code`),
  KEY `idx_promotions_vendor_active_dates` (`vendor_id`,`is_active`,`starts_on`,`ends_on`),
  KEY `fk_promotions_get_product` (`get_product_id`),
  KEY `fk_promotions_created_by` (`created_by`),
  CONSTRAINT `fk_promotions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_promotions_get_product` FOREIGN KEY (`get_product_id`) REFERENCES `products` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_promotions_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promotion_categories` (
  `vendor_id` int(10) unsigned NOT NULL,
  `promotion_id` int(10) unsigned NOT NULL,
  `category_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`promotion_id`,`category_id`),
  KEY `idx_promotion_categories_vendor_category` (`vendor_id`,`category_id`),
  KEY `fk_promotion_categories_category` (`category_id`),
  CONSTRAINT `fk_promotion_categories_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_promotion_categories_promotion` FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_promotion_categories_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promotion_products` (
  `vendor_id` int(10) unsigned NOT NULL,
  `promotion_id` int(10) unsigned NOT NULL,
  `product_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`promotion_id`,`product_id`),
  KEY `idx_promotion_products_vendor_product` (`vendor_id`,`product_id`),
  KEY `fk_promotion_products_product` (`product_id`),
  CONSTRAINT `fk_promotion_products_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_promotion_products_promotion` FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_promotion_products_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(100) NOT NULL,
  `applied_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `settings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned DEFAULT NULL,
  `outlet_scope` int(10) unsigned GENERATED ALWAYS AS (ifnull(`outlet_id`,0)) STORED,
  `setting_key` varchar(60) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_settings_scope_key` (`vendor_id`,`outlet_scope`,`setting_key`),
  KEY `fk_settings_outlet` (`outlet_id`),
  KEY `fk_settings_updated_by` (`updated_by`),
  CONSTRAINT `fk_settings_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_settings_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_settings_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `shifts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `terminal_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `business_day` date NOT NULL,
  `opened_at` datetime NOT NULL DEFAULT current_timestamp(),
  `opening_float` decimal(10,2) NOT NULL DEFAULT 0.00,
  `closed_at` datetime DEFAULT NULL,
  `closing_cash` decimal(10,2) DEFAULT NULL,
  `expected_cash` decimal(10,2) DEFAULT NULL,
  `variance` decimal(10,2) DEFAULT NULL,
  `status` enum('open','closed') NOT NULL DEFAULT 'open',
  `note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_shifts_vendor_outlet_day` (`vendor_id`,`outlet_id`,`business_day`),
  KEY `idx_shifts_vendor_terminal_status` (`vendor_id`,`terminal_id`,`status`),
  KEY `fk_shifts_outlet` (`outlet_id`),
  KEY `fk_shifts_terminal` (`terminal_id`),
  KEY `fk_shifts_user` (`user_id`),
  CONSTRAINT `fk_shifts_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_shifts_terminal` FOREIGN KEY (`terminal_id`) REFERENCES `terminals` (`id`),
  CONSTRAINT `fk_shifts_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_shifts_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_movements` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `product_id` int(10) unsigned NOT NULL,
  `type` enum('sale','refund','void','restock','adjustment') NOT NULL,
  `qty_change` decimal(10,2) NOT NULL,
  `balance_after` decimal(10,2) NOT NULL,
  `ref_transaction_id` int(10) unsigned DEFAULT NULL,
  `ref_order_id` int(10) unsigned DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_stock_movements_vendor_outlet_product` (`vendor_id`,`outlet_id`,`product_id`,`created_at`),
  KEY `fk_stock_movements_outlet` (`outlet_id`),
  KEY `fk_stock_movements_product` (`product_id`),
  KEY `fk_stock_movements_user` (`user_id`),
  CONSTRAINT `fk_stock_movements_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_stock_movements_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  CONSTRAINT `fk_stock_movements_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_stock_movements_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `subscriptions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `plan_id` int(10) unsigned NOT NULL,
  `status` enum('trial','active','past_due','cancelled') NOT NULL DEFAULT 'trial',
  `started_at` datetime NOT NULL DEFAULT current_timestamp(),
  `trial_ends_at` datetime DEFAULT NULL,
  `current_period_end` datetime DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_subscriptions_vendor_status` (`vendor_id`,`status`),
  KEY `fk_subscriptions_plan` (`plan_id`),
  CONSTRAINT `fk_subscriptions_plan` FOREIGN KEY (`plan_id`) REFERENCES `plans` (`id`),
  CONSTRAINT `fk_subscriptions_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `terminals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(100) NOT NULL,
  `type` enum('cashier','waiter','kitchen') NOT NULL DEFAULT 'cashier',
  `receipt_prefix` varchar(10) NOT NULL,
  `auto_print` tinyint(1) NOT NULL DEFAULT 0,
  `device_token_hash` char(64) DEFAULT NULL,
  `registered_at` datetime DEFAULT NULL,
  `registered_by` int(10) unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `last_seen_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_terminals_outlet_code` (`outlet_id`,`code`),
  UNIQUE KEY `uq_terminals_device_token` (`device_token_hash`),
  KEY `idx_terminals_vendor_outlet` (`vendor_id`,`outlet_id`),
  KEY `fk_terminals_registered_by` (`registered_by`),
  CONSTRAINT `fk_terminals_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_terminals_registered_by` FOREIGN KEY (`registered_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_terminals_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transactions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `outlet_id` int(10) unsigned NOT NULL,
  `receipt_no` varchar(30) NOT NULL,
  `business_day` date NOT NULL,
  `type` enum('sale','refund') NOT NULL DEFAULT 'sale',
  `ref_transaction_id` int(10) unsigned DEFAULT NULL,
  `terminal_id` int(10) unsigned DEFAULT NULL,
  `shift_id` int(10) unsigned DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `online_payment_id` int(10) unsigned DEFAULT NULL,
  `order_type` enum('dine_in','takeaway','counter','pickup') NOT NULL,
  `table_label` varchar(50) DEFAULT NULL,
  `takeaway_no` smallint(5) unsigned DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `tax_rate` decimal(5,4) NOT NULL DEFAULT 0.0000,
  `tax` decimal(10,2) NOT NULL DEFAULT 0.00,
  `service_charge` decimal(10,2) NOT NULL DEFAULT 0.00,
  `packaging_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `promo_discount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `manual_discount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount_tax_mode` enum('before_tax','after_tax') NOT NULL DEFAULT 'after_tax',
  `total` decimal(10,2) NOT NULL,
  `payment_method_id` int(10) unsigned DEFAULT NULL,
  `cash_received` decimal(10,2) DEFAULT NULL,
  `change_amount` decimal(10,2) DEFAULT NULL,
  `status` enum('paid','void') NOT NULL DEFAULT 'paid',
  `void_reason` varchar(255) DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `voided_by` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_transactions_outlet_receipt` (`outlet_id`,`receipt_no`),
  KEY `idx_transactions_vendor_day` (`vendor_id`,`business_day`),
  KEY `idx_transactions_vendor_outlet_day` (`vendor_id`,`outlet_id`,`business_day`),
  KEY `idx_transactions_vendor_shift` (`vendor_id`,`shift_id`),
  KEY `fk_transactions_ref` (`ref_transaction_id`),
  KEY `fk_transactions_terminal` (`terminal_id`),
  KEY `fk_transactions_shift` (`shift_id`),
  KEY `fk_transactions_user` (`user_id`),
  KEY `fk_transactions_online_payment` (`online_payment_id`),
  KEY `fk_transactions_payment_method` (`payment_method_id`),
  KEY `fk_transactions_voided_by` (`voided_by`),
  CONSTRAINT `fk_transactions_online_payment` FOREIGN KEY (`online_payment_id`) REFERENCES `online_payments` (`id`),
  CONSTRAINT `fk_transactions_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_transactions_payment_method` FOREIGN KEY (`payment_method_id`) REFERENCES `payment_methods` (`id`),
  CONSTRAINT `fk_transactions_ref` FOREIGN KEY (`ref_transaction_id`) REFERENCES `transactions` (`id`),
  CONSTRAINT `fk_transactions_shift` FOREIGN KEY (`shift_id`) REFERENCES `shifts` (`id`),
  CONSTRAINT `fk_transactions_terminal` FOREIGN KEY (`terminal_id`) REFERENCES `terminals` (`id`),
  CONSTRAINT `fk_transactions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_transactions_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`),
  CONSTRAINT `fk_transactions_voided_by` FOREIGN KEY (`voided_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transaction_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `transaction_id` int(10) unsigned NOT NULL,
  `order_item_id` int(10) unsigned DEFAULT NULL,
  `product_id` int(10) unsigned NOT NULL,
  `product_name` varchar(150) NOT NULL,
  `icon` varchar(16) DEFAULT NULL,
  `base_price` decimal(10,2) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `promotion_id` int(10) unsigned DEFAULT NULL,
  `promotion_name` varchar(150) DEFAULT NULL,
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `qty` decimal(10,2) NOT NULL,
  `line_total` decimal(10,2) NOT NULL,
  `variant_label` varchar(255) DEFAULT NULL,
  `refunded_qty` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `idx_transaction_items_vendor_txn` (`vendor_id`,`transaction_id`),
  KEY `idx_transaction_items_vendor_product` (`vendor_id`,`product_id`),
  KEY `fk_transaction_items_txn` (`transaction_id`),
  KEY `fk_transaction_items_order_item` (`order_item_id`),
  CONSTRAINT `fk_transaction_items_order_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transaction_items_txn` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_transaction_items_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transaction_item_options` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `item_id` int(10) unsigned NOT NULL,
  `group_name` varchar(100) NOT NULL,
  `option_label` varchar(100) NOT NULL,
  `price_delta` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `idx_transaction_item_options_vendor_item` (`vendor_id`,`item_id`),
  KEY `fk_transaction_item_options_item` (`item_id`),
  CONSTRAINT `fk_transaction_item_options_item` FOREIGN KEY (`item_id`) REFERENCES `transaction_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_transaction_item_options_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transaction_orders` (
  `vendor_id` int(10) unsigned NOT NULL,
  `transaction_id` int(10) unsigned NOT NULL,
  `order_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`transaction_id`,`order_id`),
  KEY `idx_transaction_orders_vendor_order` (`vendor_id`,`order_id`),
  KEY `fk_transaction_orders_order` (`order_id`),
  CONSTRAINT `fk_transaction_orders_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  CONSTRAINT `fk_transaction_orders_txn` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_transaction_orders_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transaction_promotions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `transaction_id` int(10) unsigned NOT NULL,
  `promotion_id` int(10) unsigned DEFAULT NULL,
  `promotion_name` varchar(150) NOT NULL,
  `promotion_type` varchar(30) NOT NULL,
  `discount_amount` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_transaction_promotions_vendor_txn` (`vendor_id`,`transaction_id`),
  KEY `idx_transaction_promotions_vendor_promo` (`vendor_id`,`promotion_id`),
  KEY `fk_transaction_promotions_txn` (`transaction_id`),
  CONSTRAINT `fk_transaction_promotions_txn` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_transaction_promotions_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `translations` (
  `language_code` varchar(5) NOT NULL,
  `translation_key` varchar(150) NOT NULL,
  `value` text NOT NULL,
  PRIMARY KEY (`language_code`,`translation_key`),
  CONSTRAINT `fk_translations_language` FOREIGN KEY (`language_code`) REFERENCES `languages` (`code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned DEFAULT NULL,
  `email` varchar(190) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `pin_hash` varchar(255) DEFAULT NULL,
  `full_name` varchar(150) NOT NULL,
  `role` enum('superadmin','admin','cashier','waiter') NOT NULL,
  `outlet_id` int(10) unsigned DEFAULT NULL,
  `language` varchar(5) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `failed_attempts` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `locked_until` datetime DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `idx_users_vendor_outlet_role` (`vendor_id`,`outlet_id`,`role`),
  KEY `fk_users_outlet` (`outlet_id`),
  KEY `fk_users_language` (`language`),
  CONSTRAINT `fk_users_language` FOREIGN KEY (`language`) REFERENCES `languages` (`code`),
  CONSTRAINT `fk_users_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`),
  CONSTRAINT `fk_users_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `variation_groups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `product_id` int(10) unsigned NOT NULL,
  `code` varchar(40) NOT NULL,
  `name` varchar(100) NOT NULL,
  `type` enum('single','multi') NOT NULL DEFAULT 'single',
  `is_required` tinyint(1) NOT NULL DEFAULT 0,
  `sort_order` smallint(6) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_variation_groups_product_code` (`product_id`,`code`),
  KEY `idx_variation_groups_vendor_product` (`vendor_id`,`product_id`),
  CONSTRAINT `fk_variation_groups_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_variation_groups_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `variation_options` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `code` varchar(40) NOT NULL,
  `label` varchar(100) NOT NULL,
  `price_delta` decimal(10,2) NOT NULL DEFAULT 0.00,
  `sort_order` smallint(6) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_variation_options_group_code` (`group_id`,`code`),
  KEY `idx_variation_options_vendor_group` (`vendor_id`,`group_id`),
  CONSTRAINT `fk_variation_options_group` FOREIGN KEY (`group_id`) REFERENCES `variation_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_variation_options_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `vendors` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `business_type` enum('retail','restaurant') NOT NULL,
  `status` enum('trial','active','suspended','cancelled') NOT NULL DEFAULT 'trial',
  `phone` varchar(30) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vendors_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `vendor_payment_gateways` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` int(10) unsigned NOT NULL,
  `gateway` enum('toyyibpay','billplz','senangpay','stripe') NOT NULL,
  `credentials_enc` text DEFAULT NULL,
  `is_sandbox` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  `verified_at` datetime DEFAULT NULL,
  `updated_by` int(10) unsigned DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vendor_gateways` (`vendor_id`,`gateway`),
  KEY `fk_vendor_gateways_updated_by` (`updated_by`),
  CONSTRAINT `fk_vendor_gateways_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_vendor_gateways_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
