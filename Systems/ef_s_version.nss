/*
    Script: ef_s_version
    Author: Daz

    Description:
*/

#include "ef_i_core"
#include "ef_s_eventman"

const string VERSION_SCRIPT_NAME        = "ef_s_version";

const int VERSION_MAJOR                 = 8193;
const int VERSION_MINOR                 = 34;

// @NWNX[NWNX_ON_CLIENT_CONNECT_BEFORE]
void VersionCheck_OnClientConnect()
{
    int nMajor = EM_GetNWNXInt("VERSION_MAJOR");
    int nMinor = EM_GetNWNXInt("VERSION_MINOR");
    if (nMajor != VERSION_MAJOR || (nMajor == VERSION_MAJOR && nMinor < VERSION_MINOR))
    {
        WriteLog("Player '" + EM_GetNWNXString("PLAYER_NAME") + "' (" + EM_GetNWNXString("CDKEY") + ") tried to connect with version: " + IntToString(nMajor) + "." + IntToString(nMinor));
        EM_SetNWNXEventResult("Your client version must be at least '" + IntToString(VERSION_MAJOR) + "." + IntToString(VERSION_MINOR) + "' to play on this server");
        EM_SkipNWNXEvent();
    }
}
