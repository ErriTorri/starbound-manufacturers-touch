require "/scripts/mt/lang.lua"

options = {}

function options.getOption(option)
  if not pcall(function ()
    if not options.config then
      options.config = root.assetJson("/manufacturerstouch.config")
      --[===[
      if options.config.language then
        lang.config = root.assetJson("/lang/" .. options.config.language .. ".config")
        lang.replacePaths()
      end
      --]===]
    end
  end) then
    options.config = { }
  end
  return options.config[option]
end

function options.isFrackinUniverseLoaded()
  if options.frackinUniverseIsLoaded == nil then
    local json = root.assetJson("/instance_worlds.config")
	options.frackinUniverseIsLoaded = json["scienceoutpost"] ~= nil
  end
  return options.frackinUniverseIsLoaded
end

function options.hasLanguage()
  return false --the language files aren't properly working right now, so this is disabled
  --return options.getOption("language") ~= nil
end