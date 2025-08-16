/*
    Script: ef_s_debug
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_c_profiler"
#include "ef_c_mediator"
#include "ef_s_eventman"
#include "nwnx_nwsqliteext"

const string DEBUG_SCRIPT_NAME          = "ef_s_debug";
const string DEBUG_DEBUG_SCRIPT_NAME    = "ef_debug";

// @NWNX[NWNX_ON_RESOURCE_MODIFIED]
void Debug_OnResourceModified()
{
    string sAlias = EM_NWNXGetString("ALIAS");
    int nType = EM_NWNXGetInt("TYPE");

    if (sAlias == "NWNX" && nType == RESTYPE_NSS)
    {
        string sScriptName = EM_NWNXGetString("RESREF");

        if (sScriptName == DEBUG_DEBUG_SCRIPT_NAME)
        {
            LogInfo("Changes detected, executing debug script");

            string sScriptChunk = ResManGetFileContents(DEBUG_DEBUG_SCRIPT_NAME, RESTYPE_NSS);

            if (sScriptChunk != "")
            {
                string sResult = ExecuteScriptChunk(sScriptChunk, GetModule(), FALSE);

                if (sResult != "")
                    LogError("Failed to execute debug script, error: " + sResult);
            }
        }
    }
}

int TestFunction(int nTest)
{
    string sString = "Hi!";
    string sClosure = CapturedClosure("{ PrintString(sString); nTest += arg1; string sNestedClosure = MutableClosure(\"{ PrintInteger(nTest); nTest += arg1 * 2; sString = \\\"Yo!\\\"; }\"); Call(sNestedClosure); sString += \" Hello!\"; return sString; }", "&nTest,=sString", "i", "s");
    string sRet = RetString(Call(sClosure, IntArg(5)));
    PrintString("'" + sString + "' != '" + sRet + "'");
    return nTest;
}

// @CORE[CORE_SYSTEM_LOAD]
void Debug_Load()
{
    /*
    string sLambda = Lambda("{ return TestFunction(arg1); }", "i", "i", "ef_s_debug");
    int nRet = RetInt(Call(sLambda, IntArg(5)));
    string sClosure = Closure("{ PrintString(\"The return value is: \" + IntToString(nRet)); }");
    Call(sClosure);
    */
}
