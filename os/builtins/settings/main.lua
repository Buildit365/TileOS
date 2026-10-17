local settingsui = require("settingsui")
local config = require("config")

local function loadModel()
  return settingsui.load(peripheral, term, config.read(fs) or tile.display or "terminal")
end

local model = loadModel()
settingsui.draw(term, model)

while true do
  local event, _, x, y = os.pullEvent()
  if event == "mouse_click" then
    local command
    model, command = settingsui.click(model, term, x, y)
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
end
