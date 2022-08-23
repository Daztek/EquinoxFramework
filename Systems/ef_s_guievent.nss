/*
    Script: ef_s_guievent
    Author: Daz

    // @ GUIEVENT[GUIEVENT_*]
    @ANNOTATION[@(GUIEVENT)\[([\w]+)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

#include "ef_i_core"

const string GUIEVENT_LOG_TAG           = "GuiEvent";
const string GUIEVENT_SCRIPT_NAME       = "ef_s_guievent";
const string GUIEVENT_ARRAY_PREFIX      = "GuiEventFunctions_";

// @EVENT[EVENT_SCRIPT_MODULE_ON_PLAYER_GUIEVENT]
void GuiEvent_OnPlayerGuiEvent()
{
    object oPlayer = GetLastGuiEventPlayer();
    int nGuiEventType = GetLastGuiEventType();
    json jFunctions = GetLocalJsonArray(GetDataObject(GUIEVENT_SCRIPT_NAME), GUIEVENT_ARRAY_PREFIX + IntToString(nGuiEventType));
    int nFunction, nNumFunctions = JsonGetLength(jFunctions);

    for (nFunction = 0; nFunction < nNumFunctions; nFunction++)
    {
        string sScriptChunk = JsonArrayGetString(jFunctions, nFunction);
        if (sScriptChunk != "")
        {
            string sError = ExecuteCachedScriptChunk(sScriptChunk, oPlayer, FALSE);

            if (sError != "")
                WriteLog(GUIEVENT_LOG_TAG, "ERROR: ScriptChunk '" + sScriptChunk + "' failed with error: " + sError);
        }
    }
}

// @PARSEANNOTATIONDATA[GUIEVENT]
void GuiEvent_RegisterFunction(json jGuiEvent)
{
    string sSystem = JsonArrayGetString(jGuiEvent, 0);
    string sGuiEventType = JsonArrayGetString(jGuiEvent, 2);
    int nGuiEventType = GetConstantIntValue(sGuiEventType, "", -1);
    string sFunction = JsonArrayGetString(jGuiEvent, 3);
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));

    if (nGuiEventType == -1)
        WriteLog(GUIEVENT_LOG_TAG, "* WARNING: System '" + sSystem + "' tried to register '" + sFunction + "' for an invalid gui event: " + sGuiEventType);
    else
    {
        InsertStringToLocalJsonArray(GetDataObject(GUIEVENT_SCRIPT_NAME), GUIEVENT_ARRAY_PREFIX + IntToString(nGuiEventType), sScriptChunk);
        WriteLog(GUIEVENT_LOG_TAG, "* System '" + sSystem + "' registered '" + sFunction + "' for gui event '" + sGuiEventType + "'");
    }
}

