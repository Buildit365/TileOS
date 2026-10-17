local T = tile_test

T.test("leaving shell closes tabs opened beside Tile", function()
  local tabs = dofile("os/tabs.lua")
  local names = { "tile", "lua", "edit" }
  local me = 1
  local focus = 1
  local queued = {}
  local api = {
    getCurrent = function()
      return me
    end,
    getCount = function()
      return #names
    end,
    setFocus = function(n)
      focus = n
    end,
  }
  local function queue(event)
    queued[#queued + 1] = event
  end
  local function pull()
    local event = table.remove(queued, 1)
    if event == "terminate" and focus ~= me then
      table.remove(names, focus)
      if focus < me then
        me = me - 1
      end
      focus = me
    end
    return event
  end
  tabs.closeExtras(api, pull, queue)
  T.assertDeep(names, { "tile" })
  T.assertEq(me, 1)
end)

T.test("no multishell means there is nothing to close", function()
  local tabs = dofile("os/tabs.lua")
  tabs.closeExtras(nil)
end)
