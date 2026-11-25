import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/dua_screen.dart';
import 'screens/home_screen.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/quran_recitation_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasbih_screen.dart';
import 'screens/zikr_list_screen.dart';
import 'services/desktop_tray_service.dart';
import 'services/quran_player_service.dart';
import 'services/zikr_scheduler_service.dart';
import 'theme/app_theme.dart';
import 'widgets/zikr_reminder_dialog.dart';

class ZikrApp extends StatefulWidget {
  const ZikrApp({super.key});

  @override
  State<ZikrApp> createState() => _ZikrAppState();
}

class _ZikrAppState extends State<ZikrApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  int _selectedIndex = 0;
  bool _isReminderDialogOpen = false;

  late final List<Widget> _screens = [
    HomeScreen(
      onNavigateTab: (i) => setState(() => _selectedIndex = i),
    ),
    const ZikrListScreen(),
    const TasbihScreen(),
    const DuaScreen(),
    QuranRecitationScreen(
      onBackToHome: () => setState(() => _selectedIndex = 0),
    ),
    const PrayerTimesScreen(),
    const SettingsScreen(),
  ];

  static const _titles = [
    'জিকির (Zikr)',
    'জিকিরের তালিকা',
    'ডিজিটাল তসবিহ',
    'মাসনূন দোয়া',
    'কুরআন তিলাওয়াত',
    'নামাজের সময়সূচি',
    'সেটিংস',
  ];

  // Mobile bottom nav maps 5 primary tabs -> _screens indices.
  static const List<int> _mobileTabToScreenIndex = [0, 1, 2, 4, 5];

  int get _mobileBottomNavIndex {
    final idx = _mobileTabToScreenIndex.indexOf(_selectedIndex);
    return idx == -1 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduler = context.read<ZikrSchedulerService>();
      scheduler.onReminderTriggered = (item, repeatCount) async {
        await DesktopTrayService.instance.bringToFront();
        final ctx = _navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          _isReminderDialogOpen = true;
          await showDialog<void>(
            context: ctx,
            barrierDismissible: true,
            builder: (_) => ZikrReminderDialog(
              item: item,
              targetRepeat: repeatCount,
            ),
          );
          _isReminderDialogOpen = false;
        }
      };
      scheduler.onReminderAutoClose = () {
        if (!_isReminderDialogOpen) return;
        final nav = _navigatorKey.currentState;
        if (nav != null && nav.canPop()) {
          _isReminderDialogOpen = false;
          nav.pop();
        }
      };
      scheduler.onPrePrayerAlert = (prayer, minutesLeft) {
        final ctx = _navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                'আর $minutesLeft মিনিট পর ${prayer.nameBangla} নামাজের ওয়াক্ত শুরু হবে।',
              ),
              backgroundColor: AppTheme.emeraldPrimary,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      };
      scheduler.onAzanAlert = (prayer) {
        final ctx = _navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                'আল্লাহু আকবার — ${prayer.nameBangla} নামাজের ওয়াক্ত শুরু হয়েছে।',
              ),
              backgroundColor: AppTheme.emeraldPrimary,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = context.watch<ZikrSchedulerService>();
    final quranPlayer = context.watch<QuranPlayerService>();
    final isDark = scheduler.settings.darkMode;
    final isLargeFont = scheduler.settings.largeFontMode;
    final showMiniPlayer = quranPlayer.isActiveSession && _selectedIndex != 4;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'জিকির (Zikr)',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(isLargeFont ? 1.22 : 1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: true,
            alt: true,
          ): () => scheduler.triggerZikrNow(ignorePrayerPause: true),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
          final isDesktopWide = constraints.maxWidth >= 780;
          return Scaffold(
            appBar: isDesktopWide
                ? null
                : AppBar(
                    titleSpacing: 16,
                    title: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/icons/app_logo.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _titles[_selectedIndex],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'মাসনূন দোয়া',
                        icon: Icon(
                          _selectedIndex == 3
                              ? Icons.volunteer_activism_rounded
                              : Icons.volunteer_activism_outlined,
                          color: _selectedIndex == 3
                              ? AppTheme.emeraldLight
                              : null,
                        ),
                        onPressed: () => setState(() => _selectedIndex = 3),
                      ),
                      IconButton(
                        tooltip: isDark ? 'লাইট মোড' : 'ডার্ক মোড',
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                        onPressed: () => scheduler.updateSettings(
                          scheduler.settings.copyWith(darkMode: !isDark),
                        ),
                      ),
                      IconButton(
                        tooltip: 'সেটিংস',
                        icon: Icon(
                          _selectedIndex == 6
                              ? Icons.settings_rounded
                              : Icons.settings_outlined,
                          color: _selectedIndex == 6
                              ? AppTheme.emeraldLight
                              : null,
                        ),
                        onPressed: () => setState(() => _selectedIndex = 6),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
            body: Row(
              children: [
                if (isDesktopWide)
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    extended: constraints.maxWidth >= 1000,
                    backgroundColor: Theme.of(context).cardTheme.color,
                    selectedIconTheme: const IconThemeData(
                      color: AppTheme.emeraldPrimary,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: AppTheme.emeraldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    onDestinationSelected: (i) =>
                        setState(() => _selectedIndex = i),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/icons/app_logo.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'জিকির',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('হোম'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book_rounded),
                        label: Text('জিকির তালিকা'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.touch_app_outlined),
                        selectedIcon: Icon(Icons.touch_app_rounded),
                        label: Text('তসবিহ'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.volunteer_activism_outlined),
                        selectedIcon: Icon(Icons.volunteer_activism_rounded),
                        label: Text('মাসনূন দোয়া'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.headphones_outlined),
                        selectedIcon: Icon(Icons.headphones_rounded),
                        label: Text('তিলাওয়াত'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.access_time_outlined),
                        selectedIcon: Icon(Icons.access_time_filled),
                        label: Text('নামাজের সময়'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: Text('সেটিংস'),
                      ),
                    ],
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: IconButton(
                            tooltip: isDark ? 'লাইট মোড' : 'ডার্ক মোড',
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                            ),
                            onPressed: () => scheduler.updateSettings(
                              scheduler.settings.copyWith(darkMode: !isDark),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(child: _screens[_selectedIndex]),
                        if (showMiniPlayer)
                          _MiniQuranPlayerBar(
                            player: quranPlayer,
                            onOpenQuranTab: () =>
                                setState(() => _selectedIndex = 4),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: isDesktopWide
                ? null
                : Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: NavigationBar(
                        height: 68,
                        indicatorColor:
                            AppTheme.emeraldPrimary.withOpacity(0.14),
                        selectedIndex: _mobileBottomNavIndex,
                        onDestinationSelected: (i) => setState(
                          () => _selectedIndex = _mobileTabToScreenIndex[i],
                        ),
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home_rounded,
                                color: AppTheme.emeraldPrimary),
                            label: 'হোম',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.menu_book_outlined),
                            selectedIcon: Icon(Icons.menu_book_rounded,
                                color: AppTheme.emeraldPrimary),
                            label: 'জিকির',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.touch_app_outlined),
                            selectedIcon: Icon(Icons.touch_app_rounded,
                                color: AppTheme.emeraldPrimary),
                            label: 'তসবিহ',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.headphones_outlined),
                            selectedIcon: Icon(Icons.headphones_rounded,
                                color: AppTheme.emeraldPrimary),
                            label: 'তিলাওয়াত',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.access_time_outlined),
                            selectedIcon: Icon(Icons.access_time_filled,
                                color: AppTheme.emeraldPrimary),
                            label: 'নামাজ',
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
        ),
      ),
    );
  }
}

class _MiniQuranPlayerBar extends StatelessWidget {
  final QuranPlayerService player;
  final VoidCallback onOpenQuranTab;

  const _MiniQuranPlayerBar({
    required this.player,
    required this.onOpenQuranTab,
  });

  @override
  Widget build(BuildContext context) {
    final surah = player.currentSurah;
    final ayah = player.currentAyah;
    if (surah == null) return const SizedBox.shrink();

    return InkWell(
      onTap: onOpenQuranTab,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.emeraldPrimary,
          border: Border(
            top: BorderSide(color: AppTheme.goldAccent.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.graphic_eq_rounded, color: AppTheme.goldAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'সূরা ${surah.nameBangla}${ayah != null ? ' • আয়াত ${ayah.numberInSurah}' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    player.selectedQari.nameBangla,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: player.togglePlayPause,
              icon: Icon(
                player.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: AppTheme.goldAccent,
                size: 30,
              ),
            ),
            IconButton(
              onPressed: player.stop,
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
