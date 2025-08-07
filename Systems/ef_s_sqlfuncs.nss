/*
    Script: ef_s_sqlfuncs
    Author: Daz

    @SQLFUNCTION[NAME:DETERMINISTIC]
*/

#include "ef_i_include"
#include "ef_c_annotations"
#include "ef_c_log"

const string SQLFUNCTIONS_SCRIPT_NAME   = "ef_s_sqlfuncs";

json SQLFunctions_ParseParameters(struct AnnotationData str)
{
    if (FindSubString(str.sParameters, "=", 0) != -1)
    {
        LogError("Function '" + str.sSystem + ":" + str.sFunction + "' cannot have default arguments.");
        return JsonNull();
    }

    json jRawParameters = RegExpIterate("[^,\\s][^,]*[^,\\s]*|[^,\\s]+", str.sParameters);
    int nIndex, nNumParameters = JsonGetLength(jRawParameters);
    string sArguments;
    for (nIndex = 0; nIndex < nNumParameters; nIndex++)
    {
        string sParameter = JsonArrayGetString(JsonArrayGet(jRawParameters, nIndex), 0);
        string sType = GetStringLeft(sParameter, FindSubString(sParameter, " ", 0));

        if (nIndex)
            sArguments += ",";

        if (sType == NSS_TYPE_INT)
            sArguments += "GetLocalInt(oModule, \"CF_ARG_" + IntToString(nIndex + 1) + "\")";
        else if (sType == NSS_TYPE_STRING)
            sArguments += "GetLocalString(oModule, \"CF_ARG_" + IntToString(nIndex + 1) + "\")";
        else if (sType == NSS_TYPE_FLOAT)
            sArguments += "GetLocalFloat(oModule, \"CF_ARG_" + IntToString(nIndex + 1) + "\")";
        else if (sType == NSS_TYPE_OBJECT)
            sArguments += "GetLocalObject(oModule, \"CF_ARG_" + IntToString(nIndex + 1) + "\")";
        else
        {
            LogError("Function '" + str.sSystem + ":" + str.sFunction + "' has invalid parameter type: " + sType);
            return JsonNull();
        }
    }

    json jParsedParameters = JsonArray();
    JsonArrayInsertIntInplace(jParsedParameters, nNumParameters);
    JsonArrayInsertStringInplace(jParsedParameters, sArguments);

    return jParsedParameters;
}

// @PAD[SQLFUNCTION]
void SqlFunctions_RegisterFunction(struct AnnotationData str)
{
    if (str.sReturnType != NSS_TYPE_INT &&
        str.sReturnType != NSS_TYPE_STRING &&
        str.sReturnType != NSS_TYPE_FLOAT &&
        str.sReturnType != NSS_TYPE_OBJECT)
    {
        LogError("Function '" + str.sSystem + ":" + str.sFunction + "' has an invalid return type: " + str.sReturnType);
        return;
    }

    json jParsedParameters = SQLFunctions_ParseParameters(str);

    if (!JsonGetType(jParsedParameters))
        return;

    string sName = GetAnnotationStringConstantValue(str, 0);
    int bDeterministic = GetAnnotationIntConstantValue(str, 1);
    int nArgumentCount = JsonArrayGetInt(jParsedParameters, 0);
    string sArguments = JsonArrayGetString(jParsedParameters, 1);
    string sContents = nssObject("oModule", "GetModule()") + " return " + nssFunction(str.sFunction, sArguments);

    string sMain;
    int nReturnType;
    if (str.sReturnType == NSS_TYPE_INT)
    {
        sMain = nssIntMain(sContents, FALSE);
        nReturnType = NWNX_NWSQLITEEXTENSIONS_RETURN_TYPE_INT;
    }
    else if (str.sReturnType == NSS_TYPE_STRING)
    {
        sMain = nssStringMain(sContents, FALSE);
        nReturnType = NWNX_NWSQLITEEXTENSIONS_RETURN_TYPE_STRING;
    }
    else if (str.sReturnType == NSS_TYPE_FLOAT)
    {
        sMain = nssFloatMain(sContents, FALSE);
        nReturnType = NWNX_NWSQLITEEXTENSIONS_RETURN_TYPE_FLOAT;
    }
    else if (str.sReturnType == NSS_TYPE_OBJECT)
    {
        sMain = nssObjectMain(sContents, FALSE);
        nReturnType = NWNX_NWSQLITEEXTENSIONS_RETURN_TYPE_OBJECT;
    }

    string sScriptChunk = nssInclude(str.sSystem) + sMain;
    int nRetVal = NWNX_NWSQLiteExtensions_RegisterCustomFunction(GetStringUpperCase(sName), sScriptChunk, nArgumentCount, nReturnType, bDeterministic);

    if (nRetVal)
    {
        CacheScriptChunk(sScriptChunk, FALSE, TRUE);
        LogInfo("System '" + str.sSystem + "' registered SQL function '" + str.sFunction + "' with name '" + sName + "'");
    }
    else
    {
        LogError("System '" + str.sSystem + "' failed to register SQL function '" + str.sFunction + "' with name '" + sName + "'");
    }
}
