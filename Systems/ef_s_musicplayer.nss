/*
    Script: ef_s_musicplayer
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_playermenu"
#include "ef_s_session"
#include "ef_s_musicman"

const string MP_SCRIPT_NAME                     = "ef_s_musicplayer";

const string MP_NUI_WINDOW_ID                   = "MUSICPLAYER";
const string MP_NUI_ELEMENT_STOP_BUTTON         = "btn_stop";
const string MP_NUI_ELEMENT_TRACK_BUTTON        = "btn_track";
const string MP_NUI_BIND_TRACKS                 = "bind_tracks";
const string MP_NUI_BIND_TRACK_PLAYING          = "bind_track_playing";

const string MP_TRACK_ID_ARRAY                  = "TrackIdArray";
const string MP_TRACK_NAME_ARRAY                = "TrackNameArray";
const string MP_TRACK_PLAYING_ARRAY             = "TrackPlayingArray";

const string MP_PLAYER_TRACK                    = "PlayerTrack";

const string MP_MUSIC_EVENT                     = "MusicPlayerMusic";
const int MP_MUSIC_EVENT_PRIORITY               = 100;
const float MP_MUSIC_EVENT_FADE_TIME            = 1.0f;

void MP_LoadTrackData();
void MP_SetPlayerTrack(object oPlayer, int nTrackId);
json MP_GetPlayerTrack(object oPlayer);
void MP_DeletePlayerTrack(object oPlayer);

// @CORE[EF_SYSTEM_LOAD]
void MP_Load()
{
    MP_LoadTrackData();
}

// @NWMWINDOW[MP_NUI_WINDOW_ID]
json MP_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 400.0f, 500.0f));
    NB_SetWindowTitle(JsonString("Music Player"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("Stop")));
                    NB_SetId(MP_NUI_ELEMENT_STOP_BUTTON);
                    NB_SetDimensions(380.0f, 30.0f);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartList(NuiBind(MP_NUI_BIND_TRACKS), 32.0f, TRUE);
                    NB_StartListTemplateCell(340.0f, FALSE);
                        NB_StartElement(NuiButton(NuiBind(MP_NUI_BIND_TRACKS)));
                            NB_SetId(MP_NUI_ELEMENT_TRACK_BUTTON);
                            NB_SetEncouraged(NuiBind(MP_NUI_BIND_TRACK_PLAYING));
                            NB_SetDimensions(340.0f, 32.0f);
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[MP_NUI_WINDOW_ID:NUI_EVENT_CLICK:MP_NUI_ELEMENT_TRACK_BUTTON]
void MP_ClickTrackButton()
{
    object oPlayer = OBJECT_SELF;
    object oDataObject = GetDataObject(MP_SCRIPT_NAME);
    int nIndex = NuiGetEventArrayIndex();
    int nTrackId = GetIntFromLocalJsonArray(oDataObject, MP_TRACK_ID_ARRAY, nIndex);

    if (nTrackId)
    {
        MP_SetPlayerTrack(oPlayer, nTrackId);
        MusMan_UpdatePlayerMusic(oPlayer);
        NWM_SetBind(MP_NUI_BIND_TRACK_PLAYING, JsonArraySetBool(GetLocalJson(oDataObject, MP_TRACK_PLAYING_ARRAY), nIndex, TRUE));
    }
}

// @NWMEVENT[MP_NUI_WINDOW_ID:NUI_EVENT_CLICK:MP_NUI_ELEMENT_STOP_BUTTON]
void MP_ClickStopButton()
{
    object oPlayer = OBJECT_SELF;
    MP_DeletePlayerTrack(oPlayer);
    MusMan_UpdatePlayerMusic(oPlayer);
    NWM_SetBind(MP_NUI_BIND_TRACK_PLAYING, GetLocalJson(GetDataObject(MP_SCRIPT_NAME), MP_TRACK_PLAYING_ARRAY));
}

// @PMBUTTON[Music Player:Play some rad tunes!]
void MP_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, MP_NUI_WINDOW_ID))
        NWM_CloseWindow(oPlayer, MP_NUI_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, MP_NUI_WINDOW_ID))
    {
        object oDataObject = GetDataObject(MP_SCRIPT_NAME);
        NWM_SetBind(MP_NUI_BIND_TRACKS, GetLocalJsonArray(oDataObject, MP_TRACK_NAME_ARRAY));

        json jPlayerTrack = MP_GetPlayerTrack(oPlayer);
        if (JsonGetType(jPlayerTrack))
        {
            NWM_SetBind(MP_NUI_BIND_TRACK_PLAYING,
                        JsonArraySetBool(GetLocalJson(oDataObject, MP_TRACK_PLAYING_ARRAY),
                        JsonObjectGetInt(jPlayerTrack, "trackid") - 1, TRUE));
        }
    }
}

// @MUSICEVENT[MP_MUSIC_EVENT:MP_MUSIC_EVENT_PRIORITY:MP_MUSIC_EVENT_FADE_TIME]
json MP_MusicEventGetTrack()
{
    return MP_GetPlayerTrack(OBJECT_SELF);
}

void MP_LoadTrackData()
{
    object oDataObject = GetDataObject(MP_SCRIPT_NAME);
    sqlquery sql = SqlPrepareQueryModule("SELECT trackid, name FROM " + MusMan_GetAmbientMusic2DATable() + ";");
    while (SqlStep(sql))
    {
        InsertIntToLocalJsonArray(oDataObject, MP_TRACK_ID_ARRAY, SqlGetInt(sql, 0));
        InsertStringToLocalJsonArray(oDataObject, MP_TRACK_NAME_ARRAY, SqlGetString(sql, 1));
    }

    SetLocalJson(oDataObject, MP_TRACK_PLAYING_ARRAY, GetJsonArrayOfSize(JsonGetLength(GetLocalJsonArray(oDataObject, MP_TRACK_ID_ARRAY)), JsonBool(FALSE)));
}

void MP_SetPlayerTrack(object oPlayer, int nTrackId)
{
    Session_SetJson(oPlayer, MP_SCRIPT_NAME, MP_PLAYER_TRACK, MusMan_JsonTrack(nTrackId));
}

json MP_GetPlayerTrack(object oPlayer)
{
    return Session_GetJson(oPlayer, MP_SCRIPT_NAME, MP_PLAYER_TRACK);
}

void MP_DeletePlayerTrack(object oPlayer)
{
    Session_DeleteJson(oPlayer, MP_SCRIPT_NAME, MP_PLAYER_TRACK);
}
