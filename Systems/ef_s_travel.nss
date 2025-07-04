/*
    Script: ef_s_travel
    Author: Daz

    @SKIPSYSTEM
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_eventman"

const string TRAVEL_SCRIPT_NAME                 = "ef_s_travel";

const string TRAVEL_EFFECT_TAG                  = "TravelEffectTag";
const float  TRAVEL_EFFECT_DURATION             = 300.0f;
const int    TRAVEL_SPEED_INCREASE_PERCENTAGE   = 75;
const int    TRAVEL_SPEED_DECREASE_PERCENTAGE   = 50;
const float  TRAVEL_IMPACT_DELAY_TIMER          = 0.5f;

void Travel_ApplyEffect(object oPlayer, int nMaterial, effect eEffect)
{
    if (GetSurfaceMaterial(GetLocation(oPlayer)) == nMaterial)
    {
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, HideEffectIcon(TagEffect(SupernaturalEffect(eEffect), TRAVEL_EFFECT_TAG)), oPlayer, TRAVEL_EFFECT_DURATION);
    }
}

// @NWNX[NWNX_ON_MATERIALCHANGE_AFTER]
void Travel_OnMaterialChange()
{
    object oPlayer = OBJECT_SELF;
    if (!GetIsPC(oPlayer) || GetIsDMExtended(oPlayer)) return;
    int nMaterial = EM_NWNXGetInt("MATERIAL_TYPE");
    effect eEffect;

    switch (nMaterial)
    {
        case 1: // Dirt
            eEffect = EffectMovementSpeedIncrease(TRAVEL_SPEED_INCREASE_PERCENTAGE);
            break;

        case 6: // Water
            eEffect = EffectMovementSpeedDecrease(TRAVEL_SPEED_DECREASE_PERCENTAGE);
            break;
    }

    RemoveEffectsWithTag(oPlayer, TRAVEL_EFFECT_TAG);

    if (GetEffectType(eEffect))
        DelayCommand(TRAVEL_IMPACT_DELAY_TIMER, Travel_ApplyEffect(oPlayer, nMaterial, eEffect));
}
