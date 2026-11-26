import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../services/zikr_scheduler_service.dart';
import '../theme/app_theme.dart';
import '../utils/web_audio_player.dart';

class DuaItem {
  final String category;
  final String title;
  final String arabic;
  final String banglaPronunciation;
  final String banglaMeaning;
  final String reference;
  final String audioUrl;

  const DuaItem({
    required this.category,
    required this.title,
    required this.arabic,
    required this.banglaPronunciation,
    required this.banglaMeaning,
    required this.reference,
    this.audioUrl = '',
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
      banglaMeaning:
          'হে আল্লাহ! আপনার নামেই আমি মৃত্যুবরণ করি (ঘুমাই) এবং আপনার নামেই জীবিত হই।',
      reference: 'সহীহ বুখারী',
    ),
    DuaItem(
      category: 'ঘুম ও সকাল',
      title: 'ঘুম থেকে ওঠার দোয়া',
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      banglaPronunciation:
          'আলহামদুলিল্লাহিল্লাযী আহইয়ানা বা’দা মা আমাতানা ওয়া ইলাইহিন নুশূর',
      banglaMeaning:
          'সকল প্রশংসা আল্লাহর জন্য, যিনি আমাদের মৃত্যুর (ঘুমের) পর পুনরায় জীবন দান করেছেন এবং তাঁরই দিকে প্রত্যাবর্তন।',
      reference: 'সহীহ বুখারী',
    ),
    DuaItem(
      category: 'খাওয়া',
      title: 'খাওয়ার শুরুর দোয়া',
      arabic: 'بِسْمِ اللَّهِ وَعَلَىٰ بَرَكَةِ اللَّهِ',
      banglaPronunciation: 'বিসমিল্লাহি ওয়া আলা বারাকাতিল্লাহ',
      banglaMeaning: 'আল্লাহর নামে এবং আল্লাহর বরকতের ওপর শুরু করছি।',
      reference: 'সহীহ বুখারী ও আবু দাউদ',
    ),
    DuaItem(
      category: 'খাওয়া',
      title: 'খাওয়া শেষের দোয়া',
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
      banglaPronunciation:
          'আলহামদুলিল্লাহিল্লাযী আতআমানা ওয়া সাকানা ওয়া জাআলানা মুসলিমীন',
      banglaMeaning:
          'সকল প্রশংসা সেই আল্লাহর জন্য, যিনি আমাদের আহার করিয়েছেন, পান করিয়েছেন এবং আমাদের মুসলিম বানিয়েছেন।',
      reference: 'আবু দাউদ ও তিরমিযী',
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
      arabic:
          'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      banglaPronunciation:
          'বিসমিল্লাহি তাওয়াক্কালতু আলাল্লাহি লা হাওলা ওয়া লা কুওয়্যাতা ইল্লা বিল্লাহ',
      banglaMeaning:
          'আল্লাহর নামে (বের হচ্ছি), আল্লাহর ওপর ভরসা করলাম। আল্লাহর সাহায্য ছাড়া কোনো শক্তি ও সামর্থ্য নেই।',
      reference: 'আবু দাউদ ও তিরমিযী',
    ),
    DuaItem(
      category: 'ঘর ও সফর',
      title: 'যানবাহনে আরোহণের দোয়া',
      arabic:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنْقَلِبُونَ',
      banglaPronunciation:
          'সুবহানাল্লাযী সাখখারা লানা হাযা ওয়া মা কুন্না লাহু মুকরিনীন, ওয়া ইন্না ইলা রাব্বিনা লামুনকালিবূন',
      banglaMeaning:
          'পবিত্র সেই সত্তা যিনি এটিকে আমাদের বশীভূত করে দিয়েছেন, নতুবা আমরা একে বশ করতে পারতাম না। আর আমরা অবশ্যই আমাদের প্রতিপালকের নিকট ফিরে যাব।',
      reference: 'সূরা যুখরুফ: ১৩-১৪',
    ),
    DuaItem(
      category: 'পিতামাতা ও বিপদ',
      title: 'পিতামাতার জন্য দোয়া',
      arabic: 'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      banglaPronunciation: 'রাব্বির হামহুমা কামা রাব্বাইয়ানী সাগীরা',
      banglaMeaning:
          'হে আমার প্রতিপালক! তাদের উভয়ের প্রতি দয়া করুন, যেমন তারা শৈশবে আমাকে লালন-পালন করেছেন।',
      reference: 'সূরা বনী ইসরাঈল: ২৪',
    ),
    DuaItem(
      category: 'পিতামাতা ও বিপদ',
      title: 'দুশ্চিন্তা ও বিপদ মুক্তির দোয়া (দোয়া ইউনুস)',
      arabic: 'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      banglaPronunciation:
          'লা ইলাহা ইল্লা আনতা সুবহানাকা ইন্নী কুনতু মিনায যালিমীন',
      banglaMeaning:
          'আপনি ব্যতীত কোনো উপাস্য নেই, আপনি পবিত্র ও মহান। নিশ্চয়ই আমি জালিমদের অন্তর্ভুক্ত ছিলাম।',
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
  final TextEditingController _searchCtrl = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final WebAudioPlayer _webPlayer = WebAudioPlayer();
  FlutterTts? _tts;

  String? _selectedCategory; // Level 1 -> Level 2 (Titles)
  int? _selectedDuaIndex; // Level 2 -> Level 3 (Full Dua)
  String _searchQuery = '';
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _webPlayer.onComplete = () {
      if (mounted) setState(() => _isPlaying = false);
    };
    _webPlayer.onError = (_) {
      if (mounted) setState(() => _isPlaying = false);
    };
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _audioPlayer.dispose();
    _webPlayer.dispose();
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _stopAudio() async {
    try {
      if (kIsWeb) {
        await _webPlayer.stop();
      } else {
        await _audioPlayer.stop();
      }
      await _tts?.stop();
    } catch (_) {}
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _togglePlayDua(DuaItem dua) async {
    if (_isPlaying) {
      await _stopAudio();
      return;
    }
    await _stopAudio();
    if (!mounted) return;
    setState(() => _isPlaying = true);

    try {
      if (dua.audioUrl.isNotEmpty) {
        if (kIsWeb) {
          await _webPlayer.playUrl(dua.audioUrl);
        } else {
          await _audioPlayer.play(UrlSource(dua.audioUrl));
        }
        return;
      }

      _tts ??= FlutterTts();
      try {
        await _tts!.setLanguage('ar-SA');
      } catch (_) {}
      _tts!.setCompletionHandler(() {
        if (mounted) setState(() => _isPlaying = false);
      });
      await _tts!.speak(dua.arabic);
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  IconData _iconForCategory(String cat) {
    if (cat.contains('ঘুম') || cat.contains('সকাল')) {
      return Icons.wb_twilight_rounded;
    }
    if (cat.contains('খাওয়া') || cat.contains('পানাহার')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('মসজিদ') ||
        cat.contains('নামাজ') ||
        cat.contains('সালাত')) {
      return Icons.mosque_rounded;
    }
    if (cat.contains('সফর') || cat.contains('ঘর')) return Icons.explore_rounded;
    if (cat.contains('বিপদ') || cat.contains('রোগ') || cat.contains('অসুস্থ')) {
      return Icons.healing_rounded;
    }
    if (cat.contains('পিতামাতা') || cat.contains('পরিবার')) {
      return Icons.family_restroom_rounded;
    }
    if (cat.contains('হজ্জ') || cat.contains('উমরাহ')) {
      return Icons.public_rounded;
    }
    if (cat.contains('জিকির') || cat.contains('তাসবিহ')) {
      return Icons.spa_rounded;
    }
    return Icons.menu_book_rounded;
  }

  void _goBack() {
    _stopAudio();
    setState(() {
      if (_selectedDuaIndex != null) {
        _selectedDuaIndex = null;
      } else if (_selectedCategory != null) {
        _selectedCategory = null;
      } else if (_searchQuery.isNotEmpty) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allDuas = context.watch<ZikrSchedulerService>().duas;
    final q = _searchQuery.trim().toLowerCase();

    final catCounts = <String, int>{};
    for (final d in allDuas) {
      final c = d.category.trim().isEmpty ? 'মাসনুন দোয়া' : d.category.trim();
      catCounts[c] = (catCounts[c] ?? 0) + 1;
    }
    final categories = catCounts.keys.toList();

    final filteredItems = allDuas.where((d) {
      if (_selectedCategory != null &&
          _selectedCategory != 'সকল' &&
          d.category != _selectedCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      return d.title.toLowerCase().contains(q) ||
          d.banglaMeaning.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q) ||
          d.arabic.contains(q);
    }).toList();

    final isLevel1 =
        q.isEmpty && _selectedCategory == null && _selectedDuaIndex == null;
    final isLevel2 = !isLevel1 && _selectedDuaIndex == null;

    // Clamp selected index safely
    final activeDuaIdx = (_selectedDuaIndex != null &&
            _selectedDuaIndex! >= 0 &&
            _selectedDuaIndex! < filteredItems.length)
        ? _selectedDuaIndex!
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              if (!isLevel1)
                IconButton(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'পিছনে যান',
                ),
              if (activeDuaIdx != null)
                Expanded(
                  child: Text(
                    filteredItems[activeDuaIdx].category,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emeraldPrimary,
                        ),
                  ),
                )
              else
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _selectedDuaIndex = null;
                    }),
                    decoration: InputDecoration(
                      hintText: 'দোয়া খুঁজুন (শিরোনাম, অর্থ বা ক্যাটাগরি)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // LEVEL 1: Category Grid
        if (isLevel1)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 900
                    ? 4
                    : (constraints.maxWidth >= 600 ? 3 : 2);
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                  ),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final cat = isAll ? 'সকল' : categories[index - 1];
                    final count = isAll ? allDuas.length : (catCounts[cat] ?? 0);
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() {
                        _selectedCategory = cat;
                        _selectedDuaIndex = null;
                      }),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color:
                                AppTheme.emeraldPrimary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldPrimary
                                      .withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAll
                                      ? Icons.apps_rounded
                                      : _iconForCategory(cat),
                                  color: AppTheme.emeraldPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cat,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count টি দোয়া',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.emeraldLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )

        // LEVEL 2: Dua Titles List for Selected Category / Search
        else if (isLevel2)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      '$_selectedCategory (${filteredItems.length} টি দোয়া)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.emeraldPrimary,
                          ),
                    ),
                  ),
                Expanded(
                  child: filteredItems.isEmpty
                      ? const Center(child: Text('কোনো দোয়া পাওয়া যায়নি।'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final dua = filteredItems[index];
                            return Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.emeraldPrimary
                                      .withValues(alpha: 0.12),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.emeraldPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  dua.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                  ),
                                ),
                                subtitle: dua.reference.isNotEmpty
                                    ? Text(
                                        dua.reference,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.emeraldLight,
                                ),
                                onTap: () =>
                                    setState(() => _selectedDuaIndex = index),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          )

        // LEVEL 3: Full Dua Detail View
        else if (activeDuaIdx != null)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              child: Builder(
                builder: (_) {
                  final dua = filteredItems[activeDuaIdx];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dua.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => _togglePlayDua(dua),
                                    icon: Icon(_isPlaying
                                        ? Icons.stop_rounded
                                        : Icons.volume_up_rounded),
                                    label: Text(_isPlaying ? 'থামান' : 'শুনুন'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _isPlaying
                                          ? AppTheme.goldAccent
                                          : AppTheme.emeraldPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                dua.arabic,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: AppTheme.arabicFontFamily,
                                  fontSize: 28,
                                  height: 2.0,
                                ),
                              ),
                              if (dua.banglaPronunciation.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'উচ্চারণ: ${dua.banglaPronunciation}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.emeraldLight,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                dua.banglaMeaning,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  height: 1.65,
                                ),
                              ),
                              if (dua.reference.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'সূত্র: ${dua.reference}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: activeDuaIdx > 0
                                ? () {
                                    _stopAudio();
                                    setState(() =>
                                        _selectedDuaIndex = activeDuaIdx - 1);
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded),
                            label: const Text('পূর্ববর্তী দোয়া'),
                          ),
                          Text(
                            '${activeDuaIdx + 1} / ${filteredItems.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: activeDuaIdx + 1 < filteredItems.length
                                ? () {
                                    _stopAudio();
                                    setState(() =>
                                        _selectedDuaIndex = activeDuaIdx + 1);
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                            label: const Text('পরবর্তী দোয়া'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
