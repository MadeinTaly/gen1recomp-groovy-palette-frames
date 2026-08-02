#!/usr/bin/env python3
"""Draw assets/frames.png, the mod's own border glyph page.

Every pixel here is authored in this file. Nothing is extracted from a ROM,
a cartridge dump or the engine's own font sheets -- the sheet is generated
from the rules below, which are the whole source.

Format, matched to assets/generated/fonts/font_extra.png: RGBA, two values
only -- opaque black (0,0,0,255) for ink and fully transparent elsewhere.
Font.drawBox fills the box white first and draws these over it.

Layout: six glyphs per row, one FRAME per row, in the order Font.BORDER
names them: tl h tr v bl br. So the code for frame k, slot s, is
    base + k * 6 + s
with base 0x200 and glyphsPerRow 6.


THE CONSTRAINT, WHICH IS SHARPER THAN IT LOOKS
----------------------------------------------
Font.drawBox draws `h` along the top AND the bottom edge, and `v` along the
left AND the right. There is no per-side glyph. So a rail's position is a
single number shared by two opposite edges, and a corner that puts its rail
one pixel off from `v` produces a visible step where the corner tile hands
over to the edge.

That rules out whole categories of design, not just sloppy ones. A rounded
corner needs the arc to bulge OUTWARD, which on the right edge means the
vertical must sit further right than where the horizontal ends -- and on
the left, further left. One glyph cannot do both. The same goes for a
rippling rail: its row varies along the edge, so the corner cannot meet it
at a fixed height. Both were drafted here and both were cut.

What survives is: rails on a fixed set of rows/columns, symmetric about the
tile's centre, with decoration applied ALONG a rail rather than across it.
So the frames below are built from that rule rather than drawn freehand,
and check_frames() proves it before the sheet is written.
"""

import pathlib

INK = "#"


def build(hrows, vcols, hmask=None, vmask=None):
    """Six glyphs from a rail definition.

    hrows  rows the horizontal rails sit on
    vcols  columns the vertical rails sit on
    hmask  f(i) -> draw this pixel of a horizontal rail? (i = column)
    vmask  f(i) -> draw this pixel of a vertical rail?   (i = row)

    Corners are always solid: a dashed rail that also dashes its corner
    stops reading as a closed box.
    """
    hrows, vcols = sorted(hrows), sorted(vcols)
    lo_r, hi_r = hrows[0], hrows[-1]
    lo_c, hi_c = vcols[0], vcols[-1]

    def blank():
        return [[" "] * 8 for _ in range(8)]

    def horizontal(g, c0, c1, mask):
        for r in hrows:
            for c in range(c0, c1 + 1):
                if mask is None or mask(c):
                    g[r][c] = INK

    def vertical(g, r0, r1, mask):
        for c in vcols:
            for r in range(r0, r1 + 1):
                if mask is None or mask(r):
                    g[r][c] = INK

    # h / v: the plain rails, decorated
    h = blank(); horizontal(h, 0, 7, hmask)
    v = blank(); vertical(v, 0, 7, vmask)

    # corners: the horizontal runs from the vertical rail outward, the
    # vertical from the horizontal rail inward, both solid
    tl = blank(); horizontal(tl, lo_c, 7, None); vertical(tl, lo_r, 7, None)
    tr = blank(); horizontal(tr, 0, hi_c, None); vertical(tr, lo_r, 7, None)
    bl = blank(); horizontal(bl, lo_c, 7, None); vertical(bl, 0, hi_r, None)
    br = blank(); horizontal(br, 0, hi_c, None); vertical(br, 0, hi_r, None)

    return [["".join(row) for row in g] for g in (tl, h, tr, v, bl, br)]


def every(n, keep):
    return lambda i: (i % n) in keep


FRAMES = [
    # the plainest thing that is not the Game Boy's own
    ("THIN",   build({3}, {3})),
    # the classic dialogue-box look
    ("DOUBLE", build({2, 5}, {2, 5})),
    # three rails; 1/3/5 stays symmetric about the centre
    ("TRIPLE", build({1, 3, 5}, {1, 3, 5})),
    # heaviest here
    ("THICK",  build({3, 4}, {3, 4})),
    # rails pushed to the tile edges, so the box reads wider than it is
    ("WIDE",   build({0, 7}, {0, 7})),
    # broken line. Period 4, because 8 does not divide by 3 and a period-3
    # rhythm puts two marks side by side wherever one tile meets the next.
    ("DASH",   build({3}, {3}, every(4, {0, 1}), every(4, {0, 1}))),
    # single dots on the same period-4 lattice
    ("BEADS",  build({3}, {3}, every(4, {1}), every(4, {1}))),
    # a solid outer rail with a dotted one inside it
    ("TRACK",  build({2, 5}, {2, 5}, every(2, {0}), every(2, {0}))),
]


def check_frames():
    """Prove every frame's corners meet its edges.

    Assembles a box and walks each rail. A rail may be BROKEN along its
    length -- that is what DASH and BEADS are -- but every pixel it does
    draw must fall on the rail's own rows/columns. A pixel outside that set
    is the step this whole file exists to avoid.
    """
    TW, TH = 6, 4
    problems = []
    for name, glyphs in FRAMES:
        tl, h, tr, v, bl, br = glyphs
        grid = [[" "] * (TW * 8) for _ in range(TH * 8)]

        def stamp(g, tx, ty):
            for y, line in enumerate(g):
                for x, ch in enumerate(line):
                    if ch == INK:
                        grid[ty * 8 + y][tx * 8 + x] = INK

        stamp(tl, 0, 0); stamp(tr, TW - 1, 0)
        stamp(bl, 0, TH - 1); stamp(br, TW - 1, TH - 1)
        for i in range(1, TW - 1):
            stamp(h, i, 0); stamp(h, i, TH - 1)
        for j in range(1, TH - 1):
            stamp(v, 0, j); stamp(v, TW - 1, j)

        # the rail sets, taken from the plain edge glyphs
        vcols = {x for line in v for x, ch in enumerate(line) if ch == INK}
        hrows = {y for y, line in enumerate(h) for ch in line if ch == INK}

        for label, x0 in (("left", 0), ("right", (TW - 1) * 8)):
            for y in range(TH * 8):
                for x in range(x0, x0 + 8):
                    if grid[y][x] == INK and (x - x0) not in vcols:
                        # the corner tiles also carry the horizontal rail,
                        # which legitimately reaches outside vcols
                        if (y % 8) in hrows and (y < 8 or y >= (TH - 1) * 8):
                            continue
                        problems.append(
                            f"{name}: {label} rail steps to column {x - x0} at row {y}")
                        break

        for label, y0 in (("top", 0), ("bottom", (TH - 1) * 8)):
            for x in range(TW * 8):
                for y in range(y0, y0 + 8):
                    if grid[y][x] == INK and (y - y0) not in hrows:
                        if (x % 8) in vcols and (x < 8 or x >= (TW - 1) * 8):
                            continue
                        problems.append(
                            f"{name}: {label} rail steps to row {y - y0} at column {x}")
                        break

    return problems


def main():
    from PIL import Image

    problems = check_frames()
    if problems:
        for p in problems:
            print("FAIL " + p)
        raise SystemExit(f"{len(problems)} rail(s) step; sheet not written")

    per_row = 6
    width, height = per_row * 8, len(FRAMES) * 8
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    px = img.load()
    for row, (name, glyphs) in enumerate(FRAMES):
        for col, art in enumerate(glyphs):
            for y, line in enumerate(art):
                for x, ch in enumerate(line):
                    if ch == INK:
                        px[col * 8 + x, row * 8 + y] = (0, 0, 0, 255)

    out = pathlib.Path(__file__).resolve().parent.parent / "assets" / "frames.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"wrote {out} ({width}x{height}, {len(FRAMES)} frames, every rail continuous)")
    for i, (name, _) in enumerate(FRAMES):
        print(f"  0x{0x200 + i * 6:03X}  {name}")


if __name__ == "__main__":
    main()
