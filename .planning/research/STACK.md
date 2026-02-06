# Technology Stack

**Project:** Kalkulator Oprysku (iOS Spray Calculator)
**Researched:** 2026-02-06
**Mode:** Stack dimension for App Store-quality SwiftUI app
**Constraint:** Zero external dependencies -- pure Swift/SwiftUI only (per PROJECT.md)

---

## Recommended Stack

### Core Platform

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Swift | 5.9+ | Language | Current stable Swift, ships with Xcode 15+. Required for `@Observable` macro and modern concurrency | HIGH |
| SwiftUI | iOS 17+ | UI Framework | Already in use. iOS 17 is the minimum for `ImageRenderer` PDF generation and `@Observable` macro | HIGH |
| Xcode | 15.0+ | IDE/Build | Required for iOS 17 SDK, Swift 5.9, and `@Observable` support | HIGH |

**Rationale:** iOS 17+ is the correct deployment target. As of early 2026, iOS 17 and 18 together cover ~95% of active iPhones. iOS 16 would block us from `ImageRenderer` (available iOS 16+, but the more robust PDF rendering APIs and `@Observable` require iOS 17). Targeting iOS 17 is the sweet spot: modern APIs, broad device coverage, no legacy baggage.

### Architecture Pattern: MVVM with @Observable

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| `@Observable` macro | iOS 17+ | ViewModel layer | Replaces `ObservableObject`/`@Published`. Less boilerplate, automatic property tracking, no `@Published` wrappers needed | HIGH |
| `@Environment` | iOS 13+ | Dependency injection | Standard SwiftUI DI mechanism for passing ViewModels and services | HIGH |
| `@Bindable` | iOS 17+ | Two-way binding to @Observable | Replaces `@ObservedObject` for `@Observable` classes. Use in Views that need to write back to ViewModel | HIGH |

**Architecture detail:**

```swift
// ViewModel -- uses @Observable (NOT ObservableObject)
@Observable
class SprayCalculatorViewModel {
    var fieldArea: String = ""
    var chemicalRate: String = ""
    var sprayRate: String = ""
    var tankCapacity: String = ""
    var selectedUnit: AreaUnit = .hectares

    // Computed results
    var result: SprayResult?
    var validationErrors: [ValidationError] = []

    func calculate() { /* ... */ }
}

// View -- uses @Bindable (NOT @ObservedObject)
struct CalculatorView: View {
    @Bindable var viewModel: SprayCalculatorViewModel
    // ...
}
```

**Why @Observable over ObservableObject:**
1. No `@Published` property wrappers needed -- every stored property is automatically observed
2. More granular tracking -- SwiftUI only re-renders when accessed properties change (not when ANY @Published changes)
3. Simpler syntax -- `@Bindable` instead of `@ObservedObject`, direct property access
4. Forward-compatible -- this is Apple's recommended pattern going forward
5. Better performance -- finer observation granularity means fewer unnecessary view updates

**What NOT to use:**
- `ObservableObject` + `@Published` -- legacy pattern, works but more boilerplate and coarser observation
- `@StateObject` -- replaced by `@State` for `@Observable` objects (use `@State var viewModel = SprayCalculatorViewModel()` at the ownership point)
- Combine framework for ViewModel binding -- unnecessary with `@Observable`, adds complexity

### PDF Generation: ImageRenderer

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| `ImageRenderer` | iOS 16+ (use with iOS 17+) | Render SwiftUI views to PDF | First-party, no dependencies. Renders any SwiftUI View to CGImage or PDF via Core Graphics | HIGH |
| `ShareLink` | iOS 16+ | Share generated PDF | Native share sheet integration, accepts `Transferable` items | HIGH |

**PDF generation pattern:**

```swift
@MainActor
func generatePDF(from view: some View) -> URL? {
    let renderer = ImageRenderer(content: view)

    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("spray-report.pdf")

    renderer.render { size, context in
        var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }

        pdf.beginPDFPage(nil)
        context(pdf)
        pdf.endPDFPage()
        pdf.closePDF()
    }

    return url
}
```

**Key considerations:**
- `ImageRenderer` runs on `@MainActor` -- must be called from main thread
- Set `renderer.scale = UIScreen.main.scale` for crisp output (or use fixed 2.0/3.0)
- The rendered View should be a dedicated `PDFReportView` -- NOT the on-screen view. Design it for A4 paper dimensions (595 x 842 points)
- For multi-page PDFs: call `beginPDFPage` / `endPDFPage` multiple times in the render closure
- Include: date, author credit ("Created by Wojciech Olszak"), calculation inputs, results, tank breakdown

**What NOT to use:**
- `UIGraphicsPDFRenderer` (UIKit) -- works but requires bridging to UIKit, defeats SwiftUI-native approach
- Third-party PDF libraries (TPPDF, PDFKit for generation) -- violates zero-dependency constraint
- `PDFDocument` from PDFKit -- this is for READING PDFs, not generating them
- WebView + HTML-to-PDF -- overly complex, fragile, unnecessary

### Dark Mode: Color Asset Catalog

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Asset Catalog Colors | iOS 11+ | Dark/light mode color pairs | Define once, automatic switching. Xcode built-in, zero code for mode detection | HIGH |
| `Color("assetName")` | iOS 13+ | Reference catalog colors | Standard SwiftUI pattern for named colors | HIGH |
| `@Environment(\.colorScheme)` | iOS 13+ | Detect current mode (when needed) | For conditional logic beyond color swapping | HIGH |
| `Color` extensions | N/A | Semantic color names | Type-safe color references avoid string typos | HIGH |

**Color system pattern:**

```swift
// Color extension for type safety
extension Color {
    static let fieldGreen = Color("FieldGreen")
    static let fieldBackground = Color("FieldBackground")
    static let fieldCardBackground = Color("FieldCardBackground")
    static let fieldAccent = Color("FieldAccent")
    static let fieldText = Color("FieldText")
    static let fieldSecondaryText = Color("FieldSecondaryText")
    static let fieldWarning = Color("FieldWarning")
    static let fieldSuccess = Color("FieldSuccess")
}
```

**Asset Catalog structure (in Assets.xcassets):**

For each color, define "Any Appearance" + "Dark" variant:

| Color Name | Light | Dark | Purpose |
|------------|-------|------|---------|
| FieldGreen | #2E7D32 (dark green) | #66BB6A (light green) | Primary brand/accent |
| FieldBackground | #F5F5F0 (warm off-white) | #1C1C1E (system dark) | Main background |
| FieldCardBackground | #FFFFFF | #2C2C2E | Card/section backgrounds |
| FieldText | #1A1A1A | #F5F5F5 | Primary text |
| FieldSecondaryText | #666666 | #ADADAD | Secondary/label text |
| FieldWarning | #E65100 (deep orange) | #FF9800 (orange) | Validation errors |
| FieldSuccess | #1B5E20 (forest green) | #81C784 (light green) | Success states |

**"Field-Ready" high contrast rationale:** These colors target WCAG AA contrast ratios (4.5:1 for text) in both modes. Agricultural apps are used outdoors in bright sunlight -- light mode needs dark-on-light with saturated accent colors. Dark mode is for evening/indoor use.

**What NOT to use:**
- `Color(red:green:blue:)` hardcoded -- currently in the codebase, must be replaced. Cannot adapt to dark mode
- `Color.white` / `Color.black` hardcoded -- same problem
- `UIColor.systemBackground` bridged to SwiftUI -- unnecessary, `Color(.systemBackground)` works but custom colors give more control
- `preferredColorScheme(.dark)` to force a mode -- let the user/system decide

### Dynamic Type

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| `.font(.title)` / `.body` / etc. | iOS 13+ | Semantic text styles | Automatically scale with Dynamic Type. Always prefer semantic styles over fixed sizes | HIGH |
| `@ScaledMetric` | iOS 14+ | Scale non-text dimensions | Scales spacing, icon sizes, padding proportionally to Dynamic Type setting | HIGH |
| `DynamicTypeSize` environment | iOS 15+ | Query current size | For conditional layouts at extreme sizes (accessibility sizes) | HIGH |
| `.dynamicTypeSize(...range)` | iOS 15+ | Clamp type scaling | Limit scaling range where layout would break | HIGH |

**Pattern:**

```swift
struct CalculatorView: View {
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 16
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: cardPadding) {
            // Use semantic fonts -- NEVER .font(.system(size: 18))
            Text("Powierzchnia pola")
                .font(.headline)

            TextField("np. 5.0", text: $viewModel.fieldArea)
                .font(.body)

            // Conditional layout for accessibility sizes
            if typeSize.isAccessibilitySize {
                VStack { /* vertical layout for large text */ }
            } else {
                HStack { /* horizontal layout for normal text */ }
            }
        }
    }
}
```

**What NOT to use:**
- `.font(.system(size: 18))` with fixed point sizes -- does not scale with Dynamic Type
- `.font(.custom("...", size: 14))` without `relativeTo:` -- custom fonts need `relativeTo:` to participate in Dynamic Type: `.font(.custom("Avenir", size: 17, relativeTo: .body))`
- Ignoring `isAccessibilitySize` -- at XXL/XXXL sizes, horizontal layouts overflow; must switch to vertical

### Data Persistence (existing -- no change)

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| `UserDefaults` | iOS 2+ | History + favorites storage | Already in use, sufficient for simple lists (max 50 items). No migration needed | HIGH |
| `Codable` | Swift 4+ | Serialization | Standard encoding/decoding for model types to UserDefaults | HIGH |

**What NOT to use (confirmed out of scope):**
- CoreData -- overkill for simple key-value + list storage
- SwiftData -- newer but adds complexity without benefit for this data model
- SQLite -- manual SQL management unnecessary
- iCloud sync -- explicitly out of scope per PROJECT.md

### Localization (existing -- minor fixes)

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Custom `LocalizationManager` | N/A | PL/EN switching | Already implemented, works well. Not Apple's `.strings` system but functional | HIGH |
| `String(localized:)` | iOS 16+ | Alternative if refactoring | Modern localization API, but switching mid-project is unnecessary churn | MEDIUM |

**Recommendation:** Keep existing `LocalizationManager`. Fix `HistoryRowView` hardcoded Polish text to use it. Do NOT migrate to Apple's `.strings` system -- the existing approach works and migration adds risk without value.

### Sharing and Export

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| `ShareLink` | iOS 16+ | Share PDF via share sheet | Declarative, one-line share button. Accepts URL to generated PDF file | HIGH |
| `FileManager.temporaryDirectory` | iOS 2+ | Temp storage for generated PDF | Write PDF here before sharing; system cleans up automatically | HIGH |

**Pattern:**

```swift
ShareLink(
    item: pdfURL,
    preview: SharePreview("Raport oprysku", icon: Image(systemName: "doc.richtext"))
)
```

### App Metadata and Deployment

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| `Info.plist` | N/A | App metadata | Bundle ID, version, display name, supported orientations | HIGH |
| Asset Catalog `AppIcon` | N/A | App icon | Required for App Store. Must provide 1024x1024 single icon (Xcode 15+ generates all sizes) | HIGH |
| `CFBundleIdentifier` | N/A | Bundle ID | Format: `com.wojciecholszak.spraycalculator` -- must be unique for physical device deployment | HIGH |

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Observation | `@Observable` macro | `ObservableObject` + `@Published` | Legacy pattern, more boilerplate, coarser reactivity |
| PDF Generation | `ImageRenderer` | `UIGraphicsPDFRenderer` | UIKit dependency, more complex bridging code |
| PDF Generation | `ImageRenderer` | Third-party (TPPDF) | Violates zero-dependency constraint |
| Dark Mode | Asset Catalog Colors | Hardcoded `Color(red:...)` | Cannot adapt to dark mode (current problem) |
| Dark Mode | Asset Catalog Colors | `UIColor.systemBackground` bridge | Less control over brand colors |
| State Management | `@Observable` + MVVM | TCA (The Composable Architecture) | External dependency, overkill for this app's complexity |
| State Management | `@Observable` + MVVM | Redux-like patterns | Over-engineering for a calculator |
| Navigation | `NavigationStack` | `NavigationView` | `NavigationView` deprecated in iOS 16 |
| Data Storage | `UserDefaults` | SwiftData | Unnecessary complexity, overkill for max 50 items |
| Localization | Keep `LocalizationManager` | Migrate to `.strings` | Working system, migration is risk without reward |

---

## File Structure Recommendation (MVVM)

```
SprayCalculator/
  App/
    SprayCalculatorApp.swift          -- @main entry point
    Info.plist
  Model/
    SprayResult.swift                 -- Calculation result model
    SprayConfiguration.swift          -- Saved configuration / favorite
    AreaUnit.swift                    -- Unit enum (ha, ar, m2)
    HistoryEntry.swift                -- History record model
  ViewModel/
    SprayCalculatorViewModel.swift    -- Main calculator logic (@Observable)
    HistoryViewModel.swift            -- History management (@Observable)
    FavoritesViewModel.swift          -- Favorites management (@Observable)
  View/
    Calculator/
      CalculatorView.swift            -- Main input form
      ResultView.swift                -- Calculation results display
      TankBreakdownView.swift         -- Per-tank water/chemical detail
    History/
      HistoryView.swift               -- History list
      HistoryRowView.swift            -- Single history entry
    Favorites/
      FavoritesView.swift             -- Saved configurations
    Settings/
      SettingsView.swift              -- Language, about
      AboutView.swift                 -- Author info
    PDF/
      PDFReportView.swift             -- A4-formatted view for PDF export
    Shared/
      TractorAnimationView.swift      -- Tractor loading animation
  Resources/
    Assets.xcassets/                   -- Colors + AppIcon
    Localizable/
      LocalizationManager.swift       -- Existing localization system
  Utilities/
    Extensions.swift                  -- Color extensions, formatters
```

---

## iOS Version API Summary

Every API used and its minimum iOS version:

| API | Minimum iOS | Our Target (17+) | Status |
|-----|-------------|-------------------|--------|
| SwiftUI | 13.0 | 17.0 | Available |
| `@Observable` macro | 17.0 | 17.0 | Available |
| `@Bindable` | 17.0 | 17.0 | Available |
| `ImageRenderer` | 16.0 | 17.0 | Available |
| `ShareLink` | 16.0 | 17.0 | Available |
| `NavigationStack` | 16.0 | 17.0 | Available |
| `@ScaledMetric` | 14.0 | 17.0 | Available |
| `DynamicTypeSize` | 15.0 | 17.0 | Available |
| `.dynamicTypeSize()` modifier | 15.0 | 17.0 | Available |
| `Color("named")` | 13.0 | 17.0 | Available |
| `@Environment(\.colorScheme)` | 13.0 | 17.0 | Available |
| `UserDefaults` | 2.0 | 17.0 | Available |
| `Codable` | Swift 4 | 17.0 | Available |
| Asset Catalog Colors | 11.0 | 17.0 | Available |

**All APIs are comfortably within iOS 17+ target. No availability issues.**

---

## Installation / Setup

No package installation needed (zero dependencies). Setup is Xcode-only:

```
1. Open SprayCalculator.xcodeproj in Xcode 15+
2. Set deployment target: iOS 17.0
3. Set Bundle Identifier: com.wojciecholszak.spraycalculator
4. Set Team: (developer's personal team for device deployment)
5. Build & Run -- zero warnings required
```

---

## Sources and Confidence Notes

| Claim | Confidence | Basis |
|-------|------------|-------|
| `@Observable` requires iOS 17+ | HIGH | Well-documented Apple API, part of Observation framework introduced at WWDC23 |
| `ImageRenderer` available iOS 16+, PDF via `render()` closure | HIGH | Stable Apple API, introduced at WWDC22, widely documented |
| `@Bindable` replaces `@ObservedObject` for `@Observable` | HIGH | Core part of Observation framework, extensively covered in WWDC23 sessions |
| `@ScaledMetric` available iOS 14+ | HIGH | Stable API, 3+ years old, well-established |
| `DynamicTypeSize.isAccessibilitySize` | HIGH | Standard accessibility API, iOS 15+ |
| `ShareLink` accepts URL and shows share sheet | HIGH | Standard ShareKit API, iOS 16+ |
| Asset Catalog colors auto-switch for dark mode | HIGH | Core iOS feature since iOS 11/13, fundamental pattern |
| Xcode 15+ generates all icon sizes from 1024x1024 | HIGH | Announced at WWDC23, well-established workflow |
| WCAG AA contrast ratio 4.5:1 for text | HIGH | W3C standard, not Apple-specific |
| Specific hex color values for "Field-Ready" palette | MEDIUM | Recommended values based on agricultural UX patterns, should be validated visually |
| iOS 17/18 combined market share ~95% | MEDIUM | Based on typical Apple OS adoption rates, exact figure may vary |

**Note:** WebSearch and WebFetch were unavailable during this research session. All findings are based on training knowledge of Apple's well-documented, stable APIs. These APIs (ImageRenderer, @Observable, Asset Catalog colors, Dynamic Type) have been stable for 1-3 years and are unlikely to have changed. Confidence is HIGH for API availability and patterns, MEDIUM for specific color values and market share figures.
