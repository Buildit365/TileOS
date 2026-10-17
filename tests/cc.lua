local colors = {
  white = 1,
  orange = 2,
  magenta = 4,
  lightBlue = 8,
  yellow = 16,
  lime = 32,
  pink = 64,
  gray = 128,
  lightGray = 256,
  cyan = 512,
  purple = 1024,
  blue = 2048,
  brown = 4096,
  green = 8192,
  red = 16384,
  black = 32768,
}
colors.grey = colors.gray
colors.lightGrey = colors.lightGray
_G.colors = colors

local function fakeTerm(w, h, isColor)
  local fg = colors.white
  local bg = colors.black
  local curX, curY = 1, 1
  local blink = false
  local buf = {}
  local term = {}

  local function cell(x, y)
    buf[y] = buf[y] or {}
    buf[y][x] = buf[y][x] or { " ", fg, bg }
    return buf[y][x]
  end

  function term.getSize()
    return w, h
  end

  function term.setCursorPos(x, y)
    curX, curY = x, y
  end

  function term.getCursorPos()
    return curX, curY
  end

  function term.setTextColor(c)
    fg = c
  end

  function term.setTextColour(c)
    fg = c
  end

  function term.setBackgroundColor(c)
    bg = c
  end

  function term.setBackgroundColour(c)
    bg = c
  end

  function term.getTextColor()
    return fg
  end

  function term.getBackgroundColor()
    return bg
  end

  function term.isColor()
    return isColor and true or false
  end

  function term.isColour()
    return term.isColor()
  end

  function term.write(text)
    text = tostring(text)
    for i = 1, #text do
      if curX >= 1 and curX <= w and curY >= 1 and curY <= h then
        buf[curY] = buf[curY] or {}
        buf[curY][curX] = { text:sub(i, i), fg, bg }
      end
      curX = curX + 1
    end
  end

  function term.clear()
    buf = {}
    for y = 1, h do
      buf[y] = {}
      for x = 1, w do
        buf[y][x] = { " ", fg, bg }
      end
    end
  end

  function term.clearLine()
    if curY < 1 or curY > h then
      return
    end
    buf[curY] = buf[curY] or {}
    for x = 1, w do
      buf[curY][x] = { " ", fg, bg }
    end
  end

  function term.setCursorBlink(on)
    blink = on and true or false
  end

  function term.getCursorBlink()
    return blink
  end

  function term.scroll()
  end

  function term.line(y)
    local out = {}
    for x = 1, w do
      out[x] = (buf[y] and buf[y][x] and buf[y][x][1]) or " "
    end
    return table.concat(out)
  end

  function term.cell(x, y)
    local slot = buf[y] and buf[y][x]
    if not slot then
      return " ", fg, bg
    end
    return slot[1], slot[2], slot[3]
  end

  return term
end

local function norm(path)
  path = tostring(path or "")
  path = path:gsub("^/+", ""):gsub("/+$", "")
  return path
end

local function fakeFs(tree)
  tree = tree or {}
  local fs = {}

  function fs.combine(a, b)
    a = norm(a)
    b = norm(b)
    if a == "" then
      return b
    end
    if b == "" then
      return a
    end
    return a .. "/" .. b
  end

  function fs.getName(path)
    path = norm(path)
    return path:match("([^/]+)$") or ""
  end

  function fs.getDir(path)
    path = norm(path)
    return path:match("^(.*)/[^/]+$") or ""
  end

  function fs.exists(path)
    path = norm(path)
    if path == "" then
      return true
    end
    if tree[path] ~= nil then
      return true
    end
    local prefix = path .. "/"
    for key in pairs(tree) do
      if key:sub(1, #prefix) == prefix then
        return true
      end
    end
    return false
  end

  function fs.isDir(path)
    path = norm(path)
    if path == "" then
      return true
    end
    if type(tree[path]) == "string" then
      return false
    end
    if tree[path] == true then
      return true
    end
    local prefix = path .. "/"
    for key in pairs(tree) do
      if key:sub(1, #prefix) == prefix then
        return true
      end
    end
    return false
  end

  function fs.list(path)
    path = norm(path)
    local prefix = path == "" and "" or (path .. "/")
    local seen = {}
    local names = {}
    for key in pairs(tree) do
      local rest = key
      if prefix == "" or key:sub(1, #prefix) == prefix then
        if prefix ~= "" then
          rest = key:sub(#prefix + 1)
        end
        local name = rest:match("^([^/]+)")
        if name and not seen[name] then
          seen[name] = true
          names[#names + 1] = name
        end
      end
    end
    table.sort(names)
    return names
  end

  function fs.makeDir(path)
    path = norm(path)
    if path ~= "" and type(tree[path]) ~= "string" then
      tree[path] = true
    end
  end

  function fs.delete(path)
    path = norm(path)
    if path == "" then
      return
    end
    tree[path] = nil
    local prefix = path .. "/"
    for key in pairs(tree) do
      if key:sub(1, #prefix) == prefix then
        tree[key] = nil
      end
    end
  end

  function fs.open(path, mode)
    path = norm(path)
    if mode == "r" then
      if type(tree[path]) ~= "string" then
        return nil
      end
      local data = tree[path]
      local pos = 1
      return {
        readAll = function()
          return data
        end,
        readLine = function()
          if pos > #data then
            return nil
          end
          local newline = data:find("\n", pos, true)
          local line
          if newline then
            line = data:sub(pos, newline - 1):gsub("\r$", "")
            pos = newline + 1
          else
            line = data:sub(pos)
            pos = #data + 1
          end
          return line
        end,
        close = function()
        end,
      }
    end
    if mode == "w" then
      local chunks = {}
      return {
        write = function(text)
          chunks[#chunks + 1] = text
        end,
        close = function()
          tree[path] = table.concat(chunks)
        end,
      }
    end
    return nil
  end

  return fs, tree
end

_G.fakeTerm = fakeTerm
_G.fakeFs = fakeFs

return {
  colors = colors,
  fakeTerm = fakeTerm,
  fakeFs = fakeFs,
}
