String translateHadithSectionTitle(String english) {
  final raw = english.trim();
  if (raw.isEmpty) return raw;

  final normalized = raw
      .toLowerCase()
      .replaceFirst(RegExp(r'^the book of\s+'), '')
      .replaceFirst(RegExp(r'^book of\s+'), '')
      .replaceFirst(RegExp(r'^chapters on\s+'), '')
      .replaceFirst(RegExp(r'^chapter on\s+'), '')
      .trim();

  const exactMap = <String, String>{
    'revelation': 'ওহীর সূচনা',
    'belief': 'ঈমান',
    'faith': 'ঈমান',
    'knowledge': 'ইলম (জ্ঞান)',
    "ablutions (wudu')": 'অযু',
    'purification (kitab al-taharah)': 'পবিত্রতা (তাহারাত)',
    'purification': 'পবিত্রতা (তাহারাত)',
    'bathing (ghusl)': 'গোসল',
    'menstrual periods': 'হায়েয (ঋতুস্রাব)',
    'menstruation': 'হায়েয (ঋতুস্রাব)',
    'rubbing hands and feet with dust (tayammum)': 'তায়াম্মুম',
    'prayers (salat)': 'সালাত (নামাজ)',
    'prayer (kitab al-salat)': 'সালাত (নামাজ)',
    'prayer': 'সালাত (নামাজ)',
    'times of the prayers': 'নামাজের ওয়াক্তসমূহ',
    'call to prayers (adhaan)': 'আযান ও ইকামত',
    'friday prayer': 'জুমার নামাজ',
    'fear prayer': 'ভয়ের সময় নামাজ (সালাতুল খাওফ)',
    'the two festivals (eids)': 'দুই ঈদের নামাজ',
    'witr prayer': 'বিতর নামাজ',
    'invoking allah for rain (istisqaa)': 'বৃষ্টির জন্য দোয়া (ইস্তিসকা)',
    'eclipses': 'সূর্য ও চন্দ্রগ্রহণের নামাজ',
    "prostration during recital of qur'an": 'তিলাওয়াতের সিজদাহ',
    'shortening the prayers (at-taqseer)': 'সফরে নামাজ কসর করা',
    'prayer at night (tahajjud)': 'তাহাজ্জুদ (রাতের নামাজ)',
    'virtues of prayer at masjid makkah and madinah':
        'মক্কা ও মদিনার মসজিদে নামাজের ফজিলত',
    'actions while praying': 'নামাজের ভেতরের আমল',
    'forgetfulness in prayer': 'নামাজে ভুল (সাহু সিজদা)',
    "funerals (al-janaa'iz)": 'জানাযা',
    'obligatory charity tax (zakat)': 'যাকাত',
    'zakat': 'যাকাত',
    'hajj (pilgrimage)': 'হজ্জ',
    'pilgrimage': 'হজ্জ',
    "`umrah (minor pilgrimage)": 'উমরাহ',
    'pilgrims prevented from completing the pilgrimage':
        'হজ্জ ও উমরাহে বাধাপ্রাপ্ত হওয়া',
    'penalty of hunting while on pilgrimage': 'ইহরাম অবস্থায় শিকারের কাফফারা',
    'virtues of madinah': 'মদিনার ফজিলত',
    'fasting': 'সাওম (রোজা)',
    'praying at night in ramadaan (taraweeh)': 'তারাবীহ নামাজ',
    'virtues of the night of qadr': 'লাইলাতুল কদরের ফজিলত',
    "retiring to a mosque for remembrance of allah (i'tikaf)": 'ইতিকাফ',
    'sales and trade': 'ক্রয়-বিক্রয় ও ব্যবসা',
    'sales in which a price is paid for goods to be delivered later (as-salam)':
        'সালাম (অগ্রিম মূল্যে ক্রয়-বিক্রয়)',
    "shuf'a": 'শুফআ (অগ্রাধিকার)',
    'hiring': 'ইজারা (ভাড়া ও মজুরি)',
    'transferance of a debt from one person to another (al-hawaala)':
        'হাওয়ালা (ঋণ স্থানান্তর)',
    'kafalah': 'কাফালাহ (জামিনদার হওয়া)',
    'representation, authorization, business by proxy': 'উকালাহ (প্রতিনিধিত্ব)',
    'agriculture': 'কৃষিকাজ ও বর্গাচাষ',
    'distribution of water': 'পানি বণ্টন ও সেচ',
    'loans, payment of loans, freezing of property, bankruptcy':
        'ঋণ, পরিশোধ ও দেউলিয়াত্ব',
    'khusoomaat': 'বিবাদ ও মীমাংসা',
    'lost things picked up by someone (luqatah)': 'কুড়িয়ে পাওয়া বস্তু (লুকাতা)',
    'oppressions': 'জুলুম ও অন্যায়',
    'partnership': 'অংশীদারিত্ব (শিরকাত)',
    'mortgaging': 'বন্ধক (রাহান)',
    'manumission of slaves': 'দাসমুক্তি',
    'makaatib': 'মুকাতাব (চুক্তিবদ্ধ দাস)',
    'gifts': 'হাদিয়া ও উপহার',
    'witnesses': 'সাক্ষ্যদান',
    'peacemaking': 'সন্ধি ও মীমাংসা',
    'conditions': 'শর্তাবলী',
    'wills and testaments (wasaayaa)': 'অসিয়ত',
    'fighting for the cause of allah (jihaad)': 'জিহাদ',
    'one-fifth of booty to the cause of allah (khumus)': 'খুমুস (গনিমতের এক-পঞ্চমাংশ)',
    "jizyah and mawaada'ah": 'জিযিয়া ও সন্ধিচুক্তি',
    'beginning of creation': 'সৃষ্টির সূচনা',
    'prophets': 'নবী-রাসূলগণ (আ.)',
    'virtues and merits of the prophet (pbuh) and his companions':
        'নবী (সা.) ও সাহাবীগণের ফজিলত',
    'companions of the prophet': 'সাহাবীগণের মর্যাদা',
    'merits of the helpers in madinah (ansaar)': 'আনসারগণের ফজিলত',
    'military expeditions led by the prophet (pbuh) (al-maghaazi)':
        'মাগাযী (নবীজির যুদ্ধাভিযান)',
    'prophetic commentary on the qur\'an (tafseer of the prophet (pbuh))':
        'তাফসীর (কুরআনের ব্যাখ্যা)',
    'virtues of the qur\'an': 'কুরআনের ফজিলত',
    'wedlock, marriage (nikaah)': 'বিবাহ (নিকাহ)',
    'marriage': 'বিবাহ (নিকাহ)',
    'divorce': 'তালাক',
    'supporting the family': 'পরিবারের ভরণপোষণ',
    'food, meals': 'খাদ্য ও আহার',
    'sacrifice on occasion of birth (`aqiqah)': 'আকীকা',
    'hunting, slaughtering': 'শিকার ও জবেহ',
    'al-adha festival sacrifice (adaahi)': 'কুরবানি',
    'drinks': 'পানীয়সমূহ',
    'patients': 'রোগী ও চিকিৎসা',
    'medicine': 'চিকিৎসা',
    'dress': 'পোশাক-পরিচ্ছদ',
    'good manners and form (al-adab)': 'আদব ও শিষ্টাচার',
    'asking permission': 'অনুমতি গ্রহণ',
    'invocations': 'দোয়া ও মুনাজাত',
    'to make the heart tender (ar-riqaq)': 'অন্তর নরমকারী বিষয় (রিকাক)',
    'divine will (al-qadar)': 'তাকদীর (ভাগ্য)',
    'oaths and vows': 'শপথ ও মানত',
    'expiation for unfulfilled oaths': 'ভঙ্গকৃত শপথের কাফফারা',
    'laws of inheritance (al-faraa\'id)': 'ফারায়েয (উত্তরাধিকার আইন)',
    'limits and punishments set by allah (hudood)': 'হুদুদ (ইসলামী দণ্ডবিধি)',
    'blood money (ad-diyat)': 'দিয়াত (রক্তপণ)',
    'apostates': 'মুরতাদ (ধর্মত্যাগী)',
    '(statements made under) coercion': 'জবরদস্তিমূলক অবস্থা',
    'tricks': 'কৌশল ও বাহানা',
    'interpretation of dreams': 'স্বপ্নের ব্যাখ্যা',
    'afflictions and the end of the world': 'ফিতনা ও কেয়ামতের আলামত',
    'judgments (ahkaam)': 'বিচার ও শাসনব্যবস্থা (আহকাম)',
    'wishes': 'আশা-আকাঙ্ক্ষা',
    'accepting information given by a truthful person': 'খবরে ওয়াহিদ গ্রহণ',
    'holding fast to the qur\'an and sunnah': 'কুরআন ও সুন্নাহ আঁকড়ে ধরা',
    'oneness, uniqueness of allah (tawheed)': 'তাওহীদ (আল্লাহর একত্ববাদ)',
    'forty hadith of an-nawawi': 'ইমাম নববীর ৪০ হাদিস',
  };

  if (exactMap.containsKey(normalized)) {
    return exactMap[normalized]!;
  }

  const keywordPairs = <MapEntry<String, String>>[
    MapEntry('revelation', 'ওহীর সূচনা'),
    MapEntry('belief', 'ঈমান'),
    MapEntry('faith', 'ঈমান'),
    MapEntry('knowledge', 'ইলম (জ্ঞান)'),
    MapEntry('purification', 'পবিত্রতা'),
    MapEntry('wudu', 'অযু'),
    MapEntry('ghusl', 'গোসল'),
    MapEntry('tayammum', 'তায়াম্মুম'),
    MapEntry('menstru', 'হায়েয (ঋতুস্রাব)'),
    MapEntry('salat', 'সালাত (নামাজ)'),
    MapEntry('prayer', 'নামাজ'),
    MapEntry('adhaan', 'আযান'),
    MapEntry('friday', 'জুমা'),
    MapEntry('funeral', 'জানাযা'),
    MapEntry('zakat', 'যাকাত'),
    MapEntry('charity', 'দান ও সদকা'),
    MapEntry('fasting', 'সাওম (রোজা)'),
    MapEntry('ramad', 'রমজান'),
    MapEntry('hajj', 'হজ্জ'),
    MapEntry('pilgrim', 'হজ্জ ও উমরাহ'),
    MapEntry('marriage', 'বিবাহ'),
    MapEntry('divorce', 'তালাক'),
    MapEntry('jihad', 'জিহাদ'),
    MapEntry('jihaad', 'জিহাদ'),
    MapEntry('food', 'খাদ্য ও পানীয়'),
    MapEntry('drink', 'পানীয়'),
    MapEntry('dress', 'পোশাক'),
    MapEntry('manners', 'আদব ও আখলাক'),
    MapEntry('adab', 'আদব ও আখলাক'),
    MapEntry('dua', 'দোয়া ও জিকির'),
    MapEntry('invocation', 'দোয়া ও জিকির'),
    MapEntry('remembrance', 'আল্লাহর জিকির'),
    MapEntry('repentance', 'তাওবা ও ইস্তিগফার'),
    MapEntry('paradise', 'জান্নাত'),
    MapEntry('hell', 'জাহান্নাম'),
    MapEntry('dream', 'স্বপ্নের ব্যাখ্যা'),
    MapEntry('medicine', 'চিকিৎসা'),
    MapEntry('inheritance', 'উত্তরাধিকার'),
    MapEntry('wills', 'অসিয়ত'),
    MapEntry('oath', 'শপথ ও মানত'),
    MapEntry('tawheed', 'তাওহীদ'),
    MapEntry('tafsir', 'তাফসীর'),
    MapEntry('tafseer', 'তাফসীর'),
    MapEntry('virtue', 'ফজিলত ও মর্যাদা'),
    MapEntry('merit', 'ফজিলত ও মর্যাদা'),
    MapEntry('trade', 'ক্রয়-বিক্রয়'),
    MapEntry('sales', 'ক্রয়-বিক্রয়'),
  ];

  for (final kv in keywordPairs) {
    if (normalized.contains(kv.key)) {
      return '${kv.value} ($raw)';
    }
  }

  return raw;
}
