/*
    Script: ef_s_debug
    Author: Daz
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_events"
#include "ef_s_profiler"
#include "nwnx_object"

const string DEBUG_LOG_TAG              = "Debug";
const string DEBUG_SCRIPT_NAME          = "ef_s_debug";

const string DEBUG_DEBUG_SCRIPT_NAME    = "ef_debug";

// @CORE[EF_SYSTEM_LOAD]
void Debug_Load()
{

}

// @EVENT[NWNX_ON_RESOURCE_MODIFIED]
void Debug_OnResourceModified()
{
    string sAlias = Events_GetString("ALIAS");
    int nType = Events_GetInt("TYPE");

    if (sAlias == "NWNX" && nType == RESTYPE_NSS)
    {
        string sScriptName = Events_GetString("RESREF");

        if (sScriptName == DEBUG_DEBUG_SCRIPT_NAME)
        {
            WriteLog(DEBUG_LOG_TAG, "* Changes detected, executing debug script");

            string sScriptChunk = NWNX_Util_GetNSSContents(DEBUG_DEBUG_SCRIPT_NAME);

            if (sScriptChunk != "")
            {
                string sResult = ExecuteCachedScriptChunk(sScriptChunk, GetModule(), FALSE);

                if (sResult != "")
                    WriteLog(DEBUG_LOG_TAG, "   > Failed to execute debug script, error: " + sResult);
            }
        }
    }
}

// @CONSOLE[DumpLocals:isk_search:Dump local variables of an object]
string Debug_DumpLocals()
{
    object oTarget = OBJECT_SELF;
    string sMessage = "* Name: " + GetName(oTarget);
           sMessage += "\n* Tag: " + GetTag(oTarget);
           sMessage += "\n* UUID: " + NWNX_Object_PeekUUID(oTarget);
           sMessage += "\n\n*** Variables:";

    int nCount = NWNX_Object_GetLocalVariableCount(oTarget);

    if (!nCount)
        sMessage += "\nNone defined.";
    else
    {
        int i;
        for(i = 0; i < nCount; i++)
        {
            struct NWNX_Object_LocalVariable var = NWNX_Object_GetLocalVariable(oTarget, i);

            switch (var.type)
            {
                case NWNX_OBJECT_LOCALVAR_TYPE_UNKNOWN:
                    sMessage += "\n[Unknown] '" + var.key + "' = ?\n";
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_INT:
                    sMessage += "\n[Int] '" + var.key + "' = " + IntToString(GetLocalInt(oTarget, var.key)) + "\n";
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_FLOAT:
                    sMessage += "\n[Float] '" + var.key + "' = " + FloatToString(GetLocalFloat(oTarget, var.key), 0) + "\n";
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_STRING:
                    sMessage += "\n[String] '" + var.key + "' = \"" + GetLocalString(oTarget, var.key) + "\"\n";
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_OBJECT:
                    sMessage += "\n[Object] '" + var.key + "' = " + ObjectToString(GetLocalObject(oTarget, var.key)) + "\n";
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_LOCATION:
                {
                    location locLocation = GetLocalLocation(oTarget, var.key);
                    object oArea = GetAreaFromLocation(locLocation);
                    vector vPos = GetPositionFromLocation(locLocation);

                    sMessage += "\n[Location] '" + var.key + "' = (" + GetTag(oArea) + ")(" + FloatToString(vPos.x, 0, 3) + ", " + FloatToString(vPos.y, 0, 3) + ", " + FloatToString(vPos.z, 0, 3) + ")\n";
                    break;
                }

                case NWNX_OBJECT_LOCALVAR_TYPE_JSON:
                {
                    sMessage += "\n[Json] '" + var.key + "' = " + JsonDump(GetLocalJson(oTarget, var.key)) + "\n";
                    break;
                }
            }
        }
    }
    return sMessage;
}

// @CONSOLE[Haste:ief_haste:Give Haste]
void Debug_Haste(float fDuration = 0.0f)
{
    object oPlayer = OBJECT_SELF;

    if (!GetHasEffectType(oPlayer, EFFECT_TYPE_HASTE))
    {
        if (fDuration == 0.0f)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectHaste(), oPlayer);
        else
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectHaste(), oPlayer, fDuration);
    }
}

// @CONSOLE[StartingLocation:ir_flee:Move to the module starting location]
void Debug_MoveToStartingLocation()
{
    ClearAllActions();
    JumpToLocation(GetStartingLocation());
}

// @CONSOLE[GiveXP:isk_pocket:Give XP]
void Debug_GiveXP(int nAmount)
{
    if (nAmount > 0)
        GiveXPToCreature(OBJECT_SELF, nAmount);
}

