local T = tile_test
local unpack = unpack or table.unpack

local function scripted(queue)
  return function()
    local event = table.remove(queue, 1)
    if not event then
      return nil
    end
    return unpack(event)
  end
end

T.test("clicking an app shows its error, Home returns, and Ctrl+T exits", function()
  local main = dofile("os/main.lua")
  local fs = fakeFs({
    ["apps/demo/main.lua"] = [[
local event, button, x, y = os.pullEvent("mouse_click")
error("clicked " .. x .. "," .. y, 0)
]],
  })
  local computer = fakeTerm(51, 19, true)
  local windows = {}
  local result = main.run({
    fs = fs,
    osDir = "os",
    native = function()
      return computer
    end,
    current = function()
      return computer
    end,
    wrap = function()
      return nil
    end,
    peripheral = {
      getNames = function()
        return {}
      end,
      getType = function()
        return nil
      end,
    },
    window = function(parent, x, y, w, h)
      local win = fakeTerm(w, h, parent.isColor())
      windows[#windows + 1] = win
      return win
    end,
    pullEventRaw = scripted({
      { "mouse_click", 1, 2, 3 },
      { "mouse_click", 1, 2, 3 },
      { "mouse_click", 1, 1, 1 },
      { "terminate" },
    }),
  })
  T.assertEq(result, "exit")
  T.assertEq(windows[1].line(1):sub(1, 9), "App error")
  T.assertEq(windows[1].line(2):sub(1, 11), "clicked 2,2")
  T.assertEq(computer.line(1):sub(1, 4), "Tile")
end)

T.test("a tiny saved monitor shows the message and the computer still opens Tile", function()
  local main = dofile("os/main.lua")
  local fs = fakeFs({
    [".tile"] = "display=left\n",
    ["apps/demo/main.lua"] = "os.pullEvent()\n",
  })
  local computer = fakeTerm(51, 19, true)
  local tiny = fakeTerm(7, 5, true)
  local result = main.run({
    fs = fs,
    osDir = "os",
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
    peripheral = {
      getNames = function()
        return { "left" }
      end,
      getType = function()
        return "monitor"
      end,
    },
    window = function(parent, x, y, w, h)
      return fakeTerm(w, h, parent.isColor())
    end,
    pullEventRaw = scripted({
      { "monitor_touch", "left", 1, 5 },
      { "terminate" },
    }),
  })
  T.assertEq(result, "exit")
  T.assertEq(computer.line(1):sub(1, 4), "Tile")
  T.assertEq(tiny.line(1), string.rep(" ", 7))
  local config = dofile("os/config.lua")
  T.assertEq(config.read(fs), "terminal")
end)
