local harness = dofile("tests/harness.lua")
_G.tile_test = harness
dofile("tests/cc.lua")
package.path = "os/?.lua;" .. package.path

local pipe = io.popen("ls tests/test_*.lua")
local names = {}
if pipe then
  for name in pipe:lines() do
    names[#names + 1] = name
  end
  pipe:close()
end
table.sort(names)

for i = 1, #names do
  local ok, err = pcall(dofile, names[i])
  if not ok then
    io.write("FAIL load " .. names[i] .. "\n" .. tostring(err) .. "\n")
    harness.failLoad()
  end
end

harness.run()
