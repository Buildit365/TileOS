local inner = term

local function paint()
  inner.setBackgroundColor(colors.white)
  inner.setTextColor(colors.black)
end

paint()
inner.clear()
inner.setCursorPos(1, 1)

local locked = {}
for key, value in pairs(inner) do
  if type(value) == "function" then
    locked[key] = value
  end
end

function locked.setBackgroundColor()
  paint()
end
locked.setBackgroundColour = locked.setBackgroundColor

function locked.setTextColor()
  paint()
end
locked.setTextColour = locked.setTextColor

function locked.clear()
  paint()
  inner.clear()
end

function locked.clearLine()
  paint()
  inner.clearLine()
end

function locked.write(text)
  paint()
  inner.write(text)
end

function locked.scroll(n)
  paint()
  inner.scroll(n)
end

function locked.blit(text)
  paint()
  local width = #tostring(text)
  if inner.blit then
    inner.blit(text, string.rep("f", width), string.rep("0", width))
  else
    inner.write(text)
  end
end

function locked.current()
  return locked
end

term = locked

local fn, err = tile.load("/rom/programs/shell.lua")
if not fn then
  error(err, 0)
end
fn()
