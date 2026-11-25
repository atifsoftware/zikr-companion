class HijriDateInfo {
  final int day;
  final int month;
  final int year;
  final String monthNameBangla;

  const HijriDateInfo({
    required this.day,
    required this.month,
    required this.year,
    required this.monthNameBangla,
  });

  String get formattedBangla => '$day $monthNameBangla, $year হিজরি';

  bool get isAyyamAlBeed => day == 13 || day == 14 || day == 15;
}

class HijriService {
  static const List<String> _banglaMonths = [
    'মহররম',
    'সফর',
    'রবিউল আউয়াল',
    'রবিউস সানি',
    'জমাদিউল আউয়াল',
    'জমাদিউস সানি',
    'রজব',
    'শাবান',
    'রমজান',
    'শাওয়াল',
    'জিলকদ',
    'জিলহজ',
  ];

  /// Converts a Gregorian [date] to an approximate Hijri date using the
  /// standard tabular Islamic calendar (Kuwaiti algorithm).
  HijriDateInfo fromGregorian(DateTime date) {
    final d = date.day;
    final m = date.month;
    final y = date.year;

    int jd;
    if ((y > 1582) ||
        (y == 1582 && m > 10) ||
        (y == 1582 && m == 10 && d > 14)) {
      jd = ((1461 * (y + 4800 + ((m - 14) / 12).truncate())) / 4).truncate() +
          ((367 * (m - 2 - 12 * (((m - 14) / 12).truncate()))) / 12)
              .truncate() -
          ((3 * (((y + 4900 + ((m - 14) / 12).truncate()) / 100).truncate())) /
                  4)
              .truncate() +
          d -
          32075;
    } else {
      jd = 367 * y -
          ((7 * (y + 5001 + ((m - 9) / 7).truncate())) / 4).truncate() +
          ((275 * m) / 9).truncate() +
          d +
          1729777;
    }

    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).truncate();
    final l2 = l - 10631 * n + 354;
    final j = (((10985 - l2) / 5316).truncate()) *
            (((50 * l2) / 17719).truncate()) +
        ((l2 / 5670).truncate()) * (((43 * l2) / 15238).truncate());
    final l3 = l2 -
        (((30 - j) / 15).truncate()) * (((17719 * j) / 50).truncate()) -
        ((j / 16).truncate()) * (((15238 * j) / 43).truncate()) +
        29;

    final hijriMonth = ((24 * l3) / 709).truncate();
    final hijriDay = l3 - ((709 * hijriMonth) / 24).truncate();
    final hijriYear = 30 * n + j - 30;

    final monthIdx = (hijriMonth - 1).clamp(0, 11);
    return HijriDateInfo(
      day: hijriDay,
      month: hijriMonth,
      year: hijriYear,
      monthNameBangla: _banglaMonths[monthIdx],
    );
  }

  List<String> getTodayIslamicReminders(DateTime now) {
    final reminders = <String>[];
    final hijri = fromGregorian(now);

    if (now.weekday == DateTime.friday) {
      reminders.add('আজ পবিত্র জুমার দিন — বেশি বেশি দরুদ ও সূরা কাহফ পড়ুন');
    }
    if (now.weekday == DateTime.monday || now.weekday == DateTime.thursday) {
      reminders.add('আজ সুন্নাহ নফল রোজার দিন (সোম/বৃহস্পতিবার)');
    }
    if (hijri.isAyyamAlBeed) {
      reminders.add('আজ আইয়ামে বীজ (${hijri.day} তারিখ) — সুন্নাহ রোজার দিন');
    }
    if (now.hour >= 4 && now.hour < 10) {
      reminders.add('সকালের মাসনূন জিকির ও দোয়া পড়ার উত্তম সময়');
    } else if (now.hour >= 15 && now.hour < 19) {
      reminders.add('সন্ধ্যার মাসনূন জিকির ও দোয়া পড়ার উত্তম সময়');
    }
    return reminders;
  }
}
