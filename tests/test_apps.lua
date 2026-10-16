local T = tile_test

local function fixture()
  return fakeFs({
    ["os/builtins/files/main.lua"] = "-- files\n",
    ["os/builtins/files/label"] = "Files\n",
    ["os/builtins/files/accent"] = "blue\n",
    ["os/builtins/files/icon.nfp"] = "8bb\nbbb\n",
    ["os/builtins/shell/main.lua"] = "-- shell\n",
    ["os/builtins/shell/label"] = "Shell\n",
    ["os/builtins/shell/accent"] = "lime\n",
    ["os/builtins/shell/icon.nfp"] = "fbf\nfff\n",
    ["os/builtins/settings/main.lua"] = "-- settings\n",
    ["os/builtins/settings/label"] = "Sett.\n",
    ["os/builtins/settings/accent"] = "orange\n",
    ["os/builtins/settings/icon.nfp"] = "8b8\n8b8\n",
    ["apps/zeta/main.lua"] = "-- z\n",
    ["apps/alpha/main.lua"] = "-- a\n",
    ["apps/alpha/label"] = "Alpha\n",
    ["apps/alpha/accent"] = "red\n",
    ["apps/alpha/icon.nfp"] = "not an icon\n",
    ["apps/bad/readme.txt"] = "no main\n",
    ["apps/mid/main.lua"] = "-- m\n",
    ["apps/mid/label"] = "Toolshed\n",
  })
end

T.test("labels shorten to five characters", function()
  local apps = dofile("os/apps.lua")
  T.assertEq(apps.shorten("Files"), "Files")
  T.assertEq(apps.shorten("Toolshed"), "Tools")
  T.assertEq(apps.shorten("  Hi  "), "Hi")
end)

T.test("built-ins come first and broken folders are skipped", function()
  local apps = dofile("os/apps.lua")
  local found = apps.discover(fixture(), "os")
  local ids = {}
  for i = 1, #found do
    ids[i] = found[i].id
  end
  T.assertDeep(ids, { "files", "shell", "settings", "alpha", "mid", "zeta" })
  T.assertEq(found[1].label, "Files")
  T.assertEq(found[1].accent, "blue")
  T.assertEq(found[1].icon[1][2], colors.blue)
  T.assertEq(found[2].accent, "lime")
  T.assertEq(found[3].label, "Sett.")
  T.assertEq(found[3].accent, "orange")
  T.assertEq(found[4].label, "Alpha")
  T.assertEq(found[4].accent, "red")
  T.assertEq(found[4].icon, nil)
  T.assertEq(found[5].label, "Tools")
  T.assertEq(found[6].label, "zeta")
  T.assertEq(found[6].accent, "cyan")
  T.assertEq(found[4].path, "apps/alpha/main.lua")
end)

T.test("missing built-ins and a missing apps folder still return a list", function()
  local apps = dofile("os/apps.lua")
  local found = apps.discover(fakeFs({}), "os")
  T.assertEq(#found, 0)
end)
