/*
    Script: ef_c_annotations
    Author: Daz
*/

#include "ef_i_sqlite"
#include "ef_c_registry"
#include "ef_c_profiler"

const string ANNOTATIONS_SCRIPT_NAME        = "ef_c_annotations";

struct AnnotationData
{
    string sSystem;
    string sFunction;
    string sParameters;
    string sReturnType;
    json jArguments;
    string sRawAnnotation;
};

string GetAnnotationString(struct AnnotationData str, int nIndex);
int GetAnnotationInt(struct AnnotationData str, int nIndex);
float GetAnnotationFloat(struct AnnotationData str, int nIndex);
string GetAnnotationStringConstantValue(struct AnnotationData str, int nIndex);
int GetAnnotationIntConstantValue(struct AnnotationData str, int nIndex);
float GetAnnotationFloatConstantValue(struct AnnotationData str, int nIndex);

void Annotations_ClearSystemAnnotations(string sSystem)
{
    sqlquery sql = SqlPrepareQueryRegistry("DELETE FROM " + REGISTRY_ANNOTATIONS_TABLE + " WHERE system = @system;");
    SqlBindString(sql, "@system", sSystem);
    SqlStep(sql);
}

int Annotations_ParseAnnotation(string sLine, json jOutAnnotationArray)
{
    if (GetStringLeft(sLine, 4) == "// @" && GetStringRight(sLine, 1) == "]")
    {
        json jMatch = RegExpMatch("(?://\\s@)(\\w+)\\[(.*)\\]", sLine);
        if (JsonGetLength(jMatch))
        {
            JsonArrayInsertInplace(jOutAnnotationArray, jMatch);
            return TRUE;
        }
    }
    return FALSE;
}

int Annotations_InsertAnnotation(string sSystem, string sLine, json jAnnotations)
{
    json jMatch = RegExpMatch("(\\w+)\\s(\\w*)\\((.*)\\)", sLine);
    if (JsonGetLength(jMatch))
    {
        string sReturnType = JsonArrayGetString(jMatch, 1);
        string sFunction = JsonArrayGetString(jMatch, 2);
        string sParameters = JsonArrayGetString(jMatch, 3);

        int nAnnotation, nNumAnnotations = JsonGetLength(jAnnotations);
        for (nAnnotation = 0; nAnnotation < nNumAnnotations; nAnnotation++)
        {
            json jAnnotation = JsonArrayGet(jAnnotations, nAnnotation);
            string sRawAnnotation = JsonArrayGetString(jAnnotation, 0);
            string sAnnotation = JsonArrayGetString(jAnnotation, 1);
            json jData = GetJsonArrayFromTokenizedString(JsonArrayGetString(jAnnotation, 2));

            string sQuery = "INSERT INTO " + REGISTRY_ANNOTATIONS_TABLE + "(system, annotation, function, parameters, return_type, data, raw) " +
                            "VALUES(@system, @annotation, @function, @parameters, @return_type, @data, @raw);";
            sqlquery sql = SqlPrepareQueryRegistry(sQuery);
            SqlBindString(sql, "@system", sSystem);
            SqlBindString(sql, "@annotation", sAnnotation);
            SqlBindString(sql, "@function", sFunction);
            SqlBindString(sql, "@parameters", sParameters);
            SqlBindString(sql, "@return_type", sReturnType);
            SqlBindJson(sql, "@data", jData);
            SqlBindString(sql, "@raw", sRawAnnotation);
            SqlStep(sql);
        }

        return TRUE;
    }
    return FALSE;
}

void Annotations_ParseAnnotationData()
{
    struct AnnotationData strAnnotationData;
    object oModule = GetModule();
    json jSkippedSystems = Registry_GetSkippedSystems();

    sqlquery sqlTeleportStruct = SqlPrepareQueryModule(
        "UPDATE vmstack AS target SET value = (" +
        "SELECT source.value FROM vmstack AS source " +
        "WHERE source.name = target.name AND source.recursion_level = @current_level AND source.name LIKE 'strAnnotationData.%') " +
        "WHERE target.recursion_level = @current_level + 1 AND target.name LIKE 'strAnnotationData.%';");
    SqlBindInt(sqlTeleportStruct, "@current_level", GetScriptRecursionLevel());
    struct NWNX_VM_StackVariable strStackVariable = NWNX_VM_GetStackVariable("sqlTeleportStruct");
    string sStructFunction = nssFunction("GetAnnotationDataStruct", IntToString(strStackVariable.nStackLocation), FALSE);

    sqlquery sqlParseFunction = SqlPrepareQueryRegistry(
        "SELECT system, function, data FROM " + REGISTRY_ANNOTATIONS_TABLE + " WHERE annotation = @annotation " +
        "AND system NOT IN (SELECT value FROM JSON_EACH(@skipped_systems));");
    SqlBindString(sqlParseFunction, "@annotation", "PAD");
    SqlBindJson(sqlParseFunction, "@skipped_systems", jSkippedSystems);

    sqlquery sqlAnnotationData = SqlPrepareQueryRegistry(
        "SELECT system, function, parameters, return_type, data, raw FROM " + REGISTRY_ANNOTATIONS_TABLE + " " +
        "WHERE annotation = @annotation AND system NOT IN (SELECT value FROM JSON_EACH(@skipped_systems));");
    SqlBindJson(sqlAnnotationData, "@skipped_systems", jSkippedSystems);

    while (SqlStep(sqlParseFunction))
    {
        string sSystem = SqlGetString(sqlParseFunction, 0);
        string sFunction = SqlGetString(sqlParseFunction, 1);
        string sAnnotation = JsonArrayGetString(SqlGetJson(sqlParseFunction, 2), 0);
        string sAnnotationFunction = nssFunction(sFunction, sStructFunction);

        SqlBindString(sqlAnnotationData, "@annotation", sAnnotation);

        while (SqlStep(sqlAnnotationData))
        {
            strAnnotationData.sSystem = SqlGetString(sqlAnnotationData, 0);
            strAnnotationData.sFunction = SqlGetString(sqlAnnotationData, 1);
            strAnnotationData.sParameters = SqlGetString(sqlAnnotationData, 2);
            strAnnotationData.sReturnType = SqlGetString(sqlAnnotationData, 3);
            strAnnotationData.jArguments = SqlGetJson(sqlAnnotationData, 4);
            strAnnotationData.sRawAnnotation = SqlGetString(sqlAnnotationData, 5);

            ExecuteScriptChunk(nssInclude(ANNOTATIONS_SCRIPT_NAME) + nssInclude(sSystem) + nssVoidMain(sAnnotationFunction), oModule, FALSE);
            ResetScriptInstructions();
        }

        SqlResetQuery(sqlAnnotationData);
    }
}

struct AnnotationData GetAnnotationDataStruct(int nStackLocation)
{
    struct AnnotationData strAnnotationData;
    SqlStepAndReset(NWNX_VM_GetStackSqlQueryValue(nStackLocation), FALSE);
    return strAnnotationData;
}

string GetAnnotationString(struct AnnotationData str, int nIndex)
{
    return JsonArrayGetString(str.jArguments, nIndex);
}

int GetAnnotationInt(struct AnnotationData str, int nIndex)
{
    return JsonArrayGetInt(str.jArguments, nIndex);
}

float GetAnnotationFloat(struct AnnotationData str, int nIndex)
{
    return JsonArrayGetFloat(str.jArguments, nIndex);
}

string GetAnnotationStringConstantValue(struct AnnotationData str, int nIndex)
{
    return GetConstantStringValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetString(str.jArguments, nIndex));
}

int GetAnnotationIntConstantValue(struct AnnotationData str, int nIndex)
{
    return GetConstantIntValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetInt(str.jArguments, nIndex));
}

float GetAnnotationFloatConstantValue(struct AnnotationData str, int nIndex)
{
    return GetConstantFloatValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetFloat(str.jArguments, nIndex));
}
