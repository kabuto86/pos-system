<?php
// Terjemahan antara muka (PELAN.md 7.9 hingga 7.11).
//
//   t('cart.pay')                                  -> "Bayar"
//   t('stock.insufficient', ['product' => $name])  -> "Stok Nasi Lemak tidak mencukupi"
//
// Semua rentetan satu bahasa dimuat SEKALI setiap permintaan.
// Kunci hilang -> nilai Bahasa Melayu -> kunci itu sendiri. Tidak pernah kosong.
// Hanya teks antara muka diterjemah; data vendor (nama produk) tidak.

class Lang
{
    public const DEFAULT = 'ms';

    private static string $current = self::DEFAULT;
    private static array $strings = [];   // [kod_bahasa => [kunci => nilai]]

    public static function use(string $code): void
    {
        self::$current = preg_match('/^[a-z]{2,5}$/', $code) ? $code : self::DEFAULT;
    }

    public static function current(): string
    {
        return self::$current;
    }

    // $code untuk resit: bahasa vendor, bukan bahasa juruwang (7.11).
    public static function get(string $key, array $params = [], ?string $code = null): string
    {
        $code ??= self::$current;
        $value = self::load($code)[$key] ?? '';
        if ($value === '') {
            $value = self::load(self::DEFAULT)[$key] ?? '';
        }
        if ($value === '') {
            $value = $key;
        }

        foreach ($params as $name => $replacement) {
            $value = str_replace('{' . $name . '}', (string) $replacement, $value);
        }
        return $value;
    }

    private static function load(string $code): array
    {
        if (!isset(self::$strings[$code])) {
            self::$strings[$code] = [];
            try {
                $stmt = Database::connection()->prepare(
                    'SELECT translation_key, value FROM translations WHERE language_code = ?'
                );
                $stmt->execute([$code]);
                self::$strings[$code] = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
            } catch (Throwable) {
                // Pangkalan data belum sedia (cth. sebelum migrasi pertama):
                // t() masih pulangkan kunci, bukan kosong, bukan ralat.
            }
        }
        return self::$strings[$code];
    }

    // Untuk ujian sahaja.
    public static function reset(): void
    {
        self::$strings = [];
        self::$current = self::DEFAULT;
    }
}

if (!function_exists('t')) {
    function t(string $key, array $params = []): string
    {
        return Lang::get($key, $params);
    }
}
