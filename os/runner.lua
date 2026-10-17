local runtime = require("runtime")

local runner = {}

local function readAll(fs, path)
  local handle = fs.open(path, "r")
  if not handle then
    return nil, "missing " .. tostring(path)
  end
  local text = handle.readAll()
  handle.close()
  return text
end

local function copyFunctions(into, source)
  if type(source) ~= "table" then
    return
  end
  for key, value in pairs(source) do
    if type(value) == "function" then
      into[key] = value
    end
  end
end

local function appTerm(win)
  local proxy = {}
  if type(term) == "table" then
    copyFunctions(proxy, term)
    if type(term.current) == "function" then
      copyFunctions(proxy, term.current())
    end
  end
  copyFunctions(proxy, win)
  function proxy.current()
    return proxy
  end
  if type(term) == "table" and type(term.native) == "function" then
    function proxy.native()
      return term.native()
    end
  end
  if type(term) == "table" and type(term.redirect) == "function" then
    function proxy.redirect(target)
      if target == proxy then
        target = win
      end
      return term.redirect(target)
    end
  else
    function proxy.redirect()
      return proxy
    end
  end
  return proxy
end

local function copyVisible(into, source, seen)
  if type(source) ~= "table" or seen[source] then
    return
  end
  seen[source] = true
  for key, value in pairs(source) do
    into[key] = value
  end
  local meta = getmetatable(source)
  if type(meta) == "table" then
    copyVisible(into, meta.__index, seen)
  end
end

function runner.launch(spec)
  local env = {}
  local seen = {}
  copyVisible(env, _G, seen)
  copyVisible(env, spec.parentEnv, seen)
  env._G = _G
  env.term = appTerm(spec.win)
  env.fs = spec.fs
  env.os = setmetatable({}, { __index = os })

  function env.os.pullEventRaw(filter)
    while true do
      local packed = runtime.pack(coroutine.yield("pull", filter))
      if packed[1] == "terminate" or filter == nil or packed[1] == filter then
        return runtime.unpack(packed)
      end
    end
  end

  function env.os.pullEvent(filter)
    local packed = runtime.pack(env.os.pullEventRaw(filter))
    if packed[1] == "terminate" then
      error("Terminated", 0)
    end
    return runtime.unpack(packed)
  end

  env.tile = {
    display = spec.displayName or "terminal",
  }

  function env.tile.push(path, args, label)
    coroutine.yield("push", path, args or {}, label)
  end

  function env.tile.setDisplay(name)
    coroutine.yield("set_display", name)
  end

  function env.tile.exit()
    coroutine.yield("exit_os")
  end

  function env.tile.load(path)
    local src, err = readAll(spec.fs, path)
    if not src then
      return nil, err
    end
    return runtime.loadWithEnv(src, "@" .. path, env)
  end

  local src, err = readAll(spec.fs, spec.path)
  if not src then
    error(err, 0)
  end
  local fn, loadErr = runtime.loadWithEnv(src, "@" .. spec.path, env)
  if not fn then
    error(loadErr, 0)
  end
  local args = spec.args or {}
  return {
    co = coroutine.create(function()
      fn(runtime.unpackList(args))
    end),
    env = env,
    win = spec.win,
    started = false,
    fs = spec.fs,
  }
end

function runner.pump(frame, event)
  local packed
  if not frame.started then
    frame.started = true
    packed = runtime.pack(coroutine.resume(frame.co))
  elseif event == nil then
    packed = runtime.pack(coroutine.resume(frame.co))
  else
    packed = runtime.pack(coroutine.resume(frame.co, runtime.unpackList(event)))
  end
  if not packed[1] then
    local message = tostring(packed[2])
    if message == "Terminated" then
      return { kind = "terminated" }
    end
    return { kind = "error", message = message }
  end
  if coroutine.status(frame.co) == "dead" then
    return { kind = "exit" }
  end
  local yielded = packed[2]
  if yielded == "push" then
    return {
      kind = "push",
      path = packed[3],
      args = packed[4] or {},
      label = packed[5],
    }
  end
  if yielded == "set_display" then
    return { kind = "set_display", name = packed[3] }
  end
  if yielded == "exit_os" then
    return { kind = "exit_os" }
  end
  return { kind = "wait" }
end

return runner
