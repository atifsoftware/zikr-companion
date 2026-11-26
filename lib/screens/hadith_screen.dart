import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/hadith_service.dart';
import '../theme/app_theme.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final HadithService _service = HadithService();
  final TextEditingController _searchCtrl = TextEditingController();
  FlutterTts? _tts;

  HadithBookInfo? _selectedBook; // Level 1 -> Level 2
  HadithBookData? _bookData;
  bool _isLoading = false;
  String? _error;

  HadithSection? _selectedSection; // Level 2 -> Level 3
  String _searchQuery = '';
  int? _speakingHadith;

  @override
  void dispose() {
    _searchCtrl.dispose();
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _openBook(HadithBookInfo book) async {
    setState(() {
      _selectedBook = book;
      _selectedSection = null;
      _bookData = null;
      _isLoading = true;
      _error = null;
      _searchQuery = '';
      _searchCtrl.clear();
    });

    try {
      final data = await _service.fetchBook(book.id);
      if (!mounted) return;
      setState(() {
        _bookData = data;
        _isLoading = false;
        // If book only has 1 section (e.g. Nawawi 40 Hadith), jump straight to list
        if (data.sections.length <= 1) {
          _selectedSection = data.sections.isNotEmpty
              ? data.sections.first
              : const HadithSection(
                  id: 'all', title: 'সকল হাদিস', firstHadith: 0, lastHadith: 999999);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'হাদিস লোড করা যায়নি — ইন্টারনেট সংযোগ পরীক্ষা করুন।';
      });
    }
  }

  Future<void> _toggleSpeak(HadithEntry h) async {
    if (_speakingHadith == h.hadithNumber) {
      await _tts?.stop();
      if (mounted) setState(() => _speakingHadith = null);
      return;
    }
    _tts ??= FlutterTts();
    try {
      await _tts!.stop();
      await _tts!.setLanguage('bn-BD');
    } catch (_) {}
    _tts!.setCompletionHandler(() {
      if (mounted) setState(() => _speakingHadith = null);
    });
    setState(() => _speakingHadith = h.hadithNumber);
    await _tts!.speak(h.banglaText);
  }

  void _goBack() {
    _tts?.stop();
    setState(() {
      _speakingHadith = null;
      if (_selectedSection != null && (_bookData?.sections.length ?? 0) > 1) {
        _selectedSection = null;
      } else if (_selectedBook != null) {
        _selectedBook = null;
        _bookData = null;
        _selectedSection = null;
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // LEVEL 1: Hadith Books Grid
    if (_selectedBook == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth >= 900
              ? 4
              : (constraints.maxWidth >= 600 ? 3 : 2);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.32,
            ),
            itemCount: HadithBookInfo.books.length,
            itemBuilder: (context, index) {
              final book = HadithBookInfo.books[index];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openBook(book),
                child: Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: AppTheme.emeraldPrimary.withValues(alpha: 0.16),
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
                            color:
                                AppTheme.emeraldPrimary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppTheme.emeraldPrimary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          book.titleBangla,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
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
      );
    }

    final data = _bookData;
    final q = _searchQuery.trim().toLowerCase();
    final showHadithList = _selectedSection != null || q.isNotEmpty;

    final filteredHadiths = (data?.hadiths ?? const <HadithEntry>[]).where((h) {
      if (q.isNotEmpty) {
        return h.hadithNumber.toString() == q ||
            h.banglaText.toLowerCase().contains(q) ||
            h.arabicText.contains(q);
      }
      final sec = _selectedSection;
      if (sec == null || sec.id == 'all' || sec.lastHadith == 0) return true;
      return h.hadithNumber >= sec.firstHadith &&
          h.hadithNumber <= sec.lastHadith;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'পিছনে যান',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBook!.titleBangla,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.emeraldLight,
                          ),
                    ),
                    if (_selectedSection != null)
                      Text(
                        _selectedSection!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!_isLoading && _error == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'হাদিস খুঁজুন (নম্বর বা বাংলা শব্দ)...',
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
        if (_isLoading)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('হাদিস গ্রন্থ লোড হচ্ছে...'),
                ],
              ),
            ),
          )
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _openBook(_selectedBook!),
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            ),
          )
        else if (!showHadithList && data != null)
          // LEVEL 2: Sections / Chapters List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: data.sections.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: EdgeInsets.zero,
                    color: AppTheme.emeraldPrimary.withValues(alpha: 0.08),
                    child: ListTile(
                      leading: const Icon(Icons.apps_rounded,
                          color: AppTheme.emeraldPrimary),
                      title: Text(
                        'সকল হাদিস (${data.hadiths.length} টি)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => setState(() {
                        _selectedSection = const HadithSection(
                          id: 'all',
                          title: 'সকল হাদিস',
                          firstHadith: 0,
                          lastHadith: 999999,
                        );
                      }),
                    ),
                  );
                }
                final sec = data.sections[index - 1];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor:
                          AppTheme.emeraldPrimary.withValues(alpha: 0.12),
                      child: Text(
                        sec.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emeraldPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      sec.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: sec.firstHadith > 0
                        ? Text(
                            'হাদিস ${sec.firstHadith} - ${sec.lastHadith}',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.emeraldLight),
                    onTap: () => setState(() => _selectedSection = sec),
                  ),
                );
              },
            ),
          )
        else
          // LEVEL 3: Hadiths List
          Expanded(
            child: filteredHadiths.isEmpty
                ? const Center(child: Text('কোনো হাদিস পাওয়া যায়নি।'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: filteredHadiths.length,
                    itemBuilder: (context, index) {
                      final h = filteredHadiths[index];
                      final isSpeaking = _speakingHadith == h.hadithNumber;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emeraldPrimary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'হাদিস #${h.hadithNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.emeraldPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (h.grade.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldAccent
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        h.grade,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.goldAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _toggleSpeak(h),
                                    icon: Icon(
                                      isSpeaking
                                          ? Icons.stop_circle_rounded
                                          : Icons.volume_up_rounded,
                                      color: isSpeaking
                                          ? AppTheme.goldAccent
                                          : AppTheme.emeraldPrimary,
                                    ),
                                    tooltip: isSpeaking ? 'থামান' : 'শুনুন',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final copyStr =
                                          '${h.arabicText.isNotEmpty ? '${h.arabicText}\n\n' : ''}${h.banglaText}\n(${_selectedBook!.titleBangla}, হাদিস ${h.hadithNumber})';
                                      Clipboard.setData(
                                          ClipboardData(text: copyStr));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('হাদিস কপি করা হয়েছে'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 20),
                                    tooltip: 'কপি করুন',
                                  ),
                                ],
                              ),
                              if (h.arabicText.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  h.arabicText,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.arabicFontFamily,
                                    fontSize: 22,
                                    height: 1.9,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                h.banglaText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.65,
                                ),
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
