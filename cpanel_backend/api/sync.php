<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../config.php';

try {
    $pdo = get_pdo();
    $rootUrl = base_url();

    $zikrRows = $pdo->query(
        'SELECT id, arabic, bangla_pronunciation, english_phonetic, bangla_meaning, virtue, audio_file, repeat_count
         FROM zikr_items WHERE is_active = 1 ORDER BY sort_order ASC, created_at ASC'
    )->fetchAll();

    $zikrs = array_map(function ($row) use ($rootUrl) {
        $audioUrl = '';
        if (!empty($row['audio_file'])) {
            $audioUrl = str_starts_with($row['audio_file'], 'http')
                ? $row['audio_file']
                : $rootUrl . '/uploads/audio/' . rawurlencode($row['audio_file']);
        }
        return [
            'id' => $row['id'],
            'arabic' => $row['arabic'],
            'banglaPronunciation' => $row['bangla_pronunciation'],
            'englishPhonetic' => $row['english_phonetic'] ?? '',
            'banglaMeaning' => $row['bangla_meaning'],
            'virtue' => $row['virtue'] ?? '',
            'audioUrl' => $audioUrl,
            'repeatCount' => $row['repeat_count'] !== null ? (int)$row['repeat_count'] : null,
        ];
    }, $zikrRows);

    $duas = $pdo->query(
        'SELECT category, title, arabic, bangla_pronunciation AS banglaPronunciation, bangla_meaning AS banglaMeaning, reference
         FROM duas WHERE is_active = 1 ORDER BY id ASC'
    )->fetchAll();

    $inspirations = $pdo->query(
        'SELECT arabic, bangla, reference FROM inspirations WHERE is_active = 1 ORDER BY id ASC'
    )->fetchAll();

    echo json_encode([
        'status' => 'ok',
        'version' => '1.1.0',
        'updatedAt' => gmdate('c'),
        'zikrs' => $zikrs,
        'duas' => $duas,
        'inspirations' => $inspirations,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection failed. Check config.php.',
    ], JSON_UNESCAPED_UNICODE);
}
