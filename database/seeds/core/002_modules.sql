-- 10 modul platform (PELAN.md 9.4). Nama & keterangan melalui kunci terjemahan.
-- `pos` ialah teras: sentiasa ada dalam setiap pelan.

INSERT INTO modules (code, name_key, description_key, is_core, requires_business_type, sort_order) VALUES
  ('pos',            'module.pos.name',            'module.pos.description',            1, 'any',        1),
  ('promotions',     'module.promotions.name',     'module.promotions.description',     0, 'any',        2),
  ('stock',          'module.stock.name',          'module.stock.description',          0, 'any',        3),
  ('reports',        'module.reports.name',        'module.reports.description',        0, 'any',        4),
  ('csv_import',     'module.csv_import.name',     'module.csv_import.description',     0, 'any',        5),
  ('waiter_app',     'module.waiter_app.name',     'module.waiter_app.description',     0, 'restaurant', 6),
  ('qr_order',       'module.qr_order.name',       'module.qr_order.description',       0, 'restaurant', 7),
  ('kitchen',        'module.kitchen.name',        'module.kitchen.description',        0, 'restaurant', 8),
  ('online_payment', 'module.online_payment.name', 'module.online_payment.description', 0, 'any',        9),
  ('online_order',   'module.online_order.name',   'module.online_order.description',   0, 'any',        10)
ON DUPLICATE KEY UPDATE
  name_key = VALUES(name_key), description_key = VALUES(description_key),
  is_core = VALUES(is_core), requires_business_type = VALUES(requires_business_type),
  sort_order = VALUES(sort_order);
