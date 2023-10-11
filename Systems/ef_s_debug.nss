/*
    Script: ef_s_debug
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_eventman"
#include "ef_s_profiler"

#include "nwnx_nwsqliteext"

const string DEBUG_SCRIPT_NAME          = "ef_s_debug";
const string DEBUG_DEBUG_SCRIPT_NAME    = "ef_debug";

// @NWNX[NWNX_ON_RESOURCE_MODIFIED]
void Debug_OnResourceModified()
{
    string sAlias = EM_NWNXGetString("ALIAS");
    int nType = EM_NWNXGetInt("TYPE");

    if (sAlias == "NWNX" && nType == RESTYPE_NSS)
    {
        string sScriptName = EM_NWNXGetString("RESREF");

        if (sScriptName == DEBUG_DEBUG_SCRIPT_NAME)
        {
            LogInfo("Changes detected, executing debug script");

            string sScriptChunk = ResManGetFileContents(DEBUG_DEBUG_SCRIPT_NAME, RESTYPE_NSS);

            if (sScriptChunk != "")
            {
                string sResult = ExecuteScriptChunk(sScriptChunk, GetModule(), FALSE);

                if (sResult != "")
                    LogError("Failed to execute debug script, error: " + sResult);
            }
        }
    }
}

// @CORE[EF_SYSTEM_LOAD]
void Debug_Load()
{
/*
   NWNX_NWSQLiteExtensions_CreateVirtual2DATable("classes", "01111101000001001111111101110111111111111111111110111111011111110021111");

    sqlquery sql = SqlPrepareQueryObject(GetModule(), "SELECT name FROM classes WHERE label IS NOT NULL AND playerclass = 1 AND hitdie > 8;");
    while (SqlStep(sql))
    {
        PrintString(GetStringByStrRef(SqlGetInt(sql, 0)));
    }
*/
}
