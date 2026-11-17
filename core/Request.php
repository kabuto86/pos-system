<?php
// Membaca input permintaan: query string, borang POST, atau badan JSON.
//
// `vendor_id` DITOLAK di sini secara sengaja. Vendor datang dari sesi melalui
// VendorScope, tidak pernah dari pelayar (PELAN.md 3.1). Kod yang cuba
// membacanya dari input gagal serta-merta semasa dibina, bukan bocor senyap
// dalam produksi.

class Request
{
    private static ?array $body = null;

    public static function method(): string
    {
        return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    }

    public static function isPost(): bool
    {
        return self::method() === 'POST';
    }

    public static function input(string $key, mixed $default = null): mixed
    {
        self::guard($key);
        $body = self::body();
        return array_key_exists($key, $body) ? $body[$key] : $default;
    }

    public static function query(string $key, mixed $default = null): mixed
    {
        self::guard($key);
        return $_GET[$key] ?? $default;
    }

    // Badan dahulu, kemudian query string.
    public static function int(string $key, int $default = 0): int
    {
        $value = self::input($key, self::query($key));
        return filter_var($value, FILTER_VALIDATE_INT) !== false ? (int) $value : $default;
    }

    public static function string(string $key, string $default = ''): string
    {
        $value = self::input($key, self::query($key, $default));
        return is_scalar($value) ? trim((string) $value) : $default;
    }

    // Semua medan badan permintaan, tanpa vendor_id.
    public static function all(): array
    {
        $body = self::body();
        unset($body['vendor_id']);
        return $body;
    }

    private static function body(): array
    {
        if (self::$body === null) {
            $type = $_SERVER['CONTENT_TYPE'] ?? '';
            if (str_contains($type, 'application/json')) {
                $decoded = json_decode(file_get_contents('php://input') ?: '', true);
                self::$body = is_array($decoded) ? $decoded : [];
            } else {
                self::$body = $_POST;
            }
        }
        return self::$body;
    }

    private static function guard(string $key): void
    {
        if ($key === 'vendor_id') {
            throw new LogicException('vendor_id tidak boleh dibaca dari permintaan. Guna VendorScope::id().');
        }
    }
}
