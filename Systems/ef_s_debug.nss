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
                    LogError("Failed to execute debug script, error: {sResult}");
            }
        }
    }
}

int GetInteger()
{
    return RetInt(Call(GetLocalString(GetModule(), "GetInteger")));
}

void SetInteger(int nValue)
{
    Call(GetLocalString(GetModule(), "SetInteger"), IntArg(nValue));
}

void SomeFunction()
{
    Profiler_Start("SomeFunction");
    SetInteger(GetInteger() + 1);
    PrintString(Profiler_Stop());

    while (GetInteger() < 10)
        SomeFunction();
}

int TestFunction(int nTest)
{
    string sString = "Hi!";
    string sClosure = Closure("{ PrintString(sString); nTest += arg1; string sNestedClosure = Closure(\"{ PrintInteger(nTest); nTest += arg1 * 2; sString = \\\"Yo!\\\"; }\", \"&nTest,&sString,&arg1\"); Call(sNestedClosure); sString += \" Hello!\"; return sString; }", "&nTest,=sString", "i", "s");
    string sRet = RetString(Call(sClosure, IntArg(5)));
    PrintString("'" + sString + "' != '" + sRet + "'");
    return nTest;
}

struct MoreStruct
{
    string sWtf;
    object oSendHelp;
};

struct AnotherStruct
{
    int nFoo;
    struct MoreStruct strOhGod;
    vector vVector;
};

struct TestStruct
{
    object oObject;
    string sString;
    int nInt;
    struct AnotherStruct strAnother;
};

struct StructWithVector
{
    vector vPosition;
    location locStart;
    json jStuff;
};

struct AnotherTestStruct
{
    int nFoo;
    float fBar;
    string sBaz;
    object oQux;
    vector vTest;
    struct StructWithVector strNested;
};

// @CORE[CORE_SYSTEM_LOAD]
void Debug_Load()
{
    int nInteger = 5;
    Profiler_Start("sGetInteger");
    string sGetInteger = Closure("{ return nInteger; }", "&nInteger", "", "i");
    PrintString(Profiler_Stop());
    SetLocalString(GetModule(), "GetInteger", sGetInteger);

    Profiler_Start("sSetInteger");
    string sSetInteger = Closure("{ nInteger = arg1; }", "&nInteger", "i");
    PrintString(Profiler_Stop());
    SetLocalString(GetModule(), "SetInteger", sSetInteger);

    SomeFunction();
    PrintInteger(nInteger);

    string sLambdaClosure = Closure("{ return TestFunction(arg1); }", "", "i", "i", "ef_s_debug");
    int nRet = RetInt(Call(sLambdaClosure, IntArg(7)));
    string sClosure = Closure("{ LogInfo(\"The value is: {nRet}\"); }", "=nRet");
    Call(sClosure);

    string sName = "Daz";
    object oDataObject = GetDataObject(DEBUG_SCRIPT_NAME);
    location loc = GetStartingLocation();

    LogInfo("Hi, my name is {sName} and I like {oDataObject:%ot}. I'm currently at {loc}.");

    struct TestStruct str;
    str.oObject = GetModule();
    str.sString = "Hello!";
    str.nInt = 123;
    str.strAnother.nFoo = 5;
    str.strAnother.strOhGod.sWtf = "Aaaaa";

    LogInfo("{str}");
    LogInfo("{str.strAnother.strOhGod.sWtf}");

    vector vPosition = GetPosition(oDataObject);
    LogInfo("{vPosition}");

    float f = 56.72345;
    LogInfo("{f:%.3f}");

    struct AnotherTestStruct strOriginal;
    strOriginal.nFoo = 5;
    strOriginal.fBar = 2.5f;
    strOriginal.sBaz = "Hello!";
    strOriginal.oQux = GetDataObject(DEBUG_SCRIPT_NAME);
    strOriginal.vTest = GetPosition(strOriginal.oQux);
    strOriginal.strNested.vPosition = Vector(1.0, 2.0, 3.0);
    strOriginal.strNested.locStart = loc;
    strOriginal.strNested.jStuff = JsonObjectSetString(JsonObject(), "key", "value");
    Profiler_Start("StructToJson");
    json jStruct = StructToJson("strOriginal");
    PrintString(Profiler_Stop());
    struct AnotherTestStruct strCopy;
    Profiler_Start("JsonToStruct");
    JsonToStruct("strCopy", jStruct);
    PrintString(Profiler_Stop());
    LogInfo("{strCopy}");
}
