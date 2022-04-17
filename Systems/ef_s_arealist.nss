/*
    Script: ef_s_arealist
    Author: Daz

    Description: A system that adds a player menu button that lists all areas.
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"

const string AL_LOG_TAG                 = "AreaList";
const string AL_SCRIPT_NAME             = "ef_s_arealist";

const string AL_WINDOW_ID               = "AREA_LIST";
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
       NB_StartList(NuiBind("buttons"), 24.0f, TRUE);
        NB_StartListTemplateCell(340.0f, FALSE);
         NB_StartElement(NuiButton(NuiBind("buttons")));
          NB_SetId(AL_ELEMENT_AREA_BUTTON);
          NB_SetDimensions(340.0f, 24.0f);
         NB_End();
        NB_End();
       NB_End();
      NB_End();
     NB_End();
    return NB_FinalizeWindow();
}

void AL_RefreshAreaList()
{
    json jAreaNames = JsonArray(), jAreaIds = JsonArray();
    object oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        jAreaNames = JsonArrayInsertString(jAreaNames, GetName(oArea) + " (" + GetTag(oArea) + ")");
        jAreaIds = JsonArrayInsertString(jAreaIds, ObjectToString(oArea));
        oArea = GetNextArea();
    }

    NWM_SetBind("buttons", jAreaNames);
    NWM_SetUserData("areas", jAreaIds);
}

// @NWMEVENT[AL_WINDOW_ID:NUI_EVENT_CLICK:AL_ELEMENT_REFRESH_BUTTON]
void AL_ClickRefreshButton()
{
    AL_RefreshAreaList();
}

// @NWMEVENT[AL_WINDOW_ID:NUI_EVENT_CLICK:AL_ELEMENT_AREA_BUTTON]
void AL_ClickAreaButton()
{
    object oPlayer = OBJECT_SELF;
    object oArea = StringToObject(JsonArrayGetString(NWM_GetUserData("areas"), NuiGetEventArrayIndex()));
    if (GetIsObjectValid(oArea))
    {
        ClearAllActions();
        JumpToLocation(Location(oArea, GetAreaCenterPosition(oArea), GetFacing(oPlayer)));
    }
}

// @PMBUTTON[Area List:Display a list of all areas]
void AL_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, AL_WINDOW_ID))
        NWM_CloseWindow(oPlayer, AL_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, AL_WINDOW_ID))
        AL_RefreshAreaList();
}

