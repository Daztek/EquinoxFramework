/*
    Script: ef_s_debuglog
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_poststring"

const string DEBUGLOG_SCRIPT_NAME   = "ef_s_debuglog";
const int DEBUGLOG_ENABLED          = TRUE;
const int DEBUGLOG_NUM_IDS          = LOG_RINGBUFFER_SIZE;
const float DEBUGLOG_DISPLAY_TIME   = 15.0f;

// @CORE[CORE_SYSTEM_LOAD]
void DebugLog_Load()
{
    PostString_ReserveIDs(DEBUGLOG_NUM_IDS);
}

void DebugLog_DisplayLine(object oPlayer, int nLineOffset, int nID, string sText, int nColor)
{
    PostString(oPlayer, sText, 1, nLineOffset, SCREEN_ANCHOR_TOP_LEFT, DEBUGLOG_DISPLAY_TIME, nColor, POSTSTRING_COLOR_TRANSPARENT, nID, POSTSTRING_FONT_TEXT_NAME);
}

// @MESSAGEBUS[LOG_BROADCAST_EVENT]
// @CONSOLE[DisplayLog::]
void DebugLog_Display()
{
    if (!DEBUGLOG_ENABLED)
        return;

    json jLogMessages = LogGetRingBufferAsArray();
    int nStartID = PostString_GetStartID(DEBUGLOG_SCRIPT_NAME);

    object oPlayer = GetFirstPC();
    while (GetIsObjectValid(oPlayer))
    {
        int nID = nStartID;
        PostString_ClearByRange(oPlayer, nID, nID + DEBUGLOG_NUM_IDS);

        int nOffsetY = 4, nColor = POSTSTRING_COLOR_WHITE;
        int nIndex, nLength = JsonGetLength(jLogMessages);
        for (nIndex = 0; nIndex < nLength; nIndex++)
        {
            json jMessage = JsonArrayGet(jLogMessages, nIndex);
            string sText = JsonObjectGetString(jMessage, "time") + " [" + JsonObjectGetString(jMessage, "file") + "] " + JsonObjectGetString(jMessage, "message");
            switch (JsonObjectGetInt(jMessage, "type"))
            {
                case LOG_TYPE_INFO: nColor = POSTSTRING_COLOR_YELLOW; break;
                case LOG_TYPE_WARNING: nColor = POSTSTRING_COLOR_ORANGE; break;
                case LOG_TYPE_ERROR: nColor = POSTSTRING_COLOR_RED; break;
                case LOG_TYPE_DEBUG: nColor = POSTSTRING_COLOR_AQUA; break;
            }
            DebugLog_DisplayLine(oPlayer, nOffsetY++, nID++, sText, nColor);
        }

        oPlayer = GetNextPC();
    }
}
