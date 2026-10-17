local unpack = unpack or table.unpack

local runtime = {}

function runtime.pack(...)
  return { n = select("#", ...), ... }
end

function runtime.unpack(packed)
  if packed == nil then
    return
  end
  return unpack(packed, 1, packed.n or #packed)
end

function runtime.unpackList(list)
  return unpack(list, 1, #list)
end

function runtime.loadWithEnv(src, chunkName, env)
  if not setfenv then
    return load(src, chunkName, "t", env)
  end
  local fn, err = loadstring(src, chunkName)
  if not fn then
    return nil, err
  end
  setfenv(fn, env)
  return fn
end

return runtime
