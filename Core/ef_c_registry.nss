/*
    Script: ef_c_registry
    Author: Daz
*/

#include "ef_i_dataobject"
#include "ef_i_json"

const string REGISTRY_SCRIPT_NAME           = "ef_c_registry";
const string REGISTRY_DATABASE_NAME         = "ef_registry";

const string REGISTRY_SYSTEMS_TABLE         = "ef_systems";
const string REGISTRY_ANNOTATIONS_TABLE     = "ef_annotations";
const string REGISTRY_MEDIATOR_TABLE        = "ef_mediator";

const string REGISTRY_INCLUDE_HASH          = "INCLUDE_HASH";
const string REGISTRY_SKIPPED_SYSTEMS       = "SKIPPED_SYSTEMS";
const string REGISTRY_FORCE_REVALIDATE      = "FORCE_REVALIDATE";

sqlquery SqlPrepareQueryRegistry(string sQuery);
void SqlBeginTransactionRegistry();
void SqlCommitTransactionRegistry();

int Registry_GetInt(string sVarName);
void Registry_SetInt(string sVarName, int nValue);
json Registry_GetSkippedSystems();
void Registry_InsertSkippedSystem(string sSystem);

void Registry_Init()
{
    string sQuery;
    object oDataObject = GetDataObject(REGISTRY_SCRIPT_NAME);

    sQuery = "CREATE TABLE IF NOT EXISTS " + REGISTRY_SYSTEMS_TABLE + "(" +
             "system TEXT NOT NULL PRIMARY KEY, " +
             "hash INTEGER NOT NULL, " +
             "validated_hash INTEGER NOT NULL DEFAULT 0, " +
             "scriptdata TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryRegistry(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + REGISTRY_ANNOTATIONS_TABLE + " (" +
             "system TEXT NOT NULL, " +
             "annotation TEXT NOT NULL, " +
             "function TEXT NOT NULL, " +
             "parameters TEXT NOT NULL, " +
             "return_type TEXT NOT NULL, " +
             "data TEXT NOT NULL, " +
             "raw TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryRegistry(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_ef_annotations_system ON " + REGISTRY_ANNOTATIONS_TABLE + "(system);";
    SqlStep(SqlPrepareQueryRegistry(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_ef_annotations_annotation ON " + REGISTRY_ANNOTATIONS_TABLE + "(annotation);";
    SqlStep(SqlPrepareQueryRegistry(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + REGISTRY_MEDIATOR_TABLE + " (" +
             "system TEXT NOT NULL, " +
             "function TEXT NOT NULL, " +
             "returntype TEXT NOT NULL, " +
             "parameters TEXT NOT NULL, " +
             "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryRegistry(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_ef_mediator_system_function ON " + REGISTRY_MEDIATOR_TABLE + "(system, function);";
    SqlStep(SqlPrepareQueryRegistry(sQuery));

    SetLocalJson(oDataObject, REGISTRY_SKIPPED_SYSTEMS, JsonArray());
}

sqlquery SqlPrepareQueryRegistry(string sQuery)
{
    return SqlPrepareQueryCampaign(REGISTRY_DATABASE_NAME, sQuery);
}

void SqlBeginTransactionRegistry()
{
    SqlStep(SqlPrepareQueryCampaign(REGISTRY_DATABASE_NAME, "BEGIN TRANSACTION;"));
}

void SqlCommitTransactionRegistry()
{
    SqlStep(SqlPrepareQueryCampaign(REGISTRY_DATABASE_NAME, "COMMIT;"));
}

int Registry_GetInt(string sVarName)
{
    return GetCampaignInt(REGISTRY_DATABASE_NAME, sVarName);
}

void Registry_SetInt(string sVarName, int nValue)
{
    SetCampaignInt(REGISTRY_DATABASE_NAME, sVarName, nValue);
}

json Registry_GetSkippedSystems()
{
    return GetLocalJson(GetDataObject(REGISTRY_SCRIPT_NAME), REGISTRY_SKIPPED_SYSTEMS);
}

void Registry_InsertSkippedSystem(string sSystem)
{
    JsonArrayInsertStringInplace(Registry_GetSkippedSystems(), sSystem);
}
