local T = tile_test

T.test("the home bar names Tile and shows arrows only when paged", function()
  local draw = dofile("os/draw.lua")
  local term = fakeTerm(26, 20, true)
  draw.bar(term, { mode = "home", pages = 1 })
  T.assertEq(term.line(1), "Tile" .. string.rep(" ", 22))
  draw.bar(term, { mode = "home", pages = 3 })
  T.assertEq(term.line(1):sub(1, 4), "Tile")
  T.assertEq(term.line(1):sub(24, 26), "< >")
  draw.bar(term, { mode = "app", label = "Files" })
  T.assertEq(term.line(1):sub(1, 10), "Home Files")
end)

T.test("a letter tile and a painted tile land on the grid", function()
  local draw = dofile("os/draw.lua")
  local layout = dofile("os/layout.lua")
  local term = fakeTerm(15, 10, true)
  local metrics = layout.metrics(15, 10)
  draw.home(term, metrics, {
    { label = "Files", accent = "blue", icon = nil },
  }, 1, true)
  T.assertEq(term.line(4):sub(1, 5), "Files")
  local ch, _, bg = term.cell(3, 2)
  T.assertEq(ch, "F")
  T.assertEq(bg, colors.white)

  local picture = {
    { colors.white, colors.blue, colors.black },
    { colors.black, colors.black, colors.black },
  }
  draw.home(term, metrics, {
    { label = "Shell", accent = "lime", icon = picture },
  }, 1, true)
  local _, _, accent = term.cell(3, 2)
  T.assertEq(accent, colors.lime)
end)

T.test("errors and the too-small message use the locked strings", function()
  local draw = dofile("os/draw.lua")
  local term = fakeTerm(20, 8, false)
  draw.error(term, "boom")
  T.assertEq(term.line(1):sub(1, 9), "App error")
  T.assertEq(term.line(2):sub(1, 4), "boom")
  draw.tooSmall(term, true)
  T.assertEq(term.line(1):sub(1, 16), "Screen too small")
  T.assertEq(term.line(2):sub(1, 16), "Lower text scale")
  T.assertEq(term.line(3):sub(1, 13), "or add blocks")
  T.assertEq(term.line(5):sub(1, 12), "Use computer")
  draw.tooSmall(term, false)
  T.assertEq(term.line(5):sub(1, 12), string.rep(" ", 12))
  draw.status(term)
  T.assertEq(term.line(1):sub(1, 18), "Showing on monitor")
end)
