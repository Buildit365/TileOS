local fileslist = require("fileslist")
local input = require("input")

local filesui = {}

local function capacity(h, count)
  local pager = count > (h - 1)
  local rows = pager and (h - 2) or (h - 1)
  if rows < 1 then
    rows = 1
  end
  return rows, pager
end

function filesui.draw(term, model, fs)
  local w, h = term.getSize()
  local entries = fileslist.list(fs, model.path)
  local rows, pager = capacity(h, #entries)
  local pages = math.max(1, math.ceil(#entries / rows))
  if model.page > pages then
    model.page = pages
  end
  if model.page < 1 then
    model.page = 1
  end
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.clear()
  term.setCursorPos(1, 1)
  term.write(model.path:sub(1, w))
  local start = (model.page - 1) * rows
  for i = 1, rows do
    local entry = entries[start + i]
    if entry then
      local text = entry.name
      if entry.kind == "dir" then
        text = text .. "/"
      end
      local selected = model.cursor == start + i
      if selected then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
      else
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
      end
      term.setCursorPos(1, i + 1)
      local shown = text:sub(1, w)
      if selected and #shown < w then
        shown = shown .. string.rep(" ", w - #shown)
      end
      term.write(shown)
    end
  end
  if pager then
    term.setCursorPos(1, h)
    term.write("Prev")
    term.setCursorPos(w - 3, h)
    term.write("Next")
  end
end

local function openEntry(model, entry)
  if not entry then
    return model, nil
  end
  if entry.kind == "up" then
    model.path = fileslist.parent(model.path)
    model.page = 1
    model.cursor = 1
    return model, nil
  end
  if entry.kind == "dir" then
    model.path = fileslist.child(model.path, entry.name)
    model.page = 1
    model.cursor = 1
    return model, nil
  end
  local full = fileslist.child(model.path, entry.name)
  if entry.kind == "lua" then
    return model, { type = "push", path = full, args = {}, label = "Files" }
  end
  return model, {
    type = "push",
    path = "/rom/programs/edit.lua",
    args = { full },
    label = "Files",
  }
end

local function showCursor(model, rows)
  local cursor = model.cursor or 1
  if cursor < 1 then
    cursor = 1
  end
  if rows < 1 then
    rows = 1
  end
  model.cursor = cursor
  model.page = math.floor((cursor - 1) / rows) + 1
end

function filesui.key(model, term, code, fs)
  local _, h = term.getSize()
  local entries = fileslist.list(fs, model.path)
  local rows = capacity(h, #entries)
  if #entries < 1 then
    return model, nil
  end
  local cursor = model.cursor or 1
  local way = input.direction(code)
  if way == "up" or way == "left" then
    cursor = cursor - 1
  elseif way == "down" or way == "right" then
    cursor = cursor + 1
  end
  if cursor < 1 then
    cursor = 1
  end
  if cursor > #entries then
    cursor = #entries
  end
  model.cursor = cursor
  showCursor(model, rows)
  if not input.isEnter(code) then
    return model, nil
  end
  return openEntry(model, entries[cursor])
end

function filesui.click(model, term, x, y, fs)
  local w, h = term.getSize()
  local entries = fileslist.list(fs, model.path)
  local rows, pager = capacity(h, #entries)
  local pages = math.max(1, math.ceil(#entries / rows))
  if pager and y == h then
    if x <= 4 and model.page > 1 then
      model.page = model.page - 1
    end
    if x >= w - 3 and model.page < pages then
      model.page = model.page + 1
    end
    if model.cursor then
      model.cursor = (model.page - 1) * rows + 1
    end
    return model, nil
  end
  if y < 2 or (pager and y >= h) then
    return model, nil
  end
  local index = (model.page - 1) * rows + (y - 1)
  local entry = entries[index]
  if not entry then
    return model, nil
  end
  if model.cursor then
    model.cursor = index
  end
  return openEntry(model, entry)
end

return filesui
