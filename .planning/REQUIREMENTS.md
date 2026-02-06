# Requirements -- Kalkulator Oprysku v1.0

## v1 Requirements

### Obliczenia (CALC)

- [x] **CALC-01**: Skad pelnego zbiornika -- ile litrow wody + ile litrow srodka wlac do kazdego pelnego zbiornika
- [x] **CALC-02**: Skad niepelnego zbiornika -- ile litrow wody + ile litrow srodka wlac do ostatniego, niepelnego zbiornika
- [x] **CALC-03**: Podsumowanie zakupowe -- sumaryczna ilosc srodka do kupienia na cale pole

### UI/UX (UI)

- [x] **UI-01**: Obsluga trybu ciemnego (Dark Mode) -- Asset Catalog named colors, adaptacyjne gradienty
- [x] **UI-02**: Dynamic Type -- semantyczne czcionki, @ScaledMetric, czytelnosc na kazdym rozmiarze
- [x] **UI-03**: Styl "Field-Ready" -- wysoki kontrast, duze przyciski, czytelnosc w pelnym sloncu
- [x] **UI-04**: Refaktor do MVVM -- logika z widokow do ViewModel, podzial na foldery Model/View/ViewModel/Services/Theme

### Eksport i branding (EXP)

- [ ] **EXP-01**: Eksport wynikow do PDF -- ImageRenderer, data, wyniki, podpis "Wygenerowano w aplikacji autorstwa Wojciecha Olszaka"
- [ ] **EXP-02**: Widok "O aplikacji" -- informacja o autorze, wersja, link do kontaktu
- [ ] **EXP-03**: Profesjonalny README.md z instrukcja budowania i miejsce na screenshoty + Licencja MIT
- [ ] **EXP-04**: Zero warnings w Xcode + poprawny Bundle Identifier pod deployment

### Naprawy i porzadki (FIX)

- [x] **FIX-01**: Naprawienie hardcoded polskiego tekstu w HistoryRowView -- uzycie LocalizationManager
- [x] **FIX-02**: Naprawienie hardcoded polskiego tekstu w SettingsView ("Wersja", "Informacje")
- [x] **FIX-03**: Uporzadkowanie struktury plikow -- podzial na foldery Model/View/ViewModel/Services/Theme
- [x] **FIX-04**: iOS 17+ deployment target -- wymagane dla ImageRenderer i nowoczesnych API
- [x] **FIX-05**: Migracja z ObservableObject/@Published na @Observable/@Bindable (iOS 17+)

### Istniejace (zachowane z obecnego kodu) (EXISTING)

- [x] **EXISTING-01**: Obliczanie sumarycznej ilosci cieczy roboczej
- [x] **EXISTING-02**: Obliczanie sumarycznej ilosci srodka
- [x] **EXISTING-03**: Podzial na pelne i niepelne zbiorniki
- [x] **EXISTING-04**: Obsluga jednostek powierzchni (ha, ar, m2)
- [x] **EXISTING-05**: Historia obliczen z UserDefaults (max 50)
- [x] **EXISTING-06**: Ulubione konfiguracje z mozliwoscia zapisu/odczytu
- [x] **EXISTING-07**: Lokalizacja PL/EN z przelaczaniem w ustawieniach
- [x] **EXISTING-08**: Animacja traktora przy obliczaniu
- [x] **EXISTING-09**: Walidacja pol wejsciowych z haptic feedback

## v2 Requirements (odroczone)

- Integracja z GPS / mapami pol
- Rozpoznawanie etykiet srodkow (OCR/AI)
- Synchronizacja iCloud
- iPad layout (dedykowany)
- Testy jednostkowe

## Out of Scope

| Wykluczone | Powod |
|------------|-------|
| Baza danych SQLite / CoreData | UserDefaults wystarcza dla prostych list |
| Konta uzytkownikow / backend | Aplikacja offline-first, jeden rolnik |
| Zewnetrzne zaleznosci (SPM/CocoaPods) | Zero zaleznosci = zero problemow |
| Rekomendacje dawek srodkow | Odpowiedzialnosc prawna -- aplikacja tylko liczy, nie doradza |
| Sprawdzanie kompatybilnosci srodkow | Zbyt zlozone, wymaga bazy danych chemicznej |

## Traceability

| REQ | Phase | Plan | Status |
|-----|-------|------|--------|
| CALC-01 | Phase 1 | 01-03 | Complete |
| CALC-02 | Phase 1 | 01-03 | Complete |
| CALC-03 | Phase 1 | 01-03 | Complete |
| UI-01 | Phase 2 | 02-01, 02-02 | Complete |
| UI-02 | Phase 2 | 02-01, 02-02 | Complete |
| UI-03 | Phase 2 | 02-01, 02-02 | Complete |
| UI-04 | Phase 1 | 01-01, 01-02, 01-03 | Complete |
| EXP-01 | Phase 3 | -- | pending |
| EXP-02 | Phase 3 | -- | pending |
| EXP-03 | Phase 3 | -- | pending |
| EXP-04 | Phase 3 | -- | pending |
| FIX-01 | Phase 1 | 01-04 | Complete |
| FIX-02 | Phase 1 | 01-04 | Complete |
| FIX-03 | Phase 1 | 01-01 | Complete |
| FIX-04 | Phase 1 | 01-01 | Complete |
| FIX-05 | Phase 1 | 01-01 | Complete |

---
*16 aktywnych wymagan v1 + 9 istniejacych = 25 lacznie*
*Last updated: 2026-02-06 -- phase mappings added*
