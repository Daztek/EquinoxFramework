/*
    Script: ef_i_log
    Author: Daz

    Description: Equinox Framework Log Utility Include
*/

#include "ef_i_vm"

// Write an info message to the log
void LogInfo(string sMessage);
// Write a debug message to the log
void LogDebug(string sMessage);
// Write a warmomg message to the log
void LogWarning(string sMessage);
// Write an error message to the log
void LogError(string sMessage, int bIncludeBacktrace = TRUE);

void WriteLog(string sType, string sMessage)
{
    struct VMFrame str = GetVMFrame(2);
    PrintString("(" + str.sFile + ":" + str.sFunction + ":" + IntToString(str.nLine) + ") " + (sType != "" ? sType + ": " : "") + sMessage);
}

void LogInfo(string sMessage)
{
    WriteLog("", sMessage);
}

void LogDebug(string sMessage)
{
    WriteLog("DEBUG", sMessage);
}

void LogWarning(string sMessage)
{
    WriteLog("WARNING", sMessage);
}

void LogError(string sMessage, int bIncludeBacktrace = TRUE)
{
    if (bIncludeBacktrace)
        sMessage += "\nBACKTRACE:\n" + GetVMBacktrace(0);
    WriteLog("ERROR", sMessage);
}
