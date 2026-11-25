import 'package:flutter_test/flutter_test.dart';
import 'package:zikr/models/app_settings.dart';
import 'package:zikr/models/daily_inspiration.dart';
import 'package:zikr/models/surah_data.dart';
import 'package:zikr/models/zikr_item.dart';
import 'package:zikr/screens/dua_screen.dart';
import 'package:zikr/services/hijri_service.dart';
import 'package:zikr/services/prayer_service.dart';

void main() {
  test('Surah list has all 114 surahs and Qari presets are present', () {
    expect(SurahInfo.all114.length, 114);
    expect(SurahInfo.all114.first.number, 1);
    expect(SurahInfo.all114.last.number, 114);
    expect(QariInfo.presets.length, greaterThanOrEqualTo(5));
    expect(DuaItem.allDuas.length, greaterThanOrEqualTo(8));
  });
  test('Default zikr list is populated and enabled', () {
    final items = ZikrItem.defaultList();
    expect(items.length, greaterThanOrEqualTo(8));
    expect(items.every((item) => item.isEnabled), isTrue);
  });

  test('HijriService formats date and QuietHours handles overnight range', () {
    final hijri = HijriService().fromGregorian(DateTime(2026, 11, 24));
    expect(hijri.year, greaterThan(1440));
    expect(hijri.formattedBangla, contains('হিজরি'));

    const settings = AppSettings(
      quietHoursEnabled: true,
      quietStartHour: 23,
      quietEndHour: 4,
    );
    expect(settings.isWithinQuietHours(DateTime(2026, 11, 24, 23, 30)), isTrue);
    expect(settings.isWithinQuietHours(DateTime(2026, 11, 24, 2, 0)), isTrue);
    expect(settings.isWithinQuietHours(DateTime(2026, 11, 24, 14, 0)), isFalse);
  });

  test('PrayerService computes 5 daily prayers and auto-pause window', () {
    final service = PrayerService();
    final now = DateTime(2026, 11, 24, 12, 0);
    final slots = service.getPrayerTimesForDate(
      latitude: 23.8103,
      longitude: 90.4125,
      date: now,
    );
    expect(slots.length, 5);

    final dhuhrStart = slots[1].startTime;
    final pausedStatus = service.checkPrayerPause(
      latitude: 23.8103,
      longitude: 90.4125,
      autoPauseEnabled: true,
      pauseMinutes: 20,
      now: dhuhrStart.add(const Duration(minutes: 5)),
    );
    expect(pausedStatus.isPaused, isTrue);
    expect(pausedStatus.activePrayer?.nameEnglish, 'Dhuhr');

    final customSlots = service.getPrayerTimesForDate(
      latitude: 23.8103,
      longitude: 90.4125,
      date: now,
      useCustomTimes: true,
      customTimes: const {'Dhuhr': '13:30'},
    );
    expect(customSlots[1].startTime.hour, 13);
    expect(customSlots[1].startTime.minute, 30);

    final sehriIftar = service.getSehriAndIftarTimes(
      latitude: 23.8103,
      longitude: 90.4125,
      date: now,
    );
    expect(sehriIftar.sehriEnd.isBefore(sehriIftar.iftarTime), isTrue);
    expect(DailyInspiration.forDate(now).bangla, isNotEmpty);
  });
}
