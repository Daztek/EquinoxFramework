/*
    Script: ef_i_vm
    Author: Daz

    Description: Equinox Framework VM Utility Include
*/

#include "ef_i_json"
#include "ef_i_nss"

struct VMFrame
{
    string sFile;
    string sFunction;
    int nLine;
};

// Get a VM frame at nDepth
// 0: Current Function
// 1: Calling Function
struct VMFrame GetVMFrame(int nDepth = 0);
// Get script name of the current frame
string GetVMFrameScript(int nDepth = 0);
// Get a VM backtrace as string
string GetVMBacktrace(int nDepth = 0);
// Convenience  Wrapper around CompileScript
string VMCompileScript(string sFileName, string sInclude, string sScriptChunk);

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
