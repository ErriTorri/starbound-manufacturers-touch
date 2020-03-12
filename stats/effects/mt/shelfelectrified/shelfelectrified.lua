require "/scripts/util.lua"

function init()
  animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=7733AA=0.25")

  script.setUpdateDelta(5)

  self.tickDamagePercentage = config.getParameter("tickDamagePercentage")
  self.tickTime = 1.0
  self.tickTimer = self.tickTime

end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
      damageSourceKind = "electric",
      sourceEntityId = entity.id()
    })
    animator.playSound("bolt")
  end
end

function uninit()

end
