/*
    Script: ef_s_debug
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_eventman"

const string DEBUG_LOG_TAG              = "Debug";
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
            WriteLog(DEBUG_LOG_TAG, "* Changes detected, executing debug script");

            string sScriptChunk = NWNX_Util_GetNSSContents(DEBUG_DEBUG_SCRIPT_NAME);

            if (sScriptChunk != "")
            {
                string sResult = ExecuteCachedScriptChunk(sScriptChunk, GetModule(), FALSE);

                if (sResult != "")
                    WriteLog(DEBUG_LOG_TAG, "   > Failed to execute debug script, error: " + sResult);
            }
        }
    }   
}
