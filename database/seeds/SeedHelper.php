<?php
// Pembantu untuk seed .php. Bukan seed: pelari hanya membaca seeds/core/ dan
// seeds/demo/, jadi fail ini tidak dijalankan sendiri.
//
// Semua seed mesti idempotent (PELAN.md 15.2): jalan dua kali, hasil sama.

class SeedHelper
{
    // Cari baris melalui $match (kunci semula jadi). Ada -> kemas kini $data.
    // Tiada -> cipta. Pulangkan id.
    public static function upsert(PDO $db, string $table, array $match, array $data = []): int
    {
        $where = implode(' AND ', array_map(fn ($c) => "`{$c}` <=> ?", array_keys($match)));
        $find = $db->prepare("SELECT id FROM `{$table}` WHERE {$where} LIMIT 1");
        $find->execute(array_values($match));
        $id = $find->fetchColumn();

        if ($id !== false) {
            if ($data) {
                $set = implode(', ', array_map(fn ($c) => "`{$c}` = ?", array_keys($data)));
                $db->prepare("UPDATE `{$table}` SET {$set} WHERE id = ?")
                   ->execute([...array_values($data), $id]);
            }
            return (int) $id;
        }

        $row = $match + $data;
        $cols = implode(', ', array_map(fn ($c) => "`{$c}`", array_keys($row)));
        $marks = implode(', ', array_fill(0, count($row), '?'));
        $db->prepare("INSERT INTO `{$table}` ({$cols}) VALUES ({$marks})")->execute(array_values($row));
        return (int) $db->lastInsertId();
    }

    public static function vendorId(PDO $db, string $code): int
    {
        $stmt = $db->prepare('SELECT id FROM vendors WHERE code = ?');
        $stmt->execute([$code]);
        $id = $stmt->fetchColumn();
        if ($id === false) {
            throw new RuntimeException("Vendor {$code} belum wujud. Jalankan seed vendor dahulu.");
        }
        return (int) $id;
    }

    public static function outletId(PDO $db, int $vendorId, string $code): int
    {
        $stmt = $db->prepare('SELECT id FROM outlets WHERE vendor_id = ? AND code = ?');
        $stmt->execute([$vendorId, $code]);
        $id = $stmt->fetchColumn();
        if ($id === false) {
            throw new RuntimeException("Kedai {$code} belum wujud.");
        }
        return (int) $id;
    }

    // Barcode EAN-13 sah daripada 12 digit (digit semak dikira).
    public static function ean13(string $twelve): string
    {
        $sum = 0;
        foreach (str_split($twelve) as $i => $digit) {
            $sum += (int) $digit * ($i % 2 === 0 ? 1 : 3);
        }
        return $twelve . ((10 - $sum % 10) % 10);
    }
}
