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
    opts.modOptions.groovy_palette = { browser = false, advanced = "off" }
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

  local colorsRow = { id = "colors", label = "COLORS" }
  require("src.mods.Runtime").call("ui.options.rows",
    function(_, r) return r end, {}, { colorsRow })
  T.check(colorsRow.activate == nil,
    "and leaves the COLORS row exactly as the engine built it")

  T.check(#off.loader.exports.groovy_palette.palettes() >= 25,
    "but the palettes stay -- the switch is the browser, not the mod")

  -- USE ADVANCED = OFF restores the four-shade behaviour of 0.2.0: the
  -- palette replaces ADVANCED rather than riding it
  do
    local first = off.loader.exports.groovy_palette.palettes()[1]
    PaletteFX.setMode(first.id)
    T.check(not PaletteFX.usesGbcPack(),
      "USE ADVANCED off keeps a Groovy palette off the per-tile path")
    -- A forced palette needs a surface to be forced onto: a screen exposing
    -- no SGB zones gets a whole-screen one invented, exactly as CLASSIC
    -- does. Miss this and the palette silently does nothing there.
    local zones = PaletteFX.ensureZones(nil)
    T.check(zones and zones[1] ~= nil,
      "and it forces a whole-screen zone again, as a four-shade mode must")
    T.eq(PaletteFX.darkKey(), "",
      "and bakes under the engine's own cache key")

    -- the exact substitution 0.1.0 shipped, which is what OFF restores
    local got4 = PaletteFX.effectiveColors(PaletteFX.GRAYS)
    T.eq(got4[1][1], first.colors[1][1], "the palette replaces the zone colours outright")
    T.eq(got4[4][3], first.colors[4][3], "including the darkest rung")
  end

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

-- What "changes the colours" means depends on which path the palette is
-- on, and that is the point of USE ADVANCED. Riding ADVANCED (the default,
-- when the pack is present) the greys are pulled TOWARD the palette rather
-- than replaced by it -- replacing them is what throws the variety away.
-- The exact-substitution assertions live in the four-shade pass at the
-- bottom of this file, which is where that behaviour now is.
if PaletteFX.gbcPack() then
  T.check(got[1][1] ~= PaletteFX.GRAYS[1][1] or got[1][2] ~= PaletteFX.GRAYS[1][2],
    "the active palette moves the zone colours off the DMG greys")
  local toward = math.abs(got[1][1] - sample.colors[1][1])
                 < math.abs(PaletteFX.GRAYS[1][1] - sample.colors[1][1])
  T.check(toward or got[1][1] == sample.colors[1][1],
    "and moves them toward the palette, not somewhere else")
else
  T.eq(got[1][1], sample.colors[1][1], "the active palette replaces the zone colours")
  T.eq(got[4][3], sample.colors[4][3], "including the darkest rung")
end

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

-- ------- and from the COLORS row, which is where a player actually is
--
-- An options row may carry activate = fn(game), which OptionsMenu calls on
-- A. The engine's own COLORS row has none, so pressing A there did nothing
-- -- and choosing a colour from a menu covering the game is choosing it
-- blind. This attaches one.
do
  local Screens = require("src.ui.Screens")
  local colorsRow = { id = "colors", label = "COLORS",
                      step = function() return true end }
  local otherRow = { id = "tilt", label = "TILT" }
  local out = Runtime.call("ui.options.rows", function(_, r) return r end,
    {}, { colorsRow, otherRow })

  T.check(type(colorsRow.activate) == "function",
    "the COLORS row gains an activate, so A does something there")
  T.check(otherRow.activate == nil, "and no other row is touched")
  T.check(colorsRow.step ~= nil, "while COLORS still steps with left/right")

  local pushed
  local realPush = Screens.push
  Screens.push = function(_, id) pushed = id end
  pcall(colorsRow.activate, {})
  Screens.push = realPush
  T.eq(pushed, "GroovyPaletteBrowser", "and A opens the preview")

  -- a row another mod already claimed is left alone
  local taken = { id = "colors", activate = function() end }
  local mine = taken.activate
  Runtime.call("ui.options.rows", function(_, r) return r end, {}, { taken })
  T.check(taken.activate == mine, "an activate another mod set is not stolen")
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

-- left/right is what the player asked for and what the COLORS row uses, so
-- it has to walk the list too -- and in the same directions
-- self-contained: it drives the palette as a side effect, and the
-- assertions after this one depend on where the one above left it
do
  local wasMode = PaletteFX.mode
  local wasOption = game.save.options.colors

  local probe = factory.new(game)
  local start = probe.index
  pressed = { right = true }; probe:update()
  local afterRight = probe.index
  pressed = { left = true }; probe:update()
  T.check(afterRight ~= start, "RIGHT walks the list")
  T.eq(probe.index, start, "and LEFT walks back the same step")
  pressed = { down = true }; probe:update()
  T.eq(probe.index, afterRight, "DOWN still agrees with RIGHT")

  PaletteFX.setMode(wasMode)
  game.save.options.colors = wasOption
end
pressed = { down = true }
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

-- ------- riding ADVANCED
--
-- The whole point of the option: a Groovy palette used to REPLACE the
-- richest colorization the engine has with four shades. These assert it
-- now rides it instead -- and count the colours, because "it looks more
-- colourful" is not something a test can be trusted to feel.

do
  local pack = PaletteFX.gbcPack()
  if not pack then
    T.check(true, "no pokered-gbc pack here, ADVANCED checks skipped")
  else
    local tileset = next(pack.world.groupColors)
    local groovy = exports.palettes()[1].id

    local function distinct(groups)
      local seen, n = {}, 0
      for _, palette in ipairs(groups) do
        for _, c in ipairs(palette) do
          local k = ("%d,%d,%d"):format(c[1], c[2], c[3])
          if not seen[k] then seen[k] = true; n = n + 1 end
        end
      end
      return n
    end

    -- the baseline ADVANCED itself resolves
    PaletteFX.setMode("redpp")
    local vanilla = PaletteFX.worldGroupColors(Data, tileset, nil, nil)
    T.check(vanilla ~= nil and #vanilla == 8,
      "ADVANCED resolves eight background palettes at once")
    local vanillaCount = distinct(vanilla)
    T.check(vanillaCount > 4,
      ("and more than four colours in them (%d)"):format(vanillaCount))

    -- a Groovy palette must now take that same path...
    PaletteFX.setMode(groovy)
    T.check(PaletteFX.usesGbcPack(),
      "a Groovy palette takes the ADVANCED path while USE ADVANCED is on")

    -- ...and keep the variety rather than flattening it to four
    local ridden = PaletteFX.worldGroupColors(Data, tileset, nil, nil)
    T.eq(#ridden, 8, "still eight palettes")
    local riddenCount = distinct(ridden)
    T.check(riddenCount > 4,
      ("the palette keeps ADVANCED's variety (%d colours, not 4)"):format(riddenCount))

    -- and it must actually be RECOLOURED, not passed through untouched
    local changed = false
    for i, palette in ipairs(ridden) do
      for j, c in ipairs(palette) do
        local v = vanilla[i][j]
        if c[1] ~= v[1] or c[2] ~= v[2] or c[3] ~= v[3] then changed = true end
      end
    end
    T.check(changed, "and it is recoloured, not merely passed through")

    -- the bake cache must not serve one palette's atlas for another
    local keyA = PaletteFX.darkKey()
    PaletteFX.setMode(exports.palettes()[2].id)
    T.check(PaletteFX.darkKey() ~= keyA,
      "two palettes bake under different cache keys")

    -- USE ADVANCED = OFF is checked in the second pass below, where the
    -- option can actually be stored off before the mod loads
  end
end

-- ------- the frames
--
-- A border is six font glyphs. These check the whole chain: the page is
-- registered, the codes RESOLVE to real glyphs on it (a code pointing past
-- the sheet draws nothing and reports no error), the border table is
-- actually repointed, and GAME BOY puts the engine's own six back.

do
  local Font = require("src.render.Font")
  local api = run.loader.exports.groovy_palette

  T.check(type(api.frameCodes) == "function", "the frame surface is exported")

  local page = Data.font and Data.font.pages and Data.font.pages.groovy_frames
  T.check(page ~= nil, "the frame glyph page is registered")
  T.eq(page and page.base, 0x200, "at the base the codes are computed from")

  -- every frame's six codes must land ON the sheet. The page is 6 glyphs
  -- per row and one row per frame, so the last code of the last frame is
  -- the last glyph -- an off-by-one here draws an empty box and says
  -- nothing about it.
  local names = { "thin", "double", "triple", "thick",
                  "wide", "dash", "beads", "track" }
  local highest = 0
  for _, name in ipairs(names) do
    local codes = api.frameCodes(name)
    T.check(codes ~= nil, name .. " resolves to a set of codes")
    if codes then
      for _, key in ipairs({ "tl", "h", "tr", "v", "bl", "br" }) do
        T.check(codes[key] ~= nil, name .. " defines " .. key)
        if codes[key] and codes[key] > highest then highest = codes[key] end
      end
    end
  end

  -- The sheet's own size is the authority on how many glyphs exist, and it
  -- is read from the PNG header rather than through Assets -- a stubbed
  -- love returns a placeholder image whose dimensions prove nothing, which
  -- is how the first version of this check passed while testing nothing.
  local f = io.open(page.image, "rb")
  T.check(f ~= nil, "the frame sheet is where the manifest says it is")
  if f then
    local header = f:read(24)
    f:close()
    local function be32(s, at)
      local a, b, c, d = s:byte(at, at + 3)
      return ((a * 256 + b) * 256 + c) * 256 + d
    end
    T.eq(header:sub(2, 4), "PNG", "and it is a PNG")
    local w, h = be32(header, 17), be32(header, 21)
    local glyphs = (w / 8) * (h / 8)
    T.eq(highest - 0x200 + 1, glyphs,
      ("every code lands on the sheet (%d codes, %dx%d = %d glyphs)")
        :format(highest - 0x200 + 1, w, h, glyphs))
  end

  T.check(api.frameCodes("gb") == nil, "GAME BOY is not one of ours")

  -- and the border table must actually move
  local vanillaTl = Font.DEFAULT_BORDER.tl
  local codes = api.frameCodes("double")
  for key, code in pairs(codes) do Font.BORDER[key] = code end
  T.check(Font.BORDER.tl ~= vanillaTl, "pointing the border elsewhere takes")
  for key, code in pairs(Font.DEFAULT_BORDER) do Font.BORDER[key] = code end
  T.eq(Font.BORDER.tl, vanillaTl, "and GAME BOY restores the engine's own")

  -- ------- and it must not need a reboot
  --
  -- 0.4.0 applied the frame at load and on game.ready and nowhere else, so
  -- choosing one did nothing until the next launch. Font.drawBox reads
  -- Font.BORDER fresh every call, so the only thing missing was somebody
  -- writing it when the row moved.
  --
  -- Driven through the loader's own bus with the event ManagerState:setOption
  -- emits, rather than by calling applyFrame directly -- calling it directly
  -- would have passed in 0.4.0 too.
  do
    local loader = run.loader
    local function choose(value)
      loader.modOptions = loader.modOptions or {}
      loader.modOptions.groovy_palette = loader.modOptions.groovy_palette or {}
      loader.modOptions.groovy_palette.frame = value
      loader.events:emit("mod.options_changed",
        { mod = "groovy_palette", key = "frame", value = value })
    end

    choose("thick")
    T.eq(Font.BORDER.tl, api.frameCodes("thick").tl,
      "choosing a frame applies it immediately, without a restart")

    choose("beads")
    T.eq(Font.BORDER.tl, api.frameCodes("beads").tl,
      "and again when it changes to another")

    choose("gb")
    T.eq(Font.BORDER.tl, vanillaTl, "and GAME BOY comes back live too")

    -- someone else's option must not drag the border around
    choose("double")
    loader.events:emit("mod.options_changed",
      { mod = "some_other_mod", key = "frame", value = "gb" })
    T.eq(Font.BORDER.tl, api.frameCodes("double").tl,
      "another mod's option change is ignored")

    loader.modOptions.groovy_palette.frame = nil
    for key, code in pairs(Font.DEFAULT_BORDER) do Font.BORDER[key] = code end
  end

  -- ------- which other rows are live, checked rather than assumed
  --
  -- USE ADVANCED is read on every colour lookup rather than cached at load,
  -- so it should need no restart either. PACKS and START MENU genuinely do:
  -- one builds the MODES array and the other registers a screen and a menu
  -- row, both of which happen once. Asserting that here keeps the README
  -- honest if any of them ever changes.
  if PaletteFX.gbcPack() then
    local loader = run.loader
    loader.modOptions = loader.modOptions or {}
    loader.modOptions.groovy_palette = loader.modOptions.groovy_palette or {}
    local store = loader.modOptions.groovy_palette

    PaletteFX.setMode(exports.palettes()[1].id)
    store.advanced = "tint"
    local tinted = PaletteFX.worldGroupColors(Data, next(PaletteFX.gbcPack().world.groupColors), nil, nil)
    store.advanced = "off"
    T.check(not PaletteFX.usesGbcPack(),
      "USE ADVANCED takes effect without a restart")
    store.advanced = "full"
    local full = PaletteFX.worldGroupColors(Data, next(PaletteFX.gbcPack().world.groupColors), nil, nil)
    T.check(tinted[1][2][1] ~= full[1][2][1],
      "and TINT and FULL really differ")
    store.advanced = nil
  end
end

-- ------- day and night
--
-- The engine's own comment invites this: "world.tod default: always DAY. A
-- day/night mod returns NIGHT, MORNING, etc." Nothing was using it.
--
-- The period tints whatever palette is active rather than replacing it,
-- which is the whole design: replacing would mean writing
-- save.options.colors on a timer, and losing somebody's choice while they
-- are not looking.

do
  local api = run.loader.exports.groovy_palette
  local loader = run.loader
  loader.modOptions = loader.modOptions or {}
  loader.modOptions.groovy_palette = loader.modOptions.groovy_palette or {}
  local store = loader.modOptions.groovy_palette

  -- the tint ramps obey the same rule the palettes do: a ramp that does not
  -- fall in brightness renders the game inside out, and "at night" is a bad
  -- time to discover it
  for name, tint in pairs(api.timeTints) do
    local last
    for i, c in ipairs(tint.ramp) do
      local l = 0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3]
      if last then
        T.check(l < last,
          ("%s rung %d is darker than the one before (%.0f < %.0f)")
            :format(name, i, l, last))
      end
      last = l
    end
  end

  -- the clock maps hours to the periods it claims to
  T.eq(api.periodFromClock ~= nil, true, "the clock is exported")
  local hours = { [0]="NIGHT", [4]="NIGHT", [6]="MORNING", [8]="MORNING",
                  [12]="DAY", [16]="DAY", [18]="EVENING", [22]="NIGHT" }
  local realDate = os.date
  local bad = {}
  for hour, want in pairs(hours) do
    os.date = function(fmt, ...)
      if fmt == "%H" then return ("%02d"):format(hour) end
      return realDate(fmt, ...)
    end
    local got = api.periodFromClock()
    if got ~= want then bad[#bad + 1] = ("%02dh->%s(want %s)"):format(hour, got, want) end
  end
  os.date = realDate
  T.eq(#bad, 0, "every hour lands in the right period (" .. table.concat(bad, " ") .. ")")

  -- the step clock walks all four periods and comes back round
  local seen = {}
  for s = 0, 1199, 60 do seen[api.periodFromSteps(s)] = true end
  local count = 0
  for _ in pairs(seen) do count = count + 1 end
  T.eq(count, 4, "the step clock visits all four periods in a day")
  T.eq(api.periodFromSteps(0), api.periodFromSteps(1200),
    "and wraps round to where it started")
  T.eq(api.periodFromSteps(0), "DAY", "a fresh save starts in daylight")

  -- OFF really is off: the hook must hand back what it was given
  store.daynight = "off"
  T.eq(Runtime.call("world.tod", function(t) return t end, "DAY", { steps = 0 }),
    "DAY", "OFF leaves the time of day alone")
  T.eq(api.period(), "DAY", "and reports DAY")

  -- ON, the hook answers with a period the engine will hand to map.palette.
  -- The step count that lands in NIGHT is FOUND rather than assumed: the
  -- first draft of this test hardcoded three quarters of a day and landed
  -- in MORNING, then blamed the tint for being warm.
  store.daynight = "steps"
  local nightSteps
  for s = 0, 1199 do
    if api.periodFromSteps(s) == "NIGHT" then nightSteps = s break end
  end
  T.check(nightSteps ~= nil, "the step clock reaches NIGHT at all")
  local night = Runtime.call("world.tod", function(t) return t end, "DAY",
    { steps = nightSteps })
  T.eq(night, "NIGHT", "with the clock on, the hook answers with the period")

  -- and another mod's real clock outranks ours: we are guessing, it knows
  local theirs = Runtime.call("world.tod", function() return "EVENING" end, "DAY", {})
  T.eq(theirs, "EVENING", "a mod that already answered keeps its answer")

  -- ------- the tint reaches the colours, and OFF leaves them alone
  PaletteFX.setMode("gbc")
  store.daynight = "off"
  local byDay = PaletteFX.effectiveColors(PaletteFX.GRAYS)
  local dayCopy = {}
  for i, c in ipairs(byDay) do dayCopy[i] = { c[1], c[2], c[3] } end

  store.daynight = "steps"
  Runtime.call("world.tod", function(t) return t end, "DAY", { steps = nightSteps })
  T.eq(api.period(), "NIGHT", "and the mod is reporting NIGHT while we look")
  local byNight = PaletteFX.effectiveColors(PaletteFX.GRAYS)

  local moved = false
  for i, c in ipairs(byNight) do
    if c[1] ~= dayCopy[i][1] or c[2] ~= dayCopy[i][2] or c[3] ~= dayCopy[i][3] then
      moved = true
    end
  end
  T.check(moved, "night recolours even a VANILLA palette, not just ours")

  -- night must go blue, not merely dark: a night that only darkens reads as
  -- a fault in the screen
  T.check(byNight[2][3] > byNight[2][1],
    "and it goes cool -- blue above red in the midtone")

  -- The bake key must carry the PERIOD, or ADVANCED serves dusk's atlas at
  -- midnight. Compared between two TINTED periods, not against OFF: night
  -- and off differ in the key anyway (off produces no groovy suffix at
  -- all), so that comparison passed with the period missing entirely.
  if PaletteFX.gbcPack() then
    local eveningSteps
    for s = 0, 1199 do
      if api.periodFromSteps(s) == "EVENING" then eveningSteps = s break end
    end
    T.check(eveningSteps ~= nil, "the step clock reaches EVENING")

    Runtime.call("world.tod", function(t) return t end, "DAY", { steps = nightSteps })
    local keyNight = PaletteFX.darkKey()
    Runtime.call("world.tod", function(t) return t end, "DAY", { steps = eveningSteps })
    local keyEvening = PaletteFX.darkKey()
    T.check(keyNight ~= keyEvening,
      "dusk and midnight bake under different cache keys")
  end

  store.daynight = "off"
  PaletteFX.setMode("gbc")
end

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
