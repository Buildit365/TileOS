local fn, err = tile.load("/rom/programs/shell.lua")
if not fn then
  error(err, 0)
end
fn()
