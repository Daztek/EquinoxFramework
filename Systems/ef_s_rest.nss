/*
    Script: ef_s_rest
    Author: Daz

    // @ REST[REST_EVENTTYPE_REST_*]
    @ANNOTATION[@(REST)\[(REST_EVENTTYPE_REST_STARTED|REST_EVENTTYPE_REST_FINISHED|REST_EVENTTYPE_REST_CANCELLED)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

//void main() {}

#include "ef_i_core"

const string REST_LOG_TAG                   = "Rest";
const string REST_SCRIPT_NAME               = "ef_s_rest";
const string REST_FUNCTIONS_ARRAY_PREFIX    = "FunctionsArray_";

// @CORE[EF_SYSTEM_INIT]
void GuiEvent_Init()
{
    EFCore_ExecuteFunctionOnAnnotationData(REST_SCRIPT_NAME, "REST", "Rest_RegisterFunction({DATA});");
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_PLAYER_REST]
void Rest_OnPlayerRest()
{
    object oPlayer = GetLastPCRested();
    int nRestEventType = GetLastRestEventType();

    if (nRestEventType != REST_EVENTTYPE_REST_INVALID)
    {
        json jFunctions = GetLocalJsonArray(GetDataObject(REST_SCRIPT_NAME), REST_FUNCTIONS_ARRAY_PREFIX + IntToString(nRestEventType));
        int nFunction, nNumFunctions = JsonGetLength(jFunctions);

        for (nFunction = 0; nFunction < nNumFunctions; nFunction++)
        {
            string sScriptChunk = JsonArrayGetString(jFunctions, nFunction);
            if (sScriptChunk != "")
                ExecuteCachedScriptChunk(sScriptChunk, oPlayer, FALSE);
        }
    }
}

void Rest_RegisterFunction(json jRestFunction)
{
    string sSystem = JsonArrayGetString(jRestFunction, 0);
    string sRestEventTypeConstant = JsonArrayGetString(jRestFunction, 2);
    int nRestEventType = GetConstantIntValue(sRestEventTypeConstant);
    string sFunction = JsonArrayGetString(jRestFunction, 3);
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));

    InsertStringToLocalJsonArray(GetDataObject(REST_SCRIPT_NAME), REST_FUNCTIONS_ARRAY_PREFIX + IntToString(nRestEventType), sScriptChunk);
    WriteLog(REST_LOG_TAG, "* System '" + sSystem + "' registered function '" + sFunction + "' for rest event type: " + sRestEventTypeConstant);
}

