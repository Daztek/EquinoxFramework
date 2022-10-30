/*
    Script: ef_s_radial
    Author: Daz

    @SKIPSYSTEM
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"

const string RAD_SCRIPT_NAME            = "ef_s_radial";

const string RAD_PLACEABLE_WINDOW_ID    = "RAD_PLACEABLE";
const string RAD_SPACER_ID_CLOSE        = "spacer_close";
const string RAD_BUTTON_ID_INTERACT     = "btn_interact";

// @EVENT[EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER]
void Rad_OnClientEnter()
{
    SetGuiPanelDisabled(GetEnteringObject(), GUI_PANEL_RADIAL_PLACEABLE, TRUE, OBJECT_INVALID);
}

// @GUIEVENT[GUIEVENT_DISABLED_PANEL_ATTEMPT_OPEN]
void Rad_OnRadialAttemptOpen()
{
    if (GetLastGuiEventInteger() == GUI_PANEL_RADIAL_PLACEABLE)
    {
        object oPlayer = OBJECT_SELF;
        if (NWM_GetIsWindowOpen(oPlayer, RAD_PLACEABLE_WINDOW_ID))
            NWM_CloseWindow(oPlayer, RAD_PLACEABLE_WINDOW_ID);
        else if (NWM_OpenWindow(oPlayer, RAD_PLACEABLE_WINDOW_ID))
        {
            NuiSetClickthroughProtection(oPlayer, 0.25f);
            NWM_SetUserDataObject("Target", GetLastGuiEventObject());
        }
    }
}

// @NWMWINDOW[RAD_PLACEABLE_WINDOW_ID]
json Rad_CreatePlaceableWindow()
{
    NB_InitializeWindow(JsonNull());
    NB_SetWindowTitlebarHidden();
    NB_SetWindowTransparent(JsonBool(TRUE));
    //NB_SetWindowBorder(JsonBool(FALSE));
    NB_SetWindowGeometry(NuiRect(-3.0f, -3.0f, 150.0f, 150.0f));
        NB_StartColumn();
            NB_StartRow();
                NB_StartElement(NuiSpacer());
                    NB_SetId(RAD_SPACER_ID_CLOSE);
                NB_End();
                NB_StartElement(NuiButton(JsonString("Interact")));
                    NB_SetId(RAD_BUTTON_ID_INTERACT);
                    NB_SetDimensions(100.0f, 24.0f);
                NB_End();
                NB_StartElement(NuiSpacer());
                    NB_SetId(RAD_SPACER_ID_CLOSE);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiSpacer());
                    NB_SetId(RAD_SPACER_ID_CLOSE);
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[RAD_PLACEABLE_WINDOW_ID:NUI_EVENT_MOUSEUP:RAD_SPACER_ID_CLOSE]
void Rad_GroupMouseUp()
{
    object oPlayer = OBJECT_SELF;
    if (NuiGetClickthroughProtection(oPlayer))
        return;

    if (NuiGetIsRightMouseButton(NuiGetEventPayload()))
        NWM_Destroy();
}

// @NWMEVENT[RAD_PLACEABLE_WINDOW_ID:NUI_EVENT_CLICK:RAD_BUTTON_ID_INTERACT]
void Rad_SitButtonClick()
{
    object oPlayer = OBJECT_SELF;
    object oPlaceable = NWM_GetUserDataObject("Target");

    AssignCommand(oPlayer, ClearAllActions());
    AssignCommand(oPlayer, ActionInteractObject(oPlaceable));
    NWM_Destroy();
}
