/*
    Script: ef_s_debuglog
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_poststring"

const string DEBUGLOG_SCRIPT_NAME   = "ef_s_debuglog";
const int DEBUGLOG_GUI_NUM_IDS      = LOG_RINGBUFFER_SIZE;
const float DEBUGLOG_DISPLAY_TIME   = 60.0f;

// @CORE[EF_SYSTEM_LOAD]
void DebugLog_Load()
{
    PostString_ReserveIDs(DEBUGLOG_GUI_NUM_IDS, DEBUGLOG_SCRIPT_NAME);
}

void DebugLog_DisplayLine(object oPlayer, int nLineOffset, int nID, string sText, int nColor)
{
    PostString(oPlayer, sText, 1, nLineOffset, SCREEN_ANCHOR_TOP_LEFT, DEBUGLOG_DISPLAY_TIME, nColor, nColor, nID, POSTSTRING_FONT_TEXT_NAME);
}

// @MESSAGEBUS[LOG_BROADCAST_EVENT]
void DebugLog_Display()
{
    object oPlayer = GetFirstPC();
    if (!GetIsObjectValid(oPlayer))
        return;

    json jLogMessages = LogGetRingBufferAsArray();
    int nID = PostString_GetStartID(DEBUGLOG_SCRIPT_NAME);
    PostString_ClearByRange(oPlayer, nID, nID + DEBUGLOG_GUI_NUM_IDS);

    int nOffsetY = 1;
    int nColor = POSTSTRING_COLOR_WHITE;
    int nIndex, nLength = JsonGetLength(jLogMessages);
    for (nIndex = 0; nIndex < nLength; nIndex++)
    {
        json jMessage = JsonArrayGet(jLogMessages, nIndex);
        string sText = "[" + JsonObjectGetString(jMessage, "file") + "] " + JsonObjectGetString(jMessage, "message");
        switch (JsonObjectGetInt(jMessage, "type"))
        {
            case LOG_TYPE_INFO: nColor = POSTSTRING_COLOR_YELLOW; break;
            case LOG_TYPE_WARNING: nColor = POSTSTRING_COLOR_ORANGE; break;
            case LOG_TYPE_ERROR: nColor = POSTSTRING_COLOR_RED; break;
            case LOG_TYPE_DEBUG: nColor = POSTSTRING_COLOR_AQUA; break;
        }
        DebugLog_DisplayLine(oPlayer, nOffsetY++, nID++, sText, nColor);
    }
}
