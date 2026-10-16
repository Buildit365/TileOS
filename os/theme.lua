local NAMES = {
  white = colors.white,
  orange = colors.orange,
  magenta = colors.magenta,
  lightBlue = colors.lightBlue,
  yellow = colors.yellow,
  lime = colors.lime,
  pink = colors.pink,
  gray = colors.gray,
  grey = colors.gray,
  lightGray = colors.lightGray,
  lightGrey = colors.lightGray,
  cyan = colors.cyan,
  purple = colors.purple,
  blue = colors.blue,
  brown = colors.brown,
  green = colors.green,
  red = colors.red,
  black = colors.black,
}

local theme = {}

function theme.resolveAccent(name, isColor)
  local accent = NAMES[name or ""] or colors.cyan
  if not isColor then
    return colors.gray
  end
  return accent
end

function theme.remap(picture, isColor, accentName)
  local accent = theme.resolveAccent(accentName, isColor)
  local out = {}
  for y = 1, #picture do
    out[y] = {}
    for x = 1, #picture[y] do
      local pixel = picture[y][x]
      if pixel == colors.blue then
        out[y][x] = accent
      elseif not isColor and pixel ~= colors.white and pixel ~= colors.black and pixel ~= colors.lightGray and pixel ~= colors.gray then
        out[y][x] = colors.gray
      else
        out[y][x] = pixel
      end
    end
  end
  return out
end

return theme
