/*
    Script: ef_i_poststring
    Author: Daz

    Description: An Equinox Framework System that provides various PostString functionality
*/

//void main() {}

#include "ef_i_core"

const string POSTSTRING_LOG_TAG         = "PostString";
const string POSTSTRING_SCRIPT_NAME     = "ef_s_poststring";

const int POSTSTRING_ID_START           = 1000;

const string POSTSTRING_FONT_TEXT_NAME  = "fnt_ef_text";

const int POSTSTRING_COLOR_TRANSPARENT  = 0xFFFFFF00;
const int POSTSTRING_COLOR_WHITE        = 0xFFFFFFFF;
const int POSTSTRING_COLOR_SILVER       = 0xC0C0C0FF;
const int POSTSTRING_COLOR_GRAY         = 0x808080FF;
const int POSTSTRING_COLOR_DARK_GRAY    = 0x303030FF;
const int POSTSTRING_COLOR_BLACK        = 0x000000FF;
const int POSTSTRING_COLOR_RED          = 0xFF0000FF;
const int POSTSTRING_COLOR_MAROON       = 0x800000FF;
const int POSTSTRING_COLOR_ORANGE       = 0xFFA500FF;
const int POSTSTRING_COLOR_YELLOW       = 0xFFFF00FF;
const int POSTSTRING_COLOR_OLIVE        = 0x808000FF;
const int POSTSTRING_COLOR_LIME         = 0x00FF00FF;
const int POSTSTRING_COLOR_GREEN        = 0x008000FF;
const int POSTSTRING_COLOR_AQUA         = 0x00FFFFFF;
const int POSTSTRING_COLOR_TEAL         = 0x008080FF;
const int POSTSTRING_COLOR_BLUE         = 0x0000FFFF;
const int POSTSTRING_COLOR_NAVY         = 0x000080FF;
const int POSTSTRING_COLOR_FUSCHIA      = 0xFF00FFFF;
const int POSTSTRING_COLOR_PURPLE       = 0x800080FF;

// Reserve nAmount of PostString() IDs for sSystem
void PostString_ReserveIDs(string sSystem, int nAmount);
// Return the starting PostString() ID for sSystem
int PostString_GetStartID(string sSystem);
// Return the ending PostString() ID for sSystem
int PostString_GetEndID(string sSystem);
// Return the amount of PostString() IDs that sSystem has requested
int PostString_GetIDAmount(string sSystem);

// Clear a PostString() string with nID for oPlayer
void PostString_ClearByID(object oPlayer, int nID);
// Clear a PostString() string ID range for oPlayer
void PostString_ClearByRange(object oPlayer, int nStartID, int nEndID);
// Clear all PostString() strings of sSystem for oPlayer
void PostString_ClearBySystem(object oPlayer, string sSystem);

// @CORE[EF_SYSTEM_INIT]
void PostString_Init()
{
    object oDataObject = GetDataObject(POSTSTRING_SCRIPT_NAME);
    SetLocalInt(oDataObject, "TotalIDs", POSTSTRING_ID_START);
}

void PostString_ReserveIDs(string sSystem, int nAmount)
{
    object oDataObject = GetDataObject(POSTSTRING_SCRIPT_NAME);

    if (!GetLocalInt(oDataObject, sSystem + "_Amount"))
    {
        int nTotal = GetLocalInt(oDataObject, "TotalIDs");
        int nStart = nTotal;
        int nEnd = nTotal + nAmount - 1;

        SetLocalInt(oDataObject, "TotalIDs", nTotal + nAmount);
        SetLocalInt(oDataObject, sSystem + "_Amount", nAmount);
        SetLocalInt(oDataObject, sSystem + "_StartID", nStart);
        SetLocalInt(oDataObject, sSystem + "_EndID", nEnd);

        WriteLog(POSTSTRING_LOG_TAG, "System '" + sSystem + "' reserved '" + IntToString(nAmount) + "' IDs -> " + IntToString(nStart) + " - " + IntToString(nEnd));
    }
}

int PostString_GetStartID(string sSystem)
{
    return GetLocalInt(GetDataObject(POSTSTRING_SCRIPT_NAME), sSystem + "_StartID");
}

int PostString_GetEndID(string sSystem)
{
    return GetLocalInt(GetDataObject(POSTSTRING_SCRIPT_NAME), sSystem + "_EndID");
}

int PostString_GetIDAmount(string sSystem)
{
    return GetLocalInt(GetDataObject(POSTSTRING_SCRIPT_NAME), sSystem + "_Amount");
}

void PostString_ClearByID(object oPlayer, int nID)
{
    PostString(oPlayer, "", 0, 0, SCREEN_ANCHOR_TOP_LEFT, 0.1f, POSTSTRING_COLOR_TRANSPARENT, POSTSTRING_COLOR_TRANSPARENT, nID);
}

void PostString_ClearByRange(object oPlayer, int nStartID, int nEndID)
{
    int i;
    for(i = nStartID; i < nEndID; i++)
    {
        PostString_ClearByID(oPlayer, i);
    }
}

void PostString_ClearBySystem(object oPlayer, string sSystem)
{
    int nStartID = PostString_GetStartID(sSystem);
    int nEndID = nStartID + PostString_GetIDAmount(sSystem);

    PostString_ClearByRange(oPlayer, nStartID, nEndID);
}

