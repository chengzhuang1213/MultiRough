# Character Asset Pipeline

1. Approve one high-resolution concept image with a readable weapon silhouette.
2. Create one 192×192 pixel master. Its feet end at y=138 and its body scale becomes immutable.
3. Generate Idle, Run, Attack 1, Attack 2, Cast, Hit, Death, Dash, and Defend from both references.
4. Remove the chroma key without resizing individual frames independently.
5. Keep the body and declared equipment components; remove only small unapproved fragments.
6. Apply one scale per character, align the lower-body anchor, and keep the y=138 foot baseline.
7. Run `python tools/validate_character_sprites.py` before importing or committing assets.
8. Run the Godot headless logic, lifecycle, and character-combat checks.

## Animation contract

- Cell size: 192×192, horizontal sheets.
- Frames: Idle 6, Run 6, Attack 1/2 6, Cast 6, Hit 3, Death 6, Dash 4, Defend 4.
- Priority: Death > Hit > Cast/Attack > Dash/Defend > Run > Idle.
- Death is non-looping and holds its final frame.
- Gameplay effects use an explicit event frame; they are not inferred from the full animation duration.
- Weapons may be separate connected components. Components of 8 pixels or fewer are rejected as noise; components up to 200 pixels are rejected only when their true pixel gap from the body is at least 12 pixels. Large equipment is preserved for manual review.
