local install = {}

local function norm(path)
  path = tostring(path or "")
  return path:gsub("^/+", ""):gsub("/+$", "")
end

local function copyTree(fs, source, dest)
  if fs.isDir(source) then
    if norm(dest) ~= "" then
      fs.makeDir(dest)
    end
    local names = fs.list(source)
    for i = 1, #names do
      copyTree(fs, fs.combine(source, names[i]), fs.combine(dest, names[i]))
    end
    return
  end
  local handle = fs.open(source, "r")
  local data = handle.readAll()
  handle.close()
  local parent = fs.getDir(dest)
  if parent ~= "" and not fs.exists(parent) then
    fs.makeDir(parent)
  end
  local out = fs.open(dest, "w")
  out.write(data)
  out.close()
end

function install.run(fs, sourceDir, ask)
  local source = fs.combine(sourceDir, "os")
  local target = "/os"
  if norm(source) ~= norm(target) then
    if fs.exists(target) then
      fs.delete(target)
    end
    copyTree(fs, source, target)
  end
  local startup = "/startup.lua"
  if fs.exists(startup) then
    local answer = ask("Replace startup.lua? (y/n)")
    if not answer or answer:lower() ~= "y" then
      return "kept"
    end
  end
  local handle = fs.open(startup, "w")
  handle.write("shell.run(\"/os/main.lua\")\n")
  handle.close()
  return "replaced"
end

local function runningAsProgram()
  return shell and shell.getRunningProgram and fs.getName(shell.getRunningProgram()) == "install.lua"
end

if runningAsProgram() then
  local dir = fs.getDir(shell.getRunningProgram())
  install.run(fs, dir, function(prompt)
    print(prompt)
    return read()
  end)
end

return install
