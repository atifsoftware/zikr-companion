# জিকির (Zikr Companion)

A cross-platform Islamic **Zikr Reminder, Digital Tasbih, Masnun Duas, Prayer-Time Auto-Pause, and Quran Recitation** app built with **Flutter** for **Windows Desktop** and **Android**.

---

## প্রধান ফিচারসমূহ (Key Features)

- **স্বয়ংক্রিয় জিকির রিমাইন্ডার:** নির্ধারিত মিনিট পরপর (ডিফল্ট ১৫ মিনিট) আরবি, বাংলা উচ্চারণ, অর্থ ও ফজিলতসহ জিকির মনে করিয়ে দেয়; অডিও শেষে পপ-আপ অটো-বন্ধ হয়।
- **অফলাইন আরবি অডিও ও কাস্টম জিকির:** সূরা আল-ফাতিহা, সুবহানাল্লাহ, আলহামদুলিল্লাহ, আল্লাহু আকবার, লা ইলাহা ইল্লাল্লাহসহ জিকিরের অডিও এবং নিজের নতুন জিকিরে MP3/WAV/M4A অডিও যুক্ত করার সুবিধা।
- **নামাজের সময় অটো-পজ ও আজান সতর্কতা:** অফলাইনেই শহরের সময় (অথবা কাস্টম সেট করা সময়) অনুযায়ী ৫ ওয়াক্ত নামাজের সময় হিসাব করে, ওয়াক্ত শুরু হলে নোটিফিকেশন দেয় এবং নির্ধারিত সময় জিকির অটো-পজ রাখে।
- **কুরআন তিলাওয়াত ও বাংলা অনুবাদ:** ৬ জন প্রখ্যাত ক্বারী (মিশারি আল-আফাসি, আব্দুল বাসিত, আল-মিনশাবি, আল-হুসারি, আল-শাতরি, আল-আজমি)-এর কণ্ঠে পূর্ণ ১১৪টি সূরা, আয়াত-বাই-আয়াত লাইভ হাইলাইট, উচ্চারণ, বাংলা অনুবাদ ও তাফসির এবং **অফলাইন ডাউনলোড**।
- **মাসনূন দোয়া ও ডিজিটাল তসবিহ:** ক্যাটাগরি-ভিত্তিক দৈনন্দিন দোয়া এবং হ্যাপটিক ভাইব্রেশনসহ তসবিহ কাউন্টার।
- **ডেস্কটপ ও মোবাইল সাপোর্ট:** Windows-এ সিস্টেম ট্রে, অটো-স্টার্টআপ, `Ctrl+Alt+Z` শর্টকাট, ডার্ক/লাইট মোড এবং JSON ব্যাকআপ ও রিস্টোর।

---

## টেক স্ট্যাক (Tech Stack)

- **Framework:** Flutter (Dart)
- **Platforms:** Windows (Desktop), Android (Mobile)
- **Fonts:** `Amiri` (Arabic), `Hind Siliguri` & `Tiro Bangla` (Bengali)
- **APIs / Libraries:** `adhan`, `audioplayers`, `flutter_local_notifications`, `tray_manager`, `window_manager`, `launch_at_startup`, `file_picker`, `api.alquran.cloud`

---

## বিল্ড করার নিয়ম (Build from Source)

```powershell
flutter pub get
flutter test

# Windows Release
flutter build windows --release

# Android APK
flutter build apk --release
```
