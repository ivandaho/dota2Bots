local DotaBotUtility = require(GetScriptDirectory().."/utility");

----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_item_usage_generic", package.seeall )

----------------------------------------------------------------------------------------------------

function AbilityUsageThink()
	local courier = DotaBotUtility.IsItemAvailable("item_courier");
	if(courier ~= nil) then
		local npcBot = GetBot();
		npcBot:Action_UseAbility(courier);
	end

	--print( "Generic.AbilityUsageThink" );

end

----------------------------------------------------------------------------------------------------

function ItemUsageThink()

	--print( "Generic.ItemUsageThink" );

end

----------------------------------------------------------------------------------------------------


for k,v in pairs( ability_item_usage_generic ) do	_G._savedEnv[k] = v end
