---
phase: 01-foundation-mvvm
plan: 02
subsystem: architecture
tags: [swift, observable, mvvm, viewmodel, service-layer, dependency-injection]

# Dependency graph
requires:
  - phase: 01-foundation-mvvm plan 01
    provides: "@Observable managers, Models.swift with SprayCalculation, pbxproj project structure"
provides:
  - "SprayCalculatorService struct -- pure computation layer without SwiftUI"
  - "SprayCalculation.waterPerFullTank and waterForPartialTank computed properties"
  - "@Observable CalcViewModel with full calculation, validation, formatting, and history logic"
  - "HistoryManager DI via init injection in CalcViewModel"
affects: [01-03 UI refactor to bind to CalcViewModel, 01-04 final polish]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Service struct for pure computation (no framework imports)", "ViewModel accepts dependencies via init (constructor DI)", "Localization strings passed as method parameters (ViewModel decoupled from LocalizationManager)"]

key-files:
  created:
    - "SprayCalculator/Services/SprayCalculatorService.swift"
    - "SprayCalculator/ViewModels/CalcViewModel.swift"
  modified:
    - "SprayCalculator/Models.swift"
    - "SprayCalculator.xcodeproj/project.pbxproj"

key-decisions:
  - "SprayCalculatorService named as struct (not class) -- stateless, pure computation"
  - "CalcViewModel passes localization strings as parameters to avoid LocalizationManager dependency"
  - "parseNumber() and formatNumber() are public on CalcViewModel -- view needs them for display"
  - "Haptic feedback (UINotificationFeedbackGenerator) stays in ViewModel alongside validation logic"

patterns-established:
  - "Service struct: Pure computation services as struct with no framework imports"
  - "ViewModel DI: Dependencies injected via init(), services instantiated internally"
  - "Localization decoupling: ViewModel methods accept localized strings as parameters"

# Metrics
duration: 4min
completed: 2026-02-06
---

# Phase 1 Plan 2: SprayCalculatorService + CalcViewModel Extraction Summary

**Pure SprayCalculatorService struct with CalcViewModel @Observable extracting all calculation, validation, formatting, and history logic from the view layer**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-06T09:41:22Z
- **Completed:** 2026-02-06T09:44:59Z
- **Tasks:** 2
- **Files modified:** 2 created + 2 modified

## Accomplishments
- Created SprayCalculatorService as a pure struct in Services/ with zero SwiftUI dependency
- Extended SprayCalculation model with waterPerFullTank and waterForPartialTank computed properties for per-tank water composition
- Extracted complete calculation logic from CalculatorViewWithFavorite into @Observable CalcViewModel
- CalcViewModel accepts HistoryManager via constructor DI and uses SprayCalculatorService for computation
- Both new files registered in pbxproj and project builds successfully

## Task Commits

Each task was committed atomically:

1. **Task 1: Create SprayCalculatorService and extend model** - `0f60fbb` (feat)
2. **Task 2: Create CalcViewModel with full calculation logic** - `415e9ff` (feat)

## Files Created/Modified
- `SprayCalculator/Services/SprayCalculatorService.swift` - Pure computation service struct wrapping SprayCalculation creation
- `SprayCalculator/ViewModels/CalcViewModel.swift` - @Observable ViewModel with input state, output state, calculation, validation, formatting, haptic feedback, favorite loading
- `SprayCalculator/Models.swift` - Added waterPerFullTank and waterForPartialTank computed properties
- `SprayCalculator.xcodeproj/project.pbxproj` - Registered both new files (Services/, ViewModels/)

## Decisions Made
- SprayCalculatorService is a struct (not class) -- purely stateless computation, no framework imports needed
- CalcViewModel.calculate() accepts `invalidValueError: String` parameter so it does not depend on LocalizationManager
- CalcViewModel.tankFillsDescription() accepts `fullTanksLabel` and `partialTankLabel` as parameters for the same reason
- parseNumber() and formatNumber() are public -- the view needs them for display formatting
- Haptic feedback (UINotificationFeedbackGenerator) lives in ViewModel alongside validation logic, not in the view

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SprayCalculatorService and CalcViewModel ready for view binding in Plan 03
- CalculatorViewWithFavorite still has its own logic inline -- Plan 03 will refactor it to use CalcViewModel
- showSaveDialog and favoriteName remain as @State in view (as designed)
- Both Services/ and ViewModels/ directories established for future files

## Self-Check: PASSED

---
*Phase: 01-foundation-mvvm*
*Completed: 2026-02-06*
