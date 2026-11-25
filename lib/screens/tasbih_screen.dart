import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/zikr_scheduler_service.dart';
import '../theme/app_theme.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _sessionCount = 0;
  int _target = 33;
  int _selectedZikrIndex = 0;

  void _increment() {
    setState(() => _sessionCount++);
    if (_target > 0 && _sessionCount % _target == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    context.read<ZikrSchedulerService>().incrementTodayCount(1);
  }

  void _reset() {
    setState(() => _sessionCount = 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = context.watch<ZikrSchedulerService>();
    final items = scheduler.zikrList;
    if (_selectedZikrIndex >= items.length) {
      _selectedZikrIndex = 0;
    }
    final currentZikr = items[_selectedZikrIndex];
    final progress = _target > 0 ? (_sessionCount % _target) / _target : 0.0;
    final displayProgress =
        _sessionCount > 0 && _sessionCount % _target == 0 ? 1.0 : progress;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedZikrIndex,
                        isExpanded: true,
                        items: List.generate(
                          items.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(
                              '${items[i].banglaPronunciation} (${items[i].arabic})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedZikrIndex = val;
                              _sessionCount = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _target,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 33, child: Text('লক্ষ্য: ৩৩')),
                      DropdownMenuItem(value: 99, child: Text('লক্ষ্য: ৯৯')),
                      DropdownMenuItem(value: 100, child: Text('লক্ষ্য: ১০০')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _target = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            currentZikr.arabic,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.arabicFontFamily,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentZikr.banglaPronunciation,
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.emeraldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _increment,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: displayProgress,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.emeraldPrimary.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.goldAccent,
                    ),
                  ),
                ),
                Container(
                  width: 185,
                  height: 185,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.emeraldPrimary, Color(0xFF146C43)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emeraldPrimary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_sessionCount',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ট্যাপ করুন (লক্ষ্য $_target)',
                        style: const TextStyle(
                          color: AppTheme.goldAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('রিসেট'),
              ),
              const SizedBox(width: 16),
              Text(
                'আজকের মোট: ${scheduler.todayCount} বার',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
