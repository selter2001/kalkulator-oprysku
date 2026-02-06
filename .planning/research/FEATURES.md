# Feature Landscape

**Domain:** Agricultural spray calculator (iOS)
**Researched:** 2026-02-06
**Confidence:** MEDIUM (based on training knowledge of agricultural apps domain; web verification unavailable)

## Context

Agricultural spray calculators help farmers compute mixing ratios for crop protection products. The core workflow: farmer has a field of known area, a product label specifying dose per hectare and recommended water volume per hectare, and a sprayer with a fixed tank capacity. The app must answer: "How much product and water go into each tank load, and how many loads do I need?"

Competing apps in this space include: Syngenta Spray Mix Calculator, BASF AgSolutions, Bayer Crop Science apps, TankMix (independent), SprayerCalc, and various local/regional agricultural extension tools. In the Polish market: eSADR, Agricon, and similar tools from agricultural advisory centers (ODR).

---

## Table Stakes

Features users expect. Missing any of these = product feels incomplete or untrustworthy.

| # | Feature | Why Expected | Complexity | Status in Project | Notes |
|---|---------|--------------|------------|-------------------|-------|
| 1 | **Core calculation: total chemical needed** | Fundamental purpose of the app | Low | EXISTING | `chemicalRate * area` |
| 2 | **Core calculation: total water/spray liquid needed** | Fundamental purpose | Low | EXISTING | `sprayRate * area` |
| 3 | **Tank division: full + partial tanks** | Farmers need to know how many passes | Low | EXISTING | `total / tankCapacity` |
| 4 | **Per-tank composition (water + chemical)** | The ACTUAL question farmers need answered at the sprayer | Medium | ACTIVE (planned) | Critical: farmer stands at sprayer and needs "pour X liters of product, fill to Y liters with water" |
| 5 | **Last partial tank composition** | Last tank is almost never full -- farmer must know exact amounts | Medium | ACTIVE (planned) | Often the most error-prone calculation when done by hand |
| 6 | **Unit support: hectares** | Standard agricultural area unit in EU/PL | Low | EXISTING | Primary unit |
| 7 | **Unit support: ares (ar)** | Common for smaller plots in Poland | Low | EXISTING | 1 ha = 100 ar |
| 8 | **Input validation** | Prevent nonsensical inputs (negative, zero, text) | Low | EXISTING | With haptic feedback |
| 9 | **Clear, readable results** | Farmer reads this in bright sunlight, often wearing gloves | Medium | PARTIAL (needs field-ready styling) | High contrast, large text critical |
| 10 | **Offline functionality** | Fields have no/poor connectivity | Low | EXISTING | No backend = inherently offline |
| 11 | **Polish language** | Target market is Polish farmers | Low | EXISTING | Via LocalizationManager |
| 12 | **Dark mode support** | iOS standard since iOS 13; App Store reviewers check this | Medium | ACTIVE (planned) | Required for App Store polish |
| 13 | **Decimal/comma input handling** | Polish locale uses comma as decimal separator | Low | VERIFY | Must accept both "." and "," |

## Differentiators

Features that set this app apart from competitors. Not universally expected, but valued.

| # | Feature | Value Proposition | Complexity | Status in Project | Notes |
|---|---------|-------------------|------------|-------------------|-------|
| 1 | **PDF export of calculation results** | Farmer can save/print/share exact recipe; useful for regulatory compliance documentation | Medium | ACTIVE (planned) | ImageRenderer in iOS 17+. Include: inputs, results, per-tank breakdown, date, author credit |
| 2 | **Calculation history** | Farmer reuses similar configs season to season; no re-entering data | Low | EXISTING (max 50, UserDefaults) | Most competing apps lack this or do it poorly |
| 3 | **Favorites / saved configurations** | Named presets for common product+field combos (e.g., "Pole A - Roundup") | Medium | EXISTING | Strong differentiator -- many competing apps are stateless |
| 4 | **PL/EN bilingual support** | Polish farmers increasingly work with English-speaking contexts; also broadens market | Low | EXISTING | Already implemented |
| 5 | **Tractor animation** | Delightful UX touch -- makes the app feel alive and agricultural, not generic | Low | EXISTING | Keep it -- distinctive branding |
| 6 | **About / author info screen** | Builds trust, professional feel; credit to Wojciech Olszak | Low | ACTIVE (planned) | Include contact/support info |
| 7 | **Dynamic Type support** | Accessibility for older farmers (primary demographic has vision concerns) | Medium | ACTIVE (planned) | Apple values this in App Store review |
| 8 | **Field-ready UI design** | High contrast, large touch targets, sunlight readability | Medium | ACTIVE (planned) | Agricultural green palette with high contrast. Most farming apps fail here -- generic iOS styling that washes out in sunlight |
| 9 | **m-squared (m2) unit support** | Useful for greenhouse/tunnel growers, small plots | Low | EXISTING | Nice to have for edge cases |
| 10 | **Haptic feedback on validation** | Tactile confirmation when wearing gloves, noisy environment | Low | EXISTING | Gloves + field noise = visual alone insufficient |

## Future Differentiators (Post-App Store)

Features worth considering for v2+ but explicitly NOT for the current milestone.

| # | Feature | Value Proposition | Complexity | Why Defer |
|---|---------|-------------------|------------|-----------|
| 1 | **Multi-product tank mix** | Many sprays combine 2-3 products + adjuvant in one tank | High | Requires product compatibility logic, significantly more complex UI |
| 2 | **Product database / label lookup** | Pre-populate dose from product database | High | Requires maintaining a database, regulatory considerations, frequent updates |
| 3 | **Nozzle/pressure calibration calculator** | Calculate actual output rate from nozzle type + pressure + speed | High | Different domain (sprayer calibration vs. mix calculation) |
| 4 | **Weather advisory** | Wind speed, temperature, humidity warnings for spraying conditions | Medium | Requires API, online connectivity, weather service integration |
| 5 | **GPS field area measurement** | Measure field directly instead of manual input | High | Major feature, needs location permissions, different UX paradigm |
| 6 | **Spray diary / application log** | Regulatory record-keeping (required in EU for IPM compliance) | High | Database needed, export formats, regulatory requirements |
| 7 | **Widget / Lock Screen widget** | Quick access to last calculation or favorites | Medium | Nice UX, but not core value |
| 8 | **Apple Watch companion** | Glance at per-tank recipe while at sprayer | Medium | Narrow use case, additional platform to maintain |
| 9 | **iCloud sync** | Multi-device history sync | Medium | Adds complexity, out of scope per PROJECT.md |
| 10 | **Siri Shortcuts** | "Hey Siri, calculate my spray mix" | Medium | Voice input unreliable for numeric inputs |

## Anti-Features

Features to explicitly NOT build. Common mistakes in this domain.

| # | Anti-Feature | Why Avoid | What to Do Instead |
|---|--------------|-----------|-------------------|
| 1 | **Product compatibility checker** | Liability risk -- if app says "compatible" and products react, farmer has crop damage and legal claim. Chemical companies spend millions on this testing. | Defer entirely. If ever built, must disclaim "consult product label" prominently. |
| 2 | **Dose recommendation engine** | The label IS the law in crop protection. App must never suggest doses -- only calculate from user-provided dose. Regulatory and liability minefield. | Always require user to input dose from product label. Never pre-fill or suggest. |
| 3 | **AI/ML "smart" features** | Unnecessary complexity for a calculator. Farmers want reliable, predictable tools -- not "smart" ones that might give different answers. | Keep it deterministic. Same inputs = same outputs. Always. |
| 4 | **Social features / sharing spray programs** | Privacy concern -- farmers don't want neighbors knowing their chemical usage. Also regulatory: unlicensed advice. | PDF export covers the sharing need (deliberate, controlled). |
| 5 | **Complex onboarding / tutorial** | The app must be self-explanatory. If it needs a tutorial, the UX has failed. Farmers are impatient with apps. | Use clear labels, sensible defaults, inline hints if needed. |
| 6 | **User accounts / registration** | Friction for zero benefit. No backend needed. Farmers abandon apps that demand registration. | UserDefaults for local storage. No accounts. |
| 7 | **Excessive settings / customization** | Farmers want to calculate, not configure. Settings should be minimal (language, maybe theme). | Keep settings to: language toggle, maybe clear history. That's it. |
| 8 | **In-app purchases / subscriptions** | For a calculator? Users will leave 1-star reviews. Free or paid upfront only. | Free app with author credit. Or paid upfront (max $0.99). |
| 9 | **Ads** | Destroy trust instantly in a professional agricultural tool. | No ads. Ever. |
| 10 | **Complex unit conversion system** | Don't turn this into a unit converter. Support ha/ar/m2 for area, L for volume. That's sufficient. | Fixed, clear unit options. No gallons/acres unless targeting US market later. |

## Feature Dependencies

```
Input Validation ──> Core Calculations ──> Tank Division ──> Per-Tank Composition
                                                               │
                                                               v
                                                          PDF Export
                                                               │
                                                               v
                                                      History / Favorites

Dark Mode ──> Field-Ready Styling (colors must work in both modes)

MVVM Refactor ──> Clean PDF generation (ViewModel provides data, View renders PDF)
               ──> Testable calculations (separated from UI)

Localization ──> All user-facing text (must be localized before adding new UI)

Dynamic Type ──> All text elements (do this BEFORE adding new views, not after)
```

### Critical Path for Current Milestone

```
1. MVVM Refactor (enables everything else cleanly)
   │
   ├── 2a. Per-tank composition calculation (core missing feature)
   │
   ├── 2b. Dark Mode + Field-Ready styling (parallel with 2a)
   │        └── Dynamic Type (do alongside styling)
   │
   └── 3. PDF Export (needs clean ViewModel + styled views)
        │
        └── 4. About screen + Polish/packaging (final)
             └── README, LICENSE, Bundle ID, zero warnings
```

## MVP vs. Polish Feature Split

### Must Complete for App Store (this milestone)

These are the ACTIVE requirements from PROJECT.md that make the app App Store-ready:

1. **Per-tank composition** (water + chemical for full AND partial tanks) -- the core missing calculation
2. **PDF export** -- key differentiator, professional output
3. **Dark Mode** -- App Store expectation, Apple design guidelines
4. **Dynamic Type** -- accessibility, Apple values this in review
5. **Field-Ready styling** -- domain-specific UX excellence
6. **MVVM refactor** -- code quality for maintainability
7. **About screen** -- author credit, professional feel
8. **Localization fix** (hardcoded Polish in HistoryRowView)
9. **Zero warnings, correct Bundle ID, iOS 17+ target** -- deployment readiness
10. **README + LICENSE** -- professional open-source package

### Already Complete (preserve, don't break)

- Core calculations (total chemical, total water, tank count)
- Unit support (ha, ar, m2)
- History (50 items, UserDefaults)
- Favorites (save/load)
- PL/EN localization
- Tractor animation
- Input validation with haptic feedback

## Competitor Landscape Summary

**Confidence: MEDIUM** -- Based on training data knowledge of agricultural apps. Cannot verify current App Store listings.

| Competitor Type | Typical Features | Where They Fall Short |
|-----------------|------------------|----------------------|
| **Big Ag company apps** (Syngenta, BASF, Bayer) | Product databases, weather, full-featured | Locked to their products only, heavy, require accounts, often poor UX |
| **Extension service tools** (ODR, university tools) | Accurate calculations, trusted | Desktop-only or web-only, not mobile-optimized, outdated UI |
| **Independent calc apps** (TankMix, SprayerCalc) | Simple, focused | Basic UI, no history/favorites, no Polish language, no PDF export |
| **This app's niche** | Simple + professional + Polish + offline + history + PDF | Fills gap: Polish farmer needs a fast, trustworthy, offline tool |

### Competitive Advantage Summary

This app's strongest differentiating combination:
1. **Polish-first** (most competing apps are English-only)
2. **Offline + no account** (big ag apps require registration and connectivity)
3. **History + Favorites** (most simple calculators are stateless)
4. **PDF export** (professional documentation for regulatory needs)
5. **Field-ready design** (purpose-built for outdoor/sunlight use)
6. **Per-tank composition** (surprisingly, many apps only show totals, not per-tank breakdown)

## Sources

- Training data knowledge of agricultural spray calculation domain (MEDIUM confidence)
- PROJECT.md existing requirements and constraints (HIGH confidence -- actual project state)
- Knowledge of EU/Polish agricultural regulations and farmer workflows (MEDIUM confidence)
- Knowledge of iOS App Store requirements and design guidelines (MEDIUM-HIGH confidence)
- Unable to verify against live App Store listings or competitor websites (web tools unavailable)

**Key uncertainty:** Competitor feature sets may have changed since training data cutoff. The feature categorization (table stakes vs. differentiator) is based on the agricultural calculator domain generally, not a live competitive analysis. The recommendations remain sound because they're grounded in farmer workflow needs, which don't change with app updates.
