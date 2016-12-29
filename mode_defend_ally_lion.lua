
require( GetScriptDirectory().."/mode_defend_ally_generic" )
require( GetScriptDirectory().."/ability_item_usage_lion" )

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
followup = 0;
frametick = -1;

function SelectTargetHighThreat(npcBot, tableNearbyEnemyHeroes)
    -- unimplemented
end
function SelectTargetClosest(npcBot, tableNearbyEnemyHeroes)
    -- Actually sorted after Dec 21 bot API update
    for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
        npcBot:SetTarget(npcEnemy);
        return;
    end
    return;

    --[[
    if (#tableNearbyEnemyHeroes > 0) then
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
    --]]
end
function CastImpaleOnTarget(npcBot, tableNearbyEnemyHeroes)
    -- attempt to cast Impale on the closest enemy
    -- Check if we're already using an ability
    if ( npcBot:IsUsingAbility() ) then return end;
    -- If we have a target and can cast Impale on them, do so
    if ( npcBot:GetTarget() ~= nil ) then
        abilityImpale = npcBot:GetAbilityByName( "lion_impale" );
        print(abilityImpale:GetCooldownTimeRemaining());
        if ( abilityImpale:IsFullyCastable() ) then
            npcBot:Action_UseAbilityOnLocation( abilityImpale, npcBot:GetTarget():GetLocation() );
            ability_item_usage_lion.timeOfLastImpaleCast = DotaTime();
            return true;
        end
    end
    return false;
end

function Think()
    -- Do the standard Think
    mode_generic_defend_ally.Think()

    local npcBot = GetBot();
    local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    SelectTargetClosest(npcBot, tableNearbyEnemyHeroes);
    if (CastImpaleOnTarget(npcBot, tableNearbyEnemyHeroes) == false) then
        -- cant cast impale. do something else
    followup = 1;
    else
    followup = 1;
        -- upon successful cast
        -- if danger > 0.5, move back
        -- elseif danger < 0.5, harass a bit, then back
        
    end
    print(CastImpaleOnTarget(npcBot, tableNearbyEnemyHeroes));
end

----------------------------------------------------------------------------------------------------

function GetDesire()
    
    if(frametick > 10) then
        followup = 0
        frametick = -1;
    end

    if (followup == 1) then
        print("following up 1: " .. frametick);
        -- force back to mode_retreat by reducing threat to 0
        totalThreat = 0
        -- for 30 frameticks
        -- count each frame
        frametick = frametick + 1;
        return RemapValClamped( totalThreat, 0.0, 1.0, BOT_MODE_DESIRE_NONE, BOT_MODE_DESIRE_HIGH );
    elseif (followup == 2) then
        print("following up 2: " .. frametick);
        -- force back to mode_retreat by reducing threat to 0
        totalThreat = 0
        -- for 30 frameticks
        -- count each frame
        frametick = frametick + 1;
        return RemapValClamped( totalThreat, 0.0, 1.0, BOT_MODE_DESIRE_NONE, BOT_MODE_DESIRE_HIGH );
    end
    -- did for 30 frames

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

