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

function settingsui.load(peripheral, term, activeName, options)
  options = options or {}
  local screenColor = term.isColor() and true or false
  local machineColor = options.machineColor
  if machineColor == nil then
    machineColor = screenColor
  end
  return {
    page = 1,
    cursor = 1,
    confirm = false,
    selected = activeName or "terminal",
    screenColor = screenColor,
    machineColor = machineColor and true or false,
    colorOn = screenColor and options.color ~= "gray",
    keysOn = (not machineColor) or options.keys == "on",
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

local function place(model, h)
  local y = 1
  local colorY = nil
  local keysY = nil
  if model.screenColor then
    colorY = y
    y = y + 1
  else
    y = y + 1
  end
  if model.machineColor then
    keysY = y
    y = y + 1
  end
  y = y + 1
  local itemY = y + 1
  local avail = h - itemY - 1
  if avail < 1 then
    avail = 1
  end
  return {
    colorY = colorY,
    keysY = keysY,
    displayY = y,
    itemY = itemY,
    avail = avail,
  }
end

local function rows(model)
  local list = {}
  if model.screenColor then
    list[#list + 1] = { kind = "color" }
  end
  if model.machineColor then
    list[#list + 1] = { kind = "keys" }
  end
  local shown = items(model)
  for i = 1, #shown do
    list[#list + 1] = { kind = "display", index = i, item = shown[i] }
  end
  list[#list + 1] = { kind = "exit" }
  return list
end

function settingsui.draw(term, model)
  local w, h = term.getSize()
  local spot = place(model, h)
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.clear()
  if model.confirm then
    writeRow(term, 1, "Exit to CraftOS?", w, false)
    writeRow(term, 3, "Yes", w, model.keysOn and model.cursor == 1)
    writeRow(term, 4, "No", w, model.keysOn and model.cursor == 2)
    return
  end
  local choice = rows(model)
  local function marked(index)
    return model.keysOn and model.cursor == index
  end
  if model.screenColor then
    local text = model.colorOn and "Screen: Color" or "Screen: Gray"
    writeRow(term, spot.colorY, text, w, marked(1))
  else
    writeRow(term, 1, "Screen: Gray", w, false)
  end
  if spot.keysY then
    local text = model.keysOn and "Keys: On" or "Keys: Off"
    local index = model.screenColor and 2 or 1
    writeRow(term, spot.keysY, text, w, marked(index))
  end
  writeRow(term, spot.displayY, "Display", w, false)
  local list = items(model)
  local pages = math.max(1, math.ceil(#list / spot.avail))
  if model.page > pages then
    model.page = pages
  end
  local start = (model.page - 1) * spot.avail + 1
  for i = 0, spot.avail - 1 do
    local item = list[start + i]
    if item then
      local mark = item.name == model.selected and ">" or " "
      local index = (model.screenColor and 1 or 0) + (model.machineColor and 1 or 0) + start + i
      writeRow(term, spot.itemY + i, (mark .. " " .. item.text):sub(1, w), w, marked(index))
    end
  end
  writeRow(term, h, "Exit to CraftOS", w, marked(#choice))
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
  local spot = place(model, h)
  if spot.colorY and y == spot.colorY then
    model.colorOn = not model.colorOn
    return model, { type = "color", name = model.colorOn and "color" or "gray" }
  end
  if spot.keysY and y == spot.keysY then
    model.keysOn = not model.keysOn
    return model, { type = "keys", name = model.keysOn and "on" or "off" }
  end
  if y == h and x <= 16 then
    model.confirm = true
    model.cursor = 2
    return model, nil
  end
  local list = items(model)
  if y >= spot.itemY and y < h then
    local offset = y - spot.itemY
    local index = (model.page - 1) * spot.avail + offset + 1
    local item = list[index]
    if item then
      return model, { type = "display", name = item.name }
    end
  end
  return model, nil
end

function settingsui.key(model, term, code)
  local way = input.direction(code)
  local choice = rows(model)
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
    model.cursor = #choice
    return model, nil
  end
  local _, h = term.getSize()
  local spot = place(model, h)
  local cursor = model.cursor or 1
  if way == "up" or way == "left" then
    cursor = cursor - 1
  elseif way == "down" or way == "right" then
    cursor = cursor + 1
  end
  if cursor < 1 then
    cursor = 1
  end
  if cursor > #choice then
    cursor = #choice
  end
  model.cursor = cursor
  local picked = choice[cursor]
  if picked and picked.kind == "display" then
    model.page = math.floor((picked.index - 1) / spot.avail) + 1
  end
  if not input.isEnter(code) then
    return model, nil
  end
  if picked.kind == "color" then
    model.colorOn = not model.colorOn
    return model, { type = "color", name = model.colorOn and "color" or "gray" }
  end
  if picked.kind == "keys" then
    model.keysOn = not model.keysOn
    return model, { type = "keys", name = model.keysOn and "on" or "off" }
  end
  if picked.kind == "exit" then
    model.confirm = true
    model.cursor = 2
    return model, nil
  end
  return model, { type = "display", name = picked.item.name }
end

return settingsui
