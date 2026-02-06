# Kalkulator Oprysku

## What This Is

Professional iOS spray calculator app (SwiftUI) with MVVM architecture, delivering accurate per-tank composition breakdowns for agricultural spraying operations. Shipped v1.0 includes dark mode theming via Asset Catalog, PDF export with ShareLink, full PL/EN localization, and App Store-ready packaging. Built for Polish farmers who need fast, error-free calculations in the field.

Autor: Wojciech Olszak. Repozytorium: https://github.com/selter2001/kalkulator-oprysku

## Core Value

Rolnik w polu musi szybko i bezbłędnie wiedzieć: ile środka i wody wlać do każdego zbiornika opryskiwacza — bez kalkulatora, kartki, błędów w rachunkach.

## Requirements

### Validated

**v1.0 shipped requirements (16 active + 9 existing):**

- ✓ Skład każdego zbiornika (ile wody + ile środka do pełnego i niepełnego) — Phase 1
- ✓ Eksport wyników do PDF (ImageRenderer, data, podpis autora) — Phase 3
- ✓ Widok "O aplikacji" z informacją o autorze — Phase 3
- ✓ Obsługa trybu ciemnego (Dark Mode) — Phase 2
- ✓ Dynamic Type — czytelne czcionki na każdym rozmiarze — Phase 2
- ✓ Styl "Field-Ready" — wysoki kontrast, czytelność w polu — Phase 2
- ✓ Refaktor do MVVM (logika z widoków do ViewModel) — Phase 1
- ✓ Uporządkowanie struktury plików (Model, View, ViewModel) — Phase 1
- ✓ Zero warnings w Xcode — Phase 3
- ✓ Bundle Identifier pod deployment na fizyczne urządzenie — Phase 3
- ✓ iOS 17+ deployment target — Phase 1
- ✓ Profesjonalny README.md z instrukcją i miejscem na screenshoty — Phase 3
- ✓ Licencja MIT — Phase 3
- ✓ Naprawienie hardcoded polskiego tekstu w HistoryRowView — Phase 1
- ✓ Naprawienie hardcoded polskiego tekstu w SettingsView — Phase 1
- ✓ Commity w języku polskim — Phase 1

**Existing features (preserved from original code):**

- ✓ Obliczanie sumarycznej ilości cieczy roboczej
- ✓ Obliczanie sumarycznej ilości środka
- ✓ Podział na pełne i niepełne zbiorniki
- ✓ Obsługa jednostek powierzchni (ha, ar, m²)
- ✓ Historia obliczeń z UserDefaults (max 50)
- ✓ Ulubione konfiguracje z możliwością zapisu/odczytu
- ✓ Lokalizacja PL/EN z przełączaniem w ustawieniach
- ✓ Animacja traktora przy obliczaniu
- ✓ Walidacja pól wejściowych z haptic feedback

### Active

None — v1.0 complete, awaiting next milestone definition.

### Out of Scope

- Baza danych SQLite / CoreData — UserDefaults wystarcza dla prostych list, niepotrzebna złożoność
- Integracja z GPS / mapami pól — to byłaby osobna, znacznie większa aplikacja
- Rozpoznawanie etykiet środków (OCR/AI) — zbyt złożone na v1
- Synchronizacja iCloud — użytkownik docelowy to jeden rolnik, jedno urządzenie
- Konta użytkowników / backend — aplikacja offline-first
- iPad layout — skupiamy się na iPhone, iPad może działać w kompatybilności
- Testy jednostkowe — istniejący kod jest prosty i obliczeniowy, priorytet to UI/UX

## Context

### v1.0 Codebase (as shipped)

- 17 Swift files organized into Model/View/ViewModel/Services/Theme folders
- MVVM architecture with @Observable macro (iOS 17+)
- SprayCalculatorService with per-tank water/chemical composition logic
- CalcViewModel handling calculation, validation, and formatting
- Asset Catalog with 18 named color sets (light/dark variants)
- AppGradients.swift for semantic gradient definitions
- PDFExportService + PDFContentView for PDF generation
- LocalizationManager for PL/EN language switching
- Zero external dependencies (no SPM/CocoaPods)

### Key Features Delivered

- Per-tank composition: exact liters of water + chemical for full and partial tanks
- PDF export with ShareLink: inputs, results, per-tank breakdown, date, author signature
- Dark mode: all views adapt via Asset Catalog colors
- Dynamic Type: @ScaledMetric, semantic fonts, readable at all sizes
- Field-ready styling: high-contrast colors for outdoor visibility
- About view: author info, version, contact
- Zero hardcoded strings: full PL/EN localization

### Architecture Decisions

- MVVM with dependency injection: CalcViewModel injected with optional SprayCalculatorService for testability
- @Observable over ObservableObject: modern iOS 17+ observation, cleaner than @Published
- Asset Catalog semantic colors: Color(.primaryGreen) resolves dynamically per appearance
- Hardcoded Color.black/white in PDF: dark-mode safety for print documents
- ShareLink eager evaluation: acceptable for single-page PDF (~instant generation)
- UserDefaults persistence: simple, sufficient for history/favorites
- A4 width (595pt) for PDF: European standard for Polish farmers

## Constraints

- **Tech stack**: Swift/SwiftUI only — brak zewnętrznych zależności (SPM/CocoaPods)
- **iOS target**: iOS 17.0+ — wymagane dla ImageRenderer (PDF) i @Observable
- **Język commitów**: polski — wymaganie użytkownika
- **Deployment**: musi kompilować się na fizyczne urządzenie (poprawny Bundle ID)
- **Zero warnings**: projekt musi budować się bez ostrzeżeń w Xcode

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| iOS 17+ deployment target | ImageRenderer for PDF, modern SwiftUI API | ✓ Good |
| Zachowanie lokalizacji PL/EN | User wants both languages | ✓ Good |
| MVVM refaktor | Logic in views hard to maintain | ✓ Good |
| UserDefaults (nie CoreData) | Simple data, few records | ✓ Good |
| Brak zewnętrznych dependencji | Zero deps = zero problems | ✓ Good |
| Asset Catalog named colors | Dynamic light/dark mode resolution | ✓ Good |
| Hardcoded Color.black/white in PDF | Dark mode safety for print documents | ✓ Good |
| A4 width (595pt) for PDF | European standard for Polish farmers | ✓ Good |
| Bundle ID com.wojciecholszak.kalkulatoroprysku | Proper reverse-domain for App Store | ✓ Good |
| @Observable over ObservableObject | Modern iOS 17+ API, cleaner syntax | ✓ Good |
| SprayCalculatorService separate from ViewModel | Pure calculation logic, no UI coupling | ✓ Good |
| provides-namespace: false for Colors subfolder | Color(.primaryGreen) without prefix | ✓ Good |
| AppGradients computed static vars | Asset Catalog colors resolve dynamically | ✓ Good |
| ShareLink(item:) eager evaluation | Acceptable for single-page PDF | ✓ Good |
| 3 new ResultCards for per-tank composition | Clear separation: full tank, partial tank, total chemical | ✓ Good |

## v1.0 Milestone Complete

**Shipped:** 2026-02-06
**Timeline:** ~2 hours (single day)
**Phases:** 3 phases, 8 plans
**Commits:** 35 commits (feat(01-01) → docs(03): zamkniecie Fazy 3)
**LOC:** 2,194 lines of Swift (17 files)

**Archive:** See `.planning/milestones/v1.0-ROADMAP.md` and `.planning/milestones/v1.0-REQUIREMENTS.md`

---
*Last updated: 2026-02-06 after v1.0 milestone complete*
