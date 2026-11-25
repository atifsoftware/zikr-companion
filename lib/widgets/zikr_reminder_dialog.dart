import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zikr_item.dart';
import '../services/zikr_scheduler_service.dart';
import '../theme/app_theme.dart';

class ZikrReminderDialog extends StatefulWidget {
  final ZikrItem item;
  final int targetRepeat;

  const ZikrReminderDialog({
    super.key,
    required this.item,
    required this.targetRepeat,
  });

  @override
  State<ZikrReminderDialog> createState() => _ZikrReminderDialogState();
}

class _ZikrReminderDialogState extends State<ZikrReminderDialog> {
  int _completed = 0;
  bool _autoCloseScheduled = false;
  Timer? _silentAutoCloseTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceOn = context.read<ZikrSchedulerService>().settings.voiceEnabled;
      if (!voiceOn) {
        _silentAutoCloseTimer = Timer(const Duration(seconds: 8), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _silentAutoCloseTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoClose() {
    if (_autoCloseScheduled) return;
    _autoCloseScheduled = true;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _tapRecite() {
    if (_completed >= widget.targetRepeat) return;
    setState(() => _completed++);
    context.read<ZikrSchedulerService>().incrementTodayCount(1);

    if (_completed >= widget.targetRepeat) {
      _scheduleAutoClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final scheduler = context.watch<ZikrSchedulerService>();
    final displayCompleted = scheduler.reminderProgress > _completed
        ? scheduler.reminderProgress
        : _completed;
    final progress =
        widget.targetRepeat > 0 ? displayCompleted / widget.targetRepeat : 1.0;

    if (displayCompleted >= widget.targetRepeat) {
      _scheduleAutoClose();
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.emeraldPrimary,
                AppTheme.emeraldPrimary.withOpacity(0.90),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.goldAccent.withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        'জিকিরের সময়',
                        style: TextStyle(
                          color: AppTheme.goldAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        context.read<ZikrSchedulerService>().stopVoice();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 10 : 14),
                Text(
                  widget.item.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTheme.arabicFontFamily,
                    fontSize: isMobile ? 25 : 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  widget.item.banglaPronunciation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 19,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.banglaMeaning,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
                if (widget.item.virtue.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.item.virtue,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.goldAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$displayCompleted / ${widget.targetRepeat} বার পড়া হয়েছে',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _tapRecite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldAccent,
                      foregroundColor: AppTheme.emeraldPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.touch_app_rounded, size: 19),
                    label: Text(
                      displayCompleted >= widget.targetRepeat
                          ? 'মাশাআল্লাহ! সম্পন্ন'
                          : (scheduler.settings.voiceEnabled
                              ? 'শোনা শেষ হলে অটো বন্ধ হবে'
                              : 'পড়েছি (ট্যাপ করুন)'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
