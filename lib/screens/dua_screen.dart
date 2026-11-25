import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DuaItem {
  final String category;
  final String title;
  final String arabic;
  final String banglaPronunciation;
  final String banglaMeaning;
  final String reference;

  const DuaItem({
    required this.category,
    required this.title,
    required this.arabic,
    required this.banglaPronunciation,
    required this.banglaMeaning,
    required this.reference,
  });

  static const List<String> categories = [
    'সকল',
    'ঘুম ও সকাল',
    'খাওয়া',
    'মসজিদ',
    'ঘর ও সফর',
    'পিতামাতা ও বিপদ',
  ];

  static const List<DuaItem> allDuas = [
    DuaItem(
      category: 'ঘুম ও সকাল',
      title: 'ঘুমানোর আগের দোয়া',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      banglaPronunciation: 'বিসমিকা আল্লাহুম্মা আমূতু ওয়া আহইয়া',
      banglaMeaning: 'হে আল্লাহ! আপনার নামেই আমি মৃত্যুবরণ করি (ঘুমাই) এবং আপনার নামেই জীবিত হই।',
      reference: 'সহীহ বুখারী',
    ),
    DuaItem(
      category: 'ঘুম ও সকাল',
      title: 'ঘুম থেকে ওঠার দোয়া',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      banglaPronunciation: 'আলহামদুলিল্লাহিল্লাযী আহইয়ানা বা’দা মা আমাতানা ওয়া ইলাইহিন নুশূর',
      banglaMeaning: 'সকল প্রশংসা আল্লাহর জন্য, যিনি আমাদের মৃত্যুর (ঘুমের) পর পুনরায় জীবন দান করেছেন এবং তাঁরই দিকে প্রত্যাবর্তন।',
      reference: 'সহীহ বুখারী',
    ),
    DuaItem(
      category: 'খাওয়া',
      title: 'খাওয়ার শুরুর দোয়া',
      arabic: 'بِسْمِ اللَّهِ وَعَلَىٰ بَرَكَةِ اللَّهِ',
      banglaPronunciation: 'বিসমিল্লাহি ওয়া আলা বারাকাতিল্লাহ',
      banglaMeaning: 'আল্লাহর নামে ও আল্লাহর বরকতে শুরু করছি।',
      reference: 'মুসতাদরাক হাকিম',
    ),
    DuaItem(
      category: 'খাওয়া',
      title: 'খাওয়া শেষের দোয়া',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
      banglaPronunciation: 'আলহামদুলিল্লাহিল্লাযী আতআমানা ওয়া সাকানা ওয়া জাআলানা মুসলিমীন',
      banglaMeaning: 'সকল প্রশংসা আল্লাহর জন্য, যিনি আমাদের খাওয়ালেন, পান করালেন এবং আমাদের মুসলিম বানালেন।',
      reference: 'সুনান আবু দাউদ ও তিরমিযী',
    ),
    DuaItem(
      category: 'মসজিদ',
      title: 'মসজিদে প্রবেশের দোয়া',
      arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      banglaPronunciation: 'আল্লাহুম্মাফতাহ লী আবওয়াবা রাহমাতিক',
      banglaMeaning: 'হে আল্লাহ! আমার জন্য আপনার রহমতের দরজাসমূহ খুলে দিন।',
      reference: 'সহীহ মুসলিম',
    ),
    DuaItem(
      category: 'মসজিদ',
      title: 'মসজিদ থেকে বের হওয়ার দোয়া',
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      banglaPronunciation: 'আল্লাহুম্মা ইন্নী আসআলুকা মিন ফাদলিক',
      banglaMeaning: 'হে আল্লাহ! আমি আপনার নিকট আপনার অনুগ্রহ প্রার্থনা করছি।',
      reference: 'সহীহ মুসলিম',
    ),
    DuaItem(
      category: 'ঘর ও সফর',
      title: 'ঘর থেকে বের হওয়ার দোয়া',
      arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      banglaPronunciation: 'বিসমিল্লাহি তাওয়াক্কালতু আলাল্লাহি ওয়া লা হাওলা ওয়া লা কুওয়াতা ইল্লা বিল্লাহ',
      banglaMeaning: 'আল্লাহর নামে বের হলাম, আল্লাহর ওপর ভরসা করলাম। আল্লাহর সাহায্য ছাড়া কোনো শক্তি ও সামর্থ্য নেই।',
      reference: 'সুনান আবু দাউদ ও তিরমিযী',
    ),
    DuaItem(
      category: 'ঘর ও সফর',
      title: 'যানবাহনে বা সফরে আরোহণের দোয়া',
      arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنْقَلِبُونَ',
      banglaPronunciation: 'সুবহানাল্লাযী সাখখারা লানা হাযা ওয়া মা কুন্না লাহু মুকরিনীন ওয়া ইন্না ইলা রাব্বিনা লামুনকালিবূন',
      banglaMeaning: 'মহান পবিত্র তিনি, যিনি আমাদের জন্য এটিকে বশীভূত করে দিয়েছেন; অথচ আমরা একে বশীভূত করতে সক্ষম ছিলাম না। আর নিশ্চয়ই আমরা আমাদের প্রতিপালকের নিকট ফিরে যাব।',
      reference: 'সূরা যুখরুফ: ১৩-১৪',
    ),
    DuaItem(
      category: 'পিতামাতা ও বিপদ',
      title: 'পিতামাতার জন্য দোয়া',
      arabic: 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      banglaPronunciation: 'রাব্বির হামহুমা কামা রাব্বাইয়ানী সাগীরা',
      banglaMeaning: 'হে আমার প্রতিপালক! তাদের উভয়ের প্রতি রহম করুন, যেমন তারা আমাকে শৈশবে লালন-পালন করেছেন।',
      reference: 'সূরা বনি ইসরাইল: ২৪',
    ),
    DuaItem(
      category: 'পিতামাতা ও বিপদ',
      title: 'দুশ্চিন্তা ও বিপদ মুক্তির দোয়া (দোয়া ইউনুস)',
      arabic: 'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      banglaPronunciation: 'লা ইলাহা ইল্লা আনতা সুবহানাকা ইন্নী কুনতু মিনায যালিমীন',
      banglaMeaning: 'আপনি ব্যতীত কোনো উপাস্য নেই, আপনি পবিত্র ও মহান। নিশ্চয়ই আমি জালিমদের অন্তর্ভুক্ত ছিলাম।',
      reference: 'সূরা আম্বিয়া: ৮৭',
    ),
  ];
}

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  String _selectedCategory = 'সকল';

  @override
  Widget build(BuildContext context) {
    final items = _selectedCategory == 'সকল'
        ? DuaItem.allDuas
        : DuaItem.allDuas
            .where((d) => d.category == _selectedCategory)
            .toList();

    return Column(
      children: [
        SizedBox(
          height: 58,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: DuaItem.categories.length,
            itemBuilder: (context, index) {
              final cat = DuaItem.categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  selectedColor: AppTheme.emeraldPrimary.withOpacity(0.18),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final dua = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              dua.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldPrimary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              dua.category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.emeraldLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        dua.arabic,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: AppTheme.arabicFontFamily,
                          fontSize: 26,
                          height: 1.9,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dua.banglaPronunciation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.emeraldLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dua.banglaMeaning,
                        style: const TextStyle(
                          fontFamily: AppTheme.banglaSerifFontFamily,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'সূত্র: ${dua.reference}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
