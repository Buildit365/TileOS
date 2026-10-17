local T = tile_test

T.test("apps can call require and term.current", function()
  local runner = dofile("os/runner.lua")
  local fs = fakeFs({
    ["apps/check/main.lua"] = [[
if type(require) ~= "function" then
  error("require missing", 0)
end
local current = term.current()
current.write("ok")
os.pullEvent()
]],
  })
  local win = fakeTerm(10, 4, true)
  local frame = runner.launch({
    fs = fs,
    path = "apps/check/main.lua",
    args = {},
    win = win,
    displayName = "terminal",
  })
  local result = runner.pump(frame, nil)
  T.assertEq(result.kind, "wait")
  T.assertEq(win.line(1):sub(1, 2), "ok")
end)

T.test("an app receives translated events and can push a child", function()
  local runner = dofile("os/runner.lua")
  local fs = fakeFs({
    ["apps/demo/main.lua"] = [[
local event, button, x, y = os.pullEvent("mouse_click")
tile.push("/rom/programs/edit.lua", { "/readme" }, "Files")
]],
  })
  local frame = runner.launch({
    fs = fs,
    path = "apps/demo/main.lua",
    args = {},
    win = fakeTerm(20, 10, true),
    displayName = "terminal",
  })
  local first = runner.pump(frame, nil)
  T.assertEq(first.kind, "wait")
  local pushed = runner.pump(frame, { "mouse_click", 1, 4, 2 })
  T.assertEq(pushed.kind, "push")
  T.assertEq(pushed.path, "/rom/programs/edit.lua")
  T.assertDeep(pushed.args, { "/readme" })
  T.assertEq(pushed.label, "Files")
  local done = runner.pump(frame, nil)
  T.assertEq(done.kind, "exit")
end)

T.test("terminate and a lua error are reported and do not escape", function()
  local runner = dofile("os/runner.lua")
  local fs = fakeFs({
    ["apps/bad/main.lua"] = [[
os.pullEvent()
error("boom", 0)
]],
    ["apps/stop/main.lua"] = [[
os.pullEvent()
]],
  })
  local bad = runner.launch({
    fs = fs,
    path = "apps/bad/main.lua",
    args = {},
    win = fakeTerm(10, 5, true),
    displayName = "terminal",
  })
  runner.pump(bad, nil)
  local errored = runner.pump(bad, { "key", 1, false })
  T.assertEq(errored.kind, "error")
  T.assertEq(errored.message, "boom")

  local stop = runner.launch({
    fs = fs,
    path = "apps/stop/main.lua",
    args = {},
    win = fakeTerm(10, 5, true),
    displayName = "terminal",
  })
  runner.pump(stop, nil)
  local terminated = runner.pump(stop, { "terminate" })
  T.assertEq(terminated.kind, "terminated")
end)

T.test("tile.load runs a ROM program in the same hooked environment", function()
  local runner = dofile("os/runner.lua")
  local fs = fakeFs({
    ["apps/shell/main.lua"] = [[
tile.load("/rom/programs/shell.lua")()
]],
    ["rom/programs/shell.lua"] = [[
local event, button, x, y = os.pullEvent("mouse_click")
if x ~= 3 then
  error("bad x " .. tostring(x), 0)
end
]],
  })
  local frame = runner.launch({
    fs = fs,
    path = "apps/shell/main.lua",
    args = { "ignored" },
    win = fakeTerm(10, 5, false),
    displayName = "left",
  })
  T.assertEq(frame.env.tile.display, "left")
  local waited = runner.pump(frame, nil)
  T.assertEq(waited.kind, "wait")
  local done = runner.pump(frame, { "mouse_click", 1, 3, 1 })
  T.assertEq(done.kind, "exit")
end)
