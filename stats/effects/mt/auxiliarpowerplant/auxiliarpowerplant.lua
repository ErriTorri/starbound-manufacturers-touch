function init()
  animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("energy", config.getParameter("emissionRate", 5))
  animator.setParticleEmitterActive("energy", true)

  effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", amount = config.getParameter("regenBonusAmount", 0)},
      {stat = "energyRegenBlockTime", effectiveMultiplier = config.getParameter("blockTimeBonusAmount", 0)}
    })
end

function update(dt)
end

function uninit()
end
