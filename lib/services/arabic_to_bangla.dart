class ArabicToBangla {
  static const Map<String, String> _consonants = {
    'ب': 'ব',
    'ت': 'ত',
    'ث': 'ছ',
    'ج': 'জ',
    'ح': 'হ',
    'خ': 'খ',
    'د': 'দ',
    'ذ': 'য',
    'ر': 'র',
    'ز': 'য',
    'س': 'স',
    'ش': 'শ',
    'ص': 'স',
    'ض': 'দ',
    'ط': 'ত',
    'ظ': 'য',
    'ع': 'আ',
    'غ': 'গ',
    'ف': 'ফ',
    'ق': 'ক',
    'ك': 'ক',
    'ل': 'ল',
    'م': 'ম',
    'ن': 'ন',
    'ه': 'হ',
    'و': 'ও',
    'ي': 'ই',
    'ى': 'আ',
    'ة': 'হ',
    'أ': 'আ',
    'إ': 'ই',
    'آ': 'আ',
    'ؤ': 'উ',
    'ئ': 'ই',
    'ء': 'আ',
    'ا': 'আ',
    'ٱ': 'আ',
  };

  static const Set<String> _sunLetters = {
    'ت',
    'ث',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ل',
    'ن',
  };

  static const String _fatha = '\u064E';
  static const String _kasra = '\u0650';
  static const String _damma = '\u064F';
  static const String _sukun = '\u0652';
  static const String _shadda = '\u0651';
  static const String _fathatan = '\u064B';
  static const String _kasratan = '\u064D';
  static const String _dammatan = '\u064C';
  static const String _daggerAlif = '\u0670';
  static const String _maddah = '\u0653';

  /// Converts an Arabic Quranic [text] with harakat into phonetic Bengali.
  static String transliterate(String text) {
    // Strip Uthmani pause marks and BOM.
    final cleaned = text
        .replaceAll('\uFEFF', '')
        .replaceAll(RegExp(r'[\u06D6-\u06ED\u06DE\u06E9]'), '')
        .trim();

    if (cleaned.isEmpty) return '';

    final words = cleaned.split(RegExp(r'\s+'));
    final result = <String>[];

    for (final rawWord in words) {
      if (rawWord.isEmpty) continue;
      result.add(_transliterateWord(rawWord));
    }

    return result.join(' ');
  }

  static String _transliterateWord(String word) {
    // Handle common exact phrases/words cleanly.
    final stripped = word.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    if (stripped == 'الله' || stripped == 'اللّه') {
      return 'আল্লাহ';
    }
    if (stripped == 'لله') {
      return 'লিল্লাহ';
    }

    final buf = StringBuffer();
    final runes = word.runes.toList();
    var i = 0;

    // Handle initial Alif-Lam (ال / ٱل).
    if (runes.length >= 2 &&
        (String.fromCharCode(runes[0]) == 'ا' ||
            String.fromCharCode(runes[0]) == 'ٱ') &&
        String.fromCharCode(runes[1]) == 'ل') {
      i = 2;
      // Skip sukun on lam if present.
      if (i < runes.length && String.fromCharCode(runes[i]) == _sukun) {
        i++;
      }
      if (i < runes.length &&
          _sunLetters.contains(String.fromCharCode(runes[i]))) {
        buf.write('আ');
      } else {
        buf.write('আল-');
      }
    }

    while (i < runes.length) {
      final ch = String.fromCharCode(runes[i]);
      i++;

      // Skip standalone diacritics if any.
      if (!_consonants.containsKey(ch)) continue;

      // Collect diacritics following this letter.
      var hasShadda = false;
      var vowel = '';
      while (i < runes.length) {
        final next = String.fromCharCode(runes[i]);
        if (next == _shadda) {
          hasShadda = true;
          i++;
        } else if (next == _fatha || next == _daggerAlif || next == _maddah) {
          vowel = 'a';
          i++;
        } else if (next == _kasra) {
          vowel = 'i';
          i++;
        } else if (next == _damma) {
          vowel = 'u';
          i++;
        } else if (next == _fathatan) {
          vowel = 'an';
          i++;
        } else if (next == _kasratan) {
          vowel = 'in';
          i++;
        } else if (next == _dammatan) {
          vowel = 'un';
          i++;
        } else if (next == _sukun) {
          vowel = 'sukun';
          i++;
        } else if (next.codeUnitAt(0) >= 0x064B &&
            next.codeUnitAt(0) <= 0x065F) {
          i++;
        } else {
          break;
        }
      }

      // Long vowel letters without explicit harakat.
      if (ch == 'ا' || ch == 'ٱ') {
        if (vowel.isEmpty || vowel == 'sukun') {
          buf.write('া');
        } else if (vowel == 'i') {
          buf.write('ই');
        } else if (vowel == 'u') {
          buf.write('উ');
        } else {
          buf.write('আ');
        }
        continue;
      }

      if (ch == 'و' && vowel.isEmpty && buf.isNotEmpty) {
        buf.write('ূ');
        continue;
      }
      if ((ch == 'ي' || ch == 'ى') && vowel.isEmpty && buf.isNotEmpty) {
        buf.write(ch == 'ى' ? 'া' : 'ী');
        continue;
      }

      final base = _consonants[ch] ?? '';
      if (base.isEmpty) continue;

      if (hasShadda && buf.isNotEmpty) {
        buf.write(base);
      }
      buf.write(base);

      switch (vowel) {
        case 'a':
          if (base != 'আ') buf.write('া');
          break;
        case 'i':
          buf.write('ি');
          break;
        case 'u':
          buf.write('ু');
          break;
        case 'an':
          buf.write('ান');
          break;
        case 'in':
          buf.write('িন');
          break;
        case 'un':
          buf.write('ুন');
          break;
      }
    }

    return buf.toString();
  }
}
