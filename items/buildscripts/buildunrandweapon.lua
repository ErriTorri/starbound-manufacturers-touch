require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/scripts/mt/options.lua"
require "/scripts/mt/kitutil.lua"
require "/items/buildscripts/abilities.lua"
require "/items/buildscripts/appearance.lua"
require "/items/buildscripts/manufacturers.lua"

function build(directory, config, parameters, level, seed)
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  setupAbility(config, parameters, "primary")
  setupAbility(config, parameters, "alt")

  -- elemental type and config (for alt ability)
  local elementalType = configParameter("elementalType", "physical")
  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if config.altAbility and config.altAbility.elementalConfig then
    kitutil.mergeTablesWithoutOverwriting(config.altAbility, config.altAbility.elementalConfig[elementalType])
  end

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  -- palette swaps
  config.paletteSwaps = ""
  if config.palette then
    local palette = root.assetJson(util.absolutePath(directory, config.palette))
    local selectedSwaps = palette.swaps[configParameter("colorIndex", 1)]
    for k, v in pairs(selectedSwaps) do
      config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
    end
  end
  if type(config.inventoryIcon) == "string" then
    config.inventoryIcon = config.inventoryIcon .. config.paletteSwaps
  else
    for i, drawable in ipairs(config.inventoryIcon) do
      if drawable.image then drawable.image = drawable.image .. config.paletteSwaps end
    end
  end

  -- gun offsets
  if config.baseOffset then
    construct(config, "animationCustom", "animatedParts", "parts", "middle", "properties")
    config.animationCustom.animatedParts.parts.middle.properties.offset = config.baseOffset
    if config.muzzleOffset then
      config.muzzleOffset = vec2.add(config.muzzleOffset, config.baseOffset)
    end
  end
  
  --add color to weapon name
  
  if not parameters.hasColoredName and config.shortdescription then
    local colorWeaponNamesFor = options.getOption("colorWeaponNamesFor")
    if colorWeaponNamesFor then
	  local defShortDescription = ""
	  if parameters.shortdescription then
	    defShortDescription = parameters.shortdescription
	  else
	    defShortDescription = config.shortdescription
	  end
	  
	  if colorWeaponNamesFor == "rarity" then
	    parameters.shortdescription = color.getColorByRarity(config.rarity) .. defShortDescription
      elseif colorWeaponNamesFor == "level" or colorWeaponNamesFor == "levelFull" then --same thing for unrandom weapons
	    parameters.shortdescription = color.getColorByLevel(math.floor(config.level or 1)) .. defShortDescription
	  end
      parameters.hasColoredName = true
	end
  end

  -- populate tooltip fields
  if config.tooltipKind ~= "base" then
    config.tooltipFields = {}
	
    if options.getOption("showWeaponLevel") then
      config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
    else
      config.tooltipFields.levelLabel = ""
    end
	
    --For compatibility with FU
    if options.isFrackinUniverseLoaded() then
      config.tooltipFields.levelTitleLabel = ""
    
      local decimalCount = options.getOption("criticalStatDecimalCount") or 1

      config.tooltipFields.critChanceTitleLabel = "^orange;Crit %^reset;"
      config.tooltipFields.critBonusTitleLabel = "^yellow;Dmg +^reset;"
      config.tooltipFields.critChanceLabel = configParameter("critChance") and util.round(configParameter("critChance", 0), decimalCount) .. "%" or "--"
      config.tooltipFields.critBonusLabel = configParameter("critBonus") and util.round(configParameter("critBonus", 0), decimalCount) or "--"
      config.tooltipFields.stunChanceLabel = configParameter("stunChance") and util.round(configParameter("stunChance", 0), decimalCount) .. "%" or "--"
      
      if config.tooltipKind == "gun" or config.tooltipKind == "gun2" then
        config.tooltipFields.critChanceTitleLabel = ""
        config.tooltipFields.critBonusTitleLabel = ""
      end

    -- ***ORIGINAL CODE BY ALBERTO-ROTA and SAYTER***
    -- FU ADDITIONS

      config.tooltipFields.magazineSizeImage = "/interface/statuses/ammo.png"  
      config.tooltipFields.reloadTimeImage = "/interface/statuses/reload.png"  
      config.tooltipFields.critBonusImage = "/interface/statuses/dmgplus.png"  
      config.tooltipFields.critChanceImage = "/interface/statuses/crit2.png" 

      -- weapon abilities

      --overheating
      if config.primaryAbility.overheatLevel then
        config.tooltipFields.overheatLabel = util.round(config.primaryAbility.overheatLevel / config.primaryAbility.heatGain, 1)
        config.tooltipFields.cooldownLabel = util.round(config.primaryAbility.overheatLevel / config.primaryAbility.heatLossRateMax, 1)    
      end

      -- Staff and Wand specific --
      if config.primaryAbility.projectileParameters then
        if config.primaryAbility.projectileParameters.baseDamage then
          config.tooltipFields.staffDamageLabel = config.primaryAbility.projectileParameters.baseDamage  
        end	     
      end    

      if config.primaryAbility.energyCost then
        config.tooltipFields.staffEnergyLabel = config.primaryAbility.energyCost
      end
      if config.primaryAbility.energyPerShot then
        config.tooltipFields.staffEnergyLabel = config.primaryAbility.energyPerShot
      end
      if config.primaryAbility.maxCastRange then
        config.tooltipFields.staffRangeLabel = config.primaryAbility.maxCastRange
      else
            config.tooltipFields.staffRangeLabel = 25
      end
      if config.primaryAbility.projectileCount then
        config.tooltipFields.staffProjectileLabel = config.primaryAbility.projectileCount
      else
            config.tooltipFields.staffProjectileLabel = 1
      end

      -- Recoil
      if config.primaryAbility.recoilVelocity then
        config.tooltipFields.isCrouch = configParameter("crouchReduction",false)
        config.tooltipFields.recoilStrength = util.round(configParameter("recoilVelocity",0), 0)
        config.tooltipFields.recoilCrouchStrength = util.round(configParameter("crouchRecoilVelocity",0), 0)    
      end

      if (parameters.isAmmoBased ==1 ) then   -- if its ammo based, we set the relevant data to the tooltip
        parameters.magazineSizeFactor = valueOrRandom(parameters.magazineSizeFactor, seed, "magazineSizeFactor")
        parameters.reloadTimeFactor = valueOrRandom(parameters.reloadTimeFactor, seed, "reloadTimeFactor")
        config.magazineSize = scaleConfig(parameters.primaryAbility.energyUsageFactor, config.magazineSize) or 0
        config.reloadTime = scaleConfig(parameters.reloadTimeFactor, config.reloadTime) or 0  
        config.tooltipFields.energyPerShotLabel = util.round((energyUsage * fireTime)/2, 1)  -- these weapons have 50% energy cost
        config.tooltipFields.magazineSizeLabel = util.round(configParameter("magazineSize",1), 0) --
        config.tooltipFields.reloadTimeLabel = util.round(configParameter("reloadTime",1),1)  .. "s"
      else
        config.magazineSize = 0
        config.reloadTime = 0       
        config.tooltipFields.magazineSizeLabel = "--"
        config.tooltipFields.reloadTimeLabel = "--"        
      end

      -- END OF FU ADDITIONS
    end
    --End of FU tooltips
	
    config.tooltipFields.dpsLabel = util.round((config.primaryAbility.baseDps or 0) * config.damageLevelMultiplier, 1)
    config.tooltipFields.speedLabel = util.round(1 / (config.primaryAbility.fireTime or 1.0), 1)
    config.tooltipFields.damagePerShotLabel = util.round((config.primaryAbility.baseDps or 0) * (config.primaryAbility.fireTime or 1.0) * config.damageLevelMultiplier, 1)
    config.tooltipFields.energyPerShotLabel = util.round((config.primaryAbility.energyUsage or 0) * (config.primaryAbility.fireTime or 1.0), 1)
	
	--manufacturer only determines this label for non-random weapons
	local manuName = getManufacturerName(parameters.manufacturer or config.manufacturer or "none", config, parameters)
	if manuName ~= "" then
	  config.tooltipFields.manufacturerNameLabel = manuName
	else
	  config.tooltipFields.manufacturerNameLabel = parameters.manufacturer or config.manufacturer or ""
	end
    config.tooltipFields.energyPerSecondLabel = util.round(config.primaryAbility.energyUsage or 0, 1)
	if config.primaryAbility.energyUsage and config.primaryAbility.energyUsage > 0 and config.primaryAbility.baseDps then
      config.tooltipFields.damagePerEnergyLabel = util.round((config.primaryAbility.baseDps * config.damageLevelMultiplier) / config.primaryAbility.energyUsage, 2)
    else
      config.tooltipFields.damagePerEnergyLabel = "---"
    end
	
    if elementalType ~= "physical" then
      config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
    end
    if config.primaryAbility then
      config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
      config.tooltipFields.primaryAbilityLabel = config.primaryAbility.name or "unknown"
    end
    if config.altAbility then
      config.tooltipFields.altAbilityTitleLabel = "Special:"
      config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
    end
  end

  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end
