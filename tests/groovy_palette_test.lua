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

-- ------- the second pass: START MENU = off
--
-- Spawned by the main pass at the bottom of this file, because a mod can
-- only be loaded once per process (see the note there). It checks that
-- turning the browser off removes BOTH halves of it and leaves the palettes
-- -- the switch is meant to restore the pre-browser behaviour, not disable
-- the mod.
if os.getenv("GROOVY_PALETTE_BROWSER_OFF") then
  local SaveData = require("src.core.SaveData")
  local realLoadOptions = SaveData.loadOptions
  SaveData.loadOptions = function(fs)
    local opts = realLoadOptions(fs)
    opts.modOptions = opts.modOptions or {}
    opts.modOptions.groovy_palette = { browser = false }
    return opts
  end
  local off = T.sdk.loadMod(DIR, { data = Data })
  SaveData.loadOptions = realLoadOptions

  T.eq(#off.errors, 0, "loads clean with the browser off")
  T.check(Data.screens == nil or Data.screens.GroovyPaletteBrowser == nil,
    "START MENU off registers no screen")

  local items = require("src.mods.Runtime").call("ui.start_menu.items",
    function(_, i) return i end, {}, { { label = "POKéDEX" }, { label = "SAVE" } })
  local still = false
  for _, e in ipairs(items) do if e.label == "PALETTE" then still = true end end
  T.check(not still, "and adds no start menu row")

  T.check(#off.loader.exports.groovy_palette.palettes() >= 25,
    "but the palettes stay -- the switch is the browser, not the mod")
  off.release()
  T.finish("groovy_palette (START MENU off)")
  return
end

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

-- ------- the live browser
--
-- The point of the screen is that it is NOT opaque: the states beneath keep
-- drawing, colorisation runs at composite time on the finished frame, and
-- so moving the cursor recolours the actual game rather than a swatch.

local Runtime = require("src.mods.Runtime")
local factory = Data.screens and Data.screens.GroovyPaletteBrowser
T.check(factory ~= nil, "the browser screen is registered")

-- it is reachable from the start menu
local startOut = Runtime.call("ui.start_menu.items", function(_, i) return i end,
  {}, { { label = "POKéDEX" }, { label = "SAVE" } })
local row
for _, e in ipairs(startOut) do if e.label == "PALETTE" then row = e end end
T.check(row ~= nil, "a PALETTE row is added to the start menu")

-- and selecting it must reach the screen. The row could carry a wrong id or
-- a wrong push and the assertion above would still pass, which is the same
-- class of hole as a registered screen that never opens.
do
  local Screens = require("src.ui.Screens")
  local pushed
  local realPush = Screens.push
  Screens.push = function(_, id) pushed = id end
  pcall(row.onSelect)
  Screens.push = realPush
  T.eq(pushed, "GroovyPaletteBrowser", "and selecting it opens the browser")
end

PaletteFX.setMode("gbc")
local pressed, closed = {}, false
local game = {
  data = Data,
  save = { options = { colors = "gbc" } },
  stack = { pop = function() closed = true end },
  input = { wasPressed = function(_, k) return pressed[k] end },
}

local browser = factory.new(game)
T.eq(browser.isOpaque, false, "the screen is NOT opaque, so the game draws behind it")

-- scrolling applies live, and writes the option as it goes: several parts of
-- the engine read save.options.colors rather than PaletteFX.mode
pressed = { down = true }; browser:update()
T.check(PaletteFX.mode ~= "gbc", "moving the cursor changes the live palette")
T.eq(game.save.options.colors, PaletteFX.mode, "and the saved option follows it")
local previewed = PaletteFX.mode

-- B restores BOTH, or a cancelled browse silently becomes a choice
pressed = { b = true }; browser:update()
T.eq(PaletteFX.mode, "gbc", "B restores the palette that was active on entry")
T.eq(game.save.options.colors, "gbc", "and the saved option with it")
T.check(closed, "and closes")

-- A keeps what is on screen
PaletteFX.setMode("gbc")
game.save.options.colors = "gbc"
closed = false
browser = factory.new(game)
pressed = { down = true }; browser:update()
pressed = { a = true }; browser:update()
T.eq(PaletteFX.mode, previewed, "A keeps the previewed palette")
T.eq(game.save.options.colors, previewed, "and leaves it saved")
T.check(closed, "and closes")

-- the label box must fit the 160px screen, in the worst case
local Font = require("src.render.Font"); Font.load(Data)
local realDraw, realBox = Font.draw, Font.drawBox
local widest, worst = 0, ""
Font.draw = function(text, x)
  local w = x + Font.width(text)
  if w > widest then widest, worst = w, text end
end
Font.drawBox = function() end
PaletteFX.setMode(PaletteFX.MODES[#PaletteFX.MODES])
browser = factory.new(game)
browser:draw()
browser.index = #PaletteFX.MODES
browser:draw()
Font.draw, Font.drawBox = realDraw, realBox
T.check(widest <= 160,
  ("the browser box fits the screen (widest %d: %q)"):format(widest, worst))

PaletteFX.mode = before
run.release()

-- ------- START MENU = off puts it back exactly as it was
--
-- Half the request was the switch, and an option nothing asserts is an
-- option that can quietly stop working.
--
-- This needs a SECOND process, not a second loadMod. The loader's Builtins
-- pass registers vanilla content into the data target, and Data.statuses is
-- empty until it does -- so a second load in the same process finds the five
-- statuses the first one created and dies with "already registered: FRZ".
-- One mod load per process is the harness's real contract.
--
-- So the suite re-runs itself with the option forced off and fails if that
-- child fails. One command still covers both halves.

if not os.getenv("GROOVY_PALETTE_BROWSER_OFF") then
  local cmd = ("GROOVY_PALETTE_BROWSER_OFF=1 GROOVY_PALETTE_DIR=%q luajit %q")
    :format(DIR, arg and arg[0] or "mods/groovy_palette/tests/groovy_palette_test.lua")
  local ok = os.execute(cmd .. " >/dev/null 2>&1")
  T.check(ok == true or ok == 0,
    "START MENU off: the second pass passes (re-run with "
    .. "GROOVY_PALETTE_BROWSER_OFF=1 to see it)")
end

T.finish("groovy_palette")
