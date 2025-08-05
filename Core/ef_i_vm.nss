/*
    Script: ef_i_vm
    Author: Daz
*/

#include "ef_i_json"
#include "ef_i_nss"
#include "nwnx_vm"

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
string CacheScriptChunk(string sScriptChunk, int bWrapIntoMain = FALSE, int bAlwaysPrecache = FALSE);
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
    string sScriptChunk = nssInclude(sInclude) + nssIntMain(sConstant + ";");
    string sError = ExecuteScriptChunk(sScriptChunk, GetModule(), FALSE);
    return sError == "" ? NWNX_VM_GetScriptReturnValueInt() : nErrorValue;
}

string GetConstantStringValue(string sConstant, string sInclude = "", string sErrorValue = "")
{
    string sScriptChunk = nssInclude(sInclude) + nssStringMain(sConstant + ";");
    string sError = ExecuteScriptChunk(sScriptChunk, GetModule(), FALSE);
    return sError == "" ? NWNX_VM_GetScriptReturnValueString() : sErrorValue;
}

float GetConstantFloatValue(string sConstant, string sInclude = "", float fErrorValue = 0.0f)
{
    string sScriptChunk = nssInclude(sInclude) + nssFloatMain(sConstant + ";");
    string sError = ExecuteScriptChunk(sScriptChunk, GetModule(), FALSE);
    return sError == "" ? NWNX_VM_GetScriptReturnValueFloat() : fErrorValue;
}

json ExecuteScriptChunkAndReturnJson(string sInclude, string sScriptChunk, object oObject)
{
    ExecuteScriptChunk(nssInclude(sInclude) + nssJsonMain(sScriptChunk), oObject, FALSE);
    return NWNX_VM_GetScriptReturnValueJson();
}

int ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject)
{
    ExecuteScriptChunk(nssInclude(sInclude) + nssIntMain(sScriptChunk), oObject, FALSE);
    return NWNX_VM_GetScriptReturnValueInt();
}

void ExecuteScriptChunkAndReturnVoid(string sInclude, string sScriptChunk, object oObject)
{
    string sScript = nssInclude(sInclude) + nssVoidMain(sScriptChunk);
    ExecuteScriptChunk(sScript, oObject, FALSE);
}

string CacheScriptChunk(string sScriptChunk, int bWrapIntoMain = FALSE, int bAlwaysPrecache = FALSE)
{
    string sRetVal;
    if (VM_ENABLE_SCRIPTCHUNK_PRECACHING || bAlwaysPrecache)
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
    NWNX_VM_SetInstructionsExecuted(0);
}
