local icon = require("icon")

local apps = {}

local BUILTINS = {
  { id = "files", fallback = "Files", accent = "blue" },
  { id = "shell", fallback = "Shell", accent = "lime" },
  { id = "settings", fallback = "Sett.", accent = "orange" },
}

function apps.shorten(text)
  text = tostring(text or "")
  text = text:gsub("\r", "")
  text = text:match("^%s*(.-)%s*$") or ""
  if text == "" then
    return ""
  end
  return text:sub(1, 5)
end

local function readLine(fs, path)
  local handle = fs.open(path, "r")
  if not handle then
    return nil
  end
  local line = handle.readLine()
  handle.close()
  return line
end

local function loadIcon(fs, path)
  local handle = fs.open(path, "r")
  if not handle then
    return nil
  end
  local text = handle.readAll()
  handle.close()
  return icon.parse(text)
end

local function addApp(out, spec)
  local label = apps.shorten(spec.label)
  if label == "" then
    label = apps.shorten(spec.fallback or spec.id)
  end
  out[#out + 1] = {
    id = spec.id,
    label = label,
    accent = spec.accent or "cyan",
    path = spec.path,
    icon = spec.icon,
    folder = spec.folder or spec.id,
  }
end

function apps.discover(fs, osDir)
  local found = {}
  for i = 1, #BUILTINS do
    local spec = BUILTINS[i]
    local dir = fs.combine(fs.combine(osDir, "builtins"), spec.id)
    local path = fs.combine(dir, "main.lua")
    if fs.exists(path) and not fs.isDir(path) then
      addApp(found, {
        id = spec.id,
        fallback = spec.fallback,
        label = readLine(fs, fs.combine(dir, "label")) or spec.fallback,
        accent = readLine(fs, fs.combine(dir, "accent")) or spec.accent,
        path = path,
        icon = loadIcon(fs, fs.combine(dir, "icon.nfp")),
        folder = spec.id,
      })
    end
  end

  local users = {}
  if fs.exists("apps") and fs.isDir("apps") then
    local names = fs.list("apps")
    for i = 1, #names do
      local folder = names[i]
      local dir = fs.combine("apps", folder)
      local path = fs.combine(dir, "main.lua")
      if fs.isDir(dir) and fs.exists(path) and not fs.isDir(path) then
        local accent = readLine(fs, fs.combine(dir, "accent")) or "cyan"
        users[#users + 1] = {
          id = folder,
          fallback = folder,
          label = readLine(fs, fs.combine(dir, "label")) or folder,
          accent = accent,
          path = path,
          icon = loadIcon(fs, fs.combine(dir, "icon.nfp")),
          folder = folder,
        }
      end
    end
  end
  table.sort(users, function(a, b)
    local left = apps.shorten(a.label):lower()
    local right = apps.shorten(b.label):lower()
    if left == right then
      return a.folder:lower() < b.folder:lower()
    end
    return left < right
  end)
  for i = 1, #users do
    addApp(found, users[i])
  end
  return found
end

return apps
