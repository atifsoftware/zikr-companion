class ZikrItem {
  final String id;
  final String arabic;
  final String banglaPronunciation;
  final String englishPhonetic;
  final String banglaMeaning;
  final String virtue;
  final String customAudioPath;
  final bool isEnabled;
  final bool isCustom;

  const ZikrItem({
    required this.id,
    required this.arabic,
    required this.banglaPronunciation,
    this.englishPhonetic = '',
    required this.banglaMeaning,
    this.virtue = '',
    this.customAudioPath = '',
    this.isEnabled = true,
    this.isCustom = false,
  });

  ZikrItem copyWith({
    String? id,
    String? arabic,
    String? banglaPronunciation,
    String? englishPhonetic,
    String? banglaMeaning,
    String? virtue,
    String? customAudioPath,
    bool? isEnabled,
    bool? isCustom,
  }) {
    return ZikrItem(
      id: id ?? this.id,
      arabic: arabic ?? this.arabic,
      banglaPronunciation: banglaPronunciation ?? this.banglaPronunciation,
      englishPhonetic: englishPhonetic ?? this.englishPhonetic,
      banglaMeaning: banglaMeaning ?? this.banglaMeaning,
      virtue: virtue ?? this.virtue,
      customAudioPath: customAudioPath ?? this.customAudioPath,
      isEnabled: isEnabled ?? this.isEnabled,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabic': arabic,
        'banglaPronunciation': banglaPronunciation,
        'englishPhonetic': englishPhonetic,
        'banglaMeaning': banglaMeaning,
        'virtue': virtue,
        'customAudioPath': customAudioPath,
        'isEnabled': isEnabled,
        'isCustom': isCustom,
      };

  factory ZikrItem.fromJson(Map<String, dynamic> json) => ZikrItem(
        id: json['id'] as String,
        arabic: json['arabic'] as String,
        banglaPronunciation: json['banglaPronunciation'] as String,
        englishPhonetic: (json['englishPhonetic'] as String?) ?? '',
        banglaMeaning: json['banglaMeaning'] as String,
        virtue: (json['virtue'] as String?) ?? '',
        customAudioPath: (json['customAudioPath'] as String?) ?? '',
        isEnabled: (json['isEnabled'] as bool?) ?? true,
        isCustom: (json['isCustom'] as bool?) ?? false,
      );

  static const ZikrItem masudFourZikr = ZikrItem(
    id: 'masud_four_zikr',
    arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ',
    banglaPronunciation: 'সূরা আল-ফাতিহা (প্রথম তিলাওয়াত)',
    englishPhonetic: 'Surah Al Fatiha',
    banglaMeaning:
        'সকল প্রশংসা বিশ্বজগতের প্রতিপালক আল্লাহর জন্য, যিনি পরম করুণাময় ও দয়ালু।',
    virtue: 'কুরআনের সর্বশ্রেষ্ঠ সূরা ও শিফা (আরোগ্য)।',
  );

  static List<ZikrItem> defaultList() => const [
        masudFourZikr,
        ZikrItem(
          id: 'subhanallah',
          arabic: 'سُبْحَانَ اللَّهِ',
          banglaPronunciation: 'সুবহানাল্লাহ',
          englishPhonetic: 'Subhan Allah',
          banglaMeaning: 'আল্লাহ অতি পবিত্র ও মহান।',
          virtue: 'প্রতিবার পাঠে সওয়াব ও মর্যাদা বৃদ্ধি পায়।',
        ),
        ZikrItem(
          id: 'alhamdulillah',
          arabic: 'الْحَمْدُ لِلَّهِ',
          banglaPronunciation: 'আলহামদুলিল্লাহ',
          englishPhonetic: 'Alhamdulillah',
          banglaMeaning: 'সকল প্রশংসা একমাত্র আল্লাহর জন্য।',
          virtue: 'আলহামদুলিল্লাহ আমলের পাল্লা পূর্ণ করে দেয়।',
        ),
        ZikrItem(
          id: 'allahuakbar',
          arabic: 'اللَّهُ أَكْبَرُ',
          banglaPronunciation: 'আল্লাহু আকবার',
          englishPhonetic: 'Allahu Akbar',
          banglaMeaning: 'আল্লাহ সর্বশ্রেষ্ঠ।',
          virtue: 'আসমান ও জমিনের মধ্যবর্তী স্থান পূর্ণ করে দেয়।',
        ),
        ZikrItem(
          id: 'lailahaillallah',
          arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
          banglaPronunciation: 'লা ইলাহা ইল্লাল্লাহ',
          englishPhonetic: 'La ilaha illallah',
          banglaMeaning: 'আল্লাহ ব্যতীত কোনো উপাস্য নেই।',
          virtue: 'সর্বোত্তম জিকির হলো লা ইলাহা ইল্লাল্লাহ।',
        ),
        ZikrItem(
          id: 'astaghfirullah',
          arabic: 'أَسْتَغْفِرُ اللَّهَ',
          banglaPronunciation: 'আস্তাগফিরুল্লাহ',
          englishPhonetic: 'Astaghfirullah',
          banglaMeaning: 'আমি আল্লাহর কাছে ক্ষমা প্রার্থনা করছি।',
          virtue: 'গুনাহ মাফ ও রিজিকে বরকত আনে।',
        ),
        ZikrItem(
          id: 'subhanallahi_wabihamdihi',
          arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
          banglaPronunciation: 'সুবহানাল্লাহি ওয়া বিহামদিহি',
          englishPhonetic: 'Subhan Allahi wa bihamdihi',
          banglaMeaning: 'আমি আল্লাহর প্রশংসাসহ তাঁর পবিত্রতা ঘোষণা করছি।',
          virtue: 'দিনে ১০০ বার পড়লে সমুদ্রের ফেনা সমান গুনাহও মাফ হয়।',
        ),
        ZikrItem(
          id: 'lahawla',
          arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
          banglaPronunciation: 'লা হাওলা ওয়া লা কুওয়াতা ইল্লা বিল্লাহ',
          englishPhonetic: 'La hawla wa la quwwata illa billah',
          banglaMeaning: 'আল্লাহর সাহায্য ছাড়া কোনো শক্তি ও সামর্থ্য নেই।',
          virtue: 'এটি জান্নাতের ভান্ডারসমূহের একটি।',
        ),
        ZikrItem(
          id: 'durood',
          arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
          banglaPronunciation: 'আল্লাহুম্মা সাল্লি আলা মুহাম্মাদ',
          englishPhonetic: 'Allahumma salli ala Muhammad',
          banglaMeaning: 'হে আল্লাহ, মুহাম্মাদ (সা.)-এর ওপর রহমত বর্ষণ করুন।',
          virtue: 'একবার দরুদ পড়লে আল্লাহ ১০টি রহমত নাযিল করেন।',
        ),
      ];
}
