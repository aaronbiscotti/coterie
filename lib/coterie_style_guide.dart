import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// ============================================================================
/// COTERIE DESIGN SYSTEM & STYLE GUIDE
/// ============================================================================
/// Codifies:
/// 1. Architectural Hardware Bezel & Fuzzy Velvet-Black Aperture Surfaces
/// 2. Editorial Serif (Instrument Serif & XB Niloofar) + Thermal Receipt Mono
/// 3. Embossed Die-Stamped Typography
/// 4. Nintendo / Apple / Design-Engineering Substack Motion Curves & Springs
/// ============================================================================

class CoterieColors {
  const CoterieColors._();

  // Canvas & Archival Paper
  static const Color galleryWhite = Color(0xFFFFFFFF);
  static const Color archivalCream = Color(0xFFF3F0E8);
  static const Color hairlineDivider = Color(0xFFE5E2DA);
  static const Color inkPrimary = Color(0xFF141312);
  static const Color inkSecondary = Color(0xFF2B2A27);
  static const Color inkMuted = Color(0xFF6E6B64);

  // Bezeled Hardware Opening (Outer Anodized Gray -> Inner Bevel -> Fuzzy Black)
  static const List<Color> outerBezelGradient = [
    Color(0xFFE7E6E2),
    Color(0xFFD6D5D0),
    Color(0xFFC5C4BE),
    Color(0xFFDDDDD8),
  ];
  static const Color outerBezelStroke = Color(0xFFB8B7B0);

  static const List<Color> innerChamferGradient = [
    Color(0xFF8E8D87),
    Color(0xFFB5B4AE),
    Color(0xFFDEDDD8),
    Color(0xFFF4F4F1),
  ];

  static const Color fuzzyBlackFeather = Color(0xFF19191C);
  static const List<Color> fuzzyBlackCavityGradient = [
    Color(0xFF040405),
    Color(0xFF09090B),
    Color(0xFF101013),
    Color(0xFF050507),
  ];
  static const Color fuzzyVelvetFleck = Color(0xFF34343A);
}

class CoterieTypography {
  const CoterieTypography._();

  static const String displaySerifFamily = 'InstrumentSerif';
  static const String bodySerifFamily = 'Niloofar';
  static const String receiptMonoFamily = 'ReceiptMono';

  /// High-fashion display wordmark ("Coterie")
  static const TextStyle displayTitle = TextStyle(
    fontFamily: displaySerifFamily,
    fontSize: 40.0,
    fontWeight: FontWeight.w400,
    height: 0.88,
    letterSpacing: 0.8,
    color: Color(0xFFF7F5EE),
  );

  /// Physically embossed single-line uppercase label
  static const TextStyle embossedLabel = TextStyle(
    fontFamily: receiptMonoFamily,
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
  );

  /// Thermal receipt metadata
  static const TextStyle receiptMeta = TextStyle(
    fontFamily: receiptMonoFamily,
    fontSize: 10.5,
    letterSpacing: 0.4,
    height: 1.25,
    color: CoterieColors.inkSecondary,
  );

  /// Literary serif headword
  static const TextStyle headwordSerif = TextStyle(
    fontFamily: bodySerifFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.15,
    color: CoterieColors.inkPrimary,
  );
}

class CoterieMotion {
  const CoterieMotion._();

  /// Emil Kowalski / Rauno Freiberg strong ease-out for immediate input response
  static const Cubic snappyOut = Cubic(0.23, 1.0, 0.32, 1.0);

  /// High-torque primary deceleration curve
  static const Cubic primaryDecel = Cubic(0.16, 1.0, 0.30, 1.0);

  /// iOS sheet / full-screen push transition curve
  static const Cubic sheetTransition = Cubic(0.32, 0.72, 0.0, 1.0);

  /// Apple WWDC18 Fluid Interfaces snappy underdamped spring
  static const SpringDescription snappySpring = SpringDescription(
    mass: 1.0,
    stiffness: 380.0,
    damping: 22.0,
  );
}

/// Reusable painter for the Coterie signature bezeled hardware opening
/// (anodized gray rounded border, recessed inner bevel, fuzzy velvet-black interior).
class CoterieBezelAperturePainter extends CustomPainter {
  final double bevelInset;
  final double throatHorizontalInset;
  final double throatVerticalInset;
  final double pressedProgress;

  const CoterieBezelAperturePainter({
    this.bevelInset = 4.2,
    this.throatHorizontalInset = 26.0,
    this.throatVerticalInset = 15.0,
    this.pressedProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outerRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height / 2),
    );

    final bevelRect = rect.deflate(bevelInset);
    final bevelRRect = RRect.fromRectAndRadius(
      bevelRect,
      Radius.circular(bevelRect.height / 2),
    );

    final throatRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + 0.5),
      width: math.max(12.0, size.width - throatHorizontalInset),
      height: math.max(8.0, size.height - throatVerticalInset),
    );
    final throatRRect = RRect.fromRectAndRadius(
      throatRect,
      Radius.circular(throatRect.height / 2),
    );

    // 1. Soft outer drop shadow on the white gallery background
    final shadowOffset = Offset(0, 3.0 * (1.0 - pressedProgress * 0.6));
    canvas.drawRRect(
      outerRRect.shift(shadowOffset),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

    // 2. Outer gray rounded border housing
    final outerGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: CoterieColors.outerBezelGradient,
      stops: [0.0, 0.45, 0.80, 1.0],
    ).createShader(rect);
    canvas.drawRRect(outerRRect, Paint()..shader = outerGradient);

    canvas.drawRRect(
      outerRRect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = CoterieColors.outerBezelStroke,
    );

    // 3. Inner recessed chamfer bevel
    final bevelGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: CoterieColors.innerChamferGradient,
      stops: [0.0, 0.35, 0.72, 1.0],
    ).createShader(bevelRect);
    canvas.drawRRect(bevelRRect, Paint()..shader = bevelGradient);

    // 4. Fuzzy black interior feather halo
    canvas.drawRRect(
      throatRRect.inflate(2.4),
      Paint()
        ..color = CoterieColors.fuzzyBlackFeather.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );

    // 5. Deep fuzzy velvet-black interior cavity
    final throatShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: CoterieColors.fuzzyBlackCavityGradient,
    ).createShader(throatRect);
    canvas.drawRRect(throatRRect, Paint()..shader = throatShader);

    // 6. Stochastic velvet micro-flecks inside the dark cavity
    final rng = math.Random(42);
    final dotPaint = Paint();
    canvas.save();
    canvas.clipRRect(throatRRect);
    for (int i = 0; i < 200; i++) {
      final fx = throatRect.left + rng.nextDouble() * throatRect.width;
      final fy = throatRect.top + rng.nextDouble() * throatRect.height;
      dotPaint.color = CoterieColors.fuzzyVelvetFleck
          .withValues(alpha: 0.08 + rng.nextDouble() * 0.12);
      canvas.drawCircle(Offset(fx, fy), 0.6, dotPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CoterieBezelAperturePainter oldDelegate) {
    return oldDelegate.pressedProgress != pressedProgress ||
        oldDelegate.bevelInset != bevelInset ||
        oldDelegate.throatHorizontalInset != throatHorizontalInset ||
        oldDelegate.throatVerticalInset != throatVerticalInset;
  }
}

/// Interactive button styled identically to the hyperrealistic bezeled opening at the top:
/// - Outer anodized gray rounded border
/// - Recessed inner bevel rim
/// - Deep fuzzy velvet-black interior cavity
/// - Embossed / high-contrast receipt-mono & serif label inside
/// - Snappy Apple/Nintendo spring compression and release physics
class CoterieBezelButton extends StatefulWidget {
  final String label;
  final String? trailingGlyph;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const CoterieBezelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingGlyph = '→',
    this.width = 248.0,
    this.height = 50.0,
  });

  @override
  State<CoterieBezelButton> createState() => _CoterieBezelButtonState();
}

class _CoterieBezelButtonState extends State<CoterieBezelButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController.unbounded(
      vsync: this,
      value: 0.0,
    );
  }

  void _handleTapDown(TapDownDetails _) {
    const spring = SpringDescription(
      mass: 1.0,
      stiffness: 520.0,
      damping: 28.0,
    );
    _pressController.animateWith(
      SpringSimulation(spring, _pressController.value, 1.0, 4.0),
    );
  }

  void _handleTapUp(TapUpDetails _) {
    const spring = SpringDescription(
      mass: 1.0,
      stiffness: 420.0,
      damping: 19.0,
    );
    _pressController.animateWith(
      SpringSimulation(spring, _pressController.value, 0.0, -6.0),
    );
    widget.onPressed();
  }

  void _handleTapCancel() {
    const spring = CoterieMotion.snappySpring;
    _pressController.animateWith(
      SpringSimulation(spring, _pressController.value, 0.0, 0.0),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _pressController,
          builder: (context, child) {
            final p = _pressController.value.clamp(-0.25, 1.25);
            final scale = 1.0 - (p * 0.045);
            final dy = p * 1.6;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: CustomPaint(
                    painter: CoterieBezelAperturePainter(
                      bevelInset: 4.5,
                      throatHorizontalInset: 18.0,
                      throatVerticalInset: 13.0,
                      pressedProgress: p.clamp(0.0, 1.0),
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: CoterieTypography.embossedLabel.copyWith(
                      fontSize: 10.5,
                      letterSpacing: 1.4,
                      color: const Color(0xFFF3F0E8),
                    ),
                  ),
                  if (widget.trailingGlyph != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      widget.trailingGlyph!,
                      style: const TextStyle(
                        fontFamily: CoterieTypography.receiptMonoFamily,
                        fontSize: 12.0,
                        color: Color(0xFFF3F0E8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
