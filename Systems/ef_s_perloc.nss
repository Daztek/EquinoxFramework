/*
    Script: ef_s_perloc
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_playerdb"
#include "nwnx_player"

const string PERLOC_LOG_TAG             = "PersistentLocation";
const string PERLOC_SCRIPT_NAME         = "ef_s_perloc";

const string PERLOC_AREA_DISABLED       = "EFPersistentLocationDisabled";

int PerLoc_GetAreaDisabled(object oArea);
void PerLoc_SetAreaDisabled(object oArea);

// @NWNX[NWNX_ON_CLIENT_DISCONNECT_BEFORE]
void PerLoc_SaveLocation()
{
    object oPlayer = OBJECT_SELF;

    if (!GetIsObjectValid(oPlayer) || GetIsDM(oPlayer) || GetIsDMPossessed(oPlayer))
        return;

    object oMaster = GetMaster(oPlayer);
    if (GetIsObjectValid(oMaster)) oPlayer = oMaster;
  
    if (!PerLoc_GetAreaDisabled(GetArea(oPlayer)))
        PlayerDB_SetLocation(oPlayer, PERLOC_SCRIPT_NAME, "Location", GetLocation(oPlayer));
}

// @NWNX[NWNX_ON_ELC_VALIDATE_CHARACTER_AFTER]
void PerLoc_RestoreLocation()
{
    object oPlayer = OBJECT_SELF;

    if (GetIsDM(oPlayer))
        return;

    NWNX_Player_SetSpawnLocation(oPlayer, PlayerDB_GetLocation(oPlayer, PERLOC_SCRIPT_NAME, "Location"));
}

int PerLoc_GetAreaDisabled(object oArea)
{
    return GetLocalInt(oArea, PERLOC_AREA_DISABLED);
}

void PerLoc_SetAreaDisabled(object oArea)
{
    SetLocalInt(oArea, PERLOC_AREA_DISABLED, TRUE);
}
