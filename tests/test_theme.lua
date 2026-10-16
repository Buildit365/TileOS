local T = tile_test
local colors = colors

T.test("cyan is the fallback accent on a color screen", function()
  local theme = dofile("os/theme.lua")
  T.assertEq(theme.resolveAccent(nil, true), colors.cyan)
  T.assertEq(theme.resolveAccent("nope", true), colors.cyan)
  T.assertEq(theme.resolveAccent("lime", true), colors.lime)
  T.assertEq(theme.resolveAccent("grey", true), colors.gray)
end)

T.test("a basic screen collapses the accent to gray", function()
  local theme = dofile("os/theme.lua")
  T.assertEq(theme.resolveAccent("lime", false), colors.gray)
  T.assertEq(theme.resolveAccent("blue", false), colors.gray)
end)

T.test("remap recolors blue and leaves the other tones on a color screen", function()
  local theme = dofile("os/theme.lua")
  local picture = {
    { colors.white, colors.blue, colors.black },
    { colors.lightGray, colors.red, colors.blue },
  }
  T.assertDeep(theme.remap(picture, true, "lime"), {
    { colors.white, colors.lime, colors.black },
    { colors.lightGray, colors.red, colors.lime },
  })
end)

T.test("remap turns blue and stray colors gray on a basic screen", function()
  local theme = dofile("os/theme.lua")
  local picture = {
    { colors.white, colors.blue, colors.black },
    { colors.lightGray, colors.red, colors.blue },
  }
  T.assertDeep(theme.remap(picture, false, "lime"), {
    { colors.white, colors.gray, colors.black },
    { colors.lightGray, colors.gray, colors.gray },
  })
end)
