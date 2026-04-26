/*
    Script: ef_c_annotations
    Author: Daz
*/

#include "ef_i_json"
#include "ef_i_sqlite"
#include "ef_i_vm"

const string ANNOTATIONS_SCRIPT_NAME        = "ef_c_annotations";
const string ANNOTATIONS_STACK_LOCATION     = "AnnotationsStackLocation";

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

void Annotations_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + ANNOTATIONS_SCRIPT_NAME + " (" +
                    "system TEXT NOT NULL, " +
                    "annotation TEXT NOT NULL, " +
                    "function TEXT NOT NULL, " +
                    "parameters TEXT NOT NULL, " +
                    "return_type TEXT NOT NULL, " +
                    "data TEXT NOT NULL, " +
                    "raw TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryEF(sQuery));
}

void Annotations_ClearSystemAnnotations(string sSystem)
{
    sqlquery sql = SqlPrepareQueryEF("DELETE FROM " + ANNOTATIONS_SCRIPT_NAME + " WHERE system = @system;");
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

            string sQuery = "INSERT INTO " + ANNOTATIONS_SCRIPT_NAME + "(system, annotation, function, parameters, return_type, data, raw) " +
                            "VALUES(@system, @annotation, @function, @parameters, @return_type, @data, @raw);";
            sqlquery sql = SqlPrepareQueryEF(sQuery);
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

void Annotations_ParseAnnotationData(json jSkippedSystems)
{
    struct AnnotationData strAnnotationData;
    object oModule = GetModule();
    sqlquery sqlParseFunction = SqlPrepareQueryEF("SELECT system, function, data FROM " + ANNOTATIONS_SCRIPT_NAME + " WHERE annotation = @annotation " +
                                                  "AND system NOT IN (SELECT value FROM JSON_EACH(@skipped_systems));");
    SqlBindString(sqlParseFunction, "@annotation", "PAD");
    SqlBindJson(sqlParseFunction, "@skipped_systems", jSkippedSystems);

    while (SqlStep(sqlParseFunction))
    {
        string sSystem = SqlGetString(sqlParseFunction, 0);
        string sFunction = SqlGetString(sqlParseFunction, 1);
        string sAnnotation = JsonArrayGetString(SqlGetJson(sqlParseFunction, 2), 0);
        string sAnnotationFunction = nssFunction(sFunction, nssFunction("GetAnnotationDataStruct", "", FALSE));

        sqlquery sqlAnnotationData = SqlPrepareQueryEF("SELECT system, function, parameters, return_type, data, raw FROM " + ANNOTATIONS_SCRIPT_NAME + " " +
                                                       "WHERE annotation = @annotation AND system NOT IN (SELECT value FROM JSON_EACH(@skipped_systems));");
        SqlBindString(sqlAnnotationData, "@annotation", sAnnotation);
        SqlBindJson(sqlAnnotationData, "@skipped_systems", jSkippedSystems);

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
    }
}

struct AnnotationData GetAnnotationDataStruct()
{
    struct AnnotationData strAnnotationData;
    string sQuery = "UPDATE vmstack AS target SET value = (" +
                        "SELECT source.value FROM vmstack AS source " +
                        "WHERE source.name = target.name AND source.recursion_level = @current_level - 1) " +
                    "WHERE target.recursion_level = @current_level AND target.name LIKE 'strAnnotationData.%';";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@current_level", GetScriptRecursionLevel());
    SqlStep(sql);
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
