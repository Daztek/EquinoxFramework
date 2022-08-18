/*
    Script: ef_s_peraoe
    Author: Daz
*/

#include "ef_i_core"

const string PERAOE_LOG_TAG                         = "PersistentAoE";
const string PERAOE_SCRIPT_NAME                     = "ef_s_peraoe";

const string PERAOE_SCRIPT_ON_ENTER                 = "ef_s_peraoe_oen";
const string PERAOE_SCRIPT_ON_EXIT                  = "ef_s_peraoe_oex";
const string PERAOE_SCRIPT_ON_HEARTBEAT             = "ef_s_peraoe_ohb";

const int PERAOE_SIZE_5                             = 37;
const int PERAOE_SIZE_10                            = 44;

void PerAOE_Apply(object oTarget, int nSize, string sSystem, string sOnEnterFunction = "", string sOnExitFunction = "", string sOnHeartbeatFunction = "");

void PerAOE_AddScript(string sScript)
{
    string sObjectSelf = nssObject("oSelf", nssFunction("GetAreaOfEffectCreator"));
    string sGetLocalString = nssFunction("GetLocalString", "oSelf, " + nssEscape(sScript), FALSE);
    string sExecuteCachedScriptChunk = nssFunction("ExecuteCachedScriptChunk", sGetLocalString + ", OBJECT_SELF, FALSE");
    string sScriptChunk = sObjectSelf + sExecuteCachedScriptChunk;

    AddScript(sScript, PERAOE_SCRIPT_NAME, sScriptChunk); 
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
    SetLocalString(oTarget, sScript, sScriptChunk);
    return sScript;
}

void PerAOE_Apply(object oTarget, int nSize, string sSystem, string sOnEnterFunction = "", string sOnExitFunction = "", string sOnHeartbeatFunction = "")
{
    RemoveEffectsWithTag(oTarget, PERAOE_SCRIPT_NAME);

    if (sOnEnterFunction == "" && sOnExitFunction == "" && sOnHeartbeatFunction == "")
        return;

    sOnEnterFunction = PerAOE_SetScriptChunk(oTarget, PERAOE_SCRIPT_ON_ENTER, sSystem, sOnEnterFunction);
    sOnExitFunction = PerAOE_SetScriptChunk(oTarget, PERAOE_SCRIPT_ON_EXIT, sSystem, sOnExitFunction);
    sOnHeartbeatFunction = PerAOE_SetScriptChunk(oTarget, PERAOE_SCRIPT_ON_HEARTBEAT, sSystem, sOnHeartbeatFunction);    
    
    effect eAoE = EffectAreaOfEffect(nSize, sOnEnterFunction, sOnHeartbeatFunction, sOnExitFunction);
           eAoE = TagEffect(eAoE, PERAOE_SCRIPT_NAME);
           eAoE = ExtraordinaryEffect(eAoE);

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAoE, oTarget);
}
