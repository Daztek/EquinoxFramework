/*
    Script: ef_s_aibehaviors
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_aiman"
#include "ef_s_peraoe"

const string AIB_LOG_TAG                        = "AIBehaviors";
const string AIB_SCRIPT_NAME                    = "ef_s_aibehaviors";

const string AIB_BEHAVIOR_WANDERFLEE            = "AIBWanderFlee";
const string AIB_BEHAVIOR_CHARGEFLEE            = "AIBChargeFlee";

void AIB_EnableWanderFleeBehavior(object oCreature);
void AIB_EnableChargeFleeBehavior(object oCreature);

// ***
// WanderFlee behavior

void AIB_EnableWanderFleeBehavior(object oCreature)
{
    AIMan_SetBehavior(oCreature, AIB_BEHAVIOR_WANDERFLEE);
}

// @AIMANEVENT[AIB_BEHAVIOR_WANDERFLEE:EVENT_SCRIPT_CREATURE_ON_SPAWN_IN]
void AIB_WanderFlee_OnSpawn()
{
    PerAOE_Apply(OBJECT_SELF, 7.5f, AIB_BEHAVIOR_WANDERFLEE, AIB_SCRIPT_NAME, "AIB_WanderFlee_OnEnterAoE");
    AIMan_ApplyCutsceneGhost();
    ActionRandomWalk();
}

void AIB_WanderFlee_OnEnterAoE()
{
    object oPlayer = GetEnteringObject();
    object oSelf = GetAreaOfEffectCreator();

    if (!GetIsPC(oPlayer) && GetObjectSeen(oPlayer, oSelf))
        return;

    if (!AIMan_GetTimeOut("AIBWanderFleeTimeOut", oSelf))
    {
        AIMan_SetTimeOut("AIBWanderFleeTimeOut", 5.0f, oSelf);

        PlayVoiceChat(VOICE_CHAT_GATTACK1, oSelf);

        AssignCommand(oSelf, ClearAllActions());
        AssignCommand(oSelf, ActionMoveAwayFromObject(oPlayer, TRUE, 10.0f + IntToFloat(Random(5))));    
        AssignCommand(oSelf, ActionRandomWalk());
    }
}

// @AIMANEVENT[AIB_BEHAVIOR_WANDERFLEE:EVENT_SCRIPT_CREATURE_ON_DIALOGUE]
void AIB_WanderFlee_OnConversation()
{
    return;
}

// ***
// ChargeFlee behavior

void AIB_EnableChargeFleeBehavior(object oCreature)
{
    AIMan_SetBehavior(oCreature, AIB_BEHAVIOR_CHARGEFLEE);
}

// @AIMANEVENT[AIB_BEHAVIOR_CHARGEFLEE:EVENT_SCRIPT_CREATURE_ON_SPAWN_IN]
void AIB_ChargeFlee_OnSpawn()
{
    PerAOE_Apply(OBJECT_SELF, 12.5f, AIB_BEHAVIOR_CHARGEFLEE, AIB_SCRIPT_NAME, "AIB_ChargeFlee_OnEnterAoE");
    AIMan_ApplyCutsceneGhost();
    ActionRandomWalk();
}

void AIB_ChargeFlee_Knockdown(object oPlayer)
{
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectKnockdown(), oPlayer, 3.0f);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_CHUNK_RED_SMALL), oPlayer);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_CHUNK_BONE_MEDIUM), oPlayer);
}

void AIB_ChargeFlee_OnEnterAoE()
{
    object oPlayer = GetEnteringObject();
    object oSelf = GetAreaOfEffectCreator();

    if (!GetIsPC(oPlayer) && GetObjectSeen(oPlayer, oSelf))
        return;

    if (!AIMan_GetTimeOut("AIBChargeFleeTimeOut", oSelf))
    {
        AIMan_SetTimeOut("AIBChargeFleeTimeOut", 15.0f, oSelf);

        PlayVoiceChat(VOICE_CHAT_GATTACK1, oSelf);

        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectMovementSpeedIncrease(99), oSelf, 10.0f);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HASTE), oSelf);

        AssignCommand(oSelf, ClearAllActions());
        AssignCommand(oSelf, ActionMoveToObject(oPlayer, TRUE, 1.0f));
        AssignCommand(oSelf, ActionDoCommand(AIB_ChargeFlee_Knockdown(oPlayer)));
        AssignCommand(oSelf, ActionMoveAwayFromObject(oPlayer, TRUE, 15.0f + IntToFloat(Random(5))));    
        AssignCommand(oSelf, ActionRandomWalk());
    }
}

// @AIMANEVENT[AIB_BEHAVIOR_CHARGEFLEE:EVENT_SCRIPT_CREATURE_ON_DIALOGUE]
void AIB_ChargeFlee_OnConversation()
{
    return;
}
