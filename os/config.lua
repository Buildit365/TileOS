local config = {}
local PATH = ".tile"
local ORDER = { "display", "keys", "color" }

local function readMap(fs)
  local found = {}
  local handle = fs.open(PATH, "r")
  if not handle then
    return found
  end
  local text = handle.readAll() or ""
  handle.close()
  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    local key, value = line:match("^(%w+)=(%S+)$")
    if key then
      found[key] = value
    end
  end
  return found
end

local function writeMap(fs, map)
  local handle = fs.open(PATH, "w")
  for i = 1, #ORDER do
    local key = ORDER[i]
    if map[key] then
      handle.write(key .. "=" .. map[key] .. "\n")
    end
  end
  handle.close()
end

function config.read(fs)
  return readMap(fs).display
end

function config.write(fs, name)
  local map = readMap(fs)
  map.display = tostring(name)
  writeMap(fs, map)
end

function config.get(fs, key)
  return readMap(fs)[key]
end

function config.set(fs, key, value)
  local map = readMap(fs)
  if value == nil or value == "" then
    map[key] = nil
  else
    map[key] = tostring(value)
  end
  writeMap(fs, map)
end

return config
