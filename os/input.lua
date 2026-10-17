local input = {}

local FALLBACK = {
  enter = 28,
  numPadEnter = 156,
  up = 200,
  down = 208,
  left = 203,
  right = 205,
}

function input.code(name)
  if type(keys) == "table" and type(keys[name]) == "number" then
    return keys[name]
  end
  return FALLBACK[name]
end

function input.isEnter(code)
  return code == input.code("enter") or code == input.code("numPadEnter")
end

function input.direction(code)
  if code == input.code("up") then
    return "up"
  end
  if code == input.code("down") then
    return "down"
  end
  if code == input.code("left") then
    return "left"
  end
  if code == input.code("right") then
    return "right"
  end
  return nil
end

return input
