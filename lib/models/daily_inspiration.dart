class DailyInspiration {
  final String arabic;
  final String bangla;
  final String reference;

  const DailyInspiration({
    required this.arabic,
    required this.bangla,
    required this.reference,
  });

  static DailyInspiration forDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return items[dayOfYear % items.length];
  }

  static const List<DailyInspiration> items = [
    DailyInspiration(
      arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      bangla: 'জেনে রেখো, আল্লাহর জিকিরেই অন্তরসমূহ প্রশান্তি লাভ করে।',
      reference: 'সূরা আর-রাদ: ২৮',
    ),
    DailyInspiration(
      arabic: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
      bangla: 'অতএব তোমরা আমাকে স্মরণ করো, আমিও তোমাদের স্মরণ করব।',
      reference: 'সূরা আল-বাকারা: ১৫২',
    ),
    DailyInspiration(
      arabic: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
      bangla: 'তোমাদের মধ্যে সর্বোত্তম সেই ব্যক্তি, যে কুরআন শেখে এবং অন্যকে শেখায়।',
      reference: 'সহীহ বুখারী',
    ),
    DailyInspiration(
      arabic: 'كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ ثَقِيلَتَانِ فِي الْمِيزَانِ حَبِيبَتَانِ إِلَى الرَّحْمَٰنِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      bangla: 'দুটি বাক্য জিহ্বায় উচ্চারণে খুবই সহজ, মীযানের পাল্লায় অত্যন্ত ভারী এবং পরম করুণাময় আল্লাহর নিকট অতি প্রিয়: সুবহানাল্লাহি ওয়া বিহামদিহি, সুবহানাল্লাহিল আযীম।',
      reference: 'সহীহ বুখারী ও মুসলিম',
    ),
    DailyInspiration(
      arabic: 'مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ',
      bangla: 'যে ব্যক্তি ঈমানের সাথে ও সওয়াবের আশায় রমজানের রোজা রাখে, তার পূর্বের সমস্ত গুনাহ ক্ষমা করে দেওয়া হয়।',
      reference: 'সহীহ বুখারী ও মুসলিম',
    ),
    DailyInspiration(
      arabic: 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ',
      bangla: 'তোমরা যদি কৃতজ্ঞতা প্রকাশ করো, তবে আমি অবশ্যই তোমাদের (নেয়ামত) বাড়িয়ে দেবো।',
      reference: 'সূরা ইবরাহিম: ৭',
    ),
    DailyInspiration(
      arabic: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      bangla: 'নিশ্চয়ই কষ্টের সাথেই স্বস্তি রয়েছে।',
      reference: 'সূরা আল-ইনশিরাহ: ৬',
    ),
    DailyInspiration(
      arabic: 'الدُّعَاءُ هُوَ الْعِبَادَةُ',
      bangla: 'দোয়াই হলো ইবাদতের মূল।',
      reference: 'সুনান আবু দাউদ ও তিরমিযী',
    ),
    DailyInspiration(
      arabic: 'لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
      bangla: 'তোমরা আল্লাহর রহমত থেকে নিরাশ হয়ো না।',
      reference: 'সূরা আয-যুমার: ৫৩',
    ),
    DailyInspiration(
      arabic: 'أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ',
      bangla: 'আল্লাহর নিকট সবচেয়ে প্রিয় আমল হলো তা-ই, যা নিয়মিত করা হয়—যদিও তা পরিমাণে কম হয়।',
      reference: 'সহীহ বুখারী ও মুসলিম',
    ),
  ];
}
