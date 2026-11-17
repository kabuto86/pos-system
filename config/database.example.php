<?php
// Salin fail ini ke config/database.php dan isi kredensial sebenar.
// config/database.php berada dalam .gitignore — jangan commit kata laluan.
return [
    'host'     => '127.0.0.1',
    'port'     => 3306,
    'database' => 'pos_saas',
    'username' => 'pos_user',
    'password' => '',
    // 'local' membenarkan `migrate.php fresh` dan seed demo.
    // Pelayan sebenar: 'production' — arahan yang memadam data akan ditolak.
    'env'      => 'local',
];
