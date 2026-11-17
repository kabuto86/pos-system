<?php
// Hash kata laluan & PIN dengan Argon2id (PELAN.md 4.4).
// Parameter OWASP ditetapkan eksplisit: lalai PHP (64MB, t=4) terlalu perlahan.
// PIN di-hash dengan cara yang sama. Ia kata laluan, cuma pendek.

class Password
{
    private const OPTIONS = [
        'memory_cost' => 19456,   // 19 MiB
        'time_cost'   => 2,
        'threads'     => 1,
    ];

    public static function hash(string $plain): string
    {
        return password_hash($plain, PASSWORD_ARGON2ID, self::OPTIONS);
    }

    public static function verify(string $plain, ?string $hash): bool
    {
        return $hash !== null && $hash !== '' && password_verify($plain, $hash);
    }

    // Dipanggil selepas setiap log masuk berjaya (4.5).
    public static function needsRehash(string $hash): bool
    {
        return password_needs_rehash($hash, PASSWORD_ARGON2ID, self::OPTIONS);
    }
}
