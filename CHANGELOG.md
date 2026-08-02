# Changelog

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
