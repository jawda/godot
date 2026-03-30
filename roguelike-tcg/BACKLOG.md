# RoguelikeTCG — Backlog

---

## Needs Design Decisions

These items need more thought before implementation begins.

- [ ] **Player classes** — what classes exist, what differentiates them, class-specific starter decks and card pools
- [ ] **Card effects system** — how card effects (damage, block, status) are defined and executed. Options: data-driven Effect resource, scripted per-card, or a mix
- [ ] **Enemy system** — enemy data structure, AI intent (show what the enemy will do next turn), health/defense model
- [ ] **Combat turn loop** — full turn structure: player draws → plays cards → ends turn → enemy acts → repeat
- [ ] **Status effects** — Void, Burn, Bleed, etc. — data model and how they tick each turn
- [ ] **Energy system** — player has X energy per turn, cards cost energy to play, energy refills on new turn

---

## Ready to Build

Design is clear enough to start implementation.

- [ ] **Playing a card** — select a focused card and play it: consume energy, trigger effect, move to discard
- [ ] **Card play input** — mouse: click focused card to play; controller: confirm button to play selected card
- [ ] **Energy display UI** — show current / max energy each turn
- [ ] **Draw / discard pile counters UI** — show card counts for each pile during combat
- [ ] **End turn button** — triggers enemy action phase, refills energy, draws new hand
- [ ] **Battlefield scene** — `gui/battlefield.tscn` is currently empty; needs layout for player area, enemy area, hand, energy, and end turn button

---

## Polish / Future

- [ ] **Expand card pool** — add more cards beyond Strike and Defend; eventually class-specific cards
- [ ] **Store system** — the designed way for players to add or remove cards from their deck mid-run
- [ ] **Event system** — random events that can modify the deck or grant cards
- [ ] **Run structure** — map, room types (combat, rest, store, event), progression between rooms
- [ ] **Full gamepad support** — hand navigation is done; still need confirm/cancel for playing cards and navigating all menus
- [ ] **Art** — replace card art placeholders with real assets
