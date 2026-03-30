# Creating a Card

Cards are data-driven. Each card is a `CardData` resource saved as a `.tres` file in
`cards/data/`. The `card.tscn` scene is a reusable visual template that reads from
whichever `CardData` resource is assigned to it.

---

## Step 1 — Create a new CardData resource

In the Godot FileSystem panel, right-click the `cards/data/` folder and choose
**New Resource**. Search for `CardData` and confirm. Save the file with a descriptive
name matching the card, e.g. `fireball.tres`.

Alternatively, duplicate an existing `.tres` file in `cards/data/` and rename it.

---

## Step 2 — Fill in the card properties

Select the new `.tres` file. The Inspector will show two groups:

#### Card Data
| Property | Type | Description |
|---|---|---|
| `card_name` | String | Display name shown on the name banner |
| `card_cost` | int | Energy cost shown in the cost badge |
| `card_type` | CardType | Dropdown — controls the type label (Attack, Skill, etc.) |
| `card_description` | String (multiline) | Description text — supports BBCode and `{N}` value tokens (see [BBCode Reference](#bbcode-reference)) |
| `effects` | Array[CardEffect] | The effects this card applies when played — see [Step 3](#step-3--add-effects) |
| `is_token` | bool | If true, this card is a token — created at runtime, removed from the deck at end of combat |

#### Rarity
| Property | Type | Description |
|---|---|---|
| `base_rarity` | Rarity | The card's starting rarity tier |
| `upgraded` | bool | If true, effective rarity = base_rarity + 1 (capped at Special) |

---

## Step 3 — Add effects

With the `.tres` file selected, click the `effects` array in the Inspector and add one
`CardEffect` resource per thing the card does. Each `CardEffect` has:

| Property | Type | Description |
|---|---|---|
| `effect_type` | EffectType | What the effect does — see [Effect Types](#effect-types) |
| `value` | int | Base value (e.g. damage amount, block amount, cards drawn) |
| `upgraded_value` | int | Value when the card is upgraded — set to `-1` to keep the same as base |
| `target` | Target | Who the effect applies to: `Self`, `Enemy`, or `All Enemies` |
| `param` | String | For `Apply Status`: the status id (e.g. `"void"`, `"burn"`). For `Stat Up`: the stat name (e.g. `"strength"`) |
| `token_data` | CardData | For `Generate Token` only: the card resource to instantiate |
| `token_destination` | TokenDestination | For `Generate Token` only: `Hand`, `Draw Pile`, or `Discard Pile` |

---

## Step 4 — Write the description

The `card_description` field is where you write the text that appears on the card.
It has two features layered on top of plain text: **formatting tags** and **value placeholders**.

### Formatting tags (BBCode)

To style text on the card you wrap it in opening and closing tags — similar to HTML if
you've seen that before. The tag name goes in square brackets.

| What you type | What the player sees |
|---|---|
| `Deal 6 damage.` | Deal 6 damage. *(plain text, no formatting)* |
| `Deal [b]6[/b] damage.` | Deal **6** damage. *(the number is bold)* |
| `[i]Exhaust.[/i]` | *Exhaust.* *(italic)* |
| `[color=#00e5c8]Void[/color]` | Void *(teal-colored text)* |

The closing tag always has a `/` before the name. You can combine tags:
`[color=#00e5c8][b]2 Void[/b][/color]` gives bold teal text.

See the [BBCode Reference](#bbcode-reference) for a full tag list and the color values
used for each status effect.

### Value placeholders

If your card deals damage, gains block, or has any numeric effect you set up in Step 3,
you should **not** type that number directly into the description. Instead, use a
placeholder: `{0}` for the first effect, `{1}` for the second, and so on.

When the card is displayed, the placeholder is replaced automatically with the correct
value — including the upgraded value if the card has been upgraded. This means you only
ever need one description regardless of whether the card is upgraded.

The position number matches the order of effects in your effects array:

| Placeholder | Pulls from |
|---|---|
| `{0}` | The **first** effect in the array (index 0) |
| `{1}` | The **second** effect in the array (index 1) |
| `{2}` | The **third** effect in the array (index 2) |

### Worked example — Strike

Step 3 produced one effect: Damage, value `6`, upgraded_value `9`, target Enemy.
That effect is at position 0 in the array.

The description should be:

```
Deal [b]{0}[/b] damage.
```

When displayed (not upgraded): **Deal 6 damage.**
When displayed (upgraded): **Deal 9 damage.**

If you had typed `Deal [b]6[/b] damage.` instead, upgrading the card would still show 6.

### Worked example — Void Strike

Step 3 produced two effects:
- Position 0: Damage, value `8`, upgraded_value `12`, target Enemy
- Position 1: Apply Status, value `1`, upgraded_value `2`, param `"void"`, target Enemy

The description should be:

```
Deal [b]{0}[/b] damage.
Apply [color=#00e5c8][b]{1} Void[/b][/color].
```

When displayed (not upgraded): **Deal 8 damage. Apply 1 Void.**
When displayed (upgraded): **Deal 12 damage. Apply 2 Void.**

> **Important:** The placeholder numbers must match the order of effects in the array.
> If you reorder effects in the Inspector the wrong values will show in the description.

---

## Step 5 — Preview the card

Instance `cards/card.tscn` into any scene. Select it and drag your new `.tres` file
into the `Data` property in the Inspector. The card updates immediately.

To preview it in isolation, assign the resource to the Card node in `main.tscn`.

---

## Effect Types

Defined in `CardEffect.EffectType`. Used in the `effect_type` field of a `CardEffect` resource.

| Type | Description | Relevant fields |
|---|---|---|
| `Damage` | Deal X damage to the target | `value`, `upgraded_value`, `target` |
| `Block` | Gain X block | `value`, `upgraded_value` |
| `Draw` | Draw X cards | `value`, `upgraded_value` |
| `Heal` | Restore X HP | `value`, `upgraded_value` |
| `Apply Status` | Apply X stacks of a status to the target | `value`, `upgraded_value`, `target`, `param` (status id) |
| `Stat Up` | Increase a stat by X for the rest of combat | `value`, `upgraded_value`, `param` (stat name) |
| `Generate Token` | Add a copy of a card to the chosen destination | `token_data`, `token_destination` |

---

## Creating a Token Card

A token card is a temporary card that gets added to the player's hand, draw pile, or
discard pile during combat as the result of playing another card. Tokens are not part of
the starting deck — they only exist for that combat and are removed at the end.

Setting up tokens involves two `.tres` files: the **token card** itself, and the
**generating card** that creates it.

---

### Step 1 — Create the token's CardData

Create a new `.tres` file in `cards/data/` following Steps 1–4 above. The main
differences from a regular card:

- Enable `is_token` — this marks it as a temporary card so the game knows to remove it
  at end of combat
- Set `card_cost` to `0` unless the token is meant to cost energy
- Keep it focused — tokens typically do one thing

**Example — Void Shard token:**

| Field | Value |
|---|---|
| `card_name` | `Void Shard` |
| `card_cost` | `0` |
| `card_type` | `Attack` |
| `is_token` | `true` |
| `effects[0]` | Damage, value `3`, upgraded_value `-1`, target Enemy |
| `card_description` | `Deal [b]{0}[/b] damage. [i]Exhaust.[/i]` |

The description above displays as: **Deal 3 damage.** *Exhaust.*

---

### Step 2 — Set up the generating card

Open the card that will create the token. In its effects array, add a `Generate Token`
effect and fill in:

- `token_data` — drag in the token's `.tres` file (e.g. `void_shard.tres`)
- `token_destination` — where the token goes: `Hand`, `Draw Pile`, or `Discard Pile`

The `value` and `upgraded_value` fields are not used for `Generate Token` effects —
leave them at `0`.

**Example — Void Forge (the generating card):**

| Field | Value |
|---|---|
| `card_name` | `Void Forge` |
| `card_cost` | `1` |
| `card_type` | `Skill` |
| `effects[0]` | Generate Token, token_data `void_shard.tres`, token_destination `Hand` |

---

### Step 3 — Write the generating card's description

The generating card's description tells the player what will happen. The token name
should be bolded so it's clear a card is being added.

Important: the description is just text you write — it does **not** automatically pull
the token's name. You type it yourself.

```
Add a [b]Void Shard[/b] to your hand.
```

Displays as: Add a **Void Shard** to your hand.

If the card does something else in addition to creating the token, add those effects
to the array first so their values get the lower `{0}`, `{1}` placeholders, and put
the `Generate Token` effect last since it has no value placeholder.

**Example — a card that deals damage and creates a token:**

Effects array:
- `effects[0]`: Damage, value `5`
- `effects[1]`: Generate Token, token_data `void_shard.tres`, token_destination `Hand`

Description:
```
Deal [b]{0}[/b] damage.
Add a [b]Void Shard[/b] to your hand.
```

Displays as: **Deal 5 damage.** Add a **Void Shard** to your hand.

---

## BBCode Reference

Card descriptions support Godot's RichTextLabel BBCode syntax alongside `{N}` value tokens.

### Value tokens

`{N}` is replaced at display time with the resolved value of `effects[N]`, automatically
switching to the `upgraded_value` when the card is upgraded. Use these instead of
hardcoding numbers so upgraded cards show the correct values without a separate description.

| Token | Resolves to |
|---|---|
| `{0}` | `effects[0].resolved_value(upgraded)` |
| `{1}` | `effects[1].resolved_value(upgraded)` |
| `{N}` | `effects[N].resolved_value(upgraded)` |

### BBCode tags

| Tag | Example | Result |
|---|---|---|
| Bold | `[b]{0}[/b]` | Value in bold |
| Color | `[color=#00e5c8]{1} Void[/color]` | Teal-colored text |
| Italic | `[i]text[/i]` | *text* |

Example using both:
```
Deal [b]{0}[/b] damage.
Apply [color=#00e5c8]{1} Void[/color].
```

---

## Adding a New Card Type

Card types are defined in `cards/card_data.gd`. Both the enum and the display label
array in `cards/card.gd` must be updated together.

**Step 1 — Add the enum value**

Open `cards/card_data.gd` and append to the `CardType` enum:

```gdscript
enum CardType { ATTACK, SKILL, POWER, CURSE, STATUS, STANCE }
```

**Step 2 — Add the display label**

Open `cards/card.gd` and append to `CARD_TYPE_LABELS` in the **same position**:

```gdscript
const CARD_TYPE_LABELS: Array[String] = ["Attack", "Skill", "Power", "Curse", "Status", "Stance"]
```

> **Important:** The array index must match the enum value. `ATTACK = 0` maps to `"Attack"`
> at index 0, `SKILL = 1` maps to `"Skill"` at index 1, and so on. If the order gets out
> of sync, cards will display the wrong type label.

The new type will appear in the `card_type` dropdown on any `CardData` resource immediately.
