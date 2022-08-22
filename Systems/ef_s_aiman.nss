/*
    Script: ef_s_aiman
    Author: Daz

    // @ AIMANEVENT[Behavior:EVENT_SCRIPT_CREATURE_*]
    @ANNOTATION[@(AIMANEVENT)\[([\w]+):(EVENT_SCRIPT_CREATURE_[\w]+)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

#include "ef_i_core"
#include "ef_s_eventman"
#include "ef_s_profiler"

const string AIMAN_LOG_TAG                      = "AIManager";
const string AIMAN_SCRIPT_NAME                  = "ef_s_aiman";
const int AIMAN_DEBUG_EVENTS                    = FALSE;

const string AIMAN_BEHAVIOR_NAME                = "AIManBehavior";

string AIMan_GetBehavior(object oCreature);
void AIMan_SetBehavior(object oCreature, string sBehavior);
void AIMan_UnsetBehavior(object oCreature);
int AIMan_GetTimeOut(string sTimeoutFlag, object oCreature = OBJECT_SELF);
void AIMan_SetTimeOut(string sTimeoutFlag, float fSeconds, object oCreature = OBJECT_SELF);
void AIMan_ApplyCutsceneGhost(object oCreature = OBJECT_SELF);

// @CORE[EF_SYSTEM_INIT]
void AIMan_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + AIMAN_SCRIPT_NAME + "(" +
                    "behavior TEXT NOT NULL, " +
                    "eventtype INTEGER NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    EFCore_ParseAnnotationData(AIMAN_SCRIPT_NAME, "AIMANEVENT", "AIMan_RegisterAIBehaviorEvent");
}

string AIMan_GetBehavior(object oCreature)
{
    return GetLocalString(oCreature, AIMAN_BEHAVIOR_NAME);
}

void AIMan_SetBehavior(object oCreature, string sBehavior)
{
    if (sBehavior == "")
        return;         
    
    //struct ProfilerData pd = Profiler_Start("AIMan_SetBehavior: " + sBehavior);

    AIMan_UnsetBehavior(oCreature); 
    SetLocalString(oCreature, AIMAN_BEHAVIOR_NAME, sBehavior);
    EM_ClearObjectEventScripts(oCreature);

    int nLastEventType = 0, bHandleOnDeath = TRUE;
    sqlquery sql = SqlPrepareQueryModule("SELECT eventtype FROM " + AIMAN_SCRIPT_NAME + " WHERE behavior = @behavior ORDER BY eventtype;");
    SqlBindString(sql, "@behavior", sBehavior);

    while (SqlStep(sql))
    {
        int nEventType = SqlGetInt(sql, 0);
        
        if (nEventType == EVENT_SCRIPT_CREATURE_ON_DEATH)
            bHandleOnDeath = FALSE;   
        
        if (nLastEventType != nEventType)
        {
            nLastEventType = nEventType;
            EM_SetObjectEventScript(oCreature, nEventType, FALSE);            
            EM_ObjectDispatchListInsert(oCreature, EM_GetObjectDispatchListId(AIMAN_SCRIPT_NAME, nEventType));
        } 
    }

    if (bHandleOnDeath)
    {
        EM_SetObjectEventScript(oCreature, EVENT_SCRIPT_CREATURE_ON_DEATH, FALSE);
        EM_ObjectDispatchListInsert(oCreature, EM_GetObjectDispatchListId(AIMAN_SCRIPT_NAME, EVENT_SCRIPT_CREATURE_ON_DEATH));       
    }   

    //Profiler_Stop(pd);
}

void AIMan_UnsetBehavior(object oCreature)
{
    string sBehavior = AIMan_GetBehavior(oCreature);

    if (sBehavior == "")
        return;

    //struct ProfilerData pd = Profiler_Start("AIMan_UnsetBehavior: " + sBehavior);        
        
    DeleteLocalString(oCreature, AIMAN_BEHAVIOR_NAME);

    int nLastEventType = 0, bHandleOnDeath = TRUE;
    sqlquery sql = SqlPrepareQueryModule("SELECT eventtype FROM " + AIMAN_SCRIPT_NAME + " WHERE behavior = @behavior ORDER BY eventtype;");
    SqlBindString(sql, "@behavior", sBehavior);

    while (SqlStep(sql))
    {
        int nEventType = SqlGetInt(sql, 0);

        if (nEventType == EVENT_SCRIPT_CREATURE_ON_DEATH)
            bHandleOnDeath = FALSE;   
        
        if (nLastEventType != nEventType)
        {
            nLastEventType = nEventType;
            SetEventScript(oCreature, nEventType, "");
            EM_ObjectDispatchListRemove(oCreature, EM_GetObjectDispatchListId(AIMAN_SCRIPT_NAME, nEventType));
        } 
    }

    if (bHandleOnDeath)
    {
        SetEventScript(oCreature, EVENT_SCRIPT_CREATURE_ON_DEATH, "");
        EM_ObjectDispatchListRemove(oCreature, EM_GetObjectDispatchListId(AIMAN_SCRIPT_NAME, EVENT_SCRIPT_CREATURE_ON_DEATH));       
    }  

    //Profiler_Stop(pd);    
}

int AIMan_GetTimeOut(string sTimeoutFlag, object oCreature = OBJECT_SELF)
{
    return GetLocalInt(oCreature, sTimeoutFlag);
}

void AIMan_SetTimeOut(string sTimeoutFlag, float fSeconds, object oCreature = OBJECT_SELF)
{
    SetLocalInt(oCreature, sTimeoutFlag, AIMan_GetTimeOut(sTimeoutFlag, oCreature) + 1);
    DelayCommand(fSeconds, SetLocalInt(oCreature, sTimeoutFlag, AIMan_GetTimeOut(sTimeoutFlag, oCreature) - 1));
}

void AIMan_ApplyCutsceneGhost(object oCreature = OBJECT_SELF)
{
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, ExtraordinaryEffect(EffectCutsceneGhost()), oCreature);
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
        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + AIMAN_SCRIPT_NAME + "(behavior, eventtype, scriptchunk) VALUES(@behavior, @eventtype, @scriptchunk);");
        SqlBindString(sql, "@behavior", sBehavior);
        SqlBindInt(sql, "@eventtype", nEventType);
        SqlBindString(sql, "@scriptchunk", nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction)));
        SqlStep(sql);

        WriteLog(AIMAN_LOG_TAG, "* System '" + sSystem + "' registered '" + sFunction + "' for behavior '" + sBehavior + "' and event '" + sEventType + "'");
    }
}

void AIMan_HandleAIEvent(int nEventType)
{
    //struct ProfilerData pd = Profiler_Start("AIMan_HandleAIEvent");

    object oCreature = OBJECT_SELF;
    string sBehavior = AIMan_GetBehavior(oCreature);

    if (sBehavior != "")
    {
        sqlquery sql = SqlPrepareQueryModule("SELECT scriptchunk FROM " + AIMAN_SCRIPT_NAME + " WHERE behavior = @behavior AND eventtype = @eventtype;");
        SqlBindString(sql, "@behavior", sBehavior);
        SqlBindInt(sql, "@eventtype", nEventType);

        while (SqlStep(sql))
        {
            string sScriptchunk = SqlGetString(sql, 0);

            if (sScriptchunk != "")
            {
                string sError = ExecuteCachedScriptChunk(sScriptchunk, oCreature, FALSE);

                if (AIMAN_DEBUG_EVENTS && sError != "")
                {
                    WriteLog(AIMAN_LOG_TAG, "DEBUG: '" + GetName(oCreature) + "' failed event '" + IntToString(nEventType) + "' for behavior '" + sBehavior + "' with error: " + sError);
                }
            }
        }
    }

    //Profiler_Stop(pd);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_HEARTBEAT]
void AIMan_OnHeartBeat()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_HEARTBEAT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_NOTICE]
void AIMan_OnPerception()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_NOTICE);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT]
void AIMan_OnSpellCastAt()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED]
void AIMan_OnPhysicalAttacked()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DAMAGED]
void AIMan_OnDamaged()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_DAMAGED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DISTURBED]
void AIMan_OnDisturbed()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_DISTURBED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND]
void AIMan_OnCombatRoundEnd()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DIALOGUE]
void AIMan_OnConversation()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_DIALOGUE);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_SPAWN_IN]
void AIMan_OnSpawn()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_SPAWN_IN);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_RESTED]
void AIMan_OnRested()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_RESTED);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_DEATH]
void AIMan_OnDeath()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_DEATH);

    AIMan_UnsetBehavior(OBJECT_SELF);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT]
void AIMan_OnUserDefined()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT);
}

// @EVENT[DL:EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR]
void AIMan_OnBlocked()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR);
}
