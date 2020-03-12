# (Starbound) Manufacturer's Touch

A mod to overhaul weapon creation in Starbound, allowing manufacturers to modify weapon stats, palettes, and names on item creation.

## Current Version Major Features

Nothing of note right now, see change log

## Notes on File Extensions

Some of these files have strange extensions. I would like to note that these were not my first choices.

.manu files are used instead of .manufacturer files, because Starbound believes that the JSON is malformed if it uses that extension.

.palettes files are used instead of .weaponcolors files, because Starbound will only read the first palette from some of those files,
rather than reading all of the palettes to choose a proper color.

## Notes on New Random Weapons

If you plan on adding any new weapons that use manufacturers, you need to be careful about which elements are supported.
By default in Starbound, uncommon and rare weapons are always elemental, and they do not support physical damage. However,
some manufacturers, like Callox, will default to physical damage.

In order to get past this, these elemental weapons need to have

"treatPhysicalAsElementalType" : true,

in their builderConfig, and then physical needs to be listed in the elementalConfig.