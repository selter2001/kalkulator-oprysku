# Project Research Summary

**Project:** Kalkulator Oprysku (Agricultural Spray Calculator for iOS)
**Domain:** iOS SwiftUI App Store-ready agricultural utility app
**Researched:** 2026-02-06
**Confidence:** MEDIUM-HIGH

## Executive Summary

Kalkulator Oprysku is an iOS agricultural spray calculator designed for Polish farmers working in field conditions. The app calculates chemical mixing ratios for crop protection applications, helping farmers determine how much product and water to pour into each sprayer tank load. Research reveals this is a well-understood domain with clear technical patterns: SwiftUI MVVM architecture using iOS 17+ `@Observable` macro, Asset Catalog-based dark mode theming, and `ImageRenderer` for PDF export. The app targets a competitive but underserved niche—Polish-language, offline-first spray calculators with professional features like history tracking, favorites, and PDF documentation.

The recommended approach is a focused MVVM refactor followed by parallel dark mode and PDF export implementation. The existing codebase has solid fundamentals (calculation logic, persistence, localization) but mixes UI and business logic, uses hardcoded colors that break in dark mode, and lacks the per-tank composition breakdown that farmers actually need at the sprayer. The refactor must carefully preserve working features while establishing clean boundaries for testability and maintainability.

Key risks center on iOS 17 API patterns—`@Observable` macro is fundamentally different from `ObservableObject` and mixing the two breaks observation silently. `ImageRenderer` must run on MainActor or produces blank PDFs. Dark mode requires a coordinated color system, not one-off fixes. The app is targeting App Store release, so professional polish matters: zero warnings, correct Bundle ID, privacy policy, proper screenshots, and Dynamic Type support for accessibility. Research shows these pitfalls are preventable with upfront design rather than incremental fixes.

## Key Findings

### Recommended Stack

The app targets iOS 17+ to leverage modern SwiftUI patterns, achieving ~95% iPhone market coverage while accessing cutting-edge APIs. iOS 17 is the sweet spot: `@Observable` macro eliminates boilerplate, `ImageRenderer` enables native PDF generation, and Asset Catalog colors provide automatic dark mode adaptation—all with zero external dependencies per project constraints.

**Core technologies:**
- **Swift 5.9+ / SwiftUI iOS 17+**: Current stable release, required for `@Observable` macro and `ImageRenderer` PDF APIs
- **@Observable macro**: Replaces `ObservableObject`/`@Published` with simpler syntax, finer observation granularity, and better performance
- **ImageRenderer + UIGraphicsPDFRenderer**: First-party PDF generation from SwiftUI views, no third-party dependencies
- **Asset Catalog Colors**: Define light/dark color pairs once, automatic mode switching with zero runtime code
- **@ScaledMetric + Dynamic Type**: Proportional scaling for accessibility—critical for outdoor use by older farmers
- **UserDefaults + Codable**: Existing persistence layer, sufficient for max 50 history items, no migration needed

**What NOT to use:**
- `ObservableObject`/`@Published` (legacy, more boilerplate, coarser tracking)
- Third-party PDF libraries (violates zero-dependency constraint)
- Hardcoded `Color(red:green:blue:)` literals (cannot adapt to dark mode)
- CoreData/SwiftData (overkill for simple key-value storage)

### Expected Features

Agricultural spray calculators solve a specific farmer workflow: calculate mixing ratios for tank sprayers. Research identifies table stakes versus differentiators based on competitive landscape and farmer needs.

**Must have (table stakes):**
- Per-tank composition (water + chemical for full AND partial tanks)—the actual question farmers need answered at the sprayer
- Tank division (full + partial) with last-tank remainder calculation
- Unit support: hectares, ares, square meters (EU/Polish standard)
- Input validation with clear error messages
- High-contrast "field-ready" UI for outdoor sunlight readability
- Offline functionality (fields have poor connectivity)
- Polish language (target market)
- Dark mode support (iOS standard since iOS 13, App Store expectation)

**Should have (competitive differentiators):**
- PDF export of calculation results—professional documentation for regulatory compliance, rare in competing apps
- Calculation history (max 50 items)—farmers reuse similar configs season to season
- Favorites / saved configurations—named presets for common product+field combinations
- PL/EN bilingual support—Polish farmers work in multilingual contexts
- Tractor animation—delightful UX touch, makes app feel agricultural rather than generic
- Dynamic Type support—accessibility for older farmers, Apple values this in App Store review
- About screen with author credit—builds trust, professional feel

**Defer (v2+):**
- Multi-product tank mix (2-3 products + adjuvant in one tank)—requires compatibility logic, significantly complex
- Product database / label lookup—regulatory burden, frequent updates required
- Nozzle/pressure calibration calculator—different domain from mixing calculation
- Weather advisory for spray conditions—requires API, online connectivity
- GPS field area measurement—major feature, different UX paradigm
- Spray diary / regulatory logging (EU IPM compliance)—database needed, export formats

**Anti-features (explicitly avoid):**
- Product compatibility checker—liability risk if wrong, requires extensive testing
- Dose recommendation engine—the label IS the law, app must never suggest doses
- AI/ML "smart" features—farmers want reliable, predictable tools
- Social features / sharing spray programs—privacy concern, unlicensed advice risk
- User accounts / registration—friction for zero benefit, farmers abandon apps that demand this

### Architecture Approach

SwiftUI MVVM with `@Observable` provides clean separation between UI and business logic while maintaining SwiftUI's declarative style. The existing 12-file flat structure refactors into organized folders (Models/, ViewModels/, Views/, Services/, Theme/) with ~28 total files.

**Major components:**

1. **Models (struct, value types)** — SprayInput, SprayResult, TankBreakdown, HistoryEntry, FavoriteConfig, AreaUnit. All Codable for UserDefaults persistence. No logic, pure data containers.

2. **ViewModels (@Observable class)** — CalcViewModel (main calculator logic), HistoryViewModel, FavoritesViewModel, SettingsViewModel. Own business logic, validation, formatting. Expose state to Views via automatic observation. Injected via constructor, not singletons.

3. **Services (class or struct)** — SprayCalculator (pure calculation engine, no SwiftUI), PDFExportService (ImageRenderer wrapper), HistoryManager (UserDefaults persistence), FavoritesManager, LocalizationManager. Services do NOT observe state—they're called by ViewModels.

4. **Views (thin, layout only)** — ContentView, ResultsView, HistoryView, FavoritesView, SettingsView, AboutView, plus Components/ folder (InputField, ResultCard, TactorAnimation). Views bind to ViewModels via `@Bindable`, contain ZERO business logic.

5. **Theme (Color extensions + Asset Catalog)** — AppColors (fieldGreen, soilBrown, cardBackground, textPrimary, warningRed) with light/dark variants defined in Asset Catalog. Referenced via `Color.fieldGreen` for type safety. "Field-Ready" high-contrast palette for outdoor readability.

**Key patterns:**
- Thin views, fat ViewModels—all logic, validation, formatting lives in ViewModels
- Value types for data (struct), reference types for state (class with @Observable)
- Manual constructor injection for services—no DI frameworks needed at this scale
- Dedicated PDFContentView for export—NOT a screenshot of the screen view, designed for print layout
- Asset Catalog colors with semantic naming—one definition, automatic adaptation

### Critical Pitfalls

Research identifies 16 pitfalls across critical/moderate/minor severity. Top 5 for roadmap planning:

1. **MVVM Over-Engineering (God ViewModel)** — Moving ALL logic into one massive ViewModel is worse than the original. Split by responsibility: InputViewModel (fields + validation), SprayCalculator (pure functions), HistoryManager (persistence). Use `@Observable` macro for fine-grained tracking. Rule: if ViewModel exceeds 6-8 properties, split it.

2. **@Observable vs ObservableObject Confusion** — iOS 17+ uses `@Observable` macro, NOT `ObservableObject`/`@Published`. Mixing both breaks observation silently. Use `@State` for ownership, plain property access for reading, `@Bindable` for bindings. NEVER use `@StateObject` or `@ObservedObject` with `@Observable` classes—silent failure.

3. **ImageRenderer Runs Off-MainActor** — `ImageRenderer` must run on `@MainActor` or produces blank/corrupted PDFs with no error. Mark PDF generation method explicitly `@MainActor`. Test on real device (Simulator masks threading issues). Always open generated PDF to verify content, not just file existence.

4. **App Store Rejection for Missing Privacy Policy** — Even simple utility apps need a privacy policy URL in App Store Connect. Can be minimal: "This app does not collect any personal data." Create GitHub Pages or simple HTML before first submission attempt.

5. **Dark Mode Without a System** — Replacing colors one-by-one with inline conditionals creates inconsistent, unmaintainable mess. Define Asset Catalog color sets FIRST with semantic names (background, primaryAction, fieldText, cardBackground, warningRed). Each has light AND dark variants. Then do single pass replacing ALL hardcoded colors.

**Other key pitfalls:**
- ImageRenderer doesn't inherit environment—explicitly inject locale, colorScheme (always light for PDFs)
- MVVM refactor can break `@State` ownership—input state stays in View, only logic moves to ViewModel
- Bundle Identifier must match Apple Developer account—set correct Bundle ID early, test on real device
- Dynamic Type breaks fixed-size layouts—test at max accessibility size, use ScrollView and flexible frames
- Localization regression—existing `HistoryRowView` has hardcoded Polish, new views prone to same issue

## Implications for Roadmap

Based on research, the work naturally divides into 3 phases with clear dependencies and parallel opportunities.

### Phase 1: Foundation & MVVM Refactor
**Rationale:** Clean architecture is a prerequisite for everything else. Cannot safely add dark mode or PDF export to mixed-concern views. The refactor is medium-risk but enables low-risk parallel work afterward.

**Delivers:**
- Organized folder structure (Models/, ViewModels/, Views/, Services/, Theme/)
- Split Models.swift into individual model files + new TankBreakdown model
- SprayCalculator service with per-tank composition calculation (the core missing feature)
- CalcViewModel with `@Observable` macro, validated input, clean state management
- Fix HistoryRowView hardcoded Polish text
- Preserve ALL working features (history, favorites, PL/EN, tractor animation, validation)

**Addresses:** Table stakes per-tank composition feature, foundation for differentiators (PDF, dark mode)

**Avoids:**
- Pitfall 1 (God ViewModel)—split by responsibility from the start
- Pitfall 2 (@Observable confusion)—establish pattern correctly in first ViewModel
- Pitfall 7 (breaking @State ownership)—input state stays in View
- Pitfall 12 (localization regression)—fix HistoryRowView, enforce no bare strings

**Research flag:** Standard MVVM patterns, well-documented. Skip /gsd:research-phase.

### Phase 2: Visual Polish (Dark Mode + Dynamic Type + Field-Ready Styling)
**Rationale:** Can proceed in parallel after Phase 1 completes. Visual changes are independent of PDF export. Dark mode requires coordinated system design (Asset Catalog), not incremental fixes. Dynamic Type testing reveals layout issues that must be fixed before App Store submission.

**Delivers:**
- Asset Catalog color sets with light/dark variants for all app colors
- Theme/AppColors.swift extension with semantic color names (fieldGreen, soilBrown, cardBackground, textPrimary, warningRed)
- "Field-Ready" high-contrast palette for outdoor sunlight readability
- Replace ALL hardcoded colors across all views
- @ScaledMetric for proportional spacing/icon sizing with Dynamic Type
- Test and fix layout at max accessibility text size (accessibility3)
- Fix deprecated API warnings (NavigationView → NavigationStack, .foregroundColor → .foregroundStyle, onChange signature)

**Addresses:** Dark mode (table stakes), Dynamic Type (differentiator), field-ready design (differentiator)

**Avoids:**
- Pitfall 5 (color-by-color replacement without system)—design Asset Catalog FIRST
- Pitfall 9 (Dynamic Type breaks layout)—test at max size, use flexible frames
- Pitfall 10 (Xcode warnings from deprecated APIs)—clean pass fixing all warnings
- Pitfall 13 (Asset Catalog name mismatch)—central AppColors enum catches typos

**Research flag:** Standard Asset Catalog + Dynamic Type patterns. Skip /gsd:research-phase.

### Phase 3: PDF Export & App Store Preparation
**Rationale:** Depends on Phase 1 (clean ViewModel provides data) and Phase 2 (styled views inform PDF design). PDF export is the key differentiator. App Store prep is final packaging work.

**Delivers:**
- PDFExportService using UIGraphicsPDFRenderer + ImageRenderer.uiImage pattern
- PDFContentView designed for print: A4 layout, white background, high contrast, no interactive elements
- Include: calculation inputs, results, per-tank breakdown, date, author credit ("Obliczono w Kalkulator Oprysku - Wojciech Olszak")
- ShareLink integration for sharing/saving PDF
- AboutView with author info, app version, contact
- Privacy policy page (GitHub Pages or simple HTML)
- Correct Bundle Identifier for App Store (com.wojciecholszak.kalkulatoroprysku)
- App icon (1024x1024, Xcode generates all sizes)
- App Store screenshots at required dimensions (6.7" display: 1290 x 2796 px)
- Zero Xcode warnings, test on real device
- README + LICENSE for open-source package

**Addresses:** PDF export (differentiator), About screen (differentiator), App Store polish (table stakes)

**Avoids:**
- Pitfall 3 (ImageRenderer off-MainActor)—mark method @MainActor, test on device
- Pitfall 4 (missing privacy policy)—create before first submission
- Pitfall 6 (ImageRenderer ignores environment)—always render PDFs in light mode
- Pitfall 8 (wrong Bundle Identifier)—set early, verify on real device
- Pitfall 11 (PDF file sharing fails)—use temp directory, keep URL reference alive
- Pitfall 14 (tractor animation blocks render)—stop animation during PDF generation
- Pitfall 15 (.xcuserdata in git)—update .gitignore
- Pitfall 16 (wrong screenshot dimensions)—capture from correct Simulator devices

**Research flag:** ImageRenderer PDF generation has MEDIUM confidence on exact API (CGContext dance). Consider /gsd:research-phase if implementation issues arise. Alternative UIGraphicsPDFRenderer + uiImage pattern is HIGH confidence fallback.

### Phase Ordering Rationale

**Sequential dependency:** Phase 1 → Phase 2/3 (parallel)
- MVVM refactor (Phase 1) must complete before visual changes (Phase 2) to avoid duplicating effort across old and new code structure
- MVVM refactor (Phase 1) must complete before PDF export (Phase 3) to provide clean data for PDF rendering
- Dark mode (Phase 2) and PDF export (Phase 3) are independent and can proceed in parallel after Phase 1

**Grouping logic:**
- Phase 1 groups related architecture changes—all refactoring together minimizes disruption
- Phase 2 groups all visual/styling work—Asset Catalog design informs all color decisions at once
- Phase 3 groups export + packaging—both are "polish" work for App Store readiness

**Pitfall avoidance:**
- Starting with color fixes before refactor would duplicate work (changing colors in views that will be rewritten)
- Starting with PDF export before refactor would tightly couple to messy view structure
- Attempting all work in one phase risks God ViewModel (Pitfall 1) and incomplete testing

### Research Flags

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (MVVM Refactor):** Well-established SwiftUI MVVM pattern, `@Observable` macro extensively documented by Apple
- **Phase 2 (Dark Mode/Dynamic Type):** Asset Catalog colors and Dynamic Type are mature iOS features with extensive guidance

**Phases potentially needing deeper research:**
- **Phase 3 (PDF Export):** ImageRenderer CGContext rendering has MEDIUM confidence on exact implementation. If initial attempt produces blank PDFs or crashes, trigger `/gsd:research-phase pdf-generation-swiftui` to investigate. The UIGraphicsPDFRenderer + ImageRenderer.uiImage alternative is HIGH confidence fallback—use if direct rendering fails.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | iOS 17 APIs (`@Observable`, `ImageRenderer`, Asset Catalog) are well-documented, stable. Zero external dependencies simplifies risk. |
| Features | MEDIUM-HIGH | Table stakes features identified from domain knowledge and PROJECT.md requirements. Competitive analysis based on training data (cannot verify live App Store). Farmer workflow patterns are stable. |
| Architecture | HIGH | MVVM with `@Observable` is Apple's recommended pattern for iOS 17+, extensively covered in WWDC23 sessions. File structure and component boundaries are standard iOS practices. |
| Pitfalls | MEDIUM-HIGH | SwiftUI patterns (God ViewModel, @Observable confusion, Dynamic Type issues) are well-known from community experience. ImageRenderer threading and PDF generation are documented but have edge cases. App Store requirements (privacy policy, Bundle ID, screenshots) are official Apple guidelines. |

**Overall confidence:** MEDIUM-HIGH

Research is based on stable, well-documented Apple APIs and established iOS patterns. The main uncertainty is ImageRenderer's exact CGContext PDF rendering API (MEDIUM confidence on implementation details), but a proven fallback exists (UIGraphicsPDFRenderer + uiImage). Feature expectations are grounded in domain knowledge but competitive landscape cannot be live-verified. All technical risks are mitigable with proper planning and testing on real devices.

### Gaps to Address

**ImageRenderer PDF rendering implementation:** The exact CGContext dance for writing PDF data from ImageRenderer.render() closure may need adjustment during Phase 3 implementation. Research provides two approaches: direct CGContext rendering (MEDIUM confidence) and UIGraphicsPDFRenderer + uiImage conversion (HIGH confidence). Plan: attempt direct rendering first, fall back to uiImage conversion if issues arise. Worst case, trigger `/gsd:research-phase pdf-generation-swiftui` if both approaches fail.

**App Store screenshot requirements:** Specific required dimensions for 2026 iPhone models may have updated since training data (iPhone 16 series). Plan: verify exact requirements at App Store Connect during Phase 3. Xcode Simulator provides correct device frames—screenshot from recommended devices and App Store Connect will validate dimensions.

**Competitive feature validation:** Cannot verify live competitor feature sets from App Store listings. Table stakes identification is based on domain workflow patterns (stable) rather than competitive analysis (uncertain). Plan: if roadmap planning reveals uncertainty about feature priority, trigger `/gsd:research-phase competitor-analysis-spray-calculators` for live verification.

**Localization completeness:** Existing LocalizationManager may be missing keys for new features (PDF export, About screen). Plan: during Phase 3, audit all new UI strings and add to LocalizationManager dictionary. Test language switch covers all screens including PDF output.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: `@Observable` macro and Observation framework (iOS 17+, introduced WWDC23)
- Apple Developer Documentation: ImageRenderer API (iOS 16+, stable since WWDC22)
- Apple Developer Documentation: Asset Catalog color sets with appearance variants (iOS 11+)
- Apple Developer Documentation: Dynamic Type and @ScaledMetric (iOS 14+)
- Apple Developer Documentation: UIGraphicsPDFRenderer (mature UIKit API)
- Apple App Store Review Guidelines (fetched 2026-02-06 per PITFALLS.md)
- PROJECT.md existing requirements and constraints (actual project state)

### Secondary (MEDIUM confidence)
- SwiftUI MVVM patterns with `@Observable` (widely documented community pattern, WWDC23 sessions)
- iOS 17 market share ~95% combined iOS 17/18 (based on typical Apple adoption rates, not verified live)
- Agricultural spray calculator domain workflows (stable farmer needs, not dependent on specific app features)
- "Field-Ready" color palette recommendations (based on WCAG contrast ratios and agricultural UX patterns, should be validated visually)
- Competitor feature landscape (training data knowledge of agricultural app domain, cannot verify live App Store listings)

### Tertiary (LOW confidence)
- Exact App Store screenshot dimensions for iPhone 16 series (may have updated, verify at submission)
- Specific hex color values for recommended palette (suggestions, need visual validation in bright sunlight)

---
*Research completed: 2026-02-06*
*Ready for roadmap: yes*
