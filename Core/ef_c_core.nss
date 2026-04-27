/*
    Script: ef_c_core
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_annotations"
#include "ef_c_log"
#include "ef_c_mediator"
#include "ef_c_registry"
#include "nwnx_admin"

const string CORE_SCRIPT_NAME                       = "ef_c_core";
const int CORE_VALIDATE_SYSTEMS                     = TRUE;
const int CORE_SHUTDOWN_ON_VALIDATION_FAILURE       = FALSE;
const int CORE_DEBUG_MINIMAL_LOAD                   = FALSE;

const int CORE_SYSTEM_INIT                          = 1;
const int CORE_SYSTEM_LOAD                          = 2;
const int CORE_SYSTEM_POST                          = 3;

const string CORE_CORE_SCRIPT_PREFIX                = "ef_c_";
const string CORE_SYSTEM_SCRIPT_PREFIX              = "ef_s_";
const string CORE_INCLUDE_SCRIPT_PREFIX             = "ef_i_";

void Core_InitializeSystemData();
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
    Annotations_ParseAnnotationData();
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

    json jIncludes = GetResRefArray(CORE_INCLUDE_SCRIPT_PREFIX, RESTYPE_NSS);
    jIncludes = JsonArrayTransform(jIncludes, JSON_ARRAY_SORT_ASCENDING);
    int nNewIncludeHash, nInclude, nNumIncludes = JsonGetLength(jIncludes);
    for (nInclude = 0; nInclude < nNumIncludes; nInclude++)
    {
        nNewIncludeHash = nNewIncludeHash * 31 + HashString(ResManGetFileContents(JsonArrayGetString(jIncludes, nInclude), RESTYPE_NSS));
    }

    int nOldIncludeHash = Registry_GetInt(REGISTRY_INCLUDE_HASH);
    if (nOldIncludeHash != nNewIncludeHash)
    {
        LogInfo("Core Include Hash Changed; Forcing Revalidation -> {nOldIncludeHash} != {nNewIncludeHash}");

        Registry_SetInt(REGISTRY_INCLUDE_HASH, nNewIncludeHash);
        Registry_SetInt(REGISTRY_FORCE_REVALIDATE, TRUE);
    }

    json jSystems = GetResRefArray(CORE_CORE_SCRIPT_PREFIX, RESTYPE_NSS);
    jSystems = GetResRefArray(CORE_SYSTEM_SCRIPT_PREFIX, RESTYPE_NSS, FALSE, "", jSystems);
    jSystems = JsonArrayTransform(jSystems, JSON_ARRAY_SORT_ASCENDING);

    int nSystem, nNumSystems = JsonGetLength(jSystems);
    for (nSystem = 0; nSystem < nNumSystems; nSystem++)
    {
        Core_ParseSystem(JsonArrayGetString(jSystems, nSystem));
    }

    string sQuery = "DELETE FROM " + REGISTRY_SYSTEMS_TABLE + " WHERE system NOT IN (SELECT value FROM JSON_EACH(@systems)) RETURNING system;";
    sqlquery sql = SqlPrepareQueryRegistry(sQuery);
    SqlBindJson(sql, "@systems", jSystems);
    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);

        LogInfo("Deleting Stale System Data: {sSystem}");
        Mediator_ClearSystemFunctions(sSystem);
        Annotations_ClearSystemAnnotations(sSystem);
    }
}

void Core_InsertSystem(string sSystem, int nHash, string sScriptData)
{
    string sQuery = "INSERT OR REPLACE INTO " + REGISTRY_SYSTEMS_TABLE + "(system, hash, scriptdata) VALUES(@system, @hash, @scriptdata);";
    sqlquery sql = SqlPrepareQueryRegistry(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindInt(sql, "@hash", nHash);
    SqlBindString(sql, "@scriptdata", sScriptData);
    SqlStep(sql);
}

int Core_GetSystemHash(string sSystem)
{
    sqlquery sql = SqlPrepareQueryRegistry("SELECT hash FROM " + REGISTRY_SYSTEMS_TABLE + " WHERE system = @system");
    SqlBindString(sql, "@system", sSystem);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void Core_ParseSystem(string sSystem)
{
    string sScriptData = ResManGetFileContents(sSystem, RESTYPE_NSS);

    if (GetStringLeft(sSystem, GetStringLength(CORE_SYSTEM_SCRIPT_PREFIX)) == CORE_SYSTEM_SCRIPT_PREFIX &&
        ((CORE_DEBUG_MINIMAL_LOAD && sSystem != "ef_s_debug" && sSystem != "ef_s_eventman") ||
        FindSubString(sScriptData, "@SKIPSYSTEM") != -1))
    {
        LogInfo("Skipping System: {sSystem}");
        Registry_InsertSkippedSystem(sSystem);
    }

    int nOldHash = Core_GetSystemHash(sSystem);
    int nNewHash = HashString(sScriptData);

    if (nOldHash != nNewHash)
    {
        LogInfo("Parsing System: {sSystem} -> {nOldHash} != {nNewHash}");

        SqlBeginTransactionRegistry();

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

        SqlCommitTransactionRegistry();
    }

    ResetScriptInstructions();
}

int Core_ValidateSystems()
{
    object oModule = GetModule();
    int bValidated = TRUE;
    int bForceRevalidate = Registry_GetInt(REGISTRY_FORCE_REVALIDATE);

    LogInfo("Validating System Data...");

    sqlquery sqlUpdateHash = SqlPrepareQueryRegistry("UPDATE " + REGISTRY_SYSTEMS_TABLE + " SET validated_hash = hash WHERE system = @system;");
    sqlquery sqlGetSystems = SqlPrepareQueryRegistry("SELECT system, scriptdata FROM " + REGISTRY_SYSTEMS_TABLE + " WHERE hash != validated_hash OR @force_revalidate;");
    SqlBindInt(sqlGetSystems, "@force_revalidate", bForceRevalidate);

    while (SqlStep(sqlGetSystems))
    {
        string sSystem = SqlGetString(sqlGetSystems, 0);
        string sScriptData = SqlGetString(sqlGetSystems, 1);
        string sError = ExecuteScriptChunk(sScriptData + " " + nssVoidMain(""),  oModule, FALSE);

        LogInfo("Validating System: {sSystem}");

        if (sError != "")
        {
            bValidated = FALSE;
            LogError("System '{sSystem}' failed to validate with error: {sError}");
        }
        else
        {
            SqlBindString(sqlUpdateHash, "@system", sSystem);
            SqlStepAndReset(sqlUpdateHash);
        }
    }

    ResetScriptInstructions();

    if (bForceRevalidate && bValidated)
        Registry_SetInt(REGISTRY_FORCE_REVALIDATE, FALSE);

    return bValidated;
}

void Core_ExecuteCoreFunction(int nCoreFunctionType)
{
    object oModule = GetModule();
    sqlquery sql = SqlPrepareQueryRegistry("SELECT system, function, data FROM " + REGISTRY_ANNOTATIONS_TABLE + " WHERE annotation = @annotation " +
                                           "AND system NOT IN (SELECT value FROM JSON_EACH(@skipped_systems));");
    SqlBindString(sql, "@annotation", "CORE");
    SqlBindJson(sql, "@skipped_systems", Registry_GetSkippedSystems());
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
