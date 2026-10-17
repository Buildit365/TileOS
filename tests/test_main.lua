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
  T.assertEq(computer.line(1), string.rep(" ", 51))
  local _, _, bg = computer.cell(1, 1)
  T.assertEq(bg, colors.black)
end)

T.test("the shell cursor stays on the prompt when the bar is drawn or clicked", function()
  local main = dofile("os/main.lua")
  local fs = fakeFs({
    ["apps/demo/main.lua"] = [[
term.setCursorPos(4, 2)
term.setCursorBlink(true)
os.pullEvent()
]],
  })
  local computer = fakeTerm(51, 19, true)
  computer.setCursorBlink(true)
  local shots = {}
  local pulls = 0
  local queue = {
    { "mouse_click", 1, 2, 3 },
    { "mouse_click", 1, 8, 1 },
    { "mouse_click", 1, 1, 1 },
    { "terminate" },
  }
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
      function win.restoreCursor()
        local cx, cy = win.getCursorPos()
        parent.setCursorPos(x + cx - 1, y + cy - 1)
        parent.setCursorBlink(win.getCursorBlink())
      end
      return win
    end,
    pullEventRaw = function()
      pulls = pulls + 1
      local cx, cy = computer.getCursorPos()
      shots[pulls] = { x = cx, y = cy, blink = computer.getCursorBlink() }
      local event = table.remove(queue, 1)
      if not event then
        return nil
      end
      return unpack(event)
    end,
  })
  T.assertEq(result, "exit")
  T.assertEq(shots[1].blink, false)
  T.assertEq(shots[2].x, 4)
  T.assertEq(shots[2].y, 3)
  T.assertEq(shots[2].blink, true)
  T.assertEq(shots[3].x, 4)
  T.assertEq(shots[3].y, 3)
  T.assertEq(shots[3].blink, true)
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
  T.assertEq(computer.line(1), string.rep(" ", 51))
  T.assertEq(tiny.line(1), string.rep(" ", 7))
  local config = dofile("os/config.lua")
  T.assertEq(config.read(fs), "terminal")
end)
