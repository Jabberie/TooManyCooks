# TooManyCooks

Too Many Cooks is a lightweight World of Warcraft addon that helps with instruction-based events by detecting NPC callouts and clearly highlighting which object or ingredient to use next.

## Current Support

### Suspicious Stew — The Coiled Isle

Detects the Witherbark Cook's instructions and highlights the requested ingredient.

- Salted Split Boar
- Stale Hardtack
- Scavenged Pepperplant
- Lukewarm Fish Guts
- Tracks progress through the 6 ingredient requests
- Automatically resets when the stew is spoiled
- Automatically hides when the event is completed

### Acceptable Apprentice — The Coiled Isle

Detects Ofi the Sly's instructions and highlights the requested ingredient.

- Fish Guts
- Scales
- Pearl Dust
- Tracks progress through the 5 ingredient requests
- Automatically hides when the activity is completed

### Artificing Aggression — Voidstorm

Detects Decimus's forging instructions and highlights the requested component.

- Void Brazier
- Behemoth Bone Dust
- Crystallized Void
- Void Repository
- Tracks progress through the 6 component requests
- Automatically hides when the activity is completed

## Features

- Automatic event detection
- Clear highlighting of the requested object or ingredient
- Progress tracking specific to each supported activity
- Flip/mirror layout to support different player positions
- Movable interface
- Automatic completion detection
- Failure detection and reset where supported
- Mid-event recovery if the opening dialogue was missed or the UI was reloaded
- Only monitors relevant events while in supported areas
- Modular encounter system for adding additional activities

## Development Status

Too Many Cooks was initially vibe-coded as a small quality-of-life addon for the Suspicious Stew event and has since expanded to support other similar instruction-based activities.

The addon has been tested in-game, but bugs and edge cases are possible. Additional activities may be added as they are identified and tested.

Bug reports, fixes, and suggestions for other activities are welcome.

## License

Too Many Cooks is released under the MIT License.