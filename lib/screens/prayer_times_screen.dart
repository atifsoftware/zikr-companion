import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/zikr_scheduler_service.dart';
import '../theme/app_theme.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  Future<void> _pickPrayerTime(
    BuildContext context,
    ZikrSchedulerService scheduler,
    String prayerKey,
    DateTime currentTime,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime),
    );
    if (picked == null) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updatedMap = Map<String, String>.from(
      scheduler.settings.customPrayerTimes,
    );
    updatedMap[prayerKey] = formatted;

    await scheduler.updateSettings(
      scheduler.settings.copyWith(
        useCustomPrayerTimes: true,
        customPrayerTimes: updatedMap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = context.watch<ZikrSchedulerService>();
    final settings = scheduler.settings;
    final slots = scheduler.todayPrayerTimes;
    final pauseStatus = scheduler.currentPrayerPause;
    final nextPrayer = scheduler.nextPrayer;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.emeraldLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        settings.useCustomPrayerTimes
                            ? 'কাস্টম নামাজের সময় (নিজে নির্ধারিত)'
                            : settings.cityName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  settings.autoPauseOnPrayer
                      ? 'প্রতি ওয়াক্তের শুরু থেকে ${settings.prayerPauseMinutes} মিনিট জিকির অটো বন্ধ থাকবে।'
                      : 'নামাজের সময় অটো-পজ বর্তমানে বন্ধ আছে (সেটিংস থেকে চালু করতে পারবেন)।',
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('নিজে নামাজের সময় নির্ধারণ করুন'),
                  subtitle: const Text(
                    'চালু করলে প্রতিটি ওয়াক্তের সময় নিজের মতো পরিবর্তন করতে পারবেন',
                  ),
                  value: settings.useCustomPrayerTimes,
                  activeColor: AppTheme.emeraldPrimary,
                  onChanged: (val) => scheduler.updateSettings(
                    settings.copyWith(useCustomPrayerTimes: val),
                  ),
                ),
                if (pauseStatus.isPaused) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'এখন ${pauseStatus.activePrayer?.nameBangla} নামাজের বিরতি চলছে।',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...slots.map((slot) {
          final isNext = slot.nameEnglish == nextPrayer.nameEnglish &&
              slot.startTime.isAtSameMomentAs(nextPrayer.startTime);
          final pauseEnd = slot.startTime
              .add(Duration(minutes: settings.prayerPauseMinutes));
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: isNext ? AppTheme.emeraldPrimary.withOpacity(0.08) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isNext
                    ? AppTheme.emeraldPrimary
                    : AppTheme.emeraldPrimary.withOpacity(0.12),
                child: Icon(
                  Icons.mosque_rounded,
                  color: isNext ? Colors.white : AppTheme.emeraldPrimary,
                ),
              ),
              title: Text(
                '${slot.nameBangla} (${slot.nameEnglish})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: settings.autoPauseOnPrayer
                  ? Text(
                      'জিকির বিরতি: ${DateFormat.jm().format(slot.startTime)} – ${DateFormat.jm().format(pauseEnd)}',
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.jm().format(slot.startTime),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emeraldLight,
                        ),
                  ),
                  if (settings.useCustomPrayerTimes) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'সময় পরিবর্তন করুন',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _pickPrayerTime(
                        context,
                        scheduler,
                        slot.nameEnglish,
                        slot.startTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
