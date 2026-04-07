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
    SqlStep(SqlPrepareQueryModule(sQuery));
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
            sqlquery sql = SqlPrepareQueryModule(sQuery);
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
    struct AnnotationData str;
    object oModule = GetModule();
    sqlquery sqlGetStackLocations = SqlPrepareQueryModule("SELECT name, stack_location FROM vmstack WHERE recursion_level = @recursion_level AND name LIKE @like;");
    SqlBindInt(sqlGetStackLocations, "@recursion_level", GetScriptRecursionLevel());
    SqlBindString(sqlGetStackLocations, "@like", "str.%");
    while (SqlStep(sqlGetStackLocations))
    {
        SetLocalInt(oModule, ANNOTATIONS_STACK_LOCATION + SqlGetString(sqlGetStackLocations, 0), SqlGetInt(sqlGetStackLocations, 1));
    }

    sqlquery sqlParseFunction = SqlPrepareQueryModule("SELECT system, function, data FROM " + ANNOTATIONS_SCRIPT_NAME + " WHERE annotation = @annotation;");
    SqlBindString(sqlParseFunction, "@annotation", "PAD");

    while (SqlStep(sqlParseFunction))
    {
        string sSystem = SqlGetString(sqlParseFunction, 0);
        string sFunction = SqlGetString(sqlParseFunction, 1);
        string sAnnotation = JsonArrayGetString(SqlGetJson(sqlParseFunction, 2), 0);
        string sAnnotationFunction = nssFunction(sFunction, nssFunction("GetAnnotationDataStruct", "", FALSE));

        sqlquery sqlAnnotationData = SqlPrepareQueryModule("SELECT system, function, parameters, return_type, data, raw FROM " + ANNOTATIONS_SCRIPT_NAME + " WHERE annotation = @annotation;");
        SqlBindString(sqlAnnotationData, "@annotation", sAnnotation);

        while (SqlStep(sqlAnnotationData))
        {
            str.sSystem = SqlGetString(sqlAnnotationData, 0);
            str.sFunction = SqlGetString(sqlAnnotationData, 1);
            str.sParameters = SqlGetString(sqlAnnotationData, 2);
            str.sReturnType = SqlGetString(sqlAnnotationData, 3);
            str.jArguments = SqlGetJson(sqlAnnotationData, 4);
            str.sRawAnnotation = SqlGetString(sqlAnnotationData, 5);

            ExecuteScriptChunk(nssInclude(ANNOTATIONS_SCRIPT_NAME) + nssInclude(sSystem) + nssVoidMain(sAnnotationFunction), oModule, FALSE);
            ResetScriptInstructions();
        }
    }

    SqlResetQuery(sqlGetStackLocations);
    while (SqlStep(sqlGetStackLocations))
    {
        DeleteLocalInt(oModule, ANNOTATIONS_STACK_LOCATION + SqlGetString(sqlGetStackLocations, 0));
    }
}

string GetAnnotationStructString(string sVarName)
{
    return NWNX_VM_GetStackStringValue(GetLocalInt(OBJECT_SELF, ANNOTATIONS_STACK_LOCATION + sVarName));
}

json GetAnnotationStructJson(string sVarName)
{
    return NWNX_VM_GetStackJsonValue(GetLocalInt(OBJECT_SELF, ANNOTATIONS_STACK_LOCATION + sVarName));
}

struct AnnotationData GetAnnotationDataStruct()
{
    struct AnnotationData str;
    str.sSystem = GetAnnotationStructString("str.sSystem");
    str.sFunction = GetAnnotationStructString("str.sFunction");
    str.sParameters = GetAnnotationStructString("str.sParameters");
    str.sReturnType = GetAnnotationStructString("str.sReturnType");
    str.jArguments = GetAnnotationStructJson("str.jArguments");
    str.sRawAnnotation = GetAnnotationStructString("str.sRawAnnotation");
    return str;
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
