# Kalkulator Oprysku

## What This Is

Profesjonalna aplikacja iOS (SwiftUI) do obliczania parametrów oprysku rolniczego. Rolnik podaje powierzchnię pola, dawkę środka/ha, ilość wody/ha i pojemność opryskiwacza — aplikacja oblicza ile środka kupić, ile wody przygotować, na ile napełnień rozbić pracę i jaki jest dokładny skład każdego zbiornika (w tym ostatniego niepełnego). Gotowa do publikacji w App Store.

Autor: Wojciech Olszak. Repozytorium: https://github.com/selter2001/kalkulator-oprysku

## Core Value

Rolnik w polu musi szybko i bezbłędnie wiedzieć: ile środka i wody wlać do każdego zbiornika opryskiwacza — bez kalkulatora, kartki, błędów w rachunkach.

## Requirements

### Validated

- ✓ Obliczanie sumarycznej ilości cieczy roboczej — existing
- ✓ Obliczanie sumarycznej ilości środka — existing
- ✓ Podział na pełne i niepełne zbiorniki — existing
- ✓ Obsługa jednostek powierzchni (ha, ar, m²) — existing
- ✓ Historia obliczeń z UserDefaults (max 50) — existing
- ✓ Ulubione konfiguracje z możliwością zapisu/odczytu — existing
- ✓ Lokalizacja PL/EN z przełączaniem w ustawieniach — existing
- ✓ Animacja traktora przy obliczaniu — existing
- ✓ Walidacja pól wejściowych z haptic feedback — existing

### Active

- [ ] Skład każdego zbiornika (ile wody + ile środka do pełnego i niepełnego)
- [ ] Eksport wyników do PDF (ImageRenderer, data, podpis autora)
- [ ] Widok "O aplikacji" z informacją o autorze
- [ ] Obsługa trybu ciemnego (Dark Mode)
- [ ] Dynamic Type — czytelne czcionki na każdym rozmiarze
- [ ] Styl "Field-Ready" — wysoki kontrast, czytelność w polu
- [ ] Refaktor do MVVM (logika z widoków do ViewModel)
- [ ] Uporządkowanie struktury plików (Model, View, ViewModel)
- [ ] Zero warnings w Xcode
- [ ] Bundle Identifier pod deployment na fizyczne urządzenie
- [ ] iOS 17+ deployment target
- [ ] Profesjonalny README.md z instrukcją i miejscem na screenshoty
- [ ] Licencja MIT
- [ ] Naprawienie hardcoded polskiego tekstu w HistoryRowView
- [ ] Commity w języku polskim

### Out of Scope

- Baza danych SQLite / CoreData — UserDefaults wystarcza dla prostych list, niepotrzebna złożoność
- Integracja z GPS / mapami pól — to byłaby osobna, znacznie większa aplikacja
- Rozpoznawanie etykiet środków (OCR/AI) — zbyt złożone na v1
- Synchronizacja iCloud — użytkownik docelowy to jeden rolnik, jedno urządzenie
- Konta użytkowników / backend — aplikacja offline-first
- iPad layout — skupiamy się na iPhone, iPad może działać w kompatybilności
- Testy jednostkowe — istniejący kod jest prosty i obliczeniowy, priorytet to UI/UX

## Context

### Istniejący kod
- 12 plików Swift w jednym katalogu `SprayCalculator/`
- Xcode project (`SprayCalculator.xcodeproj`) już istnieje
- Brak podziału na foldery (Model/View/ViewModel)
- Kolory hardcoded — `Color.white`, `Color(red:...)` — nie adaptują się do dark mode
- `LocalizationManager` — ręczna lokalizacja (nie .strings), ale działa dobrze
- `HistoryRowView` ma hardcoded "pełne"/"częściowe" zamiast użycia `localization`
- Animacja traktora jest fajna — zachowujemy

### Logika obliczeniowa
- `chemicalPerTank = (chemicalRate / sprayRate) * tankCapacity` — poprawna proporcja
- Brakuje: skład każdego zbiornika (woda vs środek), szczególnie dla niepełnego zbiornika
- Brakuje: ile środka wlać do niepełnego zbiornika osobno

### Cel końcowy
- Aplikacja gotowa do App Store
- Profesjonalny wygląd i branding
- Podpis "Created by Wojciech Olszak" w widoku O aplikacji i w PDF

## Constraints

- **Tech stack**: Swift/SwiftUI only — brak zewnętrznych zależności (SPM/CocoaPods)
- **iOS target**: iOS 17.0+ — wymagane dla ImageRenderer (PDF)
- **Język commitów**: polski — wymaganie użytkownika
- **Deployment**: musi kompilować się na fizyczne urządzenie (poprawny Bundle ID)
- **Zero warnings**: projekt musi budować się bez ostrzeżeń w Xcode

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| iOS 17+ deployment target | Potrzebne ImageRenderer dla PDF, nowoczesne SwiftUI API | — Pending |
| Zachowanie lokalizacji PL/EN | Użytkownik chce obu języków, istniejący system działa | — Pending |
| MVVM refaktor | Logika w widokach utrudnia testowanie i rozwój | — Pending |
| UserDefaults (nie CoreData) | Proste dane, mało rekordów, niepotrzebna złożoność | ✓ Good |
| Brak zewnętrznych dependencji | Zero zależności = zero problemów z aktualizacjami | — Pending |

---
*Last updated: 2026-02-06 after initialization*
