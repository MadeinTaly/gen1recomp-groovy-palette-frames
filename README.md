# gen1recomp-groovy-palette

Thirty more entries on the **COLORS** row for
[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) — Amiga Workbench,
the C64 boot screen, a Virtual Boy, an amber terminal, and a pile of colour
ideas the Game Boy never had.

They join the engine's own list rather than replacing it: same OPTIONS row,
same hotkey, and the vanilla seven keep their positions.

## Install

Download `groovy_palette-<version>.zip` from [Releases](../../releases), then
**Launcher → MODS → Import mod .zip**. The launcher keeps it updated on its
own, and it can be installed from the **Find mods** tab without touching a
file.

## Use

**START → PALETTE.** Up and down walk the list; the game keeps drawing
behind it, so you are looking at Pallet Town in the palette rather than at a
menu covering it. **A** keeps it, **B** puts back the one you arrived with.

The game's own **OPTION → COLORS** row and hotkey `2` still work and still
cycle the same list.

**START → MODS → Groovy Palette → OPTIONS..**

| Row | Values | Meaning |
| --- | --- | --- |
| `START MENU` | on / off | the browser above; off removes the row and the screen and leaves the palettes |
| `PACKS` | `ALL` / `RETRO` / `COLOUR` | all thirty, the twelve that are somebody's real hardware, or the eighteen invented ones |

## Why the browser is not a grid of swatches

A swatch cannot tell you what a palette does. The engine colorises at
composite time — the finished 160×144 frame goes through a shade-remap — so
a screen that declares itself non-opaque leaves the map, your sprite and the
text box drawing underneath and gets recoloured along with them. Scrolling
the list *is* the preview, at full size, on the real picture.

## What is in it

**Hardware** — AMIGA (Workbench 1.3), DPAINT, C64, SPECCY, CGA, APPLE II,
POCKET, GB LIGHT, VBOY, AMBER, PHOSPHR, PLASMA.

**Colour** — RAINBOW, FUCHSIA, SUNSET, OCEAN, FOREST, LAVA, ICE, CANDY,
VAPOR, NEON, TOXIC, SEPIA, NOIR, CHERRY, MIDNITE, GOLD, MINT, GRAPE.

## The one rule, and the two palettes it caught

A Game Boy pixel is one of four **shades**, and the engine feeds a palette to
the shade-remap shader lightest-first. So the four colours must fall in
brightness across the row — and getting that wrong does not merely look odd,
it renders the game **inside out**, because the shading that describes every
sprite's form is the brightness order.

Thirty palettes is well past what anyone will check carefully by eye, so the
test suite checks all of them by luminance. It caught two:

**AMIGA.** Workbench 1.3's four colours are grey, blue `#0055AA`, orange
`#FF8800` and black. Laid out in Workbench's own order the ramp goes 170,
73, 151, 0 — the orange is *brighter* than the blue, so it reads inside out.
Same four colours, reordered by brightness.

**VBOY.** Red carries little luminance: pure `#FF0000` is darker to the eye
than mid grey, so four saturated reds collapse into mud with barely a third
of the range they need. The top rung is lifted toward white-hot to buy the
contrast back without letting another hue in.

## Notes

Four shades is four shades. These recolour the Game Boy's ramp; they do not
add colours to a scene, and no palette here can show you something the
original could not draw.

Disable the mod with one of its palettes saved and the game falls back to
SGB: the id stops resolving and the map's own colours pass through
untouched. You lose the palette, never the save.

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
