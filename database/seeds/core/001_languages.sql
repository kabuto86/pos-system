-- Bahasa sistem (PELAN.md 7.9). Bahasa Melayu lalai, Inggeris aktif.
-- Idempotent: dijalankan semula tidak menggandakan baris.

INSERT INTO languages (code, name, native_name, is_active, is_default, sort_order) VALUES
  ('ms', 'Malay',   'Bahasa Melayu', 1, 1, 1),
  ('en', 'English', 'English',       1, 0, 2)
ON DUPLICATE KEY UPDATE
  name = VALUES(name), native_name = VALUES(native_name),
  is_active = VALUES(is_active), is_default = VALUES(is_default), sort_order = VALUES(sort_order);
