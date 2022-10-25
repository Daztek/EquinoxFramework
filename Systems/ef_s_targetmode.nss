/*
    Script: ef_s_targetmode
    Author: Daz

    // @ TARGETMODE[TARGET_MODE_ID]
    @ANNOTATION[TARGETMODE]
*/

#include "ef_i_core"

const string TARGETMODE_SCRIPT_NAME             = "ef_s_targetmode";
const string TARGETMODE_FUNCTIONS_ARRAY_PREFIX  = "FunctionsArray_";
const string TARGETMODE_CURRENT_TARGET_MODE     = "CurrentTargetMode_";

string TargetMode_GetTargetMode(object oPlayer);
void TargetMode_Enter(object oPlayer, string sTargetingMode, int nValidObjectTypes = OBJECT_TYPE_ALL, int nMouseCursorId = MOUSECURSOR_MAGIC, int nBadTargetCursor = MOUSECURSOR_NOMAGIC);

// Sets the spell targeting data which is used for the next call to EnterTargetingMode() for this player.
// If the shape is set to SPELL_TARGETING_SHAPE_NONE and the range is provided, the dotted line range indicator will still appear.
// - nShape: SPELL_TARGETING_SHAPE_*
// - nFlags: SPELL_TARGETING_FLAGS_*
// - nSpell: SPELL_* (optional, passed to the shader but does nothing by default, you need to edit the shader to use it)
// - nFeat: FEAT_* (optional, passed to the shader but does nothing by default, you need to edit the shader to use it)
void _SetEnterTargetingModeData(object oPlayer, int nShape, float fSizeX, float fSizeY, int nFlags, float fRange = 0.0f, int nSpell = -1, int nFeat = -1);

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
                string sError = ExecuteScriptChunk(sScriptChunk, oPlayer, FALSE);

                if (sError != "")
                    WriteLog("ERROR: ScriptChunk '" + sScriptChunk + "' failed with error: " + sError);
            }
        }
    }
}

// @PAD[TARGETMODE]
void TargetMode_RegisterFunction(struct AnnotationData str)
{
    string sTargetModeIdConstant = JsonArrayGetString(str.jTokens, 0);
    string sTargetModeId = GetConstantStringValue(sTargetModeIdConstant, str.sSystem, sTargetModeIdConstant);
    string sScriptChunk = nssInclude(str.sSystem) + nssVoidMain(nssFunction(str.sFunction));

    if (sTargetModeId == "")
        WriteLog("* WARNING: System '" + str.sSystem + "' tried to register function '" + str.sFunction + "' with an invalid target mode id");
    else
    {
        EFCore_CacheScriptChunk(sScriptChunk);
        InsertStringToLocalJsonArray(GetDataObject(TARGETMODE_SCRIPT_NAME), TARGETMODE_FUNCTIONS_ARRAY_PREFIX + sTargetModeId, sScriptChunk);
        WriteLog("* System '" + str.sSystem + "' registered function '" + str.sFunction + "' for target mode id: " + sTargetModeId);
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

void TargetMode_SetSpellData(object oPlayer, int nSpellId)
{
    int nShape = 0;
    string sShape = Get2DAString("spells", "TargetShape", nSpellId);

    if (sShape == "sphere")
        nShape = SPELL_TARGETING_SHAPE_SPHERE;
    else if (sShape == "rectangle")
        nShape = SPELL_TARGETING_SHAPE_RECT;
    else if (sShape == "cone")
        nShape = SPELL_TARGETING_SHAPE_CONE;
    else if (sShape == "hsphere")
        nShape = SPELL_TARGETING_SHAPE_HSPHERE;

    float fSizeX = StringToFloat(Get2DAString("spells", "TargetSizeX", nSpellId));
    float fSizeY = StringToFloat(Get2DAString("spells", "TargetSizeY", nSpellId));
    int nFlags = StringToInt(Get2DAString("spells", "TargetFlags", nSpellId));

    float fRange = 0.0f;
    string sRange = Get2DAString("spells", "Range", nSpellId);

    if (sRange == "L")
        fRange = 40.0f;
    else if (sRange == "M")
        fRange = 20.0f;
    else if (sRange == "S")
        fRange = 8.0f;
    else if (sRange == "T" || sRange == "P")
        fRange = 2.25f;

    SetEnterTargetingModeData(oPlayer, nShape, fSizeX, fSizeY, nFlags, fRange, nSpellId);
}
