import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah_data.dart';
import '../services/quran_player_service.dart';
import '../theme/app_theme.dart';

class QuranRecitationScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const QuranRecitationScreen({super.key, this.onBackToHome});

  @override
  State<QuranRecitationScreen> createState() => _QuranRecitationScreenState();
}

class _QuranRecitationScreenState extends State<QuranRecitationScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showTransliteration = true;
  bool _showTafsir = false;
  int _lastScrolledAyah = -1;
  List<GlobalKey> _ayahKeys = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SurahInfo> get _filteredSurahs {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return SurahInfo.all114;
    return SurahInfo.all114.where((s) {
      return s.number.toString() == q ||
          s.nameBangla.toLowerCase().contains(q) ||
          s.nameArabic.contains(q);
    }).toList();
  }

  void _syncAyahKeysAndScroll(int count, int currentIdx) {
    if (_ayahKeys.length != count) {
      _ayahKeys = List.generate(count, (_) => GlobalKey());
    }
    if (currentIdx != _lastScrolledAyah &&
        currentIdx >= 0 &&
        currentIdx < _ayahKeys.length) {
      _lastScrolledAyah = currentIdx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _ayahKeys[currentIdx].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            alignment: 0.25,
          );
        }
      });
    }
  }

  Widget _buildSurahSidebar(
    BuildContext context,
    QuranPlayerService player,
  ) {
    final filtered = _filteredSurahs;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          right: BorderSide(
            color: AppTheme.emeraldPrimary.withOpacity(0.12),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            child: Row(
              children: [
                if (widget.onBackToHome != null)
                  IconButton(
                    tooltip: 'হোম-এ ফিরুন',
                    onPressed: widget.onBackToHome,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                const Expanded(
                  child: Text(
                    'সকল সূরা (১১৪)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'সূরার নাম বা নম্বর লিখুন...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final surah = filtered[index];
                final isCurrent = player.currentSurah?.number == surah.number;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: isCurrent
                      ? AppTheme.emeraldPrimary.withOpacity(0.12)
                      : null,
                  child: ListTile(
                    dense: true,
                    onTap: () => player.selectSurah(surah),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isCurrent
                          ? AppTheme.emeraldPrimary
                          : AppTheme.emeraldPrimary.withOpacity(0.12),
                      child: Text(
                        '${surah.number}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCurrent
                              ? Colors.white
                              : AppTheme.emeraldPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      surah.nameBangla,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${surah.ayahCount} আয়াত'),
                    trailing: Text(
                      surah.nameArabic,
                      style: const TextStyle(
                        fontFamily: AppTheme.arabicFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMobileHeader(
    BuildContext context,
    QuranPlayerService player,
  ) {
    final ayahs = player.ayahs;
    final currentAyah = player.currentAyah;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.emeraldPrimary, Color(0xFF146C43)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => _openMobileSurahPicker(context, player),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player.currentSurah != null
                            ? '${player.currentSurah!.number}. ${player.currentSurah!.nameBangla}'
                            : 'সূরা বাছুন',
                        style: const TextStyle(
                          color: AppTheme.goldAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.goldAccent, size: 18),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (currentAyah != null)
                Text(
                  'আয়াত ${currentAyah.numberInSurah}/${ayahs.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune_rounded,
                    color: Colors.white, size: 20),
                tooltip: 'অপশন',
                onSelected: (val) {
                  if (val == 'translit') {
                    setState(
                        () => _showTransliteration = !_showTransliteration);
                  } else if (val == 'tafsir') {
                    setState(() => _showTafsir = !_showTafsir);
                  } else if (val == 'qari') {
                    _openMobileQariPicker(context, player);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'qari',
                    child: Text('ক্বারী: ${player.selectedQari.nameBangla}'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'translit',
                    checked: _showTransliteration,
                    child: const Text('উচ্চারণ দেখান'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'tafsir',
                    checked: _showTafsir,
                    child: const Text('তাফসির / ব্যাখ্যা দেখান'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: player.currentAyahIndex > 0
                        ? () => player.playAyahAt(player.currentAyahIndex - 1)
                        : null,
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        player.isLoadingAudio ? null : player.togglePlayPause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldAccent,
                      foregroundColor: AppTheme.emeraldPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: player.isLoadingAudio
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                    label: Text(
                      player.isLoadingAudio
                          ? 'লোড...'
                          : (player.isPlaying ? 'বিরতি' : 'শুনুন'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: player.currentAyahIndex + 1 < ayahs.length
                        ? () => player.playAyahAt(player.currentAyahIndex + 1)
                        : null,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Colors.white),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'বন্ধ করুন',
                    onPressed: player.stop,
                    icon: const Icon(Icons.stop_rounded, color: Colors.white70),
                  ),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: player.isCurrentDownloaded
                    ? 'অফলাইন প্রস্তুত'
                    : 'অফলাইন ডাউনলোড',
                onPressed: (player.isDownloading || ayahs.isEmpty)
                    ? null
                    : player.downloadCurrentSurah,
                icon: player.isDownloading
                    ? Text(
                        '${player.downloadDone}/${player.downloadTotal}',
                        style: const TextStyle(
                            color: AppTheme.goldAccent, fontSize: 11),
                      )
                    : Icon(
                        player.isCurrentDownloaded
                            ? Icons.offline_pin_rounded
                            : Icons.download_rounded,
                        color: player.isCurrentDownloaded
                            ? AppTheme.goldAccent
                            : Colors.white,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openMobileQariPicker(
    BuildContext context,
    QuranPlayerService player,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'ক্বারী নির্বাচন করুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...QariInfo.presets.map(
            (q) => RadioListTile<String>(
              value: q.id,
              groupValue: player.selectedQari.id,
              activeColor: AppTheme.emeraldPrimary,
              title: Text(q.nameBangla),
              subtitle: Text(q.nameEnglish),
              onChanged: (_) {
                Navigator.pop(ctx);
                player.setQari(q);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahReaderPane(
    BuildContext context,
    QuranPlayerService player, {
    required bool isCompact,
  }) {
    final ayahs = player.ayahs;
    final currentAyah = player.currentAyah;
    _syncAyahKeysAndScroll(ayahs.length, player.currentAyahIndex);

    return Column(
      children: [
        if (isCompact)
          _buildCompactMobileHeader(context, player)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.emeraldPrimary, Color(0xFF146C43)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isCompact && widget.onBackToHome != null)
                      IconButton(
                        tooltip: 'হোম-এ ফিরুন',
                        onPressed: widget.onBackToHome,
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: player.selectedQari.id,
                          dropdownColor: AppTheme.emeraldPrimary,
                          iconEnabledColor: AppTheme.goldAccent,
                          isExpanded: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.banglaFontFamily,
                          ),
                          items: QariInfo.presets
                              .map(
                                (q) => DropdownMenuItem(
                                  value: q.id,
                                  child: Text(
                                    q.nameBangla,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            if (id == null) return;
                            final q = QariInfo.presets.firstWhere(
                              (e) => e.id == id,
                            );
                            player.setQari(q);
                          },
                        ),
                      ),
                    ),
                    if (player.isCurrentDownloaded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.offline_pin_rounded,
                                color: AppTheme.goldAccent, size: 15),
                            SizedBox(width: 4),
                            Text(
                              'অফলাইন প্রস্তুত',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (player.currentSurah != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'সূরা ${player.currentSurah!.nameBangla} (${player.currentSurah!.nameArabic})',
                          style: const TextStyle(
                            color: AppTheme.goldAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (currentAyah != null)
                        Text(
                          'আয়াত ${currentAyah.numberInSurah} / ${ayahs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            player.isLoadingAudio ? null : player.togglePlayPause,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldAccent,
                          foregroundColor: AppTheme.emeraldPrimary,
                        ),
                        icon: player.isLoadingAudio
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                        label: Text(
                          player.isLoadingAudio
                              ? 'লোড হচ্ছে...'
                              : (player.isPlaying ? 'বিরতি' : 'চালু করুন'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: player.currentAyahIndex > 0
                            ? () => player.playAyahAt(player.currentAyahIndex - 1)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        icon: const Icon(Icons.skip_previous_rounded),
                        label: const Text('আগের'),
                      ),
                      OutlinedButton.icon(
                        onPressed: player.currentAyahIndex + 1 < ayahs.length
                            ? () => player.playAyahAt(player.currentAyahIndex + 1)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('পরের'),
                      ),
                      OutlinedButton.icon(
                        onPressed: player.stop,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('বন্ধ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: (player.isDownloading || ayahs.isEmpty)
                            ? null
                            : player.downloadCurrentSurah,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        icon: Icon(player.isCurrentDownloaded
                            ? Icons.download_done_rounded
                            : Icons.download_rounded),
                        label: Text(
                          player.isDownloading
                              ? '${player.downloadDone}/${player.downloadTotal}'
                              : (player.isCurrentDownloaded
                                  ? 'ডাউনলোড করা'
                                  : 'অফলাইন ডাউনলোড'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (player.errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    player.errorText!,
                    style: const TextStyle(
                        color: Colors.amberAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!isCompact && player.currentSurah != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              children: [
                const Text(
                  'আয়াতে ক্লিক করে তিলাওয়াত শুনুন',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('উচ্চারণ', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _showTransliteration,
                      activeColor: AppTheme.emeraldPrimary,
                      onChanged: (v) =>
                          setState(() => _showTransliteration = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('তাফসির / ব্যাখ্যা',
                        style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _showTafsir,
                      activeColor: AppTheme.emeraldPrimary,
                      onChanged: (v) => setState(() => _showTafsir = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: player.isLoadingText
              ? const Center(child: CircularProgressIndicator())
              : player.textError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          player.textError!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: ayahs.length,
                      itemBuilder: (context, index) {
                        final ayah = ayahs[index];
                        final isHighlighted = index == player.currentAyahIndex;

                        return InkWell(
                          key: index < _ayahKeys.length
                              ? _ayahKeys[index]
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => player.playAyahAt(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? AppTheme.emeraldPrimary.withOpacity(0.10)
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHighlighted
                                    ? AppTheme.goldAccent
                                    : Colors.grey.withOpacity(0.18),
                                width: isHighlighted ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isHighlighted
                                          ? AppTheme.emeraldPrimary
                                          : AppTheme.emeraldPrimary
                                              .withOpacity(0.12),
                                      child: Text(
                                        '${ayah.numberInSurah}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isHighlighted
                                              ? Colors.white
                                              : AppTheme.emeraldPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ayah.arabic,
                                        textAlign: TextAlign.right,
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.arabicFontFamily,
                                          fontSize: 28,
                                          height: 1.95,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_showTransliteration &&
                                    ayah.transliteration.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'উচ্চারণ: ${ayah.transliteration}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.emeraldLight,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  ayah.banglaTranslation,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontFamily:
                                            AppTheme.banglaSerifFontFamily,
                                        fontSize: 15.5,
                                        height: 1.6,
                                      ),
                                ),
                                if (_showTafsir &&
                                    ayah.banglaTafsir.isNotEmpty &&
                                    ayah.banglaTafsir !=
                                        ayah.banglaTranslation) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.goldAccent.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ব্যাখ্যামূলক অনুবাদ (ড. জহুরুল হক):',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.emeraldLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ayah.banglaTafsir,
                                          style: const TextStyle(
                                            fontFamily:
                                                AppTheme.banglaSerifFontFamily,
                                            fontSize: 14,
                                            height: 1.55,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _openMobileSurahPicker(
    BuildContext context,
    QuranPlayerService player,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => StatefulBuilder(
          builder: (ctx, setModalState) {
            final q = _searchCtrl.text.trim().toLowerCase();
            final list = q.isEmpty
                ? SurahInfo.all114
                : SurahInfo.all114.where((s) {
                    return s.number.toString() == q ||
                        s.nameBangla.toLowerCase().contains(q) ||
                        s.nameArabic.contains(q);
                  }).toList();

            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: '১১৪টি সূরা থেকে খুঁজুন...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: list.length,
                    itemBuilder: (_, idx) {
                      final surah = list[idx];
                      final isCurrent =
                          player.currentSurah?.number == surah.number;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrent
                              ? AppTheme.emeraldPrimary
                              : AppTheme.emeraldPrimary.withOpacity(0.12),
                          child: Text(
                            '${surah.number}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrent
                                  ? Colors.white
                                  : AppTheme.emeraldPrimary,
                            ),
                          ),
                        ),
                        title: Text(
                          surah.nameBangla,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${surah.ayahCount} আয়াত'),
                        trailing: Text(
                          surah.nameArabic,
                          style: const TextStyle(
                            fontFamily: AppTheme.arabicFontFamily,
                            fontSize: 18,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          player.selectSurah(surah);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<QuranPlayerService>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 780;
        if (isWide) {
          return Row(
            children: [
              SizedBox(
                width: 310,
                child: _buildSurahSidebar(context, player),
              ),
              Expanded(
                child: _buildAyahReaderPane(context, player, isCompact: false),
              ),
            ],
          );
        }

        return _buildAyahReaderPane(context, player, isCompact: true);
      },
    );
  }
}
