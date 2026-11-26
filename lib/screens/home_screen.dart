import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/daily_inspiration.dart';
import '../services/zikr_scheduler_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _showIntervalPicker(
    BuildContext context,
    ZikrSchedulerService scheduler,
  ) async {
    int selected = scheduler.settings.intervalMinutes;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('রিমাইন্ডার বিরতি নির্ধারণ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('প্রতি $selected মিনিট পর পর জিকির আসবে'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 15, 20, 30, 45, 60]
                    .map(
                      (m) => ChoiceChip(
                        label: Text('$m মি.'),
                        selected: selected == m,
                        selectedColor:
                            AppTheme.emeraldPrimary.withOpacity(0.18),
                        onSelected: (_) => setDialogState(() => selected = m),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Slider(
                value: selected.toDouble().clamp(1, 120),
                min: 1,
                max: 120,
                divisions: 119,
                label: '$selected মিনিট',
                activeColor: AppTheme.emeraldPrimary,
                onChanged: (v) =>
                    setDialogState(() => selected = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                scheduler.updateSettings(
                  scheduler.settings.copyWith(intervalMinutes: selected),
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = context.watch<ZikrSchedulerService>();
    final settings = scheduler.settings;
    final prayerPause = scheduler.currentPrayerPause;
    final nextPrayer = scheduler.nextPrayer;
    final hijri = scheduler.hijriDate;
    final islamicReminders = scheduler.todayIslamicReminders;
    final enabledZikr = scheduler.enabledZikrList;
    final featuredZikr = scheduler.currentZikr ??
        (enabledZikr.isNotEmpty ? enabledZikr.first : null);
    final goalProgress = settings.dailyGoal > 0
        ? (scheduler.todayCount / settings.dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final stats = scheduler.last7DaysStats;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _HeroStatusCard(
          hijriDateText: hijri.formattedBangla,
          gregorianDateText: DateFormat('EEE, d MMM').format(DateTime.now()),
          isActive: settings.isReminderActive,
          isPrayerPaused: prayerPause.isPaused,
          isQuietHours: scheduler.isQuietHours,
          activePrayerName: prayerPause.activePrayer?.nameBangla,
          remainingPause: prayerPause.remainingPause,
          timeUntilNext: scheduler.timeUntilNextReminder,
          formatDuration: _formatDuration,
          onToggleActive: scheduler.toggleReminderActive,
          onTriggerNow: () =>
              scheduler.triggerZikrNow(ignorePrayerPause: true),
        ),
        if (onNavigateTab != null) ...[
          const SizedBox(height: 14),
          _QuickActionsRow(onNavigateTab: onNavigateTab!),
        ],
        if (settings.showRamadanCard) ...[
          const SizedBox(height: 14),
          _RamadanFastingCard(
            sehriEnd: scheduler.todaySehriIftar.sehriEnd,
            iftarTime: scheduler.todaySehriIftar.iftarTime,
            isRamadanMonth: hijri.month == 9,
            formatDuration: _formatDuration,
          ),
        ],
        if (islamicReminders.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: islamicReminders
                .map(
                  (msg) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.goldAccent.withOpacity(0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppTheme.goldAccent, size: 17),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            msg,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 640;
            final cards = [
              _StatCard(
                icon: Icons.favorite_rounded,
                iconColor: AppTheme.goldAccent,
                title: 'আজকের জিকির',
                value: '${scheduler.todayCount} / ${settings.dailyGoal}',
                subtitle: 'স্ট্রিক: ${scheduler.currentStreak} দিন',
              ),
              _StatCard(
                icon: Icons.timer_outlined,
                iconColor: AppTheme.emeraldLight,
                title: 'রিমাইন্ডার বিরতি (ট্যাপ করে বদলান)',
                value: '${settings.intervalMinutes} মিনিট',
                subtitle: 'সক্রিয় জিকির: ${enabledZikr.length} টি',
                onTap: () => _showIntervalPicker(context, scheduler),
              ),
              _StatCard(
                icon: Icons.mosque_rounded,
                iconColor: Colors.teal,
                title: 'পরবর্তী (${nextPrayer.nameBangla})',
                value: DateFormat.jm().format(nextPrayer.startTime),
                subtitle: settings.autoPauseOnPrayer
                    ? 'অটো-পজ: ${settings.prayerPauseMinutes} মিনিট'
                    : 'অটো-পজ বন্ধ আছে',
              ),
            ];

            if (isWide) {
              return Row(
                children: cards
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: c,
                          ),
                        ))
                    .toList(),
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[2]),
                  ],
                ),
                const SizedBox(height: 10),
                cards[1],
              ],
            );
          },
        ),
        if (featuredZikr != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome,
                                color: AppTheme.goldAccent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'এখনকার নির্বাচিত জিকির',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        tooltip: 'শুনুন',
                        onPressed: () => scheduler.playZikrItem(featuredZikr),
                        icon: const Icon(Icons.volume_up_rounded,
                            color: AppTheme.emeraldPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.goldAccent.withOpacity(0.28),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          featuredZikr.arabic,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: AppTheme.arabicFontFamily,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          featuredZikr.banglaPronunciation,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.emeraldLight,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          featuredZikr.banglaMeaning,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: AppTheme.banglaSerifFontFamily,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'দৈনিক লক্ষ্য ও ৭ দিনের হিসাব',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldPrimary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(goalProgress * 100).round()}% সম্পন্ন',
                        style: const TextStyle(
                          color: AppTheme.emeraldLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goalProgress,
                    minHeight: 8,
                    backgroundColor: AppTheme.emeraldPrimary.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.emeraldLight,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _WeeklyBarChart(stats: stats, goal: settings.dailyGoal),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (scheduler.activeAnnouncement != null) ...[
          Card(
            color: AppTheme.emeraldPrimary.withValues(alpha: 0.08),
            child: ListTile(
              leading: const Icon(Icons.notifications_active_rounded,
                  color: AppTheme.goldAccent),
              title: Text(
                scheduler.activeAnnouncement!.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(scheduler.activeAnnouncement!.body),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: scheduler.dismissAnnouncement,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _DailyInspirationCard(
          items: scheduler.inspirations,
        ),
      ],
    );
  }
}

class _RamadanFastingCard extends StatelessWidget {
  final DateTime sehriEnd;
  final DateTime iftarTime;
  final bool isRamadanMonth;
  final String Function(Duration) formatDuration;

  const _RamadanFastingCard({
    required this.sehriEnd,
    required this.iftarTime,
    required this.isRamadanMonth,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String countdownText;
    if (now.isBefore(sehriEnd)) {
      countdownText =
          'সেহরির শেষ সময় হতে বাকি: ${formatDuration(sehriEnd.difference(now))}';
    } else if (now.isBefore(iftarTime)) {
      countdownText =
          'ইফতারের সময় হতে বাকি: ${formatDuration(iftarTime.difference(now))}';
    } else {
      countdownText = 'আজকের ইফতার সম্পন্ন হয়েছে';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.nightlight_round,
                        color: AppTheme.goldAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isRamadanMonth
                          ? 'মাহে রমজান — সেহরি ও ইফতার'
                          : 'রোজা ও সেহরি-ইফতার সময়সূচি',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('সেহরির শেষ সময়',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.jm().format(sehriEnd),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.emeraldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ইফতারের সময়',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.jm().format(iftarTime),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB8860B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              countdownText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.emeraldLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyInspirationCard extends StatefulWidget {
  final List<DailyInspiration> items;

  const _DailyInspirationCard({required this.items});

  @override
  State<_DailyInspirationCard> createState() => _DailyInspirationCardState();
}

class _DailyInspirationCardState extends State<_DailyInspirationCard> {
  int _currentIndex = 0;

  void _nextInspiration() {
    if (widget.items.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.items.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.items.isNotEmpty ? widget.items : DailyInspiration.items;
    final inspiration = list[_currentIndex % list.length];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: AppTheme.goldAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'আজকের বাণী (কুরআন ও হাদিস)',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _nextInspiration,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.emeraldLight,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text(
                    'অন্য বাণী',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              inspiration.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: AppTheme.arabicFontFamily,
                fontSize: 22,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              inspiration.bangla,
              style: const TextStyle(
                fontFamily: AppTheme.banglaSerifFontFamily,
                fontSize: 15,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '— ${inspiration.reference}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.emeraldLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const _QuickActionsRow({required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.touch_app_rounded,
        label: 'তসবিহ',
        color: AppTheme.emeraldPrimary,
        tabIndex: 2,
      ),
      (
        icon: Icons.headphones_rounded,
        label: 'তিলাওয়াত',
        color: Colors.teal,
        tabIndex: 4,
      ),
      (
        icon: Icons.volunteer_activism_rounded,
        label: 'মাসনূন দোয়া',
        color: const Color(0xFFB8860B),
        tabIndex: 3,
      ),
      (
        icon: Icons.mosque_rounded,
        label: 'নামাজের সময়',
        color: const Color(0xFF146C43),
        tabIndex: 5,
      ),
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onNavigateTab(a.tabIndex),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: a.color.withOpacity(0.16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon, color: a.color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyZikrStat> stats;
  final int goal;

  const _WeeklyBarChart({required this.stats, required this.goal});

  @override
  Widget build(BuildContext context) {
    final maxCount = stats.fold<int>(
      goal > 0 ? goal : 10,
      (prev, s) => s.count > prev ? s.count : prev,
    );

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: stats.map((s) {
          final ratio =
              maxCount > 0 ? (s.count / maxCount).clamp(0.05, 1.0) : 0.05;
          final dayLabel = DateFormat.E().format(s.date);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${s.count}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: ratio,
                    child: Container(
                      width: 18,
                      decoration: BoxDecoration(
                        color: s.count >= goal
                            ? AppTheme.goldAccent
                            : AppTheme.emeraldLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayLabel,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  final String hijriDateText;
  final String gregorianDateText;
  final bool isActive;
  final bool isPrayerPaused;
  final bool isQuietHours;
  final String? activePrayerName;
  final Duration? remainingPause;
  final Duration timeUntilNext;
  final String Function(Duration) formatDuration;
  final VoidCallback onToggleActive;
  final VoidCallback onTriggerNow;

  const _HeroStatusCard({
    required this.hijriDateText,
    required this.gregorianDateText,
    required this.isActive,
    required this.isPrayerPaused,
    required this.isQuietHours,
    required this.activePrayerName,
    required this.remainingPause,
    required this.timeUntilNext,
    required this.formatDuration,
    required this.onToggleActive,
    required this.onTriggerNow,
  });

  @override
  Widget build(BuildContext context) {
    String statusTitle;
    String statusSubtitle;

    if (!isActive) {
      statusTitle = 'জিকির রিমাইন্ডার বিরতিতে আছে';
      statusSubtitle = 'আবার চালু করতে নিচের বাটনে ক্লিক করুন';
    } else if (isQuietHours) {
      statusTitle = 'নীরব সময় (Quiet Hours) চলছে';
      statusSubtitle = 'নির্ধারিত নীরব সময় শেষে রিমাইন্ডার চালু হবে';
    } else if (isPrayerPaused) {
      statusTitle = '$activePrayerName নামাজের সময় — অটো-পজ চলছে';
      statusSubtitle =
          'আরও ${formatDuration(remainingPause ?? Duration.zero)} পর জিকির চালু হবে';
    } else {
      statusTitle = 'জিকির রিমাইন্ডার চালু আছে';
      statusSubtitle =
          'পরবর্তী জিকির আসবে: ${formatDuration(timeUntilNext)} পর';
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A3D25),
            AppTheme.emeraldPrimary,
            Color(0xFF198754),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emeraldPrimary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(
              Icons.mosque_rounded,
              size: 140,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: TextStyle(
                        fontFamily: AppTheme.arabicFontFamily,
                        color: AppTheme.goldAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$hijriDateText • $gregorianDateText',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  statusTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14.5),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onTriggerNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: AppTheme.emeraldPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_active_rounded),
                      label: const Text(
                        'এখনই জিকির দেখান',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onToggleActive,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(isActive ? 'বিরতি দিন' : 'চালু করুন'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
