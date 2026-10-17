local filesui = require("filesui")

local model = { path = "/", page = 1 }

local function redraw()
  filesui.draw(term, model, fs)
end

redraw()
while true do
  local event, _, x, y = os.pullEvent()
  if event == "mouse_click" then
    local command
    model, command = filesui.click(model, term, x, y, fs)
    if command and command.type == "push" then
      tile.push(command.path, command.args, command.label)
    end
    redraw()
  elseif event == "disk" or event == "disk_eject" then
    redraw()
  end
end
