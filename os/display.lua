local display = {}

local function large(term)
  if not term or not term.getSize then
    return false
  end
  local w, h = term.getSize()
  return w >= 15 and h >= 10
end

local function computerActive()
  return { kind = "computer", name = "terminal" }
end

local function monitorActive(name)
  return { kind = "monitor", name = name }
end

local function isMonitor(term)
  return type(term) == "table" and type(term["set" .. "TextScale"]) == "function"
end

function display.resolve(api, saved)
  local native = api.native()
  local current = api.current()
  if saved == nil then
    local term = current or native
    if isMonitor(term) then
      if large(term) then
        return {
          mode = "ui",
          ui = term,
          status = native ~= term and native or nil,
          active = monitorActive("current"),
          displayName = "current",
        }
      end
      if native ~= term and large(native) then
        return {
          mode = "split",
          ui = native,
          message = term,
          messageSide = "current",
          active = computerActive(),
          displayName = "terminal",
        }
      end
      return {
        mode = "message",
        message = term,
        active = monitorActive("current"),
        displayName = "current",
      }
    end
    if large(term) then
      return {
        mode = "ui",
        ui = term,
        active = computerActive(),
        displayName = "terminal",
      }
    end
    return {
      mode = "message",
      message = term,
      active = computerActive(),
      displayName = "terminal",
    }
  end

  if saved == "terminal" then
    if large(native) then
      return {
        mode = "ui",
        ui = native,
        active = computerActive(),
        displayName = "terminal",
      }
    end
    return {
      mode = "message",
      message = native,
      active = computerActive(),
      displayName = "terminal",
    }
  end

  local monitor = api.wrap(saved)
  if not monitor then
    return {
      mode = "ui",
      ui = native,
      active = computerActive(),
      displayName = "terminal",
      clearSaved = true,
    }
  end
  if not large(monitor) then
    if large(native) and native ~= monitor then
      return {
        mode = "split",
        ui = native,
        message = monitor,
        messageSide = saved,
        active = computerActive(),
        displayName = saved,
      }
    end
    return {
      mode = "message",
      message = monitor,
      messageSide = saved,
      active = monitorActive(saved),
      displayName = saved,
    }
  end
  return {
    mode = "ui",
    ui = monitor,
    status = native ~= monitor and native or nil,
    active = monitorActive(saved),
    displayName = saved,
  }
end

return display
