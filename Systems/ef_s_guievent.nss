/*
    Script: ef_s_guievent
    Author: Daz

    @GUIEVENT[GUIEVENT_*]
*/

#include "ef_i_core"

const string GUIEVENT_SCRIPT_NAME       = "ef_s_guievent";
const int GUIEVENT_DEBUG_EVENTS         = FALSE;

// @CORE[EF_SYSTEM_INIT]
void GuiEvent_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + GUIEVENT_SCRIPT_NAME + "(" +
                    "guieventtype INTEGER NOT NULL, " +
                    "system TEXT NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_PLAYER_GUIEVENT]
void GuiEvent_OnPlayerGuiEvent()
{
    object oPlayer = GetLastGuiEventPlayer();
    int nGuiEventType = GetLastGuiEventType();

    if (GUIEVENT_DEBUG_EVENTS)
    {
        LogDebug("Event=" + IntToString(nGuiEventType) + ", Int=" + IntToString(GetLastGuiEventInteger()) + ", Object=" + ObjectToString(GetLastGuiEventObject()));
    }

    sqlquery sql = SqlPrepareQueryModule("SELECT system, scriptchunk FROM " + GUIEVENT_SCRIPT_NAME + " WHERE guieventtype = @guieventtype;");
    SqlBindInt(sql, "@guieventtype", nGuiEventType);

    while (SqlStep(sql))
    {
        string sScriptChunk = SqlGetString(sql, 1);
        string sError = ExecuteScriptChunk(sScriptChunk, oPlayer, FALSE);

        if (sError != "")
            LogError("(" + IntToString(nGuiEventType) + ") System '" + SqlGetString(sql, 0) + "' + ScriptChunk '" + sScriptChunk + "' failed with error: " + sError);
    }
}

// @PAD[GUIEVENT]
void GuiEvent_RegisterFunction(struct AnnotationData str)
{
    string sGuiEventType = JsonArrayGetString(str.jArguments, 0);
    int nGuiEventType = GetConstantIntValue(sGuiEventType, "", -1);
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction));

    if (nGuiEventType == -1)
        LogWarning("System '" + str.sSystem + "' tried to register '" + str.sFunction + "' for an invalid gui event: " + sGuiEventType);
    else
    {
        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + GUIEVENT_SCRIPT_NAME + " (guieventtype, system, scriptchunk) VALUES(@guieventtype, @system, @scriptchunk);");
        SqlBindInt(sql, "@guieventtype", nGuiEventType);
        SqlBindString(sql, "@system", str.sSystem);
        SqlBindString(sql, "@scriptchunk", sScriptChunk);
        SqlStep(sql);

        EFCore_CacheScriptChunk(sScriptChunk);

        LogInfo("System '" + str.sSystem + "' registered '" + str.sFunction + "' for gui event '" + sGuiEventType + "'");
    }
}
