require "/scripts/util.lua"

kitutil = {}

function kitutil.splitString(str)
  local ret = {}
  for s in string.gmatch(str, "[%ad]+") do
    table.insert(ret, s)
  end
  return ret
end

function kitutil.getSubTableParent(mainTable, pathAsString)
  local valid = true
  local path = kitutil.splitString(pathAsString) --since this may have multiple tables that we need to go into
  local cur = mainTable
  local prev --workaround because Lua doesn't support references or pointers
  --Why aren't there any scripting languages that actually do? Dear reader, if you know of any, please let me know
  for _, loc in ipairs(path) do
    if not cur[loc] then
      valid = false
      break
    end
    prev = cur
    cur = cur[loc]
  end
		
  return prev, path[#path], valid
end

function kitutil.intersection(list1, list2)
  local retTab = {}
  for _, v in ipairs(list2) do
    for _, v2 in ipairs(list1) do
      if v == v2 then
        table.insert(retTab, v)
        break
      end
    end
  end  
  return retTab
end

function kitutil.getLastPartOfSpaceDelimitedString(str)
  local retVal = ""
  for e in string.gmatch(str, "%S+") do
    retVal = e
  end
  return retVal
end

function kitutil.getTableLength(tab)
  local count = 0
  for k, v in ipairs(tab) do
    sb.logInfo("Key is " .. k)
    count = count + 1
  end
  return count
end

function kitutil.mergeTablesWithoutOverwriting(base, layer)
  for k, v in pairs(layer) do
    if base[k] == nil then
      base[k] = v
    end
  end
  return base
end

--Merges two tables together. If both tables have a value assigned to the same key, use the second one
function kitutil.mergeTablesWithOverwriting(base, layer)
  for k, v in pairs(layer) do
    base[k] = v
  end
  return base
end