<?php
// Vendor semasa untuk permintaan ini: sempadan keselamatan (PELAN.md 3.1, 3.8).
//
// Ditetapkan SEKALI oleh Auth (dari sesi), atau oleh halaman awam selepas
// pelayan mencari token meja / slug kedai dalam pangkalan data (3.9).
// Tidak pernah ditetapkan daripada input pelayar.

class VendorScope
{
    private static ?int $vendorId = null;

    public static function set(int $vendorId): void
    {
        if ($vendorId <= 0) {
            throw new InvalidArgumentException('vendor_id tidak sah.');
        }
        // Menukar vendor di tengah permintaan hampir pasti pepijat kebocoran.
        if (self::$vendorId !== null && self::$vendorId !== $vendorId) {
            throw new LogicException('Vendor sudah ditetapkan untuk permintaan ini.');
        }
        self::$vendorId = $vendorId;
    }

    public static function id(): int
    {
        if (self::$vendorId === null) {
            throw new LogicException('Vendor belum ditetapkan. Panggil VendorScope::set() selepas pengesahan.');
        }
        return self::$vendorId;
    }

    public static function has(): bool
    {
        return self::$vendorId !== null;
    }

    // Untuk log keluar dan ujian CLI sahaja.
    public static function clear(): void
    {
        self::$vendorId = null;
    }
}
