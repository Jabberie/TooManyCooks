# Changelog

All notable changes to Too Many Cooks will be documented here.

## [12.003] - 2026-08-17

### Added
- Support for the **Artificing Aggression** event in Voidstorm.
- Added Decimus encounter detection.
- Added ingredient highlighting for:
  - Void Brazier
  - Behemoth Bone Dust
  - Crystallized Void
  - Void Repository
- Added support for Voidstorm (Map ID 2405).
- Added automatic completion detection for Artificing Aggression.

### Changed
- Expanded Too Many Cooks to support encounters across multiple zones.
- Artificing Aggression uses its physical ingredient layout:
  - Void Brazier
  - Behemoth Bone Dust
  - Crystallized Void
  - Void Repository

## [12.002] - 2026-08-13

### Added
- Support for the Acceptable Apprentice cooking event.
- Added Fish Guts, Scales, and Pearl Dust ingredient highlighting.
- Added support for encounters with different numbers of ingredients and required steps.

### Changed
- Refactored Too Many Cooks into a modular structure.
- Cooking events now have separate encounter files for easier maintenance and expansion.
- Ingredient panels now automatically resize based on the number of available ingredients.
- Updated release packaging to support the new modular structure.

## [12.001] - 2026-08-13

### Added

- Initial release.
- Support for the **Suspicious Stew** cooking event on The Coiled Isle.
- Automatic detection of the Witherbark Cook event.
- Ingredient callout detection for:
  - Boar
  - Bread
  - Peppers
  - Fish
- Clear visual highlighting of the requested ingredient.
- 6-step progress counter.
- Automatic reset when the stew is spoiled.
- Automatic hiding when the event is completed.
- Flip button to mirror the ingredient layout depending on which side of the cooking area the player is standing.
- Movable interface.
- Close button and right-click-to-close support.
- Automatic activation when the event begins.
- Area detection for The Coiled Isle.
- Lazy UI creation and event registration to keep the addon dormant outside supported content.
- Mid-event recovery if the initial dialogue was missed or the UI was reloaded.