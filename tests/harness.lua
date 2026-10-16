local unpack = unpack or table.unpack

local harness = {}
local tests = {}
local failed = false

local function deepEqual(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= "table" then
    return a == b
  end
  for k, v in pairs(a) do
    if not deepEqual(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

local function dump(v)
  if type(v) ~= "table" then
    return tostring(v)
  end
  local parts = {}
  for k, value in pairs(v) do
    parts[#parts + 1] = tostring(k) .. "=" .. dump(value)
  end
  table.sort(parts)
  return "{" .. table.concat(parts, ",") .. "}"
end

function harness.test(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
end

function harness.assertEq(actual, expected, message)
  if actual ~= expected then
    error((message or "assertEq") .. "\n  actual:   " .. dump(actual) .. "\n  expected: " .. dump(expected), 2)
  end
end

function harness.assertDeep(actual, expected, message)
  if not deepEqual(actual, expected) then
    error((message or "assertDeep") .. "\n  actual:   " .. dump(actual) .. "\n  expected: " .. dump(expected), 2)
  end
end

function harness.failLoad()
  failed = true
end

function harness.run()
  for i = 1, #tests do
    local ok, err = pcall(tests[i].fn)
    if ok then
      io.write("PASS " .. tests[i].name .. "\n")
    else
      failed = true
      io.write("FAIL " .. tests[i].name .. "\n" .. tostring(err) .. "\n")
    end
  end
  if failed then
    os.exit(1)
  end
end

return harness
