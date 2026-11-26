import '../utils/io_compat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class DesktopTrayService with TrayListener, WindowListener {
  static final DesktopTrayService instance = DesktopTrayService._();
  DesktopTrayService._();

  VoidCallback? onShowZikrNow;
  VoidCallback? onTogglePause;
  bool _minimizeToTrayOnClose = true;

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  void updateCloseBehavior(bool minimizeToTray) {
    _minimizeToTrayOnClose = minimizeToTray;
    if (isDesktop) {
      windowManager.setPreventClose(minimizeToTray);
    }
  }

  Future<void> init({
    required bool launchOnBoot,
    required bool minimizeToTray,
    VoidCallback? onShowZikrNow,
    VoidCallback? onTogglePause,
  }) async {
    if (!isDesktop) return;
    _minimizeToTrayOnClose = minimizeToTray;
    this.onShowZikrNow = onShowZikrNow;
    this.onTogglePause = onTogglePause;

    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(minimizeToTray);

    const windowOptions = WindowOptions(
      size: Size(1020, 700),
      minimumSize: Size(760, 540),
      center: true,
      title: 'জিকির (Zikr) — ইসলামিক রিমাইন্ডার',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    await _initStartup(launchOnBoot);
    await _initTray();
  }

  Future<void> _initStartup(bool enabled) async {
    try {
      final info = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: info.appName.isEmpty ? 'Zikr' : info.appName,
        appPath: Platform.resolvedExecutable,
      );
      await setLaunchAtStartup(enabled);
    } catch (_) {
      // Startup registration may fail in unsigned/dev environments; ignore safely.
    }
  }

  static Future<void> setLaunchAtStartup(bool enabled) async {
    if (!isDesktop) return;
    try {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (_) {}
  }

  Future<void> _initTray() async {
    try {
      trayManager.addListener(this);
      if (Platform.isWindows) {
        await trayManager.setIcon('assets/icons/app_icon.ico');
      }
      await trayManager.setToolTip('জিকির (Zikr) — আল্লাহর জিকির রিমাইন্ডার');
      final menu = Menu(
        items: [
          MenuItem(key: 'open_app', label: 'অ্যাপ খুলুন (Open Zikr)'),
          MenuItem(key: 'show_zikr', label: 'এখনই জিকির দেখান'),
          MenuItem(key: 'toggle_pause', label: 'রিমাইন্ডার চালু / বিরতি'),
          MenuItem.separator(),
          MenuItem(key: 'exit_app', label: 'সম্পূর্ণ বন্ধ করুন (Exit)'),
        ],
      );
      await trayManager.setContextMenu(menu);
    } catch (_) {
      // Tray icon might require a platform icon asset when packaged.
    }
  }

  Future<void> bringToFront() async {
    if (!isDesktop) return;
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconMouseDown() {
    bringToFront();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open_app':
        bringToFront();
        break;
      case 'show_zikr':
        bringToFront();
        onShowZikrNow?.call();
        break;
      case 'toggle_pause':
        onTogglePause?.call();
        break;
      case 'exit_app':
        windowManager.setPreventClose(false);
        windowManager.close();
        exit(0);
    }
  }

  @override
  void onWindowClose() async {
    if (_minimizeToTrayOnClose) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }
}
