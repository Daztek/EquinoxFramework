/*
    Script: ef_s_playermenu
    Author: Daz

    // @ PMBUTTON[Button Name:Tooltip Text]
    @ANNOTATION[@(PMBUTTON)\[([\w\s]+)(?:\:?([\w\s]*))\][\n|\r]+[a-z]+\s([\w]+)\(]
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"

const string PM_LOG_TAG             = "PlayerMenu";
const string PM_SCRIPT_NAME         = "ef_s_playermenu";

const string PM_WINDOW_ID           = "PLAYER_MENU";
const string PM_BIND_COMMAND_BUTTON = "btn_command";

const string PM_BUTTON_ARRAY        = "ButtonArray";
const string PM_TOOLTIP_ARRAY       = "TooltipArray";
const string PM_FUNCTION_ARRAY      = "FunctionArray";

// @CORE[EF_SYSTEM_INIT]
void PM_Init()
{
    EFCore_ExecuteFunctionOnAnnotationData(PM_SCRIPT_NAME, "PMBUTTON", "PM_RegisterButton({DATA});");
}

// @NWMWINDOW[PM_WINDOW_ID]
json PM_CreateWindow()
{
    NB_InitializeWindow(JsonNull());
    NB_SetWindowTitlebarHidden();
    NB_SetWindowGeometry(NuiRect(10.0f, 10.0f, 240.0f, 480.0f));
        NB_StartColumn();
            NB_StartRow();
                NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                    NB_SetHeight(25.0f);
                    NB_AddElement(NuiLabel(JsonString("Player Menu"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartList(NuiBind("buttons"), 25.0f, TRUE);
                    NB_StartListTemplateCell(180.0f, FALSE);
                        NB_StartElement(NuiButton(NuiBind("buttons")));
                            NB_SetId(PM_BIND_COMMAND_BUTTON);
                            NB_SetDimensions(180.0f, 25.0f);
                            NB_SetTooltip(NuiBind("tooltips"));
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @EVENT[NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE]
void PM_OnTogglePauseEvent()
{
    object oPlayer = OBJECT_SELF;

    if (NWM_GetIsWindowOpen(oPlayer, PM_WINDOW_ID))
        NWM_CloseWindow(oPlayer,PM_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, PM_WINDOW_ID))
    {
        object oDataObject = GetDataObject(PM_SCRIPT_NAME);
        NWM_SetBind("buttons", GetLocalJsonArray(oDataObject, PM_BUTTON_ARRAY));
        NWM_SetBind("tooltips", GetLocalJsonArray(oDataObject, PM_TOOLTIP_ARRAY));
    }
}

// @GUIEVENT[GUIEVENT_COMPASS_CLICK]
void PM_OnCompassClick()
{
    PM_OnTogglePauseEvent();
}

// @NWMEVENT[PM_WINDOW_ID:NUI_EVENT_CLICK:PM_BIND_COMMAND_BUTTON]
void PM_OnCommandButtonClick()
{
    object oPlayer = OBJECT_SELF;
    string sScriptChunk = GetStringFromLocalJsonArray(GetDataObject(PM_SCRIPT_NAME), PM_FUNCTION_ARRAY, NuiGetEventArrayIndex());

    if (sScriptChunk != "")
        ExecuteCachedScriptChunk(sScriptChunk, oPlayer, FALSE);
}

void PM_RegisterButton(json jButton)
{
    string sSystem = JsonArrayGetString(jButton, 0);
    string sButton = JsonArrayGetString(jButton, 2);
    string sTooltip = JsonArrayGetString(jButton, 3);
    string sFunction = JsonArrayGetString(jButton, 4);

    object oDataObject = GetDataObject(PM_SCRIPT_NAME);
    InsertStringToLocalJsonArray(oDataObject, PM_BUTTON_ARRAY, sButton);
    InsertStringToLocalJsonArray(oDataObject, PM_TOOLTIP_ARRAY, sTooltip);
    InsertStringToLocalJsonArray(oDataObject, PM_FUNCTION_ARRAY, nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction)));

    WriteLog(PM_LOG_TAG, "* System '" + sSystem + "' registered player menu button '" + sButton + "' with tooltip: \""  + sTooltip + "\"");
}

