/*
    Script: ef_c_log
    Author: Daz
*/

#include "ef_i_dataobject"
#include "ef_i_vm"
#include "ef_i_ringbuffer"
#include "ef_c_messagebus"

const string LOG_SCRIPT_NAME        = "ef_c_log";
const int LOG_RINGBUFFER_SIZE       = 10;
const string LOG_BROADCAST_EVENT    = "LOG_BROADCAST_EVENT";

const int LOG_TYPE_INFO             = 1;
const int LOG_TYPE_WARNING          = 2;
const int LOG_TYPE_ERROR            = 3;
const int LOG_TYPE_DEBUG            = 4;

void LogInfo(string sMessage);
void LogDebug(string sMessage, int bIncludeBacktrace = FALSE);
void LogWarning(string sMessage);
void LogError(string sMessage, int bIncludeBacktrace = TRUE);
json LogGetRingBufferAsArray();
string LogTypeToString(int nType);

void Log_Init()
{
    RingBuffer_Init(GetDataObject(LOG_SCRIPT_NAME), LOG_SCRIPT_NAME, LOG_RINGBUFFER_SIZE);
}

void LogAddToRingBuffer(int nType, string sMessage, struct VMFrame str)
{
    json jLogMessage = JsonObject();
    JsonObjectSetStringInplace(jLogMessage, "file", str.sFile);
    JsonObjectSetStringInplace(jLogMessage, "funtion", str.sFunction);
    JsonObjectSetIntInplace(jLogMessage, "line", str.nLine);
    JsonObjectSetIntInplace(jLogMessage, "type", nType);
    JsonObjectSetStringInplace(jLogMessage, "message", sMessage);

    RingBuffer_PushJson(GetDataObject(LOG_SCRIPT_NAME), LOG_SCRIPT_NAME, jLogMessage);

    if (MessageBus_GetNumberOfSubscribers(LOG_BROADCAST_EVENT))
        MessageBus_Broadcast(LOG_BROADCAST_EVENT);
}

void WriteLog(int nType, string sMessage, int bShowFunctionName, int bIncludeBacktrace)
{
    struct VMFrame str = GetVMFrame(2);
    LogAddToRingBuffer(nType, sMessage, str);
    string sType = LogTypeToString(nType);
    if (bIncludeBacktrace)
        sMessage += "\nBACKTRACE:\n" + GetVMBacktrace(2);
    PrintString("(" + str.sFile + (bShowFunctionName ? ":" + str.sFunction : "") + ":" + IntToString(str.nLine) + ") " + (sType != "" && sType != "I" ? sType + ": " : "") + sMessage);
}

void LogInfo(string sMessage)
{
    WriteLog(LOG_TYPE_INFO, sMessage, FALSE, FALSE);
}

void LogDebug(string sMessage, int bIncludeBacktrace = FALSE)
{
    WriteLog(LOG_TYPE_DEBUG, sMessage, TRUE, bIncludeBacktrace);
}

void LogWarning(string sMessage)
{
    WriteLog(LOG_TYPE_WARNING, sMessage, TRUE, FALSE);
}

void LogError(string sMessage, int bIncludeBacktrace = TRUE)
{
    WriteLog(LOG_TYPE_ERROR, sMessage, TRUE, TRUE);
}

json LogGetRingBufferAsArray()
{
    return RingBuffer_ToArray(GetDataObject(LOG_SCRIPT_NAME), LOG_SCRIPT_NAME);
}

string LogTypeToString(int nType)
{
    string sType = "?";
    switch (nType)
    {
        case LOG_TYPE_INFO: sType = ""; break;
        case LOG_TYPE_WARNING: sType = "WARNING"; break;
        case LOG_TYPE_ERROR: sType = "ERROR"; break;
        case LOG_TYPE_DEBUG: sType = "DEBUG"; break;
    }
    return sType;
}
