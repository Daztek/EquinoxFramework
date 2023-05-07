/*
    Script: ef_i_core
    Author: Daz

    Description: Core Include for the Equinox Framework
*/

#include "ef_i_array"
#include "ef_i_convert"
#include "ef_i_dataobject"
#include "ef_i_gff"
#include "ef_i_json"
#include "ef_i_log"
#include "ef_i_nss"
#include "ef_i_nui"
#include "ef_i_sqlite"
#include "ef_i_util"
#include "ef_i_vm"

#include "nwnx_admin"
#include "nwnx_util"

const string EFCORE_SCRIPT_NAME                         = "ef_i_core";

const int EFCORE_VALIDATE_SYSTEMS                       = TRUE;
const int EFCORE_SHUTDOWN_ON_VALIDATION_FAILURE         = FALSE;
const int EFCORE_ENABLE_SCRIPTCHUNK_PRECACHING          = FALSE;
const int EFCORE_PARSE_SYSTEM_FUNCTIONS                 = TRUE;
const int EFCORE_PRECACHE_SYSTEM_FUNCTIONS              = FALSE;

const int EF_SYSTEM_INIT                                = 1;
const int EF_SYSTEM_LOAD                                = 2;
const int EF_SYSTEM_POST                                = 3;

const string EFCORE_SYSTEM_SCRIPT_PREFIX                = "ef_s_";
const string EFCORE_ANNOTATIONS_ARRAY                   = "EFCoreAnnotationsArray";
const string EFCORE_ANNOTATION_DATA                     = "EFCoreAnnotationData";

const string EFCORE_INVALID_FUNCTION                    = "EFCoreInvalidFunction";
const string EFCORE_CALLSTACK_DEPTH                     = "EFCoreCallStackDepth";
const string EFCORE_CALLSTACK_FUNCTION                  = "EFCoreCallStackFunction_";
const string EFCORE_CALLSTACK_RETURN_TYPE               = "EFCoreCallStackReturnType_";
const string EFCORE_ARGUMENT_COUNT                      = "EFCoreArgumentCount";
const string EFCORE_ARGUMENT_PREFIX                     = "EFCoreArgument_";
const string EFCORE_RETURN_VALUE_PREFIX                 = "EFCoreReturnValue_";
const string EFCORE_FUNCTION_SCRIPT_CHUNK               = "EFCoreFunctionScriptChunk_";
const string EFCORE_FUNCTION_PARAMETERS                 = "EFCoreFunctionParameters_";
const string EFCORE_FUNCTION_RETURN_TYPE                = "EFCoreFunctionReturnType_";
const string EFCORE_LAMBDA_ID                           = "EFCoreLambdaId_";
const string EFCORE_LAMBDA_FUNCTION                     = "Lambda::";

struct AnnotationData
{
    string sSystem;
    string sAnnotation;
    json jArguments;
    string sReturnType;
    string sFunction;
    string sParameters;
};

void EFCore_InitializeSystemData();
void EFCore_InsertSystem(string sSystem, string sScriptData);
void EFCore_InsertAnnotation(string sAnnotation);
void EFCore_InsertFunction(string sSystem, string sFunction, string sReturnType, string sParameters, string sScriptChunk);
void EFCore_InsertAnnotationData(string sAnnotation, json jData);
int EFCore_GetNumberOfSystems();
json EFCore_GetAnnotationsArray();
void EFCore_ParseSystem(string sSystem);
int EFCore_ValidateSystems();
void EFCore_ParseSystemsForAnnotationData();
void EFCore_ExecuteCoreFunction(int nCoreFunctionType);
void EFCore_ParseAnnotationData();
struct AnnotationData EFCore_GetAnnotationDataStruct(json jAnnotationData);
string EFCore_GetAnnotationString(struct AnnotationData str, int nIndex);
int EFCore_GetAnnotationInt(struct AnnotationData str, int nIndex);
float EFCore_GetAnnotationFloat(struct AnnotationData str, int nIndex);
string EFCore_CacheScriptChunk(string sScriptChunk, int bWrapIntoMain = FALSE);
void EFCore_ResetScriptInstructions();

void EFCore_Initialize()
{
    LogInfo("Starting Equinox Framework...");

    NWNX_Administration_SetPlayerPassword(GetRandomUUID());
    NWNX_Util_SetInstructionLimit(NWNX_Util_GetInstructionLimit() * 64);

    EFCore_InitializeSystemData();

    if (EFCORE_VALIDATE_SYSTEMS && !EFCore_ValidateSystems())
    {
        LogError("System Validation Failure!");

        if (EFCORE_SHUTDOWN_ON_VALIDATION_FAILURE)
            NWNX_Administration_ShutdownServer();

        return;
    }

    EFCore_ParseSystemsForAnnotationData();

    LogInfo("Executing System 'Init' Functions...");
    EFCore_ExecuteCoreFunction(EF_SYSTEM_INIT);
    LogInfo("Parsing Annotation Data...");
    EFCore_ParseAnnotationData();
    LogInfo("Executing System 'Load' Functions...");
    EFCore_ExecuteCoreFunction(EF_SYSTEM_LOAD);
    LogInfo("Executing System 'Post' Functions...");
    EFCore_ExecuteCoreFunction(EF_SYSTEM_POST);

    NWNX_Administration_SetPlayerPassword("");
    NWNX_Util_SetInstructionLimit(-1);
}

void EFCore_InitializeSystemData()
{
    LogInfo("Initializing System Data...");

    string sQuery = "CREATE TABLE IF NOT EXISTS " + EFCORE_SCRIPT_NAME + "_systems (" +
                    "system TEXT NOT NULL, " +
                    "scriptdata TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + EFCORE_SCRIPT_NAME + "_annotationdata (" +
             "annotation TEXT NOT NULL, " +
             "data TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + EFCORE_SCRIPT_NAME + "_functions (" +
             "system TEXT NOT NULL, " +
             "function TEXT NOT NULL, " +
             "returntype TEXT NOT NULL, " +
             "parameters TEXT NOT NULL, " +
             "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    json jSystems = JsonArrayTransform(GetResRefArray(EFCORE_SYSTEM_SCRIPT_PREFIX, RESTYPE_NSS), JSON_ARRAY_SORT_ASCENDING);
    int nSystem, nNumSystems = JsonGetLength(jSystems);
    for (nSystem = 0; nSystem < nNumSystems; nSystem++)
    {
        EFCore_ParseSystem(JsonArrayGetString(jSystems, nSystem));
    }

    LogInfo("Found " + IntToString(EFCore_GetNumberOfSystems()) + " Systems...");
}

void EFCore_InsertSystem(string sSystem, string sScriptData)
{
    string sQuery = "INSERT INTO " + EFCORE_SCRIPT_NAME + "_systems(system, scriptdata) VALUES(@system, @scriptdata);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@scriptdata", sScriptData);
    SqlStep(sql);
}

void EFCore_InsertAnnotation(string sAnnotation)
{
    if (!JsonArrayContainsString(EFCore_GetAnnotationsArray(), sAnnotation))
    {
        LogInfo("Found Annotation: " + sAnnotation);
        InsertStringToLocalJsonArray(GetDataObject(EFCORE_SCRIPT_NAME), EFCORE_ANNOTATIONS_ARRAY, sAnnotation);
    }
}

void EFCore_InsertFunction(string sSystem, string sFunction, string sReturnType, string sParameters, string sScriptChunk)
{
    string sQuery = "INSERT INTO " + EFCORE_SCRIPT_NAME + "_functions(system, function, returntype, parameters, scriptchunk) " +
                    "VALUES(@system, @function, @returntype, @parameters, @scriptchunk);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@function", sFunction);
    SqlBindString(sql, "@returntype", sReturnType);
    SqlBindString(sql, "@parameters", sParameters);
    SqlBindString(sql, "@scriptchunk", sScriptChunk);
    SqlStep(sql);
}

void EFCore_InsertAnnotationData(string sAnnotation, json jData)
{
    string sQuery = "INSERT INTO " + EFCORE_SCRIPT_NAME + "_annotationdata(annotation, data) VALUES(@annotation, @data);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@annotation", sAnnotation);
    SqlBindJson(sql, "@data", jData);
    SqlStep(sql);
}

int EFCore_GetNumberOfSystems()
{
    sqlquery sql = SqlPrepareQueryModule("SELECT COUNT(system) FROM " + EFCORE_SCRIPT_NAME + "_systems;");
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

json EFCore_GetAnnotationsArray()
{
    return GetLocalJsonOrDefault(GetDataObject(EFCORE_SCRIPT_NAME), EFCORE_ANNOTATIONS_ARRAY, JsonArray());
}

void EFCore_ParseSystem(string sSystem)
{
    string sScriptData = ResManGetFileContents(sSystem, RESTYPE_NSS);

    if (FindSubString(sScriptData, "@SKIPSYSTEM") != -1)
    {
        LogInfo("Skipping System: " + sSystem);
        return;
    }

    SqlBeginTransactionModule();

    EFCore_InsertSystem(sSystem, sScriptData);

    // Get annotations
    string sRegex = "(?://\\s@)(\\w+)(?:\\[.*\\])";
    json jMatches = RegExpIterate(sRegex, sScriptData);
    int nMatch, nNumMatches = JsonGetLength(jMatches);
    for(nMatch = 0; nMatch < nNumMatches; nMatch++)
    {
        EFCore_InsertAnnotation(JsonArrayGetString(JsonArrayGet(jMatches, nMatch), 1));
    }

    if (EFCORE_PARSE_SYSTEM_FUNCTIONS)
    {
        json jMatches = RegExpIterate("(?!.*\\s?(?:action|effect|event|itemproperty|sqlquery|struct|talent|cassowary)\\s?.*)" +
                                      "(void|object|int|float|string|json|vector|location)\\s(\\w+)\\((.*)\\);", sScriptData);
        int nMatch, nNumMatches = JsonGetLength(jMatches);
        for(nMatch = 0; nMatch < nNumMatches; nMatch++)
        {
            json jMatch = JsonArrayGet(jMatches, nMatch);
            string sReturnType = nssConvertType(JsonArrayGetString(jMatch, 1));
            string sFunctionName = JsonArrayGetString(jMatch, 2);
            string sRawParameters = JsonArrayGetString(jMatch, 3);
            string sParameters;

            if (sRawParameters != "")
            {
                json jRawParameters = RegExpIterate("(object|int|float|string|json|vector|location)\\s", sRawParameters);
                int nRawParameter, nNumRawParameters = JsonGetLength(jRawParameters);
                for(nRawParameter = 0; nRawParameter < nNumRawParameters; nRawParameter++)
                {
                    sParameters += nssConvertType(JsonArrayGetString(JsonArrayGet(jRawParameters, nRawParameter), 1));
                }
            }

            string sArguments;
            int nArgument, nNumArguments = GetStringLength(sParameters);
            for (nArgument = 0; nArgument < nNumArguments; nArgument++)
            {
                sArguments += (!nArgument ? "" : ", ") +
                    nssFunction("GetLocal" + nssConvertShortType(GetSubString(sParameters, nArgument, 1)),
                        "oFDO, " + nssEscape(EFCORE_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            }

            string sFunctionBody = nssObject("oFDO", nssFunction("GetFunctionsDataObject"));
                sFunctionBody += nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "", FALSE)));

            if (sReturnType != "")
            {
                sFunctionBody += nssFunction("DeleteLocal" + nssConvertShortType(sReturnType),
                                    "oFDO, " + nssEscape(EFCORE_RETURN_VALUE_PREFIX) + "+sCallStackDepth");
                sFunctionBody += nssFunction("SetLocal" + nssConvertShortType(sReturnType),
                                    "oFDO, " + nssEscape(EFCORE_RETURN_VALUE_PREFIX) + "+sCallStackDepth, " + nssFunction(sFunctionName, sArguments, FALSE));
            }
            else
                sFunctionBody += nssFunction(sFunctionName, sArguments);

            string sScriptChunk = nssInclude(EFCORE_SCRIPT_NAME) + nssInclude(sSystem) + nssVoidMain(sFunctionBody);

            if (EFCORE_PRECACHE_SYSTEM_FUNCTIONS)
                EFCore_CacheScriptChunk(sScriptChunk);

            EFCore_InsertFunction(sSystem, sFunctionName, sReturnType, sParameters, sScriptChunk);
        }
    }

    SqlCommitTransactionModule();

    EFCore_ResetScriptInstructions();
}

int EFCore_ValidateSystems()
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

    EFCore_ResetScriptInstructions();

    return bValidated;
}

void EFCore_ParseSystemsForAnnotationData()
{
    json jAnnotations = EFCore_GetAnnotationsArray();
    int nNumAnnotations = JsonGetLength(jAnnotations);
    LogInfo("Parsing Systems for " + IntToString(nNumAnnotations) + " Annotations...");

    SqlBeginTransactionModule();

    sqlquery sqlSystems = SqlPrepareQueryModule("SELECT system, scriptdata FROM " + EFCORE_SCRIPT_NAME + "_systems;");
    while (SqlStep(sqlSystems))
    {
        string sSystem = SqlGetString(sqlSystems, 0);
        string sScriptData = SqlGetString(sqlSystems, 1);

        int nAnnotation;
        for (nAnnotation = 0; nAnnotation < nNumAnnotations; nAnnotation++)
        {
            string sAnnotation = "@(" + JsonArrayGetString(jAnnotations, nAnnotation) + ")\\[(.*)\\][\\n|\\r]+([a-z]+)\\s([\\w]+)\\((.*)\\)";
            json jMatches = RegExpIterate(sAnnotation, sScriptData);

            int nMatch, nNumMatches = JsonGetLength(jMatches);
            for(nMatch = 0; nMatch < nNumMatches; nMatch++)
            {
                json jMatch = JsonArrayGet(jMatches, nMatch);
                     jMatch = JsonArraySetString(jMatch, 0, sSystem);
                     jMatch = JsonArraySet(jMatch, 2, GetJsonArrayFromTokenizedString(JsonArrayGetString(jMatch, 2)));

                EFCore_InsertAnnotationData(JsonArrayGetString(jMatch, 1), jMatch);
            }
        }

        EFCore_ResetScriptInstructions();
    }

    SqlCommitTransactionModule();
}

void EFCore_ExecuteCoreFunction(int nCoreFunctionType)
{
    object oModule = GetModule();
    sqlquery sql = SqlPrepareQueryModule("SELECT data FROM " + EFCORE_SCRIPT_NAME + "_annotationdata WHERE annotation = @annotation;");
    SqlBindString(sql, "@annotation", "CORE");
    while (SqlStep(sql))
    {
        struct AnnotationData str = EFCore_GetAnnotationDataStruct(SqlGetJson(sql, 0));
        if (GetConstantIntValue(JsonArrayGetString(str.jArguments, 0), EFCORE_SCRIPT_NAME) == nCoreFunctionType)
        {
            string sError = ExecuteScriptChunk(nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction)), oModule, FALSE);

            if (sError != "")
                LogError("Function '" + str.sFunction + "' for '" + str.sSystem + "' failed with error: " + sError);

            EFCore_ResetScriptInstructions();
        }
    }
}

void EFCore_ParseAnnotationData()
{
    object oModule = GetModule();
    sqlquery sqlParseFunction = SqlPrepareQueryModule("SELECT data FROM " + EFCORE_SCRIPT_NAME + "_annotationdata WHERE annotation = @annotation;");
    SqlBindString(sqlParseFunction, "@annotation", "PAD");
    while (SqlStep(sqlParseFunction))
    {
        struct AnnotationData str = EFCore_GetAnnotationDataStruct(SqlGetJson(sqlParseFunction, 0));
        string sAnnotation = JsonArrayGetString(str.jArguments, 0);
        string sFunction = nssFunction(str.sFunction,
                               nssFunction("EFCore_GetAnnotationDataStruct",
                                   nssFunction("GetLocalJson", "GetModule(), " + nssEscape(EFCORE_ANNOTATION_DATA), FALSE), FALSE));

        sqlquery sqlAnnotationData = SqlPrepareQueryModule("SELECT data FROM " + EFCORE_SCRIPT_NAME + "_annotationdata WHERE annotation = @annotation;");
        SqlBindString(sqlAnnotationData, "@annotation", sAnnotation);

        while (SqlStep(sqlAnnotationData))
        {
            SetLocalJson(oModule, EFCORE_ANNOTATION_DATA, SqlGetJson(sqlAnnotationData, 0));
            string sError = ExecuteScriptChunk(nssInclude(EFCORE_SCRIPT_NAME) + nssInclude(str.sSystem) + nssVoidMain(sFunction), oModule, FALSE);

            if (sError != "")
                LogError("[" + sAnnotation + "] Function '" + str.sFunction + "' for '" + str.sSystem + "' failed with error: " + sError);

            EFCore_ResetScriptInstructions();
        }
    }

    DeleteLocalJson(oModule, EFCORE_ANNOTATION_DATA);
}

struct AnnotationData EFCore_GetAnnotationDataStruct(json jAnnotationData)
{
    struct AnnotationData str;
    str.sSystem = JsonArrayGetString(jAnnotationData, 0);
    str.sAnnotation = JsonArrayGetString(jAnnotationData, 1);
    str.jArguments = JsonArrayGet(jAnnotationData, 2);
    str.sReturnType = JsonArrayGetString(jAnnotationData, 3);
    str.sFunction = JsonArrayGetString(jAnnotationData, 4);
    str.sParameters = JsonArrayGetString(jAnnotationData, 5);
    return str;
}

string EFCore_GetAnnotationString(struct AnnotationData str, int nIndex)
{
    return GetConstantStringValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetString(str.jArguments, nIndex));
}

int EFCore_GetAnnotationInt(struct AnnotationData str, int nIndex)
{
    return GetConstantIntValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetInt(str.jArguments, nIndex));
}

float EFCore_GetAnnotationFloat(struct AnnotationData str, int nIndex)
{
    return GetConstantFloatValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetFloat(str.jArguments, nIndex));
}

string EFCore_CacheScriptChunk(string sScriptChunk, int bWrapIntoMain = FALSE)
{
    string sRetVal;
    if (EFCORE_ENABLE_SCRIPTCHUNK_PRECACHING)
    {
        NWNX_PushArgumentInt(bWrapIntoMain);
        NWNX_PushArgumentString(sScriptChunk);
        NWNX_CallFunction("NWNX_Optimizations", "CacheScriptChunk");
        sRetVal = NWNX_GetReturnValueString();
    }
    return sRetVal;
}

void EFCore_ResetScriptInstructions()
{
    NWNX_Util_SetInstructionsExecuted(0);
}

// **** Function Stuff

int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF);
string Function(string sSystem, string sFunction);
string Lambda(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "");
string ObjectArg(object oValue);
string IntArg(int nValue);
string FloatArg(float fValue);
string StringArg(string sValue);
string JsonArg(json jValue);
string VectorArg(vector vValue);
string LocationArg(location locValue);
object RetObject(int nCallStackDepth);
int RetInt(int nCallStackDepth);
float RetFloat(int nCallStackDepth);
string RetString(int nCallStackDepth);
json RetJson(int nCallStackDepth);
vector RetVector(int nCallStackDepth);
location RetLocation(int nCallStackDepth);
void RetVoid(int nCallStackDepth);

object GetFunctionsDataObject()
{
    return GetDataObject(EFCORE_SCRIPT_NAME + "_Functions");
}

int GetCallStackDepth()
{
    return GetLocalInt(GetFunctionsDataObject(), EFCORE_CALLSTACK_DEPTH);
}

int IncrementCallStackDepth(string sFunction, string sReturnType)
{
    object oFDO = GetFunctionsDataObject();
    int nCallStackDepth = GetLocalInt(oFDO, EFCORE_CALLSTACK_DEPTH);
    SetLocalInt(oFDO, EFCORE_CALLSTACK_DEPTH, ++nCallStackDepth);
    SetLocalString(oFDO, EFCORE_CALLSTACK_FUNCTION + IntToString(nCallStackDepth), sFunction);
    SetLocalString(oFDO, EFCORE_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth), sReturnType);
    return nCallStackDepth;
}

int DecrementCallStackDepth()
{
    object oFDO = GetFunctionsDataObject();
    int nCallStackDepth = GetLocalInt(oFDO, EFCORE_CALLSTACK_DEPTH);
    SetLocalInt(oFDO, EFCORE_CALLSTACK_DEPTH, --nCallStackDepth);
    return nCallStackDepth;
}

string GetCallStackReturnType(int nCallStackDepth)
{
    return GetLocalString(GetFunctionsDataObject(), EFCORE_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth));
}

string GetCallStackFunction(int nCallStackDepth)
{
    return GetLocalString(GetFunctionsDataObject(), EFCORE_CALLSTACK_FUNCTION + IntToString(nCallStackDepth));
}

void ClearArgumentCount()
{
    DeleteLocalInt(GetFunctionsDataObject(), EFCORE_ARGUMENT_COUNT);
}

int IncrementArgumentCount()
{
    object oFDO = GetFunctionsDataObject();
    int nCount = GetLocalInt(oFDO, EFCORE_ARGUMENT_COUNT);
    SetLocalInt(oFDO, EFCORE_ARGUMENT_COUNT, nCount + 1);
    return nCount;
}

int GetNextLambdaId()
{
    object oFDO = GetFunctionsDataObject();
    int nId = GetLocalInt(oFDO, EFCORE_LAMBDA_ID) + 1;
    SetLocalInt(oFDO, EFCORE_LAMBDA_ID, nId);
    return nId;
}

int GetLambdaIdFromFunction(string sFunction)
{
    int nPrefixLength = GetStringLength(EFCORE_LAMBDA_FUNCTION);
    if (GetStringLeft(sFunction, nPrefixLength) == EFCORE_LAMBDA_FUNCTION)
        return StringToInt(GetStringRight(sFunction, GetStringLength(sFunction) - nPrefixLength));
    return 0;
}

int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF)
{
    object oFDO = GetFunctionsDataObject();
    int nLambdaId = GetLambdaIdFromFunction(sFunction);
    int nCallStackDepth = 0;

    if (!EFCORE_PARSE_SYSTEM_FUNCTIONS && !nLambdaId)
    {
        LogError("Function Parsing Disabled: could not execute '" + sFunction + "'");
        return nCallStackDepth;
    }

    ClearArgumentCount();

    if (sFunction != EFCORE_INVALID_FUNCTION || nLambdaId)
    {
        string sParameters = GetLocalString(oFDO, EFCORE_FUNCTION_PARAMETERS + sFunction);
        string sReturnType = GetLocalString(oFDO, EFCORE_FUNCTION_RETURN_TYPE + sFunction);

        if (sParameters == sArgs)
        {
            nCallStackDepth = IncrementCallStackDepth(sFunction, sReturnType);
            string sScriptChunk = GetLocalString(oFDO, EFCORE_FUNCTION_SCRIPT_CHUNK + sFunction);
            string sError = ExecuteScriptChunk(sScriptChunk, oTarget, FALSE);
            DecrementCallStackDepth();

            if (sError != "")
                LogError("Failed to execute '" + sFunction + "' with error: " + sError);
        }
        else
        {
            LogError("Parameter Mismatch: EXPECTED: '" + sFunction + "(" + sParameters + ")' -> GOT: '"  + sFunction + "(" + sArgs + ")'");
        }
    }
    else
    {
        LogError("Function '" + sFunction + "' does not exist");
    }

    return nCallStackDepth;
}

string Function(string sSystem, string sFunction)
{
    object oFDO = GetFunctionsDataObject();
    string sFunctionSymbol = sSystem + "_" + sFunction;
    string sScriptChunk = GetLocalString(oFDO, EFCORE_FUNCTION_SCRIPT_CHUNK + sFunctionSymbol);

    if (sScriptChunk == "")
    {
        string sQuery = "SELECT returntype, parameters, scriptchunk FROM " + EFCORE_SCRIPT_NAME + "_functions WHERE " +
                        "system = @system AND function = @function;";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindString(sql, "@system", sSystem);
        SqlBindString(sql, "@function", sFunction);

        if (SqlStep(sql))
        {
            SetLocalString(oFDO, EFCORE_FUNCTION_RETURN_TYPE + sFunctionSymbol, SqlGetString(sql, 0));
            SetLocalString(oFDO, EFCORE_FUNCTION_PARAMETERS + sFunctionSymbol, SqlGetString(sql, 1));
            sScriptChunk = SqlGetString(sql, 2);
        }
        else
            sScriptChunk = EFCORE_INVALID_FUNCTION;

        SetLocalString(oFDO, EFCORE_FUNCTION_SCRIPT_CHUNK + sFunctionSymbol, sScriptChunk);
    }

    return sFunctionSymbol;
}

string Lambda(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "")
{
    object oFDO = GetFunctionsDataObject();
    string sHash = IntToString(HashString(sReturnType + sBody + sParameters));
    int nLambdaId = GetLocalInt(oFDO, EFCORE_LAMBDA_ID + sHash);

    if (!nLambdaId)
    {
        nLambdaId = GetNextLambdaId();
        string sLambdaSymbol = EFCORE_LAMBDA_FUNCTION + IntToString(nLambdaId);
        string sArguments, sLambdaParameters;
        int nArgument, nNumArguments = GetStringLength(sParameters);

        sLambdaParameters += "(";
        for (nArgument = 0; nArgument < nNumArguments; nArgument++)
        {
            string sParameter = GetSubString(sParameters, nArgument, 1);
            sArguments += (!nArgument ? "" : ", ") +
                nssFunction("GetLocal" + nssConvertShortType(sParameter),
                    "oFDO, " + nssEscape(EFCORE_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            sLambdaParameters += (!nArgument ? "" : ", ") +
                nssParameter(nssConvertShortType(sParameter, TRUE), "arg" + IntToString(nArgument + 1));
        }
        sLambdaParameters += ")";

        string sLambdaFunction = (sReturnType == "" ? "void " : nssConvertShortType(sReturnType, TRUE) + " ") + "LambdaFunction" + sLambdaParameters + sBody;

        string sFunctionBody = nssObject("oFDO", nssFunction("GetFunctionsDataObject"));
            sFunctionBody += nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "", FALSE)));

        if (sReturnType != "")
        {
            sFunctionBody += nssFunction("DeleteLocal" + nssConvertShortType(sReturnType),
                                "oFDO, " + nssEscape(EFCORE_RETURN_VALUE_PREFIX) + "+sCallStackDepth");
            sFunctionBody += nssFunction("SetLocal" + nssConvertShortType(sReturnType),
                                "oFDO, " + nssEscape(EFCORE_RETURN_VALUE_PREFIX) + "+sCallStackDepth, " + nssFunction("LambdaFunction", sArguments, FALSE));
        }
        else
            sFunctionBody += nssFunction("LambdaFunction", sArguments);

        SetLocalInt(oFDO, EFCORE_LAMBDA_ID + sHash, nLambdaId);

        SetLocalString(oFDO, EFCORE_FUNCTION_RETURN_TYPE + sLambdaSymbol, sReturnType);
        SetLocalString(oFDO, EFCORE_FUNCTION_PARAMETERS + sLambdaSymbol, sParameters);

        string sScriptChunk = nssInclude(EFCORE_SCRIPT_NAME) + nssInclude(sInclude) + sLambdaFunction + nssVoidMain(sFunctionBody);
        SetLocalString(oFDO, EFCORE_FUNCTION_SCRIPT_CHUNK + sLambdaSymbol, sScriptChunk);

        return sLambdaSymbol;
    }

    return EFCORE_LAMBDA_FUNCTION + IntToString(nLambdaId);
}

string ObjectArg(object oValue)
{
    SetLocalObject(GetFunctionsDataObject(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), oValue);
    return "o";
}

string IntArg(int nValue)
{
    SetLocalInt(GetFunctionsDataObject(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), nValue);
    return "i";
}

string FloatArg(float fValue)
{
    SetLocalFloat(GetFunctionsDataObject(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), fValue);
    return "f";
}

string StringArg(string sValue)
{
    SetLocalString(GetFunctionsDataObject(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), sValue);
    return "s";
}

string JsonArg(json jValue)
{
    SetLocalJson(GetFunctionsDataObject(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), jValue);
    return "j";
}

string VectorArg(vector vValue)
{
    SetLocalVector(GetFunctionsDataObject(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), vValue);
    return "v";
}

string LocationArg(location locValue)
{
    SetLocalLocation(GetFunctionsDataObject(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), locValue);
    return "l";
}

int ValidateReturnType(int nCallStackDepth, string sRequestedType)
{
    if (nCallStackDepth == 0)
    {
        LogError("Tried to get return value for an invalid call stack depth");
        return FALSE;
    }

    string sReturnType = GetCallStackReturnType(nCallStackDepth);
    if (sReturnType != sRequestedType)
    {
        LogError("Tried to get return type '" + sRequestedType + "' for function '" +
                 GetCallStackFunction(nCallStackDepth) + "' with return type: " + sReturnType);
        return FALSE;
    }

    return TRUE;
}

object RetObject(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "o"))
        return GetLocalObject(GetFunctionsDataObject(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return OBJECT_INVALID;
}

int RetInt(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "i"))
        return GetLocalInt(GetFunctionsDataObject(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return 0;
}

float RetFloat(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "f"))
        return GetLocalFloat(GetFunctionsDataObject(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return 0.0f;
}

string RetString(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "s"))
        return GetLocalString(GetFunctionsDataObject(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return "";
}

json RetJson(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "j"))
        return GetLocalJson(GetFunctionsDataObject(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return JsonNull();
}

vector RetVector(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "v"))
        return GetLocalVector(GetFunctionsDataObject(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return Vector(0.0f, 0.0f, 0.0f);
}

location RetLocation(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "l"))
        return GetLocalLocation(GetFunctionsDataObject(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return Location(OBJECT_INVALID, Vector(0.0f, 0.0f, 0.0f), 0.0f);
}

void RetVoid(int nCallStackDepth)
{

}
