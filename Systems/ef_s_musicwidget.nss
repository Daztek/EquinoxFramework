/*
    Script: ef_s_musicwidget
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_musicman"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_playerdb"

const string MUSICWIDGET_SCRIPT_NAME                        = "ef_s_musicwidget";
const string MUSICWIDGET_NUI_WIDGET_WINDOW_ID               = "MUSICWIDGET";
const string MUSICWIDGET_NUI_BIND_VOLUME                    = "bind_volume";
const string MUSICWIDGET_VOLUME_PLAYERDB_VARNAME            = "Volume";
const int MUSICWIDGET_SLIDER_STEP_SIZE                      = 5;

// @NWMWINDOW[MUSICWIDGET_NUI_WIDGET_WINDOW_ID]
json MusicWidget_CreateWindow()
{
    NB_InitializeWindow(NuiRect(0.0f, -1.0f, 140.0f, 32.0f));
    NB_SetWindowTitlebarHidden();
    NB_SetWindowBorder(JsonBool(FALSE));
    NB_SetWindowTransparent(JsonBool(TRUE));
        NB_StartRow();
            NB_StartElement(NuiImage(JsonString("ife_bardsong"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                NB_SetDimensions(20.0f, 20.0f);
            NB_End();
            NB_StartElement(NuiSlider(NuiBind(MUSICWIDGET_NUI_BIND_VOLUME), JsonInt(0), JsonInt(100), JsonInt(MUSICWIDGET_SLIDER_STEP_SIZE)));
                NB_SetDimensions(100.0f, 20.0f);
            NB_End();
            NB_AddSpacer();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[MUSICWIDGET_NUI_WIDGET_WINDOW_ID:NUI_EVENT_WATCH:MUSICWIDGET_NUI_BIND_VOLUME]
void MusicWidget_WatchVolumeSlider()
{
    object oPlayer = OBJECT_SELF;
    int nVolume = NWM_GetBindInt(MUSICWIDGET_NUI_BIND_VOLUME);
    PlayerDB_SetInt(oPlayer, MUSICWIDGET_SCRIPT_NAME, MUSICWIDGET_VOLUME_PLAYERDB_VARNAME, nVolume);
    MusMan_SetPlayerVolumeModifier(oPlayer, nVolume / 100.0f);
    MusMan_RefreshCurrentChannelVolume(oPlayer);
}

// @GUIEVENT[GUIEVENT_AREA_LOADSCREEN_FINISHED]
void MusicWidget_AreaLoadScreenFinished()
{
    object oPlayer = GetLastGuiEventPlayer();
    if (!NWM_GetIsWindowOpen(oPlayer, MUSICWIDGET_NUI_WIDGET_WINDOW_ID) && NWM_OpenWindow(oPlayer, MUSICWIDGET_NUI_WIDGET_WINDOW_ID))
    {
        NWM_SetBind(NUI_WINDOW_GEOMETRY_BIND, NuiRect(0.0f, GetPlayerDeviceProperty(oPlayer, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT) - 32.0f, 140.0f, 32.0f));
        NWM_SetBindWatch(MUSICWIDGET_NUI_BIND_VOLUME);
        NWM_SetBindInt(MUSICWIDGET_NUI_BIND_VOLUME, PlayerDB_GetInt(oPlayer, MUSICWIDGET_SCRIPT_NAME, MUSICWIDGET_VOLUME_PLAYERDB_VARNAME, 100));
    }
}
