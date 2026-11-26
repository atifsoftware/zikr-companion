import 'dart:convert';
import '../utils/hadith_section_bn.dart';
import '../utils/http_fetch.dart';

class HadithBookInfo {
  final String id; // e.g., 'bukhari' -> ben-bukhari.min.json
  final String titleBangla;
  final String subtitle;

  const HadithBookInfo({
    required this.id,
    required this.titleBangla,
    required this.subtitle,
  });

  static const List<HadithBookInfo> books = [
    HadithBookInfo(
      id: 'bukhari',
      titleBangla: 'সহীহ আল-বুখারী',
      subtitle: 'ইমাম মুহাম্মাদ ইবনে ইসমাঈল আল-বুখারী (রহ.)',
    ),
    HadithBookInfo(
      id: 'muslim',
      titleBangla: 'সহীহ মুসলিম',
      subtitle: 'ইমাম মুসলিম ইবনুল হাজ্জাজ (রহ.)',
    ),
    HadithBookInfo(
      id: 'abudawud',
      titleBangla: 'সুনান আবু দাউদ',
      subtitle: 'ইমাম আবু দাউদ সুলাইমান (রহ.)',
    ),
    HadithBookInfo(
      id: 'tirmidhi',
      titleBangla: 'জামে আত-তিরমিযী',
      subtitle: 'ইমাম মুহাম্মাদ ইবনে ঈসা আত-তিরমিযী (রহ.)',
    ),
    HadithBookInfo(
      id: 'nasai',
      titleBangla: 'সুনান আন-নাসাঈ',
      subtitle: 'ইমাম আহমাদ ইবনে শুআইব আন-নাসাঈ (রহ.)',
    ),
    HadithBookInfo(
      id: 'ibnmajah',
      titleBangla: 'সুনান ইবনে মাজাহ',
      subtitle: 'ইমাম মুহাম্মাদ ইবনে ইয়াযীদ ইবনে মাজাহ (রহ.)',
    ),
    HadithBookInfo(
      id: 'malik',
      titleBangla: 'মুয়াত্তা ইমাম মালিক',
      subtitle: 'ইমাম মালিক ইবনে আনাস (রহ.)',
    ),
    HadithBookInfo(
      id: 'nawawi',
      titleBangla: 'চল্লিশ হাদিস (ইমাম নববী)',
      subtitle: 'ইমাম মুহিউদ্দীন আন-নববী (রহ.)',
    ),
  ];
}

class HadithSection {
  final String id;
  final String title;
  final int firstHadith;
  final int lastHadith;

  const HadithSection({
    required this.id,
    required this.title,
    required this.firstHadith,
    required this.lastHadith,
  });
}

class HadithEntry {
  final int hadithNumber;
  final String banglaText;
  final String arabicText;
  final String grade;

  const HadithEntry({
    required this.hadithNumber,
    required this.banglaText,
    this.arabicText = '',
    this.grade = '',
  });
}

class HadithBookData {
  final List<HadithSection> sections;
  final List<HadithEntry> hadiths;

  const HadithBookData({
    required this.sections,
    required this.hadiths,
  });
}

class HadithService {
  static final Map<String, HadithBookData> _cache = {};

  Future<HadithBookData> fetchBook(String bookId) async {
    if (_cache.containsKey(bookId)) {
      return _cache[bookId]!;
    }

    final bnUrl =
        'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ben-$bookId.min.json';
    final bnRaw = await fetchTextUrl(bnUrl, timeout: const Duration(seconds: 25));
    final bnDecoded = jsonDecode(bnRaw) as Map<String, dynamic>;

    // Optionally fetch Arabic for nawawi / smaller books or in parallel best-effort
    final araMap = <int, String>{};
    try {
      final araUrl =
          'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-$bookId.min.json';
      final araRaw =
          await fetchTextUrl(araUrl, timeout: const Duration(seconds: 15));
      final araDecoded = jsonDecode(araRaw) as Map<String, dynamic>;
      final araList = (araDecoded['hadiths'] as List<dynamic>?) ?? const [];
      for (final h in araList.whereType<Map<String, dynamic>>()) {
        final numVal = (h['hadithnumber'] as num?)?.toInt();
        final txt = (h['text'] as String?)?.trim() ?? '';
        if (numVal != null && txt.isNotEmpty) {
          araMap[numVal] = txt;
        }
      }
    } catch (_) {}

    final metadata = (bnDecoded['metadata'] as Map<String, dynamic>?) ?? {};
    final sectionsRaw =
        (metadata['sections'] as Map<String, dynamic>?) ?? const {};
    final detailsRaw =
        (metadata['section_details'] as Map<String, dynamic>?) ?? const {};

    final sections = <HadithSection>[];
    sectionsRaw.forEach((secId, secTitle) {
      final title = (secTitle as String?)?.trim() ?? '';
      if (title.isEmpty) return;
      final d = detailsRaw[secId];
      final first = (d is Map ? (d['hadithnumber_first'] as num?)?.toInt() : null) ?? 0;
      final last = (d is Map ? (d['hadithnumber_last'] as num?)?.toInt() : null) ?? 0;
      sections.add(HadithSection(
        id: secId,
        title: translateHadithSectionTitle(title),
        firstHadith: first,
        lastHadith: last,
      ));
    });

    final hadithsRaw = (bnDecoded['hadiths'] as List<dynamic>?) ?? const [];
    final hadiths = <HadithEntry>[];
    for (final h in hadithsRaw.whereType<Map<String, dynamic>>()) {
      final numVal = (h['hadithnumber'] as num?)?.toInt() ?? 0;
      final text = (h['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) continue;
      final grades = (h['grades'] as List<dynamic>?) ?? const [];
      String grade = '';
      if (grades.isNotEmpty && grades.first is Map) {
        grade = ((grades.first as Map)['grade'] as String?)?.trim() ?? '';
      }
      hadiths.add(HadithEntry(
        hadithNumber: numVal,
        banglaText: text,
        arabicText: araMap[numVal] ?? '',
        grade: grade,
      ));
    }

    final result = HadithBookData(sections: sections, hadiths: hadiths);
    _cache[bookId] = result;
    return result;
  }
}
