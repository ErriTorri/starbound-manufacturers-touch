require "/scripts/util.lua"
require "/scripts/staticrandom.lua"
require "/scripts/mt/kitelements.lua"
require "/scripts/mt/kitutil.lua"
require "/scripts/mt/lang.lua"
require "/scripts/mt/options.lua"
require "/items/buildscripts/kitmath.lua"
require "/items/buildscripts/appearance.lua"

--beware ye who enter, for this code is long and poorly documented

local manufacturerTablePath = "/items/buildscripts/manufacturers.config"
local abilityInfoPath = "/items/buildscripts/abilityinfo.config"
local manufacturers = nil

function configParameter(parameters, config, keyName, defaultValue)
  if parameters[keyName] ~= nil then
    return parameters[keyName]
  elseif config[keyName] ~= nil then
    return config[keyName]
  else
    return defaultValue
  end
end

function isManufacturerConfigPropertyTrue(parameters, config, key)
  if parameters and config then
    if parameters.manufacturerConfig ~= nil and parameters.manufacturerConfig[key] ~= nil then
      --only check if key is nil so that we can fall back to config if parameters doesn't care
      return parameters.manufacturerConfig[key] == true
    end
    
    if config.manufacturerConfig ~= nil then
      return config.manufacturerConfig[key] == true
    end
  end
  return false
end

function getManufacturerSourceFromType(manufacturerType)
  if not manufacturerType then return nil end
  if not manufacturers then
    manufacturers = root.assetJson(manufacturerTablePath)
  end
  return manufacturers[manufacturerType]
end

function hasCommonElement(elementListA, elementListB)
  for i, v in ipairs(elementListA) do
    for j, k in ipairs(elementListB) do
      if v == k then
        do return true end
      end
    end
  end
  return false
end

function hasAcceptableElement(element, elementalTypeList)
  for i, v in ipairs(elementalTypeList) do
    if element == v then
      do return true end
    end
  end
  return false
end

function addPrefix(parameters, config, prefix) --weird, but values changed through parameters get run on every reload, so need to check to avoid adding an endless amount of prefixes
  --options file  
  if parameters.shortdescription and not parameters.hasPrefix then
    parameters.hasPrefix = true
    local colorWeaponNamesFor = options.getOption("colorWeaponNamesFor")
    
    local shouldAddPrefix = not isManufacturerConfigPropertyTrue(parameters, config, "disablePrefixAdding")
    local shouldAddColor = not isManufacturerConfigPropertyTrue(parameters, config, "disableNameColoring")
    if colorWeaponNamesFor and shouldAddColor then
      if shouldAddPrefix then
        if colorWeaponNamesFor == "level" then
          parameters.shortdescription = color.getColorByLevel(math.floor(parameters.level or 1)) .. prefix .. "^#FFFFFF;" .. parameters.shortdescription
        elseif colorWeaponNamesFor == "levelFull" then
          parameters.shortdescription = color.getColorByLevel(math.floor(parameters.level or 1)) .. prefix .. parameters.shortdescription
        elseif colorWeaponNamesFor == "rarity" then
          parameters.shortdescription = color.getColorByRarity(config.rarity) .. prefix .. parameters.shortdescription
        end
      else
        --no level, as only the prefix gets colored for that, and there is none here
        if colorWeaponNamesFor == "levelFull" then
          parameters.shortdescription = color.getColorByLevel(math.floor(parameters.level or 1)) .. parameters.shortdescription
        elseif colorWeaponNamesFor == "rarity" then
          parameters.shortdescription = color.getColorByRarity(config.rarity) .. parameters.shortdescription
        end
      end
      parameters.hasColoredName = true
    elseif shouldAddPrefix then
      parameters.shortdescription = prefix .. parameters.shortdescription
    end
  end
end

function applyOperation(abilityConfig, baseValue, operation, modifier)
  local oper = kitmath[operation]
  if not modifier or not oper then
    do return baseValue end
  end
  
  if type(modifier) == "table" then
    --modifier is a function
    if modifier.evalFunction then
      local varAsParam = baseValue
      if modifier.variable then
        varAsParam = abilityConfig[modifier.variable]
      end
      baseValue = oper(baseValue, root.evalFunction(modifier.evalFunction, varAsParam))
    end
  else
    baseValue = oper(baseValue, modifier)
  end
  return baseValue
end

function applyModifier(abilityConfig, baseValue, modifier)
  return applyOperation(abilityConfig, baseValue, "multiply", modifier)
end

--advanced math stuff: more than just multiple by modifier
--not finished at all
function setValue(baseValue, mods)
  if not mods then
    do return baseValue end
  end

  return baseValue
end

function applyManufacturerStats(config, parameters, builderConfig, seed, manufacturerSource, weaponType, noPrefix, elementalTypeList)
  local manufacturerName = ""
  local projectileReplacements = {}
  local fireSoundReplacements = {}
  
  if manufacturerSource then  
    local manufacturerConfig = root.assetJson(manufacturerSource)
  
    --manufacturer id name
    manufacturerID = manufacturerConfig.manufacturerName or ""
  
    --manufacturer label
    manufacturerName = getManufacturerName(parameters.manufacturer, config, parameters)
    if options.hasLanguage() then
      manufacturerName = lang.getManufacturerName(manufacturerID, seed) or manufacturerName
    end
  
    --price
  
    if manufacturerConfig.priceMultiplier then
      config.price = config.price * manufacturerConfig.priceMultiplier
    end
    
    --proper elemental types
    local acceptableElements = manufacturerConfig.elementalType or elementalTypeList
    acceptableElements = kitelements.removeUnavailableElements(acceptableElements) --remove elements that aren't configured
    
    local defaultElement =  manufacturerConfig.defaultElementalType or (elementalTypeList[1] or "physical")
    
    --makes sure there is an element that works for both the manufacturer and the gun    
    if not hasAcceptableElement(config.elementalType, acceptableElements) and hasCommonElement(elementalTypeList, acceptableElements) then
      local newList = kitutil.intersection(elementalTypeList, acceptableElements)
      
      if builderConfig.treatPhysicalAsElementalType then
        table.insert(newList, "physical")
      end
      
      local newElementalType = randomFromList(newList, seed, "elementalType")
      
      if hasAcceptableElement(newElementalType, elementalTypeList) then
        config.elementalType = newElementalType
        parameters.elementalType = newElementalType
      elseif hasAcceptableElement(defaultElement, elementalTypeList) then --if elementalType generated is not acceptable, just use default if it is
        config.elementalType = defaultElement
        parameters.elementalType = defaultElement
      end
    end
  
    --weapon stats and palettes
    --determine if it is an older manufacturer file or a newer one
    local palettePath = nil
    local primaryAbility = nil
    if manufacturerConfig[weaponType] then
	    if manufacturerConfig[weaponType].palette then
        palettePath = manufacturerConfig[weaponType].palette
	    end
      primaryAbility = manufacturerConfig[weaponType].primaryAbility
    else --support for old file type
	    if weaponType == "ranged" then
        palettePath = manufacturerConfig.rangedPalette
        primaryAbility = manufacturerConfig.rangedPrimaryAbility
	    elseif weaponType == "melee" then
        palettePath = manufacturerConfig.meleePalette
        primaryAbility = manufacturerConfig.meleePrimaryAbility
	    end
    end
    
    --palettes (if no .appearance file)
    appearance.applyPalette(config, parameters, seed, palettePath)
	
	  --variables stuff
	  if manufacturerConfig[weaponType] and manufacturerConfig[weaponType].modifyVariables then
	    for k, v in ipairs(manufacturerConfig[weaponType].modifyVariables) do
		    local prev, name, isValid = kitutil.getSubTableParent(config, v.variable)
	  
	      if isValid then
          prev[name] = applyOperation(config.primaryAbility, prev[name], v.operation, v.value)
        end
	    end
	  end
	
    if primaryAbility and not builderConfig.noStatChanges then
      --Weapon Stats for Primary Ability
      if config.primaryAbility.fireTime then
        config.primaryAbility.fireTime = applyModifier(config.primaryAbility, config.primaryAbility.fireTime, primaryAbility.fireTimeMultiplier)
      end
	
      if config.primaryAbility.baseDps then
        config.primaryAbility.baseDps = applyModifier(config.primaryAbility, config.primaryAbility.baseDps, primaryAbility.baseDpsMultiplier)
	    end
	  
	    --FrackinUniverse's Crit stats
	    if config.critBonus then
	      config.critBonus = applyModifier(config.primaryAbility, config.critBonus, primaryAbility.critBonusMultiplier)
	    end
	    if config.critChance then
	      config.critChance = applyModifier(config.primaryAbility, config.critChance, primaryAbility.critChanceMultiplier)
	    end
     
	    --ranged only modifications
	    if weaponType == "ranged" then
	      if config.primaryAbility.energyUsage then
          config.primaryAbility.energyUsage = applyModifier(config.primaryAbility, config.primaryAbility.energyUsage, primaryAbility.energyUsageMultiplier)
        end
		
        if config.primaryAbility.projectileCount then
          config.primaryAbility.projectileCount = util.round(applyModifier(config.primaryAbility, config.primaryAbility.projectileCount, primaryAbility.projectileCountMultiplier) or 0, 0)
        end
		
		    if config.primaryAbility.projectileParameters and config.primaryAbility.projectileParameters.knockback then
          config.primaryAbility.projectileParameters.knockback = applyModifier(config.primaryAbility, config.primaryAbility.projectileParameters.knockback, primaryAbility.knockbackMultiplier)
        end
	
        if config.primaryAbility.inaccuracy then
          config.primaryAbility.inaccuracy = applyModifier(config.primaryAbility, config.primaryAbility.inaccuracy, primaryAbility.inaccuracyMultiplier)
        end
	    else
	    --melee only modifications
	      if primaryAbility.knockbackMultiplier and config.primaryAbility.damageConfig.knockbackRange then
          config.primaryAbility.damageConfig.knockbackRange = applyModifier(config.primaryAbility, config.primaryAbility.damageConfig.knockbackRange, primaryAbility.knockbackMultiplier)
	 
          if config.primaryAbility.stepDamageConfig then
            for k, v in ipairs(config.primaryAbility.stepDamageConfig) do
              if config.primaryAbility.stepDamageConfig[k].knockback then
                config.primaryAbility.stepDamageConfig[k].knockback = applyModifier(config.primaryAbility, config.primaryAbility.stepDamageConfig[k].knockback, primaryAbility.knockbackMultiplier)
              end
            end
          end
	      end
      end
	
      --Special Scripts
	  local scriptList = nil
      if manufacturerConfig[weaponType] and manufacturerConfig[weaponType].replaceScripts then
	      scriptList = manufacturerConfig[weaponType].replaceScripts
	    end
      if scriptList then
        for k, v in ipairs(scriptList) do
          for i, u in ipairs(config.scripts) do
            if v.script and v.replacement and u and v.script == u then
              table.remove(config.scripts, i)
              table.insert(config.scripts, v.replacement)
            end
          end
        end
      end
    
	  scriptList = nil
    if not noStatChanges and manufacturerConfig[weaponType] and manufacturerConfig[weaponType].scripts then
	    scriptList = manufacturerConfig[weaponType].scripts
	  end
      if scriptList then
        for k, v in ipairs(scriptList) do
          if v then
            table.insert(config.scripts, v)
          end
        end
      end
    
      if primaryAbility.setVariables then
        for k, v in ipairs(primaryAbility.setVariables) do
          if v.variable and type(v.variable) == "string" and v.value then
		        local path = kitutil.splitString(v.variable)
            local cur = config.primaryAbility
            local prev --stupid workaround because Lua doesn't support references or pointers
			      for i, loc in ipairs(path) do
              if not cur[loc] then
			          cur[loc] = {}
              end
              prev = cur
              cur = cur[loc]
            end
			      prev[path[#path]] = v.value
          end
        end
      end
    
      if primaryAbility.projectileReplacements then
        projectileReplacements = primaryAbility.projectileReplacements
      end
	end
  
    fireSoundReplacements = appearance.applyManufacturerAppearance(config, parameters, builderConfig, seed, manufacturerConfig, weaponType)
  
    --prefix
    if not noPrefix then
      if parameters.shortdescription ~= nil and not parameters.hasPrefix then
        if not isManufacturerConfigPropertyTrue(parameters, config, "disableNamePrefixRemoval") then
          parameters.shortdescription = kitutil.getLastPartOfSpaceDelimitedString(parameters.shortdescription)
        end
      end
  
      local level = math.floor(parameters.level or 1)
      local prefix = manufacturerConfig.prefix or { "" }
      
      if options.hasLanguage() then
        prefix = lang.replacePrefixes(manufacturerID, prefix, seed)
      end
      
      local selectedPrefix = nil
      if level <= #prefix then
        if level <= 0 then
          selectedPrefix = prefix[1]
        else
          selectedPrefix = prefix[level]
        end
      else
        selectedPrefix = prefix[#prefix]
      end
      if type(selectedPrefix) == "table" then
        --there are multiple prefixes in a table, choose one at random
        addPrefix(parameters, config, util.randomChoice(selectedPrefix))
      else
        --there is only one for this tier
        addPrefix(parameters, config, selectedPrefix)
      end
    end
  end  
  return manufacturerName, projectileReplacements, fireSoundReplacements --this is by far my favorite part of lua!
end

-- Determines manufacturer from config/parameters and then adds it.
function setupManufacturer(config, parameters, builderConfig, seed, weaponType, noPrefix, elementalTypeList)
  if parameters.manufacturer == "none" or not parameters.manufacturer then
    do return end
  end
    
  seed = seed or parameters.seed or config.seed or 0
  
  local manufacturerSource = getManufacturerSourceFromType(parameters.manufacturer)
  
  local manufacturerName = ""
  local projectileReplacements = {}
  local fireSoundReplacements = {}
  
  if manufacturerSource then
    manufacturerName, projectileReplacements, fireSoundReplacements = applyManufacturerStats(config, parameters, builderConfig, seed, manufacturerSource, weaponType, noPrefix, elementalTypeList)
  end
  return manufacturerName, projectileReplacements, fireSoundReplacements
end

--Applies needed changes to non random weapons with manufacturers (just tooltip stuff)
function getManufacturerName(manufacturer, config, parameters)
  if parameters.manufacturer == "none" or not parameters.manufacturer then
    do return "" end
  end
  local manufacturerName = ""
  local manufacturerSource = getManufacturerSourceFromType(parameters.manufacturer)
  
  if manufacturerSource then
    local manufacturerConfig = root.assetJson(manufacturerSource)
    manufacturerName = manufacturerConfig.friendlyName or ""
	
    if config.setManufacturerNameToCustom or parameters.setManufacturerNameToCustom then
      --So that weapons that have been modified can appear as "custom" while still using a manufacturer's stats
      manufacturerName = "Custom"
    end
    
    if manufacturerConfig.nameColor and options.getOption("colorManufacturerNames") then
      manufacturerName = "^#" .. manufacturerConfig.nameColor .. ";" .. manufacturerName .. "^reset;"
    end
  end
  return manufacturerName
end