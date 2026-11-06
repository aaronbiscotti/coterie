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
      definition: 'a small, select group of people with shared interests.',
      isSaved: true,
    ),
    VocabularyEntry(
      word: 'cur',
      partOfSpeech: 'n.',
      definition: 'a mongrel dog; a contemptible or cowardly person.',
      isSaved: true,
    ),
    VocabularyEntry(
      word: 'dearth',
      partOfSpeech: 'n.',
      definition: 'a scarcity or lack of something needed.',
      isSaved: false,
    ),
    VocabularyEntry(
      word: 'brook',
      partOfSpeech: 'v.',
      definition: 'to tolerate or allow, especially dissent or delay.',
      isSaved: true,
    ),
    VocabularyEntry(
      word: 'untoward',
      partOfSpeech: 'adj.',
      definition: 'unexpected and inappropriate or inconvenient.',
      isSaved: false,
    ),
    VocabularyEntry(
      word: 'chide',
      partOfSpeech: 'v.',
      definition: 'to scold or rebuke gently.',
      isSaved: false,
    ),
    VocabularyEntry(
      word: 'fetter',
      partOfSpeech: 'v.',
      definition: 'to restrain with chains; to restrict freedom.',
      isSaved: false,
    ),
    VocabularyEntry(
      word: 'augur',
      partOfSpeech: 'v.',
      definition: 'to portend a good or bad outcome; to foreshadow.',
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
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: CoterieColors.pureBlack, width: 1.0),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: wordCtrl,
                    autofocus: true,
                    style: CoterieTypography.listWordTitleSerif,
                    decoration: const InputDecoration(
                      hintText: 'word',
                      hintStyle: TextStyle(
                        fontFamily: CoterieTypography.wordTitleSerifFamily,
                        fontSize: 28,
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: defCtrl,
                    style: CoterieTypography.definitionText,
                    decoration: const InputDecoration(
                      hintText: 'definition',
                      hintStyle: TextStyle(
                        fontFamily: CoterieTypography.monoFamily,
                        fontSize: 12.5,
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CoterieBezelButton(
                        label: 'CANCEL',
                        isDark: false,
                        height: 38,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      const SizedBox(width: 10),
                      CoterieBezelButton(
                        label: 'SAVE',
                        isDark: true,
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
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. FOCUS WORD (Learn)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: CoterieMotion.snappyOut,
                    child: Column(
                      key: ValueKey<String>(current.word),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Word title ONLY in Serif
                        Text(
                          current.word,
                          style: CoterieTypography.heroWordTitleSerif,
                        ),
                        const SizedBox(height: 10),
                        // Definition in Non-Serif
                        Text(
                          '${current.partOfSpeech}  ${current.definition}',
                          style: CoterieTypography.definitionText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 2. HARDWARE BEZEL BUTTONS (Save & Next)
                  Row(
                    children: [
                      CoterieBezelButton(
                        label: current.isSaved ? 'SAVED' : 'SAVE',
                        isDark: current.isSaved,
                        height: 40,
                        onPressed: () => _toggleSave(current),
                      ),
                      const SizedBox(width: 10),
                      CoterieBezelButton(
                        label: 'NEXT',
                        trailingGlyph: '→',
                        isDark: false,
                        height: 40,
                        onPressed: _nextWord,
                      ),
                      const Spacer(),
                      CoterieBezelButton(
                        label: '+',
                        isDark: false,
                        height: 40,
                        onPressed: _openAddWordModal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),
                  Container(
                    height: 1.0,
                    color: CoterieColors.hairlineBlack,
                  ),

                  // 3. SAVED WORDS LIST
                  Expanded(
                    child: savedWords.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: savedWords.length,
                            separatorBuilder: (_, _) => Container(
                              height: 1.0,
                              color: CoterieColors.hairlineBlack,
                            ),
                            itemBuilder: (context, index) {
                              final item = savedWords[index];
                              return InkWell(
                                onTap: () {
                                  final idx = _words.indexOf(item);
                                  if (idx != -1) {
                                    setState(() => _activeIndex = idx);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      // Word title ONLY in Serif
                                      SizedBox(
                                        width: 112,
                                        child: Text(
                                          item.word,
                                          style: CoterieTypography
                                              .listWordTitleSerif,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Definition in Non-Serif
                                      Expanded(
                                        child: Text(
                                          item.definition,
                                          style:
                                              CoterieTypography.definitionText,
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
