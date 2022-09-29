/*
    Script: ef_s_debug
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_eventman"
#include "ef_s_profiler"

const string DEBUG_LOG_TAG              = "Debug";
const string DEBUG_SCRIPT_NAME          = "ef_s_debug";
const string DEBUG_DEBUG_SCRIPT_NAME    = "ef_debug";

// @NWNX[NWNX_ON_RESOURCE_MODIFIED]
void Debug_OnResourceModified()
{
    string sAlias = EM_GetNWNXString("ALIAS");
    int nType = EM_GetNWNXInt("TYPE");

    if (sAlias == "NWNX" && nType == RESTYPE_NSS)
    {
        string sScriptName = EM_GetNWNXString("RESREF");

        if (sScriptName == DEBUG_DEBUG_SCRIPT_NAME)
        {
            WriteLog(DEBUG_LOG_TAG, "* Changes detected, executing debug script");

            string sScriptChunk = ResManGetFileContents(DEBUG_DEBUG_SCRIPT_NAME, RESTYPE_NSS);

            if (sScriptChunk != "")
            {
                string sResult = ExecuteScriptChunk(sScriptChunk, GetModule(), FALSE);

                if (sResult != "")
                    WriteLog(DEBUG_LOG_TAG, "   > Failed to execute debug script, error: " + sResult);
            }
        }
    }
}

int MyRandom(int i)
{
    return Random(i) + Random(i);
}

// @CORE[EF_SYSTEM_POST]
void Debug_Init()
{
    string sLambda1 = Lambda("{ return MyRandom(arg1); }", "i", "i", "ef_s_debug");
    string sLambda2 = Lambda("{ return RetInt(Call(arg2, IntArg(arg1))); }", "is", "i");
    int a = 100;

    a = RetInt(Call(sLambda2, IntArg(a) + StringArg(sLambda1)));
    PrintString(IntToString(a));

    struct ProfilerData pd = Profiler_Start("NestedLambda");
    a = RetInt(Call(sLambda2, IntArg(a) + StringArg(sLambda1)));
    Profiler_Stop(pd);
    PrintString(IntToString(a));

    pd = Profiler_Start("NestedLambda");
    a = RetInt(Call(sLambda2, IntArg(a) + StringArg(sLambda1)));
    Profiler_Stop(pd);
    PrintString(IntToString(a));
}
