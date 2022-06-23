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
string Debug_DumpLocals(int bModule = 0, int bArea = 0)
{
    object oTarget = OBJECT_SELF;

    if (bModule)
        oTarget = GetModule();
    else if (bArea)
        oTarget = GetArea(oTarget);

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
    object oTarget = OBJECT_SELF;

    if (!GetHasEffectType(oTarget, EFFECT_TYPE_HASTE))
    {
        effect eHaste = EffectHaste();
        if (fDuration == 0.0f)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eHaste, oTarget);
        else
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eHaste, oTarget, fDuration);
    }
}

// @CONSOLE[StartingLocation:dm_jump:Move to the module starting location]
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

// @CONSOLE[SetCurrentHitPoints:ir_heal:Set the current hitpoints of a target]
void Debug_SetCurrentHitPoints(int nHitPoints)
{
    object oTarget = OBJECT_SELF;

    if (nHitPoints <= 0)
        nHitPoints = GetMaxHitPoints(oTarget);

    SetCurrentHitPoints(oTarget, nHitPoints);
}

// @CONSOLE[TogglePlot:dm_god:Toggle the plot state of a target]
string Debug_TogglePlot()
{
    object oTarget = OBJECT_SELF;
    int bPlot = GetPlotFlag(oTarget);
    SetPlotFlag(oTarget, !bPlot);

    return "Set Plot Flag to: " + IntToString(!bPlot);
}

// @CONSOLE[ToggleImmortal:dm_immortal:Toggle the immortal state of a target]
string Debug_ToggleImmortal()
{
    object oTarget = OBJECT_SELF;
    int bImmortal = GetImmortal(oTarget);
    SetImmortal(oTarget, !bImmortal);

    return "Set Immortal Flag to: " + IntToString(!bImmortal);
}

// @CONSOLE[ToggleCommandable:dm_ai:Toggle the commandable state of a target]
string Debug_ToggleCommandable()
{
    object oTarget = OBJECT_SELF;
    int bCommandable = GetCommandable(oTarget);
    SetCommandable(!bCommandable, oTarget);

    return "Set Commandable Flag to: " + IntToString(!bCommandable);
}

// @CONSOLE[ForceRest:dm_rest:Forcibly rest a target]
void Debug_ForceRest()
{
    ForceRest(OBJECT_SELF);
}
