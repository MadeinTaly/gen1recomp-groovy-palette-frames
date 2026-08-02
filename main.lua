-- Groovy Palette
--
-- Thirty more entries on the COLORS row: Amiga Workbench, the C64 boot
-- screen, a Virtual Boy, and a pile of colour ideas the Game Boy never had.
--
-- ------- where these plug in
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
-- The palette table lives in this file rather than a data/ module on
-- purpose. modkit runs the validating loader with its cwd at the ENGINE
-- root, so `require("data.palettes")` searches the engine's data directory
-- and not the mod's -- a mod-relative require is not a thing the loader
-- provides. One file has no such question to answer.
--
-- ------- turning the mod off
--
-- A save keeps the mode id. Disable this mod and the id is no longer in
-- MODES, `effectiveColors` falls through its if-chain and returns the map's
-- own colours untouched -- which is SGB, the default. The player loses the
-- palette, never the game.

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
    -- Same four colours, ordered by brightness.
    colors = { {170,170,170}, {255,136,0}, {0,85,170}, {0,0,0} } },

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
    -- Palette 1 high intensity: white, cyan, magenta, black.
    colors = { {255,255,255}, {85,255,255}, {255,85,255}, {0,0,0} } },

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

  { id = "rainbow", label = "RAINBOW",
    -- Four shades cannot be a spectrum, so this walks the hue wheel while
    -- brightness falls: yellow, orange-pink, violet, indigo. It reads as a
    -- rainbow because the hue moves, not because six colours are present.
    colors = { {255,241,120}, {255,120,150}, {150,70,200}, {30,20,80} } },

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
    colors = { {245,225,255}, {120,220,235}, {200,80,180}, {45,20,70} } },

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
  })

  local function wanted()
    local ok, value = pcall(function() return mod.options:get("packs") end)
    return ok and value or "all"
  end

  local PaletteFX = require("src.render.PaletteFX")

  -- Which ids this mod owns, and the colours behind each. Built once: MODES
  -- is read every time the option row moves, so it has to be a stable array
  -- rather than something recomputed under the cursor.
  local mine, added = {}, {}
  local pick = wanted()
  for _, p in ipairs(PALETTES) do
    local isRetro = RETRO[p.id] and true or false
    local take = pick == "all"
                 or (pick == "retro" and isRetro)
                 or (pick == "colour" and not isRetro)
    if take then
      mine[p.id] = p.colors
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

  -- ------- effectiveColors: substitute our four, then let the original run
  --
  -- Calling through rather than returning early matters: the original applies
  -- the shade map LAST -- rBGP is a hardware register write, so a dark cave
  -- has to read dark in these palettes exactly as it does in CLASSIC's pea
  -- greens. Handing it our colours as its input keeps that composition.
  if not PaletteFX._groovyPaletteOriginalColors then
    PaletteFX._groovyPaletteOriginalColors = PaletteFX.effectiveColors
  end
  local originalColors = PaletteFX._groovyPaletteOriginalColors

  PaletteFX.effectiveColors = function(c)
    local swap = mine[PaletteFX.mode or ""]
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
    if mine[PaletteFX.mode or ""] then
      -- Same shape the vanilla forced modes invent: one zone covering the
      -- screen, carrying the plain DMG greys for the shader to remap.
      return { PaletteFX.whole(PaletteFX.GRAYS) }
    end
    return originalZones(zones)
  end

  -- Read by another mod through mod.find("groovy_palette").exports.
  mod.exports.palettes = function()
    local out = {}
    for _, p in ipairs(added) do
      out[#out + 1] = { id = p.id, label = p.label, colors = p.colors }
    end
    return out
  end
end
