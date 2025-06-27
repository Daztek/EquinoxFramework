/*
    Script: ef_c_core
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_annotations"
#include "ef_c_log"
#include "ef_c_mediator"
#include "nwnx_admin"
#include "nwnx_util"

const string EFCORE_SCRIPT_NAME                         = "ef_c_core";
const int EFCORE_VALIDATE_SYSTEMS                       = TRUE;
const int EFCORE_SHUTDOWN_ON_VALIDATION_FAILURE         = FALSE;

const int EF_SYSTEM_INIT                                = 1;
const int EF_SYSTEM_LOAD                                = 2;
const int EF_SYSTEM_POST                                = 3;

const string EFCORE_CORE_SCRIPT_PREFIX                  = "ef_c_";
const string EFCORE_SYSTEM_SCRIPT_PREFIX                = "ef_s_";

void Core_InitializeSystemData();
void Core_ParseSystem(string sSystem);
int Core_ValidateSystems();
void Core_ExecuteCoreFunction(int nCoreFunctionType);

void Core_Init()
{
    LogInfo("Starting Equinox Framework...");

    NWNX_Administration_SetPlayerPassword(GetRandomUUID());
    NWNX_Util_SetInstructionLimit(NWNX_Util_GetInstructionLimit() * 64);

    Core_InitializeSystemData();

    if (EFCORE_VALIDATE_SYSTEMS && !Core_ValidateSystems())
    {
        LogError("System Validation Failure!");

        if (EFCORE_SHUTDOWN_ON_VALIDATION_FAILURE)
            NWNX_Administration_ShutdownServer();

        return;
    }

    LogInfo("Executing System 'Init' Functions...");
    Core_ExecuteCoreFunction(EF_SYSTEM_INIT);
    LogInfo("Parsing Annotation Data...");
    Annotations_ParseAnnotationData();
    LogInfo("Executing System 'Load' Functions...");
    Core_ExecuteCoreFunction(EF_SYSTEM_LOAD);
    LogInfo("Executing System 'Post' Functions...");
    Core_ExecuteCoreFunction(EF_SYSTEM_POST);

    NWNX_Administration_SetPlayerPassword("");
    NWNX_Util_SetInstructionLimit(-1);
}

void Core_InitializeSystemData()
{
    LogInfo("Initializing System Data...");

    string sQuery = "CREATE TABLE IF NOT EXISTS " + EFCORE_SCRIPT_NAME + "_systems (" +
                    "system TEXT NOT NULL, " +
                    "scriptdata TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    json jSystems = JsonArrayTransform(GetResRefArray(EFCORE_SYSTEM_SCRIPT_PREFIX, RESTYPE_NSS), JSON_ARRAY_SORT_ASCENDING);
    int nSystem, nNumSystems = JsonGetLength(jSystems);
    for (nSystem = 0; nSystem < nNumSystems; nSystem++)
    {
        Core_ParseSystem(JsonArrayGetString(jSystems, nSystem));
    }
}

void Core_InsertSystem(string sSystem, string sScriptData)
{
    string sQuery = "INSERT INTO " + EFCORE_SCRIPT_NAME + "_systems(system, scriptdata) VALUES(@system, @scriptdata);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@scriptdata", sScriptData);
    SqlStep(sql);
}

void Core_ParseSystem(string sSystem)
{
    string sScriptData = ResManGetFileContents(sSystem, RESTYPE_NSS);

    if (FindSubString(sScriptData, "@SKIPSYSTEM") != -1)
        return;

    SqlBeginTransactionModule();

    Core_InsertSystem(sSystem, sScriptData);

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
                    LogWarning("Didn't find a function for the following annotations: " + JsonDump(jAnnotations));
                }

                bFoundAnnotations = FALSE;
                jAnnotations = JsonArray();
            }
        }
    }

    SqlCommitTransactionModule();
}

int Core_ValidateSystems()
{
    object oModule = GetModule();
    int bValidated = TRUE;

    LogInfo("Validating System Data...");

    sqlquery sql = SqlPrepareQueryModule("SELECT system, scriptdata FROM " + EFCORE_SCRIPT_NAME + "_systems;");
    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);
        string sScriptData = SqlGetString(sql, 1);

        string sError = ExecuteScriptChunk(sScriptData + " " + nssVoidMain(""),  oModule, FALSE);

        if (sError != "")
        {
            bValidated = FALSE;
            LogError("System '" + sSystem + "' failed to validate with error: " + sError);
        }
    }

    ResetScriptInstructions();

    return bValidated;
}

void Core_ExecuteCoreFunction(int nCoreFunctionType)
{
    object oModule = GetModule();
    sqlquery sql = SqlPrepareQueryModule("SELECT system, function, data FROM " + ANNOTATIONS_SCRIPT_NAME + " WHERE annotation = @annotation;");
    SqlBindString(sql, "@annotation", "CORE");
    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);
        string sFunction = SqlGetString(sql, 1);
        json jData = SqlGetJson(sql, 2);

        if (GetConstantIntValue(JsonArrayGetString(jData, 0), EFCORE_SCRIPT_NAME) == nCoreFunctionType)
        {
            string sError = ExecuteScriptChunk(nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction)), oModule, FALSE);

            if (sError != "")
                LogError("Function '" + sFunction + "' for '" + sSystem + "' failed with error: " + sError);

            ResetScriptInstructions();
        }
    }
}
