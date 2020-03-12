require "/scripts/util.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit

function init()
  oldInit()
end

function update(dt, fireMode, shiftHeld)

  local preEnergy = status.resource("energy")

  oldUpdate(dt, fireMode, shiftHeld)

  local postEnergy = status.resource("energy")

  if self.primaryAbility.recoil == nil then
    return
  end
  
  if postEnergy < preEnergy then
    local recoilSpeed = self.primaryAbility.recoil.speed
    local recoilForce = self.primaryAbility.recoil.force
    if fireMode ~= "alt" then
      recoilForce = recoilForce * self.primaryAbility.fireTime
    else
      recoilForce = recoilForce * 0.15 --a magic number that allows some knockback, but prevents ridiculous amounts
    end
    local boostAngle = mcontroller.facingDirection() == 1 and self.weapon.aimAngle + math.pi or -self.weapon.aimAngle
    mcontroller.controlApproachVelocityAlongAngle(boostAngle, recoilSpeed, recoilForce, true)
  end

end

function uninit()
  oldUnInit()
end
