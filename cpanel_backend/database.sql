-- Zikr Companion MySQL Schema
-- Import this file into phpMyAdmin in your cPanel

CREATE TABLE IF NOT EXISTS zikr_items (
  id VARCHAR(64) PRIMARY KEY,
  arabic TEXT NOT NULL,
  bangla_pronunciation VARCHAR(255) NOT NULL,
  english_phonetic VARCHAR(255) DEFAULT '',
  bangla_meaning TEXT NOT NULL,
  virtue TEXT DEFAULT '',
  audio_file VARCHAR(255) DEFAULT '',
  repeat_count INT DEFAULT NULL,
  is_active TINYINT(1) DEFAULT 1,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS duas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  category VARCHAR(100) NOT NULL,
  title VARCHAR(255) NOT NULL,
  arabic TEXT NOT NULL,
  bangla_pronunciation TEXT NOT NULL,
  bangla_meaning TEXT NOT NULL,
  reference VARCHAR(255) DEFAULT '',
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inspirations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  arabic TEXT NOT NULL,
  bangla TEXT NOT NULL,
  reference VARCHAR(255) NOT NULL,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sample seed row
INSERT IGNORE INTO inspirations (id, arabic, bangla, reference) VALUES
(1, 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'জেনে রেখো, আল্লাহর জিকিরেই অন্তরসমূহ প্রশান্তি লাভ করে।', 'সূরা আর-রাদ: ২৮');
