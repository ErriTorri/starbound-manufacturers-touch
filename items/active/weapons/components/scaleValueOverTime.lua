require "/scripts/util.lua"
require "/scripts/mt/kitutil.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit

local dValues
local consecutiveShots
local cooldownTimer

function init()
  oldInit()
  
  dValues = {}
  local values = self.primaryAbility.scaleValueOverTime.values
  for k, v in ipairs(values) do
	local prev, name, isValid = kitutil.getSubTableParent(self.primaryAbility, v.variable)
	
    if isValid then
      local curFireTime = self.primaryAbility.fireTime or 1.0
      -- for attacks with really slow firetime, we reduce the number of attacks needed to reach the max multiplier
      local attacksToReachMult = (curFireTime > 0.6) and (v.attacksToReachMultiplier / (curFireTime + 0.4)) or v.attacksToReachMultiplier

	    local finalMultiplier = v.minimumMultiplier or v.maximumMultiplier or v.endingMultiplier or 1.0
      local deltaV = (prev[name] - (prev[name]  * finalMultiplier)) / attacksToReachMult * -1
      table.insert(dValues, { ["name"] = v.variable, ["prev"] = prev, ["baseValue"] = prev[name], ["minMultiplier"] = finalMultiplier, ["deltaV"] = deltaV, ["attacksToReachMultiplier"] = attacksToReachMult })
	end
  end
  consecutiveShots = 0
  --cooldown will be 2.0 times the fireTime, so that there won't be problems if the attack is still continuing but the energy couldn't change in that exact frame
  cooldownTimer = self.primaryAbility.fireTime * 2.0
end

function update(dt, fireMode, shiftHeld)
  -- New code
  local preEnergy = status.resource("energy")
  oldUpdate(dt, fireMode, shiftHeld)
  local postEnergy = status.resource("energy")
  
  cooldownTimer = math.max(0, cooldownTimer - dt)

  -- Change to check if has fired
  if postEnergy < preEnergy then
    consecutiveShots = consecutiveShots + 1
	cooldownTimer = self.primaryAbility.fireTime * 2.0
  elseif cooldownTimer == 0 then
    consecutiveShots = 0
  end
  
  local delta = 0
  for k, v in ipairs(dValues) do
    if consecutiveShots > v.attacksToReachMultiplier then
	  delta = v.deltaV * v.attacksToReachMultiplier
	else
	  delta = v.deltaV * consecutiveShots
	end
    v.prev[v.name] = v.baseValue + delta
  end
end

function uninit()
  for k, v in ipairs(dValues) do
    v.prev[v.name] = v.baseValue
  end
  oldUnInit()
end
