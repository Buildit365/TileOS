local T = tile_test

T.test("computer clicks and monitor touches stay on their own screen", function()
  local events = dofile("os/events.lua")
  local computer = { kind = "computer", name = "terminal" }
  local monitor = { kind = "monitor", name = "left" }
  T.assertDeep(events.classify(computer, { "mouse_click", 1, 4, 5 }), {
    kind = "pointer",
    x = 4,
    y = 5,
  })
  T.assertEq(events.classify(computer, { "mouse_click", 2, 4, 5 }).kind, "ignore")
  T.assertEq(events.classify(computer, { "monitor_touch", "left", 4, 5 }).kind, "ignore")
  T.assertDeep(events.classify(monitor, { "monitor_touch", "left", 2, 3 }), {
    kind = "pointer",
    x = 2,
    y = 3,
  })
  T.assertEq(events.classify(monitor, { "monitor_touch", "right", 2, 3 }).kind, "ignore")
  T.assertEq(events.classify(monitor, { "mouse_click", 1, 2, 3 }).kind, "ignore")
end)

T.test("keys pass through and terminate is its own kind", function()
  local events = dofile("os/events.lua")
  local computer = { kind = "computer", name = "terminal" }
  T.assertEq(events.classify(computer, { "terminate" }).kind, "terminate")
  local key = events.classify(computer, { "key", 17, false })
  T.assertEq(key.kind, "pass")
  T.assertEq(key.event[1], "key")
  local drag = events.classify(computer, { "mouse_drag", 1, 3, 4 })
  T.assertEq(drag.kind, "pointer_pass")
  T.assertEq(drag.name, "mouse_drag")
  T.assertEq(drag.x, 3)
  T.assertEq(drag.y, 4)
  T.assertEq(events.classify({ kind = "monitor", name = "left" }, { "mouse_drag", 1, 3, 4 }).kind, "ignore")
end)
