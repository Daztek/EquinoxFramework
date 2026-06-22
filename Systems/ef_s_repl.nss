/*
    Script: ef_s_repl
    Author: Daz
*/

#include "ef_c_dazscript"
#include "ef_c_profiler"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_session"
#include "ef_s_targetmode"

const string REPL_SCRIPT_NAME                           = "ef_s_repl";
const string REPL_WINDOW_ID                             = "REPL";

const string REPL_NUI_ELEMENT_CLEAR_BUTTON              = "btn_clear";
const string REPL_NUI_ELEMENT_INPUT                     = "input_text";
const string REPL_NUI_ELEMENT_ENTER_BUTTON              = "btn_enter";
const string REPL_NUI_ELEMENT_TARGET_BUTTON             = "btn_target";
const string REPL_NUI_ELEMENT_CMD_HISTORY_UP_BUTTON     = "btn_cmdhistory_up";
const string REPL_NUI_ELEMENT_CMD_HISTORY_DOWN_BUTTON   = "btn_cmdhistory_down";

const string REPL_NUI_BIND_CONSOLE                      = "bind_console";
const string REPL_NUI_BIND_INPUT                        = "bind_input";
const string REPL_NUI_BIND_PROFILER                     = "bind_profiler";

const string REPL_SESSION_STACK_KEY                     = "ReplStack";
const string REPL_USERDATA_CONSOLE_KEY                  = "ReplConsole";
const string REPL_USERDATA_TARGET_KEY                   = "ReplTarget";
const string REPL_USERDATA_CMD_HISTORY_KEY              = "ReplCommandHistory";
const string REPL_USERDATA_CMD_HISTORY_INDEX_KEY        = "ReplCommandHistoryIndex";
const string REPL_USERDATA_CMD_HISTORY_SAVED_INPUT_KEY  = "ReplCommandHistorySavedInput";

const string REPL_TARGET_MODE                           = "ReplTargetMode";
const int REPL_CMD_HISTORY_SIZE                         = 25;


void Repl_Init(object oPlayer);
string Repl_Interpret(string sInput);
void Repl_AppendToConsole(json jLine);
void Repl_InjectStackEntry(json jStack, string sStackVarName, string sREPLName);
void Repl_AddCommandToHistory(string sInput);

// @NWMWINDOW[REPL_WINDOW_ID]
json Repl_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 800.0f, 600.0f));
    NB_SetWindowTitle(JsonString("DazScript REPL"));
        NB_StartColumn();
            NB_StartRow();
                NB_AddSpacer();
                NB_StartElement(NuiLabel(NuiBind(REPL_NUI_BIND_PROFILER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(600.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiButton(JsonString("Target")));
                    NB_SetId(REPL_NUI_ELEMENT_TARGET_BUTTON);
                    NB_SetDimensions(80.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiButton(JsonString("Clear")));
                    NB_SetId(REPL_NUI_ELEMENT_CLEAR_BUTTON);
                    NB_SetDimensions(80.0f, 32.0f);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartList(NuiBind(REPL_NUI_BIND_CONSOLE), 16.0f, TRUE);
                    NB_StartListTemplateCell(700.0f, TRUE);
                        NB_StartElement(NuiLabel(NuiBind(REPL_NUI_BIND_CONSOLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_SetDimensions(700.0f, 16.0f);
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiTextEdit(JsonString(". . ."), NuiBind(REPL_NUI_BIND_INPUT), 1024, FALSE, FALSE));
                    NB_SetId(REPL_NUI_ELEMENT_INPUT);
                    NB_SetDimensions(620.0f, 32.0f);
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("^")));
                    NB_SetId(REPL_NUI_ELEMENT_CMD_HISTORY_UP_BUTTON);
                    NB_SetDimensions(32.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiButton(JsonString("v")));
                    NB_SetId(REPL_NUI_ELEMENT_CMD_HISTORY_DOWN_BUTTON);
                    NB_SetDimensions(32.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiButton(JsonString("Enter")));
                    NB_SetId(REPL_NUI_ELEMENT_ENTER_BUTTON);
                    NB_SetDimensions(80.0f, 32.0f);
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @PMBUTTON[DazScript REPL:Commit Coding Crimes]
void Repl_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_ToggleWindow(oPlayer, REPL_WINDOW_ID))
    {
        Repl_Init(oPlayer);
    }
}

// @TARGETMODE[REPL_TARGET_MODE]
void Repl_OnTargetSelected()
{
    if (NWM_GetIsWindowOpen(OBJECT_SELF, REPL_WINDOW_ID, TRUE))
    {
        NWM_SetUserDataObject(REPL_USERDATA_TARGET_KEY, GetTargetingModeSelectedObject());
    }
}

// @NWMEVENT[REPL_WINDOW_ID:NUI_EVENT_CLICK:REPL_NUI_ELEMENT_ENTER_BUTTON]
void Repl_ClickEnterButton()
{
    object oPlayer = OBJECT_SELF;
    json jInput = NWM_GetBind(REPL_NUI_BIND_INPUT);
    string sInput = JsonGetString(jInput);

    if (sInput != "")
    {
        Repl_AddCommandToHistory(sInput);

        string sOutput = Repl_Interpret(sInput);
        Repl_AppendToConsole(JsonString("> " + sInput));
        if (sOutput != "")
            Repl_AppendToConsole(JsonString(sOutput));
    }

    NWM_SetBind(REPL_NUI_BIND_INPUT, JsonString(""));
}

// @NWMEVENT[REPL_WINDOW_ID:NUI_EVENT_CLICK:REPL_NUI_ELEMENT_CLEAR_BUTTON]
void Repl_ClickClearButton()
{
    Repl_Init(OBJECT_SELF);
}

// @NWMEVENT[REPL_WINDOW_ID:NUI_EVENT_CLICK:REPL_NUI_ELEMENT_TARGET_BUTTON]
void Repl_ClickTargetButton()
{
    TargetMode_Enter(OBJECT_SELF, REPL_TARGET_MODE);
}

// @NWMEVENT[REPL_WINDOW_ID:NUI_EVENT_CLICK:REPL_NUI_ELEMENT_CMD_HISTORY_UP_BUTTON]
// @NWMEVENT[REPL_WINDOW_ID:NUI_EVENT_CLICK:REPL_NUI_ELEMENT_CMD_HISTORY_DOWN_BUTTON]
void Repl_ClickCommandHistoryUpDownButton()
{
    int nDelta = NuiGetEventElement() == REPL_NUI_ELEMENT_CMD_HISTORY_UP_BUTTON ? - 1 : 1;
    json jCommands = NWM_GetUserData(REPL_USERDATA_CMD_HISTORY_KEY);

    int nLength = JsonGetLength(jCommands);
    if (nLength <= 0)
        return;

    int nIndex = NWM_GetUserDataInt(REPL_USERDATA_CMD_HISTORY_INDEX_KEY);

    if (nIndex == nLength && nDelta < 0)
        NWM_SetUserDataString(REPL_USERDATA_CMD_HISTORY_SAVED_INPUT_KEY, NWM_GetBindString(REPL_NUI_BIND_INPUT));

    nIndex += nDelta;

    if (nIndex < 0)
        nIndex = 0;
    if (nIndex > nLength)
        nIndex = nLength;

    NWM_SetUserDataInt(REPL_USERDATA_CMD_HISTORY_INDEX_KEY, nIndex);

    if (nIndex == nLength)
        NWM_SetBindString(REPL_NUI_BIND_INPUT, NWM_GetUserDataString(REPL_USERDATA_CMD_HISTORY_SAVED_INPUT_KEY));
    else
        NWM_SetBind(REPL_NUI_BIND_INPUT, JsonArrayGet(jCommands, nIndex));
}

void Repl_Init(object oPlayer)
{
    Session_SetJson(oPlayer, REPL_SCRIPT_NAME, REPL_SESSION_STACK_KEY, JsonObject());
    NWM_SetUserDataInt(REPL_USERDATA_CMD_HISTORY_INDEX_KEY, 0);
    NWM_SetUserData(REPL_USERDATA_CMD_HISTORY_KEY, JsonArray());
    NWM_SetUserDataString(REPL_USERDATA_CMD_HISTORY_SAVED_INPUT_KEY, "");
    NWM_SetUserData(REPL_USERDATA_CONSOLE_KEY, JsonArray());
    NWM_SetBind(REPL_NUI_BIND_CONSOLE, JsonArray());
    NWM_SetBindString(REPL_NUI_BIND_PROFILER, "");
}

string Repl_Interpret(string sInput)
{
    object oPlayer = OBJECT_SELF;
    object oTarget = NWM_GetUserDataObject(REPL_USERDATA_TARGET_KEY);
    json jStack = Session_GetJson(OBJECT_SELF, REPL_SCRIPT_NAME, REPL_SESSION_STACK_KEY);

    Repl_InjectStackEntry(jStack, "oPlayer", "PLAYER");
    Repl_InjectStackEntry(jStack, "oTarget", "TARGET");

    Profiler_Start("REPL");
    string sOutput = Interpret(sInput, FALSE, 0, jStack);
    string sProfiler = Profiler_Stop(FALSE, FALSE);
    NWM_SetBindString(REPL_NUI_BIND_PROFILER, sProfiler);

    return sOutput;
}

void Repl_AppendToConsole(json jLine)
{
    json jConsole = NWM_GetUserData(REPL_USERDATA_CONSOLE_KEY);
    JsonArrayInsertInplace(jConsole, jLine);
    NWM_SetUserData(REPL_USERDATA_CONSOLE_KEY, jConsole);
    NWM_SetBind(REPL_NUI_BIND_CONSOLE, jConsole);
}

void Repl_InjectStackEntry(json jStack, string sStackVarName, string sREPLName)
{
    if (!JsonObjectContainsKey(jStack, sREPLName))
    {
        struct NWNX_VM_StackVariable str = NWNX_VM_GetStackVariable(sStackVarName, 1);
        json jStackVariable = JsonObject();
        JsonObjectSetIntInplace(jStackVariable, NWNX_VM_STACK_LOCATION_KEY, str.nStackLocation);
        JsonObjectSetIntInplace(jStackVariable, NWNX_VM_TYPE_KEY, str.nAuxType);
        JsonObjectSetStringInplace(jStackVariable, NWNX_VM_STRUCT_NAME_KEY, "");
        JsonObjectSetInplace(jStack, sREPLName, jStackVariable);
    }
}

void Repl_AddCommandToHistory(string sInput)
{
    json jCommands = NWM_GetUserData(REPL_USERDATA_CMD_HISTORY_KEY);
    JsonArrayInsertInplace(jCommands, JsonString(sInput));

    while (JsonGetLength(jCommands) > REPL_CMD_HISTORY_SIZE)
        JsonArrayDelInplace(jCommands, 0);

    NWM_SetUserData(REPL_USERDATA_CMD_HISTORY_KEY, jCommands);
    NWM_SetUserDataInt(REPL_USERDATA_CMD_HISTORY_INDEX_KEY, JsonGetLength(jCommands));
    NWM_SetUserDataString(REPL_USERDATA_CMD_HISTORY_SAVED_INPUT_KEY, "");
}
