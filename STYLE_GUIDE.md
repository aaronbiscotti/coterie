# Coterie Style Guide

Saved design tokens, surface recipes, typography, and motion curves implemented in [`lib/coterie_style_guide.dart`](file:///C:/Users/theso/.gemini/antigravity/scratch/coterie/lib/coterie_style_guide.dart).

## 1. Hardware Bezel & Fuzzy Velvet-Black Aperture (`CoterieBezelAperturePainter` & `CoterieBezelButton`)

Used for both the top ticket-dispenser slit and primary hardware-styled interactive buttons (`CoterieBezelButton`):

| Layer | Specification |
| --- | --- |
| **Outer Bezel Housing** | Pill stadium (`Radius.circular(height / 2)`), vertical gradient `#E7E6E2 → #D6D5D0 → #C5C4BE → #DDDDD8`, `1px` rim stroke `#B8B7B0`, soft drop shadow (`blur: 6.0`, `alpha: 0.10`) |
| **Recessed Chamfer Bevel** | Inset by `4.2px–4.5px`, vertical gradient `#8E8D87 → #B5B4AE → #DEDDD8 → #F4F4F1` (dark upper slope to bright lower catchlight) |
| **Fuzzy Black Feather Halo** | Inflated `2.4px` around the inner throat, `#19191C` (`alpha: 0.85`) with `MaskFilter.blur(BlurStyle.normal, 3.2)` |
| **Deep Velvet Cavity** | Vertical gradient `#040405 → #09090B → #101013 → #050507` with 200 stochastic `#34343A` velvet micro-flecks |

## 2. Typography (`CoterieTypography`)

- **Display Wordmark (`InstrumentSerif`)**: High-fashion vertical-stress editorial serif (`40px`, `letterSpacing: 0.8`, `#F7F5EE` on dark / `#141312` on newsprint masthead).
- **Literary Serif (`Niloofar` / `XB Niloofar`)**: Used for vocabulary headwords, artist attributions, definitions, and literary citations.
- **Thermal Receipt Mono (`ReceiptMono` / `Share Tech Mono`)**: Used for POS ticket numbers (`Tck: 2267  Trn: 12`), phonetic transcriptions, section indices (`§ 1`, `[01]`), and bracketed academic HTML links (`[+ save]`, `[next →]`).
- **Embossed Label (`CoterieTypography.embossedLabel`)**: Single-line uppercase stamp with top-left specular bevel (`Offset(-0.75, -0.75)`, `#B8FFFFFF`) and bottom-right recessed shadow (`Offset(0.95, 1.05)`, `#000000`).

## 3. Moodboard & Structural Language (`CoterieHomeScreen`)

- **News Articles**: Broadsheet masthead with edition/dateline rules (`1.5px` `#141312` and `1px` `#E5E2DA`), oversized `InstrumentSerif` header, and lead "Daily Dispatch" specimen column.
- **Modern Art Era Brutalism / Raw Minimalism**: Exposed `1px` solid `#141312` structural containers with `BorderRadius.zero`, zero decorative card drop-shadows, and high-contrast gallery white (`#FFFFFF`) paired with archival cream (`#F3F0E8`).
- **Academic HTML Webpages**: Section numbering (`§ 1. SPECIMEN`, `§ 2. INDEX`), bracketed plain-text anchor actions (`[+ save]`, `[saved ★]`, `[next →]`, `[all (6)]`), inline `filter: ________` input, and tabular `[01]` numbered rows.

## 4. Motion & Timing Curves (`CoterieMotion`)

- **Snappy Ease-Out (`Cubic(0.23, 1.0, 0.32, 1.0)`)**: Instant responsiveness on entry and micro-interactions.
- **Primary High-Torque Feed (`Cubic(0.16, 1.0, 0.30, 1.0)`)**: Fast initial impulse with a long deceleration tail.
- **Sheet Push-Up Transition (`Cubic(0.32, 0.72, 0.0, 1.0)`)**: iOS-style friction curve that pushes the entire ticket screen upward into the raw minimalist home screen.
- **Tactile Spring (`SpringDescription(mass: 1.0, stiffness: 380.0, damping: 22.0)`)**: Physical button press/release and ticket settle bounce.
