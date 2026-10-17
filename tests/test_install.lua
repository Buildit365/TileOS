local T = tile_test

T.test("install copies os, writes startup, and keeps .tile", function()
  local install = dofile("install.lua")
  local fs = fakeFs({
    ["disk/os/main.lua"] = "return {}\n",
    ["disk/os/theme.lua"] = "return {}\n",
    [".tile"] = "display=left\n",
    ["os/old.lua"] = "stale\n",
  })
  local asked = false
  local result = install.run(fs, "disk", function()
    asked = true
    return "y"
  end)
  T.assertEq(asked, false)
  T.assertEq(result, "replaced")
  T.assertEq(fs.open("os/main.lua", "r").readAll(), "return {}\n")
  T.assertEq(fs.open("os/theme.lua", "r").readAll(), "return {}\n")
  T.assertEq(fs.exists("os/old.lua"), false)
  T.assertEq(fs.open("startup.lua", "r").readAll(), "shell.run(\"/os/main.lua\")\n")
  T.assertEq(fs.open(".tile", "r").readAll(), "display=left\n")
end)

T.test("an existing startup is replaced only when the answer is y", function()
  local install = dofile("install.lua")
  local fs = fakeFs({
    ["disk/os/main.lua"] = "return {}\n",
    ["startup.lua"] = "print('old')\n",
  })
  local prompt
  local result = install.run(fs, "disk", function(text)
    prompt = text
    return "n"
  end)
  T.assertEq(prompt, "Replace startup.lua? (y/n)")
  T.assertEq(result, "kept")
  T.assertEq(fs.open("startup.lua", "r").readAll(), "print('old')\n")
  T.assertEq(fs.open("os/main.lua", "r").readAll(), "return {}\n")

  result = install.run(fs, "disk", function()
    return "Y"
  end)
  T.assertEq(result, "replaced")
  T.assertEq(fs.open("startup.lua", "r").readAll(), "shell.run(\"/os/main.lua\")\n")
end)

T.test("install from the computer root does not delete the source it is copying", function()
  local install = dofile("install.lua")
  local fs = fakeFs({
    ["os/main.lua"] = "return {}\n",
  })
  local result = install.run(fs, "", function()
    error("should not ask")
  end)
  T.assertEq(result, "replaced")
  T.assertEq(fs.open("os/main.lua", "r").readAll(), "return {}\n")
  T.assertEq(fs.open("startup.lua", "r").readAll(), "shell.run(\"/os/main.lua\")\n")
end)
