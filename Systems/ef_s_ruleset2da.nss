/*
    Script: ef_s_ruleset2da
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"

const string RS2DA_SCRIPT_NAME                         = "ef_s_ruleset2da";

int RS2DA_GetIntEntry(string sEntry);
float RS2DA_GetFloatEntry(string sEntry);

// @CORE[CORE_SYSTEM_INIT]
void RS2DA_Init()
{
    NWNX_NWSQLiteExtensions_CreateVirtual2DATable("ruleset", "00", RS2DA_SCRIPT_NAME);
}

int RS2DA_GetIntEntry(string sEntry)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT value FROM " + RS2DA_SCRIPT_NAME + " WHERE label = @label;");
    SqlBindString(sql, "@label", sEntry);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

float RS2DA_GetFloatEntry(string sEntry)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT value FROM " + RS2DA_SCRIPT_NAME + " WHERE label = @label;");
    SqlBindString(sql, "@label", sEntry);
    return SqlStep(sql) ? SqlGetFloat(sql, 0) : 0.0f;
}
