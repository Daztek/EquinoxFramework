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
const string AIMAN_BEHAVIOR_NAME                = "AIManBehavior";

string AIMan_GetBehavior(object oCreature);
void AIMan_SetBehavior(object oCreature, string sBehavior);
void AIMan_UnsetBehavior(object oCreature);

// @CORE[EF_SYSTEM_INIT]
void AIMan_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + AIMAN_SCRIPT_NAME + "(" +
                    "behavior TEXT NOT NULL, " +
                    "eventtype INTEGER NOT NULL, " +
                    "eventname TEXT NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    EFCore_ExecuteFunctionOnAnnotationData(AIMAN_SCRIPT_NAME, "AIMANEVENT", "AIMan_RegisterAIBehaviorEvent({DATA});");
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

    SetLocalString(oCreature, AIMAN_BEHAVIOR_NAME, sBehavior);
    Events_ClearCreatureEventScripts(oCreature);

    string sQuery = "SELECT eventtype, eventname, scriptchunk FROM " + AIMAN_SCRIPT_NAME + " WHERE behavior = @behavior ORDER BY eventtype;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@behavior", sBehavior);

    int nLastEventType = 0, bHandleOnDeath = TRUE;
    while (SqlStep(sql))
    {
        int nEventType = SqlGetInt(sql, 0);
        string sEvent = SqlGetString(sql, 1);
        string sScriptChunk = SqlGetString(sql, 2);
        
        NWNX_Events_AddObjectToDispatchList(sEvent, sScriptChunk, oCreature);

        if (nEventType == EVENT_SCRIPT_CREATURE_ON_DEATH)
            bHandleOnDeath = FALSE;   
        
        if (nLastEventType != nEventType)
        {
            nLastEventType = nEventType;
            Events_SetObjectEventScript(oCreature, nEventType, FALSE);            
            Events_AddObjectToDispatchList(AIMAN_SCRIPT_NAME, Events_GetObjectEventName(nEventType), oCreature);
        } 
    }

    if (bHandleOnDeath)
    {
        Events_SetObjectEventScript(oCreature, EVENT_SCRIPT_CREATURE_ON_DEATH, FALSE);
        Events_AddObjectToDispatchList(AIMAN_SCRIPT_NAME, Events_GetObjectEventName(EVENT_SCRIPT_CREATURE_ON_DEATH), oCreature);       
    }   

    Profiler_Stop(pd);
}

void AIMan_UnsetBehavior(object oCreature)
{
    string sBehavior = AIMan_GetBehavior(oCreature);

    if (sBehavior == "")
        return;

    struct ProfilerData pd = Profiler_Start("AIMan_UnsetBehavior: " + sBehavior);        
        
    DeleteLocalString(oCreature, AIMAN_BEHAVIOR_NAME);

    string sQuery = "SELECT eventtype, eventname, scriptchunk FROM " + AIMAN_SCRIPT_NAME + " WHERE behavior = @behavior ORDER BY eventtype;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@behavior", sBehavior);

    int nLastEventType = 0, bHandleOnDeath = TRUE;
    while (SqlStep(sql))
    {
        int nEventType = SqlGetInt(sql, 0);
        string sEvent = SqlGetString(sql, 1);
        string sScriptChunk = SqlGetString(sql, 2);

        NWNX_Events_RemoveObjectFromDispatchList(sEvent, sScriptChunk, oCreature);

        if (nEventType == EVENT_SCRIPT_CREATURE_ON_DEATH)
            bHandleOnDeath = FALSE;   
        
        if (nLastEventType != nEventType)
        {
            nLastEventType = nEventType;
            SetEventScript(oCreature, nEventType, "");
            NWNX_Events_RemoveObjectFromDispatchList(AIMAN_SCRIPT_NAME, Events_GetObjectEventName(nEventType), oCreature);
        } 
    }

    if (bHandleOnDeath)
    {
        SetEventScript(oCreature, EVENT_SCRIPT_CREATURE_ON_DEATH, "");
        NWNX_Events_RemoveObjectFromDispatchList(AIMAN_SCRIPT_NAME, Events_GetObjectEventName(EVENT_SCRIPT_CREATURE_ON_DEATH), oCreature);       
    }  

    Profiler_Stop(pd);    
}

string AIMan_GetBehaviorEventName(string sBehavior, int nEventType)
{
   return AIMAN_EVENT_NAME_PREFIX + sBehavior + "_" + IntToString(nEventType);
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

        string sQuery = "INSERT INTO " + AIMAN_SCRIPT_NAME + "(behavior, eventtype, eventname, scriptchunk) VALUES(@behavior, @eventtype, @eventname, @scriptchunk);";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindString(sql, "@behavior", sBehavior);
        SqlBindInt(sql, "@eventtype", nEventType);
        SqlBindString(sql, "@eventname", sEvent);
        SqlBindString(sql, "@scriptchunk", sScriptChunk);
        SqlStep(sql);

        NWNX_Events_SubscribeEventScriptChunk(sEvent, sScriptChunk, FALSE);
        NWNX_Events_ToggleDispatchListMode(sEvent, sScriptChunk, TRUE);

        WriteLog(AIMAN_LOG_TAG, "* System '" + sSystem + "' registered '" + sFunction + "' for behavior '" + sBehavior + "' and event '" + sEventType + "'");
    }
}

int AIMan_GetBehaviorHasEvent(string sBehavior, int nEventType)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT * FROM " + AIMAN_SCRIPT_NAME + " WHERE behavior = @behavior AND eventtype = @eventtype;");
    SqlBindString(sql, "@behavior", sBehavior);
    SqlBindInt(sql, "@eventtype", nEventType);

    return SqlStep(sql);
}

void AIMan_SignalAIEvent(int nEventType)
{
    object oCreature = OBJECT_SELF;
    string sBehavior = AIMan_GetBehavior(oCreature);

    if (sBehavior != "" && AIMan_GetBehaviorHasEvent(sBehavior, nEventType))
    {
        Events_SignalEvent(AIMan_GetBehaviorEventName(sBehavior, nEventType), oCreature);      
    }
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_HEARTBEAT]
void AIMan_OnHeartBeat()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_HEARTBEAT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_NOTICE]
void AIMan_OnPerception()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_NOTICE);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT]
void AIMan_OnSpellCastAt()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED]
void AIMan_OnPhysicalAttacked()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DAMAGED]
void AIMan_OnDamaged()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_DAMAGED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DISTURBED]
void AIMan_OnDisturbed()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_DISTURBED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND]
void AIMan_OnCombatRoundEnd()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DIALOGUE]
void AIMan_OnConversation()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_DIALOGUE);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_SPAWN_IN]
void AIMan_OnSpawn()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_SPAWN_IN);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_RESTED]
void AIMan_OnRested()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_RESTED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DEATH]
void AIMan_OnDeath()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_DEATH);

    AIMan_UnsetBehavior(OBJECT_SELF);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT]
void AIMan_OnUserDefined()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR]
void AIMan_OnBlocked()
{
    AIMan_SignalAIEvent(EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR);
}
