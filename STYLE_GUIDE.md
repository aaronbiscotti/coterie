# Coterie Style Guide

Saved design tokens, surface recipes, Swiss-grid spacing, typography, and motion curves implemented in [`lib/coterie_style_guide.dart`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart).

## 1. Top Opening Hole vs. Hardware Bezel Button

Both share the same material palette (anodized outer bezel `#E7E6E2 → #C5C4BE`, recessed chamfer `#8E8D87 → #F4F4F1`, and fuzzy velvet-black `#040405 → #141417` with `#34343A` micro-flecks), but are structured differently for their roles:

| Element | Painter / Widget | Structure |
| --- | --- | --- |
| **Top Slit Opening (Hole)** | [`CoterieBezelAperturePainter`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L186-L291) | Wide pill housing (`Radius.circular(height / 2)`) with deep horizontal & vertical insets framing a narrow recessed slot cavity where the ticket emerges. |
| **Hardware Bezel Button** | [`CoterieBezelKeycapPainter`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L298-L409) & [`CoterieBezelButton`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L413-L534) | Rounded-rectangle tactile button (`cornerRadius: 10px`) with a uniform thin `3.0px` anodized outer bezel collar, recessed chamfer groove, and a full-face velvet-black (`isDark: true`) or pure-white (`isDark: false`) button cap that physically depresses on tap. |

## 2. Two-Family Typography (`CoterieTypography`)

- **Serif ONLY for Word Titles (`InstrumentSerif`)**:
  - [`CoterieTypography.heroWordTitleSerif`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L99-L107) (`56px`, `height: 1.0`, `letterSpacing: -0.4`, `TextLeadingDistribution.even`) for the focus word title (`coterie`, `cur`, `dearth`, `brook`, etc.).
  - [`CoterieTypography.listWordTitleSerif`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L110-L118) (`26px`, `height: 1.1`, `letterSpacing: -0.1`, `TextLeadingDistribution.even`) for saved list word titles.
- **Sans-Serif for All Normal Text (`EditorialSans` / Inter)**:
  - [`CoterieTypography.heroDefinitionSans`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L121-L129) (`15px`, `height: 1.5`, `letterSpacing: -0.15`) for the hero definition.
  - [`CoterieTypography.listDefinitionSans`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L132-L140) (`14px`, `height: 1.45`, `letterSpacing: -0.1`) for row definitions.
  - [`CoterieTypography.partOfSpeechSans`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L143-L151) (`13px`, `#737373`) for part-of-speech tags (`n.`, `v.`, `adj.`).
  - [`CoterieTypography.buttonLabelSans`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L154-L162) (`12px`, `fontWeight: FontWeight.w500`, `letterSpacing: 0.4`) for optically centered button labels.

## 3. Swiss Grid & Optical Alignment (`CoterieSpacing`)

- **8pt Spatial Rhythm ([`CoterieSpacing`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart#L65-L81))**:
  - Outer margins: `32px` horizontal (`4 × 8pt`), `48px` top (`6 × 8pt`), `440px` max content width.
  - Vertical rhythm: `16px` (`2 × 8pt`) from word title to definition, `48px` (`6 × 8pt`) fixed 2-line definition height reservation so controls never shift vertically when cycling words, `24px` (`3 × 8pt`) to the action button row, and `40px` (`5 × 8pt`) to the saved index divider.
- **Optical Alignment**:
  - Flush-left anchor (`Alignment.topLeft` in `AnimatedSwitcher` + `TextLeadingDistribution.even`) prevents horizontal centering jitter.
  - Two-column index uses a `128px` (`16 × 8pt`) left column for the `26px` Serif word title, a `24px` (`3 × 8pt`) gutter, and a `+4px` optical top offset (`listOpticalTopOffset`) on the `14px` Sans definition so its first line aligns optically with the cap-height/x-height of the Serif word title.
