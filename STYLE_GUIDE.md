# Coterie Style Guide

Saved design tokens, surface recipes, typography, and motion curves implemented in [`lib/coterie_style_guide.dart`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart).

## 1. Top Opening Hole vs. Hardware Bezel Button

Both share the same material palette (anodized outer bezel `#E7E6E2 → #C5C4BE`, recessed chamfer `#8E8D87 → #F4F4F1`, and fuzzy velvet-black `#040405 → #141417` with `#34343A` micro-flecks), but are structured differently for their roles:

| Element | Painter / Widget | Structure |
| --- | --- | --- |
| **Top Slit Opening (Hole)** | [`CoterieBezelAperturePainter`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L132-L237) | Wide pill housing (`Radius.circular(height / 2)`) with deep horizontal & vertical insets framing a narrow recessed slot cavity where the ticket emerges. |
| **Hardware Bezel Button** | [`CoterieBezelKeycapPainter`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L244-L355) & [`CoterieBezelButton`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L358-L483) | Rounded-rectangle tactile button (`cornerRadius: 10px`) with a uniform thin `3.2px` anodized outer bezel collar, recessed chamfer groove, and a full-face velvet-black (`isDark: true`) or pure-white (`isDark: false`) button cap that physically depresses on tap. |

## 2. Palette & Minimalist Typography (`CoterieTypography`)

- **Palette**: Strictly pure white (`#FFFFFF`) and black (`#000000`) on the home screen.
- **Serif ONLY for Word Titles (`InstrumentSerif`)**:
  - [`CoterieTypography.heroWordTitleSerif`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L72-L79) (`54px`) for the active word title (`coterie`, `cur`, `dearth`, `brook`, etc.).
  - [`CoterieTypography.listWordTitleSerif`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L82-L89) (`28px`) for saved word titles.
- **Non-Serif for Everything Else (`ReceiptMono`)**:
  - [`CoterieTypography.definitionText`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L92-L98) (`12.5px`) for definitions and parts of speech.
  - [`CoterieTypography.embossedLabel`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L101-L118) for hardware button labels.

## 3. Motion & Timing Curves (`CoterieMotion`)

- **Snappy Ease-Out (`Cubic(0.23, 1.0, 0.32, 1.0)`)**: Instant responsiveness on entry and micro-interactions.
- **Sheet Push-Up Transition (`Cubic(0.32, 0.72, 0.0, 1.0)`)**: Pushes the entire ticket screen upward into the raw white-and-black home screen.
- **Tactile Spring (`SpringDescription(mass: 1.0, stiffness: 380.0, damping: 22.0)`)**: Physical button press/release and ticket settle bounce.
