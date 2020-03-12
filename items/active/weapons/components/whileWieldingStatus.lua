require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit

function init()
  oldInit()
  status.setPersistentEffects("whileWieldingStatus", { self.primaryAbility.whileWieldingStatus })
end

function update(dt, fireMode, shiftHeld)
  oldUpdate(dt, fireMode, shiftHeld)
end

function uninit()
  oldUnInit()
  status.clearPersistentEffects("whileWieldingStatus")
end
