<?php
// Pengesahan input ringkas. Peraturan dipisah dengan '|':
//   required, string, int, decimal, email, min:N, max:N, in:a,b,c
// `min`/`max` = panjang untuk teks, nilai untuk nombor (selepas int/decimal).
//
//   $errors = Validator::check($data, ['email' => 'required|email|max:190']);
//   if ($errors) Response::error(t('error.validation'), 422, $errors);

class Validator
{
    public static function check(array $data, array $rules): array
    {
        $errors = [];
        foreach ($rules as $field => $ruleString) {
            $value = $data[$field] ?? null;
            $isEmpty = $value === null || (is_string($value) && trim($value) === '');
            $isNumeric = false;

            foreach (explode('|', $ruleString) as $rule) {
                [$name, $arg] = array_pad(explode(':', $rule, 2), 2, null);

                if ($name === 'required') {
                    if ($isEmpty) {
                        $errors[$field] = t('validation.required');
                        break;
                    }
                    continue;
                }
                if ($isEmpty) {
                    continue; // medan pilihan yang kosong tidak disemak lagi
                }

                $message = match ($name) {
                    'string'  => is_string($value) ? null : t('validation.string'),
                    'int'     => filter_var($value, FILTER_VALIDATE_INT) !== false ? null : t('validation.int'),
                    'decimal' => preg_match('/^-?\d+(\.\d{1,2})?$/', (string) $value) ? null : t('validation.decimal'),
                    'email'   => filter_var($value, FILTER_VALIDATE_EMAIL) ? null : t('validation.email'),
                    'in'      => in_array((string) $value, explode(',', (string) $arg), true) ? null : t('validation.in'),
                    'min'     => self::size($value, $isNumeric) >= (float) $arg ? null : t('validation.min', ['min' => $arg]),
                    'max'     => self::size($value, $isNumeric) <= (float) $arg ? null : t('validation.max', ['max' => $arg]),
                    default   => throw new InvalidArgumentException("Peraturan tidak dikenali: {$name}"),
                };
                if ($name === 'int' || $name === 'decimal') {
                    $isNumeric = true;
                }
                if ($message !== null) {
                    $errors[$field] = $message;
                    break;
                }
            }
        }
        return $errors;
    }

    private static function size(mixed $value, bool $isNumeric): float
    {
        return $isNumeric ? (float) $value : (float) mb_strlen((string) $value);
    }
}
