local T = tile_test

local function peripheralWith(list)
  return {
    getNames = function()
      local names = {}
      for i = 1, #list do
        names[i] = list[i].name
      end
      return names
    end,
    getType = function(name)
      for i = 1, #list do
        if list[i].name == name then
          return list[i].type
        end
      end
      return nil
    end,
  }
end

T.test("settings shows color, the selected display, and exit", function()
  local settingsui = dofile("os/settingsui.lua")
  local peripheral = peripheralWith({
    { name = "top", type = "monitor" },
    { name = "right", type = "speaker" },
    { name = "left", type = "monitor" },
  })
  local term = fakeTerm(30, 12, true)
  local model = settingsui.load(peripheral, term, "terminal")
  settingsui.draw(term, model)
  T.assertEq(term.line(1):sub(1, 13), "Screen: Color")
  T.assertEq(term.line(3):sub(1, 7), "Display")
  T.assertEq(term.line(4):sub(1, 13), "> This screen")
  T.assertEq(term.line(5):sub(1, 6), "  left")
  T.assertEq(term.line(6):sub(1, 5), "  top")
  T.assertEq(term.line(12):sub(1, 15), "Exit to CraftOS")

  local command
  model, command = settingsui.click(model, term, 1, 5)
  T.assertEq(command.type, "display")
  T.assertEq(command.name, "left")

  model.confirm = false
  model, command = settingsui.click(model, term, 1, 12)
  T.assertEq(command, nil)
  T.assertEq(model.confirm, true)
  settingsui.draw(term, model)
  T.assertEq(term.line(1):sub(1, 16), "Exit to CraftOS?")
  model, command = settingsui.click(model, term, 1, 4)
  T.assertEq(command, nil)
  T.assertEq(model.confirm, false)
  model.confirm = true
  model, command = settingsui.click(model, term, 1, 3)
  T.assertEq(command.type, "exit_os")
end)

T.test("arrow keys move through settings and enter chooses the row", function()
  local settingsui = dofile("os/settingsui.lua")
  local peripheral = peripheralWith({
    { name = "left", type = "monitor" },
  })
  local term = fakeTerm(30, 12, true)
  local model = settingsui.load(peripheral, term, "terminal")
  local command
  model, command = settingsui.key(model, term, 208)
  T.assertEq(command, nil)
  T.assertEq(model.cursor, 2)
  model, command = settingsui.key(model, term, 28)
  T.assertEq(command.type, "display")
  T.assertEq(command.name, "left")
  model.cursor = 3
  model, command = settingsui.key(model, term, 28)
  T.assertEq(model.confirm, true)
  T.assertEq(model.cursor, 2)
  model, command = settingsui.key(model, term, 200)
  model, command = settingsui.key(model, term, 28)
  T.assertEq(command.type, "exit_os")
end)

T.test("a gray screen is labeled Gray", function()
  local settingsui = dofile("os/settingsui.lua")
  local term = fakeTerm(20, 10, false)
  local model = settingsui.load(peripheralWith({}), term, "left")
  settingsui.draw(term, model)
  T.assertEq(term.line(1):sub(1, 12), "Screen: Gray")
  T.assertEq(term.line(4):sub(1, 13), "  This screen")
end)
