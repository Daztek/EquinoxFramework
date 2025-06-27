/*
    Script: ef_c_log
    Author: Daz
*/

#include "ef_i_dataobject"
#include "ef_i_vm"
#include "ef_i_ringbuffer"

const string LOG_SCRIPT_NAME    = "ef_c_log";
const int LOG_RINGBUFFER_SIZE   = 10;

void LogInfo(string sMessage);
void LogDebug(string sMessage, int bIncludeBacktrace = FALSE);
void LogWarning(string sMessage);
void LogError(string sMessage, int bIncludeBacktrace = TRUE);

void Log_Init()
{
    RingBuffer_Init(GetDataObject(LOG_SCRIPT_NAME), LOG_SCRIPT_NAME, LOG_RINGBUFFER_SIZE);
}

void LogAddToRingBuffer(string sType, string sMessage, struct VMFrame str)
{
    json jLogMessage = JsonObject();
    JsonObjectSetStringInplace(jLogMessage, "file", str.sFile);
    JsonObjectSetStringInplace(jLogMessage, "funtion", str.sFunction);
    JsonObjectSetIntInplace(jLogMessage, "line", str.nLine);
    JsonObjectSetStringInplace(jLogMessage, "type", sType);
    JsonObjectSetStringInplace(jLogMessage, "message", sMessage);
    RingBuffer_PushJson(GetDataObject(LOG_SCRIPT_NAME), LOG_SCRIPT_NAME, jLogMessage);
}

void WriteLog(string sType, string sMessage, int bShowFunctionName = TRUE)
{
    struct VMFrame str = GetVMFrame(2);
    LogAddToRingBuffer(sType, sMessage, str);
    PrintString("(" + str.sFile + (bShowFunctionName ? ":" + str.sFunction : "") + ":" + IntToString(str.nLine) + ") " + (sType != "" && sType != "I" ? sType + ": " : "") + sMessage);
}

void LogInfo(string sMessage)
{
    WriteLog("I", sMessage, FALSE);
}

void LogDebug(string sMessage, int bIncludeBacktrace = FALSE)
{
    if (bIncludeBacktrace)
        sMessage += "\nBACKTRACE:\n" + GetVMBacktrace(1);
    WriteLog("D", sMessage);
}

void LogWarning(string sMessage)
{
    WriteLog("W", sMessage);
}

void LogError(string sMessage, int bIncludeBacktrace = TRUE)
{
    if (bIncludeBacktrace)
        sMessage += "\nBACKTRACE:\n" + GetVMBacktrace(1);
    WriteLog("E", sMessage);
}
