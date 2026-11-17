<?php
// Rentetan antara muka sistem, ms & en (PELAN.md 7.9 hingga 7.11).
// Kunci dalam Bahasa Inggeris; nilai dalam bahasa masing-masing.
// Gabungkan ayat dengan placeholder {nama}, jangan cantum serpihan.
// Fasa seterusnya menambah kunci ke fail ini apabila skrin dibina.

return function (PDO $db): void {
    $strings = [
        // Ralat umum
        'error.forbidden'          => ['Anda tiada akses ke bahagian ini.', 'You do not have access to this section.'],
        'error.not_found'          => ['Rekod tidak dijumpai.', 'Record not found.'],
        'error.validation'         => ['Sila semak medan yang ditanda.', 'Please check the highlighted fields.'],
        'error.server'             => ['Ralat pelayan. Cuba lagi sebentar.', 'Server error. Please try again shortly.'],
        'error.module_unavailable' => ['Ciri ini tiada dalam pelan langganan anda.', 'This feature is not included in your plan.'],

        // Pengesahan input (core/Validator.php)
        'validation.required' => ['Medan ini wajib diisi.', 'This field is required.'],
        'validation.string'   => ['Mesti teks.', 'Must be text.'],
        'validation.int'      => ['Mesti nombor bulat.', 'Must be a whole number.'],
        'validation.decimal'  => ['Mesti nombor, maksimum 2 tempat perpuluhan.', 'Must be a number with at most 2 decimal places.'],
        'validation.email'    => ['Alamat e-mel tidak sah.', 'Invalid email address.'],
        'validation.in'       => ['Pilihan tidak sah.', 'Invalid choice.'],
        'validation.min'      => ['Minimum {min}.', 'Minimum {min}.'],
        'validation.max'      => ['Maksimum {max}.', 'Maximum {max}.'],

        // Log masuk (PELAN.md 4)
        'auth.login'              => ['Log masuk', 'Log in'],
        'auth.logout'             => ['Log keluar', 'Log out'],
        'auth.email'              => ['E-mel', 'Email'],
        'auth.password'           => ['Kata laluan', 'Password'],
        'auth.invalid_credentials'=> ['E-mel atau kata laluan salah. Cuba lagi.', 'Incorrect email or password. Try again.'],
        'auth.account_locked'     => ['Akaun dikunci sementara. Cuba lagi selepas {minutes} minit.', 'Account temporarily locked. Try again in {minutes} minutes.'],
        'auth.who_is_on_duty'     => ['Siapa yang bertugas?', 'Who is on duty?'],
        'auth.enter_pin'          => ['Tekan nama anda, kemudian masukkan PIN.', 'Tap your name, then enter your PIN.'],
        'auth.pin_wrong'          => ['PIN salah. {left} cubaan lagi sebelum dikunci.', 'Wrong PIN. {left} attempts left before lock.'],
        'auth.pin_locked'         => ['Dikunci, minta admin buka', 'Locked, ask an admin to unlock'],
        'auth.subscription_ended' => ['Langganan kedai ini telah tamat. Hubungi KedaiPOS untuk menyambung.', 'This shop\'s subscription has ended. Contact KedaiPOS to renew.'],
        'auth.choose_outlet'      => ['Pilih kedai', 'Choose shop'],
        'device.register'         => ['Daftar peranti', 'Register device'],
        'device.not_registered'   => ['Peranti ini belum didaftarkan ke mana-mana kedai.', 'This device is not registered to any shop.'],

        // Syif
        'shift.open'           => ['Buka syif', 'Open shift'],
        'shift.close'          => ['Tutup syif', 'Close shift'],
        'shift.opening_float'  => ['Wang permulaan dalam laci', 'Opening cash in drawer'],
        'shift.expected_cash'  => ['Sepatutnya dalam laci', 'Expected in drawer'],
        'shift.counted'        => ['Dikira', 'Counted'],
        'shift.short'          => ['Kurang daripada sepatutnya', 'Short of expected'],
        'shift.over'           => ['Lebih daripada sepatutnya', 'Over expected'],
        'shift.note_required'  => ['Catatan wajib bila ada beza.', 'A note is required when there is a difference.'],

        // Jualan & troli
        'order.counter'   => ['Kaunter', 'Counter'],
        'order.dine_in'   => ['Dine-in', 'Dine-in'],
        'order.takeaway'  => ['Take away', 'Takeaway'],
        'order.pickup'    => ['Ambil sendiri', 'Pickup'],
        'cart.subtotal'   => ['Subjumlah', 'Subtotal'],
        'cart.tax'        => ['Cukai SST {rate}%', 'SST {rate}%'],
        'cart.discount'   => ['Diskaun', 'Discount'],
        'cart.promo_discount'  => ['Diskaun promosi', 'Promotion discount'],
        'cart.manual_discount' => ['Diskaun manual', 'Manual discount'],
        'cart.total'      => ['Jumlah', 'Total'],
        'cart.pay'        => ['Bayar', 'Pay'],
        'cart.clear'      => ['Kosongkan troli', 'Clear cart'],
        'cart.add'        => ['Tambah ke troli', 'Add to cart'],
        'stock.insufficient' => ['Stok {product} tidak mencukupi.', 'Insufficient stock for {product}.'],
        'stock.out'       => ['Habis', 'Sold out'],
        'stock.low'       => ['Tinggal {qty}', '{qty} left'],
        'variant.required_pick_one' => ['Wajib, pilih 1', 'Required, pick 1'],
        'variant.pick_one'          => ['Pilih 1', 'Pick 1'],
        'variant.pick_many'         => ['Pilihan, boleh lebih dari satu', 'Optional, pick any'],

        // Bayaran
        'payment.receive'       => ['Terima bayaran', 'Receive payment'],
        'payment.amount_due'    => ['Perlu dibayar', 'Amount due'],
        'payment.cash_received' => ['Wang diterima', 'Cash received'],
        'payment.change'        => ['Baki dipulangkan', 'Change'],
        'payment.confirm_print' => ['Sahkan & cetak resit', 'Confirm & print receipt'],

        // Resit (bahasa VENDOR, bukan juruwang — 7.11)
        'receipt.no'        => ['Resit', 'Receipt'],
        'receipt.date'      => ['Tarikh', 'Date'],
        'receipt.cashier'   => ['Juruwang', 'Cashier'],
        'receipt.cash'      => ['Tunai', 'Cash'],
        'receipt.change'    => ['Baki', 'Change'],
        'receipt.thank_you' => ['Terima kasih, datang lagi', 'Thank you, please come again'],
        'receipt.void'      => ['VOID', 'VOID'],
        'receipt.void_copy' => ['SALINAN, BUKAN RESIT JUALAN', 'COPY, NOT A SALES RECEIPT'],

        // Transaksi
        'transaction.history'     => ['Sejarah transaksi', 'Transaction history'],
        'transaction.reprint'     => ['Cetak semula', 'Reprint'],
        'transaction.void'        => ['Void resit', 'Void receipt'],
        'transaction.void_reason' => ['Sebab', 'Reason'],

        // Modul (PELAN.md 9.4)
        'module.pos.name'                   => ['Jualan kaunter', 'Point of sale'],
        'module.pos.description'            => ['Jualan kaunter, katalog asas, resit, syif dan dashboard.', 'Counter sales, basic catalogue, receipts, shifts and dashboard.'],
        'module.promotions.name'            => ['Promosi', 'Promotions'],
        'module.promotions.description'     => ['Promosi dan diskaun automatik.', 'Automatic promotions and discounts.'],
        'module.stock.name'                 => ['Pengurusan stok', 'Stock management'],
        'module.stock.description'          => ['Terima stok, pelarasan, log pergerakan dan amaran stok rendah.', 'Stock receiving, adjustments, movement log and low-stock alerts.'],
        'module.reports.name'               => ['Laporan lanjutan', 'Advanced reports'],
        'module.reports.description'        => ['Laporan lanjutan, Z-report dan eksport CSV.', 'Advanced reports, Z-report and CSV export.'],
        'module.csv_import.name'            => ['Import CSV', 'CSV import'],
        'module.csv_import.description'     => ['Import produk secara pukal dari fail CSV.', 'Bulk import products from a CSV file.'],
        'module.waiter_app.name'            => ['Aplikasi waiter', 'Waiter app'],
        'module.waiter_app.description'     => ['Waiter ambil pesanan di meja dari telefon.', 'Waiters take orders at the table from a phone.'],
        'module.qr_order.name'              => ['Pesanan QR', 'QR ordering'],
        'module.qr_order.description'       => ['Pelanggan imbas QR di meja dan pesan sendiri.', 'Customers scan the table QR and order themselves.'],
        'module.kitchen.name'               => ['Dapur', 'Kitchen'],
        'module.kitchen.description'        => ['Skrin pesanan dapur dan slip cetak automatik.', 'Kitchen order screen and automatic slip printing.'],
        'module.online_payment.name'        => ['Bayaran online', 'Online payment'],
        'module.online_payment.description' => ['Pelanggan bayar online terus ke akaun gerbang kedai.', 'Customers pay online straight to the shop\'s gateway account.'],
        'module.online_order.name'          => ['Kedai online, ambil sendiri', 'Online shop, pickup'],
        'module.online_order.description'   => ['Pautan kedai untuk pelanggan tempah dan ambil sendiri.', 'A shop link for customers to order and pick up.'],
    ];

    $stmt = $db->prepare(
        'INSERT INTO translations (language_code, translation_key, value) VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE value = VALUES(value)'
    );
    foreach ($strings as $key => [$ms, $en]) {
        $stmt->execute(['ms', $key, $ms]);
        $stmt->execute(['en', $key, $en]);
    }
};
