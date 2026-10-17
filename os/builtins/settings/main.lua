local settingsui = require("settingsui")
local config = require("config")
local input = require("input")

local function machineColor()
  if type(term.native) == "function" then
    local native = term.native()
    if native and native.isColor then
      return native.isColor() and true or false
    end
  end
  return term.isColor() and true or false
end

local function loadModel()
  return settingsui.load(peripheral, term, config.read(fs) or tile.display or "terminal", {
    machineColor = machineColor(),
    color = config.get(fs, "color"),
    keys = config.get(fs, "keys"),
  })
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
  elseif command and command.type == "color" then
    config.set(fs, "color", command.name)
  elseif command and command.type == "keys" then
    config.set(fs, "keys", command.name)
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
  elseif event == "key" and model.keysOn and not (c and input.isEnter(a)) then
    local command
    model, command = settingsui.key(model, term, a)
    apply(command)
  end
end
