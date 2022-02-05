/*
    Script: ef_s_arealist
    Author: Daz

    Description: A system that adds a PlayerMenu button that lists all areas.
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"

const string AL_LOG_TAG                 = "AreaList";
const string AL_SCRIPT_NAME             = "ef_s_arealist";

const string AL_WINDOW_ID               = "AREA_LIST";
const string AL_BIND_AREA_BUTTON        = "btn_area";

// @NWMWINDOW[AL_WINDOW_ID]
json AL_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 240.0f, 300.0f));
    NB_SetWindowTitle(JsonString("Area List"));
     NB_StartColumn();
      NB_StartRow();
       NB_StartList(NuiBind("buttons"), 24.0f, TRUE);
        NB_StartListTemplateCell(180.0f, FALSE);
         NB_StartElement(NuiButton(NuiBind("buttons")));
          NB_SetId(AL_BIND_AREA_BUTTON);
          NB_SetWidth(180.0f);
          NB_SetHeight(24.0f);
         NB_End();
        NB_End();
       NB_End();
      NB_End();
     NB_End();
    return NB_FinalizeWindow();
}

// @PMBUTTON[Area List]
void AL_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, AL_WINDOW_ID))
        NWM_CloseWindow(oPlayer, AL_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, AL_WINDOW_ID))
    {
        json jAreaNames = JsonArray(), jAreaIds = JsonArray();
        object oArea = GetFirstArea();
        while (GetIsObjectValid(oArea))
        {
            jAreaNames = JsonArrayInsertString(jAreaNames, GetName(oArea));
            jAreaIds = JsonArrayInsertString(jAreaIds, ObjectToString(oArea));
            oArea = GetNextArea();
        }

        NWM_SetBind("buttons", jAreaNames);
        NWM_SetUserData("areas", jAreaIds);
    }
}

// @NWMEVENT[AL_WINDOW_ID:NUI_EVENT_CLICK:AL_BIND_AREA_BUTTON]
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

