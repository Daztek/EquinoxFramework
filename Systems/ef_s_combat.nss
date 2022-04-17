/*
    Script: ef_s_combat
    Author: Daz
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_gfftools"
#include "nwnx_equinox"
#include "nwnx_player"

const string COMBAT_LOG_TAG                     = "Combat";
const string COMBAT_SCRIPT_NAME                 = "ef_s_combat";

const int COMBAT_SPELL_DEFAULT_MELEE_ATTACK     = 840;
const int COMBAT_SPELL_DEFAULT_RANGED_ATTACK    = 841;

const float COMBAT_DEFAULT_DAMAGE_DELAY         = 0.25f;

void Combat_SetAdditionalAttackDelay(object oPlayer, int nSpellID, float fDelay);
void Combat_PlaySwingSound(object oPlayer, int nBaseItemType);
void Combat_PlayHitSound(object oTarget, int nBaseItemType);
void Combat_HandleDefaultAttack(object oPlayer, object oTarget, int nSpellID);
void Combat_HandleFakeAttack(object oPlayer, location locTarget, int nSpellID);
void Combat_HandleIgnite(object oPlayer, object oTarget, float fDelay);

// @CORE[EF_SYSTEM_INIT]
void Combat_Init()
{
    string sError = AddScript(COMBAT_SCRIPT_NAME, COMBAT_SCRIPT_NAME, nssFunction("Combat_SpellEventHandler"));
    if (sError != "")
        WriteLog(COMBAT_LOG_TAG, "* WARNING: Failed to compile Combat_SpellEventHandler() with error: " + sError);
}

void Combat_SpellEventHandler()
{
    object oPlayer = OBJECT_SELF;
    object oTarget = GetSpellTargetObject();
    int nSpellID = GetSpellId();

    if (nSpellID == COMBAT_SPELL_DEFAULT_MELEE_ATTACK || nSpellID == COMBAT_SPELL_DEFAULT_RANGED_ATTACK)
    {
        if (GetIsObjectValid(oTarget))
            Combat_HandleDefaultAttack(oPlayer, oTarget, nSpellID);
        else
            Combat_HandleFakeAttack(oPlayer, GetSpellTargetLocation(), nSpellID);
    }

    //SendMessageToPC(oPlayer, "Combat_SpellEventHandler: " + IntToString(nSpellID) + " @ " + GetName(oTarget));
}

void Combat_SetAdditionalAttackDelay(object oPlayer, int nSpellID, float fDelay)
{
    SetLocalFloat(oPlayer, "EF_S_COMBAT_ADDITIONAL_ATTACK_DELAY_" + IntToString(nSpellID), fDelay);
}

void Combat_PlaySwingSound(object oPlayer, int nBaseItemType)
{
    int nWeaponMaterialType = StringToInt(Get2DAString("baseitems", "weaponmattype", nBaseItemType));
    string sSwingSound = Get2DAString("weaponsounds", "miss" + IntToString(0 + Random(2)), nWeaponMaterialType);

    if (sSwingSound != "")
        NWNX_Equinox_PlaySound(oPlayer, sSwingSound, 30.0f);
}

void Combat_PlayHitSound(object oTarget, int nBaseItemType)
{
    string sHitSoundType;
    int nObjectType = GetObjectType(oTarget);

    if (nObjectType == OBJECT_TYPE_CREATURE)
    {
        string sAppearanceSoundset = Get2DAString("appearance", "soundapptype", GetAppearanceType(oTarget));
        if (sAppearanceSoundset != "")
        {
            int nAppearanceSoundset = StringToInt(sAppearanceSoundset);
            if (!nAppearanceSoundset)
            {
                object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oTarget);
                if (GetIsObjectValid(oArmor))
                {
                    int nAC = StringToInt(Get2DAString("parts_chest", "acbonus", GetItemAppearance(oArmor, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_TORSO)));
                    if (nAC < 4)
                        sHitSoundType = "leather";
                    else if (nAC < 6)
                        sHitSoundType = "chain";
                    else
                        sHitSoundType = "plate";
                }
                else
                    sHitSoundType = "leather";
            }
            else
                sHitSoundType = Get2DAString("appearancesndset", "armortype", nAppearanceSoundset);
        }
    }
    else if (nObjectType == OBJECT_TYPE_PLACEABLE)
    {
        string sSoundAppType = Get2DAString("placeables", "soundapptype", GetAppearanceType(oTarget));
        if (sSoundAppType != "")
            sHitSoundType = Get2DAString("placeableobjsnds", "armortype", StringToInt(sSoundAppType));
    }

    // TODO: Doors?

    if (sHitSoundType != "")
    {
        int nWeaponMaterialType = StringToInt(Get2DAString("baseitems", "weaponmattype", nBaseItemType));
        string sHitSound = Get2DAString("weaponsounds", sHitSoundType + IntToString(0 + Random(2)), nWeaponMaterialType);
        if (sHitSound != "")
            NWNX_Equinox_PlaySound(oTarget, sHitSound, 30.0f);
    }
}

void Combat_HandleDefaultAttackDamage(object oPlayer, object oTarget, int nBaseItemType)
{
    int nWeaponType = StringToInt(Get2DAString("baseitems", "weapontype", nBaseItemType));
    int nDamageType;

    switch (nWeaponType)
    {
        case 1: nDamageType = DAMAGE_TYPE_PIERCING; break;
        case 2: nDamageType = DAMAGE_TYPE_BLUDGEONING; break;
        case 3: nDamageType = DAMAGE_TYPE_SLASHING; break;
        case 4: nDamageType = Random(2) ? DAMAGE_TYPE_SLASHING : DAMAGE_TYPE_PIERCING; break;
        case 5: nDamageType = Random(2) ? DAMAGE_TYPE_PIERCING : DAMAGE_TYPE_BLUDGEONING; break;
        default: nDamageType = DAMAGE_TYPE_SLASHING; break;
    }

    int nDamage = d6(4);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nDamage, nDamageType), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_BLOOD_REG_RED), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_BLOOD_SPARK_MEDIUM), oTarget);

    Combat_PlayHitSound(oTarget, nBaseItemType);

    if (!GetPlotFlag(oTarget) && !Random(3))
        PlayVoiceChat(VOICE_CHAT_PAIN1 + Random(3), oTarget);
}

void Combat_HandleDefaultAttack(object oPlayer, object oTarget, int nSpellID)
{
    int nBaseItemType = 0;
    object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPlayer);
    if (GetIsObjectValid(oWeapon))
        nBaseItemType = GetBaseItemType(oWeapon);

    Combat_PlaySwingSound(oPlayer, nBaseItemType);

    if (!Random(2))
        PlayVoiceChat(VOICE_CHAT_GATTACK1 + Random(3), oPlayer);

    float fDelay = COMBAT_DEFAULT_DAMAGE_DELAY;

    if (nSpellID == COMBAT_SPELL_DEFAULT_MELEE_ATTACK)
    {
        DelayCommand(fDelay, Combat_HandleDefaultAttackDamage(oPlayer, oTarget, nBaseItemType));
    }
    else if (nSpellID == COMBAT_SPELL_DEFAULT_RANGED_ATTACK)
    {
        fDelay += GetDistanceBetween(oPlayer, oTarget);
        fDelay /= 50.0f;

        NWNX_Equinox_BroadcastSafeProjectile(oPlayer, oTarget, GetLocation(oTarget), fDelay, 4, 1, 2, 0);
        DelayCommand(fDelay, Combat_HandleDefaultAttackDamage(oPlayer, oTarget, nBaseItemType));
    }

    Combat_HandleIgnite(oPlayer, oTarget, fDelay);
}

void Combat_HandleFakeAttack(object oPlayer, location locTarget, int nSpellID)
{
    int nBaseItemType = 0;
    object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPlayer);
    if (GetIsObjectValid(oWeapon))
        nBaseItemType = GetBaseItemType(oWeapon);

    Combat_PlaySwingSound(oPlayer, nBaseItemType);

    if (!Random(2))
        PlayVoiceChat(VOICE_CHAT_GATTACK1 + Random(3), oPlayer);

    float fDelay = COMBAT_DEFAULT_DAMAGE_DELAY;

    if (nSpellID == COMBAT_SPELL_DEFAULT_MELEE_ATTACK)
    {

    }
    else if (nSpellID == COMBAT_SPELL_DEFAULT_RANGED_ATTACK)
    {
        fDelay += GetDistanceBetweenLocations(GetLocation(oPlayer), locTarget);
        fDelay /= 50.0f;

        NWNX_Equinox_BroadcastSafeProjectile(oPlayer, OBJECT_INVALID, locTarget, fDelay, 0, 4, 2, 0);
    }
}

void Combat_HandleIgnite(object oPlayer, object oTarget, float fDelay)
{
    if (Random(100) < 75)
        return;

    //DelayCommand(fDelay, NWNX_Player_FloatingTextStringOnCreature(oPlayer, oTarget, "*Ignite*"));
    DelayCommand(fDelay, ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_FIREBALL), oTarget));
    fDelay += 0.25f;

    location locTarget = GetLocation(oTarget);
    object oObject = GetFirstObjectInShape(SHAPE_SPHERE, 2.5f, locTarget, OBJECT_TYPE_CREATURE);

    while (GetIsObjectValid(oObject))
    {
        if (oObject != oPlayer && oObject != oTarget)
        {
            DelayCommand(fDelay, ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(d6(2), DAMAGE_TYPE_FIRE), oObject));
            DelayCommand(fDelay, ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_HIT_FIRE), oObject));
        }

        oObject = GetNextObjectInShape(SHAPE_SPHERE, 2.5f, locTarget, OBJECT_TYPE_CREATURE);
    }
}

