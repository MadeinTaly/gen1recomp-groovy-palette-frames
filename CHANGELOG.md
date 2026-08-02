# Changelog

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
