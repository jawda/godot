# Last Rites — Backlog

---

## Needs Design Decisions

- [ ] **Intelligence stat** — field exists on PlayerData, no effect wired yet. Reserved for card synergies / spell scaling.
- [ ] **Run structure** — map layout, room types (combat, rest, store, event), floor progression, encounter groupings
- [ ] **Compendium unlock tiers** — seen (basic info) vs defeated (full lore). EnemyData has `description` and `compendium_lore` fields ready; unlock state lives in save data.
- [ ] **Additional player classes** — design and card pools. Revisiting after combat system is fully playable.

---

## Ready to Build

Design is clear enough to start implementation.

- [ ] **Audio buses** — Music and SFX buses need to be created in Project Settings → Audio for the settings sliders to have any effect
- [ ] **Status effect visuals on enemies** — show stack counts on the enemy card (e.g. "Burn ×2"). EnemyData and CombatManager already track statuses.
- [ ] **Enemy AI context conditions** — `PLAYER_HP_BELOW_THRESHOLD`, `ALLY_PRESENT`, `ALLY_DIED` on `ActionWeightModifier` need the combat manager to evaluate and pass in before weight selection. Data fields exist, evaluation logic is missing.
- [ ] **CharacterMenu wired into battlefield** — open on pause input during combat, close resumes. `character_menu.tscn` exists; just needs wiring to a pause input action and `Battlefield` hooks.
- [ ] **Continue wired to save state** — currently goes to character select same as New Game. Needs to load the character's `RunSaveData` (health, floor, deck) and resume mid-run.
- [ ] **Back button on character select** — no way to return to the start screen from character select yet.
- [ ] **Settings overlay label** — "Exit to Main Menu" button in `SettingsTab` reads oddly when shown from the start screen. Should contextually read "Back" or "Close".

---

## Polish / Future

- [ ] **Sprite sheets** — idle, attack, hit, damaged, death per character and enemy. Waiting on art.
- [ ] **Run structure implementation** — map scene, room transitions, encounter selection
- [ ] **Encounter system** — which enemies appear together in a room, difficulty scaling per floor
- [ ] **Store system** — add/remove cards from deck mid-run, gear purchases
- [ ] **Event system** — random narrative events that modify deck, stats, or grant items
- [ ] **In-game compendium** — reads from EnemyData and PlayerData resources, unlock gated by save state
- [ ] **Full gamepad support** — hand navigation works; still need confirm/cancel for card play and full menu navigation
- [ ] **Additional characters** — expand CHARACTER_RESOURCE_PATHS in character_select.gd to add new entries
