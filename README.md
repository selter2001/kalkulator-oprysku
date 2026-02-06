# Kalkulator Oprysku

Profesjonalny kalkulator opryskow rolniczych na iOS. Szybko i bezblednie oblicza ile srodka chemicznego i wody wlac do kazdego zbiornika opryskiwacza.

## Funkcje

- Obliczanie calkowitej ilosci cieczy roboczej i srodka chemicznego
- Automatyczny podzial na zbiorniki (pelne + czesciowy)
- Sklad kazdego zbiornika: ile wody, ile srodka
- Eksport wynikow do PDF z natywnym udostepnianiem
- Historia obliczen z mozliwoscia ponownego uzycia
- Ulubione konfiguracje opryskow
- Lokalizacja PL / EN
- Tryb ciemny (Dark Mode)
- Wsparcie Dynamic Type (dostepnosc)

## Zrzuty ekranu

<!-- TODO: Add screenshots -->

## Wymagania

- iOS 17.0+
- Xcode 15.0+

## Budowanie

```bash
git clone https://github.com/selter2001/kalkulator-oprysku.git
cd kalkulator-oprysku
open SprayCalculator.xcodeproj
```

1. Wybierz urzadzenie docelowe (symulator lub fizyczne)
2. Nacisnij Cmd+R aby zbudowac i uruchomic

Alternatywnie z linii polecen:

```bash
xcodebuild -scheme SprayCalculator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Architektura

Projekt uzywa wzorca MVVM z natywnym SwiftUI i `@Observable` (iOS 17):

- **Models** -- `SprayCalculation`, `HistoryEntry`, `FavoriteConfig`
- **ViewModels** -- `CalcViewModel` z walidacja i logika obliczen
- **Views** -- `ContentView`, `HistoryView`, `FavoritesView`, `SettingsView`, `AboutView`
- **Services** -- `SprayCalculatorService`, `PDFExportService`
- **Theme** -- Asset Catalog colors + `AppGradients`

## Autor

**Wojciech Olszak**
- GitHub: [@selter2001](https://github.com/selter2001)

## Licencja

Ten projekt jest udostepniony na licencji MIT -- szczegoly w pliku [LICENSE](LICENSE).
