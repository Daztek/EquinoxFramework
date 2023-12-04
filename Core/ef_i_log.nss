/*
    Script: ef_i_log
    Author: Daz

    Description: Equinox Framework Log Utility Include
*/

#include "ef_i_vm"

// Write an info message to the log
void LogInfo(string sMessage);
// Write a debug message to the log
void LogDebug(string sMessage, int bIncludeBacktrace = FALSE);
// Write a warning message to the log
void LogWarning(string sMessage);
// Write an error message to the log
void LogError(string sMessage, int bIncludeBacktrace = TRUE);

void WriteLog(string sType, string sMessage, int bShowFunctionName = TRUE)
{
    struct VMFrame str = GetVMFrame(2);
    PrintString("(" + str.sFile + (bShowFunctionName ? ":" + str.sFunction : "") + ":" + IntToString(str.nLine) + ") " + (sType != "" ? sType + ": " : "") + sMessage);
}

void LogInfo(string sMessage)
{
    WriteLog("", sMessage, FALSE);
}

void LogDebug(string sMessage, int bIncludeBacktrace = FALSE)
{
    if (bIncludeBacktrace)
        sMessage += "\nBACKTRACE:\n" + GetVMBacktrace(1);
    WriteLog("DEBUG", sMessage);
}

void LogWarning(string sMessage)
{
    WriteLog("WARNING", sMessage);
}

void LogError(string sMessage, int bIncludeBacktrace = TRUE)
{
    if (bIncludeBacktrace)
        sMessage += "\nBACKTRACE:\n" + GetVMBacktrace(1);
    WriteLog("ERROR", sMessage);
}
