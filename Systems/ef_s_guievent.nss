/*
    Script: ef_s_guievent
    Author: Daz

    // @ GUIEVENT[GUIEVENT_*]
    @ANNOTATION[@(GUIEVENT)\[([\w]+)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

#include "ef_i_core"

const string GUIEVENT_LOG_TAG           = "GuiEvent";
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
        WriteLog(GUIEVENT_LOG_TAG, "DEBUG: Event=" + IntToString(nGuiEventType) + ", Int=" + IntToString(GetLastGuiEventInteger()) + ", Object=" + ObjectToString(GetLastGuiEventObject()));
    }

    sqlquery sql = SqlPrepareQueryModule("SELECT system, scriptchunk FROM " + GUIEVENT_SCRIPT_NAME + " WHERE guieventtype = @guieventtype;");
    SqlBindInt(sql, "@guieventtype", nGuiEventType);

    while (SqlStep(sql))
    {
        string sScriptChunk = SqlGetString(sql, 1);
        string sError = ExecuteScriptChunk(sScriptChunk, oPlayer, FALSE);

        if (sError != "")
            WriteLog(GUIEVENT_LOG_TAG, "ERROR: (" + IntToString(nGuiEventType) + ") System '" + SqlGetString(sql, 0) + "' + ScriptChunk '" + sScriptChunk + "' failed with error: " + sError);
    }
}

// @PAD[GUIEVENT]
void GuiEvent_RegisterFunction(json jGuiEvent)
{
    string sSystem = JsonArrayGetString(jGuiEvent, 0);
    string sGuiEventType = JsonArrayGetString(jGuiEvent, 2);
    int nGuiEventType = GetConstantIntValue(sGuiEventType, "", -1);
    string sFunction = JsonArrayGetString(jGuiEvent, 3);
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));

    if (nGuiEventType == -1)
        WriteLog(GUIEVENT_LOG_TAG, "* WARNING: System '" + sSystem + "' tried to register '" + sFunction + "' for an invalid gui event: " + sGuiEventType);
    else
    {
        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + GUIEVENT_SCRIPT_NAME + " (guieventtype, system, scriptchunk) VALUES(@guieventtype, @system, @scriptchunk);");
        SqlBindInt(sql, "@guieventtype", nGuiEventType);
        SqlBindString(sql, "@system", sSystem);
        SqlBindString(sql, "@scriptchunk", sScriptChunk);
        SqlStep(sql);

        EFCore_CacheScriptChunk(sScriptChunk);

        WriteLog(GUIEVENT_LOG_TAG, "* System '" + sSystem + "' registered '" + sFunction + "' for gui event '" + sGuiEventType + "'");
    }
}
