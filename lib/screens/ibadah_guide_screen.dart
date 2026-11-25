import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../services/zikr_scheduler_service.dart';
import '../theme/app_theme.dart';

class IbadahGuideScreen extends StatelessWidget {
  const IbadahGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.emeraldPrimary.withOpacity(0.14),
              ),
            ),
            child: const TabBar(
              indicatorColor: AppTheme.emeraldPrimary,
              labelColor: AppTheme.emeraldPrimary,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(icon: Icon(Icons.explore_rounded), text: 'ক্বিবলা'),
                Tab(icon: Icon(Icons.water_drop_rounded), text: 'অযু গাইড'),
                Tab(icon: Icon(Icons.mosque_rounded), text: 'নামাজ গাইড'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _QiblaTab(),
                _WuduTab(),
                _SalahTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaTab extends StatelessWidget {
  const _QiblaTab();

  // Kaaba coordinates: 21.4225° N, 39.8262° E
  static double calculateQiblaBearing(double latDeg, double lonDeg) {
    const kaabaLat = 21.4225 * math.pi / 180.0;
    const kaabaLon = 39.8262 * math.pi / 180.0;
    final lat = latDeg * math.pi / 180.0;
    final lon = lonDeg * math.pi / 180.0;

    final dLon = kaabaLon - lon;
    final y = math.sin(dLon) * math.cos(kaabaLat);
    final x = math.cos(lat) * math.sin(kaabaLat) -
        math.sin(lat) * math.cos(kaabaLat) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  String _compassDirectionBangla(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'উত্তর';
    if (deg < 67.5) return 'উত্তর-পূর্ব';
    if (deg < 112.5) return 'পূর্ব';
    if (deg < 157.5) return 'দক্ষিণ-পূর্ব';
    if (deg < 202.5) return 'দক্ষিণ';
    if (deg < 247.5) return 'দক্ষিণ-পশ্চিম';
    if (deg < 292.5) return 'পশ্চিম';
    return 'উত্তর-পশ্চিম';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ZikrSchedulerService>().settings;
    final qiblaAngle =
        calculateQiblaBearing(settings.latitude, settings.longitude);
    final dirLabel = _compassDirectionBangla(qiblaAngle);
    final isMobileSensorSupported =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'ক্বিবলার দিক (${settings.cityName})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '${qiblaAngle.toStringAsFixed(1)}° ($dirLabel)',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emeraldLight,
                  ),
                ),
                const SizedBox(height: 24),
                if (isMobileSensorSupported)
                  StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      final heading = snapshot.data?.heading;
                      if (heading == null) {
                        return _StaticCompassDial(qiblaAngle: qiblaAngle);
                      }
                      final needleRad =
                          (qiblaAngle - heading) * (math.pi / 180.0);
                      return Column(
                        children: [
                          _CompassDial(needleAngleRad: needleRad),
                          const SizedBox(height: 14),
                          const Text(
                            'সোনালি তীরটি ক্বিবলা (পবিত্র কাবা শরীফ)-এর দিক নির্দেশ করছে।',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  )
                else ...[
                  _StaticCompassDial(qiblaAngle: qiblaAngle),
                  const SizedBox(height: 14),
                  Text(
                    'আপনার শহর থেকে ক্বিবলা উত্তর দিকের সাপেক্ষে ${qiblaAngle.toStringAsFixed(1)}° ($dirLabel) কোণে অবস্থিত।',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StaticCompassDial extends StatelessWidget {
  final double qiblaAngle;
  const _StaticCompassDial({required this.qiblaAngle});

  @override
  Widget build(BuildContext context) {
    return _CompassDial(needleAngleRad: qiblaAngle * math.pi / 180.0);
  }
}

class _CompassDial extends StatelessWidget {
  final double needleAngleRad;
  const _CompassDial({required this.needleAngleRad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.emeraldPrimary.withOpacity(0.08),
              border: Border.all(
                color: AppTheme.emeraldPrimary.withOpacity(0.35),
                width: 3,
              ),
            ),
          ),
          const Positioned(
            top: 10,
            child: Text('উত্তর (N)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const Positioned(
            bottom: 10,
            child: Text('দক্ষিণ (S)', style: TextStyle(fontSize: 11)),
          ),
          const Positioned(
            right: 10,
            child: Text('পূর্ব', style: TextStyle(fontSize: 11)),
          ),
          const Positioned(
            left: 10,
            child: Text('পশ্চিম', style: TextStyle(fontSize: 11)),
          ),
          Transform.rotate(
            angle: needleAngleRad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.navigation_rounded,
                  size: 64,
                  color: AppTheme.goldAccent,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'কাবা',
                    style: TextStyle(
                      color: AppTheme.goldAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WuduTab extends StatelessWidget {
  const _WuduTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _GuideCard(
          title: 'অযুর ৪টি ফরজ',
          items: [
            '১. সমস্ত মুখমণ্ডল ধৌত করা (কপালের চুলের গোড়া থেকে থুতনির নিচ পর্যন্ত এবং এক কানের লতি থেকে অন্য কানের লতি পর্যন্ত)।',
            '২. উভয় হাত কনুইসহ ধৌত করা।',
            '৩. মাথার এক-চতুর্থাংশ মাসেহ করা।',
            '৪. উভয় পা টাখনুসহ ধৌত করা।',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          title: 'অযু করার সুন্নত পদ্ধতি',
          items: [
            '• বিসমিল্লাহ বলে শুরু করা ও নিয়ত করা।',
            '• উভয় হাত কব্জি পর্যন্ত ৩ বার ধোয়া।',
            '• মিসওয়াক করা ও ৩ বার কুলি করা।',
            '• ৩ বার নাকে পানি দিয়ে পরিষ্কার করা।',
            '• প্রতিটি অঙ্গ ৩ বার করে ধোয়া এবং আঙুল ও দাড়ি খিলাল করা।',
            '• অযু শেষে কালেমায়ে শাহাদাত পাঠ করা।',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          title: 'অযু ভঙ্গের প্রধান কারণসমূহ',
          items: [
            '• পায়খানা-পেশাব বা বায়ু নির্গত হওয়া।',
            '• শরীরের কোনো স্থান থেকে রক্ত বা পুঁজ বের হয়ে গড়িয়ে পড়া।',
            '• মুখ ভরে বমি হওয়া।',
            '• হেলান দিয়ে বা শুয়ে ঘুমিয়ে পড়া।',
          ],
        ),
      ],
    );
  }
}

class _SalahTab extends StatelessWidget {
  const _SalahTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _GuideCard(
          title: '৫ ওয়াক্ত নামাজের রাকাত সংখ্যা',
          items: [
            '• ফজর: ২ রাকাত সুন্নত + ২ রাকাত ফরজ (মোট ৪ রাকাত)',
            '• যোহর: ৪ রাকাত সুন্নত + ৪ রাকাত ফরজ + ২ রাকাত সুন্নত + ২ রাকাত নফল',
            '• আসর: ৪ রাকাত সুন্নত (গাইরে মুয়াক্কাদাহ) + ৪ রাকাত ফরজ',
            '• মাগরিব: ৩ রাকাত ফরজ + ২ রাকাত সুন্নত + ২ রাকাত নফল',
            '• এশা: ৪ রাকাত ফরজ + ২ রাকাত সুন্নত + ৩ রাকাত বিতর',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          title: 'নামাজের ভেতরের ফরজ (রুকন)',
          items: [
            '১. তাকবীরে তাহরীমা (আল্লাহু আকবার বলে নামাজ শুরু করা)।',
            '২. কিয়াম (দাঁড়িয়ে নামাজ পড়া)।',
            '৩. কিরাত (কুরআন থেকে পাঠ করা)।',
            '৪. রুকু করা।',
            '৫. সিজদা করা (প্রতি রাকাতে ২টি সিজদা)।',
            '৬. শেষ বৈঠক (তাশাহহুদ পরিমাণ সময় বসা)।',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          title: 'রুকু ও সিজদার তাসবিহ',
          items: [
            '• রুকুর তাসবিহ (৩ বা ৫ বার): সুবহানা রাব্বিয়াল আযীম (سُبْحَانَ رَبِّيَ الْعَظِيمِ)',
            '• রুকু থেকে ওঠার সময়: সামিআল্লাহু লিমান হামিদাহ, রাব্বানা লাকাল হামদ।',
            '• সিজদার তাসবিহ (৩ বা ৫ বার): সুবহানা রাব্বিয়াল আ’লা (سُبْحَانَ رَبِّيَ الْأَعْلَىٰ)',
          ],
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _GuideCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emeraldLight,
                  ),
            ),
            const Divider(),
            ...items.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  line,
                  style: const TextStyle(height: 1.55, fontSize: 14.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
