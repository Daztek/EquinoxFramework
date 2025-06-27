/*
    Script: ef_s_eventman
    Author: Daz

    @EVENT[EVENT_SCRIPT_*:DL:1234]
    @NWNX[SOME_EVENT:DL]
*/

#include "ef_i_include"
#include "ef_c_annotations"
#include "ef_c_log"
#include "nwnx_events"

const string EM_SCRIPT_NAME                     = "ef_s_eventman";
const int EM_LOG_DEBUG                          = FALSE;
const int EM_HOOK_AREA_HEARTBEAT                = FALSE;
const string EM_ORIGINAL_EVENT_SCRIPT_PREFIX    = "EMOriginalEventScript_";

string EM_GetObjectEventScript();
int EM_GetObjectDispatchListId(string sSystem, int nEventType, int nPriority = 0);
void EM_ObjectDispatchListInsert(object oObject, int nObjectDispatchListId);
void EM_ObjectDispatchListRemove(object oObject, int nObjectDispatchListId);
void EM_SetObjectEventScript(object oObject, int nEvent, int bStoreOriginalEvent = TRUE);
void EM_SetModuleEventScripts();
void EM_SetAreaEventScripts(object oArea, int bSetHeartbeat = EM_HOOK_AREA_HEARTBEAT);
void EM_ClearObjectEventScripts(object oObject);

void EM_NWNXSubscribeEvent(string sSystem, string sEvent, string sScriptChunk, int bDispatchListMode = FALSE, int bWrapIntoMain = FALSE);
void EM_NWNXDispatchListInsert(object oObject, string sSystem, string sEvent);
void EM_NWNXDispatchListRemove(object oObject, string sSystem, string sEvent);
void EM_NWNXSignalEvent(string sEvent, object oTarget = OBJECT_SELF);
void EM_NWNXAddIDToWhitelist(string sEvent, int nID);
void EM_NWNXRemoveIDFromWhitelist(string sEvent, int nID);
void EM_NWNXSkipEvent();
void EM_NWNXSetEventResult(string sData);
string EM_NWNXGetString(string sTag);
int EM_NWNXGetInt(string sTag);
float EM_NWNXGetFloat(string sTag);
object EM_NWNXGetObject(string sTag);
vector EM_NWNXGetVector(string sTagX, string sTagY, string sTagZ);
location EM_NWNXGetLocation(string sTagArea, string sTagX, string sTagY, string sTagZ);

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
             "objectid INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    // :(
    VMCompileScript(EM_SCRIPT_NAME, EM_SCRIPT_NAME, nssFunction("EM_SignalObjectEvent"));
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
    string sScript = GetLocalString(oTarget, EM_ORIGINAL_EVENT_SCRIPT_PREFIX + IntToString(nEventType));
    if (sScript != "")
        ExecuteScript(sScript, oTarget);

    string sQuery = "SELECT events.scriptchunk FROM " + EM_SCRIPT_NAME + "_events AS events " +
                    "WHERE events.eventtype = @eventtype AND (events.dispatchlist = 0 OR " +
                    "EXISTS(SELECT dispatchlist.id FROM " + EM_SCRIPT_NAME + "_dispatchlist AS dispatchlist WHERE " +
                    "dispatchlist.id = events.rowid AND dispatchlist.objectid = @objectid)) " +
                    "ORDER BY events.priority;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@eventtype", nEventType);
    SqlBindObjectRef(sql, "@objectid", oTarget);

    while (SqlStep(sql))
    {
        string sScriptChunk = SqlGetString(sql, 0);
        SetScriptParam("EVENT_TYPE", IntToString(nEventType));
        string sError = ExecuteScriptChunk(sScriptChunk, oTarget, FALSE);

        if (EM_LOG_DEBUG && sError != "")
            LogError("Failed to run scriptchunk '" + sScriptChunk + "' with error: " + sError);
    }
}

// @PAD[EVENT]
void EM_InsertObjectEventAnnotations(struct AnnotationData str)
{
    string sEventType = JsonArrayGetString(str.jArguments, 0);
    int nEventType = GetConstantIntValue(sEventType, "", -1);
    string sOptions = JsonArrayGetString(str.jArguments, 1);
    int bDispatchListMode = FindSubString(sOptions, "DL") != -1;
    int bPassEventType = FindSubString(sOptions, "PET") != -1;
    int nPriority = GetConstantIntValue(JsonArrayGetString(str.jArguments, 2), str.sSystem, StringToInt(JsonArrayGetString(str.jArguments, 2)));
    string sEventTypeFunction = bPassEventType ? nssFunction("StringToInt", nssFunction("GetScriptParam", nssEscape("EVENT_TYPE"), FALSE), FALSE) : "";
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction, sEventTypeFunction));

    if (nEventType == -1 || GetStringLeft(sEventType, GetStringLength("EVENT_SCRIPT_")) != "EVENT_SCRIPT_")
        LogWarning("System '" + str.sSystem + "' tried to register '" + str.sFunction + "' for an invalid object event: " + sEventType);
    else
    {
        string sQuery = "INSERT INTO " + EM_SCRIPT_NAME + "_events(system, eventtype, scriptchunk, priority, dispatchlist) " +
                        "VALUES(@system, @eventtype, @scriptchunk, @priority, @dispatchlist);";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindString(sql, "@system", str.sSystem);
        SqlBindInt(sql, "@eventtype", nEventType);
        SqlBindString(sql, "@scriptchunk", sScriptChunk);
        SqlBindInt(sql, "@priority", nPriority);
        SqlBindInt(sql, "@dispatchlist", bDispatchListMode);
        SqlStep(sql);

        CacheScriptChunk(sScriptChunk);

        if (EM_LOG_DEBUG)
        {
            string sError = SqlGetError(sql);
            if (sError != "")
                LogError("Failed to insert event: " + sError);
        }

        LogInfo("System '" + str.sSystem + "' subscribed to '" + sEventType +
                 "' with priority '" + IntToString(nPriority) + "', DL=" +
                 IntToString(bDispatchListMode) + ", PET=" + IntToString(bPassEventType));
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
        SqlBindObjectRef(sql, "@objectid", oObject);
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
        SqlBindObjectRef(sql, "@objectid", oObject);
        SqlStep(sql);
    }
}

void EM_SetObjectEventScript(object oObject, int nEvent, int bStoreOriginalEvent = TRUE)
{
    string sEvent = IntToString(nEvent);
    string sEventScript = EM_GetObjectEventScript();
    string sOriginalScript = GetEventScript(oObject, nEvent);
    int bSet = SetEventScript(oObject, nEvent, sEventScript);

    if (!bSet)
        LogWarning("Failed to set event script for object: " + GetName(oObject) + "(" + sEvent + ")");
    else if (bStoreOriginalEvent && sOriginalScript != "" && sOriginalScript != sEventScript)
        SetLocalString(oObject, EM_ORIGINAL_EVENT_SCRIPT_PREFIX + sEvent, sOriginalScript);
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

void EM_NWNXSetEventScriptChunk(string sSystem, string sEvent, string sScriptChunk)
{
    SetLocalString(GetDataObject(EM_SCRIPT_NAME), sSystem + sEvent, sScriptChunk);
}

string EM_NWNXGetEventScriptChunk(string sSystem, string sEvent)
{
    return GetLocalString(GetDataObject(EM_SCRIPT_NAME), sSystem + sEvent);
}

// @PAD[NWNX]
void EM_NWNXSubscribeAnnotations(struct AnnotationData str)
{
    string sEvent = JsonArrayGetString(str.jArguments, 0);
    int bDispatchListMode = JsonArrayGetString(str.jArguments, 1) == "DL";
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction));

    CacheScriptChunk(sScriptChunk);
    EM_NWNXSetEventScriptChunk(str.sSystem, sEvent, sScriptChunk);
    EM_NWNXSubscribeEvent(str.sSystem, sEvent, sScriptChunk, bDispatchListMode);
}

void EM_NWNXSubscribeEvent(string sSystem, string sEvent, string sScriptChunk, int bDispatchListMode = FALSE, int bWrapIntoMain = FALSE)
{
    LogInfo("System '" + sSystem + "' subscribed to NWNX event '" + sEvent + "', DL=" + IntToString(bDispatchListMode));

    NWNX_Events_SubscribeEventScriptChunk(sEvent, sScriptChunk, bWrapIntoMain);
    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sEvent, sScriptChunk, TRUE);
}

void EM_NWNXDispatchListInsert(object oObject, string sSystem, string sEvent)
{
    string sScriptChunk = EM_NWNXGetEventScriptChunk(sSystem, sEvent);
    if (sScriptChunk != "")
        NWNX_Events_AddObjectToDispatchList(sEvent, sScriptChunk, oObject);
}

void EM_NWNXDispatchListRemove(object oObject, string sSystem, string sEvent)
{
    string sScriptChunk = EM_NWNXGetEventScriptChunk(sSystem, sEvent);
    if (sScriptChunk != "")
        NWNX_Events_RemoveObjectFromDispatchList(sEvent, sScriptChunk, oObject);
}

void EM_NWNXSignalEvent(string sEvent, object oTarget = OBJECT_SELF)
{
    NWNX_Events_SignalEvent(sEvent, oTarget);
}

void EM_NWNXAddIDToWhitelist(string sEvent, int nID)
{
    NWNX_Events_AddIDToWhitelist(sEvent, nID);
}

void EM_NWNXRemoveIDFromWhitelist(string sEvent, int nID)
{
    NWNX_Events_RemoveIDFromWhitelist(sEvent, nID);
}

void EM_NWNXSkipEvent()
{
    NWNX_Events_SkipEvent();
}

void EM_NWNXSetEventResult(string sData)
{
    NWNX_Events_SetEventResult(sData);
}

string EM_NWNXGetString(string sTag)
{
    return NWNX_Events_GetEventData(sTag);
}

int EM_NWNXGetInt(string sTag)
{
    return StringToInt(EM_NWNXGetString(sTag));
}

float EM_NWNXGetFloat(string sTag)
{
    return StringToFloat(EM_NWNXGetString(sTag));
}

object EM_NWNXGetObject(string sTag)
{
    return StringToObject(EM_NWNXGetString(sTag));
}

vector EM_NWNXGetVector(string sTagX, string sTagY, string sTagZ)
{
    return Vector(EM_NWNXGetFloat(sTagX), EM_NWNXGetFloat(sTagY), EM_NWNXGetFloat(sTagZ));
}

location EM_NWNXGetLocation(string sTagArea, string sTagX, string sTagY, string sTagZ)
{
    return Location(EM_NWNXGetObject(sTagArea), EM_NWNXGetVector(sTagX, sTagY, sTagZ), 0.0f);
}
