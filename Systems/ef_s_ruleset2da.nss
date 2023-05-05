/*
    Script: ef_s_ruleset2da
    Author: Daz
*/

#include "ef_i_core"

const string RS2DA_SCRIPT_NAME                         = "ef_s_ruleset2da";

int RS2DA_GetIntEntry(string sEntry);
float RS2DA_GetFloatEntry(string sEntry);

// @CORE[EF_SYSTEM_INIT]
void RS2DA_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + RS2DA_SCRIPT_NAME + " (" +
                    "name TEXT NOT NULL, " +
                    "value TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();

    sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + RS2DA_SCRIPT_NAME + "(name, value) VALUES(@name, @value);");
    int nRow, nNumRows = Get2DARowCount("ruleset");
    for (nRow = 0; nRow < nNumRows; nRow++)
    {
        string sName = Get2DAString("ruleset", "Label", nRow);
        string sValue = Get2DAString("ruleset", "Value", nRow);

        if (sName == "" || sValue == "")
            continue;

        SqlBindString(sql, "@name", sName);
        SqlBindString(sql, "@value", sValue);
        SqlStepAndReset(sql);
    }

    SqlCommitTransactionModule();
}

int RS2DA_GetIntEntry(string sEntry)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT value FROM " + RS2DA_SCRIPT_NAME + " WHERE name = @name;");
    SqlBindString(sql, "@name", sEntry);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

float RS2DA_GetFloatEntry(string sEntry)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT value FROM " + RS2DA_SCRIPT_NAME + " WHERE name = @name;");
    SqlBindString(sql, "@name", sEntry);
    return SqlStep(sql) ? SqlGetFloat(sql, 0) : 0.0f;
}
