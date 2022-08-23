/*
    Script: ef_s_eventman
    Author: Daz

    // @ EVENT[DL:EVENT_SCRIPT_*:1234]
    @ANNOTATION[@(EVENT)\[(DL)?:?(EVENT_SCRIPT_[A-Z_]+):?(-?\w+)?\][\n|\r]+[a-z]+\s([\w]+)\(]

    // @ NWNX[DL:SOME_EVENT]
    @ANNOTATION[@(NWNX)\[(DL)?:?([A-Z_]+)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

#include "ef_i_core"
#include "nwnx_events"

const string EM_SCRIPT_NAME                     = "ef_s_eventman";
const string EM_LOG_TAG                         = "EventManager";
const int EM_LOG_DEBUG                          = FALSE;
const int EM_HOOK_AREA_HEARTBEAT                = FALSE;
const string EM_OLD_EVENT_SCRIPT_PREFIX         = "EMOldEventScript_";

string EM_GetObjectEventScript();
int EM_GetObjectDispatchListId(string sSystem, int nEventType, int nPriority = 0);
void EM_ObjectDispatchListInsert(object oObject, int nObjectDispatchListId);
void EM_ObjectDispatchListRemove(object oObject, int nObjectDispatchListId);
void EM_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE);
void EM_SetModuleEventScripts();
void EM_SetAreaEventScripts(object oArea, int bSetHeartbeat = EM_HOOK_AREA_HEARTBEAT);
void EM_ClearObjectEventScripts(object oObject);

void EM_SubscribeNWNXEvent(string sSystem, string sEvent, string sScriptChunk, int bDispatchListMode = FALSE, int bWrapIntoMain = FALSE);
void EM_NWNXDispatchListInsert(object oObject, string sSystem, string sEvent);
void EM_NWNXDispatchListRemove(object oObject, string sSystem, string sEvent);
void EM_SignalNWNXEvent(string sEvent, object oTarget = OBJECT_SELF);
void EM_SkipNWNXEvent();
void EM_SetNWNXEventResult(string sData);
string EM_GetNWNXString(string sTag);
int EM_GetNWNXInt(string sTag);
float EM_GetNWNXFloat(string sTag);
object EM_GetNWNXObject(string sTag);
vector EM_GetNWNXVector(string sTagX, string sTagY, string sTagZ);
location EM_GetNWNXLocation(string sTagArea, string sTagX, string sTagY, string sTagZ);

// @CORE[EF_SYSTEM_INIT]
void EM_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + EM_SCRIPT_NAME + "_events (" +
             "system TEXT NOT NULL, " +
             "eventtype INTEGER NOT NULL, " +
             "scriptchunk TEXT NOT NULL, " +
             "priority INTEGER NOT NULL, " +
             "dispatchlist INTEGER NOT NULL, " +
             "PRIMARY KEY(system, eventtype, priority));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + EM_SCRIPT_NAME + "_dispatchlist (" +
             "id INTEGER NOT NULL, " +
             "objectid TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    // :(
    AddScript(EM_SCRIPT_NAME, EM_SCRIPT_NAME, nssFunction("EM_SignalObjectEvent")); 
}

// @CORE[EF_SYSTEM_LOAD]
void EM_Load()
{
    EM_SetModuleEventScripts();

    object oArea = GetFirstArea();
    while (oArea != OBJECT_INVALID)
    {
        EM_SetAreaEventScripts(oArea);
        oArea = GetNextArea();
    }     
}

// *** Object Events

void EM_SignalObjectEvent(object oTarget = OBJECT_SELF)
{
    int nEventType = GetCurrentlyRunningEvent(FALSE);    
    string sScript = GetLocalString(oTarget, EM_OLD_EVENT_SCRIPT_PREFIX + IntToString(nEventType));
    if (sScript != "")
        ExecuteScript(sScript, oTarget);

    string sQuery = "SELECT " + EM_SCRIPT_NAME + "_events.scriptchunk FROM " + EM_SCRIPT_NAME + "_events " + 
                    "WHERE " + EM_SCRIPT_NAME + "_events.eventtype = @eventtype AND (" + EM_SCRIPT_NAME + "_events.dispatchlist = 0 OR " +
                    "EXISTS(SELECT " + EM_SCRIPT_NAME + "_dispatchlist.id FROM " + EM_SCRIPT_NAME + "_dispatchlist WHERE " + 
                    EM_SCRIPT_NAME + "_dispatchlist.id = " + EM_SCRIPT_NAME + "_events.rowid AND " + EM_SCRIPT_NAME + "_dispatchlist.objectid = @objectid)) " + 
                    "ORDER BY " + EM_SCRIPT_NAME + "_events.priority;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@eventtype", nEventType);
    SqlBindString(sql, "@objectid", ObjectToString(oTarget));

    while (SqlStep(sql))
    {
        string sScriptChunk = SqlGetString(sql, 0);
        string sError = ExecuteCachedScriptChunk(sScriptChunk, oTarget, FALSE);

        if (EM_LOG_DEBUG && sError != "")
            WriteLog(EM_LOG_TAG, "DEBUG: Failed to run scriptchunk '" + sScriptChunk + "' with error: " + sError);
    }
}

// @PAD[EVENT]
void EM_InsertObjectEventAnnotations(json jObjectEvent)
{
    string sSystem = JsonArrayGetString(jObjectEvent, 0);
    int bDispatchListMode = JsonArrayGetString(jObjectEvent, 2) == "DL";
    string sEventType = JsonArrayGetString(jObjectEvent, 3);
    int nEventType = GetConstantIntValue(sEventType, "", -1);
    int nPriority = GetConstantIntValue(JsonArrayGetString(jObjectEvent, 4), sSystem, StringToInt(JsonArrayGetString(jObjectEvent, 4)));
    string sFunction = JsonArrayGetString(jObjectEvent, 5);
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));

    if (nEventType == -1)
        WriteLog(EM_LOG_TAG, "* WARNING: System '" + sSystem + "' tried to register '" + sFunction + "' for an invalid object event: " + sEventType);
    else
    {
        string sQuery = "INSERT INTO " + EM_SCRIPT_NAME + "_events(system, eventtype, scriptchunk, priority, dispatchlist) " + 
                        "VALUES(@system, @eventtype, @scriptchunk, @priority, @dispatchlist);";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindString(sql, "@system", sSystem);
        SqlBindInt(sql, "@eventtype", nEventType);
        SqlBindString(sql, "@scriptchunk", sScriptChunk);
        SqlBindInt(sql, "@priority", nPriority);
        SqlBindInt(sql, "@dispatchlist", bDispatchListMode);
        SqlStep(sql);

        if (EM_LOG_DEBUG)
        {
            string sError = SqlGetError(sql);
            if (sError != "")
                WriteLog(EM_LOG_TAG, "DEBUG: Failed to insert event: " + sError);    
        }

        WriteLog(EM_LOG_TAG, "* System '" + sSystem + "' subscribed to object event '" + IntToString(nEventType) + 
                            "' with priority '" + IntToString(nPriority) + "', DL=" + IntToString(bDispatchListMode));
    }
}

string EM_GetObjectEventScript()
{
    return EM_SCRIPT_NAME;
}

int EM_GetObjectDispatchListId(string sSystem, int nEventType, int nPriority = 0)
{
    string sQuery = "SELECT rowid FROM " + EM_SCRIPT_NAME + "_events WHERE " + 
                    "system = @system AND eventtype = @eventtype AND priority = @priority AND dispatchlist = 1;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindInt(sql, "@eventtype", nEventType);
    SqlBindInt(sql, "@priority", nPriority);

    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void EM_ObjectDispatchListInsert(object oObject, int nObjectDispatchListId)
{
    if(nObjectDispatchListId)
    {
        string sQuery = "INSERT INTO " + EM_SCRIPT_NAME + "_dispatchlist(id, objectid) VALUES(@id, @objectid);";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindInt(sql, "@id", nObjectDispatchListId);          
        SqlBindString(sql, "@objectid", ObjectToString(oObject));
        SqlStep(sql);                      
    }
}

void EM_ObjectDispatchListRemove(object oObject, int nObjectDispatchListId)
{
    if(nObjectDispatchListId)
    {
        string sQuery = "DELETE FROM " + EM_SCRIPT_NAME + "_dispatchlist WHERE id = @id AND objectid = @objectid;";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindInt(sql, "@id", nObjectDispatchListId);          
        SqlBindString(sql, "@objectid", ObjectToString(oObject));
        SqlStep(sql);                      
    }
}

void EM_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE)
{
    string sEvent = IntToString(nEvent);
    string sNewScript = EM_GetObjectEventScript();
    string sOldScript = GetEventScript(oObject, nEvent);
    int bSet = SetEventScript(oObject, nEvent, sNewScript);

    if (!bSet)
        WriteLog(EM_SCRIPT_NAME, "WARNING: EM_SetObjectEventScript failed: " + GetName(oObject) + "(" + sEvent + ")");
    else if (bStoreOldEvent && sOldScript != "" && sOldScript != sNewScript)
        SetLocalString(oObject, EM_OLD_EVENT_SCRIPT_PREFIX + sEvent, sOldScript);
}

void EM_SetModuleEventScripts()
{
    string sQuery = "SELECT DISTINCT eventtype FROM " + EM_SCRIPT_NAME + "_events WHERE eventtype >= @start AND eventtype <= @end;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@start", EVENT_SCRIPT_MODULE_ON_HEARTBEAT);
    SqlBindInt(sql, "@end", EVENT_SCRIPT_MODULE_ON_NUI_EVENT);

    while (SqlStep(sql))
    {
        EM_SetObjectEventScript(GetModule(), SqlGetInt(sql, 0));
    }
}

void EM_SetAreaEventScripts(object oArea, int bSetHeartbeat = EM_HOOK_AREA_HEARTBEAT)
{
    int nEvent;
    for(nEvent = EVENT_SCRIPT_AREA_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_AREA_ON_EXIT; nEvent++)
    {
        if (nEvent == EVENT_SCRIPT_AREA_ON_HEARTBEAT && !bSetHeartbeat)
            continue;
        EM_SetObjectEventScript(oArea, nEvent);
    }
}

void EM_ClearObjectEventScripts(object oObject)
{
    int nStart, nEnd;
    
    switch (GetObjectType(oObject))
    {
        case OBJECT_TYPE_CREATURE: 
            nStart = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT;
            nEnd = EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR;
        break;                             
        case OBJECT_TYPE_TRIGGER: 
            nStart = EVENT_SCRIPT_TRIGGER_ON_HEARTBEAT;
            nEnd = EVENT_SCRIPT_TRIGGER_ON_CLICKED;
        break; 
        case OBJECT_TYPE_DOOR: 
            nStart = EVENT_SCRIPT_DOOR_ON_OPEN;
            nEnd = EVENT_SCRIPT_DOOR_ON_FAIL_TO_OPEN;
        break;
        case OBJECT_TYPE_AREA_OF_EFFECT: 
            nStart = EVENT_SCRIPT_AREAOFEFFECT_ON_HEARTBEAT;
            nEnd = EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_EXIT;
        break;
        case OBJECT_TYPE_PLACEABLE: 
            nStart = EVENT_SCRIPT_PLACEABLE_ON_CLOSED;
            nEnd = EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK;
        break;
        case OBJECT_TYPE_STORE: 
            nStart = EVENT_SCRIPT_STORE_ON_OPEN;
            nEnd = EVENT_SCRIPT_STORE_ON_CLOSE;
        break;
        case OBJECT_TYPE_ENCOUNTER: 
            nStart = EVENT_SCRIPT_ENCOUNTER_ON_OBJECT_ENTER;
            nEnd = EVENT_SCRIPT_ENCOUNTER_ON_USER_DEFINED_EVENT;
        break;
        default:
        {
            if (oObject == GetArea(oObject))
            {
                nStart = EVENT_SCRIPT_AREA_ON_HEARTBEAT;
                nEnd = EVENT_SCRIPT_AREA_ON_EXIT;            
            }            
            else if (oObject == GetModule())
            {
                nStart = EVENT_SCRIPT_MODULE_ON_HEARTBEAT;
                nEnd = EVENT_SCRIPT_MODULE_ON_NUI_EVENT;
            }
            break;
        }                                                                        
    }
    
    if (nStart && nEnd)
    {
        int nEvent;
        for(nEvent = nStart; nEvent <= nEnd; nEvent++)
        {
            SetEventScript(oObject, nEvent, "");
        }
    } 
}

// *** NWNX Events

void EM_SetNWNXEventScriptChunk(string sSystem, string sEvent, string sScriptChunk)
{
    SetLocalString(GetDataObject(EM_SCRIPT_NAME), sSystem + sEvent, sScriptChunk);
}

string EM_GetNWNXEventScriptChunk(string sSystem, string sEvent)
{
    return GetLocalString(GetDataObject(EM_SCRIPT_NAME), sSystem + sEvent);
}

// @PAD[NWNX]
void EM_SubscribeNWNXAnnotations(json jNWNXEvent)
{
    string sSystem = JsonArrayGetString(jNWNXEvent, 0);
    int bDispatchListMode = JsonArrayGetString(jNWNXEvent, 2) == "DL";
    string sEvent = JsonArrayGetString(jNWNXEvent, 3);
    string sFunction = JsonArrayGetString(jNWNXEvent, 4);
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));

    EM_SetNWNXEventScriptChunk(sSystem, sEvent, sScriptChunk);
    EM_SubscribeNWNXEvent(sSystem, sEvent, sScriptChunk, bDispatchListMode);
}

void EM_SubscribeNWNXEvent(string sSystem, string sEvent, string sScriptChunk, int bDispatchListMode = FALSE, int bWrapIntoMain = FALSE)
{
    WriteLog(EM_LOG_TAG, "* System '" + sSystem + "' subscribed to NWNX event '" + sEvent + "', DL=" + IntToString(bDispatchListMode));

    NWNX_Events_SubscribeEventScriptChunk(sEvent, sScriptChunk, bWrapIntoMain);
    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sEvent, sScriptChunk, TRUE);
}

void EM_NWNXDispatchListInsert(object oObject, string sSystem, string sEvent)
{
    string sScriptChunk = EM_GetNWNXEventScriptChunk(sSystem, sEvent);
    if (sScriptChunk != "")
        NWNX_Events_AddObjectToDispatchList(sEvent, sScriptChunk, oObject);
}

void EM_NWNXDispatchListRemove(object oObject, string sSystem, string sEvent)
{
    string sScriptChunk = EM_GetNWNXEventScriptChunk(sSystem, sEvent);
    if (sScriptChunk != "")
        NWNX_Events_RemoveObjectFromDispatchList(sEvent, sScriptChunk, oObject);
}

void EM_SignalNWNXEvent(string sEvent, object oTarget = OBJECT_SELF)
{
    NWNX_Events_SignalEvent(sEvent, oTarget);
}

void EM_SkipNWNXEvent()
{
    NWNX_Events_SkipEvent();
}

void EM_SetNWNXEventResult(string sData)
{
    NWNX_Events_SetEventResult(sData);
}

string EM_GetNWNXString(string sTag)
{
    return NWNX_Events_GetEventData(sTag);
}

int EM_GetNWNXInt(string sTag)
{
    return StringToInt(EM_GetNWNXString(sTag));
}

float EM_GetNWNXFloat(string sTag)
{
    return StringToFloat(EM_GetNWNXString(sTag));
}

object EM_GetNWNXObject(string sTag)
{
    return StringToObject(EM_GetNWNXString(sTag));
}

vector EM_GetNWNXVector(string sTagX, string sTagY, string sTagZ)
{
    return Vector(EM_GetNWNXFloat(sTagX), EM_GetNWNXFloat(sTagY), EM_GetNWNXFloat(sTagZ));
}

location EM_GetNWNXLocation(string sTagArea, string sTagX, string sTagY, string sTagZ)
{
    return Location(EM_GetNWNXObject(sTagArea), EM_GetNWNXVector(sTagX, sTagY, sTagZ), 0.0f);
}
