# Art Specification

A single reference for all pixel art dimensions, conventions, and standards used in this project.
All art should be created to these specifications before being imported into Godot.

---

## Pixel Art Sizes

| Asset Type | Dimensions | Notes |
|---|---|---|
| Base tileset tile | 16x16px | All terrain, floors, walls, roofs |
| Small items / objects | 16x16px | Pickups, props, environmental details |
| Character sprite frame | 16x32px | All NPCs, player, enemies |
| Character portrait | 64x64px | Dialogue UI, level-up screen |
| Large environmental objects | 16x32px or 32x32px | Doors, large furniture, trees |
| UI icons | 16x16px | Inventory slots, stat icons, map markers |

---

## Sprite Sheets

### Character Sprite Sheet Layout
- **Frame size:** 16x32px
- **Standard sheet:** 4 frames wide × 4 rows tall = 64x128px
- **Extended sheet (stealth row):** 4 frames wide × 5 rows tall = 64x160px (Nessa only)

| Row | Direction |
|---|---|
| 0 | Walk Down (toward camera) |
| 1 | Walk Left |
| 2 | Walk Right |
| 3 | Walk Up (away from camera) |
| 4 | Stealth / Crouch (extended sheet only) |

Walk cycle: 4 frames per direction. Frame 0 and 2 are neutral/mid poses. Frames 1 and 3 are left and right step extremes.

### Enemy Sprite Sheet Layout
Same convention as characters unless the enemy is non-humanoid, in which case define per enemy.
Non-humanoid enemies (e.g. Cave Grippers, Barrow Stags) use 16x16px or 32x32px frames depending on size.

---

## Tileset Conventions

- All tiles are **16x16px**
- Tilesets should be laid out on a single PNG sheet in rows and columns
- Recommended sheet width: 16 tiles (256px) for easy navigation in Godot's TileMap editor
- Each environment (Duskholm streets, Duskholm interiors, Mirewald Tier 1/2/3, Cave) gets its own tileset sheet

### Planned Tilesets

| Tileset | File | Status |
|---|---|---|
| Duskholm exterior | `tileset_duskholm.png` | Not started |
| Duskholm interiors | `tileset_interior.png` | Not started |
| Mirewald Tier 1 | `tileset_mirewald_t1.png` | Not started |
| Mirewald Tier 2 | `tileset_mirewald_t2.png` | Not started |
| Mirewald Tier 3 | `tileset_mirewald_t3.png` | Not started |
| Saltmere Vein | `tileset_cave.png` | Not started |
| UI / HUD elements | `tileset_ui.png` | Not started |

---

## Colour Palette — Blood & Parchment

All art should draw from this palette for visual consistency.
Full swatch reference available in `color_palette.html`.

| Name | Hex | Primary Use |
|---|---|---|
| Void | `#0D0B0A` | Scene backgrounds, deep shadow |
| Crypt Stone | `#1C1714` | UI panels, dark walls |
| Worn Stone | `#2A211C` | Hover states, mid-tone terrain |
| Aged Parchment | `#E8D5B0` | Primary text, light surfaces |
| Faded Ink | `#9A8878` | Secondary text, muted details |
| Dried Blood | `#8B1A1A` | Health, danger, corruption |
| Tarnished Gold | `#C4922A` | Buttons, interactive elements, the Hollow Sun |
| Nightshade | `#4A1A5C` | Magic, faith, arcane |
| Moonstone | `#B8C5D6` | Cold, ethereal, ice |
| Pale Gold | `#D4AF5A` | Stat increased, highlights |
| Coagulated | `#8B3030` | Stat decreased, damage |
| Grave Moss | `#4A6248` | Healing, nature, cave growth |

### Additional Colours (character-specific)

| Character | Skin Base | Notes |
|---|---|---|
| Corren | `#7A4A2A` | Deep warm brown |
| Cael | `#C4956A` | Medium warm tone |
| Nessa | `#B8956A` | Cool medium tone |
| Rowan | `#B87848` | Medium warm, weathered |
| Serafin | `#C9A882` | Warm parchment |
| Strell | TBD | |

---

## Portrait Conventions

- **Size:** 64x64px
- **Crop:** Head and shoulders, chest visible
- **Background:** Solid dark (`#0D0B0A` or `#1C1714`) or minimal environmental suggestion
- **Lighting:** Single warm light source from the left (candle/firelight) consistent across all portraits
- **Border:** Optional 1px gold (`#C4922A`) border for UI framing — applied in-engine, not in the source file

---

## Import Settings (Godot)

For all pixel art assets, use these import settings to prevent blurring:

- **Filter:** Nearest (not Linear)
- **Mipmaps:** Off
- **Compression:** Lossless
- **SVG Scale:** As needed per asset

For sprite sheets, configure in the SpriteFrames editor or AnimatedSprite2D:
- Set region to match frame size (16x32 for characters)
- Animation speed: 8 FPS default for walk cycles

---

## File Naming Conventions

| Asset Type | Pattern | Example |
|---|---|---|
| Character portrait | `[name]_portrait.png` | `corren_portrait.png` |
| Character sprite sheet | `[name]_sprite.png` | `corren_sprite.png` |
| Enemy sprite sheet | `[enemy]_sprite.png` | `hollow_wolf_sprite.png` |
| Tileset | `tileset_[location].png` | `tileset_duskholm.png` |
| Icon | `icon_[name].svg` or `.png` | `icon_sword.svg` |
| UI element | `ui_[name].png` | `ui_healthbar.png` |

---

## Asset Locations (Godot project)

| Asset Type | Path |
|---|---|
| Character portraits | `res://characters/portraits/` |
| Character sprites | `res://characters/sprites/` |
| Enemy sprites | `res://assets/enemies/` |
| Tilesets | `res://assets/tilesets/` |
| Icons | `res://assets/icons/` |
| UI elements | `res://assets/ui/` |
