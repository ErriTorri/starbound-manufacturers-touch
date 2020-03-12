require "/scripts/util.lua"

kitelements = {}

--Takes a list of elements from a manufacturer, and returns one containing only elements available in the elementaltypes config
function kitelements.removeUnavailableElements(manu)
  if kitelements.elementList == nil then
    kitelements.elementList = {}
    local jsonFile = root.assetJson("/damage/elementaltypes.config")
    for k, v in pairs(jsonFile) do
      table.insert(kitelements.elementList, k)
    end
  end
  
  local retTab = {}
  for _, v in ipairs(manu) do
    for _, vke in ipairs(kitelements.elementList) do
      if v == vke or v == "physical" then
        table.insert(retTab, v)
        break
      end
    end
  end
  
  return retTab
end