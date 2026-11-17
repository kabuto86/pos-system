<?php
// Tiga vendor demo (PELAN.md 3.4, 15.2). Dua vendor sejak hari pertama
// supaya WHERE vendor_id yang tertinggal terserlah serta-merta.
//
//   KEDAI01  runcit       Asas       1 kedai
//   KEDAI02  kedai makan  Pro        2 kedai (Bangi, Kajang) — isu kedai berbilang awal
//   KEDAI03  dari rumah   Percubaan  1 kedai, s/kak-ani, tiada meja

require_once __DIR__ . '/../SeedHelper.php';

return function (PDO $db): void {
    $vendors = [
        'KEDAI01' => [
            'name' => 'Kedai Runcit Maju Jaya', 'business_type' => 'retail', 'status' => 'active',
            'phone' => '03-4021 5566', 'address' => '22, Jalan Pahang, 53000 Kuala Lumpur',
            'plan' => 'basic', 'sub_status' => 'active',
            'outlets' => [
                'HQ' => ['name' => 'Kedai Utama', 'address' => '22, Jalan Pahang, 53000 Kuala Lumpur', 'phone' => '03-4021 5566', 'slug' => null],
            ],
        ],
        'KEDAI02' => [
            'name' => 'Restoran Selera Kampung', 'business_type' => 'restaurant', 'status' => 'active',
            'phone' => '03-8925 1234', 'address' => 'No 12, Jalan 7/1, Seksyen 7, 43650 Bangi, Selangor',
            'plan' => 'pro', 'sub_status' => 'active',
            'outlets' => [
                'BGI' => ['name' => 'Cawangan Bangi', 'address' => 'No 12, Jalan 7/1, Seksyen 7, 43650 Bangi, Selangor', 'phone' => '03-8925 1234', 'slug' => null],
                'KJG' => ['name' => 'Cawangan Kajang', 'address' => 'Lot 4, Jalan Reko, 43000 Kajang, Selangor', 'phone' => '03-8736 4410', 'slug' => null],
            ],
        ],
        'KEDAI03' => [
            'name' => 'Dapur Kak Ani', 'business_type' => 'restaurant', 'status' => 'trial',
            'phone' => '012-345 6789', 'address' => 'Taman Seri Muda, 40400 Shah Alam, Selangor',
            'plan' => 'trial', 'sub_status' => 'trial',
            'outlets' => [
                'RUMAH' => ['name' => 'Dapur Kak Ani', 'address' => 'Taman Seri Muda, 40400 Shah Alam, Selangor', 'phone' => '012-345 6789', 'slug' => 'kak-ani'],
            ],
        ],
    ];

    foreach ($vendors as $code => $v) {
        $vendorId = SeedHelper::upsert($db, 'vendors', ['code' => $code], [
            'name' => $v['name'], 'business_type' => $v['business_type'], 'status' => $v['status'],
            'phone' => $v['phone'], 'address' => $v['address'],
        ]);

        $outletIds = [];
        foreach ($v['outlets'] as $outletCode => $o) {
            $outletIds[$outletCode] = SeedHelper::upsert($db, 'outlets', ['vendor_id' => $vendorId, 'code' => $outletCode], [
                'name' => $o['name'], 'address' => $o['address'], 'phone' => $o['phone'],
                'shop_slug' => $o['slug'], 'is_active' => 1, 'opened_at' => '2026-01-01',
            ]);
        }

        // Langganan: satu baris aktif setiap vendor
        $planId = (int) $db->query('SELECT id FROM plans WHERE code = ' . $db->quote($v['plan']))->fetchColumn();
        $isTrial = $v['sub_status'] === 'trial';
        SeedHelper::upsert($db, 'subscriptions', ['vendor_id' => $vendorId], [
            'plan_id'            => $planId,
            'status'             => $v['sub_status'],
            'started_at'         => '2026-01-01 00:00:00',
            'trial_ends_at'      => $isTrial ? date('Y-m-d 23:59:59', strtotime('+14 days')) : null,
            'current_period_end' => $isTrial ? null : date('Y-m-t 23:59:59'),
        ]);

        // Kaedah bayaran: ikon ialah kelas Font Awesome, bukan emoji
        $methods = [
            ['cash', 'Tunai',      'fa-money-bill-wave', 1, 'Terima wang tunai daripada pelanggan dan masukkan amaun di bawah.'],
            ['card', 'Kad',        'fa-credit-card',     0, 'Sila proses bayaran pada terminal kad, kemudian tekan Sahkan Bayaran.'],
            ['qr',   'DuitNow QR', 'fa-qrcode',          0, 'Minta pelanggan imbas kod QR kedai dan tunjukkan bukti bayaran berjaya.'],
        ];
        foreach ($methods as $i => [$mCode, $label, $icon, $needsCash, $note]) {
            SeedHelper::upsert($db, 'payment_methods', ['vendor_id' => $vendorId, 'code' => $mCode], [
                'label' => $label, 'icon' => $icon, 'needs_cash' => $needsCash, 'note' => $note,
                'is_active' => 1, 'sort_order' => $i + 1,
            ]);
        }

        // Tetapan lalai vendor (outlet_id NULL) — PELAN.md 6.F
        $defaults = [
            'day_cutoff_time'                => '04:00',
            'shop_name'                      => $v['name'],
            'shop_address'                   => $v['address'],
            'tax_rate'                       => '0.06',
            'service_charge_rate'            => '0',
            'packaging_fee'                  => '0',
            'receipt_footer'                 => 'Terima kasih, datang lagi',
            'paper_width'                    => '58',
            'printer_name'                   => '',
            'currency_prefix'                => 'RM',
            'discount_tax_mode'              => 'after_tax',
            'manual_discount_max_percent'    => '0',
            'manual_discount_needs_approval' => '0',
            'default_language'               => 'ms',
            'qr_order_enabled'               => '0',
            'qr_payment_options'             => 'counter',
            'online_order_enabled'           => '0',
            'pickup_payment_options'         => 'counter',
            'pickup_lead_minutes'            => '30',
            'pickup_hours'                   => '{"mon":["10:00","20:00"],"tue":["10:00","20:00"],"wed":["10:00","20:00"],"thu":["10:00","20:00"],"fri":["14:30","20:00"],"sat":["10:00","18:00"],"sun":null}',
            'online_payment_expiry_minutes'  => '15',
        ];
        $setting = $db->prepare(
            'INSERT INTO settings (vendor_id, outlet_id, setting_key, setting_value) VALUES (?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)'
        );
        foreach ($defaults as $key => $value) {
            $setting->execute([$vendorId, null, $key, $value]);
        }

        // Tindihan per kedai: alamat sentiasa per kedai
        foreach ($v['outlets'] as $outletCode => $o) {
            $setting->execute([$vendorId, $outletIds[$outletCode], 'shop_address', $o['address']]);
        }

        if ($code === 'KEDAI02') {
            // Kajang guna pencetak 80mm: uji tindihan lebar resit (Fasa 5)
            $setting->execute([$vendorId, $outletIds['KJG'], 'paper_width', '80']);
            // Pesanan QR dihidupkan di Bangi sahaja: tetapan per kedai (3.9)
            $setting->execute([$vendorId, $outletIds['BGI'], 'qr_order_enabled', '1']);
            $setting->execute([$vendorId, $outletIds['BGI'], 'qr_payment_options', 'both']);
        }
        if ($code === 'KEDAI03') {
            $setting->execute([$vendorId, null, 'online_order_enabled', '1']);
            $setting->execute([$vendorId, null, 'pickup_payment_options', 'both']);
            $setting->execute([$vendorId, null, 'receipt_footer', 'Terima kasih kerana menyokong peniaga kecil']);
        }

        // Gerbang sandbox, kunci KOSONG: isi sendiri dari akaun ujian gerbang (15.2).
        // Tidak aktif selagi kunci belum diisi dan disahkan.
        $gateway = ['KEDAI02' => 'toyyibpay', 'KEDAI03' => 'billplz'][$code] ?? null;
        if ($gateway) {
            SeedHelper::upsert($db, 'vendor_payment_gateways', ['vendor_id' => $vendorId, 'gateway' => $gateway], [
                'credentials_enc' => null, 'is_sandbox' => 1, 'is_active' => 0, 'verified_at' => null,
            ]);
        }
    }
};
