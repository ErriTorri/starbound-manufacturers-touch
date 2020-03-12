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
      config.tooltipFields.critChanceLabel =  util.round(configParameter("critChance", 0), decimalCount)
      config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus", 0), decimalCount)
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
