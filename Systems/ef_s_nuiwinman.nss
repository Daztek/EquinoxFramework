/*
    Script: ef_s_nuiwinman
    Author: Daz

    // @ NWMWINDOW[WINDOW_ID]
    @ANNOTATION[NWMWINDOW]

    // @ NWMEVENT[WINDOW_ID:NUI_EVENT_*:element]
    @ANNOTATION[NWMEVENT]
*/

#include "ef_i_core"
#include "ef_s_playerdb"

const string NWM_SCRIPT_NAME        = "ef_s_nuiwinman";
const int NWM_DEBUG_EVENTS          = FALSE;

const string NWM_REGISTERED_WINDOW  = "RegisteredWindow_";
const string NWM_WINDOW_GEOMETRY    = "WindowGeometry_";
const string NWM_EVENT_PREFIX       = "EventPrefix_";
const string NWM_CURRENT_TOKEN      = "CurrentToken";
const string NWM_CURRENT_PLAYER     = "CurrentPlayer";

void NWM_SetToken(int nToken);
int NWM_GetToken();
void NWM_SetPlayer(object oPlayer);
object NWM_GetPlayer();
json NWM_GetWindowJson(string sWindowId);
json NWM_GetWindowRootJson(string sWindowId);
json NWM_GetDefaultWindowGeometry(string sWindowId);
json NWM_GetPlayerWindowGeometry(object oPlayer, string sWindowId);
void NWM_SetPlayerWindowGeometry(object oPlayer, string sWindowId, json jGeometry);
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
void NWM_SetBindWatch(string sBind, int bWatch = TRUE);
json NWM_GetUserData(string sKey);
void NWM_SetUserData(string sKey, json jValue);
int NWM_GetUserDataInt(string sKey);
void NWM_SetUserDataInt(string sKey, int nValue);
string NWM_GetUserDataString(string sKey);
void NWM_SetUserDataString(string sKey, string sValue);
void NWM_DeleteUserData(string sKey);
json NWM_GetUserDataFromWindow(string sWindowId, string sKey);
void NWM_CopyUserData(string sSourceWindow, string sKey);
json NWM_GetEvents(string sWindowId, string sEventType, string sElement);
json NWM_GetPrefixArray(string sWindowId);
void NWM_RunEvents(object oPlayer, string sWindowId, string sEventType, string sElement);
void NWM_Destroy();
void NWM_SetRootWindowLayout(string sOtherWindowId);

// @CORE[EF_SYSTEM_INIT]
void NWM_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + NWM_SCRIPT_NAME + "(" +
                    "windowid TEXT NOT NULL, " +
                    "eventtype TEXT NOT NULL, " +
                    "element TEXT NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

// @PAD[NWMWINDOW]
void NWM_RegisterWindow(struct AnnotationData str)
{
    string sWindowId = JsonArrayGetString(str.jTokens, 0);
           sWindowId = GetConstantStringValue(sWindowId, str.sSystem, sWindowId);
    json jWindow = ExecuteScriptChunkAndReturnJson(str.sSystem, nssFunction(str.sFunction), GetModule());

    if (!JsonGetType(jWindow))
        WriteLog("* WARNING: System '" + str.sSystem + "' tried to register window with no data!");
    else if (JsonGetType(NWM_GetWindowJson(sWindowId)))
        WriteLog("* WARNING: System '" + str.sSystem + "' tried to register already registered window: " + sWindowId);
    else
    {
        object oDataObject = GetDataObject(NWM_SCRIPT_NAME);
        json jGeometry = JsonObjectGet(jWindow, NUI_DEFAULT_GEOMETRY_NAME);
        SetLocalJson(oDataObject, NWM_REGISTERED_WINDOW + sWindowId, jWindow);
        SetLocalJson(oDataObject, NWM_WINDOW_GEOMETRY + sWindowId, jGeometry);
        WriteLog("* System '" + str.sSystem + "' registered window: " + sWindowId);
    }
}

// @PAD[NWMEVENT]
void NWM_RegisterEvent(struct AnnotationData str)
{
    string sWindowId = JsonArrayGetString(str.jTokens, 0);
           sWindowId = GetConstantStringValue(sWindowId, str.sSystem, sWindowId);
    string sEventType = JsonArrayGetString(str.jTokens, 1);
           sEventType = GetConstantStringValue(sEventType, str.sSystem, sEventType);
    string sElement = JsonArrayGetString(str.jTokens, 2);
           sElement = GetConstantStringValue(sElement, str.sSystem, sElement);
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction));
    int bPrefix = GetStringRight(sElement, 1) == "_"; // Bit of a hack, assume it's a prefix if the last character of an element is an underscore

    if (JsonGetType(NWM_GetWindowJson(sWindowId)))
    {
        if (bPrefix)
            InsertStringToLocalJsonArray(GetDataObject(NWM_SCRIPT_NAME), NWM_EVENT_PREFIX + sWindowId, sElement);

        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + NWM_SCRIPT_NAME + " (windowid, eventtype, element, scriptchunk) " +
                                             "VALUES(@windowid, @eventtype, @element, @scriptchunk);");
        SqlBindString(sql, "@windowid", sWindowId);
        SqlBindString(sql, "@eventtype", sEventType);
        SqlBindString(sql, "@element", sElement);
        SqlBindString(sql, "@scriptchunk", sScriptChunk);
        SqlStep(sql);

        EFCore_CacheScriptChunk(sScriptChunk);

        WriteLog("* System '" + str.sSystem + "' registered event '" + sEventType + "' for element '" + sElement + "' with function '" + str.sFunction + "' for window: " + sWindowId);
    }
    else
    {
        WriteLog("* WARNING: System '" + str.sSystem + "' tried to register event for a window that does not exist: " + sWindowId);
    }
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_NUI_EVENT]
void NWM_NuiEvent()
{
    object oPlayer = NuiGetEventPlayer();
    int nToken = NuiGetEventWindow();
    string sWindowId = NuiGetWindowId(oPlayer, nToken);

    if (sWindowId == "" || !JsonGetType(NWM_GetWindowJson(sWindowId)))
    {
        if (NWM_DEBUG_EVENTS)
            WriteLog("DEBUG: Unknown or Anonymous Window: (" + sWindowId + ") Event: " + NuiGetEventType() + ", Element: " + NuiGetEventElement());
        return;
    }

    string sEventType = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEventType == NUI_EVENT_WATCH && sElement == NUI_WINDOW_GEOMETRY_BIND)
    {
        json jGeometry = NuiGetBind(oPlayer, nToken, NUI_WINDOW_GEOMETRY_BIND);

        if (NWM_DEBUG_EVENTS)
            WriteLog("DEBUG: (" + IntToString(nToken) + ":" + sWindowId +
                     ") Geometry Update: x=" + FloatToString(JsonObjectGetFloat(jGeometry, "x"), 0, 0) +
                     ", y=" + FloatToString(JsonObjectGetFloat(jGeometry, "y"), 0, 0) +
                     ", w=" + FloatToString(JsonObjectGetFloat(jGeometry, "w"), 0, 0) +
                     ", h=" + FloatToString(JsonObjectGetFloat(jGeometry, "h"), 0, 0));

        if (!GetIsDefaultNuiRect(jGeometry))
        {
            NWM_SetPlayerWindowGeometry(oPlayer, sWindowId, jGeometry);
        }
    }

    if (NWM_DEBUG_EVENTS)
    {
        int nArrayIndex = NuiGetEventArrayIndex();
        json jPayload = NuiGetEventPayload();

        WriteLog("DEBUG: (" + IntToString(nToken) + ":" + sWindowId + ") T: " + sEventType + ", E: " + sElement + ", AI: " + IntToString(nArrayIndex) + ", P: " + JsonDump(jPayload));
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

json NWM_GetWindowRootJson(string sWindowId)
{
    return JsonObjectGet(GetLocalJson(GetDataObject(NWM_SCRIPT_NAME), NWM_REGISTERED_WINDOW + sWindowId), "root");
}

json NWM_GetDefaultWindowGeometry(string sWindowId)
{
    return GetLocalJson(GetDataObject(NWM_SCRIPT_NAME), NWM_WINDOW_GEOMETRY + sWindowId);
}

json NWM_GetPlayerWindowGeometry(object oPlayer, string sWindowId)
{
    return PlayerDB_GetJson(oPlayer, NWM_SCRIPT_NAME, NWM_WINDOW_GEOMETRY + sWindowId);
}

void NWM_SetPlayerWindowGeometry(object oPlayer, string sWindowId, json jGeometry)
{
    PlayerDB_SetJson(oPlayer, NWM_SCRIPT_NAME, NWM_WINDOW_GEOMETRY + sWindowId, jGeometry);
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

    json jDefaultGeometry = NWM_GetDefaultWindowGeometry(sWindowId);
    json jPlayerGeometry = NWM_GetPlayerWindowGeometry(oPlayer, sWindowId);
    if (!JsonGetType(jPlayerGeometry) || !GetNuiRectSizeMatches(jDefaultGeometry, jPlayerGeometry))
    {
        jPlayerGeometry = jDefaultGeometry;
        NWM_SetPlayerWindowGeometry(oPlayer, sWindowId, jPlayerGeometry);
    }

    NuiSetBindWatch(oPlayer, nToken, NUI_WINDOW_GEOMETRY_BIND, TRUE);
    NuiSetBind(oPlayer, nToken, NUI_WINDOW_GEOMETRY_BIND, jPlayerGeometry);

    return nToken;
}

void NWM_CloseWindow(object oPlayer, string sWindowId)
{
    int nToken = NWM_GetToken();
    int nWindowToken = NuiFindWindow(oPlayer, sWindowId);
    if (nWindowToken)
    {
        NWM_SetPlayer(oPlayer);
        NWM_SetToken(nWindowToken);
        NWM_RunEvents(oPlayer, sWindowId, NUI_EVENT_CLOSE, NUI_WINDOW_ROOT_GROUP);
        NuiDestroy(oPlayer, nWindowToken);
    }
    NWM_SetToken(nToken);
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

void NWM_SetBindWatch(string sBind, int bWatch = TRUE)
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

int NWM_GetUserDataInt(string sKey)
{
    return JsonGetInt(NWM_GetUserData(sKey));
}

void NWM_SetUserDataInt(string sKey, int nValue)
{
    NWM_SetUserData(sKey, JsonInt(nValue));
}

string NWM_GetUserDataString(string sKey)
{
    return JsonGetString(NWM_GetUserData(sKey));
}

void NWM_SetUserDataString(string sKey, string sValue)
{
    NWM_SetUserData(sKey, JsonString(sValue));
}

void NWM_DeleteUserData(string sKey)
{
    object oPlayer = NWM_GetPlayer();
    int nToken = NWM_GetToken();
    NuiSetUserData(oPlayer, nToken, JsonObjectDel(NuiGetUserData(oPlayer, nToken), sKey));
}

json NWM_GetUserDataFromWindow(string sWindowId, string sKey)
{
    object oPlayer = NWM_GetPlayer();
    int nToken = NWM_GetToken();
    json jUserData;

     if (NWM_GetIsWindowOpen(oPlayer, sWindowId, TRUE))
        jUserData = NWM_GetUserData(sKey);

    NWM_SetToken(nToken);
    return jUserData;
}

void NWM_CopyUserData(string sSourceWindow, string sKey)
{
    NWM_SetUserData(sKey, NWM_GetUserDataFromWindow(sSourceWindow, sKey));
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

    if (NWM_DEBUG_EVENTS)
        WriteLog("DEBUG: (" + sWindowId + ") Running Event '" + sEventType + "' for Element '" + sElement + "'");

    sqlquery sql = SqlPrepareQueryModule("SELECT scriptchunk FROM " + NWM_SCRIPT_NAME + " WHERE windowid = @windowid AND eventtype = @eventtype AND element = @element;");
    SqlBindString(sql, "@windowid", sWindowId);
    SqlBindString(sql, "@eventtype", sEventType);
    SqlBindString(sql, "@element", sElement);

    while (SqlStep(sql))
    {
        string sScriptChunk = SqlGetString(sql, 0);
        string sError = ExecuteScriptChunk(sScriptChunk, oPlayer, FALSE);

        if (NWM_DEBUG_EVENTS)
        {
            if (sError != "")
                WriteLog("DEBUG: Event Chunk '" + sScriptChunk + "' failed with error: " + sError);
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

void NWM_SetRootWindowLayout(string sOtherWindowId)
{
    NuiSetGroupLayout(NWM_GetPlayer(), NWM_GetToken(), NUI_WINDOW_ROOT_GROUP, NWM_GetWindowRootJson(sOtherWindowId));
}
