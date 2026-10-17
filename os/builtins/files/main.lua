local filesui = require("filesui")
local input = require("input")

local model = { path = "/", page = 1, cursor = 1 }

local function redraw()
  filesui.draw(term, model, fs)
end

local function apply(command)
  if command and command.type == "push" then
    tile.push(command.path, command.args, command.label)
  end
  redraw()
end

redraw()
while true do
  local event, a, b, c = os.pullEvent()
  if event == "mouse_click" then
    local command
    model, command = filesui.click(model, term, b, c, fs)
    apply(command)
  elseif event == "key" and not (c and input.isEnter(a)) then
    local command
    model, command = filesui.key(model, term, a, fs)
    apply(command)
  elseif event == "disk" or event == "disk_eject" then
    redraw()
  end
end
