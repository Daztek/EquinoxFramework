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

void AIB_EnableWanderFleeBehavior(object oCreature);

// @CORE[EF_SYSTEM_INIT]
void AIB_Init()
{

}

// ***
// WanderFlee behavior

void AIB_EnableWanderFleeBehavior(object oCreature)
{
    AIMan_UnsetBehavior(oCreature);
    AIMan_SetBehavior(oCreature, AIB_BEHAVIOR_WANDERFLEE);
}

// @AIMANEVENT[AIB_BEHAVIOR_WANDERFLEE:EVENT_SCRIPT_CREATURE_ON_SPAWN_IN]
void AIB_WanderFlee_OnSpawn()
{
    PerAOE_Apply(OBJECT_SELF, PERAOE_SIZE_5, AIB_BEHAVIOR_WANDERFLEE, AIB_SCRIPT_NAME, "AIB_WanderFlee_OnEnterAoE");
    
    ActionRandomWalk();
}

void AIB_WanderFlee_OnEnterAoE()
{
    object oPlayer = GetEnteringObject();

    if (!GetIsPC(oPlayer))
        return; 

    object oSelf = GetAreaOfEffectCreator();

    if (!AIMan_GetTimeOut("AIBWanderFleeTimeOut", oSelf))
    {
        AIMan_SetTimeOut("AIBWanderFleeTimeOut", 5.0f, oSelf);

        PlayVoiceChat(VOICE_CHAT_GATTACK1 + Random(3), oSelf);

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
