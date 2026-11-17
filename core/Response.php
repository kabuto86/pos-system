<?php
// Semua api/ pulangkan JSON dengan bentuk yang sama:
//   berjaya: { "ok": true,  "data": ... }
//   gagal:   { "ok": false, "error": "mesej", "fields": { medan: mesej } }

class Response
{
    public static function ok(mixed $data = null, int $status = 200): never
    {
        self::send(['ok' => true, 'data' => $data], $status);
    }

    public static function error(string $message, int $status = 400, array $fields = []): never
    {
        $payload = ['ok' => false, 'error' => $message];
        if ($fields) {
            $payload['fields'] = $fields;
        }
        self::send($payload, $status);
    }

    public static function forbidden(): never
    {
        self::error(t('error.forbidden'), 403);
    }

    private static function send(array $payload, int $status): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-store');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}
