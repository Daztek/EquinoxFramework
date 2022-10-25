/*
    Script: ef_s_rest
    Author: Daz

    @REST[REST_EVENTTYPE_REST_*]
*/

#include "ef_i_core"

const string REST_SCRIPT_NAME               = "ef_s_rest";

// @CORE[EF_SYSTEM_INIT]
void Rest_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + REST_SCRIPT_NAME + "(" +
                    "resteventtype INTEGER NOT NULL, " +
                    "system TEXT NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_PLAYER_REST]
void Rest_OnPlayerRest()
{
    object oPlayer = GetLastPCRested();
    int nRestEventType = GetLastRestEventType();

    sqlquery sql = SqlPrepareQueryModule("SELECT system, scriptchunk FROM " + REST_SCRIPT_NAME + " WHERE resteventtype = @resteventtype;");
    SqlBindInt(sql, "@resteventtype", nRestEventType);

    while (SqlStep(sql))
    {
        string sScriptChunk = SqlGetString(sql, 1);
        string sError = ExecuteScriptChunk(sScriptChunk, oPlayer, FALSE);

        if (sError != "")
            WriteLog("ERROR: (" + IntToString(nRestEventType) + ") System '" + SqlGetString(sql, 0) + "' + ScriptChunk '" + sScriptChunk + "' failed with error: " + sError);
    }
}

// @PAD[REST]
void Rest_RegisterFunction(struct AnnotationData str)
{
    string sRestEventTypeConstant = JsonArrayGetString(str.jTokens, 0);
    int nRestEventType = GetConstantIntValue(sRestEventTypeConstant);
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction));

    sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + REST_SCRIPT_NAME + " (resteventtype, system, scriptchunk) VALUES(@resteventtype, @system, @scriptchunk);");
    SqlBindInt(sql, "@resteventtype", nRestEventType);
    SqlBindString(sql, "@system", str.sSystem);
    SqlBindString(sql, "@scriptchunk", sScriptChunk);
    SqlStep(sql);

    EFCore_CacheScriptChunk(sScriptChunk);

    WriteLog("* System '" + str.sSystem + "' registered function '" + str.sFunction + "' for rest event type: " + sRestEventTypeConstant);
}
