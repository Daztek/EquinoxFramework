/*
    Script: ef_s_dmconcom
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "nwnx_object"

const string DMCONCOM_SCRIPT_NAME       = "ef_s_dmconcom";

// @CONSOLE[DumpLocals:isk_search:Dump local variables of an object]
string DMConCom_DumpLocals(int bModule = 0, int bArea = 0)
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
void DMConCom_Haste(float fDuration = 0.0f)
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
void DMConCom_StartingLocation()
{
    ClearAllActions();
    ActionJumpToLocation(GetStartingLocation());
}

// @CONSOLE[GiveXP:isk_pocket:Give XP]
string DMConCom_GiveXP(int nAmount, int bUntilNextLevel = 1)
{
    object oTarget = OBJECT_SELF;
    if (bUntilNextLevel)
    {
        int nCurrentLevel = GetHitDice(oTarget);

        if (nCurrentLevel < 40)
            nAmount = StringToInt(Get2DAString("exptable", "XP", nCurrentLevel)) - GetXP(oTarget);
        else
            nAmount = 0;
    }

    if (nAmount > 0)
        GiveXPToCreature(oTarget, nAmount);

    return "Gave " + IntToString(nAmount) + " XP to " + GetName(oTarget);
}

// @CONSOLE[SetCurrentHitPoints:ir_heal:Set the current hitpoints of a target]
void DMConCom_SetCurrentHitPoints(int nHitPoints)
{
    object oTarget = OBJECT_SELF;

    if (nHitPoints <= 0)
        nHitPoints = GetMaxHitPoints(oTarget);

    SetCurrentHitPoints(oTarget, nHitPoints);
}

// @CONSOLE[TogglePlot:dm_god:Toggle the plot state of a target]
string DMConCom_TogglePlot()
{
    object oTarget = OBJECT_SELF;
    int bPlot = GetPlotFlag(oTarget);
    SetPlotFlag(oTarget, !bPlot);

    return "Set Plot Flag to: " + IntToString(!bPlot);
}

// @CONSOLE[ToggleImmortal:dm_immortal:Toggle the immortal state of a target]
string DMConCom_ToggleImmortal()
{
    object oTarget = OBJECT_SELF;
    int bImmortal = GetImmortal(oTarget);
    SetImmortal(oTarget, !bImmortal);

    return "Set Immortal Flag to: " + IntToString(!bImmortal);
}

// @CONSOLE[ToggleCommandable:dm_ai:Toggle the commandable state of a target]
string DMConCom_ToggleCommandable()
{
    object oTarget = OBJECT_SELF;
    int bCommandable = GetCommandable(oTarget);
    SetCommandable(!bCommandable, oTarget);

    return "Set Commandable Flag to: " + IntToString(!bCommandable);
}

// @CONSOLE[ForceRest:dm_rest:Forcibly rest a target]
void DMConCom_ForceRest()
{
    ForceRest(OBJECT_SELF);
}

// @CONSOLE[ToggleCutsceneInvisibility::Toggle the cutscene invisibility on a target]
string DMConCom_ToggleCutsceneInvisibility()
{
    object oTarget = OBJECT_SELF;
    string sTag = DMCONCOM_SCRIPT_NAME + "_CUTSCENE_INVISIBILITY";
    int bCutsceneInvisibility = GetHasEffectWithTag(oTarget, sTag);

    if (bCutsceneInvisibility)
        RemoveEffectsWithTag(oTarget, sTag);
    else
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, TagEffect(EffectVisualEffect(VFX_DUR_CUTSCENE_INVISIBILITY), sTag), oTarget);

    return "Set Cutscene Invisibility to: " + IntToString(!bCutsceneInvisibility);
}

// @CONSOLE[SetTimeHour::Set the hour]
void DMConCom_SetTimeHour(int nHour = 8, int nMinute = 0)
{
    if (nHour >= 0 && nHour <= 23 && nMinute >= 0 && (nMinute * 60.0f) < HoursToSeconds(1))
        SetTime(nHour, nMinute, 0, 0);
}

// @CONSOLE[GetTickRate::Get the server tick rate]
string DMConCom_GetTickRate()
{
    return "Server Tick Rate: " + IntToString(GetTickRate());
}

// @CONSOLE[Kill::Kill the target]
void DMConCom_Kill()
{
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), OBJECT_SELF);
}

// @CONSOLE[DestroyObject::Destroy an object]
void DMConCom_DestroyObject(float fDelay = 0.0f)
{
    DestroyObject(OBJECT_SELF, fDelay);
}

// @CONSOLE[ToggleCutsceneMode::Toggle cutscene mode]
void DMConCom_ToggleCutsceneMode(int bLeftClickingEnabled = FALSE)
{
    SetCutsceneMode(OBJECT_SELF, !GetCutsceneMode(OBJECT_SELF), bLeftClickingEnabled);
}
