/*
    Script: ef_c_log
    Author: Daz
*/

#include "ef_i_vm"
#include "ef_c_dazscript"
#include "ef_c_profiler"

const string LOG_SCRIPT_NAME        = "ef_c_log";

const int LOG_TYPE_INFO             = 1;
const int LOG_TYPE_WARNING          = 2;
const int LOG_TYPE_ERROR            = 3;
const int LOG_TYPE_DEBUG            = 4;

const string _FILE_;
const string _FUNCTION_;
const int _LINE_;

void LogInfo(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_);
void LogDebug(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_);
void LogWarning(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_);
void LogError(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_);

string FormatString(string sMessage, string sFile, string sFunction, int nLine)
{
    if (FindSubString(sMessage, "{", 0) != -1)
    {
        object oDataObject = GetDataObject(LOG_SCRIPT_NAME);
        string sKey = sFile + ":" + sFunction + ":" + IntToString(nLine) + ":" + IntToString(NWNX_VM_GetCallsiteHash(2));
        json jStack = GetLocalJson(oDataObject, sKey);
        if (!JsonGetType(jStack))
        {
            jStack = NWNX_VM_GetStackVariables(2);
            SetLocalJson(oDataObject, sKey, jStack);
        }
        return Interpret(sMessage, FALSE, 2, jStack);
    }
    return sMessage;
}

void WriteLog(int nType, string sMessage, int bShowFunctionName, string sFile, string sFunction, int nLine)
{
    string sType;
    switch (nType)
    {
        case LOG_TYPE_INFO: sType = ""; break;
        case LOG_TYPE_WARNING: sType = "WARNING"; break;
        case LOG_TYPE_ERROR: sType = "ERROR"; break;
        case LOG_TYPE_DEBUG: sType = "DEBUG"; break;
        default: sType = "?"; break;
    }

    PrintString("(" + sFile + (bShowFunctionName ? ":" + sFunction : "") + ":" + IntToString(nLine) + ") " + (sType != "" ? sType + ": " : "") + sMessage);
}

void LogInfo(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_)
{
    sMessage = FormatString(sMessage, sFile, sFunction, nLine);
    WriteLog(LOG_TYPE_INFO, sMessage, FALSE, sFile, sFunction, nLine);
}

void LogDebug(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_)
{
    sMessage = FormatString(sMessage, sFile, sFunction, nLine);
    WriteLog(LOG_TYPE_DEBUG, sMessage, TRUE, sFile, sFunction, nLine);
}

void LogWarning(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_)
{
    sMessage = FormatString(sMessage, sFile, sFunction, nLine);
    WriteLog(LOG_TYPE_WARNING, sMessage, TRUE, sFile, sFunction, nLine);
}

void LogError(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_)
{
    sMessage = FormatString(sMessage, sFile, sFunction, nLine);
    WriteLog(LOG_TYPE_ERROR, sMessage, TRUE, sFile, sFunction, nLine);
}
