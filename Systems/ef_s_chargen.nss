/*
    Script: ef_s_chargen
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_ruleset2da"
#include "ef_s_profiler"

const string CG_LOG_TAG                             = "CharacterGemeration";
const string CG_SCRIPT_NAME                         = "ef_s_chargen";

const string CG_MAIN_WINDOW_ID                      = "CG_MAIN";
const string CG_ABILITY_WINDOW_ID                   = "CG_ABILITY";
const string CG_SKILL_WINDOW_ID                     = "CG_SKILL";

const string CG_BIND_VALUE_GENDER                   = "val_gender";
const string CG_BIND_VALUE_RACE                     = "val_race";
const string CG_BIND_VALUE_FIRST_NAME               = "val_first_name";
const string CG_BIND_VALUE_LAST_NAME                = "val_last_name";
const string CG_BIND_VALUE_CLASS                    = "val_class";
const string CG_BIND_VALUE_ALIGNMENT                = "val_alignment";

const string CG_BIND_COMBO_ENTRIES_RACE             = "combo_entries_race";
const string CG_BIND_COMBO_ENTRIES_CLASS            = "combo_entries_class";
const string CG_BIND_COMBO_ENTRIES_ALIGNMENT        = "combo_entries_alignment";

const string CG_ID_BUTTON_RANDOM_FIRST_NAME         = "btn_random_first_name";
const string CG_ID_BUTTON_RANDOM_LAST_NAME          = "btn_random_last_name";

const string CG_ID_BUTTON_ABILITY_WINDOW            = "btn_ability_window";
const string CG_BIND_BUTTON_ABILITY_WINDOW_ENABLED  = "btn_ability_window_enabled";
const string CG_ID_BUTTON_SKILL_WINDOW              = "btn_skill_window";
const string CG_BIND_BUTTON_SKILL_WINDOW_ENABLED    = "btn_skill_window_enabled";
const string CG_ID_BUTTON_FEAT_WINDOW               = "btn_feat_window";
const string CG_BIND_BUTTON_FEAT_WINDOW_ENABLED     = "btn_feat_window_enabled";

const string CG_ID_BUTTON_OK                        = "btn_ok";
const string CG_ID_BUTTON_OK_ENABLED                = "btn_ok_enabled";
const string CG_ID_BUTTON_LIST_ADJUST               = "btn_list_adjust";
const string CG_BIND_LIST_ICONS                     = "list_icons";
const string CG_BIND_LIST_NAMES                     = "list_names";
const string CG_BIND_LIST_VALUES                    = "list_values";
const string CG_BIND_TEXT_POINTS_REMAINING          = "list_points_remaining";

const string CG_USERDATA_RACE                       = "Race";
const string CG_USERDATA_CLASS                      = "Class";
const string CG_USERDATA_ABILITY_POINT_BUY_NUMBER   = "AbilityPointBuyNumber";
const string CG_USERDATA_BASE_ABILITY_SCORES        = "BaseAbilityScores";
const string CG_USERDATA_SKILLPOINTS_REMAINING      = "SkillPointsRemaining";
const string CG_USERDATA_SKILLRANKS                 = "SkillRanks";
const string CG_USERDATA_CLASS_AVAILABLE_SKILLS     = "ClassAvailableSkills";

const string CG_CURRENT_STATE                       = "CurrentState";
const int CG_STATE_BASE                             = 1;
const int CG_STATE_ABILITY                          = 2;
const int CG_STATE_SKILL                            = 3;
const int CG_STATE_FEAT                             = 4;

void CG_LoadRaceData();
void CG_LoadClassData();
void CG_LoadSkillData();
void CG_LoadFeatData();

void CG_SetCurrentState(int nState);
int CG_GetCurrentState();
void CG_ChangeState(int nState);

void CG_CloseChildWindows(string sWindowIdToSkip = "");

void CG_LoadRaceComboBox();
void CG_LoadClassComboBox();
void CG_UpdateAlignmentComboBox();

void CG_SetAbilityPointBuyNumber(int nPoints);
int CG_GetAbilityPointBuyNumber();
void CG_ModifyAbilityPointBuyNumber(int nModify);
int CG_GetRacialAbilityAdjust(int nRace, int nAbility);
int CG_GetClassAbilityAdjust(int nClass, int nAbility);
void CG_SetBaseAbilityScores();
int CG_GetAdjustedAbilityScore(int nAbility);

void CG_SetBaseSkillValues();

// @CORE[EF_SYSTEM_INIT]
void CG_Init()
{
    CG_LoadRaceData();
    CG_LoadClassData();
    CG_LoadSkillData();
}

// @CORE[EF_SYSTEM_POST]
void CG_Post()
{
    CG_LoadFeatData();
}

// *** DATA FUNCTIONS

void CG_LoadRaceData()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_races (" +
                    "id INTEGER NOT NULL, " +
                    "name TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();
    
    int nRow, nNumRows = Get2DARowCount("racialtypes");
    for (nRow = 0; nRow < nNumRows; nRow++)
    {
        if (!StringToInt(Get2DAString("racialtypes", "PlayerRace", nRow)))
            continue;

        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + CG_SCRIPT_NAME + "_races(id, name) VALUES(@id, @name);");
        SqlBindInt(sql, "@id", nRow);
        SqlBindString(sql, "@name", Get2DAStrRefString("racialtypes", "Name", nRow));                
        SqlStep(sql);
    }

    SqlCommitTransactionModule();    
}

void CG_LoadClassData()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_classes (" +
                    "id INTEGER NOT NULL, " +
                    "name TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();
    
    int nRow, nNumRows = Get2DARowCount("classes");
    for (nRow = 0; nRow < nNumRows; nRow++)
    {
        if (!StringToInt(Get2DAString("classes", "PlayerClass", nRow)) || Get2DAString("classes", "PreReqTable", nRow) != "")
            continue;

        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + CG_SCRIPT_NAME + "_classes(id, name) VALUES(@id, @name);");
        SqlBindInt(sql, "@id", nRow);
        SqlBindString(sql, "@name", Get2DAStrRefString("classes", "Name", nRow));                
        SqlStep(sql);
    }

    SqlCommitTransactionModule();    
}

void CG_LoadSkillData()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_skills (" +
                    "id INTEGER NOT NULL, " +
                    "name TEXT NOT NULL, " +
                    "icon TEXT NOT NULL, " +
                    "all_classes_can_use INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();
    
    int nRow, nNumRows = Get2DARowCount("skills");
    for (nRow = 0; nRow < nNumRows; nRow++)
    {
        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + CG_SCRIPT_NAME + "_skills(id, name, icon, all_classes_can_use) VALUES(@id, @name, @icon, @all_classes_can_use);");
        SqlBindInt(sql, "@id", nRow);
        SqlBindString(sql, "@name", Get2DAStrRefString("skills", "Name", nRow));
        SqlBindString(sql, "@icon", Get2DAString("skills", "Icon", nRow)); 
        SqlBindInt(sql, "@all_classes_can_use", StringToInt(Get2DAString("skills", "AllClassesCanUse", nRow)));               
        SqlStep(sql);
    }

    sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_class_skills (" +
             "class INTEGER NOT NULL, " +
             "id INTEGER NOT NULL, " +
             "class_skill INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sqlquery sqlClasses = SqlPrepareQueryModule("SELECT id FROM " + CG_SCRIPT_NAME + "_classes;");
    while (SqlStep(sqlClasses))
    {
        int nClass = SqlGetInt(sqlClasses, 0);
        string sSkillsTable = Get2DAString("classes", "SkillsTable", nClass);
    
        int nRow, nNumRows = Get2DARowCount(sSkillsTable);
        for (nRow = 0; nRow < nNumRows; nRow++)
        {
            sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + CG_SCRIPT_NAME + "_class_skills(class, id, class_skill) VALUES(@class, @id, @class_skill);");
            SqlBindInt(sql, "@class", nClass);
            SqlBindInt(sql, "@id", StringToInt(Get2DAString(sSkillsTable, "SkillIndex", nRow)));
            SqlBindInt(sql, "@class_skill", StringToInt(Get2DAString(sSkillsTable, "ClassSkill", nRow)));           
            SqlStep(sql);  
        }     
    } 

    SqlCommitTransactionModule();      
}

// Feats ... 
// Step 1: Grab all granted on level 1 feats for all classes. 
// Step 2: Grab all feats that all classes can use and aren't invalid or have an epic level prereq

const string CG_CLASS_FEATS_GRANTED_ON_LEVEL1 = "ClassFeatsGrantedOnLevel1_";

void CG_LoadLevel1GrantedFeats()
{
    sqlquery sqlClasses = SqlPrepareQueryModule("SELECT id FROM " + CG_SCRIPT_NAME + "_classes;");
    while (SqlStep(sqlClasses))
    {
        int nClass = SqlGetInt(sqlClasses, 0);
        string sFeatsTable = Get2DAString("classes", "FeatsTable", nClass);
        json jGrantedLevel1Feats = JsonArray();
    
        int nRow, nNumRows = Get2DARowCount(sFeatsTable);
        for (nRow = 0; nRow < nNumRows; nRow++)
        {
            if (StringToInt(Get2DAString(sFeatsTable, "List", nRow)) == 3 &&
                StringToInt(Get2DAString(sFeatsTable, "GrantedOnLevel", nRow)) == 1)
            {
                jGrantedLevel1Feats = JsonArrayInsertUniqueInt(jGrantedLevel1Feats, StringToInt(Get2DAString(sFeatsTable, "FeatIndex", nRow)));  
            }                
        }

        SetLocalJson(GetDataObject(CG_SCRIPT_NAME), CG_CLASS_FEATS_GRANTED_ON_LEVEL1 + IntToString(nClass), jGrantedLevel1Feats);      
    }        
}

void CG_LoadFeatData()
{
    CG_LoadLevel1GrantedFeats();
    /*
    string sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_feats (" +
                    "id INTEGER NOT NULL, " +
                    "name TEXT NOT NULL, " +
                    "icon TEXT NOT NULL, " +
                    "all_classes_can_use INTEGER NOT NULL, " +
                    "masterfeat INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));    

    SqlBeginTransactionModule();

    int nFeat, nNumFeats = Get2DARowCount("feat");
    for (nFeat = 0; nFeat < nNumFeats; nFeat++)
    {
        if (StringToInt(Get2DAString("feat", "PreReqEpic", nFeat)))
            continue; // Don't care about epic feats for level 1        
        
        string sNameStrRef = Get2DAString("feat", "FEAT", nFeat);
        if (sNameStrRef == "")
            continue; // Don't care about invalid feats either

        string sMasterFeat = Get2DAString("feat", "MASTERFEAT", nFeat);

        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + CG_SCRIPT_NAME + "_feats(id, name, icon, all_classes_can_use, masterfeat) VALUES(@class, @id, @name, @icon, @all_classes_can_use, @masterfeat);");
        SqlBindInt(sql, "@id", nFeat);
        SqlBindString(sql, "@name", GetStringByStrRef(StringToInt(sNameStrRef)));
        SqlBindString(sql, "@icon", Get2DAString("feat", "ICON", nFeat));   
        SqlBindInt(sql, "@all_classes_can_use", StringToInt(Get2DAString("feat", "ALLCLASSESCANUSE", nFeat)));                    
        SqlBindInt(sql, "@masterfeat", sMasterFeat == "" ? -1 : StringToInt(sMasterFeat));
        SqlStep(sql);             
    }

    SqlCommitTransactionModule();
    */     
}

// *** STATE FUNCTIONS

void CG_SetCurrentState(int nState)
{
    NWM_SetUserDataInt(CG_CURRENT_STATE, nState);
}

int CG_GetCurrentState()
{
    return NWM_GetUserDataInt(CG_CURRENT_STATE);
}

void CG_ChangeState(int nState)
{
    PrintString("State Change: " + IntToString(nState));

    CG_SetCurrentState(nState);

    switch (nState)
    {
        case CG_STATE_BASE:
        {
            CG_CloseChildWindows();
            NWM_SetBindBool(CG_BIND_BUTTON_ABILITY_WINDOW_ENABLED, FALSE);
            NWM_SetBindBool(CG_BIND_BUTTON_SKILL_WINDOW_ENABLED, FALSE);
            NWM_SetBindBool(CG_BIND_BUTTON_FEAT_WINDOW_ENABLED, FALSE);            
            CG_SetBaseAbilityScores();
            CG_ChangeState(CG_STATE_ABILITY);
            break;
        }

        case CG_STATE_ABILITY:
        {
            CG_CloseChildWindows(CG_ABILITY_WINDOW_ID);
            NWM_SetBindBool(CG_BIND_BUTTON_ABILITY_WINDOW_ENABLED, TRUE);
            NWM_SetBindBool(CG_BIND_BUTTON_SKILL_WINDOW_ENABLED, FALSE);
            NWM_SetBindBool(CG_BIND_BUTTON_FEAT_WINDOW_ENABLED, FALSE);
            break;
        }

        case CG_STATE_SKILL:
        { 
            CG_CloseChildWindows(CG_SKILL_WINDOW_ID);
            NWM_SetBindBool(CG_BIND_BUTTON_SKILL_WINDOW_ENABLED, TRUE);
            CG_SetBaseSkillValues(); 
            break;
        }

        case CG_STATE_FEAT:
        {
            NWM_SetBindBool(CG_BIND_BUTTON_FEAT_WINDOW_ENABLED, TRUE);
            break;
        }                        
    }
}

// *** WINDOWS

void CG_CloseChildWindows(string sWindowIdToSkip = "")
{
    object oPlayer = OBJECT_SELF;    

    if (sWindowIdToSkip != CG_ABILITY_WINDOW_ID)
        NWM_CloseWindow(oPlayer, CG_ABILITY_WINDOW_ID);

    if (sWindowIdToSkip != CG_SKILL_WINDOW_ID)
        NWM_CloseWindow(oPlayer, CG_SKILL_WINDOW_ID);     
}

// @NWMWINDOW[CG_MAIN_WINDOW_ID]
json CG_CreateMainWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 500.0f, 600.0f));
    NB_SetWindowTitle(JsonString("Character Creator"));
        NB_StartColumn();
            
            NB_StartRow();                
                NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                    NB_SetHeight(24.0f);
                    NB_AddElement(NuiLabel(JsonString("Character Info"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                NB_End();
            NB_End();

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Gender:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartStaticOptions(NUI_DIRECTION_HORIZONTAL, NuiBind(CG_BIND_VALUE_GENDER));
                    NB_SetDimensions(346.0f, 32.0f);
                    NB_AddStaticOptionsEntry("Male");
                    NB_AddStaticOptionsEntry("Female");
                NB_End();
            NB_End();            

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Race:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiCombo(NuiBind(CG_BIND_COMBO_ENTRIES_RACE), NuiBind(CG_BIND_VALUE_RACE)));
                    NB_SetDimensions(346.0f, 32.0f);
                NB_End();
            NB_End();           
            
            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("First Name:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiTextEdit(JsonString(""), NuiBind(CG_BIND_VALUE_FIRST_NAME), 256, FALSE));
                    NB_SetHeight(32.0f);
                NB_End();
                NB_StartElement(NuiButtonImage(JsonString("ir_cheer")));
                    NB_SetDimensions(32.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_RANDOM_FIRST_NAME);
                NB_End();
            NB_End();

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Last Name:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiTextEdit(JsonString(""), NuiBind(CG_BIND_VALUE_LAST_NAME), 256, FALSE));
                    NB_SetHeight(32.0f);
                NB_End();
                NB_StartElement(NuiButtonImage(JsonString("ir_cheer")));
                    NB_SetDimensions(32.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_RANDOM_LAST_NAME);
                NB_End();                
            NB_End();

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Class:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiCombo(NuiBind(CG_BIND_COMBO_ENTRIES_CLASS), NuiBind(CG_BIND_VALUE_CLASS)));
                    NB_SetDimensions(346.0f, 32.0f);
                NB_End();
            NB_End();

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Alignment:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiCombo(NuiBind(CG_BIND_COMBO_ENTRIES_ALIGNMENT), NuiBind(CG_BIND_VALUE_ALIGNMENT)));
                    NB_SetDimensions(346.0f, 32.0f);
                NB_End();
            NB_End();

            NB_StartRow();
                NB_StartElement(NuiLabel(JsonString(""), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();           
                NB_StartElement(NuiButton(JsonString("Abilities")));
                    NB_SetDimensions(346.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_ABILITY_WINDOW);
                    NB_SetEnabled(NuiBind(CG_BIND_BUTTON_ABILITY_WINDOW_ENABLED));
                NB_End();
                NB_AddSpacer();                             
            NB_End();

            NB_StartRow();                
                NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                    NB_SetHeight(24.0f);
                    NB_AddElement(NuiLabel(JsonString("Packages"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                NB_End();
            NB_End();            

            NB_StartRow();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("Skills")));
                    NB_SetDimensions(150.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_SKILL_WINDOW);
                    NB_SetEnabled(NuiBind(CG_BIND_BUTTON_SKILL_WINDOW_ENABLED));
                NB_End();
                NB_AddSpacer(); 
                NB_StartElement(NuiButton(JsonString("Feats")));
                    NB_SetDimensions(150.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_FEAT_WINDOW);
                    NB_SetEnabled(NuiBind(CG_BIND_BUTTON_FEAT_WINDOW_ENABLED));
                NB_End();
                NB_AddSpacer();                              
            NB_End();

            NB_StartRow();
                NB_AddSpacer();
            NB_End();                                                                                 

        NB_End();            
    return NB_FinalizeWindow();
}

// @NWMWINDOW[CG_ABILITY_WINDOW_ID]
json CG_CreateAbilityWindow()
{
   NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 280.0f, 300.0f));
    NB_SetWindowTitle(JsonString("Character Creator: Abilities"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartList(NuiBind(CG_BIND_LIST_NAMES), 28.0f, TRUE, NUI_SCROLLBARS_NONE);
                    NB_SetHeight(200.0f);
                    NB_StartListTemplateCell(2.0f, FALSE);
                        NB_AddSpacer();
                    NB_End();
                    NB_StartListTemplateCell(100.0f, FALSE);
                        NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(30.0f, TRUE);
                        NB_AddSpacer();
                    NB_End();
                    NB_StartListTemplateCell(50.0f, FALSE);
                        NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_VALUES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(14.0f, FALSE);
                        NB_StartElement(NuiSpacer());
                            NB_SetId(CG_ID_BUTTON_LIST_ADJUST);
                            NB_StartDrawList(JsonBool(FALSE));                                
                                NB_AddDrawListItem(NuiDrawListImage(JsonBool(TRUE), JsonString("nui_cnt_up"), NuiRect(0.0f, 0.0f, 14.0f, 14.0f),
                                        JsonInt(NUI_ASPECT_EXACTSCALED), JsonInt(NUI_VALIGN_MIDDLE), JsonInt(NUI_HALIGN_CENTER)));
                                NB_AddDrawListItem(NuiDrawListImage(JsonBool(TRUE), JsonString("nui_cnt_down"), NuiRect(0.0f, 14.0f, 14.0f, 14.0f),
                                        JsonInt(NUI_ASPECT_EXACTSCALED), JsonInt(NUI_VALIGN_MIDDLE), JsonInt(NUI_HALIGN_CENTER))); 
                            NB_End();
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiLabel(NuiBind(CG_BIND_TEXT_POINTS_REMAINING), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(150.0f, 32.0f);
                NB_End(); 
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("OK")));
                    NB_SetDimensions(100.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_OK);
                    NB_SetEnabled(NuiBind(CG_ID_BUTTON_OK_ENABLED));
                NB_End();             
            NB_End();                
        NB_End();
    return NB_FinalizeWindow();        
}

// @NWMWINDOW[CG_SKILL_WINDOW_ID]
json CG_CreateSkillWindow()
{
   NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 450.0f, 600.0f));
    NB_SetWindowTitle(JsonString("Character Creator: Skills"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartList(NuiBind(CG_BIND_LIST_ICONS), 32.0f, TRUE, NUI_SCROLLBARS_Y);
                    NB_SetHeight(500.0f);                     
                    NB_StartListTemplateCell(32.0f, FALSE);
                        NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                            NB_StartElement(NuiImage(NuiBind(CG_BIND_LIST_ICONS), JsonInt(NUI_ASPECT_EXACTSCALED), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_End();
                        NB_End();
                    NB_End();                    
                    NB_StartListTemplateCell(250.0f, FALSE);
                        NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(30.0f, TRUE);
                        NB_AddSpacer();
                    NB_End();
                    NB_StartListTemplateCell(50.0f, FALSE);
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_VALUES), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_End();
                        NB_End();                            
                    NB_End();
                    NB_StartListTemplateCell(14.0f, FALSE);
                        NB_StartElement(NuiSpacer());
                            NB_SetId(CG_ID_BUTTON_LIST_ADJUST);
                            NB_StartDrawList(JsonBool(FALSE));                                
                                NB_AddDrawListItem(NuiDrawListImage(JsonBool(TRUE), JsonString("nui_cnt_up"), NuiRect(0.0f, 2.0f, 14.0f, 14.0f),
                                        JsonInt(NUI_ASPECT_EXACTSCALED), JsonInt(NUI_VALIGN_MIDDLE), JsonInt(NUI_HALIGN_CENTER)));
                                NB_AddDrawListItem(NuiDrawListImage(JsonBool(TRUE), JsonString("nui_cnt_down"), NuiRect(0.0f, 16.0f, 14.0f, 14.0f),
                                        JsonInt(NUI_ASPECT_EXACTSCALED), JsonInt(NUI_VALIGN_MIDDLE), JsonInt(NUI_HALIGN_CENTER))); 
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(4.0f, FALSE);
                        NB_AddSpacer();
                    NB_End();
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiLabel(NuiBind(CG_BIND_TEXT_POINTS_REMAINING), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(170.0f, 32.0f);
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("OK")));
                    NB_SetDimensions(100.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_OK);
                NB_End();             
            NB_End();                
        NB_End();
    return NB_FinalizeWindow();        
}

// *** PLAYER MENU BUTTON

// @PMBUTTON[Character Creator:Create a new character]
void CG_ShowMainWindow()
{
    object oPlayer = OBJECT_SELF;

    if (NWM_GetIsWindowOpen(oPlayer, CG_MAIN_WINDOW_ID))
        NWM_CloseWindow(oPlayer, CG_MAIN_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, CG_MAIN_WINDOW_ID))
    {      
        CG_LoadRaceComboBox();
        CG_LoadClassComboBox();

        CG_ChangeState(CG_STATE_BASE);
     }
}

// *** RACE 

void CG_LoadRaceComboBox()
{
    int nInitialId = -1;
    json jComboEntries = JsonArray();
    sqlquery sql = SqlPrepareQueryModule("SELECT id, name FROM " + CG_SCRIPT_NAME + "_races");
    while (SqlStep(sql))
    {
        int nId = SqlGetInt(sql, 0);
        string sName = SqlGetString(sql, 1);

        if (nInitialId == -1)
            nInitialId = nId;        

        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry(sName, nId));
    }

    NWM_SetBind(CG_BIND_COMBO_ENTRIES_RACE, jComboEntries);
    NWM_SetBindWatch(CG_BIND_VALUE_RACE, TRUE);
    NWM_SetBindInt(CG_BIND_VALUE_RACE, nInitialId);    
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_WATCH:CG_BIND_VALUE_RACE]
void CG_WatchRaceBind()
{    
    NWM_SetUserData(CG_USERDATA_RACE, NWM_GetBind(CG_BIND_VALUE_RACE));
    CG_ChangeState(CG_STATE_BASE);
}

// *** CHARACTER NAME

string CG_GetRandomCharacterName(int nRace, int nGender, int bFirstName)
{
    string sName;
    if (bFirstName)
        sName = RandomName(2 + ((nRace == 3 ? 4 : nRace == 4 ? 3 : nRace) * 3) + nGender > 0);
    else 
        sName = RandomName(2 + (nRace * 3) + 2);

    return sName;
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_RANDOM_FIRST_NAME]
void CG_ClickFirstNameButton()
{
    int nRace = NWM_GetUserDataInt(CG_USERDATA_RACE);
    int nGender = NWM_GetBindInt(CG_BIND_VALUE_GENDER);
    NWM_SetBindString(CG_BIND_VALUE_FIRST_NAME, CG_GetRandomCharacterName(nRace, nGender, TRUE));
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_RANDOM_LAST_NAME]
void CG_ClickLastNameButton()
{
    int nRace = NWM_GetUserDataInt(CG_USERDATA_RACE);
    int nGender = NWM_GetBindInt(CG_BIND_VALUE_GENDER);    
    NWM_SetBindString(CG_BIND_VALUE_LAST_NAME, CG_GetRandomCharacterName(nRace, nGender, FALSE));
}

// *** CLASS

void CG_LoadClassComboBox()
{
    int nInitialId = -1;
    json jComboEntries = JsonArray();
    sqlquery sql = SqlPrepareQueryModule("SELECT id, name FROM " + CG_SCRIPT_NAME + "_classes");
    while (SqlStep(sql))
    {
        int nId = SqlGetInt(sql, 0);
        string sName = SqlGetString(sql, 1);

        if (nInitialId == -1)
            nInitialId = nId;

        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry(sName, nId));
    }

    NWM_SetBind(CG_BIND_COMBO_ENTRIES_CLASS, jComboEntries);
    NWM_SetBindWatch(CG_BIND_VALUE_CLASS, TRUE);
    NWM_SetBindInt(CG_BIND_VALUE_CLASS, nInitialId);
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_WATCH:CG_BIND_VALUE_CLASS]
void CG_WatchClassBind()
{
    NWM_SetUserData(CG_USERDATA_CLASS, NWM_GetBind(CG_BIND_VALUE_CLASS));    
    CG_ChangeState(CG_STATE_BASE);
    CG_UpdateAlignmentComboBox();    
}

// *** ALIGNMENT

int CG_GetIsAlignmentAllowed(int nClass, int nLawfulChaoticConstant, int nGoodEvilConstant)
{
    int nAlignRestrict = HexStringToInt(Get2DAString("classes", "AlignRestrict", nClass));
    int nAlignRestrictType = HexStringToInt(Get2DAString("classes", "AlignRstrctType", nClass));
    int bInvertRestrict = StringToInt(Get2DAString("classes", "InvertRestrict", nClass));

    if ((nAlignRestrictType & 0x1))    
    {
        if ((nLawfulChaoticConstant == ALIGNMENT_LAWFUL  && ((nAlignRestrict & 0x02))) ||
            (nLawfulChaoticConstant == ALIGNMENT_NEUTRAL && ((nAlignRestrict & 0x01))) ||
            (nLawfulChaoticConstant == ALIGNMENT_CHAOTIC && ((nAlignRestrict & 0x04))))
            return bInvertRestrict;        
    }

    if ((nAlignRestrictType & 0x2))    
    {
        if ((nGoodEvilConstant == ALIGNMENT_GOOD    && ((nAlignRestrict & 0x08))) ||
            (nGoodEvilConstant == ALIGNMENT_NEUTRAL && ((nAlignRestrict & 0x01))) ||
            (nGoodEvilConstant == ALIGNMENT_EVIL    && ((nAlignRestrict & 0x10))))
            return bInvertRestrict;        
    }

    return !bInvertRestrict;    
}

int CG_CombineAlignmentConstants(int nLawfulChaoticConstant, int nGoodEvilConstant)
{
    return StringToInt(IntToString(nLawfulChaoticConstant) + IntToString(nGoodEvilConstant));
}

void CG_UpdateAlignmentComboBox()
{
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);
    json jComboEntries = JsonArray();

    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_LAWFUL, ALIGNMENT_GOOD))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("Lawful Good", CG_CombineAlignmentConstants(ALIGNMENT_LAWFUL, ALIGNMENT_GOOD)));
    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_NEUTRAL, ALIGNMENT_GOOD))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("Neutral Good", CG_CombineAlignmentConstants(ALIGNMENT_NEUTRAL, ALIGNMENT_GOOD)));
    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_CHAOTIC, ALIGNMENT_GOOD))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("Chaotic Good", CG_CombineAlignmentConstants(ALIGNMENT_CHAOTIC, ALIGNMENT_GOOD)));

    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_LAWFUL, ALIGNMENT_NEUTRAL))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("Lawful Neutral", CG_CombineAlignmentConstants(ALIGNMENT_LAWFUL, ALIGNMENT_NEUTRAL)));
    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_NEUTRAL, ALIGNMENT_NEUTRAL))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("True Neutral", CG_CombineAlignmentConstants(ALIGNMENT_NEUTRAL, ALIGNMENT_NEUTRAL)));
    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_CHAOTIC, ALIGNMENT_NEUTRAL))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("Chaotic Neutral", CG_CombineAlignmentConstants(ALIGNMENT_CHAOTIC, ALIGNMENT_NEUTRAL)));

    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_LAWFUL, ALIGNMENT_EVIL))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("Lawful Evil", CG_CombineAlignmentConstants(ALIGNMENT_LAWFUL, ALIGNMENT_EVIL)));
    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_NEUTRAL, ALIGNMENT_EVIL))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("Neutral Evil", CG_CombineAlignmentConstants(ALIGNMENT_NEUTRAL, ALIGNMENT_EVIL)));
    if (CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_CHAOTIC, ALIGNMENT_EVIL))
        jComboEntries = JsonArrayInsert(jComboEntries, NuiComboEntry("Chaotic Evil", CG_CombineAlignmentConstants(ALIGNMENT_CHAOTIC, ALIGNMENT_EVIL)));                                  
    
    NWM_SetBind(CG_BIND_COMBO_ENTRIES_ALIGNMENT, jComboEntries);    
}

// *** ABILITY

void CG_SetAbilityPointBuyNumber(int nPoints)
{
    NWM_SetUserDataInt(CG_USERDATA_ABILITY_POINT_BUY_NUMBER, nPoints);    
}

int CG_GetAbilityPointBuyNumber()
{
    return NWM_GetUserDataInt(CG_USERDATA_ABILITY_POINT_BUY_NUMBER); 
}

void CG_ModifyAbilityPointBuyNumber(int nModify)
{
    CG_SetAbilityPointBuyNumber(CG_GetAbilityPointBuyNumber() + nModify);    
}

int CG_GetRacialAbilityAdjust(int nRace, int nAbility)
{
    return StringToInt(Get2DAString("racialtypes", GetStringLeft(AbilityConstantToName(nAbility), 3) + "Adjust", nRace));
}

int CG_GetClassAbilityAdjust(int nClass, int nAbility)
{
    string sStatGainTable = Get2DAString("classes", "StatGainTable", nClass);

    if (sStatGainTable == "")
        return 0;        

    return StringToInt(Get2DAString("sStatGainTable", GetStringLeft(AbilityConstantToName(nAbility), 3), 0));
}

int CG_CalculateAbilityModifier(int nAbilityValue)
{
    int nAbilityNeutralValue = RS2DA_GetIntEntry("CHARGEN_ABILITY_NEUTRAL_VALUE");
    int nAbilityModifierIncrement = RS2DA_GetIntEntry("CHARGEN_ABILITY_MODIFIER_INCREMENT");

    if (nAbilityValue < nAbilityNeutralValue && (nAbilityNeutralValue % 2 == 0))
        return ((nAbilityValue - (nAbilityNeutralValue + 1)) / nAbilityModifierIncrement);
    else
        return ((nAbilityValue - nAbilityNeutralValue) / nAbilityModifierIncrement);
}

void CG_SetBaseAbilityScores()
{
    int nRace = NWM_GetUserDataInt(CG_USERDATA_RACE);
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);
    int nAbilityMin = RS2DA_GetIntEntry("CHARGEN_BASE_ABILITY_MIN"); 
    int nAbilityMinPrimary = RS2DA_GetIntEntry("CHARGEN_BASE_ABILITY_MIN_PRIMARY");

    CG_SetAbilityPointBuyNumber(StringToInt(Get2DAString("racialtypes", "AbilitiesPointBuyNumber", nRace)));
    json jAbilities = GetJsonArrayOfSize(6, JsonInt(nAbilityMin));

    if (StringToInt(Get2DAString("classes", "SpellCaster", nClass)))
    {
        int nSpellcastingAbility = AbilityToConstant(Get2DAString("classes", "SpellcastingAbil", nClass));
        int nCurrentAbilityValue = JsonArrayGetInt(jAbilities, nSpellcastingAbility);
        int nAbilityAdjust = CG_GetRacialAbilityAdjust(nRace, nSpellcastingAbility) + CG_GetClassAbilityAdjust(nClass, nSpellcastingAbility);
        int nPointBuyChange = CG_GetAbilityPointBuyNumber() - (nAbilityMinPrimary - nAbilityMin);

        CG_SetAbilityPointBuyNumber(nPointBuyChange + nAbilityAdjust);
        jAbilities = JsonArraySetInt(jAbilities, nSpellcastingAbility, nAbilityMinPrimary - nAbilityAdjust);
    } 

    NWM_SetUserData(CG_USERDATA_BASE_ABILITY_SCORES, jAbilities);
}

int CG_GetAdjustedAbilityScore(int nAbility)
{
    return JsonArrayGetInt(NWM_GetUserData(CG_USERDATA_BASE_ABILITY_SCORES), nAbility) + 
           CG_GetRacialAbilityAdjust(NWM_GetUserDataInt(CG_USERDATA_RACE), nAbility) + 
           CG_GetClassAbilityAdjust(NWM_GetUserDataInt(CG_USERDATA_CLASS), nAbility);
}

void CG_SetAbilityNames()
{
    json jAbilityNames = JsonArray();
    int nAbility;
    for (nAbility = 0; nAbility < 6; nAbility++)
    {
        jAbilityNames = JsonArrayInsertString(jAbilityNames, AbilityConstantToName(nAbility) + ":");
    }
    NWM_SetBind(CG_BIND_LIST_NAMES, jAbilityNames);    
}

void CG_UpdateAbilityValues()
{
    int nRace = NWM_GetUserDataInt(CG_USERDATA_RACE);
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);
    json jBaseAbilityScores = NWM_GetUserData(CG_USERDATA_BASE_ABILITY_SCORES);
    json jAbilityValues = JsonArray();
    int nAbility;
    for (nAbility = 0; nAbility < 6; nAbility++)
    {
        int nAbilityValue = JsonArrayGetInt(jBaseAbilityScores, nAbility) + CG_GetRacialAbilityAdjust(nRace, nAbility) + CG_GetClassAbilityAdjust(nClass, nAbility);        
        int nModifier = CG_CalculateAbilityModifier(nAbilityValue);        
        jAbilityValues = JsonArrayInsertString(jAbilityValues, IntToString(nAbilityValue) + " (" + (nModifier >= 0 ? "+" : "" ) + IntToString(nModifier) + ")");
    }

    NWM_SetBind(CG_BIND_LIST_VALUES, jAbilityValues);
}

int CG_CalculatePointCost(int nAbilityValue)
{
	if (nAbilityValue < RS2DA_GetIntEntry("CHARGEN_ABILITY_COST_INCREMENT2"))
		return 1;
	if (nAbilityValue < RS2DA_GetIntEntry("CHARGEN_ABILITY_COST_INCREMENT3"))
		return 2;
	if (nAbilityValue < RS2DA_GetIntEntry("CHARGEN_ABILITY_COST_INCREMENT4"))
		return 3;
	return 4;
}

int CG_CheckAbilityAboveMinimum(int nAbility, int nBaseValue)
{
    if (AbilityToConstant(Get2DAString("classes", "SpellcastingAbil", NWM_GetUserDataInt(CG_USERDATA_CLASS))) == nAbility)
        return (nBaseValue + CG_GetRacialAbilityAdjust(NWM_GetUserDataInt(CG_USERDATA_RACE), nAbility)) > RS2DA_GetIntEntry("CHARGEN_BASE_ABILITY_MIN_PRIMARY");
    else
        return nBaseValue > RS2DA_GetIntEntry("CHARGEN_BASE_ABILITY_MIN");
}

void CG_CheckAbilityOkButtonStatus()
{
    if (!CG_GetAbilityPointBuyNumber())
        NWM_SetBindBool(CG_ID_BUTTON_OK_ENABLED, TRUE);
    else
        NWM_SetBindBool(CG_ID_BUTTON_OK_ENABLED, FALSE);
}

void CG_AdjustAbility(int nAbility, int bIncrement)
{
    json jBaseAbilityScores = NWM_GetUserData(CG_USERDATA_BASE_ABILITY_SCORES);
    int nAbilityValue = JsonArrayGetInt(jBaseAbilityScores, nAbility);
    int nPointBuyNumber = CG_GetAbilityPointBuyNumber();

    if (bIncrement)
    {        
        int nAbilityPointCost = CG_CalculatePointCost(nAbilityValue);
        if (nAbilityValue < RS2DA_GetIntEntry("CHARGEN_BASE_ABILITY_MAX") && nAbilityPointCost <= nPointBuyNumber)
        {
            jBaseAbilityScores = JsonArraySetInt(jBaseAbilityScores, nAbility, nAbilityValue + 1);
            CG_ModifyAbilityPointBuyNumber(-nAbilityPointCost);
            NWM_SetUserData(CG_USERDATA_BASE_ABILITY_SCORES, jBaseAbilityScores);
            NWM_SetBindString(CG_BIND_TEXT_POINTS_REMAINING, "Ability Points: " + IntToString(CG_GetAbilityPointBuyNumber()));            
            CG_UpdateAbilityValues();
            CG_CheckAbilityOkButtonStatus();             
        }
    }
    else
    {
        if (CG_CheckAbilityAboveMinimum(nAbility, nAbilityValue))
        {
            nAbilityValue--;
            jBaseAbilityScores = JsonArraySetInt(jBaseAbilityScores, nAbility, nAbilityValue);
            CG_ModifyAbilityPointBuyNumber(CG_CalculatePointCost(nAbilityValue));
            NWM_SetUserData(CG_USERDATA_BASE_ABILITY_SCORES, jBaseAbilityScores);
            NWM_SetBindString(CG_BIND_TEXT_POINTS_REMAINING, "Ability Points: " + IntToString(CG_GetAbilityPointBuyNumber()));
            CG_UpdateAbilityValues(); 
            CG_CheckAbilityOkButtonStatus();
        }
    }    
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_ABILITY_WINDOW]
void CG_ClickAbilitiesButton()
{
    object oPlayer = OBJECT_SELF;
    
    if (NWM_GetIsWindowOpen(oPlayer, CG_ABILITY_WINDOW_ID))
        return;

    CG_ChangeState(CG_STATE_ABILITY);

    if (NWM_OpenWindow(oPlayer, CG_ABILITY_WINDOW_ID))
    {
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_RACE);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_CLASS);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_ABILITY_POINT_BUY_NUMBER);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_BASE_ABILITY_SCORES);
        
        CG_SetAbilityNames();
        CG_UpdateAbilityValues();
        CG_CheckAbilityOkButtonStatus();
        NWM_SetBindString(CG_BIND_TEXT_POINTS_REMAINING, "Ability Points: " + IntToString(CG_GetAbilityPointBuyNumber()));
    }
}

// @NWMEVENT[CG_ABILITY_WINDOW_ID:NUI_EVENT_MOUSEUP:CG_ID_BUTTON_LIST_ADJUST]
void CG_AbilityAdjustmentButtonMouseUp()
{
    json jPayload = NuiGetEventPayload();

    if (NuiGetMouseButton(jPayload) == NUI_MOUSE_BUTTON_LEFT)
    {    
        CG_AdjustAbility(NuiGetEventArrayIndex(), NuiGetMouseY(jPayload) <= 14.0f);
    }
}

// @NWMEVENT[CG_ABILITY_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_OK]
void CG_ClickAbilityOkButton()
{
    object oPlayer = OBJECT_SELF;

    if (NWM_GetIsWindowOpen(oPlayer, CG_MAIN_WINDOW_ID, TRUE))
    {
        NWM_CopyUserData(CG_ABILITY_WINDOW_ID, CG_USERDATA_ABILITY_POINT_BUY_NUMBER);        
        NWM_CopyUserData(CG_ABILITY_WINDOW_ID, CG_USERDATA_BASE_ABILITY_SCORES);        
        CG_ChangeState(CG_STATE_SKILL); 
        NWM_CloseWindow(oPlayer, CG_ABILITY_WINDOW_ID);        
    }  
}

// *** SKILLS

void CG_SetSkillPointsRemaining(int nPoints)
{
    NWM_SetUserDataInt(CG_USERDATA_SKILLPOINTS_REMAINING, nPoints);    
}

int CG_GetSkillPointsRemaining()
{
    return NWM_GetUserDataInt(CG_USERDATA_SKILLPOINTS_REMAINING); 
}

void CG_ModifySkillPointsRemaining(int nModify)
{
    CG_SetSkillPointsRemaining(CG_GetSkillPointsRemaining() + nModify);    
}

void CG_SetBaseSkillValues()
{
    int nRace = NWM_GetUserDataInt(CG_USERDATA_RACE);
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);

    int nFirstLevelSkillPointsMultiplier = StringToInt(Get2DAString("racialtypes", "FirstLevelSkillPointsMultiplier", nRace));
    int nExtraSkillPointsPerLevel = StringToInt(Get2DAString("racialtypes", "ExtraSkillPointsPerLevel", nRace));
    int nClassSkillPointBase = StringToInt(Get2DAString("classes", "SkillPointBase", nClass)); 
    int nSkillPointModifierAbility = AbilityToConstant(Get2DAString("racialtypes", "SkillPointModifierAbility", nRace));
    int nAbilityBonus = CG_CalculateAbilityModifier(CG_GetAdjustedAbilityScore(nSkillPointModifierAbility));
    int nSkillPointsRemaining = (nFirstLevelSkillPointsMultiplier * (max(1, nClassSkillPointBase + nAbilityBonus))) + 
                                (nFirstLevelSkillPointsMultiplier * nExtraSkillPointsPerLevel);

    CG_SetSkillPointsRemaining(nSkillPointsRemaining);
    NWM_SetUserData(CG_USERDATA_SKILLRANKS, GetJsonArrayOfSize(Get2DARowCount("skills"), JsonInt(0)));                                 
}

int CG_GetClassHasSkill(int nClass, int nSkill)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT id FROM "+ CG_SCRIPT_NAME + "_class_skills WHERE class = @class AND id = @id;");
    SqlBindInt(sql, "@class", nClass);
    SqlBindInt(sql, "@id", nSkill);
    return SqlStep(sql);   
}

int CG_GetIsClassSkill(int nClass, int nSkill)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT class_skill FROM "+ CG_SCRIPT_NAME + "_class_skills WHERE class = @class AND id = @id;");
    SqlBindInt(sql, "@class", nClass);
    SqlBindInt(sql, "@id", nSkill);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : FALSE;
}

void CG_SetSkillData(json jSkillRanks)
{
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);

    json jSkillArray = JsonArray();
    json jIconsArray = JsonArray();
    json jNamesArray = JsonArray();
    json jValuesArray = JsonArray();
    
    sqlquery sqlSkills = SqlPrepareQueryModule("SELECT id, name, icon, all_classes_can_use FROM " + CG_SCRIPT_NAME + "_skills ORDER BY name ASC;");
    while (SqlStep(sqlSkills))
    {
        int nSkill = SqlGetInt(sqlSkills, 0);
        string sName = SqlGetString(sqlSkills, 1);
        string sIcon = SqlGetString(sqlSkills, 2);
        int bAllClassesCanUse = SqlGetInt(sqlSkills, 3);

        if (bAllClassesCanUse || CG_GetClassHasSkill(nClass, nSkill))
        {
            jSkillArray = JsonArrayInsertInt(jSkillArray, nSkill);
            jIconsArray = JsonArrayInsertString(jIconsArray, sIcon);
            jNamesArray = JsonArrayInsertString(jNamesArray, sName + (CG_GetIsClassSkill(nClass, nSkill) ? " (Class Skill)" : ""));
            jValuesArray = JsonArrayInsertInt(jValuesArray, JsonArrayGetInt(jSkillRanks, nSkill)); 
        }
    }
    NWM_SetUserData(CG_USERDATA_CLASS_AVAILABLE_SKILLS, jSkillArray);
    NWM_SetBind(CG_BIND_LIST_ICONS, jIconsArray);
    NWM_SetBind(CG_BIND_LIST_NAMES, jNamesArray);
    NWM_SetBind(CG_BIND_LIST_VALUES, jValuesArray);
}

void CG_AdjustSkill(int nSkillIndex, int bIncrement)
{
    json jSkillValues = NWM_GetBind(CG_BIND_LIST_VALUES);
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);
    int nSkill = JsonArrayGetInt(NWM_GetUserData(CG_USERDATA_CLASS_AVAILABLE_SKILLS), nSkillIndex);
    int nCurrentRank = JsonArrayGetInt(jSkillValues, nSkillIndex);
    int nMaxRank = 1 + RS2DA_GetIntEntry("CHARGEN_SKILL_MAX_LEVEL_1_BONUS");
    int nCost = 1;

    if (!CG_GetIsClassSkill(nClass, nSkill))
    {
        nMaxRank /= 2;
        nCost += 1;
    }    

    if (bIncrement)
    {
        if (CG_GetSkillPointsRemaining() >= nCost && nCurrentRank < nMaxRank)
        {
            CG_ModifySkillPointsRemaining(-nCost);
            NWM_SetBind(CG_BIND_LIST_VALUES, JsonArraySetInt(jSkillValues, nSkillIndex, nCurrentRank + 1));
            NWM_SetBindString(CG_BIND_TEXT_POINTS_REMAINING, "Remaining Skill Points: " + IntToString(CG_GetSkillPointsRemaining()));            
        }    
    }
    else
    {
        if (nCurrentRank > 0)
        {
            CG_ModifySkillPointsRemaining(nCost);
            NWM_SetBind(CG_BIND_LIST_VALUES, JsonArraySetInt(jSkillValues, nSkillIndex, nCurrentRank - 1));
            NWM_SetBindString(CG_BIND_TEXT_POINTS_REMAINING, "Remaining Skill Points: " + IntToString(CG_GetSkillPointsRemaining()));            
        } 
    }
}

json CG_GetMergedSkillRanks()
{
    json jSkillRanks = GetJsonArrayOfSize(Get2DARowCount("skills"), JsonInt(0));
    json jSkillArray = NWM_GetUserData(CG_USERDATA_CLASS_AVAILABLE_SKILLS);
    json jSkillValues = NWM_GetBind(CG_BIND_LIST_VALUES);
    int nSkill, nNumSkills = JsonGetLength(jSkillArray);
    for (nSkill = 0; nSkill < nNumSkills; nSkill++)
    {
        jSkillRanks = JsonArraySetInt(jSkillRanks, JsonArrayGetInt(jSkillArray, nSkill), JsonArrayGetInt(jSkillValues, nSkill));
    }  

    return jSkillRanks;
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_SKILL_WINDOW]
void CG_ClickSkillsButton()
{
    object oPlayer = OBJECT_SELF;
    
    if (NWM_GetIsWindowOpen(oPlayer, CG_SKILL_WINDOW_ID))
        return;

    if (NWM_OpenWindow(oPlayer, CG_SKILL_WINDOW_ID))
    {
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_RACE);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_CLASS);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_SKILLPOINTS_REMAINING);
        CG_SetSkillData(NWM_GetUserDataFromWindow(CG_MAIN_WINDOW_ID, CG_USERDATA_SKILLRANKS));
        NWM_SetBindString(CG_BIND_TEXT_POINTS_REMAINING, "Remaining Skill Points: " + IntToString(CG_GetSkillPointsRemaining()));
    }
}

// @NWMEVENT[CG_SKILL_WINDOW_ID:NUI_EVENT_MOUSEUP:CG_ID_BUTTON_LIST_ADJUST]
void CG_SkillAdjustmentButtonMouseUp()
{
    json jPayload = NuiGetEventPayload();

    if (NuiGetMouseButton(jPayload) == NUI_MOUSE_BUTTON_LEFT)
    {    
        CG_AdjustSkill(NuiGetEventArrayIndex(), NuiGetMouseY(jPayload) <= 16.0f);
    }
}

// @NWMEVENT[CG_SKILL_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_OK]
void CG_ClickSkillOkButton()
{
    object oPlayer = OBJECT_SELF;
    int nSKillPointsRemaining = CG_GetSkillPointsRemaining();
    json jSkillRanks = CG_GetMergedSkillRanks();

    if (NWM_GetIsWindowOpen(oPlayer, CG_MAIN_WINDOW_ID, TRUE))
    {
        NWM_CopyUserData(CG_SKILL_WINDOW_ID, CG_USERDATA_SKILLPOINTS_REMAINING);
        NWM_SetUserData(CG_USERDATA_SKILLRANKS, jSkillRanks);   
        CG_ChangeState(CG_STATE_FEAT); 
        NWM_CloseWindow(oPlayer, CG_SKILL_WINDOW_ID);        
    }  
}

// *** FEATS

json CG_GetLevel1GrantedFeats(int nClass)
{
    return GetLocalJson(GetDataObject(CG_SCRIPT_NAME), CG_CLASS_FEATS_GRANTED_ON_LEVEL1 + IntToString(nClass));
}

int CG_GetHasFeat(int nClass, int nFeat)
{
    return JsonArrayContainsInt(CG_GetLevel1GrantedFeats(nClass), nFeat);
}
