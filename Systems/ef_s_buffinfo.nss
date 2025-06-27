/*
    Script: ef_s_buffinfo
    Author: Daz

    Description: An Equinox Framework system to display buffs when a player clicks an effect icon
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_session"
#include "ef_s_playerdb"
#include "ef_s_poststring"

const string BUFFINFO_SCRIPT_NAME               = "ef_s_buffinfo";

const string BUFFINFO_LAST_NUM_LINES            = "LastNumLines";
const int BUFFINFO_GUI_NUM_IDS                  = 50;
const float BUFFINFO_DISPLAY_TIME               = 15.0f;

void BuffInfo_DisplayLine(object oPlayer, int nLineOffset, int nID, string sText, int nColor);
string BuffInfo_GetVersusRacialTypeAndAlignment(int nRacialType, int nLawfulChaotic, int nGoodEvil);
string BuffInfo_GetModifierType(int nEffectType, int nPlus, int nMinus);

// @CORE[EF_SYSTEM_LOAD]
void BuffInfo_Load()
{
    PostString_ReserveIDs(BUFFINFO_GUI_NUM_IDS);
}

// @GUIEVENT[GUIEVENT_EFFECTICON_CLICK]
void BuffInfo_HandleEffectIconClick()
{
    object oPlayer = OBJECT_SELF;
    int nEffectIconID = GetLastGuiEventInteger();
    int nIconEffectType = EffectIconToEffectType(nEffectIconID);

    if (nIconEffectType == EFFECT_TYPE_INVALIDEFFECT)
        return;

    int nID = PostString_GetStartID();
    int nLastNumLines = Session_GetInt(oPlayer, BUFFINFO_SCRIPT_NAME, BUFFINFO_LAST_NUM_LINES);
    PostString_ClearByRange(oPlayer, nID, nID + nLastNumLines);

    int nOffsetY = 1;
    int nColor = POSTSTRING_COLOR_LIME;
    int bSkipDisplay = FALSE, bHasEffect = FALSE, bIsSpellLevelAbsorptionPretendingToBeSpellImmunity = FALSE;

    BuffInfo_DisplayLine(oPlayer, nOffsetY++, nID++, "BuffInfo: " + Get2DAStrRefString("effecticons", "StrRef", nEffectIconID), POSTSTRING_COLOR_WHITE);

    effect eEffect = GetFirstEffect(oPlayer);
    while (GetIsEffectValid(eEffect))
    {
        bSkipDisplay = FALSE;
        int nEffectType = GetEffectType(eEffect);

        // Unlimited EffectSpellLevelAbsorption has a SpellImmunity Icon
        if (nEffectType == EFFECT_TYPE_SPELLLEVELABSORPTION && nIconEffectType == EFFECT_TYPE_SPELL_IMMUNITY && GetEffectInteger(eEffect, 3))
        {
            bIsSpellLevelAbsorptionPretendingToBeSpellImmunity = TRUE;
            nIconEffectType = EFFECT_TYPE_SPELLLEVELABSORPTION;
        }

        if (nEffectType == nIconEffectType)
        {
            bHasEffect = TRUE;

            int nSpellID = GetEffectSpellId(eEffect);
            string sSpellName = nSpellID == -1 ? "<Unknown>" : Get2DAStrRefString("spells", "Name", nSpellID);
            int bIsPermanentEffect = GetEffectDurationType(eEffect) == DURATION_TYPE_PERMANENT;
            int nDurationRemaining = GetEffectDurationRemaining(eEffect);
            string sDurationRemaining = bIsPermanentEffect ? "(Permanent)" : "(" + SecondsToStringTimestamp(nDurationRemaining) + ")";

            if (bIsPermanentEffect)
                nColor = POSTSTRING_COLOR_BLUE;
            else
            {
                float fPercentage = IntToFloat(nDurationRemaining) / IntToFloat(GetEffectDuration(eEffect));

                if (fPercentage > 0.5f)
                    nColor = POSTSTRING_COLOR_LIME;
                else if (fPercentage < 0.25f)
                    nColor = POSTSTRING_COLOR_RED;
                else
                    nColor = POSTSTRING_COLOR_YELLOW;
            }

            string sStats = "";
            string sRacialTypeAlignment = "";

            switch (nEffectType)
            {
                case EFFECT_TYPE_AC_INCREASE:
                case EFFECT_TYPE_AC_DECREASE:
                {
                    string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_AC_INCREASE, EFFECT_TYPE_AC_DECREASE);
                    sStats = sModifier + IntToString(GetEffectInteger(eEffect, 1)) + " " + ACTypeToString(GetEffectInteger(eEffect, 0)) + " AC";
                    sRacialTypeAlignment = BuffInfo_GetVersusRacialTypeAndAlignment(GetEffectInteger(eEffect, 2), GetEffectInteger(eEffect, 3), GetEffectInteger(eEffect, 4));
                    break;
                }

                case EFFECT_TYPE_ATTACK_INCREASE:
                case EFFECT_TYPE_ATTACK_DECREASE:
                {
                    string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_ATTACK_INCREASE, EFFECT_TYPE_ATTACK_DECREASE);
                    sStats = sModifier + IntToString(GetEffectInteger(eEffect, 0)) +" AB";
                    sRacialTypeAlignment = BuffInfo_GetVersusRacialTypeAndAlignment(GetEffectInteger(eEffect, 2), GetEffectInteger(eEffect, 3), GetEffectInteger(eEffect, 4));
                    break;
                }

                case EFFECT_TYPE_SAVING_THROW_INCREASE:
                case EFFECT_TYPE_SAVING_THROW_DECREASE:
                {
                    string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_SAVING_THROW_INCREASE, EFFECT_TYPE_SAVING_THROW_DECREASE);
                    string sSavingThrow = SavingThrowToString(GetEffectInteger(eEffect, 1));
                    string sSavingThrowType = SavingThrowTypeToString(GetEffectInteger(eEffect, 2));
                    sStats = sModifier + IntToString(GetEffectInteger(eEffect, 0)) + " " + sSavingThrow + (sSavingThrowType == "" ? "" : " (vs. " + sSavingThrowType + ")");
                    sRacialTypeAlignment = BuffInfo_GetVersusRacialTypeAndAlignment(GetEffectInteger(eEffect, 3), GetEffectInteger(eEffect, 4), GetEffectInteger(eEffect, 5));
                    break;
                }

                case EFFECT_TYPE_ABILITY_INCREASE:
                case EFFECT_TYPE_ABILITY_DECREASE:
                {
                    int nAbility = AbilityTypeFromEffectIconAbility(nEffectIconID);

                    if (nAbility != GetEffectInteger(eEffect, 0))
                        bSkipDisplay = TRUE;
                    else
                    {
                        string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_ABILITY_INCREASE, EFFECT_TYPE_ABILITY_DECREASE);
                        sStats = sModifier + IntToString(GetEffectInteger(eEffect, 1)) + " " + AbilityToString(nAbility);
                    }
                    break;
                }

                case EFFECT_TYPE_DAMAGE_INCREASE:
                case EFFECT_TYPE_DAMAGE_DECREASE:
                {
                    string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_DAMAGE_INCREASE, EFFECT_TYPE_DAMAGE_DECREASE);
                    sStats = sModifier + Get2DAStrRefString("iprp_damagecost", "Name", GetEffectInteger(eEffect, 0)) + " (" + DamageTypeToString(GetEffectInteger(eEffect, 1)) + ")";
                    sRacialTypeAlignment = BuffInfo_GetVersusRacialTypeAndAlignment(GetEffectInteger(eEffect, 2), GetEffectInteger(eEffect, 3), GetEffectInteger(eEffect, 4));
                    break;
                }

                case EFFECT_TYPE_SKILL_INCREASE:
                case EFFECT_TYPE_SKILL_DECREASE:
                {
                    int nSkill = GetEffectInteger(eEffect, 0);
                    string sSkill = nSkill == SKILL_ALL_SKILLS ? "All Skills" : Get2DAStrRefString("skills", "Name", nSkill);
                    string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_SKILL_INCREASE, EFFECT_TYPE_SKILL_DECREASE);
                    sStats = sModifier + IntToString(GetEffectInteger(eEffect, 1)) + " " + sSkill;
                    sRacialTypeAlignment = BuffInfo_GetVersusRacialTypeAndAlignment(GetEffectInteger(eEffect, 2), GetEffectInteger(eEffect, 3), GetEffectInteger(eEffect, 4));
                    break;
                }

                case EFFECT_TYPE_TEMPORARY_HITPOINTS:
                {
                    sStats = "+" + IntToString(GetEffectInteger(eEffect, 0)) + " HitPoints";
                    break;
                }

                case EFFECT_TYPE_DAMAGE_REDUCTION:
                {
                    int nAmount = GetEffectInteger(eEffect, 0);
                    int nDamagePower = GetEffectInteger(eEffect, 1);
                    nDamagePower = nDamagePower > 6 ? --nDamagePower : nDamagePower;
                    int nRemaining = GetEffectInteger(eEffect, 2);
                    sStats = IntToString(nAmount) + "/+" + IntToString(nDamagePower) + " (" + (nRemaining == 0 ? "Unlimited" : IntToString(nRemaining) + " Damage Remaining") + ")";
                    break;
                }

                case EFFECT_TYPE_DAMAGE_RESISTANCE:
                {
                    int nAmount = GetEffectInteger(eEffect, 1);
                    int nRemaining = GetEffectInteger(eEffect, 2);
                    sStats = IntToString(nAmount) + "/- " + DamageTypeToString(GetEffectInteger(eEffect, 0)) + " Resistance (" + (nRemaining == 0 ? "Unlimited" : IntToString(nRemaining) + " Damage Remaining") + ")";
                    break;
                }

                case EFFECT_TYPE_IMMUNITY:
                {
                    int nImmunity = ImmunityTypeFromEffectIconImmunity(nEffectIconID);

                    if (nImmunity != GetEffectInteger(eEffect, 0))
                        bSkipDisplay = TRUE;
                    else
                    {
                        sStats = Get2DAStrRefString("effecticons", "StrRef", nEffectIconID);
                        sRacialTypeAlignment = BuffInfo_GetVersusRacialTypeAndAlignment(GetEffectInteger(eEffect, 1), GetEffectInteger(eEffect, 2), GetEffectInteger(eEffect, 3));
                    }
                    break;
                }

                case EFFECT_TYPE_DAMAGE_IMMUNITY_INCREASE:
                case EFFECT_TYPE_DAMAGE_IMMUNITY_DECREASE:
                {
                    int nDamageType = GetEffectInteger(eEffect, 0);
                    int nDamageTypeFromIcon = DamageTypeFromEffectIconDamageImmunity(nEffectIconID);

                    if (nDamageTypeFromIcon != -1 && nDamageType != nDamageTypeFromIcon)
                        bSkipDisplay = TRUE;

                    string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_DAMAGE_IMMUNITY_INCREASE, EFFECT_TYPE_DAMAGE_IMMUNITY_DECREASE);
                    sStats = sModifier + IntToString(GetEffectInteger(eEffect, 1)) + "% " + DamageTypeToString(nDamageType) + " Damage Immunity";
                    break;
                }

                case EFFECT_TYPE_SPELL_IMMUNITY:
                {
                    sStats = "Spell Immunity: " + Get2DAStrRefString("spells", "Name", GetEffectInteger(eEffect, 0));
                    break;
                }

                case EFFECT_TYPE_SPELLLEVELABSORPTION:
                {
                    int nMaxSpellLevelAbsorbed = GetEffectInteger(eEffect, 0);
                    int bUnlimited = GetEffectInteger(eEffect, 3);
                    string sSpellLevel;
                    switch (nMaxSpellLevelAbsorbed)
                    {
                        case 0: sSpellLevel = "Cantrip"; break;
                        case 1: sSpellLevel = "1st"; break;
                        case 2: sSpellLevel = "2nd"; break;
                        case 3: sSpellLevel = "3rd"; break;
                        default: sSpellLevel = IntToString(nMaxSpellLevelAbsorbed) + "th"; break;
                    }
                    sSpellLevel += " Level" + (nMaxSpellLevelAbsorbed == 0 ? "" : " and Below");
                    string sSpellSchool = SpellSchoolToString(GetEffectInteger(eEffect, 2));
                    string sRemainingSpellLevels = bUnlimited ? "" : "(" + IntToString(GetEffectInteger(eEffect, 1)) + " Spell Levels Remaining)";
                    sStats = sSpellLevel + " " + sSpellSchool + " Spell Immunity " + sRemainingSpellLevels;

                    if (bIsSpellLevelAbsorptionPretendingToBeSpellImmunity)
                        nIconEffectType = EFFECT_TYPE_SPELL_IMMUNITY;
                    else if (bUnlimited && !bIsSpellLevelAbsorptionPretendingToBeSpellImmunity)
                        bSkipDisplay = TRUE;

                    break;
                }

                case EFFECT_TYPE_REGENERATE:
                {
                    sStats = "+" + IntToString(GetEffectInteger(eEffect, 0)) + " HP / " + FloatToString((GetEffectInteger(eEffect, 1) / 1000.0f), 0, 2) + "s";
                    break;
                }

                case EFFECT_TYPE_POISON:
                {
                    sStats = "Poison: " + Get2DAStrRefString("poison", "Name", GetEffectInteger(eEffect, 0));
                    break;
                }

                case EFFECT_TYPE_DISEASE:
                {
                    sStats = "Disease: " + Get2DAStrRefString("disease", "Name", GetEffectInteger(eEffect, 0));
                    break;
                }

                case EFFECT_TYPE_CURSE:
                {
                    int nAbility;
                    string sAbilityDecrease;
                    for (nAbility = ABILITY_STRENGTH; nAbility <= ABILITY_CHARISMA; nAbility++)
                    {
                        int nAbilityMod = GetEffectInteger(eEffect, nAbility);
                        if (nAbilityMod > 0)
                        {
                            string sAbility = GetStringLeft(AbilityToString(nAbility), 3);
                            sAbilityDecrease += "-" + IntToString(nAbilityMod) + " " + sAbility + ", ";
                        }
                    }
                    sAbilityDecrease = GetStringLeft(sAbilityDecrease, GetStringLength(sAbilityDecrease) - 2);
                    sStats = sAbilityDecrease;
                    break;
                }

                case EFFECT_TYPE_MOVEMENT_SPEED_INCREASE:
                case EFFECT_TYPE_MOVEMENT_SPEED_DECREASE:
                {
                    string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_MOVEMENT_SPEED_INCREASE, EFFECT_TYPE_MOVEMENT_SPEED_DECREASE);
                    sStats = sModifier + IntToString(GetEffectInteger(eEffect, 0)) + "% Movement Speed";
                    break;
                }

                case EFFECT_TYPE_ELEMENTALSHIELD:
                {
                    sStats = IntToString(GetEffectInteger(eEffect, 0)) + " + " + Get2DAStrRefString("iprp_damagecost", "Name", GetEffectInteger(eEffect, 1)) + " (" + DamageTypeToString(GetEffectInteger(eEffect, 2)) + ")";
                    break;
                }

                case EFFECT_TYPE_NEGATIVELEVEL:
                {
                    sStats = "-" + IntToString(GetEffectInteger(eEffect, 0)) + " Levels";
                    break;
                }

                case EFFECT_TYPE_CONCEALMENT:
                {
                    string sMissChance = MissChanceToString(GetEffectInteger(eEffect, 4) - 1);
                    sStats = IntToString(GetEffectInteger(eEffect, 0)) + "% Concealment" + (sMissChance == "" ? "" : " (" + sMissChance + ")");
                    sRacialTypeAlignment = BuffInfo_GetVersusRacialTypeAndAlignment(GetEffectInteger(eEffect, 1), GetEffectInteger(eEffect, 2), GetEffectInteger(eEffect, 3));
                    break;
                }

                case EFFECT_TYPE_SPELL_RESISTANCE_INCREASE:
                case EFFECT_TYPE_SPELL_RESISTANCE_DECREASE:
                {
                    string sModifier = BuffInfo_GetModifierType(nEffectType, EFFECT_TYPE_SPELL_RESISTANCE_INCREASE, EFFECT_TYPE_SPELL_RESISTANCE_DECREASE);
                    sStats = sModifier + IntToString(GetEffectInteger(eEffect, 0)) + " Spell Resistance";
                    break;
                }

                case EFFECT_TYPE_SPELL_FAILURE:
                {
                    sStats = IntToString(GetEffectInteger(eEffect, 0)) + "% Spell Failure (Spell School: " + SpellSchoolToString(GetEffectInteger(eEffect, 1)) + ")";
                    break;
                }

                case EFFECT_TYPE_INVISIBILITY:
                {
                    int nInvisibilityType = GetEffectInteger(eEffect, 0);
                    if (nEffectIconID == EFFECT_ICON_INVISIBILITY)
                        bSkipDisplay = nInvisibilityType != INVISIBILITY_TYPE_NORMAL;
                    else if (nEffectIconID == EFFECT_ICON_IMPROVEDINVISIBILITY)
                        bSkipDisplay = nInvisibilityType != INVISIBILITY_TYPE_IMPROVED;
                    if (!bSkipDisplay)
                    {
                        sStats = (nInvisibilityType == INVISIBILITY_TYPE_IMPROVED ? "Improved " : "") + "Invisibility";
                        sRacialTypeAlignment = BuffInfo_GetVersusRacialTypeAndAlignment(GetEffectInteger(eEffect, 1), GetEffectInteger(eEffect, 2), GetEffectInteger(eEffect, 3));
                    }
                    break;
                }
            }

            if (!bSkipDisplay)
            {
                BuffInfo_DisplayLine(oPlayer, nOffsetY++, nID++, " - " + sSpellName + " " + sDurationRemaining + (sStats == "" ? "" : " -> " + sStats + sRacialTypeAlignment), nColor);

                if (!PlayerDB_GetInt(oPlayer, BUFFINFO_SCRIPT_NAME, "HideSource"))
                {
                    object oSource = GetEffectCreator(eEffect);
                    if (GetIsObjectValid(oSource))
                    {
                        string sSource = GetObjectType(oSource) ? GetName(oSource) : "<Unknown>";
                        BuffInfo_DisplayLine(oPlayer, nOffsetY++, nID++, "  * Source: " + sSource, POSTSTRING_COLOR_AQUA);
                    }
                }
            }
        }

        eEffect = GetNextEffect(oPlayer);
    }

    if (!bHasEffect)
    {
        BuffInfo_DisplayLine(oPlayer, nOffsetY++, nID++, " - <Item Effect?>", nColor);
    }

    Session_SetInt(oPlayer, BUFFINFO_SCRIPT_NAME, BUFFINFO_LAST_NUM_LINES, nOffsetY);
}

void BuffInfo_DisplayLine(object oPlayer, int nLineOffset, int nID, string sText, int nColor)
{
    PostString(oPlayer, sText, 1, nLineOffset, SCREEN_ANCHOR_TOP_LEFT, BUFFINFO_DISPLAY_TIME, nColor, nColor, nID, POSTSTRING_FONT_TEXT_NAME);
}

string BuffInfo_GetVersusRacialTypeAndAlignment(int nRacialType, int nLawfulChaotic, int nGoodEvil)
{
    string sRacialType = nRacialType == RACIAL_TYPE_INVALID ? "" : Get2DAStrRefString("racialtypes", "NamePlural", nRacialType);
    string sLawfulChaotic = nLawfulChaotic == ALIGNMENT_LAWFUL ? "Lawful" : nLawfulChaotic == ALIGNMENT_CHAOTIC ? "Chaotic" : "";
    string sGoodEvil = nGoodEvil == ALIGNMENT_GOOD ? "Good" : nGoodEvil == ALIGNMENT_EVIL ? "Evil" : "";
    string sAlignment = sLawfulChaotic + (sLawfulChaotic == "" ? sGoodEvil : (sGoodEvil == "" ? "" : " " + sGoodEvil));
    return (sRacialType != "" || sAlignment != "") ? (" vs. " + sAlignment + (sAlignment == "" ? sRacialType : (sRacialType == "" ? "" : " " + sRacialType))) : "";
}

string BuffInfo_GetModifierType(int nEffectType, int nPlus, int nMinus)
{
    return nEffectType == nPlus ? "+" : nEffectType == nMinus ? "-" : "";
}
