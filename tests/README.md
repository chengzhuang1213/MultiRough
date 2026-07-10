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

The checks cover character configuration, upgrade application and uniqueness,
wave progression through the boss, single/duo scaling, revival, wave-clear
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
accounting, and lifesteal accounting.
