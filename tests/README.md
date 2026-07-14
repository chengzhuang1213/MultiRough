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
godot --headless --path . --script res://tests/logic_checks.gd
```

The checks cover character configuration, the 27 general upgrade cards,
same-rarity three-card rolls, random rarity rates, the final-round epic
guarantee, skipped-card offer weights, upgrade application and uniqueness, ten
upgrade waves followed by the boss, single/duo scaling, revival, wave-clear
healing, cooldown pausing, and the future host-authority snapshot contract.

Run the main-scene lifecycle integration checks:

```powershell
godot --headless --path . --script res://tests/run_lifecycle_checks.gd
```

This suite loads the real main scene and verifies a complete single-player run,
every upgrade transition, boss victory, player defeat, and cleanup after two
separate restarts. It also verifies player-to-HUD binding, player attack signal
routing, and persistent skill-area registration and cleanup after the managers
are split out of the main scene script.

Run the character combat regression checks:

```powershell
godot --headless --path . --script res://tests/character_combat_checks.gd
```

These checks cover the existing warrior, archer, and lancer combat modules:
basic attack shape, Q/E behavior, F activation, module registration, damage
accounting, lifesteal accounting, and all four shared-cooldown right-click
secondary actions.

Run the enemy roster and behavior checks:

```powershell
godot --headless --path . --script res://tests/enemy_behavior_checks.gd
```

These checks cover the ten-wave enemy composition, all seven non-boss enemy
types, shield directional reduction, charger windup, bomber self-destruction,
the grand-elite priest's area healing, and the boss reinforcement, enrage,
cataclysm, and repeated-stun-resistance phases.

Run the non-visual balance bot simulation:

```powershell
godot --headless --path . --script res://tools/balance_simulation.gd -- --runs=2 --speed=12
```

The bot drives the real main scene and enemy AI, chooses upgrades, and writes
per-character and per-wave results to `tests/balance_report.json`. The report is
for numeric screening; it does not replace human testing of feel or readability.
