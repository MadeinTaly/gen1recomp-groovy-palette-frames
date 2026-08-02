-- Standalone: luajit mods/groovy_palette/tests/groovy_palette_test.lua
--
-- The palettes are checked by arithmetic rather than by eye. Thirty of them
-- is far past what anyone will look at carefully, and the failure mode is
-- not "slightly ugly" -- a ramp that does not fall in brightness renders the
-- game inside out, because Game Boy shading IS the brightness order.
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

local PaletteFX = require("src.render.PaletteFX")
local vanillaModes = #PaletteFX.MODES

local DIR = os.getenv("GROOVY_PALETTE_DIR") or "mods/groovy_palette"
local run = T.sdk.loadMod(DIR, { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local exports = run.loader.exports.groovy_palette
T.check(type(exports.palettes) == "function", "the palette list is exported")
local list = exports.palettes()
T.check(#list >= 25, ("ships %d palettes (asked for 25+)"):format(#list))

-- ------- every palette must be a legal Game Boy ramp

local function luminance(c)
  return 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3]
end

local seen, broken, flat, wide, longLabel = {}, {}, {}, 0, {}
for _, p in ipairs(list) do
  if seen[p.id] then broken[#broken + 1] = "duplicate id " .. p.id end
  seen[p.id] = true

  if #p.colors ~= 4 then
    broken[#broken + 1] = p.id .. " has " .. #p.colors .. " colours"
  else
    local previous
    for _, c in ipairs(p.colors) do
      if #c ~= 3 then broken[#broken + 1] = p.id .. " has a bad triple" end
      for _, channel in ipairs(c) do
        if channel < 0 or channel > 255 then
          broken[#broken + 1] = p.id .. " channel out of 0..255"
        end
      end
      local L = luminance(c)
      -- STRICTLY falling: two rungs of equal brightness collapse two Game Boy
      -- shades into one and lose a quarter of the picture's detail.
      if previous and L >= previous then
        broken[#broken + 1] = ("%s is not ordered light to dark"):format(p.id)
      end
      previous = L
    end
    local span = luminance(p.colors[1]) - luminance(p.colors[4])
    if span < 120 then
      flat[#flat + 1] = ("%s (span %d)"):format(p.id, span)
    end
  end

  -- The OPTIONS row draws this value beside its label, and every glyph
  -- advances 8 pixels on a 160-wide screen.
  if #p.label > 8 then longLabel[#longLabel + 1] = p.label end
end

T.eq(#broken, 0, "every palette is a legal ramp (" .. table.concat(broken, "; ") .. ")")
T.eq(#flat, 0, "every palette has usable contrast (" .. table.concat(flat, "; ") .. ")")
T.eq(#longLabel, 0, "every label fits 8 glyphs (" .. table.concat(longLabel, ",") .. ")")

-- ------- the engine actually offers them

T.eq(#PaletteFX.MODES, vanillaModes + #list,
  "every palette was appended to the COLORS ladder")
for i = 1, vanillaModes do
  T.check(PaletteFX.MODES[i] ~= nil, "vanilla mode " .. i .. " kept its position")
end
T.eq(PaletteFX.MODES[1], "ogred", "the vanilla ladder still starts where it did")

local sample = list[1]
T.eq(PaletteFX.MODE_LABELS[sample.id], sample.label, "and each carries its label")

-- ------- selecting one actually changes the colours

local before = PaletteFX.mode
PaletteFX.mode = sample.id
local got = PaletteFX.effectiveColors(PaletteFX.GRAYS)
T.eq(got[1][1], sample.colors[1][1], "the active palette replaces the zone colours")
T.eq(got[4][3], sample.colors[4][3], "including the darkest rung")

-- A forced palette needs a surface to be forced onto: a screen exposing no
-- SGB zones gets a whole-screen one invented, exactly as CLASSIC does. Miss
-- this and the palette silently does nothing on those screens.
local zones = PaletteFX.ensureZones(nil)
T.check(zones and zones[1] ~= nil, "a whole-screen zone is invented for our modes")

-- an unknown mode must fall through untouched: that is what a player sees
-- after disabling this mod with one of its palettes saved
PaletteFX.mode = "a_mode_no_longer_installed"
local fallback = PaletteFX.effectiveColors(PaletteFX.GRAYS)
T.eq(fallback[1][1], PaletteFX.GRAYS[1][1],
  "an uninstalled palette id degrades to the map's own colours")

PaletteFX.mode = before
run.release()
T.finish("groovy_palette")
