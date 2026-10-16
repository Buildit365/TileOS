local T = tile_test

local function ctx(w, h, count)
  local layout = dofile("os/layout.lua")
  local apps = {}
  for i = 1, count do
    apps[i] = { path = "/apps/" .. i .. "/main.lua", label = "A" .. i, id = "a" .. i }
  end
  return { apps = apps, metrics = layout.metrics(w, h) }
end

T.test("a grid click launches that app", function()
  local session = dofile("os/session.lua")
  local state, effect = session.reduce(session.new(), { type = "click", x = 1, y = 2 }, ctx(51, 19, 3))
  T.assertEq(effect, "launch")
  T.assertEq(state.screen, "app")
  T.assertEq(state.stack[1].label, "A1")
  T.assertEq(state.stack[1].path, "/apps/1/main.lua")
end)

T.test("Home and Ctrl+T clear the stack", function()
  local session = dofile("os/session.lua")
  local state = session.new()
  state, _ = session.reduce(state, { type = "click", x = 1, y = 2 }, ctx(51, 19, 1))
  state, _ = session.reduce(state, {
    type = "push",
    path = "/rom/programs/edit.lua",
    args = { "/readme" },
    label = "A1",
  }, ctx(51, 19, 1))
  T.assertEq(#state.stack, 2)
  local effect
  state, effect = session.reduce(state, { type = "terminate" }, ctx(51, 19, 1))
  T.assertEq(effect, "go_home")
  T.assertEq(state.screen, "home")
  T.assertEq(#state.stack, 0)
  state, effect = session.reduce(state, { type = "terminate" }, ctx(51, 19, 1))
  T.assertEq(effect, "exit_os")
end)

T.test("a child exit resumes the parent and an error stays until Home", function()
  local session = dofile("os/session.lua")
  local state, effect = session.reduce(session.new(), { type = "click", x = 1, y = 2 }, ctx(51, 19, 1))
  state, effect = session.reduce(state, { type = "child_error", message = "boom" }, ctx(51, 19, 1))
  T.assertEq(effect, "show_error")
  T.assertEq(state.error, "boom")
  T.assertEq(state.screen, "app")
  state, effect = session.reduce(state, { type = "click", x = 1, y = 1 }, ctx(51, 19, 1))
  T.assertEq(effect, "go_home")
  T.assertEq(state.error, nil)

  state = session.new()
  state = session.reduce(state, { type = "click", x = 1, y = 2 }, ctx(51, 19, 1))
  state = session.reduce(state, { type = "push", path = "/edit", args = {}, label = "A1" }, ctx(51, 19, 1))
  state, effect = session.reduce(state, { type = "child_done" }, ctx(51, 19, 1))
  T.assertEq(effect, "resume")
  T.assertEq(#state.stack, 1)
  state, effect = session.reduce(state, { type = "child_done" }, ctx(51, 19, 1))
  T.assertEq(effect, "go_home")
  T.assertEq(state.screen, "home")
end)

T.test("page arrows clamp and a too-small click clears the display", function()
  local session = dofile("os/session.lua")
  local state, effect = session.reduce(session.new(), { type = "click", x = 51, y = 1 }, ctx(51, 19, 40))
  T.assertEq(state.page, 2)
  state, effect = session.reduce(state, { type = "click", x = 51, y = 1 }, ctx(51, 19, 40))
  T.assertEq(state.page, 2)
  state, effect = session.reduce(state, { type = "click", x = 49, y = 1 }, ctx(51, 19, 40))
  T.assertEq(state.page, 1)
  T.assertEq(effect, nil)

  local tiny = ctx(7, 5, 1)
  state = session.new()
  state.screen = "toosmall"
  state, effect = session.reduce(state, { type = "click", x = 1, y = 5 }, tiny)
  T.assertEq(effect, "clear_display")
end)
