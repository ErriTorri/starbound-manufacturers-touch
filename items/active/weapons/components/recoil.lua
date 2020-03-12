require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  self.weapon:init()

end

function update(dt, fireMode, shiftHeld)

  local preEnergy = status.resource("energy")

  self.weapon:update(dt, fireMode, shiftHeld)

  local postEnergy = status.resource("energy")

  if postEnergy < preEnergy then
    local recoil = config.getParameter("primaryAbility").recoil
    local boostAngle = mcontroller.facingDirection() == 1 and self.weapon.aimAngle + math.pi or -self.weapon.aimAngle
    mcontroller.controlApproachVelocityAlongAngle(boostAngle, recoil.speed, recoil.force * config.getParameter("primaryAbility").fireTime, true)
  end
end

function uninit()
  self.weapon:uninit()
end
