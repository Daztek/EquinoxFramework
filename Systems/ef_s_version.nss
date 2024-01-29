/*
    Script: ef_s_version
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_eventman"

const string VERSION_SCRIPT_NAME        = "ef_s_version";

const int VERSION_BUILD                 = 8193;
const int VERSION_REVISION              = 36;
const int VERSION_POSTFIX               = 10;

// @NWNX[NWNX_ON_CLIENT_CONNECT_BEFORE]
void VersionCheck_OnClientConnect()
{
    int nBuild = EM_NWNXGetInt("VERSION_MAJOR");
    int nRevision = EM_NWNXGetInt("VERSION_MINOR");
    int nPostfix = EM_NWNXGetInt("VERSION_POSTFIX");
    if (nRevision < VERSION_REVISION || (nRevision == VERSION_REVISION && nPostfix < VERSION_POSTFIX))
    {
        LogInfo("Player '" + EM_NWNXGetString("PLAYER_NAME") + "' (" + EM_NWNXGetString("CDKEY") + ") tried to connect with version: " + IntToString(nBuild) + "." + IntToString(nRevision) + "-" + IntToString(nPostfix));
        EM_NWNXSetEventResult("Your client version must be at least '" + IntToString(VERSION_BUILD) + "." + IntToString(VERSION_REVISION) + "-" + IntToString(VERSION_POSTFIX) + "' to play on this server");
        EM_NWNXSkipEvent();
    }
}
