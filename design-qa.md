# UI Design QA

**Source visual truth paths**

- `C:\Users\cheng\AppData\Local\Temp\codex-clipboard-765401c7-dc74-40b9-b210-38bbbe631338.png`
- `C:\Users\cheng\AppData\Local\Temp\codex-clipboard-2e8d89c4-ece7-41ff-b302-d550dd2c0ef4.png`
- `C:\Users\cheng\AppData\Local\Temp\codex-clipboard-0d391343-abe3-4d87-9c3e-fb5dab3f4c60.png`

**Implementation screenshot path**

- Not captured. The user explicitly requested that Codex no longer open or inspect the running game screen.

**Viewport**

- Project viewport: 1280 x 720.
- Supplied defect captures use different window crops and therefore are not normalized post-change comparison evidence.

**State**

- Main menu.
- Single-player character selection.
- Two-player/network character selection was additionally checked through the scene tree and layout tests.
- Combat HUD compact state.

**Full-view comparison evidence**

- Blocked because no post-change implementation capture is available.

**Focused region comparison evidence**

- Source defect regions were opened for the main-menu controls and character-card body.
- Post-change visual comparison is blocked because runtime capture is intentionally disabled.

**Findings**

- [P1] Source controls left insufficient height around themed text. Code fix: main controls are now 64 px; other framed buttons are at least 60 px.
- [P1] Source character skill slots used text-only Q/E/F placeholders. Code fix: each slot now loads the character-specific Q/E/F texture and keeps a small key overlay.
- [P2] Source character cards sat too close to the heading region. Code fix: the single-player card row now has a dedicated 14 px top offset.
- [P2] Network character selection could exceed the vertical budget after increasing control sizes. Code fix: its compact card height and art region were reduced, and containment is covered by an automated layout assertion.
- [P1] Source character portraits used a centered cover crop that cut into the top of the head. The first fix preserved the whole image but made the subject too small. Current code fix: portraits keep an aspect-preserving cover scale, fill the card width, and anchor cropping to the top so the complete head remains visible while only the lower image is cropped.
- [P1] The old portrait assets were tall full-body compositions and remained unsuitable for the landscape card slot under multiple crop strategies. Current fix: four new landscape, waist-up character-selection artworks were generated and connected through separate versioned asset paths; all legacy assets remain available.
- [P1] The project-wide nearest-neighbor texture filter and disabled mipmaps made the new 1402 x 1122 portraits look coarse when reduced to card size. Current fix: character portraits override the pixel-art default with linear mipmapped filtering, and the four redraw imports generate mipmaps.
- [P1] The selected-state badge used 12 px dark text in a 70 x 28 area. Current fix: the badge is 90 x 36 with crisp 16 px near-black text and no inherited text shadow.
- [P2] The combat HUD occupied too much of the lower playfield. Current fix: the HUD width is reduced from 560 to 440, the decorative frame uses a compact slice, and health/action rows use smaller spacing and control heights while retaining readable labels.

**Required fidelity surfaces**

- Fonts and typography: framed-control height is validated against frame margins and font size; the selected badge uses a larger high-contrast label without shadow. Visual font fidelity remains unverified.
- Spacing and layout rhythm: panel/content containment and viewport bounds pass automated checks; visual rhythm remains unverified.
- Colors and visual tokens: existing Verdant theme tokens are unchanged; visual comparison remains unverified.
- Image quality and asset fidelity: new 1402 x 1122 character-specific landscape artworks and real skill icon textures are used. Portraits use linear mipmapped downsampling while pixel-art UI assets retain the global nearest filter. Legacy portrait files remain intact. Runtime comparison remains unverified.
- Copy and content: existing Chinese copy is preserved; skill keys remain visible as overlays on their icons.

**Comparison history**

- Iteration 1 source findings: cramped framed text, high card row, text-only skill slots.
- Iteration 2 source finding: centered portrait cover-cropping cut off the top of character heads.
- Iteration 3 source finding: whole-image fitting preserved heads but reduced the character image too much.
- Iteration 4 source finding: the original tall assets could not produce a strong landscape card composition through runtime cropping alone.
- Fixes made: enlarged framed controls, added card-row offset, integrated supplied character skill icon assets, generated four dedicated landscape card artworks under new filenames, preserved the legacy asset map, and added single/network containment tests.
- Post-fix visual evidence: unavailable by user instruction.

**Implementation checklist**

- [x] Increase framed control dimensions.
- [x] Keep text inside the safe frame budget through automated assertions.
- [x] Move the single-player card row downward.
- [x] Replace Q/E/F text-only slots with character-specific icons.
- [x] Fill the portrait frame while anchoring the crop to the top so the complete head remains visible.
- [x] Replace the active card-art map with four dedicated landscape redraws while retaining the full legacy map.
- [x] Verify single-player and network layouts remain inside the panel and viewport.
- [ ] Perform a normalized post-change visual comparison if runtime inspection is allowed later.

**Follow-up polish**

- Visual polish is intentionally deferred to the user's in-game review. No additional layout change should be inferred from this document without a new requirement or screenshot annotation.

final result: code implementation complete; normalized visual sign-off deferred by user instruction
