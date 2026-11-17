<?php
// Pelari migrasi & seed KedaiPOS (PELAN.md 15.2). CLI sahaja.
//
//   php database/migrate.php up              migrasi yang belum dijalankan
//   php database/migrate.php status          senarai migrasi: sudah / belum
//   php database/migrate.php seed [--demo]   seeds/core/ (+ seeds/demo/)
//   php database/migrate.php fresh [--demo]  PADAM semua jadual, up, seed
//   php database/migrate.php dump            jana semula database/schema.sql
//   php database/migrate.php superadmin      cipta akaun superadmin
//
// Fail dijalankan melalui PDO utf8mb4, bukan mysql.exe, jadi perangkap cp850
// emoji di Windows (15.1) tidak berlaku.

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require __DIR__ . '/../core/bootstrap.php';

const MIGRATIONS_DIR = __DIR__ . '/migrations';
const SEEDS_DIR      = __DIR__ . '/seeds';
const SCHEMA_FILE    = __DIR__ . '/schema.sql';

$command = $argv[1] ?? 'help';
$demo    = in_array('--demo', $argv, true);

try {
    $db = Database::connection();

    match ($command) {
        'up'         => migrateUp($db),
        'status'     => showStatus($db),
        'seed'       => runSeeds($db, $demo),
        'fresh'      => fresh($db, $demo),
        'dump'       => dumpSchema($db),
        'superadmin' => createSuperadmin($db),
        default      => showHelp(),
    };
} catch (Throwable $e) {
    fwrite(STDERR, "\nGAGAL: " . $e->getMessage() . "\n");
    exit(1);
}

// ---------------------------------------------------------------------------

function showHelp(): void
{
    echo <<<TXT
    Guna:
      php database/migrate.php up | status | seed [--demo] | fresh [--demo] | dump | superadmin

    TXT;
}

function ensureMigrationsTable(PDO $db): void
{
    // Jadual sistem ke-40: rekod migrasi, bukan sebahagian model aplikasi
    $db->exec('CREATE TABLE IF NOT EXISTS schema_migrations (
        version     VARCHAR(100) NOT NULL,
        applied_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (version)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
}

function migrationFiles(): array
{
    $files = glob(MIGRATIONS_DIR . '/*.sql') ?: [];
    sort($files, SORT_STRING);
    return $files;
}

function appliedVersions(PDO $db): array
{
    ensureMigrationsTable($db);
    return $db->query('SELECT version FROM schema_migrations')->fetchAll(PDO::FETCH_COLUMN);
}

function migrateUp(PDO $db): void
{
    $applied = appliedVersions($db);
    $ran = 0;

    foreach (migrationFiles() as $file) {
        $version = basename($file, '.sql');
        if (in_array($version, $applied, true)) {
            continue;
        }
        echo "  migrasi  {$version} ... ";
        // DDL auto-commit dalam MySQL: migrasi gagal separuh jalan tidak
        // digulung balik. Berhenti serta-merta dan tunjuk kenyataan yang gagal.
        runSqlFile($db, $file);
        $db->prepare('INSERT INTO schema_migrations (version) VALUES (?)')->execute([$version]);
        echo "siap\n";
        $ran++;
    }

    echo $ran ? "Migrasi selesai: {$ran} fail.\n" : "Tiada migrasi baharu.\n";
}

function showStatus(PDO $db): void
{
    $applied = appliedVersions($db);
    foreach (migrationFiles() as $file) {
        $version = basename($file, '.sql');
        printf("  [%s] %s\n", in_array($version, $applied, true) ? 'sudah' : 'BELUM', $version);
    }
}

// Pecah fail pada ';' di hujung baris. Baris komen '--' dibuang dahulu
// supaya ';' dalam komen tidak memecah kenyataan.
function runSqlFile(PDO $db, string $file): void
{
    $sql = file_get_contents($file);
    if (str_starts_with($sql, "\xEF\xBB\xBF")) {
        throw new RuntimeException(basename($file) . ' disimpan dengan BOM. Simpan semula sebagai UTF-8 tanpa BOM.');
    }

    $lines = array_filter(
        preg_split('/\R/', $sql),
        fn ($line) => !str_starts_with(ltrim($line), '--')
    );
    $statements = preg_split('/;\s*$/m', implode("\n", $lines));

    foreach ($statements as $statement) {
        $statement = trim($statement);
        if ($statement === '') {
            continue;
        }
        try {
            $db->exec($statement);
        } catch (PDOException $e) {
            $preview = mb_substr(preg_replace('/\s+/', ' ', $statement), 0, 160);
            throw new RuntimeException(basename($file) . "\n  Kenyataan: {$preview}\n  Ralat: " . $e->getMessage());
        }
    }
}

function requireLocal(string $what): void
{
    if (Database::env() !== 'local') {
        throw new RuntimeException("'{$what}' hanya dibenarkan bila config env = 'local'. Pelayan ini: '" . Database::env() . "'.");
    }
}

// Seed .sql dijalankan seperti migrasi. Seed .php memulangkan
// function (PDO $db): ?array — array (jika ada) ialah baris untuk dicetak.
function runSeeds(PDO $db, bool $demo): void
{
    if ($demo) {
        requireLocal('seed --demo');
    }

    $notes = [];
    foreach ($demo ? ['core', 'demo'] : ['core'] as $group) {
        $files = array_filter(
            glob(SEEDS_DIR . "/{$group}/*") ?: [],
            fn ($f) => str_ends_with($f, '.sql') || str_ends_with($f, '.php')
        );
        sort($files, SORT_STRING);

        foreach ($files as $file) {
            echo "  seed     {$group}/" . basename($file) . " ... ";
            if (str_ends_with($file, '.sql')) {
                runSqlFile($db, $file);
            } else {
                $seed = require $file;
                $db->beginTransaction();
                try {
                    $result = $seed($db);
                    $db->commit();
                } catch (Throwable $e) {
                    $db->rollBack();
                    throw new RuntimeException("{$group}/" . basename($file) . ': ' . $e->getMessage(), 0, $e);
                }
                if (is_array($result)) {
                    $notes = array_merge($notes, $result);
                }
            }
            echo "siap\n";
        }
    }

    if ($notes) {
        echo "\n" . implode("\n", $notes) . "\n";
    }
}

function fresh(PDO $db, bool $demo): void
{
    requireLocal('fresh');

    $tables = $db->query(
        "SELECT table_name FROM information_schema.tables
         WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'"
    )->fetchAll(PDO::FETCH_COLUMN);

    echo 'Padam ' . count($tables) . " jadual dalam '" . Database::config()['database'] . "' ...\n";
    $db->exec('SET FOREIGN_KEY_CHECKS = 0');
    foreach ($tables as $table) {
        $db->exec('DROP TABLE `' . str_replace('`', '', $table) . '`');
    }
    $db->exec('SET FOREIGN_KEY_CHECKS = 1');

    migrateUp($db);
    runSeeds($db, $demo);
}

// schema.sql ialah RUJUKAN yang dijana; sumber kebenaran ialah migrations/.
function dumpSchema(PDO $db): void
{
    $tables = $db->query(
        "SELECT table_name FROM information_schema.tables
         WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
         ORDER BY table_name"
    )->fetchAll(PDO::FETCH_COLUMN);

    $applied = appliedVersions($db);
    $out  = "-- KedaiPOS: skema pangkalan data (" . count($tables) . " jadual)\n";
    $out .= "-- DIJANA oleh `php database/migrate.php dump`. Jangan sunting.\n";
    $out .= "-- Sumber kebenaran: database/migrations/. Migrasi terakhir: " . (end($applied) ?: '-') . "\n\n";
    $out .= "SET NAMES utf8mb4;\nSET FOREIGN_KEY_CHECKS = 0;\n\n";

    foreach ($tables as $table) {
        $create = $db->query('SHOW CREATE TABLE `' . $table . '`')->fetch(PDO::FETCH_NUM)[1];
        $create = preg_replace('/ AUTO_INCREMENT=\d+/', '', $create);
        $out .= $create . ";\n\n";
    }
    $out .= "SET FOREIGN_KEY_CHECKS = 1;\n";

    file_put_contents(SCHEMA_FILE, $out);
    echo 'schema.sql dijana: ' . count($tables) . " jadual.\n";
}

// Untuk pelayan sebenar, di mana seed demo tidak dijalankan.
function createSuperadmin(PDO $db): void
{
    $email = strtolower(trim(prompt('E-mel: ')));
    $name  = trim(prompt('Nama penuh: '));
    echo "Kata laluan akan kelihatan semasa ditaip. Kosongkan skrin selepas ini.\n";
    $password = prompt('Kata laluan (min 12 aksara): ');

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new RuntimeException('E-mel tidak sah.');
    }
    if ($name === '') {
        throw new RuntimeException('Nama penuh diperlukan.');
    }
    if (mb_strlen($password) < 12) {
        throw new RuntimeException('Kata laluan mesti sekurang-kurangnya 12 aksara.');
    }

    $exists = $db->prepare('SELECT 1 FROM users WHERE email = ?');
    $exists->execute([$email]);
    if ($exists->fetchColumn()) {
        throw new RuntimeException('E-mel ini sudah digunakan.');
    }

    $db->prepare(
        "INSERT INTO users (vendor_id, email, password_hash, full_name, role) VALUES (NULL, ?, ?, ?, 'superadmin')"
    )->execute([$email, Password::hash($password), $name]);

    echo "Superadmin {$email} dicipta.\n";
}

function prompt(string $label): string
{
    echo $label;
    return rtrim((string) fgets(STDIN), "\r\n");
}
