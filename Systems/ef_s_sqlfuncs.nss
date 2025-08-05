/*
    Script: ef_s_sqlfuncs
    Author: Daz

    @SQLFUNCTION[NAME:ARGUMENTCOUNT:DETERMINISTIC]
*/

#include "ef_i_include"
#include "ef_c_annotations"
#include "ef_c_log"
#include "ef_c_profiler"

const string SQLFUNCTIONS_SCRIPT_NAME   = "ef_s_sqlfuncs";

int SqlFunctions_GetArgInt(int nArg);
float SqlFunctions_GetArgFloat(int nArg);
string SqlFunctions_GetArgString(int nArg);
object SqlFunctions_GetArgObject(int nArg);

// @PAD[SQLFUNCTION]
void SqlFunctions_RegisterFunction(struct AnnotationData str)
{
    if (str.sReturnType != NSS_RETURN_TYPE_INT &&
        str.sReturnType != NSS_RETURN_TYPE_STRING &&
        str.sReturnType != NSS_RETURN_TYPE_FLOAT &&
        str.sReturnType != NSS_RETURN_TYPE_OBJECT)
    {
        LogError("Function '" + str.sSystem + ":" + str.sFunction + "' has an invalid return type!");
        return;
    }

    string sName = GetAnnotationStringConstantValue(str, 0);
    int nArgumentCount = GetAnnotationIntConstantValue(str, 1);
    int bDeterministic = GetAnnotationIntConstantValue(str, 2);

    string sMain;
    int nReturnType;
    if (str.sReturnType == NSS_RETURN_TYPE_INT)
    {
        sMain = nssIntMain(nssFunction(str.sFunction));
        nReturnType = NWNX_NWSQLITEEXTENSIONS_RETURN_TYPE_INT;
    }
    else if (str.sReturnType == NSS_RETURN_TYPE_STRING)
    {
        sMain = nssStringMain(nssFunction(str.sFunction));
        nReturnType = NWNX_NWSQLITEEXTENSIONS_RETURN_TYPE_STRING;
    }
    else if (str.sReturnType == NSS_RETURN_TYPE_FLOAT)
    {
        sMain = nssFloatMain(nssFunction(str.sFunction));
        nReturnType = NWNX_NWSQLITEEXTENSIONS_RETURN_TYPE_FLOAT;
    }
    else if (str.sReturnType == NSS_RETURN_TYPE_OBJECT)
    {
        sMain = nssObjectMain(nssFunction(str.sFunction));
        nReturnType = NWNX_NWSQLITEEXTENSIONS_RETURN_TYPE_OBJECT;
    }

    string sScriptChunk = nssInclude(str.sSystem) + sMain;
    int nRetVal = NWNX_NWSQLiteExtensions_RegisterCustomFunction(sName, sScriptChunk, nArgumentCount, nReturnType, bDeterministic);

    if (nRetVal)
    {
        CacheScriptChunk(sScriptChunk, FALSE, TRUE);
        LogInfo("System '" + str.sSystem + "' registered SQL function '" + str.sFunction + "' with name '" + sName + "'");
    }
    else
    {
        LogWarning("System '" + str.sSystem + "' failed to register SQL function '" + str.sFunction + "' with name '" + sName + "'");
    }
}

int SqlFunctions_GetArgInt(int nArg)
{
    return GetLocalInt(GetModule(), "CF_ARG_" + IntToString(nArg));
}

float SqlFunctions_GetArgFloat(int nArg)
{
    return GetLocalFloat(GetModule(), "CF_ARG_" + IntToString(nArg));
}

string SqlFunctions_GetArgString(int nArg)
{
    return GetLocalString(GetModule(), "CF_ARG_" + IntToString(nArg));
}

object SqlFunctions_GetArgObject(int nArg)
{
    return GetLocalObject(GetModule(), "CF_ARG_" + IntToString(nArg));
}
