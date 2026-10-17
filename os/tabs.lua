local tabs = {}

function tabs.closeExtras(multishellApi, pull, queue)
  if type(multishellApi) ~= "table" or type(multishellApi.getCount) ~= "function" or type(multishellApi.getCurrent) ~= "function" or type(multishellApi.setFocus) ~= "function" then
    return
  end
  pull = pull or os.pullEventRaw
  queue = queue or os.queueEvent
  local guard = 0
  while guard < 32 do
    guard = guard + 1
    local me = multishellApi.getCurrent()
    local victim = nil
    for n = multishellApi.getCount(), 1, -1 do
      if n ~= me then
        victim = n
        break
      end
    end
    if not victim then
      return
    end
    local before = multishellApi.getCount()
    multishellApi.setFocus(victim)
    queue("terminate")
    queue("tile_tab_closed")
    while true do
      local event = pull()
      if event == "tile_tab_closed" then
        break
      end
    end
    if multishellApi.getCount() >= before then
      return
    end
  end
end

return tabs
