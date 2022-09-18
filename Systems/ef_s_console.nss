/*
    Script: ef_s_console
    Author: Daz

    // @ CONSOLE[command_name:icon:Description]
    @ANNOTATION[@(CONSOLE)\[([\w]+)\:([\w]*)\:([\w\s]*)\][\n|\r]+(void|string+)\s([\w]+)\((.*)\)]
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_targetmode"
#include "nwnx_player"

const string CONSOLE_LOG_TAG                        = "Console";
const string CONSOLE_SCRIPT_NAME                    = "ef_s_console";

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
const string CONSOLE_BIND_LIST_COMMAND_NAME         = "list_name";
const string CONSOLE_BIND_LIST_COMMAND_ICON         = "list_icon";
const string CONSOLE_BIND_LIST_COMMAND_TOOLTIP      = "list_tooltip";
const string CONSOLE_BIND_SELECTED_COMMAND_ICON     = "sel_icon";
const string CONSOLE_BIND_SELECTED_COMMAND_NAME     = "sel_name";
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
             "id INTEGER PRIMARY KEY, " +
             "system TEXT NOT NULL, " +
             "name TEXT NOT NULL COLLATE NOCASE, " +
             "icon TEXT NOT NULL, " +
             "description TEXT NOT NULL, " +
             "parameters TEXT NOT NULL, " +
             "function TEXT NOT NULL, " +
             "script_chunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
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
                NB_StartList(NuiBind(CONSOLE_BIND_LIST_COMMAND_ICON), 16.0f);
                    NB_SetWidth(300.0f);
                    NB_StartListTemplateCell(16.0f, FALSE);
                        NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                            NB_SetMargin(0.0f);
                            NB_StartElement(NuiImage(NuiBind(CONSOLE_BIND_LIST_COMMAND_ICON), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_SetDimensions(16.0f, 16.0f);
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(200.0f, TRUE);
                        NB_StartElement(NuiSpacer());
                            NB_SetTooltip(NuiBind(CONSOLE_BIND_LIST_COMMAND_TOOLTIP));
                            NB_SetId(CONSOLE_BIND_LIST_COMMAND_NAME);
                            NB_StartDrawList(JsonBool(TRUE));
                                NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiColor(255, 255, 255), NuiRect(0.0f, 0.0f, 200.0f, 16.0f), NuiBind(CONSOLE_BIND_LIST_COMMAND_NAME), NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_OFF));
                                NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiColor(50, 150, 250), NuiRect(0.0f, 0.0f, 200.0f, 16.0f), NuiBind(CONSOLE_BIND_LIST_COMMAND_NAME), NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER));
                            NB_End();
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
                        NB_StartList(NuiBind(CONSOLE_BIND_LIST_ARG_TYPE_TOOLTIP), 25.0f);
                            NB_SetDimensions(472.0f, 150.0f);
                            NB_StartListTemplateCell(2.0f, FALSE);
                                NB_AddSpacer();
                            NB_End();
                            NB_StartListTemplateCell(200.0f, FALSE);
                                NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                                    NB_SetTooltip(NuiBind(CONSOLE_BIND_LIST_ARG_TYPE_TOOLTIP));
                                    NB_StartElement(NuiLabel(NuiBind(CONSOLE_BIND_LIST_ARG_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                    NB_End();
                                NB_End();
                            NB_End();
                            NB_StartListTemplateCell(2.0f, FALSE);
                                NB_AddSpacer();
                            NB_End();
                            NB_StartListTemplateCell(220.0f, TRUE);
                                NB_StartElement(NuiTextEdit(JsonString(""), NuiBind(CONSOLE_BIND_LIST_ARG_VALUE), 128, FALSE));
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

void Console_UpdateCommandList(string sSearch)
{
    string sIdArray;
    string sNameArray;
    string sIconArray;
    string sTooltipArray;

    string sSystem = JsonArrayGetString(NWM_GetUserData("systems"), JsonGetInt(NWM_GetBind(CONSOLE_BIND_COMBO_SYSTEM_SELECTED)));

    string sQuery = "SELECT id, name, icon, description FROM " + CONSOLE_SCRIPT_NAME + " WHERE " +
                    "name LIKE @search AND system LIKE @system " +
                    "ORDER BY name ASC;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@search", "%" + sSearch + "%");
    SqlBindString(sql, "@system", "%" + sSystem + "%");

    while (SqlStep(sql))
    {
        sIdArray += StringJsonArrayElementInt(SqlGetInt(sql, 0));
        sNameArray += StringJsonArrayElementString(SqlGetString(sql, 1));
        sIconArray += StringJsonArrayElementString(SqlGetString(sql, 2));
        sTooltipArray += StringJsonArrayElementString(SqlGetString(sql, 3));
    }

    NWM_SetBind(CONSOLE_BIND_LIST_COMMAND_NAME, StringJsonArrayElementsToJsonArray(sNameArray));
    NWM_SetBind(CONSOLE_BIND_LIST_COMMAND_ICON, StringJsonArrayElementsToJsonArray(sIconArray));
    NWM_SetBind(CONSOLE_BIND_LIST_COMMAND_TOOLTIP, StringJsonArrayElementsToJsonArray(sTooltipArray));

    NWM_SetUserData("commands", StringJsonArrayElementsToJsonArray(sIdArray));
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

void Console_SelectCommand(int nCommand)
{
    string sQuery = "SELECT name, icon, parameters, script_chunk FROM " + CONSOLE_SCRIPT_NAME + " WHERE " +
                    "id = @id;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@id", nCommand);

    if (SqlStep(sql))
    {
        string sName = SqlGetString(sql, 0);
        string sIcon = SqlGetString(sql, 1);
        json jParameters = SqlGetJson(sql, 2);
        string sScriptChunk = SqlGetString(sql, 3);
        string sArrayArgName;
        string sArrayArgValue;
        string sArrayArgTooltip;

        int nParameter, nNumParameters = JsonGetLength(jParameters);
        for (nParameter = 0; nParameter < nNumParameters; nParameter++)
        {
            json jParameter = JsonArrayGet(jParameters, nParameter);
            string sType = JsonObjectGetString(jParameter, "type");
            string sName = JsonObjectGetString(jParameter, "name");
            string sDefault = JsonObjectGetString(jParameter, "default");

            sArrayArgName += StringJsonArrayElementString(JsonObjectGetString(jParameter, "name"));
            sArrayArgValue += StringJsonArrayElementString(JsonObjectGetString(jParameter, "default"));
            sArrayArgTooltip += StringJsonArrayElementString(nssConvertShortType(JsonObjectGetString(jParameter, "type")));
        }

        NWM_SetUserData("selected_command", JsonInt(nCommand));
        NWM_SetUserData("selected_parameters", jParameters);
        NWM_SetUserData("selected_scriptchunk", JsonString(sScriptChunk));

        NWM_SetBindString(CONSOLE_BIND_SELECTED_COMMAND_ICON, sIcon);
        NWM_SetBindString(CONSOLE_BIND_SELECTED_COMMAND_NAME, sName);
        NWM_SetBind(CONSOLE_BIND_LIST_ARG_NAME, StringJsonArrayElementsToJsonArray(sArrayArgName));
        NWM_SetBind(CONSOLE_BIND_LIST_ARG_VALUE, StringJsonArrayElementsToJsonArray(sArrayArgValue));
        NWM_SetBind(CONSOLE_BIND_LIST_ARG_TYPE_TOOLTIP, StringJsonArrayElementsToJsonArray(sArrayArgTooltip));

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
        Console_SetOutput("");
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
    if (NuiGetClickthroughProtection())
        return;

    int nCommand = JsonArrayGetInt(NWM_GetUserData("commands"), NuiGetEventArrayIndex());
    if (nCommand != 0 && JsonGetInt(NWM_GetUserData("selected_command")) != nCommand)
        Console_SelectCommand(nCommand);
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_CLICK:CONSOLE_BIND_BUTTON_SELECT_TARGET]
void Console_ClickTargetButton()
{
    TargetMode_Enter(OBJECT_SELF, CONSOLE_TARGET_MODE_ID, OBJECT_TYPE_CREATURE | OBJECT_TYPE_ITEM | OBJECT_TYPE_PLACEABLE | OBJECT_TYPE_DOOR);
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
    json jValues = NWM_GetBind(CONSOLE_BIND_LIST_ARG_VALUE);
    int nArgument, nNumArguments = JsonGetLength(jValues);
    string sArgumentValueArray;

    for (nArgument = 0; nArgument < nNumArguments; nArgument++)
    {
        sArgumentValueArray += StringJsonArrayElementString("");
    }

    NWM_SetBind(CONSOLE_BIND_LIST_ARG_VALUE, StringJsonArrayElementsToJsonArray(sArgumentValueArray));
}

// @NWMEVENT[CONSOLE_WINDOW_ID:NUI_EVENT_CLICK:CONSOLE_BIND_BUTTON_EXECUTE]
void Console_ClickExecuteButton()
{
    object oPlayer = OBJECT_SELF;
    object oTarget = Console_GetTarget();

    if (GetIsObjectValid(oTarget))
    {
        object oDataObject = GetDataObject(CONSOLE_SCRIPT_NAME);
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
    NuiSetClickthroughProtection();
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

// @PAD[CONSOLE]
void Console_RegisterCommand(json jCommand)
{
    string sSystem = JsonArrayGetString(jCommand, 0);
    string sName = JsonArrayGetString(jCommand, 2);
    string sIcon = JsonArrayGetString(jCommand, 3);
    string sDescription = JsonArrayGetString(jCommand, 4);
    string sReturnType = JsonArrayGetString(jCommand, 5);
    string sFunction = JsonArrayGetString(jCommand, 6);
    string sParameters = JsonArrayGetString(jCommand, 7), sParameterTypes;

    json jParameters = JsonArray();
    if (sParameters != "")
    {
        json jMatches = NWNX_Regex_Match(sParameters, "(int|float|string)\\s(\\w+)(?:\\s=\\s)?(-?\\d+|-?\\d+\\.\\d+f?|\".*\")?(?:,|$)");
        int nMatch, nNumMatches = JsonGetLength(jMatches);
        for(nMatch = 0; nMatch < nNumMatches; nMatch++)
        {
            json jMatch = JsonArrayGet(jMatches, nMatch), jParameter = JsonObject();
            string sType = nssConvertType(JsonArrayGetString(jMatch, 1));
            string sVarName = JsonArrayGetString(jMatch, 2);
            string sDefault = JsonArrayGetString(jMatch, 3);

            sParameterTypes += sType;

            if (sType == "s" && GetStringLength(sDefault))
                sDefault = GetSubString(sDefault, 1, GetStringLength(sDefault) - 2);

            jParameter = JsonObjectSetString(jParameter, "type", sType);
            jParameter = JsonObjectSetString(jParameter, "name", sVarName);
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

    string sQuery = "INSERT INTO " + CONSOLE_SCRIPT_NAME + "(system, name, icon, description, parameters, function, script_chunk) " +
                    "VALUES(@system, @name, @icon, @description, @parameters, @function, @script_chunk);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@system", sSystem);
    SqlBindString(sql, "@name", sName);
    SqlBindString(sql, "@icon", sIcon == "" ? CONSOLE_DEFAULT_ICON : sIcon);
    SqlBindString(sql, "@description", sDescription);
    SqlBindJson(sql, "@parameters", jParameters);
    SqlBindString(sql, "@function", sFunction);
    SqlBindString(sql, "@script_chunk", sScriptChunk);
    SqlStep(sql);

    EFCore_CacheScriptChunk(sScriptChunk);

    WriteLog(CONSOLE_LOG_TAG, "* System '" + sSystem + "' registered command '" + sName + "' with '" + IntToString(nNumArguments) + "' parameters");
}
