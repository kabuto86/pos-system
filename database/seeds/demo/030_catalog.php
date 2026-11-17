<?php
// Katalog demo. 18 produk asal dari js/data.js diberikan kepada KEDAI01 dan
// KEDAI02 (PELAN.md 17) dengan BARCODE YANG SAMA: menguji UNIQUE(vendor_id,
// barcode) dan memastikan carian barcode tidak bocor ke vendor lain (3.5).
// KEDAI03 dapat menu peniaga dari rumah sendiri.

require_once __DIR__ . '/../SeedHelper.php';

return function (PDO $db): void {
    // [kategori => [nama, harga, emoji, stok, unit, kos]]
    $classic = [
        'Makanan' => [
            ['Nasi Lemak', 4.50, '🍛', 20, 'pcs', 2.20],
            ['Roti Canai', 2.00, '🫓', 30, 'pcs', 0.80],
            ['Mee Goreng', 5.00, '🍜', 15, 'pcs', 2.30],
            ['Ayam Goreng', 6.50, '🍗', 12, 'pcs', 3.10],
            ['Burger', 7.00, '🍔', 10, 'pcs', 3.50],
            ['Pizza Slice', 8.00, '🍕', 8, 'pcs', 3.80],
        ],
        'Minuman' => [
            ['Teh Tarik', 2.20, '🍵', 40, 'cawan', 0.70],
            ['Kopi O', 1.80, '☕', 40, 'cawan', 0.50],
            ['Air Sirap', 1.50, '🥤', 25, 'cawan', 0.40],
            ['Jus Oren', 3.00, '🧃', 18, 'botol', 1.60],
            ['Air Mineral', 1.20, '💧', 50, 'botol', 0.55],
            ['Milkshake', 4.00, '🥛', 0, 'cawan', 1.90],
        ],
        'Snek' => [
            ['Kerepek', 1.50, '🍟', 35, 'bungkus', 0.80],
            ['Biskut', 2.50, '🍪', 22, 'bungkus', 1.40],
            ['Donut', 3.20, '🍩', 14, 'pcs', 1.50],
            ['Kek Coklat', 5.50, '🍰', 9, 'pcs', 2.60],
            ['Aiskrim', 3.50, '🍦', 0, 'pcs', 1.70],
            ['Coklat Bar', 2.00, '🍫', 28, 'pcs', 1.10],
        ],
    ];

    // Variasi dari js/data.js — `code` dikekalkan untuk makeLineId()
    $classicVariations = [
        'Nasi Lemak' => [
            ['lauk', 'Lauk', 'single', 1, [['biasa', 'Biasa (ikan bilis)', 0], ['ayam', 'Ayam goreng', 3.00], ['rendang', 'Rendang daging', 4.50]]],
            ['pedas', 'Kepedasan', 'single', 1, [['kurang', 'Kurang pedas', 0], ['sederhana', 'Sederhana', 0], ['extra', 'Extra pedas', 0.30]]],
            ['tambah_nl', 'Tambahan', 'multi', 0, [['telur', 'Telur mata', 1.50], ['sambal', 'Sambal extra', 1.00], ['timun', 'Tanpa timun', 0]]],
        ],
        'Burger' => [
            ['patty', 'Jenis Patty', 'single', 1, [['ayam', 'Ayam', 0], ['daging', 'Daging', 1.50], ['double', 'Double daging', 4.00]]],
            ['tambah_bg', 'Tambahan', 'multi', 0, [['keju', 'Keju', 1.00], ['telur', 'Telur', 1.20], ['bawang', 'Tanpa bawang', 0]]],
        ],
        'Teh Tarik' => [
            ['saiz', 'Saiz', 'single', 1, [['kecil', 'Kecil', 0], ['besar', 'Besar', 0.80]]],
            ['suhu', 'Suhu', 'single', 1, [['panas', 'Panas', 0], ['ais', 'Ais', 0.50]]],
            ['tambah_tt', 'Tambahan', 'multi', 0, [['kurang_manis', 'Kurang manis', 0], ['extra_susu', 'Extra susu', 0.60], ['tanpa_ais', 'Tanpa ais', -0.20]]],
        ],
        'Kopi O' => [
            ['saiz', 'Saiz', 'single', 1, [['kecil', 'Kecil', 0], ['besar', 'Besar', 0.70]]],
            ['gula', 'Paras Gula', 'single', 1, [['normal', 'Normal', 0], ['kurang', 'Kurang gula', 0], ['kosong', 'Kosong', 0]]],
        ],
    ];

    $homeMenu = [
        'Lauk & Nasi' => [
            ['Nasi Lemak Bungkus', 5.00, '🍛', 30, 'bungkus', 2.40],
            ['Nasi Ayam Madu', 9.00, '🍗', 20, 'bungkus', 4.50],
            ['Mee Bandung', 8.50, '🍜', 15, 'mangkuk', 4.00],
        ],
        'Kuih & Kek' => [
            ['Karipap Pusing (10 biji)', 6.00, '🥟', 25, 'kotak', 2.80],
            ['Kek Batik', 25.00, '🍫', 6, 'biji', 12.00],
            ['Puding Roti', 12.00, '🍮', 8, 'bekas', 5.00],
            ['Seri Muka (6 keping)', 9.00, '🍰', 10, 'kotak', 4.20],
        ],
        'Minuman' => [
            ['Air Bandung Botol', 3.50, '🥤', 40, 'botol', 1.20],
        ],
    ];
    $homeVariations = [
        'Nasi Ayam Madu' => [
            ['nasi', 'Jenis nasi', 'single', 1, [['ayam', 'Nasi ayam', 0], ['putih', 'Nasi putih', -0.50]]],
            ['tambah', 'Tambahan', 'multi', 0, [['telur', 'Telur rebus', 1.00], ['sup', 'Sup ekstra', 1.50]]],
        ],
    ];

    // Kategori tanpa masak: tidak masuk tiket dapur (send_to_kitchen = 0)
    $noKitchen = ['Snek', 'Kuih & Kek'];

    $vendorCatalogs = [
        'KEDAI01' => [$classic, $classicVariations, true],
        'KEDAI02' => [$classic, $classicVariations, true],
        'KEDAI03' => [$homeMenu, $homeVariations, false],
    ];

    foreach ($vendorCatalogs as $vendorCode => [$catalog, $variations, $withBarcode]) {
        $vendorId = SeedHelper::vendorId($db, $vendorCode);
        $outletStmt = $db->prepare('SELECT id, code FROM outlets WHERE vendor_id = ?');
        $outletStmt->execute([$vendorId]);
        $outlets = $outletStmt->fetchAll(PDO::FETCH_KEY_PAIR); // id => code

        $sort = 0;
        $catSort = 0;
        foreach ($catalog as $categoryName => $products) {
            $categoryId = SeedHelper::upsert($db, 'categories', ['vendor_id' => $vendorId, 'name' => $categoryName], [
                'sort_order' => ++$catSort, 'is_active' => 1,
                'send_to_kitchen' => in_array($categoryName, $noKitchen, true) ? 0 : 1,
            ]);

            foreach ($products as [$name, $price, $icon, $stock, $unit, $cost]) {
                $sort++;
                $productId = SeedHelper::upsert($db, 'products', ['vendor_id' => $vendorId, 'name' => $name], [
                    'category_id'   => $categoryId,
                    'icon'          => $icon,
                    'barcode'       => $withBarcode ? SeedHelper::ean13('955' . str_pad((string) $sort, 9, '0', STR_PAD_LEFT)) : null,
                    'sku'           => sprintf('SKU-%03d', $sort),
                    'price'         => $price,
                    'cost_price'    => $cost,
                    'unit'          => $unit,
                    'is_tax_exempt' => $name === 'Air Mineral' ? 1 : 0,
                    'is_active'     => 1,
                    'sort_order'    => $sort,
                ]);

                // Stok & harga per kedai. Kajang caj lebih untuk Nasi Lemak: uji price_override.
                foreach ($outlets as $outletId => $outletCode) {
                    $override = ($outletCode === 'KJG' && $name === 'Nasi Lemak') ? 5.00 : null;
                    $db->prepare(
                        'INSERT INTO product_outlets (vendor_id, outlet_id, product_id, price_override, stock, min_stock, is_available)
                         VALUES (?, ?, ?, ?, ?, ?, 1)
                         ON DUPLICATE KEY UPDATE price_override = VALUES(price_override), stock = VALUES(stock),
                                                 min_stock = VALUES(min_stock), is_available = 1'
                    )->execute([$vendorId, $outletId, $productId, $override, $stock, 5]);
                }

                foreach ($variations[$name] ?? [] as $gSort => [$gCode, $gName, $gType, $gRequired, $options]) {
                    $groupId = SeedHelper::upsert($db, 'variation_groups', ['product_id' => $productId, 'code' => $gCode], [
                        'vendor_id' => $vendorId, 'name' => $gName, 'type' => $gType,
                        'is_required' => $gRequired, 'sort_order' => $gSort + 1,
                    ]);
                    foreach ($options as $oSort => [$oCode, $oLabel, $delta]) {
                        SeedHelper::upsert($db, 'variation_options', ['group_id' => $groupId, 'code' => $oCode], [
                            'vendor_id' => $vendorId, 'label' => $oLabel, 'price_delta' => $delta,
                            'sort_order' => $oSort + 1, 'is_active' => 1,
                        ]);
                    }
                }
            }
        }
    }
};
