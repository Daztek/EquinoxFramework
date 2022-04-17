/*
    Script: ef_i_core
    Author: Daz

    Description: Core Include for the Equinox Framework
*/

#include "ef_i_array"
#include "ef_i_nui"
#include "ef_i_sqlite"
#include "ef_i_util"
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
    object oDataObject = GetDataObject(EFCORE_SCRIPT_NAME);
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

