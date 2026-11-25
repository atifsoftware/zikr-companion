import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/desktop_tray_service.dart';
import 'services/quran_player_service.dart';
import 'services/storage_service.dart';
import 'services/zikr_scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.init();
  final scheduler = ZikrSchedulerService(storage);
  final quranPlayer = QuranPlayerService();

  await DesktopTrayService.instance.init(
    launchOnBoot: scheduler.settings.launchAtStartup,
    minimizeToTray: scheduler.settings.minimizeToTrayOnClose,
    onShowZikrNow: () => scheduler.triggerZikrNow(ignorePrayerPause: true),
    onTogglePause: () => scheduler.toggleReminderActive(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ZikrSchedulerService>.value(value: scheduler),
        ChangeNotifierProvider<QuranPlayerService>.value(value: quranPlayer),
      ],
      child: const ZikrApp(),
    ),
  );
}
