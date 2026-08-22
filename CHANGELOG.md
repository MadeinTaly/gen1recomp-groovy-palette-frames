# Changelog

## 0.8.0-beta.1 — moving palettes, HSV blending, and Gold steps aside for its own frame row

**Prerelease.** The Update button does not offer prereleases; the install path is
**Launcher → MODS → the mod's row → `Versions` → the entry marked `pre` → `Install`**.

- **The palettes stopped washing everything into one hue.** The old recolour in
  0.7.0 mapped every source colour's luminance onto the scheme's four-rung ramp
  and blended 55% toward it in straight RGB. Because `rampAt` (main.lua:374)
  answers with ONE colour per luminance, two sources of equal brightness — Gold's
  grass green and its roof red — were handed the SAME target and CONVERGED: the
  gap between them closed by 55% too. On Gold, whose eight background palette
  groups are the entire point of its colour, that collapsed the overworld to a
  monochrome wash.
  
  The fix moves the blend into HSV (main.lua:432-511) so the three things a scheme
  wants can be asked for separately: VALUE follows the ramp (non-negotiable —
  brightness order IS Game Boy shading), SATURATION moves toward the ramp's
  weighted by how grey the source already is, and HUE rotates toward the ramp by
  an amount that fades out as the source's own saturation rises. So hue DIFFERENCES
  survive.
  
  `FULL` deliberately keeps the old straight collapse — that setting's whole
  promise is "go all the way onto the ramp" — so `TINT` and `FULL` are now a
  real choice rather than two strengths of the same flattening.

- **RAINBOW moves, and ACID is new.** Both are functions of the clock rather than
  constants (main.lua:613). RAINBOW turns all four rungs together on one
  rigid wheel (~12s a turn), so the ramp keeps the hue spacing the table was
  written with and the whole picture rotates through the spectrum. ACID drifts
  each rung at its own incommensurable speed with saturation breathing underneath.

  Only hue and saturation move: every rung keeps the LUMINANCE its table entry
  gave it, because the four rungs are fed to the shade shader lightest-first and
  a ramp that stopped falling in brightness for even one frame would render the
  picture inside out. Holding HSV's *value* fixed would not have achieved that,
  and the distinction is the whole reason `atLuminance` (main.lua:581) exists:
  value is the largest channel, not a brightness the eye agrees with — a pure
  blue at value 1.0 carries a luminance of 18 and a yellow at value 0.8 carries
  200, so four rungs rotating at constant value cross over somewhere in the turn
  and the ramp inverts. Putting each hue back on the luminance its rung started
  with makes the ordering rule hold by construction; `tests/` walks a full turn
  of the wheel at 20ms and re-checks it anyway, along with both contrast floors.
  A new `MOTION` option freezes both at their written four colours (also the
  accessibility answer a continuously-cycling screen has to have). There is no
  per-frame mod event and none is needed: both are reached from inside functions the
  renderer already calls once a frame.
  
  Cost: a moving palette must never touch anything BAKED. On Gen 1 it therefore
  refuses the ADVANCED path (main.lua:663 — atlases cache under `darkKey`); on Gold
  `resolve` hands the frame back to DMG (main.lua:886) so the map canvas and OBJ
  bakes build once in grey under a cache key that never moves, and the colour
  arrives in `GbcPalette.presentColors` (main.lua:914) — the same whole-screen pass
  CLASSIC uses, which `src/core/Game2.lua:1384` rebuilds every frame. Nothing
  re-bakes; one shader uniform changes.

- **On Gold the frames stopped fighting Gold's own.** Gold ships eight frames and
  its own `OPTION → FRAME` row (src/ui/gen2/OptionsMenu.lua:81, ladder at
  :344-350). Pointing `Font.BORDER` at this mod's page won over that row silently,
  because `pageFor` only sends $79-$7e to the frame sheet (src/render/Font.lua
  :245-250) and this mod's codes are not among them — so the player had two frame
  settings, one of which quietly did nothing. Now on Gold the mod's own FRAME
  option steps aside (main.lua:1233-1287) and Gold's row runs 1..16 instead: its
  own eight, then these eight. Done by attaching `row.step`, which the menu checks
  before `row.frame` (OptionsMenu.lua:331-336); `game.options` is the same table the
  menu holds (Game2:showOptions passes `options = self.options` by reference) so the
  printed number follows. Uninstalling with 9..16 saved degrades to the cart's frame
  1, not to a missing border. Gen 1 is unchanged — it has no such row.

- **Gold's text boxes take the scheme.** On Gen 1 they always did, for free: the
  whole UI canvas goes through the shade-remap shader, so white paper comes out as
  rung 1 and the black border as rung 4. Gold's do not — `Chrome.box` calls
  `Font.drawBox` straight (src/ui/gen2/Chrome.lua:81-84), which fills a white
  rectangle and blits six black glyphs with no shader bound, so no palette can
  reach it. (`Chrome.printThrough` was already reached, because it resolves through
  `GbcPalette.resolve` — Chrome.lua:121-124.) `Font.drawBox` is now wrapped
  (main.lua:1356) to bind the scheme's palette via `useRaw` around the draw:
  shade 0 is the paper, shade 3 the border ink, which is the identical mapping Gen 1
  gets from its own shader arrived at from the other side. Moving palettes stay out
  — they are coloured by the present pass, and a box that is no longer four greys
  would confuse it.

## 0.7.0 — the palettes run on Gold too

0.6.0 shipped believing Gold's OPTION menu "carries no palette row at all".
That was true of the mechanism this mod already knew — Gen 1's PaletteFX,
an SGB-style whole-screen remap — but not of Gold's colour in general. Gold's
own OPTION screen carries a `COLOR` row (`src/ui/gen2/OptionsMenu.lua:152`)
that already switches between three modes of its own, `GBC` / `DMG` /
`CLASSIC`, through `src/render/GbcPalette.lua` — Gold's direct equivalent of
PaletteFX, and the one seam its own module comment says every colour in the
Gen 2 port arrives through. That is where this mod's thirty schemes plug in
now.

- **The palettes work on Gold.** The same thirty ids are appended to
  `GbcPalette.MODES` alongside `PaletteFX.MODES`, and `GbcPalette.resolve`
  is wrapped the same way `effectiveColors` is on Gen 1. `PALETTE` on the
  START menu, and `A` on `OPTION → COLOR`, open the same live preview screen
  Red/Blue/Yellow have always had — the screen now reads `game.save
  .generation` to decide which of the two engine modules to drive, and
  writes the save option under whichever key that generation actually uses
  (`colors` on Gen 1, `color` on Gen 2).

- **USE ADVANCED rides Gold's own colour, not a stand-in for it.** Gold never
  works from four bare shades — every call into `GbcPalette.resolve` already
  carries a real palette (one of eight background groups, one of eight
  overworld sprite groups, a Pokémon's or trainer's own shipped pair, an HP
  or EXP bar colour) — so `TINT`/`FULL` bend each of those toward the scheme
  along the same luminance curve the Gen 1 ADVANCED path uses, rather than
  flattening dozens of distinct palettes onto one shared four-rung ramp.
  `OFF` is that flat swap, matching what Gold's own `DMG` and `CLASSIC`
  modes already do.

- **What still does not move: the title screen and the boot cinema.** Both
  draw from pre-rendered art rather than through `GbcPalette.resolve` —
  `TitleState:gray()` already swaps to a grey image set for any COLOR mode
  but `GBC`, and a groovy scheme lands on that same branch DMG and CLASSIC
  do. The splash shows grey; the recolour picks up from the first menu or
  map onward. Named rather than patched around, because patching around it
  would mean either baking new art (which this mod's own rule against
  ROM-derived or hand-traced sprite art already forbids) or running the
  finished frame back through the whole-screen present-pass trick CLASSIC
  uses, which only works because CLASSIC forces every draw call onto the
  same four fixed shades first — exactly the flattening TINT/FULL exist to
  avoid everywhere else.

- **Three palettes tightened for contrast, not repainted.** The test suite
  now checks WCAG relative-luminance contrast (the web's own text-contrast
  formula) between every adjacent rung, not just brightness ordering, and
  requires 1.3 as a floor. AMIGA's grey, CGA's cyan and VAPOR's cyan rung
  each sat close enough to a neighbour to read as one colour once
  desaturated by the shade shader; all three moved a little, none changed
  identity, and every id still resolves to the same *kind* of colour a
  player who already picked it expects.

## 0.6.0 — the frames run on Gold

`"games": ["gen1", "gen2"]`. The mod is two halves and they answer Gold
differently, so they are split rather than shipped together and hoped for.

- **FRAME works on Gold.** Gold draws every text box and menu through
  `Chrome.box` -> `Font.drawBox`, which reads the same `Font.BORDER` codes
  this mod rewrites, and the `font` registry is at the shared path so the
  glyph sheet merges on both games. Gold's own FRAME row is a different knob
  -- it picks which of the cart's eight frame *pages* is current, while this
  picks which glyphs the border is built from -- so the two are orthogonal
  rather than fighting.

- **The palettes stay Gen 1.** Gold is a CGB game whose colour comes from its
  own palettes; `src/ui/gen2/OptionsMenu.lua:149` says exactly that, and its
  OPTION menu carries no palette row at all. Thirty extra rungs on a ladder
  that is not there would be thirty choices that change nothing, so on Gold
  the PALETTE entry on the START menu and the COLORS row takeover both stand
  down.

This also cuts the 0.5.0 release that never happened: the manifest had moved
to 0.5.0 while the newest tag was still v0.4.1, so the listing and the tag had
drifted apart. 0.6.0 puts them back together.

## 0.5.0

- **The preview is now where you actually choose a colour.** Press **A** on
  the game's own **OPTION → COLORS** row and the menu lifts off: the running
  game, the palette's name, nothing else. **Left/right** walks the list,
  **A** keeps, **B** puts back the one you arrived with.

  Choosing a colour from a menu that is covering the game is choosing it
  blind, and COLORS is exactly where a player goes to do it. The browser
  existed since 0.2.0 but only from `START → PALETTE`, which is not where
  anyone looks.

  An options row descriptor may carry `activate = fn(game)` — `OptionsMenu`
  calls it on A — and the rows run through the `ui.options.rows` hook before
  the menu is built. So this attaches one to the row the *engine* owns. The
  row still steps with left/right exactly as it did; A simply does something
  now where it used to do nothing. A row another mod has already claimed is
  left alone.

- **Left and right** work in the browser, not just up and down. It is
  reached from a row that steps with left/right, so the gesture carries on
  meaning the same thing.

- **The browser shows the palette name and nothing else.** The
  `A:KEEP B:CANCEL` line cost a third of the box for something you need
  once, and every pixel of chrome is a pixel of the thing being previewed
  that you cannot see. The box that remains is sized to the word rather than
  the screen — it cannot go entirely, because a glyph is one shade over a
  world drawn in four, and bare text would be unreadable over a busy map in
  exactly the palettes worth looking at.

- `START MENU` is now labelled **`PREVIEW`**, since it governs both ways in.
  Off removes the START row, the COLORS `activate`, and the screen; the
  palettes stay. Your stored setting carries over — the key is unchanged.

## 0.4.1

- **Fixed: `FRAME` needed a restart.** Choosing a border did nothing until
  the next launch.

  `Font.drawBox` does read `Font.BORDER` fresh on every call, so the change
  is instant the moment something writes it — and nothing did. 0.4.0 applied
  the frame at load and on `game.ready` and nowhere else. It now also
  listens for `mod.options_changed`, which `ManagerState:setOption` emits
  right after storing a value, so the border redraws the very menu you are
  choosing it in.

  The test drives the loader's own event bus rather than calling the apply
  function directly — calling it directly would have passed in 0.4.0 too.

- The README now says which rows take effect at once and which wait for the
  next launch, and the suite asserts it: `FRAME` and `USE ADVANCED` are
  live, `PACKS` and `START MENU` are read once at load because one builds
  the COLORS list and the other registers a screen.

- Releases are titled with the mod's **name** rather than its id, so this
  one reads *Groovy Palette & Frames 0.4.1*. The asset stays
  `groovy_palette-<version>.zip`: the launcher's updater looks for that
  exact name, so it follows the id through any rebrand.

## 0.4.0

Now **Groovy Palette & Frames**. The mod id stays `groovy_palette`, so the
launcher keeps updating your existing install and no saved palette moves.

- **`FRAME`** — eight new borders for every text box and menu, plus
  `GAME BOY` for the engine's own: THIN, DOUBLE, TRIPLE, THICK, WIDE, DASH,
  BEADS, TRACK.

  A border is not a texture, it is **six font glyphs** — `tl h tr v bl br` —
  and `Font.drawBox` reads that table fresh every call. So this registers
  its own glyph page and repoints six entries. The choice is written to both
  `Font.BORDER` (what the next box reads, so it changes immediately) and
  `data.font.border` (what a font reload rebuilds from, so it survives one).

  Every pixel of the sheet is generated by `tools/make_frames.py` from rules
  written out in that file. No ROM, no cartridge dump, and not a pixel of
  the engine's own font sheets — `modkit lint` still reports
  `no ROM-derived content`.

  **The constraint that shaped them.** `h` is drawn along the top *and* the
  bottom, `v` along the left *and* the right — one glyph per axis, not per
  side. So a rail's position is a single number shared by two opposite
  edges, and a corner one pixel off produces a visible step. That rules out
  rounded corners outright: the arc has to bulge outward, which on the right
  edge means the vertical sits further right and on the left further left,
  and one glyph cannot do both. A rippling rail fails the same way. Both
  were drawn, both stepped, both were cut. The eight that shipped are built
  from the rule rather than drawn freehand, and the generator refuses to
  write the sheet if any rail steps.

## 0.3.0

- **`USE ADVANCED`** (TINT) — the palettes now ride the engine's **ADVANCED**
  colorization instead of replacing it.

  ADVANCED is not a four-shade mode: it is the pokered-gbc pack, which
  resolves a real colour *per tile* and keeps **eight background palettes
  live at once**. Picking RAINBOW used to switch that off and hand you four
  shades — measurably a downgrade.

  A four-rung ramp can be read as a *curve* rather than four steps: take
  each colour's luminance, find that height on the ramp, interpolate
  between the two rungs it falls between. Counted on the real pack, on a
  house interior:

  | | on screen | across the game |
  | --- | --- | --- |
  | ADVANCED | 18 | 47 |
  | RAINBOW, before | 4 | 4 |
  | **RAINBOW, riding ADVANCED** | **18** | **47** |

  Nothing is collapsed — the counts match ADVANCED's exactly. And the
  source's own hue distinctions survive: a green tile still reads greener
  than a red one, both pulled into the palette's family.

  | | |
  | --- | --- |
  | `TINT` | keep ADVANCED's colour, pull it toward the palette (default) |
  | `FULL` | all the way onto the ramp, but along the curve |
  | `OFF` | what 0.2.0 did — four shades, ADVANCED replaced |

  Installs without the pokered-gbc pack fall back to `OFF` on their own.

## 0.2.0

- **A live palette browser on the START menu.** `START → PALETTE` scrolls
  the whole list with the game still on screen behind it: the screen
  declares `isOpaque = false`, and colorisation runs at composite time on
  the finished frame, so moving the cursor recolours *the actual game*
  rather than a swatch. **A** keeps what you are looking at, **B** puts back
  the palette you came in with.

  Thirty extra rungs on an options row you cycle one press at a time is a
  bad way to choose a colour, and choosing it from a menu that is covering
  the game is choosing it blind. This is the answer to both.

- **`START MENU`** (on) turns it off again: no menu row, no screen, and the
  palettes exactly as in 0.1.0. The switch is the browser, not the mod.

## 0.1.0

- First release. Thirty palettes appended to the engine's COLORS row, with
  `PACKS` to narrow them to the twelve hardware ones (`RETRO`) or the
  eighteen invented ones (`COLOUR`).
- Every palette is verified by luminance in the test suite rather than by
  eye. That check caught two on the way in: **AMIGA**, whose authentic
  Workbench order puts the orange above the blue and reads inside out, and
  **VBOY**, where a ramp of saturated reds collapses because red carries so
  little luminance.
