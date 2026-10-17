local settingsui = require("settingsui")
local config = require("config")
local input = require("input")

local function loadModel()
  return settingsui.load(peripheral, term, config.read(fs) or tile.display or "terminal")
end

local model = loadModel()
settingsui.draw(term, model)

local function apply(command)
  if command and command.type == "display" then
    config.write(fs, command.name)
    model.selected = command.name
    settingsui.draw(term, model)
    tile.setDisplay(command.name)
    model = loadModel()
  elseif command and command.type == "exit_os" then
    tile.exit()
  end
  settingsui.draw(term, model)
end

while true do
  local event, a, b, c = os.pullEvent()
  if event == "mouse_click" then
    local command
    model, command = settingsui.click(model, term, b, c)
    apply(command)
  elseif event == "key" and not (c and input.isEnter(a)) then
    local command
    model, command = settingsui.key(model, term, a)
    apply(command)
  end
end
