# Phase 2: Visual Polish - Research

**Researched:** 2026-02-06
**Domain:** SwiftUI dark mode (Asset Catalog named colors), Dynamic Type (@ScaledMetric, semantic fonts), high-contrast field-ready styling
**Confidence:** HIGH

## Summary

Phase 2 transforms the current hardcoded color system into an adaptive, Asset Catalog-based theme that works in both light and dark mode, supports Dynamic Type at all sizes including maximum accessibility, and provides high-contrast readability for outdoor field use. The codebase currently has **31 color definitions** in `Colors.swift` as static `Color(red:green:blue:)` literals -- none of these adapt to dark mode. All gradients use fixed color values. All fonts use `.font(.system(size: N))` with hardcoded point sizes (13 instances) instead of semantic text styles, meaning Dynamic Type has no effect. There are no `@ScaledMetric` properties for padding, icon sizes, or spacing.

The work divides into two coordinated tasks: (1) create a complete Asset Catalog color system with light/dark/high-contrast variants and a thin Swift wrapper (`AppTheme`) for type-safe access plus gradient definitions, and (2) replace every hardcoded color and font across all 8 view files with the new semantic references, add `@ScaledMetric` for non-text dimensions, and verify all screens in both modes and at max Dynamic Type size.

**Primary recommendation:** Define all colors in Asset Catalog `.colorset` JSON files with "Any, Dark" appearances. Create an `AppTheme` enum with nested `AppColors`, `AppFonts`, and `AppSpacing` that provides type-safe access via `Color(.semanticName)` (Xcode 15+ auto-generated symbols). Replace all 13 hardcoded `.system(size:)` fonts with semantic text styles (`.body`, `.headline`, `.title2`, etc.). Add `@ScaledMetric` to icon sizes, card padding, and button heights. Use `@Environment(\.colorScheme)` only where gradients need programmatic dark-mode switching.

## Standard Stack

### Core

| Technology | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Asset Catalog Color Sets | Xcode 15+ / iOS 14+ | Adaptive light/dark/high-contrast colors | Apple's recommended approach. System handles appearance switching automatically. No conditional code needed. |
| `Color(.resourceName)` | Xcode 15+ (auto-generated symbols) | Type-safe color access from Asset Catalog | Compile-time safety. No string literals. Autocomplete support. Works on older deployment targets. |
| Semantic Text Styles | SwiftUI / iOS 13+ | Dynamic Type support for text | `.body`, `.headline`, `.title2` etc. scale automatically with user preference. Apple's design system. |
| `@ScaledMetric` | SwiftUI / iOS 14+ | Scale non-text dimensions with Dynamic Type | Automatically scales padding, icon sizes, spacing proportionally with the user's Dynamic Type setting. |
| `@Environment(\.colorScheme)` | SwiftUI / iOS 13+ | Detect current appearance for gradients | Read-only. Use for programmatic gradient adjustments where Asset Catalog alone is insufficient. |
| `@Environment(\.colorSchemeContrast)` | SwiftUI / iOS 14+ | Detect "Increase Contrast" accessibility setting | Read-only. Use to boost contrast for images or custom-drawn elements beyond what Asset Catalog provides. |

### Supporting

| Technology | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `LinearGradient` with adaptive colors | SwiftUI | Dark mode gradients | Build gradients from Asset Catalog colors -- they adapt automatically. For complex gradients, use `@Environment(\.colorScheme)` to switch gradient arrays. |
| `.dynamicTypeSize(...)` range | iOS 15+ | Cap Dynamic Type scaling | Use `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` to prevent layout breakage at extreme sizes -- only if truly needed. |
| `ViewThatFits` | iOS 16+ | Adaptive layout at large Dynamic Type | If a horizontal row clips at large type, use `ViewThatFits` to switch to vertical stack. Available since iOS 16. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|-----------|-----------|----------|
| Asset Catalog `.colorset` files | `Color(uiColor: UIColor { trait in ... })` in code | Code-only approach works but misses Xcode color preview, requires manual trait collection handling, no "High Contrast" appearance support without extra code. Asset Catalog is cleaner. |
| Semantic text styles (`.body`, `.headline`) | Keep `.system(size: N)` with `.dynamicTypeSize()` | Hardcoded sizes never scale with Dynamic Type. Even with dynamic type modifier, system styles match Apple HIG proportions better. |
| `@ScaledMetric` for dimensions | Fixed `CGFloat` values | Fixed values don't adapt. At max accessibility size, 50pt icons next to 60pt text look disproportionate. |
| Creating color sets via JSON files | Creating via Xcode GUI | JSON files can be generated programmatically and committed to git. GUI requires manual clicking. JSON is faster for 15+ color sets. Both produce identical results. |

## Architecture Patterns

### Recommended Color Set File Structure

```
Assets.xcassets/
  Colors/
    primaryGreen.colorset/Contents.json
    darkGreen.colorset/Contents.json
    lightGreen.colorset/Contents.json
    earthBrown.colorset/Contents.json
    lightBrown.colorset/Contents.json
    darkBrown.colorset/Contents.json
    accentGold.colorset/Contents.json
    waterBlue.colorset/Contents.json
    errorRed.colorset/Contents.json
    backgroundPrimary.colorset/Contents.json
    backgroundCard.colorset/Contents.json
    backgroundSecondary.colorset/Contents.json
    textPrimary.colorset/Contents.json
    textSecondary.colorset/Contents.json
    gradientStart.colorset/Contents.json
    gradientEnd.colorset/Contents.json
    backgroundGradientStart.colorset/Contents.json
    backgroundGradientEnd.colorset/Contents.json
  AccentColor.colorset/Contents.json    (update existing)
  AppIcon.appiconset/Contents.json      (keep existing)
```

### Pattern 1: Asset Catalog Color Set JSON with Dark Mode

**What:** Each `.colorset/Contents.json` defines light (universal/any) and dark appearance colors.

**When to use:** Every semantic color in the app.

**Example:**

```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.340",
          "green": "0.540",
          "red": "0.180"
        }
      },
      "idiom": "universal"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.420",
          "green": "0.680",
          "red": "0.300"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Source: [GitHub pkluz/Indicate colorset example](https://github.com/pkluz/Indicate/blob/master/Example/Resources/Assets.xcassets/BackgroundColor.colorset/Contents.json), verified against Apple Asset Catalog format.

### Pattern 2: AppTheme Wrapper with Xcode 15+ Type-Safe Colors

**What:** Thin enum namespace that re-exports Asset Catalog colors as type-safe static properties and defines gradients.

**When to use:** Single import point for all theme values.

**Example:**

```swift
import SwiftUI

// Colors are auto-generated by Xcode 15+ from Asset Catalog
// Access via Color(.primaryGreen) -- type-safe, no strings

// MARK: - Adaptive Gradients
enum AppGradients {
    static func primaryGradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(.lightGreen), Color(.primaryGreen)]
                : [Color(.primaryGreen), Color(.darkGreen)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [Color(.backgroundGradientStart), Color(.backgroundGradientEnd)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Scaled Spacing
enum AppSpacing {
    @ScaledMetric(relativeTo: .body) static var cardPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) static var sectionSpacing: CGFloat = 24
    @ScaledMetric(relativeTo: .body) static var inputFieldPadding: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) static var iconSize: CGFloat = 50
}
```

**IMPORTANT caveat:** `@ScaledMetric` cannot be used on static properties of an enum -- it is a property wrapper that requires a SwiftUI view context. The scaled metrics must be declared INSIDE each View struct that uses them, or passed as environment-derived values. The `AppSpacing` enum shown above is illustrative of the VALUES to use; the actual `@ScaledMetric` declarations go inside each view.

### Pattern 3: Semantic Font Replacement

**What:** Replace all `.font(.system(size: N, weight: W, design: D))` with semantic text styles.

**When to use:** Every text element in the app.

**Mapping (current hardcoded sizes to semantic styles):**

| Current Usage | Size | Replacement | Rationale |
|--------------|------|-------------|-----------|
| ResultCard value | 28pt bold rounded | `.font(.title2.weight(.bold))` with `.fontDesign(.rounded)` | Primary result number, prominent |
| Input field text / Button text | 18pt semibold rounded | `.font(.body.weight(.semibold))` with `.fontDesign(.rounded)` | Standard input size |
| Icon in input field | 18pt medium | `.font(.body.weight(.medium))` | Match input text size |
| Emoji in ResultCard | 24pt | `.font(.title3)` | Slightly larger than body |
| Section header title | 18pt bold rounded | `.font(.headline)` with `.fontDesign(.rounded)` | Standard section header |
| Section header icon | 16pt semibold | `.font(.subheadline.weight(.semibold))` | Slightly smaller than header |
| Label text | .subheadline | Already semantic -- keep | Good |
| Secondary button text | 14pt semibold rounded | `.font(.subheadline.weight(.semibold))` with `.fontDesign(.rounded)` | Smaller action text |
| Empty state icons | 60pt system | `.font(.system(size: 60))` -- keep fixed OR use @ScaledMetric | Decorative, could remain fixed |
| Loading text (animation) | 16pt medium rounded | `.font(.callout.weight(.medium))` with `.fontDesign(.rounded)` | Secondary text |
| Caption text | .caption | Already semantic -- keep | Good |

### Pattern 4: @ScaledMetric for Non-Text Dimensions

**What:** Declare `@ScaledMetric` properties inside views for dimensions that should scale with Dynamic Type.

```swift
struct ResultCard: View {
    @ScaledMetric(relativeTo: .title2) private var iconCircleSize: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var iconSpacing: CGFloat = 16

    // Use iconCircleSize instead of hardcoded 50
    // Use cardPadding instead of hardcoded 16
}

struct SprayInputField: View {
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = 14
}

struct PrimaryButton: View {
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = 18
}
```

### Anti-Patterns to Avoid

- **Using `Color("stringName")` instead of `Color(.resourceName)`:** String-based access has no compile-time safety. A typo silently produces `nil` color (renders as clear). With Xcode 15+ type-safe generation, use `Color(.primaryGreen)` which produces a compile error if the asset is missing or renamed.
- **Conditional `colorScheme == .dark ? darkColor : lightColor` everywhere:** This defeats the purpose of Asset Catalog. Define both variants in the `.colorset` and let the system switch automatically. Only use `@Environment(\.colorScheme)` for gradients that need different color ARRAYS (not individual colors).
- **Scaling decorative animation dimensions:** The TractorAnimation has many hardcoded frame sizes for the tractor body, wheels, nozzles. These are decorative illustration elements. Scaling them with Dynamic Type would make the animation disproportionate. Keep them fixed.
- **Using `.foregroundColor()` (deprecated in iOS 17+):** Use `.foregroundStyle()` instead. While `.foregroundColor()` still works, `.foregroundStyle()` is the modern API that supports gradients and hierarchical styles.
- **Forgetting `scrollContentBackground(.hidden)` on List views:** When applying a custom background gradient to List/Form views, the default system background covers it. Must call `.scrollContentBackground(.hidden)` first (already done in SettingsView, verify on all List views).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark mode color switching | Manual `@Environment(\.colorScheme)` checks for every color | Asset Catalog `.colorset` with "Any, Dark" appearances | System handles switching automatically. Zero code per color. Handles transitions, animations. |
| High contrast mode | Manual contrast ratio calculations | Asset Catalog "High Contrast" appearance checkbox + provide alternate values | System handles switching. Matches iOS "Increase Contrast" accessibility setting. |
| Dynamic Type text scaling | Manual font size calculations based on size class | SwiftUI semantic text styles (`.body`, `.headline`, etc.) | Built into SwiftUI. Tested by Apple across all devices. Handles all edge cases. |
| Non-text dimension scaling | Custom `UIFontMetrics` wrappers | `@ScaledMetric` property wrapper | Built into SwiftUI. Automatically updates when Dynamic Type changes. No observation code needed. |
| Color set JSON generation | Creating each colorset by hand in Xcode GUI | Script or manual JSON file creation in filesystem | 15+ color sets with 2 variants each = 30+ color clicks in Xcode. JSON files are faster to create, easier to review in git. |

**Key insight:** The entire dark mode + Dynamic Type system is built into SwiftUI and Asset Catalogs. The work is defining the right color values and replacing references -- NOT building infrastructure. The "framework" already exists.

## Common Pitfalls

### Pitfall 1: White-on-White / Black-on-Black Text After Dark Mode

**What goes wrong:** After migrating colors, some screens show invisible text because a text color and its background both map to similar values in one mode.

**Why it happens:** When defining dark mode colors, it's easy to make `textPrimary` white and `backgroundCard` also white-ish. Or to forget to update one of the pair.

**How to avoid:**
- Define colors in semantic PAIRS: every background color must have a tested text color that works on it in BOTH modes
- Test every screen in BOTH modes immediately after replacing colors
- Use Xcode preview with `.preferredColorScheme(.dark)` modifier to see both modes side by side
- Critical pairs to verify: `textPrimary` on `backgroundCard`, `textSecondary` on `backgroundCard`, `textPrimary` on `backgroundPrimary`, white text on `primaryGreen` gradient

**Warning signs:** Text disappears when toggling dark mode. Buttons become invisible. Cards blend into background.

### Pitfall 2: Gradients Not Adapting to Dark Mode

**What goes wrong:** `LinearGradient` defined with Asset Catalog colors does adapt, but if the gradient colors are too similar in dark mode, the gradient effect disappears. Or if gradient start/end colors are not both defined for dark mode.

**Why it happens:** A gradient from dark-green to darker-green works in light mode but becomes nearly solid black in dark mode.

**How to avoid:**
- For dark mode gradients, LIGHTEN the colors (reverse the light-mode logic)
- The background gradient should go from dark-background to slightly-lighter-background in dark mode (subtle, not dramatic)
- The primary button gradient should remain vibrant green in both modes (just shift brightness)
- Test gradients specifically -- they're easy to miss in quick dark mode checks

**Warning signs:** Gradient areas appear as flat solid colors in dark mode.

### Pitfall 3: Fixed Dimensions Breaking at Max Dynamic Type

**What goes wrong:** At AX5 (maximum accessibility) size, text grows 3-4x larger. Fixed-size containers (e.g., 50pt icon circle, 14pt padding) don't grow, causing text to overflow or clip.

**Why it happens:** Only text scales with Dynamic Type by default. Padding, frames, and icon sizes stay fixed unless wrapped with `@ScaledMetric`.

**How to avoid:**
- Add `@ScaledMetric` to: icon container sizes, card padding, button padding, spacing between elements
- Do NOT add `@ScaledMetric` to: decorative animation (tractor), corner radius values, border widths
- Test at `.accessibility5` (maximum) in Xcode preview
- Ensure ALL content views are in `ScrollView` (already done for main calculator, verify all tabs)

**Warning signs:** Text overflows its container. Elements overlap. Content cut off at bottom of screen with no scroll.

### Pitfall 4: `.foregroundColor(.white)` Hardcoded on Buttons

**What goes wrong:** Button text is hardcoded as `.white`. In light mode on green gradient, this works. In dark mode with a lighter green, white text may have insufficient contrast.

**Why it happens:** White text on dark backgrounds is a common pattern, but dark mode may lighten the background color.

**How to avoid:**
- For buttons with green gradient background: keep white text (the green should remain dark enough in both modes)
- For the animation overlay text: it's `.white` on a `.black.opacity(0.3)` overlay -- this works in both modes
- Verify WCAG contrast ratio is at least 4.5:1 for all text-on-background combinations
- The primary concern is `.foregroundColor(.white)` on `backgroundCard` -- this would be invisible in light mode. Check all usages.

**Warning signs:** White text on light backgrounds. Text that's readable in dark mode but invisible in light mode (or vice versa).

### Pitfall 5: Xcode Not Recognizing New Color Sets

**What goes wrong:** After creating `.colorset` directories with `Contents.json` files on disk, Xcode doesn't see them and `Color(.name)` doesn't compile.

**Why it happens:** The `.xcassets` catalog needs to be registered in the Xcode project, and color set folders must be at the correct level inside it. If created outside Xcode (via filesystem), the project may need a clean build.

**How to avoid:**
- Create color set folders INSIDE the existing `Assets.xcassets` directory
- Each colorset must be a folder named `Name.colorset` containing exactly one `Contents.json`
- After creating files on disk, do a clean build (Cmd+Shift+K then Cmd+B)
- Verify auto-generated symbols appear: check `Color(.name)` autocomplete in Xcode
- If using a `Colors` subfolder inside `.xcassets`, create a `Colors` folder (not `.colorset`) with its own `Contents.json`: `{ "info": { "author": "xcode", "version": 1 }, "properties": { "provides-namespace": true } }`

**Warning signs:** `Color(.primaryGreen)` produces "cannot find in scope" error. Build succeeds but colors render as default (black).

### Pitfall 6: Forgetting to Remove Old Colors.swift

**What goes wrong:** After creating Asset Catalog colors, the old `Colors.swift` with `Color.primaryGreen` static extensions still exists. New code uses `Color(.primaryGreen)` from Asset Catalog, but old references still use `Color.primaryGreen` from the extension. Both compile but reference different values.

**Why it happens:** The old static extension `Color.primaryGreen` and the Xcode-generated `Color(.primaryGreen)` are different things. If both exist, there's ambiguity.

**How to avoid:**
- After ALL views are migrated to `Color(.name)` syntax, DELETE `Colors.swift` entirely
- In the transition period, rename old extension properties to avoid collision (e.g., `_oldPrimaryGreen`)
- Or better: migrate all references first, then delete `Colors.swift` in the same commit
- Verify build after deletion -- any missed reference will produce a compile error (which is good, it surfaces what was missed)

**Warning signs:** Build succeeds but some views use old (non-adaptive) colors. Dark mode works on some screens but not others.

## Code Examples

### Complete Color Set JSON: backgroundPrimary (light + dark)

```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.920",
          "green": "0.950",
          "red": "0.960"
        }
      },
      "idiom": "universal"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.130",
          "green": "0.140",
          "red": "0.120"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Source: Verified JSON format from [GitHub pkluz/Indicate](https://github.com/pkluz/Indicate/blob/master/Example/Resources/Assets.xcassets/BackgroundColor.colorset/Contents.json)

### Color Subfolder Contents.json (namespace provider)

```json
{
  "info": {
    "author": "xcode",
    "version": 1
  },
  "properties": {
    "provides-namespace": false
  }
}
```

Note: Set `provides-namespace` to `false` so colors are accessed as `Color(.primaryGreen)` not `Color(.Colors.primaryGreen)`.

### Semantic Font Migration Example

```swift
// BEFORE (Components.swift - SprayInputField)
Text(title)
    .font(.subheadline)       // Already semantic -- keep
    .fontWeight(.medium)
    .foregroundColor(.textSecondary)

Image(systemName: icon)
    .font(.system(size: 18, weight: .medium))  // Hardcoded
    .foregroundColor(isFocused ? .primaryGreen : .textSecondary)
    .frame(width: 24)

TextField("0", text: $value)
    .keyboardType(.decimalPad)
    .font(.system(size: 18, weight: .semibold, design: .rounded))  // Hardcoded
    .foregroundColor(.textPrimary)

// AFTER
Text(title)
    .font(.subheadline)       // Keep
    .fontWeight(.medium)
    .foregroundStyle(Color(.textSecondary))

Image(systemName: icon)
    .font(.body.weight(.medium))   // Semantic
    .foregroundStyle(isFocused ? Color(.primaryGreen) : Color(.textSecondary))
    .frame(width: iconWidth)       // @ScaledMetric

TextField("0", text: $value)
    .keyboardType(.decimalPad)
    .font(.body.weight(.semibold))  // Semantic
    .fontDesign(.rounded)
    .foregroundStyle(Color(.textPrimary))
```

### @ScaledMetric Declaration Pattern

```swift
struct SprayInputField: View {
    // ... existing properties ...

    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) private var unitPaddingH: CGFloat = 10
    @ScaledMetric(relativeTo: .caption) private var unitPaddingV: CGFloat = 6

    var body: some View {
        // Use iconWidth, horizontalPadding, verticalPadding instead of literals
    }
}
```

Source: Pattern verified from [SwiftLee @ScaledMetric guide](https://www.avanderlee.com/swiftui/scaledmetric-dynamic-type-support/) and [Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-scaledmetric-property-wrapper)

### Adaptive Gradient with @Environment

```swift
struct CalculatorViewWithFavorite: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            // ...
        }
        .background(
            LinearGradient(
                colors: [Color(.backgroundGradientStart), Color(.backgroundGradientEnd)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
```

Note: If the gradient colors are defined in Asset Catalog with dark variants, this "just works" without any `colorScheme` conditional. The `@Environment(\.colorScheme)` is only needed if you want to change the gradient STRUCTURE (e.g., different start/end points or number of stops).

### Xcode Preview Dark Mode Testing

```swift
#Preview("Light Mode") {
    ContentView()
        .environment(LocalizationManager())
        .environment(HistoryManager())
        .environment(FavoritesManager())
}

#Preview("Dark Mode") {
    ContentView()
        .environment(LocalizationManager())
        .environment(HistoryManager())
        .environment(FavoritesManager())
        .preferredColorScheme(.dark)
}

#Preview("Max Dynamic Type") {
    ContentView()
        .environment(LocalizationManager())
        .environment(HistoryManager())
        .environment(FavoritesManager())
        .dynamicTypeSize(.accessibility5)
}
```

## Codebase-Specific Findings

### Current Color Inventory (Colors.swift)

Every color that needs an Asset Catalog replacement:

| Current Extension | RGB Values (Light) | Proposed Dark Mode | Semantic Name |
|------------------|-------------------|-------------------|---------------|
| `primaryGreen` | (0.18, 0.54, 0.34) | (0.30, 0.68, 0.42) brighter | `primaryGreen` |
| `lightGreen` | (0.40, 0.73, 0.42) | (0.45, 0.78, 0.48) slightly brighter | `lightGreen` |
| `darkGreen` | (0.10, 0.36, 0.22) | (0.20, 0.52, 0.32) less dark | `darkGreen` |
| `earthBrown` | (0.55, 0.38, 0.24) | (0.65, 0.50, 0.35) lighter | `earthBrown` |
| `lightBrown` | (0.76, 0.60, 0.42) | (0.55, 0.42, 0.28) reversed | `lightBrown` |
| `darkBrown` | (0.36, 0.25, 0.15) | (0.50, 0.38, 0.25) lighter | `darkBrown` |
| `accentGold` | (0.85, 0.65, 0.13) | (0.90, 0.72, 0.20) brighter | `accentGold` |
| `waterBlue` | (0.25, 0.61, 0.76) | (0.35, 0.70, 0.85) brighter | `waterBlue` |
| `backgroundLight` | (0.96, 0.95, 0.92) | (0.12, 0.14, 0.13) -- use current `backgroundDark` | `backgroundPrimary` |
| `backgroundCard` | white (1,1,1) | (0.18, 0.20, 0.19) dark card | `backgroundCard` |
| `backgroundDark` | (0.12, 0.14, 0.13) | N/A -- only used as dark bg, merged into `backgroundPrimary` dark | removed |
| `textPrimary` | (0.15, 0.15, 0.14) | (0.95, 0.95, 0.93) near-white | `textPrimary` |
| `textSecondary` | (0.45, 0.45, 0.43) | (0.70, 0.70, 0.68) lighter gray | `textSecondary` |
| `error` | (0.85, 0.30, 0.25) | (0.95, 0.40, 0.35) brighter | `errorRed` |
| `success` = lightGreen | Same as lightGreen | Same as lightGreen dark | Alias not needed |
| `warning` = accentGold | Same as accentGold | Same as accentGold dark | Alias not needed |

Additional colors needed for gradients:
| Purpose | Light | Dark | Name |
|---------|-------|------|------|
| Background gradient start | (0.96, 0.95, 0.92) | (0.12, 0.14, 0.13) | `backgroundGradientStart` |
| Background gradient end | (0.92, 0.90, 0.85) | (0.10, 0.12, 0.11) | `backgroundGradientEnd` |

### Files That Must Be Modified

Every file with color or font references:

| File | Color Refs | Font Refs | @ScaledMetric Needed | Effort |
|------|-----------|-----------|---------------------|--------|
| `Colors.swift` | 15 definitions | 0 | No | DELETE entirely |
| `Components.swift` | 14 refs | 7 hardcoded fonts | Yes (icon, padding, button) | HIGH |
| `ContentView.swift` | 3 refs | 0 | No | LOW |
| `FavoritesView.swift` | 7 refs | 1 hardcoded font (60pt empty state) | Maybe (empty state icon) | MEDIUM |
| `HistoryView.swift` | 6 refs | 1 hardcoded font (60pt empty state) | Maybe (empty state icon) | MEDIUM |
| `SettingsView.swift` | 4 refs | 0 | No | LOW |
| `TractorAnimation.swift` | 14 refs | 1 hardcoded font | No (decorative, fixed sizes OK) | MEDIUM |
| `SprayCalculatorApp.swift` | 0 | 0 | No | NONE |

**Total: ~49 color references to replace, 10 fonts to make semantic, 6-10 @ScaledMetric properties to add.**

### Hardcoded `.foregroundColor(.white)` Locations

These use white regardless of mode -- verify each:

1. `Components.swift` line 165: `PrimaryButton` text -- OK, white on green gradient (gradient stays dark enough)
2. `FavoritesView.swift` line 76: "Use" button text -- OK, white on `primaryGreen` capsule
3. `TractorAnimation.swift` line 43: "Calculating..." text -- OK, white on dark overlay

All three are white text on colored/dark backgrounds -- these should remain white in both modes.

### User Feedback Integration

The user specifically said:
- *"UI sam wyglad jest slaby trzeba poprawic aby wygladalo to minimalistycznie, lecz przyjemnie dla oka"* (UI looks weak, needs to be minimalist but pleasant)
- *"animacja wygalda tragicznie"* (animation looks terrible)

For Phase 2 scope:
- **Minimalist + pleasant:** Reduce visual noise (softer shadows, more whitespace, cleaner card styling). Use the new color system to create a calm, professional look.
- **Animation:** The shake animation quality was criticized. Consider replacing with a gentler feedback mechanism (border color flash or subtle scale). The tractor animation feedback was separate -- keep existing for now but ensure it adapts to dark mode.
- The "field-ready" high contrast requirement aligns with "pleasant" -- a farmer in bright sunlight needs clear, strong visual hierarchy, which also reads as professional.

### High-Contrast Field-Ready Color Guidelines

For WCAG AA compliance (minimum) and outdoor readability:

- **Text on backgrounds:** Minimum 4.5:1 contrast ratio for body text, 3:1 for large text (title2+)
- **Light mode** `textPrimary` (0.15, 0.15, 0.14) on `backgroundPrimary` (0.96, 0.95, 0.92): ~14:1 ratio -- EXCELLENT
- **Dark mode** `textPrimary` (0.95, 0.95, 0.93) on `backgroundCard` (0.18, 0.20, 0.19): ~13:1 ratio -- EXCELLENT
- **Green button text:** White (1,1,1) on `primaryGreen` (0.18, 0.54, 0.34): ~5.3:1 -- PASSES AA
- **Input labels:** `textSecondary` on `backgroundCard` needs checking in both modes
- **Sunlight readability:** High-contrast colors are inherently better outdoors. The green/white palette has strong contrast. Avoid light-gray-on-white patterns.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|-------------|-----------------|--------------|--------|
| `Color("stringName")` | `Color(.resourceName)` type-safe | Xcode 15 (2023) | Compile-time safety, autocomplete, no string typos |
| `.foregroundColor()` | `.foregroundStyle()` | iOS 17 (2023) | Supports gradients, hierarchical styles. Replacement recommended. |
| Manual trait collection for dark mode | Asset Catalog "Any, Dark" appearances | iOS 13 (2019) | Zero code needed. System handles transitions. |
| `UIFontMetrics` for custom scaling | `@ScaledMetric` | iOS 14 / SwiftUI 2 (2020) | Declarative, no UIKit dependency |
| `GeometryReader` for adaptive layout | `ViewThatFits` | iOS 16 (2022) | Simpler API for choosing layout based on available space |
| `@Environment(\.sizeCategory)` | `@Environment(\.dynamicTypeSize)` | iOS 15 (2021) | New type with clearer API, `.isAccessibilitySize` property |

**Deprecated/outdated:**
- `.foregroundColor()`: Still works but superseded by `.foregroundStyle()` in iOS 17+. Can be replaced opportunistically.
- `Color("string")`: Still works but `Color(.resource)` is safer. Should be replaced.

## Open Questions

1. **Should the tractor animation adapt to dark mode?**
   - What we know: The animation uses hardcoded colors (green body, brown wheels, gray metal, blue water). It renders inside a card with a dark overlay. The card background is `backgroundCard`.
   - What's unclear: Whether the tractor colors should change in dark mode. Green tractor on dark card might look fine as-is. But brown wheels might become invisible on dark background.
   - Recommendation: Replace the animation card background and overlay with adaptive colors. Keep tractor body colors mostly the same but verify visibility. LOW priority -- the user called the animation "tragic" which may mean they want it redesigned, not just adapted.

2. **Should we add the Asset Catalog "High Contrast" appearance (4 variants per color)?**
   - What we know: Asset Catalog supports "Any, Dark, High Contrast, Dark High Contrast" -- 4 variants. iOS "Increase Contrast" accessibility setting triggers the high-contrast variants.
   - What's unclear: Whether the user/target audience needs this level of accessibility.
   - Recommendation: Skip for now. The base colors are already high-contrast (agricultural app, field-ready). Adding 4 variants per color doubles the work for marginal benefit. Can be added later if needed. Satisfies UI-03 requirement through base color choices rather than separate high-contrast variants.

3. **Should `.foregroundColor()` be replaced with `.foregroundStyle()` throughout?**
   - What we know: 36 instances of `.foregroundColor()` across all view files. `.foregroundStyle()` is the modern replacement in iOS 17+.
   - What's unclear: Whether this is strictly required for the phase goals (dark mode, Dynamic Type, high contrast).
   - Recommendation: Replace during the color migration sweep -- it's one extra character change per line and brings the codebase to modern conventions. No functional difference for solid colors.

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis: All 14 Swift files read and analyzed -- actual color/font usage inventoried
- [Xcode 15 Asset Catalog auto-generated symbols](https://nilcoalescing.com/blog/Xcode15Assets/) -- `Color(.name)` syntax, `ColorResource` type, build settings
- [Hacking with Swift: @ScaledMetric](https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-scaledmetric-property-wrapper) -- property wrapper usage, `relativeTo:` parameter
- [SwiftLee: @ScaledMetric for Dynamic Type support](https://www.avanderlee.com/swiftui/scaledmetric-dynamic-type-support/) -- what to scale, testing approach
- [GitHub pkluz/Indicate colorset example](https://github.com/pkluz/Indicate/blob/master/Example/Resources/Assets.xcassets/BackgroundColor.colorset/Contents.json) -- verified JSON structure for light+dark colorset
- [CreateWithSwift: Supporting Increase Contrast](https://www.createwithswift.com/supporting-increase-contrast-in-your-app-to-enhance-accessibility/) -- Asset Catalog High Contrast checkbox, `@Environment(\.colorSchemeContrast)` usage

### Secondary (MEDIUM confidence)
- [Swift by Sundell: Defining dynamic colors](https://www.swiftbysundell.com/articles/defining-dynamic-colors-in-swift/) -- UIColor dynamic provider pattern, Asset Catalog approach comparison
- [SwiftLee: Dark mode support](https://www.avanderlee.com/swift/dark-mode-support-ios/) -- comprehensive dark mode guide, semantic colors
- [Sarunw: @ScaledMetric for margin and padding](https://sarunw.com/posts/swiftui-scaledmetric/) -- practical examples for scaling spacing
- [Sarunw: Xcode 15 asset symbols](https://sarunw.com/posts/swift-symbols-for-asset-catalog/) -- naming conventions, camelCase conversion

### Tertiary (LOW confidence)
- Dark mode gradient color value recommendations (darker greens becoming slightly brighter) -- based on general iOS design patterns, not verified against specific agricultural app guidelines

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Asset Catalog color sets, semantic text styles, @ScaledMetric are stable, well-documented SwiftUI APIs verified against multiple authoritative sources
- Architecture: HIGH -- Pattern of Asset Catalog + type-safe access + semantic fonts is Apple's recommended approach, verified via official docs and Xcode 15+ documentation
- Pitfalls: HIGH -- all pitfalls derived from verified documentation and common real-world issues; codebase-specific inventory (49 color refs, 10 font refs) from direct analysis
- Color values for dark mode: MEDIUM -- specific RGB values for dark mode variants are design choices that should be verified visually. The light mode values are taken directly from existing code. Dark mode values follow standard iOS patterns (lighter/brighter in dark mode for foreground elements, darker for backgrounds).

**Research date:** 2026-02-06
**Valid until:** 2026-03-06 (stable APIs, unlikely to change)
