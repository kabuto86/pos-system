<?php
// Sejarah jualan 7 hari perniagaan lepas, supaya dashboard & laporan ada isi.
//
// Idempotent: sejarah vendor demo dipadam dahulu, kemudian dijana semula
// dengan benih rawak tetap (mt_srand), jadi hasilnya sama setiap kali.
// Hari ini sengaja dibiarkan kosong dan tiada syif terbuka, supaya aliran
// "buka syif" di Fasa 2 boleh diuji dari awal.
//
// Stok semasa dalam product_outlets ialah nilai demo; sejarah ini tidak
// menulis stock_movements.

require_once __DIR__ . '/../SeedHelper.php';

return function (PDO $db): void {
    foreach (['KEDAI01', 'KEDAI02', 'KEDAI03'] as $vendorCode) {
        $vendorId = SeedHelper::vendorId($db, $vendorCode);
        clearHistory($db, $vendorId);

        $outlets = $db->prepare('SELECT id, code FROM outlets WHERE vendor_id = ? ORDER BY id');
        $outlets->execute([$vendorId]);
        foreach ($outlets->fetchAll() as $outlet) {
            mt_srand(crc32($vendorCode . $outlet['code']));
            seedOutletHistory($db, $vendorId, (int) $outlet['id'], $vendorCode);
        }
    }
};

function clearHistory(PDO $db, int $vendorId): void
{
    $db->prepare('UPDATE dining_tables SET status = ?, current_order_id = NULL WHERE vendor_id = ?')->execute(['free', $vendorId]);
    $db->prepare('UPDATE transactions SET ref_transaction_id = NULL WHERE vendor_id = ?')->execute([$vendorId]);
    // Anak jadual dipadam melalui ON DELETE CASCADE (items, options, transaction_orders)
    foreach (['transaction_promotions', 'transactions', 'online_payments', 'kitchen_tickets', 'orders', 'shifts', 'stock_movements'] as $table) {
        $db->prepare("DELETE FROM {$table} WHERE vendor_id = ?")->execute([$vendorId]);
    }
}

function seedOutletHistory(PDO $db, int $vendorId, int $outletId, string $vendorCode): void
{
    $one = fn (string $sql, array $args) => (function () use ($db, $sql, $args) {
        $s = $db->prepare($sql);
        $s->execute($args);
        return $s->fetch();
    })();

    $terminal = $one("SELECT id, receipt_prefix FROM terminals WHERE vendor_id = ? AND outlet_id = ? AND type = 'cashier' ORDER BY id LIMIT 1", [$vendorId, $outletId]);
    $cashier  = $one("SELECT id FROM users WHERE vendor_id = ? AND outlet_id = ? AND role = 'cashier' ORDER BY id LIMIT 1", [$vendorId, $outletId]);
    if (!$terminal || !$cashier) {
        return;
    }

    $methods = $db->prepare('SELECT code, id FROM payment_methods WHERE vendor_id = ?');
    $methods->execute([$vendorId]);
    $methodIds = $methods->fetchAll(PDO::FETCH_KEY_PAIR);

    $products = $db->prepare(
        'SELECT p.id, p.name, p.icon, p.is_tax_exempt, COALESCE(po.price_override, p.price) AS price
         FROM products p
         JOIN product_outlets po ON po.product_id = p.id AND po.vendor_id = p.vendor_id AND po.outlet_id = ?
         WHERE p.vendor_id = ? AND p.is_active = 1 AND po.is_available = 1
         ORDER BY p.id'
    );
    $products->execute([$outletId, $vendorId]);
    $products = $products->fetchAll();

    $tables = $db->prepare('SELECT id, name FROM dining_tables WHERE vendor_id = ? AND outlet_id = ? ORDER BY sort_order');
    $tables->execute([$vendorId, $outletId]);
    $tables = $tables->fetchAll();

    $customers = [['Puan Rohana', '013-220 4411'], ['Encik Faiz', '017-881 2093'], ['Cik Liyana', '011-2345 7788'], ['Encik Wong', '012-660 1530']];
    $taxRate = 0.06;
    $receiptSeq = 0;

    for ($daysAgo = 7; $daysAgo >= 1; $daysAgo--) {
        $day = date('Y-m-d', strtotime("-{$daysAgo} days"));
        $float = 150.00;
        $cashTotal = 0.00;

        $db->prepare(
            "INSERT INTO shifts (vendor_id, outlet_id, terminal_id, user_id, business_day, opened_at, opening_float, status)
             VALUES (?, ?, ?, ?, ?, ?, ?, 'open')"
        )->execute([$vendorId, $outletId, $terminal['id'], $cashier['id'], $day, "{$day} 08:00:00", $float]);
        $shiftId = (int) $db->lastInsertId();

        $count = mt_rand(6, 12);
        $minute = 9 * 60;
        $takeawayNo = 0;

        for ($n = 1; $n <= $count; $n++) {
            $minute += mt_rand(20, 70);
            $time = sprintf('%s %02d:%02d:%02d', $day, intdiv($minute, 60) % 24, $minute % 60, mt_rand(0, 59));

            // Jenis pesanan ikut jenis perniagaan
            $orderType = 'counter';
            $tableId = null;
            $tableLabel = null;
            $takeaway = null;
            $source = 'staff';
            $customer = [null, null];
            if ($vendorCode === 'KEDAI02') {
                $roll = mt_rand(1, 10);
                if ($roll <= 6 && $tables) {
                    $orderType = 'dine_in';
                    $t = $tables[array_rand($tables)];
                    [$tableId, $tableLabel] = [$t['id'], $t['name']];
                } elseif ($roll <= 9) {
                    $orderType = 'takeaway';
                    $takeaway = ++$takeawayNo;
                }
            } elseif ($vendorCode === 'KEDAI03') {
                $orderType = 'pickup';
                $source = 'online';
                $customer = $customers[array_rand($customers)];
            }

            // 1 hingga 4 baris, tanpa produk berulang
            $picked = (array) array_rand($products, mt_rand(1, min(4, count($products))));
            $lines = [];
            foreach ($picked as $idx) {
                $p = $products[$idx];
                [$delta, $options] = pickOptions($db, $vendorId, (int) $p['id']);
                $unit = round((float) $p['price'] + $delta, 2);
                $qty = mt_rand(1, 3) === 1 ? 2 : 1;
                $lines[] = $p + [
                    'unit' => $unit, 'qty' => $qty, 'line_total' => round($unit * $qty, 2),
                    'options' => $options, 'label' => implode(', ', array_column($options, 'label')) ?: null,
                ];
            }

            $subtotal = round(array_sum(array_column($lines, 'line_total')), 2);
            $taxable = array_sum(array_map(fn ($l) => $l['is_tax_exempt'] ? 0 : $l['line_total'], $lines));
            $tax = round($taxable * $taxRate, 2);
            $total = round($subtotal + $tax, 2);

            $methodRoll = mt_rand(1, 10);
            $method = $methodRoll <= 6 ? 'cash' : ($methodRoll <= 8 ? 'card' : 'qr');
            $cashReceived = null;
            $change = null;
            if ($method === 'cash') {
                foreach ([5, 10, 20, 50, 100] as $note) {
                    if ($note >= $total) {
                        $cashReceived = (float) $note;
                        break;
                    }
                }
                $cashReceived ??= ceil($total);
                $change = round($cashReceived - $total, 2);
            }

            // Satu void setiap kedai: resit ke-3, dua hari lepas
            $isVoid = $daysAgo === 2 && $n === 3;

            $db->prepare(
                "INSERT INTO orders (vendor_id, outlet_id, order_no, business_day, order_type, table_id, takeaway_no,
                    status, source, payment_choice, customer_name, customer_phone, pickup_at,
                    opened_by, terminal_id, opened_at, closed_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            )->execute([
                $vendorId, $outletId, sprintf('%04d', $n), $day, $orderType, $tableId, $takeaway,
                $isVoid ? 'cancelled' : 'paid', $source, $source === 'online' ? 'counter' : null,
                $customer[0], $customer[1], $orderType === 'pickup' ? $time : null,
                $source === 'staff' ? $cashier['id'] : null, $terminal['id'], $time, $time,
            ]);
            $orderId = (int) $db->lastInsertId();

            $receiptNo = sprintf('%s-%04d', $terminal['receipt_prefix'], ++$receiptSeq);
            $db->prepare(
                "INSERT INTO transactions (vendor_id, outlet_id, receipt_no, business_day, type, terminal_id, shift_id, user_id,
                    order_type, table_label, takeaway_no, subtotal, tax_rate, tax, discount_tax_mode, total,
                    payment_method_id, cash_received, change_amount, status, void_reason, voided_at, voided_by, created_at)
                 VALUES (?, ?, ?, ?, 'sale', ?, ?, ?, ?, ?, ?, ?, ?, ?, 'after_tax', ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            )->execute([
                $vendorId, $outletId, $receiptNo, $day, $terminal['id'], $shiftId, $cashier['id'],
                $orderType, $tableLabel, $takeaway, $subtotal, $taxRate, $tax, $total,
                $methodIds[$method], $cashReceived, $change,
                $isVoid ? 'void' : 'paid',
                $isVoid ? 'Salah tekan item' : null,
                $isVoid ? date('Y-m-d H:i:s', strtotime($time) + 300) : null,
                $isVoid ? $cashier['id'] : null,
                $time,
            ]);
            $transactionId = (int) $db->lastInsertId();

            $db->prepare('INSERT INTO transaction_orders (vendor_id, transaction_id, order_id) VALUES (?, ?, ?)')
               ->execute([$vendorId, $transactionId, $orderId]);

            foreach ($lines as $l) {
                $db->prepare(
                    "INSERT INTO order_items (vendor_id, order_id, product_id, product_name, icon, base_price, unit_price,
                        variant_label, qty, paid_qty, line_total, status, added_by, added_at)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                )->execute([
                    $vendorId, $orderId, $l['id'], $l['name'], $l['icon'], $l['price'], $l['unit'],
                    $l['label'], $l['qty'], $isVoid ? 0 : $l['qty'], $l['line_total'],
                    $isVoid ? 'cancelled' : 'served', $source === 'staff' ? $cashier['id'] : null, $time,
                ]);
                $orderItemId = (int) $db->lastInsertId();

                $db->prepare(
                    'INSERT INTO transaction_items (vendor_id, transaction_id, order_item_id, product_id, product_name, icon,
                        base_price, unit_price, qty, line_total, variant_label)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
                )->execute([
                    $vendorId, $transactionId, $orderItemId, $l['id'], $l['name'], $l['icon'],
                    $l['price'], $l['unit'], $l['qty'], $l['line_total'], $l['label'],
                ]);
                $transactionItemId = (int) $db->lastInsertId();

                foreach ($l['options'] as $o) {
                    $db->prepare('INSERT INTO order_item_options (vendor_id, order_item_id, group_name, option_label, price_delta) VALUES (?, ?, ?, ?, ?)')
                       ->execute([$vendorId, $orderItemId, $o['group'], $o['label'], $o['delta']]);
                    $db->prepare('INSERT INTO transaction_item_options (vendor_id, item_id, group_name, option_label, price_delta) VALUES (?, ?, ?, ?, ?)')
                       ->execute([$vendorId, $transactionItemId, $o['group'], $o['label'], $o['delta']]);
                }
            }

            if ($method === 'cash' && !$isVoid) {
                $cashTotal += $total;
            }
        }

        // Tutup syif. Tiga hari lepas, laci kurang RM 2.00: contoh beza tunai.
        $expected = round($float + $cashTotal, 2);
        $short = $daysAgo === 3 ? 2.00 : 0.00;
        $db->prepare(
            "UPDATE shifts SET status = 'closed', closed_at = ?, expected_cash = ?, closing_cash = ?, variance = ?, note = ?
             WHERE id = ? AND vendor_id = ?"
        )->execute([
            "{$day} 22:00:00", $expected, $expected - $short, -$short,
            $short ? 'Baki tersalah beri kepada pelanggan' : null, $shiftId, $vendorId,
        ]);
    }
}

// Satu pilihan untuk setiap kumpulan wajib. Pulangkan [jumlah delta, pilihan].
function pickOptions(PDO $db, int $vendorId, int $productId): array
{
    $groups = $db->prepare(
        'SELECT g.id, g.name FROM variation_groups g
         WHERE g.vendor_id = ? AND g.product_id = ? AND g.is_required = 1 ORDER BY g.sort_order'
    );
    $groups->execute([$vendorId, $productId]);

    $delta = 0.0;
    $picked = [];
    foreach ($groups->fetchAll() as $g) {
        $opts = $db->prepare('SELECT label, price_delta FROM variation_options WHERE vendor_id = ? AND group_id = ? AND is_active = 1 ORDER BY sort_order');
        $opts->execute([$vendorId, $g['id']]);
        $opts = $opts->fetchAll();
        if (!$opts) {
            continue;
        }
        $o = $opts[mt_rand(0, count($opts) - 1)];
        $delta += (float) $o['price_delta'];
        $picked[] = ['group' => $g['name'], 'label' => $o['label'], 'delta' => $o['price_delta']];
    }
    return [$delta, $picked];
}
