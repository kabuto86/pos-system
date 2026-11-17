<?php
// Satu sambungan PDO setiap permintaan.
// utf8mb4 ditetapkan pada sambungan, bukan hanya pada jadual (PELAN.md 14.9).
// Tanpanya emoji produk rosak walaupun jadual betul.

class Database
{
    private static ?PDO $pdo = null;
    private static ?array $config = null;

    public static function config(): array
    {
        if (self::$config === null) {
            $file = APP_ROOT . '/config/database.php';
            if (!is_file($file)) {
                throw new RuntimeException(
                    'config/database.php tiada. Salin config/database.example.php dan isi kredensial.'
                );
            }
            self::$config = require $file;
        }
        return self::$config;
    }

    public static function connection(): PDO
    {
        if (self::$pdo === null) {
            $c = self::config();
            $dsn = sprintf(
                'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
                $c['host'],
                $c['port'] ?? 3306,
                $c['database']
            );
            self::$pdo = new PDO($dsn, $c['username'], $c['password'], [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci, time_zone = '+08:00'",
            ]);
        }
        return self::$pdo;
    }

    // 'local' membenarkan arahan yang memadam data (migrate.php fresh, seed demo).
    public static function env(): string
    {
        return self::config()['env'] ?? 'production';
    }
}
