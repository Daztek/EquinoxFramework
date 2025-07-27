/*
    Script: ef_i_vm
    Author: Daz
*/

#include "ef_i_json"
#include "ef_i_nss"
#include "nwnx_util"

const string VM_SCRIPT_NAME = "ef_i_vm";
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
void ExecuteScriptChunkAndReturnVoid(string sInclude, string sScriptChunk, object oObject);
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

/*
json ExecuteScriptChunkAndReturnJson(string sInclude, string sScriptChunk, object oObject)
{
    object oModule = GetModule();
    int nDepth = GetLocalInt(oModule, "EF_TEMP_VAR_JSON_DEPTH") + 1;
    SetLocalInt(oModule, "EF_TEMP_VAR_JSON_DEPTH", nDepth);
    string sTempVarName = "EF_TEMP_VAR_JSON_" + IntToString(nDepth);
    string sScript = nssInclude(sInclude) + nssVoidMain(nssJson("jReturn", sScriptChunk) +
        nssFunction("SetLocalJson", nssFunction("GetModule", "", FALSE) + ", " + nssEscape(sTempVarName) + ", jReturn"));
    ExecuteScriptChunk(sScript, oObject, FALSE);
    json jReturn = GetLocalJson(oModule, sTempVarName);
    DeleteLocalJson(oModule, sTempVarName);
    SetLocalInt(oModule, "EF_TEMP_VAR_JSON_DEPTH", GetLocalInt(oModule, "EF_TEMP_VAR_JSON_DEPTH") - 1);
    return jReturn;
}

int ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject)
{
    object oModule = GetModule();
    int nDepth = GetLocalInt(oModule, "EF_TEMP_VAR_INT_DEPTH") + 1;
    SetLocalInt(oModule, "EF_TEMP_VAR_INT_DEPTH", nDepth);
    string sTempVarName = "EF_TEMP_VAR_INT_" + IntToString(nDepth);
    string sScript = nssInclude(sInclude) + nssVoidMain(nssInt("nReturn", sScriptChunk) +
        nssFunction("SetLocalInt", nssFunction("GetModule", "", FALSE) + ", " + nssEscape(sTempVarName) + ", nReturn"));
    DeleteLocalInt(oModule, sTempVarName);
    ExecuteScriptChunk(sScript, oObject, FALSE);
    int nReturn = GetLocalInt(oModule, sTempVarName);
    //DeleteLocalInt(oModule, sTempVarName);
    SetLocalInt(oModule, "EF_TEMP_VAR_INT_DEPTH", GetLocalInt(oModule, "EF_TEMP_VAR_INT_DEPTH") - 1);
    return nReturn;
}
*/

json ExecuteScriptChunkAndReturnJson(string sInclude, string sScriptChunk, object oObject)
{
    object oModule = GetModule();
    json jReturnVars = GetLocalJson(oModule, "JSON_VAR_RETURNS");
    if (!JsonGetType(jReturnVars))
    {
        jReturnVars = JsonArray();
        SetLocalJson(oModule, "JSON_VAR_RETURNS", jReturnVars);
    }
    string sFunction = "json jReturn = " + sScriptChunk + ";JsonArrayInsertInplace(GetLocalJson(GetModule(), \"JSON_VAR_RETURNS\"), jReturn);";
    string sScript = nssInclude(sInclude) + nssVoidMain(sFunction);
    ExecuteScriptChunk(sScript, oObject, FALSE);
    int nIndex = JsonGetLength(jReturnVars) - 1;
    json jRet = JsonArrayGet(jReturnVars, nIndex);
    JsonArrayDelInplace(jReturnVars, nIndex);
    return jRet;
}

int ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject)
{
    object oModule = GetModule();
    json jReturnVars = GetLocalJson(oModule, "INT_VAR_RETURNS");
    if (!JsonGetType(jReturnVars))
    {
        jReturnVars = JsonArray();
        SetLocalJson(oModule, "INT_VAR_RETURNS", jReturnVars);
    }
    string sFunction = "int nReturn = " + sScriptChunk + ";JsonArrayInsertInplace(GetLocalJson(GetModule(), \"INT_VAR_RETURNS\"), JsonInt(nReturn));";
    string sScript = nssInclude(sInclude) + nssVoidMain(sFunction);
    ExecuteScriptChunk(sScript, oObject, FALSE);
    int nIndex = JsonGetLength(jReturnVars) - 1;
    int nRet = JsonArrayGetInt(jReturnVars, nIndex);
    JsonArrayDelInplace(jReturnVars, nIndex);
    return nRet;
}

void ExecuteScriptChunkAndReturnVoid(string sInclude, string sScriptChunk, object oObject)
{
    string sScript = nssInclude(sInclude) + nssVoidMain(sScriptChunk);
    ExecuteScriptChunk(sScript, oObject, FALSE);
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
