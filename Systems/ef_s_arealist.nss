/*
    Script: ef_s_arealist
    Author: Daz

    Description: A system that adds a player menu button that lists all areas.
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"

const string AL_SCRIPT_NAME             = "ef_s_arealist";

const string AL_WINDOW_ID               = "AREA_LIST";
const string AL_NUI_BIND_BUTTONS        = "buttons";
const string AL_ELEMENT_REFRESH_BUTTON  = "btn_refresh";
const string AL_ELEMENT_AREA_BUTTON     = "btn_area";

// @NWMWINDOW[AL_WINDOW_ID]
json AL_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 400.0f, 500.0f));
    NB_SetWindowTitle(JsonString("Area List"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("Refresh")));
                    NB_SetId(AL_ELEMENT_REFRESH_BUTTON);
                    NB_SetDimensions(380.0f, 30.0f);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartList(NuiBind(AL_NUI_BIND_BUTTONS), 24.0f, TRUE);
                    NB_StartListTemplateCell(340.0f, FALSE);
                        NB_StartElement(NuiButton(NuiBind(AL_NUI_BIND_BUTTONS)));
                            NB_SetId(AL_ELEMENT_AREA_BUTTON);
                            NB_SetDimensions(340.0f, 24.0f);
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[AL_WINDOW_ID:NUI_EVENT_CLICK:AL_ELEMENT_REFRESH_BUTTON]
void AL_RefreshAreaList()
{
    json jAreaNames = JsonArray(), jAreaIds = JsonArray();
    object oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        JsonArrayInsertStringInplace(jAreaNames, GetName(oArea) + " (" + GetTag(oArea) + ")");
        JsonArrayInsertStringInplace(jAreaIds, ObjectToString(oArea));
        oArea = GetNextArea();
    }

    NWM_SetBind(AL_NUI_BIND_BUTTONS, jAreaNames);
    NWM_SetUserData("areas", jAreaIds);
}

// @NWMEVENT[AL_WINDOW_ID:NUI_EVENT_CLICK:AL_ELEMENT_AREA_BUTTON]
void AL_ClickAreaButton()
{
    object oPlayer = OBJECT_SELF;
    object oArea = StringToObject(JsonArrayGetString(NWM_GetUserData("areas"), NuiGetEventArrayIndex()));
    if (GetIsObjectValid(oArea))
    {
        ClearAllActions();
        ActionJumpToLocation(Location(oArea, GetAreaCenterPosition(oArea), GetFacing(oPlayer)));
    }
}

// @PMBUTTON[Area List:Display a list of all areas]
void AL_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_ToggleWindow(oPlayer, AL_WINDOW_ID))
        AL_RefreshAreaList();
}
