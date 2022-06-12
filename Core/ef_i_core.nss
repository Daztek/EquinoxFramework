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
#include "nwnx_regex"

//void main() {}

const string EFCORE_LOG_TAG                             = "Equinox";
const string EFCORE_SCRIPT_NAME                         = "ef_i_core";

const string EFCORE_SYSTEM_SCRIPT_PREFIX                = "ef_s_";
const string EFCORE_SYSTEM_OBJECT                       = "Systems";
const string EFCORE_ANNOTATION_ARRAY                    = "Annotations";
const string EFCORE_ANNOTATION_DATA_OBJECT              = "AnnotationData";

const int EF_SYSTEM_INIT                                = 1;
const int EF_SYSTEM_LOAD                                = 2;
const int EF_SYSTEM_POST                                = 3;

json EFCore_GetSystems();
void EFCore_InsertSystem(json jSystem);
json EFCore_GetAnnotations();
void EFCore_InsertAnnotation(json jAnnotation);
void EFCore_InitSystemData();
json EFCore_GetSystem(string sSystem);
json EFCore_GetAnnotationData(string sKey = "");
void EFCore_InsertAnnotationData(string sKey, json jData);
void EFCore_ParseSystemsForAnnotations();
void EFCore_ExecuteFunctions(int nCoreFunctionType);
void EFCore_ExecuteFunctionOnAnnotationData(string sSystem, string sAnnotationData, string sFunction);

void EFCore_Initialize()
{
    WriteLog(EFCORE_LOG_TAG, "* Starting Equinox Framework...");

    NWNX_Util_SetInstructionLimit(NWNX_Util_GetInstructionLimit() * 64);

    EFCore_InsertAnnotation(JsonString("@(CORE)\\[(EF_SYSTEM_[A-Z]+)\\][\\n|\\r]+[a-z]+\\s([\\w]+)\\("));

    EFCore_InitSystemData();
    EFCore_ParseSystemsForAnnotations();

    WriteLog(EFCORE_LOG_TAG, "* Executing System 'Init' Functions");
    EFCore_ExecuteFunctions(EF_SYSTEM_INIT);
    WriteLog(EFCORE_LOG_TAG, "* Executing System 'Load' Functions");
    EFCore_ExecuteFunctions(EF_SYSTEM_LOAD);
    WriteLog(EFCORE_LOG_TAG, "* Executing System 'Post' Functions");
    EFCore_ExecuteFunctions(EF_SYSTEM_POST);

    NWNX_Optimizations_FlushCachedChunks();
    NWNX_Util_SetInstructionLimit(-1);
}

json EFCore_GetSystems()
{
    return GetLocalJsonOrDefault(GetDataObject(EFCORE_SCRIPT_NAME), EFCORE_SYSTEM_OBJECT, JsonObject());
}

void EFCore_InsertSystem(json jSystem)
{
    json jSystems = EFCore_GetSystems();
    jSystems = JsonObjectSet(jSystems, JsonObjectGetString(jSystem, "system"), jSystem);
    SetLocalJson(GetDataObject(EFCORE_SCRIPT_NAME), EFCORE_SYSTEM_OBJECT, jSystems);
}

json EFCore_GetAnnotations()
{
    return GetLocalJsonArray(GetDataObject(EFCORE_SCRIPT_NAME), EFCORE_ANNOTATION_ARRAY);
}

void EFCore_InsertAnnotation(json jAnnotation)
{
    json jAnnotations = JsonArrayInsert(EFCore_GetAnnotations(), jAnnotation);
    SetLocalJson(GetDataObject(EFCORE_SCRIPT_NAME), EFCORE_ANNOTATION_ARRAY, jAnnotations);
}

void EFCore_InitSystemData()
{
    json jSystems = GetResRefArray(RESTYPE_NSS, EFCORE_SYSTEM_SCRIPT_PREFIX + ".*", FALSE);
    int nSystem, nNumSystems = JsonGetLength(jSystems);

    for (nSystem = 0; nSystem < nNumSystems; nSystem++)
    {
        EFCore_GetSystem(JsonArrayGetString(jSystems, nSystem));
    }

    nNumSystems = JsonGetLength(EFCore_GetSystems());
    WriteLog(EFCORE_LOG_TAG, "* Found " + IntToString(nNumSystems) + " Systems...");
}

json EFCore_GetSystem(string sSystem)
{
    json jSystems = EFCore_GetSystems();
    json jSystem = JsonObjectGet(jSystems, sSystem);

    if (!JsonGetType(jSystem))
    {
        string sScriptData = NWNX_Util_GetNSSContents(sSystem);

        if (FindSubString(sScriptData, "@SKIPSYSTEM") != -1)
        {
            WriteLog(EFCORE_LOG_TAG, "  > Skipping System: " + sSystem);
            return JsonNull();
        }

        jSystem = JsonObject();
        jSystem = JsonObjectSetString(jSystem, "system", sSystem);
        jSystem = JsonObjectSetString(jSystem, "scriptdata", sScriptData);

        // Get annotations
        string sRegex = "@ANNOTATION\\[([\\S]+)\\]";
        json jAnnotations = JsonArray();
        json jMatches = NWNX_Regex_Match(sScriptData, sRegex);
        int nMatch, nNumMatches = JsonGetLength(jMatches);
        for(nMatch = 0; nMatch < nNumMatches; nMatch++)
        {
            json jAnnotation = JsonArrayGet(JsonArrayGet(jMatches, nMatch), 1);
            EFCore_InsertAnnotation(jAnnotation);
            jAnnotations = JsonArrayInsert(jAnnotations, jAnnotation);
        }
        jSystem = JsonObjectSet(jSystem, "annotations", jAnnotations);

        // Get functions
        json jFunctions = JsonObject();
        jMatches = NWNX_Regex_Match(sScriptData, "(?!.*\\s?(?:action|effect|event|itemproperty|sqlquery|struct|talent|cassowary)\\s?.*)(void|object|int|float|string|json|vector|location)\\s(\\w+)\\((.*)\\);");
        nNumMatches = JsonGetLength(jMatches);
        for(nMatch = 0; nMatch < nNumMatches; nMatch++)
        {
            json jMatch = JsonArrayGet(jMatches, nMatch), jFunction = JsonObject();
            string sReturnType = nssConvertType(JsonArrayGetString(jMatch, 1));
            string sFunctionName = JsonArrayGetString(jMatch, 2);
            string sParameters = JsonArrayGetString(jMatch, 3);
            string sParameterTypes;

            if (sParameters != "")
            {
                json jParameters = NWNX_Regex_Match(sParameters, "(object|int|float|string|json|vector|location)\\s");
                int nParameter, nNumParameters = JsonGetLength(jParameters);
                for(nParameter = 0; nParameter < nNumParameters; nParameter++)
                {
                    sParameterTypes += nssConvertType(JsonArrayGetString(JsonArrayGet(jParameters, nParameter), 1));
                }
            }

            jFunction = JsonObjectSetString(jFunction, "return_type", sReturnType);
            jFunction = JsonObjectSetString(jFunction, "parameters", sParameterTypes);
            jFunctions = JsonObjectSet(jFunctions, sFunctionName, jFunction);
        }
        jSystem = JsonObjectSet(jSystem, "functions", jFunctions);

        EFCore_InsertSystem(jSystem);

        NWNX_Util_SetInstructionsExecuted(0);
    }

    return jSystem;
}

json EFCore_GetAnnotationData(string sKey = "")
{
    json jAnnotationData = GetLocalJsonOrDefault(GetDataObject(EFCORE_SCRIPT_NAME), EFCORE_ANNOTATION_DATA_OBJECT, JsonObject());
    return sKey == "" ? jAnnotationData : JsonObjectGetOrDefault(jAnnotationData, sKey, JsonArray());
}

void EFCore_InsertAnnotationData(string sKey, json jData)
{
    json jAnnotationData = EFCore_GetAnnotationData();
    json jKeyArray = JsonObjectGetOrDefault(jAnnotationData, sKey, JsonArray());
    jAnnotationData = JsonObjectSet(jAnnotationData, sKey, JsonArrayInsert(jKeyArray, jData));
    SetLocalJson(GetDataObject(EFCORE_SCRIPT_NAME), EFCORE_ANNOTATION_DATA_OBJECT, jAnnotationData);
}

void EFCore_ParseSystemsForAnnotations()
{
    json jSystems = JsonObjectKeys(EFCore_GetSystems());
    int nSystem, nNumSystems = JsonGetLength(jSystems);
    json jAnnotations = EFCore_GetAnnotations();
    int nAnnotation, nNumAnnotations = JsonGetLength(jAnnotations);

    WriteLog(EFCORE_LOG_TAG, "* Parsing Systems for " + IntToString(nNumAnnotations) + " Annotations...");

    for (nSystem = 0; nSystem < nNumSystems; nSystem++)
    {
        json jSystemName = JsonArrayGet(jSystems, nSystem);
        json jSystem = EFCore_GetSystem(JsonGetString(jSystemName));
        string sScriptData = JsonObjectGetString(jSystem, "scriptdata");

        for (nAnnotation = 0; nAnnotation < nNumAnnotations; nAnnotation++)
        {
            string sAnnotation = JsonArrayGetString(jAnnotations, nAnnotation);
            json jMatches = NWNX_Regex_Match(sScriptData, sAnnotation);

            int nMatch, nNumMatches = JsonGetLength(jMatches);
            for(nMatch = 0; nMatch < nNumMatches; nMatch++)
            {
                json jMatch = JsonArrayGet(jMatches, nMatch);
                // Replace the full match with the system name
                jMatch = JsonArraySet(jMatch, 0, jSystemName);
                EFCore_InsertAnnotationData(JsonArrayGetString(jMatch, 1), jMatch);
            }
        }

        NWNX_Util_SetInstructionsExecuted(0);
    }
}

void EFCore_ExecuteFunctions(int nCoreFunctionType)
{
    object oModule = GetModule();
    json jFunctions = EFCore_GetAnnotationData("CORE");
    int nFunction, nNumFunctions = JsonGetLength(jFunctions);

    for (nFunction = 0; nFunction < nNumFunctions; nFunction++)
    {
        json jFunction = JsonArrayGet(jFunctions, nFunction);
        if (GetConstantIntValue(JsonArrayGetString(jFunction, 2), EFCORE_SCRIPT_NAME) == nCoreFunctionType)
        {
            string sSystem = JsonArrayGetString(jFunction, 0);
            string sFunction = JsonArrayGetString(jFunction, 3);
            string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));
            string sError = ExecuteCachedScriptChunk(sScriptChunk, oModule, FALSE);

            if (sError != "")
                WriteLog(EFCORE_LOG_TAG, "  > Function '" +sFunction + "' for '" + sSystem + "' failed with error: " + sError);

            NWNX_Util_SetInstructionsExecuted(0);
        }
    }
}

void EFCore_ExecuteFunctionOnAnnotationData(string sSystem, string sAnnotation, string sFunction)
{
    object oModule = GetModule();
    json jAnnotationData = EFCore_GetAnnotationData(sAnnotation);
    int nData, nNumData = JsonGetLength(jAnnotationData);
    string sError;
    int bPrintError = FALSE;

    sFunction = NWNX_Regex_Replace(sFunction, "\\{DATA\\}", nssFunction("GetLocalJson", "GetModule(), " + nssEscape("EF_ANNOTATION_DATA"), FALSE));

    for (nData = 0; nData < nNumData; nData++)
    {
        SetLocalJson(oModule, "EF_ANNOTATION_DATA", JsonArrayGet(jAnnotationData, nData));
        sError = ExecuteCachedScriptChunk(nssInclude(sSystem) + nssVoidMain(sFunction), oModule, FALSE);

        if (sError != "")
            bPrintError = TRUE;

        NWNX_Util_SetInstructionsExecuted(0);
    }

    DeleteLocalJson(oModule, "EF_ANNOTATION_DATA");

    if (bPrintError)
        WriteLog(EFCORE_LOG_TAG, "(ExecuteFunctionOnAnnotationData) [" + sAnnotation + "] Function '" +sFunction + "' for '" + sSystem + "' failed with error: " + sError);
}

// **** Function Stuff

const string EFCORE_CURRENT_FUNCTION        = "EFCoreCurrentFunction";
const string EFCORE_INVALID_FUNCTION        = "EFCoreInvalidFunction";
const string EFCORE_CALLSTACK_DEPTH         = "EFCoreCallStackDepth";
const string EFCORE_CALLSTACK_FUNCTION      = "EFCoreCallStackFunction_";
const string EFCORE_CALLSTACK_RETURN_TYPE   = "EFCoreCallStackReturnType_";
const string EFCORE_ARGUMENT_COUNT          = "EFCoreArgumentCount";
const string EFCORE_ARGUMENT_PREFIX         = "EFCoreArgument_";
const string EFCORE_RETURN_VALUE_PREFIX     = "EFCoreReturnValue_";
const string EFCORE_FUNCTION_SCRIPT_CHUNK   = "EFCoreFunctionScriptChunk_";
const string EFCORE_FUNCTION_PARAMETERS     = "EFCoreFunctionParameters_";
const string EFCORE_FUNCTION_RETURN_TYPE    = "EFCoreFunctionReturnType_";

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

int GetArgumentCount()
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
                WriteLog(EFCORE_LOG_TAG, "ERROR: (" + NWNX_Util_GetCurrentScriptName() + ") failed to execute '" + sFunctionSymbol + "' with error: " + sError);
        }
        else
        {
            WriteLog(EFCORE_LOG_TAG, "ERROR: (" + NWNX_Util_GetCurrentScriptName() + ") Parameter Mismatch: EXPECTED: '" + sFunctionSymbol + "(" + sParameters + ")' -> GOT: '"  + sFunctionSymbol + "(" + sArgs + ")'");
        }
    }
    else
    {
        WriteLog(EFCORE_LOG_TAG, "ERROR: (" + NWNX_Util_GetCurrentScriptName() + ") Function '" + sFunctionSymbol + "' does not exist");
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
        json jFunction = JsonObjectGet(JsonObjectGet(EFCore_GetSystem(sSystem), "functions"), sFunction);

        if (!JsonGetType(jFunction))
            sScriptChunk = EFCORE_INVALID_FUNCTION;
        else
        {
            string sArguments, sParameters = JsonObjectGetString(jFunction, "parameters");
            int nArgument, nNumArguments = GetStringLength(sParameters);
            for (nArgument = 0; nArgument < nNumArguments; nArgument++)
            {
                sArguments += (!nArgument ? "" : ", ") + nssFunction("GetLocal" + nssConvertShortType(GetSubString(sParameters, nArgument, 1)), "oModule, " + nssEscape(EFCORE_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            }

            string sReturnType = JsonObjectGetString(jFunction, "return_type");
            string sFunctionBody = nssObject("oModule", nssFunction("GetModule"));
                   sFunctionBody += nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "", FALSE)));

            if (sReturnType != "")
            {
                sFunctionBody += nssFunction("DeleteLocal" + nssConvertShortType(sReturnType), "oModule, " + nssEscape(EFCORE_RETURN_VALUE_PREFIX) + "+sCallStackDepth");
                sFunctionBody += nssFunction("SetLocal" + nssConvertShortType(sReturnType), "oModule, " + nssEscape(EFCORE_RETURN_VALUE_PREFIX) + "+sCallStackDepth, " + nssFunction(sFunction, sArguments, FALSE));
            }
            else
                sFunctionBody += nssFunction(sFunction, sArguments);

            sScriptChunk = nssInclude(EFCORE_SCRIPT_NAME) + nssInclude(sSystem) + nssVoidMain(sFunctionBody);

            SetLocalString(oModule, EFCORE_FUNCTION_PARAMETERS + sFunctionSymbol, sParameters);
            SetLocalString(oModule, EFCORE_FUNCTION_RETURN_TYPE + sFunctionSymbol, sReturnType);
        }

        SetLocalString(oModule, EFCORE_FUNCTION_SCRIPT_CHUNK + sFunctionSymbol, sScriptChunk);
    }

    SetLocalString(oModule, EFCORE_CURRENT_FUNCTION, sFunctionSymbol);
    ClearArgumentCount();

    return sScriptChunk;
}

string ObjectArg(object oValue)
{
    SetLocalObject(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(GetArgumentCount()), oValue);
    return "o";
}

string IntArg(int nValue)
{
    SetLocalInt(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(GetArgumentCount()), nValue);
    return "i";
}

string FloatArg(float fValue)
{
    SetLocalFloat(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(GetArgumentCount()), fValue);
    return "f";
}

string StringArg(string sValue)
{
    SetLocalString(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(GetArgumentCount()), sValue);
    return "s";
}

string JsonArg(json jValue)
{
    SetLocalJson(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(GetArgumentCount()), jValue);
    return "j";
}

string VectorArg(vector vValue)
{
    SetLocalVector(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(GetArgumentCount()), vValue);
    return "v";
}

string LocationArg(location locValue)
{
    SetLocalLocation(GetModule(), EFCORE_ARGUMENT_PREFIX + IntToString(GetArgumentCount()), locValue);
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
        WriteLog(EFCORE_LOG_TAG, "WARNING: (" + NWNX_Util_GetCurrentScriptName() + ") Tried to get return type '" + sRequestedType + "' for function '" + GetCallStackFunction(nCallStackDepth) + "' with return type: " + sReturnType);
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

