/*
    Script: ef_s_targetmode
    Author: Daz

    // @ TARGETMODE[TARGET_MODE_ID]
    @ANNOTATION[@(TARGETMODE)\[([\w]+)\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

#include "ef_i_core"

const string TARGETMODE_LOG_TAG                 = "TargetMode";
const string TARGETMODE_SCRIPT_NAME             = "ef_s_targetmode";
const string TARGETMODE_FUNCTIONS_ARRAY_PREFIX  = "FunctionsArray_";
const string TARGETMODE_CURRENT_TARGET_MODE     = "CurrentTargetMode_";

const int _SPELL_TARGETING_SHAPE_NONE                      = 0;
const int _SPELL_TARGETING_SHAPE_SPHERE                    = 1;
const int _SPELL_TARGETING_SHAPE_RECT                      = 2;
const int _SPELL_TARGETING_SHAPE_CONE                      = 3;
const int _SPELL_TARGETING_SHAPE_HSPHERE                   = 4;

const int _SPELL_TARGETING_FLAGS_NONE                      = 0;
const int _SPELL_TARGETING_FLAGS_HARMS_ENEMIES             = 1;
const int _SPELL_TARGETING_FLAGS_HARMS_ALLIES              = 2;
const int _SPELL_TARGETING_FLAGS_HELPS_ALLIES              = 4;
const int _SPELL_TARGETING_FLAGS_IGNORES_SELF              = 8;
const int _SPELL_TARGETING_FLAGS_ORIGIN_ON_SELF            = 16;
const int _SPELL_TARGETING_FLAGS_SUPPRESS_WITH_TARGET      = 32;

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
                string sError = ExecuteCachedScriptChunk(sScriptChunk, oPlayer, FALSE);

                if (sError != "")
                    WriteLog(TARGETMODE_LOG_TAG, "ERROR: ScriptChunk '" + sScriptChunk + "' failed with error: " + sError);
            }
        }
    }
}

// @PARSEANNOTATIONDATA[TARGETMODE]
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

void _SetEnterTargetingModeData(object oPlayer, int nShape, float fSizeX, float fSizeY, int nFlags, float fRange = 0.0f, int nSpell = -1, int nFeat = -1)
{
    NWNX_PushArgumentInt(nFeat);
    NWNX_PushArgumentInt(nSpell);
    NWNX_PushArgumentFloat(fRange);
    NWNX_PushArgumentInt(nFlags);
    NWNX_PushArgumentFloat(fSizeY);
    NWNX_PushArgumentFloat(fSizeX);
    NWNX_PushArgumentInt(nShape);
    NWNX_PushArgumentObject(oPlayer);
    NWNX_CallFunction("NWNX_Vault", "SetEnterTargetingModeData");
}

void TargetMode_SetSpellData(object oPlayer, int nSpellId)
{
    int nShape = 0;
    string sShape = Get2DAString("spells", "TargetShape", nSpellId);
    
    if (sShape == "sphere")
        nShape = _SPELL_TARGETING_SHAPE_SPHERE;
    else if (sShape == "rectangle")    
        nShape = _SPELL_TARGETING_SHAPE_RECT;
    else if (sShape == "cone")
        nShape = _SPELL_TARGETING_SHAPE_CONE;
    else if (sShape == "hsphere") 
        nShape = _SPELL_TARGETING_SHAPE_HSPHERE;

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

    _SetEnterTargetingModeData(oPlayer, nShape, fSizeX, fSizeY, nFlags, fRange, nSpellId);
}
