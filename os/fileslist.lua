local fileslist = {}

local function isRoot(path)
  return path == nil or path == "" or path == "/"
end

function fileslist.parent(path)
  if isRoot(path) then
    return "/"
  end
  local trimmed = path:gsub("/+$", "")
  local parent = trimmed:match("^(.*)/[^/]+$")
  if not parent or parent == "" then
    return "/"
  end
  return parent
end

function fileslist.child(path, name)
  if isRoot(path) then
    return "/" .. name
  end
  return path:gsub("/+$", "") .. "/" .. name
end

function fileslist.list(fs, path)
  local names = fs.list(path)
  local dirs = {}
  local files = {}
  for i = 1, #names do
    local name = names[i]
    local full = fileslist.child(path, name)
    if fs.isDir(full) then
      dirs[#dirs + 1] = { name = name, kind = "dir" }
    elseif name:sub(-4):lower() == ".lua" then
      files[#files + 1] = { name = name, kind = "lua" }
    else
      files[#files + 1] = { name = name, kind = "text" }
    end
  end
  table.sort(dirs, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  table.sort(files, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  local out = {}
  if not isRoot(path) then
    out[1] = { name = "..", kind = "up" }
  end
  for i = 1, #dirs do
    out[#out + 1] = dirs[i]
  end
  for i = 1, #files do
    out[#out + 1] = files[i]
  end
  return out
end

return fileslist
