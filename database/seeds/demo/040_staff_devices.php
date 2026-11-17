<?php
// Akaun demo, peranti (kaunter/waiter/dapur) dan meja dengan qr_token.
// Kata laluan & PIN di-hash Argon2id melalui core/Password.php (PELAN.md 4.4).
// Pulangkan senarai log masuk untuk dicetak di hujung `fresh --demo`.

require_once __DIR__ . '/../SeedHelper.php';

return function (PDO $db): array {
    $password = 'demo12345'; // demo tempatan sahaja; env bukan 'local' ditolak pelari

    // Superadmin platform: vendor_id NULL
    SeedHelper::upsert($db, 'users', ['email' => 'superadmin@kedaipos.test'], [
        'vendor_id' => null, 'password_hash' => Password::hash($password), 'pin_hash' => null,
        'full_name' => 'Pentadbir Platform', 'role' => 'superadmin', 'outlet_id' => null,
        'is_active' => 1, 'failed_attempts' => 0, 'locked_until' => null,
    ]);

    // [vendor => [admin, [kedai => [kakitangan], peranti, meja]]]
    $setup = [
        'KEDAI01' => [
            'admin' => ['ahmad@majujaya.test', 'Ahmad bin Yusof'],
            'outlets' => [
                'HQ' => [
                    'staff'     => [['Ali', 'cashier', '1111']],
                    'terminals' => [['K1', 'Kaunter 1', 'cashier', 'K1', 0]],
                    'tables'    => [],
                ],
            ],
        ],
        'KEDAI02' => [
            'admin' => ['pakmat@selera.test', 'Mat bin Salleh'],
            'outlets' => [
                'BGI' => [
                    'staff' => [
                        ['Ali', 'cashier', '1111'], ['Aisyah', 'cashier', '2222'],
                        ['Kumar', 'waiter', '3333'], ['Mei Ling', 'waiter', '4444'],
                    ],
                    'terminals' => [
                        ['K1', 'Kaunter 1', 'cashier', 'K1', 0],
                        ['W1', 'Tablet Waiter', 'waiter', 'W1', 0],
                        ['D1', 'Dapur', 'kitchen', 'D1', 1],
                    ],
                    'tables' => [
                        ['M1', 'Meja 1', 'Dalam', 4], ['M2', 'Meja 2', 'Dalam', 4], ['M3', 'Meja 3', 'Dalam', 2],
                        ['M4', 'Meja 4', 'Dalam', 6], ['M5', 'Meja 5', 'Luar', 4], ['M6', 'Meja 6', 'Luar', 4],
                        ['M7', 'Meja 7', 'Luar', 4], ['M8', 'Meja 8', 'Luar', 8],
                    ],
                ],
                'KJG' => [
                    'staff'     => [['Hafiz', 'cashier', '1111'], ['Siti', 'waiter', '2222']],
                    'terminals' => [['K1', 'Kaunter 1', 'cashier', 'K1', 0]],
                    'tables'    => [['M1', 'Meja 1', 'Dalam', 4], ['M2', 'Meja 2', 'Dalam', 4], ['M3', 'Meja 3', 'Dalam', 4], ['M4', 'Meja 4', 'Dalam', 4]],
                ],
            ],
        ],
        'KEDAI03' => [
            'admin' => ['kakani@dapurkakani.test', 'Ani binti Kassim'],
            'outlets' => [
                'RUMAH' => [
                    'staff'     => [['Kak Ani', 'cashier', '1234']],
                    'terminals' => [['K1', 'Telefon Kak Ani', 'cashier', 'KA', 0]],
                    'tables'    => [], // peniaga dari rumah: tiada meja
                ],
            ],
        ],
    ];

    $notes = [
        'Akaun demo (kata laluan semua akaun e-mel: ' . $password . ')',
        str_repeat('-', 72),
        sprintf('%-9s %-26s %s', 'Superadmin', 'superadmin@kedaipos.test', ''),
    ];

    foreach ($setup as $vendorCode => $v) {
        $vendorId = SeedHelper::vendorId($db, $vendorCode);
        [$adminEmail, $adminName] = $v['admin'];

        SeedHelper::upsert($db, 'users', ['email' => $adminEmail], [
            'vendor_id' => $vendorId, 'password_hash' => Password::hash($password), 'pin_hash' => null,
            'full_name' => $adminName, 'role' => 'admin', 'outlet_id' => null,
            'is_active' => 1, 'failed_attempts' => 0, 'locked_until' => null,
        ]);
        $notes[] = sprintf('%-9s %-26s admin', $vendorCode, $adminEmail);

        foreach ($v['outlets'] as $outletCode => $o) {
            $outletId = SeedHelper::outletId($db, $vendorId, $outletCode);

            // Kakitangan PIN sahaja: tiada e-mel, dikenal pasti melalui vendor + kedai + nama
            $pins = [];
            foreach ($o['staff'] as [$name, $role, $pin]) {
                SeedHelper::upsert($db, 'users', ['vendor_id' => $vendorId, 'outlet_id' => $outletId, 'full_name' => $name], [
                    'email' => null, 'password_hash' => null, 'pin_hash' => Password::hash($pin),
                    'role' => $role, 'is_active' => 1, 'failed_attempts' => 0, 'locked_until' => null,
                ]);
                $pins[] = "{$name} ({$role}) {$pin}";
            }
            if ($pins) {
                $notes[] = sprintf('%-9s %-26s PIN: %s', '', $outletCode, implode(', ', $pins));
            }

            foreach ($o['terminals'] as [$tCode, $tName, $tType, $prefix, $autoPrint]) {
                SeedHelper::upsert($db, 'terminals', ['outlet_id' => $outletId, 'code' => $tCode], [
                    'vendor_id' => $vendorId, 'name' => $tName, 'type' => $tType,
                    'receipt_prefix' => $prefix, 'auto_print' => $autoPrint, 'is_active' => 1,
                ]);
            }

            foreach ($o['tables'] as $i => [$tCode, $tName, $area, $capacity]) {
                $tableId = SeedHelper::upsert($db, 'dining_tables', ['outlet_id' => $outletId, 'code' => $tCode], [
                    'vendor_id' => $vendorId, 'name' => $tName, 'area' => $area, 'capacity' => $capacity,
                    'status' => 'free', 'current_order_id' => null, 'is_active' => 1, 'sort_order' => $i + 1,
                ]);
                // Token dijana sekali sahaja: jalan semula seed tidak mematikan QR yang sudah dicetak
                $db->prepare('UPDATE dining_tables SET qr_token = ? WHERE id = ? AND qr_token IS NULL')
                   ->execute([bin2hex(random_bytes(16)), $tableId]);
            }
        }
    }

    $notes[] = str_repeat('-', 72);
    $notes[] = 'Kedai online KEDAI03: s/kak-ani    Senarai penuh: database/seeds/demo/README.md';
    return $notes;
};
