local DotaBotUtility = require(GetScriptDirectory().."/utility");
LANE = LANE_MID;

local STATE_IDLE = "STATE_IDLE";
local STATE_LANE_GOTO_SURVEY_POINT = "STATE_LANE_GOTO_SURVEY_POINT";
local STATE_LANE_SEARCHLASTHIT = "STATE_LANE_SEARCHLASTHIT";

local function StateLaneGoToSurveyPoint(StateMachine)
    -- move the bot to the edge of the lane, within their attack range
    local npcBot = GetBot();
    local botRange = npcBot:GetAttackRange();
    local edgeOfLane = GetLaneFrontLocation(2,2,0);

    local distanceToEdgeOfLane = GetUnitToLocationDistance(npcBot, edgeOfLane);
    if (distanceToEdgeOfLane < botRange) then
        -- already kinda near, don't move anymore
        if (distanceToEdgeOfLane < botRange * 0.75) then
            -- too near, move out
            npcBot:Action_MoveToLocation(GetLaneFrontLocation(2,2,-botRange));
        end
        -- StateMachine.State = STATE_LANE_SEARCHLASTHIT;
        TryLastHit();
        -- find creep to last hit
        return;
    end
    npcBot:Action_MoveToLocation(edgeOfLane);
    return;
end

function TryLastHit()
    local npcBot = GetBot();
    local EnemyCreeps = npcBot:GetNearbyCreeps(1000,true);

    local lowest_hp = 100000;
    local weakest_creep = nil;

    for creep_k,creep in pairs(EnemyCreeps)
    do
        --npcBot:GetEstimatedDamageToTarget
        local creep_name = creep:GetUnitName();
        DotaBotUtility:UpdateCreepHealth(creep);
        --print(creep_name);
        if(creep:IsAlive()) then
            local creep_hp = creep:GetHealth();
            if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
            end
        end
    end

    if(weakest_creep ~= nil and weakest_creep:GetHealth() / weakest_creep:GetMaxHealth() < 0.5) then
        -- print(npcBot:GetAttackPoint() .. " | " .. npcBot:GetAttackSpeed());
        -- if(creepHP < atkdmg + creepHealthLossPS * atkpoint/atkspd + distance/prjectilespd)
        --     50        50       10                 0.5 / 1.25

        local safeamount = 15;
        if(lowest_hp < weakest_creep:GetActualDamage(
            npcBot:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL) - safeamount
            + DotaBotUtility:GetCreepHealthDeltaPerSec(weakest_creep)
            * (npcBot:GetAttackPoint() / (1 + npcBot:GetAttackSpeed())
            + GetUnitToUnitDistance(npcBot,weakest_creep) / 1100)) then
            if(npcBot:GetAttackTarget() == nil) then --StateMachine["attcking creep"]
                npcBot:Action_AttackUnit(weakest_creep,false);
                return;
            elseif(weakest_creep ~= StateMachine["attcking creep"]) then
                StateMachine["attcking creep"] = weakest_creep;
                npcBot:Action_AttackUnit(weakest_creep,true);
                return;
            end
        else
            -- simulation of human attack and stop
            if(npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_ATTACK) then
                npcBot:Action_ClearActions(true);
                return;
            else
                npcBot:Action_AttackUnit(weakest_creep,false);
                return;
            end
        end
        weakest_creep = nil;

    end

    return;
end
local function StateLaneSearchLastHit(StateMachine)
    local npcBot = GetBot();
    local EnemyCreeps = npcBot:GetNearbyCreeps(1000,true);
    print(#EnemyCreeps);
    return;
end

local function StateIdle(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        return;
    end

    -- allow bot to finish current channel
    if (npcBot:IsUsingAbility() or npcBot:IsChanneling()) then return end;

    if(DotaTime() < 15) then
        MoveToLaneTower();
    else
        StateMachine.State = STATE_LANE_GOTO_SURVEY_POINT;
        return;
    end
end


StateMachine = {};
StateMachine["State"] = STATE_IDLE; -- set default state
StateMachine[STATE_IDLE] = StateIdle;
StateMachine[STATE_LANE_GOTO_SURVEY_POINT] = StateLaneGoToSurveyPoint;
StateMachine[STATE_LANE_SEARCHLASTHIT] = StateLaneSearchLastHit;
-- StateMachine[STATE_ATTACKING_CREEP] = StateAttackingCreep;
-- StateMachine[STATE_RETREAT] = StateRetreat;
-- StateMachine[STATE_GOTO_COMFORT_POINT] = StateGotoComfortPoint;
-- StateMachine[STATE_FIGHTING] = StateFighting;
-- StateMachine[STATE_RUN_AWAY] = StateRunAway;
-- StateMachine["totalLevelOfAbilities"] = 0;

function OnStart()
    print("starting to do lane stuff");
end

----------------------------------------------------------------------------------------------------

function OnEnd()
    print("ending lane stuff");
end

----------------------------------------------------------------------------------------------------

local prevState = "none";
function Think()

    -- draw lane front for mid lane, both teams
    DebugDrawCircle(GetLaneFrontLocation(1,2,0), 50, 0, 255, 0);
    DebugDrawCircle(GetLaneFrontLocation(2,2,0), 50, 255, 0, 0);

    StateMachine[StateMachine.State](StateMachine);

    if(prevState ~= StateMachine["State"]) then
        print("Storm bot STATE: " .. StateMachine.State);
        prevState = StateMachine.State;
    end

    --[[
    if(DotaTime() < 15) then
        MoveToLaneTower();
        return;
    elseif (DotaTime() < 600) then
        DoLaneThings();
        return;
    end
    ]]--
end

function GetDesire()
    return 1.0;
end

function MoveToLaneTower()
    local npcBot = GetBot();
    local tower = DotaBotUtility:GetFrontTowerAt(LANE);
    npcBot:Action_MoveToLocation(tower:GetLocation());
    return;

--         target = DotaBotUtility:GetNearBySuccessorPointOnLane(LANE);
--         npcBot:Action_AttackMove(target);
--         return;
--     end
end
