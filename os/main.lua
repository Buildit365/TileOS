local apps = require("apps")
local config = require("config")
local display = require("display")
local events = require("events")
local session = require("session")
local draw = require("draw")
local runner = require("runner")
local layout = require("layout")
local runtime = require("runtime")
local tabs = require("tabs")

local main = {}

local function makeWindow(api, parent)
  local w, h = parent.getSize()
  if h < 2 then
    return api.window(parent, 1, 1, math.max(1, w), 1)
  end
  return api.window(parent, 1, 2, w, h - 1)
end

local function context(appList, ui)
  local w, h = ui.getSize()
  return {
    apps = appList,
    metrics = layout.metrics(w, h),
  }
end

function main.run(api)
  local rootTerm = api.current and api.current() or nil
  local saved = config.read(api.fs)
  local view = display.resolve(api, saved)
  if view.clearSaved then
    config.write(api.fs, "terminal")
  end

  local function clearTerm(target)
    if type(target) ~= "table" or type(target.clear) ~= "function" then
      return
    end
    draw.blank(target)
    if type(target.setCursorBlink) == "function" then
      target.setCursorBlink(false)
    end
  end

  local function exitToShell()
    if window then
      clearTerm(window)
      if type(window.setVisible) == "function" then
        window.setVisible(false)
      end
    end
    if rootTerm and type(api.redirect) == "function" then
      api.redirect(rootTerm)
    end
    clearTerm(view.ui)
    clearTerm(view.message)
    clearTerm(view.status)
    if api.native then
      clearTerm(api.native())
    end
    clearTerm(rootTerm)
    return "exit"
  end
  local state = session.new()
  local frames = {}
  local frame = nil
  local window = nil

  local function listApps()
    return apps.discover(api.fs, api.osDir or "/os")
  end

  local function restoreAppCursor()
    if state.screen == "app" and window and type(window.restoreCursor) == "function" then
      window.restoreCursor()
    end
  end

  local function paint()
    if view.mode == "message" then
      draw.tooSmall(view.message, false)
      return
    end
    if view.message then
      draw.tooSmall(view.message, true)
    end
    if view.status then
      draw.status(view.status)
    end
    local ui = view.ui
    local ctx = context(listApps(), ui)
    if ctx.metrics.tooSmall then
      draw.tooSmall(ui, false)
      return
    end
    if state.screen == "home" then
      draw.home(ui, ctx.metrics, ctx.apps, state.page, ui.isColor())
      draw.bar(ui, {
        mode = "home",
        pages = layout.pageCount(#ctx.apps, ctx.metrics.pageSize),
        page = state.page,
      })
      return
    end
    local top = state.stack[#state.stack]
    draw.bar(ui, { mode = "app", label = top and top.label or "" })
    restoreAppCursor()
    if state.error and window then
      draw.error(window, state.error)
    end
  end

  local function attachWindow()
    window = nil
    if not view.ui then
      return
    end
    local w, h = view.ui.getSize()
    local metrics = layout.metrics(w, h)
    if metrics.tooSmall or state.screen ~= "app" then
      return
    end
    window = makeWindow(api, view.ui)
    window.setBackgroundColor(colors.white)
    window.setTextColor(colors.black)
    window.clear()
    if frame then
      frame.win = window
      frame.env.term = window
      frame.env.tile.display = view.displayName or "terminal"
    end
  end

  local dispatch

  local function isShell(frame)
    if type(frame) ~= "table" then
      return false
    end
    if frame.id == "shell" then
      return true
    end
    local path = frame.path
    return type(path) == "string" and path:find("builtins/shell/main.lua", 1, true) ~= nil
  end

  local function stackHasShell(stack)
    for i = 1, #stack do
      if isShell(stack[i]) then
        return true
      end
    end
    return false
  end

  local function closeShellTabs(stack)
    if stackHasShell(stack) then
      tabs.closeExtras(multishell)
    end
  end

  local function launchTop()
    local top = state.stack[#state.stack]
    attachWindow()
    frame = runner.launch({
      fs = api.fs,
      path = top.path,
      args = top.args or {},
      win = window,
      displayName = view.displayName or "terminal",
      parentEnv = _ENV,
    })
    frames[#frames + 1] = frame
    return dispatch(runner.pump(frame, nil))
  end

  function dispatch(result)
    if not result then
      return nil
    end
    if result.kind == "wait" then
      return nil
    end
    if result.kind == "exit_os" then
      return exitToShell()
    end
    local ctx = view.ui and context(listApps(), view.ui) or {
      apps = {},
      metrics = layout.metrics(1, 1),
    }
    if result.kind == "error" then
      state = session.reduce(state, { type = "child_error", message = result.message }, ctx)
      paint()
      return nil
    end
    if result.kind == "terminated" then
      local hadShell = stackHasShell(state.stack)
      local effect
      state, effect = session.reduce(state, { type = "terminate" }, ctx)
      if hadShell then
        closeShellTabs({ { id = "shell" } })
      end
      if effect == "exit_os" then
        return exitToShell()
      end
      frames = {}
      frame = nil
      window = nil
      paint()
      return nil
    end
    if result.kind == "exit" then
      local hadShell = isShell(state.stack[#state.stack])
      local effect
      state, effect = session.reduce(state, { type = "child_done" }, ctx)
      if hadShell and effect == "go_home" then
        closeShellTabs({ { id = "shell" } })
      end
      frames[#frames] = nil
      frame = frames[#frames]
      if effect == "resume" and frame then
        frame.env.tile.display = view.displayName or "terminal"
        return dispatch(runner.pump(frame, nil))
      end
      frame = nil
      window = nil
      paint()
      return nil
    end
    if result.kind == "push" then
      state = session.reduce(state, {
        type = "push",
        path = result.path,
        args = result.args,
        label = result.label,
      }, ctx)
      return launchTop()
    end
    if result.kind == "set_display" then
      config.write(api.fs, result.name)
      view = display.resolve(api, result.name)
      if view.clearSaved then
        config.write(api.fs, "terminal")
      end
      attachWindow()
      paint()
      if frame then
        frame.env.tile.display = view.displayName or result.name
        return dispatch(runner.pump(frame, nil))
      end
    end
    return nil
  end

  local function forward(contentEvent)
    if frame and state.screen == "app" and not state.error then
      return dispatch(runner.pump(frame, contentEvent))
    end
    return nil
  end

  paint()

  while true do
    local packed = runtime.pack(api.pullEventRaw())
    if packed[1] == nil then
      return "stop"
    end
    if view.mode == "split" and packed[1] == "monitor_touch" and packed[2] == view.messageSide then
      if layout.tooSmallHit(packed[3], packed[4]) == "use_computer" then
        config.write(api.fs, "terminal")
        if view.message then
          draw.blank(view.message)
        end
        view = display.resolve(api, "terminal")
        attachWindow()
        paint()
      end
    else
      local active = view.active or { kind = "computer", name = "terminal" }
      local class = events.classify(active, packed)
      local ctx = view.ui and context(listApps(), view.ui) or {
        apps = {},
        metrics = layout.metrics(view.message and view.message.getSize() or 1, 1),
      }
      if class.kind == "terminate" then
        local hadShell = stackHasShell(state.stack)
        local effect
        state, effect = session.reduce(state, { type = "terminate" }, ctx)
        if hadShell then
          closeShellTabs({ { id = "shell" } })
        end
        if effect == "exit_os" then
          return exitToShell()
        end
        frames = {}
        frame = nil
        window = nil
        paint()
      elseif class.kind == "pointer" then
        local hadShell = stackHasShell(state.stack)
        local effect
        state, effect = session.reduce(state, { type = "click", x = class.x, y = class.y }, ctx)
        if hadShell and effect == "go_home" then
          closeShellTabs({ { id = "shell" } })
        end
        if effect == "clear_display" then
          config.write(api.fs, "terminal")
          view = display.resolve(api, "terminal")
          attachWindow()
          paint()
        elseif effect == "go_home" then
          frames = {}
          frame = nil
          window = nil
          paint()
        elseif effect == "launch" then
          frames = {}
          frame = nil
          local exited = launchTop()
          paint()
          if exited == "exit" then
            return exitToShell()
          end
        elseif state.screen == "app" and frame and not state.error and class.y >= 2 then
          local exited = forward({ "mouse_click", 1, class.x, class.y - 1 })
          if exited == "exit" then
            return exitToShell()
          end
          paint()
        else
          paint()
        end
      elseif class.kind == "pointer_pass" and class.y and class.y >= 2 then
        local exited = forward({ class.name, class.button, class.x, class.y - 1 })
        if exited == "exit" then
          return exitToShell()
        end
      elseif class.kind == "pass" then
        local exited = forward(packed)
        if exited == "exit" then
          return exitToShell()
        end
      end
    end
  end
end

local function runningAsProgram()
  return shell and shell.getRunningProgram and fs.getName(shell.getRunningProgram()) == "main.lua"
end

if runningAsProgram() then
  local programDir = fs.getDir(shell.getRunningProgram())
  package.path = programDir .. "/?.lua;" .. package.path
  local native = term.native()
  main.run({
    fs = fs,
    osDir = programDir,
    native = function()
      return native
    end,
    current = function()
      return term.current()
    end,
    redirect = function(target)
      return term.redirect(target)
    end,
    wrap = function(name)
      if peripheral.getType(name) ~= "monitor" then
        return nil
      end
      return peripheral.wrap(name)
    end,
    peripheral = peripheral,
    window = function(parent, x, y, w, h)
      return window.create(parent, x, y, w, h, true)
    end,
    pullEventRaw = os.pullEventRaw,
  })
end

return main
