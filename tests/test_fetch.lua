local T = tile_test

local function read(path)
  local handle = io.open(path, "r")
  T.assertEq(type(handle), "userdata", path)
  local text = handle:read("*a")
  handle:close()
  return text
end

local function listFiles()
  local pipe = io.popen("find install.lua os -type f")
  local names = {}
  for name in pipe:lines() do
    names[#names + 1] = name
  end
  pipe:close()
  table.sort(names)
  return names
end

T.test("fetch lists every Tile file and asks before overwriting", function()
  local fetch = dofile("fetch.lua")
  local found = listFiles()
  local listed = {}
  for i = 1, #fetch.files do
    listed[i] = fetch.files[i]
  end
  table.sort(listed)
  T.assertDeep(listed, found)

  local source = read("fetch.lua")
  T.assertEq(source:find("Overwrite them? (y/n)", 1, true) ~= nil, true)
  T.assertEq(source:find("os.reboot", 1, true), nil)
  T.assertEq(fetch.confirmOverwrite(0, nil), true)
  T.assertEq(fetch.confirmOverwrite(4, "n"), false)
  T.assertEq(fetch.confirmOverwrite(4, "y"), true)
  T.assertEq(fetch.launchesTile('shell.run("/os/main.lua")\n'), true)
  T.assertEq(fetch.launchesTile("print('hello')\n"), false)
  T.assertEq(fetch.accepted("os/main.lua", "<html>no</html>"), false)
  T.assertEq(fetch.accepted("os/main.lua", read("os/main.lua")), true)
  T.assertEq(fetch.accepted("os/tabs.lua", read("os/tabs.lua")), true)
  T.assertEq(fetch.accepted("os/builtins/files/label", read("os/builtins/files/label")), true)
  T.assertEq(fetch.accepted("os/builtins/files/icon.nfp", read("os/builtins/files/icon.nfp")), true)
end)
