<?php
session_start();
require_once __DIR__ . '/../config.php';

if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(24));
}

if (isset($_GET['logout'])) {
    session_destroy();
    header('Location: index.php');
    exit;
}

$loginError = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login_password'])) {
    $pw = $_POST['login_password'];
    if ($pw === ADMIN_SETUP_PASSWORD || password_verify($pw, ADMIN_PASSWORD_HASH)) {
        $_SESSION['zikr_admin_logged_in'] = true;
        header('Location: index.php');
        exit;
    }
    $loginError = 'পাসওয়ার্ড সঠিক নয়।';
}

$loggedIn = !empty($_SESSION['zikr_admin_logged_in']);
$message = '';

if ($loggedIn && $_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    if (!hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'] ?? '')) {
        die('Invalid CSRF token');
    }
    $pdo = get_pdo();

    if ($_POST['action'] === 'add_zikr') {
        $arabic = trim($_POST['arabic'] ?? '');
        $bangla = trim($_POST['bangla'] ?? '');
        $meaning = trim($_POST['meaning'] ?? '');
        $virtue = trim($_POST['virtue'] ?? '');
        $repeat = trim($_POST['repeat_count'] ?? '');
        $repeatVal = $repeat !== '' ? (int)$repeat : null;
        $audioName = '';

        if (!empty($_FILES['audio']['name']) && $_FILES['audio']['error'] === UPLOAD_ERR_OK) {
            $ext = strtolower(pathinfo($_FILES['audio']['name'], PATHINFO_EXTENSION));
            if (in_array($ext, ['mp3', 'wav', 'm4a', 'aac'], true)) {
                $uploadDir = __DIR__ . '/../uploads/audio';
                if (!is_dir($uploadDir)) {
                    mkdir($uploadDir, 0755, true);
                }
                $audioName = 'zikr_' . time() . '_' . bin2hex(random_bytes(3)) . '.' . $ext;
                move_uploaded_file($_FILES['audio']['tmp_name'], $uploadDir . '/' . $audioName);
            }
        }

        if ($arabic !== '' && $bangla !== '' && $meaning !== '') {
            $id = 'remote_' . time() . '_' . bin2hex(random_bytes(2));
            $stmt = $pdo->prepare(
                'INSERT INTO zikr_items (id, arabic, bangla_pronunciation, bangla_meaning, virtue, audio_file, repeat_count)
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([$id, $arabic, $bangla, $meaning, $virtue, $audioName, $repeatVal]);
            $message = 'নতুন জিকির যুক্ত হয়েছে!';
        }
    } elseif ($_POST['action'] === 'delete_zikr') {
        $id = $_POST['id'] ?? '';
        $stmt = $pdo->prepare('DELETE FROM zikr_items WHERE id = ?');
        $stmt->execute([$id]);
        $message = 'জিকির মুছে ফেলা হয়েছে।';
    } elseif ($_POST['action'] === 'add_inspiration') {
        $arabic = trim($_POST['arabic'] ?? '');
        $bangla = trim($_POST['bangla'] ?? '');
        $ref = trim($_POST['reference'] ?? '');
        if ($arabic !== '' && $bangla !== '' && $ref !== '') {
            $stmt = $pdo->prepare('INSERT INTO inspirations (arabic, bangla, reference) VALUES (?, ?, ?)');
            $stmt->execute([$arabic, $bangla, $ref]);
            $message = 'নতুন বাণী যুক্ত হয়েছে!';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Zikr Companion — Admin Panel</title>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; background: #f7f5ef; color: #1b2a22; margin: 0; padding: 24px; }
    .container { max-width: 920px; margin: 0 auto; }
    .card { background: #fff; border-radius: 16px; padding: 22px; margin-bottom: 20px; box-shadow: 0 4px 16px rgba(15,81,50,0.08); }
    h1, h2 { color: #0F5132; margin-top: 0; }
    input, textarea, select { width: 100%; padding: 10px 12px; margin: 6px 0 14px; border: 1px solid #cbd5ce; border-radius: 10px; box-sizing: border-box; font-size: 14px; }
    button { background: #0F5132; color: #fff; border: none; padding: 11px 18px; border-radius: 10px; cursor: pointer; font-weight: 600; }
    button.danger { background: #b91c1c; padding: 6px 12px; font-size: 12px; }
    .msg { background: #d1e7dd; color: #0f5132; padding: 10px 14px; border-radius: 10px; margin-bottom: 16px; }
    .err { background: #f8d7da; color: #842029; padding: 10px 14px; border-radius: 10px; margin-bottom: 16px; }
    table { width: 100%; border-collapse: collapse; }
    th, td { text-align: left; padding: 10px; border-bottom: 1px solid #eee; font-size: 14px; }
  </style>
</head>
<body>
<div class="container">
  <?php if (!$loggedIn): ?>
    <div class="card" style="max-width:420px;margin:60px auto;">
      <h2>Zikr Admin Login</h2>
      <?php if ($loginError): ?><div class="err"><?= htmlspecialchars($loginError) ?></div><?php endif; ?>
      <form method="post">
        <label>অ্যাডমিন পাসওয়ার্ড</label>
        <input type="password" name="login_password" required>
        <button type="submit">লগইন করুন</button>
      </form>
    </div>
  <?php else:
    $pdo = get_pdo();
    $zikrs = $pdo->query('SELECT * FROM zikr_items ORDER BY created_at DESC')->fetchAll();
  ?>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h1>জিকির (Zikr) অ্যাডমিন প্যানেল</h1>
      <a href="?logout=1" style="color:#b91c1c;font-weight:600;text-decoration:none;">লগআউট</a>
    </div>
    <?php if ($message): ?><div class="msg"><?= htmlspecialchars($message) ?></div><?php endif; ?>

    <div class="card">
      <h2>নতুন জিকির ও অডিও যুক্ত করুন</h2>
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token']) ?>">
        <input type="hidden" name="action" value="add_zikr">
        <label>আরবি লেখা *</label>
        <input type="text" name="arabic" dir="rtl" required placeholder="সুবহানাল্লাহ...">
        <label>বাংলা উচ্চারণ / শিরোনাম *</label>
        <input type="text" name="bangla" required placeholder="সুবহানাল্লাহ">
        <label>বাংলা অর্থ *</label>
        <input type="text" name="meaning" required placeholder="আল্লাহ অতি পবিত্র">
        <label>ফজিলত (ঐচ্ছিক)</label>
        <input type="text" name="virtue">
        <label>কতবার বলবে (খালি রাখলে অ্যাপের ডিফল্ট)</label>
        <input type="number" name="repeat_count" min="1" max="100" placeholder="যেমন: 1 বা 3">
        <label>MP3 / WAV / M4A অডিও ফাইল</label>
        <input type="file" name="audio" accept=".mp3,.wav,.m4a,.aac">
        <button type="submit">জিকির যুক্ত করুন</button>
      </form>
    </div>

    <div class="card">
      <h2>নতুন দৈনিক বাণী (কুরআন / হাদিস) যুক্ত করুন</h2>
      <form method="post">
        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token']) ?>">
        <input type="hidden" name="action" value="add_inspiration">
        <label>আরবি *</label>
        <input type="text" name="arabic" dir="rtl" required>
        <label>বাংলা অনুবাদ *</label>
        <textarea name="bangla" rows="2" required></textarea>
        <label>রেফারেন্স *</label>
        <input type="text" name="reference" required placeholder="যেমন: সহীহ বুখারী">
        <button type="submit">বাণী যুক্ত করুন</button>
      </form>
    </div>

    <div class="card">
      <h2>সকল রিমোট জিকির (<?= count($zikrs) ?>)</h2>
      <table>
        <thead><tr><th>জিকির</th><th>অডিও</th><th>রিপিট</th><th>অ্যাকশন</th></tr></thead>
        <tbody>
          <?php foreach ($zikrs as $z): ?>
            <tr>
              <td><strong><?= htmlspecialchars($z['bangla_pronunciation']) ?></strong><br><small><?= htmlspecialchars($z['arabic']) ?></small></td>
              <td><?= $z['audio_file'] ? htmlspecialchars($z['audio_file']) : 'নেই' ?></td>
              <td><?= $z['repeat_count'] ?? 'ডিফল্ট' ?></td>
              <td>
                <form method="post" style="margin:0;">
                  <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token']) ?>">
                  <input type="hidden" name="action" value="delete_zikr">
                  <input type="hidden" name="id" value="<?= htmlspecialchars($z['id']) ?>">
                  <button type="submit" class="danger">মুছুন</button>
                </form>
              </td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  <?php endif; ?>
</div>
</body>
</html>
