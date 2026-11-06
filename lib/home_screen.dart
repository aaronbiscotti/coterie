import 'package:flutter/material.dart';
import 'coterie_style_guide.dart';

class VocabularyEntry {
  final String word;
  final String partOfSpeech;
  final String definition;
  bool isSaved;

  VocabularyEntry({
    required this.word,
    required this.partOfSpeech,
    required this.definition,
    this.isSaved = false,
  });
}

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
  int _activeIndex = 0;

  final List<VocabularyEntry> _words = [
    VocabularyEntry(
      word: 'coterie',
      partOfSpeech: 'n.',
      definition: 'A small, select group of people with shared interests.',
      isSaved: true,
    ),
    VocabularyEntry(
      word: 'cur',
      partOfSpeech: 'n.',
      definition: 'A mongrel dog; a contemptible or cowardly person.',
      isSaved: true,
    ),
    VocabularyEntry(
      word: 'dearth',
      partOfSpeech: 'n.',
      definition: 'A scarcity or lack of something needed.',
      isSaved: false,
    ),
    VocabularyEntry(
      word: 'brook',
      partOfSpeech: 'v.',
      definition: 'To tolerate or allow, especially dissent or delay.',
      isSaved: true,
    ),
    VocabularyEntry(
      word: 'untoward',
      partOfSpeech: 'adj.',
      definition: 'Unexpected and inappropriate or inconvenient.',
      isSaved: false,
    ),
    VocabularyEntry(
      word: 'chide',
      partOfSpeech: 'v.',
      definition: 'To scold or rebuke gently.',
      isSaved: false,
    ),
    VocabularyEntry(
      word: 'fetter',
      partOfSpeech: 'v.',
      definition: 'To restrain with chains; to restrict freedom.',
      isSaved: false,
    ),
    VocabularyEntry(
      word: 'augur',
      partOfSpeech: 'v.',
      definition: 'To portend a good or bad outcome; to foreshadow.',
      isSaved: false,
    ),
  ];

  void _nextWord() {
    setState(() {
      _activeIndex = (_activeIndex + 1) % _words.length;
    });
  }

  void _toggleSave(VocabularyEntry entry) {
    setState(() {
      entry.isSaved = !entry.isSaved;
    });
  }

  Future<void> _openAddWordModal() async {
    final wordCtrl = TextEditingController();
    final defCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: CoterieColors.pureWhite,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: CoterieColors.hairlineBlack, width: 1.0),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Word Title input in Serif
                  TextField(
                    controller: wordCtrl,
                    autofocus: true,
                    style: CoterieTypography.listWordTitleSerif,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(bottom: 10),
                      hintText: 'Word',
                      hintStyle: TextStyle(
                        fontFamily: CoterieTypography.wordTitleSerifFamily,
                        fontSize: 26,
                        color: CoterieColors.inkMuted,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: CoterieColors.hairlineBlack,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: CoterieColors.pureBlack),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Definition input in Sans-Serif
                  TextField(
                    controller: defCtrl,
                    style: CoterieTypography.listDefinitionSans,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(bottom: 10),
                      hintText: 'Definition',
                      hintStyle: TextStyle(
                        fontFamily: CoterieTypography.sansFamily,
                        fontSize: 14.0,
                        color: CoterieColors.inkMuted,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: CoterieColors.hairlineBlack,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: CoterieColors.pureBlack),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CoterieBezelButton(
                        label: 'Cancel',
                        isDark: false,
                        width: 92,
                        height: 38,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      const SizedBox(width: 10),
                      CoterieBezelButton(
                        label: 'Save',
                        isDark: true,
                        width: 92,
                        height: 38,
                        onPressed: () {
                          final w = wordCtrl.text.trim();
                          final d = defCtrl.text.trim();
                          if (w.isNotEmpty && d.isNotEmpty) {
                            setState(() {
                              _words.insert(
                                0,
                                VocabularyEntry(
                                  word: w,
                                  partOfSpeech: 'n.',
                                  definition: d,
                                  isSaved: true,
                                ),
                              );
                              _activeIndex = 0;
                            });
                          }
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
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
  Widget build(BuildContext context) {
    final current = _words[_activeIndex % _words.length];
    final savedWords = _words.where((w) => w.isSaved).toList();

    return Scaffold(
      backgroundColor: CoterieColors.pureWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: CoterieSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                CoterieSpacing.pageHorizontalMargin,
                CoterieSpacing.pageTopMargin,
                CoterieSpacing.pageHorizontalMargin,
                CoterieSpacing.pageBottomMargin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==========================================================
                  // 1. HERO STUDY BLOCK (Flush-left locked, fixed vertical rhythm)
                  // ==========================================================
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: CoterieMotion.snappyOut,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topLeft,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: SizedBox(
                      key: ValueKey<String>(current.word),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Word Title (Serif ONLY) + Part of Speech (Sans-Serif) aligned on baseline
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                current.word,
                                style: CoterieTypography.heroWordTitleSerif,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                current.partOfSpeech,
                                style: CoterieTypography.partOfSpeechSans,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: CoterieSpacing.titleToDefinitionGap,
                          ),
                          // Definition in clean Sans-Serif with fixed 2-line height reservation
                          // so the button row below never shifts vertically.
                          SizedBox(
                            height: CoterieSpacing.heroDefinitionHeight,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                current.definition,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: CoterieTypography.heroDefinitionSans,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: CoterieSpacing.definitionToActionsGap),

                  // ==========================================================
                  // 2. HARDWARE BEZEL BUTTON ROW (Fixed widths = zero layout shift)
                  // ==========================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CoterieBezelButton(
                        label: current.isSaved ? 'Saved' : 'Save',
                        isDark: current.isSaved,
                        width: 96,
                        height: 40,
                        onPressed: () => _toggleSave(current),
                      ),
                      const SizedBox(width: CoterieSpacing.buttonGap),
                      CoterieBezelButton(
                        label: 'Next',
                        trailingGlyph: '→',
                        isDark: false,
                        width: 96,
                        height: 40,
                        onPressed: _nextWord,
                      ),
                      const Spacer(),
                      CoterieBezelButton(
                        label: '+',
                        isDark: false,
                        width: 40,
                        height: 40,
                        onPressed: _openAddWordModal,
                      ),
                    ],
                  ),

                  const SizedBox(height: CoterieSpacing.sectionVerticalGap),
                  Container(
                    height: 1.0,
                    color: CoterieColors.hairlineBlack,
                  ),

                  // ==========================================================
                  // 3. TWO-COLUMN SAVED WORDS LIST (Swiss Grid Optical Alignment)
                  // ==========================================================
                  Expanded(
                    child: savedWords.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: savedWords.length,
                            separatorBuilder: (_, _) => Container(
                              height: 1.0,
                              color: CoterieColors.hairlineBlack,
                            ),
                            itemBuilder: (context, index) {
                              final item = savedWords[index];
                              return InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                hoverColor: const Color(0xFFFAFAFA),
                                onTap: () {
                                  final idx = _words.indexOf(item);
                                  if (idx != -1) {
                                    setState(() => _activeIndex = idx);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical:
                                        CoterieSpacing.listRowVerticalPadding,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Column 1: Word Title ONLY in Serif (128px fixed grid column)
                                      SizedBox(
                                        width:
                                            CoterieSpacing.listLeftColumnWidth,
                                        child: Text(
                                          item.word,
                                          style: CoterieTypography
                                              .listWordTitleSerif,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: CoterieSpacing.listColumnGutter,
                                      ),
                                      // Column 2: Definition in Sans-Serif, optically offset (+4px)
                                      // to align with the cap-height/x-height of the 26px Serif word
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: CoterieSpacing
                                                .listOpticalTopOffset,
                                          ),
                                          child: Text(
                                            item.definition,
                                            style: CoterieTypography
                                                .listDefinitionSans,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Column 3: Right-aligned Part of Speech in Sans-Serif
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top:
                                              CoterieSpacing
                                                  .listOpticalTopOffset +
                                              1.0,
                                        ),
                                        child: Text(
                                          item.partOfSpeech,
                                          style: CoterieTypography
                                              .partOfSpeechSans,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
