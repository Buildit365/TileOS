local input = require("input")

local settingsui = {}

function settingsui.monitors(peripheral)
  local names = peripheral.getNames()
  local out = {}
  for i = 1, #names do
    if peripheral.getType(names[i]) == "monitor" then
      out[#out + 1] = names[i]
    end
  end
  table.sort(out)
  return out
end

function settingsui.load(peripheral, term, activeName)
  return {
    page = 1,
    cursor = 1,
    confirm = false,
    selected = activeName or "terminal",
    color = term.isColor(),
    monitors = settingsui.monitors(peripheral),
  }
end

local function items(model)
  local list = {
    { name = "terminal", text = "This screen" },
  }
  for i = 1, #model.monitors do
    list[#list + 1] = { name = model.monitors[i], text = model.monitors[i] }
  end
  return list
end

local function writeRow(term, y, text, w, selected)
  if selected then
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
  else
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
  end
  term.setCursorPos(1, y)
  local shown = text:sub(1, w)
  if selected and #shown < w then
    shown = shown .. string.rep(" ", w - #shown)
  end
  term.write(shown)
end

function settingsui.draw(term, model)
  local w, h = term.getSize()
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.clear()
  if model.confirm then
    writeRow(term, 1, "Exit to CraftOS?", w, false)
    writeRow(term, 3, "Yes", w, model.cursor == 1)
    writeRow(term, 4, "No", w, model.cursor == 2)
    return
  end
  if model.color then
    writeRow(term, 1, "Screen: Color", w, false)
  else
    writeRow(term, 1, "Screen: Gray", w, false)
  end
  writeRow(term, 3, "Display", w, false)
  local list = items(model)
  local avail = h - 5
  if avail < 1 then
    avail = 1
  end
  local pages = math.max(1, math.ceil(#list / avail))
  if model.page > pages then
    model.page = pages
  end
  local start = (model.page - 1) * avail + 1
  for i = 0, avail - 1 do
    local item = list[start + i]
    if item then
      local mark = item.name == model.selected and ">" or " "
      writeRow(term, 4 + i, (mark .. " " .. item.text):sub(1, w), w, model.cursor == start + i)
    end
  end
  writeRow(term, h, "Exit to CraftOS", w, model.cursor == #list + 1)
end

function settingsui.click(model, term, x, y)
  local _, h = term.getSize()
  if model.confirm then
    if y == 3 and x <= 3 then
      return model, { type = "exit_os" }
    end
    if y == 4 and x <= 2 then
      model.confirm = false
    end
    return model, nil
  end
  if y == h and x <= 16 then
    model.confirm = true
    model.cursor = 2
    return model, nil
  end
  local list = items(model)
  local avail = h - 5
  if avail < 1 then
    avail = 1
  end
  if y >= 4 and y < h then
    local offset = y - 4
    local index = (model.page - 1) * avail + offset + 1
    local item = list[index]
    if item then
      return model, { type = "display", name = item.name }
    end
  end
  return model, nil
end

function settingsui.key(model, term, code)
  local way = input.direction(code)
  local list = items(model)
  if model.confirm then
    local cursor = model.cursor
    if cursor ~= 1 and cursor ~= 2 then
      cursor = 2
    end
    if way == "up" or way == "left" then
      cursor = 1
    elseif way == "down" or way == "right" then
      cursor = 2
    end
    model.cursor = cursor
    if not input.isEnter(code) then
      return model, nil
    end
    if cursor == 1 then
      return model, { type = "exit_os" }
    end
    model.confirm = false
    model.cursor = #list + 1
    return model, nil
  end
  local total = #list + 1
  local cursor = model.cursor or 1
  if way == "up" or way == "left" then
    cursor = cursor - 1
  elseif way == "down" or way == "right" then
    cursor = cursor + 1
  end
  if cursor < 1 then
    cursor = 1
  end
  if cursor > total then
    cursor = total
  end
  model.cursor = cursor
  local _, h = term.getSize()
  local avail = h - 5
  if avail < 1 then
    avail = 1
  end
  if cursor <= #list then
    model.page = math.floor((cursor - 1) / avail) + 1
  end
  if not input.isEnter(code) then
    return model, nil
  end
  if cursor > #list then
    model.confirm = true
    model.cursor = 2
    return model, nil
  end
  local item = list[cursor]
  return model, { type = "display", name = item.name }
end

return settingsui
