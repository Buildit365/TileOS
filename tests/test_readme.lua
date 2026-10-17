local T = tile_test

local function read(path)
  local handle = io.open(path, "r")
  T.assertEq(type(handle), "userdata", path)
  local text = handle:read("*a")
  handle:close()
  return text
end

local function listLua()
  local pipe = io.popen("find os install.lua -name '*.lua'")
  local names = {}
  for name in pipe:lines() do
    names[#names + 1] = name
  end
  pipe:close()
  table.sort(names)
  return names
end

T.test("the readme tells a player how to install and how to get home", function()
  local text = read("README.md")
  T.assertEq(text:find("CC:Tweaked", 1, true) ~= nil, true)
  T.assertEq(text:find("1.20.1", 1, true) ~= nil, true)
  T.assertEq(text:find("startup.lua", 1, true) ~= nil, true)
  T.assertEq(text:find("/apps", 1, true) ~= nil, true)
  T.assertEq(text:find("Ctrl+T", 1, true) ~= nil, true)
  T.assertEq(text:find("lua5.1 tests/run.lua", 1, true) ~= nil, true)
  T.assertEq(text:find("Sett.", 1, true) ~= nil, true)
end)

T.test("Tile does not change monitor scale or reboot the computer", function()
  local names = listLua()
  T.assertEq(#names > 0, true)
  for i = 1, #names do
    local text = read(names[i])
    T.assertEq(text:find("setTextScale", 1, true), nil, names[i])
    T.assertEq(text:find("os.reboot", 1, true), nil, names[i])
    T.assertEq(text:find("os.shutdown", 1, true), nil, names[i])
  end
end)
