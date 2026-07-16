# Logic checks

Validate all original character sprite sheets before running Godot:

```powershell
python tools/validate_character_sprites.py
```

This rejects missing sheets, incorrect dimensions or frame counts, empty frames,
incorrect foot baselines, clipped horizontal bounds, and tiny isolated alpha
fragments. It also writes `tests/character_sprite_report.json` for inspection.

Run the non-visual logic checks from the project root:

```powershell
godot --headless --path . --script res://tests/ui_theme_checks.gd
```

The UI checks load the real main scene and verify Verdant theme resources,
framed-text safety, main-menu controls, single-player and network character-card
containment, active and legacy portrait paths, mipmapped portrait filtering,
class-specific Q/E/F icons, the selected badge, upgrade layout, result controls,
and the compact combat HUD dimensions. These checks validate code and layout
constraints; they do not replace in-game visual review.

Run the non-visual gameplay logic checks from the project root:

```powershell
godot --headless --path . --script res://tests/logic_checks.gd
```

The checks cover character configuration, the 27 general upgrade cards,
same-rarity three-card rolls, random rarity rates, the final-round epic
guarantee, skipped-card offer weights, upgrade application and uniqueness, ten
upgrade waves followed by the boss, single/duo scaling, revival, wave-clear
healing, cooldown pausing, and the versioned host-authority snapshot contract.

Run the main-scene lifecycle integration checks:

```powershell
godot --headless --path . --script res://tests/run_lifecycle_checks.gd
```

This suite loads the real main scene and verifies a complete single-player run,
every upgrade transition, boss victory, player defeat, and cleanup after two
separate restarts. It also verifies player-to-HUD binding, player attack signal
routing, persistent skill-area registration and cleanup after the managers are
split out of the main scene script, synchronized E-branch upgrades across host
and client instances, ordered authority-snapshot correction, stale snapshot
rejection, host-only enemy simulation, stable combat-entity IDs, projectile and
persistent-area creation/update/removal, hunter-mark ownership, warrior ultimate
state, synchronized enemy warning events, and network-run upgrade cleanup.

Run the character combat regression checks:

```powershell
godot --headless --path . --script res://tests/character_combat_checks.gd
```

These checks cover the existing warrior, archer, and lancer combat modules:
basic attack shape, Q/E behavior, F activation, module registration, damage
accounting, lifesteal accounting, and all four shared-cooldown right-click
secondary actions. Boss regression coverage also fixes the explicit critical-hit
context, true-AOE resistance, and the non-AOE classification of lancer Q and
chain lightning; warrior F projectile interception is checked directly.

Run the enemy roster and behavior checks:

```powershell
godot --headless --path . --script res://tests/enemy_behavior_checks.gd
```

These checks cover the ten-wave enemy composition, all seven non-boss enemy
types, shield directional reduction, charger windup, bomber self-destruction,
the grand-elite priest's area healing, wave-seven melee blood rage, heavy stomp,
ranged repositioning, and the boss reinforcement, enrage,
cataclysm, and repeated-stun-resistance phases.

Run the non-visual balance bot simulation:

```powershell
godot --headless --path . --script res://tools/balance_simulation.gd -- --runs=2 --speed=12
```

The bot drives the real main scene and enemy AI, chooses upgrades, and writes
per-character and per-wave results to `tests/balance_report.json`. The report is
for numeric screening; it does not replace human testing of feel or readability.
