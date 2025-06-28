/*
    Script: ef_c_messagebus
    Author: Daz

    @MESSAGEBUS[EVENTNAME]
*/

#include "ef_c_annotations"
#include "ef_i_dataobject"
#include "ef_i_sqlite"
#include "ef_i_util"

const string MESSAGEBUG_SCRIPT_NAME = "ef_c_messagebus";

void MessageBus_Broadcast(string sEvent);
int MessageBus_GetNumberOfSubscribers(string sEvent);

void MessageBus_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + MESSAGEBUG_SCRIPT_NAME + "(" +
                    "event TEXT NOT NULL, " +
                    "system TEXT NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

void MessageBus_Broadcast(string sEvent)
{
    object oModule = GetModule();
    sqlquery sql = SqlPrepareQueryModule("SELECT system, scriptchunk FROM " + MESSAGEBUG_SCRIPT_NAME + " WHERE event = @event;");
    SqlBindString(sql, "@event", sEvent);

    while (SqlStep(sql))
    {
        string sScriptChunk = SqlGetString(sql, 1);
        ExecuteScriptChunk(sScriptChunk, oModule, FALSE);
    }
}

int MessageBus_GetNumberOfSubscribers(string sEvent)
{
    return GetLocalInt(GetDataObject(MESSAGEBUG_SCRIPT_NAME), sEvent);
}

// @PAD[MESSAGEBUS]
void MessageBus_Subscribe(struct AnnotationData str)
{
    string sEvent = GetAnnotationString(str, 0);
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction));

    sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + MESSAGEBUG_SCRIPT_NAME + " (event, system, scriptchunk) VALUES(@event, @system, @scriptchunk);");
    SqlBindString(sql, "@event", sEvent);
    SqlBindString(sql, "@system", str.sSystem);
    SqlBindString(sql, "@scriptchunk", sScriptChunk);
    SqlStep(sql);

    CacheScriptChunk(sScriptChunk);
    IncrementLocalInt(GetDataObject(MESSAGEBUG_SCRIPT_NAME), sEvent);
}
