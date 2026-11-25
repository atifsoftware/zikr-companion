class AppSettings {
  final int intervalMinutes;
  final int repeatCount;
  final int dailyGoal;
  final bool isReminderActive;
  final bool showReminderPopup;
  final bool voiceEnabled;
  final double speechRate;
  final bool autoPauseOnPrayer;
  final int prayerPauseMinutes;
  final bool prePrayerAlertEnabled;
  final int prePrayerAlertMinutes;
  final bool azanAlertEnabled;
  final bool quietHoursEnabled;
  final int quietStartHour;
  final int quietEndHour;
  final bool useCustomPrayerTimes;
  final Map<String, String> customPrayerTimes;
  final bool launchAtStartup;
  final bool minimizeToTrayOnClose;
  final bool darkMode;
  final bool largeFontMode;
  final bool showRamadanCard;
  final String cityName;
  final double latitude;
  final double longitude;

  static const Map<String, String> defaultCustomPrayerTimes = {
    'Fajr': '05:00',
    'Dhuhr': '12:15',
    'Asr': '15:45',
    'Maghrib': '17:20',
    'Isha': '19:00',
  };

  const AppSettings({
    this.intervalMinutes = 15,
    this.repeatCount = 3,
    this.dailyGoal = 300,
    this.isReminderActive = true,
    this.showReminderPopup = true,
    this.voiceEnabled = true,
    this.speechRate = 0.45,
    this.autoPauseOnPrayer = true,
    this.prayerPauseMinutes = 20,
    this.prePrayerAlertEnabled = true,
    this.prePrayerAlertMinutes = 10,
    this.azanAlertEnabled = true,
    this.quietHoursEnabled = false,
    this.quietStartHour = 23,
    this.quietEndHour = 4,
    this.useCustomPrayerTimes = false,
    this.customPrayerTimes = defaultCustomPrayerTimes,
    this.launchAtStartup = true,
    this.minimizeToTrayOnClose = true,
    this.darkMode = false,
    this.largeFontMode = false,
    this.showRamadanCard = true,
    this.cityName = 'ঢাকা (Dhaka)',
    this.latitude = 23.8103,
    this.longitude = 90.4125,
  });

  bool isWithinQuietHours(DateTime now) {
    if (!quietHoursEnabled) return false;
    final h = now.hour;
    if (quietStartHour <= quietEndHour) {
      return h >= quietStartHour && h < quietEndHour;
    }
    return h >= quietStartHour || h < quietEndHour;
  }

  AppSettings copyWith({
    int? intervalMinutes,
    int? repeatCount,
    int? dailyGoal,
    bool? isReminderActive,
    bool? showReminderPopup,
    bool? voiceEnabled,
    double? speechRate,
    bool? autoPauseOnPrayer,
    int? prayerPauseMinutes,
    bool? prePrayerAlertEnabled,
    int? prePrayerAlertMinutes,
    bool? azanAlertEnabled,
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietEndHour,
    bool? useCustomPrayerTimes,
    Map<String, String>? customPrayerTimes,
    bool? launchAtStartup,
    bool? minimizeToTrayOnClose,
    bool? darkMode,
    bool? largeFontMode,
    bool? showRamadanCard,
    String? cityName,
    double? latitude,
    double? longitude,
  }) {
    return AppSettings(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      repeatCount: repeatCount ?? this.repeatCount,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      isReminderActive: isReminderActive ?? this.isReminderActive,
      showReminderPopup: showReminderPopup ?? this.showReminderPopup,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      speechRate: speechRate ?? this.speechRate,
      autoPauseOnPrayer: autoPauseOnPrayer ?? this.autoPauseOnPrayer,
      prayerPauseMinutes: prayerPauseMinutes ?? this.prayerPauseMinutes,
      prePrayerAlertEnabled:
          prePrayerAlertEnabled ?? this.prePrayerAlertEnabled,
      prePrayerAlertMinutes:
          prePrayerAlertMinutes ?? this.prePrayerAlertMinutes,
      azanAlertEnabled: azanAlertEnabled ?? this.azanAlertEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietEndHour: quietEndHour ?? this.quietEndHour,
      useCustomPrayerTimes: useCustomPrayerTimes ?? this.useCustomPrayerTimes,
      customPrayerTimes: customPrayerTimes ?? this.customPrayerTimes,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      minimizeToTrayOnClose:
          minimizeToTrayOnClose ?? this.minimizeToTrayOnClose,
      darkMode: darkMode ?? this.darkMode,
      largeFontMode: largeFontMode ?? this.largeFontMode,
      showRamadanCard: showRamadanCard ?? this.showRamadanCard,
      cityName: cityName ?? this.cityName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'intervalMinutes': intervalMinutes,
        'repeatCount': repeatCount,
        'dailyGoal': dailyGoal,
        'isReminderActive': isReminderActive,
        'showReminderPopup': showReminderPopup,
        'voiceEnabled': voiceEnabled,
        'speechRate': speechRate,
        'autoPauseOnPrayer': autoPauseOnPrayer,
        'prayerPauseMinutes': prayerPauseMinutes,
        'prePrayerAlertEnabled': prePrayerAlertEnabled,
        'prePrayerAlertMinutes': prePrayerAlertMinutes,
        'azanAlertEnabled': azanAlertEnabled,
        'quietHoursEnabled': quietHoursEnabled,
        'quietStartHour': quietStartHour,
        'quietEndHour': quietEndHour,
        'useCustomPrayerTimes': useCustomPrayerTimes,
        'customPrayerTimes': customPrayerTimes,
        'launchAtStartup': launchAtStartup,
        'minimizeToTrayOnClose': minimizeToTrayOnClose,
        'darkMode': darkMode,
        'largeFontMode': largeFontMode,
        'showRamadanCard': showRamadanCard,
        'cityName': cityName,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawCustom = json['customPrayerTimes'];
    final parsedCustom = Map<String, String>.from(defaultCustomPrayerTimes);
    if (rawCustom is Map) {
      for (final entry in rawCustom.entries) {
        parsedCustom[entry.key.toString()] = entry.value.toString();
      }
    }

    return AppSettings(
      intervalMinutes: (json['intervalMinutes'] as int?) ?? 15,
      repeatCount: (json['repeatCount'] as int?) ?? 3,
      dailyGoal: (json['dailyGoal'] as int?) ?? 300,
      isReminderActive: (json['isReminderActive'] as bool?) ?? true,
      showReminderPopup: (json['showReminderPopup'] as bool?) ?? true,
      voiceEnabled: (json['voiceEnabled'] as bool?) ?? true,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.45,
      autoPauseOnPrayer: (json['autoPauseOnPrayer'] as bool?) ?? true,
      prayerPauseMinutes: (json['prayerPauseMinutes'] as int?) ?? 20,
      prePrayerAlertEnabled: (json['prePrayerAlertEnabled'] as bool?) ?? true,
      prePrayerAlertMinutes: (json['prePrayerAlertMinutes'] as int?) ?? 10,
      azanAlertEnabled: (json['azanAlertEnabled'] as bool?) ?? true,
      quietHoursEnabled: (json['quietHoursEnabled'] as bool?) ?? false,
      quietStartHour: (json['quietStartHour'] as int?) ?? 23,
      quietEndHour: (json['quietEndHour'] as int?) ?? 4,
      useCustomPrayerTimes: (json['useCustomPrayerTimes'] as bool?) ?? false,
      customPrayerTimes: parsedCustom,
      launchAtStartup: (json['launchAtStartup'] as bool?) ?? true,
      minimizeToTrayOnClose:
          (json['minimizeToTrayOnClose'] as bool?) ?? true,
      darkMode: (json['darkMode'] as bool?) ?? false,
      largeFontMode: (json['largeFontMode'] as bool?) ?? false,
      showRamadanCard: (json['showRamadanCard'] as bool?) ?? true,
      cityName: (json['cityName'] as String?) ?? 'ঢাকা (Dhaka)',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.8103,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 90.4125,
    );
  }
}

class CityPreset {
  final String name;
  final double latitude;
  final double longitude;

  const CityPreset(this.name, this.latitude, this.longitude);

  static const List<CityPreset> presets = [
    CityPreset('ঢাকা (Dhaka)', 23.8103, 90.4125),
    CityPreset('চট্টগ্রাম (Chattogram)', 22.3569, 91.7832),
    CityPreset('সিলেট (Sylhet)', 24.8949, 91.8687),
    CityPreset('রাজশাহী (Rajshahi)', 24.3745, 88.6042),
    CityPreset('খুলনা (Khulna)', 22.8456, 89.5403),
    CityPreset('বরিশাল (Barishal)', 22.7010, 90.3535),
    CityPreset('রংপুর (Rangpur)', 25.7439, 89.2752),
    CityPreset('ময়মনসিংহ (Mymensingh)', 24.7471, 90.4203),
  ];
}
