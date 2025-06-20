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
const int EFCORE_PARSE_SYSTEM_FUNCTION_DEFINITIONS      = TRUE;
const int EFCORE_PRECACHE_SYSTEM_FUNCTIONS              = FALSE;

const int EF_SYSTEM_INIT                                = 1;
const int EF_SYSTEM_LOAD                                = 2;
const int EF_SYSTEM_POST                                = 3;

const string EFCORE_SYSTEM_SCRIPT_PREFIX                = "ef_s_";
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
    string sFunction;
    string sParameters;
    string sReturnType;
    json jArguments;
};

void EFCore_InitializeSystemData();
void EFCore_ParseSystem(string sSystem);
int EFCore_ValidateSystems();
void EFCore_ExecuteCoreFunction(int nCoreFunctionType);
void EFCore_ParseAnnotationData();
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

    sQuery = "CREATE TABLE IF NOT EXISTS " + EFCORE_SCRIPT_NAME + "_annotations (" +
             "system TEXT NOT NULL, " +
             "annotation TEXT NOT NULL, " +
             "function TEXT NOT NULL, " +
             "parameters TEXT NOT NULL, " +
             "return_type TEXT NOT NULL, " +
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

    sqlquery sql = SqlPrepareQueryModule("SELECT COUNT(system) FROM " + EFCORE_SCRIPT_NAME + "_systems;");
    if (SqlStep(sql))
        LogInfo("Found " + IntToString(SqlGetInt(sql, 0)) + " Systems...");
}

void EFCore_InsertSystem(string sSystem, string sScriptData)
{
    string sQuery = "INSERT INTO " + EFCORE_SCRIPT_NAME + "_systems(system, scriptdata) VALUES(@system, @scriptdata);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@scriptdata", sScriptData);
    SqlStep(sql);
}

void EFCore_InsertAnnotation(string sSystem, string sAnnotation, string sFunction, string sParameters, string sReturnType, json jData)
{
    string sQuery = "INSERT INTO " + EFCORE_SCRIPT_NAME + "_annotations(system, annotation, function, parameters, return_type, data) " +
                    "VALUES(@system, @annotation, @function, @parameters, @return_type, @data);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@annotation", sAnnotation);
    SqlBindString(sql, "@function", sFunction);
    SqlBindString(sql, "@parameters", sParameters);
    SqlBindString(sql, "@return_type", sReturnType);
    SqlBindJson(sql, "@data", jData);
    SqlStep(sql);
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

int EFCore_ParseAnnotation(string sLine, json jOutAnnotationArray)
{
    if (GetStringLeft(sLine, 4) == "// @" && GetStringRight(sLine, 1) == "]")
    {
        json jMatch = RegExpMatch("(?://\\s@)(\\w+)\\[(.*)\\]", sLine);
        if (JsonGetLength(jMatch))
        {
            json jAnnotation = JsonArray();
            JsonArrayInsertInplace(jAnnotation, JsonArrayGet(jMatch, 1));
            JsonArrayInsertInplace(jAnnotation, JsonArrayGet(jMatch, 2));
            JsonArrayInsertInplace(jOutAnnotationArray, jAnnotation);
            return TRUE;
        }
    }
    return FALSE;
}

int EFCore_ParseFunctionDefinition(string sLine, string sSystem)
{
    if (GetStringRight(sLine, 2) == ");" &&
        (GetStringLeft(sLine, 4) == "void" ||
         GetStringLeft(sLine, 5) == "object" ||
         GetStringLeft(sLine, 3) == "int" ||
         GetStringLeft(sLine, 5) == "string" ||
         GetStringLeft(sLine, 4) == "json" ||
         GetStringLeft(sLine, 5) == "float" ||
         GetStringLeft(sLine, 5) == "vector" ||
         GetStringLeft(sLine, 8) == "location") &&
        FindSubString(sLine, "=", 0) == -1)
    {

        json jMatch = RegExpMatch("(?!.*\\s?(?:action|effect|event|itemproperty|sqlquery|struct|talent|cassowary)\\s?.*)" +
                                  "(void|object|int|float|string|json|vector|location)\\s(\\w+)\\((.*)\\);", sLine);
        if (JsonGetLength(jMatch))
        {
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

            return TRUE;
        }
    }

    return FALSE;
}

void EFCore_ParseSystem(string sSystem)
{
    string sScriptData = ResManGetFileContents(sSystem, RESTYPE_NSS);

    if (FindSubString(sScriptData, "@SKIPSYSTEM") != -1)
        return;

    SqlBeginTransactionModule();

    EFCore_InsertSystem(sSystem, sScriptData);

    struct ParserData str = ParserPrepare(sScriptData, TRUE);
    json jAnnotations = JsonArray();
    int bFoundAnnotations = FALSE;

    while (!(str = ParserParse(str)).bEndOfFile)
    {
        if (!EFCORE_PARSE_SYSTEM_FUNCTION_DEFINITIONS || !EFCore_ParseFunctionDefinition(str.sLine, sSystem))
        {
            while (EFCore_ParseAnnotation(str.sLine, jAnnotations))
            {
                bFoundAnnotations = TRUE;
                str = ParserParse(str);
            }

            if (bFoundAnnotations)
            {
                int bFoundFunction = FALSE;
                if (ParserPeek(str) == "{")
                {
                    json jMatch = RegExpMatch("(\\w+)\\s(\\w*)\\((.*)\\)", str.sLine);
                    if (JsonGetLength(jMatch))
                    {
                        string sReturnType = JsonArrayGetString(jMatch, 1);
                        string sFunction = JsonArrayGetString(jMatch, 2);
                        string sParameters = JsonArrayGetString(jMatch, 3);

                        int nAnnotation, nNumAnnotations = JsonGetLength(jAnnotations);
                        for (nAnnotation = 0; nAnnotation < nNumAnnotations; nAnnotation++)
                        {
                            json jAnnotation = JsonArrayGet(jAnnotations, nAnnotation);
                            string sAnnotation = JsonArrayGetString(jAnnotation, 0);
                            json jData = GetJsonArrayFromTokenizedString(JsonArrayGetString(jAnnotation, 1));
                            EFCore_InsertAnnotation(sSystem, sAnnotation, sFunction, sParameters, sReturnType, jData);
                        }

                        bFoundFunction = TRUE;
                    }
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

void EFCore_ExecuteCoreFunction(int nCoreFunctionType)
{
    object oModule = GetModule();
    sqlquery sql = SqlPrepareQueryModule("SELECT system, function, data FROM " + EFCORE_SCRIPT_NAME + "_annotations WHERE annotation = @annotation;");
    SqlBindString(sql, "@annotation", "CORE");
    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);
        string sFunction = SqlGetString(sql, 1);

        if (GetConstantIntValue(JsonArrayGetString(SqlGetJson(sql, 2), 0), EFCORE_SCRIPT_NAME) == nCoreFunctionType)
        {
            string sError = ExecuteScriptChunk(nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction)), oModule, FALSE);

            if (sError != "")
                LogError("Function '" + sFunction + "' for '" + sSystem + "' failed with error: " + sError);

            EFCore_ResetScriptInstructions();
        }
    }
}

void EFCore_ParseAnnotationData()
{
    object oModule = GetModule();
    sqlquery sqlParseFunction = SqlPrepareQueryModule("SELECT system, function, data FROM " + EFCORE_SCRIPT_NAME + "_annotations WHERE annotation = @annotation;");
    SqlBindString(sqlParseFunction, "@annotation", "PAD");
    while (SqlStep(sqlParseFunction))
    {
        string sSystem = SqlGetString(sqlParseFunction, 0);
        string sFunction = SqlGetString(sqlParseFunction, 1);
        string sAnnotation = JsonArrayGetString(SqlGetJson(sqlParseFunction, 2), 0);

        string sAnnotationFunction = nssFunction(sFunction,
            nssFunction("EFCore_GetAnnotationDataStruct",
            nssFunction("GetLocalJson", "GetModule(), " + nssEscape(EFCORE_ANNOTATION_DATA), FALSE), FALSE));

        sqlquery sqlAnnotationData = SqlPrepareQueryModule("SELECT system, function, parameters, return_type, data FROM " + EFCORE_SCRIPT_NAME + "_annotations WHERE annotation = @annotation;");
        SqlBindString(sqlAnnotationData, "@annotation", sAnnotation);

        while (SqlStep(sqlAnnotationData))
        {
            json jAnnotationData = JsonArray();
            JsonArrayInsertStringInplace(jAnnotationData, SqlGetString(sqlAnnotationData, 0));
            JsonArrayInsertStringInplace(jAnnotationData, SqlGetString(sqlAnnotationData, 1));
            JsonArrayInsertStringInplace(jAnnotationData, SqlGetString(sqlAnnotationData, 2));
            JsonArrayInsertStringInplace(jAnnotationData, SqlGetString(sqlAnnotationData, 3));
            JsonArrayInsertInplace(jAnnotationData, SqlGetJson(sqlAnnotationData, 4));

            SetLocalJson(oModule, EFCORE_ANNOTATION_DATA, jAnnotationData);
            string sError = ExecuteScriptChunk(nssInclude(EFCORE_SCRIPT_NAME) + nssInclude(sSystem) + nssVoidMain(sAnnotationFunction), oModule, FALSE);

            if (sError != "")
                LogError("Function '" + sFunction + "' for '" + sSystem + "' failed with error: " + sError);

            EFCore_ResetScriptInstructions();
        }
    }

    DeleteLocalJson(oModule, EFCORE_ANNOTATION_DATA);
}

struct AnnotationData EFCore_GetAnnotationDataStruct(json jAnnotationData)
{
    struct AnnotationData str;
    str.sSystem = JsonArrayGetString(jAnnotationData, 0);
    str.sFunction = JsonArrayGetString(jAnnotationData, 1);
    str.sParameters = JsonArrayGetString(jAnnotationData, 2);
    str.sReturnType = JsonArrayGetString(jAnnotationData, 3);
    str.jArguments = JsonArrayGet(jAnnotationData, 4);
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
        NWNXPushInt(bWrapIntoMain);
        NWNXPushString(sScriptChunk);
        NWNXCall("NWNX_Optimizations", "CacheScriptChunk");
        sRetVal = NWNXPopString();
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

int GetCallStackDepth(object oFDO = OBJECT_INVALID)
{
    if (oFDO == OBJECT_INVALID) oFDO = GetFunctionsDataObject();
    return GetLocalInt(oFDO, EFCORE_CALLSTACK_DEPTH);
}

int IncrementCallStackDepth(string sFunction, string sReturnType, object oFDO = OBJECT_INVALID)
{
    if (oFDO == OBJECT_INVALID) oFDO = GetFunctionsDataObject();
    int nCallStackDepth = GetLocalInt(oFDO, EFCORE_CALLSTACK_DEPTH);
    SetLocalInt(oFDO, EFCORE_CALLSTACK_DEPTH, ++nCallStackDepth);
    SetLocalString(oFDO, EFCORE_CALLSTACK_FUNCTION + IntToString(nCallStackDepth), sFunction);
    SetLocalString(oFDO, EFCORE_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth), sReturnType);
    return nCallStackDepth;
}

int DecrementCallStackDepth(object oFDO = OBJECT_INVALID)
{
    if (oFDO == OBJECT_INVALID) oFDO = GetFunctionsDataObject();
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

void ClearArgumentCount(object oFDO = OBJECT_INVALID)
{
    if (oFDO == OBJECT_INVALID) oFDO = GetFunctionsDataObject();
    DeleteLocalInt(oFDO, EFCORE_ARGUMENT_COUNT);
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

    if (!EFCORE_PARSE_SYSTEM_FUNCTION_DEFINITIONS && !nLambdaId)
    {
        LogError("Function Parsing Disabled: could not execute '" + sFunction + "'");
        return nCallStackDepth;
    }

    ClearArgumentCount(oFDO);

    if (sFunction != EFCORE_INVALID_FUNCTION || nLambdaId)
    {
        string sParameters = GetLocalString(oFDO, EFCORE_FUNCTION_PARAMETERS + sFunction);
        string sReturnType = GetLocalString(oFDO, EFCORE_FUNCTION_RETURN_TYPE + sFunction);

        if (sParameters == sArgs)
        {
            nCallStackDepth = IncrementCallStackDepth(sFunction, sReturnType, oFDO);
            string sScriptChunk = GetLocalString(oFDO, EFCORE_FUNCTION_SCRIPT_CHUNK + sFunction);
            string sError = ExecuteScriptChunk(sScriptChunk, oTarget, FALSE);
            DecrementCallStackDepth(oFDO);

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
        string sFunctionBody = nssObject("oFDO", nssFunction("GetFunctionsDataObject")) +
            nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "oFDO", FALSE)));

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
