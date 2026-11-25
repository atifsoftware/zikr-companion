import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/desktop_tray_service.dart';
import '../services/zikr_scheduler_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportBackup(
    BuildContext context,
    ZikrSchedulerService scheduler,
  ) async {
    try {
      final jsonStr = scheduler.exportBackupJson();
      String? outputPath;
      if (DesktopTrayService.isDesktop) {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'জিকির ব্যাকআপ সেভ করুন',
          fileName: 'zikr_backup.json',
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        outputPath = '${dir.path}${Platform.pathSeparator}zikr_backup.json';
      }
      if (outputPath == null) return;
      await File(outputPath).writeAsString(jsonStr);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ব্যাকআপ সংরক্ষিত হয়েছে: $outputPath')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ব্যাকআপ সেভ করা যায়নি।')),
        );
      }
    }
  }

  Future<void> _importBackup(
    BuildContext context,
    ZikrSchedulerService scheduler,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      final path = result?.files.single.path;
      if (path == null) return;
      final raw = await File(path).readAsString();
      final ok = await scheduler.importBackupJson(raw);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'ব্যাকআপ সফলভাবে রিস্টোর হয়েছে!'
                  : 'ফাইলটি সঠিক ব্যাকআপ ফরম্যাটে নেই।',
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = context.watch<ZikrSchedulerService>();
    final settings = scheduler.settings;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: 'জিকির রিমাইন্ডার সেটিংস',
          children: [
            ListTile(
              title: const Text('কত মিনিট পর পর জিকির চালু হবে'),
              subtitle: Text('প্রতি ${settings.intervalMinutes} মিনিট পর পর'),
              trailing: SizedBox(
                width: 180,
                child: Slider(
                  value: settings.intervalMinutes.toDouble(),
                  min: 1,
                  max: 120,
                  divisions: 119,
                  label: '${settings.intervalMinutes} মিনিট',
                  activeColor: AppTheme.emeraldPrimary,
                  onChanged: (val) => scheduler.updateSettings(
                    settings.copyWith(intervalMinutes: val.round()),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('প্রতিবার কতবার জিকির বলবে / পড়বে'),
              subtitle: Text('${settings.repeatCount} বার'),
              trailing: DropdownButton<int>(
                value: [1, 2, 3, 4, 5, 7, 10, 33].contains(settings.repeatCount)
                    ? settings.repeatCount
                    : 3,
                items: const [1, 2, 3, 4, 5, 7, 10, 33]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v বার')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    scheduler.updateSettings(
                      settings.copyWith(repeatCount: val),
                    );
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('দৈনিক জিকিরের লক্ষ্য (Daily Goal)'),
              subtitle: Text('${settings.dailyGoal} বার'),
              trailing: DropdownButton<int>(
                value: [100, 300, 500, 1000, 2000].contains(settings.dailyGoal)
                    ? settings.dailyGoal
                    : 300,
                items: const [100, 300, 500, 1000, 2000]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v বার')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    scheduler.updateSettings(
                      settings.copyWith(dailyGoal: val),
                    );
                  }
                },
              ),
            ),
            SwitchListTile(
              title: const Text('জিকিরের পপ-আপ মডাল দেখাবে'),
              subtitle: const Text(
                'বন্ধ রাখলে স্ক্রিনে পপ-আপ না দেখিয়ে শুধু সাউন্ডে জিকির বলবে',
              ),
              value: settings.showReminderPopup,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(showReminderPopup: val),
              ),
            ),
            SwitchListTile(
              title: const Text('জিকির মুখে / সাউন্ডে বলবে (Voice)'),
              subtitle: const Text('সময় হলে নির্ধারিত সংখ্যক বার জিকির শোনাবে'),
              value: settings.voiceEnabled,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(voiceEnabled: val),
              ),
            ),
            if (settings.voiceEnabled) ...[
              ListTile(
                title: const Text('বলার গতি (Speech Speed)'),
                subtitle: Text(
                  settings.speechRate <= 0.4
                      ? 'ধীর ও স্পষ্ট'
                      : (settings.speechRate >= 0.6 ? 'দ্রুত' : 'স্বাভাবিক'),
                ),
                trailing: SizedBox(
                  width: 180,
                  child: Slider(
                    value: settings.speechRate,
                    min: 0.25,
                    max: 0.75,
                    divisions: 10,
                    activeColor: AppTheme.emeraldPrimary,
                    onChanged: (val) => scheduler.updateSettings(
                      settings.copyWith(speechRate: val),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: OutlinedButton.icon(
                  onPressed: scheduler.testVoice,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('ভয়েস টেস্ট করুন'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'নামাজের সময় অটো-পজ',
          children: [
            SwitchListTile(
              title: const Text('নামাজের সময় জিকির অটো বন্ধ রাখুন'),
              subtitle:
                  const Text('ওয়াক্ত শুরু হলে নির্ধারিত সময় পর্যন্ত রিমাইন্ডার বন্ধ থাকবে'),
              value: settings.autoPauseOnPrayer,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(autoPauseOnPrayer: val),
              ),
            ),
            if (settings.autoPauseOnPrayer)
              ListTile(
                title: const Text('নামাজের সময় কত মিনিট বন্ধ থাকবে'),
                subtitle: Text('${settings.prayerPauseMinutes} মিনিট'),
                trailing: SizedBox(
                  width: 180,
                  child: Slider(
                    value: settings.prayerPauseMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${settings.prayerPauseMinutes} মিনিট',
                    activeColor: AppTheme.emeraldPrimary,
                    onChanged: (val) => scheduler.updateSettings(
                      settings.copyWith(prayerPauseMinutes: val.round()),
                    ),
                  ),
                ),
              ),
            ListTile(
              title: const Text('শহর / লোকেশন নির্বাচন'),
              subtitle: Text(settings.cityName),
              trailing: DropdownButton<String>(
                value: CityPreset.presets
                        .any((c) => c.name == settings.cityName)
                    ? settings.cityName
                    : CityPreset.presets.first.name,
                items: CityPreset.presets
                    .map((c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (name) {
                  if (name == null) return;
                  final preset = CityPreset.presets.firstWhere(
                    (c) => c.name == name,
                  );
                  scheduler.updateSettings(
                    settings.copyWith(
                      cityName: preset.name,
                      latitude: preset.latitude,
                      longitude: preset.longitude,
                    ),
                  );
                },
              ),
            ),
            SwitchListTile(
              title: const Text('নামাজের আগে সতর্কতা (Pre-Prayer Alert)'),
              subtitle: Text(
                'ওয়াক্ত শুরুর ${settings.prePrayerAlertMinutes} মিনিট আগে মনে করিয়ে দেবে',
              ),
              value: settings.prePrayerAlertEnabled,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(prePrayerAlertEnabled: val),
              ),
            ),
            SwitchListTile(
              title: const Text('ওয়াক্ত শুরু হলে আজান/সতর্কতা নোটিফিকেশন'),
              subtitle:
                  const Text('প্রতিটি নামাজের ওয়াক্ত শুরু হলেই নোটিফিকেশন দেবে'),
              value: settings.azanAlertEnabled,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(azanAlertEnabled: val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'নীরব সময় (Quiet Hours)',
          children: [
            SwitchListTile(
              title: const Text('রাতের নির্দিষ্ট সময়ে জিকির নীরব রাখুন'),
              subtitle: Text(
                'রাত ${settings.quietStartHour}:00 থেকে ভোর ${settings.quietEndHour}:00 পর্যন্ত নীরব থাকবে',
              ),
              value: settings.quietHoursEnabled,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(quietHoursEnabled: val),
              ),
            ),
            if (settings.quietHoursEnabled)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: settings.quietStartHour,
                        decoration: const InputDecoration(
                          labelText: 'শুরু (ঘণ্টা)',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          24,
                          (h) => DropdownMenuItem(
                            value: h,
                            child: Text('${h.toString().padLeft(2, '0')}:00'),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) {
                            scheduler.updateSettings(
                              settings.copyWith(quietStartHour: v),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: settings.quietEndHour,
                        decoration: const InputDecoration(
                          labelText: 'শেষ (ঘণ্টা)',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          24,
                          (h) => DropdownMenuItem(
                            value: h,
                            child: Text('${h.toString().padLeft(2, '0')}:00'),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) {
                            scheduler.updateSettings(
                              settings.copyWith(quietEndHour: v),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (DesktopTrayService.isDesktop) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'কম্পিউটার / ডেস্কটপ সেটিংস',
            children: [
              SwitchListTile(
                title: const Text('কম্পিউটার অন হলে অটো চালু হবে (Startup)'),
                subtitle:
                    const Text('উইন্ডোজ/ম্যাক চালু হলেই জিকির ব্যাকগ্রাউন্ডে রান হবে'),
                value: settings.launchAtStartup,
                activeColor: AppTheme.emeraldPrimary,
                onChanged: (val) => scheduler.updateSettings(
                  settings.copyWith(launchAtStartup: val),
                ),
              ),
              SwitchListTile(
                title: const Text('উইন্ডো ক্লোজ করলে সিস্টেম ট্রে-তে চলবে'),
                subtitle: const Text('অ্যাপ বন্ধ না হয়ে ঘড়ির পাশে মিনিমাইজ হয়ে থাকবে'),
                value: settings.minimizeToTrayOnClose,
                activeColor: AppTheme.emeraldPrimary,
                onChanged: (val) {
                  DesktopTrayService.instance.updateCloseBehavior(val);
                  scheduler.updateSettings(
                    settings.copyWith(minimizeToTrayOnClose: val),
                  );
                },
              ),
              const ListTile(
                leading: Icon(Icons.keyboard_alt_outlined,
                    color: AppTheme.emeraldLight),
                title: Text('কীবোর্ড গ্লোবাল শর্টকাট'),
                subtitle:
                    Text('পিসির যেকোনো জায়গা থেকে Ctrl + Alt + Z চাপলে জিকির আসবে'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _SectionCard(
          title: 'অ্যাপিয়ারেন্স ও সহজ পাঠ (Display)',
          children: [
            SwitchListTile(
              title: const Text('ডার্ক মোড (Dark Mode)'),
              value: settings.darkMode,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(darkMode: val),
              ),
            ),
            SwitchListTile(
              title: const Text('বড় ফন্ট মোড (সহজ পাঠের জন্য)'),
              subtitle: const Text('চালু করে নিচের স্লাইডার দিয়ে সাইজ ঠিক করুন'),
              value: settings.largeFontMode,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(
                  largeFontMode: val,
                  fontScale: val
                      ? (settings.fontScale <= 1.0 ? 1.22 : settings.fontScale)
                      : 1.0,
                ),
              ),
            ),
            if (settings.largeFontMode)
              ListTile(
                title: const Text('ফন্ট সাইজ কাস্টমাইজ করুন'),
                subtitle: Text(
                  '${((settings.fontScale <= 1.0 ? 1.22 : settings.fontScale) * 100).round()}%',
                ),
                trailing: SizedBox(
                  width: 180,
                  child: Slider(
                    value: (settings.fontScale <= 1.0 ? 1.22 : settings.fontScale)
                        .clamp(1.05, 1.5),
                    min: 1.05,
                    max: 1.5,
                    divisions: 9,
                    label:
                        '${((settings.fontScale <= 1.0 ? 1.22 : settings.fontScale) * 100).round()}%',
                    activeColor: AppTheme.emeraldPrimary,
                    onChanged: (val) => scheduler.updateSettings(
                      settings.copyWith(fontScale: val),
                    ),
                  ),
                ),
              ),
            SwitchListTile(
              title: const Text('হোম পেজে সেহরি ও ইফতার কার্ড দেখান'),
              value: settings.showRamadanCard,
              activeColor: AppTheme.emeraldPrimary,
              onChanged: (val) => scheduler.updateSettings(
                settings.copyWith(showRamadanCard: val),
              ),
            ),
            ListTile(
              title: const Text('আরবি ফন্ট স্টাইল (Quran & Zikr)'),
              subtitle: Text(
                settings.arabicFontFamily == 'Lateef'
                    ? 'ইন্দো-পাক / ছাপার কুরআন (Lateef)'
                    : (settings.arabicFontFamily == 'Amiri'
                        ? 'ক্লাসিক্যাল আমিরি (Amiri)'
                        : 'মদীনা মুসহাফ (Scheherazade New)'),
              ),
              trailing: DropdownButton<String>(
                value: ['Lateef', 'ScheherazadeNew', 'Amiri']
                        .contains(settings.arabicFontFamily)
                    ? settings.arabicFontFamily
                    : 'Lateef',
                items: const [
                  DropdownMenuItem(
                    value: 'Lateef',
                    child: Text('ইন্দো-পাক (Lateef)'),
                  ),
                  DropdownMenuItem(
                    value: 'ScheherazadeNew',
                    child: Text('মদীনা (Scheherazade)'),
                  ),
                  DropdownMenuItem(
                    value: 'Amiri',
                    child: Text('ক্লাসিক্যাল (Amiri)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    scheduler.updateSettings(
                      settings.copyWith(arabicFontFamily: val),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CloudSyncCard(scheduler: scheduler),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'ব্যাকআপ ও রিস্টোর (Backup & Restore)',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportBackup(context, scheduler),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldPrimary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('ব্যাকআপ এক্সপোর্ট করুন'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _importBackup(context, scheduler),
                    icon: const Icon(Icons.download_for_offline_rounded),
                    label: const Text('ব্যাকআপ রিস্টোর করুন'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CloudSyncCard extends StatefulWidget {
  final ZikrSchedulerService scheduler;
  const _CloudSyncCard({required this.scheduler});

  @override
  State<_CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends State<_CloudSyncCard> {
  late final TextEditingController _urlCtrl = TextEditingController(
    text: widget.scheduler.settings.serverUrl,
  );
  bool _syncing = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _syncNow() async {
    if (_urlCtrl.text.trim().isEmpty || _syncing) return;
    setState(() => _syncing = true);
    try {
      final added = await widget.scheduler.syncFromServer(_urlCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added > 0
                  ? '$added টি নতুন জিকির ও অডিও সিঙ্ক হয়েছে!'
                  : 'সিঙ্ক সম্পন্ন হয়েছে (সবগুলো আপডেটেড)।',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('সার্ভারের সাথে সংযোগ করা যায়নি — URL পরীক্ষা করুন।'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ওয়েবসাইট ও ক্লাউড সিঙ্ক (cPanel API)',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'আপনার ওয়েবসাইটের URL',
                  hintText: 'https://zikr.yourdomain.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _syncing ? null : _syncNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  foregroundColor: Colors.white,
                ),
                icon: _syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded),
                label: Text(_syncing ? 'সিঙ্ক হচ্ছে...' : 'এখনই সিঙ্ক করুন'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emeraldLight,
                    ),
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}
