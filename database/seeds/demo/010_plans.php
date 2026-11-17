<?php
// Pelan langganan demo dengan HARGA CONTOH (PELAN.md 9.2, 9.4).
// Sufi tetapkan harga sebenar melalui panel superadmin.
//
//   Asas       pos sahaja                 -> KEDAI01 (uji sekatan modul)
//   Pro        semua 10 modul             -> KEDAI02
//   Percubaan  semua modul, had kecil     -> KEDAI03

require_once __DIR__ . '/../SeedHelper.php';

return function (PDO $db): void {
    $allModules = $db->query('SELECT code FROM modules ORDER BY sort_order')->fetchAll(PDO::FETCH_COLUMN);

    $plans = [
        'basic' => [
            'name' => 'Asas', 'price_per_outlet' => 49.00,
            'max_outlets' => 1, 'max_terminals_per_outlet' => 2, 'max_users' => 5, 'max_products' => 200,
            'tiers'   => [[1, 1, 49.00], [2, 5, 39.00], [6, null, 29.00]],
            'modules' => ['pos'],
        ],
        'pro' => [
            'name' => 'Pro', 'price_per_outlet' => 99.00,
            'max_outlets' => 10, 'max_terminals_per_outlet' => 5, 'max_users' => 30, 'max_products' => 5000,
            'tiers'   => [[1, 1, 99.00], [2, 5, 79.00], [6, null, 59.00]],
            'modules' => $allModules,
        ],
        'trial' => [
            'name' => 'Percubaan', 'price_per_outlet' => 0.00,
            'max_outlets' => 1, 'max_terminals_per_outlet' => 2, 'max_users' => 3, 'max_products' => 50,
            'tiers'   => [[1, null, 0.00]],
            'modules' => $allModules,
        ],
    ];

    foreach ($plans as $code => $p) {
        $planId = SeedHelper::upsert($db, 'plans', ['code' => $code], [
            'name'                     => $p['name'],
            'base_price'               => 0.00,
            'price_per_outlet'         => $p['price_per_outlet'],
            'max_outlets'              => $p['max_outlets'],
            'max_terminals_per_outlet' => $p['max_terminals_per_outlet'],
            'max_users'                => $p['max_users'],
            'max_products'             => $p['max_products'],
            'is_active'                => 1,
        ]);

        $db->prepare('DELETE FROM plan_outlet_tiers WHERE plan_id = ?')->execute([$planId]);
        $tier = $db->prepare('INSERT INTO plan_outlet_tiers (plan_id, from_outlet, to_outlet, unit_price) VALUES (?, ?, ?, ?)');
        foreach ($p['tiers'] as [$from, $to, $price]) {
            $tier->execute([$planId, $from, $to, $price]);
        }

        $db->prepare('DELETE FROM plan_modules WHERE plan_id = ?')->execute([$planId]);
        $module = $db->prepare('INSERT INTO plan_modules (plan_id, module_code) VALUES (?, ?)');
        foreach ($p['modules'] as $moduleCode) {
            $module->execute([$planId, $moduleCode]);
        }
    }
};
