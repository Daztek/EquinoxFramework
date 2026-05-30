/*
    Script: ef_s_repl
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_profiler"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_session"
#include "ef_s_targetmode"

const string REPL_SCRIPT_NAME               = "ef_s_repl";
const string REPL_WINDOW_ID                 = "REPL";
const string REPL_NUI_ELEMENT_CLEAR_BUTTON  = "btn_clear";
const string REPL_NUI_BIND_CONSOLE          = "bind_console";
const string REPL_NUI_ELEMENT_INPUT         = "input_text";
const string REPL_NUI_BIND_INPUT            = "bind_input";
const string REPL_NUI_ELEMENT_ENTER_BUTTON  = "btn_enter";
const string REPL_NUI_ELEMENT_TARGET_BUTTON = "btn_target";
const string REPL_NUI_BIND_PROFILER         = "bind_profiler";

const string REPL_SESSION_STACK_KEY         = "ReplStack";
const string REPL_USERDATA_CONSOLE_KEY      = "ReplConsole";
const string REPL_USERDATA_TARGET_KEY       = "ReplTarget";
const string REPL_TARGET_MODE               = "ReplTargetMode";

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
                    NB_StartListTemplateCell(340.0f, FALSE);
                        NB_StartElement(NuiLabel(NuiBind(REPL_NUI_BIND_CONSOLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_SetDimensions(780.0f, 16.0f);
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiTextEdit(JsonString("..."), NuiBind(REPL_NUI_BIND_INPUT), 1024, FALSE, FALSE));
                    NB_SetId(REPL_NUI_ELEMENT_INPUT);
                    NB_SetDimensions(680.0f, 32.0f);
                NB_End();
                NB_AddSpacer();
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
        Session_SetJson(oPlayer, REPL_SCRIPT_NAME, REPL_SESSION_STACK_KEY, JsonObject());

        json jConsole = JsonArray();
        NWM_SetUserData(REPL_USERDATA_CONSOLE_KEY, jConsole);
        NWM_SetBind(REPL_NUI_BIND_CONSOLE, jConsole);
    }
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

string Repl_Interpret(string sInput)
{
    object oPlayer = OBJECT_SELF;
    object oTarget = NWM_GetUserDataObject(REPL_USERDATA_TARGET_KEY);
    object oModule = GetModule();
    json jStack = Session_GetJson(OBJECT_SELF, REPL_SCRIPT_NAME, REPL_SESSION_STACK_KEY);

    Repl_InjectStackEntry(jStack, "oPlayer", "PLAYER");
    Repl_InjectStackEntry(jStack, "oTarget", "TARGET");
    Repl_InjectStackEntry(jStack, "oModule", "MODULE");

    Profiler_Start("REPL");
    string sOutput = FormatString(sInput, 0, jStack);
    string sProfiler = Profiler_Stop(FALSE);
    NWM_SetBindString(REPL_NUI_BIND_PROFILER, sProfiler);

    return sOutput;
}

// @NWMEVENT[REPL_WINDOW_ID:NUI_EVENT_CLICK:REPL_NUI_ELEMENT_ENTER_BUTTON]
void Repl_ClickEnterButton()
{
    json jInput = NWM_GetBind(REPL_NUI_BIND_INPUT);
    string sInput = JsonGetString(jInput);

    if (sInput != "")
    {
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
    Session_SetJson(OBJECT_SELF, REPL_SCRIPT_NAME, REPL_SESSION_STACK_KEY, JsonObject());
    NWM_SetUserData(REPL_USERDATA_CONSOLE_KEY, JsonArray());
    NWM_SetBind(REPL_NUI_BIND_CONSOLE, JsonArray());
}

// @NWMEVENT[REPL_WINDOW_ID:NUI_EVENT_CLICK:REPL_NUI_ELEMENT_TARGET_BUTTON]
void Repl_ClickTargetButton()
{
    TargetMode_Enter(OBJECT_SELF, REPL_TARGET_MODE);
}

// @TARGETMODE[REPL_TARGET_MODE]
void Repl_OnTargetSelected()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, REPL_WINDOW_ID, TRUE))
    {
        NWM_SetUserDataObject(REPL_USERDATA_TARGET_KEY, GetTargetingModeSelectedObject());
    }
}
