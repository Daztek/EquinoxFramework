/*
    Script: ef_s_console
    Author: Daz

    // @ CONSOLE[command_name:icon:Description]
    @ANNOTATION[@(CONSOLE)\[([\w]+)\:([\w]*)\:([\w\s]*)\][\n|\r]+(void|string+)\s([\w]+)\((.*)\)]
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_targetmode"
#include "nwnx_player"

const string CONSOLE_LOG_TAG                        = "Console";
const string CONSOLE_SCRIPT_NAME                    = "ef_s_console";

const int CONSOLE_MAX_COMMANDS                      = 100;
const int CONSOLE_MAX_PARAMETERS                    = 10;
const string CONSOLE_TARGET_MODE_ID                 = "ConsoleTargetMode";
const string CONSOLE_ARG_PREFIX                     = "ConsoleArg_";
const string CONSOLE_DEFAULT_ICON                   = "ir_use";

const string CONSOLE_WINDOW_ID                      = "CONSOLE";
const string CONSOLE_BIND_WINDOW_COLLAPSED          = "collapsed";
const string CONSOLE_BIND_ICON_TARGET               = "icon_target";
const string CONSOLE_BIND_BUTTON_SELECT_TARGET      = "btn_target";
const string CONSOLE_BIND_INPUT_COMMAND             = "in_command";
const string CONSOLE_BIND_BUTTON_CLEAR_COMMAND      = "btn_clear";
const string CONSOLE_BIND_LABEL_TARGET              = "lbl_target";
const string CONSOLE_BIND_LIST_COMMAND_NAME         = "list_command";
const string CONSOLE_BIND_LIST_COMMAND_ICON         = "list_icon";
const string CONSOLE_BIND_LIST_COMMAND_TOOLTIP      = "list_tooltip";
const string CONSOLE_BIND_LIST_COMMAND_ROW_VISIBLE  = "list_visible";
const string CONSOLE_BIND_SELECTED_COMMAND_ICON     = "sel_icon";
const string CONSOLE_BIND_SELECTED_COMMAND_NAME     = "sel_name";
const string CONSOLE_BIND_LIST_ARG_ROW_VISIBLE      = "list_arg_visible";
const string CONSOLE_BIND_LIST_ARG_NAME             = "list_arg_name";
const string CONSOLE_BIND_LIST_ARG_VALUE            = "list_arg_value";
const string CONSOLE_BIND_LIST_ARG_TYPE_TOOLTIP     = "list_arg_type";
const string CONSOLE_BIND_BUTTON_CLEAR_ARGS         = "btn_clearargs";
const string CONSOLE_BIND_BUTTON_CLEAR_ARGS_ENABLED = "btn_clearargs_enabled";
const string CONSOLE_BIND_BUTTON_EXECUTE            = "btn_execute";
const string CONSOLE_BIND_BUTTON_EXECUTE_ENABLED    = "btn_execute_enabled";
const string CONSOLE_BIND_OUTPUT_TEXT               = "text_output";
const string CONSOLE_BIND_COMBO_SYSTEM_ENTRIES      = "system_combo_entries";
const string CONSOLE_BIND_COMBO_SYSTEM_SELECTED     = "system_combo_selected";

// @CORE[EF_SYSTEM_INIT]
void Console_Init()
{
    string sQuery;
    sQuery = "CREATE TABLE IF NOT EXISTS " + CONSOLE_SCRIPT_NAME + " (" +
             "system TEXT NOT NULL, " +
             "command TEXT NOT NULL COLLATE NOCASE, " +
             "icon TEXT NOT NULL, " +
             "description TEXT NOT NULL, " +
             "parameters TEXT NOT NULL, " +
             "function TEXT NOT NULL, " +
             "script_chunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    EFCore_ExecuteFunctionOnAnnotationData(CONSOLE_SCRIPT_NAME, "CONSOLE", "Console_RegisterCommand({DATA});");
}

// @NWMWINDOW[CONSOLE_WINDOW_ID]
json Console_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, 0.0f, 800.0f, 600.0f));
    NB_SetWindowTitle(JsonString("Console"));
    NB_SetWindowCollapsed(NuiBind(CONSOLE_BIND_WINDOW_COLLAPSED));
        NB_StartColumn();
            NB_StartRow();
                NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                    NB_SetHeight(40.0f);
                    NB_StartRow();
                        NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                            NB_SetMargin(0.0f);
                            NB_SetDimensions(32.0f, 32.0f);
                            NB_StartElement(NuiImage(JsonString("ir_socialize"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_SetId(CONSOLE_BIND_ICON_TARGET);
                            NB_End();
                        NB_End();
                        NB_AddSpacer();
                        NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                            NB_SetMargin(0.0f);
                            NB_SetDimensions(600.0f, 32.0f);
                            NB_AddElement(NuiLabel(NuiBind(CONSOLE_BIND_LABEL_TARGET), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                        NB_AddSpacer();
                    NB_End();
                NB_End();
                NB_StartElement(NuiButton(JsonString("Select Target")));
                    NB_SetId(CONSOLE_BIND_BUTTON_SELECT_TARGET);
                    NB_SetDimensions(125.0f, 40.0f);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiCombo(NuiBind(CONSOLE_BIND_COMBO_SYSTEM_ENTRIES), NuiBind(CONSOLE_BIND_COMBO_SYSTEM_SELECTED)));
                    NB_SetDimensions(150.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiTextEdit(JsonString("Search commands..."), NuiBind(CONSOLE_BIND_INPUT_COMMAND), 64, FALSE));
                    NB_SetHeight(32.0f);
                NB_End();
                NB_StartElement(NuiButton(JsonString("X")));
                    NB_SetId(CONSOLE_BIND_BUTTON_CLEAR_COMMAND);
                    NB_SetEnabled(NuiBind(CONSOLE_BIND_BUTTON_CLEAR_COMMAND));
                    NB_SetDimensions(32.0f, 32.0f);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartList(NuiBind(CONSOLE_BIND_LIST_COMMAND_NAME), 16.0f);
                    NB_SetWidth(300.0f);
                    NB_StartListTemplateCell(16.0f, FALSE);
                        NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                            NB_SetVisible(NuiBind(CONSOLE_BIND_LIST_COMMAND_ROW_VISIBLE));
                            NB_SetMargin(0.0f);
                            NB_StartElement(NuiImage(NuiBind(CONSOLE_BIND_LIST_COMMAND_ICON), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_SetVisible(NuiBind(CONSOLE_BIND_LIST_COMMAND_ROW_VISIBLE));
                                NB_SetDimensions(16.0f, 16.0f);
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(200.0f, TRUE);
                        NB_StartElement(NuiLabel(NuiBind(CONSOLE_BIND_LIST_COMMAND_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_SetVisible(NuiBind(CONSOLE_BIND_LIST_COMMAND_ROW_VISIBLE));
                            NB_SetTooltip(NuiBind(CONSOLE_BIND_LIST_COMMAND_TOOLTIP));
                            NB_SetId(CONSOLE_BIND_LIST_COMMAND_NAME);
                        NB_End();
                    NB_End();
                NB_End();
                NB_StartColumn();
                    NB_SetMargin(0.0f);
                    NB_StartRow();
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_SetMargin(0.0f);
                            NB_SetDimensions(32.0f, 32.0f);
                            NB_AddElement(NuiImage(NuiBind(CONSOLE_BIND_SELECTED_COMMAND_ICON), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                        NB_AddSpacer();
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_SetMargin(0.0f);
                            NB_SetDimensions(436.0f, 32.0f);
                            NB_AddElement(NuiLabel(NuiBind(CONSOLE_BIND_SELECTED_COMMAND_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();
                    NB_StartRow();
                        NB_StartList(NuiBind(CONSOLE_BIND_LIST_ARG_NAME), 25.0f);
                            NB_SetDimensions(472.0f, 150.0f);
                            NB_StartListTemplateCell(2.0f, FALSE);
                                NB_AddSpacer();
                            NB_End();
                            NB_StartListTemplateCell(200.0f, FALSE);
                                NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                                    NB_SetVisible(NuiBind(CONSOLE_BIND_LIST_ARG_ROW_VISIBLE));
                                    NB_SetTooltip(NuiBind(CONSOLE_BIND_LIST_ARG_TYPE_TOOLTIP));
                                    NB_StartElement(NuiLabel(NuiBind(CONSOLE_BIND_LIST_ARG_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetVisible(NuiBind(CONSOLE_BIND_LIST_ARG_ROW_VISIBLE));
                                    NB_End();
                                NB_End();
                            NB_End();
                            NB_StartListTemplateCell(2.0f, FALSE);
                                NB_AddSpacer();
                            NB_End();
                            NB_StartListTemplateCell(220.0f, TRUE);
                                NB_StartElement(NuiTextEdit(JsonString(""), NuiBind(CONSOLE_BIND_LIST_ARG_VALUE), 128, FALSE));
                                    NB_SetVisible(NuiBind(CONSOLE_BIND_LIST_ARG_ROW_VISIBLE));
                                NB_End();
                            NB_End();
                            NB_StartListTemplateCell(2.0f, FALSE);
                                NB_AddSpacer();
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_StartRow();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Clear")));
                            NB_SetId(CONSOLE_BIND_BUTTON_CLEAR_ARGS);
                            NB_SetEnabled(NuiBind(CONSOLE_BIND_BUTTON_CLEAR_ARGS_ENABLED));
                            NB_SetDimensions(125.0f, 40.0f);
                        NB_End();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Execute")));
                            NB_SetId(CONSOLE_BIND_BUTTON_EXECUTE);
                            NB_SetEnabled(NuiBind(CONSOLE_BIND_BUTTON_EXECUTE_ENABLED));
                            NB_SetDimensions(125.0f, 40.0f);
                        NB_End();
                        NB_AddSpacer();
                    NB_End();
                    NB_StartRow();
                        NB_StartElement(NuiText(NuiBind(CONSOLE_BIND_OUTPUT_TEXT), TRUE, NUI_SCROLLBARS_Y));
                            NB_SetDimensions(472.0f, 210.0f);
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

void Console_UpdateCommandList(string sCommand)
{
    json jVisibleArray = GetEmptyJsonBoolArray(CONSOLE_MAX_COMMANDS);
    json jCommandArray = GetEmptyJsonStringArray(CONSOLE_MAX_COMMANDS);
    json jIconArray = GetEmptyJsonStringArray(CONSOLE_MAX_COMMANDS);
    json jTooltipArray = GetEmptyJsonStringArray(CONSOLE_MAX_COMMANDS);

    string sSystem = JsonArrayGetString(NWM_GetUserData("systems"), JsonGetInt(NWM_GetBind(CONSOLE_BIND_COMBO_SYSTEM_SELECTED)));

    string sQuery = "SELECT command, icon, description FROM " + CONSOLE_SCRIPT_NAME + " WHERE " +
                    "command LIKE @command AND system LIKE @system " +
                    "ORDER BY command ASC LIMIT " + IntToString(CONSOLE_MAX_COMMANDS) + ";";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@command", "%" + sCommand + "%");
    SqlBindString(sql, "@system", "%" + sSystem + "%");

    int nIndex;
    while (SqlStep(sql))
    {
        jVisibleArray = JsonArraySetBool(jVisibleArray, nIndex, TRUE);
        jCommandArray = JsonArraySetString(jCommandArray, nIndex, SqlGetString(sql, 0));
        jIconArray = JsonArraySetString(jIconArray, nIndex, SqlGetString(sql, 1));
        jTooltipArray = JsonArraySetString(jTooltipArray, nIndex, SqlGetString(sql, 2));
        nIndex++;
    }

    NWM_SetBind(CONSOLE_BIND_LIST_COMMAND_ROW_VISIBLE, jVisibleArray);
    NWM_SetBind(CONSOLE_BIND_LIST_COMMAND_NAME, jCommandArray);
    NWM_SetBind(CONSOLE_BIND_LIST_COMMAND_ICON, jIconArray);
    NWM_SetBind(CONSOLE_BIND_LIST_COMMAND_TOOLTIP, jTooltipArray);

    NWM_SetUserData("commands", jCommandArray);
}

void Console_UpdateSystemCombo()
{
    string sQuery = "SELECT DISTINCT system FROM " + CONSOLE_SCRIPT_NAME + ";";
    sqlquery sql = SqlPrepareQueryModule(sQuery);

    int nIndex;
    json jSystems = JsonArray();
         jSystems = JsonArrayInsertString(jSystems, "");
    json jComboEntries = JsonArray();
         jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("", nIndex++));

    while (SqlStep(sql))
    {
        string sSystem = SqlGetString(sql, 0);
        jSystems = JsonArrayInsertString(jSystems, sSystem);
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry(sSystem, nIndex++));
    }

    NWM_SetBind(CONSOLE_BIND_COMBO_SYSTEM_ENTRIES, jComboEntries);
    NWM_SetUserData("systems", jSystems);
}

void Console_SetOutput(string sOutput)
{
    NWM_SetBindString(CONSOLE_BIND_OUTPUT_TEXT, sOutput);
}

void Console_SelectCommand(string sCommand)
{
    string sQuery = "SELECT icon, parameters, script_chunk FROM " + CONSOLE_SCRIPT_NAME + " WHERE " +
                    "command = @command;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@command", sCommand);

    if (SqlStep(sql))
    {
        string sIcon = SqlGetString(sql, 0);
        json jParameters = SqlGetJson(sql, 1);
        string sScriptChunk = SqlGetString(sql, 2);
        json jArrayArgVisible = GetEmptyJsonBoolArray(CONSOLE_MAX_PARAMETERS);
        json jArrayArgName = GetEmptyJsonStringArray(CONSOLE_MAX_PARAMETERS);
        json jArrayArgValue = GetEmptyJsonStringArray(CONSOLE_MAX_PARAMETERS);
        json jArrayArgTooltip = GetEmptyJsonStringArray(CONSOLE_MAX_PARAMETERS);

        int nParameter, nNumParameters = JsonGetLength(jParameters);
        for (nParameter = 0; nParameter < nNumParameters; nParameter++)
        {
            json jParameter = JsonArrayGet(jParameters, nParameter);
            string sType = JsonObjectGetString(jParameter, "type");
            string sName = JsonObjectGetString(jParameter, "name");
            string sDefault = JsonObjectGetString(jParameter, "default");

            jArrayArgVisible = JsonArraySetBool(jArrayArgVisible, nParameter, TRUE);
            jArrayArgName = JsonArraySetString(jArrayArgName, nParameter, sName);
            jArrayArgValue = JsonArraySetString(jArrayArgValue, nParameter, sDefault);
            jArrayArgTooltip = JsonArraySetString(jArrayArgTooltip, nParameter, nssConvertShortType(sType));
        }

        NWM_SetUserData("selected_command", JsonString(sCommand));
        NWM_SetUserData("selected_parameters", jParameters);
        NWM_SetUserData("selected_scriptchunk", JsonString(sScriptChunk));

        NWM_SetBindString(CONSOLE_BIND_SELECTED_COMMAND_ICON, sIcon);
        NWM_SetBindString(CONSOLE_BIND_SELECTED_COMMAND_NAME, sCommand);
        NWM_SetBind(CONSOLE_BIND_LIST_ARG_ROW_VISIBLE, jArrayArgVisible);
        NWM_SetBind(CONSOLE_BIND_LIST_ARG_NAME, jArrayArgName);
        NWM_SetBind(CONSOLE_BIND_LIST_ARG_VALUE, jArrayArgValue);
        NWM_SetBind(CONSOLE_BIND_LIST_ARG_TYPE_TOOLTIP, jArrayArgTooltip);

        NWM_SetBindBool(CONSOLE_BIND_BUTTON_CLEAR_ARGS_ENABLED, TRUE);
        NWM_SetBindBool(CONSOLE_BIND_BUTTON_EXECUTE_ENABLED, TRUE);

        Console_SetOutput("");
    }
}

void Console_SetTarget(object oTarget)
{
    if (GetIsObjectValid(oTarget))
    {
        string sObjectType = ObjectTypeToString(GetObjectType(oTarget));
        NWM_SetBindString(CONSOLE_BIND_LABEL_TARGET, GetName(oTarget) + " (" + sObjectType + ")");
        NWM_SetUserData("target", JsonString(ObjectToString(oTarget)));
    }
}

object Console_GetTarget()
{
    return StringToObject(JsonGetString(NWM_GetUserData("target")));
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_WATCH:CONSOLE_BIND_INPUT_COMMAND]
void Console_WatchCommandInput()
{
    string sCommand = NWM_GetBindString(CONSOLE_BIND_INPUT_COMMAND);
    NWM_SetBindBool(CONSOLE_BIND_BUTTON_CLEAR_COMMAND, GetStringLength(sCommand));
    Console_UpdateCommandList(sCommand);
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_CLICK:CONSOLE_BIND_BUTTON_CLEAR_COMMAND]
void Console_ClickClearButton()
{
    NWM_SetBindString(CONSOLE_BIND_INPUT_COMMAND, "");
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_MOUSEUP:CONSOLE_BIND_LIST_COMMAND_NAME]
void Console_MouseUpListCommandName()
{
    string sCommand = JsonArrayGetString(NWM_GetUserData("commands"), NuiGetEventArrayIndex());
    if (sCommand != "" && JsonGetString(NWM_GetUserData("selected_command")) != sCommand)
        Console_SelectCommand(sCommand);
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_CLICK:CONSOLE_BIND_BUTTON_SELECT_TARGET]
void Console_ClickTargetButton()
{
    TargetMode_Enter(OBJECT_SELF, CONSOLE_TARGET_MODE_ID, OBJECT_TYPE_CREATURE | OBJECT_TYPE_ITEM | OBJECT_TYPE_PLACEABLE);
    NWM_SetBindBool(CONSOLE_BIND_WINDOW_COLLAPSED, TRUE);
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_MOUSEUP:CONSOLE_BIND_ICON_TARGET]
void Console_TargetIconMouseUp()
{
    object oPlayer = OBJECT_SELF;
    object oTarget = Console_GetTarget();

    if (GetIsObjectValid(oTarget) && GetArea(oPlayer) == GetArea(oTarget))
        NWNX_Player_ApplyInstantVisualEffectToObject(oPlayer, oTarget, VFX_IMP_KNOCK);
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_CLICK:CONSOLE_BIND_BUTTON_CLEAR_ARGS]
void Console_ClickClearArgsButton()
{
    NWM_SetBind(CONSOLE_BIND_LIST_ARG_VALUE, GetEmptyJsonStringArray(CONSOLE_MAX_PARAMETERS));
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_CLICK:CONSOLE_BIND_BUTTON_EXECUTE]
void Console_ClickExecuteButton()
{
    object oPlayer = OBJECT_SELF;
    object oTarget = Console_GetTarget();

    if (GetIsObjectValid(oTarget))
    {
        object oDataObject = GetDataObject(CONSOLE_SCRIPT_NAME);
        string sCommand = JsonGetString(NWM_GetUserData("selected_command"));
        json jParameters = NWM_GetUserData("selected_parameters");
        string sScriptChunk = JsonGetString(NWM_GetUserData("selected_scriptchunk"));
        json jValues = NWM_GetBind(CONSOLE_BIND_LIST_ARG_VALUE);

        int nParameter, nNumParameters = JsonGetLength(jParameters);
        for (nParameter = 0; nParameter < nNumParameters; nParameter++)
        {
            json jParameter = JsonArrayGet(jParameters, nParameter);
            string sType = JsonObjectGetString(jParameter, "type");
            string sValue = JsonArrayGetString(jValues, nParameter);

            if (sType == "i")
                SetLocalInt(oDataObject, CONSOLE_ARG_PREFIX + IntToString(nParameter), StringToInt(sValue));
            else if (sType == "f")
                SetLocalFloat(oDataObject, CONSOLE_ARG_PREFIX + IntToString(nParameter), StringToFloat(sValue));
            else if (sType == "s")
                SetLocalString(oDataObject, CONSOLE_ARG_PREFIX + IntToString(nParameter), sValue);
        }

        string sError = ExecuteCachedScriptChunk(sScriptChunk, oTarget, FALSE);
        if (sError != "")
            Console_SetOutput("ERROR: failed to execute script chunk: " + sError);
    }
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_WATCH:CONSOLE_BIND_COMBO_SYSTEM_SELECTED]
void Console_WatchSystemComboSelected()
{
    Console_UpdateCommandList(NWM_GetBindString(CONSOLE_BIND_INPUT_COMMAND));
}

// @TARGETMODE[CONSOLE_TARGET_MODE_ID]
void Console_OnPlayerTarget()
{
    object oPlayer = OBJECT_SELF;
    object oTarget = GetTargetingModeSelectedObject();

    if (NWM_GetIsWindowOpen(oPlayer, CONSOLE_WINDOW_ID, TRUE))
    {
        if (GetIsObjectValid(oTarget) && oTarget != GetArea(oPlayer))
            Console_SetTarget(oTarget);

        NWM_SetBindBool(CONSOLE_BIND_WINDOW_COLLAPSED, FALSE);
    }
}

// @PMBUTTON[Console:Open the console]
void Console_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, CONSOLE_WINDOW_ID))
        NWM_CloseWindow(oPlayer, CONSOLE_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, CONSOLE_WINDOW_ID))
    {
        Console_UpdateSystemCombo();
        Console_SetTarget(oPlayer);
        NWM_SetBindWatch(CONSOLE_BIND_INPUT_COMMAND, TRUE);
        NWM_SetBindString(CONSOLE_BIND_INPUT_COMMAND, "");
        NWM_SetBindString(CONSOLE_BIND_SELECTED_COMMAND_ICON, CONSOLE_DEFAULT_ICON);
        NWM_SetBindWatch(CONSOLE_BIND_COMBO_SYSTEM_SELECTED, TRUE);
    }
}

void Console_RegisterCommand(json jCommand)
{
    string sSystem = JsonArrayGetString(jCommand, 0);
    string sCommand = JsonArrayGetString(jCommand, 2);
    string sIcon = JsonArrayGetString(jCommand, 3);
    string sDescription = JsonArrayGetString(jCommand, 4);
    string sReturnType = JsonArrayGetString(jCommand, 5);
    string sFunction = JsonArrayGetString(jCommand, 6);
    string sParameters = JsonArrayGetString(jCommand, 7), sParameterTypes;

    string sQuery = "SELECT function FROM " + CONSOLE_SCRIPT_NAME + " WHERE " + "command = @command;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@command", sCommand);

    if (SqlStep(sql))
    {
        WriteLog(CONSOLE_LOG_TAG, "* ERROR: System '" + sSystem + "' tried to register command '" + sCommand + "' but command already exists!");
        return;
    }

    json jParameters = JsonArray();
    if (sParameters != "")
    {
        json jMatches = NWNX_Regex_Match(sParameters, "(int|float|string)\\s(\\w+)(?:\\s=\\s)?(-?\\d+|-?\\d+\\.\\d+f?|\".*\")?(?:,|$)");
        int nMatch, nNumMatches = JsonGetLength(jMatches);
        for(nMatch = 0; nMatch < nNumMatches; nMatch++)
        {
            json jMatch = JsonArrayGet(jMatches, nMatch), jParameter = JsonObject();
            string sType = nssConvertType(JsonArrayGetString(jMatch, 1));
            string sName = JsonArrayGetString(jMatch, 2);
            string sDefault = JsonArrayGetString(jMatch, 3);

            sParameterTypes += sType;

            if (sType == "s" && GetStringLength(sDefault))
                sDefault = GetSubString(sDefault, 1, GetStringLength(sDefault) - 2);

            jParameter = JsonObjectSetString(jParameter, "type", sType);
            jParameter = JsonObjectSetString(jParameter, "name", sName);
            jParameter = JsonObjectSetString(jParameter, "default", sDefault);

            jParameters = JsonArrayInsert(jParameters, jParameter);
        }
    }

    string sFunctionBody = nssObject("oDataObject", nssFunction("GetDataObject", nssEscape(CONSOLE_SCRIPT_NAME)));

    string sArguments;
    int nArgument, nNumArguments = GetStringLength(sParameterTypes);
    for (nArgument = 0; nArgument < nNumArguments; nArgument++)
    {
        sArguments += (!nArgument ? "" : ", ") + nssFunction("GetLocal" + nssConvertShortType(GetSubString(sParameterTypes, nArgument, 1)), "oDataObject, " + nssEscape(CONSOLE_ARG_PREFIX + IntToString(nArgument)), FALSE);
    }

    if (sReturnType == "string")
        sFunctionBody += nssFunction("Console_SetOutput", nssFunction(sFunction, sArguments, FALSE));
    else
        sFunctionBody += nssFunction(sFunction, sArguments);

    string sScriptChunk = (sSystem == CONSOLE_SCRIPT_NAME ? "" : nssInclude(CONSOLE_SCRIPT_NAME)) + nssInclude(sSystem) + nssVoidMain(sFunctionBody);

    sQuery = "INSERT INTO " + CONSOLE_SCRIPT_NAME + "(system, command, icon, description, parameters, function, script_chunk) " +
                    "VALUES(@system, @command, @icon, @description, @parameters, @function, @script_chunk);";
    sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@command", sCommand);
    SqlBindString(sql, "@icon", sIcon == "" ? CONSOLE_DEFAULT_ICON : sIcon);
    SqlBindString(sql, "@description", sDescription);
    SqlBindJson(sql, "@parameters", jParameters);
    SqlBindString(sql, "@function", sFunction);
    SqlBindString(sql, "@script_chunk", sScriptChunk);
    SqlStep(sql);

    WriteLog(CONSOLE_LOG_TAG, "* System '" + sSystem + "' registered command '" + sCommand + "' with '" + IntToString(nNumArguments) + "' parameters");
}

