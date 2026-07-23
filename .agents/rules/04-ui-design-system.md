# UI Design System — asmita_society (Material 3, project-established)
Activation: Model Decision — apply whenever building or editing any screen, widget, or style in this repo.
Scope: Fully replaces the global `04-ui-design-system.md` (Claymorphism/Skeuomorphism/Bento) and the global Flutter-only "iOS-native for new projects" override for this workspace. Neither applies here — this project already has its own established, Material 3-based identity in `lib/core/constants/design_system.dart`. Match it; don't introduce a third visual language.

## Source of truth
`lib/core/constants/design_system.dart` — `AsmitaPalette` (colors) and `AsmitaTheme` (Material 3 `ThemeData`). Read/extend this file rather than hardcoding new hex values or ad hoc `TextStyle`s in a screen.

## Palette
```dart
actionRed  = 0xFFE21F26   // alerts, primary emphasis, high-priority labels (e.g. "GUEST PASS")
deepNavy   = 0xFF27347B   // primary brand color, nav icons, primary CTAs
systemBG   = 0xFFF8F8FB   // scaffold background, matches native splash color
textDark   = 0xFF1E2022   // primary text
textLight  = 0xFF676E76   // secondary text, labels — verify 4.5:1 contrast on white/systemBG before using at small sizes
borderGrey = 0xFFE5E8ED   // card/field borders
```
`deepNavy` is the primary brand color; `actionRed` is a reserved accent for alerts and the single most important call-to-action on a screen — don't spread it across multiple elements or it stops signaling priority.

## Typography
Google Fonts, loaded via `AsmitaTheme.lightTheme`:
- **Montserrat** (bold/semibold) — headings, titles, labels (`displayLarge`, `headlineMedium`, `titleLarge`, `labelLarge`).
- **Poppins** (regular/medium) — body text (`bodyLarge`, `bodyMedium`).
Use `Theme.of(context).textTheme.*` rather than constructing `GoogleFonts.montserrat(...)`/`GoogleFonts.poppins(...)` inline in a screen — new text styles that don't fit an existing role should be added to `AsmitaTheme`, not one-offed.

## Visual language
Flat Material 3 (`useMaterial3: true`), not claymorphism, not skeuomorphism, not Cupertino:
- Cards: white surface, `borderRadius: 24` (or 16 for smaller elements), a single `1.5px` `borderGrey` border — **no drop shadows, no dual-shadow clay effect.** Depth comes from the border + flat white-on-`systemBG` contrast, not elevation/shadow.
- App bars: transparent/`systemBG`-matching background, `elevation: 0`, centered title in Montserrat semibold.
- Icons: Material icon set, consistently the **`_rounded`** variant (`arrow_back_ios_new_rounded`, `delivery_dining_rounded`, `directions_car_rounded`, `build_rounded`, etc.) — pick the rounded variant for any new icon to stay consistent with every existing screen. Custom icon assets go through `flutter_svg` from `assets/icons/`.
- Buttons/CTAs: solid fill in `deepNavy` or `actionRed` depending on intent (primary action vs. alert/urgent), rounded corners matching the card radius scale — no gradient/glossy skeuomorphic treatment.

## Layout
Standard responsive Flutter layouts (`Column`/`Row`/`ListView`/`SingleChildScrollView`) per screen. No Bento Grid — this app's dashboards (`owner_dashboard_view.dart`, `tenant_dashboard_view.dart`) use role-specific composed views, not a generic asymmetric card grid; keep extending them in that style rather than introducing a Bento layout.

## Accessibility
- Check `textLight` (#676E76) against both `systemBG` (#F8F8FB) and white card surfaces for 4.5:1 body-text contrast before using it for anything other than clearly secondary/de-emphasized labels — it's close to the line and worth verifying per use, not assuming.
- Icon-only buttons (e.g. the back arrow in `AppBar.leading`) need an accessible label (`Semantics`/`tooltip`) even though they're visually self-explanatory.
- Respect `prefers-reduced-motion`-equivalent behavior in Flutter (`MediaQuery.disableAnimations`) for any new transition/animation.

## What not to do here
- Don't apply the global Claymorphism/Skeuomorphism/Bento system — it's a different product's visual language, not this one's.
- Don't default to Cupertino/iOS-native widgets or SF Pro-style typography — this project is Material 3 with Montserrat/Poppins by deliberate, already-implemented choice.
- Don't hardcode a new color inline (`Color(0xFF...)`) in a screen when it should be added to `AsmitaPalette` — the one exception already in the codebase is per-item accent colors for dynamic content (e.g. brand colors for delivery services in `visitor_history_screen.dart`'s mock data), which are legitimately data-driven, not part of the core UI palette.
