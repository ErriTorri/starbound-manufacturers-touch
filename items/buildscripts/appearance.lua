require "/scripts/util.lua"
require "/scripts/staticrandom.lua"
require "/scripts/mt/options.lua"

color = {}
appearance = {}

local rarityColorTable = {
  ["common"] = "^#ffffff;",
  ["uncommon"] = "^#37a336;",
  ["rare"] = "^#3ea8c5;",
  ["legendary"] = "^#833bbe;"
}

local levelColorTable = {
  "^#7E7066;",
  "^#FFFFFF;",
  "^#37a336;",
  "^#3ea8c5;",
  "^#833bbe;",
  "^#FF8000;"
}

function color.getColorByRarity(keyword)
  return rarityColorTable[string.lower(keyword)] or ""
end

function color.getColorByLevel(level)
  local colorStr = ""
  if level >= 1 then
    if level > #levelColorTable then
      colorStr = levelColorTable[#levelColorTable]
    else
      colorStr = levelColorTable[level]
    end
  end
  return colorStr
end

function appearance.getElementalMuzzleFlash(element)
  local config = root.assetJson("/items/active/weapons/elements/muzzleflash.config")
  if config[element] then
    return config[element]
  elseif config.default then
    return config.default
  else
    return ""
  end
end

function appearance.applyPalette(config, parameters, seed, palettePath)
  if options.getOption("useManufacturerPalettes") then
    if palettePath and not parameters.WA_customPalettes then
      config.paletteSwaps = ""
    local palette = root.assetJson(palettePath)
    local selectedSwaps = randomFromList(palette.swaps, seed, "paletteSwaps")
      for k, v in pairs(selectedSwaps) do
        config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
      end
    end
  end
end

function appearance.applyManufacturerAppearance(config, parameters, builderConfig, seed, manufacturerConfig, weaponType)
  local fireSoundReplacements = {}
  if manufacturerConfig.appearance then
    local appearanceConfig = root.assetJson(manufacturerConfig.appearance)
    local categoryConfig = nil
    if appearanceConfig then
      if appearanceConfig.specific and appearanceConfig.specific[config.category] then
        categoryConfig = appearanceConfig.specific[config.category]
      end
      local palettePath
      if categoryConfig and categoryConfig.palette then
        palettePath = categoryConfig.palette
      elseif appearanceConfig["default" .. (weaponType:gsub("^%l", string.upper)) .. "Palette"] then
        palettePath = appearanceConfig["default" .. (weaponType:gsub("^%l", string.upper)) .. "Palette"]
      end
      appearance.applyPalette(config, parameters, seed, palettePath)
      
      if appearanceConfig.fireSoundReplacements then
          fireSoundReplacements = appearanceConfig.fireSoundReplacements
      end
      
      if appearanceConfig.categoryMappings and appearanceConfig.categoryMappings[config.category] then
        config.category = appearanceConfig.categoryMappings[config.category]
      end
      
      if categoryConfig then
          if categoryConfig.animationParts  then builderConfig.animationParts  = kitutil.mergeTablesWithOverwriting(builderConfig.animationParts, categoryConfig.animationParts) end
          if categoryConfig.baseOffset      then builderConfig.baseOffset      = categoryConfig.baseOffset     end
          if categoryConfig.muzzleOffset    then builderConfig.muzzleOffset    = categoryConfig.muzzleOffset   end
          if categoryConfig.gunParts        then builderConfig.gunParts        = categoryConfig.gunParts       end
          if categoryConfig.iconDrawables   then builderConfig.iconDrawables   = categoryConfig.iconDrawables  end
        
        if categoryConfig.fireSoundReplacements then
          fireSoundReplacements = categoryConfig.fireSoundReplacements
        end
        
        if categoryConfig.nameGenerator then
          if not parameters.hasPrefix then --if hasPrefix is set already, then that means that it was given a name rather than needing one generated
            parameters.shortdescription = root.generateName(categoryConfig.nameGenerator, seed)
          end
        end	  
        
      end
      
      if appearanceConfig.useElementalMuzzleFlash and builderConfig and builderConfig.animationParts and builderConfig.animationParts.muzzleFlash
        and builderConfig.animationParts.muzzleFlash == "/items/active/weapons/ranged/muzzleflash.png" then
        
        builderConfig.animationParts.muzzleFlash = appearance.getElementalMuzzleFlash(parameters.elementalType)
      end
    end
  end
  return fireSoundReplacements 
end