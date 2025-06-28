/*
    Script: ef_i_poststring
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"

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

void PostString_ReserveIDs(int nAmount, string sSystem = "");
int PostString_GetStartID(string sSystem = "");
int PostString_GetEndID(string sSystem = "");
int PostString_GetIDAmount(string sSystem = "");
void PostString_ClearByID(object oPlayer, int nID);
void PostString_ClearByRange(object oPlayer, int nStartID, int nEndID);
void PostString_ClearBySystem(object oPlayer, string sSystem);

// @CORE[CORE_SYSTEM_INIT]
void PostString_Init()
{
    SetLocalInt(GetDataObject(POSTSTRING_SCRIPT_NAME), "TotalIDs", POSTSTRING_ID_START);
}

void PostString_ReserveIDs(int nAmount, string sSystem = "")
{
    object oDataObject = GetDataObject(POSTSTRING_SCRIPT_NAME);

    if (sSystem == "")
        sSystem = GetVMFrameScript(1);

    if (!GetLocalInt(oDataObject, sSystem + "_Amount"))
    {
        int nTotal = GetLocalInt(oDataObject, "TotalIDs");
        int nStart = nTotal;
        int nEnd = nTotal + nAmount - 1;

        SetLocalInt(oDataObject, "TotalIDs", nTotal + nAmount);
        SetLocalInt(oDataObject, sSystem + "_Amount", nAmount);
        SetLocalInt(oDataObject, sSystem + "_StartID", nStart);
        SetLocalInt(oDataObject, sSystem + "_EndID", nEnd);

        LogInfo("System '" + sSystem + "' reserved '" + IntToString(nAmount) + "' IDs -> " + IntToString(nStart) + " - " + IntToString(nEnd));
    }
}

int PostString_GetStartID(string sSystem = "")
{
    if (sSystem == "")
        sSystem = GetVMFrameScript(1);

    return GetLocalInt(GetDataObject(POSTSTRING_SCRIPT_NAME), sSystem + "_StartID");
}

int PostString_GetEndID(string sSystem = "")
{
    if (sSystem == "")
        sSystem = GetVMFrameScript(1);

    return GetLocalInt(GetDataObject(POSTSTRING_SCRIPT_NAME), sSystem + "_EndID");
}

int PostString_GetIDAmount(string sSystem = "")
{
    if (sSystem == "")
        sSystem = GetVMFrameScript(1);

    return GetLocalInt(GetDataObject(POSTSTRING_SCRIPT_NAME), sSystem + "_Amount");
}

void PostString_ClearByID(object oPlayer, int nID)
{
    PostString(oPlayer, "", 0, 0, SCREEN_ANCHOR_TOP_LEFT, 0.1f, POSTSTRING_COLOR_TRANSPARENT, POSTSTRING_COLOR_TRANSPARENT, nID);
}

void PostString_ClearByRange(object oPlayer, int nStartID, int nEndID)
{
    int nID;
    for(nID = nStartID; nID < nEndID; nID++)
    {
        PostString_ClearByID(oPlayer, nID);
    }
}

void PostString_ClearBySystem(object oPlayer, string sSystem)
{
    int nStartID = PostString_GetStartID(sSystem);
    int nEndID = nStartID + PostString_GetIDAmount(sSystem);

    PostString_ClearByRange(oPlayer, nStartID, nEndID);
}
