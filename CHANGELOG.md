# Changelog

## 0.1.0

- First release. Thirty palettes appended to the engine's COLORS row, with
  `PACKS` to narrow them to the twelve hardware ones (`RETRO`) or the
  eighteen invented ones (`COLOUR`).
- Every palette is verified by luminance in the test suite rather than by
  eye. That check caught two on the way in: **AMIGA**, whose authentic
  Workbench order puts the orange above the blue and reads inside out, and
  **VBOY**, where a ramp of saturated reds collapses because red carries so
  little luminance.
