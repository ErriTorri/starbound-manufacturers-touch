require "/scripts/util.lua"
require "/scripts/mt/options.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit

local isDisabled

function init()
  isDisabled = options.getOption("disableOnEnergyExhaustionStatus")
  oldInit()
end

function update(dt, fireMode, shiftHeld)
  local preEnergy = status.resource("energy")

  oldUpdate(dt, fireMode, shiftHeld)

  local postEnergy = status.resource("energy")

  if postEnergy < preEnergy and postEnergy == 0 then  
    if not isDisabled then
      local effect = self.primaryAbility.onEnergyExaustionStatus
      status.addEphemeralEffect(effect.effectName, effect.duration)
	end
  end
end

function uninit()
  oldUnInit()
end