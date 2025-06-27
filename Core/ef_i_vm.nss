/*
    Script: ef_i_vm
    Author: Daz

    Description: Equinox Framework VM Utility Include
*/

#include "ef_i_json"
#include "ef_i_nss"
#include "nwnx_util"

const int VM_ENABLE_SCRIPTCHUNK_PRECACHING = FALSE;

struct VMFrame
{
    string sFile;
    string sFunction;
    int nLine;
};

struct VMFrame GetVMFrame(int nDepth = 0);
string GetVMFrameScript(int nDepth = 0);
string GetVMBacktrace(int nDepth = 0);
string VMCompileScript(string sFileName, string sInclude, string sScriptChunk);
int GetConstantIntValue(string sConstant, string sInclude = "", int nErrorValue = 0);
string GetConstantStringValue(string sConstant, string sInclude = "", string sErrorValue = "");
float GetConstantFloatValue(string sConstant, string sInclude = "", float fErrorValue = 0.0f);
json ExecuteScriptChunkAndReturnJson(string sInclude, string sScriptChunk, object oObject);
int ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject);
string CacheScriptChunk(string sScriptChunk, int bWrapIntoMain = FALSE);
void ResetScriptInstructions();

struct VMFrame GetVMFrame(int nDepth = 0)
{
    json jFrame = JsonArrayGet(JsonObjectGet(GetScriptBacktrace(FALSE), "frames"), 1 + nDepth);
    struct VMFrame str;
    str.sFile = JsonObjectGetString(jFrame, "file");
    str.sFunction = JsonObjectGetString(jFrame, "function");
    str.nLine = JsonObjectGetInt(jFrame, "line");
    return str;
}

string GetVMFrameScript(int nDepth = 0)
{
    return JsonObjectGetString(JsonArrayGet(JsonObjectGet(GetScriptBacktrace(FALSE), "frames"), 1 + nDepth), "file");
}

string GetVMBacktrace(int nDepth = 0)
{
    string sBacktrace;
    json jFrames = JsonObjectGet(GetScriptBacktrace(FALSE), "frames");
    int nFrame, nNumFrames = JsonGetLength(jFrames);

    for (nFrame = (1 + nDepth); nFrame < nNumFrames; nFrame++)
    {
        json jFrame = JsonArrayGet(jFrames, nFrame);
        string sFile = JsonObjectGetString(jFrame, "file");
        string sFunction = JsonObjectGetString(jFrame, "function");
        int nLine = JsonObjectGetInt(jFrame, "line");

        sBacktrace += IntToString(nFrame - (1 + nDepth)) + ": " + sFile + "::" + sFunction + ":" + IntToString(nLine) + "\n";

        if (sFunction == "main")
            break;
    }

    return sBacktrace;
}

string VMCompileScript(string sFileName, string sInclude, string sScriptChunk)
{
    return CompileScript(sFileName, nssInclude(sInclude) + nssVoidMain(sScriptChunk), FALSE, TRUE);
}

int GetConstantIntValue(string sConstant, string sInclude = "", int nErrorValue = 0)
{
    object oModule = GetModule();
    string sScriptChunk = nssInclude(sInclude) + nssVoidMain("SetLocalInt(OBJECT_SELF, \"CONVERT_CONSTANT\", " + sConstant + ");");
    string sError = ExecuteScriptChunk(sScriptChunk, oModule, FALSE);
    int nRet = GetLocalInt(oModule, "CONVERT_CONSTANT");
    DeleteLocalInt(oModule, "CONVERT_CONSTANT");
    return sError == "" ? nRet : nErrorValue;
}

string GetConstantStringValue(string sConstant, string sInclude = "", string sErrorValue = "")
{
    object oModule = GetModule();
    string sScriptChunk = nssInclude(sInclude) + nssVoidMain("SetLocalString(OBJECT_SELF, \"CONVERT_CONSTANT\", " + sConstant + ");");
    string sError = ExecuteScriptChunk(sScriptChunk, oModule, FALSE);
    string sRet = GetLocalString(oModule, "CONVERT_CONSTANT");
    DeleteLocalString(oModule, "CONVERT_CONSTANT");
    return sError == "" ? sRet : sErrorValue;
}

float GetConstantFloatValue(string sConstant, string sInclude = "", float fErrorValue = 0.0f)
{
    object oModule = GetModule();
    string sScriptChunk = nssInclude(sInclude) + nssVoidMain("SetLocalFloat(OBJECT_SELF, \"CONVERT_CONSTANT\", " + sConstant + ");");
    string sError = ExecuteScriptChunk(sScriptChunk, oModule, FALSE);
    float fRet = GetLocalFloat(oModule, "CONVERT_CONSTANT");
    DeleteLocalFloat(oModule, "CONVERT_CONSTANT");
    return sError == "" ? fRet : fErrorValue;
}

json ExecuteScriptChunkAndReturnJson(string sInclude, string sScriptChunk, object oObject)
{
    object oModule = GetModule();
    string sScript = nssInclude(sInclude) + nssVoidMain(nssJson("jReturn", sScriptChunk) +
        nssFunction("SetLocalJson", nssFunction("GetModule", "", FALSE) + ", " + nssEscape("EF_TEMP_VAR") + ", jReturn"));
    ExecuteScriptChunk(sScript, oObject, FALSE);
    json jReturn = GetLocalJson(oModule, "EF_TEMP_VAR");
    DeleteLocalJson(oModule, "EF_TEMP_VAR");
    return jReturn;
}

int ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject)
{
    object oModule = GetModule();
    string sScript = nssInclude(sInclude) + nssVoidMain(nssInt("nReturn", sScriptChunk) +
        nssFunction("SetLocalInt", nssFunction("GetModule", "", FALSE) + ", " + nssEscape("EF_TEMP_VAR") + ", nReturn"));
    ExecuteScriptChunk(sScript, oObject, FALSE);
    int nReturn = GetLocalInt(oModule, "EF_TEMP_VAR");
    DeleteLocalInt(oModule, "EF_TEMP_VAR");
    return nReturn;
}

string CacheScriptChunk(string sScriptChunk, int bWrapIntoMain = FALSE)
{
    string sRetVal;
    if (VM_ENABLE_SCRIPTCHUNK_PRECACHING)
    {
        NWNXPushInt(bWrapIntoMain);
        NWNXPushString(sScriptChunk);
        NWNXCall("NWNX_Optimizations", "CacheScriptChunk");
        sRetVal = NWNXPopString();
    }
    return sRetVal;
}

void ResetScriptInstructions()
{
    NWNX_Util_SetInstructionsExecuted(0);
}
