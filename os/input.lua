local input = {}

local FALLBACK = {
  enter = 28,
  numPadEnter = 156,
  up = 200,
  down = 208,
  left = 203,
  right = 205,
  t = 84,
  leftCtrl = 341,
  rightCtrl = 345,
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

function input.isCtrl(code)
  return code == input.code("leftCtrl") or code == input.code("rightCtrl")
end

function input.isTerminateKey(code)
  return code == input.code("t")
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
