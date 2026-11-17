<?php
// Dimuatkan oleh setiap titik masuk (halaman, api/, CLI).
// Tugasnya kecil: zon waktu, autoload kelas core/ dan jobs/, helper t().

date_default_timezone_set('Asia/Kuala_Lumpur');

define('APP_ROOT', dirname(__DIR__));

// Autoload ringkas: Database -> core/Database.php,
// Product\SaveProductJob -> jobs/Product/SaveProductJob.php
spl_autoload_register(function (string $class): void {
    $path = str_replace('\\', '/', $class) . '.php';
    foreach (['/core/', '/jobs/'] as $dir) {
        $file = APP_ROOT . $dir . $path;
        if (is_file($file)) {
            require $file;
            return;
        }
    }
});

require_once APP_ROOT . '/core/Lang.php';
