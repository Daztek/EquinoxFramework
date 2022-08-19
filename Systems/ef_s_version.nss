/*
    Script: ef_s_version
    Author: Daz

    Description:
*/

#include "ef_i_core"
#include "ef_s_events"

const string VERSION_LOG_TAG            = "VersionCheck";
const string VERSION_SCRIPT_NAME        = "ef_s_version";

const int VERSION_MAJOR                 = 8193;
const int VERSION_MINOR                 = 34;

// @EVENT[NWNX_ON_CLIENT_CONNECT_BEFORE]
void VersionCheck_OnClientConnect()
{
    int nMajor = Events_GetInt("VERSION_MAJOR");
    int nMinor = Events_GetInt("VERSION_MINOR");
    if (nMajor != VERSION_MAJOR || (nMajor == VERSION_MAJOR && nMinor < VERSION_MINOR))
    {
        WriteLog(VERSION_LOG_TAG, "Player '" + Events_GetString("PLAYER_NAME") + "' (" + Events_GetString("CDKEY") + ") tried to connect with version: " + IntToString(nMajor) + "." + IntToString(nMinor));
        Events_SetEventResult("Your client version must be at least '" + IntToString(VERSION_MAJOR) + "." + IntToString(VERSION_MINOR) + "' to play on this server");
        Events_SkipEvent();
    }
}

