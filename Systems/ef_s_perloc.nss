/*
    Script: ef_s_perloc
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_playerdb"
#include "nwnx_player"

const string PERLOC_SCRIPT_NAME         = "ef_s_perloc";

const string PERLOC_AREA_DISABLED       = "EFPersistentLocationDisabled";

int PerLoc_GetAreaDisabled(object oArea);
void PerLoc_SetAreaDisabled(object oArea);
void PerLoc_SaveLocation(object oPlayer = OBJECT_SELF);
void PerLoc_RestoreLocation(object oPlayer = OBJECT_SELF);

int PerLoc_GetAreaDisabled(object oArea)
{
    return GetLocalInt(oArea, PERLOC_AREA_DISABLED);
}

void PerLoc_SetAreaDisabled(object oArea)
{
    SetLocalInt(oArea, PERLOC_AREA_DISABLED, TRUE);
}

// @NWNX[NWNX_ON_CLIENT_DISCONNECT_BEFORE]
// @GUIEVENT[GUIEVENT_AREA_LOADSCREEN_FINISHED]
void PerLoc_SaveLocation(object oPlayer = OBJECT_SELF)
{
    if (!GetIsObjectValid(oPlayer) || GetIsDMExtended(oPlayer))
        return;

    object oMaster = GetMaster(oPlayer);
    if (GetIsObjectValid(oMaster)) oPlayer = oMaster;

    if (!PerLoc_GetAreaDisabled(GetArea(oPlayer)))
        PlayerDB_SetLocation(oPlayer, PERLOC_SCRIPT_NAME, "Location", GetLocation(oPlayer));
}

// @NWNX[NWNX_ON_ELC_VALIDATE_CHARACTER_AFTER]
void PerLoc_RestoreLocation(object oPlayer = OBJECT_SELF)
{
    if (GetIsDMExtended(oPlayer))
        return;

    location locPlayer = PlayerDB_GetLocation(oPlayer, PERLOC_SCRIPT_NAME, "Location");
    if (GetIsLocationValid(locPlayer))
        NWNX_Player_SetSpawnLocation(oPlayer, locPlayer);
}
