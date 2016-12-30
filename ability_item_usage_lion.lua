_G._savedEnv = getfenv()
module( "ability_item_usage_lion", package.seeall )

local utils = require(GetScriptDirectory() .. "/util")
----------------------------------------------------------------------------------------------------

castImpaleDesire = 0;
castVoodooDesire = 0;
castManaDrainDesire = 0;
castFingerDesire = 0;
-- min = 0
-- sec = 0
timeOfLastImpaleCast = -1;
----------------------------------------------------------------------------------------------------

--mess should keep courier clear?
function CourierUsageThink()
    local npcBot = GetBot();
    if (IsCourierAvailable() and
        npcBot:GetCourierValue( ) > 0 and
        npcBot:GetActiveMode() ~= BOT_MODE_ATTACK and
        npcBot:GetActiveMode() ~= BOT_MODE_RETREAT and
        npcBot:GetActiveMode() ~= BOT_MODE_EVASIVE_MANEUVERS and
        npcBot:GetActiveMode() ~= BOT_MODE_DEFEND_ALLY)
    then
        npcBot:Action_CourierDeliver( )
    end
end

----------------------------------------------------------------------------------------------------
function CheckDesires()
    return castImpaleDesire, castVoodooDesire, castManaDrainDesire;
end

function AbilityUsageThink()
    local npcBot = GetBot();

    -- min = math.floor(DotaTime() / 60)
    -- sec = DotaTime() % 60

    -- Check if we're already using an ability
    if (npcBot:IsUsingAbility()) then
        local abilityManaDrain = npcBot:GetAbilityByName("lion_mana_drain");
        if not (abilityManaDrain:IsChanneling()) then
            -- print("ability that is being used is not mana drain");
            return
        end
        -- an ability is being used (mana drain)
        -- might want to interrupt mana drain for something better
        -- print(ManaPriority(npcBot));
        if (ManaPriority(npcBot) > 0.7) then
            -- if we need mana for other spells,
            -- continue channeling mana drain
            return
        end

        -- TODO: insert logic to retreat back if channeling with low health
        -- local defensive = false;
        -- if (npcBot:GetHealth() / npcBot:GetMaxHealth() < 0.5) then
        --     defensive = true;
        -- end
        -- if (defensive == true) then
        --     print("health low while casting mana drain.");
        -- end


    end

    abilityImpale = npcBot:GetAbilityByName("lion_impale");
    abilityVoodoo = npcBot:GetAbilityByName("lion_Voodoo");
    abilityManaDrain = npcBot:GetAbilityByName("lion_mana_drain");
    abilityFinger = npcBot:GetAbilityByName("lion_finger_of_death");

    castImpaleDesire, castImpaleTarget = ConsiderImpale();
    castVoodooDesire, castVoodooTarget = ConsiderVoodoo();
    castManaDrainDesire, castManaDrainTarget = ConsiderManaDrain();
    -- print(CheckDesires());


    local highestDesire = castImpaleDesire;
    local desiredSkill = 1;

    if ( castVoodooDesire > highestDesire)
        then
            highestDesire = castVoodooDesire;
            desiredSkill = 2;
    end

    if ( castManaDrainDesire > highestDesire)
        then
            highestDesire = castManaDrainDesire;
            desiredSkill = 3;
    end
    --[[

    if ( castFingerDesire > highestDesire)
        then
            highestDesire = castFingerDesire;
            desiredSkill = 4;
    end
    --]]
    -- print("highestDesire: " .. highestDesire .. "|desiredSkill: " .. desiredSkill .. "|castImpaleDesire: " .. castImpaleDesire .. "|castVoodooDesire: " .. castVoodooDesire);

    if highestDesire == 0 then return;
    elseif desiredSkill == 1 then
        npcBot:Action_UseAbilityOnEntity( abilityImpale, castImpaleTarget );
        timeOfLastImpaleCast = DotaTime();
    elseif desiredSkill == 2 then
        npcBot:Action_UseAbilityOnEntity( abilityVoodoo, castVoodooTarget );
    elseif desiredSkill == 3 then
        npcBot:Action_UseAbilityOnEntity( abilityManaDrain, castManaDrainTarget );
    elseif desiredSkill == 4 then
        npcBot:Action_UseAbilityOnEntity( abilityFinger, castFingerTarget );
    end
end

----------------------------------------------------------------------------------------------------

function CanCastImpaleOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

----------------------------------------------------------------------------------------------------

function ConsiderImpale()
    -- local debug = false;
    -- if (debug == true) then
        -- print("debug is turned on - don't consider using Impale");
    --     return BOT_ACTION_DESIRE_NONE;
    -- end

    local npcBot = GetBot();

    -- Make sure it's castable
    if (not abilityImpale:IsFullyCastable()) then
        -- print("Impale: not fully castable");
        return BOT_ACTION_DESIRE_NONE;
    end;
    -- print("Impale: thinking about casting");

    -- If we want to cast priorities at all, bail
    --if ( castPhaseDesire > 0 or castCoilDesire > 50) then
    --  return BOT_ACTION_DESIRE_NONE;
    --end

    -- Get some of its values
    local nWidth = abilityImpale:GetSpecialValueInt( "width" );
    local nCastRange = abilityImpale:GetCastRange();
    local nSpeed = abilityImpale:GetSpecialValueInt( "speed" );

    --------------------------------------
    -- Mode based usage
    --------------------------------------


    -- consider casting on enemy if on the offense
    if ( npcBot:GetActiveMode() == BOT_MODE_ATTACK ) then
        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 700, true, BOT_MODE_NONE );
        return BOT_ACTION_DESIRE_HIGH, tableNearbyEnemyHeroes[1];
    end


    -- force lion to think in all modes
    -- local debug2 = true;
    -- if (debug2 == true) then

    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
    if ( npcBot:GetActiveMode() == BOT_MODE_RETREAT and npcBot:GetActiveModeDesire() >= BOT_MODE_DESIRE_LOW ) then
        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + nWidth, true, BOT_MODE_NONE );
        for _,npcTarget in pairs( tableNearbyEnemyHeroes )
        do
            if ( npcBot:WasRecentlyDamagedByHero( npcTarget, 2.0 ) )
            then
                -- note, npcBot calls it, not npcTarget
                if (CanCastImpaleOnTarget(npcTarget)) then
                    -- retreat Impale
                    -- print("Impale: cast - reason: recently damaged lion");
                    return BOT_ACTION_DESIRE_MODERATE, npcTarget;
                end
            end
        end
        -- if there is no unit that recently damaged lion, cast Impale on the closest enemy
        for _,npcTarget in pairs( tableNearbyEnemyHeroes ) do
            -- set target to nearest enemy
            -- print("Impale: cast - reason: closest to lion (no recent hero damage sources)");
            return BOT_ACTION_DESIRE_MODERATE, npcTarget;
        end
    end

    -- If we're going after someone
    -- TODO: COMMENT START
    -- if ( npcBot:GetActiveMode() == BOT_MODE_ROAM or
    --      npcBot:GetActiveMode() == BOT_MODE_ATTACK or
    --      npcBot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
    --      npcBot:GetActiveMode() == BOT_MODE_GANK or
    --      npcBot:GetActiveMode() == BOT_MODE_DEFEND_ALLY )
    -- then
    --     local npcTarget = npcBot:GetTarget();

    --     if ( npcTarget ~= nil )
    --     then
    --         if ( CanCastImpaleOnTarget( npcTarget ) and GetUnitToUnitDistance( npcBot, npcTarget ) < nCastRange)
    --         then
            --print("Chase Impale")
    --             return BOT_ACTION_DESIRE_MODERATE, npcTarget;
    --         end
    --     end
    -- end
    -- TODO: COMMENT END

    -- If we're about to meepmeep someone
    -- TODO: change to FOD combo
    --[[

    if  npcBot:GetActiveMode() == BOT_MODE_ATTACK
    then
        local npcTarget = npcBot:GetTarget();

        if ( npcTarget ~= nil)
        then
            if ( CanCastEarthBindOnTarget( npcTarget ) and GetUnitToUnitDistance( npcBot, npcTarget ) < 160)
            then
            -- print("MeepMeep Net")
                return BOT_ACTION_DESIRE_MODERATE, utils.GetXUnitsInFront(npcTarget, 100);
            end
        end
    end
    --]]
    -- print("Impale: No reason to impale");

    return BOT_ACTION_DESIRE_NONE;

end

----------------------------------------------------------------------------------------------------

function CanCastVoodooOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

----------------------------------------------------------------------------------------------------

function ConsiderVoodoo()

    local npcBot = GetBot();

    -- Make sure it's castable
    if ( not abilityVoodoo:IsFullyCastable() ) then
        -- print("Hex: not fully castable");
        return BOT_ACTION_DESIRE_NONE;
    end;
    -- print("Hex: thinking about casting");


    -- If we want to cast priorities at all, bail
    -- TODO: put logic for priority over other skills
    --[[
    if ( castNetDesire > 0 ) then
        return BOT_ACTION_DESIRE_NONE;
    end
    --]]

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    -- force lion to think in all modes
    -- local debug2 = true;
    -- if (debug2 == true) then

    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
    local defensive = false;
    if (npcBot:GetActiveMode() == BOT_MODE_RETREAT) or (npcBot:GetActiveMode() == BOT_MODE_DEFEND_ALLY) then
        defensive = true;
    end
    if (defensive == true) and (npcBot:GetActiveModeDesire() >= BOT_MODE_DESIRE_LOW ) then
        if (abilityImpale:IsFullyCastable()) then
            -- print("Hex: don't cast first - prioritize Impale instead");
            return BOT_ACTION_DESIRE_NONE;
        end
        local nCastRange = abilityVoodoo:GetCastRange();
        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange+300, true, BOT_MODE_NONE );

        -- calculate if lion has just launched an impale
        -- wait until the impale can reach the nearest unit
        local npcTargetClosest = tableNearbyEnemyHeroes[1];
        local v = abilityImpale:GetSpecialValueInt("speed");
        local d = GetUnitToUnitDistance(npcBot, npcTargetClosest);
        local timeRequiredForMissleToHit = d / v;

        -- TODO: not really accurate
        -- print("DT: " .. DotaTime() .. " d: " .. d .. " T: " .. timeRequiredForMissleToHit + timeOfLastImpaleCast + 0.6);
        if not (DotaTime() > timeOfLastImpaleCast + timeRequiredForMissleToHit + 0.6) then
            -- if not yet allowed time for the impale to hit, dont cast
            -- print("Hex: wait for impale to land");
            return BOT_ACTION_DESIRE_NONE;
        end

        for _,npcTarget in pairs( tableNearbyEnemyHeroes ) do
            if not (npcTarget:IsStunned()) then
                -- only consider the target if the target is not already stunned
                if ( npcBot:WasRecentlyDamagedByHero( npcTarget, 2.0 ) ) then
                    if (CanCastVoodooOnTarget(npcTarget)) then
                        -- retreat Voodoo
                        -- set target to enemy that recently damaged lion
                        -- print("Hex: cast - reason: recently damaged by this hero");
                        return BOT_ACTION_DESIRE_MODERATE, npcTarget;
                    end
                end
            else
                -- check the following on each nearby enemy
                local safeTime = 0.4
                if (DotaTime() > timeOfLastImpaleCast + abilityImpale:GetSpecialValueFloat("duration") - safeTime) then
                -- if (DotaTime() > timeOfLastImpaleCast + 0.5) then
                    -- if impale's duration is running out
                    -- on a stunned enemy hero nearby
                    -- attempt to chain disable
                    if (CanCastVoodooOnTarget(npcTarget)) then
                        -- print("Hex: cast - reason: chain from impale");
                        return BOT_ACTION_DESIRE_VERYHIGH, npcTarget;
                    end
                end
            end
            -- try to chain
        end
        -- if there are no heroes that recently damaged lion,
        -- or no heroes that can be chain diabled,
        -- cast voodoo on the closest enemy that is not stunned
        for _,npcTarget in pairs( tableNearbyEnemyHeroes ) do
            if not (npcTarget:IsStunned()) then
                -- set target to nearest enemy that is not stunned
                        -- print("Hex: cast - reason: closest enemy to lion and not stunned");
                return BOT_ACTION_DESIRE_MODERATE, npcTarget;
            else
                -- print("Hex: found a stunned enemy #2");
            end
        end
    end

    -- CONTINUE
    -- print("Hex: no reason to cast Hex");
    return BOT_ACTION_DESIRE_NONE;

end

----------------------------------------------------------------------------------------------------

function ManaPriority(npcBot)
    -- checks the amount of mana available on Lion
    -- returns a float from 0 to 1 representing Lion's
    -- need for mana
    local manaCostImpale = abilityImpale:GetManaCost();
    local manaCostVoodoo = abilityImpale:GetManaCost();
    local currentMana = npcBot:GetMana();

    local higherManaCost = manaCostVoodoo;
    local lowerManaCost = manaCostImpale;
    local totalManaCost = manaCostImpale + manaCostVoodoo;
    if (manaCostImpale > higherManaCost) then
        higherManaCost = manaCostImpale
        lowerManaCost = manaCostVoodoo
    end
    -- TODO: add logic for Finger

    if (npcBot:GetMana() / npcBot:GetMaxMana() > 0.8) then
        -- lion has more than 80% mana
        return -1;
    elseif  (currentMana > totalManaCost + 200) then
        -- lion still has a lot of mana
        return -1;
    elseif  (currentMana > totalManaCost) then
        -- lion can cast all spells
        return 0.2;
    elseif  (currentMana > totalManaCost) then
        -- lion can cast all spells
        return 0.2;
    elseif (currentMana > higherManaCost) then
        -- lion can cast either spell
        -- but not enough to cast multipe spells
        return 0.4;
    elseif (currentMana  > lowerManaCost) then
        -- lion can cast ONLY one spell
        return 0.6;
    end
    -- lion doesn't have mana for a disable
    -- highest priorty
    return 1.0;
end

function ManaDrainAmount(npcBot, npcTarget)
    -- predicts the amount of mana drained on a target
    -- TODO: implement this when laning against a mana dependent hero
    -- for example, preventing juggernaut spin:w
    local minimumTraverseRange = GetUnitToUnitDistance(npcBot, npcTarget);
    local targetMS = npcTarget:GetCurrentMovementSpeed();
end

function ManaDrainTime(npcBot, npcTarget)
    -- calculates the worst case scenario of how long a mana drain will last
    -- assuming the target instantly attempts to break maina drain by moving away
    if (npcTarget == nil) then
        return 0;
    end

    local nBreakDistance = abilityManaDrain:GetSpecialValueInt( "break_distance" );
    local minimumTraverseRange = nBreakDistance - GetUnitToUnitDistance(npcBot, npcTarget);
    local targetMS = npcTarget:GetCurrentMovementSpeed();
    local timeReq = minimumTraverseRange / targetMS;

    return timeReq;
end

function ConsiderManaDrain()
    local npcBot = GetBot();
    -- Make sure it's castable
    if (not abilityManaDrain:IsFullyCastable()) then
        -- print("ManaDrain: not fully castable");
        return BOT_ACTION_DESIRE_NONE;
    end

    local nBreakDistance = abilityManaDrain:GetSpecialValueInt( "break_distance" );
    local nCastRange = abilityManaDrain:GetCastRange();
    local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nBreakDistance, true, BOT_MODE_NONE );
    local drainTime = ManaDrainTime(npcBot, tableNearbyEnemyHeroes[1]);
    -- TODO: implement something along with ManaDrainAmount that causes lion to mana drain
    -- a critical amount of mana away from the opponent (such as to prevent a big ult usage)
    if (drainTime > 1) then
        -- if it is possible to drain for more than a second without breaking
        return Clamp(BOT_ACTION_DESIRE_LOW + ManaPriority(npcBot), 0.0, 1.0), tableNearbyEnemyHeroes[1];
        -- elseif (drainTime > 2) then
        --     return BOT_ACTION_DESIRE_MODERATE, tableNearbyEnemyHeroes[1];
        -- elseif (drainTime > 3) then
        --     return BOT_ACTION_DESIRE_HIGH, tableNearbyEnemyHeroes[1];
    end

    return BOT_ACTION_DESIRE_NONE;
end
function ConsiderBlinkInit()

    local npcBot = GetBot();

    -- Make sure it's castable
    if  not abilityPoof:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0;
    end

    -- Get some of its values
    local nCastRange = 1200;
    local nRadius = abilityPoof:GetSpecialValueInt( "radius" );
    local dmg = abilityPoof:GetAbilityDamage() * #tableMeepos * 1.25
    -- Find vulnerable enemy
    local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1300, true, BOT_MODE_NONE );
    for k,v in ipairs(tableNearbyEnemyHeroes) do
        if(v:GetHealth() < dmg) then
            return BOT_ACTION_DESIRE_MODERATE, v:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0;
end

----------------------------------------------------------------------------------------------------

function performBlinkInit( castBlinkInitTarget )
    local npcBot = GetBot();

    if( itemBlink ~= "item_blink" and itemBlink:IsFullyCastable()) then
        npcBot:Action_UseAbilityOnLocation( itemBlink, castBlinkInitTarget);
    end
end

for k,v in pairs( ability_item_usage_lion ) do	_G._savedEnv[k] = v end
