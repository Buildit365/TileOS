local layout = require("layout")

local session = {}

function session.new()
  return {
    screen = "home",
    page = 1,
    stack = {},
    error = nil,
  }
end

local function copyStack(stack)
  local out = {}
  for i = 1, #stack do
    out[i] = stack[i]
  end
  return out
end

local function withPage(state, ctx)
  local pages = layout.pageCount(#ctx.apps, ctx.metrics.pageSize)
  if state.page > pages then
    state.page = pages
  end
  if state.page < 1 then
    state.page = 1
  end
  return pages
end

function session.reduce(state, event, ctx)
  local nextState = {
    screen = state.screen,
    page = state.page,
    stack = copyStack(state.stack),
    error = state.error,
  }

  if event.type == "terminate" then
    if #nextState.stack == 0 then
      return nextState, "exit_os"
    end
    nextState.stack = {}
    nextState.screen = "home"
    nextState.error = nil
    return nextState, "go_home"
  end

  if ctx.metrics.tooSmall or nextState.screen == "toosmall" then
    nextState.screen = "toosmall"
    if event.type == "click" and layout.tooSmallHit(event.x, event.y) == "use_computer" then
      return nextState, "clear_display"
    end
    return nextState, nil
  end

  if event.type == "child_done" then
    if #nextState.stack > 0 then
      table.remove(nextState.stack)
    end
    nextState.error = nil
    if #nextState.stack == 0 then
      nextState.screen = "home"
      return nextState, "go_home"
    end
    nextState.screen = "app"
    return nextState, "resume"
  end

  if event.type == "child_error" then
    nextState.error = event.message or "error"
    nextState.screen = "app"
    return nextState, "show_error"
  end

  if event.type == "push" then
    nextState.stack[#nextState.stack + 1] = {
      path = event.path,
      args = event.args or {},
      label = event.label or "App",
    }
    nextState.screen = "app"
    nextState.error = nil
    return nextState, "launch"
  end

  if event.type == "click" then
    local pages = withPage(nextState, ctx)
    local mode = nextState.screen == "app" and "app" or "home"
    local bar = layout.barHit(ctx.metrics.w, event.x, event.y, mode, pages)
    if bar == "home" then
      nextState.stack = {}
      nextState.screen = "home"
      nextState.error = nil
      return nextState, "go_home"
    end
    if bar == "prev" then
      if nextState.page > 1 then
        nextState.page = nextState.page - 1
      end
      return nextState, nil
    end
    if bar == "next" then
      if nextState.page < pages then
        nextState.page = nextState.page + 1
      end
      return nextState, nil
    end
    if nextState.screen == "home" and nextState.error == nil then
      local index = layout.hit(ctx.metrics, event.x, event.y, nextState.page, #ctx.apps)
      if index then
        local app = ctx.apps[index]
        nextState.stack = {
          {
            path = app.path,
            args = {},
            label = app.label,
            id = app.id,
          },
        }
        nextState.screen = "app"
        nextState.error = nil
        return nextState, "launch"
      end
    end
  end

  withPage(nextState, ctx)
  return nextState, nil
end

return session
