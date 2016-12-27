
require( GetScriptDirectory().."/mode_defend_ally_generic" )

----------------------------------------------------------------------------------------------------

function OnStart()
    -- Do the standard OnStart
    mode_generic_defend_ally.OnStart();
end

----------------------------------------------------------------------------------------------------

function OnEnd()
    -- Do the standard OnEnd
    mode_generic_defend_ally.OnEnd();
end

----------------------------------------------------------------------------------------------------

totalThreat = 0;
comfortableDistance = 550;
threatDecayAmount = 0.05;

function UpdateTotalThreat(npcBot)

end

function Think()

    local npcBot = GetBot();

    local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );

    if (#tableNearbyEnemyHeroes > 0) then
        -- danger
        local closestEnemy = nil;
        local closestEnemyDistance = 99999;
        for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
            local distToEnemy = GetUnitToUnitDistance(npcBot, npcEnemy);
            if (distToEnemy < closestEnemyDistance) then
                closestEnemy = npcEnemy;
                closestEnemyDistance =  distToEnemy;
            end
        end
        npcBot:SetTarget(closestEnemy);
    end


    -- Do the standard Think
    mode_generic_defend_ally.Think()

    -- Check if we're already using an ability
    if ( npcBot:IsUsingAbility() ) then return end;
    
    -- If we have a target and can cast Impale on them, do so
    if ( npcBot:GetTarget() ~= nil ) then
        abilityImpale = npcBot:GetAbilityByName( "lion_impale" );
        if ( abilityImpale:IsFullyCastable() ) then
            npcBot:Action_UseAbilityOnLocation( abilityImpale, npcBot:GetTarget():GetLocation() );
        end
    end
end

----------------------------------------------------------------------------------------------------

function GetDesire()
    print(totalThreat);
    -- decay threat
    totalThreat = totalThreat - threatDecayAmount;
    if (totalThreat < 0) then
        totalThreat = 0;
    elseif (totalThreat > 1.0) then
        totalThreat = 1.0;
    end

    local npcBot = GetBot();
    local fBonus = 0.0;

    local tableNearbyRetreatingAlliedHeroes = npcBot:GetNearbyHeroes( 1000, false, BOT_MODE_RETREAT );
    if ( #tableNearbyRetreatingAlliedHeroes > 0 )
    then
        for _,npcAlly in pairs( tableNearbyRetreatingAlliedHeroes ) do
            totalThreat = totalThreat + 0.05;
        end
    end

    local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );

    if (#tableNearbyEnemyHeroes > 0) then
        -- danger
        for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
            local distToEnemy = GetUnitToUnitDistance(npcBot, npcEnemy);
            if (distToEnemy < comfortableDistance) then
                local proximityDanger = 1 - (distToEnemy / comfortableDistance);
                totalThreat = totalThreat + proximityDanger;
            end
        end
        return RemapValClamped( totalThreat, 0.0, 1.0, BOT_MODE_DESIRE_NONE, BOT_MODE_DESIRE_HIGH );
    end
    return BOT_MODE_DESIRE_NONE
    -- Is there a good enemy to stun?
end
----------------------------------------------------------------------------------------------------

