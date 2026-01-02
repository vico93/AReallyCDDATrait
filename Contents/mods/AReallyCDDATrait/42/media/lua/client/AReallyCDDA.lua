local AReallyCDDATraitRegistries = require("AReallyCDDATrait/Registries")

local function StartBurnInside(_tile)
    if (not _tile:isOutside()) then
        _tile:StartFire();
        local b = ZombRand(1, 3);
        if (b > 1) then  _tile:Burn() end
    end
    return _tile;
end

local function StartBurnInsideAround(_tile)
    local n = ZombRand(1, 2);
    if (n == 2) then
        StartBurnInside(_tile:getTileInDirection(IsoDirections.N));
        StartBurnInside(_tile:getTileInDirection(IsoDirections.E));
        StartBurnInside(_tile:getTileInDirection(IsoDirections.SW));
        StartBurnInside(_tile:getTileInDirection(IsoDirections.NW));
    else
        StartBurnInside(_tile:getTileInDirection(IsoDirections.S));
        StartBurnInside(_tile:getTileInDirection(IsoDirections.W));
        StartBurnInside(_tile:getTileInDirection(IsoDirections.NE));
        StartBurnInside(_tile:getTileInDirection(IsoDirections.SE));
    end
    StartBurnInside(_tile);
    return _tile;
end

local function getTile(_originTile, _direction, _distance)
    local nextTile = _originTile;
    for i=_distance,1,-1 do nextTile = nextTile:getTileInDirection(_direction); end
    return nextTile;
end

local function initCDDAFire(_player)
    for i = 0, 10 do
        outdoorTile = _player:getCell():getRandomOutdoorTile();
        if outdoorTile then outdoorTile:explode(); end -- we start a bunch of fires outdoors. 
    end
    local playerSquare = _player:getCurrentSquare();
    StartBurnInsideAround(getTile(playerSquare, IsoDirections.NW, 3)); -- then we start a bunch of fires indoors 3 tiles away around the player
    StartBurnInsideAround(getTile(playerSquare, IsoDirections.NE, 3)); -- We don't use explode() here because the explosion is too powerful
    StartBurnInsideAround(getTile(playerSquare, IsoDirections.SW, 3));
    StartBurnInsideAround(getTile(playerSquare, IsoDirections.SE, 3));
    StartBurnInsideAround(getTile(playerSquare, IsoDirections.N, 3));
    StartBurnInsideAround(getTile(playerSquare, IsoDirections.E, 3));
    StartBurnInsideAround(getTile(playerSquare, IsoDirections.S, 3));
    StartBurnInsideAround(getTile(playerSquare, IsoDirections.W, 3));
    if not playerSquare then return end
	local room = playerSquare:getRoom();
	if not room then return end
	local building = room:getBuilding();
	if not building then return end
	for i = 0, 7 do
		local tile = building:getRandomRoom():getRandomSquare(); -- get random tile of a random room of the building where the player spawns; this allows us to get tiles that are upstairs or downstairs relative to the player. don't know how else to do it
		if(tile:getRoom() == room) then
			i = i - 1; -- skip this iteration, to ensure no fire starts on the player's tile
		else
			StartBurnInsideAround(tile);
		end
	end
end

local function initCDDAPlayer(_player)
    _player:getStats():set(CharacterStat.INTOXICATION, 100); -- start drunk
    _player:getStats():set(CharacterStat.PANIC, 100); -- start panicked. Because why not
    _player:getBodyDamage():increaseBodyWetness(100); -- start wet
    _player:getBodyDamage():setHasACold(true);-- set up nasty cold
    _player:getBodyDamage():setCatchACold(0.0);
    _player:getBodyDamage():setColdStrength(80.0);
    _player:getBodyDamage():setTimeToSneezeOrCough(0);
    local inv = _player:getInventory()
    local itemsToRemove = {}
    local items = inv:getItems()
    for i=0, items:size()-1 do
        local item = items:get(i)
        local type = item:getFullType()
        -- Lógica de preservação: Chaves, Mapas e ID Cards
        if type ~= "Base.Key1" 
        and not item:IsMap() 
        and type ~= "Base.IDcard" 
        and type ~= "Base.IDcard_Female" 
        and type ~= "Base.IDcard_Male" 
        and type ~= "Base.IDcard_Stolen" then
            table.insert(itemsToRemove, item)
        end
    end

    -- Remove apenas os itens que não foram preservados
    for _, item in ipairs(itemsToRemove) do
        inv:Remove(item)
    end
    _player:clearWornItems();-- remove all clothes
    _player:setClothingItem_Feet(nil);
    _player:setClothingItem_Legs(nil);
    _player:setClothingItem_Torso(nil);
    _player:setClothingItem_Head(nil);
    _player:setClothingItem_Hands(nil);
    -- inv:AddItem("Base.KeyRing"); --we give the player a key ring cause it's not lootable anywhere.
    -- TODO: remove line above and add keyRing to loot tables
    _player:getBodyDamage():getBodyPart(BodyPartType.Groin):generateDeepShardWound();-- start with a deep wound with glass shard in the groin
    local whichPartIsScratched = 9;-- random scratch between leg, foot and torso parts
    if whichPartIsScratched == 1 then _player:getBodyDamage():SetScratched(BodyPartType.LowerLeg_L, true) end
	if whichPartIsScratched == 2 then _player:getBodyDamage():SetScratched(BodyPartType.LowerLeg_R, true) end
    if whichPartIsScratched == 3 then _player:getBodyDamage():SetScratched(BodyPartType.UpperLeg_L, true) end
    if whichPartIsScratched == 4 then _player:getBodyDamage():SetScratched(BodyPartType.UpperLeg_R, true) end
    if whichPartIsScratched == 5 then _player:getBodyDamage():SetScratched(BodyPartType.Foot_R, true) end
    if whichPartIsScratched == 6 then _player:getBodyDamage():SetScratched(BodyPartType.Foot_L, true) end
    if whichPartIsScratched == 7 then _player:getBodyDamage():SetScratched(BodyPartType.Torso, true) end
    if whichPartIsScratched == 8 then _player:getBodyDamage():SetScratched(BodyPartType.ForeArm_L, true) end
    if whichPartIsScratched == 9 then _player:getBodyDamage():SetScratched(BodyPartType.UpperArm_L, true) end
end

local function initCDDA()
    local player = getPlayer();
    if player:getHoursSurvived() > 1 then return end --additionnal security check
    if player:hasTrait(AReallyCDDATraitRegistries.traits.AReallyCDDAFireOnly) then return end -- end function if player has cdda fire only trait
    if not player:hasTrait(AReallyCDDATraitRegistries.traits.AReallyCDDA) then return end -- end function if player doesn't have cdda trait
    initCDDAPlayer(player); -- init injuries, moodles, stats and inventory
    initCDDAFire(player); -- init fire around player, inside and outside
    addSound(player, player:getX(), player:getY(), 0, 50, 50);--zombies heard the player break his shower's glass //TODO not sure if this works
    Events.OnTick.Remove(initCDDA);-- we remove the function from the OnTick event, so that the function is only called once
    Events.OnTick.Remove(initCDDAPlayerOnly);
    Events.OnTick.Remove(initCDDAFireOnly);
end

local function initCDDAFireOnly()
    local player = getPlayer();
    if player:getHoursSurvived() > 1 then return end --additionnal security check
    if player:hasTrait(AReallyCDDATraitRegistries.traits.AReallyCDDA) or player:hasTrait(AReallyCDDATraitRegistries.traits.AReallyCDDAPlayerOnly) then return end -- end function if player has cdda trait
    if not player:hasTrait(AReallyCDDATraitRegistries.traits.AReallyCDDAFireOnly) then return end -- end function if player doesn't have cdda fire only trait
    initCDDAFire(player); -- init fire around player, inside and outside
    addSound(player, player:getX(), player:getY(), 0, 100, 100);--zombies heard the player break his shower's glass //TODO not sure if this works
    Events.OnTick.Remove(initCDDAFireOnly);-- we remove the function from the OnTick event, so that the function is only called once
    Events.OnTick.Remove(initCDDAPlayerOnly);
    Events.OnTick.Remove(initCDDA);
end

local function initCDDAPlayerOnly()
    local player = getPlayer();
    if player:getHoursSurvived() > 1 then return end --additionnal security check
    if player:hasTrait(AReallyCDDATraitRegistries.traits.AReallyCDDA) or player:hasTrait(AReallyCDDATraitRegistries.traits.AReallyCDDAFireOnly) then return end
    if not player:hasTrait(AReallyCDDATraitRegistries.traits.AReallyCDDAPlayerOnly) then return end 
    initCDDAPlayer(player); -- init fire around player, inside and outside
    addSound(player, player:getX(), player:getY(), 0, 100, 100);--zombies heard the player break his shower's glass //TODO not sure if this works
    Events.OnTick.Remove(initCDDAPlayerOnly);-- we remove the function from the OnTick event, so that the function is only called once
    Events.OnTick.Remove(initCDDAFireOnly);
    Events.OnTick.Remove(initCDDA);
end


local function addInitCDDAToOnTickEvent()
    Events.OnTick.Add(initCDDA); -- we use OnTick event so that the trait works with characters created via the death screen, to spawn fire in the world; and also to clear any item given by other mods
    Events.OnTick.Add(initCDDAFireOnly); 
    Events.OnTick.Add(initCDDAPlayerOnly); 
end

Events.OnCreatePlayer.Add(addInitCDDAToOnTickEvent);