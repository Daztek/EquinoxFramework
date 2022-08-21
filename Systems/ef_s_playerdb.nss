/*
    Script: ef_s_playerdb
    Author: Daz

    Description: An Equinox Framework System to store player data temporarily or persistently.
*/

#include "ef_i_core"

const string PLAYERDB_LOG_TAG               = "PlayerDB";
const string PLAYERDB_SCRIPT_NAME           = "ef_s_playerdb";
const string PLAYERDB_DATABASE_NAME         = "EFPlayerDB";
const string PLAYERDB_SESSION_DATA          = "PDBSessionData_";
const int PLAYERDB_ONCLIENTEXIT_PRIORITY    = 100;

const int PLAYERDB_TYPE_ALL                 = 0;
const int PLAYERDB_TYPE_INT                 = 1;
const int PLAYERDB_TYPE_FLOAT               = 2;
const int PLAYERDB_TYPE_STRING              = 4;
const int PLAYERDB_TYPE_VECTOR              = 8;
const int PLAYERDB_TYPE_LOCATION            = 16;
const int PLAYERDB_TYPE_JSON                = 32;

object PlayerDB_GetSessionDataObject(object oPlayer);
int PlayerDB_GetSessionInt(object oPlayer, string sSystem, string sVarName);
void PlayerDB_SetSessionInt(object oPlayer, string sSystem, string sVarName, int nValue);
void PlayerDB_DeleteSessionInt(object oPlayer, string sSystem, string sVarName);
string PlayerDB_GetSessionString(object oPlayer, string sSystem, string sVarName);
void PlayerDB_SetSessionString(object oPlayer, string sSystem, string sVarName, string sValue);
void PlayerDB_DeleteSessionString(object oPlayer, string sSystem, string sVarName);

int PlayerDB_GetInt(object oPlayer, string sSystem, string sVarName);
void PlayerDB_SetInt(object oPlayer, string sSystem, string sVarName, int nValue);
void PlayerDB_DeleteInt(object oPlayer, string sSystem, string sVarName);
float PlayerDB_GetFloat(object oPlayer, string sSystem, string sVarName);
void PlayerDB_SetFloat(object oPlayer, string sSystem, string sVarName, float fValue);
void PlayerDB_DeleteFloat(object oPlayer, string sSystem, string sVarName);
string PlayerDB_GetString(object oPlayer, string sSystem, string sVarName);
void PlayerDB_SetString(object oPlayer, string sSystem, string sVarName, string sValue);
void PlayerDB_DeleteString(object oPlayer, string sSystem, string sVarName);
vector PlayerDB_GetVector(object oPlayer, string sSystem, string sVarName);
void PlayerDB_SetVector(object oPlayer, string sSystem, string sVarName, vector vValue);
void PlayerDB_DeleteVector(object oPlayer, string sSystem, string sVarName);
location PlayerDB_GetLocation(object oPlayer, string sSystem, string sVarName);
void PlayerDB_SetLocation(object oPlayer, string sSystem, string sVarName, location locValue);
void PlayerDB_DeleteLocation(object oPlayer, string sSystem, string sVarName);
json PlayerDB_GetJson(object oPlayer, string sSystem, string sVarName);
void PlayerDB_SetJson(object oPlayer, string sSystem, string sVarName, json jValue);
void PlayerDB_DeleteJson(object oPlayer, string sSystem, string sVarName);

void PlayerDB_Delete(object oPlayer, string sSystem, int nType = PLAYERDB_TYPE_ALL, string sLike = "", string sEscape = "");
int PlayerDB_Count(object oPlayer, string sSystem, int nType = PLAYERDB_TYPE_ALL, string sLike = "", string sEscape = "");
int PlayerDB_IsSet(object oPlayer, string sSystem, string sVarName, int nType);
int PlayerDB_GetLastUpdated_UnixEpoch(object oPlayer, string sSystem, string sVarName, int nType);
string PlayerDB_GetLastUpdated_UTC(object oPlayer, string sSystem, string sVarName, int nType);

// @NWNX[NWNX_ON_ELC_VALIDATE_CHARACTER_BEFORE]
void PlayerDB_Init()
{
    object oPlayer = OBJECT_SELF;
    SqlStep(SqlPrepareQueryObject(oPlayer,
        "CREATE TABLE IF NOT EXISTS " + PLAYERDB_DATABASE_NAME + " (" +
        "system TEXT, " +
        "type INTEGER, " +
        "varname TEXT, " +
        "value BLOB, " +
        "timestamp INTEGER, " +
        "PRIMARY KEY(system, type, varname));"));
    ExportSingleCharacter(oPlayer);
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:PLAYERDB_ONCLIENTEXIT_PRIORITY]
void PlayerDB_DestroySessionDataObject()
{
    DestroyDataObject(PLAYERDB_SESSION_DATA + GetObjectUUID(GetExitingObject()));
}

object PlayerDB_GetSessionDataObject(object oPlayer)
{
    return GetDataObject(PLAYERDB_SESSION_DATA + GetObjectUUID(oPlayer));
}

int PlayerDB_GetSessionInt(object oPlayer, string sSystem, string sVarName)
{
    return GetLocalInt(PlayerDB_GetSessionDataObject(oPlayer), PLAYERDB_SESSION_DATA + sSystem + sVarName);
}

void PlayerDB_SetSessionInt(object oPlayer, string sSystem, string sVarName, int nValue)
{
    SetLocalInt(PlayerDB_GetSessionDataObject(oPlayer), PLAYERDB_SESSION_DATA + sSystem + sVarName, nValue);
}

void PlayerDB_DeleteSessionInt(object oPlayer, string sSystem, string sVarName)
{
    DeleteLocalInt(PlayerDB_GetSessionDataObject(oPlayer), PLAYERDB_SESSION_DATA + sSystem + sVarName);
}

string PlayerDB_GetSessionString(object oPlayer, string sSystem, string sVarName)
{
    return GetLocalString(PlayerDB_GetSessionDataObject(oPlayer), PLAYERDB_SESSION_DATA + sSystem + sVarName);
}

void PlayerDB_SetSessionString(object oPlayer, string sSystem, string sVarName, string sValue)
{
    SetLocalString(PlayerDB_GetSessionDataObject(oPlayer), PLAYERDB_SESSION_DATA + sSystem + sVarName, sValue);
}

void PlayerDB_DeleteSessionString(object oPlayer, string sSystem, string sVarName)
{
    DeleteLocalString(PlayerDB_GetSessionDataObject(oPlayer), PLAYERDB_SESSION_DATA + sSystem + sVarName);
}

sqlquery PlayerDB_PrepareSelect(object oPlayer, string sSystem, int nType, string sVarName)
{
    sqlquery sql = SqlPrepareQueryObject(oPlayer,
        "SELECT value FROM " + PLAYERDB_DATABASE_NAME + " " +
        "WHERE system = @system AND type = @type AND varname = @varname;");
    SqlBindString(sql, "@system", sSystem);
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);
    return sql;
}

sqlquery PlayerDB_PrepareInsert(object oPlayer, string sSystem, int nType, string sVarName)
{
    sqlquery sql = SqlPrepareQueryObject(oPlayer,
        "INSERT INTO " + PLAYERDB_DATABASE_NAME + " " +
        "(system, type, varname, value, timestamp) VALUES (@system, @type, @varname, @value, strftime('%s','now')) " +
        "ON CONFLICT (system, type, varname) DO UPDATE SET value = @value, timestamp = strftime('%s','now');");
    SqlBindString(sql, "@system", sSystem);
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);
    return sql;
}

sqlquery PlayerDB_PrepareDelete(object oPlayer, string sSystem, int nType, string sVarName)
{
    sqlquery sql = SqlPrepareQueryObject(oPlayer,
        "DELETE FROM " + PLAYERDB_DATABASE_NAME + " " +
        "WHERE system = @system AND type = @type AND varname = @varname;");
    SqlBindString(sql, "@system", sSystem);
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);
    return sql;
}

int PlayerDB_ValidateArguments(object oPlayer, string sSystem, string sVarName)
{
    return GetIsObjectValid(oPlayer) && sSystem != "" && sVarName != "";
}

int PlayerDB_GetInt(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return 0;
    sqlquery sql = PlayerDB_PrepareSelect(oPlayer, sSystem, PLAYERDB_TYPE_INT, sVarName);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void PlayerDB_SetInt(object oPlayer, string sSystem, string sVarName, int nValue)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    sqlquery sql = PlayerDB_PrepareInsert(oPlayer, sSystem, PLAYERDB_TYPE_INT, sVarName);
    SqlBindInt(sql, "@value", nValue);
    SqlStep(sql);
}

void PlayerDB_DeleteInt(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    SqlStep(PlayerDB_PrepareDelete(oPlayer, sSystem, PLAYERDB_TYPE_INT, sVarName));
}

float PlayerDB_GetFloat(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return 0.0f;
    sqlquery sql = PlayerDB_PrepareSelect(oPlayer, sSystem, PLAYERDB_TYPE_FLOAT, sVarName);
    return SqlStep(sql) ? SqlGetFloat(sql, 0) : 0.0f;
}

void PlayerDB_SetFloat(object oPlayer, string sSystem, string sVarName, float fValue)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    sqlquery sql = PlayerDB_PrepareInsert(oPlayer, sSystem, PLAYERDB_TYPE_FLOAT, sVarName);
    SqlBindFloat(sql, "@value", fValue);
    SqlStep(sql);
}

void PlayerDB_DeleteFloat(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    SqlStep(PlayerDB_PrepareDelete(oPlayer, sSystem, PLAYERDB_TYPE_FLOAT, sVarName));
}

string PlayerDB_GetString(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return "";
    sqlquery sql = PlayerDB_PrepareSelect(oPlayer, sSystem, PLAYERDB_TYPE_STRING, sVarName);
    return SqlStep(sql) ? SqlGetString(sql, 0) : "";
}

void PlayerDB_SetString(object oPlayer, string sSystem, string sVarName, string sValue)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    sqlquery sql = PlayerDB_PrepareInsert(oPlayer, sSystem, PLAYERDB_TYPE_STRING, sVarName);
    SqlBindString(sql, "@value", sValue);
    SqlStep(sql);
}

void PlayerDB_DeleteString(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    SqlStep(PlayerDB_PrepareDelete(oPlayer, sSystem, PLAYERDB_TYPE_STRING, sVarName));
}

vector PlayerDB_GetVector(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return Vector(0.0f, 0.0f, 0.0f);
    sqlquery sql = PlayerDB_PrepareSelect(oPlayer, sSystem, PLAYERDB_TYPE_VECTOR, sVarName);
    if (SqlStep(sql))
        return SqlGetVector(sql, 0);
    else
        return Vector(0.0f, 0.0f, 0.0f);
}

void PlayerDB_SetVector(object oPlayer, string sSystem, string sVarName, vector vValue)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    sqlquery sql = PlayerDB_PrepareInsert(oPlayer, sSystem, PLAYERDB_TYPE_VECTOR, sVarName);
    SqlBindVector(sql, "@value", vValue);
    SqlStep(sql);
}

void PlayerDB_DeleteVector(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    SqlStep(PlayerDB_PrepareDelete(oPlayer, sSystem, PLAYERDB_TYPE_VECTOR, sVarName));
}

location PlayerDB_GetLocation(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return GetStartingLocation();
    sqlquery sql = PlayerDB_PrepareSelect(oPlayer, sSystem, PLAYERDB_TYPE_LOCATION, sVarName);
    return SqlStep(sql) ? JsonToLocation(SqlGetJson(sql, 0)) : GetStartingLocation();
}

void PlayerDB_SetLocation(object oPlayer, string sSystem, string sVarName, location locValue)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    sqlquery sql = PlayerDB_PrepareInsert(oPlayer, sSystem, PLAYERDB_TYPE_LOCATION, sVarName);
    SqlBindJson(sql, "@value", LocationToJson(locValue));
    SqlStep(sql);
}

void PlayerDB_DeleteLocation(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    SqlStep(PlayerDB_PrepareDelete(oPlayer, sSystem, PLAYERDB_TYPE_LOCATION, sVarName));
}

json PlayerDB_GetJson(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return JsonNull();
    sqlquery sql = PlayerDB_PrepareSelect(oPlayer, sSystem, PLAYERDB_TYPE_JSON, sVarName);
    return SqlStep(sql) ? SqlGetJson(sql, 0) : JsonNull();
}

void PlayerDB_SetJson(object oPlayer, string sSystem, string sVarName, json jValue)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    sqlquery sql = PlayerDB_PrepareInsert(oPlayer, sSystem, PLAYERDB_TYPE_JSON, sVarName);
    SqlBindJson(sql, "@value", jValue);
    SqlStep(sql);
}

void PlayerDB_DeleteJson(object oPlayer, string sSystem, string sVarName)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName)) return;
    SqlStep(PlayerDB_PrepareDelete(oPlayer, sSystem, PLAYERDB_TYPE_JSON, sVarName));
}

void PlayerDB_Delete(object oPlayer, string sSystem, int nType = PLAYERDB_TYPE_ALL, string sLike = "", string sEscape = "")
{
    if (!GetIsObjectValid(oPlayer) || sSystem == "" || nType < 0) return;

    sqlquery sql = SqlPrepareQueryObject(oPlayer,
        "DELETE FROM " + PLAYERDB_DATABASE_NAME + " " +
        "WHERE system = @system " +
        (nType != PLAYERDB_TYPE_ALL ? "AND type & @type " : " ") +
        (sLike != "" ? "AND varname LIKE @like " + (sEscape != "" ? "ESCAPE @escape" : "") : "") +
        ";");

    SqlBindString(sql, "@system", sSystem);

    if (nType != PLAYERDB_TYPE_ALL)
        SqlBindInt(sql, "@type", nType);
    if (sLike != "")
    {
        SqlBindString(sql, "@like", sLike);

        if (sEscape != "")
            SqlBindString(sql, "@escape", sEscape);
    }

    SqlStep(sql);
}

int PlayerDB_Count(object oPlayer, string sSystem, int nType = PLAYERDB_TYPE_ALL, string sLike = "", string sEscape = "")
{
    if (!GetIsObjectValid(oPlayer) || sSystem == "" || nType < 0) return 0;

    sqlquery sql = SqlPrepareQueryObject(oPlayer,
        "SELECT COUNT(*) FROM " + PLAYERDB_DATABASE_NAME + " " +
        "WHERE system = @system " +
        (nType != PLAYERDB_TYPE_ALL ? "AND type & @type " : " ") +
        (sLike != "" ? "AND varname LIKE @like " + (sEscape != "" ? "ESCAPE @escape" : "") : "") +
        ";");

    SqlBindString(sql, "@system", sSystem);

    if (nType != PLAYERDB_TYPE_ALL)
        SqlBindInt(sql, "@type", nType);
    if (sLike != "")
    {
        SqlBindString(sql, "@like", sLike);

        if (sEscape != "")
            SqlBindString(sql, "@escape", sEscape);
    }

    if (SqlStep(sql))
        return SqlGetInt(sql, 0);
    else
        return 0;
}

int PlayerDB_IsSet(object oPlayer, string sSystem, string sVarName, int nType)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName) || nType < 0) return 0;

    sqlquery sql = SqlPrepareQueryObject(oPlayer,
        "SELECT * FROM " + PLAYERDB_DATABASE_NAME + " " +
        "WHERE system = @system " +
        (nType != PLAYERDB_TYPE_ALL ? "AND type & @type " : " ") +
        "AND varname = @varname;");

    SqlBindString(sql, "@system", sSystem);
    if (nType != PLAYERDB_TYPE_ALL)
        SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    return SqlStep(sql);
}

int PlayerDB_GetLastUpdated_UnixEpoch(object oPlayer, string sSystem, string sVarName, int nType)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName) || nType < 0) return 0;

    sqlquery sql = SqlPrepareQueryObject(oPlayer,
        "SELECT timestamp FROM " + PLAYERDB_DATABASE_NAME + " " +
        "WHERE system = @system " +
        "AND type = @type " +
        "AND varname = @varname;");

    SqlBindString(sql, "@system", sSystem);
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    if (SqlStep(sql))
        return SqlGetInt(sql, 0);
    else
        return 0;
}

string PlayerDB_GetLastUpdated_UTC(object oPlayer, string sSystem, string sVarName, int nType)
{
    if (!PlayerDB_ValidateArguments(oPlayer, sSystem, sVarName) || nType < 0) return "";

    sqlquery sql = SqlPrepareQueryObject(oPlayer,
        "SELECT datetime(timestamp, 'unixepoch') FROM " + PLAYERDB_DATABASE_NAME + " " +
        "WHERE system = @system " +
        "AND type = @type " +
        "AND varname = @varname;");

    SqlBindString(sql, "@system", sSystem);
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    if (SqlStep(sql))
        return SqlGetString(sql, 0);
    else
        return "";
}

