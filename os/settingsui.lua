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

function settingsui.draw(term, model)
  local w, h = term.getSize()
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.clear()
  if model.confirm then
    term.setCursorPos(1, 1)
    term.write("Exit to CraftOS?")
    term.setCursorPos(1, 3)
    term.write("Yes")
    term.setCursorPos(1, 4)
    term.write("No")
    return
  end
  term.setCursorPos(1, 1)
  if model.color then
    term.write("Screen: Color")
  else
    term.write("Screen: Gray")
  end
  term.setCursorPos(1, 3)
  term.write("Display")
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
      term.setCursorPos(1, 4 + i)
      term.write((mark .. " " .. item.text):sub(1, w))
    end
  end
  term.setCursorPos(1, h)
  term.write("Exit to CraftOS")
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

return settingsui
