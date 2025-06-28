/*
    Script: ef_c_messagebus
    Author: Daz

    @MESSAGEBUS[EVENTNAME]
*/

#include "ef_c_annotations"
#include "ef_i_dataobject"
#include "ef_i_sqlite"
#include "ef_i_util"

const string MESSAGEBUS_SCRIPT_NAME = "ef_c_messagebus";
const string MESSAGEBUS_EVENT_PREFIX = "MBE_";

void MessageBus_Broadcast(string sEvent, object oObject);
int MessageBus_GetNumberOfSubscribers(string sEvent);

void MessageBus_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + MESSAGEBUS_SCRIPT_NAME + "(" +
                    "event TEXT NOT NULL, " +
                    "system TEXT NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

void MessageBus_Broadcast(string sEvent, object oObject)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT system, scriptchunk FROM " + MESSAGEBUS_SCRIPT_NAME + " WHERE event = @event;");
    SqlBindString(sql, "@event", sEvent);

    while (SqlStep(sql))
    {
        string sScriptChunk = SqlGetString(sql, 1);
        ExecuteScriptChunk(sScriptChunk, oObject, FALSE);
        ResetScriptInstructions();
    }
}

int MessageBus_GetNumberOfSubscribers(string sEvent)
{
    return GetLocalInt(GetDataObject(MESSAGEBUS_SCRIPT_NAME), MESSAGEBUS_EVENT_PREFIX + sEvent);
}

// @PAD[MESSAGEBUS]
void MessageBus_Subscribe(struct AnnotationData str)
{
    string sEvent = GetAnnotationString(str, 0);
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction));

    sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + MESSAGEBUS_SCRIPT_NAME + " (event, system, scriptchunk) VALUES(@event, @system, @scriptchunk);");
    SqlBindString(sql, "@event", sEvent);
    SqlBindString(sql, "@system", str.sSystem);
    SqlBindString(sql, "@scriptchunk", sScriptChunk);
    SqlStep(sql);

    CacheScriptChunk(sScriptChunk);
    IncrementLocalInt(GetDataObject(MESSAGEBUS_SCRIPT_NAME), MESSAGEBUS_EVENT_PREFIX + sEvent);
}
