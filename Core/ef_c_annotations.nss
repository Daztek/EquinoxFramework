/*
    Script: ef_c_annotations
    Author: Daz
*/

#include "ef_i_sqlite"
#include "ef_i_vm"
#include "ef_c_log"

const string ANNOTATIONS_SCRIPT_NAME        = "ef_c_annotations";
const string ANNOTATIONS_ANNOTATION_DATA    = "AnnotationsAnnotationData";

struct AnnotationData
{
    string sSystem;
    string sFunction;
    string sParameters;
    string sReturnType;
    json jArguments;
};

struct AnnotationData GetAnnotationDataStruct(json jAnnotationData);
string GetAnnotationString(struct AnnotationData str, int nIndex);
int GetAnnotationInt(struct AnnotationData str, int nIndex);
float GetAnnotationFloat(struct AnnotationData str, int nIndex);

void Annotations_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + ANNOTATIONS_SCRIPT_NAME + " (" +
                    "system TEXT NOT NULL, " +
                    "annotation TEXT NOT NULL, " +
                    "function TEXT NOT NULL, " +
                    "parameters TEXT NOT NULL, " +
                    "return_type TEXT NOT NULL, " +
                    "data TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

int Annotations_ParseAnnotation(string sLine, json jOutAnnotationArray)
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
            string sAnnotation = JsonArrayGetString(jAnnotation, 0);
            json jData = GetJsonArrayFromTokenizedString(JsonArrayGetString(jAnnotation, 1));

            string sQuery = "INSERT INTO " + ANNOTATIONS_SCRIPT_NAME + "(system, annotation, function, parameters, return_type, data) " +
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

        return TRUE;
    }
    return FALSE;
}

void Annotations_ParseAnnotationData()
{
    object oModule = GetModule();
    sqlquery sqlParseFunction = SqlPrepareQueryModule("SELECT system, function, data FROM " + ANNOTATIONS_SCRIPT_NAME + " WHERE annotation = @annotation;");
    SqlBindString(sqlParseFunction, "@annotation", "PAD");
    while (SqlStep(sqlParseFunction))
    {
        string sSystem = SqlGetString(sqlParseFunction, 0);
        string sFunction = SqlGetString(sqlParseFunction, 1);
        string sAnnotation = JsonArrayGetString(SqlGetJson(sqlParseFunction, 2), 0);

        string sAnnotationFunction = nssFunction(sFunction,
            nssFunction("GetAnnotationDataStruct",
            nssFunction("GetLocalJson", "GetModule(), " + nssEscape(ANNOTATIONS_ANNOTATION_DATA), FALSE), FALSE));

        sqlquery sqlAnnotationData = SqlPrepareQueryModule("SELECT system, function, parameters, return_type, data FROM " + ANNOTATIONS_SCRIPT_NAME + " WHERE annotation = @annotation;");
        SqlBindString(sqlAnnotationData, "@annotation", sAnnotation);

        while (SqlStep(sqlAnnotationData))
        {
            json jAnnotationData = JsonArray();
            JsonArrayInsertStringInplace(jAnnotationData, SqlGetString(sqlAnnotationData, 0));
            JsonArrayInsertStringInplace(jAnnotationData, SqlGetString(sqlAnnotationData, 1));
            JsonArrayInsertStringInplace(jAnnotationData, SqlGetString(sqlAnnotationData, 2));
            JsonArrayInsertStringInplace(jAnnotationData, SqlGetString(sqlAnnotationData, 3));
            JsonArrayInsertInplace(jAnnotationData, SqlGetJson(sqlAnnotationData, 4));

            SetLocalJson(oModule, ANNOTATIONS_ANNOTATION_DATA, jAnnotationData);
            string sError = ExecuteScriptChunk(nssInclude(ANNOTATIONS_SCRIPT_NAME) + nssInclude(sSystem) + nssVoidMain(sAnnotationFunction), oModule, FALSE);

            if (sError != "")
                LogError("Function '" + sFunction + "' for '" + sSystem + "' failed with error: " + sError);

            ResetScriptInstructions();
        }
    }

    DeleteLocalJson(oModule, ANNOTATIONS_ANNOTATION_DATA);
}

struct AnnotationData GetAnnotationDataStruct(json jAnnotationData)
{
    struct AnnotationData str;
    str.sSystem = JsonArrayGetString(jAnnotationData, 0);
    str.sFunction = JsonArrayGetString(jAnnotationData, 1);
    str.sParameters = JsonArrayGetString(jAnnotationData, 2);
    str.sReturnType = JsonArrayGetString(jAnnotationData, 3);
    str.jArguments = JsonArrayGet(jAnnotationData, 4);
    return str;
}

string GetAnnotationString(struct AnnotationData str, int nIndex)
{
    return GetConstantStringValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetString(str.jArguments, nIndex));
}

int GetAnnotationInt(struct AnnotationData str, int nIndex)
{
    return GetConstantIntValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetInt(str.jArguments, nIndex));
}

float GetAnnotationFloat(struct AnnotationData str, int nIndex)
{
    return GetConstantFloatValue(JsonArrayGetString(str.jArguments, nIndex), str.sSystem, JsonArrayGetFloat(str.jArguments, nIndex));
}
