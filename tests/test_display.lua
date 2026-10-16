local T = tile_test

local function sized(w, h, id, isColor)
  local term = fakeTerm(w, h, isColor)
  term.id = id
  return term
end

T.test("config round trip and empty file", function()
  local config = dofile("os/config.lua")
  local fs = fakeFs({})
  T.assertEq(config.read(fs), nil)
  config.write(fs, "left")
  T.assertEq(config.read(fs), "left")
  config.write(fs, "terminal")
  T.assertEq(config.read(fs), "terminal")
  local broken = fakeFs({ [".tile"] = "nope\n" })
  T.assertEq(config.read(broken), nil)
end)

T.test("no saved display uses the terminal Tile started on", function()
  local display = dofile("os/display.lua")
  local computer = sized(51, 19, "computer", true)
  local monitor = sized(15, 10, "left", true)
  local view = display.resolve({
    native = function()
      return computer
    end,
    current = function()
      return monitor
    end,
    wrap = function()
      return nil
    end,
  }, nil)
  T.assertEq(view.mode, "ui")
  T.assertEq(view.ui.id, "left")
  T.assertEq(view.active.kind, "monitor")
  T.assertEq(view.active.name, "current")
  T.assertEq(view.displayName, "current")
end)

T.test("terminal display forces the computer", function()
  local display = dofile("os/display.lua")
  local computer = sized(51, 19, "computer", false)
  local monitor = sized(15, 10, "left", true)
  local view = display.resolve({
    native = function()
      return computer
    end,
    current = function()
      return monitor
    end,
    wrap = function()
      return monitor
    end,
  }, "terminal")
  T.assertEq(view.ui.id, "computer")
  T.assertEq(view.active.kind, "computer")
  T.assertEq(view.displayName, "terminal")
  T.assertEq(view.status, nil)
end)

T.test("a missing monitor clears the setting and uses the computer", function()
  local display = dofile("os/display.lua")
  local computer = sized(26, 20, "pocket", true)
  local view = display.resolve({
    native = function()
      return computer
    end,
    current = function()
      return computer
    end,
    wrap = function()
      return nil
    end,
  }, "left")
  T.assertEq(view.mode, "ui")
  T.assertEq(view.ui.id, "pocket")
  T.assertEq(view.clearSaved, true)
  T.assertEq(view.displayName, "terminal")
end)

T.test("a tiny saved monitor splits onto the computer", function()
  local display = dofile("os/display.lua")
  local computer = sized(51, 19, "computer", true)
  local tiny = sized(7, 5, "left", true)
  local view = display.resolve({
    native = function()
      return computer
    end,
    current = function()
      return computer
    end,
    wrap = function(name)
      if name == "left" then
        return tiny
      end
      return nil
    end,
  }, "left")
  T.assertEq(view.mode, "split")
  T.assertEq(view.ui.id, "computer")
  T.assertEq(view.message.id, "left")
  T.assertEq(view.messageSide, "left")
  T.assertEq(view.active.kind, "computer")
  T.assertEq(view.clearSaved, nil)
end)

T.test("a large monitor is the UI and the computer gets a status line", function()
  local display = dofile("os/display.lua")
  local computer = sized(51, 19, "computer", true)
  local monitor = sized(30, 20, "top", true)
  local view = display.resolve({
    native = function()
      return computer
    end,
    current = function()
      return computer
    end,
    wrap = function()
      return monitor
    end,
  }, "top")
  T.assertEq(view.mode, "ui")
  T.assertEq(view.ui.id, "top")
  T.assertEq(view.status.id, "computer")
  T.assertEq(view.active.name, "top")
  T.assertEq(view.displayName, "top")
end)

T.test("a tiny screen with no larger computer stays a message", function()
  local display = dofile("os/display.lua")
  local tiny = sized(7, 5, "only", false)
  local view = display.resolve({
    native = function()
      return tiny
    end,
    current = function()
      return tiny
    end,
    wrap = function()
      return nil
    end,
  }, nil)
  T.assertEq(view.mode, "message")
  T.assertEq(view.ui, nil)
  T.assertEq(view.message.id, "only")
end)
