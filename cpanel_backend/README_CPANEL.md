# cPanel-এ Zikr Companion ওয়েবসাইট ও API সেটআপ করার নিয়ম

১. **MySQL ডেটাবেস তৈরি:**
   - cPanel → **MySQL® Databases**-এ গিয়ে একটি ডেটাবেস ও ইউজার তৈরি করুন এবং ইউজারকে **All Privileges** দিন।
   - **phpMyAdmin**-এ গিয়ে `database.sql` ফাইলটি ইমপোর্ট করুন।

২. **ফাইল আপলোড:**
   - `cpanel_backend/` ফোল্ডারের সব ফাইল আপনার cPanel-এর `public_html/` (অথবা সাবডোমেইন ফোল্ডারে) আপলোড করুন।
   - `config.php` ফাইলটি খুলে আপনার `DB_NAME`, `DB_USER`, `DB_PASS` এবং `ADMIN_SETUP_PASSWORD` পরিবর্তন করুন।

৩. **ব্যবহার:**
   - ওয়েবসাইট: `https://yourdomain.com/`
   - অ্যাডমিন প্যানেল: `https://yourdomain.com/admin/` (এখান থেকে নতুন জিকির, অডিও MP3 এবং বাণী যোগ করতে পারবেন)।
   - API লিংক: `https://yourdomain.com/api/sync.php`

৪. **অ্যাপের সাথে কানেক্ট করা:**
   - Zikr Companion মোবাইল বা ডেস্কটপ অ্যাপের **সেটিংস → ওয়েবসাইট ও ক্লাউড সিঙ্ক** অপশনে গিয়ে আপনার ডোমেইন (`https://yourdomain.com`) লিখে **"এখনই সিঙ্ক করুন"** বাটনে ক্লিক করলেই সব জিকির ও অডিও অফলাইনে ডাউনলোড হয়ে যাবে!
