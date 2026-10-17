local T = tile_test

T.test("shipped icons are 3 by 2 and labels match the grid", function()
  local icon = dofile("os/icon.lua")
  local function read(path)
    local handle = io.open(path, "r")
    local text = handle:read("*a")
    handle:close()
    return text
  end
  local filesIcon = icon.parse(read("os/builtins/files/icon.nfp"))
  local shellIcon = icon.parse(read("os/builtins/shell/icon.nfp"))
  local settingsIcon = icon.parse(read("os/builtins/settings/icon.nfp"))
  T.assertEq(#filesIcon, 2)
  T.assertEq(#filesIcon[1], 3)
  T.assertEq(#shellIcon[2], 3)
  T.assertEq(#settingsIcon[2], 3)
  T.assertEq(read("os/builtins/files/label"), "Files\n")
  T.assertEq(read("os/builtins/shell/label"), "Shell\n")
  T.assertEq(read("os/builtins/settings/label"), "Sett.\n")
  T.assertEq(read("os/builtins/files/accent"), "blue\n")
  T.assertEq(read("os/builtins/shell/accent"), "lime\n")
  T.assertEq(read("os/builtins/settings/accent"), "orange\n")
end)

T.test("Files pushes edit for a text file", function()
  local runner = dofile("os/runner.lua")
  local tree = {
    ["os/builtins/files/main.lua"] = io.open("os/builtins/files/main.lua", "r"):read("*a"),
    ["readme.txt"] = "hello",
  }
  local fs = fakeFs(tree)
  local frame = runner.launch({
    fs = fs,
    path = "os/builtins/files/main.lua",
    args = {},
    win = fakeTerm(20, 8, true),
    displayName = "terminal",
  })
  T.assertEq(runner.pump(frame, nil).kind, "wait")
  local result = runner.pump(frame, { "mouse_click", 1, 1, 3 })
  T.assertEq(result.kind, "push")
  T.assertEq(result.path, "/rom/programs/edit.lua")
  T.assertDeep(result.args, { "/readme.txt" })
  T.assertEq(result.label, "Files")
end)

T.test("Settings saves a monitor and Shell loads the ROM shell", function()
  local runner = dofile("os/runner.lua")
  local settingsSrc = io.open("os/builtins/settings/main.lua", "r"):read("*a")
  local shellSrc = io.open("os/builtins/shell/main.lua", "r"):read("*a")
  local fs = fakeFs({
    ["os/builtins/settings/main.lua"] = settingsSrc,
    ["os/builtins/shell/main.lua"] = shellSrc,
    ["rom/programs/shell.lua"] = "os.pullEvent()\n",
  })
  _G.peripheral = {
    getNames = function()
      return { "left" }
    end,
    getType = function(name)
      if name == "left" then
        return "monitor"
      end
      return nil
    end,
  }
  local settings = runner.launch({
    fs = fs,
    path = "os/builtins/settings/main.lua",
    args = {},
    win = fakeTerm(30, 12, true),
    displayName = "terminal",
  })
  T.assertEq(runner.pump(settings, nil).kind, "wait")
  local changed = runner.pump(settings, { "mouse_click", 1, 1, 5 })
  T.assertEq(changed.kind, "set_display")
  T.assertEq(changed.name, "left")
  local config = dofile("os/config.lua")
  T.assertEq(config.read(fs), "left")

  local shell = runner.launch({
    fs = fs,
    path = "os/builtins/shell/main.lua",
    args = {},
    win = fakeTerm(20, 8, true),
    displayName = "terminal",
  })
  T.assertEq(runner.pump(shell, nil).kind, "wait")
  T.assertEq(runner.pump(shell, { "key", 1, false }).kind, "exit")
end)
