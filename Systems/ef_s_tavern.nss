/*
    Script: ef_s_tavern
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_musicman"
#include "ef_s_eventman"
#include "ef_s_session"

const string TAVERN_SCRIPT_NAME                 = "ef_s_tavern";

const string TAVERN_AREA_TAG                    = "AR_TAVERN";
const string TAVERN_INNSHOP_DOOR_TAG            = "DOOR_TAVERN_INNSHOP";
const string TAVERN_INNKITCHEN_DOOR_TAG         = "DOOR_TAVERN_INNKITCHEN";

const int TAVERN_TRACKID_MAIN                   = 132;
const int TAVERN_TRACKID_MUTED                  = 131;
const string TAVERN_TRACK_JSON_MAIN             = "TrackMain";
const string TAVERN_TRACK_JSON_MUTED            = "TrackMuted";

const string TAVERN_AREA_MUSIC_EVENT            = "TavernMusic";
const int TAVERN_AREA_MUSIC_EVENT_PRIORITY      = 10;
const float TAVERN_AREA_MUSIC_EVENT_FADETIME    = 1.0f;

const int TAVERN_SUBAREA_INN                    = 1;
const int TAVERN_SUBAREA_SHOP                   = 2;
const int TAVERN_SUBAREA_KITCHEN                = 3;

const string TAVERN_PLAYER_SUBAREA              = "PlayerSubArea";

const string TAVERN_DOOR_STATE                  = "DoorState";
const int TAVERN_DOOR_STATE_CLOSED              = 0;
const int TAVERN_DOOR_STATE_OPEN                = 1;

void Tavern_InitializeDoor(object oDoor);
void Tavern_SetDoorState(int nState, object oDoor = OBJECT_SELF);
int Tavern_GetDoorState(object oDoor);
int Tavern_GetSubAreaFromTileIndex(int nTileIndex);
void Tavern_SetPlayerSubArea(object oPlayer, int nSubArea);
int Tavern_GetPlayerSubArea(object oPlayer);

// @CORE[EF_SYSTEM_INIT]
void Tavern_Init()
{
    object oDataObject = GetDataObject(TAVERN_SCRIPT_NAME);
    int nUnixEpoch = SqlGetUnixEpoch();

    SetLocalJson(oDataObject, TAVERN_TRACK_JSON_MAIN, MusMan_JsonTrack(TAVERN_TRACKID_MAIN, nUnixEpoch));
    SetLocalJson(oDataObject, TAVERN_TRACK_JSON_MUTED, MusMan_JsonTrack(TAVERN_TRACKID_MUTED, nUnixEpoch, FALSE, TRUE, 0.75f));
}

// @CORE[EF_SYSTEM_LOAD]
void Tavern_Load()
{
    Tavern_InitializeDoor(GetObjectByTag(TAVERN_INNSHOP_DOOR_TAG));
    Tavern_InitializeDoor(GetObjectByTag(TAVERN_INNKITCHEN_DOOR_TAG));
}

// @MUSICEVENT[TAVERN_AREA_MUSIC_EVENT:TAVERN_AREA_MUSIC_EVENT_PRIORITY:TAVERN_AREA_MUSIC_EVENT_FADETIME]
json Tavern_GetAreaMusicTrack()
{
    object oPlayer = OBJECT_SELF;
    if (GetTag(GetArea(oPlayer)) == TAVERN_AREA_TAG)
    {
        int nSubArea = Tavern_GetPlayerSubArea(oPlayer);
        if ((nSubArea == TAVERN_SUBAREA_INN) ||
            (nSubArea == TAVERN_SUBAREA_SHOP && Tavern_GetDoorState(GetObjectByTag(TAVERN_INNSHOP_DOOR_TAG))) ||
            (nSubArea == TAVERN_SUBAREA_KITCHEN && Tavern_GetDoorState(GetObjectByTag(TAVERN_INNKITCHEN_DOOR_TAG))))
            return GetLocalJson(GetDataObject(TAVERN_SCRIPT_NAME), TAVERN_TRACK_JSON_MAIN);
        else
            return GetLocalJson(GetDataObject(TAVERN_SCRIPT_NAME), TAVERN_TRACK_JSON_MUTED);
    }

    return JsonNull();
}

// @EVENT[EVENT_SCRIPT_DOOR_ON_OPEN:DL]
void Tavern_OnDoorOpen()
{
    Tavern_SetDoorState(TAVERN_DOOR_STATE_OPEN);
    MusMan_UpdatePlayerMusicByEvent(TAVERN_AREA_MUSIC_EVENT);
}

// @EVENT[EVENT_SCRIPT_DOOR_ON_CLOSE:DL]
void Tavern_OnDoorClose()
{
    Tavern_SetDoorState(TAVERN_DOOR_STATE_CLOSED);
    MusMan_UpdatePlayerMusicByEvent(TAVERN_AREA_MUSIC_EVENT);
}

// @NWNX[NWNX_ON_SERVER_SEND_AREA_BEFORE]
void Tavern_OnServerSendAreaBefore()
{
    if (GetTag(EM_GetNWNXObject("AREA")) == TAVERN_AREA_TAG)
        EM_NWNXDispatchListInsert(OBJECT_SELF, TAVERN_SCRIPT_NAME, "NWNX_ON_CREATURE_TILE_CHANGE_BEFORE");
    else
        EM_NWNXDispatchListRemove(OBJECT_SELF, TAVERN_SCRIPT_NAME, "NWNX_ON_CREATURE_TILE_CHANGE_BEFORE");
}

// @NWNX[NWNX_ON_CREATURE_TILE_CHANGE_BEFORE:DL]
void Tavern_OnTileChange()
{
    Tavern_SetPlayerSubArea(OBJECT_SELF, Tavern_GetSubAreaFromTileIndex(EM_GetNWNXInt("NEW_TILE_INDEX")));
}

void Tavern_InitializeDoor(object oDoor)
{
    EM_SetObjectEventScript(oDoor, EVENT_SCRIPT_DOOR_ON_OPEN);
    EM_SetObjectEventScript(oDoor, EVENT_SCRIPT_DOOR_ON_CLOSE);
    EM_ObjectDispatchListInsert(oDoor, EM_GetObjectDispatchListId(TAVERN_SCRIPT_NAME, EVENT_SCRIPT_DOOR_ON_OPEN));
    EM_ObjectDispatchListInsert(oDoor, EM_GetObjectDispatchListId(TAVERN_SCRIPT_NAME, EVENT_SCRIPT_DOOR_ON_CLOSE));
}

void Tavern_SetDoorState(int nState, object oDoor = OBJECT_SELF)
{
    SetLocalInt(oDoor, TAVERN_DOOR_STATE, nState);
}

int Tavern_GetDoorState(object oDoor)
{
    return GetLocalInt(oDoor, TAVERN_DOOR_STATE);
}

int Tavern_GetSubAreaFromTileIndex(int nTileIndex)
{
    int nSubArea = TAVERN_SUBAREA_INN;
    switch (nTileIndex)
    {
        case 0: case 1: case 6: case 7: case 12: case 13:
            nSubArea = TAVERN_SUBAREA_SHOP;
            break;
        case 15: case 16:
            nSubArea = TAVERN_SUBAREA_KITCHEN;
            break;
    }
    return nSubArea;
}

void Tavern_SetPlayerSubArea(object oPlayer, int nSubArea)
{
    Session_SetInt(oPlayer, TAVERN_SCRIPT_NAME, TAVERN_PLAYER_SUBAREA, nSubArea);
}

int Tavern_GetPlayerSubArea(object oPlayer)
{
    return Session_GetInt(oPlayer, TAVERN_SCRIPT_NAME, TAVERN_PLAYER_SUBAREA);
}
