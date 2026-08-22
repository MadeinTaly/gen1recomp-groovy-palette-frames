# gen1recomp-groovy-palette-frames

Thirty-one more entries on the **COLORS** row for
[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) — Amiga Workbench,
the C64 boot screen, a Virtual Boy, an amber terminal, and a pile of colour
ideas the Game Boy never had — and **eight new borders** for every text box
and menu.

They join the engine's own lists rather than replacing them: same OPTIONS
row, same hotkey, and the vanilla seven palettes keep their positions.

The mod id is still `groovy_palette`, so an existing install updates in
place and no saved palette moves.

## On Gold

The **frames** work on Pokémon Gold: it draws its boxes through the same
`Font.drawBox` this mod rewrites the border codes for. Gold also has a FRAME
option of its own, and until 0.8.0 this mod quietly overrode it — the two were
separate knobs and the mod's always won, so the cart's row looked broken. They
are one ladder now: Gold's row runs 1..16, its own eight and then these eight.

The **palettes** work on Gold too. Gold's colour really does come from its
own palettes -- that part was always true -- but Gold has a choke point of
its own that every one of those palettes passes through:
`src/render/GbcPalette.lua`, whose own comment says outright that "every
colour in the Gen 2 port arrives here". It already carries three modes
(`GBC`, `DMG`, `CLASSIC`) reached from Gold's own `OPTION → COLOR` row, and
this mod appends the same thirty-one ids there the same way it appends them to
Gen 1's `COLORS` row, then wraps `GbcPalette.resolve` the way it wraps
`PaletteFX.effectiveColors`. The `PALETTE` start-menu entry and the browser
work on Gold exactly as they do on Red/Blue/Yellow -- pressing A on `OPTION →
COLOR` lifts the same screen over the running game.

Because Gold never has *only* four shades to work with, `USE ADVANCED`
means something slightly different there: `TINT`/`FULL` bend Gold's own rich
per-context colours (eight background groups, eight overworld sprite
groups, every Pokémon and trainer's own pair, the HP and EXP bars) toward the
scheme along the same curve `riding ADVANCED` uses below, rather than
flattening them onto four shared rungs; `OFF` is that flat four-shade swap,
matching what Gold's own `DMG` and `CLASSIC` modes already do.

Text boxes and menus now take the scheme on Gold too. On Gen 1 they always did
for free — the whole UI canvas goes through the shade-remap shader — but Gold's
boxes draw with no shader bound, so they stayed white and black. The mod now
binds the palette around the box draw with the same call Gold uses for menu
text, so white becomes rung 1 and the border becomes rung 4. Moving palettes
(RAINBOW, ACID) stay out — they are coloured by the whole-screen pass, and a
box that is not four greys would confuse it.

The one place this still does not reach is the title screen and the Gold/Silver
boot cinema, which draw from **pre-rendered art** rather than through
`GbcPalette.resolve` -- `TitleState:gray()` swaps to a grey-only image set
for any COLOR mode but `GBC`, the same branch `DMG` and `CLASSIC` already
land on. A groovy scheme shows the plain grey splash and picks up the
recolour from the first menu or map onward.

## Install

Download `groovy_palette-<version>.zip` from [Releases](../../releases), then
**Launcher → MODS → Import mod .zip**. The launcher keeps it updated on its
own, and it can be installed from the **Find mods** tab without touching a
file.

## Use

**OPTION → COLORS, then press A.** The menu lifts off and you are looking at
the running game with the palette's name over it and nothing else.

| | |
| --- | --- |
| **← →** | walk the list (**↑ ↓** work too) |
| **A** | keep this one |
| **B** | put back the one you arrived with |

Choosing a colour from a menu that is covering the game is choosing it
blind. The row itself still steps with left/right without opening anything,
so nothing you already do has changed — A just does something now where it
used to do nothing.

**START → PALETTE** opens the same screen mid-game, and hotkey `2` still
cycles the list.

**START → MODS → Groovy Palette → OPTIONS..**

| Row | Values | Takes effect | Meaning |
| --- | --- | --- | --- |
| `FRAME` | `GAME BOY` + eight | at once | the border on every text box and menu — see below |
| `USE ADVANCED` | `TINT` / `FULL` / `OFF` | at once | ride the engine's per-tile colour instead of replacing it — see below |
| `MOTION` | on / off | at once | cycle RAINBOW's hue and ACID's drift through time; off freezes both at their table colours — the accessibility answer for continuous animation |
| `PREVIEW` | on / off | next launch | both ways into the browser above; off removes the START row, the A on COLORS and the screen, and leaves the palettes |
| `PACKS` | `ALL` / `RETRO` / `COLOUR` | next launch | all thirty-one, the twelve that are somebody's real hardware, or the nineteen invented ones |

The last two are read once, when the mod loads: one builds the COLORS list
and the other registers a screen and a menu row. The first two are read
every time they are used, so moving them shows immediately — you can watch
`FRAME` redraw the very menu you are choosing it in.

## The frames

On **Gen 1**: `THIN` `DOUBLE` `TRIPLE` `THICK` `WIDE` `DASH` `BEADS` `TRACK`, plus
`GAME BOY` for the engine's own, cycled from the `FRAME` row on the mod's OPTIONS.

On **Gold**: the same eight extend Gold's own `OPTION → FRAME` row, which picks
between the cart's eight frames and these eight (16 total). Uninstalling with one
of the mod's frames saved degrades safely to the cart's frame 1. The mod's own
FRAME row steps aside; Gold's row handles everything.

A border in this engine is not a texture. It is **six font glyphs** —
`tl h tr v bl br` — and `Font.drawBox` reads that table fresh on every
call. The engine's own comment says the table *"stays writable so a mod can
retheme one corner without shipping a whole page"*, so this ships a page and
repoints all six.

The sheet is generated by [`tools/make_frames.py`](tools/make_frames.py)
from rules written out in that file. Every pixel is authored there: no ROM,
no cartridge dump, and not a pixel of the engine's own font sheets.

### One glyph, two edges

`h` is drawn along the top **and** the bottom. `v` along the left **and**
the right. One glyph per axis, not per side — so a rail's position is a
single number shared by two opposite edges, and a corner that puts its rail
one pixel off produces a visible step where the corner tile hands over.

That rules out whole categories of design rather than just careless ones. A
**rounded** corner needs its arc to bulge outward — on the right edge the
vertical must sit further right than the horizontal ends, on the left
further left. One glyph cannot do both. A **rippling** rail fails the same
way: its row varies along the edge, so no corner can meet it at a fixed
height. Both were drawn here. Both stepped. Both were cut.

What is left is rails on fixed rows and columns, symmetric about the tile's
centre, decorated *along* their length rather than across it — which is why
`DASH` and `BEADS` use a period of 4 and not 3: eight does not divide by
three, so a period-3 rhythm puts two marks side by side wherever one tile
meets the next.

The generator checks all of this and refuses to write the sheet if any rail
steps.

## Four colours, or eighteen

The engine's **ADVANCED** mode is not a four-shade mode at all. It is the
pokered-gbc pack: a real colour resolved *per tile*, with **eight background
palettes live at once**. Until 0.3.0, picking RAINBOW switched that off — a
palette is a four-rung ramp, and four rungs is what the shade shader takes.

It does not have to be. A ramp can be read as a **curve** instead of four
steps: take each colour's luminance, find that height on the ramp, and
interpolate between the two rungs it falls between. Counted on the real
pack, inside a house:

| | colours on screen | across the game |
| --- | --- | --- |
| ADVANCED | 18 | 47 |
| RAINBOW, before | 4 | 4 |
| **RAINBOW, riding ADVANCED** | **18** | **47** |

Nothing is collapsed — the counts match ADVANCED's exactly — and the
source's own distinctions survive. VAPOR over a house interior:

```
          ADVANCED                          VAPOR
grey   247,230,214 156,156,156 …    228,227,234 143,179,194 …
pink   247,230,214 255,156,197 …    228,227,234 197,192,221 …
green  247,230,214 123,165,  8 …    228,227,234 140,163,120 …
```

The green tiles still read greener than the pink ones. They are simply all
inside VAPOR now.

`TINT` keeps ADVANCED's colour and pulls it toward the palette; `FULL` goes
all the way onto the ramp; `OFF` is the four-shade behaviour of 0.2.0. An
install with no pokered-gbc pack falls back to `OFF` by itself.

This is also the one place the lightest-first rule stops being cosmetic: the
curve is indexed by brightness, so a palette out of order would map light
tiles to dark colours and turn the world inside out. Every palette here is
checked by luminance in the test suite.

### Why the blend moved from RGB to HSV

Two source colours of equal brightness are answered by `rampAt` with a single
target colour. Blending both 55% toward that target in straight RGB closes the
gap between them by 55% too — so a green and a red of the same brightness
converge into a muddy brown, and Gold's eight background palette groups collapse
into a monochrome wash. It is arithmetic rather than taste: no choice of ramp
avoids it, which is why the fix had to be to the blend itself.

The fix splits the blend into three channels in HSV: VALUE follows the ramp
(immovable — brightness order is Game Boy shading), SATURATION moves toward
the ramp's weighted by how grey the source already is, and HUE rotates by an
amount that fades out as the source becomes more saturated. A vivid red stays
red and only gets re-lit; a dull wall takes the scheme's hue outright. Hue
DIFFERENCES survive.

`FULL` keeps the old RGB collapse — it is the one setting whose promise is "go
all the way onto the ramp" — so `TINT` and `FULL` are now a real choice.

### Moving palettes: RAINBOW and ACID

**RAINBOW** cycles its hue at a fixed rate, ~12 seconds per full rotation, so the
whole screen rotates through the spectrum while the ramp's brightness order stays
put. **ACID** lets each rung drift at its own incommensurable speed with saturation
breathing underneath — no two rungs keep the same relationship for long. Both
reach the screen from inside the renderer's per-frame path with no per-frame hook
needed.

Only hue and saturation move; each rung's **luminance** is fixed. The shade
shader reads rungs lightest-first, and if brightness stopped falling for even one
frame the picture would render inside out. Freezing HSV's *value* would not have
been enough — value is the largest channel, and a blue at full value is darker to
the eye than a yellow at four fifths of it, so four rungs turning at constant
value cross over somewhere in the rotation. Each hue is put back on the luminance
its rung started with instead. The suite walks a full turn of the wheel and
asserts the order and both contrast floors at every step.

The **MOTION** option freezes both at their table colours, which are ordinary
palettes and look it. This is the accessibility answer for a continuously-cycling
screen.

## Why the browser is not a grid of swatches

A swatch cannot tell you what a palette does. The engine colorises at
composite time — the finished 160×144 frame goes through a shade-remap — so
a screen that declares itself non-opaque leaves the map, your sprite and the
text box drawing underneath and gets recoloured along with them. Scrolling
the list *is* the preview, at full size, on the real picture.

## What is in it

**Hardware** — AMIGA (Workbench 1.3), DPAINT, C64, SPECCY, CGA, APPLE II,
POCKET, GB LIGHT, VBOY, AMBER, PHOSPHR, PLASMA.

**Colour** — RAINBOW, ACID, FUCHSIA, SUNSET, OCEAN, FOREST, LAVA, ICE, CANDY,
VAPOR, NEON, TOXIC, SEPIA, NOIR, CHERRY, MIDNITE, GOLD, MINT, GRAPE.

## The one rule, and the two palettes it caught

A Game Boy pixel is one of four **shades**, and the engine feeds a palette to
the shade-remap shader lightest-first. So the four colours must fall in
brightness across the row — and getting that wrong does not merely look odd,
it renders the game **inside out**, because the shading that describes every
sprite's form is the brightness order.

Thirty-one palettes is well past what anyone will check carefully by eye, so the
test suite checks all of them by luminance. It caught two:

**AMIGA.** Workbench 1.3's four colours are grey, blue `#0055AA`, orange
`#FF8800` and black. Laid out in Workbench's own order the ramp goes 170,
73, 151, 0 — the orange is *brighter* than the blue, so it reads inside out.
Same four colours, reordered by brightness.

**VBOY.** Red carries little luminance: pure `#FF0000` is darker to the eye
than mid grey, so four saturated reds collapse into mud with barely a third
of the range they need. The top rung is lifted toward white-hot to buy the
contrast back without letting another hue in.

Ordering by itself only says a ramp does not read *backwards* — it does not
say a ramp has any actual contrast to it. Two rungs can fall in the right
order and still sit close enough in brightness to look like the same colour
once the shade shader has desaturated them, which is the "flat" failure
`span < 120` above catches at the paper/ink extremes but not between
neighbours. So the suite also runs the **WCAG relative-luminance contrast
ratio** — the same formula behind the web's own text-contrast rule, each
channel gamma-corrected back to linear light before it is weighted — over
every adjacent pair (1-2, 2-3, 3-4) in every row, and requires **1.3** as a
floor: comfortably off "identical" without forcing every scheme toward the
high-contrast extreme CGA and SPECCY already sit at. The paper/ink pair
itself (index 1 against index 4 — the exact colours Chrome.printThrough on
Gold, and this mod's own browser box on either generation, draw a glyph
over) is held to the web's own body-text AA minimum, **4.5:1**.

Three rows were tightened to clear it, all without changing what the
scheme *is*: **AMIGA**'s grey lightened from `#AAAAAA` to `#D2D2D2` (it sat
at 1.03 against the orange next to it — effectively the same brightness
despite the different hue), **CGA**'s cyan deepened from `#55FFFF` to
`#3CE6E6`, and **VAPOR**'s cyan rung pulled down from `#78DCEB` to
`#5FB9CD`.

## Notes

Four shades is four shades. These recolour the Game Boy's ramp; they do not
add colours to a scene, and no palette here can show you something the
original could not draw.

Disable the mod with one of its palettes saved and the game falls back to
SGB (Gen 1) or GBC (Gold): the id stops resolving on whichever engine module
reads it, and the map's own colours pass through untouched either way. You
lose the palette, never the save.

## How it works

COLORS is not a registry. `src/render/PaletteFX.lua` keeps a plain array —
`PaletteFX.MODES` — that the options row cycles by index, while
`effectiveColors` turns the active mode into four RGB triples. Both are
ordinary tables on a module table, so this appends to one and wraps the
other.

Two functions need wrapping, not one. `ensureZones` invents a whole-screen
zone for modes that *force* a palette rather than tinting the map's own, and
it names OG / OG INV / CLASSIC explicitly — so a mode missing from that list
silently does nothing on exactly the screens that expose no SGB data.

Gold's own equivalent is `src/render/GbcPalette.lua`. It is not a registry
either, and it needs no `ensureZones`-shaped counterpart — Gold is never
working from a bare four greys with nothing else to draw from, so there is
no "screen with no SGB data" case to invent a zone for. One function does the
whole job: `GbcPalette.MODES` gets the same ids appended, and
`GbcPalette.resolve` gets wrapped the same way `effectiveColors` does, riding
Gold's own colours through the curve trick instead of Gen 1's ADVANCED pack.

## Ideas, and help building them

**Got an idea for something this should do?** Open an issue — there is a
template for it. You do not need to know any Lua, and you do not need to
have worked out how it would be built. Describe what you want and why.

**Want to build it yourself?** Open a pull request. Collaboration is welcome
on any part of this.

Anything you send that includes art has to be your own work — nothing
traced, edited or recoloured from a ROM, a fan game, a wiki or another mod.

## Requirements and legal

Lua source only: no ROM, no ROM-derived data, no game assets. The palettes
are original colour choices and reconstructions of other machines' hardware
palettes — nothing here is extracted from a Pokémon ROM. You need Gen1Recomp
and your own legally obtained Red or Blue ROM; neither is provided here.

Not affiliated with, endorsed by, or connected to Nintendo, Game Freak, or
The Pokémon Company. Amiga, Commodore, Sinclair and Apple marks belong to
their respective owners and are used only to say which machine a palette is
imitating.

## Support

<https://linktr.ee/made_in_taly>

## Licence

[MIT](LICENSE)
