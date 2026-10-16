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
        local slot = cell(curX, curY)
        slot[1] = text:sub(i, i)
        slot[2] = fg
        slot[3] = bg
      end
      curX = curX + 1
    end
  end

  function term.clear()
    buf = {}
    for y = 1, h do
      for x = 1, w do
        cell(x, y)
        buf[y][x] = { " ", fg, bg }
      end
    end
  end

  function term.clearLine()
    if curY < 1 or curY > h then
      return
    end
    for x = 1, w do
      buf[curY][x] = { " ", fg, bg }
    end
  end

  function term.setCursorBlink()
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

return {
  colors = colors,
  fakeTerm = fakeTerm,
}
