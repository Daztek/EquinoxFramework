/*
    Script: ef_s_events
    Author: Daz

    // @ EVENT[DL:EVENT:A]
    @ANNOTATION[@(EVENT)\[(DL)?:?([A-Z_]+):?(A|B)?\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

#include "ef_i_core"
#include "nwnx_events"

//void main() {}

const string EVENTS_SCRIPT_NAME                         = "ef_s_events";
const string EVENTS_LOG_TAG                             = "Events";

const int EVENTS_HOOK_AREA_HEARTBEAT                    = FALSE;

const string EVENTS_OBJECT_EVENT_PREFIX                 = "EF_OBJECT_EVENT_";
const int EVENTS_OBJECT_EVENT_TYPE_DEFAULT              = 1;
const int EVENTS_OBJECT_EVENT_TYPE_BEFORE               = 2;
const int EVENTS_OBJECT_EVENT_TYPE_AFTER                = 4;

string Events_GetObjectEventScript();
void Events_SetSystemEventScriptChunk(string sSystem, string sEvent, string sScriptChunk);
string Events_GetSystemEventScriptChunk(string sSystem, string sEvent);
void Events_SubscribeEventChunk(string sSystem, string sEvent, string sScriptChunk, int bWrapIntoMain = FALSE, int bDispatchListMode = FALSE);
void Events_SubscribeAnnotations(json jEvent);
void Events_SignalEvent(string sEvent, object oTarget = OBJECT_SELF);
void Events_SignalObjectEvent(object oTarget = OBJECT_SELF);
void Events_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE);
void Events_AddObjectToDispatchList(string sSystem, string sEvent, object oObject);
void Events_RemoveObjectFromDispatchList(string sSystem, string sEvent, object oObject);
void Events_SkipEvent();
int Events_GetNumSubscribers(string sEvent);
string Events_GetObjectEventName(int nEvent, int nType = EVENTS_OBJECT_EVENT_TYPE_DEFAULT);
string Events_GetString(string sTag);
int Events_GetInt(string sTag);
float Events_GetFloat(string sTag);
object Events_GetObject(string sTag);
vector Events_GetVector(string sTagX, string sTagY, string sTagZ);
location Events_GetLocation(string sTagArea, string sTagX, string sTagY, string sTagZ);
void Events_EnterTargetingMode(object oPlayer, string sTargetingMode, int nValidObjectTypes = OBJECT_TYPE_ALL, int nMouseCursorId = MOUSECURSOR_MAGIC, int nBadTargetCursor = MOUSECURSOR_NOMAGIC);
string Events_GetCurrentTargetingMode(object oPlayer);
void Events_SetAreaEventScripts(object oArea, int bSetHeartbeat = EVENTS_HOOK_AREA_HEARTBEAT);

// @CORE[EF_SYSTEM_INIT]
void Events_Init()
{
    object oModule = GetModule();

    // :(
    AddScript(EVENTS_SCRIPT_NAME, EVENTS_SCRIPT_NAME, nssFunction("Events_SignalObjectEvent"));

    WriteLog(EVENTS_LOG_TAG, "* Hooking Module Event Scripts");

    int nEvent;
    for(nEvent = EVENT_SCRIPT_MODULE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_MODULE_ON_NUI_EVENT; nEvent++)
    {
        Events_SetObjectEventScript(oModule, nEvent);
    }

    WriteLog(EVENTS_LOG_TAG, "* Hooking Area Event Scripts" + (EVENTS_HOOK_AREA_HEARTBEAT ? "" : ", skipping Heartbeat Event"));
    object oArea = GetFirstArea();
    while (oArea != OBJECT_INVALID)
    {
        Events_SetAreaEventScripts(oArea);
        oArea = GetNextArea();
    }

    EFCore_ExecuteFunctionOnAnnotationData(EVENTS_SCRIPT_NAME, "EVENT", "Events_SubscribeAnnotations({DATA});");
}

string Events_GetObjectEventScript()
{
    return EVENTS_SCRIPT_NAME;
}

void Events_SetSystemEventScriptChunk(string sSystem, string sEvent, string sScriptChunk)
{
    SetLocalString(GetDataObject(EVENTS_SCRIPT_NAME), sSystem + sEvent, sScriptChunk);
}

string Events_GetSystemEventScriptChunk(string sSystem, string sEvent)
{
    return GetLocalString(GetDataObject(EVENTS_SCRIPT_NAME), sSystem + sEvent);
}

void Events_SubscribeEventChunk(string sSystem, string sEvent, string sScriptChunk, int bWrapIntoMain = FALSE, int bDispatchListMode = FALSE)
{
    WriteLog(EVENTS_LOG_TAG, "* System '" + sSystem + "' subscribed to event '" + sEvent + "'");

    NWNX_Events_SubscribeEventScriptChunk(sEvent, sScriptChunk, bWrapIntoMain);
    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sEvent, sScriptChunk, TRUE);
}

void Events_SubscribeAnnotations(json jEvent)
{
    string sSystem = JsonArrayGetString(jEvent, 0);
    int bDispatchListMode = JsonArrayGetString(jEvent, 2) == "DL";
    string sEvent = JsonArrayGetString(jEvent, 3);

    if (GetStringLeft(sEvent, 13) == "EVENT_SCRIPT_")
    {
        string sSuffix = JsonArrayGetString(jEvent, 4);
               sSuffix = sSuffix == "A" ? "_AFTER" : sSuffix == "B" ? "_BEFORE" : "_DEFAULT";
        sEvent = EVENTS_OBJECT_EVENT_PREFIX + IntToString(GetConstantIntValue(sEvent)) + sSuffix;
    }

    string sFunction = JsonArrayGetString(jEvent, 5);
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));

    Events_SetSystemEventScriptChunk(sSystem, sEvent, sScriptChunk);
    Events_SubscribeEventChunk(sSystem, sEvent, sScriptChunk, FALSE, bDispatchListMode);
}

void Events_SignalEvent(string sEvent, object oTarget = OBJECT_SELF)
{
    NWNX_Events_SignalEvent(sEvent, oTarget);
}

void Events_SignalObjectEvent(object oTarget = OBJECT_SELF)
{
    int nEvent = GetCurrentlyRunningEvent(FALSE);
    string sEvent = Events_GetObjectEventName(nEvent, 0);

    if (Events_GetNumSubscribers(sEvent + "_BEFORE"))
        Events_SignalEvent(sEvent + "_BEFORE", oTarget);

    string sScript = GetLocalString(oTarget, EVENTS_SCRIPT_NAME + "_OldEventScript!" + IntToString(nEvent));
    if (sScript != "")
        ExecuteScript(sScript, oTarget);

    if (Events_GetNumSubscribers(sEvent + "_DEFAULT"))
        Events_SignalEvent(sEvent + "_DEFAULT", oTarget);

    if (Events_GetNumSubscribers(sEvent + "_AFTER"))
        Events_SignalEvent(sEvent + "_AFTER", oTarget);
}

void Events_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE)
{
    string sEvent = IntToString(nEvent);
    string sOldScript = GetEventScript(oObject, nEvent);
    string sObjectEventScript = Events_GetObjectEventScript();
    int bSet = SetEventScript(oObject, nEvent, sObjectEventScript);

    if (!bSet)
        WriteLog(EVENTS_LOG_TAG, "WARNING: Events_SetObjectEventScript failed: " + GetName(oObject) + "(" + sEvent + ")");
    else
    if (bStoreOldEvent && sOldScript != "" && sOldScript != sObjectEventScript)
        SetLocalString(oObject, EVENTS_SCRIPT_NAME + "_OldEventScript!" + sEvent, sOldScript);
}

void Events_AddObjectToDispatchList(string sSystem, string sEvent, object oObject)
{
    string sScriptChunk = Events_GetSystemEventScriptChunk(sSystem, sEvent);
    if (sScriptChunk != "")
        NWNX_Events_AddObjectToDispatchList(sEvent, sScriptChunk, oObject);
}

void Events_RemoveObjectFromDispatchList(string sSystem, string sEvent, object oObject)
{
    string sScriptChunk = Events_GetSystemEventScriptChunk(sSystem, sEvent);
    if (sScriptChunk != "")
        NWNX_Events_RemoveObjectFromDispatchList(sEvent, sScriptChunk, oObject);
}

void Events_SkipEvent()
{
    NWNX_Events_SkipEvent();
}

int Events_GetNumSubscribers(string sEvent)
{
    return NWNX_Events_GetNumSubscribers(sEvent);
}

string Events_GetObjectEventName(int nEvent, int nType = EVENTS_OBJECT_EVENT_TYPE_DEFAULT)
{
    string sSuffix;

    if (nType == EVENTS_OBJECT_EVENT_TYPE_DEFAULT)
        sSuffix = "_DEFAULT";
    else if (nType == EVENTS_OBJECT_EVENT_TYPE_BEFORE)
        sSuffix = "_BEFORE";
    else if (nType == EVENTS_OBJECT_EVENT_TYPE_AFTER)
        sSuffix = "_AFTER";

    return EVENTS_OBJECT_EVENT_PREFIX + IntToString(nEvent) + sSuffix;
}

string Events_GetString(string sTag)
{
    return NWNX_Events_GetEventData(sTag);
}

int Events_GetInt(string sTag)
{
    return StringToInt(Events_GetString(sTag));
}

float Events_GetFloat(string sTag)
{
    return StringToFloat(Events_GetString(sTag));
}

object Events_GetObject(string sTag)
{
    return StringToObject(Events_GetString(sTag));
}

vector Events_GetVector(string sTagX, string sTagY, string sTagZ)
{
    return Vector(Events_GetFloat(sTagX), Events_GetFloat(sTagY), Events_GetFloat(sTagZ));
}

location Events_GetLocation(string sTagArea, string sTagX, string sTagY, string sTagZ)
{
    return Location(Events_GetObject(sTagArea), Events_GetVector(sTagX, sTagY, sTagZ), 0.0f);
}

void Events_EnterTargetingMode(object oPlayer, string sTargetingMode, int nValidObjectTypes = OBJECT_TYPE_ALL, int nMouseCursorId = MOUSECURSOR_MAGIC, int nBadTargetCursor = MOUSECURSOR_NOMAGIC)
{
    SetLocalString(oPlayer, "EF_TARGETING_MODE", sTargetingMode);
    EnterTargetingMode(oPlayer, nValidObjectTypes, nMouseCursorId, nBadTargetCursor);
}

string Events_GetCurrentTargetingMode(object oPlayer)
{
    return GetLocalString(oPlayer, "EF_TARGETING_MODE");
}

void Events_SetAreaEventScripts(object oArea, int bSetHeartbeat = EVENTS_HOOK_AREA_HEARTBEAT)
{
    int nEvent;
    for(nEvent = EVENT_SCRIPT_AREA_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_AREA_ON_EXIT; nEvent++)
    {
        if (nEvent == EVENT_SCRIPT_AREA_ON_HEARTBEAT && !bSetHeartbeat)
            continue;
        Events_SetObjectEventScript(oArea, nEvent);
    }
}

