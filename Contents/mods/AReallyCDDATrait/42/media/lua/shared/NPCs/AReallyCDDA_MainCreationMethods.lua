
local function initCDDATraits()
	TraitFactory.addTrait(
		"AReallyCDDA",
		getText("UI_trait_areallycdda"),
		-1,
		getText("UI_trait_areallycddadesc"),
		false
	);
	TraitFactory.addTrait(
		"AReallyCDDAFireOnly",
		getText("UI_trait_areallycddafireonly"),
		-1,
		getText("UI_trait_areallycddafireonlydesc"),
		false
	);
	TraitFactory.addTrait(
		"AReallyCDDAPlayerOnly",
		getText("UI_trait_areallycddaplayeronly"),
		-1,
		getText("UI_trait_areallycddaplayeronlydesc"),
		false
	);
	TraitFactory.setMutualExclusive("AReallyCDDA", "AReallyCDDAFireOnly")
	TraitFactory.setMutualExclusive("AReallyCDDA", "AReallyCDDAPlayerOnly")
	TraitFactory.setMutualExclusive("AReallyCDDAFireOnly", "AReallyCDDAPlayerOnly")
end

Events.OnGameBoot.Add(initCDDATraits);