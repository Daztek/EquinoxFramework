/*
    Script: ef_s_peraoe
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_eventman"
#include "nwnx_object"

const string PERAOE_SCRIPT_NAME         = "ef_s_peraoe";
const int AOE_MOB_CUSTOM                = 37;

void PerAOE_Apply(object oTarget, float fRadius, string sEffectTag, string sSystem, string sOnEnterFunction = "", string sOnExitFunction = "", string sOnHeartbeatFunction = "");

void PerAOE_SetScriptChunk(object oAoE, int nEventType, string sSystem, string sFunction)
{
    if (sFunction != "")
    {
        string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction));
        EFCore_CacheScriptChunk(sScriptChunk);
        SetLocalString(oAoE, IntToString(nEventType), sScriptChunk);
        EM_SetObjectEventScript(oAoE, nEventType, FALSE);
        EM_ObjectDispatchListInsert(oAoE, EM_GetObjectDispatchListId(PERAOE_SCRIPT_NAME, nEventType));
    }
}

void PerAOE_Apply(object oTarget, float fRadius, string sEffectTag, string sSystem, string sOnEnterFunction = "", string sOnExitFunction = "", string sOnHeartbeatFunction = "")
{
    RemoveEffectsWithTag(oTarget, sEffectTag);

    if (sOnEnterFunction == "" && sOnExitFunction == "" && sOnHeartbeatFunction == "")
        return;

    effect eAoE = EffectAreaOfEffect(AOE_MOB_CUSTOM);
           eAoE = TagEffect(eAoE, sEffectTag);
           eAoE = ExtraordinaryEffect(eAoE);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAoE, oTarget);

    object oAoE = NWNX_Util_GetLastCreatedObject(NWNX_OBJECT_TYPE_INTERNAL_AREAOFEFFECT);
    if (GetIsObjectValid(oAoE))
    {
        NWNX_Object_SetAoEObjectRadius(oAoE, fRadius);
        PerAOE_SetScriptChunk(oAoE, EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_ENTER, sSystem, sOnEnterFunction);
        PerAOE_SetScriptChunk(oAoE, EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_EXIT, sSystem, sOnExitFunction);
        PerAOE_SetScriptChunk(oAoE, EVENT_SCRIPT_AREAOFEFFECT_ON_HEARTBEAT, sSystem, sOnHeartbeatFunction);
    }
}

void PerAOE_RunScript()
{
    ExecuteScriptChunk(GetLocalString(OBJECT_SELF, IntToString(GetCurrentlyRunningEvent())), OBJECT_SELF, FALSE);
}

// @EVENT[EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_ENTER:DL:]
void PerAOE_OnEnter()
{
    PerAOE_RunScript();
}

// @EVENT[EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_EXIT:DL:]
void PerAOE_OnExit()
{
    PerAOE_RunScript();
}

// @EVENT[EVENT_SCRIPT_AREAOFEFFECT_ON_HEARTBEAT:DL:]
void PerAOE_OnHeartbeat()
{
    PerAOE_RunScript();
}
