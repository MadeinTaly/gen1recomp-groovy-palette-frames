-- Groovy Palette
--
-- Thirty more entries on the COLORS row: Amiga Workbench, the C64 boot
-- screen, a Virtual Boy, and a pile of colour ideas the Game Boy never had.
-- The same thirty play on Gold too, recolouring its own GBC palettes rather
-- than standing in for a mechanism Gold does not have -- see "Gold: the same
-- palettes, through the choke point Gold actually has" further down.
--
-- ------- where these plug in, on Red/Blue/Yellow
--
-- COLORS is not a registry. `src/render/PaletteFX.lua` keeps a plain array:
--
--   PaletteFX.MODES = { "ogred", "gbc", "redpp", "og", ... }
--
-- and the options row cycles it by index while `effectiveColors` turns the
-- active mode into four RGB triples. Both are ordinary Lua tables on a module
-- table, so a mod appends to one and wraps the other. That is the whole
-- mechanism -- there is no palette registry to go through, and inventing a
-- parallel one would have left the vanilla row still cycling seven modes.
--
-- Two functions need wrapping, not one:
--
--   effectiveColors(c)  turns the active mode into colours
--   ensureZones(zones)  invents a whole-screen zone when a mode FORCES a
--                       palette rather than tinting the map's own
--
-- The second is the one that is easy to miss. OG / OG INV / CLASSIC are named
-- explicitly there, and a mode not in that list gets no zone on a screen that
-- exposes none -- so the shade-remap shader never runs and the palette
-- silently does nothing on exactly the screens with no SGB data.
--
-- Gold has no equivalent of either function, because it has no equivalent
-- problem: it is never working from four greys with nothing else to draw
-- from. `src/render/GbcPalette.lua`'s `resolve` is the one function this mod
-- wraps there, and that section (further down, next to where it happens) is
-- where the difference is worth reading in full.
--
-- The palette table lives in this file rather than a data/ module on
-- purpose. modkit runs the validating loader with its cwd at the ENGINE
-- root, so `require("data.palettes")` searches the engine's data directory
-- and not the mod's -- a mod-relative require is not a thing the loader
-- provides. One file has no such question to answer.
--
-- ------- turning the mod off
--
-- A save keeps the mode id. Disable this mod and the id is no longer in
-- MODES (PaletteFX's on Gen 1, GbcPalette's on Gen 2), so the resolving
-- function falls through its if-chain and returns the map's own colours
-- untouched -- SGB on Gen 1, the cart's own GBC palettes on Gen 2, both the
-- default either game already had. The player loses the palette, never the
-- game.

-- ------- the palettes
--
-- ------- the one rule
--
-- A Game Boy pixel is one of four SHADES, and the engine feeds a palette to
-- the shade-remap shader lightest-first: index 1 is paper, index 4 is ink.
-- So the four colours must fall in brightness across the row. Get that wrong
-- and the image does not merely look odd -- it reads inside out, because the
-- shading that describes every sprite's form is inverted.
--
-- `tests/` checks this by luminance on every row here, which is why the set
-- can be this large without any of them being eyeballed.
--
-- ------- the second rule: a rung has to earn its place
--
-- Falling in brightness is necessary but not sufficient -- two rungs a
-- fraction of a shade apart in the eye's own response fall in the right
-- order and still read as one flat colour once the shader has desaturated
-- them, which throws away exactly the boundary the four-shade ramp exists to
-- draw. `tests/` computes the WCAG relative-luminance contrast ratio (the
-- formula behind the web's text-contrast rule: each channel gamma-corrected
-- back to linear light before the 0.2126/0.7152/0.0722 weighting, then
-- (L_light + 0.05) / (L_dark + 0.05)) for every ADJACENT pair in a row --
-- 1-2, 2-3, 3-4 -- and requires at least 1.3, a deliberately modest floor:
-- enough that no two neighbouring rungs are visually interchangeable,
-- without forcing every scheme toward the high-contrast extreme CGA and
-- SPECCY already sit at on their own. The paper/ink pair (1 and 4, what
-- Chrome.printThrough in the Gen 2 port and the box text in Gen 1 both
-- actually draw a glyph over) is held to the web's own AA body-text minimum,
-- 4.5:1 -- every row here clears it by at least double, because a ramp built
-- to satisfy the ordering rule above already spans most of the shade range.
--
-- Labels are capped at 8 characters: the OPTIONS row draws the value beside
-- its label on a 160px screen, and every glyph advances 8 pixels.
local PALETTES = {

  -- ------- machines that actually looked like this

  { id = "amiga_wb", label = "AMIGA",
    -- Workbench 1.3, and a lesson in why the luminance test exists. The four
    -- authentic colours are grey, blue #0055AA, orange #FF8800 and black --
    -- but in Workbench's own order the orange (luminance 151) sits below the
    -- blue (73), so laying them out "as the Amiga had them" produces a ramp
    -- that goes bright, dark, bright, dark and reads inside out.
    -- Same four colours, ordered by brightness. The grey is lifted from
    -- #AAAAAA to #D2D2D2: WCAG relative luminance (sRGB-linearised, not the
    -- flat R+G+B the ordering check above uses) put grey against orange at
    -- a contrast ratio of 1.03 -- next to unity, i.e. two "different" rungs
    -- that read as the same brightness once desaturated by the shade
    -- shader. 1.03 -> 1.58 is what buys the boundary back.
    colors = { {210,210,210}, {255,136,0}, {0,85,170}, {0,0,0} } },

  { id = "amiga_dp", label = "DPAINT",
    -- Deluxe Paint's default ramp -- cooler, and the one every Amiga demo
    -- artist actually stared at.
    colors = { {221,221,238}, {119,136,187}, {68,68,119}, {17,17,34} } },

  { id = "c64", label = "C64",
    -- VIC-II: light blue on blue, the boot screen everyone remembers.
    colors = { {160,160,255}, {108,94,181}, {64,49,141}, {24,16,72} } },

  { id = "spectrum", label = "SPECCY",
    -- ZX Spectrum's bright primaries: white, cyan, magenta, black.
    colors = { {255,255,255}, {0,204,204}, {204,0,204}, {0,0,0} } },

  { id = "cga", label = "CGA",
    -- Palette 1 high intensity: white, cyan, magenta, black. The cyan is
    -- deepened from #55FFFF (WCAG contrast 1.23 against white, the same
    -- near-unity collision AMIGA had) to #3CE6E6, splitting the gap toward
    -- magenta roughly evenly (1.54 against white, 1.71 against magenta)
    -- instead of leaving one boundary flat and the other doing all the work.
    colors = { {255,255,255}, {60,230,230}, {255,85,255}, {0,0,0} } },

  { id = "apple2", label = "APPLE II",
    colors = { {200,255,200}, {80,220,110}, {30,130,60}, {8,32,16} } },

  { id = "pocket", label = "POCKET",
    -- Game Boy Pocket: the greys that replaced the pea soup.
    colors = { {224,224,224}, {160,160,160}, {88,88,88}, {24,24,24} } },

  { id = "gblight", label = "GB LIGHT",
    -- The backlit Light's indigo-tinted screen.
    colors = { {0,251,199}, {0,187,155}, {0,107,96}, {0,48,48} } },

  { id = "virtualboy", label = "VBOY",
    -- Four reds and nothing else, exactly as Nintendo intended and everyone
    -- regretted. Red is a dark colour to the eye -- pure #FF0000 carries less
    -- luminance than mid grey -- so a ramp of saturated reds collapses into
    -- mud. The top rung is lifted toward white-hot to buy the contrast back
    -- without letting another hue in.
    colors = { {255,150,130}, {215,45,32}, {120,12,8}, {12,0,0} } },

  { id = "amber", label = "AMBER",
    -- An amber CRT terminal.
    colors = { {255,196,64}, {200,140,30}, {120,76,10}, {24,12,0} } },

  { id = "phosphor", label = "PHOSPHR",
    -- And the green one next to it.
    colors = { {170,255,170}, {80,200,90}, {30,110,45}, {5,25,10} } },

  { id = "plasma", label = "PLASMA",
    colors = { {255,230,180}, {255,140,60}, {170,40,90}, {30,10,40} } },

  -- ------- colour ideas

  { id = "rainbow", label = "RAINBOW", motion = "cycle",
    -- Four shades cannot be a spectrum, so this walks the hue wheel while
    -- brightness falls: yellow, orange-pink, violet, indigo. It reads as a
    -- rainbow because the hue moves, not because six colours are present.
    --
    -- And since 0.8.0 the hue moves in TIME as well as down the ramp: see
    -- "the moving palettes" below. These four are what it looks like at
    -- t=0, and what it is frozen at when MOTION is off -- so the ordering
    -- and contrast rules the suite enforces are checked against a real
    -- palette, not against a still of an animation.
    colors = { {255,241,120}, {255,120,150}, {150,70,200}, {30,20,80} } },

  { id = "acid", label = "ACID", motion = "acid",
    -- Four rungs let off the leash: every one drifts round the wheel at its
    -- own speed, so the ramp is never the same twice and no two rungs keep
    -- a fixed relationship. What it does NOT do is move brightness -- see
    -- `animate` below for why that is not a stylistic choice.
    colors = { {236,255,150}, {120,225,140}, {150,60,190}, {35,15,55} } },

  { id = "fuchsia", label = "FUCHSIA",
    colors = { {255,214,240}, {255,105,190}, {170,30,120}, {40,0,40} } },

  { id = "sunset", label = "SUNSET",
    colors = { {255,224,168}, {255,140,90}, {170,60,90}, {40,20,60} } },

  { id = "ocean", label = "OCEAN",
    colors = { {200,245,255}, {80,190,220}, {25,95,150}, {5,20,60} } },

  { id = "forest", label = "FOREST",
    colors = { {214,240,180}, {130,190,90}, {50,110,60}, {12,35,25} } },

  { id = "lava", label = "LAVA",
    colors = { {255,240,180}, {255,150,40}, {180,40,20}, {35,8,8} } },

  { id = "ice", label = "ICE",
    colors = { {240,252,255}, {170,220,245}, {80,130,190}, {20,35,80} } },

  { id = "candy", label = "CANDY",
    colors = { {255,235,245}, {255,160,200}, {190,90,160}, {60,25,70} } },

  { id = "vapor", label = "VAPOR",
    -- Vaporwave: the pink-and-cyan pairing, darkened into a usable ramp.
    -- The cyan rung sat at contrast 1.29 against the lilac paper above it --
    -- below the 1.3 floor this file holds every adjacent pair to -- so it is
    -- pulled down toward the magenta below it (1.84 against paper, 1.77
    -- against magenta) rather than left crowding the top of the ramp.
    colors = { {245,225,255}, {95,185,205}, {200,80,180}, {45,20,70} } },

  { id = "neon", label = "NEON",
    colors = { {225,255,90}, {60,230,180}, {200,40,160}, {15,10,35} } },

  { id = "toxic", label = "TOXIC",
    colors = { {225,255,60}, {130,210,30}, {60,120,25}, {15,30,10} } },

  { id = "sepia", label = "SEPIA",
    colors = { {240,224,196}, {186,155,116}, {110,84,58}, {32,24,18} } },

  { id = "noir", label = "NOIR",
    -- High-contrast monochrome: the midtones pushed apart so the shading
    -- stays legible when everything else is grey.
    colors = { {245,245,245}, {150,150,155}, {60,60,68}, {0,0,0} } },

  { id = "cherry", label = "CHERRY",
    colors = { {255,225,225}, {235,90,90}, {150,25,45}, {40,5,15} } },

  { id = "midnight", label = "MIDNITE",
    colors = { {180,195,235}, {90,110,180}, {40,50,110}, {8,10,30} } },

  { id = "gold", label = "GOLD",
    colors = { {255,244,200}, {228,190,80}, {150,110,30}, {40,28,8} } },

  { id = "mint", label = "MINT",
    colors = { {224,255,240}, {130,225,190}, {45,140,120}, {10,45,40} } },

  { id = "grape", label = "GRAPE",
    colors = { {235,220,255}, {170,130,225}, {95,55,150}, {28,12,50} } },
}

-- The twelve that are somebody's real hardware; the rest are inventions.
local RETRO = {
  amiga_wb = true, amiga_dp = true, c64 = true, spectrum = true,
  cga = true, apple2 = true, pocket = true, gblight = true,
  virtualboy = true, amber = true, phosphor = true, plasma = true,
}

return function(mod)
  mod.options:define({
    -- Thirty extra rungs on a ladder cycled one press at a time is a long
    -- walk, so the pack can be narrowed to the half you came for.
    { key = "packs", label = "PACKS", type = "choice", default = "all",
      choices = {
        { "ALL", "all" },
        { "RETRO", "retro" },
        { "COLOUR", "colour" },
      } },
    -- The browser is the point of having thirty of these: choosing a colour
    -- from a menu that is covering the game is choosing it blind. Off puts
    -- the mod back to being nothing but extra rungs on the OPTIONS row.
    { key = "browser", label = "PREVIEW", type = "toggle", default = true },
    -- See "riding ADVANCED" below for Red/Blue/Yellow, and "Gold: the same
    -- palettes, through the choke point Gold actually has" for what the same
    -- three settings mean there. OFF is what 0.2.0 did on Gen 1, and the
    -- plain four-shade swap on Gold.
    { key = "advanced", label = "USE ADVANCED", type = "choice", default = "tint",
      choices = {
        { "TINT", "tint" },
        { "FULL", "full" },
        { "OFF", "off" },
      } },
    -- RAINBOW and ACID are functions of the clock rather than constants.
    -- Off freezes both at the four colours their table gives them, which are
    -- ordinary palettes and look it -- so this is a real setting and not a
    -- disable switch. It is also the one accessibility answer a screen that
    -- cycles hue continuously has to have.
    { key = "motion", label = "MOTION", type = "toggle", default = true },
    -- The border every text box and menu is drawn with. GAME BOY is the
    -- engine's own; the rest are this mod's, drawn in tools/make_frames.py.
    { key = "frame", label = "FRAME", type = "choice", default = "gb",
      choices = {
        { "GAME BOY", "gb" },
        { "THIN", "thin" },
        { "DOUBLE", "double" },
        { "TRIPLE", "triple" },
        { "THICK", "thick" },
        { "WIDE", "wide" },
        { "DASH", "dash" },
        { "BEADS", "beads" },
        { "TRACK", "track" },
      } },
  })

  local function wanted()
    local ok, value = pcall(function() return mod.options:get("packs") end)
    return ok and value or "all"
  end

  local function advancedMode()
    local ok, value = pcall(function() return mod.options:get("advanced") end)
    if not ok or value == nil then return "tint" end
    return value
  end

  local PaletteFX = require("src.render.PaletteFX")
  -- Gold's answer to PaletteFX -- see "Gold: the same palettes, through the
  -- choke point Gold actually has" below, where this is put to use.
  local GbcPalette = require("src.render.GbcPalette")

  -- Which ids this mod owns, and the colours behind each. Built once: MODES
  -- is read every time the option row moves, so it has to be a stable array
  -- rather than something recomputed under the cursor.
  local mine, added, MOTION = {}, {}, {}
  local pick = wanted()
  for _, p in ipairs(PALETTES) do
    local isRetro = RETRO[p.id] and true or false
    local take = pick == "all"
                 or (pick == "retro" and isRetro)
                 or (pick == "colour" and not isRetro)
    if take then
      mine[p.id] = p.colors
      if p.motion then MOTION[p.id] = p.motion end
      added[#added + 1] = p
    end
  end

  -- Append rather than replace: the vanilla seven keep their positions, so a
  -- save pointing at "gbc" still lands on SGB and the hotkey still walks the
  -- original modes first.
  for _, p in ipairs(added) do
    local known = false
    for _, id in ipairs(PaletteFX.MODES) do
      if id == p.id then known = true; break end
    end
    if not known then
      PaletteFX.MODES[#PaletteFX.MODES + 1] = p.id
      PaletteFX.MODE_LABELS[p.id] = p.label
    end
  end

  -- ------- riding ADVANCED instead of replacing it
  --
  -- A Game Boy screen is four shades, and that is what every mode here was
  -- built on. ADVANCED is not: it is the pokered-gbc pack, which resolves a
  -- real colour PER TILE and assigns each tile one of EIGHT background
  -- palettes. Counted from the pack on disk:
  --
  --     24 tilesets carry per-tile data
  --      8 background palettes are live at once  ->  up to 32 colours
  --     47 distinct colours across the whole pack
  --
  -- So picking RAINBOW used to be a straight downgrade: thirty-two colours
  -- traded for four. The palette was applied INSTEAD of ADVANCED, because a
  -- palette is a four-rung ramp and that is all the shade shader can take.
  --
  -- It does not have to be. ADVANCED's colours arrive as ordinary RGB
  -- triples, and a ramp can be read as a CURVE rather than four steps:
  -- take each colour's luminance, find that height on the ramp, and
  -- interpolate between the two rungs it falls between. Forty-seven source
  -- colours come back as forty-seven colours in the palette's own hue
  -- family, not four.
  --
  --     TINT   keep ADVANCED's colour, pull it toward the palette
  --     FULL   go all the way onto the ramp, but along the curve
  --     OFF    what 0.2.0 did: four shades, ADVANCED replaced
  --
  -- The rung order is what makes this work, and it is the same rule the
  -- suite already enforces on every palette: lightest first, falling in
  -- brightness. A palette that failed that check would map light tiles to
  -- dark colours and render the world inside out.

  local BLEND = { tint = 0.55, full = 1.0 }

  local function luminance(c)
    return 0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3]
  end

  -- the ramp read as a curve: 0 luminance is the last rung, 255 the first
  local function rampAt(ramp, l)
    local p = (255 - l) / 255 * (#ramp - 1)
    if p < 0 then p = 0 elseif p > #ramp - 1 then p = #ramp - 1 end
    local i = math.floor(p)
    local a = ramp[i + 1]
    local b = ramp[math.min(i + 2, #ramp)]
    local t = p - i
    return a[1] + (b[1] - a[1]) * t,
           a[2] + (b[2] - a[2]) * t,
           a[3] + (b[3] - a[3]) * t
  end

  local function clamp255(v)
    v = math.floor(v + 0.5)
    if v < 0 then return 0 elseif v > 255 then return 255 end
    return v
  end

  -- ------- why the ramp cannot simply be blended in RGB
  --
  -- Reading the ramp as a curve (above) fixes the COUNT of colours: forty-
  -- seven sources come back as forty-seven. It does not fix their VARIETY,
  -- and 0.7.0 shipped without noticing the difference.
  --
  -- `rampAt` answers with one colour per luminance, so two sources of equal
  -- brightness -- Gold's grass green and its roof red, say -- are handed the
  -- SAME target. Blend both 55% of the way there in straight RGB and they do
  -- not merely shift, they CONVERGE: the gap between them closes by 55% too.
  -- Do that to every palette on screen and the eight background groups Gold
  -- spent its whole colour budget distinguishing collapse toward one hue.
  -- That is the "everything went red" a CHERRY or VBOY screenshot shows, and
  -- it is arithmetic rather than taste -- no choice of ramp avoids it.
  --
  -- So the blend moves to HSV, where the three things a scheme wants to do
  -- can be asked for separately:
  --
  --   VALUE       follows the ramp. This is the part that must not be
  --               negotiable: brightness order IS Game Boy shading, and a
  --               scheme that does not govern brightness is not a scheme.
  --   SATURATION  moves toward the ramp's, weighted by how grey the source
  --               already is -- so a flat wall takes the scheme's intensity
  --               and a colour that is already vivid keeps its own.
  --   HUE         rotates toward the ramp, by an amount that FADES OUT as
  --               the source's own saturation rises.
  --
  -- The hue term is the fix. A near-grey source has no hue worth keeping, so
  -- it takes the scheme's outright -- which is how the mod still reads as
  -- CHERRY or OCEAN rather than as a faint wash. A saturated source is
  -- something the cart deliberately coloured, so it is left where it is and
  -- only re-lit. Hue DIFFERENCES survive, which is the property that was
  -- being destroyed, and the "does this palette do anything at all" property
  -- is kept by the value and saturation terms rather than by flattening.
  --
  -- FULL is deliberately exempt: it is the one setting whose whole promise
  -- is "go all the way onto the ramp", so it keeps the straight collapse
  -- TINT used to do by accident. The difference between the two settings is
  -- now a real one, and the default is the side that keeps the picture.

  local function toHsv(c)
    local r, g, b = c[1] / 255, c[2] / 255, c[3] / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local span = max - min
    local h = 0
    if span > 0 then
      if max == r then h = (g - b) / span % 6
      elseif max == g then h = (b - r) / span + 2
      else h = (r - g) / span + 4 end
      h = h / 6
      if h < 0 then h = h + 1 end
    end
    return h, (max > 0 and span / max or 0), max
  end

  local function fromHsv(h, s, v)
    h = h % 1
    if s <= 0 then
      local g = clamp255(v * 255)
      return { g, g, g }
    end
    local sector = h * 6
    local i = math.floor(sector)
    local f = sector - i
    local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    local r, g, b
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    return { clamp255(r * 255), clamp255(g * 255), clamp255(b * 255) }
  end

  -- Round the short way. Straight interpolation between 0.95 and 0.05 walks
  -- backwards through the entire wheel -- red to red via cyan -- which is a
  -- visible sweep through hues neither end asked for.
  local function hueToward(from, to, t)
    local delta = (to - from) % 1
    if delta > 0.5 then delta = delta - 1 end
    return (from + delta * t) % 1
  end

  -- How hard a saturated source resists having its hue moved. Squared rather
  -- than linear so the protection arrives early: Gold's colours mostly sit
  -- high on the saturation scale, and a linear term still dragged them a
  -- third of the way to a shared hue.
  local function huePull(amount, saturation)
    local keep = 1 - saturation
    return amount * keep * keep
  end

  local function recolor(c, ramp, amount, collapse)
    local r, g, b = rampAt(ramp, luminance(c))
    if collapse then
      -- FULL: the ramp and nothing else, which is what it says on the row
      return {
        clamp255(c[1] + (r - c[1]) * amount),
        clamp255(c[2] + (g - c[2]) * amount),
        clamp255(c[3] + (b - c[3]) * amount),
      }
    end
    local sh, ss, sv = toHsv(c)
    local th, ts, tv = toHsv({ r, g, b })
    return fromHsv(
      hueToward(sh, th, huePull(amount, ss)),
      ss + (ts - ss) * amount * (1 - ss),
      sv + (tv - sv) * amount)
  end

  local function recolorAll(colors, ramp, amount, collapse)
    local out = {}
    for i, c in ipairs(colors) do out[i] = recolor(c, ramp, amount, collapse) end
    return out
  end

  -- ------- the moving palettes
  --
  -- RAINBOW asks for something the other thirty-one do not: a colour that is
  -- not a constant. The engine has no per-frame event for a mod to subscribe
  -- to, and it does not need one -- everything below is reached from inside
  -- functions the renderer already calls once a frame, so the clock can be
  -- read where the colour is asked for.
  --
  -- ------- what may move, and what may not
  --
  -- Only HUE and SATURATION. Every rung keeps the BRIGHTNESS its entry in the
  -- table gave it, which is not a stylistic preference: the four rungs are
  -- fed to the shade shader lightest-first, and a ramp that stopped falling
  -- in brightness for even one frame would turn the picture inside out for
  -- that frame.
  --
  -- Holding HSV's "value" fixed does NOT achieve that, which is the trap
  -- here and worth stating plainly. Value is the largest channel, not a
  -- brightness the eye agrees with: a pure blue at value 1.0 carries a
  -- luminance of 18, and a yellow at value 0.8 carries 200. Rotate four
  -- rungs round the wheel at constant value and they will, at some phase of
  -- the turn, cross over each other -- the ramp inverts, and the picture
  -- with it.
  --
  -- So the hue moves at constant LUMINANCE instead. `atLuminance` puts a hue
  -- back on the brightness its rung started with: scale it down if the hue
  -- can carry more than that on its own, mix it toward white if it cannot
  -- carry enough (both are linear in the luminance, so it is a solve rather
  -- than a search). The ordering rule then holds for every frame by
  -- construction, because each rung's luminance is exactly the one the
  -- suite already checked on the table -- and the suite walks a whole turn
  -- of the wheel and re-checks it anyway, since an invariant nothing tests
  -- is a comment.
  --
  -- ------- and why they cost nothing
  --
  -- A moving palette must not touch anything that is BAKED. On Gen 1 that
  -- rules out the ADVANCED path, whose atlases are cached under `darkKey`
  -- (one re-bake of every tileset and sprite sheet per frame -- see the
  -- cache in TileRenderer's `getGbcAtlas`); on Gold it rules out the map
  -- canvas and the OBJ bakes, which key on `GbcPalette.mode` and would
  -- otherwise serve whatever hue they were first built with while the menus
  -- moved on without them.
  --
  -- So both generations put a moving palette on the same footing: the frame
  -- renders in four flat greys, exactly as DMG does, and the colour arrives
  -- in the whole-screen pass over the finished picture. On Gen 1 that is
  -- `ensureZones` + `effectiveColors`, which the four-shade path already
  -- used; on Gold it is `GbcPalette.presentColors`, which is how CLASSIC
  -- turns a grey frame green (src/core/Game2.lua:1384 builds the zone from
  -- it every frame). Nothing re-bakes, and one shader uniform changes.

  local MOTION_SPEED = 0.085          -- turns per second: ~12s for a full round

  -- Per-rung drift for ACID, in turns per second. Deliberately incommensurable
  -- -- no two share a common period -- so the four never fall back into the
  -- arrangement they started in.
  local ACID_DRIFT = { 0.11, -0.17, 0.23, -0.07 }

  -- The brightness the ORDERING rule is written in. Deliberately not the
  -- `luminance` above: that one is a position on the ramp curve (which rung
  -- is this colour nearest), and these weights are the ones tests/ sorts the
  -- rungs by. The animation has to preserve the metric that is actually
  -- being checked, not a near neighbour of it.
  local function shadeLuma(c)
    return 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3]
  end

  -- A hue, put on a given luminance. Both branches are exact: RGB scales
  -- linearly with value, and mixing toward white moves luminance linearly
  -- too, so neither needs to iterate.
  local function atLuminance(h, s, target)
    local pure = fromHsv(h, s, 1)
    local carry = shadeLuma(pure)
    if carry >= target then
      local v = target / carry
      return { clamp255(pure[1] * v), clamp255(pure[2] * v), clamp255(pure[3] * v) }
    end
    -- this hue cannot be bright enough on its own; walk it toward white
    local k = (target - carry) / (255 - carry)
    return {
      clamp255(pure[1] + (255 - pure[1]) * k),
      clamp255(pure[2] + (255 - pure[2]) * k),
      clamp255(pure[3] + (255 - pure[3]) * k),
    }
  end

  local function now()
    -- The suite runs without love, and a palette that is a function of time
    -- has to be reproducible there: no clock means t=0, which is exactly the
    -- table as written.
    if love and love.timer and love.timer.getTime then return love.timer.getTime() end
    return 0
  end

  local function motionOn()
    local ok, value = pcall(function() return mod.options:get("motion") end)
    return (not ok) or (value ~= false)
  end

  -- The ramp `id` should be drawn with at time `t`, or its own table when it
  -- does not move. Exposed on mod.exports for the suite, which drives `t`
  -- itself rather than waiting on a clock.
  local function animate(id, t)
    local base = mine[id]
    if not base then return nil end
    local how = MOTION[id]
    if not how then return base end
    local out = {}
    for i, c in ipairs(base) do
      local h, s = toHsv(c)
      local keep = shadeLuma(c)
      if how == "cycle" then
        -- One rigid wheel: every rung turns together, so the ramp keeps the
        -- hue SPACING the table was written with and the whole picture
        -- rotates through the spectrum rather than smearing into one hue.
        out[i] = atLuminance(h + t * MOTION_SPEED, s, keep)
      else
        -- ACID: each rung on its own wheel, and the saturation breathing
        -- underneath, which is what stops it reading as a tidy rotation.
        local drift = ACID_DRIFT[i] or MOTION_SPEED
        local pulse = 0.5 + 0.5 * math.sin(t * 1.7 + i)
        out[i] = atLuminance(h + t * drift,
          math.min(1, s * (0.75 + 0.5 * pulse)), keep)
      end
    end
    return out
  end

  -- The four colours a mode is being drawn with RIGHT NOW: the animation if
  -- it is one and motion is on, the table as written otherwise. Every read of
  -- `mine[...]` that reaches the screen goes through this.
  local function ramping(id)
    local base = mine[id or ""]
    if not base then return nil end
    if MOTION[id] and motionOn() then return animate(id, now()) end
    return base
  end

  local function moving(id)
    return MOTION[id or ""] ~= nil and motionOn()
  end

  -- The active ramp, but only while a Groovy palette is selected AND the
  -- option asks for it. Returns nil the rest of the time, which is what
  -- every wrapper below tests to decide whether to stay out of the way.
  local function riding()
    local ramp = mine[PaletteFX.mode or ""]
    if not ramp then return nil end
    -- A moving palette never rides ADVANCED: the per-tile path BAKES, and a
    -- colour that changes every frame would rebuild every atlas every frame.
    -- Refusing here is what puts it on the four-shade path instead, where the
    -- colour is a shader uniform and moving it is free.
    if moving(PaletteFX.mode) then return nil end
    local how = advancedMode()
    local amount = BLEND[how]
    if not amount then return nil end
    -- No pack, nothing to ride: an install without data/palettes_gbc.lua
    -- must fall back to the four-shade path rather than to nothing at all.
    -- usesGbcPack already refuses in that case, so without this check the
    -- palette would neither ride ADVANCED nor replace it.
    if not PaletteFX.gbcPack() then return nil end
    return ramp, amount, how
  end

  -- ------- 1. take the ADVANCED code path at all
  --
  -- usesGbcPack is the single gate: TileRenderer, SpriteRenderer and this
  -- module all ask it before reading the pack. Answering yes for our own
  -- ids is what puts a Groovy palette on the per-tile path instead of the
  -- four-shade one.
  if not PaletteFX._groovyPaletteOriginalUses then
    PaletteFX._groovyPaletteOriginalUses = PaletteFX.usesGbcPack
  end
  local originalUses = PaletteFX._groovyPaletteOriginalUses

  PaletteFX.usesGbcPack = function(mode)
    mode = mode or PaletteFX.mode
    if moving(mode) then return originalUses(mode) end
    if mine[mode or ""] and BLEND[advancedMode()] then
      -- only claim the path when the pack is actually there to walk it
      return PaletteFX.gbcPack() ~= nil
    end
    return originalUses(mode)
  end

  -- ------- 2. the overworld's eight background palettes
  if not PaletteFX._groovyPaletteOriginalWorld then
    PaletteFX._groovyPaletteOriginalWorld = PaletteFX.worldGroupColors
  end
  local originalWorld = PaletteFX._groovyPaletteOriginalWorld

  PaletteFX.worldGroupColors = function(data, tileset, mapId, playerCellY)
    local groups = originalWorld(data, tileset, mapId, playerCellY)
    local ramp, amount, how = riding()
    if not (groups and ramp) then return groups end
    local out = {}
    for i, palette in ipairs(groups) do
      out[i] = recolorAll(palette, ramp, amount, how == "full")
    end
    return out
  end

  -- ------- 3. the overworld sprites' OBJ palettes
  if not PaletteFX._groovyPaletteOriginalObp then
    PaletteFX._groovyPaletteOriginalObp = PaletteFX.spriteObp
  end
  local originalObp = PaletteFX._groovyPaletteOriginalObp

  PaletteFX.spriteObp = function(spriteDef, seed)
    local colors, group = originalObp(spriteDef, seed)
    local ramp, amount, how = riding()
    if not (colors and ramp) then return colors, group end
    return recolorAll(colors, ramp, amount, how == "full"), group
  end

  -- ------- 4. do not serve a stale bake
  --
  -- ADVANCED does not shade at draw time, it BAKES: the tileset atlas and
  -- the sprite sheets are rendered once per map and cached under a key that
  -- ends in darkKey(). Two palettes would otherwise share one cache entry
  -- and the second would show the first one's colours. The suffix is the
  -- engine's own mechanism for exactly this -- a dark cave uses it to keep
  -- its lit and unlit bakes apart -- so the palette rides it.
  if not PaletteFX._groovyPaletteOriginalDarkKey then
    PaletteFX._groovyPaletteOriginalDarkKey = PaletteFX.darkKey
  end
  local originalDarkKey = PaletteFX._groovyPaletteOriginalDarkKey

  PaletteFX.darkKey = function()
    local base = originalDarkKey()
    local _, _, how = riding()
    if not how then return base end
    return base .. "#groovy:" .. tostring(PaletteFX.mode) .. ":" .. how
  end

  -- ------- effectiveColors: substitute our four, then let the original run
  --
  -- Calling through rather than returning early matters: the original applies
  -- the shade map LAST -- rBGP is a hardware register write, so a dark cave
  -- has to read dark in these palettes exactly as it does in CLASSIC's pea
  -- greens. Handing it our colours as its input keeps that composition.
  --
  -- While riding ADVANCED this must NOT substitute. The named palettes --
  -- battle backdrops, a Pokemon's own colours, the menus -- come through
  -- here already resolved from the pack, so flattening them to our four
  -- would throw away exactly the variety we came for. They get the same
  -- curve as everything else instead.
  if not PaletteFX._groovyPaletteOriginalColors then
    PaletteFX._groovyPaletteOriginalColors = PaletteFX.effectiveColors
  end
  local originalColors = PaletteFX._groovyPaletteOriginalColors

  PaletteFX.effectiveColors = function(c)
    local ramp, amount, how = riding()
    if ramp then
      if not c then return originalColors(c) end
      return originalColors(recolorAll(c, ramp, amount, how == "full"))
    end
    -- `ramping` rather than `mine`: this is the per-frame read, and for a
    -- moving palette it is the one that makes it move. Everything else about
    -- the four-shade path is unchanged.
    local swap = ramping(PaletteFX.mode)
    if swap then return originalColors(swap) end
    return originalColors(c)
  end

  -- ------- ensureZones: a forced palette needs a surface to be forced onto
  if not PaletteFX._groovyPaletteOriginalZones then
    PaletteFX._groovyPaletteOriginalZones = PaletteFX.ensureZones
  end
  local originalZones = PaletteFX._groovyPaletteOriginalZones

  PaletteFX.ensureZones = function(zones)
    if zones and zones[1] then return zones end
    -- riding ADVANCED there is nothing to force: the colour is already in
    -- the bake, and inventing a whole-screen grey zone would hand the
    -- shader a flat ramp to remap over the top of it
    if riding() then return originalZones(zones) end
    if mine[PaletteFX.mode or ""] then
      -- Same shape the vanilla forced modes invent: one zone covering the
      -- screen, carrying the plain DMG greys for the shader to remap.
      return { PaletteFX.whole(PaletteFX.GRAYS) }
    end
    return originalZones(zones)
  end

  -- ------- Gold: the same palettes, through the choke point Gold actually
  -- has
  --
  -- Gold is a CGB game and its colour genuinely does come from its own
  -- palettes -- that much of the reasoning this mod shipped with was right.
  -- What was wrong was concluding there is nothing to plug a palette INTO.
  -- There is: `src/render/GbcPalette.lua` is Gold's own equivalent of
  -- PaletteFX, and its module comment says outright that "every colour in
  -- the Gen 2 port arrives here" (GbcPalette.lua:16-19). `GbcPalette.resolve
  -- (colors)` is the seam -- it already has three modes of its own (GBC, the
  -- cart's colours; DMG, the grey Game Boy; CLASSIC, the DMG pea-soup ramp
  -- run through `presentColors` as a final pass), reached from Gold's own
  -- OPTION screen's COLOR row (src/ui/gen2/OptionsMenu.lua:152-159). Every
  -- consumer -- the world (src/world/gen2/World.lua), every menu, the
  -- Pokedex, the box, the party screen, battle, credits, the naming screen --
  -- calls `GbcPalette.use` / `.with` / `.color`, all of which run through
  -- `resolve`, so one wrapper here reaches every one of them the same way
  -- wrapping `effectiveColors` reaches every Gen 1 screen above.
  --
  -- `GbcPalette.setMode` only accepts an id already in `GbcPalette.MODES`
  -- (falling back to "gbc" otherwise), so appending our ids there --
  -- mirroring the PaletteFX append above, same ids and labels -- is what
  -- makes them selectable at all. `GbcPalette.mode` is a bare module field
  -- with the same identity contract PaletteFX.mode has: uninstall this mod
  -- and a save pointing at one of our ids is no longer in MODES, so
  -- `resolve` falls through untouched and the player gets GBC back, not a
  -- crash.
  --
  -- ------- what "riding" means when the whole game is already colour
  --
  -- Gen 1's ADVANCED question -- four shades or the pokered-gbc pack's
  -- eighteen -- does not need asking on Gold, because Gold never has only
  -- four. `resolve` is called with a real 4-colour palette on every one of
  -- the eight BG groups, the eight OBJ groups, each Pokemon's own two
  -- shipped colours, each trainer class's, the HP and EXP bars, the roof
  -- pair -- dozens of genuinely different palettes a frame, not one. So the
  -- same curve trick the ADVANCED path uses above is not an upgrade here,
  -- it is the ONLY sensible behaviour: recolour what each call already is,
  -- rather than flattening every one of those palettes onto the same four
  -- rungs and losing the very distinctions Gold spent eight BG groups making.
  --
  -- USE ADVANCED is read again rather than a second option, because it
  -- already asks the right question in different clothes: TINT bends each
  -- palette's own colours toward the scheme (55%, `BLEND.tint`), FULL goes
  -- all the way onto the ramp's curve, and OFF is the literal four-shade
  -- swap -- the same one DMG and CLASSIC already do for their own three
  -- modes, and the fallback for an install with no shader
  -- (`GbcPalette.available()` false) to have fallen back to before this mod
  -- existed. A player who set USE ADVANCED to OFF for the Gen 1 pack gets
  -- the plain four-shade Gold too, which is the one answer that cannot
  -- surprise them either way.
  --
  -- ------- what this does NOT reach, and why
  --
  -- The title screen and the Gold/Silver boot cinema do not call
  -- `GbcPalette.resolve` at all: `TitleState:gray()` (src/ui/gen2/
  -- TitleState.lua:183-187) answers `GbcPalette.mode ~= "gbc"` and picks
  -- between two PRE-RENDERED image sets, `screenColor` and `screenGray`,
  -- neither of which is a 4-shade texture the shader can remap. That branch
  -- already exists for DMG and CLASSIC -- a groovy mode lands on it exactly
  -- as they do, so the boot splash goes flat grey rather than picking up the
  -- scheme, then resolves normally the moment the world or a menu draws.
  -- Nothing here tries to patch that: it is the same boundary DMG and
  -- CLASSIC already live with, not a new one this mod is cutting corners on.
  if not GbcPalette._groovyPaletteOriginalResolve then
    GbcPalette._groovyPaletteOriginalResolve = GbcPalette.resolve
  end
  local originalResolve = GbcPalette._groovyPaletteOriginalResolve

  for _, p in ipairs(added) do
    local known = false
    for _, id in ipairs(GbcPalette.MODES) do
      if id == p.id then known = true; break end
    end
    if not known then
      GbcPalette.MODES[#GbcPalette.MODES + 1] = p.id
      GbcPalette.MODE_LABELS[p.id] = p.label
    end
  end

  GbcPalette.resolve = function(colors)
    local ramp = mine[GbcPalette.mode or ""]
    if not ramp then return originalResolve(colors) end
    -- A moving palette hands the frame back to DMG on purpose. `originalResolve`
    -- answers DMG_SHADES for any mode that is not "gbc", and ours is not, so
    -- the world bakes ONCE in four greys under a cache key that never moves --
    -- and the colour arrives afterwards, in `presentColors` below. Recolouring
    -- here instead would leave the baked map frozen at whatever hue it was
    -- built with while the menus carried on cycling without it.
    if moving(GbcPalette.mode) then return originalResolve(colors) end
    local how = advancedMode()
    if how == "off" or not colors then
      -- the flat swap: what DMG and CLASSIC already do for their own three
      -- modes when there is nothing (or nothing wanted) to bend toward
      return ramp
    end
    return recolorAll(colors, ramp, BLEND[how] or BLEND.tint, how == "full")
  end

  -- ------- and the pass that puts the colour back
  --
  -- CLASSIC's own trick, borrowed whole: the scene has rendered in the four
  -- DMG shades, so mapping those four to a palette is a single whole-screen
  -- zone over the finished frame. `Game2:draw` rebuilds that zone from this
  -- function every frame (src/core/Game2.lua:1384), which is precisely the
  -- per-frame read a moving palette needs and the reason it needs no hook of
  -- its own.
  --
  -- Only the moving palettes come through here. A still one has already been
  -- applied by `resolve` above, palette by palette, and a whole-screen pass on
  -- top of that would flatten the eight background groups it just took care to
  -- keep apart.
  if not GbcPalette._groovyPaletteOriginalPresent then
    GbcPalette._groovyPaletteOriginalPresent = GbcPalette.presentColors
  end
  local originalPresent = GbcPalette._groovyPaletteOriginalPresent

  GbcPalette.presentColors = function()
    if moving(GbcPalette.mode) then return ramping(GbcPalette.mode) end
    return originalPresent()
  end

-- The live palette browser.
--
-- Thirty-seven entries on a one-press ladder is a bad way to choose a
-- colour, because the OPTIONS menu is showing you a menu rather than the
-- game. This walks the same ladder with the world still on screen.
--
-- ------- how it shows the game
--
-- The state stack draws every state from the highest OPAQUE one upward, so
-- a screen that declares `isOpaque = false` leaves whatever is beneath it
-- drawing normally. Setting `PaletteFX.mode` then recolours that, because
-- colorisation happens at composite time on the finished frame -- not
-- inside the states, which know nothing about it.
--
-- So this is barely a screen at all: it moves an index, writes a module
-- field, and draws one small box. The preview is the game itself.
--
-- ------- cancelling has to actually restore
--
-- The mode is live the moment the cursor moves -- that is the whole point --
-- which means backing out has to put back both the mode AND the saved
-- option, or a cancelled browse silently becomes a choice the next time
-- anything reads save.options.colors.


local BOX_TILES_W = 20      -- the full 160px width in 8px tiles
local BOX_TILES_H = 4
local TEXT_X = 8
local TEXT_MAX = 160 - TEXT_X * 2

local function newBrowser(game)
  local Font = require("src.render.Font")

  -- Which module actually resolves the active id into colours, and which
  -- key on save.options carries it, are the only two things that differ
  -- between the generations -- everything below (the index, the box, the
  -- restore-on-cancel logic) is generation-agnostic once those are settled.
  -- PaletteFX and GbcPalette share the same shape on purpose (MODES,
  -- MODE_LABELS, mode, setMode(id)) -- see "Gold: the same palettes, through
  -- the choke point Gold actually has" above -- so one screen walks either
  -- ladder without knowing which one it is on.
  --
  -- The option key differs because the two mechanisms are different things
  -- wearing similar clothes: Gen 1's `colors` is an SGB-style whole-screen
  -- pack id (src/core/SaveData.lua), Gen 2's `color` is GbcPalette.MODES
  -- (src/core/gen2/Save.lua DEFAULT_OPTIONS), and sharing the flat key
  -- across generations would have each game quietly reinterpreting the
  -- other's save value.
  local isGen2 = game and game.save and game.save.generation == 2
  local Backend = isGen2 and require("src.render.GbcPalette")
    or require("src.render.PaletteFX")
  local optionKey = isGen2 and "color" or "colors"

  local function fit(text)
    text = tostring(text or "")
    while #text > 1 and Font.width(text) > TEXT_MAX do
      text = text:sub(1, #text - 1)
    end
    return text
  end

  -- The whole ladder, vanilla modes included: browsing should be able to
  -- walk back to GBC (or SGB, on Gen 1) as easily as it reaches AMIGA, and
  -- the engine's own modes are the ones a player is most likely to be
  -- returning to.
  local modes = {}
  for i, id in ipairs(Backend.MODES) do modes[i] = id end

  local opened = Backend.mode or "gbc"
  local index = 1
  for i, id in ipairs(modes) do
    if id == opened then index = i; break end
  end

  local self = {
    game = game,
    -- The reason this screen exists: everything below keeps drawing, so the
    -- palette is previewed on the actual game rather than on a swatch.
    isOpaque = false,
    index = index,
    opened = opened,
    openedOption = game.save and game.save.options and game.save.options[optionKey],
  }

  local function apply(id)
    Backend.setMode(id)
    -- Written as we go, not only on confirm: several parts of the engine
    -- read save.options[optionKey] rather than Backend.mode, and a preview
    -- that only half-applied would look different from the same palette
    -- chosen through OPTIONS.
    if game.save and game.save.options then game.save.options[optionKey] = id end
  end

  local function restore()
    Backend.setMode(self.opened)
    if game.save and game.save.options then
      game.save.options[optionKey] = self.openedOption
    end
  end

  function self:update()
    local input = game.input
    local n = #modes
    if n == 0 then game.stack:pop(); return end

    -- Left/right and up/down both walk the list. Left/right is the natural
    -- one: this screen is reached by pressing A on the COLORS row, which is
    -- stepped with left/right, so the hand is already there and the gesture
    -- carries on meaning the same thing.
    if input:wasPressed("left") or input:wasPressed("up") then
      self.index = self.index > 1 and self.index - 1 or n
      apply(modes[self.index])
    elseif input:wasPressed("right") or input:wasPressed("down") then
      self.index = self.index < n and self.index + 1 or 1
      apply(modes[self.index])
    elseif input:wasPressed("a") or input:wasPressed("start") then
      -- keep what is on screen; it is already applied and already saved
      game.stack:pop()
    elseif input:wasPressed("b") then
      restore()
      game.stack:pop()
    end
  end

  function self:draw()
    local id = modes[self.index]
    local label = fit(Backend.MODE_LABELS[id] or id or "?")

    -- The name and nothing else. The point of the screen is the game behind
    -- it, so every pixel of chrome is a pixel of the thing being previewed
    -- that the player cannot see -- the hint line this used to carry cost a
    -- third of the box for something you need once.
    --
    -- It cannot be bare text, though: a glyph is drawn in one shade and the
    -- world behind it is drawn in four, so over a busy map the name would
    -- be unreadable in exactly the palettes worth looking at. So it keeps a
    -- box, sized to the word rather than to the screen.
    --
    -- A box at the TOP: a Gen 1 screen puts the player and the world in the
    -- middle and lower half.
    local tiles = math.ceil(Font.width(label) / 8) + 2
    if tiles > BOX_TILES_W then tiles = BOX_TILES_W end
    Font.drawBox(0, 0, tiles, 3)
    love.graphics.setColor(0, 0, 0, 1)
    Font.draw(label, TEXT_X, 8)
  end

  return self
end

  -- ------- the live browser
  --
  -- A screen that declares isOpaque = false leaves the states beneath it
  -- drawing, and colorisation happens at composite time on the finished
  -- frame -- so moving the cursor recolours the actual game rather than a
  -- swatch. That is the whole feature; the screen itself is an index and a
  -- label box.
  --
  -- It is written inline for the same reason the palette table is: a
  -- mod-relative `require` does not resolve. modkit VALIDATES clean either
  -- way, because the screen factory is never called during validation --
  -- the failure only appears when a player opens the screen, which is the
  -- worst possible time to find it.

  local browserOn = true
  do
    local ok, value = pcall(function() return mod.options:get("browser") end)
    browserOn = (not ok) or (value ~= false)
  end

  if browserOn then
    local SCREEN = "GroovyPaletteBrowser"
    -- ------- which generation is running
    --
    -- Off the live game, never a version allow-list -- see "Gold: the same
    -- palettes, through the choke point Gold actually has" above for why
    -- this browser has something to preview there too. What still differs
    -- per generation is cosmetic: which row on OPTION carries `activate`,
    -- because the two screens spell the row differently (Gen 1's is
    -- "colors", Gen 2's "color" -- src/ui/gen2/OptionsMenu.lua:152). The
    -- browser screen itself (`newBrowser`) figures out which backend to
    -- drive by reading `game.save.generation`, same as this does.
    local function isGen2(game)
      local save = game and game.save
      return save ~= nil and save.generation == 2
    end

    mod.content.screens:register(SCREEN, { new = function(game)
      return newBrowser(game)
    end })

    mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
      local out = next(game, items)
      if type(out) ~= "table" then return out end
      return mod.ui.insertBefore(out, "SAVE", {
        label = "PALETTE",
        onSelect = function() mod.ui.push(game, SCREEN) end,
      })
    end)

    -- ------- and from the COLORS/COLOR row itself, which is where you
    -- already are
    --
    -- Choosing a colour from a menu that is covering the game is choosing it
    -- blind, and OPTION -> COLORS (Gen 1) or OPTION -> COLOR (Gen 2) is
    -- exactly where a player goes to do it. An options row descriptor may
    -- carry `activate = fn(game)`, which both generations' OptionsMenu call
    -- on A (src/ui/OptionsMenu.lua and src/ui/gen2/OptionsMenu.lua:315-321,
    -- "if row.activate ... elseif input:wasPressed('a')"), and the rows run
    -- through this hook before either menu is built. So the row keeps
    -- stepping with left/right as it always did, and A now lifts the menu
    -- off the game instead.
    --
    -- Attached to the row the ENGINE calls "colors" (Gen 1) or "color"
    -- (Gen 2) rather than to one of ours, because that is the row the
    -- player is on. Left alone if a future engine renames it, or if another
    -- mod got there first and gave it an activate of its own.
    mod.hooks:wrap("ui.options.rows", function(next, game, rows)
      local out = next(game, rows)
      if type(out) ~= "table" then return out end
      local wantId = isGen2(game) and "color" or "colors"
      for _, row in ipairs(out) do
        if row.id == wantId and row.activate == nil then
          row.activate = function(g) mod.ui.push(g or game, SCREEN) end
        end
      end
      return out
    end)
  end

  -- ------- the frames
  --
  -- A box's border is not a texture, it is six FONT GLYPHS. Font.BORDER
  -- names them (tl h tr v bl br) and Font.drawBox reads that table fresh on
  -- every call, and the engine's own comment says the table "stays writable
  -- so a mod can retheme one corner without shipping a whole page". So a
  -- frame is a matter of pointing six entries somewhere else.
  --
  -- Somewhere else is our own glyph page: eight frames x six glyphs on one
  -- 48x64 sheet, registered at 0x200. Every pixel of it is generated by
  -- tools/make_frames.py from rules written out in that file -- no ROM, no
  -- cartridge dump, and not a pixel of the engine's font sheets either.
  --
  -- Written to BOTH Font.BORDER and data.font.border. The first is what the
  -- next drawBox reads, so a change shows immediately; the second is what
  -- Font.load rebuilds the table from, so the choice survives the reload
  -- that Assets fires when a sheet is touched.

  local FRAME_BASE = 0x200
  local FRAME_ORDER = { "thin", "double", "triple", "thick",
                        "wide", "dash", "beads", "track" }
  local FRAME_SLOTS = { "tl", "h", "tr", "v", "bl", "br" }

  mod.content.font:register("groovy_frames", {
    image = mod.assets:path("assets/frames.png"),
    base = FRAME_BASE,
    glyphsPerRow = #FRAME_SLOTS,
  })

  local Font = require("src.render.Font")

  local function frameCodes(id)
    for index, name in ipairs(FRAME_ORDER) do
      if name == id then
        local codes = {}
        for slot, key in ipairs(FRAME_SLOTS) do
          codes[key] = FRAME_BASE + (index - 1) * #FRAME_SLOTS + (slot - 1)
        end
        return codes
      end
    end
    return nil -- "gb", or an id from a future version this one does not know
  end

  -- Point the six slots at one of our frames, or hand them back to the
  -- engine. The `data.font.border` half is what survives the reload Assets
  -- fires when a sheet is touched; Font.BORDER is what the next drawBox reads.
  local function useCodes(codes)
    -- the loader's merge target is the engine's Data, which is also what
    -- Font.load reads; there is no mod.data to prefer
    local data = require("src.core.Data")
    if not codes then
      -- back to the engine's own six
      for key, code in pairs(Font.DEFAULT_BORDER) do Font.BORDER[key] = code end
      if data and data.font then data.font.border = nil end
      return
    end
    for key, code in pairs(codes) do Font.BORDER[key] = code end
    if data and data.font then data.font.border = codes end
  end

  -- ------- Gold already has this row, so do not build a second one
  --
  -- 0.6.0 put these frames on Gold by pointing Font.BORDER at our page, which
  -- works -- but Gold is not Gen 1 here: it ships its OWN eight frames and its
  -- own OPTION -> FRAME row to pick between them (src/ui/gen2/OptionsMenu.lua
  -- :81, and the ladder at :344-350). Overriding Font.BORDER wins over that
  -- row silently, because the codes it answers with ($79-$7e) are the only
  -- ones `pageFor` sends to the frame sheet (src/render/Font.lua:245-250) and
  -- ours are not among them. The player got two frame settings, one of which
  -- quietly did nothing.
  --
  -- So on Gold this mod stops carrying its own frame setting and EXTENDS
  -- Gold's instead: the row runs 1..16 now, its own eight first, then these
  -- eight. `row.step` is checked before `row.frame` in the menu's own cycle
  -- (OptionsMenu.lua:331-336), so attaching one takes the ladder over without
  -- touching the engine; `game.options` is the same table the menu is holding
  -- (Game2:showOptions passes `options = self.options` by reference), so the
  -- number the row prints follows along.
  --
  -- Uninstalling with 9..16 saved is safe: `Font.setFrame(12)` finds no such
  -- page and `pageFor` falls through to the ordinary font pages, which answer
  -- $79-$7e with the cart's own frame 1. A stale value degrades to a working
  -- border, not to a missing one.
  local GOLD_FRAMES = 8

  local function applyGoldFrame(index)
    index = math.floor(tonumber(index) or 1)
    if index < 1 or index > GOLD_FRAMES + #FRAME_ORDER then index = 1 end
    if index <= GOLD_FRAMES then
      useCodes(nil)
      Font.setFrame(index)
    else
      useCodes(frameCodes(FRAME_ORDER[index - GOLD_FRAMES]))
      -- Gold's own sheet is no longer being asked for, but leave the index
      -- somewhere legal: a later uninstall reads it back.
      Font.setFrame(1)
    end
  end

  -- Which generation is running, learned from the live game rather than
  -- guessed. Nil until game.ready, which is also the first moment either
  -- branch below has anything to apply.
  local gen2Game = nil

  local function applyFrame()
    if gen2Game then
      applyGoldFrame(gen2Game.options and gen2Game.options.frame or 1)
      return
    end
    local ok, id = pcall(function() return mod.options:get("frame") end)
    useCodes(ok and frameCodes(id) or nil)
  end

  -- The ladder itself. Its own wrap rather than a branch inside the browser's
  -- (further up), because the frames are not the browser's business and the
  -- PREVIEW switch must not take Gold's frame row away with it.
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    local save = game and game.save
    if not (save and save.generation == 2) then return out end
    for _, row in ipairs(out) do
      -- `frame = true` rather than an id: Gold's row carries no id at all
      -- (OptionsMenu.lua:81), and `key` is what it writes, not what it is.
      if row.frame and row.step == nil then
        row.step = function(g, delta)
          local options = (g and g.options) or (game and game.options)
          local total = GOLD_FRAMES + #FRAME_ORDER
          local index = ((options and options.frame or 1) - 1 + delta) % total + 1
          if options then options.frame = index end
          applyGoldFrame(index)
        end
      end
    end
    return out
  end)

  mod.exports.applyFrame = applyFrame
  mod.exports.frameCodes = frameCodes
  mod.exports.applyGoldFrame = applyGoldFrame
  mod.exports.goldFrameCount = GOLD_FRAMES + #FRAME_ORDER

  -- The page has to be merged and the font loaded before the codes resolve,
  -- so the first apply waits for the game rather than running at load time.
  mod.events:on("game.ready", function(ev)
    local game = ev and ev.game
    if game and game.save and game.save.generation == 2 then
      gen2Game = game
    end
    applyFrame()
  end)

  -- ...and again whenever the row moves. Without this the border only
  -- changed on the next boot: Font.drawBox does read Font.BORDER fresh on
  -- every call, so the change is instant once something writes it -- but
  -- nothing did. ManagerState:setOption emits this after storing the value,
  -- which is the moment to write it.
  mod.events:on("mod.options_changed", function(ev)
    if ev and ev.mod == "groovy_palette" and ev.key == "frame" then
      applyFrame()
    end
  end)

  applyFrame()

  -- ------- and a box that is not white with a black edge
  --
  -- On Gen 1 a text box has always taken the scheme, without this mod doing
  -- anything: the whole UI canvas goes through the shade-remap shader, so the
  -- box's white paper comes out as rung 1 and its black border as rung 4.
  -- Gold's boxes do not, and that is the plain white box with the plain black
  -- edge sitting on top of an OCEAN or a CHERRY overworld.
  --
  -- The reason is narrow. Gold colours text by handing a palette to the
  -- shader around the draw -- `Chrome.printThrough` does exactly that, and it
  -- reaches this mod already because it resolves through `GbcPalette.resolve`
  -- (src/ui/gen2/Chrome.lua:121-124). But the BOX is not drawn that way:
  -- `Chrome.box` calls `Font.drawBox` straight (Chrome.lua:81-84), which fills
  -- a white rectangle and blits six black glyphs with no shader bound at all.
  -- No palette is consulted, so no palette can reach it.
  --
  -- Binding one is the whole fix, and it is the same call Chrome already
  -- makes: white is shade 0 and the border ink is shade 3, so a palette sent
  -- through `useRaw` lands the paper on rung 1 and the border on rung 4 -- the
  -- identical mapping Gen 1 gets from its own shader, arrived at from the
  -- other side.
  --
  -- Two cases stay out. A moving palette (RAINBOW, ACID) is coloured by the
  -- whole-screen present pass instead, and colouring the box here as well
  -- would hand that pass a box that is no longer four greys -- so it is left
  -- grey and picks up the cycle with everything else. And on Gen 1
  -- `GbcPalette.mode` is never one of ours, so `ramping` answers nil and this
  -- wrapper costs one table lookup per box and changes nothing.
  local function boxPalette()
    if moving(GbcPalette.mode) then return nil end
    local ramp = ramping(GbcPalette.mode)
    if not ramp then return nil end
    if not GbcPalette.available() then return nil end
    return ramp
  end

  if not Font._groovyPaletteOriginalDrawBox then
    Font._groovyPaletteOriginalDrawBox = Font.drawBox
  end
  local originalDrawBox = Font._groovyPaletteOriginalDrawBox

  Font.drawBox = function(tx, ty, tw, th, fill)
    local ok, pal = pcall(boxPalette)
    if not (ok and pal) then return originalDrawBox(tx, ty, tw, th, fill) end
    -- Restore rather than clear: a caller mid-draw may have had its own
    -- shader bound, and Chrome puts one back the same way (Chrome.lua:142-145).
    local previous = love.graphics.getShader()
    GbcPalette.useRaw(pal)
    originalDrawBox(tx, ty, tw, th, fill)
    love.graphics.setShader(previous)
  end

  -- Read by another mod through mod.find("groovy_palette").exports.
  mod.exports.palettes = function()
    local out = {}
    for _, p in ipairs(added) do
      out[#out + 1] = { id = p.id, label = p.label,
                        colors = p.colors, motion = p.motion }
    end
    return out
  end

  -- The animation as a pure function of time, so the suite can walk a whole
  -- turn of the wheel and assert the ramp stays legal at every step rather
  -- than sampling whatever second it happened to run in.
  mod.exports.animate = animate
  mod.exports.recolor = recolor
end
