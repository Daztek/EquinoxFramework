/*
    Script: ef_s_session
    Author: Daz
*/

#include "ef_i_core"

const string SESSION_SCRIPT_NAME                        = "ef_s_session";

const string SESSION_DATA_NAME                          = "SessionData_";
const int SESSION_ONCLIENTEXIT_PRIORITY                 = 1000;

object Session_GetDataObject(object oPlayer);
void Session_SetInt(object oPlayer, string sSystem, string sVarName, int nValue, object oSessionDataObject = OBJECT_INVALID);
int Session_GetInt(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID);
void Session_DeleteInt(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID);
void Session_SetString(object oPlayer, string sSystem, string sVarName, string sValue, object oSessionDataObject = OBJECT_INVALID);
string Session_GetString(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID);
void Session_DeleteString(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID);
void Session_SetFloat(object oPlayer, string sSystem, string sVarName, float fValue, object oSessionDataObject = OBJECT_INVALID);
float Session_GetFloat(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID);
void Session_DeleteFloat(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID);
void Session_SetJson(object oPlayer, string sSystem, string sVarName, json jValue, object oSessionDataObject = OBJECT_INVALID);
json Session_GetJson(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID);
void Session_DeleteJson(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID);

// @EVENT[EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT::SESSION_ONCLIENTEXIT_PRIORITY]
void Session_DestroySessionDataObjectOnClientExit()
{
    DestroyDataObject(SESSION_DATA_NAME + GetObjectUUID(GetExitingObject()));
}

object Session_GetDataObject(object oPlayer)
{
    return GetDataObject(SESSION_DATA_NAME + GetObjectUUID(oPlayer));
}

void Session_SetInt(object oPlayer, string sSystem, string sVarName, int nValue, object oSessionDataObject = OBJECT_INVALID)
{
    SetLocalInt(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName, nValue);
}

int Session_GetInt(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID)
{
    return GetLocalInt(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName);
}

void Session_DeleteInt(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID)
{
    DeleteLocalInt(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName);
}

void Session_SetString(object oPlayer, string sSystem, string sVarName, string sValue, object oSessionDataObject = OBJECT_INVALID)
{
    SetLocalString(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName, sValue);
}

string Session_GetString(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID)
{
    return GetLocalString(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName);
}

void Session_DeleteString(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID)
{
    DeleteLocalString(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName);
}

void Session_SetFloat(object oPlayer, string sSystem, string sVarName, float fValue, object oSessionDataObject = OBJECT_INVALID)
{
    SetLocalFloat(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName, fValue);
}

float Session_GetFloat(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID)
{
    return GetLocalFloat(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName);
}

void Session_DeleteFloat(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID)
{
    DeleteLocalFloat(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName);
}

void Session_SetJson(object oPlayer, string sSystem, string sVarName, json jValue, object oSessionDataObject = OBJECT_INVALID)
{
    SetLocalJson(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName, jValue);
}

json Session_GetJson(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID)
{
    return GetLocalJson(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName);
}

void Session_DeleteJson(object oPlayer, string sSystem, string sVarName, object oSessionDataObject = OBJECT_INVALID)
{
    DeleteLocalJson(oSessionDataObject == OBJECT_INVALID ? Session_GetDataObject(oPlayer) : oSessionDataObject, SESSION_DATA_NAME + sSystem + sVarName);
}
