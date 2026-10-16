local T = tile_test

T.test("a 3 by 2 nfp parses into color numbers", function()
  local icon = dofile("os/icon.lua")
  local picture, err = icon.parse("8bb\nbbb\n")
  T.assertEq(err, nil)
  T.assertDeep(picture, {
    { colors.lightGray, colors.blue, colors.blue },
    { colors.blue, colors.blue, colors.blue },
  })
end)

T.test("carriage returns are ignored", function()
  local icon = dofile("os/icon.lua")
  local picture = icon.parse("fbf\r\nfff\r\n")
  T.assertDeep(picture, {
    { colors.black, colors.blue, colors.black },
    { colors.black, colors.black, colors.black },
  })
end)

T.test("the wrong size is rejected", function()
  local icon = dofile("os/icon.lua")
  local picture, err = icon.parse("8bb\n")
  T.assertEq(picture, nil)
  T.assertEq(type(err), "string")
  picture, err = icon.parse("zzzz\nbbbb\n")
  T.assertEq(picture, nil)
  T.assertEq(type(err), "string")
end)
