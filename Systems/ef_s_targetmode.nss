/*
    Script: ef_s_targetmode
    Author: Daz

    // @ TARGETMODE[TARGET_MODE_ID]
    @ANNOTATION[@(TARGETMODE)\[([\w]+)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

//void main() {}

#include "ef_i_core"

const string TARGETMODE_LOG_TAG                 = "TargetMode";
const string TARGETMODE_SCRIPT_NAME             = "ef_s_targetmode";
const string TARGETMODE_FUNCTIONS_ARRAY_PREFIX  = "FunctionsArray_";
const string TARGETMODE_CURRENT_TARGET_MODE     = "CurrentTargetMode_";

string TargetMode_GetTargetMode(object oPlayer);
void TargetMode_Enter(object oPlayer, string sTargetingMode, int nValidObjectTypes = OBJECT_TYPE_ALL, int nMouseCursorId = MOUSECURSOR_MAGIC, int nBadTargetCursor = MOUSECURSOR_NOMAGIC);

// @CORE[EF_SYSTEM_INIT]
void GuiEvent_Init()
{
    EFCore_ExecuteFunctionOnAnnotationData(TARGETMODE_SCRIPT_NAME, "TARGETMODE", "TargetMode_RegisterFunction({DATA});");
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_PLAYER_TARGET]
void TargetMode_OnPlayerTarget()
{
    object oPlayer = GetLastPlayerToSelectTarget();
    string sTargetMode = TargetMode_GetTargetMode(oPlayer);

    if (sTargetMode != "")
    {
        json jFunctions = GetLocalJsonArray(GetDataObject(TARGETMODE_SCRIPT_NAME), TARGETMODE_FUNCTIONS_ARRAY_PREFIX + sTargetMode);
        int nFunction, nNumFunctions = JsonGetLength(jFunctions);

        for (nFunction = 0; nFunction < nNumFunctions; nFunction++)
        {
            string sScriptChunk = JsonArrayGetString(jFunctions, nFunction);
            if (sScriptChunk != "")
            {
                string sError = ExecuteCachedScriptChunk(sScriptChunk, oPlayer, FALSE);

                if (sError != "")
                    WriteLog(TARGETMODE_LOG_TAG, "ERROR: ScriptChunk '" + sScriptChunk + "' failed with error: " + sError);
            }
        }
    }
}

void TargetMode_RegisterFunction(json jTargetModeFunction)
{
    string sSystem = JsonArrayGetString(jTargetModeFunction, 0);
    string sTargetModeIdConstant = JsonArrayGetString(jTargetModeFunction, 2);
    string sTargetModeId = GetConstantStringValue(sTargetModeIdConstant, sSystem, sTargetModeIdConstant);
    string sFunction = JsonArrayGetString(jTargetModeFunction, 3);
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));

    if (sTargetModeId == "")
        WriteLog(TARGETMODE_LOG_TAG, "* WARNING: System '" + sSystem + "' tried to register function '" + sFunction + "' with an invalid target mode id");
    else
    {
        InsertStringToLocalJsonArray(GetDataObject(TARGETMODE_SCRIPT_NAME), TARGETMODE_FUNCTIONS_ARRAY_PREFIX + sTargetModeId, sScriptChunk);
        WriteLog(TARGETMODE_LOG_TAG, "* System '" + sSystem + "' registered function '" + sFunction + "' for target mode id: " + sTargetModeId);
    }
}

string TargetMode_GetTargetMode(object oPlayer)
{
    return GetLocalString(GetDataObject(TARGETMODE_SCRIPT_NAME), TARGETMODE_CURRENT_TARGET_MODE + GetObjectUUID(oPlayer));
}

void TargetMode_Enter(object oPlayer, string sTargetingMode, int nValidObjectTypes = OBJECT_TYPE_ALL, int nMouseCursorId = MOUSECURSOR_MAGIC, int nBadTargetCursor = MOUSECURSOR_NOMAGIC)
{
    SetLocalString(GetDataObject(TARGETMODE_SCRIPT_NAME), TARGETMODE_CURRENT_TARGET_MODE + GetObjectUUID(oPlayer), sTargetingMode);
    EnterTargetingMode(oPlayer, nValidObjectTypes, nMouseCursorId, nBadTargetCursor);
}

