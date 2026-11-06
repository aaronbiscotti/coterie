import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// ============================================================================
/// COTERIE DESIGN SYSTEM & STYLE GUIDE
/// ============================================================================
/// 1. Top Slit Aperture (`CoterieBezelAperturePainter`):
///    Recessed stadium slot hole with deep fuzzy velvet-black interior cavity.
/// 2. Hardware Bezel Button (`CoterieBezelButton`):
///    Structured differently from the top hole — a full-face rounded-rectangle
///    tactile button with a thin anodized outer bezel rim, recessed chamfer, and
///    fuzzy velvet-black (or pure white) button cap.
/// 3. Strict Typography (`CoterieTypography`):
///    - Serif (`InstrumentSerif`) ONLY for vocabulary word titles.
///    - Non-serif (`ReceiptMono`) for definitions and button labels.
/// 4. Strict Palette: Pure White (`#FFFFFF`) and Black (`#000000`).
/// ============================================================================

class CoterieColors {
  const CoterieColors._();

  // Pure White & Black for Home Screen
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  static const Color hairlineBlack = Color(0xFFE8E8E8);

  // Ticket paper (used only on the physical museum ticket)
  static const Color galleryWhite = Color(0xFFFFFFFF);
  static const Color archivalCream = Color(0xFFF3F0E8);
  static const Color inkPrimary = Color(0xFF000000);
  static const Color inkSecondary = Color(0xFF1A1A1A);
  static const Color inkMuted = Color(0xFF666666);

  // Bezeled Hardware Palette (Anodized Gray Outer -> Chamfer -> Velvet Black)
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

  static const List<Color> darkKeycapGradient = [
    Color(0xFF141417),
    Color(0xFF0B0B0D),
    Color(0xFF050506),
  ];
  static const List<Color> whiteKeycapGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
    Color(0xFFF2F2F2),
  ];
  static const Color fuzzyVelvetFleck = Color(0xFF34343A);
}

class CoterieTypography {
  const CoterieTypography._();

  static const String wordTitleSerifFamily = 'InstrumentSerif';
  static const String monoFamily = 'ReceiptMono';

  /// High-fashion display wordmark on ticket ("Coterie")
  static const TextStyle displayTitle = TextStyle(
    fontFamily: wordTitleSerifFamily,
    fontSize: 40.0,
    fontWeight: FontWeight.w400,
    height: 0.88,
    letterSpacing: 0.8,
    color: Color(0xFFF7F5EE),
  );

  /// SERIF ONLY FOR WORD TITLES: Large focus word title
  static const TextStyle heroWordTitleSerif = TextStyle(
    fontFamily: wordTitleSerifFamily,
    fontSize: 54.0,
    fontWeight: FontWeight.w400,
    height: 0.95,
    letterSpacing: 0.2,
    color: CoterieColors.pureBlack,
  );

  /// SERIF ONLY FOR WORD TITLES: List row word title
  static const TextStyle listWordTitleSerif = TextStyle(
    fontFamily: wordTitleSerifFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0.2,
    color: CoterieColors.pureBlack,
  );

  /// Non-serif definition & body copy
  static const TextStyle definitionText = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12.5,
    height: 1.4,
    letterSpacing: 0.1,
    color: CoterieColors.pureBlack,
  );

  /// Physically embossed single-line uppercase label
  static const TextStyle embossedLabel = TextStyle(
    fontFamily: monoFamily,
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

  /// Non-serif metadata / UI label
  static const TextStyle receiptMeta = TextStyle(
    fontFamily: monoFamily,
    fontSize: 10.5,
    letterSpacing: 0.5,
    height: 1.25,
    color: CoterieColors.pureBlack,
  );
}

class CoterieMotion {
  const CoterieMotion._();

  static const Cubic snappyOut = Cubic(0.23, 1.0, 0.32, 1.0);
  static const Cubic primaryDecel = Cubic(0.16, 1.0, 0.30, 1.0);
  static const Cubic sheetTransition = Cubic(0.32, 0.72, 0.0, 1.0);

  static const SpringDescription snappySpring = SpringDescription(
    mass: 1.0,
    stiffness: 380.0,
    damping: 22.0,
  );
}

/// Painter for the TOP TICKET SLIT OPENING (a recessed pill slot hole).
class CoterieBezelAperturePainter extends CustomPainter {
  final double bevelInset;
  final double throatHorizontalInset;
  final double throatVerticalInset;

  const CoterieBezelAperturePainter({
    this.bevelInset = 4.2,
    this.throatHorizontalInset = 26.0,
    this.throatVerticalInset = 15.0,
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

    canvas.drawRRect(
      outerRRect.shift(const Offset(0, 3.0)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

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

    final bevelGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: CoterieColors.innerChamferGradient,
      stops: [0.0, 0.35, 0.72, 1.0],
    ).createShader(bevelRect);
    canvas.drawRRect(bevelRRect, Paint()..shader = bevelGradient);

    canvas.drawRRect(
      throatRRect.inflate(2.4),
      Paint()
        ..color = CoterieColors.fuzzyBlackFeather.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );

    final throatShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: CoterieColors.fuzzyBlackCavityGradient,
    ).createShader(throatRect);
    canvas.drawRRect(throatRRect, Paint()..shader = throatShader);

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
  bool shouldRepaint(covariant CoterieBezelAperturePainter oldDelegate) =>
      false;
}

/// Painter for HARDWARE BEZEL BUTTONS:
/// Structured differently from the slit hole — instead of a narrow slot with
/// wide side margins, this is a full-face rounded-rectangle tactile button cap
/// framed by a uniform thin anodized bezel and recessed chamfer.
class CoterieBezelKeycapPainter extends CustomPainter {
  final bool isDark;
  final double cornerRadius;
  final double bezelThickness;
  final double pressedProgress;

  const CoterieBezelKeycapPainter({
    this.isDark = true,
    this.cornerRadius = 10.0,
    this.bezelThickness = 3.2,
    this.pressedProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outerRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius),
    );

    final chamferRect = rect.deflate(bezelThickness * 0.55);
    final chamferRRect = RRect.fromRectAndRadius(
      chamferRect,
      Radius.circular(math.max(2.0, cornerRadius - bezelThickness * 0.5)),
    );

    final capRect = rect
        .deflate(bezelThickness)
        .shift(Offset(0, pressedProgress * 0.8));
    final capRadius = math.max(2.0, cornerRadius - bezelThickness);
    final capRRect = RRect.fromRectAndRadius(
      capRect,
      Radius.circular(capRadius),
    );

    // 1. Soft outer drop shadow
    final shadowDy = 2.0 * (1.0 - pressedProgress * 0.6);
    canvas.drawRRect(
      outerRRect.shift(Offset(0, shadowDy)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );

    // 2. Anodized outer bezel frame
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

    // 3. Recessed inner chamfer
    final chamferGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: CoterieColors.innerChamferGradient,
      stops: [0.0, 0.35, 0.72, 1.0],
    ).createShader(chamferRect);
    canvas.drawRRect(chamferRRect, Paint()..shader = chamferGradient);

    if (isDark) {
      // 4A. Fuzzy black edge feather
      canvas.drawRRect(
        capRRect.inflate(0.9),
        Paint()
          ..color = CoterieColors.fuzzyBlackFeather.withValues(alpha: 0.80)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
      );

      // 5A. Full-face velvet-black button keycap
      final capShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: CoterieColors.darkKeycapGradient,
      ).createShader(capRect);
      canvas.drawRRect(capRRect, Paint()..shader = capShader);

      final rng = math.Random(42);
      final dotPaint = Paint();
      canvas.save();
      canvas.clipRRect(capRRect);
      for (int i = 0; i < 120; i++) {
        final fx = capRect.left + rng.nextDouble() * capRect.width;
        final fy = capRect.top + rng.nextDouble() * capRect.height;
        dotPaint.color = CoterieColors.fuzzyVelvetFleck
            .withValues(alpha: 0.08 + rng.nextDouble() * 0.10);
        canvas.drawCircle(Offset(fx, fy), 0.55, dotPaint);
      }
      canvas.restore();
    } else {
      // 4B. Pure white button keycap inside the same anodized bezel frame
      final capShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: CoterieColors.whiteKeycapGradient,
      ).createShader(capRect);
      canvas.drawRRect(capRRect, Paint()..shader = capShader);
    }
  }

  @override
  bool shouldRepaint(covariant CoterieBezelKeycapPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.bezelThickness != bezelThickness ||
        oldDelegate.pressedProgress != pressedProgress;
  }
}

/// Interactive hardware-bezel button (structured as a button cap, not a hole).
class CoterieBezelButton extends StatefulWidget {
  final String label;
  final String? trailingGlyph;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final bool isDark;
  final double cornerRadius;

  const CoterieBezelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingGlyph,
    this.width,
    this.height = 44.0,
    this.isDark = true,
    this.cornerRadius = 10.0,
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
    final textColor = widget.isDark
        ? CoterieColors.pureWhite
        : CoterieColors.pureBlack;

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
            final scale = 1.0 - (p * 0.032);
            final dy = p * 1.2;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: CustomPaint(
                    painter: CoterieBezelKeycapPainter(
                      isDark: widget.isDark,
                      cornerRadius: widget.cornerRadius,
                      bezelThickness: 3.2,
                      pressedProgress: p.clamp(0.0, 1.0),
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: widget.isDark
                      ? CoterieTypography.embossedLabel.copyWith(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          color: textColor,
                        )
                      : CoterieTypography.receiptMeta.copyWith(
                          fontSize: 10.5,
                          letterSpacing: 1.1,
                          color: textColor,
                        ),
                ),
                if (widget.trailingGlyph != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.trailingGlyph!,
                    style: TextStyle(
                      fontFamily: CoterieTypography.monoFamily,
                      fontSize: 11.5,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
