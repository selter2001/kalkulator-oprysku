# Phase 1: Foundation & MVVM - Research

**Researched:** 2026-02-06
**Domain:** SwiftUI MVVM refactor, @Observable migration, per-tank composition calculation, localization fixes
**Confidence:** HIGH

## Summary

Phase 1 transforms a working but flat 12-file SwiftUI spray calculator into a cleanly architected MVVM app with per-tank composition breakdowns and fully localized UI. The codebase currently has all calculation logic embedded inside views (specifically `CalculatorViewWithFavorite` in `ContentView.swift`), uses legacy `ObservableObject`/`@Published`/`@StateObject` patterns, has hardcoded Polish text in `HistoryRowView` and `SettingsView`, and contains a dead duplicate `CalculatorView.swift` file.

The refactor involves three interconnected workstreams: (1) file restructuring into Model/View/ViewModel/Services/Theme folders with corresponding pbxproj updates, (2) extracting business logic into `CalcViewModel` using `@Observable` macro and creating a `SprayCalculator` service that computes per-tank water+chemical composition, and (3) fixing all hardcoded Polish strings to use `LocalizationManager`. The deployment target is already iOS 17.0, but the project uses PBXGroup-based organization (Xcode 15 era) and `SWIFT_VERSION = 5.0`, both of which should be updated.

**Primary recommendation:** Restructure files first (zero logic change, low risk), then extract ViewModel + SprayCalculator service with per-tank composition, then fix localization. Each step must leave the app in a buildable, working state.

## Standard Stack

### Core

| Technology | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `@Observable` macro | iOS 17+ / Observation framework | ViewModel state management | Replaces `ObservableObject`/`@Published` with simpler syntax, finer-grained property tracking, fewer view redraws. Apple's recommended path forward. |
| `@Bindable` | iOS 17+ | Two-way binding in views | Replaces `@ObservedObject` for `@Observable` classes. Required for `$viewModel.field` bindings in TextFields |
| `@State` (for @Observable) | iOS 17+ | ViewModel ownership in views | Replaces `@StateObject`. Creates and owns the `@Observable` instance at the view identity level |
| `.environment()` | iOS 17+ | DI for shared services | Injects `@Observable` instances into view hierarchy. Use with `@Environment(Type.self)` to read |

### Supporting

| Technology | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `@Environment(Type.self)` | iOS 17+ | Read injected @Observable services | For shared state like LocalizationManager, HistoryManager accessed across many views |
| `NumberFormatter` | Foundation | Number formatting/parsing | Already in use for comma/dot decimal handling. Keep as-is. |
| `UserDefaults` + `Codable` | Foundation | History/favorites persistence | Already working. No changes needed in Phase 1. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|-----------|-----------|----------|
| `@Observable` | Keep `ObservableObject`/`@Published` | Would work but is legacy pattern, coarser observation, more boilerplate. Since target is iOS 17+, no reason to keep old pattern. |
| `@Environment` for all managers | Direct init injection | Simpler for small app, but `@Environment` scales better for views deep in hierarchy (like HistoryRowView needing localization) |
| Splitting into 6+ model files | Keep single `Models.swift` | Single file is fine for 3 types. Split only if adding new models. |

## Architecture Patterns

### Recommended Project Structure

```
SprayCalculator/
  SprayCalculatorApp.swift           # @main entry, creates services, injects via .environment()
  Models/
    SprayCalculation.swift           # Existing model (renamed from Models.swift), add waterPerTank computed props
    FavoriteConfiguration.swift      # Extracted from Models.swift
    AreaUnit.swift                   # Extracted from Models.swift
  ViewModels/
    CalcViewModel.swift              # @Observable -- owns input state, calls SprayCalculator, saves history
  Views/
    ContentView.swift                # TabView shell, thin -- delegates to sub-views
    CalculatorView.swift             # Rewritten: binds to CalcViewModel via @Bindable
    HistoryView.swift                # Existing, with HistoryRowView fixed for localization
    FavoritesView.swift              # Existing, minimal changes (wire to @Environment)
    SettingsView.swift               # Existing, fix hardcoded Polish
    Components/
      SprayInputField.swift          # Extracted from Components.swift
      ResultCard.swift               # Extracted from Components.swift
      PrimaryButton.swift            # Extracted from Components.swift
      SecondaryButton.swift          # Extracted from Components.swift
      SectionHeader.swift            # Extracted from Components.swift
      DetailRow.swift                # Extracted from HistoryView.swift
  Services/
    SprayCalculator.swift            # Pure calculation engine (struct, no SwiftUI)
    HistoryManager.swift             # Migrated to @Observable
    FavoritesManager.swift           # Migrated to @Observable
    LocalizationManager.swift        # Migrated to @Observable, add missing keys
  Theme/
    Colors.swift                     # Existing (keep as-is for Phase 1, Phase 2 replaces with Asset Catalog)
  Animation/
    TractorAnimation.swift           # Existing, no changes
  Assets.xcassets/                   # Existing
```

### Pattern 1: @Observable ViewModel with @Bindable

**What:** ViewModel is an `@Observable` class. Views receive it and use `@Bindable` for two-way TextField bindings.

**When to use:** For the main CalcViewModel that manages calculator input/output state.

**Example:**

```swift
// Source: Apple Observation framework docs + nilcoalescing.com/blog/ObservableInSwiftUI/

import Observation

@Observable
class CalcViewModel {
    // Input state (bound to TextFields)
    var fieldAreaText: String = ""
    var sprayRateText: String = ""
    var chemicalRateText: String = ""
    var tankCapacityText: String = ""
    var selectedAreaUnit: AreaUnit = .hectares

    // Output state
    var calculationResult: SprayCalculation?
    var showResults: Bool = false
    var showAnimation: Bool = false
    var shakingFields: Set<String> = []
    var showError: Bool = false
    var errorMessage: String = ""

    // Dependencies
    private let calculator = SprayCalculator()
    private let historyManager: HistoryManager

    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
    }

    func calculate() { /* validate, compute, save to history */ }
    func clear() { /* reset all fields */ }
    func loadFavorite(_ favorite: FavoriteConfiguration) { /* populate fields */ }
}
```

```swift
// View binding pattern
struct CalculatorView: View {
    @Bindable var viewModel: CalcViewModel
    @Environment(LocalizationManager.self) private var localization

    var body: some View {
        // Use $viewModel.fieldAreaText for TextField binding
        SprayInputField(
            title: localization.fieldArea,
            unit: viewModel.selectedAreaUnit.displayName,
            value: $viewModel.fieldAreaText,
            icon: "square.dashed",
            isShaking: viewModel.shakingFields.contains("fieldArea")
        )
    }
}
```

### Pattern 2: @Observable Service Migration

**What:** Migrate existing `ObservableObject` services to `@Observable` macro.

**When to use:** For HistoryManager, FavoritesManager, LocalizationManager.

**Example (before/after):**

```swift
// BEFORE (current)
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: Language { ... }
}
// Used as: @EnvironmentObject var localization: LocalizationManager

// AFTER (target)
@Observable
class LocalizationManager {
    var currentLanguage: Language { ... }  // No @Published needed
}
// Used as: @Environment(LocalizationManager.self) private var localization
```

### Pattern 3: Environment Injection at App Level

**What:** Create @Observable services in App struct with @State, inject via .environment().

```swift
@main
struct SprayCalculatorApp: App {
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

### Pattern 4: @Bindable from @Environment

**What:** When an @Observable is injected via @Environment, create a local @Bindable to get bindings.

```swift
struct SomeView: View {
    @Environment(CalcViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel  // Local rebinding for $ access
        TextField("Area", text: $viewModel.fieldAreaText)
    }
}
```

### Anti-Patterns to Avoid

- **Mixing @Observable with @StateObject/@ObservedObject:** Compiles but observation silently breaks. NEVER use `@StateObject` or `@ObservedObject` with `@Observable` classes.
- **Mixing @Observable with @Published:** `@Published` inside an `@Observable` class is ignored. Remove all `@Published` wrappers when adding `@Observable` macro.
- **God ViewModel:** Do NOT put history management, favorites management, localization, AND calculation logic into one ViewModel. CalcViewModel handles calculation flow only. Managers stay as separate services.
- **Moving ALL @State to ViewModel:** UI-only state like `showSaveDialog`, `favoriteName` (for the sheet) can stay as `@State` in the view. Only move business-relevant state to ViewModel.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-tank water calculation | Inline math in views | `SprayCalculation.waterPerFullTank` computed property | Single source of truth, tested once, used everywhere |
| Number parsing (comma/dot) | New parser | Existing `parseNumber()` function (keep, move to ViewModel) | Already handles Polish comma and international dot |
| Number formatting | New formatter | Existing `formatNumber()` function (keep, move to ViewModel/service) | Already configured for Polish locale |
| File restructuring | Manual pbxproj editing | Xcode GUI drag-and-drop or "Convert to Folder" | pbxproj is complex binary-like format, manual edits are error-prone |

**Key insight:** The per-tank composition calculation is trivial -- `waterPerFullTank = tankCapacity - chemicalPerTank`. The model already computes `chemicalPerTank` and `chemicalForPartialTank`. The "missing feature" is just 2 computed properties and updated results UI, NOT a complex algorithm.

## Common Pitfalls

### Pitfall 1: @Observable + @StateObject/ObservedObject Silent Breakage

**What goes wrong:** Using `@StateObject` or `@ObservedObject` property wrappers with a class marked `@Observable` compiles without error but observation silently breaks -- views never update when properties change.

**Why it happens:** `@StateObject`/`@ObservedObject` look for `ObservableObject` protocol conformance and `@Published` properties. The `@Observable` macro uses the Observation framework instead. The two systems are incompatible at the observation level.

**How to avoid:** Enforce project-wide convention:
- `@Observable` class -> `@State` for ownership, plain parameter for passing, `@Bindable` for bindings
- Search codebase for `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published` -- ALL must be removed/replaced
- Run app after each file migration and verify that UI updates when changing values

**Warning signs:** After refactoring a class to `@Observable`, toggles/inputs stop working. TextField shows typing but computed results never update.

### Pitfall 2: @State Initializer Runs Multiple Times (vs @StateObject Once)

**What goes wrong:** `@State` for `@Observable` objects runs the initializer every time SwiftUI rebuilds the view hierarchy, unlike `@StateObject` which ran it once. If the initializer has side effects (loading data, registering notifications), they execute repeatedly.

**Why it happens:** `@State` receives the value directly, not wrapped in `@autoclosure` like `@StateObject` was.

**How to avoid:**
- Declare app-level state (HistoryManager, FavoritesManager, LocalizationManager) in the `App` struct, NOT in individual views
- CalcViewModel should be created at `ContentView` level with `@State` -- it's fine because it has no expensive init
- Managers load data in `init()` from UserDefaults -- this is cheap and idempotent, so repeated init is harmless as long as there's only one instance (which @State at App level guarantees)

**Warning signs:** Duplicate notification handlers, history loading multiple times, memory growing unexpectedly.

### Pitfall 3: Dead Code / Duplicate Calculator Logic

**What goes wrong:** The current codebase has TWO copies of the calculator UI logic:
1. `CalculatorView` in `CalculatorView.swift` (appears unused)
2. `CalculatorViewWithFavorite` in `ContentView.swift` (the one actually rendered)

If the refactor modifies the wrong copy, changes have no effect.

**Why it happens:** `CalculatorView.swift` was likely the original, then `CalculatorViewWithFavorite` was created in `ContentView.swift` to handle the favorites-loading flow. The original was never deleted.

**How to avoid:** Delete `CalculatorView.swift` (the standalone one) during restructuring. The `CalculatorViewWithFavorite` in `ContentView.swift` is the real implementation. During MVVM extraction, this becomes the new `CalculatorView` backed by `CalcViewModel`.

**Warning signs:** Making changes to CalculatorView and seeing no effect in the running app.

### Pitfall 4: pbxproj Corruption During File Restructuring

**What goes wrong:** Manually editing `project.pbxproj` to add/remove/move files corrupts the project file. Xcode cannot open the project.

**Why it happens:** The pbxproj format has cross-referenced UUIDs across multiple sections (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase). Missing or mismatched references break the file.

**How to avoid:**
- **Preferred:** Use Xcode GUI to create folder groups and drag files into them. Xcode updates pbxproj automatically.
- **Alternative for Xcode 16+:** Convert project to use folder-based organization ("Migrate to Folder Based Project Navigator" in Xcode), then files on disk = files in project automatically.
- **If editing pbxproj programmatically:** Use the `xcodeproj` Ruby gem or Tuist's XcodeProj Swift package. Never edit by hand.
- **Always:** Commit working pbxproj BEFORE restructuring. If it breaks, revert.

**Warning signs:** Xcode shows "The file couldn't be opened" or files appear with red icons in Project Navigator.

### Pitfall 5: Localization Regression in New Views

**What goes wrong:** New views or refactored views use hardcoded English strings ("Calculate", "Results") instead of `localization.calculate`, `localization.results`. The app appears to work in Polish but English is broken (or vice versa).

**Why it happens:** When rewriting views, it's natural to use string literals first and "add localization later." But later never comes, or some strings are missed.

**How to avoid:**
- Rule: EVERY user-facing string in a View MUST go through `LocalizationManager`
- The `TractorSprayingAnimation` currently has hardcoded `"Obliczanie..."` (line 40) -- this needs fixing too
- After completing Phase 1, manually switch to English and visually inspect EVERY screen
- Add any missing localization keys to `LocalizationManager`

**Warning signs:** Switching to English and seeing Polish text anywhere on any screen.

## Code Examples

### Per-Tank Composition (the core new feature)

```swift
// Add to existing SprayCalculation model
// Source: Direct calculation from existing chemicalPerTank formula

extension SprayCalculation {
    /// Water to pour into each full tank (liters)
    var waterPerFullTank: Double {
        tankCapacity - chemicalPerTank
    }

    /// Water to pour into the last partial tank (liters)
    var waterForPartialTank: Double {
        partialTankVolume - chemicalForPartialTank
    }
}
```

That's it. The model already computes `chemicalPerTank`, `chemicalForPartialTank`, `partialTankVolume`, and `tankCapacity`. Water is simply the remainder.

### SprayCalculator Service (pure calculation engine)

```swift
// Services/SprayCalculator.swift
import Foundation

struct SprayCalculator {
    func calculate(
        fieldArea: Double,
        areaUnit: AreaUnit,
        sprayRate: Double,
        chemicalRate: Double,
        tankCapacity: Double
    ) -> SprayCalculation {
        SprayCalculation(
            fieldArea: fieldArea,
            areaUnit: areaUnit,
            sprayRate: sprayRate,
            chemicalRate: chemicalRate,
            tankCapacity: tankCapacity
        )
    }
}
```

Note: The existing `SprayCalculation` model already has all computed properties. The service is thin -- it's a construction + validation wrapper. The real value is separating the "call site" from views.

### CalcViewModel Core

```swift
// ViewModels/CalcViewModel.swift
import Observation
import Foundation

@Observable
class CalcViewModel {
    // MARK: - Input State
    var fieldAreaText: String = ""
    var sprayRateText: String = ""
    var chemicalRateText: String = ""
    var tankCapacityText: String = ""
    var selectedAreaUnit: AreaUnit = .hectares

    // MARK: - Output State
    var calculationResult: SprayCalculation?
    var showResults: Bool = false
    var showAnimation: Bool = false
    var shakingFields: Set<String> = []
    var showError: Bool = false
    var errorMessage: String = ""

    // MARK: - Dependencies
    private let calculator = SprayCalculator()
    private let historyManager: HistoryManager

    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
    }

    // MARK: - Actions
    func calculate() {
        let fields = validateFields()
        guard fields.isValid else {
            shakeInvalidFields(fields.invalidFields)
            return
        }

        guard let area = parseNumber(fieldAreaText),
              let spray = parseNumber(sprayRateText),
              let chemical = parseNumber(chemicalRateText),
              let tank = parseNumber(tankCapacityText) else {
            showError = true
            return
        }

        let result = calculator.calculate(
            fieldArea: area,
            areaUnit: selectedAreaUnit,
            sprayRate: spray,
            chemicalRate: chemical,
            tankCapacity: tank
        )

        calculationResult = result
        historyManager.addCalculation(result)
        showResults = false
        showAnimation = true
    }

    func clear() {
        fieldAreaText = ""
        sprayRateText = ""
        chemicalRateText = ""
        tankCapacityText = ""
        calculationResult = nil
        showResults = false
    }

    func loadFavorite(_ favorite: FavoriteConfiguration) {
        sprayRateText = formatNumber(favorite.sprayRate)
        chemicalRateText = formatNumber(favorite.chemicalRate)
        tankCapacityText = formatNumber(favorite.tankCapacity)
        selectedAreaUnit = favorite.areaUnit
    }

    func onAnimationComplete() {
        showAnimation = false
        showResults = true
    }

    // MARK: - Private
    private func validateFields() -> (isValid: Bool, invalidFields: [String]) {
        var invalid: [String] = []
        if fieldAreaText.isEmpty { invalid.append("fieldArea") }
        if sprayRateText.isEmpty { invalid.append("sprayRate") }
        if chemicalRateText.isEmpty { invalid.append("chemicalRate") }
        if tankCapacityText.isEmpty { invalid.append("tankCapacity") }
        return (invalid.isEmpty, invalid)
    }

    private func shakeInvalidFields(_ fields: [String]) {
        shakingFields = Set(fields)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.shakingFields.removeAll()
        }
    }

    func parseNumber(_ string: String) -> Double? {
        let normalized = string.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
```

### Localization Fixes

```swift
// HistoryRowView -- BEFORE (hardcoded Polish)
private var tankFillsText: String {
    if calculation.hasPartialTank {
        return "\(calculation.fullTanks) pelne + 1 czesciowe (\(formatNumber(calculation.partialTankVolume)) l)"
    }
    return "\(calculation.fullTanks) pelne"
}

// HistoryRowView -- AFTER (localized)
// Requires @Environment(LocalizationManager.self) private var localization
private var tankFillsText: String {
    if calculation.hasPartialTank {
        return "\(calculation.fullTanks) \(localization.fullTanks) + 1 \(localization.partialTank) (\(formatNumber(calculation.partialTankVolume)) l)"
    }
    return "\(calculation.fullTanks) \(localization.fullTanks)"
}

// Also fix DetailRow labels:
// "Ciecz robocza" -> localization.workingFluid
// "Srodek" -> localization.chemical
// "Napelnienia" -> localization.tankFills
```

```swift
// SettingsView -- BEFORE (hardcoded Polish)
Text("Wersja")
Text("Informacje")

// SettingsView -- AFTER (localized)
// Add to LocalizationManager:
var version: String {
    currentLanguage == .polish ? "Wersja" : "Version"
}
var information: String {
    currentLanguage == .polish ? "Informacje" : "Information"
}
```

```swift
// TractorAnimation -- BEFORE (hardcoded Polish)
Text(isAnimating ? "Obliczanie..." : "")

// TractorAnimation -- AFTER (localized)
// Add to LocalizationManager:
var calculating: String {
    currentLanguage == .polish ? "Obliczanie..." : "Calculating..."
}
// Pass via parameter or @Environment
```

### Updated Results Section (showing per-tank composition)

```swift
// New result cards for per-tank composition (CALC-01, CALC-02)
if let result = viewModel.calculationResult {
    // Existing: total working fluid, total chemical, tank fills

    // NEW: Full tank composition (CALC-01)
    ResultCard(
        icon: "tank_icon",
        title: localization.fullTankComposition,
        value: "\(formatNumber(result.waterPerFullTank)) l \(localization.water) + \(formatNumber(result.chemicalPerTank)) l \(localization.chemical)",
        unit: "",
        delay: 0.4
    )

    // NEW: Partial tank composition (CALC-02)
    if result.hasPartialTank {
        ResultCard(
            icon: "partial_tank_icon",
            title: localization.partialTankComposition,
            value: "\(formatNumber(result.waterForPartialTank)) l \(localization.water) + \(formatNumber(result.chemicalForPartialTank)) l \(localization.chemical)",
            unit: "",
            delay: 0.5
        )
    }

    // NEW: Total chemical to buy (CALC-03)
    ResultCard(
        icon: "shopping_icon",
        title: localization.totalChemicalToBuy,
        value: formatNumber(result.totalChemical),
        unit: localization.liters,
        delay: 0.6
    )
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|-------------|-----------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 (WWDC 2023) | Simpler syntax, fine-grained tracking, better performance |
| `@StateObject` | `@State` for @Observable | iOS 17 (WWDC 2023) | Different init semantics (runs every rebuild vs once) -- declare in App struct for singletons |
| `@ObservedObject` | Plain parameter or `@Bindable` | iOS 17 (WWDC 2023) | `@Bindable` only needed for `$` binding access |
| `@EnvironmentObject` | `@Environment(Type.self)` | iOS 17 (WWDC 2023) | Type-based lookup instead of protocol-based |
| `.environmentObject()` | `.environment()` | iOS 17 (WWDC 2023) | Simpler injection API |
| PBXGroup in Xcode | Folder-based project navigator | Xcode 16 (2024) | Files on disk = files in Xcode, reduced merge conflicts |
| `SWIFT_VERSION = 5.0` | Swift 6.2 (on this machine) | 2025 | Strict concurrency by default, Approachable Concurrency |

**Deprecated/outdated:**
- `ObservableObject` protocol: Still works but Apple recommends `@Observable` for iOS 17+
- `@Published` property wrapper: Ignored inside `@Observable` classes
- `@StateObject`: Does NOT work with `@Observable` -- silent failure
- `@EnvironmentObject`: Replaced by `@Environment(Type.self)` for `@Observable` classes

## Codebase-Specific Findings

### Critical Discovery: Duplicate Calculator Code

The codebase contains TWO implementations of the calculator UI:

1. **`CalculatorView.swift`** -- standalone struct, NOT used anywhere in the running app
2. **`ContentView.swift`** contains `CalculatorViewWithFavorite` -- this is the ACTUAL implementation rendered by the app

The app uses: `ContentView` -> `CalculatorViewWrapper` -> `CalculatorViewWithFavorite`

**Action:** Delete `CalculatorView.swift` during restructuring. Use `CalculatorViewWithFavorite` as the basis for the new `CalculatorView` backed by `CalcViewModel`.

### Current pbxproj State

- `objectVersion = 56` (Xcode 14 compatibility)
- `LastSwiftUpdateCheck = 1500; LastUpgradeCheck = 1500` (created in Xcode 15.0)
- `SWIFT_VERSION = 5.0`
- PBXGroup-based file organization (NOT folder-based)
- `developmentRegion = pl` (Polish primary)
- 14 PBXBuildFile entries, 14 PBXFileReference entries
- All files flat in one PBXGroup

**File restructuring strategy:** Either (a) drag files into new groups in Xcode GUI and let it update pbxproj, or (b) convert to Xcode 16+ folder-based project. Option (b) is better long-term but riskier in a single step. **Recommend option (a)** -- create groups, move files, verify build after each batch.

### Existing Localization Gaps

Files with hardcoded Polish that need fixing:

| File | Line(s) | Hardcoded Text | Localization Key Needed |
|------|---------|---------------|------------------------|
| `HistoryView.swift` (HistoryRowView) | 87-89 | `"Ciecz robocza"`, `"Srodek"`, `"Napelnienia"` | `localization.workingFluid`, `.chemical`, `.tankFills` |
| `HistoryView.swift` (tankFillsText) | 110-112 | `"pelne"`, `"czesciowe"` | `localization.fullTanks`, `.partialTank` |
| `SettingsView.swift` | 32, 45 | `"Wersja"`, `"Informacje"` | New keys: `localization.version`, `.information` |
| `TractorAnimation.swift` | 40 | `"Obliczanie..."` | New key: `localization.calculating` |

### Per-Tank Composition Math (CALC-01, CALC-02, CALC-03)

The model already has the core formulas. Missing computed properties:

```
Given: chemicalPerTank = (chemicalRate / sprayRate) * tankCapacity
Need:  waterPerFullTank = tankCapacity - chemicalPerTank

Given: chemicalForPartialTank = (chemicalRate / sprayRate) * partialTankVolume
Need:  waterForPartialTank = partialTankVolume - chemicalForPartialTank

CALC-03 (total chemical to buy) = totalChemical (already exists as fieldAreaInHectares * chemicalRate)
```

**Complexity: Very Low.** Two computed property additions to existing model. The UI needs new ResultCard entries to display them.

### New LocalizationManager Keys Needed

```
fullTankComposition: "Sklad pelnego zbiornika" / "Full tank composition"
partialTankComposition: "Sklad niepelnego zbiornika" / "Partial tank composition"
water: "Woda" / "Water"
totalChemicalToBuy: "Srodek do kupienia" / "Chemical to buy"
version: "Wersja" / "Version"
information: "Informacje" / "Information"
calculating: "Obliczanie..." / "Calculating..."
```

### Haptic Feedback

Currently in `CalculatorViewWithFavorite.shakeInvalidFields()`:
```swift
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.error)
```

And in `PrimaryButton`:
```swift
let impact = UIImpactFeedbackGenerator(style: .medium)
impact.impactOccurred()
```

**Action:** Move haptic trigger to CalcViewModel for shake (it's business logic -- validation failed). Keep PrimaryButton haptic in the view (it's UI feedback on tap).

### Swift 6 Concurrency Consideration

The machine runs Swift 6.2 with Xcode 26. The project has `SWIFT_VERSION = 5.0`. When this is updated:

- **Swift 6 strict concurrency** will flag data races
- `@Observable` classes accessed from views are implicitly on MainActor (SwiftUI views run on MainActor)
- `HistoryManager` and `FavoritesManager` access UserDefaults (MainActor-safe as UserDefaults is thread-safe)
- **Recommendation for Phase 1:** Keep `SWIFT_VERSION = 5.0` or update to `6.0` with `SWIFT_STRICT_CONCURRENCY = minimal`. Full Swift 6 strict concurrency migration is out of scope -- it's a rabbit hole that would derail the phase.

## Open Questions

1. **Should the project convert to Xcode folder-based organization?**
   - What we know: Current project uses PBXGroup. Xcode 16+ supports folder-based (simpler, auto-syncs). The user has Xcode 26.
   - What's unclear: Whether the conversion tool works cleanly on this specific project.
   - Recommendation: Use PBXGroup approach (create groups, drag files) for safety. Convert to folder-based in a later phase if desired.

2. **Should SWIFT_VERSION be updated?**
   - What we know: Currently 5.0. Machine has Swift 6.2. `@Observable` works fine with Swift 5.9+.
   - What's unclear: Whether updating to 6.0 triggers strict concurrency errors that would block the phase.
   - Recommendation: Leave at 5.0 for Phase 1. Update in Phase 3 (zero warnings cleanup).

3. **CalculatorViewWrapper indirection -- keep or simplify?**
   - What we know: `ContentView` -> `CalculatorViewWrapper` -> `CalculatorViewWithFavorite` is 3 layers. The wrapper exists only to pass `$selectedFavorite` binding.
   - What's unclear: Whether the indirection is still needed with ViewModel pattern.
   - Recommendation: Simplify to `ContentView` -> `CalculatorView(viewModel:)`. The ViewModel handles favorite loading directly.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: [Migrating from ObservableObject to @Observable](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro) -- migration steps
- [nilcoalescing.com: Using @Observable in SwiftUI views](https://nilcoalescing.com/blog/ObservableInSwiftUI/) -- @Bindable patterns, @Environment injection, property wrapper pairings table
- [Jesse Squires: @Observable is not a drop-in replacement](https://www.jessesquires.com/blog/2024/09/09/swift-observable-macro/) -- @State vs @StateObject initialization semantics, memory implications
- Direct codebase analysis: all 12 Swift files read and analyzed -- actual current state, not assumed
- project.pbxproj analyzed -- actual Xcode project configuration

### Secondary (MEDIUM confidence)
- [Antoine van der Lee: @Observable macro performance](https://www.avanderlee.com/swiftui/observable-macro-performance-increase-observableobject/) -- fine-grained tracking benefits
- [Antoine van der Lee: Approachable Concurrency in Swift 6.2](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) -- Swift 6 concurrency considerations
- [TrozWare: Xcode Folders & Groups](https://troz.net/post/2024/xcode_folders_groups/) -- Xcode 16 folder-based organization changes
- Prior project research: ARCHITECTURE.md, STACK.md, PITFALLS.md from `.planning/research/`

### Tertiary (LOW confidence)
- None -- all findings verified against primary/secondary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- @Observable, @Bindable, @Environment are well-documented stable iOS 17 APIs, verified against multiple authoritative sources
- Architecture: HIGH -- MVVM with @Observable is Apple's recommended pattern, codebase thoroughly analyzed for specific restructuring plan
- Pitfalls: HIGH -- all pitfalls verified against official documentation and community-documented real issues; codebase-specific pitfalls (duplicate code, pbxproj state) identified from direct analysis
- Per-tank calculation: HIGH -- trivial math, existing model already has all needed intermediate values

**Research date:** 2026-02-06
**Valid until:** 2026-03-06 (stable APIs, unlikely to change)
