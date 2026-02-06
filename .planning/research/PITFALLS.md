# Domain Pitfalls

**Domain:** iOS SwiftUI agricultural spray calculator -- App Store preparation
**Researched:** 2026-02-06
**Confidence:** MEDIUM-HIGH (SwiftUI patterns well-established since iOS 16-17; App Store guidelines verified via official source)

---

## Critical Pitfalls

Mistakes that cause App Store rejection, data loss, or forced rewrites.

---

### Pitfall 1: MVVM Over-Engineering -- ViewModel Becomes a God Object

**What goes wrong:** When refactoring from "logic in views" to MVVM, developers move ALL logic into a single ViewModel. The result is a 500-line `SprayCalculatorViewModel` that manages inputs, validation, calculation, history, favorites, localization, and PDF export. This is worse than the original because it is untestable, hard to navigate, and causes excessive view redraws.

**Why it happens:** "MVVM" is interpreted as "one ViewModel per screen." In SwiftUI, a screen-level ViewModel holding 15+ `@Published` properties causes the entire view tree to re-render on any single property change.

**Consequences:**
- UI jank and unnecessary recomposition (every keystroke in one field redraws the entire screen)
- The ViewModel is harder to maintain than the original views
- Testing requires mocking the entire application state

**Prevention:**
- Split by responsibility: `InputViewModel` (fields + validation), `CalculationEngine` (pure functions, no ObservableObject), `HistoryManager` (persistence). The calculation logic should be a plain struct with static/instance methods, not an Observable.
- Use `@Observable` macro (iOS 17+) instead of `ObservableObject` -- it tracks property access granularly, so only views reading a changed property re-render. This is the single biggest performance win for iOS 17+ targets.
- Rule of thumb: if a ViewModel has more than 6-8 `@Published` properties, split it.

**Detection:** ViewModel file exceeds 200 lines. Multiple unrelated concerns in one class. Typing in a text field causes visible lag.

**Phase:** MVVM Refactor phase. Design the split BEFORE moving code.

---

### Pitfall 2: @Observable vs ObservableObject Confusion (iOS 17+)

**What goes wrong:** Since the project targets iOS 17+, the new `@Observable` macro (Observation framework) should be used instead of the old `ObservableObject` protocol. But developers mix both patterns, leading to subtle bugs where views don't update or update too often.

**Why it happens:** Most SwiftUI tutorials still show `ObservableObject` + `@Published` + `@StateObject`/`@ObservedObject`. The iOS 17 `@Observable` macro uses a completely different injection pattern (`@State` for ownership, plain property reference for reading, `@Bindable` for bindings).

**Consequences:**
- Using `@StateObject` with an `@Observable` class silently compiles but observation breaks -- view never updates
- Using `@ObservedObject` with `@Observable` also breaks observation
- Mixing `@Published` inside an `@Observable` class does nothing (ignored)

**Prevention:**
- Commit to ONE pattern project-wide: `@Observable` macro for iOS 17+
- Ownership: `@State private var viewModel = MyViewModel()`
- Read access: just pass the object, no property wrapper needed
- Bindings: `@Bindable var viewModel` in child views
- NEVER use `@StateObject`, `@ObservedObject`, or `@Published` with `@Observable` classes

**Detection:** Xcode may not warn about this. If a view stops updating after data changes, check for wrapper mismatch. Search codebase for `@StateObject` or `@ObservedObject` used with `@Observable` classes.

**Phase:** MVVM Refactor phase. Establish the pattern in the first ViewModel, then apply consistently.

---

### Pitfall 3: ImageRenderer Runs Off-MainActor Silently

**What goes wrong:** `ImageRenderer` must run on the main actor because it renders SwiftUI views. But calling `.render()` from a background context (e.g., inside a `Task {}` or a method not marked `@MainActor`) produces a blank or corrupted image/PDF with no error -- just empty output.

**Why it happens:** `ImageRenderer` does not crash or throw when used off-main-thread in all cases. It sometimes produces partial output. The compiler may not warn if the calling context is ambiguous.

**Consequences:**
- PDF files are generated but contain blank pages
- Bug is intermittent (works in debug, fails in release, or vice versa)
- Extremely hard to diagnose because no error is thrown

**Prevention:**
- Mark the PDF generation method explicitly `@MainActor`
- Use `MainActor.run { }` if calling from an async context
- Test PDF generation on a real device (Simulator may mask threading issues)
- Always open the generated PDF and verify content, not just file existence

```swift
@MainActor
func generatePDF(from view: some View) -> Data? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = UIScreen.main.scale // retina
    var pdfData = Data()
    renderer.render { size, renderInContext in
        var box = CGRect(origin: .zero, size: size)
        guard let context = CGContext(consumer: CGDataConsumer(data: pdfData as! CFMutableData)!,
                                      mediaBox: &box, nil) else { return }
        context.beginPDFPage(nil)
        renderInContext(context)
        context.endPDFPage()
        context.closePDF()
    }
    return pdfData
}
```

**Detection:** PDF file has non-zero size but opens as blank. Works in Simulator but not on device (or vice versa).

**Phase:** PDF Export phase. Verify on real device immediately.

---

### Pitfall 4: App Store Rejection for Missing Privacy Policy

**What goes wrong:** Even a simple calculator app that collects NO user data still needs a privacy policy URL in App Store Connect. Apps without one are rejected automatically.

**Why it happens:** Developers of simple utility apps assume "I don't collect data, so I don't need a privacy policy." Apple requires it regardless. The policy can simply state "This app does not collect any personal data."

**Consequences:**
- Automatic rejection during metadata review
- Delays publication by days (resubmission queue)

**Prevention:**
- Create a simple privacy policy page (GitHub Pages, a simple HTML page, or even a GitHub gist)
- Add the URL to App Store Connect before first submission
- Content can be minimal: "Kalkulator Oprysku does not collect, store, or transmit any personal data. All calculations are performed locally on your device."

**Detection:** App Store Connect shows a warning if privacy policy URL is empty.

**Phase:** App Store Preparation phase. Create before first submission attempt.

---

### Pitfall 5: Dark Mode -- Replacing Colors One-by-One Without a System

**What goes wrong:** Developer goes through each file replacing `Color.white` with `Color(.systemBackground)` and `Color(red: 0.2, ...)` with inline conditionals like `colorScheme == .dark ? Color.gray : Color.green`. The result is inconsistent colors, missed spots, and an unmaintainable mess of ternary expressions.

**Why it happens:** It feels faster to fix each hardcoded color in-place rather than designing a color system first. But agricultural apps need high-contrast "field-ready" colors that look good in BOTH modes, which requires coordinated design.

**Consequences:**
- Inconsistent appearance (some views adapted, others not)
- Text becomes invisible against similarly-colored backgrounds in one mode
- Every new view requires remembering which color variant to use
- "Field-Ready" high-contrast goal is impossible without a system

**Prevention:**
- Create an `AppColors` enum or Asset Catalog color set FIRST, before touching any view
- Define semantic colors: `AppColors.background`, `AppColors.primaryAction`, `AppColors.fieldText`, `AppColors.cardBackground`, `AppColors.warningRed`
- Each semantic color has light AND dark variants defined in one place
- Asset Catalog approach: create Color Sets with "Any Appearance" + "Dark" variants
- Then do a single pass replacing ALL hardcoded colors with semantic names

```swift
// AppColors.swift -- define ONCE, use everywhere
enum AppColors {
    static let background = Color("AppBackground")       // Asset Catalog
    static let cardBackground = Color("CardBackground")
    static let primaryText = Color("PrimaryText")
    static let accentGreen = Color("AccentGreen")        // field-ready green
    static let inputField = Color("InputFieldBackground")
}
```

**Detection:** Search codebase for `Color(` and `Color.` -- if more than 2-3 unique definitions exist outside a central file, the system is missing. Also: toggle dark mode in Simulator and visually inspect every screen.

**Phase:** Dark Mode phase. Define the color system as the FIRST task, before any view changes.

---

## Moderate Pitfalls

Mistakes that cause delays, rework, or technical debt.

---

### Pitfall 6: ImageRenderer Ignores Environment Values

**What goes wrong:** The view passed to `ImageRenderer` does not inherit the app's environment. This means `@Environment(\.colorScheme)`, `@Environment(\.locale)`, Dynamic Type size, and custom `EnvironmentObject` values are all missing. The rendered PDF shows default (light mode, English, standard text size) regardless of app settings.

**Why it happens:** `ImageRenderer` creates a new rendering context. It does not inherit the hosting view's environment chain.

**Prevention:**
- Explicitly inject ALL environment values into the rendered view:

```swift
let renderer = ImageRenderer(content:
    PDFContentView(results: results)
        .environment(\.locale, currentLocale)
        .environment(\.colorScheme, .light)  // PDFs should always be light
        .environment(\.dynamicTypeSize, .large)
)
```

- Design a dedicated `PDFContentView` that does NOT rely on environment values and instead takes all data as explicit parameters
- Always render PDFs in light mode (PDFs are printed -- dark backgrounds waste ink)

**Detection:** PDF shows English text when app is in Polish mode, or shows wrong colors.

**Phase:** PDF Export phase.

---

### Pitfall 7: MVVM Refactor Breaks @State Ownership

**What goes wrong:** When moving `@State` variables from a view to a ViewModel, developers use `@Published` but forget that `@State` provided value semantics and view-local ownership. The ViewModel (reference type) now shares state, causing unexpected behavior when the same ViewModel is accidentally shared or retained.

**Why it happens:** `@State` in SwiftUI is owned by the view's identity in the view tree. Moving to ViewModel changes ownership semantics. If the ViewModel is created in `.onAppear` or passed via environment, its lifecycle may not match the view's.

**Consequences:**
- Input fields retain stale values after navigation
- History/favorites state bleeds between screens
- Difficult-to-reproduce bugs around view lifecycle

**Prevention:**
- Text field input state (`fieldArea`, `fieldChemicalRate`, etc.) should stay as `@State` in the View or use `@Bindable` with the ViewModel
- Only LOGIC (validation, calculation, persistence) moves to the ViewModel
- The ViewModel should be created with `@State` (iOS 17+): `@State private var vm = CalculatorViewModel()`
- Do NOT create ViewModel in `init()` or `.onAppear` -- use `@State` for stable identity

**Detection:** Navigate away from calculator screen and back -- do input fields reset unexpectedly or retain old values?

**Phase:** MVVM Refactor phase.

---

### Pitfall 8: Bundle Identifier Not Matching Apple Developer Account

**What goes wrong:** The Bundle Identifier in Xcode (e.g., `com.example.SprayCalculator`) does not match a registered App ID in the developer's Apple Developer account, or uses a placeholder domain. App cannot be deployed to a physical device or submitted to App Store.

**Why it happens:** Xcode templates use `com.example.*` or the developer's machine username. Nobody changes it until deployment fails.

**Consequences:**
- Cannot install on physical iPhone for testing
- Cannot submit to App Store
- Changing Bundle ID later may require recreating provisioning profiles

**Prevention:**
- Set Bundle ID early: `com.wojciecholszak.kalkulatoroprysku` (or similar)
- Ensure Automatic Signing is enabled in Xcode with the correct Apple ID team
- Verify on a physical device BEFORE doing any other work
- In Xcode: Target > Signing & Capabilities > Team must be set

**Detection:** Xcode shows red error in Signing & Capabilities tab. Build fails with "No profiles for 'com.example...' were found."

**Phase:** Should be the FIRST task in any phase -- verify the project builds and deploys to a real device.

---

### Pitfall 9: Dynamic Type Breaks Layout

**What goes wrong:** App looks perfect at default text size but becomes unusable at larger Dynamic Type sizes. Text overlaps, buttons become too small relative to text, horizontal layouts overflow, and the tractor animation area pushes inputs off-screen.

**Why it happens:** SwiftUI uses Dynamic Type by default for `Text` views, but fixed-size frames (`frame(width: 300)`) and `HStack` layouts don't adapt. Agricultural apps need to work for users who may have poor eyesight (working outdoors, bright sun).

**Consequences:**
- App is unusable for accessibility users
- App Store reviewers may test with non-default text sizes
- "Field-Ready" design goal fails -- farmers in bright sun often use larger text

**Prevention:**
- Use `.font(.body)`, `.font(.headline)` etc. (semantic fonts) instead of fixed sizes
- Replace fixed `frame(width:)` with `frame(maxWidth: .infinity)` and flexible layouts
- Test with `@Environment(\.dynamicTypeSize)` at `.accessibility3` (largest)
- Use `ScrollView` for any screen that might overflow at large text sizes
- In Xcode: use the Accessibility Inspector or set Dynamic Type in Simulator settings

**Detection:** In Simulator: Settings > Accessibility > Display & Text Size > Larger Text > drag slider to maximum. If any screen breaks, this pitfall is active.

**Phase:** Dark Mode / UI Polish phase. Test AFTER all layout changes are complete.

---

### Pitfall 10: Xcode Warnings From Deprecated API Usage

**What goes wrong:** Project uses deprecated APIs (e.g., `NavigationView` instead of `NavigationStack`, `onChange(of:perform:)` single-closure version, `.foregroundColor()` instead of `.foregroundStyle()`). Each produces a warning. "Zero warnings" goal requires fixing all of them.

**Why it happens:** Original code was written for an earlier iOS version or copied from older tutorials. Xcode shows deprecation warnings but code still compiles and runs.

**Consequences:**
- "Zero warnings" requirement fails
- Deprecated APIs may behave differently in future iOS versions
- App Store review may note deprecated API usage

**Prevention:**
- Audit all deprecation warnings BEFORE starting new feature work
- Common SwiftUI deprecations for iOS 17+:
  - `NavigationView` -> `NavigationStack`
  - `onChange(of:) { newValue in }` -> `onChange(of:) { oldValue, newValue in }`
  - `.foregroundColor()` -> `.foregroundStyle()`
  - `.background(Color.x)` -> `.background(.x)` (simplified)
  - `List { ForEach }` with `onDelete` may need `EditMode` handling update
- Run Xcode Build (Cmd+B) and fix ALL yellow warnings in one pass

**Detection:** Xcode Issue Navigator (Cmd+5) shows yellow triangle warnings.

**Phase:** Should be a dedicated cleanup task early in the refactor phase, or as a final pass before submission.

---

### Pitfall 11: PDF File Sharing Fails on Real Device

**What goes wrong:** PDF is generated successfully but `ShareLink` or `UIActivityViewController` fails to share it because the file URL points to a temporary location that's been cleaned up, or the file is written to a non-accessible sandbox location.

**Why it happens:** Using `FileManager.default.temporaryDirectory` is fine, but the file must persist until the share sheet is dismissed. Also, some developers try to write to the app's bundle (read-only) instead of the documents directory.

**Consequences:**
- Share sheet opens but attachment is missing
- "Save to Files" option crashes or saves empty file
- Works in Simulator but fails on device

**Prevention:**
- Write PDF to `FileManager.default.temporaryDirectory` with a unique filename
- Keep a reference to the URL in `@State` so it persists during share sheet display
- Use `ShareLink` (iOS 16+) with a `Transferable` conformance, or pass `Data` directly
- Test the full flow: generate -> share -> open in Files / send via AirDrop

```swift
ShareLink(item: pdfURL,
          preview: SharePreview("Wyniki oprysku", image: Image(systemName: "doc.fill")))
```

**Detection:** Tap Share, select "Save to Files" -- if it fails or saves 0-byte file, the URL/lifecycle is wrong.

**Phase:** PDF Export phase. Test on real device.

---

### Pitfall 12: Localization Regression During Refactor

**What goes wrong:** The existing `LocalizationManager` with manual PL/EN switching works. During MVVM refactor, hardcoded strings sneak back in (especially in new views like "About" or PDF export). The `HistoryRowView` already has hardcoded "pelne"/"czesciowe" that needs fixing.

**Why it happens:** New code is written in Polish first ("it's faster"), with intent to localize later. But "later" never comes, or some strings are missed.

**Consequences:**
- Mixed language UI (some Polish, some English, some hardcoded)
- Known issue: `HistoryRowView` hardcoded strings not using `LocalizationManager`

**Prevention:**
- Every new string literal goes through `LocalizationManager` immediately -- no exceptions
- Add a code review checklist item: "No bare string literals in Views"
- The PDF export view is especially prone to this (date formats, labels, author credit)
- Fix the `HistoryRowView` hardcoded strings as part of the refactor phase, not later

**Detection:** Switch app language to English and check every screen, including PDF output and About view.

**Phase:** MVVM Refactor phase (for existing issues). Every subsequent phase must maintain this discipline.

---

## Minor Pitfalls

Mistakes that cause annoyance but are fixable quickly.

---

### Pitfall 13: Asset Catalog Color Names Don't Match Code

**What goes wrong:** Developer creates color sets in Asset Catalog named "Background" but references `Color("background")` in code (case mismatch). SwiftUI silently falls back to a default color (usually clear/black) with no compile-time error.

**Prevention:**
- Use `Color("ExactName")` matching the Asset Catalog entry exactly
- Better: use the Xcode-generated color assets (iOS 17+): `Color(.appBackground)` with proper naming
- Or define all color references in a single `AppColors` enum to catch typos in one place

**Detection:** A view appears with unexpected transparent or black areas.

**Phase:** Dark Mode phase.

---

### Pitfall 14: Tractor Animation Blocks Main Thread During PDF Render

**What goes wrong:** If the tractor animation is running when `ImageRenderer.render()` is called, the animation may interfere with rendering or cause a brief freeze because both compete for the main thread.

**Prevention:**
- Stop or hide the tractor animation before starting PDF generation
- Show a "Generating PDF..." indicator instead
- Resume animation after PDF is complete

**Detection:** App freezes momentarily when generating PDF while animation is active.

**Phase:** PDF Export phase.

---

### Pitfall 15: Git Commits Include .xcuserdata

**What goes wrong:** The `.xcuserdata/` directory inside `.xcodeproj` contains user-specific Xcode settings (breakpoints, window positions, scheme configurations). Committing these creates noisy diffs and can cause issues if working from multiple machines.

**Prevention:**
- Add to `.gitignore` before any commits:
```
*.xcuserdata/
xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
.build/
```
- Run `git rm -r --cached *.xcuserdata/` if already committed

**Detection:** `git status` shows changes in `xcuserdata/` after simply opening Xcode.

**Phase:** First commit of the milestone.

---

### Pitfall 16: App Store Screenshots Wrong Device Frame

**What goes wrong:** App Store Connect requires screenshots for specific device sizes (6.7" for iPhone 15 Pro Max, 6.5" for iPhone 11 Pro Max, etc.). Submitting wrong dimensions causes rejection or displays poorly on the listing.

**Prevention:**
- Required screenshot sizes (2026):
  - 6.7" display: 1290 x 2796 px (iPhone 15 Pro Max)
  - 6.5" display: 1284 x 2778 px (iPhone 14 Plus) -- optional if 6.7" provided
  - 5.5" display: 1242 x 2208 px (iPhone 8 Plus) -- may still be required
- Use Simulator to capture screenshots at correct resolutions
- Show the app IN USE (results displayed) -- not splash screens

**Detection:** App Store Connect rejects upload or shows warning about image dimensions.

**Phase:** App Store Preparation phase.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| MVVM Refactor | God ViewModel (Pitfall 1) | Split by responsibility; keep input @State in views |
| MVVM Refactor | @Observable vs ObservableObject confusion (Pitfall 2) | Commit to @Observable only for iOS 17+ |
| MVVM Refactor | Breaking @State ownership (Pitfall 7) | Input state stays in View; logic in ViewModel |
| MVVM Refactor | Localization regression (Pitfall 12) | Fix HistoryRowView; enforce no bare strings |
| Dark Mode | Color-by-color replacement without system (Pitfall 5) | Define AppColors enum/Asset Catalog FIRST |
| Dark Mode | Asset Catalog name mismatch (Pitfall 13) | Central AppColors enum catches typos |
| Dark Mode | Dynamic Type layout breaks (Pitfall 9) | Test at max Dynamic Type after all layout changes |
| Dark Mode | Deprecated API warnings (Pitfall 10) | Fix NavigationView, foregroundColor, onChange |
| PDF Export | ImageRenderer off-MainActor (Pitfall 3) | Mark method @MainActor; test on real device |
| PDF Export | Environment not inherited (Pitfall 6) | Inject locale/colorScheme explicitly; always light mode |
| PDF Export | File sharing lifecycle (Pitfall 11) | Use temp directory; keep URL reference alive |
| PDF Export | Animation interference (Pitfall 14) | Stop tractor animation during render |
| App Store Prep | Missing privacy policy (Pitfall 4) | Create minimal policy page on GitHub Pages |
| App Store Prep | Wrong Bundle Identifier (Pitfall 8) | Set correct Bundle ID and test on device FIRST |
| App Store Prep | Wrong screenshot dimensions (Pitfall 16) | Capture from correct Simulator devices |
| App Store Prep | .xcuserdata in git (Pitfall 15) | Update .gitignore immediately |

## Sources

- Apple App Store Review Guidelines (https://developer.apple.com/app-store/review/guidelines/) -- fetched 2026-02-06, HIGH confidence
- SwiftUI `@Observable` macro behavior -- based on WWDC23 sessions and iOS 17 documentation, MEDIUM-HIGH confidence (training data, well-established pattern)
- `ImageRenderer` API behavior -- based on Apple documentation and community-reported issues, MEDIUM confidence (training data, verified pattern but not fetched live)
- Dark mode and Dynamic Type best practices -- based on Apple Human Interface Guidelines, MEDIUM-HIGH confidence (stable guidance since iOS 13)
- App Store screenshot requirements -- MEDIUM confidence (dimensions may have updated for newer devices; verify before submission)
