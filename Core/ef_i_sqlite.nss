/*
    Script: ef_i_sqlite
    Author: Daz

    Description: Equinox Framework SQLite Utility Include
*/

#include "ef_i_string"
#include "nwnx_nwsqliteext"

const int SQL_ENABLE_MERSENNE_TWISTER = TRUE;

int SqlGetTableExistsCampaign(string sDatabase, string sTableName);
int SqlGetTableExistsObject(object oObject, string sTableName);
int SqlGetLastInsertIdCampaign(string sDatabase);
int SqlGetLastInsertIdObject(object oObject);
int SqlGetAffectedRowsCampaign(string sDatabase);
int SqlGetAffectedRowsObject(object oObject);
sqlquery SqlPrepareQueryModule(string sQuery);
void SqlBeginTransactionCampaign(string sDatabase);
void SqlCommitTransactionCampaign(string sDatabase);
void SqlBeginTransactionObject(object oObject);
void SqlCommitTransactionObject(object oObject);
void SqlBeginTransactionModule();
void SqlCommitTransactionModule();
int SqlGetUnixEpoch();
void SqlStepAndReset(sqlquery sql);
void SqlMersenneTwisterSetSeed(string sName, int nSeed);
int SqlMersenneTwisterGetValue(string sName, int nMaxInteger);
void SqlMersenneTwisterDiscard(string sName, int nAmount);
void SqlBindObjectRef(sqlquery sqlQuery, string sParam, object oObject);
object SqlGetObjectRef(sqlquery sqlQuery, int nIndex);
string SqlGetLocalTimeAsString();

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
    SqlStep(SqlPrepareQueryModule("BEGIN TRANSACTION;"));
}

void SqlCommitTransactionModule()
{
    SqlStep(SqlPrepareQueryModule("COMMIT;"));
}

int SqlGetUnixEpoch()
{
    sqlquery sql = SqlPrepareQueryModule("SELECT UNIXEPOCH();");
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void SqlStepAndReset(sqlquery sql)
{
    SqlStep(sql);
    SqlResetQuery(sql, TRUE);
}

void SqlMersenneTwisterSetSeed(string sName, int nSeed)
{
    if (SQL_ENABLE_MERSENNE_TWISTER)
    {
        sqlquery sql = SqlPrepareQueryModule("SELECT MT_SEED(@name, @seed);");
        SqlBindString(sql, "@name", sName);
        SqlBindInt(sql, "@seed", nSeed);
        SqlStep(sql);
    }
}

int SqlMersenneTwisterGetValue(string sName, int nMaxInteger)
{
    if (SQL_ENABLE_MERSENNE_TWISTER)
    {
        sqlquery sql = SqlPrepareQueryModule("SELECT (MT_VALUE(@name) % @maxinteger);");
        SqlBindString(sql, "@name", sName);
        SqlBindInt(sql, "@maxinteger", nMaxInteger);
        return SqlStep(sql) ? SqlGetInt(sql, 0) : Random(nMaxInteger);
    }
    else
    {
        return Random(nMaxInteger);
    }
}

void SqlMersenneTwisterDiscard(string sName, int nAmount)
{
    if (SQL_ENABLE_MERSENNE_TWISTER)
    {
        sqlquery sql = SqlPrepareQueryModule("SELECT MT_DISCARD(@name, @amount);");
        SqlBindString(sql, "@name", sName);
        SqlBindInt(sql, "@amount", nAmount);
        SqlStep(sql);
    }
}

void SqlBindObjectRef(sqlquery sqlQuery, string sParam, object oObject)
{
    SqlBindInt(sqlQuery, sParam, HexStringToInt(ObjectToString(oObject)));
}

object SqlGetObjectRef(sqlquery sqlQuery, int nIndex)
{
    return StringToObject(IntToHexString(SqlGetInt(sqlQuery, nIndex)));
}

string SqlGetLocalTimeAsString()
{
    sqlquery sql = SqlPrepareQueryModule("SELECT STRFTIME('%H:%M:%S', 'now', 'localtime')");
    return SqlStep(sql) ? SqlGetString(sql, 0) : "??:??:??";
}
