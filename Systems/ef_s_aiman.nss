/*
    Script: ef_s_aiman
    Author: Daz

    @AIMANEVENT[Behavior:EVENT_SCRIPT_CREATURE_*]
*/

#include "ef_i_core"
#include "ef_s_eventman"
#include "ef_s_profiler"

const string AIMAN_SCRIPT_NAME                  = "ef_s_aiman";
const int AIMAN_DEBUG_EVENTS                    = FALSE;

const string AIMAN_BEHAVIOR_NAME                = "AIManBehavior";

string AIMan_GetBehavior(object oCreature);
void AIMan_SetBehavior(object oCreature, string sBehavior);
void AIMan_UnsetBehavior(object oCreature);
int AIMan_GetTimeOut(string sTimeoutFlag, object oCreature = OBJECT_SELF);
void AIMan_SetTimeOut(string sTimeoutFlag, float fSeconds, object oCreature = OBJECT_SELF);
void AIMan_ApplyCutsceneGhost(object oCreature = OBJECT_SELF);
void AIMan_SetIsAmbientNPC(object oCreature = OBJECT_SELF);

// @CORE[EF_SYSTEM_INIT]
void AIMan_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + AIMAN_SCRIPT_NAME + "(" +
                    "behavior TEXT NOT NULL, " +
                    "eventtype INTEGER NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

// @PAD[AIMANEVENT]
void AIMan_RegisterAIBehaviorEvent(struct AnnotationData str)
{
    string sBehavior = JsonArrayGetString(str.jArguments, 0);
           sBehavior = GetConstantStringValue(sBehavior, str.sSystem, sBehavior);
    string sEventType = JsonArrayGetString(str.jArguments, 1);
    int nEventType = GetConstantIntValue(sEventType, "", -1);
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction));

    if (nEventType == -1)
        WriteLog("* WARNING: System '" + str.sSystem + "' tried to register '" + str.sFunction + "' for behavior '" + sBehavior + "' with an invalid creature event: " + sEventType);
    else
    {
        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + AIMAN_SCRIPT_NAME + "(behavior, eventtype, scriptchunk) VALUES(@behavior, @eventtype, @scriptchunk);");
        SqlBindString(sql, "@behavior", sBehavior);
        SqlBindInt(sql, "@eventtype", nEventType);
        SqlBindString(sql, "@scriptchunk", sScriptChunk);
        SqlStep(sql);

        EFCore_CacheScriptChunk(sScriptChunk);

        WriteLog("* System '" + str.sSystem + "' registered '" + str.sFunction + "' for behavior '" + sBehavior + "' and event '" + sEventType + "'");
    }
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

void AIMan_SetIsAmbientNPC(object oCreature = OBJECT_SELF)
{
    SetObjectUiDiscoveryMask(oCreature, OBJECT_UI_DISCOVERY_HILITE_MOUSEOVER | OBJECT_UI_DISCOVERY_TEXTBUBBLE_MOUSEOVER);
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
                string sError = ExecuteScriptChunk(sScriptchunk, oCreature, FALSE);

                if (AIMAN_DEBUG_EVENTS && sError != "")
                {
                    WriteLog("DEBUG: '" + GetName(oCreature) + "' failed event '" + IntToString(nEventType) + "' for behavior '" + sBehavior + "' with error: " + sError);
                }
            }
        }
    }

    //Profiler_Stop(pd);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_HEARTBEAT:DL]
void AIMan_OnHeartBeat()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_HEARTBEAT);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_NOTICE:DL]
void AIMan_OnPerception()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_NOTICE);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT:DL]
void AIMan_OnSpellCastAt()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED:DL]
void AIMan_OnPhysicalAttacked()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_DAMAGED:DL]
void AIMan_OnDamaged()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_DAMAGED);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_DISTURBED:DL]
void AIMan_OnDisturbed()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_DISTURBED);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND:DL]
void AIMan_OnCombatRoundEnd()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_DIALOGUE:DL]
void AIMan_OnConversation()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_DIALOGUE);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_SPAWN_IN:DL]
void AIMan_OnSpawn()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_SPAWN_IN);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_RESTED:DL]
void AIMan_OnRested()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_RESTED);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_DEATH:DL]
void AIMan_OnDeath()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_DEATH);

    AIMan_UnsetBehavior(OBJECT_SELF);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT:DL]
void AIMan_OnUserDefined()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT);
}

// @EVENT[EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR:DL]
void AIMan_OnBlocked()
{
    AIMan_HandleAIEvent(EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR);
}
