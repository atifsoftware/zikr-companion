import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/zikr_scheduler_service.dart';
import '../theme/app_theme.dart';

class ZikrListScreen extends StatelessWidget {
  const ZikrListScreen({super.key});

  Future<void> _showAddDialog(BuildContext context) async {
    final arabicCtrl = TextEditingController();
    final banglaCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();
    final virtueCtrl = TextEditingController();
    String selectedAudioPath = '';
    String selectedAudioName = '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('নতুন জিকির যোগ করুন'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: arabicCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'আরবি লেখা',
                      hintText: 'যেমন: سُبْحَانَ اللَّهِ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: banglaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'বাংলা উচ্চারণ *',
                      hintText: 'যেমন: সুবহানাল্লাহ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: meaningCtrl,
                    decoration: const InputDecoration(
                      labelText: 'বাংলা অর্থ *',
                      hintText: 'যেমন: আল্লাহ অতি পবিত্র',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: virtueCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ফজিলত (ঐচ্ছিক)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac'],
                      );
                      if (result != null && result.files.single.path != null) {
                        setDialogState(() {
                          selectedAudioPath = result.files.single.path!;
                          selectedAudioName = result.files.single.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.audio_file_rounded),
                    label: Text(
                      selectedAudioName.isEmpty
                          ? 'অডিও ফাইল যুক্ত করুন (MP3/WAV/M4A)'
                          : 'নির্বাচিত: $selectedAudioName',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                if (banglaCtrl.text.trim().isEmpty ||
                    meaningCtrl.text.trim().isEmpty) {
                  return;
                }
                context.read<ZikrSchedulerService>().addCustomZikr(
                      arabic: arabicCtrl.text.trim().isEmpty
                          ? banglaCtrl.text.trim()
                          : arabicCtrl.text.trim(),
                      banglaPronunciation: banglaCtrl.text.trim(),
                      banglaMeaning: meaningCtrl.text.trim(),
                      virtue: virtueCtrl.text.trim(),
                      customAudioPath: selectedAudioPath,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('সংরক্ষণ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = context.watch<ZikrSchedulerService>();
    final items = scheduler.zikrList;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppTheme.emeraldPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন জিকির'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isCurrent = scheduler.currentZikr?.id == item.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isCurrent ? AppTheme.emeraldPrimary.withOpacity(0.08) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.arabic,
                          style: const TextStyle(
                            fontFamily: AppTheme.arabicFontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.banglaPronunciation,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.emeraldLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.banglaMeaning,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (item.virtue.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.virtue,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                        if (item.customAudioPath.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.audiotrack_rounded,
                                  size: 14, color: AppTheme.goldAccent),
                              SizedBox(width: 4),
                              Text(
                                'কাস্টম অডিও যুক্ত আছে',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.goldAccent),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'শুনুন',
                            icon: const Icon(Icons.volume_up_rounded,
                                color: AppTheme.emeraldPrimary),
                            onPressed: () => scheduler.playZikrItem(item),
                          ),
                          if (isCurrent)
                            IconButton(
                              tooltip: 'বন্ধ করুন',
                              icon: const Icon(Icons.stop_circle_outlined,
                                  color: Colors.redAccent),
                              onPressed: scheduler.stopVoice,
                            ),
                          Switch(
                            value: item.isEnabled,
                            activeColor: AppTheme.emeraldPrimary,
                            onChanged: (_) =>
                                scheduler.toggleZikrEnabled(item.id),
                          ),
                        ],
                      ),
                      if (item.isCustom)
                        IconButton(
                          tooltip: 'মুছে ফেলুন',
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => scheduler.deleteCustomZikr(item.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
