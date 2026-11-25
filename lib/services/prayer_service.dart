import 'package:adhan/adhan.dart';

class PrayerSlot {
  final String nameBangla;
  final String nameEnglish;
  final DateTime startTime;

  const PrayerSlot({
    required this.nameBangla,
    required this.nameEnglish,
    required this.startTime,
  });
}

class PrayerPauseStatus {
  final bool isPaused;
  final PrayerSlot? activePrayer;
  final Duration? remainingPause;

  const PrayerPauseStatus({
    required this.isPaused,
    this.activePrayer,
    this.remainingPause,
  });
}

class PrayerService {
  DateTime _parseTimeOnDate(DateTime date, String hhmm, DateTime fallback) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  List<PrayerSlot> getPrayerTimesForDate({
    required double latitude,
    required double longitude,
    DateTime? date,
    bool useCustomTimes = false,
    Map<String, String> customTimes = const {},
  }) {
    final target = date ?? DateTime.now();
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(target),
      params,
    );

    DateTime resolveTime(String key, DateTime autoTime) {
      if (!useCustomTimes) return autoTime;
      final custom = customTimes[key];
      if (custom == null) return autoTime;
      return _parseTimeOnDate(target, custom, autoTime);
    }

    return [
      PrayerSlot(
        nameBangla: 'ফজর',
        nameEnglish: 'Fajr',
        startTime: resolveTime('Fajr', prayerTimes.fajr),
      ),
      PrayerSlot(
        nameBangla: 'যোহর',
        nameEnglish: 'Dhuhr',
        startTime: resolveTime('Dhuhr', prayerTimes.dhuhr),
      ),
      PrayerSlot(
        nameBangla: 'আসর',
        nameEnglish: 'Asr',
        startTime: resolveTime('Asr', prayerTimes.asr),
      ),
      PrayerSlot(
        nameBangla: 'মাগরিব',
        nameEnglish: 'Maghrib',
        startTime: resolveTime('Maghrib', prayerTimes.maghrib),
      ),
      PrayerSlot(
        nameBangla: 'এশা',
        nameEnglish: 'Isha',
        startTime: resolveTime('Isha', prayerTimes.isha),
      ),
    ];
  }

  PrayerPauseStatus checkPrayerPause({
    required double latitude,
    required double longitude,
    required bool autoPauseEnabled,
    required int pauseMinutes,
    DateTime? now,
    bool useCustomTimes = false,
    Map<String, String> customTimes = const {},
  }) {
    if (!autoPauseEnabled || pauseMinutes <= 0) {
      return const PrayerPauseStatus(isPaused: false);
    }

    final current = now ?? DateTime.now();
    final slots = getPrayerTimesForDate(
      latitude: latitude,
      longitude: longitude,
      date: current,
      useCustomTimes: useCustomTimes,
      customTimes: customTimes,
    );

    for (final slot in slots) {
      final pauseEnd = slot.startTime.add(Duration(minutes: pauseMinutes));
      if (!current.isBefore(slot.startTime) && current.isBefore(pauseEnd)) {
        return PrayerPauseStatus(
          isPaused: true,
          activePrayer: slot,
          remainingPause: pauseEnd.difference(current),
        );
      }
    }

    return const PrayerPauseStatus(isPaused: false);
  }

  PrayerSlot getNextPrayer({
    required double latitude,
    required double longitude,
    DateTime? now,
    bool useCustomTimes = false,
    Map<String, String> customTimes = const {},
  }) {
    final current = now ?? DateTime.now();
    final todaySlots = getPrayerTimesForDate(
      latitude: latitude,
      longitude: longitude,
      date: current,
      useCustomTimes: useCustomTimes,
      customTimes: customTimes,
    );

    for (final slot in todaySlots) {
      if (slot.startTime.isAfter(current)) {
        return slot;
      }
    }

    final tomorrowSlots = getPrayerTimesForDate(
      latitude: latitude,
      longitude: longitude,
      date: current.add(const Duration(days: 1)),
      useCustomTimes: useCustomTimes,
      customTimes: customTimes,
    );
    return tomorrowSlots.first;
  }
}
