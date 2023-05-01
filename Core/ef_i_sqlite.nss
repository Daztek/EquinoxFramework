/*
    Script: ef_i_sqlite
    Author: Daz

    Description: Equinox Framework SQLite Utility Include
*/

// Returns TRUE if sTableName exists in sDatabase.
int SqlGetTableExistsCampaign(string sDatabase, string sTableName);
// Returns TRUE if sTableName exists on oObject.
int SqlGetTableExistsObject(object oObject, string sTableName);
// Returns the last insert id for sDatabase, -1 on error.
int SqlGetLastInsertIdCampaign(string sDatabase);
// Returns the last insert id for oObject, -1 on error.
int SqlGetLastInsertIdObject(object oObject);
// Returns the number of affected rows by the most recent INSERT, UPDATE or DELETE query for sDatabase, -1 on error.
int SqlGetAffectedRowsCampaign(string sDatabase);
// Returns the number of affected rows by the most recent INSERT, UPDATE or DELETE query for oObject, -1 on error.
int SqlGetAffectedRowsObject(object oObject);
// Prepare a new query for the module database
sqlquery SqlPrepareQueryModule(string sQuery);
// Begin a transaction on a campaign database
void SqlBeginTransactionCampaign(string sDatabase);
// Commit a transaction on a campaign database
void SqlCommitTransactionCampaign(string sDatabase);
// Begin a transaction on an object database
void SqlBeginTransactionObject(object oObject);
// Commit a transaction on an object database
void SqlCommitTransactionObject(object oObject);
// Begin a transaction on the module database
void SqlBeginTransactionModule();
// Commit a transaction on the module database
void SqlCommitTransactionModule();
// Get the unix epoch
int SqlGetUnixEpoch();

int SqlGetTableExistsCampaign(string sDatabase, string sTableName)
{
    string sQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name=@tableName;";
    sqlquery sql = SqlPrepareQueryCampaign(sDatabase, sQuery);
    SqlBindString(sql, "@tableName", sTableName);

    return SqlStep(sql);
}

int SqlGetTableExistsObject(object oObject, string sTableName)
{
    string sQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name=@tableName;";
    sqlquery sql = SqlPrepareQueryObject(oObject, sQuery);
    SqlBindString(sql, "@tableName", sTableName);

    return SqlStep(sql);
}

int SqlGetLastInsertIdCampaign(string sDatabase)
{
    sqlquery sql = SqlPrepareQueryCampaign(sDatabase, "SELECT last_insert_rowid();");

    return SqlStep(sql) ? SqlGetInt(sql, 0) : -1;
}

int SqlGetLastInsertIdObject(object oObject)
{
    sqlquery sql = SqlPrepareQueryObject(oObject, "SELECT last_insert_rowid();");

    return SqlStep(sql) ? SqlGetInt(sql, 0) : -1;
}

int SqlGetAffectedRowsCampaign(string sDatabase)
{
    sqlquery sql = SqlPrepareQueryCampaign(sDatabase, "SELECT changes();");

    return SqlStep(sql) ? SqlGetInt(sql, 0) : -1;
}

int SqlGetAffectedRowsObject(object oObject)
{
    sqlquery sql = SqlPrepareQueryObject(oObject, "SELECT changes();");

    return SqlStep(sql) ? SqlGetInt(sql, 0) : -1;
}

sqlquery SqlPrepareQueryModule(string sQuery)
{
    return SqlPrepareQueryObject(GetModule(), sQuery);
}

void SqlBeginTransactionCampaign(string sDatabase)
{
    SqlStep(SqlPrepareQueryCampaign(sDatabase, "BEGIN TRANSACTION;"));
}

void SqlCommitTransactionCampaign(string sDatabase)
{
    SqlStep(SqlPrepareQueryCampaign(sDatabase, "COMMIT;"));
}

void SqlBeginTransactionObject(object oObject)
{
    SqlStep(SqlPrepareQueryObject(oObject, "BEGIN TRANSACTION;"));
}

void SqlCommitTransactionObject(object oObject)
{
    SqlStep(SqlPrepareQueryObject(oObject, "COMMIT;"));
}
void SqlBeginTransactionModule()
{
    SqlStep(SqlPrepareQueryObject(GetModule(), "BEGIN TRANSACTION;"));
}

void SqlCommitTransactionModule()
{
    SqlStep(SqlPrepareQueryObject(GetModule(), "COMMIT;"));
}

int SqlGetUnixEpoch()
{
    sqlquery sql = SqlPrepareQueryModule("SELECT UNIXEPOCH();");
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}
