# Phase 3: Export & App Store Prep - Research

**Researched:** 2026-02-06
**Domain:** SwiftUI PDF generation (ImageRenderer), ShareLink, AboutView, Bundle ID, zero-warnings cleanup
**Confidence:** HIGH

## Summary

Phase 3 covers four requirements: PDF export of calculation results (EXP-01), an About screen (EXP-02), README + MIT LICENSE (EXP-03), and zero Xcode warnings with correct Bundle Identifier (EXP-04). The technical core is SwiftUI's `ImageRenderer` (iOS 16+) which renders any SwiftUI view to a vector PDF via `CGContext`, paired with `ShareLink` (iOS 16+) for the native share sheet. Both APIs are well-documented and stable on iOS 17.

The project already has a clean MVVM architecture with `@Observable`, `SprayCalculation` model with all required data fields, `LocalizationManager` for PL/EN strings, and Asset Catalog-based theming. The PDF content view will be a dedicated SwiftUI view that lays out the calculation data in a print-friendly format. No external dependencies are needed -- everything uses native SwiftUI + CoreGraphics APIs.

**Primary recommendation:** Create a `PDFContentView` that renders the SprayCalculation data in a fixed-width layout, use `ImageRenderer.render()` to write it to a temporary PDF URL, and share via `ShareLink(item: url)`. The About screen is a simple `List`-based view reading `Bundle.main` info. Bundle ID must change from `com.spraycalculator.app` to `com.wojciecholszak.kalkulatoroprysku` (proper reverse-domain).

## Standard Stack

### Core (all native -- zero external dependencies)

| API | iOS Version | Purpose | Why Standard |
|-----|-------------|---------|--------------|
| `ImageRenderer` | 16.0+ | Render SwiftUI view to PDF via `CGContext` | Apple's official SwiftUI-to-PDF path; vector output |
| `ShareLink` | 16.0+ | Native share sheet for the generated PDF | Built-in SwiftUI view, no UIKit wrapping needed |
| `CGContext` (CoreGraphics) | 2.0+ | PDF page creation and rendering | Low-level PDF context; `ImageRenderer.render()` provides the draw callback |
| `Bundle.main` | 2.0+ | Read app version, build number from Info.plist | Standard iOS approach for `CFBundleShortVersionString` |

### Supporting

| API | Purpose | When to Use |
|-----|---------|-------------|
| `URL.documentsDirectory` | PDF file output path | Destination for rendered PDF before sharing |
| `FileManager.default.temporaryDirectory` | Alternative temp path | If PDF should not persist after sharing |
| `NumberFormatter` | Consistent number formatting in PDF | Already exists in `CalcViewModel.formatNumber()` -- reuse |
| `Date.formatted()` | Date display in PDF footer | SwiftUI-native date formatting |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `ImageRenderer` PDF | `UIGraphicsPDFRenderer` (UIKit) | More control but requires UIKit bridge; ImageRenderer is simpler and pure SwiftUI |
| `ShareLink` | `UIActivityViewController` via `UIViewControllerRepresentable` | Works but is UIKit legacy; ShareLink is the SwiftUI-native way |
| Custom PDF with CoreText | `ImageRenderer` | CoreText gives pixel-perfect control but massive complexity; overkill for this use case |

**No installation needed -- all APIs are in the iOS SDK.**

## Architecture Patterns

### Recommended Project Structure

```
SprayCalculator/
  Services/
    SprayCalculatorService.swift    (existing)
    PDFExportService.swift          (NEW -- render logic)
  ViewModels/
    CalcViewModel.swift             (existing -- add export action)
  Views/
    ContentView.swift               (existing -- add export button)
    AboutView.swift                 (NEW)
    PDFContentView.swift            (NEW -- layout for PDF, not shown on screen)
  Theme/
    AppGradients.swift              (existing)
  ...existing files...
```

### Pattern 1: PDFExportService (Service Layer)

**What:** A struct that takes a `SprayCalculation` + localization strings and returns a PDF `URL`.
**When to use:** Called from the view layer when user taps the export/share button.

```swift
// Source: Hacking with Swift + Apple Developer Documentation
struct PDFExportService {
    @MainActor
    static func generatePDF(
        for calculation: SprayCalculation,
        localization: LocalizationManager
    ) -> URL {
        let content = PDFContentView(
            calculation: calculation,
            localization: localization
        )
        .frame(width: 595) // A4 width in points (210mm)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2.0 // Retina quality

        let url = URL.documentsDirectory.appending(path: "KalkulatorOprysku.pdf")

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
}
```

### Pattern 2: PDFContentView (Print-Only View)

**What:** A SwiftUI view designed exclusively for PDF rendering -- never shown on screen.
**When to use:** Passed to `ImageRenderer` as the content to render.

```swift
// Source: verified pattern from multiple SwiftUI PDF tutorials
struct PDFContentView: View {
    let calculation: SprayCalculation
    let localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with app name and date
            headerSection

            // Input parameters
            inputSection

            // Results
            resultsSection

            // Per-tank breakdown
            tankBreakdownSection

            // Footer with author signature
            footerSection
        }
        .padding(40)
        .background(Color.white) // PDF always white background
        .foregroundStyle(Color.black) // PDF always black text
    }
}
```

**Key insight:** The PDF view must use hardcoded white/black colors (not Asset Catalog colors) because it renders to a document, not to screen. Asset Catalog dark mode colors would produce unreadable dark-on-dark PDFs.

### Pattern 3: ShareLink Integration (Toolbar Button)

**What:** Add a ShareLink to the results section that generates and shares the PDF.
**When to use:** Only visible after calculation results are displayed.

```swift
// Source: Hacking with Swift, DEV Community verified pattern
ShareLink(item: PDFExportService.generatePDF(
    for: result,
    localization: localization
)) {
    Label(localization.exportPDF, systemImage: "square.and.arrow.up")
}
```

**Important:** `ShareLink(item:)` accepts `URL` directly because `URL` already conforms to `Transferable`. No custom Transferable conformance needed.

### Pattern 4: AboutView

**What:** Simple informational view showing author, version, contact.
**When to use:** Accessible from Settings or a dedicated tab/navigation link.

```swift
struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        List {
            Section {
                // Author
                Label("Wojciech Olszak", systemImage: "person.fill")
                // Version
                Label("\(appVersion) (\(buildNumber))", systemImage: "info.circle")
                // Contact
                Link(destination: URL(string: "mailto:contact@example.com")!) {
                    Label("contact@example.com", systemImage: "envelope.fill")
                }
            }
        }
    }
}
```

### Anti-Patterns to Avoid

- **Rendering Asset Catalog colors in PDF:** The PDF view must NOT use `Color(.textPrimary)` or `Color(.backgroundCard)` -- these adapt to dark mode and will produce unreadable PDFs when the device is in dark mode. Use explicit `Color.black` and `Color.white`.
- **Forgetting `.frame(width:)` on PDF content:** Without a fixed width, `ImageRenderer` renders at an unpredictable size. Always constrain the width (595pt for A4, 612pt for US Letter).
- **Not setting `renderer.scale`:** Default scale may produce blurry output on Retina devices. Set `renderer.scale = 2.0` or use `UIScreen.main.scale`.
- **Blocking main thread:** `ImageRenderer.render()` is synchronous and must run on `@MainActor`. For complex views this is fine (our view is simple), but be aware.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF generation | Custom CoreText/CoreGraphics PDF drawing | `ImageRenderer` + SwiftUI view | SwiftUI handles layout, fonts, spacing automatically |
| Share sheet | `UIActivityViewController` wrapper | `ShareLink` | Native SwiftUI, no UIKit bridge needed |
| App version reading | Hardcoded string "1.0" | `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` | Stays in sync with Xcode project settings automatically |
| License file | Custom text | Standard MIT License template from choosealicense.com | Legally correct, widely recognized |

**Key insight:** This phase is almost entirely "assemble existing APIs" -- the framework provides everything. The only real work is designing the PDF layout view.

## Common Pitfalls

### Pitfall 1: Dark Mode Colors in PDF

**What goes wrong:** PDF renders with dark background and light text when device is in dark mode, making the document unreadable when printed or viewed on a white background.
**Why it happens:** `Color(.textPrimary)` resolves to white in dark mode. `ImageRenderer` captures the view as-is, including dark mode colors.
**How to avoid:** Use explicit `Color.black` / `Color.white` / `Color.gray` in the `PDFContentView`. Never use Asset Catalog named colors in the PDF view.
**Warning signs:** PDF looks fine in light mode preview but appears blank/dark when tested in dark mode.

### Pitfall 2: ImageRenderer iOS 17.4 Regression with SwiftData

**What goes wrong:** `ImageRenderer` crashes with SwiftData error "no entities in default configuration" on iOS 17.4+.
**Why it happens:** iOS 17.4 introduced a bug where ImageRenderer requires explicit model context.
**How to avoid:** This project does NOT use SwiftData/CoreData, so this bug does NOT apply. However, if future versions add SwiftData, add `.modelContext(modelContext)` to the ImageRenderer content.
**Warning signs:** Fatal error about SwiftData configuration during PDF render.

### Pitfall 3: Missing Width Constraint on PDF Content

**What goes wrong:** The rendered PDF has unpredictable width, text wraps oddly or extends beyond page.
**Why it happens:** SwiftUI's layout system needs a proposed width to determine line breaks and layout.
**How to avoid:** Always wrap the PDF content view in `.frame(width: 595)` (A4) before passing to ImageRenderer.
**Warning signs:** PDF text runs off the right edge or view renders as a thin column.

### Pitfall 4: Bundle Identifier Format

**What goes wrong:** App fails to deploy to physical device, or provisioning profile doesn't match.
**Why it happens:** Current Bundle ID `com.spraycalculator.app` is not proper reverse-domain notation tied to the developer's identity.
**How to avoid:** Change to `com.wojciecholszak.kalkulatoroprysku` (or similar with the developer's actual domain) in both Debug and Release build configurations.
**Warning signs:** Xcode shows signing errors, "no provisioning profile" warnings.

### Pitfall 5: Localization Strings Missing for New Views

**What goes wrong:** New views (AboutView, PDF export button) show hardcoded Polish text, breaking English localization.
**Why it happens:** Forgetting to add new strings to `LocalizationManager`.
**How to avoid:** Add ALL new user-visible strings to `LocalizationManager` before building views. The project uses a manual localization system, not `.strings` files.
**Warning signs:** Switching to English still shows Polish labels for new features.

### Pitfall 6: ShareLink Evaluated Eagerly

**What goes wrong:** The PDF is generated when the view loads, not when the user taps the share button. This causes unnecessary work and potential stale PDFs.
**Why it happens:** `ShareLink(item: generatePDF())` evaluates the function immediately when building the view hierarchy.
**How to avoid:** Use a computed property or wrap in a button that generates the PDF first, then presents the share sheet. Alternatively, use `ShareLink(item: url, preview:)` where `url` is a binding that gets set when needed.
**Warning signs:** App slows down when showing results, even before user wants to export. Or alternatively, use `@State` with a sheet-based approach.

**Recommended approach:** Generate the PDF on-demand:
```swift
// Option A: Generate each time (simplest, PDF is small)
ShareLink(item: PDFExportService.generatePDF(for: result, localization: localization))

// Option B: Generate on button tap, then show sheet (if performance matters)
Button("Export PDF") {
    pdfURL = PDFExportService.generatePDF(for: result, localization: localization)
    showShareSheet = true
}
```

For this app's simple PDF, Option A is sufficient. The PDF generation is fast (single page, simple layout).

## Code Examples

### Complete PDF Generation + Share Flow

```swift
// Source: Hacking with Swift tutorial + Apple Developer Documentation
// Verified pattern from multiple sources

// MARK: - PDFExportService.swift (in Services/)
import SwiftUI

struct PDFExportService {
    @MainActor
    static func generatePDF(
        for calculation: SprayCalculation,
        localization: LocalizationManager
    ) -> URL {
        let content = PDFContentView(
            calculation: calculation,
            localization: localization
        )
        .frame(width: 595) // A4 width in points

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2.0

        let url = URL.documentsDirectory.appending(path: "KalkulatorOprysku.pdf")

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
}
```

### PDF Content Layout View

```swift
// Source: based on verified ImageRenderer PDF patterns
// This view is ONLY used for PDF rendering, never shown on screen

struct PDFContentView: View {
    let calculation: SprayCalculation
    let localization: LocalizationManager

    private var dateString: String {
        calculation.date.formatted(date: .long, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text(localization.appTitle)
                .font(.title.bold())

            Divider()

            // Date
            Text(dateString)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Input parameters section
            Text(localization.currentLanguage == .polish ? "Parametry" : "Parameters")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text(localization.fieldArea)
                    Text("\(formatNumber(calculation.fieldArea)) \(calculation.areaUnit.displayName)")
                        .bold()
                }
                GridRow {
                    Text(localization.sprayRate)
                    Text("\(formatNumber(calculation.sprayRate)) l/ha").bold()
                }
                GridRow {
                    Text(localization.chemicalRate)
                    Text("\(formatNumber(calculation.chemicalRate)) l/ha").bold()
                }
                GridRow {
                    Text(localization.tankCapacity)
                    Text("\(formatNumber(calculation.tankCapacity)) l").bold()
                }
            }

            Divider()

            // Results section
            Text(localization.results)
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text(localization.workingFluid)
                    Text("\(formatNumber(calculation.totalWorkingFluid)) l").bold()
                }
                GridRow {
                    Text(localization.totalChemicalToBuy)
                    Text("\(formatNumber(calculation.totalChemical)) l").bold()
                }
                GridRow {
                    Text(localization.tankFills)
                    Text(tankDescription).bold()
                }
            }

            Divider()

            // Per-tank breakdown
            Text(localization.fullTankComposition)
                .font(.headline)
            Text("\(localization.water): \(formatNumber(calculation.waterPerFullTank)) l + \(localization.chemical): \(formatNumber(calculation.chemicalPerTank)) l")

            if calculation.hasPartialTank {
                Text(localization.partialTankComposition)
                    .font(.headline)
                Text("\(localization.water): \(formatNumber(calculation.waterForPartialTank)) l + \(localization.chemical): \(formatNumber(calculation.chemicalForPartialTank)) l")
            }

            Spacer()

            Divider()

            // Footer with author signature
            Text(localization.currentLanguage == .polish
                 ? "Wygenerowano w aplikacji autorstwa Wojciecha Olszaka"
                 : "Generated in app by Wojciech Olszak")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .foregroundStyle(Color.black) // Always black text for PDF
        .background(Color.white)      // Always white background for PDF
    }

    // MARK: - Helpers
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var tankDescription: String {
        if calculation.fullTanks > 0 && calculation.hasPartialTank {
            return "\(calculation.fullTanks) \(localization.fullTanks) + 1 \(localization.partialTank)"
        } else if calculation.fullTanks > 0 {
            return "\(calculation.fullTanks) \(localization.fullTanks)"
        } else if calculation.hasPartialTank {
            return "1 \(localization.partialTank)"
        }
        return "0"
    }
}
```

### ShareLink in Results View

```swift
// Source: Apple ShareLink documentation
// Add after the last ResultCard in resultsSection:

if viewModel.showResults, let result = viewModel.calculationResult {
    ShareLink(
        item: PDFExportService.generatePDF(for: result, localization: localization),
        preview: SharePreview(
            localization.appTitle,
            image: Image(systemName: "doc.text")
        )
    ) {
        Label(
            localization.currentLanguage == .polish ? "Eksportuj PDF" : "Export PDF",
            systemImage: "square.and.arrow.up"
        )
    }
}
```

### App Version from Bundle

```swift
// Source: Apple Bundle documentation, Hacking with Swift
private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}

private var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
```

### MIT LICENSE File Content

```
MIT License

Copyright (c) 2026 Wojciech Olszak

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `UIGraphicsPDFRenderer` (UIKit) | `ImageRenderer` (SwiftUI) | iOS 16 (2022) | Can render any SwiftUI view to PDF without UIKit bridge |
| `UIActivityViewController` | `ShareLink` | iOS 16 (2022) | Native SwiftUI share sheet, no UIKit wrapping |
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 (2023) | Already adopted in this project |
| Manual color management | Asset Catalog named colors | iOS 11+ | Already adopted in this project |

**Deprecated/outdated:**
- `UIActivityViewController` wrapping is unnecessary since iOS 16 -- use `ShareLink`
- `@State private var activityItems: [Any]` pattern is obsolete for share sheets

## Current Bundle ID Analysis

The project currently uses `com.spraycalculator.app` as the Bundle Identifier. This needs to change:

| Issue | Current | Should Be |
|-------|---------|-----------|
| Not reverse-domain | `com.spraycalculator.app` | `com.wojciecholszak.kalkulatoroprysku` |
| Not tied to developer | Generic "spraycalculator" | Should use developer's name/domain |
| Both configs must match | Debug = Release (ok) | Must update BOTH Debug and Release in pbxproj |

**Note:** The Development Team (`DB4A3HP486`) is already set with Automatic signing. Changing Bundle ID should work with automatic provisioning profile generation.

## Localization Strings Needed

New strings to add to `LocalizationManager`:

| Key | Polish | English |
|-----|--------|---------|
| `exportPDF` | "Eksportuj PDF" | "Export PDF" |
| `about` | "O aplikacji" | "About" |
| `author` | "Autor" | "Author" |
| `contact` | "Kontakt" | "Contact" |
| `pdfSignature` | "Wygenerowano w aplikacji autorstwa Wojciecha Olszaka" | "Generated in app by Wojciech Olszak" |
| `parameters` | "Parametry" | "Parameters" |

## Open Questions

1. **Contact information for About view**
   - What we know: EXP-02 requires "link do kontaktu" (contact link)
   - What's unclear: What specific email/URL should be displayed? GitHub profile? Email?
   - Recommendation: Use the GitHub repo URL (https://github.com/selter2001/kalkulator-oprysku) as the primary contact link, possibly with an email if the author provides one. Can use a placeholder for now.

2. **PDF paper size: A4 vs US Letter**
   - What we know: A4 is standard in Poland/Europe (595 x 842 pt). US Letter is 612 x 792 pt.
   - What's unclear: Which the user prefers.
   - Recommendation: Use A4 (595pt width) since the app is Polish-authored and primarily for Polish farmers. The content is simple enough that it fits either size.

3. **ShareLink eager evaluation concern**
   - What we know: `ShareLink(item: func())` calls the function when the view is built.
   - What's unclear: Whether this causes noticeable lag for this simple PDF.
   - Recommendation: Start with the simple `ShareLink(item:)` approach. If there is lag, switch to a Button + sheet approach. For a single-page PDF with text only, generation should be nearly instant.

## Sources

### Primary (HIGH confidence)
- [Hacking with Swift - Render SwiftUI view to PDF](https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf) - Complete ImageRenderer + CGContext pattern
- [AppCoda - SwiftUI ImageRenderer PDF](https://www.appcoda.com/swiftui-imagerenderer-pdf/) - PDF export with mediaBox sizing
- [Sima's Swifty Blog - Sharing files in SwiftUI](https://www.simanerush.com/posts/sharing-files) - Transferable + FileRepresentation for PDF
- [DEV Community - SwiftUI Views to PDFs](https://dev.to/uy/turning-swiftui-views-into-pdfs-a-quick-how-to-388n) - Complete ShareLink(item: url) pattern
- [Choose a License - MIT](https://choosealicense.com/licenses/mit/) - Standard MIT License template

### Secondary (MEDIUM confidence)
- [Hacking with Swift Forums - iOS 17.4 regression](https://www.hackingwithswift.com/forums/swiftui/rendering-to-pdf-fails-in-ios-17-4-ok-in-ios-17-2/26795) - SwiftData-related crash (not applicable to this project)
- [Apple Developer Forums - ShareLink + PDFDocument](https://developer.apple.com/forums/thread/708538) - PDFDocument Transferable conformance

### Tertiary (LOW confidence)
- None -- all findings verified with multiple sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All APIs are native Apple frameworks, well-documented, stable since iOS 16+
- Architecture: HIGH - PDFExportService + PDFContentView pattern is the consensus approach across all tutorials
- Pitfalls: HIGH - Dark mode colors in PDF is the #1 documented issue; all others verified from forums
- Bundle ID: HIGH - Current ID `com.spraycalculator.app` is clearly not reverse-domain; fix is straightforward
- Localization: HIGH - Existing LocalizationManager pattern is clear; just add new keys

**Research date:** 2026-02-06
**Valid until:** 2026-03-06 (stable APIs, unlikely to change)
