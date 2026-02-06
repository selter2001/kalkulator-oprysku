# Architecture Patterns

**Domain:** iOS SwiftUI agricultural calculator with PDF export
**Researched:** 2026-02-06
**Confidence:** HIGH (SwiftUI MVVM is a mature, well-documented pattern; iOS 17+ APIs are stable)

## Current State Analysis

The existing app has 12 Swift files in a flat `SprayCalculator/` directory:

| File | Current Role | Problem |
|------|-------------|---------|
| `SprayCalculatorApp.swift` | App entry point | Fine as-is |
| `Models.swift` | Data models | Needs splitting into separate model files |
| `ContentView.swift` | Main view + calculation logic | Logic must move to ViewModel |
| `Components.swift` | Reusable UI components | Good — keep, possibly split |
| `Colors.swift` | Hardcoded color values | Must become adaptive theme system |
| `LocalizationManager.swift` | Manual PL/EN translation manager | Works — needs minor cleanup |
| `SettingsView.swift` | Settings screen | Fine — just wire to ViewModel |
| `HistoryManager.swift` | UserDefaults history persistence | Good — stays as Service |
| `HistoryView.swift` | History list display | Has hardcoded Polish — needs fix |
| `FavoritesManager.swift` | UserDefaults favorites persistence | Good — stays as Service |
| `FavoritesView.swift` | Favorites list display | Fine |
| `TractorAnimation.swift` | Tractor animation during calc | Keep as-is — it's fun |

**Core problems:**
1. Calculation logic lives inside `ContentView` — untestable, unmaintainable
2. Colors are hardcoded `Color.white`, `Color(red:...)` — break in dark mode
3. No folder structure — 12 files in one directory
4. No PDF export capability yet
5. `HistoryRowView` has hardcoded Polish text

## Recommended Architecture: MVVM + Services

```
┌─────────────────────────────────────────────────────────┐
│                        App                               │
│  SprayCalculatorApp.swift                                │
│  (creates root view, injects dependencies)               │
└──────────────┬──────────────────────────────────────────┘
               │
    ┌──────────▼──────────┐
    │    ViewModels        │
    │                      │
    │  CalcViewModel       │◄──── @Observable (iOS 17+)
    │  HistoryViewModel    │      owns business logic
    │  FavoritesViewModel  │      exposes @Published-like
    │  SettingsViewModel   │      state to Views
    └──────────┬──────────┘
               │ uses
    ┌──────────▼──────────┐
    │    Services          │
    │                      │
    │  SprayCalculator     │◄──── pure calculation engine
    │  PDFExportService    │◄──── ImageRenderer → PDF Data
    │  HistoryManager      │◄──── UserDefaults persistence
    │  FavoritesManager    │◄──── UserDefaults persistence
    │  LocalizationManager │◄──── PL/EN string provider
    └──────────┬──────────┘
               │ operates on
    ┌──────────▼──────────┐
    │    Models            │
    │                      │
    │  SprayInput          │◄──── user input parameters
    │  SprayResult         │◄──── calculation output
    │  TankBreakdown       │◄──── per-tank chemical + water
    │  HistoryEntry        │◄──── saved calculation record
    │  FavoriteConfig      │◄──── saved favorite config
    │  AreaUnit            │◄──── ha, ar, m² enum
    └─────────────────────┘

    ┌─────────────────────┐
    │    Views             │
    │                      │
    │  ContentView         │◄──── main calculator screen
    │  ResultsView         │◄──── detailed results display
    │  HistoryView         │◄──── history list
    │  FavoritesView       │◄──── favorites list
    │  SettingsView        │◄──── settings screen
    │  AboutView           │◄──── "about this app" screen
    │  Components/         │◄──── reusable UI pieces
    │    InputField.swift  │
    │    TractorAnimation  │
    │    ResultCard.swift   │
    └─────────────────────┘

    ┌─────────────────────┐
    │    Theme             │
    │                      │
    │  AppColors           │◄──── Asset Catalog + Color extension
    │  AppFonts            │◄──── Dynamic Type scaled fonts
    │  AppSpacing          │◄──── consistent layout values
    └─────────────────────┘
```

## File/Folder Structure

Concrete folder layout inside `SprayCalculator/`:

```
SprayCalculator/
├── SprayCalculatorApp.swift          # @main entry point
│
├── Models/
│   ├── SprayInput.swift              # input parameters struct
│   ├── SprayResult.swift             # calculation result struct
│   ├── TankBreakdown.swift           # per-tank breakdown (water + chemical)
│   ├── HistoryEntry.swift            # history record (Codable)
│   ├── FavoriteConfig.swift          # favorite config (Codable)
│   └── AreaUnit.swift                # ha/ar/m² enum
│
├── ViewModels/
│   ├── CalcViewModel.swift           # main calculator logic
│   ├── HistoryViewModel.swift        # history list management
│   ├── FavoritesViewModel.swift      # favorites management
│   └── SettingsViewModel.swift       # settings + localization state
│
├── Views/
│   ├── ContentView.swift             # main calculator screen (thin)
│   ├── ResultsView.swift             # results display
│   ├── HistoryView.swift             # history list
│   ├── FavoritesView.swift           # favorites list
│   ├── SettingsView.swift            # settings screen
│   ├── AboutView.swift               # about screen (author, version)
│   └── Components/
│       ├── InputField.swift          # labeled text field
│       ├── ResultCard.swift          # result display card
│       ├── TankDetailRow.swift       # single tank breakdown row
│       └── TractorAnimation.swift    # tractor animation
│
├── Services/
│   ├── SprayCalculator.swift         # pure calculation engine
│   ├── PDFExportService.swift        # ImageRenderer PDF generation
│   ├── HistoryManager.swift          # UserDefaults history
│   ├── FavoritesManager.swift        # UserDefaults favorites
│   └── LocalizationManager.swift     # PL/EN string provider
│
├── Theme/
│   ├── AppColors.swift               # Color extension using Asset Catalog
│   ├── AppFonts.swift                # Dynamic Type font definitions
│   └── AppSpacing.swift              # layout constants
│
├── Resources/
│   └── Localizable.xcstrings         # (optional, if migrating from manual)
│
└── Assets.xcassets/
    ├── AccentColor.colorset/         # primary accent (adaptive)
    ├── AppColors/
    │   ├── FieldGreen.colorset/      # brand green (adaptive)
    │   ├── SoilBrown.colorset/       # brand brown (adaptive)
    │   ├── CardBackground.colorset/  # card surface (adaptive)
    │   ├── InputBackground.colorset/ # input field bg (adaptive)
    │   └── WarningRed.colorset/      # validation error (adaptive)
    └── AppIcon.appiconset/
```

**Total: ~28 files in organized folders** (up from 12 flat files).

## Component Boundaries

### What Talks to What

```
View ──reads──► ViewModel ──calls──► Service ──operates on──► Model
View ◄─binds─── ViewModel ◄─returns── Service
View NEVER calls Service directly
ViewModel NEVER creates Views
Service NEVER imports SwiftUI (except PDFExportService)
Model has ZERO dependencies
```

**Strict rules:**

| Component | Can Import | Cannot Import |
|-----------|-----------|---------------|
| Model | Foundation | SwiftUI, Observation |
| Service | Foundation, SwiftUI (PDFExportService only) | Observation |
| ViewModel | Foundation, Observation, SwiftUI (for Color? No.) | UIKit |
| View | SwiftUI | Foundation services directly |
| Theme | SwiftUI | Everything else |

### CalcViewModel — The Core

This is the most important refactor target. It extracts all calculation logic from `ContentView`.

```swift
import Observation
import Foundation

@Observable
class CalcViewModel {
    // MARK: - Input State (bound to text fields)
    var fieldAreaText: String = ""
    var chemicalRateText: String = ""
    var sprayRateText: String = ""
    var tankCapacityText: String = ""
    var selectedUnit: AreaUnit = .hectare

    // MARK: - Output State
    var result: SprayResult?
    var validationErrors: [String: String] = [:]
    var isCalculating: Bool = false

    // MARK: - Dependencies
    private let calculator: SprayCalculator
    private let historyManager: HistoryManager
    private let localization: LocalizationManager

    init(calculator: SprayCalculator = SprayCalculator(),
         historyManager: HistoryManager,
         localization: LocalizationManager) {
        self.calculator = calculator
        self.historyManager = historyManager
        self.localization = localization
    }

    // MARK: - Actions
    func calculate() { /* validate, compute, save to history */ }
    func clear() { /* reset all fields */ }
    func loadFavorite(_ config: FavoriteConfig) { /* populate fields */ }

    // MARK: - Validation
    private func validate() -> SprayInput? { /* parse & validate */ }
}
```

**Key design decisions:**
- Uses `@Observable` macro (iOS 17+) — NOT `ObservableObject`/`@Published`. The `@Observable` macro is simpler, more performant (fine-grained tracking), and is Apple's recommended approach for iOS 17+.
- Dependency injection via `init` — testable, no singletons for core logic.
- Text fields are `String` (not `Double`) — validation happens in ViewModel, not View.

### PDFExportService — ImageRenderer Pattern

```swift
import SwiftUI

struct PDFExportService {

    @MainActor
    func generatePDF(result: SprayResult,
                     input: SprayInput,
                     localization: LocalizationManager) -> Data? {
        let view = PDFContentView(result: result,
                                   input: input,
                                   localization: localization)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0  // high resolution

        var pdfData = Data()

        // A4 page size in points: 595.28 x 841.89
        let pageRect = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)

        renderer.render { size, renderInContext in
            var mediaBox = pageRect
            guard let context = CGContext(consumer: CGDataConsumer(data: pdfData as! CFMutableData)!,
                                          mediaBox: &mediaBox,
                                          nil) else { return }
            context.beginPDFPage(nil)

            // Scale to fit page
            let scale = min(pageRect.width / size.width,
                           pageRect.height / size.height)
            context.scaleBy(x: scale, y: scale)

            renderInContext(context)
            context.endPDFPage()
            context.closePDF()
        }

        return pdfData
    }
}
```

**Key points:**
- `ImageRenderer` requires iOS 16+ (available on our iOS 17+ target).
- Must be called on `@MainActor` (it renders SwiftUI views).
- The PDF content is a separate SwiftUI view (`PDFContentView`) — NOT the screen view. This view is designed for print layout: white background, high contrast, no interactive elements.
- Includes author signature: "Obliczono w Kalkulator Oprysku - Wojciech Olszak".
- Uses `render { size, renderInContext in }` method for PDF (not `cgImage` which is for images).

**IMPORTANT CAVEAT (MEDIUM confidence):** The exact `render` API for PDF generation uses a closure pattern. The precise code for writing PDF data may need verification against Xcode autocomplete during implementation. The pattern above captures the concept correctly but the `CGDataConsumer` dance may need slight adjustments. An alternative simpler approach exists using `renderer.uiImage` and then converting UIImage to PDF via `UIGraphicsPDFRenderer` — this is more proven and may be more reliable.

### Simpler Alternative for PDF (HIGH confidence):

```swift
@MainActor
func generatePDF(result: SprayResult, input: SprayInput,
                 localization: LocalizationManager) -> Data {
    let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0,
                                                            width: 595, height: 842))

    let data = pdfRenderer.pdfData { context in
        context.beginPage()

        // Render SwiftUI view to UIImage first
        let view = PDFContentView(result: result, input: input,
                                   localization: localization)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0

        if let uiImage = renderer.uiImage {
            let imageRect = CGRect(x: 20, y: 20,
                                   width: 555, height: 802)
            uiImage.draw(in: imageRect)
        }
    }
    return data
}
```

**Recommendation: Use the `UIGraphicsPDFRenderer` + `ImageRenderer.uiImage` approach.** It is simpler, more widely documented, and less error-prone than the direct CGContext render path.

### Theme System — Asset Catalog Colors

**Do NOT define colors in code.** Use Xcode Asset Catalog with named color sets.

```
Assets.xcassets/
  AppColors/
    FieldGreen.colorset/
      Contents.json    ← defines light AND dark variants
    SoilBrown.colorset/
    CardBackground.colorset/
    InputBackground.colorset/
    TextPrimary.colorset/
    TextSecondary.colorset/
    WarningRed.colorset/
```

Each `.colorset` has a `Contents.json` like:
```json
{
  "colors": [
    {
      "color": { "color-space": "srgb", "components": { "red": "0.180", "green": "0.490", "blue": "0.196", "alpha": "1.000" }},
      "idiom": "universal",
      "appearances": [{ "appearance": "luminosity", "value": "light" }]
    },
    {
      "color": { "color-space": "srgb", "components": { "red": "0.298", "green": "0.686", "blue": "0.314", "alpha": "1.000" }},
      "idiom": "universal",
      "appearances": [{ "appearance": "luminosity", "value": "dark" }]
    }
  ]
}
```

Then in `AppColors.swift`:

```swift
import SwiftUI

extension Color {
    static let fieldGreen = Color("FieldGreen")
    static let soilBrown = Color("SoilBrown")
    static let cardBackground = Color("CardBackground")
    static let inputBackground = Color("InputBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let warningRed = Color("WarningRed")
}
```

**Why Asset Catalog over code:**
- Xcode provides visual color picker for both modes
- Automatic adaptation — zero runtime code needed
- Industry standard for iOS apps
- Works with SwiftUI's `@Environment(\.colorScheme)` automatically
- Storyboard/XIB compatible (not relevant here, but future-proof)

### "Field-Ready" High Contrast Design

Agricultural apps need extreme readability outdoors. Key considerations:

```swift
// AppFonts.swift
import SwiftUI

enum AppFonts {
    static let title = Font.title.weight(.bold)
    static let headline = Font.headline
    static let inputLabel = Font.subheadline.weight(.medium)
    static let inputValue = Font.title3.monospacedDigit()
    static let resultLarge = Font.largeTitle.weight(.heavy).monospacedDigit()
    static let resultUnit = Font.body.weight(.medium)
    static let caption = Font.caption
}
```

All use system fonts with Dynamic Type — no custom fonts needed. The `.monospacedDigit()` modifier keeps numbers aligned in results.

### Localization Architecture

The existing `LocalizationManager` uses a manual dictionary approach (not Apple's `.strings` files). **Keep this approach.** Rationale:

1. It already works and the app only has 2 languages (PL/EN)
2. Apple's `.strings`/`.xcstrings` system is designed for large apps with many languages
3. The manual manager allows runtime language switching without app restart
4. Migrating to `.xcstrings` would be significant effort with zero user-facing benefit

**Improvement needed:** Make it `@Observable` and ensure all views use it consistently (fix `HistoryRowView` hardcoded text).

```swift
@Observable
class LocalizationManager {
    var currentLanguage: Language = .polish

    enum Language: String, CaseIterable, Codable {
        case polish = "pl"
        case english = "en"
    }

    func text(_ key: String) -> String {
        translations[currentLanguage]?[key] ?? key
    }

    private let translations: [Language: [String: String]] = [
        .polish: [
            "fieldArea": "Powierzchnia pola",
            "chemicalRate": "Dawka srodka (l/ha)",
            // ... etc
        ],
        .english: [
            "fieldArea": "Field Area",
            "chemicalRate": "Chemical Rate (l/ha)",
            // ... etc
        ]
    ]
}
```

## Dependency Injection Strategy

Since there are no external DI frameworks (constraint: no SPM/CocoaPods), use manual constructor injection at the app level.

```swift
@main
struct SprayCalculatorApp: App {
    // Shared services — created once at app launch
    @State private var localization = LocalizationManager()
    @State private var historyManager = HistoryManager()
    @State private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(localization)
                .environment(historyManager)
                .environment(favoritesManager)
        }
    }
}
```

With `@Observable`, services injected via `.environment()` can be accessed in any view using `@Environment`:

```swift
struct ContentView: View {
    @Environment(LocalizationManager.self) private var localization
    @Environment(HistoryManager.self) private var historyManager

    @State private var viewModel: CalcViewModel

    init() {
        // ViewModel created in onAppear or via a factory
    }
}
```

**Note:** There is a chicken-and-egg issue with `@Environment` and ViewModel initialization. The cleanest pattern for iOS 17+:

```swift
struct ContentView: View {
    @Environment(HistoryManager.self) private var historyManager
    @Environment(LocalizationManager.self) private var localization
    @State private var viewModel = CalcViewModel()

    var body: some View {
        MainCalculatorView(viewModel: viewModel)
            .onAppear {
                viewModel.configure(historyManager: historyManager,
                                   localization: localization)
            }
    }
}
```

Or, simpler approach — just pass managers directly in the App and skip `@Environment` for managers:

```swift
@main
struct SprayCalculatorApp: App {
    @State private var localization = LocalizationManager()
    @State private var historyManager = HistoryManager()
    @State private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: CalcViewModel(
                    historyManager: historyManager,
                    localization: localization
                ),
                historyManager: historyManager,
                favoritesManager: favoritesManager,
                localization: localization
            )
        }
    }
}
```

**Recommendation: Use the simpler direct-passing approach.** For a small app with 4-5 screens, `@Environment` adds indirection without real benefit. Pass dependencies explicitly through init for clarity.

## Patterns to Follow

### Pattern 1: Thin Views, Fat ViewModels

**What:** Views contain ONLY layout and binding. All logic, validation, formatting lives in ViewModel.

**When:** Always. This is the core MVVM principle.

**Example — Before (current):**
```swift
// BAD: ContentView currently does this
struct ContentView: View {
    @State private var fieldArea = ""

    func calculate() {
        guard let area = Double(fieldArea) else { return }
        let totalWater = area * sprayRate
        let totalChemical = area * chemicalRate
        // ... lots of logic in the View
    }
}
```

**Example — After (target):**
```swift
// GOOD: View just binds
struct ContentView: View {
    @Bindable var viewModel: CalcViewModel

    var body: some View {
        VStack {
            TextField("Powierzchnia", text: $viewModel.fieldAreaText)
            Button("Oblicz") { viewModel.calculate() }
            if let result = viewModel.result {
                ResultsView(result: result)
            }
        }
    }
}
```

### Pattern 2: Value Types for Data, Reference Types for State

**What:** Models are `struct` (value semantics, Codable). ViewModels and Services are `class` (reference semantics, identity).

**When:** Always.

```swift
// Models = struct
struct SprayInput: Codable {
    let fieldArea: Double
    let areaUnit: AreaUnit
    let chemicalRate: Double  // l/ha or kg/ha
    let sprayRate: Double     // l/ha (water)
    let tankCapacity: Double  // liters
}

struct SprayResult: Codable {
    let totalWater: Double
    let totalChemical: Double
    let fullTanks: Int
    let remainderVolume: Double
    let tanks: [TankBreakdown]
}

struct TankBreakdown: Codable, Identifiable {
    let id: Int  // tank number (1-based)
    let waterAmount: Double
    let chemicalAmount: Double
    let totalVolume: Double
    let isFull: Bool
}

// ViewModels = class with @Observable
@Observable
class CalcViewModel { ... }

// Services = class with @Observable (if they have mutable state)
@Observable
class HistoryManager { ... }
```

### Pattern 3: Single Source of Truth for Navigation

**What:** Use `NavigationStack` with path-based navigation, not scattered `NavigationLink` destinations.

```swift
struct ContentView: View {
    @State private var selectedTab: Tab = .calculator

    enum Tab {
        case calculator, history, favorites, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CalculatorView(viewModel: viewModel)
            }
            .tabItem { Label("Kalkulator", systemImage: "function") }
            .tag(Tab.calculator)

            NavigationStack {
                HistoryView(viewModel: historyViewModel)
            }
            .tabItem { Label("Historia", systemImage: "clock") }
            .tag(Tab.history)

            // ... etc
        }
    }
}
```

**Note:** If the current app uses a single-page design with sheets/popovers, keep that. Don't force TabView if the app doesn't need it. This pattern is shown for reference if navigation grows.

## Anti-Patterns to Avoid

### Anti-Pattern 1: God ViewModel

**What:** Putting ALL app state into one massive ViewModel.

**Why bad:** Becomes unmaintainable, every view re-renders on any state change (even with @Observable's fine-grained tracking, conceptual coupling is the bigger problem).

**Instead:** One ViewModel per major screen. `CalcViewModel` for calculator, `HistoryViewModel` for history, etc. ViewModels can share services but not each other's state.

### Anti-Pattern 2: ObservableObject + @Published for iOS 17+

**What:** Using the old `ObservableObject` protocol with `@Published` property wrappers.

**Why bad:** On iOS 17+, `@Observable` macro is simpler, more performant (tracks individual property access, not whole-object), and is Apple's recommended path forward. Using the old pattern on a new project is technical debt from day one.

**Instead:** Use `@Observable` on all ViewModels and stateful Services. Use `@Bindable` in views for two-way binding. Use `@State` for view-local observable objects.

### Anti-Pattern 3: Color Literals in Views

**What:** `Color(red: 0.2, green: 0.5, blue: 0.3)` or `Color.white` in view code.

**Why bad:** Does not adapt to dark mode. Requires finding and changing every instance to support theming.

**Instead:** Define ALL colors in Asset Catalog with light/dark variants. Reference via `Color("ColorName")` or `Color.fieldGreen` extension.

### Anti-Pattern 4: Business Logic in View Body

**What:** Calculations, validation, formatting inside the view's `body` property or view helper methods.

**Why bad:** Untestable (can't test without rendering views), violates separation of concerns, makes views hard to read.

**Instead:** ALL logic goes through ViewModel methods. View only calls `viewModel.calculate()` and reads `viewModel.result`.

### Anti-Pattern 5: PDF as Screenshot of Screen View

**What:** Using `ImageRenderer` to capture the actual on-screen view for PDF.

**Why bad:** Screen views have interactive elements, dynamic layout, dark mode styling — none of which belong in a printable document. The result looks amateur.

**Instead:** Create a dedicated `PDFContentView` designed specifically for print: white background, structured layout, header with app name, footer with author credit, no buttons or interactive elements.

## Data Flow Diagrams

### Calculation Flow

```
User taps "Oblicz"
    │
    ▼
ContentView calls viewModel.calculate()
    │
    ▼
CalcViewModel.calculate()
    ├── validate() → parse text fields to SprayInput
    │   ├── Invalid → set validationErrors, return
    │   └── Valid → continue
    ├── calculator.compute(input) → SprayResult
    │   └── includes TankBreakdown for each tank
    ├── self.result = result
    └── historyManager.save(input, result)
    │
    ▼
SwiftUI detects result changed (@Observable)
    │
    ▼
ContentView re-renders → shows ResultsView
```

### PDF Export Flow

```
User taps "Eksport PDF"
    │
    ▼
CalcViewModel.exportPDF()
    │
    ▼
PDFExportService.generatePDF(result, input, localization)
    ├── Create PDFContentView (print-optimized SwiftUI view)
    ├── ImageRenderer → UIImage
    ├── UIGraphicsPDFRenderer → Data
    └── Return Data
    │
    ▼
CalcViewModel presents ShareSheet / saves to Files
    └── Uses fileExporter or ShareLink
```

### Dark Mode Adaptation Flow

```
System changes appearance (or user toggles)
    │
    ▼
@Environment(\.colorScheme) updates automatically
    │
    ▼
Asset Catalog colors resolve to correct variant
    ├── "FieldGreen" → light green (light mode)
    └── "FieldGreen" → brighter green (dark mode)
    │
    ▼
All views using Color.fieldGreen re-render
    └── Zero code needed — fully automatic
```

## Suggested Build Order (Refactor Sequence)

The refactor must be done in a specific order to avoid breaking the working app.

### Step 1: Create Folder Structure + Move Files (Non-Breaking)

Create the `Models/`, `Views/`, `ViewModels/`, `Services/`, `Theme/` folders in Xcode. Move existing files to their correct folders. This changes NO code — only file organization.

**Why first:** Zero risk. Gets the project organized before any logic changes. All files keep their content. Xcode handles the move via drag-and-drop (updates references in project file).

### Step 2: Extract Models (Low Risk)

Split `Models.swift` into individual model files: `SprayInput.swift`, `SprayResult.swift`, `TankBreakdown.swift`, `HistoryEntry.swift`, `FavoriteConfig.swift`, `AreaUnit.swift`.

Add the new `TankBreakdown` model for per-tank water/chemical composition.

**Why second:** Models have zero dependencies. Splitting them cannot break anything.

### Step 3: Create SprayCalculator Service (Medium Risk)

Extract calculation logic from `ContentView` into `Services/SprayCalculator.swift`. This is a pure function — input in, result out. No SwiftUI dependencies.

Add the tank breakdown calculation (water + chemical per tank, including partial last tank).

**Why third:** This is the core new feature (per-tank composition) and the core refactor target. It must be extracted before the ViewModel can use it.

### Step 4: Create CalcViewModel (Medium Risk)

Create `ViewModels/CalcViewModel.swift` with `@Observable`. Move all state and logic from `ContentView` into the ViewModel. Wire `ContentView` to use the ViewModel.

**Why fourth:** Depends on Models (step 2) and SprayCalculator service (step 3). This is the biggest single change. After this step, the app should work identically but with clean separation.

### Step 5: Theme System (Low Risk)

Create Asset Catalog color sets for all app colors. Create `Theme/AppColors.swift` extension. Replace all hardcoded colors across all views.

**Why fifth:** Independent of logic refactor. Can be done after MVVM is in place. Pure visual change — if a color is wrong, it's immediately visible and easy to fix.

### Step 6: PDF Export Service (Independent)

Create `Services/PDFExportService.swift` and `Views/Components/PDFContentView.swift`. Wire into CalcViewModel with an export action.

**Why sixth:** New feature, depends on having clean SprayResult model (step 2) and ViewModel (step 4).

### Step 7: Fix Localization + About View (Low Risk)

Fix `HistoryRowView` hardcoded Polish. Create `AboutView`. Clean up `LocalizationManager` to use `@Observable`.

**Why last:** Small fixes, low risk, can be done in any order after the main refactor.

## Scalability Considerations

| Concern | Current (1 user) | Future Consideration |
|---------|-------------------|---------------------|
| Data storage | UserDefaults (fine for <50 items) | If >100 items ever needed, migrate to SwiftData |
| Languages | Manual PL/EN dict | If 3+ languages, migrate to .xcstrings |
| PDF complexity | Single page | Multi-page needs `UIGraphicsPDFRenderer` with page breaks |
| Offline | Already fully offline | No concern |
| Performance | No concern at this scale | No concern at this scale |

This app is intentionally small and focused. Do NOT over-engineer for scale that will never come.

## Key Architecture Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | `@Observable` macro | iOS 17+ target, simpler than ObservableObject, Apple's recommended approach |
| Dependency injection | Manual constructor injection | No frameworks needed for 4 services, keeps zero-dependency constraint |
| Color theming | Asset Catalog color sets | Automatic dark/light mode, zero runtime code, industry standard |
| PDF generation | `UIGraphicsPDFRenderer` + `ImageRenderer.uiImage` | More reliable than direct CGContext rendering, well-documented |
| Localization | Keep manual `LocalizationManager` | Works, only 2 languages, allows runtime switching |
| Navigation | Keep existing structure | Small app doesn't need complex navigation architecture |
| Model types | `struct` (Codable) | Value semantics, easy persistence with UserDefaults |
| ViewModel types | `class` with `@Observable` | Reference semantics needed for shared mutable state |

## Sources

- Apple Developer Documentation: ImageRenderer (developer.apple.com — requires JS, verified against training knowledge)
- Apple Developer Documentation: Observation framework / @Observable macro (iOS 17+)
- Apple Developer Documentation: Asset Catalog color sets with appearances
- Apple Developer Documentation: UIGraphicsPDFRenderer
- SwiftUI MVVM patterns: widely documented, stable pattern since SwiftUI 2.0+

**Confidence notes:**
- MVVM structure: HIGH — mature, well-established pattern
- @Observable macro: HIGH — core iOS 17 feature, widely adopted
- Asset Catalog colors: HIGH — standard iOS practice since iOS 11
- ImageRenderer for PDF: MEDIUM — API is real and documented, but exact CGContext PDF rendering code may need adjustment during implementation; the UIGraphicsPDFRenderer alternative is HIGH confidence
- Manual localization approach: HIGH — simple, already working in the project
