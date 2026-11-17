<?php
// Hari perniagaan, bukan tarikh kalendar (PELAN.md 7.3).
// Kedai tutup 2 pagi: jualan pukul 1 pagi masih milik semalam. Garis
// pemisahnya `settings.day_cutoff_time` (lalai 04:00), per vendor / kedai.

class BusinessDay
{
    // Fungsi tulen, boleh diuji tanpa pangkalan data.
    public static function compute(DateTimeInterface $now, string $cutoff = '04:00'): string
    {
        if (!preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', $cutoff)) {
            $cutoff = '04:00';
        }
        $date = DateTimeImmutable::createFromInterface($now);
        if ($date->format('H:i') < $cutoff) {
            $date = $date->modify('-1 day');
        }
        return $date->format('Y-m-d');
    }

    // Hari perniagaan semasa untuk satu kedai. Tetapan kedai menindih lalai vendor.
    public static function current(int $vendorId, ?int $outletId = null, ?DateTimeInterface $now = null): string
    {
        $stmt = Database::connection()->prepare(
            'SELECT setting_value FROM settings
             WHERE vendor_id = ? AND setting_key = ? AND (outlet_id = ? OR outlet_id IS NULL)
             ORDER BY outlet_id IS NULL
             LIMIT 1'
        );
        $stmt->execute([$vendorId, 'day_cutoff_time', $outletId]);
        $cutoff = $stmt->fetchColumn() ?: '04:00';

        return self::compute($now ?? new DateTimeImmutable(), $cutoff);
    }
}
