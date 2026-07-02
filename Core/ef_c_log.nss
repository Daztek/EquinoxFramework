/*
    Script: ef_c_log
    Author: Daz
*/

#include "ef_c_dazscript"

const string LOG_SCRIPT_NAME        = "ef_c_log";

void LogInfo(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_);
void LogDebug(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_);
void LogWarning(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_);
void LogError(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_);

string FormatString(string sMessage, string sFile, string sFunction, int nLine)
{
    if (FindSubString(sMessage, "{", 0) != -1)
    {
        object oDataObject = GetDataObject(LOG_SCRIPT_NAME);
        int nHash = NWNX_VM_GetScriptCallStackHash(2);
        string sKey = sFile + ":" + sFunction + ":" + IntToString(nLine) + ":" + IntToString(nHash);
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

void WriteLog(string sMessage, int bShowFunctionName, string sFile, string sFunction, int nLine, int nType = _FUNCTIONHASH_)
{
    string sType;
    switch (nType)
    {
        case "LogInfo": sType = ""; break;
        case "LogWarning": sType = "WARNING"; break;
        case "LogError": sType = "ERROR"; break;
        case "LogDebug": sType = "DEBUG"; break;
        default: sType = "UNKNOWN"; break;
    }

    PrintString("(" + sFile + (bShowFunctionName ? ":" + sFunction : "") + ":" + IntToString(nLine) + ") " + (sType != "" ? sType + ": " : "") + sMessage);
}

void LogInfo(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_)
{
    sMessage = FormatString(sMessage, sFile, sFunction, nLine);
    WriteLog(sMessage, FALSE, sFile, sFunction, nLine);
}

void LogDebug(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_)
{
    sMessage = FormatString(sMessage, sFile, sFunction, nLine);
    WriteLog(sMessage, TRUE, sFile, sFunction, nLine);
}

void LogWarning(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_)
{
    sMessage = FormatString(sMessage, sFile, sFunction, nLine);
    WriteLog(sMessage, TRUE, sFile, sFunction, nLine);
}

void LogError(string sMessage, string sFile = _FILE_, string sFunction = _FUNCTION_, int nLine = _LINE_)
{
    sMessage = FormatString(sMessage, sFile, sFunction, nLine);
    WriteLog(sMessage, TRUE, sFile, sFunction, nLine);
}
