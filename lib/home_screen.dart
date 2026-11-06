import 'package:flutter/material.dart';
import 'coterie_style_guide.dart';

class VocabularyEntry {
  final String id;
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String definition;
  final String citation;
  bool isSaved;

  VocabularyEntry({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.definition,
    required this.citation,
    this.isSaved = false,
  });
}

/// Raw minimalist home screen for learning and saving vocabulary.
/// Moodboard synthesis:
/// 1. News Articles: Broadsheet masthead, dateline strip, hairlines, lead dispatch column.
/// 2. Modern Art Era Brutalism / Raw Minimalism: Exposed 1px structural grid, zero border radius,
///    stark black ink (#141312) on gallery white (#FFFFFF) and newsprint cream (#F3F0E8).
/// 3. Academic HTML Webpages: Section markers (§ 1, § 2), bracketed anchor links ([save], [next ->]),
///    numbered tabular index, and zero ornamental chrome.
class CoterieHomeScreen extends StatefulWidget {
  final VoidCallback? onReturnToTicket;

  const CoterieHomeScreen({
    super.key,
    this.onReturnToTicket,
  });

  @override
  State<CoterieHomeScreen> createState() => _CoterieHomeScreenState();
}

class _CoterieHomeScreenState extends State<CoterieHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _activeWordIndex = 0;
  bool _showSavedOnly = false;
  String _searchQuery = '';

  final List<VocabularyEntry> _entries = [
    VocabularyEntry(
      id: '01',
      word: 'Velleity',
      phonetic: '/vɛˈliː.ɪ.ti/',
      partOfSpeech: 'n.',
      definition: 'A wish or inclination too slight to lead to action.',
      citation: '“His ambition remained a quiet velleity, sketched only in margins.”',
      isSaved: true,
    ),
    VocabularyEntry(
      id: '02',
      word: 'Apricity',
      phonetic: '/əˈprɪs.ɪ.ti/',
      partOfSpeech: 'n.',
      definition: 'The warmth of the sun in winter.',
      citation: '“Afternoon apricity rested against the cold limestone facade.”',
      isSaved: true,
    ),
    VocabularyEntry(
      id: '03',
      word: 'Noctivagant',
      phonetic: '/nɒkˈtɪv.ə.ɡənt/',
      partOfSpeech: 'adj.',
      definition: 'Wandering or going about in the night.',
      citation: '“Noctivagant scholars crossed the quadrangle after midnight.”',
      isSaved: false,
    ),
    VocabularyEntry(
      id: '04',
      word: 'Psithurism',
      phonetic: '/ˈsɪθ.jʊ.rɪ.zəm/',
      partOfSpeech: 'n.',
      definition: 'The sound of wind rustling through trees and leaves.',
      citation: '“Only the psithurism of the lombardy poplars broke the silence.”',
      isSaved: true,
    ),
    VocabularyEntry(
      id: '05',
      word: 'Sciamachy',
      phonetic: '/saɪˈæm.ə.ki/',
      partOfSpeech: 'n.',
      definition: 'Act of fighting with a shadow; a futile or imaginary combat.',
      citation: '“Much of the treatise was mere sciamachy against an absent critic.”',
      isSaved: false,
    ),
    VocabularyEntry(
      id: '06',
      word: 'Susurrus',
      phonetic: '/sʊˈsʌr.əs/',
      partOfSpeech: 'n.',
      definition: 'A low, indistinct whispering or murmuring sound.',
      citation: '“A dry susurrus of turning folio pages filled the reading room.”',
      isSaved: false,
    ),
  ];

  List<VocabularyEntry> get _filteredEntries {
    return _entries.where((entry) {
      if (_showSavedOnly && !entry.isSaved) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return entry.word.toLowerCase().contains(q) ||
          entry.definition.toLowerCase().contains(q);
    }).toList();
  }

  void _cycleNextWord() {
    setState(() {
      _activeWordIndex = (_activeWordIndex + 1) % _entries.length;
    });
  }

  void _toggleSaved(VocabularyEntry entry) {
    setState(() {
      entry.isSaved = !entry.isSaved;
    });
  }

  Future<void> _openAddWordDialog() async {
    final wordCtrl = TextEditingController();
    final phoneticCtrl = TextEditingController();
    final defCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: CoterieColors.galleryWhite,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: CoterieColors.inkPrimary, width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '§ 3. APPEND NEW ENTRY',
                        style: CoterieTypography.receiptMeta,
                      ),
                      _AcademicBracketLink(
                        label: '[close ×]',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: CoterieColors.inkPrimary,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: wordCtrl,
                    autofocus: true,
                    style: CoterieTypography.headwordSerif,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'HEADWORD',
                      labelStyle: CoterieTypography.receiptMeta,
                      hintText: 'e.g. Petrichor',
                      hintStyle: TextStyle(
                        fontFamily: CoterieTypography.bodySerifFamily,
                        fontSize: 18,
                        color: CoterieColors.inkMuted,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: CoterieColors.inkPrimary),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: CoterieColors.inkPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneticCtrl,
                    style: CoterieTypography.receiptMeta,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'PHONETIC / POS (OPTIONAL)',
                      labelStyle: CoterieTypography.receiptMeta,
                      hintText: '/ˈpɛt.rɪ.kɔːr/',
                      hintStyle: TextStyle(
                        fontFamily: CoterieTypography.receiptMonoFamily,
                        fontSize: 11,
                        color: CoterieColors.inkMuted,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: CoterieColors.inkPrimary),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: CoterieColors.inkPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: defCtrl,
                    style: const TextStyle(
                      fontFamily: CoterieTypography.bodySerifFamily,
                      fontSize: 15.5,
                      color: CoterieColors.inkPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'DEFINITION',
                      labelStyle: CoterieTypography.receiptMeta,
                      hintText: 'Concise lexical definition...',
                      hintStyle: TextStyle(
                        fontFamily: CoterieTypography.bodySerifFamily,
                        fontSize: 15,
                        color: CoterieColors.inkMuted,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: CoterieColors.inkPrimary),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: CoterieColors.inkPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: CoterieBezelButton(
                      label: 'COMMIT TO INDEX',
                      trailingGlyph: '↵',
                      width: 236,
                      height: 46,
                      onPressed: () {
                        final w = wordCtrl.text.trim();
                        final d = defCtrl.text.trim();
                        if (w.isNotEmpty && d.isNotEmpty) {
                          setState(() {
                            final nextNum = (_entries.length + 1)
                                .toString()
                                .padLeft(2, '0');
                            _entries.insert(
                              0,
                              VocabularyEntry(
                                id: nextNum,
                                word: w,
                                phonetic: phoneticCtrl.text.trim().isEmpty
                                    ? '/—/'
                                    : phoneticCtrl.text.trim(),
                                partOfSpeech: 'n.',
                                definition: d,
                                citation: '“Recorded in personal lexicon.”',
                                isSaved: true,
                              ),
                            );
                            _activeWordIndex = 0;
                          });
                        }
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = _entries[_activeWordIndex % _entries.length];
    final savedCount = _entries.where((e) => e.isSaved).length;
    final visibleList = _filteredEntries;

    return Scaffold(
      backgroundColor: CoterieColors.galleryWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==========================================================
                  // 1. NEWSPRINT BROADSHEET MASTHEAD & ACADEMIC HEADER
                  // ==========================================================
                  Container(
                    height: 1.5,
                    color: CoterieColors.inkPrimary,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VOL. I · NO. 12  —  LEXICON INDEX',
                        style: CoterieTypography.receiptMeta.copyWith(
                          fontSize: 9.5,
                          color: CoterieColors.inkMuted,
                        ),
                      ),
                      if (widget.onReturnToTicket != null)
                        _AcademicBracketLink(
                          label: '[↑ stub / ticket]',
                          onTap: widget.onReturnToTicket!,
                        )
                      else
                        Text(
                          'ISSN 2026-04',
                          style: CoterieTypography.receiptMeta.copyWith(
                            fontSize: 9.5,
                            color: CoterieColors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 1.0,
                    color: CoterieColors.hairlineDivider,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Coterie',
                        style: TextStyle(
                          fontFamily: CoterieTypography.displaySerifFamily,
                          fontSize: 38.0,
                          height: 0.92,
                          letterSpacing: 0.4,
                          color: CoterieColors.inkPrimary,
                        ),
                      ),
                      Text(
                        'SAVED: $savedCount / ${_entries.length}',
                        style: CoterieTypography.receiptMeta.copyWith(
                          fontSize: 10.0,
                          color: CoterieColors.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1.5,
                    color: CoterieColors.inkPrimary,
                  ),
                  const SizedBox(height: 14),

                  // ==========================================================
                  // 2. § 1. DAILY DISPATCH (Brutalist Box + News Column + HTML Links)
                  // ==========================================================
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: CoterieMotion.snappyOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) {
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.04),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<String>(currentWord.id),
                      decoration: BoxDecoration(
                        color: CoterieColors.archivalCream,
                        border: Border.all(
                          color: CoterieColors.inkPrimary,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brutalist exposed top cell bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: CoterieColors.inkPrimary,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '§ 1. SPECIMEN [${currentWord.id}]  ·  STUDY',
                                  style: CoterieTypography.receiptMeta.copyWith(
                                    fontSize: 9.5,
                                    color: CoterieColors.inkPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _AcademicBracketLink(
                                      label: currentWord.isSaved
                                          ? '[saved ★]'
                                          : '[+ save]',
                                      isBold: currentWord.isSaved,
                                      onTap: () => _toggleSaved(currentWord),
                                    ),
                                    const SizedBox(width: 12),
                                    _AcademicBracketLink(
                                      label: '[next →]',
                                      onTap: _cycleNextWord,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Dispatch body
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      currentWord.word,
                                      style: const TextStyle(
                                        fontFamily: CoterieTypography
                                            .displaySerifFamily,
                                        fontSize: 34.0,
                                        height: 0.95,
                                        letterSpacing: 0.3,
                                        color: CoterieColors.inkPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${currentWord.phonetic}  ${currentWord.partOfSpeech}',
                                      style: CoterieTypography.receiptMeta
                                          .copyWith(
                                            fontSize: 10.5,
                                            color: CoterieColors.inkMuted,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentWord.definition,
                                  style: const TextStyle(
                                    fontFamily:
                                        CoterieTypography.bodySerifFamily,
                                    fontSize: 15.5,
                                    height: 1.32,
                                    color: CoterieColors.inkPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentWord.citation,
                                  style: const TextStyle(
                                    fontFamily:
                                        CoterieTypography.bodySerifFamily,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13.5,
                                    height: 1.28,
                                    color: CoterieColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==========================================================
                  // 3. § 2. ACADEMIC HTML INDEX HEADER & INLINE FILTER
                  // ==========================================================
                  Row(
                    children: [
                      Text(
                        '§ 2. INDEX',
                        style: CoterieTypography.receiptMeta.copyWith(
                          fontSize: 10.0,
                          color: CoterieColors.inkPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _AcademicBracketLink(
                        label: '[all (${_entries.length})]',
                        isBold: !_showSavedOnly,
                        onTap: () => setState(() => _showSavedOnly = false),
                      ),
                      const SizedBox(width: 8),
                      _AcademicBracketLink(
                        label: '[saved ($savedCount)]',
                        isBold: _showSavedOnly,
                        onTap: () => setState(() => _showSavedOnly = true),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 132,
                        height: 24,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: CoterieTypography.receiptMeta.copyWith(
                            fontSize: 10.0,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 3),
                            hintText: 'filter: ________',
                            hintStyle: TextStyle(
                              fontFamily: CoterieTypography.receiptMonoFamily,
                              fontSize: 9.5,
                              color: CoterieColors.inkMuted,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 1.0,
                    color: CoterieColors.inkPrimary,
                  ),

                  // ==========================================================
                  // 4. RAW BRUTALIST / ACADEMIC HTML TABLE OF VOCABULARY
                  // ==========================================================
                  Expanded(
                    child: visibleList.isEmpty
                        ? Center(
                            child: Text(
                              '[ 0 entries matched query ]',
                              style: CoterieTypography.receiptMeta.copyWith(
                                color: CoterieColors.inkMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: visibleList.length,
                            separatorBuilder: (_, _) => Container(
                              height: 1.0,
                              color: CoterieColors.hairlineDivider,
                            ),
                            itemBuilder: (context, index) {
                              final item = visibleList[index];
                              final isSelected = item.id == currentWord.id;
                              return InkWell(
                                onTap: () {
                                  final idx = _entries.indexOf(item);
                                  if (idx != -1) {
                                    setState(() => _activeWordIndex = idx);
                                  }
                                },
                                child: Container(
                                  color: isSelected
                                      ? const Color(0xFFF8F6F1)
                                      : CoterieColors.galleryWhite,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Column 1: Academic catalog index [01]
                                      SizedBox(
                                        width: 32,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2.0,
                                          ),
                                          child: Text(
                                            '[${item.id}]',
                                            style: CoterieTypography.receiptMeta
                                                .copyWith(
                                                  fontSize: 9.5,
                                                  color: CoterieColors.inkMuted,
                                                ),
                                          ),
                                        ),
                                      ),

                                      // Column 2: Niloofar Serif Headword + Phonetic
                                      SizedBox(
                                        width: 124,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.word,
                                              style: TextStyle(
                                                fontFamily: CoterieTypography
                                                    .bodySerifFamily,
                                                fontSize: 17.0,
                                                fontWeight: FontWeight.w700,
                                                height: 1.1,
                                                decoration: isSelected
                                                    ? TextDecoration.underline
                                                    : TextDecoration.none,
                                                color: CoterieColors.inkPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.phonetic} ${item.partOfSpeech}',
                                              style: CoterieTypography
                                                  .receiptMeta
                                                  .copyWith(
                                                    fontSize: 9.0,
                                                    color:
                                                        CoterieColors.inkMuted,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Column 3: Concise Definition
                                      Expanded(
                                        child: Text(
                                          item.definition,
                                          style: const TextStyle(
                                            fontFamily: CoterieTypography
                                                .bodySerifFamily,
                                            fontSize: 14.0,
                                            height: 1.3,
                                            color: CoterieColors.inkSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Column 4: Raw HTML-style [save] / [★] toggle
                                      _AcademicBracketLink(
                                        label: item.isSaved ? '[★]' : '[save]',
                                        isBold: item.isSaved,
                                        onTap: () => _toggleSaved(item),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  Container(
                    height: 1.0,
                    color: CoterieColors.inkPrimary,
                  ),
                  const SizedBox(height: 12),

                  // ==========================================================
                  // 5. HARDWARE BEZEL BUTTON (Saved Style Guide Component)
                  // ==========================================================
                  Center(
                    child: CoterieBezelButton(
                      label: 'ADD NEW WORD',
                      trailingGlyph: '+',
                      width: 236,
                      height: 46,
                      onPressed: _openAddWordDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Unstyled academic-HTML-inspired bracket link (`[save]`, `[next ->]`, `[all]`).
class _AcademicBracketLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isBold;

  const _AcademicBracketLink({
    required this.label,
    required this.onTap,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          label,
          style: CoterieTypography.receiptMeta.copyWith(
            fontSize: 10.0,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            decoration: isBold
                ? TextDecoration.underline
                : TextDecoration.none,
            color: isBold ? CoterieColors.inkPrimary : CoterieColors.inkMuted,
          ),
        ),
      ),
    );
  }
}
