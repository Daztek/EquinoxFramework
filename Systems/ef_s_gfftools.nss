/*
    Script: ef_s_gfftools
    Author: Daz

    Description:
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_events"

const string GFFTOOLS_LOG_TAG                           = "GffTools";
const string GFFTOOLS_SCRIPT_NAME                       = "ef_s_gfftools";

const string GFFTOOLS_INVISIBLE_OBJECT_PLC_RESREF       = "plc_invisobj";
const string GFFTOOLS_PLACEABLE_TEMPLATE_JSON           = "GffToolsPlaceableTemplate";
const string GFFTOOLS_FACING_ADJUSTMENT_VARNAME         = "GffToolsFacingAdjustment";
const int GFFTOOLS_INVISIBLE_PLACEABLE_MODEL_ID         = 157;

struct GffTools_PlaceableData
{
    int nModel;
    string sName;
    string sTag;
    string sDescription;
    string sOverridePortrait;

    int bHasInventory;
    int bPlot;
    int bUseable;
    int bStatic;

    float fFacingAdjustment;

    int scriptOnClick;
    int scriptOnClose;
    int scriptOnDamaged;
    int scriptOnDeath;
    int scriptOnHeartbeat;
    int scriptOnDisturbed;
    int scriptOnLock;
    int scriptOnPhysicalAttacked;
    int scriptOnOpen;
    int scriptOnSpellCastAt;
    int scriptOnUnlock;
    int scriptOnUsed;
    int scriptOnUserDefined;
    int scriptOnDialog;
    int scriptOnDisarm;
    int scriptOnTrapTriggered;
};

json GffTools_GeneratePlaceable(struct GffTools_PlaceableData pd);
object GffTools_CreatePlaceable(json jPlaceable, location locLocation, string sNewTag = "");

// @CORE[EF_SYSTEM_INIT]
void GffTools_Init()
{
    SetLocalJson(GetDataObject(GFFTOOLS_SCRIPT_NAME), GFFTOOLS_PLACEABLE_TEMPLATE_JSON, TemplateToJson(GFFTOOLS_INVISIBLE_OBJECT_PLC_RESREF, RESTYPE_UTP));
}

json GffTools_GetPlaceableTemplate()
{
    return GetLocalJson(GetDataObject(GFFTOOLS_SCRIPT_NAME), GFFTOOLS_PLACEABLE_TEMPLATE_JSON);
}

json GffTools_GeneratePlaceable(struct GffTools_PlaceableData pd)
{
    json jGff = GffTools_GetPlaceableTemplate();

    jGff = GffAddDword(jGff, "Appearance", pd.nModel);
    jGff = GffAddResRef(jGff, "Portrait", pd.sOverridePortrait != "" ? pd.sOverridePortrait : "po_" + Get2DAString("placeables", "ModelName", pd.nModel) + "_");
    jGff = GffAddLocString(jGff, "LocName", pd.sName);
    jGff = GffAddString(jGff, "Tag", pd.sTag);
    jGff = GffAddLocString(jGff, "Description", pd.sDescription);
    jGff = GffAddByte(jGff, "HasInventory", pd.bHasInventory);
    jGff = GffAddByte(jGff, "Plot", pd.bPlot);
    jGff = GffAddByte(jGff, "Useable", pd.bUseable);
    jGff = GffAddByte(jGff, "Static", pd.bStatic);

    if (pd.fFacingAdjustment != 0.0f)
        jGff = GffAddLocalVariable(jGff, GffLocalVarFloat(GFFTOOLS_FACING_ADJUSTMENT_VARNAME, pd.fFacingAdjustment));

    string sObjectEventScript = Events_GetObjectEventScript();
    if (pd.scriptOnClick)           jGff = GffAddResRef(jGff, "OnClick", sObjectEventScript);
    if (pd.scriptOnClose)           jGff = GffAddResRef(jGff, "OnClosed", sObjectEventScript);
    if (pd.scriptOnDamaged)         jGff = GffAddResRef(jGff, "OnDamaged", sObjectEventScript);
    if (pd.scriptOnDeath)           jGff = GffAddResRef(jGff, "OnDeath", sObjectEventScript);
    if (pd.scriptOnHeartbeat)       jGff = GffAddResRef(jGff, "OnHeartbeat", sObjectEventScript);
    if (pd.scriptOnDisturbed)       jGff = GffAddResRef(jGff, "OnDisturbed", sObjectEventScript);
    if (pd.scriptOnLock)            jGff = GffAddResRef(jGff, "OnLock", sObjectEventScript);
    if (pd.scriptOnPhysicalAttacked)jGff = GffAddResRef(jGff, "OnMeleeAttacked", sObjectEventScript);
    if (pd.scriptOnOpen)            jGff = GffAddResRef(jGff, "OnOpen", sObjectEventScript);
    if (pd.scriptOnSpellCastAt)     jGff = GffAddResRef(jGff, "OnSpellCastAt", sObjectEventScript);
    if (pd.scriptOnUnlock)          jGff = GffAddResRef(jGff, "OnUnlock", sObjectEventScript);
    if (pd.scriptOnUsed)            jGff = GffAddResRef(jGff, "OnUsed", sObjectEventScript);
    if (pd.scriptOnUserDefined)     jGff = GffAddResRef(jGff, "OnUserDefined", sObjectEventScript);
    if (pd.scriptOnDialog)          jGff = GffAddResRef(jGff, "OnDialog", sObjectEventScript);
    if (pd.scriptOnDisarm)          jGff = GffAddResRef(jGff, "OnDisarm", sObjectEventScript);
    if (pd.scriptOnTrapTriggered)   jGff = GffAddResRef(jGff, "OnTrapTriggered", sObjectEventScript);

    return jGff;
}

object GffTools_CreatePlaceable(json jPlaceable, location locLocation, string sNewTag = "")
{
    object oPlaceable = JsonToObject(jPlaceable, locLocation, OBJECT_INVALID, TRUE);

    if (sNewTag != "")
        SetTag(oPlaceable, sNewTag);

    float fFacingAdjustment = GetLocalFloat(oPlaceable, GFFTOOLS_FACING_ADJUSTMENT_VARNAME);
    if (fFacingAdjustment != 0.0f)
    {
        AssignCommand(oPlaceable, SetFacing(GetFacingFromLocation(locLocation) + fFacingAdjustment));
        DeleteLocalFloat(oPlaceable, GFFTOOLS_FACING_ADJUSTMENT_VARNAME);
    }

    return oPlaceable;
}

