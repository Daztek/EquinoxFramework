/*
    Script: ef_s_nuiwinman
    Author: Daz

    // @ NWMWINDOW[WINDOW_ID]
    @ANNOTATION[@(NWMWINDOW)\[([\w]+)\][\n|\r]+json+\s([\w]+)\(]

    // @ NWMEVENT[WINDOW_ID:NUI_EVENT_*:element]
    @ANNOTATION[@(NWMEVENT)\[([\w]+):{1}([\w]+):{1}([\w]+)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

#include "ef_i_core"

const string NWM_LOG_TAG            = "NuiWindowManager";
const string NWM_SCRIPT_NAME        = "ef_s_nuiwinman";
const int NWM_DEBUG_EVENTS          = FALSE;

const string NWM_REGISTERED_WINDOW  = "RegisteredWindow_";
const string NWM_WINDOW_GEOMETRY    = "WindowGeometry_";
const string NWM_EVENT_FUNCTION     = "EventFunction_";
const string NWM_EVENT_PREFIX       = "EventPrefix_";
const string NWM_CURRENT_TOKEN      = "CurrentToken";
const string NWM_CURRENT_PLAYER     = "CurrentPlayer";

void NWM_SetToken(int nToken);
int NWM_GetToken();
void NWM_SetPlayer(object oPlayer);
object NWM_GetPlayer();
json NWM_GetWindowJson(string sWindowId);
json NWM_GetWindowGeometry(object oPlayer, string sWindowId);
void NWM_SetWindowGeometry(object oPlayer, string sWindowId, json jGeometry);
void NWM_RegisterWindow(json jNWMWindow);
int NWM_GetIsWindowOpen(object oPlayer, string sWindowId, int bSetPlayerToken = FALSE);
int NWM_OpenWindow(object oPlayer, string sWindowId);
void NWM_CloseWindow(object oPlayer, string sWindowId);
json NWM_GetBind(string sBindName);
void NWM_SetBind(string sBindName, json jValue);
string NWM_GetBindString(string sBindName);
void NWM_SetBindString(string sBindName, string sValue);
int NWM_GetBindBool(string sBindName);
void NWM_SetBindBool(string sBindName, int bValue);
int NWM_GetBindInt(string sBindName);
void NWM_SetBindInt(string sBindName, int nValue);
void NWM_SetBindWatch(string sBind, int bWatch);
json NWM_GetUserData(string sKey);
void NWM_SetUserData(string sKey, json jValue);
void NWM_DeleteUserData(string sKey);
void NWM_RegisterEvent(json jNWMEvent);
json NWM_GetEvents(string sWindowId, string sEventType, string sElement);
json NWM_GetPrefixArray(string sWindowId);
void NWM_RunEvents(object oPlayer, string sWindowId, string sEventType, string sElement);
void NWM_Destroy();

// @CORE[EF_SYSTEM_INIT]
void NWM_Init()
{
    EFCore_ExecuteFunctionOnAnnotationData(NWM_SCRIPT_NAME, "NWMWINDOW", "NWM_RegisterWindow");
    EFCore_ExecuteFunctionOnAnnotationData(NWM_SCRIPT_NAME, "NWMEVENT", "NWM_RegisterEvent");
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_NUI_EVENT]
void NWM_NuiEvent()
{
    object oPlayer = NuiGetEventPlayer();
    int nToken = NuiGetEventWindow();
    string sWindowId = NuiGetWindowId(oPlayer, nToken);

    if (sWindowId == "" || !JsonGetType(NWM_GetWindowJson(sWindowId)))
        return;// Don't bother doing anything if it's not a registered window

    string sEventType = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEventType == NUI_EVENT_WATCH && sElement == NUI_WINDOW_GEOMETRY_BIND)
    {
        NWM_SetWindowGeometry(oPlayer, sWindowId, NuiGetBind(oPlayer, nToken, NUI_WINDOW_GEOMETRY_BIND));
    }

    if (NWM_DEBUG_EVENTS)
    {
        int nArrayIndex = NuiGetEventArrayIndex();
        json jPayload = NuiGetEventPayload();

        WriteLog(NWM_LOG_TAG, "DEBUG: (" + IntToString(nToken) + ":" + sWindowId + ") T: " + sEventType + ", E: " + sElement + ", AI: " + IntToString(nArrayIndex) + ", P: " + JsonDump(jPayload));
    }

    NWM_SetPlayer(oPlayer);
    NWM_SetToken(nToken);
    NWM_RunEvents(oPlayer, sWindowId, sEventType, sElement);
}

// @GUIEVENT[GUIEVENT_OPTIONS_OPEN]
void NWM_CloseAllWindows()
{
    object oPlayer = OBJECT_SELF;
    int nToken;
    while ((nToken = NuiGetNthWindow(oPlayer, 0)))
    {
        NWM_CloseWindow(oPlayer, NuiGetWindowId(oPlayer, nToken));
    }
}

void NWM_SetToken(int nToken)
{
    SetLocalInt(GetDataObject(NWM_SCRIPT_NAME), NWM_CURRENT_TOKEN, nToken);
}

int NWM_GetToken()
{
    return GetLocalInt(GetDataObject(NWM_SCRIPT_NAME), NWM_CURRENT_TOKEN);
}

void NWM_SetPlayer(object oPlayer)
{
    SetLocalObject(GetDataObject(NWM_SCRIPT_NAME), NWM_CURRENT_PLAYER, oPlayer);
}

object NWM_GetPlayer()
{
    return GetLocalObject(GetDataObject(NWM_SCRIPT_NAME), NWM_CURRENT_PLAYER);
}

json NWM_GetWindowJson(string sWindowId)
{
    return GetLocalJson(GetDataObject(NWM_SCRIPT_NAME), NWM_REGISTERED_WINDOW + sWindowId);
}

json NWM_GetWindowGeometry(object oPlayer, string sWindowId)
{
    return GetLocalJsonOrDefault(oPlayer, NWM_WINDOW_GEOMETRY + sWindowId, GetLocalJson(GetDataObject(NWM_SCRIPT_NAME), NWM_WINDOW_GEOMETRY + sWindowId));
}

void NWM_SetWindowGeometry(object oPlayer, string sWindowId, json jGeometry)
{
    SetLocalJson(oPlayer, NWM_WINDOW_GEOMETRY + sWindowId, jGeometry);
}

void NWM_RegisterWindow(json jNWMWindow)
{
    string sSystem = JsonArrayGetString(jNWMWindow, 0);
    string sWindowId = JsonArrayGetString(jNWMWindow, 2);
           sWindowId = GetConstantStringValue(sWindowId, sSystem, sWindowId);
    string sFunction = JsonArrayGetString(jNWMWindow, 3);
    json jWindow = ExecuteScriptChunkAndReturnJson(sSystem, nssFunction(sFunction), GetModule());

    if (!JsonGetType(jWindow))
        WriteLog(NWM_LOG_TAG, "* WARNING: System '" + sSystem + "' tried to register window with no data!");
    else if (JsonGetType(NWM_GetWindowJson(sWindowId)))
        WriteLog(NWM_LOG_TAG, "* WARNING: System '" + sSystem + "' tried to register already registered window: " + sWindowId);
    else
    {
        object oDataObject = GetDataObject(NWM_SCRIPT_NAME);
        json jGeometry = JsonObjectGet(jWindow, NUI_DEFAULT_GEOMETRY_NAME);
        SetLocalJson(oDataObject, NWM_REGISTERED_WINDOW + sWindowId, jWindow);
        SetLocalJson(oDataObject, NWM_WINDOW_GEOMETRY + sWindowId, jGeometry);
        WriteLog(NWM_LOG_TAG, "* System '" + sSystem + "' registered window: " + sWindowId);
    }
}

int NWM_GetIsWindowOpen(object oPlayer, string sWindowId, int bSetPlayerToken = FALSE)
{
    int nToken = NuiFindWindow(oPlayer, sWindowId);

    if (nToken && bSetPlayerToken)
    {
        NWM_SetPlayer(oPlayer);
        NWM_SetToken(nToken);
    }

    return nToken;
}

int NWM_OpenWindow(object oPlayer, string sWindowId)
{
    json jWindow = NWM_GetWindowJson(sWindowId);

    if (!JsonGetType(jWindow))
        return FALSE;

    int nToken = NuiCreate(oPlayer, jWindow, sWindowId);
    NuiSetUserData(oPlayer, nToken, JsonObject());
    NWM_SetPlayer(oPlayer);
    NWM_SetToken(nToken);

    json jGeometry = NWM_GetWindowGeometry(oPlayer, sWindowId);
    if (JsonGetType(jGeometry))
    {
        NuiSetBindWatch(oPlayer, nToken, NUI_WINDOW_GEOMETRY_BIND, TRUE);
        NuiSetBind(oPlayer, nToken, NUI_WINDOW_GEOMETRY_BIND, jGeometry);
    }

    return nToken;
}

void NWM_CloseWindow(object oPlayer, string sWindowId)
{
    int nToken = NuiFindWindow(oPlayer, sWindowId);
    if (nToken)
    {
        NWM_SetPlayer(oPlayer);
        NWM_SetToken(nToken);
        NWM_RunEvents(oPlayer, sWindowId, NUI_EVENT_CLOSE, NUI_WINDOW_ROOT_GROUP);
        NuiDestroy(oPlayer, nToken);
    }
}

json NWM_GetBind(string sBindName)
{
    return NuiGetBind(NWM_GetPlayer(), NWM_GetToken(), sBindName);
}

void NWM_SetBind(string sBindName, json jValue)
{
    NuiSetBind(NWM_GetPlayer(), NWM_GetToken(), sBindName, jValue);
}

string NWM_GetBindString(string sBindName)
{
    return JsonGetString(NWM_GetBind(sBindName));
}

void NWM_SetBindString(string sBindName, string sValue)
{
    NWM_SetBind(sBindName, JsonString(sValue));
}

int NWM_GetBindBool(string sBindName)
{
    return JsonGetInt(NWM_GetBind(sBindName));
}

void NWM_SetBindBool(string sBindName, int bValue)
{
    NWM_SetBind(sBindName, JsonBool(bValue));
}

int NWM_GetBindInt(string sBindName)
{
    return JsonGetInt(NWM_GetBind(sBindName));
}

void NWM_SetBindInt(string sBindName, int nValue)
{
    NWM_SetBind(sBindName, JsonInt(nValue));
}

void NWM_SetBindWatch(string sBind, int bWatch)
{
    NuiSetBindWatch(NWM_GetPlayer(), NWM_GetToken(), sBind, bWatch);
}

json NWM_GetUserData(string sKey)
{
    return JsonObjectGet(NuiGetUserData(NWM_GetPlayer(), NWM_GetToken()), sKey);
}

void NWM_SetUserData(string sKey, json jValue)
{
    object oPlayer = NWM_GetPlayer();
    int nToken = NWM_GetToken();
    NuiSetUserData(oPlayer, nToken, JsonObjectSet(NuiGetUserData(oPlayer, nToken), sKey, jValue));
}

void NWM_DeleteUserData(string sKey)
{
    object oPlayer = NWM_GetPlayer();
    int nToken = NWM_GetToken();
    NuiSetUserData(oPlayer, nToken, JsonObjectDel(NuiGetUserData(oPlayer, nToken), sKey));
}

void NWM_RegisterEvent(json jNWMEvent)
{
    string sSystem = JsonArrayGetString(jNWMEvent, 0);
    string sWindowId = JsonArrayGetString(jNWMEvent, 2);
           sWindowId = GetConstantStringValue(sWindowId, sSystem, sWindowId);
    string sEventType = JsonArrayGetString(jNWMEvent, 3);
           sEventType = GetConstantStringValue(sEventType, sSystem, sEventType);
    string sElement = JsonArrayGetString(jNWMEvent, 4);
           sElement = GetConstantStringValue(sElement, sSystem, sElement);
    string sFunction = JsonArrayGetString(jNWMEvent, 5);
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));
    int bPrefix = GetStringRight(sElement, 1) == "_"; // Bit of a hack, assume it's a prefix if the last character of an element is an underscore

    if (JsonGetType(NWM_GetWindowJson(sWindowId)))
    {
        if (bPrefix)
            InsertStringToLocalJsonArray(GetDataObject(NWM_SCRIPT_NAME), NWM_EVENT_PREFIX + sWindowId, sElement);

        InsertStringToLocalJsonArray(GetDataObject(NWM_SCRIPT_NAME), NWM_EVENT_FUNCTION + sWindowId + sEventType + sElement, sScriptChunk);
        WriteLog(NWM_LOG_TAG, "* System '" + sSystem + "' registered event '" + sEventType + "' for element '" + sElement + "' with function '" + sFunction + "' for window: " + sWindowId);

    }
    else
    {
        WriteLog(NWM_LOG_TAG, "* WARNING: System '" + sSystem + "' tried to register event for a window that does not exist: " + sWindowId);
    }
}

json NWM_GetEvents(string sWindowId, string sEventType, string sElement)
{
    return GetLocalJsonArray(GetDataObject(NWM_SCRIPT_NAME), NWM_EVENT_FUNCTION + sWindowId + sEventType + sElement);
}

json NWM_GetPrefixArray(string sWindowId)
{
    return GetLocalJsonArray(GetDataObject(NWM_SCRIPT_NAME), NWM_EVENT_PREFIX + sWindowId);
}

void NWM_RunEvents(object oPlayer, string sWindowId, string sEventType, string sElement)
{
    json jPrefixes = NWM_GetPrefixArray(sWindowId);
    int nPrefix, nNumPrefixes = JsonGetLength(jPrefixes);
    for (nPrefix = 0; nPrefix < nNumPrefixes; nPrefix++)
    {
        string sPrefix = JsonArrayGetString(jPrefixes, nPrefix);
        if (GetStringLeft(sElement, GetStringLength(sPrefix)) == sPrefix)
        {
            sElement = sPrefix;
            break;
        }
    }

    json jEvents = NWM_GetEvents(sWindowId, sEventType, sElement);
    int nEvent, nNumEvents = JsonGetLength(jEvents);

    if (NWM_DEBUG_EVENTS)
    {
        WriteLog(NWM_LOG_TAG, "DEBUG: [" + sWindowId + "] Running Event '" + sEventType + "' for Element '" + sElement + "' " );
    }

    for (nEvent = 0; nEvent < nNumEvents; nEvent++)
    {
        string sScriptChunk = JsonArrayGetString(jEvents, nEvent);
        if (sScriptChunk != "")
        {
            string sError = ExecuteCachedScriptChunk(sScriptChunk, oPlayer, FALSE);

            if (NWM_DEBUG_EVENTS)
            {
                if (sError != "")
                    WriteLog(NWM_LOG_TAG, "DEBUG: [" + IntToString(nEvent) + "] Event Chunk '" + sScriptChunk + "' failed with error: " + sError);
            }
        }
    }
}

void NWM_Destroy()
{
    object oPlayer = NWM_GetPlayer();
    int nToken = NWM_GetToken();
    string sWindowId = NuiGetWindowId(oPlayer, nToken);

    NWM_RunEvents(oPlayer, sWindowId, NUI_EVENT_CLOSE, NUI_WINDOW_ROOT_GROUP);
    NuiDestroy(oPlayer, nToken);
}

