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
  // Extra 28px at the top of the stub stays permanently tucked inside the black slit rollers
  // so dragging or tilting the ticket never exposes its top edge outside the slit.
  static const double _tuckedTopBleed = 28.0;
  static const double _ticketH = 668.0;
  static const double _notchY = 142.0; // 114px visible below slit + 28px tucked inside slit
  static const double _notchDepth = 14.0;
  static const double _notchHalfHeight = 13.0;

  late final AnimationController _printController;
  late final AnimationController _settleTiltController;
  late final AnimationController _settlePullController;
  late final AnimationController _ripDetachController;

  // Taut slight pull + tilt state when dragging anywhere OUTSIDE the cut section
  double _dragPullY = 0.0; // Clamped to a slight 0..9px tug so it stays in the slit
  double _dragTiltAngle = 0.0; // Pivots around the slit throat
  bool _isDraggingTicket = false;

  // Cut-section horizontal swipe-to-rip state (ONLY triggered around _notchY)
  double _tearProgress = 0.0;
  bool _tearLeftToRight = true;
  bool _isRippedOff = false;

  @override
  void initState() {
    super.initState();

    _printController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _settleTiltController = AnimationController.unbounded(vsync: this);
    _settlePullController = AnimationController.unbounded(vsync: this);

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
        final sim = SpringSimulation(spring, -4.5, 0.0, 95.0);
        _settlePullController.animateWith(sim);
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
    _settleTiltController.stop();
    _settlePullController.stop();
    _settleTiltController.value = 0.0;
    _settlePullController.value = 0.0;
    _ripDetachController.reset();
    setState(() {
      _dragPullY = 0.0;
      _dragTiltAngle = 0.0;
      _isDraggingTicket = false;
      _tearProgress = 0.0;
      _isRippedOff = false;
    });
    _printController.forward(from: 0.0);
  }

  // ---------------------------------------------------------------------------
  // 1. WHOLE-TICKET SLIGHT PULL & TILT (Triggered anywhere OUTSIDE cut section)
  //    The ticket stays anchored inside the slit rollers — it pulls out just
  //    slightly (max ~9px) and tilts around the slit aperture.
  // ---------------------------------------------------------------------------
  void _onTicketMoveStart(DragStartDetails details) {
    if (_printController.isAnimating) return;
    _settleTiltController.stop();
    _settlePullController.stop();
    setState(() {
      _isDraggingTicket = true;
      _dragTiltAngle = _settleTiltController.value;
      _dragPullY = _settlePullController.value;
    });
  }

  void _onTicketMoveUpdate(DragUpdateDetails details) {
    if (_printController.isAnimating) return;
    setState(() {
      // Taut rubber-band vertical give: only pulls out slightly (-3px to +9px)
      // so the ticket never detaches or pulls out of the slit.
      final nextPull = (_dragPullY + details.delta.dy * 0.16).clamp(-3.0, 9.0);
      // Smooth rotational tilt anchored at the slit throat
      final nextTilt = (_dragTiltAngle - details.delta.dx * 0.0018)
          .clamp(-0.11, 0.11);
      _dragPullY = nextPull;
      _dragTiltAngle = nextTilt;
    });
  }

  void _onTicketMoveEnd(DragEndDetails details) {
    if (!_isDraggingTicket) return;
    final startTilt = _dragTiltAngle;
    final startPull = _dragPullY;
    setState(() {
      _isDraggingTicket = false;
    });

    const spring = SpringDescription(
      mass: 1.0,
      stiffness: 380.0,
      damping: 22.0,
    );
    _settleTiltController.animateWith(
      SpringSimulation(
        spring,
        startTilt,
        0.0,
        -details.velocity.pixelsPerSecond.dx * 0.0004,
      ),
    );
    _settlePullController.animateWith(
      SpringSimulation(
        spring,
        startPull,
        0.0,
        details.velocity.pixelsPerSecond.dy * 0.04,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. CUT-SECTION SWIPE-TO-RIP GESTURE (Triggered ONLY around the V-notch cut line)
  // ---------------------------------------------------------------------------
  void _onCutSectionHorizontalDragStart(DragStartDetails details) {
    if (_isRippedOff || _printController.isAnimating) return;
    _tearLeftToRight = details.localPosition.dx < (_ticketW / 2.0);
  }

  void _onCutSectionHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isRippedOff || _printController.isAnimating) return;
    final delta = _tearLeftToRight ? details.delta.dx : -details.delta.dx;
    final next = (_tearProgress + (delta / (_ticketW * 0.68))).clamp(0.0, 1.0);
    setState(() {
      _tearProgress = next;
    });
    if (_tearProgress >= 0.90) {
      _completeRip();
    }
  }

  void _onCutSectionHorizontalDragEnd(DragEndDetails details) {
    if (_isRippedOff || _printController.isAnimating) return;
    final vx = details.velocity.pixelsPerSecond.dx.abs();
    if (_tearProgress >= 0.28 || (vx > 220.0 && _tearProgress > 0.08)) {
      _completeRip();
    } else {
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
    const stubSpring = SpringDescription(
      mass: 1.0,
      stiffness: 460.0,
      damping: 22.0,
    );
    _settlePullController.animateWith(
      SpringSimulation(stubSpring, -3.5, 0.0, -70.0),
    );
    _ripDetachController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _printController.dispose();
    _settleTiltController.dispose();
    _settlePullController.dispose();
    _ripDetachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Widget cachedTopStub = RepaintBoundary(
      child: _TopStubContent(
        width: _ticketW,
        height: _notchY,
        topBleed: _tuckedTopBleed,
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
            const double visibleTicketH = _ticketH - _tuckedTopBleed;

            final double scale =
                (constraints.maxHeight / (visibleTicketH + 76.0))
                    .clamp(0.68, 1.04);

            return Center(
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: SizedBox(
                  width: slitW + 120,
                  height: visibleTicketH + 68,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Unified single-pass hyperrealistic slit (no split overlay = zero horizontal gray line)
                      const Positioned(
                        top: 8,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size(slitW, slitH),
                            painter: _HyperrealisticSlitPainter(),
                          ),
                        ),
                      ),

                      // 2. Masked ticket aperture starting inside the black throat (top: 24)
                      Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        height: visibleTicketH + 44,
                        child: ClipRect(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _printController,
                              _settleTiltController,
                              _settlePullController,
                              _ripDetachController,
                            ]),
                            builder: (context, _) {
                              final progress = const TicketFeedCurve()
                                  .transform(_printController.value);

                              final pullDy = _isDraggingTicket
                                  ? _dragPullY
                                  : _settlePullController.value;
                              final tiltAngle = _isDraggingTicket
                                  ? _dragTiltAngle
                                  : _settleTiltController.value;

                              // At progress == 1.0, baseDy is -_tuckedTopBleed (-28px),
                              // keeping the top 28px of the ticket permanently inside the black slit throat
                              // even when pulled down slightly (+9px) or tilted!
                              const double hiddenTravel = visibleTicketH + 12.0;
                              final double baseDy = -_tuckedTopBleed -
                                  hiddenTravel * (1.0 - progress) +
                                  pullDy;

                              // Rip detachment physics
                              final double ripT = const Cubic(
                                0.22,
                                1.0,
                                0.36,
                                1.0,
                              ).transform(_ripDetachController.value);

                              final double tearGap =
                                  (_tearProgress * 10.0) + (ripT * 115.0);
                              final double tearDx =
                                  (_tearLeftToRight ? 1.0 : -1.0) *
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
                                  child: Transform.rotate(
                                    // Pivot right at the slit throat line
                                    alignment: const Alignment(0.0, -0.92),
                                    angle: tiltAngle,
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
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onPanStart: _onTicketMoveStart,
                                              onPanUpdate: _onTicketMoveUpdate,
                                              onPanEnd: _onTicketMoveEnd,
                                              onTap: _isRippedOff
                                                  ? _resetAndReprint
                                                  : null,
                                              child: CustomPaint(
                                                painter:
                                                    const _StubShadowPainter(
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
                                                    leftToRight:
                                                        _tearLeftToRight,
                                                  ),
                                                  child: cachedTopStub,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // B. LOWER TICKET BODY (_notchY .. _ticketH)
                                          if (lowerOpacity > 0.0)
                                            Positioned(
                                              top: _notchY + tearGap,
                                              left: tearDx,
                                              width: _ticketW,
                                              height: _ticketH - _notchY,
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onPanStart: _onTicketMoveStart,
                                                onPanUpdate:
                                                    _onTicketMoveUpdate,
                                                onPanEnd: _onTicketMoveEnd,
                                                child: Opacity(
                                                  opacity: lowerOpacity,
                                                  child: Transform.rotate(
                                                    alignment: _tearLeftToRight
                                                        ? Alignment.topRight
                                                        : Alignment.topLeft,
                                                    angle: tearAngle,
                                                    child: CustomPaint(
                                                      painter:
                                                          const _StubShadowPainter(
                                                        isTopStub: false,
                                                        notchDepth: _notchDepth,
                                                        notchHalfHeight:
                                                            _notchHalfHeight,
                                                      ),
                                                      child: ClipPath(
                                                        clipper:
                                                            _LowerBodyClipper(
                                                          notchDepth:
                                                              _notchDepth,
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
                                            ),

                                          // C. Perforation crease line across the V-notches
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

                                          // D. DEDICATED CUT-SECTION SWIPE ZONE (ONLY around _notchY ± 24px)
                                          if (!_isRippedOff)
                                            Positioned(
                                              top: _notchY - 24.0,
                                              left: 0,
                                              right: 0,
                                              height: 48.0,
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onHorizontalDragStart:
                                                    _onCutSectionHorizontalDragStart,
                                                onHorizontalDragUpdate:
                                                    _onCutSectionHorizontalDragUpdate,
                                                onHorizontalDragEnd:
                                                    _onCutSectionHorizontalDragEnd,
                                                child: const SizedBox.expand(),
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
/// Includes `topBleed` tucked inside the black slit throat so no top edge or gray line
/// is ever visible when pulling or tilting the ticket.
class _TopStubContent extends StatelessWidget {
  final double width;
  final double height;
  final double topBleed;

  const _TopStubContent({
    required this.width,
    required this.height,
    required this.topBleed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF0A0A0C),
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
            padding: EdgeInsets.fromLTRB(18, topBleed + 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top title: Receipt metadata on left + "Coterie" in distinct high-fashion Instrument Serif on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Tck: 2267  Trn: 12\nId: 15943',
                        style: TextStyle(
                          fontFamily: 'ReceiptMono',
                          fontSize: 10.0,
                          height: 1.25,
                          letterSpacing: 0.5,
                          color: Color(0xFFD2CFC8),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Coterie',
                          style: TextStyle(
                            fontFamily: 'InstrumentSerif',
                            fontSize: 40.0,
                            fontWeight: FontWeight.w400,
                            height: 0.88,
                            letterSpacing: 0.8,
                            color: Color(0xFFF7F5EE),
                          ),
                        ),
                        SizedBox(width: 2),
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            '®',
                            style: TextStyle(
                              fontFamily: 'ReceiptMono',
                              fontSize: 10.5,
                              color: Color(0xFFEAE7DD),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Single line of physically embossed text
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
        fontFamily: 'ReceiptMono',
        fontSize: 9.5,
        letterSpacing: 1.15,
        color: Color(0xFFDAD7CE),
        shadows: [
          Shadow(
            offset: Offset(-0.75, -0.75),
            blurRadius: 0.0,
            color: Color(0xB8FFFFFF),
          ),
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
              // 1. Purely cropped 16th-century Dutch portrait (exact 256x144 = 16:9 crop, never stretched)
              SizedBox(
                width: width,
                height: 144,
                child: Image.asset(
                  'assets/images/dutch_16c_bw_grain.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
              ),

              // 2. Archival cream field with 90° vertical Niloofar Serif + thermal ReceiptMono metadata
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left vertical column: Niloofar Serif + ReceiptMono
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'AUG 30 – OCT 21  ·  1531',
                                style: TextStyle(
                                  fontFamily: 'ReceiptMono',
                                  fontSize: 11.5,
                                  letterSpacing: 0.4,
                                  height: 1.2,
                                  color: Color(0xFF2B2A27),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Dirck Jacobsz',
                                style: TextStyle(
                                  fontFamily: 'Niloofar',
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                  height: 1.1,
                                  color: Color(0xFF151413),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right vertical column: ReceiptMono POS ticket metadata
                      Align(
                        alignment: Alignment.bottomRight,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'CTR.WKS47  06/11/26  12:41',
                                style: TextStyle(
                                  fontFamily: 'ReceiptMono',
                                  fontSize: 10.5,
                                  letterSpacing: 0.3,
                                  height: 1.25,
                                  color: Color(0xFF33312E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'DE-653  ·  PRIX : 12 EUROS',
                                style: TextStyle(
                                  fontFamily: 'ReceiptMono',
                                  fontSize: 11.5,
                                  letterSpacing: 0.4,
                                  height: 1.2,
                                  color: Color(0xFF181715),
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

              // 3. Bottom Barcode + ReceiptMono Serial
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
                    SizedBox(height: 5),
                    Text(
                      '(10) ABC123 (21) 0001',
                      style: TextStyle(
                        fontFamily: 'ReceiptMono',
                        fontSize: 10.0,
                        letterSpacing: 0.8,
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
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    path.lineTo(size.width, size.height - notchHalfHeight);
    path.lineTo(size.width - notchDepth, size.height);

    _addSerratedCutEdge(
      path: path,
      fromX: size.width - notchDepth,
      toX: notchDepth,
      y: size.height,
      tearProgress: tearProgress,
      leftToRight: leftToRight,
    );

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

    path.moveTo(notchDepth, 0);

    _addSerratedCutEdge(
      path: path,
      fromX: notchDepth,
      toX: size.width - notchDepth,
      y: 0,
      tearProgress: tearProgress,
      leftToRight: leftToRight,
    );

    path.lineTo(size.width, notchHalfHeight);
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);

    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);

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
    final rect = isTopStub
        ? Rect.fromLTWH(0, 28, size.width, size.height - 28)
        : (Offset.zero & size);
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

/// Unified single-pass hyperrealistic slit painter (no horizontal split line).
class _HyperrealisticSlitPainter extends CustomPainter {
  const _HyperrealisticSlitPainter();

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
      height: size.height - 15.0,
    );
    final throatRRect = RRect.fromRectAndRadius(
      throatRect,
      Radius.circular(throatRect.height / 2),
    );

    // Soft outer elevation shadow on the white background
    canvas.drawRRect(
      outerRRect.shift(const Offset(0, 3.0)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

    // Outer gray rounded border housing
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

    // Inner recessed bevel
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

    // Fuzzy black interior feather
    canvas.drawRRect(
      throatRRect.inflate(2.4),
      Paint()
        ..color = const Color(0xFF19191C).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );

    // Deep fuzzy black cavity
    final throatShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF040405),
        Color(0xFF09090B),
        Color(0xFF101013),
        Color(0xFF050507),
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
  }

  @override
  bool shouldRepaint(covariant _HyperrealisticSlitPainter oldDelegate) => false;
}

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
