local T = tile_test

T.test("directories come before files and dot-dot is hidden at root", function()
  local fileslist = dofile("os/fileslist.lua")
  local fs = fakeFs({
    ["readme.txt"] = "hi",
    ["apps/demo/main.lua"] = "print(1)\n",
    ["rom/programs/edit.lua"] = "-- edit\n",
    ["notes.lua"] = "print(2)\n",
  })
  local entries = fileslist.list(fs, "/")
  local names = {}
  for i = 1, #entries do
    names[i] = entries[i].name .. ":" .. entries[i].kind
  end
  T.assertDeep(names, { "apps:dir", "rom:dir", "notes.lua:lua", "readme.txt:text" })
  local nested = fileslist.list(fs, "/rom")
  T.assertEq(nested[1].name, "..")
  T.assertEq(nested[1].kind, "up")
  T.assertEq(fileslist.parent("/rom/programs"), "/rom")
  T.assertEq(fileslist.parent("/rom"), "/")
  T.assertEq(fileslist.child("/", "rom"), "/rom")
  T.assertEq(fileslist.child("/rom", "programs"), "/rom/programs")
end)

T.test("clicks open directories, edit text, and run lua", function()
  local filesui = dofile("os/filesui.lua")
  local fs = fakeFs({
    ["readme.txt"] = "hi",
    ["apps/demo/main.lua"] = "print(1)\n",
    ["rom/programs/edit.lua"] = "-- edit\n",
  })
  local term = fakeTerm(20, 8, true)
  local model = { path = "/", page = 1 }
  filesui.draw(term, model, fs)
  T.assertEq(term.line(1):sub(1, 1), "/")
  T.assertEq(term.line(2):sub(1, 5), "apps/")
  T.assertEq(term.line(4):sub(1, 10), "readme.txt")

  local command
  model, command = filesui.click(model, term, 1, 2, fs)
  T.assertEq(command, nil)
  T.assertEq(model.path, "/apps")
  filesui.draw(term, model, fs)
  T.assertEq(term.line(2):sub(1, 2), "..")
  T.assertEq(term.line(3):sub(1, 5), "demo/")

  model, command = filesui.click(model, term, 1, 3, fs)
  T.assertEq(model.path, "/apps/demo")
  model, command = filesui.click(model, term, 1, 3, fs)
  T.assertEq(command.type, "push")
  T.assertEq(command.path, "/apps/demo/main.lua")
  T.assertEq(command.label, "Files")

  model = { path = "/", page = 1 }
  model, command = filesui.click(model, term, 1, 4, fs)
  T.assertEq(command.path, "/rom/programs/edit.lua")
  T.assertDeep(command.args, { "/readme.txt" })
end)

T.test("arrow keys follow the file list and enter opens the highlighted row", function()
  local filesui = dofile("os/filesui.lua")
  local fs = fakeFs({
    ["readme.txt"] = "hi",
    ["apps/demo/main.lua"] = "print(1)\n",
  })
  local term = fakeTerm(20, 8, true)
  local model = { path = "/", page = 1, cursor = 1 }
  local command
  model, command = filesui.key(model, term, 28, fs)
  T.assertEq(model.path, "/apps")
  T.assertEq(model.cursor, 1)
  filesui.draw(term, model, fs)
  local _, _, bg = term.cell(1, 2)
  T.assertEq(bg, colors.black)
  model, command = filesui.key(model, term, 208, fs)
  model, command = filesui.key(model, term, 28, fs)
  T.assertEq(model.path, "/apps/demo")
end)

T.test("a long directory pages from Prev and Next", function()
  local filesui = dofile("os/filesui.lua")
  local tree = {}
  for i = 1, 6 do
    tree["f" .. i .. ".txt"] = "x"
  end
  local fs = fakeFs(tree)
  local term = fakeTerm(20, 4, true)
  local model = { path = "/", page = 1 }
  filesui.draw(term, model, fs)
  T.assertEq(term.line(4):sub(1, 4), "Prev")
  T.assertEq(term.line(4):sub(17, 20), "Next")
  model = filesui.click(model, term, 17, 4, fs)
  T.assertEq(model.page, 2)
  filesui.draw(term, model, fs)
  T.assertEq(term.line(2):sub(1, 6), "f3.txt")
end)
