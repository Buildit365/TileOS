local layout = require("layout")
local theme = require("theme")

local draw = {}

local function fill(term, bg, fg)
  term.setBackgroundColor(bg)
  term.setTextColor(fg)
  term.clear()
  term.setCursorPos(1, 1)
end

local function put(term, x, y, text, bg, fg)
  term.setBackgroundColor(bg)
  term.setTextColor(fg)
  term.setCursorPos(x, y)
  term.write(text)
end

function draw.blank(term)
  fill(term, colors.black, colors.white)
end

function draw.status(term)
  fill(term, colors.black, colors.white)
  term.write("Showing on monitor")
end

function draw.bar(term, spec)
  local w = term.getSize()
  term.setBackgroundColor(colors.gray)
  term.setTextColor(colors.white)
  term.setCursorPos(1, 1)
  term.clearLine()
  term.setCursorPos(1, 1)
  if spec.mode == "app" then
    term.write("Home " .. (spec.label or ""))
  else
    term.write("Tile")
  end
  if spec.mode == "home" and spec.pages and spec.pages > 1 then
    put(term, w - 2, 1, "<", colors.gray, colors.white)
    put(term, w, 1, ">", colors.gray, colors.white)
  end
  if type(term.setCursorBlink) == "function" then
    term.setCursorBlink(false)
  end
end

local function paintIcon(term, x, y, app, isColor)
  if app.icon then
    local picture = theme.remap(app.icon, isColor, app.accent)
    for iy = 1, #picture do
      for ix = 1, #picture[iy] do
        put(term, x + ix - 1, y + iy - 1, " ", picture[iy][ix], picture[iy][ix])
      end
    end
    return
  end
  for iy = 0, 1 do
    for ix = 0, 2 do
      put(term, x + ix, y + iy, " ", colors.white, colors.black)
    end
  end
  local letter = (app.label:sub(1, 1) or "?"):upper()
  put(term, x + 1, y, letter, colors.white, colors.black)
end

local function paintLabel(term, x, y, label, selected)
  label = label or ""
  if #label > 5 then
    label = label:sub(1, 5)
  end
  local pad = math.floor((5 - #label) / 2)
  local text = string.rep(" ", pad) .. label .. string.rep(" ", 5 - pad - #label)
  local bg = colors.white
  local fg = colors.black
  if selected then
    bg = colors.black
    fg = colors.white
  end
  put(term, x, y, text, bg, fg)
end

function draw.home(term, metrics, appList, page, isColor, selected)
  fill(term, colors.white, colors.black)
  if metrics.pageSize <= 0 then
    return
  end
  local start = (page - 1) * metrics.pageSize
  for row = 0, metrics.rows - 1 do
    for col = 0, metrics.cols - 1 do
      local index = start + row * metrics.cols + col + 1
      local app = appList[index]
      if app then
        local x, y = layout.cellOrigin(col, row)
        paintIcon(term, x + 1, y, app, isColor)
        paintLabel(term, x, y + 2, app.label, index == selected)
      end
    end
  end
end

function draw.error(term, message)
  fill(term, colors.white, colors.black)
  local w, h = term.getSize()
  term.write("App error")
  local text = tostring(message or "")
  local y = 2
  local index = 1
  while index <= #text and y <= h do
    term.setCursorPos(1, y)
    term.write(text:sub(index, index + w - 1))
    index = index + w
    y = y + 1
  end
end

function draw.tooSmall(term, showButton)
  fill(term, colors.white, colors.black)
  term.write("Screen too small")
  term.setCursorPos(1, 2)
  term.write("Lower text scale")
  term.setCursorPos(1, 3)
  term.write("or add blocks")
  if showButton then
    term.setCursorPos(1, 5)
    term.write("Use computer")
  end
end

return draw
