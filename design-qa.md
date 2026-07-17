**Comparison Target**

- Selected direction: Campaign Satchel parchment, blue cloth, leather, and iron UI.
- Player-provided implementation evidence: four 1280×720-area captures covering the preparation HUD, card tooltip, combat HUD, and character selection.
- Post-fix implementation screenshot: unavailable because this task does not authorize launching the game.

**Observed Pre-fix Findings**

- P1: the preparation top bar exceeded its practical inner width, so headings, icons, and the ready control appeared forced into the frame.
- P1: tooltip copy entered the thick decorative top and bottom bands.
- P1: the short combat HUD used a square large-panel frame and repeated “就绪” over action icons.
- P1: character-card title, role, portrait, stats, and skills used the full nominal width without accounting for the visible leather border.

**Implemented Corrections**

- Added dedicated horizontal StyleBoxes for the preparation bar and combat HUD, plus a dedicated character-card StyleBox.
- Reduced preparation-section widths, framed each information icon in its own 54×54 slot, and retained the requested left-to-right information order.
- Increased tooltip safe content margins to 40 pixels horizontally and 36 pixels vertically.
- Removed redundant ready copy from combat icons while preserving cooldown and dash-charge information.
- Reduced character-card safe content width to 212 pixels and rebalanced title, portrait, stat, and skill-slot dimensions.
- Extended UI regression tests to cover these frame choices, padding limits, icon containment, and ready-label cleanup.
- Made Godot's automatic `TooltipPanel` host transparent so the custom colored tooltip is the only rendered decorative frame.
- Moved tooltip copy fully into the dark-blue reading area, switched parchment drawer copy to dark brown, and added outside-click dismissal for the detailed-stats drawer.
- Moved the active-wave countdown from the top-left status block to a centered top label that displays only the remaining integer.

**Verification**

- `ui_theme_checks.gd`: passed.
- `logic_checks.gd`: passed.
- `character_combat_checks.gd`: passed.
- `enemy_behavior_checks.gd`: passed.
- `run_lifecycle_checks.gd`: passed.
- Structural verification is complete; post-fix visual comparison remains blocked until the player supplies a new rendered capture or explicitly authorizes launching the game.

final result: blocked
