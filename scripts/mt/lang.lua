require "/scripts/util.lua"

--note, this file is currently not working properly in the latest build, and so it is disabled

lang = {}

function lang.getString(tab, key)
  return lang.getString(tab, key, nil)
end

function lang.getString(tab, key, seed)
  if lang.config == nil or lang.config.strings == nil then
    return nil
  end
  
  if tab[key] then
    if type(tab[key]) == "table" then
      return util.randomFromList(tab[key], seed)
    else
      return tab[key]
    end
  else
    return nil
  end
end

function lang.getManufacturerName(manu, seed)
  if lang.config == nil or lang.config.strings == nil or lang.config[manu] == nil then
    return nil
  end
  
  return lang.getString(lang.config[manu], "friendlyName")
end

function replacePrefixes(manu, prefixes, seed)
  if lang.config == nil or lang.config.strings == nil or lang.config[manu] == nil or lang.config[manu].prefixes == nil then
    return
  end
  
  for k, v in pairs(lang.config[manu].prefixes) do
    if not pcall(function ()
      local index = tonumber(k)
      if prefixes[k] ~= nil then
        prefixes[k] = lang.getString(lang.config[manu].prefixes, k, seed)
      end
    end) then
      sb.logInfo(manu .. "'s prefix for language " .. lang.config.friendlyName .. " isn't a number.")
    end
  end
end

--replaces @PATH: with the actual table
function lang.replacePaths()
  if lang.config == nil or lang.config.strings == nil then
    return
  end

  local function doReplacements(tab)
    for k, v in pair(language) do
      if type(v) == "string" and string.len(v) > 6 and string.sub(v, 1, 6) == "@PATH:" then
        local path = string.sub(v, 7) --after : until end
        if not pcall(function () tab[k] = root.assetJson(path) end) then
          sb.logInfo("File at " .. path .. " could not be loaded as a json file.")
          tab[k] = ""
        end
      end
    end
  end
  doReplacements(lang.config.strings)
end