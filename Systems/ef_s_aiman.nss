/*
    Script: ef_s_aiman
    Author: Daz

    // @ AIMANEVENT[Behavior:EVENT_SCRIPT_CREATURE_*]
    @ANNOTATION[@(AIMANEVENT)\[([\w]+):(EVENT_SCRIPT_CREATURE_[\w]+)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

#include "ef_i_core"
#include "ef_s_events"
#include "ef_s_profiler"

const string AIMAN_LOG_TAG                      = "AIManager";
const string AIMAN_SCRIPT_NAME                  = "ef_s_aiman";

const string AIMAN_EVENT_NAME_PREFIX            = "AIMANEVENT_";
const string AIMAN_EVENT_ENABLED                = "AIManEventEnabled_";
const string AIMAN_EVENT_FUNCTIONS_PREFIX       = "AIManBehaviorEventFunctions_";
const string AIMAN_BEHAVIOR_NAME                = "AIManBehavior";

string AIMan_GetBehaviorEventName(string sBehavior, int nEventType);
string AIMan_GetBehavior(object oCreature);
void AIMan_SetBehavior(object oCreature, string sBehavior);
void AIMan_UnsetBehavior(object oCreature);

// @CORE[EF_SYSTEM_INIT]
void AIMan_Init()
{
    EFCore_ExecuteFunctionOnAnnotationData(AIMAN_SCRIPT_NAME, "AIMANEVENT", "AIMan_RegisterAIBehaviorEvent({DATA});");
}

string AIMan_GetBehaviorEventName(string sBehavior, int nEventType)
{
    return AIMAN_EVENT_NAME_PREFIX + sBehavior + "_" + IntToString(nEventType);
}

string AIMan_GetBehavior(object oCreature)
{
    return GetLocalString(oCreature, AIMAN_BEHAVIOR_NAME);
}

void AIMan_SetBehavior(object oCreature, string sBehavior)
{
    if (sBehavior == "")
        return;
    
    struct ProfilerData pd = Profiler_Start("AIMan_SetBehavior: " + sBehavior);

    object oDataObject = GetDataObject(AIMAN_SCRIPT_NAME);
    
    SetLocalString(oCreature, AIMAN_BEHAVIOR_NAME, sBehavior);

    int nEventType;
    for (nEventType = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEventType <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEventType++)
    {
        if (GetLocalInt(oDataObject, AIMAN_EVENT_ENABLED + sBehavior + "_" + IntToString(nEventType)) ||
            nEventType == EVENT_SCRIPT_CREATURE_ON_DEATH)
        {
            string sEvent = AIMan_GetBehaviorEventName(sBehavior, nEventType);
            json jFunctions = GetLocalJsonArray(oDataObject, AIMAN_EVENT_FUNCTIONS_PREFIX + sBehavior + "_" + IntToString(nEventType));
            int nFunction, nNumFunctions = JsonGetLength(jFunctions);
            
            Events_SetObjectEventScript(oCreature, nEventType, FALSE);

            for (nFunction = 0; nFunction < nNumFunctions; nFunction++)
            {
                string sScriptChunk = JsonArrayGetString(jFunctions, nFunction);
                if (sScriptChunk != "")
                {
                    NWNX_Events_AddObjectToDispatchList(sEvent, sScriptChunk, oCreature);
                }
            }

            Events_AddObjectToDispatchList(AIMAN_SCRIPT_NAME, Events_GetObjectEventName(nEventType), oCreature);          
        }
        else
        {
            SetEventScript(oCreature, nEventType, "");
        }
    }

    Profiler_Stop(pd);
}

void AIMan_UnsetBehavior(object oCreature)
{
    string sBehavior = AIMan_GetBehavior(oCreature);

    if (sBehavior == "")
        return;

    struct ProfilerData pd = Profiler_Start("AIMan_UnsetBehavior: " + sBehavior);        
        
    object oDataObject = GetDataObject(AIMAN_SCRIPT_NAME);
    
    DeleteLocalString(oCreature, AIMAN_BEHAVIOR_NAME);

    int nEventType;
    for (nEventType = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEventType <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEventType++)
    {
        if (GetLocalInt(oDataObject, AIMAN_EVENT_ENABLED + sBehavior + "_" + IntToString(nEventType)))
        {
            string sEvent = AIMan_GetBehaviorEventName(sBehavior, nEventType);
            json jFunctions = GetLocalJsonArray(oDataObject, AIMAN_EVENT_FUNCTIONS_PREFIX + sBehavior + "_" + IntToString(nEventType));
            int nFunction, nNumFunctions = JsonGetLength(jFunctions);
            
            SetEventScript(oCreature, nEventType, "");

            for (nFunction = 0; nFunction < nNumFunctions; nFunction++)
            {
                string sScriptChunk = JsonArrayGetString(jFunctions, nFunction);
                if (sScriptChunk != "")
                {
                    NWNX_Events_RemoveObjectFromDispatchList(sEvent, sScriptChunk, oCreature);
                }
            }
  
            Events_RemoveObjectFromDispatchList(AIMAN_SCRIPT_NAME, Events_GetObjectEventName(nEventType), oCreature);      
        }
    }

    Profiler_Stop(pd);    
}

void AIMan_RegisterAIBehaviorEvent(json jAIEventData)
{
    string sSystem = JsonArrayGetString(jAIEventData, 0);
    string sBehavior = JsonArrayGetString(jAIEventData, 2);
           sBehavior = GetConstantStringValue(sBehavior, sSystem, sBehavior);
    string sEventType = JsonArrayGetString(jAIEventData, 3);
    string sFunction = JsonArrayGetString(jAIEventData, 4);
    int nEventType = GetConstantIntValue(sEventType, "", -1);

    if (nEventType == -1)
        WriteLog(AIMAN_LOG_TAG, "* WARNING: System '" + sSystem + "' tried to register '" + sFunction + "' for behavior '" + sBehavior + "' with an invalid creature event: " + sEventType);        
    else
    {
        object oDataObject = GetDataObject(AIMAN_SCRIPT_NAME);
        string sEvent = AIMan_GetBehaviorEventName(sBehavior, nEventType);
        string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));

        SetLocalInt(oDataObject, AIMAN_EVENT_ENABLED + sBehavior + "_" + IntToString(nEventType), TRUE);
        InsertStringToLocalJsonArray(oDataObject, AIMAN_EVENT_FUNCTIONS_PREFIX + sBehavior + "_" + IntToString(nEventType), sScriptChunk);     

        NWNX_Events_SubscribeEventScriptChunk(sEvent, sScriptChunk, FALSE);
        NWNX_Events_ToggleDispatchListMode(sEvent, sScriptChunk, TRUE);

        WriteLog(AIMAN_LOG_TAG, "* System '" + sSystem + "' registered '" + sFunction + "' for behavior '" + sBehavior + "' and event '" + sEventType + "'");
    }
}

void AIMan_SignalAIBehaviorEvent(int nEventType)
{
    object oCreature = OBJECT_SELF;
    string sBehavior = AIMan_GetBehavior(oCreature);

    if (sBehavior != "" && GetLocalInt(GetDataObject(AIMAN_SCRIPT_NAME), AIMAN_EVENT_ENABLED + sBehavior + "_" + IntToString(nEventType)))
    {
        Events_SignalEvent(AIMan_GetBehaviorEventName(sBehavior, nEventType), oCreature);      
    }
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_HEARTBEAT]
void AIMan_OnHeartBeat()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_HEARTBEAT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_NOTICE]
void AIMan_OnPerception()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_NOTICE);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT]
void AIMan_OnSpellCastAt()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED]
void AIMan_OnPhysicalAttacked()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DAMAGED]
void AIMan_OnDamaged()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_DAMAGED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DISTURBED]
void AIMan_OnDisturbed()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_DISTURBED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND]
void AIMan_OnCombatRoundEnd()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DIALOGUE]
void AIMan_OnConversation()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_DIALOGUE);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_SPAWN_IN]
void AIMan_OnSpawn()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_SPAWN_IN);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_RESTED]
void AIMan_OnRested()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_RESTED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DEATH]
void AIMan_OnDeath()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_DEATH);

    AIMan_UnsetBehavior(OBJECT_SELF);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT]
void AIMan_OnUserDefined()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR]
void AIMan_OnBlocked()
{
    AIMan_SignalAIBehaviorEvent(EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR);
}
