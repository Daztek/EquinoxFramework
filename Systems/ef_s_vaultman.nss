/*
    Script: ef_s_vaultman.nss
    Author: Daz

    "CREATE TABLE IF NOT EXISTS vault_characters ( "
    "id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "owner TEXT NOT NULL, "
    "filename TEXT, "
    "character TEXT NOT NULL, "
    "timestamp INTEGER NOT NULL "
    ");";

    "CREATE TABLE IF NOT EXISTS vault_access ( "
    "id INTEGER NOT NULL, "
    "cdkey TEXT NOT NULL, "
    "PRIMARY KEY(id, cdkey)"
    ");";

    "CREATE TABLE IF NOT EXISTS vault_status ( "
    "id INTEGER NOT NULL, "
    "cdkey TEXT NOT NULL, "
    "PRIMARY KEY(id, cdkey)"
    ");";

    "CREATE TABLE IF NOT EXISTS vault_oids ( "
    "id INTEGER NOT NULL, "
    "oid INTEGER NOT NULL, "
    "PRIMARY KEY(id, oid)"
    ");";

    "CREATE TABLE IF NOT EXISTS vault_migration ("
    "cdkey TEXT PRIMARY KEY NOT NULL, "
    "timestamp INTEGER NOT NULL "
    ");";

    "CREATE TABLE IF NOT EXISTS vault_log ("
    "id TEXT NOT NULL, "
    "cdkey TEXT NOT NULL, "
    "event INTEGER NOT NULL, "
    "timestamp INTEGER NOT NULL"
    ");";    
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_profiler"

#include "nwnx_player"
#include "nwnx_vault"

const string VMAN_LOG_TAG                                   = "VaultManager";
const string VMAN_SCRIPT_NAME                               = "ef_s_vaultman";

const string VMAN_DATABASE_NAME                             = "servervault";
const string VMAN_CHARACTERS_TABLE                          = "vault_characters";
const string VMAN_ACCESS_TABLE                              = "vault_access";
const string VMAN_STATUS_TABLE                              = "vault_status";
const string VMAN_LOG_TABLE                                 = "vault_log";

const string VMAN_NUI_MAIN_WINDOW_NAME                      = "VMAN_MAIN";
const string VMAN_BIND_LIST_PORTRAITS                       = "list_portraits";
const string VMAN_BIND_LIST_NAMES                           = "list_names";

const string VMAN_BIND_SELECTED_NAME                        = "selected_name";
const string VMAN_BIND_SELECTED_PORTRAIT                    = "selected_portrait";
const string VMAN_BIND_SELECTED_CLASS_VISIBLE_PREFIX        = "selected_class_visible_";
const string VMAN_BIND_SELECTED_CLASS_ICON_PREFIX           = "selected_class_icon_";
const string VMAN_BIND_SELECTED_CLASS_LABEL_PREFIX          = "selected_class_label_";

const string VMAN_BIND_SELECTED_CLASS_VISIBLE_1             = "selected_class_visible_1";
const string VMAN_BIND_SELECTED_CLASS_ICON_1                = "selected_class_icon_1";
const string VMAN_BIND_SELECTED_CLASS_LABEL_1               = "selected_class_label_1";

const string VMAN_BIND_SELECTED_CLASS_VISIBLE_2             = "selected_class_visible_2";
const string VMAN_BIND_SELECTED_CLASS_ICON_2                = "selected_class_icon_2";
const string VMAN_BIND_SELECTED_CLASS_LABEL_2               = "selected_class_label_2";

const string VMAN_BIND_SELECTED_CLASS_VISIBLE_3             = "selected_class_visible_3";
const string VMAN_BIND_SELECTED_CLASS_ICON_3                = "selected_class_icon_3";
const string VMAN_BIND_SELECTED_CLASS_LABEL_3               = "selected_class_label_3";

const string VMAN_BIND_SELECTED_GOLD_LABEL                  = "selected_gold_label";
const string VMAN_BIND_SELECTED_XP_LABEL                    = "selected_xp_label";
const string VMAN_BIND_SELECTED_STATUS_LABEL                = "selected_status_label";
const string VMAN_BIND_SELECTED_STATUS_COLOR                = "selected_status_color";

const string VMAN_BIND_BUTTON_EDIT                          = "btn_edit";
const string VMAN_BIND_BUTTON_LOG                           = "btn_log";
const string VMAN_BIND_BUTTON_DELETE                        = "btn_delete";
const string VMAN_BIND_BUTTON_SHARE                         = "btn_share";
const string VMAN_BIND_BUTTON_SWITCH                        = "btn_switch";

const string VMAN_NUI_USERDATA_SELECTED_ID                  = "selected_id";
const string VMAN_NUI_USERDATA_SELECTED_NAME                = "selected_name";
const string VMAN_NUI_USERDATA_IDS                          = "character_ids";

const string VMAN_NUI_LOG_WINDOW_NAME                       = "VMAN_LOG";
const string VMAN_BIND_WINDOW_NAME                          = "window_name";
const string VMAN_BIND_LIST_ICONS                           = "list_icons";
const string VMAN_BIND_LIST_LABELS                          = "list_labels";

sqlquery VMan_PrepareQuery(string sQuery);
int VMan_GetPlayersOnline();
void VMan_LoadCharacterList();
void VMan_UpdateSelectedCharacterData(int nNewId);
void VMan_UpdateEventLog(int nCharacterId, string sName);

// @NWMWINDOW[VMAN_NUI_MAIN_WINDOW_NAME]
json VMan_CreateMainWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 688.0f, 390.0f));
    NB_SetWindowTitle(JsonString("Character Vault Manager"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartColumn();                
                    NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                        NB_SetHeight(24.0f);
                        NB_AddElement(NuiLabel(JsonString("Characters"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_End();                    
                    NB_StartList(NuiBind(VMAN_BIND_LIST_PORTRAITS), 25.0f);
                        NB_SetDimensions(250.0f, 300.0f);
                        NB_StartListTemplateCell(16.0f, FALSE);
                            NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                                NB_StartElement(NuiImage(NuiBind(VMAN_BIND_LIST_PORTRAITS), JsonInt(NUI_ASPECT_EXACTSCALED), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_TOP)));
                                    NB_SetId(VMAN_BIND_LIST_PORTRAITS);
                                NB_End();
                            NB_End();
                        NB_End();
                        NB_StartListTemplateCell(0.0f, TRUE);
                            NB_StartElement(NuiSpacer());
                                NB_SetId(VMAN_BIND_LIST_NAMES);
                                NB_StartDrawList(JsonBool(TRUE));
                                    NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiColor(255, 255, 255), NuiRect(0.0f, 4.0f, 200.0f, 21.0f), NuiBind(VMAN_BIND_LIST_NAMES), NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_OFF));
                                    NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiColor(50, 150, 250), NuiRect(0.0f, 4.0f, 200.0f, 21.0f), NuiBind(VMAN_BIND_LIST_NAMES), NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER));                                
                                NB_End(); 
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_AddSpacer();
                NB_End(); 
                NB_StartColumn();
                    NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                        NB_SetDimensions(400.0f, 24.0f);
                        NB_AddElement(NuiLabel(NuiBind(VMAN_BIND_SELECTED_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_End();
                    NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                        NB_SetHeight(212.0f);
                        NB_StartRow();
                            NB_StartElement(NuiImage(NuiBind(VMAN_BIND_SELECTED_PORTRAIT), JsonInt(NUI_ASPECT_EXACTSCALED), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_TOP)));
                                NB_SetDimensions(128.0f, 200.0f);
                            NB_End();
                            NB_StartColumn();
                                float fIconSize = 20.0f;
                                NB_StartRow();
                                    NB_StartElement(NuiImage(NuiBind(VMAN_BIND_SELECTED_CLASS_ICON_1), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetDimensions(fIconSize, fIconSize);
                                        NB_SetVisible(NuiBind(VMAN_BIND_SELECTED_CLASS_VISIBLE_1));
                                    NB_End();
                                    NB_AddElement(NuiLabel(NuiBind(VMAN_BIND_SELECTED_CLASS_LABEL_1), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_End(); 
                                NB_StartRow();
                                    NB_StartElement(NuiImage(NuiBind(VMAN_BIND_SELECTED_CLASS_ICON_2), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetDimensions(fIconSize, fIconSize);
                                        NB_SetVisible(NuiBind(VMAN_BIND_SELECTED_CLASS_VISIBLE_2));
                                    NB_End();
                                    NB_AddElement(NuiLabel(NuiBind(VMAN_BIND_SELECTED_CLASS_LABEL_2), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_End();
                                NB_StartRow();
                                    NB_StartElement(NuiImage(NuiBind(VMAN_BIND_SELECTED_CLASS_ICON_3), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetDimensions(fIconSize, fIconSize);
                                        NB_SetVisible(NuiBind(VMAN_BIND_SELECTED_CLASS_VISIBLE_3));
                                    NB_End();
                                    NB_AddElement(NuiLabel(NuiBind(VMAN_BIND_SELECTED_CLASS_LABEL_3), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_End();
                                NB_StartRow();
                                    NB_StartElement(NuiSpacer());
                                        NB_SetHeight(8.0f);
                                    NB_End();
                                NB_End();
                                NB_StartRow();
                                    NB_StartElement(NuiImage(JsonString("ir_buy"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetDimensions(fIconSize, fIconSize);
                                    NB_End();
                                    NB_AddElement(NuiLabel(NuiBind(VMAN_BIND_SELECTED_GOLD_LABEL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_End();  
                                NB_StartRow();
                                    NB_StartElement(NuiImage(JsonString("ixx_levelup"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetDimensions(fIconSize, fIconSize);
                                    NB_End();
                                    NB_AddElement(NuiLabel(NuiBind(VMAN_BIND_SELECTED_XP_LABEL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_End();
                             NB_StartRow();
                                    NB_StartElement(NuiImage(JsonString("ir_wave"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetDimensions(fIconSize, fIconSize);
                                    NB_End();
                                    NB_StartElement(NuiLabel(NuiBind(VMAN_BIND_SELECTED_STATUS_LABEL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetForegroundColor(NuiBind(VMAN_BIND_SELECTED_STATUS_COLOR));
                                    NB_End();
                                NB_End();                                 
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_AddSpacer();
                    NB_StartRow();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Edit")));
                            NB_SetDimensions(100.0f, 32.0f);
                            NB_SetId(VMAN_BIND_BUTTON_EDIT);
                        NB_End();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Log")));
                            NB_SetDimensions(100.0f, 32.0f);
                            NB_SetId(VMAN_BIND_BUTTON_LOG);
                        NB_End();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Delete")));
                            NB_SetDimensions(100.0f, 32.0f);
                            NB_SetId(VMAN_BIND_BUTTON_DELETE);
                        NB_End();
                        NB_AddSpacer();
                    NB_End();
                    NB_StartRow();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Share")));
                            NB_SetDimensions(100.0f, 32.0f);
                            NB_SetId(VMAN_BIND_BUTTON_SHARE);
                        NB_End();
                        NB_AddSpacer();
                        NB_StartElement(NuiSpacer());
                            NB_SetDimensions(104.0f, 32.0f);    
                        NB_End();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Switch")));
                            NB_SetDimensions(100.0f, 32.0f);
                            NB_SetId(VMAN_BIND_BUTTON_SWITCH);
                        NB_End();
                        NB_AddSpacer();
                    NB_End();  
                NB_End();
                NB_AddSpacer();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[VMAN_NUI_MAIN_WINDOW_NAME:NUI_EVENT_MOUSEUP:VMAN_BIND_LIST_PORTRAITS]
void VMan_MouseUpSelectPortrait()
{
    int nId = JsonArrayGetInt(NWM_GetUserData(VMAN_NUI_USERDATA_IDS), NuiGetEventArrayIndex());
    if (nId != 0)
        VMan_UpdateSelectedCharacterData(nId);
}

// @NWMEVENT[VMAN_NUI_MAIN_WINDOW_NAME:NUI_EVENT_MOUSEUP:VMAN_BIND_LIST_NAMES]
void VMan_MouseUpSelectName()
{
    int nId = JsonArrayGetInt(NWM_GetUserData(VMAN_NUI_USERDATA_IDS), NuiGetEventArrayIndex());
    if (nId != 0)
        VMan_UpdateSelectedCharacterData(nId);    
}

// @NWMEVENT[VMAN_NUI_MAIN_WINDOW_NAME:NUI_EVENT_CLICK:VMAN_BIND_BUTTON_SWITCH]
void VMan_ClickSwitchButton()
{
    object oPlayer = OBJECT_SELF;
    int nCharacterId = JsonGetInt(NWM_GetUserData(VMAN_NUI_USERDATA_SELECTED_ID));

    if (nCharacterId != 0)
    {
        ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_AC_BONUS), GetLocation(oPlayer));
        NWNX_Vault_SwitchCharacter(oPlayer, nCharacterId, TRUE);
    }
}

// @NWMEVENT[VMAN_NUI_MAIN_WINDOW_NAME:NUI_EVENT_CLICK:VMAN_BIND_BUTTON_LOG]
void VMan_ClickLogButton()
{
    object oPlayer = OBJECT_SELF;
    int nCharacterId = JsonGetInt(NWM_GetUserData(VMAN_NUI_USERDATA_SELECTED_ID));

    if (nCharacterId != 0)
    {
        if (NWM_GetIsWindowOpen(oPlayer, VMAN_NUI_LOG_WINDOW_NAME))
            NWM_CloseWindow(oPlayer, VMAN_NUI_LOG_WINDOW_NAME);
        else 
        {
            string sName = JsonGetString(NWM_GetUserData(VMAN_NUI_USERDATA_SELECTED_NAME));
            if (NWM_OpenWindow(oPlayer, VMAN_NUI_LOG_WINDOW_NAME))
            {
                VMan_UpdateEventLog(nCharacterId, sName);   
            }
        }
    }
}

// @NWMEVENT[VMAN_NUI_MAIN_WINDOW_NAME:NUI_EVENT_CLOSE:NUI_WINDOW_ROOT_GROUP]
void VMan_MainWindowClose()
{
    object oPlayer = OBJECT_SELF;

    if (NWM_GetIsWindowOpen(oPlayer, VMAN_NUI_LOG_WINDOW_NAME))
        NWM_CloseWindow(oPlayer, VMAN_NUI_LOG_WINDOW_NAME);
}

// @NWMWINDOW[VMAN_NUI_LOG_WINDOW_NAME]
json VMan_CreateLogWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 500.0f, 300.0f));
    NB_SetWindowTitle(NuiBind(VMAN_BIND_WINDOW_NAME));
        NB_StartColumn();
            NB_StartList(NuiBind(VMAN_BIND_LIST_ICONS), 32.0f);
                NB_StartListTemplateCell(32.0f, FALSE);
                    NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                        NB_StartElement(NuiImage(NuiBind(VMAN_BIND_LIST_ICONS), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();
                NB_End();
                NB_StartListTemplateCell(0.0f, TRUE);
                    NB_StartElement(NuiLabel(NuiBind(VMAN_BIND_LIST_LABELS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_End();
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}  

// @PMBUTTON[Vault Manager:Manage your character vault]
void VMan_ShowMainWindow()
{
    object oPlayer = OBJECT_SELF;

    if (NWM_GetIsWindowOpen(oPlayer, VMAN_NUI_MAIN_WINDOW_NAME))
        NWM_CloseWindow(oPlayer, VMAN_NUI_MAIN_WINDOW_NAME);
    else if (NWM_OpenWindow(oPlayer, VMAN_NUI_MAIN_WINDOW_NAME))
    {      
        struct ProfilerData pd = Profiler_Start("VMan_LoadCharacterList");
        VMan_LoadCharacterList();
        Profiler_Stop(pd);

        VMan_UpdateSelectedCharacterData(StringToInt(NWNX_Player_GetBicFileName(oPlayer)));
    }
}

// @CONSOLE[VManPlayersOnline::]
string VMan_ConsolePlayersOnline()
{
    return "Players Online: " + IntToString(VMan_GetPlayersOnline());
}

sqlquery VMan_PrepareQuery(string sQuery)
{
    return SqlPrepareQueryCampaign(VMAN_DATABASE_NAME, sQuery);
}

int VMan_GetPlayersOnline()
{
    string sQuery = "SELECT COUNT(id) FROM " + VMAN_STATUS_TABLE + ";";
    sqlquery sql = VMan_PrepareQuery(sQuery);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void VMan_LoadCharacterList()
{
    object oPlayer = OBJECT_SELF;
    string sCDKey = GetPCPublicCDKey(oPlayer);
    string sIds, sNames, sPortraits;

    string sQuery = "SELECT " + VMAN_CHARACTERS_TABLE + ".id, " + VMAN_CHARACTERS_TABLE + ".owner, " + 
                        "json_extract(" + VMAN_CHARACTERS_TABLE + ".character, '$.FirstName.value.0') || ' ' || " +
                        "json_extract(" + VMAN_CHARACTERS_TABLE + ".character, '$.LastName.value.0') AS fullName, " +
                        "json_extract(" + VMAN_CHARACTERS_TABLE + ".character, '$.Portrait.value') " +
                    "FROM " + VMAN_CHARACTERS_TABLE + " INNER JOIN " + VMAN_ACCESS_TABLE + " "  + 
                    "ON " + VMAN_ACCESS_TABLE + ".id = " + VMAN_CHARACTERS_TABLE + ".id WHERE " + VMAN_ACCESS_TABLE + ".cdkey = @cdkey ORDER BY fullName;";
    sqlquery sql = VMan_PrepareQuery(sQuery);
    SqlBindString(sql, "@cdkey", sCDKey);

    while (SqlStep(sql))
    {
        sIds += StringJsonArrayElementInt(SqlGetInt(sql, 0));
        sPortraits += StringJsonArrayElementString(SqlGetString(sql, 3) + "t");
        sNames += StringJsonArrayElementString(SqlGetString(sql, 2) + (SqlGetString(sql, 1) != sCDKey ? " (Shared)" : ""));          
    }

    NWM_SetUserData(VMAN_NUI_USERDATA_IDS, StringJsonArrayElementsToJsonArray(sIds));  
    NWM_SetBind(VMAN_BIND_LIST_PORTRAITS, StringJsonArrayElementsToJsonArray(sPortraits));
    NWM_SetBind(VMAN_BIND_LIST_NAMES, StringJsonArrayElementsToJsonArray(sNames));  
}

void VMan_SetClassInfo(int nClassPosition, int nClassId, int nLevel)
{
    if (nClassId != CLASS_TYPE_INVALID)
    {
        NWM_SetBindString(VMAN_BIND_SELECTED_CLASS_ICON_PREFIX + IntToString(nClassPosition), Get2DAString("classes", "Icon", nClassId));
        NWM_SetBindString(VMAN_BIND_SELECTED_CLASS_LABEL_PREFIX + IntToString(nClassPosition), 
            Get2DAStrRefString("classes", "Name", nClassId) + " (" + IntToString(nLevel) + ")");
        NWM_SetBindBool(VMAN_BIND_SELECTED_CLASS_VISIBLE_PREFIX + IntToString(nClassPosition), TRUE);    
    }
    else
    {
        NWM_SetBindString(VMAN_BIND_SELECTED_CLASS_ICON_PREFIX + IntToString(nClassPosition), "ir_beg"); 
        NWM_SetBindString(VMAN_BIND_SELECTED_CLASS_LABEL_PREFIX + IntToString(nClassPosition), "");
        NWM_SetBindBool(VMAN_BIND_SELECTED_CLASS_VISIBLE_PREFIX + IntToString(nClassPosition), FALSE);           
    }        
}

void VMan_UpdateSelectedCharacterData(int nNewId)
{
    struct ProfilerData pd = Profiler_Start("VMan_UpdateSelectedCharacterData");

    object oPlayer = OBJECT_SELF;
    int nCurrentId = JsonGetInt(NWM_GetUserData(VMAN_NUI_USERDATA_SELECTED_ID));

    if (nCurrentId == nNewId)
        return;

    string sQuery = "SELECT owner, " +
                           "json_extract(character, '$.FirstName.value.0'), " +
                           "json_extract(character, '$.LastName.value.0'), " +
                           "json_extract(character, '$.Portrait.value'), " +
                           "json_extract(character, '$.Race.value'), " +
                           "json_extract(character, '$.Gender.value'), " +
                           "json_extract(character, '$.Gold.value'), " +    
                           "json_extract(character, '$.Experience.value'), " +                                            
                    "IFNULL(json_extract(character, '$.ClassList.value[0].Class.value'), 255), " +
                    "IFNULL(json_extract(character, '$.ClassList.value[1].Class.value'), 255), " +
                    "IFNULL(json_extract(character, '$.ClassList.value[2].Class.value'), 255), " +
                    "IFNULL(json_extract(character, '$.ClassList.value[0].ClassLevel.value'), 0), " +
                    "IFNULL(json_extract(character, '$.ClassList.value[1].ClassLevel.value'), 0), " +
                    "IFNULL(json_extract(character, '$.ClassList.value[2].ClassLevel.value'), 0) " +                                                 
                    "FROM " + VMAN_CHARACTERS_TABLE + " WHERE id = @id;"; 
    sqlquery sql = VMan_PrepareQuery(sQuery);
    SqlBindInt(sql, "@id", nNewId);

    if (SqlStep(sql))
    {
        string sOwner = SqlGetString(sql, 0);
        string sName = SqlGetString(sql, 1) + " " + SqlGetString(sql, 2);
        string sPortrait = SqlGetString(sql, 3) + "l";
        int nRace = SqlGetInt(sql, 4);
        int nGender = SqlGetInt(sql, 5);
        int nGold = SqlGetInt(sql, 6);
        int nExperience = SqlGetInt(sql, 7);
        int nClass1 = SqlGetInt(sql, 8);
        int nClass2 = SqlGetInt(sql, 9);
        int nClass3 = SqlGetInt(sql, 10); 
        int nClassLevel1 = SqlGetInt(sql, 11);
        int nClassLevel2 = SqlGetInt(sql, 12);
        int nClassLevel3 = SqlGetInt(sql, 13);
        int nTotalLevel = nClassLevel1 + nClassLevel2 + nClassLevel3; 

        NWM_SetBindString(VMAN_BIND_SELECTED_NAME, sName + " the " + (nGender ? "Female" : "Male") + " " + Get2DAStrRefString("racialtypes", "Name", nRace));
        NWM_SetBindString(VMAN_BIND_SELECTED_PORTRAIT, sPortrait);
        NWM_SetBindString(VMAN_BIND_SELECTED_GOLD_LABEL, "Gold: " + IntToString(nGold));
        NWM_SetBindString(VMAN_BIND_SELECTED_XP_LABEL, "XP: " + IntToString(nExperience) + " / " + Get2DAString("exptable", "XP", nTotalLevel));
        VMan_SetClassInfo(1, nClass1, nClassLevel1);
        VMan_SetClassInfo(2, nClass2, nClassLevel2);
        VMan_SetClassInfo(3, nClass3, nClassLevel3);

        sQuery = "SELECT cdkey FROM " + VMAN_STATUS_TABLE + " WHERE id = @id;";
        sql = VMan_PrepareQuery(sQuery);
        SqlBindInt(sql, "@id", nNewId);

        string sStatus = "Available";
        json jStatusColor = NuiColor(0, 255, 0);
        if (SqlStep(sql))
        {
            string sCDKey = SqlGetString(sql, 0);

            if (sCDKey == GetPCPublicCDKey(oPlayer))
            {
                sStatus = "Logged In (YOU)";
                jStatusColor = NuiColor(255, 140, 0);
            }
            else
            {
                sStatus = "Logged In (" + sCDKey + ")";
                jStatusColor = NuiColor(255, 0, 0);
            }            
        }
        NWM_SetBindString(VMAN_BIND_SELECTED_STATUS_LABEL, sStatus);
        NWM_SetBind(VMAN_BIND_SELECTED_STATUS_COLOR, jStatusColor);
        
        NWM_SetUserData(VMAN_NUI_USERDATA_SELECTED_ID, JsonInt(nNewId));
        NWM_SetUserData(VMAN_NUI_USERDATA_SELECTED_NAME, JsonString(sName));

        if (NWM_GetIsWindowOpen(oPlayer, VMAN_NUI_LOG_WINDOW_NAME, TRUE))
            VMan_UpdateEventLog(nNewId, sName);               
    }

    Profiler_Stop(pd);
} 

string VMan_EventToString(int nEvent)
{
    switch (nEvent)
    {
        case NWNX_VAULT_EVENT_TYPE_CREATED:
            return "Created";
        case NWNX_VAULT_EVENT_TYPE_LOGIN:
            return "Login";
        case NWNX_VAULT_EVENT_TYPE_LOGOUT:
            return "Logout";                          
    }

    return "";
}

string VMan_EventToIcon(int nEvent)
{
    switch (nEvent)
    {
        case NWNX_VAULT_EVENT_TYPE_CREATED:
            return "ir_cast";
        case NWNX_VAULT_EVENT_TYPE_LOGIN:
            return "ief_moveincr";
        case NWNX_VAULT_EVENT_TYPE_LOGOUT:
            return "ief_movedecr";                          
    }

    return "";
}

void VMan_UpdateEventLog(int nCharacterId, string sName)
{
    string sIcons, sLabels;
    sqlquery sql = VMan_PrepareQuery("SELECT cdkey, event, datetime(timestamp, 'unixepoch', 'localtime') FROM vault_log WHERE id = @id ORDER BY rowid DESC LIMIT 100;");
    SqlBindInt(sql, "@id", nCharacterId);

    while (SqlStep(sql))
    {
        int nEvent = SqlGetInt(sql, 1);

        sIcons += StringJsonArrayElementString(VMan_EventToIcon(nEvent));
        sLabels += StringJsonArrayElementString("[" + SqlGetString(sql, 2) + "] " + SqlGetString(sql, 0) + ": " + VMan_EventToString(nEvent));
    }      

    NWM_SetBindString(VMAN_BIND_WINDOW_NAME, "Event Log: " + sName);
    NWM_SetBind(VMAN_BIND_LIST_ICONS, StringJsonArrayElementsToJsonArray(sIcons));
    NWM_SetBind(VMAN_BIND_LIST_LABELS, StringJsonArrayElementsToJsonArray(sLabels));
}
