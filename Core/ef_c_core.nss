/*
    Script: ef_c_core
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_annotations"
#include "ef_c_log"
#include "ef_c_mediator"
#include "nwnx_admin"

const string CORE_SCRIPT_NAME                       = "ef_c_core";
const int CORE_VALIDATE_SYSTEMS                     = TRUE;
const int CORE_SHUTDOWN_ON_VALIDATION_FAILURE       = FALSE;
const int CORE_DEBUG_MINIMAL_LOAD                   = FALSE;

const string CORE_FORCE_REVALIDATE                  = "CORE_FORCE_REVALIDATE";

const int CORE_SYSTEM_INIT                          = 1;
const int CORE_SYSTEM_LOAD                          = 2;
const int CORE_SYSTEM_POST                          = 3;

const string CORE_CORE_SCRIPT_PREFIX                = "ef_c_";
const string CORE_SYSTEM_SCRIPT_PREFIX              = "ef_s_";
const string CORE_INCLUDE_SCRIPT_PREFIX             = "ef_i_";

void Core_InitializeSystemData();
json Core_GetSkippedSystems();
void Core_ParseSystem(string sSystem);
int Core_ValidateSystems();
void Core_ExecuteCoreFunction(int nCoreFunctionType);

void Core_Init()
{
    LogInfo("Starting Equinox Framework...");

    NWNX_Administration_SetPlayerPassword(GetRandomUUID());
    NWNX_VM_SetInstructionLimit(NWNX_VM_GetInstructionLimit() * 64);

    Core_InitializeSystemData();

    if (CORE_VALIDATE_SYSTEMS && !Core_ValidateSystems())
    {
        LogError("System Validation Failure!");

        if (CORE_SHUTDOWN_ON_VALIDATION_FAILURE)
            NWNX_Administration_ShutdownServer();

        return;
    }

    LogInfo("Executing System 'Init' Functions...");
    Core_ExecuteCoreFunction(CORE_SYSTEM_INIT);
    LogInfo("Parsing Annotation Data...");
    Annotations_ParseAnnotationData(Core_GetSkippedSystems());
    LogInfo("Executing System 'Load' Functions...");
    Core_ExecuteCoreFunction(CORE_SYSTEM_LOAD);
    LogInfo("Executing System 'Post' Functions...");
    Core_ExecuteCoreFunction(CORE_SYSTEM_POST);

    NWNX_Administration_SetPlayerPassword("");
    NWNX_VM_SetInstructionLimit(-1);
}

void Core_InitializeSystemData()
{
    LogInfo("Initializing System Data...");

    SetLocalJson(GetDataObject(CORE_SCRIPT_NAME), "SKIPPED_SYSTEMS", JsonArray());

    string sQuery = "CREATE TABLE IF NOT EXISTS " + CORE_SCRIPT_NAME + "_systems (" +
                    "system TEXT NOT NULL PRIMARY KEY, " +
                    "hash INTEGER NOT NULL, " +
                    "validated_hash INTEGER NOT NULL DEFAULT 0, " +
                    "scriptdata TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryEF(sQuery));

    json jIncludes = GetResRefArray(CORE_INCLUDE_SCRIPT_PREFIX, RESTYPE_NSS);
    jIncludes = JsonArrayTransform(jIncludes, JSON_ARRAY_SORT_ASCENDING);
    int nNewIncludeHash, nInclude, nNumIncludes = JsonGetLength(jIncludes);
    for (nInclude = 0; nInclude < nNumIncludes; nInclude++)
    {
        nNewIncludeHash = nNewIncludeHash * 31 + HashString(ResManGetFileContents(JsonArrayGetString(jIncludes, nInclude), RESTYPE_NSS));
    }

    int nOldIncludeHash = GetCampaignInt(EF_DATABASE_NAME, "INCLUDE_HASH");
    if (nOldIncludeHash != nNewIncludeHash)
    {
        LogInfo("Include Hash Changed; Forcing Revalidation -> {nOldIncludeHash} != {nNewIncludeHash}");

        SetCampaignInt(EF_DATABASE_NAME, "INCLUDE_HASH", nNewIncludeHash);
        SetCampaignInt(EF_DATABASE_NAME, CORE_FORCE_REVALIDATE, TRUE);
    }

    json jSystems = GetResRefArray(CORE_CORE_SCRIPT_PREFIX, RESTYPE_NSS);
    jSystems = GetResRefArray(CORE_SYSTEM_SCRIPT_PREFIX, RESTYPE_NSS, FALSE, "", jSystems);
    jSystems = JsonArrayTransform(jSystems, JSON_ARRAY_SORT_ASCENDING);

    int nSystem, nNumSystems = JsonGetLength(jSystems);
    for (nSystem = 0; nSystem < nNumSystems; nSystem++)
    {
        Core_ParseSystem(JsonArrayGetString(jSystems, nSystem));
    }

    sQuery = "DELETE FROM " + CORE_SCRIPT_NAME + "_systems WHERE system NOT IN (SELECT value FROM JSON_EACH(@systems)) RETURNING system;";
    sqlquery sql = SqlPrepareQueryEF(sQuery);
    SqlBindJson(sql, "@systems", jSystems);
    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);

        LogInfo("Deleting Stale System Data '{sSystem}'");
        Mediator_ClearSystemFunctions(sSystem);
        Annotations_ClearSystemAnnotations(sSystem);
    }
}

void Core_InsertSystem(string sSystem, int nHash, string sScriptData)
{
    string sQuery = "INSERT OR REPLACE INTO " + CORE_SCRIPT_NAME + "_systems(system, hash, scriptdata) VALUES(@system, @hash, @scriptdata);";
    sqlquery sql = SqlPrepareQueryEF(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindInt(sql, "@hash", nHash);
    SqlBindString(sql, "@scriptdata", sScriptData);
    SqlStep(sql);
}

int Core_GetSystemHash(string sSystem)
{
    sqlquery sql = SqlPrepareQueryEF("SELECT hash FROM " + CORE_SCRIPT_NAME + "_systems WHERE system = @system");
    SqlBindString(sql, "@system", sSystem);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

json Core_GetSkippedSystems()
{
    return GetLocalJson(GetDataObject(CORE_SCRIPT_NAME), "SKIPPED_SYSTEMS");
}

void Core_InsertSkippedSystem(string sSystem)
{
    JsonArrayInsertStringInplace(Core_GetSkippedSystems(), sSystem);
}

void Core_ParseSystem(string sSystem)
{
    string sScriptData = ResManGetFileContents(sSystem, RESTYPE_NSS);

    if (GetStringLeft(sSystem, GetStringLength(CORE_SYSTEM_SCRIPT_PREFIX)) == CORE_SYSTEM_SCRIPT_PREFIX &&
        ((CORE_DEBUG_MINIMAL_LOAD && sSystem != "ef_s_debug" && sSystem != "ef_s_eventman") ||
        FindSubString(sScriptData, "@SKIPSYSTEM") != -1))
    {
        LogInfo("Skipping System '{sSystem}'");
        Core_InsertSkippedSystem(sSystem);
    }

    int nOldHash = Core_GetSystemHash(sSystem);
    int nNewHash = HashString(sScriptData);

    if (nOldHash != nNewHash)
    {
        LogInfo("Parsing System '{sSystem}' -> {nOldHash} != {nNewHash}");

        SqlBeginTransactionEF();

        Mediator_ClearSystemFunctions(sSystem);
        Annotations_ClearSystemAnnotations(sSystem);
        Core_InsertSystem(sSystem, nNewHash, sScriptData);

        struct ParserData str = ParserPrepare(sScriptData, TRUE);
        json jAnnotations = JsonArray();
        int bFoundAnnotations = FALSE;

        while (!(str = ParserParse(str)).bEndOfFile)
        {
            if (!Mediator_ParseFunctionDefinition(str.sLine, sSystem))
            {
                while (Annotations_ParseAnnotation(str.sLine, jAnnotations))
                {
                    bFoundAnnotations = TRUE;
                    str = ParserParse(str);
                }

                if (bFoundAnnotations)
                {
                    int bFoundFunction = FALSE;
                    if (ParserPeek(str) == "{")
                    {
                        bFoundFunction = Annotations_InsertAnnotation(sSystem, str.sLine, jAnnotations);
                    }

                    if (!bFoundFunction)
                    {
                        LogWarning("Missing Function For Annotations: {jAnnotations}");
                    }

                    bFoundAnnotations = FALSE;
                    jAnnotations = JsonArray();
                }
            }
        }

        SqlCommitTransactionEF();
    }
}

int Core_ValidateSystems()
{
    object oModule = GetModule();
    int bValidated = TRUE;
    int bForceRevalidate = GetCampaignInt(EF_DATABASE_NAME, CORE_FORCE_REVALIDATE);

    LogInfo("Validating System Data...");

    sqlquery sql = SqlPrepareQueryEF("SELECT system, scriptdata FROM " + CORE_SCRIPT_NAME + "_systems WHERE hash != validated_hash OR @force_revalidate;");
    SqlBindInt(sql, "@force_revalidate", bForceRevalidate);

    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);
        string sScriptData = SqlGetString(sql, 1);
        string sError = ExecuteScriptChunk(sScriptData + " " + nssVoidMain(""),  oModule, FALSE);

        LogInfo("Validating System '{sSystem}'");

        if (sError != "")
        {
            bValidated = FALSE;
            LogError("System '{sSystem}' failed to validate with error: {sError}");
        }
        else
        {
            sqlquery sqlUpdateHash = SqlPrepareQueryEF("UPDATE " + CORE_SCRIPT_NAME + "_systems SET validated_hash = hash WHERE system = @system;");
            SqlBindString(sqlUpdateHash, "@system", sSystem);
            SqlStep(sqlUpdateHash);
        }
    }

    ResetScriptInstructions();

    if (bForceRevalidate && bValidated)
        SetCampaignInt(EF_DATABASE_NAME, CORE_FORCE_REVALIDATE, FALSE);

    return bValidated;
}

void Core_ExecuteCoreFunction(int nCoreFunctionType)
{
    object oModule = GetModule();
    sqlquery sql = SqlPrepareQueryEF("SELECT system, function, data FROM " + ANNOTATIONS_SCRIPT_NAME + " WHERE annotation = @annotation " +
                                     "AND system NOT IN (SELECT value FROM JSON_EACH(@skipped_systems));");
    SqlBindString(sql, "@annotation", "CORE");
    SqlBindJson(sql, "@skipped_systems", Core_GetSkippedSystems());
    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);
        string sFunction = SqlGetString(sql, 1);
        json jData = SqlGetJson(sql, 2);

        if (GetConstantIntValue(JsonArrayGetString(jData, 0), CORE_SCRIPT_NAME) == nCoreFunctionType)
        {
            string sError = ExecuteScriptChunk(nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction)), oModule, FALSE);
            if (sError != "")
                LogError("Function '{sFunction}' for '{sSystem}' failed with error: {sError}");
            ResetScriptInstructions();
        }
    }
}
