local config = {}
local PATH = ".tile"

function config.read(fs)
  local handle = fs.open(PATH, "r")
  if not handle then
    return nil
  end
  local line = handle.readLine()
  handle.close()
  if not line then
    return nil
  end
  return line:match("^display=(%S+)$")
end

function config.write(fs, name)
  local handle = fs.open(PATH, "w")
  handle.write("display=" .. tostring(name) .. "\n")
  handle.close()
end

return config
