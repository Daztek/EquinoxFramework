/*
    Script: ef_s_debug
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_eventman"
#include "ef_s_profiler"

const string DEBUG_SCRIPT_NAME          = "ef_s_debug";
const string DEBUG_DEBUG_SCRIPT_NAME    = "ef_debug";

// @NWNX[NWNX_ON_RESOURCE_MODIFIED]
void Debug_OnResourceModified()
{
    string sAlias = EM_GetNWNXString("ALIAS");
    int nType = EM_GetNWNXInt("TYPE");

    if (sAlias == "NWNX" && nType == RESTYPE_NSS)
    {
        string sScriptName = EM_GetNWNXString("RESREF");

        if (sScriptName == DEBUG_DEBUG_SCRIPT_NAME)
        {
            WriteLog("* Changes detected, executing debug script");

            string sScriptChunk = ResManGetFileContents(DEBUG_DEBUG_SCRIPT_NAME, RESTYPE_NSS);

            if (sScriptChunk != "")
            {
                string sResult = ExecuteScriptChunk(sScriptChunk, GetModule(), FALSE);

                if (sResult != "")
                    WriteLog("   > Failed to execute debug script, error: " + sResult);
            }
        }
    }
}
