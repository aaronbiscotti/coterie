# Coterie® — Institute for Rare & Exact Diction

Minimalist museum-ticket loading experience built with Flutter, modeled on contemporary European Kunsthalle ephemera.

## Design & Material Anatomy

- **Top Bezeled Printer Slit**: Hyperrealistic machined architectural gray outer housing (`#E6E5E0` → `#C4C3BC`) with a recessed bevel lip and a fuzzy velvet-black interior aperture (`#030304` with stochastic micro-fiber blur).
- **Aperture Masking & Occlusion**: The ticket emerges strictly from inside the slit throat via split-plane occlusion (`ClipRect` + upper bezel overhang + multi-stop contact shadow cast onto the emerging cardstock).
- **16th-Century Dutch Artwork**: Dirck Jacobsz., *Portrait of Pompeius Occo* (c. 1531, Rijksmuseum Amsterdam) — Amsterdam humanist scholar and bibliophile — cropped to an avant-garde horizontal eye/face band with silver-gelatin B&W darkroom contrast, multi-scale Ilford/Tri-X film grain, and a translucent gallery-rose modernist block overlay.
- **Tactile Cardstock Texture**: 350gsm warm cotton paper stock (`assets/images/paper_texture.png`) layered with procedural paper fibers, interactive specular tilt sheen, die-cut 45° V-notches, embossed perforation crease lines, and a deterministic Version-2 QR matrix at the bottom stub.

## Open-Source Commercial-Use High-Fashion Typography (SIL OFL)

Bundled locally in `assets/fonts/`:
- **Cormorant Garamond** (`CormorantGaramond-Regular.ttf`, `CormorantGaramond-Italic.ttf`) — Haute couture display wordmark (`Coterie®`) & editorial italics
- **Bodoni Moda** (`BodoniModa-Regular.ttf`, `BodoniModa-Italic.ttf`) — High-contrast Didone serif for lexical headword specimens (*Velleity*, *Apricity*, *Noctivagant*)
- **Syne** (`Syne-Variable.ttf`) — Avant-garde art center display sans
- **Plus Jakarta Sans** (`PlusJakartaSans-Variable.ttf`) — 90°-rotated Swiss museum exhibition typography
- **Space Mono** (`SpaceMono-Regular.ttf`, `SpaceMono-Bold.ttf`) — Archival catalog serials & edition indices

## Motion & Animation Timing Architecture

1. **Nintendo / Masahiro Sakurai Frame-Data Cadence**:
   - **Pre-Feed Bite & 4-Frame Hitstop (`0.00 → 0.14`)**: The ticket tip emerges 7% from the fuzzy black slit and pauses briefly as the thermal print-head engages, giving the eye immediate mechanical legibility before high-torque feed begins, paired with sub-pixel stepper motor micro-vibration.
2. **Design Engineering Substack Curves (Emil Kowalski / Rauno Freiberg)**:
   - **Primary Feed (`cubic-bezier(0.16, 1.0, 0.30, 1.0)`)**: High initial velocity with a long, velvety deceleration tail across the V-notches and 1531 Dutch portrait.
   - **QR Stub Ejection (`cubic-bezier(0.32, 0.72, 0.0, 1.0)`)**: iOS sheet friction curve as the bottom QR matrix clears the throat.
3. **Apple WWDC18 *Designing Fluid Interfaces* Physics**:
   - **Cutter Kiss Spring (`SpringDescription(mass: 1.0, stiffness: 390, damping: 21.5)`)**: Underdamped physical bounce when the ticket finishes printing.
   - **Direct Manipulation**: Real-time 3D perspective tilt on hover and logarithmic rubber-banding on vertical drag.
