/*
    Script: ef_i_core
    Author: Daz

    Description: Core Include for the Equinox Framework
*/

#include "ef_i_array"
#include "ef_i_nui"
#include "ef_i_sqlite"
#include "ef_i_util"
#include "ef_i_convert"
#include "nwnx_admin"
#include "nwnx_regex"

const string EFCORE_LOG_TAG                             = "Equinox";
const string EFCORE_SCRIPT_NAME                         = "ef_i_core";

const int EFCORE_DISABLE_DEBUG_FAST_START               = TRUE;

const int EFCORE_VALIDATE_SYSTEMS                       = EFCORE_DISABLE_DEBUG_FAST_START;
const int EFCORE_SHUTDOWN_ON_VALIDATION_FAILURE         = FALSE;

const int EFCORE_ENABLE_SCRIPTCHUNK_PRECACHING          = EFCORE_DISABLE_DEBUG_FAST_START;

const int EFCORE_PARSE_SYSTEM_FUNCTIONS                 = EFCORE_DISABLE_DEBUG_FAST_START;
const int EFCORE_PRECACHE_SYSTEM_FUNCTIONS              = FALSE;

const int EF_SYSTEM_INIT                                = 1;
const int EF_SYSTEM_LOAD                                = 2;
const int EF_SYSTEM_POST                                = 3;

const string EFCORE_SYSTEM_SCRIPT_PREFIX                = "ef_s_";
const string EFCORE_ANNOTATION_DATA                     = "EFCoreAnnotationData";

const string EFCORE_CURRENT_FUNCTION                    = "EFCoreCurrentFunction";
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

void EFCore_InitializeSystemData();
void EFCore_InsertSystem(string sSystem, string sScriptData);
void EFCore_InsertAnnotation(string sSystem, string sAnnotation);
void EFCore_InsertFunction(string sSystem, string sFunction, string sReturnType, string sParameters, string sScriptChunk);
void EFCore_InsertAnnotationData(string sAnnotation, json jData);
int EFCore_GetNumberOfSystems();
int EFCore_GetNumberOfAnnotations();
void EFCore_ParseSystem(string sSystem);
int EFCore_ValidateSystems();
void EFCore_ParseSystemsForAnnotationData();
void EFCore_ExecuteCoreFunction(int nCoreFunctionType);
void EFCore_ParseAnnotationData();
string EFCore_CacheScriptChunk(string sScriptChunk, int bWrapIntoMain = FALSE);

void EFCore_Initialize()
{
    WriteLog(EFCORE_LOG_TAG, "* Starting Equinox Framework...");

    NWNX_Administration_SetPlayerPassword(GetRandomUUID());
    NWNX_Util_SetInstructionLimit(NWNX_Util_GetInstructionLimit() * 64);

    EFCore_InitializeSystemData();

    if (EFCORE_VALIDATE_SYSTEMS && !EFCore_ValidateSystems())
    {
        WriteLog(EFCORE_LOG_TAG, "* ERROR: System Validation Failure!");
        
        if (EFCORE_SHUTDOWN_ON_VALIDATION_FAILURE)
            NWNX_Administration_ShutdownServer();

        return;
    }

    EFCore_ParseSystemsForAnnotationData();

    WriteLog(EFCORE_LOG_TAG, "* Executing System 'Init' Functions...");
    EFCore_ExecuteCoreFunction(EF_SYSTEM_INIT);
    WriteLog(EFCORE_LOG_TAG, "* Parsing Annotation Data...");
    EFCore_ParseAnnotationData();
    WriteLog(EFCORE_LOG_TAG, "* Executing System 'Load' Functions...");
    EFCore_ExecuteCoreFunction(EF_SYSTEM_LOAD);
    WriteLog(EFCORE_LOG_TAG, "* Executing System 'Post' Functions...");
    EFCore_ExecuteCoreFunction(EF_SYSTEM_POST);

    NWNX_Administration_SetPlayerPassword("");
    NWNX_Util_SetInstructionLimit(-1);
}

void EFCore_InitializeSystemData()
{
    WriteLog(EFCORE_LOG_TAG, "* Initializing System Data...");
    
    string sQuery = "CREATE TABLE IF NOT EXISTS " + EFCORE_SCRIPT_NAME + "_systems (" +
                    "system TEXT NOT NULL, " +
                    "scriptdata TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + EFCORE_SCRIPT_NAME + "_annotations (" +
             "system TEXT NOT NULL, " +
             "annotation TEXT NOT NULL);";
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

    EFCore_InsertAnnotation(EFCORE_SCRIPT_NAME, "@(CORE)\\[(EF_SYSTEM_[A-Z]+)\\][\\n|\\r]+[a-z]+\\s([\\w]+)\\(");
    EFCore_InsertAnnotation(EFCORE_SCRIPT_NAME, "@(PAD)\\[([\\w]+)\\][\\n|\\r]+[a-z]+\\s([\\w]+)\\(json\\s[\\w]+\\)");
    
    json jSystems = GetResRefArray(RESTYPE_NSS, EFCORE_SYSTEM_SCRIPT_PREFIX + ".*", FALSE);
    int nSystem, nNumSystems = JsonGetLength(jSystems);
    for (nSystem = 0; nSystem < nNumSystems; nSystem++)
    {
        EFCore_ParseSystem(JsonArrayGetString(jSystems, nSystem));
    }

    WriteLog(EFCORE_LOG_TAG, "* Found " + IntToString(EFCore_GetNumberOfSystems()) + " Systems...");
}

void EFCore_InsertSystem(string sSystem, string sScriptData)
{
    string sQuery = "INSERT INTO " + EFCORE_SCRIPT_NAME + "_systems(system, scriptdata) VALUES(@system, @scriptdata);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@scriptdata", sScriptData);
    SqlStep(sql);    
}

void EFCore_InsertAnnotation(string sSystem, string sAnnotation)
{
    string sQuery = "INSERT INTO " + EFCORE_SCRIPT_NAME + "_annotations(system, annotation) VALUES(@system, @annotation);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@annotation", sAnnotation);
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

int EFCore_GetNumberOfAnnotations()
{
    sqlquery sql = SqlPrepareQueryModule("SELECT COUNT(system) FROM " + EFCORE_SCRIPT_NAME + "_annotations;");
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;   
}

void EFCore_ParseSystem(string sSystem)
{
    string sScriptData = NWNX_Util_GetNSSContents(sSystem);

    if (FindSubString(sScriptData, "@SKIPSYSTEM") != -1)
    {
        WriteLog(EFCORE_LOG_TAG, "  > Skipping System: " + sSystem);
        return;
    }

    SqlBeginTransactionModule();

    EFCore_InsertSystem(sSystem, sScriptData);

    // Get annotations
    string sRegex = "@ANNOTATION\\[([\\S]+)\\]";
    json jAnnotations = JsonArray();
    json jMatches = NWNX_Regex_Match(sScriptData, sRegex);
    int nMatch, nNumMatches = JsonGetLength(jMatches);
    for(nMatch = 0; nMatch < nNumMatches; nMatch++)
    {
        EFCore_InsertAnnotation(sSystem, JsonArrayGetString(JsonArrayGet(jMatches, nMatch), 1));      
    }

    if (EFCORE_PARSE_SYSTEM_FUNCTIONS)
    {
        json jMatches = NWNX_Regex_Match(sScriptData, "(?!.*\\s?(?:action|effect|event|itemproperty|sqlquery|struct|talent|cassowary)\\s?.*)" + 
                                                "(void|object|int|float|string|json|vector|location)\\s(\\w+)\\((.*)\\);");
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
                json jRawParameters = NWNX_Regex_Match(sRawParameters, "(object|int|float|string|json|vector|location)\\s");
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
                        "oModule, " + nssEscape(EFCORE_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            }

            string sFunctionBody = nssObject("oModule", nssFunction("GetModule"));
                sFunctionBody += nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "", FALSE)));

            if (sReturnType != "")
            {
                sFunctionBody += nssFunction("DeleteLocal" + nssConvertShortType(sReturnType), 
                                    "oModule, " + nssEscape(EFCORE_RETURN_VALUE_PREFIX) + "+sCallStackDepth");
                sFunctionBody += nssFunction("SetLocal" + nssConvertShortType(sReturnType), 
                                    "oModule, " + nssEscape(EFCORE_RETURN_VALUE_PREFIX) + "+sCallStackDepth, " + nssFunction(sFunctionName, sArguments, FALSE));
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

    NWNX_Util_SetInstructionsExecuted(0);
}

int EFCore_ValidateSystems()
{
    object oModule = GetModule();
    int bValidated = TRUE;

    WriteLog(EFCORE_LOG_TAG, "* Validating System Data...");

    sqlquery sql = SqlPrepareQueryModule("SELECT system, scriptdata FROM " + EFCORE_SCRIPT_NAME + "_systems;");
    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);
        string sScriptData = SqlGetString(sql, 1); 

        string sError = ExecuteCachedScriptChunk(sScriptData + " " + nssVoidMain(""),  oModule, FALSE);

        if (sError != "")
        {
            bValidated = FALSE;
            WriteLog(EFCORE_LOG_TAG, "  > System '" + sSystem + "' failed to validate with error: " + sError);
        }              
    }

    NWNX_Util_SetInstructionsExecuted(0); 

    return bValidated;
}

void EFCore_ParseSystemsForAnnotationData()
{
    WriteLog(EFCORE_LOG_TAG, "* Parsing Systems for " + IntToString(EFCore_GetNumberOfAnnotations()) + " Annotations...");
    
    SqlBeginTransactionModule();
    
    sqlquery sqlSystems = SqlPrepareQueryModule("SELECT system, scriptdata FROM " + EFCORE_SCRIPT_NAME + "_systems;");
    while (SqlStep(sqlSystems))
    {
        string sSystem = SqlGetString(sqlSystems, 0);
        string sScriptData = SqlGetString(sqlSystems, 1); 

        sqlquery sqlAnnotations = SqlPrepareQueryModule("SELECT annotation FROM " + EFCORE_SCRIPT_NAME + "_annotations;");
        while (SqlStep(sqlAnnotations))
        {
            string sAnnotation = SqlGetString(sqlAnnotations, 0);
            json jMatches = NWNX_Regex_Match(sScriptData, sAnnotation);

            int nMatch, nNumMatches = JsonGetLength(jMatches);
            for(nMatch = 0; nMatch < nNumMatches; nMatch++)
            {
                json jMatch = JsonArrayGet(jMatches, nMatch);
                // Replace the full match with the system name
                jMatch = JsonArraySetString(jMatch, 0, sSystem);

                EFCore_InsertAnnotationData(JsonArrayGetString(jMatch, 1), jMatch); 
            }            
        } 

        NWNX_Util_SetInstructionsExecuted(0);           
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
        json jData = SqlGetJson(sql, 0);
        
        if (GetConstantIntValue(JsonArrayGetString(jData, 2), EFCORE_SCRIPT_NAME) == nCoreFunctionType)
        {
            string sSystem = JsonArrayGetString(jData, 0);
            string sFunction = JsonArrayGetString(jData, 3);
            string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));
            string sError = ExecuteCachedScriptChunk(sScriptChunk, oModule, FALSE);

            if (sError != "")
                WriteLog(EFCORE_LOG_TAG, "  > Function '" + sFunction + "' for '" + sSystem + "' failed with error: " + sError);

            NWNX_Util_SetInstructionsExecuted(0);
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
        json jData = SqlGetJson(sqlParseFunction, 0);
        string sSystem = JsonArrayGetString(jData, 0);
        string sAnnotation = JsonArrayGetString(jData, 2);
        string sFunction = nssFunction(JsonArrayGetString(jData, 3), nssFunction("GetLocalJson", "GetModule(), " + nssEscape(EFCORE_ANNOTATION_DATA), FALSE));

        sqlquery sqlAnnotationData = SqlPrepareQueryModule("SELECT data FROM " + EFCORE_SCRIPT_NAME + "_annotationdata WHERE annotation = @annotation;");
        SqlBindString(sqlAnnotationData, "@annotation", sAnnotation);
        
        while (SqlStep(sqlAnnotationData))    
        {
            SetLocalJson(oModule, EFCORE_ANNOTATION_DATA, SqlGetJson(sqlAnnotationData, 0));
            string sError = ExecuteCachedScriptChunk(nssInclude(sSystem) + nssVoidMain(sFunction), oModule, FALSE);

            if (sError != "")
            {
                WriteLog(EFCORE_LOG_TAG, "WARNING: EFCore_ParseAnnotationData() [" + sAnnotation + "] Function '" + sFunction + "' for '" + 
                                        sSystem + "' failed with error: " + sError);
            }

            NWNX_Util_SetInstructionsExecuted(0);
        }        
    }

    DeleteLocalJson(oModule, EFCORE_ANNOTATION_DATA);    
}

string EFCore_CacheScriptChunk(string sScriptChunk, int bWrapIntoMain = FALSE)
{
    return EFCORE_ENABLE_SCRIPTCHUNK_PRECACHING ? NWNX_Optimizations_CacheScriptChunk(sScriptChunk, bWrapIntoMain) : "";
}

// **** Function Stuff

int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF);
string Function(string sSystem, string sFunction);
string ObjectArg(object oValue);
string IntArg(int nValue);
string FloatArg(float fValue);
string StringArg(string sValue);
string JsonArg(json jValue);
string VectorArg(vector vValue);
string LocationArg(location locValue);
string CassowaryArg(cassowary cValue);
object RetObject(int nCallStackDepth);
int RetInt(int nCallStackDepth);
float RetFloat(int nCallStackDepth);
string RetString(int nCallStackDepth);
json RetJson(int nCallStackDepth);
vector RetVector(int nCallStackDepth);
location RetLocation(int nCallStackDepth);
cassowary RetCassowary(int nCallStackDepth);

int GetCallStackDepth()
{
    return GetLocalInt(GetModule(), EFCORE_CALLSTACK_DEPTH);
}

int IncrementCallStackDepth(string sFunction, string sReturnType)
{
    object oModule = GetModule();
    int nCallStackDepth = GetLocalInt(oModule, EFCORE_CALLSTACK_DEPTH);
    SetLocalInt(oModule, EFCORE_CALLSTACK_DEPTH, ++nCallStackDepth);
    SetLocalString(oModule, EFCORE_CALLSTACK_FUNCTION + IntToString(nCallStackDepth), sFunction);
    SetLocalString(oModule, EFCORE_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth), sReturnType);
    return nCallStackDepth;
}

int DecrementCallStackDepth()
{
    object oModule = GetModule();
    int nCallStackDepth = GetLocalInt(oModule, EFCORE_CALLSTACK_DEPTH);
    SetLocalInt(oModule, EFCORE_CALLSTACK_DEPTH, --nCallStackDepth);
    return nCallStackDepth;
}

string GetCallStackReturnType(int nCallStackDepth)
{
    return GetLocalString(GetModule(), EFCORE_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth));
}

string GetCallStackFunction(int nCallStackDepth)
{
    return GetLocalString(GetModule(), EFCORE_CALLSTACK_FUNCTION + IntToString(nCallStackDepth));
}

void ClearArgumentCount()
{
    DeleteLocalInt(GetModule(), EFCORE_ARGUMENT_COUNT);
}

int IncrementArgumentCount()
{
    object oModule = GetModule();
    int nCount = GetLocalInt(oModule, EFCORE_ARGUMENT_COUNT);
    SetLocalInt(oModule, EFCORE_ARGUMENT_COUNT, nCount + 1);
    return nCount;
}

int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF)
{
    object oModule = GetModule();
    string sFunctionSymbol = GetLocalString(oModule, EFCORE_CURRENT_FUNCTION);
    int nCallStackDepth = 0;

    if (!EFCORE_PARSE_SYSTEM_FUNCTIONS)
    {
        WriteLog(EFCORE_LOG_TAG, "WARNING: EFCore::Call() Function Parsing Disabled: could not execute '" + sFunctionSymbol + "'");
        return nCallStackDepth;
    }

    if (sFunction != EFCORE_INVALID_FUNCTION)
    {
        string sParameters = GetLocalString(oModule, EFCORE_FUNCTION_PARAMETERS + sFunctionSymbol);
        string sReturnType = GetLocalString(oModule, EFCORE_FUNCTION_RETURN_TYPE + sFunctionSymbol);

        if (sParameters == sArgs)
        {
            nCallStackDepth = IncrementCallStackDepth(sFunctionSymbol, sReturnType);
            string sError = ExecuteCachedScriptChunk(sFunction, oTarget, FALSE);
            DecrementCallStackDepth();

            if (sError != "")
                WriteLog(EFCORE_LOG_TAG, "ERROR: EFCore::Call() Failed to execute '" + sFunctionSymbol + "' with error: " + sError);
        }
        else
        {
            WriteLog(EFCORE_LOG_TAG, "ERROR: EFCore::Call() Parameter Mismatch: EXPECTED: '" + sFunctionSymbol + "(" + sParameters + 
                                     ")' -> GOT: '"  + sFunctionSymbol + "(" + sArgs + ")'");
        }
    }
    else
    {
        WriteLog(EFCORE_LOG_TAG, "ERROR: EFCore::Call() Function '" + sFunctionSymbol + "' does not exist");
    }

    return nCallStackDepth;
}

string Function(string sSystem, string sFunction)
{
    object oModule = GetModule();
    string sFunctionSymbol = sSystem + "::" + sFunction;
    string sScriptChunk = GetLocalString(oModule, EFCORE_FUNCTION_SCRIPT_CHUNK + sFunctionSymbol);

    if (sScriptChunk == "")
    {
        string sQuery = "SELECT returntype, parameters, scriptchunk FROM " + EFCORE_SCRIPT_NAME + "_functions WHERE " +
                        "system = @system AND function = @function;";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindString(sql, "@system", sSystem);
        SqlBindString(sql, "@function", sFunction);                        
        
        if (SqlStep(sql))
        {
            SetLocalString(oModule, EFCORE_FUNCTION_RETURN_TYPE + sFunctionSymbol, SqlGetString(sql, 0));            
            SetLocalString(oModule, EFCORE_FUNCTION_PARAMETERS + sFunctionSymbol, SqlGetString(sql, 1));
            sScriptChunk = SqlGetString(sql, 2);
        }
        else
            sScriptChunk = EFCORE_INVALID_FUNCTION;

        SetLocalString(oModule, EFCORE_FUNCTION_SCRIPT_CHUNK + sFunctionSymbol, sScriptChunk);
    }

    SetLocalString(oModule, EFCORE_CURRENT_FUNCTION, sFunctionSymbol);
    ClearArgumentCount();

    return sScriptChunk;
}

string ObjectArg(object oValue)
{
    SetLocalObject(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), oValue);
    return "o";
}

string IntArg(int nValue)
{
    SetLocalInt(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), nValue);
    return "i";
}

string FloatArg(float fValue)
{
    SetLocalFloat(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), fValue);
    return "f";
}

string StringArg(string sValue)
{
    SetLocalString(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), sValue);
    return "s";
}

string JsonArg(json jValue)
{
    SetLocalJson(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), jValue);
    return "j";
}

string VectorArg(vector vValue)
{
    SetLocalVector(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), vValue);
    return "v";
}

string LocationArg(location locValue)
{
    SetLocalLocation(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), locValue);
    return "l";
}

int ValidateReturnType(int nCallStackDepth, string sRequestedType)
{
    if (nCallStackDepth == 0)
    {
        WriteLog(EFCORE_LOG_TAG, "WARNING: (" + NWNX_Util_GetCurrentScriptName() + ") Tried to get return value for an invalid call stack depth");
        return FALSE;
    }

    string sReturnType = GetCallStackReturnType(nCallStackDepth);
    if (sReturnType != sRequestedType)
    {
        WriteLog(EFCORE_LOG_TAG, "WARNING: (" + NWNX_Util_GetCurrentScriptName() + ") Tried to get return type '" + sRequestedType + "' for function '" + 
                                 GetCallStackFunction(nCallStackDepth) + "' with return type: " + sReturnType);
        return FALSE;
    }

    return TRUE;
}

object RetObject(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "o"))
        return GetLocalObject(GetModule(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return OBJECT_INVALID;
}

int RetInt(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "i"))
        return GetLocalInt(GetModule(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return 0;
}

float RetFloat(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "f"))
        return GetLocalFloat(GetModule(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return 0.0f;
}

string RetString(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "s"))
        return GetLocalString(GetModule(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return "";
}

json RetJson(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "j"))
        return GetLocalJson(GetModule(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return JsonNull();
}

vector RetVector(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "v"))
        return GetLocalVector(GetModule(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return Vector(0.0f, 0.0f, 0.0f);
}

location RetLocation(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "l"))
        return GetLocalLocation(GetModule(), EFCORE_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return Location(OBJECT_INVALID, Vector(0.0f, 0.0f, 0.0f), 0.0f);
}

