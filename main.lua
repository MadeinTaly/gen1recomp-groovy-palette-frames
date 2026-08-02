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
    -- The browser is the point of having thirty of these: choosing a colour
    -- from a menu that is covering the game is choosing it blind. Off puts
    -- the mod back to being nothing but extra rungs on the OPTIONS row.
    { key = "browser", label = "START MENU", type = "toggle", default = true },
    -- See "riding ADVANCED" below. OFF is what 0.2.0 did.
    { key = "advanced", label = "USE ADVANCED", type = "choice", default = "tint",
      choices = {
        { "TINT", "tint" },
        { "FULL", "full" },
        { "OFF", "off" },
      } },
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

  local function recolor(c, ramp, amount)
    local r, g, b = rampAt(ramp, luminance(c))
    return {
      clamp255(c[1] + (r - c[1]) * amount),
      clamp255(c[2] + (g - c[2]) * amount),
      clamp255(c[3] + (b - c[3]) * amount),
    }
  end

  local function recolorAll(colors, ramp, amount)
    local out = {}
    for i, c in ipairs(colors) do out[i] = recolor(c, ramp, amount) end
    return out
  end

  -- The active ramp, but only while a Groovy palette is selected AND the
  -- option asks for it. Returns nil the rest of the time, which is what
  -- every wrapper below tests to decide whether to stay out of the way.
  local function riding()
    local ramp = mine[PaletteFX.mode or ""]
    if not ramp then return nil end
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
    local ramp, amount = riding()
    if not (groups and ramp) then return groups end
    local out = {}
    for i, palette in ipairs(groups) do
      out[i] = recolorAll(palette, ramp, amount)
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
    local ramp, amount = riding()
    if not (colors and ramp) then return colors, group end
    return recolorAll(colors, ramp, amount), group
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
    local ramp, amount = riding()
    if ramp then
      if not c then return originalColors(c) end
      return originalColors(recolorAll(c, ramp, amount))
    end
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
  local PaletteFX = require("src.render.PaletteFX")
  local Strings = require("src.core.Strings")

  local function fit(text)
    text = tostring(text or "")
    while #text > 1 and Font.width(text) > TEXT_MAX do
      text = text:sub(1, #text - 1)
    end
    return text
  end

  -- The whole ladder, vanilla modes included: browsing should be able to
  -- walk back to SGB as easily as it reaches AMIGA, and the engine's own
  -- seven are the ones a player is most likely to be returning to.
  local modes = {}
  for i, id in ipairs(PaletteFX.MODES) do modes[i] = id end

  local opened = PaletteFX.mode or "gbc"
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
    openedOption = game.save and game.save.options and game.save.options.colors,
  }

  local function apply(id)
    PaletteFX.setMode(id)
    -- Written as we go, not only on confirm: several parts of the engine
    -- read save.options.colors rather than PaletteFX.mode, and a preview
    -- that only half-applied would look different from the same palette
    -- chosen through OPTIONS.
    if game.save and game.save.options then game.save.options.colors = id end
  end

  local function restore()
    PaletteFX.setMode(self.opened)
    if game.save and game.save.options then
      game.save.options.colors = self.openedOption
    end
  end

  function self:update()
    local input = game.input
    local n = #modes
    if n == 0 then game.stack:pop(); return end

    if input:wasPressed("up") then
      self.index = self.index > 1 and self.index - 1 or n
      apply(modes[self.index])
    elseif input:wasPressed("down") then
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
    local label = PaletteFX.MODE_LABELS[id] or id or "?"

    -- A box at the TOP: the player is looking at the world, and the world
    -- is mostly in the middle and lower half of a Gen 1 screen.
    Font.drawBox(0, 0, BOX_TILES_W, BOX_TILES_H)
    love.graphics.setColor(0, 0, 0, 1)
    Font.draw(fit(Strings("%s  %d/%d", label, self.index, #modes)), TEXT_X, 8)
    Font.draw(fit(Strings("A:KEEP B:CANCEL")), TEXT_X, 18)
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

  local function applyFrame()
    local ok, id = pcall(function() return mod.options:get("frame") end)
    local codes = ok and frameCodes(id) or nil
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

  mod.exports.applyFrame = applyFrame
  mod.exports.frameCodes = frameCodes

  -- The page has to be merged and the font loaded before the codes resolve,
  -- so the first apply waits for the game rather than running at load time.
  mod.events:on("game.ready", applyFrame)

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

  -- Read by another mod through mod.find("groovy_palette").exports.
  mod.exports.palettes = function()
    local out = {}
    for _, p in ipairs(added) do
      out[#out + 1] = { id = p.id, label = p.label, colors = p.colors }
    end
    return out
  end
end
