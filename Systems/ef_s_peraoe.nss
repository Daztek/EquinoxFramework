/*
    Script: ef_s_peraoe
    Author: Daz
*/

#include "ef_i_core"
#include "nwnx_object"

const string PERAOE_SCRIPT_NAME                     = "ef_s_peraoe";

const int AOE_MOB_CUSTOM                            = 37;

const string PERAOE_SCRIPT_ON_ENTER                 = "ef_s_peraoe_oen";
const string PERAOE_SCRIPT_ON_EXIT                  = "ef_s_peraoe_oex";
const string PERAOE_SCRIPT_ON_HEARTBEAT             = "ef_s_peraoe_ohb";

void PerAOE_Apply(object oTarget, float fRadius, string sEffectTag, string sSystem, string sOnEnterFunction = "", string sOnExitFunction = "", string sOnHeartbeatFunction = "");

void PerAOE_AddScript(string sScript)
{
    string sObjectSelf = nssObject("oSelf", nssFunction("GetAreaOfEffectCreator"));
    string sGetLocalString = nssFunction("GetLocalString", "oSelf, " + nssEscape(sScript), FALSE);
    string sExecuteScriptChunk = nssFunction("ExecuteScriptChunk", sGetLocalString + ", OBJECT_SELF, FALSE");
    string sScriptChunk = sObjectSelf + sExecuteScriptChunk;

    string sError = VMCompileScript(sScript, PERAOE_SCRIPT_NAME, sScriptChunk);

    if (sError != "")
        LogError("Failed to compile script '" + sScript + "' with error: " + sError);
}

// @CORE[EF_SYSTEM_INIT]
void PerAOE_Init()
{
    PerAOE_AddScript(PERAOE_SCRIPT_ON_ENTER);
    PerAOE_AddScript(PERAOE_SCRIPT_ON_EXIT);
    PerAOE_AddScript(PERAOE_SCRIPT_ON_HEARTBEAT);
}

string PerAOE_SetScriptChunk(object oTarget, string sScript, string sSystem, string sFunction)
{
    if (sFunction == "")
    {
        DeleteLocalString(oTarget, sScript);
        return "";
    }

    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));
    EFCore_CacheScriptChunk(sScriptChunk);
    SetLocalString(oTarget, sScript, nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction)));

    return sScript;
}

void PerAOE_Apply(object oTarget, float fRadius, string sEffectTag, string sSystem, string sOnEnterFunction = "", string sOnExitFunction = "", string sOnHeartbeatFunction = "")
{
    RemoveEffectsWithTag(oTarget, sEffectTag);

    if (sOnEnterFunction == "" && sOnExitFunction == "" && sOnHeartbeatFunction == "")
        return;

    sOnEnterFunction = PerAOE_SetScriptChunk(oTarget, PERAOE_SCRIPT_ON_ENTER, sSystem, sOnEnterFunction);
    sOnExitFunction = PerAOE_SetScriptChunk(oTarget, PERAOE_SCRIPT_ON_EXIT, sSystem, sOnExitFunction);
    sOnHeartbeatFunction = PerAOE_SetScriptChunk(oTarget, PERAOE_SCRIPT_ON_HEARTBEAT, sSystem, sOnHeartbeatFunction);

    effect eAoE = EffectAreaOfEffect(AOE_MOB_CUSTOM, sOnEnterFunction, sOnHeartbeatFunction, sOnExitFunction);
           eAoE = TagEffect(eAoE, sEffectTag);
           eAoE = ExtraordinaryEffect(eAoE);

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAoE, oTarget);

    object oAoE = NWNX_Util_GetLastCreatedObject(NWNX_OBJECT_TYPE_INTERNAL_AREAOFEFFECT);
    if (GetIsObjectValid(oAoE))
        NWNX_Object_SetAoEObjectRadius(oAoE, fRadius);
}
