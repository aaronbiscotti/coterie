import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Multi-phase thermal ticket feed curve inspired by:
/// - Nintendo (Masahiro Sakurai): Initial mechanical bite + brief frame-data pause
///   before main feed velocity ramps up.
/// - Emil Kowalski / Rauno Freiberg (Substack): Strong asymmetric ease-out
///   cubic-bezier(0.23, 1, 0.32, 1) and iOS sheet curve cubic-bezier(0.32, 0.72, 0, 1).
class TicketFeedCurve extends Curve {
  const TicketFeedCurve();

  static const Cubic _biteCurve = Cubic(0.23, 1.0, 0.32, 1.0);
  static const Cubic _primaryFeed = Cubic(0.16, 1.0, 0.30, 1.0);
  static const Cubic _finalEject = Cubic(0.32, 0.72, 0.0, 1.0);

  @override
  double transformInternal(double t) {
    if (t < 0.09) {
      final localT = (t / 0.09).clamp(0.0, 1.0);
      return 0.07 * _biteCurve.transform(localT);
    }
    if (t < 0.14) {
      final localT = ((t - 0.09) / 0.05).clamp(0.0, 1.0);
      return 0.07 + 0.01 * localT;
    }
    if (t < 0.62) {
      final localT = ((t - 0.14) / 0.48).clamp(0.0, 1.0);
      return 0.08 + 0.60 * _primaryFeed.transform(localT);
    }
    final localT = ((t - 0.62) / 0.38).clamp(0.0, 1.0);
    return 0.68 + 0.32 * _finalEject.transform(localT);
  }
}

class TicketLoadingScreen extends StatefulWidget {
  const TicketLoadingScreen({super.key});

  @override
  State<TicketLoadingScreen> createState() => _TicketLoadingScreenState();
}

class _TicketLoadingScreenState extends State<TicketLoadingScreen>
    with TickerProviderStateMixin {
  static const double _ticketW = 256.0;
  static const double _ticketH = 640.0;
  static const double _notchY = 114.0;
  static const double _notchDepth = 14.0;
  static const double _notchHalfHeight = 13.0;

  late final AnimationController _printController;
  late final AnimationController _settleSpringController;
  late final AnimationController _ripDetachController;

  double _tearProgress = 0.0; // 0.0 = intact, 1.0 = fully ripped across cut line
  bool _tearLeftToRight = true;
  bool _isRippedOff = false;

  @override
  void initState() {
    super.initState();

    _printController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _settleSpringController = AnimationController.unbounded(vsync: this);

    _ripDetachController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    _printController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        const spring = SpringDescription(
          mass: 1.0,
          stiffness: 380.0,
          damping: 23.0,
        );
        final sim = SpringSimulation(spring, -5.0, 0.0, 110.0);
        _settleSpringController.animateWith(sim);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(
        const AssetImage('assets/images/dutch_16c_bw_grain.png'),
        context,
      );
      precacheImage(
        const AssetImage('assets/images/paper_texture.png'),
        context,
      );
      precacheImage(
        const AssetImage('assets/images/weather_header.png'),
        context,
      );
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) {
          _printController.forward(from: 0.0);
        }
      });
    });
  }

  void _resetAndReprint() {
    _settleSpringController.stop();
    _settleSpringController.value = 0.0;
    _ripDetachController.reset();
    setState(() {
      _tearProgress = 0.0;
      _isRippedOff = false;
    });
    _printController.forward(from: 0.0);
  }

  void _onCutHorizontalDragStart(DragStartDetails details) {
    if (_isRippedOff || _printController.isAnimating) return;
    _tearLeftToRight = details.localPosition.dx < (_ticketW / 2.0);
  }

  void _onCutHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isRippedOff || _printController.isAnimating) return;
    final delta = _tearLeftToRight ? details.delta.dx : -details.delta.dx;
    final next = (_tearProgress + (delta / (_ticketW * 0.72))).clamp(0.0, 1.0);
    setState(() {
      _tearProgress = next;
    });
    if (_tearProgress >= 0.92) {
      _completeRip();
    }
  }

  void _onCutHorizontalDragEnd(DragEndDetails details) {
    if (_isRippedOff || _printController.isAnimating) return;
    final vx = details.velocity.pixelsPerSecond.dx.abs();
    if (_tearProgress >= 0.30 || (vx > 240.0 && _tearProgress > 0.10)) {
      _completeRip();
    } else {
      // Snap back smoothly if swipe was tiny
      setState(() {
        _tearProgress = 0.0;
      });
    }
  }

  void _completeRip() {
    if (_isRippedOff) return;
    setState(() {
      _tearProgress = 1.0;
      _isRippedOff = true;
    });
    // Small upward recoil on the remaining top stub when ripped
    const stubSpring = SpringDescription(
      mass: 1.0,
      stiffness: 460.0,
      damping: 22.0,
    );
    _settleSpringController.animateWith(
      SpringSimulation(stubSpring, -4.5, 0.0, -90.0),
    );
    _ripDetachController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _printController.dispose();
    _settleSpringController.dispose();
    _ripDetachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pre-built static upper stub & lower body widgets wrapped in RepaintBoundary
    // so neither image nor typography ever flickers during printing or tearing.
    const Widget cachedTopStub = RepaintBoundary(
      child: _TopStubContent(
        width: _ticketW,
        height: _notchY,
      ),
    );

    const Widget cachedLowerBody = RepaintBoundary(
      child: _LowerTicketBodyContent(
        width: _ticketW,
        height: _ticketH - _notchY,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double slitW = 324.0;
            const double slitH = 36.0;

            final double scale =
                (constraints.maxHeight / (_ticketH + 76.0)).clamp(0.68, 1.04);

            return Center(
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: SizedBox(
                  width: slitW + 40,
                  height: _ticketH + 68,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Static hyperrealistic slit backplate (RepaintBoundary = zero flicker)
                      const Positioned(
                        top: 8,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size(slitW, slitH),
                            painter: _HyperrealisticSlitPainter(
                              isUpperOverlayOnly: false,
                            ),
                          ),
                        ),
                      ),

                      // 2. Masked ticket aperture strictly below the slit throat centerline
                      Positioned(
                        top: 26,
                        left: 0,
                        right: 0,
                        height: _ticketH + 42,
                        child: ClipRect(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _printController,
                              _settleSpringController,
                              _ripDetachController,
                            ]),
                            builder: (context, _) {
                              final progress = const TicketFeedCurve()
                                  .transform(_printController.value);
                              final springOffset = _settleSpringController.value;

                              const double hiddenTravel = _ticketH + 10.0;
                              final double baseDy =
                                  -hiddenTravel * (1.0 - progress) +
                                  springOffset;

                              // Rip detachment physics (asymmetric ease-out + gravity fall)
                              final double ripT = const Cubic(
                                0.22,
                                1.0,
                                0.36,
                                1.0,
                              ).transform(_ripDetachController.value);

                              final double tearGap =
                                  (_tearProgress * 10.0) + (ripT * 115.0);
                              final double tearDx = (_tearLeftToRight ? 1.0 : -1.0) *
                                  ((_tearProgress * 4.0) + (ripT * 28.0));
                              final double tearAngle =
                                  (_tearLeftToRight ? 1.0 : -1.0) *
                                  ((_tearProgress * 0.035) + (ripT * 0.11));
                              final double lowerOpacity =
                                  (1.0 - (ripT * 1.15)).clamp(0.0, 1.0);

                              return Align(
                                alignment: Alignment.topCenter,
                                child: Transform.translate(
                                  offset: Offset(0.0, baseDy),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onHorizontalDragStart:
                                        _onCutHorizontalDragStart,
                                    onHorizontalDragUpdate:
                                        _onCutHorizontalDragUpdate,
                                    onHorizontalDragEnd:
                                        _onCutHorizontalDragEnd,
                                    onTap: _isRippedOff ? _resetAndReprint : null,
                                    child: SizedBox(
                                      width: _ticketW,
                                      height: _ticketH,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // A. TOP TAG STUB (0 .. _notchY)
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            width: _ticketW,
                                            height: _notchY,
                                            child: CustomPaint(
                                              painter: _StubShadowPainter(
                                                isTopStub: true,
                                                notchDepth: _notchDepth,
                                                notchHalfHeight:
                                                    _notchHalfHeight,
                                              ),
                                              child: ClipPath(
                                                clipper: _TopStubClipper(
                                                  notchDepth: _notchDepth,
                                                  notchHalfHeight:
                                                      _notchHalfHeight,
                                                  tearProgress: _tearProgress,
                                                  leftToRight: _tearLeftToRight,
                                                ),
                                                child: cachedTopStub,
                                              ),
                                            ),
                                          ),

                                          // B. LOWER TICKET BODY (_notchY .. _ticketH) — Rips off when swiping cut section
                                          if (lowerOpacity > 0.0)
                                            Positioned(
                                              top: _notchY + tearGap,
                                              left: tearDx,
                                              width: _ticketW,
                                              height: _ticketH - _notchY,
                                              child: Opacity(
                                                opacity: lowerOpacity,
                                                child: Transform.rotate(
                                                  alignment: _tearLeftToRight
                                                      ? Alignment.topRight
                                                      : Alignment.topLeft,
                                                  angle: tearAngle,
                                                  child: CustomPaint(
                                                    painter: _StubShadowPainter(
                                                      isTopStub: false,
                                                      notchDepth: _notchDepth,
                                                      notchHalfHeight:
                                                          _notchHalfHeight,
                                                    ),
                                                    child: ClipPath(
                                                      clipper:
                                                          _LowerBodyClipper(
                                                        notchDepth: _notchDepth,
                                                        notchHalfHeight:
                                                            _notchHalfHeight,
                                                        tearProgress:
                                                            _tearProgress,
                                                        leftToRight:
                                                            _tearLeftToRight,
                                                      ),
                                                      child: cachedLowerBody,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // C. Perforation crease line across the V-notches (rips open as _tearProgress advances)
                                          if (!_isRippedOff)
                                            Positioned(
                                              top: _notchY - 1.0,
                                              left: _notchDepth,
                                              right: _notchDepth,
                                              height: 3.0,
                                              child: IgnorePointer(
                                                child: CustomPaint(
                                                  painter:
                                                      _DynamicPerforationPainter(
                                                    tearProgress: _tearProgress,
                                                    leftToRight:
                                                        _tearLeftToRight,
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
                            },
                          ),
                        ),
                      ),

                      // 3. Static upper bezel overhang lip so the ticket emerges from inside the fuzzy black throat
                      const Positioned(
                        top: 8,
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: Size(slitW, slitH),
                              painter: _HyperrealisticSlitPainter(
                                isUpperOverlayOnly: true,
                              ),
                            ),
                          ),
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
    );
  }
}

/// Top section above the V-notch cut line:
/// Low-brightness moody weather/cloud background (high contrast for light text)
/// + "Coterie" in Niloofar Serif + a single line of physically embossed text.
class _TopStubContent extends StatelessWidget {
  final double width;
  final double height;

  const _TopStubContent({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Low-brightness high-contrast weather cloud background
          Image.asset(
            'assets/images/weather_header.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top title: "Coterie" in Niloofar Serif with Louvre-inspired light ivory contrast
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tck: 1531',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9.0,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.4,
                        color: Color(0xFFD0CEC7),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Coterie',
                          style: TextStyle(
                            fontFamily: 'Niloofar',
                            fontSize: 34.0,
                            fontWeight: FontWeight.w700,
                            height: 0.90,
                            letterSpacing: 0.6,
                            color: Color(0xFFF6F4EC),
                          ),
                        ),
                        SizedBox(width: 2),
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            '®',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEAE7DD),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Single line of embossed text
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: _EmbossedSingleLineText(
                    text: 'ARCHIVE OF THE UNCOMMON TONGUE',
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

/// Renders a single line of physically embossed text with top-left specular bevel highlight
/// and bottom-right recessed stamp shadow.
class _EmbossedSingleLineText extends StatelessWidget {
  final String text;

  const _EmbossedSingleLineText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: const TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 8.4,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.95,
        color: Color(0xFFD8D5CC),
        shadows: [
          // Top-left specular ridge highlight (embossed upper bevel)
          Shadow(
            offset: Offset(-0.75, -0.75),
            blurRadius: 0.0,
            color: Color(0xB8FFFFFF),
          ),
          // Bottom-right deep die-stamped shadow (embossed lower recess)
          Shadow(
            offset: Offset(0.95, 1.05),
            blurRadius: 0.5,
            color: Color(0xFF000000),
          ),
        ],
      ),
    );
  }
}

/// Lower ticket body below the V-notch cut line:
/// 16th-century Dutch portrait (uncompressed B&W + grain) + simple vertical Mono/Niloofar text + bottom Barcode.
class _LowerTicketBodyContent extends StatelessWidget {
  final double width;
  final double height;

  const _LowerTicketBodyContent({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF3F0E8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Tactile cotton cardstock paper texture
          Opacity(
            opacity: 0.65,
            child: Image.asset(
              'assets/images/paper_texture.png',
              fit: BoxFit.cover,
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 16th-century Dutch portrait (uncompressed 5900x7160 master scan in B&W + fine grain)
              SizedBox(
                height: 144,
                width: width,
                child: Image.asset(
                  'assets/images/dutch_16c_bw_grain.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
              ),

              // 2. Clean archival cream field with simple 90° vertical SpaceMono + Niloofar Serif text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left vertical pair (Mono + Niloofar Serif)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                '1531 – 2026',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                  color: Color(0xFF22211F),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Dirck Jacobsz',
                                style: TextStyle(
                                  fontFamily: 'Niloofar',
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                  height: 1.1,
                                  color: Color(0xFF161514),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right vertical pair (Mono + Niloofar Serif)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'DE-653',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                  color: Color(0xFF22211F),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '12 Euros',
                                style: TextStyle(
                                  fontFamily: 'Niloofar',
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                  height: 1.1,
                                  color: Color(0xFF161514),
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

              // 3. Bottom Barcode + Mono Serial
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _MuseumBarcodePainter(),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '(10) ABC123 (21) 0001',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.6,
                        color: Color(0xFF1C1B1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Clips the top stub (`0 .. notchY`), including the upper half of the V-notches
/// and a serrated torn paper bottom edge where ripped.
class _TopStubClipper extends CustomClipper<Path> {
  final double notchDepth;
  final double notchHalfHeight;
  final double tearProgress;
  final bool leftToRight;

  const _TopStubClipper({
    required this.notchDepth,
    required this.notchHalfHeight,
    required this.tearProgress,
    required this.leftToRight,
  });

  @override
  Path getClip(Size size) {
    const double r = 1.5;
    final path = Path();

    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);

    // Right edge down to V-notch apex
    path.lineTo(size.width, size.height - notchHalfHeight);
    path.lineTo(size.width - notchDepth, size.height);

    // Bottom cut edge from right notch to left notch (with serrated paper tear teeth where ripped)
    _addSerratedCutEdge(
      path: path,
      fromX: size.width - notchDepth,
      toX: notchDepth,
      y: size.height,
      tearProgress: tearProgress,
      leftToRight: leftToRight,
    );

    // Left V-notch apex up to top-left
    path.lineTo(0, size.height - notchHalfHeight);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TopStubClipper oldClipper) {
    return oldClipper.tearProgress != tearProgress ||
        oldClipper.leftToRight != leftToRight;
  }
}

/// Clips the lower ticket body (`notchY .. ticketH`), including the lower half of the V-notches
/// and a matching serrated torn paper top edge where ripped.
class _LowerBodyClipper extends CustomClipper<Path> {
  final double notchDepth;
  final double notchHalfHeight;
  final double tearProgress;
  final bool leftToRight;

  const _LowerBodyClipper({
    required this.notchDepth,
    required this.notchHalfHeight,
    required this.tearProgress,
    required this.leftToRight,
  });

  @override
  Path getClip(Size size) {
    const double r = 1.5;
    final path = Path();

    // Start at left V-notch apex (top of lower body)
    path.moveTo(notchDepth, 0);

    // Top cut edge from left notch to right notch
    _addSerratedCutEdge(
      path: path,
      fromX: notchDepth,
      toX: size.width - notchDepth,
      y: 0,
      tearProgress: tearProgress,
      leftToRight: leftToRight,
    );

    // Right V-notch lower slope down to bottom-right
    path.lineTo(size.width, notchHalfHeight);
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);

    // Bottom edge to bottom-left
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);

    // Left edge up to left V-notch apex
    path.lineTo(0, notchHalfHeight);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _LowerBodyClipper oldClipper) {
    return oldClipper.tearProgress != tearProgress ||
        oldClipper.leftToRight != leftToRight;
  }
}

void _addSerratedCutEdge({
  required Path path,
  required double fromX,
  required double toX,
  required double y,
  required double tearProgress,
  required bool leftToRight,
}) {
  if (tearProgress <= 0.01) {
    path.lineTo(toX, y);
    return;
  }

  const int segments = 32;
  final double minX = math.min(fromX, toX);
  final double maxX = math.max(fromX, toX);
  final double span = maxX - minX;

  for (int i = 1; i <= segments; i++) {
    final double t = i / segments;
    final double x = fromX + (toX - fromX) * t;
    final double normX = (x - minX) / span;
    final bool isTornHere = leftToRight
        ? (normX <= tearProgress)
        : ((1.0 - normX) <= tearProgress);

    if (isTornHere && i < segments) {
      final double jag = (i.isEven ? -1.8 : 1.8) + math.sin(i * 1.7) * 0.7;
      path.lineTo(x, y + jag);
    } else {
      path.lineTo(x, y);
    }
  }
}

class _StubShadowPainter extends CustomPainter {
  final bool isTopStub;
  final double notchDepth;
  final double notchHalfHeight;

  const _StubShadowPainter({
    required this.isTopStub,
    required this.notchDepth,
    required this.notchHalfHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0),
    );
  }

  @override
  bool shouldRepaint(covariant _StubShadowPainter oldDelegate) => false;
}

class _DynamicPerforationPainter extends CustomPainter {
  final double tearProgress;
  final bool leftToRight;

  const _DynamicPerforationPainter({
    required this.tearProgress,
    required this.leftToRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 4.0;
    const double dashSpace = 3.0;
    double x = 0.0;

    final intactPaint = Paint()
      ..color = const Color(0xFFC4BEB2)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    while (x < size.width) {
      final normX = x / size.width;
      final isTorn = leftToRight
          ? (normX < tearProgress)
          : ((1.0 - normX) < tearProgress);
      if (!isTorn) {
        final endX = (x + dashWidth).clamp(0.0, size.width);
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(endX, size.height / 2),
          intactPaint,
        );
      }
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicPerforationPainter oldDelegate) {
    return oldDelegate.tearProgress != tearProgress ||
        oldDelegate.leftToRight != leftToRight;
  }
}

/// Hyperrealistic bezeled slit: rounded gray outer border, beveled rim, and fuzzy black interior.
/// Completely static (`shouldRepaint => false`) so it never flickers.
class _HyperrealisticSlitPainter extends CustomPainter {
  final bool isUpperOverlayOnly;

  const _HyperrealisticSlitPainter({required this.isUpperOverlayOnly});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outerRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height / 2),
    );

    final bevelRect = rect.deflate(4.2);
    final bevelRRect = RRect.fromRectAndRadius(
      bevelRect,
      Radius.circular(bevelRect.height / 2),
    );

    final throatRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + 0.5),
      width: size.width - 26.0,
      height: size.height - 17.0,
    );
    final throatRRect = RRect.fromRectAndRadius(
      throatRect,
      Radius.circular(throatRect.height / 2),
    );

    if (!isUpperOverlayOnly) {
      canvas.drawRRect(
        outerRRect.shift(const Offset(0, 3.0)),
        Paint()
          ..color = const Color(0xFF000000).withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
      );

      final outerGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE7E6E2),
          Color(0xFFD6D5D0),
          Color(0xFFC5C4BE),
          Color(0xFFDDDDD8),
        ],
        stops: [0.0, 0.45, 0.80, 1.0],
      ).createShader(rect);
      canvas.drawRRect(outerRRect, Paint()..shader = outerGradient);

      canvas.drawRRect(
        outerRRect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFB8B7B0),
      );

      final bevelGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8E8D87),
          Color(0xFFB5B4AE),
          Color(0xFFDEDDD8),
          Color(0xFFF4F4F1),
        ],
        stops: [0.0, 0.35, 0.72, 1.0],
      ).createShader(bevelRect);
      canvas.drawRRect(bevelRRect, Paint()..shader = bevelGradient);

      canvas.drawRRect(
        throatRRect.inflate(2.2),
        Paint()
          ..color = const Color(0xFF1D1D20).withValues(alpha: 0.80)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );

      final throatShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF040405),
          Color(0xFF0B0B0E),
          Color(0xFF16161A),
          Color(0xFF070709),
        ],
      ).createShader(throatRect);
      canvas.drawRRect(throatRRect, Paint()..shader = throatShader);

      final rng = math.Random(42);
      final dotPaint = Paint();
      canvas.save();
      canvas.clipRRect(throatRRect);
      for (int i = 0; i < 220; i++) {
        final fx = throatRect.left + rng.nextDouble() * throatRect.width;
        final fy = throatRect.top + rng.nextDouble() * throatRect.height;
        dotPaint.color = const Color(0xFF34343A)
            .withValues(alpha: 0.08 + rng.nextDouble() * 0.12);
        canvas.drawCircle(Offset(fx, fy), 0.6, dotPaint);
      }
      canvas.restore();
      return;
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.50));

    final outerGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE7E6E2),
        Color(0xFFD6D5D0),
        Color(0xFFC5C4BE),
        Color(0xFFDDDDD8),
      ],
      stops: [0.0, 0.45, 0.80, 1.0],
    ).createShader(rect);
    canvas.drawRRect(outerRRect, Paint()..shader = outerGradient);

    final bevelGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF8E8D87),
        Color(0xFFB5B4AE),
        Color(0xFFDEDDD8),
        Color(0xFFF4F4F1),
      ],
      stops: [0.0, 0.35, 0.72, 1.0],
    ).createShader(bevelRect);
    canvas.drawRRect(bevelRRect, Paint()..shader = bevelGradient);

    canvas.drawRRect(
      throatRRect.inflate(1.8),
      Paint()
        ..color = const Color(0xFF18181B).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawRRect(throatRRect, Paint()..color = const Color(0xFF060608));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HyperrealisticSlitPainter oldDelegate) => false;
}

/// Crisp Code-128 style vertical-bar Barcode at the bottom of the ticket.
class _MuseumBarcodePainter extends CustomPainter {
  const _MuseumBarcodePainter();

  static const List<int> _pattern = [
    2, 1, 1, 2, 3, 1, 1, 2, 1, 3, 2, 1, 1, 1, 3, 2, 1, 2, 1, 1, 2, 3, 1, 2,
    1, 1, 3, 1, 2, 2, 1, 1, 2, 1, 3, 1, 1, 2, 2, 1, 3, 1, 1, 2, 1, 2, 3, 1,
    2, 1, 1, 2, 1, 3, 1, 2, 1, 1, 2, 3, 2, 1, 1, 1, 2, 2, 1, 3, 1, 1, 2, 1,
    2, 1, 3, 1, 1, 2, 1, 2, 2, 1, 1, 3, 1, 2, 1, 1, 2, 1, 3, 2, 1, 1, 1, 2,
    2, 3, 1, 1, 2, 1, 2,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final int totalModules = _pattern.fold(0, (sum, w) => sum + w);
    final double moduleW = size.width / totalModules;
    final paint = Paint()
      ..color = const Color(0xFF141312)
      ..style = PaintingStyle.fill;

    double x = 0.0;
    for (int i = 0; i < _pattern.length; i++) {
      final double w = _pattern[i] * moduleW;
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      }
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant _MuseumBarcodePainter oldDelegate) => false;
}
