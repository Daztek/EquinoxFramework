/*
    Script: es_q_playerstats
    Author: Daz

    Description: An Equinox Framework System that saves various player stats to
                 their .bic file when they log out and sets restores them when they log back in.
*/

#include "ef_i_core"
#include "ef_s_playerdb"
#include "nwnx_player"

const string PLAYERSTATS_LOG_TAG            = "PlayerStats";
const string PLAYERSTATS_SCRIPT_NAME        = "ef_s_playerstats";

// @EVENT[NWNX_ON_CLIENT_DISCONNECT_BEFORE]
void PlayerStats_SaveStats()
{
    object oPlayer = OBJECT_SELF;

    if (!GetIsObjectValid(oPlayer) || GetIsDM(oPlayer) || GetIsDMPossessed(oPlayer))
        return;

    object oMaster = GetMaster(oPlayer);
    if (GetIsObjectValid(oMaster)) oPlayer = oMaster;

    PlayerDB_SetInt(oPlayer, PLAYERSTATS_SCRIPT_NAME, "Dead", GetIsDead(oPlayer));
    PlayerDB_SetInt(oPlayer, PLAYERSTATS_SCRIPT_NAME, "HP", GetCurrentHitPoints(oPlayer));
    PlayerDB_SetLocation(oPlayer, PLAYERSTATS_SCRIPT_NAME, "Location", GetLocation(oPlayer));
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER]
void PlayerStats_RestoreHitPoints()
{
    object oPlayer = GetEnteringObject();

    if (GetIsDM(oPlayer))
        return;

    if (PlayerDB_GetInt(oPlayer, PLAYERSTATS_SCRIPT_NAME, "Dead"))
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), oPlayer);
    else
    {
        int nHitPoints = PlayerDB_GetInt(oPlayer, PLAYERSTATS_SCRIPT_NAME, "HP");
        int nMaxHitPoints = GetMaxHitPoints(oPlayer);

        if (nHitPoints > 0 && nHitPoints < nMaxHitPoints)
           SetCurrentHitPoints(oPlayer, nHitPoints);
    }
}

// @EVENT[NWNX_ON_ELC_VALIDATE_CHARACTER_AFTER]
void PlayerStats_RestoreLocation()
{
    object oPlayer = OBJECT_SELF;

    if (GetIsDM(oPlayer))
        return;

    NWNX_Player_SetSpawnLocation(oPlayer, PlayerDB_GetLocation(oPlayer, PLAYERSTATS_SCRIPT_NAME, "Location"));
}

