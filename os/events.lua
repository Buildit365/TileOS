local events = {}

local function pointer(x, y)
  return { kind = "pointer", x = x, y = y }
end

function events.classify(active, event)
  local name = event[1]
  if name == "terminate" then
    return { kind = "terminate" }
  end
  if active.kind == "monitor" then
    if name == "monitor_touch" and event[2] == active.name then
      return pointer(event[3], event[4])
    end
    if name == "mouse_click" or name == "mouse_drag" or name == "mouse_up" or name == "mouse_scroll" or name == "monitor_touch" then
      return { kind = "ignore" }
    end
  else
    if name == "mouse_click" and (event[2] == 1 or event[2] == 2) then
      return pointer(event[3], event[4])
    end
    if name == "mouse_click" or name == "monitor_touch" then
      return { kind = "ignore" }
    end
    if name == "mouse_drag" or name == "mouse_up" or name == "mouse_scroll" then
      return {
        kind = "pointer_pass",
        name = name,
        button = event[2],
        x = event[3],
        y = event[4],
      }
    end
  end
  return { kind = "pass", event = event }
end

return events
