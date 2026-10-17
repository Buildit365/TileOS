local fetch = {}

fetch.files = {
  "install.lua",
  "os/apps.lua",
  "os/builtins/files/accent",
  "os/builtins/files/icon.nfp",
  "os/builtins/files/label",
  "os/builtins/files/main.lua",
  "os/builtins/settings/accent",
  "os/builtins/settings/icon.nfp",
  "os/builtins/settings/label",
  "os/builtins/settings/main.lua",
  "os/builtins/shell/accent",
  "os/builtins/shell/icon.nfp",
  "os/builtins/shell/label",
  "os/builtins/shell/main.lua",
  "os/config.lua",
  "os/display.lua",
  "os/draw.lua",
  "os/events.lua",
  "os/fileslist.lua",
  "os/filesui.lua",
  "os/icon.lua",
  "os/layout.lua",
  "os/main.lua",
  "os/runner.lua",
  "os/runtime.lua",
  "os/session.lua",
  "os/settingsui.lua",
  "os/tabs.lua",
  "os/theme.lua",
}

local startupLine = 'shell.run("/os/main.lua")\n'

function fetch.accepted(name, body)
  if type(body) ~= "string" or body == "" or body:sub(1, 1) == "<" then
    return false
  end
  if name:sub(-4) == ".lua" then
    if body:sub(1, 6) ~= "local " then
      return false
    end
    local loader = loadstring or load
    local compiled
    if loader == loadstring then
      compiled = loader(body, "@/" .. name)
    else
      compiled = loader(body, "@/" .. name, "t", {})
    end
    return compiled ~= nil
  end
  if name:sub(-4) == ".nfp" then
    return #body >= 7 and #body <= 16
  end
  return #body >= 2 and #body <= 16
end

function fetch.launchesTile(text)
  if type(text) ~= "string" then
    return false
  end
  return text:find('shell.run("/os/main.lua")', 1, true) ~= nil
    or text:find("shell.run('/os/main.lua')", 1, true) ~= nil
end

function fetch.confirmOverwrite(existingCount, answer)
  if existingCount <= 0 then
    return true
  end
  return type(answer) == "string" and answer:lower() == "y"
end

local function dirname(path)
  return path:match("^(.*)/[^/]+$")
end

local function runningAsProgram()
  if not shell or not shell.getRunningProgram then
    return false
  end
  local name = fs.getName(shell.getRunningProgram())
  return name == "fetch" or name == "fetch.lua"
end

local function download(url)
  local response = http.get(url)
  if not response then
    return nil
  end
  local code = response.getResponseCode and response.getResponseCode()
  local body = response.readAll()
  response.close()
  if code and code ~= 200 then
    return nil
  end
  if type(body) ~= "string" or body == "" then
    return nil
  end
  return body
end

local function save(path, body)
  local dir = dirname(path)
  if dir and dir ~= "" and not fs.exists(dir) then
    fs.makeDir(dir)
  end
  local handle = fs.open(path, "wb")
  if not handle then
    return false
  end
  handle.write(body)
  handle.close()
  return true
end

local function readAll(path)
  local handle = fs.open(path, "r")
  if not handle then
    return nil
  end
  local text = handle.readAll()
  handle.close()
  return text
end

local function ensureStartup()
  local path = "/startup.lua"
  local current = readAll(path)
  if fetch.launchesTile(current) then
    print("startup.lua already opens Tile.")
    return true
  end
  if current ~= nil then
    print("startup.lua does not open Tile.")
    print("Replace startup.lua? (y/n)")
    local answer = read()
    if not fetch.confirmOverwrite(1, answer) then
      print("Left startup.lua unchanged.")
      return false
    end
  end
  local handle = fs.open(path, "wb")
  if not handle then
    print("Could not write startup.lua")
    return false
  end
  handle.write(startupLine)
  handle.close()
  print("Wrote startup.lua")
  return true
end

local function run()
  if not http then
    print("Enable the HTTP API for this computer.")
    return
  end

  local base = "https://raw.githubusercontent.com/Buildit365/TileOS/main/"
  local mirror = "https://cdn.jsdelivr.net/gh/Buildit365/TileOS@main/"
  local existing = 0
  for i = 1, #fetch.files do
    if fs.exists("/" .. fetch.files[i]) then
      existing = existing + 1
    end
  end

  local overwrite = true
  if existing > 0 then
    print(existing .. " files already exist.")
    print("Overwrite them? (y/n)")
    overwrite = fetch.confirmOverwrite(existing, read())
    if not overwrite then
      print("Keeping the files that are already there.")
    end
  end

  local failed = {}
  for i = 1, #fetch.files do
    local name = fetch.files[i]
    local path = "/" .. name
    if fs.exists(path) and not overwrite then
      print(name .. " kept")
    else
      write(name .. " ")
      local body = download(base .. name)
      if not fetch.accepted(name, body) then
        body = download(mirror .. name)
      end
      if fetch.accepted(name, body) and save(path, body) then
        print("ok")
      else
        failed[#failed + 1] = name
        print("failed")
      end
    end
  end

  if #failed > 0 then
    print(#failed .. " failed:")
    for i = 1, #failed do
      print(failed[i])
    end
    print("Fix the failed files before rebooting.")
    return
  end

  if not fs.exists("/os/main.lua") then
    print("os/main.lua is missing, so Tile cannot start.")
    return
  end

  local ready = ensureStartup()
  if ready then
    print("Reboot the computer. Tile will open.")
  else
    print("Reboot will not open Tile until startup.lua runs it.")
  end
end

if runningAsProgram() then
  run()
end

return fetch
