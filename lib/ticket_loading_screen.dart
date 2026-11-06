import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Curated lexical specimens for the Coterie Kunstkammer ticket editions.
class LexicalSpecimen {
  final String editionCode;
  final String serialNumber;
  final String headword;
  final String phonetic;
  final String gloss;
  final String attribution;
  final String dateRange;
  final String taglinePrimary;
  final String taglineSecondary;

  const LexicalSpecimen({
    required this.editionCode,
    required this.serialNumber,
    required this.headword,
    required this.phonetic,
    required this.gloss,
    required this.attribution,
    required this.dateRange,
    required this.taglinePrimary,
    required this.taglineSecondary,
  });
}

const List<LexicalSpecimen> kSpecimens = [
  LexicalSpecimen(
    editionCode: 'LEX-653',
    serialNumber: '(10) COTERIE (26) 0001',
    headword: 'Velleity',
    phonetic: '/vɛˈliː.ɪ.ti/',
    gloss: 'A volition too slight to compel action',
    attribution: 'Dirck Jacobsz · Pompeius Occo',
    dateRange: 'c. 1531 – MMXXVI',
    taglinePrimary: 'Institute for Rare\n& Exact Diction',
    taglineSecondary: 'Anatomy of the Uncommon Tongue',
  ),
  LexicalSpecimen(
    editionCode: 'LEX-654',
    serialNumber: '(10) COTERIE (26) 0002',
    headword: 'Apricity',
    phonetic: '/əˈprɪs.ɪ.ti/',
    gloss: 'The quiet warmth of winter sun on stone',
    attribution: 'Dirck Jacobsz · Occo Codex',
    dateRange: 'Anno 1531 – MMXXVI',
    taglinePrimary: 'Kunstkammer of the\nSpoken Artifact',
    taglineSecondary: 'Lexicon as Living Architecture',
  ),
  LexicalSpecimen(
    editionCode: 'LEX-655',
    serialNumber: '(10) COTERIE (26) 0003',
    headword: 'Noctivagant',
    phonetic: '/nɒkˈtɪv.ə.ɡənt/',
    gloss: 'Walking or wandering through the night shades',
    attribution: 'Amsterdam Humanist Archive',
    dateRange: 'c. 1531 – MMXXVI',
    taglinePrimary: 'Cabinet of Precise\n& Vanishing Words',
    taglineSecondary: 'Curated Etymologies in Chiaroscuro',
  ),
];

/// Custom multi-phase mechanical thermal printer curve inspired by:
/// - Masahiro Sakurai (Nintendo): Pre-feed anticipation bite + 4-frame hitstop
///   so the eye registers mechanical engagement before velocity ramps up.
/// - Emil Kowalski / Rauno Freiberg (Substack / Design Engineering):
///   Asymmetric high-initial-velocity cubic-bezier(0.23, 1, 0.32, 1) and
///   iOS sheet friction cubic-bezier(0.32, 0.72, 0, 1).
class TicketFeedCurve extends Curve {
  const TicketFeedCurve();

  static const Cubic _biteCurve = Cubic(0.23, 1.0, 0.32, 1.0);
  static const Cubic _primaryFeed = Cubic(0.16, 1.0, 0.30, 1.0);
  static const Cubic _qrEject = Cubic(0.32, 0.72, 0.0, 1.0);

  @override
  double transformInternal(double t) {
    // Phase 0 (0.00 -> 0.09): Initial mechanical bite — ticket edge emerges 7%
    if (t < 0.09) {
      final localT = (t / 0.09).clamp(0.0, 1.0);
      return 0.07 * _biteCurve.transform(localT);
    }
    // Phase 1 (0.09 -> 0.14): Sakurai-style 4-frame thermal print-head engagement pause
    if (t < 0.14) {
      final localT = ((t - 0.09) / 0.05).clamp(0.0, 1.0);
      return 0.07 + 0.012 * localT;
    }
    // Phase 2 (0.14 -> 0.56): High-torque stepper feed across header, V-notches & Dutch portrait
    if (t < 0.56) {
      final localT = ((t - 0.14) / 0.42).clamp(0.0, 1.0);
      return 0.082 + 0.538 * _primaryFeed.transform(localT);
    }
    // Phase 3 (0.56 -> 0.63): Micro-hesitation while dense QR matrix initializes
    if (t < 0.63) {
      final localT = ((t - 0.56) / 0.07).clamp(0.0, 1.0);
      return 0.62 + 0.025 * Curves.easeInOut.transform(localT);
    }
    // Phase 4 (0.63 -> 1.00): Final QR stub ejection & deceleration into cutter position
    final localT = ((t - 0.63) / 0.37).clamp(0.0, 1.0);
    return 0.645 + 0.355 * _qrEject.transform(localT);
  }
}

class TicketLoadingScreen extends StatefulWidget {
  const TicketLoadingScreen({super.key});

  @override
  State<TicketLoadingScreen> createState() => _TicketLoadingScreenState();
}

class _TicketLoadingScreenState extends State<TicketLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _printController;
  late final AnimationController _settleSpringController;
  late final AnimationController _ambientController;
  late final AnimationController _retractController;

  int _specimenIndex = 0;
  Offset _pointerTilt = Offset.zero;
  Offset _targetTilt = Offset.zero;
  double _dragPullOffset = 0.0;
  bool _isDragging = false;
  late final Ticker _tiltTicker;

  @override
  void initState() {
    super.initState();

    // Main ticket feed animation (2650ms total choreography)
    _printController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2650),
    );

    // Underdamped Apple Fluid Spring when the cutter snaps at the end of printing
    _settleSpringController = AnimationController.unbounded(vsync: this);

    // Subtle continuous ambient breathing & optical status pulse
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    // Smooth retraction controller when re-issuing a ticket
    _retractController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _printController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerCutterSnapSpring();
      }
    });

    // Smooth 60/120fps exponential decay interpolation for 3D pointer tilt
    _tiltTicker = createTicker((_) {
      final dx = _targetTilt.dx - _pointerTilt.dx;
      final dy = _targetTilt.dy - _pointerTilt.dy;
      if (dx.abs() > 0.0005 || dy.abs() > 0.0005) {
        setState(() {
          _pointerTilt = Offset(
            _pointerTilt.dx + dx * 0.14,
            _pointerTilt.dy + dy * 0.14,
          );
        });
      }
    })..start();

    // Start initial ticket feed after brief gallery warm-up
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        _printController.forward(from: 0.0);
      }
    });
  }

  void _triggerCutterSnapSpring() {
    // Apple WWDC18 Fluid Interfaces inspired spring: crisp drop + organic bounce
    const spring = SpringDescription(
      mass: 1.0,
      stiffness: 390.0,
      damping: 21.5,
    );
    final simulation = SpringSimulation(spring, -7.5, 0.0, 140.0);
    _settleSpringController.animateWith(simulation);
  }

  Future<void> _reprintTicket() async {
    if (_retractController.isAnimating) return;
    await _retractController.forward(from: 0.0);
    if (!mounted) return;
    setState(() {
      _specimenIndex = (_specimenIndex + 1) % kSpecimens.length;
      _dragPullOffset = 0.0;
    });
    _retractController.reset();
    _settleSpringController.value = 0.0;
    _printController.forward(from: 0.0);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      // Apple logarithmic rubber-banding resistance
      final raw = (_dragPullOffset + details.delta.dy).clamp(-28.0, 90.0);
      _dragPullOffset = raw;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    if (_dragPullOffset > 44.0) {
      // Pulling firmly downward triggers a fresh archival print
      _reprintTicket();
      return;
    }
    const spring = SpringDescription(
      mass: 1.0,
      stiffness: 440.0,
      damping: 24.0,
    );
    final startOffset = _dragPullOffset;
    _dragPullOffset = 0.0;
    final sim = SpringSimulation(
      spring,
      startOffset,
      0.0,
      details.primaryVelocity ?? 0.0,
    );
    _settleSpringController.animateWith(sim);
  }

  @override
  void dispose() {
    _tiltTicker.dispose();
    _printController.dispose();
    _settleSpringController.dispose();
    _ambientController.dispose();
    _retractController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specimen = kSpecimens[_specimenIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: MouseRegion(
        onHover: (event) {
          final size = MediaQuery.sizeOf(context);
          if (size.width <= 0 || size.height <= 0) return;
          final nx = ((event.localPosition.dx / size.width) - 0.5) * 2.0;
          final ny = ((event.localPosition.dy / size.height) - 0.5) * 2.0;
          _targetTilt = Offset(nx.clamp(-1.0, 1.0), ny.clamp(-1.0, 1.0));
        },
        onExit: (_) {
          _targetTilt = Offset.zero;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle gallery ambient light radial wash on the white background
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.15,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF8F7F4),
                    Color(0xFFF1EFEA),
                  ],
                  stops: [0.0, 0.68, 1.0],
                ),
              ),
            ),

            // Center column: Hyperrealistic Bezeled Slit + Masked Emerging Ticket
             SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableH = constraints.maxHeight;
                  // Responsive ticket scale so the entire slit + ticket fits gracefully on any viewport
                  const double baseTicketW = 264.0;
                  const double baseTicketH = 668.0;
                  const double slitW = 336.0;
                  const double slitH = 38.0;

                  final double targetTotalH = baseTicketH + 74.0;
                  final double scale = (availableH / targetTotalH).clamp(0.68, 1.06);

                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: slitW + 60,
                        height: baseTicketH + 74,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _printController,
                            _settleSpringController,
                            _ambientController,
                            _retractController,
                          ]),
                          builder: (context, _) {
                            final rawT = _printController.value;
                            final curvedPrint = const TicketFeedCurve().transform(rawT);
                            final retractT = Curves.easeInCubic.transform(_retractController.value);

                            // Effective print progress [0..1]
                            final effectiveProgress = (curvedPrint * (1.0 - retractT)).clamp(0.0, 1.0);

                            // Stepper motor micro-jitter while actively feeding
                            double stepperJitterX = 0.0;
                            double stepperJitterY = 0.0;
                            if (_printController.isAnimating &&
                                rawT > 0.08 &&
                                rawT < 0.96 &&
                                !(rawT >= 0.09 && rawT < 0.14)) {
                              stepperJitterX = math.sin(rawT * 195.0) * 0.45;
                              stepperJitterY = math.cos(rawT * 340.0) * 0.35;
                            }

                            // Spring settle + interactive pull offset
                            final springOffset = _isDragging
                                ? _dragPullOffset * 0.42
                                : _settleSpringController.value;

                            // Total vertical translation of the ticket relative to the slit throat
                            // At effectiveProgress == 0, ticket bottom is tucked inside the slit (-baseTicketH).
                            // At effectiveProgress == 1, ticket hangs cleanly out of the slit.
                            final double hiddenTravel = baseTicketH + 8.0;
                            final double ticketTopY =
                                -hiddenTravel * (1.0 - effectiveProgress) +
                                springOffset +
                                stepperJitterY;

                            // Subtle pendulum sway when settling or tilting
                            final double rotationZ =
                                (_pointerTilt.dx * 0.012) +
                                (springOffset * 0.0006);

                            return Stack(
                              alignment: Alignment.topCenter,
                              clipBehavior: Clip.none,
                              children: [
                                // 1. OUTER HOUSING BACKPLATE OF THE SLIT (behind the ticket)
                                Positioned(
                                  top: 8,
                                  child: _SlitBackHousing(
                                    width: slitW,
                                    height: slitH,
                                    isPrinting: _printController.isAnimating,
                                    printProgress: rawT,
                                  ),
                                ),

                                // 2. STRICT APERTURE MASK: Ticket only exists below the centerline of the slit throat (top: 27)
                                Positioned(
                                  top: 27,
                                  left: 0,
                                  right: 0,
                                  height: baseTicketH + 46,
                                  child: ClipRect(
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          top: ticketTopY,
                                          child: GestureDetector(
                                            onVerticalDragUpdate: _onVerticalDragUpdate,
                                            onVerticalDragEnd: _onVerticalDragEnd,
                                            onTap: _reprintTicket,
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.grab,
                                              child: Transform(
                                                alignment: Alignment.topCenter,
                                                transform: Matrix4.identity()
                                                  ..setEntry(3, 2, 0.0011)
                                                  ..translateByDouble(stepperJitterX, 0.0, 0.0, 1.0)
                                                  ..rotateX((-_pointerTilt.dy * 0.045).clamp(-0.08, 0.08))
                                                  ..rotateY((_pointerTilt.dx * 0.055).clamp(-0.09, 0.09))
                                                  ..rotateZ(rotationZ),
                                                child: _CoterieTicketWidget(
                                                  width: baseTicketW,
                                                  height: baseTicketH,
                                                  specimen: specimen,
                                                  printProgress: effectiveProgress,
                                                  pointerTilt: _pointerTilt,
                                                  ambientValue: _ambientController.value,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Deep contact occlusion shadow cast by the upper lip of the slit onto the emerging ticket
                                        IgnorePointer(
                                          child: Container(
                                            width: baseTicketW + 6,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  const Color(0xFF050507).withValues(alpha: 0.72),
                                                  const Color(0xFF0A0A0E).withValues(alpha: 0.34),
                                                  const Color(0xFF0A0A0E).withValues(alpha: 0.08),
                                                  Colors.transparent,
                                                ],
                                                stops: const [0.0, 0.28, 0.65, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 3. UPPER OVERHANGING LIP OF THE SLIT BEZEL (occludes the exact emergence line for hyperrealism)
                                Positioned(
                                  top: 8,
                                  child: IgnorePointer(
                                    child: _SlitUpperLipOverlay(
                                      width: slitW,
                                      height: slitH,
                                      isPrinting: _printController.isAnimating,
                                      printProgress: rawT,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Minimalist museum micro-caption in bottom-right corner to replay / inspect animation
            Positioned(
              right: 20,
              bottom: 16,
              child: AnimatedBuilder(
                animation: _printController,
                builder: (context, _) {
                  final pct = (_printController.value * 100).round();
                  final isPrinting = _printController.isAnimating;
                  return GestureDetector(
                    onTap: _reprintTicket,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: const Cubic(0.23, 1.0, 0.32, 1.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F1EC).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFDAD6CE),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPrinting
                                    ? const Color(0xFFD96B43)
                                    : const Color(0xFF1E1E1C),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPrinting
                                  ? 'PRINTING SPECIMEN · ${pct.toString().padLeft(3, '0')}%'
                                  : 'RE-ISSUE SPECIMEN ↻',
                              style: const TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 9.5,
                                letterSpacing: 1.1,
                                color: Color(0xFF2B2A27),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hyperrealistic outer gray rounded bezel and recessed fuzzy black interior cavity.
class _SlitBackHousing extends StatelessWidget {
  final double width;
  final double height;
  final bool isPrinting;
  final double printProgress;

  const _SlitBackHousing({
    required this.width,
    required this.height,
    required this.isPrinting,
    required this.printProgress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _HyperrealisticSlitPainter(
        isUpperOverlayOnly: false,
        isPrinting: isPrinting,
        printProgress: printProgress,
      ),
    );
  }
}

/// Upper bezel lip & fuzzy black top overhang rendered IN FRONT of the emerging ticket plane.
class _SlitUpperLipOverlay extends StatelessWidget {
  final double width;
  final double height;
  final bool isPrinting;
  final double printProgress;

  const _SlitUpperLipOverlay({
    required this.width,
    required this.height,
    required this.isPrinting,
    required this.printProgress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _HyperrealisticSlitPainter(
        isUpperOverlayOnly: true,
        isPrinting: isPrinting,
        printProgress: printProgress,
      ),
    );
  }
}

class _HyperrealisticSlitPainter extends CustomPainter {
  final bool isUpperOverlayOnly;
  final bool isPrinting;
  final double printProgress;

  _HyperrealisticSlitPainter({
    required this.isUpperOverlayOnly,
    required this.isPrinting,
    required this.printProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outerRadius = Radius.circular(size.height / 2);
    final outerRRect = RRect.fromRectAndRadius(rect, outerRadius);

    // Inner recessed bevel rect
    final bevelRect = rect.deflate(4.5);
    final bevelRRect = RRect.fromRectAndRadius(
      bevelRect,
      Radius.circular(bevelRect.height / 2),
    );

    // Deep fuzzy black slot throat rect
    final throatRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + 0.5),
      width: size.width - 28.0,
      height: size.height - 17.5,
    );
    final throatRRect = RRect.fromRectAndRadius(
      throatRect,
      Radius.circular(throatRect.height / 2),
    );

    if (!isUpperOverlayOnly) {
      // 1. Soft multi-layered drop shadow on the white gallery wall
      canvas.save();
      canvas.drawRRect(
        outerRRect.shift(const Offset(0, 4.5)),
        Paint()
          ..color = const Color(0xFF141413).withValues(alpha: 0.13)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0),
      );
      canvas.drawRRect(
        outerRRect.shift(const Offset(0, 1.5)),
        Paint()
          ..color = const Color(0xFF141413).withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      canvas.restore();

      // 2. Outer architectural anodized gray housing body
      final outerGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE6E5E0),
          Color(0xFFD5D4CE),
          Color(0xFFC4C3BC),
          Color(0xFFDCDCD6),
        ],
        stops: [0.0, 0.42, 0.78, 1.0],
      ).createShader(rect);
      canvas.drawRRect(outerRRect, Paint()..shader = outerGradient);

      // Crisp machined outer border rim
      canvas.drawRRect(
        outerRRect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9F9F7),
              Color(0xFFB5B4AE),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.65, 1.0],
          ).createShader(rect),
      );

      // 3. Intermediate recessed chamfer bevel (darker top slope, lighter bottom catchlight lip)
      final bevelGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8F8E88),
          Color(0xFFB2B1AA),
          Color(0xFFDAD9D3),
          Color(0xFFF3F3F0),
        ],
        stops: [0.0, 0.35, 0.72, 1.0],
      ).createShader(bevelRect);
      canvas.drawRRect(bevelRRect, Paint()..shader = bevelGradient);

      // 4. Recessed fuzzy black interior cavity
      // Outer fuzzy halo around the black throat to transition from the gray bevel
      canvas.drawRRect(
        throatRRect.inflate(2.2),
        Paint()
          ..color = const Color(0xFF1E1E22).withValues(alpha: 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
      );

      // Core deep velvet black cavity
      final throatShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF030304),
          Color(0xFF0A0A0D),
          Color(0xFF151519),
          Color(0xFF070709),
        ],
        stops: [0.0, 0.45, 0.82, 1.0],
      ).createShader(throatRect);
      canvas.drawRRect(throatRRect, Paint()..shader = throatShader);

      // Fuzzy velvet micro-fibers inside the black slit cavity
      final rng = math.Random(901);
      final fuzzPaint = Paint()..strokeWidth = 0.75;
      canvas.save();
      canvas.clipRRect(throatRRect.inflate(1.2));
      for (int i = 0; i < 380; i++) {
        final fx = throatRect.left + rng.nextDouble() * throatRect.width;
        final fy = throatRect.top + rng.nextDouble() * throatRect.height;
        final alpha = 0.06 + rng.nextDouble() * 0.14;
        final shade = rng.nextBool()
            ? const Color(0xFF3A3A40)
            : const Color(0xFF000000);
        fuzzPaint.color = shade.withValues(alpha: alpha);
        canvas.drawCircle(Offset(fx, fy), 0.55 + rng.nextDouble() * 0.8, fuzzPaint);
      }
      canvas.restore();

      return;
    }

    // UPPER OVERLAY PASS: Masks the top half of the slit over the emerging ticket
    // so the ticket looks like it physically slides out from inside the recessed fuzzy black slot.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.51));

    // Redraw upper half of outer housing & bevel
    final outerGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE6E5E0),
        Color(0xFFD5D4CE),
        Color(0xFFC4C3BC),
        Color(0xFFDCDCD6),
      ],
      stops: [0.0, 0.42, 0.78, 1.0],
    ).createShader(rect);
    canvas.drawRRect(outerRRect, Paint()..shader = outerGradient);

    final bevelGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF8F8E88),
        Color(0xFFB2B1AA),
        Color(0xFFDAD9D3),
        Color(0xFFF3F3F0),
      ],
      stops: [0.0, 0.35, 0.72, 1.0],
    ).createShader(bevelRect);
    canvas.drawRRect(bevelRRect, Paint()..shader = bevelGradient);

    // Fuzzy black upper lip feathering
    canvas.drawRRect(
      throatRRect.inflate(2.0),
      Paint()
        ..color = const Color(0xFF1A1A1E).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8),
    );
    canvas.drawRRect(
      throatRRect,
      Paint()..color = const Color(0xFF060608),
    );

    // Subtle warm thermal print-head glow inside the fuzzy black throat while feeding
    if (isPrinting) {
      final glowAlpha = (math.sin(printProgress * math.pi) * 0.28).clamp(0.0, 0.28);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, throatRect.center.dy + 2),
          width: throatRect.width * 0.72,
          height: 8,
        ),
        Paint()
          ..color = const Color(0xFFE8875A).withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
      );
    }

    canvas.restore();

    // Soft fuzzy shadow along the exact upper slot lip
    canvas.drawLine(
      Offset(throatRect.left + 8, size.height * 0.50),
      Offset(throatRect.right - 8, size.height * 0.50),
      Paint()
        ..color = const Color(0xFF040406).withValues(alpha: 0.88)
        ..strokeWidth = 2.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
  }

  @override
  bool shouldRepaint(covariant _HyperrealisticSlitPainter oldDelegate) {
    return oldDelegate.isPrinting != isPrinting ||
        oldDelegate.printProgress != printProgress ||
        oldDelegate.isUpperOverlayOnly != isUpperOverlayOnly;
  }
}

/// The Coterie Museum Ticket Widget replicating the uploaded Klein® Vienna Gallery
/// ticket silhouette, notch geometry, vertical Swiss typography, 16th-century Dutch
/// B&W + grain artwork, top "Coterie" header, and bottom QR code.
class _CoterieTicketWidget extends StatelessWidget {
  final double width;
  final double height;
  final LexicalSpecimen specimen;
  final double printProgress;
  final Offset pointerTilt;
  final double ambientValue;

  const _CoterieTicketWidget({
    required this.width,
    required this.height,
    required this.specimen,
    required this.printProgress,
    required this.pointerTilt,
    required this.ambientValue,
  });

  @override
  Widget build(BuildContext context) {
    // Notch position at the top stub (matching the reference ticket's upper V-notches)
    const double notchY = 122.0;
    const double notchDepth = 14.5;
    const double notchHalfHeight = 13.5;

    return CustomPaint(
      painter: _TicketShadowPainter(
        notchY: notchY,
        notchDepth: notchDepth,
        notchHalfHeight: notchHalfHeight,
        pointerTilt: pointerTilt,
        printProgress: printProgress,
      ),
      child: ClipPath(
        clipper: _MuseumTicketClipper(
          notchY: notchY,
          notchDepth: notchDepth,
          notchHalfHeight: notchHalfHeight,
        ),
        child: Container(
          width: width,
          height: height,
          color: const Color(0xFFF3EFE6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Base archival cotton cardstock paper texture asset
              Opacity(
                opacity: 0.82,
                child: Image.asset(
                  'assets/images/paper_texture.png',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ),

              // 2. Main vertical layout of the ticket
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ============================================================
                  // SECTION A: TOP STUB ("Coterie" + High-Art Tagline above V-notches)
                  // ============================================================
                  SizedBox(
                    height: notchY,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Subtle dusty gallery rose top band inspired by the Klein® header block
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE3A4C8),
                                Color(0xFFD996BC),
                              ],
                            ),
                          ),
                        ),
                        // Blend paper grain over the rose pigment so ink looks letterpressed into cotton stock
                        Opacity(
                          opacity: 0.26,
                          child: Image.asset(
                            'assets/images/paper_texture.png',
                            fit: BoxFit.cover,
                            colorBlendMode: BlendMode.multiply,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top row: Left museum sub-block + Right "Coterie®" high-fashion wordmark
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left: High-art non-generic vocabulary tagline (like "Vienna Gallery of Contemporary Art")
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        specimen.taglinePrimary,
                                        style: const TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          fontSize: 9.2,
                                          fontWeight: FontWeight.w600,
                                          height: 1.22,
                                          letterSpacing: -0.1,
                                          color: Color(0xFF141312),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Right: "Coterie®" wordmark
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Coterie',
                                        style: TextStyle(
                                          fontFamily: 'CormorantGaramond',
                                          fontSize: 36.0,
                                          fontWeight: FontWeight.w700,
                                          height: 0.88,
                                          letterSpacing: -0.8,
                                          color: Color(0xFF11100F),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '®',
                                          style: TextStyle(
                                            fontFamily: 'PlusJakartaSans',
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF11100F)
                                                .withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Bottom row of top stub: Editorial italic manifesto + catalog index
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    specimen.taglineSecondary,
                                    style: const TextStyle(
                                      fontFamily: 'CormorantGaramond',
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                      color: Color(0xFF1A1817),
                                    ),
                                  ),
                                  Text(
                                    'N° 01',
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: const Color(0xFF141312)
                                          .withValues(alpha: 0.78),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ============================================================
                  // SECTION B: 16TH-CENTURY DUTCH ARTWORK (B&W + GRAIN) WITH GALLERY OVERLAY
                  // ============================================================
                  SizedBox(
                    height: 146,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1531 Dirck Jacobsz "Portrait of Pompeius Occo" in B&W + silver-halide grain
                        Image.asset(
                          'assets/images/dutch_16c_bw_grain.png',
                          fit: BoxFit.cover,
                          alignment: const Alignment(-0.15, -0.1),
                        ),

                        // Signature asymmetrical modernist rose color-block overlap (matching the Klein® reference)
                        Positioned(
                          right: 0,
                          top: 0,
                          width: width * 0.63,
                          height: 36,
                          child: Container(
                            color: const Color(0xFFD996BC).withValues(alpha: 0.68),
                          ),
                        ),

                        // Fine procedural darkroom grain & etching hairline border
                        CustomPaint(
                          painter: _ArtworkGrainOverlayPainter(
                            seed: 1531,
                            intensity: 0.08,
                          ),
                        ),

                        // Micro museum plate label in bottom-left of artwork
                        Positioned(
                          left: 10,
                          bottom: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            color: const Color(0xFF0E0E0D).withValues(alpha: 0.72),
                            child: const Text(
                              'FIG. I · AMSTERDAM 1531',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 7.2,
                                letterSpacing: 0.9,
                                color: Color(0xFFF3EFE6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ============================================================
                  // SECTION C: MIDDLE ARCHIVAL CREAM FIELD WITH 90° VERTICAL SWISS TYPOGRAPHY
                  // ============================================================
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // LEFT VERTICAL COLUMN (Rotated 90° CCW like "Aug 30 - Oct 21 / Maria Lassnig")
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    specimen.dateRange,
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                      height: 1.15,
                                      color: Color(0xFF232220),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    specimen.attribution,
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                      height: 1.15,
                                      color: Color(0xFF232220),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // CENTER VERTICAL LEXICAL SPECIMEN (High-Fashion Editorial Serif Headword & Definition)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Container(
                                padding: const EdgeInsets.only(left: 10),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Color(0xFFD5CFC3),
                                      width: 0.9,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          specimen.headword,
                                          style: const TextStyle(
                                            fontFamily: 'BodoniModa',
                                            fontStyle: FontStyle.italic,
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.3,
                                            height: 1.0,
                                            color: Color(0xFF141312),
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          specimen.phonetic,
                                          style: const TextStyle(
                                            fontFamily: 'SpaceMono',
                                            fontSize: 8.5,
                                            color: Color(0xFF5A5751),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      specimen.gloss,
                                      style: const TextStyle(
                                        fontFamily: 'CormorantGaramond',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.05,
                                        color: Color(0xFF3A3834),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // RIGHT VERTICAL COLUMN (Rotated 90° CCW like "DE-653 / $15 (A)")
                          Align(
                            alignment: Alignment.bottomRight,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    specimen.editionCode,
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                      height: 1.15,
                                      color: Color(0xFF232220),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'VOL. I (A)',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                      height: 1.15,
                                      color: Color(0xFF232220),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ============================================================
                  // SECTION D: BOTTOM STUB WITH QR CODE & ARCHIVAL SERIAL NUMBER
                  // ============================================================
                  Container(
                    height: 148,
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Subtle secondary perforated divider line above the QR stub
                        CustomPaint(
                          size: Size(width - 36, 2),
                          painter: _PerforationLinePainter(),
                        ),
                        const SizedBox(height: 4),
                        // Main bottom row: Crisp museum QR code + vertical archival metadata
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left metadata block next to QR code
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'ADMIT ONE · LEXICON',
                                      style: TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 8.2,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: Color(0xFF1F1E1C),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Permanent Collection\n16th C. Low Countries',
                                      style: TextStyle(
                                        fontFamily: 'CormorantGaramond',
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12.0,
                                        height: 1.12,
                                        color: Color(0xFF3E3C38),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF181715),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'READY · ${(printProgress * 100).round()}%',
                                          style: const TextStyle(
                                            fontFamily: 'SpaceMono',
                                            fontSize: 8.0,
                                            letterSpacing: 0.6,
                                            color: Color(0xFF45433E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Crisp Minimalist Museum QR Code at the bottom
                              Container(
                                width: 88,
                                height: 88,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F4EC),
                                  border: Border.all(
                                    color: const Color(0xFF1B1A18),
                                    width: 1.1,
                                  ),
                                ),
                                child: CustomPaint(
                                  painter: _MuseumQrCodePainter(
                                    seed: specimen.editionCode.hashCode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Bottom serial number (mirroring "(10) ABC123 (21) 0001" from reference ticket)
                        Text(
                          specimen.serialNumber,
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9.2,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                            color: Color(0xFF1A1917),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 3. Embossed perforated fold line right across the top V-notches (at notchY)
              Positioned(
                top: notchY - 1.0,
                left: notchDepth + 2,
                right: notchDepth + 2,
                height: 3.0,
                child: CustomPaint(
                  painter: _PerforationLinePainter(isDeepNotchCrease: true),
                ),
              ),

              // 4. Tactile procedural paper fiber, letterpress tooth, specular lighting & edge bevel
              IgnorePointer(
                child: CustomPaint(
                  painter: _TicketPaperSurfacePainter(
                    notchY: notchY,
                    notchDepth: notchDepth,
                    notchHalfHeight: notchHalfHeight,
                    pointerTilt: pointerTilt,
                    printProgress: printProgress,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clips the ticket silhouette with the two symmetric 45° triangular V-notches
/// near the top stub (and subtle micro-chamfered corners) matching the reference ticket.
class _MuseumTicketClipper extends CustomClipper<Path> {
  final double notchY;
  final double notchDepth;
  final double notchHalfHeight;

  const _MuseumTicketClipper({
    required this.notchY,
    required this.notchDepth,
    required this.notchHalfHeight,
  });

  @override
  Path getClip(Size size) {
    return _buildTicketPath(size, notchY, notchDepth, notchHalfHeight);
  }

  @override
  bool shouldReclip(covariant _MuseumTicketClipper oldClipper) {
    return oldClipper.notchY != notchY ||
        oldClipper.notchDepth != notchDepth ||
        oldClipper.notchHalfHeight != notchHalfHeight;
  }
}

Path _buildTicketPath(
  Size size,
  double notchY,
  double notchDepth,
  double notchHalfHeight,
) {
  const double r = 2.0; // Crisp die-cut museum cardstock corners
  final path = Path();

  // Top-left corner
  path.moveTo(0, r);
  path.quadraticBezierTo(0, 0, r, 0);

  // Top edge to top-right corner
  path.lineTo(size.width - r, 0);
  path.quadraticBezierTo(size.width, 0, size.width, r);

  // Right edge down to right V-notch
  path.lineTo(size.width, notchY - notchHalfHeight);
  path.lineTo(size.width - notchDepth, notchY);
  path.lineTo(size.width, notchY + notchHalfHeight);

  // Right edge down to bottom-right corner
  path.lineTo(size.width, size.height - r);
  path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);

  // Bottom edge to bottom-left corner
  path.lineTo(r, size.height);
  path.quadraticBezierTo(0, size.height, 0, size.height - r);

  // Left edge up to left V-notch
  path.lineTo(0, notchY + notchHalfHeight);
  path.lineTo(notchDepth, notchY);
  path.lineTo(0, notchY - notchHalfHeight);

  path.close();
  return path;
}

/// Multi-layered physical elevation shadow behind the notched ticket silhouette.
class _TicketShadowPainter extends CustomPainter {
  final double notchY;
  final double notchDepth;
  final double notchHalfHeight;
  final Offset pointerTilt;
  final double printProgress;

  _TicketShadowPainter({
    required this.notchY,
    required this.notchDepth,
    required this.notchHalfHeight,
    required this.pointerTilt,
    required this.printProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildTicketPath(size, notchY, notchDepth, notchHalfHeight);
    final shadowDx = -pointerTilt.dx * 7.0;
    final shadowDy = 10.0 - pointerTilt.dy * 4.0;

    // Ambient diffused gallery shadow
    canvas.drawPath(
      path.shift(Offset(shadowDx, shadowDy + 8)),
      Paint()
        ..color = const Color(0xFF141311).withValues(alpha: 0.11 * printProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0),
    );

    // Crisp contact shadow near paper edge
    canvas.drawPath(
      path.shift(Offset(shadowDx * 0.35, 3.5)),
      Paint()
        ..color = const Color(0xFF141311).withValues(alpha: 0.14 * printProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );
  }

  @override
  bool shouldRepaint(covariant _TicketShadowPainter oldDelegate) {
    return oldDelegate.pointerTilt != pointerTilt ||
        oldDelegate.printProgress != printProgress;
  }
}

/// Renders perforated tear-line dashes and subtle embossed highlight along the V-notch crease.
class _PerforationLinePainter extends CustomPainter {
  final bool isDeepNotchCrease;

  _PerforationLinePainter({this.isDeepNotchCrease = false});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 4.2;
    const double dashSpace = 3.2;
    double x = 0.0;

    final shadowPaint = Paint()
      ..color = isDeepNotchCrease
          ? const Color(0xFF8C7E75).withValues(alpha: 0.62)
          : const Color(0xFFB8B1A4).withValues(alpha: 0.65)
      ..strokeWidth = isDeepNotchCrease ? 1.15 : 0.9
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    while (x < size.width) {
      final endX = (x + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(endX, size.height / 2),
        shadowPaint,
      );
      canvas.drawLine(
        Offset(x, size.height / 2 + 1.0),
        Offset(endX, size.height / 2 + 1.0),
        highlightPaint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationLinePainter oldDelegate) => false;
}

/// Adds fine darkroom silver-halide grain and subtle tonal vignette over the 1531 Dutch portrait.
class _ArtworkGrainOverlayPainter extends CustomPainter {
  final int seed;
  final double intensity;

  _ArtworkGrainOverlayPainter({required this.seed, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final dotPaint = Paint();
    for (int i = 0; i < 650; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final isLight = rng.nextBool();
      dotPaint.color = (isLight ? Colors.white : Colors.black)
          .withValues(alpha: rng.nextDouble() * intensity);
      canvas.drawCircle(Offset(x, y), 0.45 + rng.nextDouble() * 0.55, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArtworkGrainOverlayPainter oldDelegate) => false;
}

/// Renders tactile cotton cardstock fibers, interactive specular sheen, and die-cut paper edge bevel.
class _TicketPaperSurfacePainter extends CustomPainter {
  final double notchY;
  final double notchDepth;
  final double notchHalfHeight;
  final Offset pointerTilt;
  final double printProgress;

  _TicketPaperSurfacePainter({
    required this.notchY,
    required this.notchDepth,
    required this.notchHalfHeight,
    required this.pointerTilt,
    required this.printProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Subtle interactive specular paper sheen as the user tilts the ticket
    final sheenCenter = Alignment(
      (-pointerTilt.dx * 0.7).clamp(-1.0, 1.0),
      (-pointerTilt.dy * 0.7 - 0.15).clamp(-1.0, 1.0),
    );
    final sheenShader = RadialGradient(
      center: sheenCenter,
      radius: 0.95,
      colors: [
        const Color(0xFFFFFFFF).withValues(alpha: 0.14),
        const Color(0xFFFFFFFF).withValues(alpha: 0.03),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = sheenShader);

    // 2. Micro-fibers & cotton paper flecks across the ticket surface
    final rng = math.Random(4096);
    final fiberPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55;
    for (int i = 0; i < 240; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final len = 1.5 + rng.nextDouble() * 3.5;
      final angle = rng.nextDouble() * math.pi;
      final isDark = rng.nextBool();
      fiberPaint.color = (isDark
              ? const Color(0xFF6B655B)
              : const Color(0xFFFFFFFF))
          .withValues(alpha: isDark ? 0.045 : 0.09);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        fiberPaint,
      );
    }

    // 3. Die-cut cardstock thickness rim (warm highlight on left/top, subtle shadow on right/bottom)
    final borderPath = _buildTicketPath(
      size,
      notchY,
      notchDepth,
      notchHalfHeight,
    );
    canvas.drawPath(
      borderPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF8),
            Color(0xFFD8D2C5),
            Color(0xFFBDB6A7),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _TicketPaperSurfacePainter oldDelegate) {
    return oldDelegate.pointerTilt != pointerTilt ||
        oldDelegate.printProgress != printProgress;
  }
}

/// Custom deterministic QR Code painter with authentic Version-2 finder patterns,
/// alignment pattern, timing strips, and high-density data matrix at the bottom of the ticket.
class _MuseumQrCodePainter extends CustomPainter {
  final int seed;

  _MuseumQrCodePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    const int n = 25; // Version 2 QR matrix (25x25 modules)
    final double cell = size.width / n;
    final paint = Paint()
      ..color = const Color(0xFF141312)
      ..style = PaintingStyle.fill;

    bool isFinderArea(int r, int c) {
      if (r < 8 && c < 8) return true;
      if (r < 8 && c >= n - 8) return true;
      if (r >= n - 8 && c < 8) return true;
      return false;
    }

    bool isAlignmentArea(int r, int c) {
      return r >= 16 && r <= 20 && c >= 16 && c <= 20;
    }

    void drawFinder(int startR, int startC) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final isOuter = r == 0 || r == 6 || c == 0 || c == 6;
          final isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          if (isOuter || isInner) {
            canvas.drawRect(
              Rect.fromLTWH(
                (startC + c) * cell,
                (startR + r) * cell,
                cell + 0.15,
                cell + 0.15,
              ),
              paint,
            );
          }
        }
      }
    }

    // 3 Corner Finder Patterns
    drawFinder(0, 0);
    drawFinder(0, n - 7);
    drawFinder(n - 7, 0);

    // Version 2 Alignment Pattern at (16..20, 16..20)
    for (int r = 16; r <= 20; r++) {
      for (int c = 16; c <= 20; c++) {
        final isBorder = r == 16 || r == 20 || c == 16 || c == 20;
        final isCenter = r == 18 && c == 18;
        if (isBorder || isCenter) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell + 0.15, cell + 0.15),
            paint,
          );
        }
      }
    }

    // Timing Patterns (row 6 and col 6)
    for (int i = 8; i < n - 8; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(i * cell, 6 * cell, cell + 0.15, cell + 0.15),
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(6 * cell, i * cell, cell + 0.15, cell + 0.15),
          paint,
        );
      }
    }

    // Data modules
    final rng = math.Random(seed ^ 0x5F3759DF);
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (isFinderArea(r, c) || isAlignmentArea(r, c) || r == 6 || c == 6) {
          continue;
        }
        if (rng.nextDouble() < 0.48) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell + 0.15, cell + 0.15),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MuseumQrCodePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
