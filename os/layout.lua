local layout = {
  CELL_W = 5,
  CELL_H = 3,
  ICON_W = 3,
  ICON_H = 2,
  GAP = 1,
  MIN_W = 15,
  MIN_H = 10,
}

local function fit(space, cell, gap)
  if space < cell then
    return 0
  end
  return math.floor((space + gap) / (cell + gap))
end

function layout.metrics(w, h)
  local tooSmall = w < layout.MIN_W or h < layout.MIN_H
  local contentH = h - 1
  if contentH < 0 then
    contentH = 0
  end
  local cols = 0
  local rows = 0
  if not tooSmall then
    cols = fit(w, layout.CELL_W, layout.GAP)
    rows = fit(contentH, layout.CELL_H, layout.GAP)
  end
  return {
    w = w,
    h = h,
    tooSmall = tooSmall,
    cols = cols,
    rows = rows,
    pageSize = cols * rows,
    contentY = 2,
    contentH = contentH,
  }
end

function layout.pageCount(appCount, pageSize)
  if pageSize <= 0 or appCount <= 0 then
    return 1
  end
  return math.ceil(appCount / pageSize)
end

function layout.cellOrigin(col, row)
  local x = 1 + col * (layout.CELL_W + layout.GAP)
  local y = 2 + row * (layout.CELL_H + layout.GAP)
  return x, y
end

function layout.hit(metrics, x, y, page, appCount)
  if metrics.tooSmall or y < metrics.contentY or appCount <= 0 then
    return nil
  end
  local strideX = layout.CELL_W + layout.GAP
  local strideY = layout.CELL_H + layout.GAP
  local localY = y - metrics.contentY
  local col = math.floor((x - 1) / strideX)
  local row = math.floor(localY / strideY)
  local inX = (x - 1) % strideX
  local inY = localY % strideY
  if col < 0 or row < 0 or col >= metrics.cols or row >= metrics.rows then
    return nil
  end
  if inX >= layout.CELL_W or inY >= layout.CELL_H then
    return nil
  end
  local index = (page - 1) * metrics.pageSize + row * metrics.cols + col + 1
  if index < 1 or index > appCount then
    return nil
  end
  return index
end

function layout.barHit(w, x, y, mode, pages)
  if y ~= 1 then
    return nil
  end
  if mode == "app" and x >= 1 and x <= 4 then
    return "home"
  end
  if mode == "home" and pages > 1 and x == w - 2 then
    return "prev"
  end
  if mode == "home" and pages > 1 and x == w then
    return "next"
  end
  return nil
end

function layout.tooSmallHit(x, y)
  if y == 5 and x >= 1 and x <= 12 then
    return "use_computer"
  end
  return nil
end

return layout
