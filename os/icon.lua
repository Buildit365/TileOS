local HEX = {
  ["0"] = colors.white,
  ["1"] = colors.orange,
  ["2"] = colors.magenta,
  ["3"] = colors.lightBlue,
  ["4"] = colors.yellow,
  ["5"] = colors.lime,
  ["6"] = colors.pink,
  ["7"] = colors.gray,
  ["8"] = colors.lightGray,
  ["9"] = colors.cyan,
  a = colors.purple,
  b = colors.blue,
  c = colors.brown,
  d = colors.green,
  e = colors.red,
  f = colors.black,
}

local icon = {}

function icon.parse(text)
  if type(text) ~= "string" then
    return nil, "icon must be text"
  end
  local rows = {}
  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    if line ~= "" then
      rows[#rows + 1] = line
    end
  end
  if #rows ~= 2 then
    return nil, "icon must be 2 rows"
  end
  local picture = {}
  for y = 1, 2 do
    if #rows[y] ~= 3 then
      return nil, "icon must be 3 columns"
    end
    picture[y] = {}
    for x = 1, 3 do
      local pixel = HEX[rows[y]:sub(x, x)]
      if not pixel then
        return nil, "bad icon color"
      end
      picture[y][x] = pixel
    end
  end
  return picture
end

return icon
