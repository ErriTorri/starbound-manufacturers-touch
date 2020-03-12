require "/scripts/util.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit
local baseValues

function init()
  oldInit()
  
  local values = self.primaryAbility.scaleValueByResource.values
  baseValues = {}
  if type(values) == "table" then
    for k, v in ipairs(values) do
	  table.insert(baseValues, { ["name"] = v, ["baseValue"] = self.primaryAbility[v] })
	end
  else
    baseValues = { { ["name"] = values, ["baseValue"] = self.primaryAbility[values] } }
  end
end

function update(dt, fireMode, shiftHeld)
  local resourceName = self.primaryAbility.scaleValueByResource.resource
  local scaleFactor = (status.resource(resourceName) / status.resourceMax(resourceName) + 0.01) ^ 2
  
  for k, v in ipairs(baseValues) do
    self.primaryAbility[v.name] = v.baseValue * scaleFactor
  end
  
  oldUpdate(dt, fireMode, shiftHeld)
end

function uninit()
  for k, v in ipairs(baseValues) do
    self.primaryAbility[v.name] = v.baseValue
  end
  oldUnInit()
end
