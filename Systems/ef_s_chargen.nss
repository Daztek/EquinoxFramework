/*
    Script: ef_s_chargen
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_ruleset2da"
#include "ef_s_profiler"

const string CG_LOG_TAG                                 = "CharacterGemeration";
const string CG_SCRIPT_NAME                             = "ef_s_chargen";

const string CG_MAIN_WINDOW_ID                          = "CG_MAIN";
const string CG_ABILITY_WINDOW_ID                       = "CG_ABILITY";
const string CG_SKILL_WINDOW_ID                         = "CG_SKILL";
const string CG_FEAT_WINDOW_ID                          = "CG_FEAT";

const string CG_BIND_VALUE_GENDER                       = "val_gender";
const string CG_BIND_VALUE_RACE                         = "val_race";
const string CG_BIND_VALUE_FIRST_NAME                   = "val_first_name";
const string CG_BIND_VALUE_LAST_NAME                    = "val_last_name";
const string CG_BIND_VALUE_CLASS                        = "val_class";
const string CG_BIND_VALUE_ALIGNMENT                    = "val_alignment";

const string CG_BIND_COMBO_ENTRIES_RACE                 = "combo_entries_race";
const string CG_BIND_COMBO_ENTRIES_CLASS                = "combo_entries_class";
const string CG_BIND_COMBO_ENTRIES_ALIGNMENT            = "combo_entries_alignment";

const string CG_ID_BUTTON_RANDOM_FIRST_NAME             = "btn_random_first_name";
const string CG_ID_BUTTON_RANDOM_LAST_NAME              = "btn_random_last_name";

const string CG_ID_BUTTON_ABILITY_WINDOW                = "btn_ability_window";
const string CG_BIND_BUTTON_ABILITY_WINDOW_ENABLED      = "btn_ability_window_enabled";
const string CG_ID_BUTTON_SKILLFEAT_WINDOW              = "btn_skillfeat_window";
const string CG_BIND_BUTTON_SKILLFEAT_WINDOW_ENABLED    = "btn_skillfeat_window_enabled";

const string CG_ID_BUTTON_OK                            = "btn_ok";
const string CG_ID_BUTTON_OK_ENABLED                    = "btn_ok_enabled";
const string CG_ID_BUTTON_LIST_ADJUST                   = "btn_list_adjust";
const string CG_ID_BUTTON_LIST_ADD_FEAT                 = "btn_list_add_feat";
const string CG_ID_BUTTON_LIST_REMOVE_FEAT              = "btn_list_remove_feat";
const string CG_BIND_LIST_ICONS                         = "list_icons";
const string CG_BIND_LIST_NAMES                         = "list_names";
const string CG_BIND_LIST_VALUES                        = "list_values";
const string CG_BIND_TEXT_POINTS_REMAINING              = "list_points_remaining";

const string CG_BIND_LIST_AVAILABLE_FEATS_PREFIX        = "available_feats_";
const string CG_BIND_LIST_GRANTED_FEATS_PREFIX          = "granted_feats_";
const string CG_BIND_LIST_CHOSEN_FEATS_PREFIX           = "chosen_feats_";

const string CG_BIND_VALUE_SEARCH_TEXT                  = "val_search_text";
const string CG_ID_BUTTON_CLEAR_SEARCH                  = "btn_clear_search";
const string CG_BIND_BUTTON_CLEAR_SEARCH_ENABLED        = "btn_clear_search_enabled";

const string CG_USERDATA_RACE                           = "Race";
const string CG_USERDATA_CLASS                          = "Class";
const string CG_USERDATA_ABILITY_POINT_BUY_NUMBER       = "AbilityPointBuyNumber";
const string CG_USERDATA_BASE_ABILITY_SCORES            = "BaseAbilityScores";
const string CG_USERDATA_SKILLPOINTS_REMAINING          = "SkillPointsRemaining";
const string CG_USERDATA_SKILLRANKS                     = "SkillRanks";
const string CG_USERDATA_CLASS_AVAILABLE_SKILLS         = "ClassAvailableSkills";
const string CG_USERDATA_CHOSEN_FEATS                   = "ChosenFeats";
const string CG_USERDATA_CHOSEN_FEATS_LIST_TYPE         = "ChosenFeatsListType";
const string CG_USERDATA_NUM_NORMAL_FEATS               = "NumNormalFeats";
const string CG_USERDATA_NUM_BONUS_FEATS                = "NumBonusFeats";
const string CG_USERDATA_AVAILABLE_FEAT_LIST            = "AvailableFeatList";

const string CG_CURRENT_STATE                           = "CurrentState";
const int CG_STATE_BASE                                 = 1;
const int CG_STATE_ABILITY                              = 2;
const int CG_STATE_PACKAGES                             = 3;

const string CG_CLASS_BASE_ATTACK_BONUS                 = "ClassBaseAttackBonus_";
const string CG_CLASS_BASE_FORTITUDE_SAVING_THROW       = "ClassBaseFortitudeSavingThrow_";
const string CG_CLASS_BASE_SPELL_LEVEL                  = "ClassBaseSpellLevel_";
const string CG_CLASS_FEATS_GRANTED_ON_LEVEL1           = "ClassFeatsGrantedOnLevel1_";
const string CG_CLASS_NUM_LEVEL_1_BONUS_FEATS           = "ClassNumLevel1BonusFeats_";

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
int CG_GetAdjustedAbilityScore(int nRace, int nClass, int nAbility);

void CG_SetBaseSkillValues();

void CG_SetBaseFeatValues();
void CG_OpenFeatsWindow();

// @CORE[EF_SYSTEM_INIT]
void CG_Init()
{
    // Do not reorder
    CG_LoadRaceData();
    CG_LoadClassData();
    CG_LoadSkillData();
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

void CG_LoadClassBaseStatData(int nClass)
{
    object oDataObject = GetDataObject(CG_SCRIPT_NAME);

    // Base Attack Bonus
    string sAttackBonusTable = Get2DAString("classes", "AttackBonusTable", nClass);
    int nBaseAttackBonus = StringToInt(Get2DAString(sAttackBonusTable, "BAB", 0));
    SetLocalInt(oDataObject, CG_CLASS_BASE_ATTACK_BONUS + IntToString(nClass), nBaseAttackBonus);

    // Fortitude Saving Throw
    string sSavingThrowTable = Get2DAString("classes", "SavingThrowTable", nClass);
    int nBaseFortitudeSave = StringToInt(Get2DAString(sSavingThrowTable, "FortSave", 0)); 
    SetLocalInt(oDataObject, CG_CLASS_BASE_FORTITUDE_SAVING_THROW + IntToString(nClass), nBaseFortitudeSave); 

    // Spell Level
    if (StringToInt(Get2DAString("classes", "SpellCaster", nClass)))
    {
        string sSpellGainTable = Get2DAString("classes", "SpellGainTable", nClass);
        int nBaseSpellLevel = StringToInt(Get2DAString(sSpellGainTable, "NumSpellLevels", 0)) - 1;
        SetLocalInt(oDataObject, CG_CLASS_BASE_SPELL_LEVEL + IntToString(nClass), nBaseSpellLevel);         
    }
    else
    {
        SetLocalInt(oDataObject, CG_CLASS_BASE_SPELL_LEVEL + IntToString(nClass), -1); 
    }

    // Num Level 1 Bonus Feats
    string sBonusFeatTable = Get2DAString("classes", "BonusFeatsTable", nClass);
    int nNumBonusFeats = StringToInt(Get2DAString(sBonusFeatTable, "Bonus", 0));
    SetLocalInt(oDataObject, CG_CLASS_NUM_LEVEL_1_BONUS_FEATS + IntToString(nClass), nNumBonusFeats);                   
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

        CG_LoadClassBaseStatData(nRow);
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

void CG_LoadFeatList()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_globalfeatlist (id INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));    

    SqlBeginTransactionModule();

    int nFeat, nNumFeats = Get2DARowCount("feat");
    for (nFeat = 0; nFeat < nNumFeats; nFeat++)
    {
        if (StringToInt(Get2DAString("feat", "PreReqEpic", nFeat)))
            continue; // Don't care about epic feats for level 1 
        if (!StringToInt(Get2DAString("feat", "ALLCLASSESCANUSE", nFeat)))
            continue; // Don't care about feats that not all classes can use
        if (StringToInt(Get2DAString("feat", "MinLevel", nFeat)) > 1)
            continue; // Don't care about feats with a minlevel of >1
        if (Get2DAString("feat", "FEAT", nFeat) == "")
            continue; // Don't care about invalid feats either

        sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + CG_SCRIPT_NAME + "_globalfeatlist(id) VALUES(@id);");
        SqlBindInt(sql, "@id", nFeat);
        SqlStep(sql);          
    }

    SqlCommitTransactionModule();
}

void CG_LoadClassLevel1GrantedFeats(int nClass)
{    
    json jGrantedLevel1Feats = JsonArray();
    string sFeatsTable = Get2DAString("classes", "FeatsTable", nClass);
    int nRow, nNumRows = Get2DARowCount(sFeatsTable);
    for (nRow = 0; nRow < nNumRows; nRow++)
    {
        if (StringToInt(Get2DAString(sFeatsTable, "List", nRow)) == 3 &&
            StringToInt(Get2DAString(sFeatsTable, "GrantedOnLevel", nRow)) == 1)
        {
            int nFeat = StringToInt(Get2DAString(sFeatsTable, "FeatIndex", nRow));

            jGrantedLevel1Feats = JsonArrayInsertUniqueInt(jGrantedLevel1Feats, nFeat);

            sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + CG_SCRIPT_NAME + "_grantedfeats(class, id, name, icon) VALUES(@class, @id, @name, @icon)");
            SqlBindInt(sql, "@class", nClass);    
            SqlBindInt(sql, "@id", nFeat); 
            SqlBindString(sql, "@name", Get2DAStrRefString("feat", "FEAT", nFeat));
            SqlBindString(sql, "@icon", Get2DAString("feat", "ICON", nFeat));
            SqlStep(sql);
        }                
    }

    SetLocalJson(GetDataObject(CG_SCRIPT_NAME), CG_CLASS_FEATS_GRANTED_ON_LEVEL1 + IntToString(nClass), jGrantedLevel1Feats);    
}

void CG_LoadClassFeatTable(int nClass)
{   
    object oDataObject = GetDataObject(CG_SCRIPT_NAME);

    // Step 1: Copy feats from the global feat list into the class feat list
    SqlBeginTransactionModule();
    string sQuery = "INSERT INTO " + CG_SCRIPT_NAME + "_feats(class, id, list, name, icon) VALUES(@class, @id, @list, @name, @icon)";
    sqlquery sqlGlobalFeatList = SqlPrepareQueryModule("SELECT id FROM " + CG_SCRIPT_NAME + "_globalfeatlist;");
    while (SqlStep(sqlGlobalFeatList))
    {
        int nFeat = SqlGetInt(sqlGlobalFeatList, 0);

        // Filter based on min spell level
        int nMinSpellLevel = Get2DAInt("feat", "MINSPELLLVL", nFeat);
        if (nMinSpellLevel != EF_UNSET_INTEGER_VALUE && GetLocalInt(oDataObject, CG_CLASS_BASE_SPELL_LEVEL + IntToString(nClass)) < nMinSpellLevel)
            continue;
        // Filter based on min attack bonus
        int nMinAttackBonus = Get2DAInt("feat", "MINATTACKBONUS", nFeat);
        if (nMinAttackBonus != EF_UNSET_INTEGER_VALUE && GetLocalInt(oDataObject, CG_CLASS_BASE_ATTACK_BONUS + IntToString(nClass)) < nMinAttackBonus)
            continue;            
        
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindInt(sql, "@class", nClass);
        SqlBindInt(sql, "@id", nFeat);
        SqlBindInt(sql, "@list", 0);
        SqlBindString(sql, "@name", Get2DAStrRefString("feat", "FEAT", nFeat));
        SqlBindString(sql, "@icon", Get2DAString("feat", "ICON", nFeat));
        SqlStep(sql);
    }
    SqlCommitTransactionModule();

    // Step 2: Parse the class feat list to add missed feats and update the list type    
    SqlBeginTransactionModule();
    sQuery = "REPLACE INTO " + CG_SCRIPT_NAME + "_feats(class, id, list, name, icon) VALUES(@class, @id, @list, @name, @icon)";
    string sFeatsTable = Get2DAString("classes", "FeatsTable", nClass);    
    int nRow, nNumRows = Get2DARowCount(sFeatsTable);
    for (nRow = 0; nRow < nNumRows; nRow++)
    {        
        int nList = StringToInt(Get2DAString(sFeatsTable, "List", nRow));
        if (nList == 3) 
            continue;

        int nFeat = StringToInt(Get2DAString(sFeatsTable, "FeatIndex", nRow));

        if (StringToInt(Get2DAString("feat", "PreReqEpic", nFeat)))
            continue; // Still don't care about epic feats for level 1 
        if (StringToInt(Get2DAString("feat", "MinLevel", nFeat)) > 1)
            continue; // Still don't care about feats with a minlevel of >1
        
        // Filter based on min spell level, again
        int nMinSpellLevel = Get2DAInt("feat", "MINSPELLLVL", nFeat);
        if (nMinSpellLevel != EF_UNSET_INTEGER_VALUE && GetLocalInt(oDataObject, CG_CLASS_BASE_SPELL_LEVEL + IntToString(nClass)) < nMinSpellLevel)
            continue;
        // Filter based on min attack bonus, again
        int nMinAttackBonus = Get2DAInt("feat", "MINATTACKBONUS", nFeat);
        if (nMinAttackBonus != EF_UNSET_INTEGER_VALUE && GetLocalInt(oDataObject, CG_CLASS_BASE_ATTACK_BONUS + IntToString(nClass)) < nMinAttackBonus)
            continue;

        switch (nList)
        {
            case 0: nList = 0x1; break;
            case 1: nList = 0x1 | 0x2; break;
            case 2: nList = 0x2; break;
        }                 

        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindInt(sql, "@class", nClass);
        SqlBindInt(sql, "@id", nFeat);
        SqlBindInt(sql, "@list", nList);
        SqlBindString(sql, "@name", Get2DAStrRefString("feat", "FEAT", nFeat));
        SqlBindString(sql, "@icon", Get2DAString("feat", "ICON", nFeat));
        SqlStep(sql);
    }

    SqlCommitTransactionModule();
}

void CG_LoadFeatData()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_grantedfeats (" +
                    "class INTEGER NOT NULL, " +
                    "id INTEGER NOT NULL, " +
                    "name TEXT NOT NULL, " +
                    "icon TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));      
    
    sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_feats (" +
                    "class INTEGER NOT NULL, " +
                    "id INTEGER NOT NULL, " +
                    "list INTEGER NOT NULL, " +
                    "name TEXT NOT NULL, " +
                    "icon TEXT NOT NULL, " +
                    "PRIMARY KEY(class, id));";
    SqlStep(SqlPrepareQueryModule(sQuery));      
    
    // Step 1: Prepare the global feat list consisting of feats that all classes can use, have a min level <=1 and aren't epic feats
    CG_LoadFeatList();    

    sqlquery sqlClasses = SqlPrepareQueryModule("SELECT id FROM " + CG_SCRIPT_NAME + "_classes;");
    while (SqlStep(sqlClasses))
    {
        int nClass = SqlGetInt(sqlClasses, 0);
        
        // Step 2: Grab all granted on level 1 feats
        CG_LoadClassLevel1GrantedFeats(nClass);

        // Step 3: Prepare the class feat list
        CG_LoadClassFeatTable(nClass);
    }            
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
    CG_SetCurrentState(nState);

    switch (nState)
    {
        case CG_STATE_BASE:
        {
            CG_CloseChildWindows();
            NWM_SetBindBool(CG_BIND_BUTTON_ABILITY_WINDOW_ENABLED, FALSE);
            NWM_SetBindBool(CG_BIND_BUTTON_SKILLFEAT_WINDOW_ENABLED, FALSE);         
            
            CG_SetBaseAbilityScores();
            CG_ChangeState(CG_STATE_ABILITY);
            break;
        }

        case CG_STATE_ABILITY:
        {
            CG_CloseChildWindows(CG_ABILITY_WINDOW_ID);
            NWM_SetBindBool(CG_BIND_BUTTON_ABILITY_WINDOW_ENABLED, TRUE);
            NWM_SetBindBool(CG_BIND_BUTTON_SKILLFEAT_WINDOW_ENABLED, FALSE);            
            break;
        }

        case CG_STATE_PACKAGES:
        { 
            CG_SetBaseSkillValues();
            CG_SetBaseFeatValues(); 
            NWM_SetBindBool(CG_BIND_BUTTON_SKILLFEAT_WINDOW_ENABLED, TRUE);             
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

    if (sWindowIdToSkip != CG_FEAT_WINDOW_ID)
        NWM_CloseWindow(oPlayer, CG_FEAT_WINDOW_ID);              
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLOSE:NUI_WINDOW_ROOT_GROUP]
void QC_MainWindowClose()
{
    CG_CloseChildWindows();
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
                NB_StartElement(NuiButton(JsonString("Skills & Feats")));
                    NB_SetDimensions(250.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_SKILLFEAT_WINDOW);
                    NB_SetEnabled(NuiBind(CG_BIND_BUTTON_SKILLFEAT_WINDOW_ENABLED));
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

// @NWMWINDOW[CG_FEAT_WINDOW_ID]
json CG_CreateFeatWindow()
{
   NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 800.0f, 600.0f));
    NB_SetWindowTitle(JsonString("Character Creator: Feats"));
        NB_StartColumn();

            NB_StartRow();
            
                NB_StartColumn();
                    NB_StartRow();
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_SetDimensions(375.0f, 24.0f);
                            NB_AddElement(NuiLabel(JsonString("Available Feats"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();                    
                    NB_End();

                    NB_StartRow();
                        NB_StartElement(NuiTextEdit(JsonString("Search Feats..."), NuiBind(CG_BIND_VALUE_SEARCH_TEXT), 32, FALSE));
                            NB_SetHeight(32.0f);
                        NB_End();
                        NB_StartElement(NuiButton(JsonString("X")));
                            NB_SetId(CG_ID_BUTTON_CLEAR_SEARCH);
                            NB_SetEnabled(NuiBind(CG_BIND_BUTTON_CLEAR_SEARCH_ENABLED));
                            NB_SetDimensions(32.0f, 32.0f);
                        NB_End();
                    NB_End();

                    NB_StartRow();
                        NB_StartList(NuiBind(CG_BIND_LIST_AVAILABLE_FEATS_PREFIX + CG_BIND_LIST_ICONS), 24.0f);
                            NB_SetWidth(375.0f);
                            NB_StartListTemplateCell(24.0f, FALSE);
                                NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                                    NB_StartElement(NuiImage(NuiBind(CG_BIND_LIST_AVAILABLE_FEATS_PREFIX + CG_BIND_LIST_ICONS), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                    NB_End();
                                NB_End();
                            NB_End();
                            NB_StartListTemplateCell(0.0f, TRUE);
                                NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_AVAILABLE_FEATS_PREFIX + CG_BIND_LIST_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_End();
                            NB_End();
                            NB_StartListTemplateCell(24.0f, FALSE);
                                NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                                    NB_StartElement(NuiImage(JsonString("nui_shld_right"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetId(CG_ID_BUTTON_LIST_ADD_FEAT);
                                    NB_End();
                                NB_End();
                            NB_End();                             
                        NB_End();
                    NB_End();

                    NB_StartRow();
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_SetDimensions(375.0f, 32.0f);                    
                            NB_StartElement(NuiLabel(NuiBind(CG_BIND_TEXT_POINTS_REMAINING), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_SetDimensions(367.0f, 22.0f);
                            NB_End();
                        NB_End();
                    NB_End();                      

                NB_End();

                NB_StartColumn();
                    NB_AddSpacer();
                NB_End();                

                NB_StartColumn();
                    NB_StartRow();
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_SetDimensions(375.0f, 24.0f);
                            NB_AddElement(NuiLabel(JsonString("Granted Feats"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();

                    NB_StartRow();
                        NB_StartList(NuiBind(CG_BIND_LIST_GRANTED_FEATS_PREFIX + CG_BIND_LIST_ICONS), 24.0f);
                            NB_SetDimensions(375.0f, 280.0f);
                            NB_StartListTemplateCell(24.0f, FALSE);
                                NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                                    NB_StartElement(NuiImage(NuiBind(CG_BIND_LIST_GRANTED_FEATS_PREFIX + CG_BIND_LIST_ICONS), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                    NB_End();
                                NB_End();
                            NB_End();
                            NB_StartListTemplateCell(0.0f, TRUE);
                                NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_GRANTED_FEATS_PREFIX + CG_BIND_LIST_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_End();
                            NB_End();                             
                        NB_End();
                    NB_End();

                    NB_StartRow();
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_SetDimensions(375.0f, 24.0f);
                            NB_AddElement(NuiLabel(JsonString("Chosen Feats"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();                    

                    NB_StartRow();
                        NB_StartList(NuiBind(CG_BIND_LIST_CHOSEN_FEATS_PREFIX + CG_BIND_LIST_ICONS), 24.0f);
                            NB_SetWidth(375.0f);
                            NB_StartListTemplateCell(24.0f, FALSE);
                                NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                                    NB_StartElement(NuiImage(NuiBind(CG_BIND_LIST_CHOSEN_FEATS_PREFIX + CG_BIND_LIST_ICONS), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                    NB_End();
                                NB_End();
                            NB_End();
                            NB_StartListTemplateCell(0.0f, TRUE);
                                NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_CHOSEN_FEATS_PREFIX + CG_BIND_LIST_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_End();
                            NB_End();
                            NB_StartListTemplateCell(24.0f, FALSE);
                                NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                                    NB_StartElement(NuiImage(JsonString("nui_shld_left"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                        NB_SetId(CG_ID_BUTTON_LIST_REMOVE_FEAT);
                                    NB_End();
                                NB_End();
                            NB_End();                             
                        NB_End();
                    NB_End();                                          

                NB_End();            
            
            NB_End();

            NB_StartRow();                   
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("OK")));
                    NB_SetDimensions(200.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_OK);
                    NB_SetEnabled(NuiBind(CG_ID_BUTTON_OK_ENABLED));
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
    if (bFirstName)
        return RandomName(2 + ((nRace == 3 ? 4 : nRace == 4 ? 3 : nRace) * 3) + (nGender > 0));
    else
        return RandomName(2 + (nRace * 3) + 2);
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

int CG_GetAdjustedAbilityScore(int nRace, int nClass, int nAbility)
{
    return JsonArrayGetInt(NWM_GetUserData(CG_USERDATA_BASE_ABILITY_SCORES), nAbility) + CG_GetRacialAbilityAdjust(nRace, nAbility) + CG_GetClassAbilityAdjust(nClass, nAbility);
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
    json jAbilityValues = JsonArray();
    int nAbility;
    for (nAbility = 0; nAbility < 6; nAbility++)
    {
        int nAbilityValue = CG_GetAdjustedAbilityScore(nRace, nClass, nAbility);        
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
        CG_ChangeState(CG_STATE_PACKAGES); 
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
    int nAbilityBonus = CG_CalculateAbilityModifier(CG_GetAdjustedAbilityScore(nRace, nClass, nSkillPointModifierAbility));
    int nSkillPointsRemaining = (nFirstLevelSkillPointsMultiplier * (max(1, nClassSkillPointBase + nAbilityBonus))) + 
                                (nFirstLevelSkillPointsMultiplier * nExtraSkillPointsPerLevel);

    CG_SetSkillPointsRemaining(nSkillPointsRemaining);
    NWM_SetUserData(CG_USERDATA_SKILLRANKS, GetJsonArrayOfSize(Get2DARowCount("skills"), JsonInt(0)));                                 
}

int CG_GetClassHasSkill(int nSkill)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT id FROM "+ CG_SCRIPT_NAME + "_class_skills WHERE class = @class AND id = @id;");
    SqlBindInt(sql, "@class", NWM_GetUserDataInt(CG_USERDATA_CLASS));
    SqlBindInt(sql, "@id", nSkill);
    return SqlStep(sql);   
}

int CG_GetIsClassSkill(int nSkill)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT class_skill FROM "+ CG_SCRIPT_NAME + "_class_skills WHERE class = @class AND id = @id;");
    SqlBindInt(sql, "@class", NWM_GetUserDataInt(CG_USERDATA_CLASS));
    SqlBindInt(sql, "@id", nSkill);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : FALSE;
}

void CG_SetSkillData(json jSkillRanks)
{
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

        if (bAllClassesCanUse || CG_GetClassHasSkill(nSkill))
        {
            jSkillArray = JsonArrayInsertInt(jSkillArray, nSkill);
            jIconsArray = JsonArrayInsertString(jIconsArray, sIcon);
            jNamesArray = JsonArrayInsertString(jNamesArray, sName + (CG_GetIsClassSkill(nSkill) ? " (Class Skill)" : ""));
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
    int nSkill = JsonArrayGetInt(NWM_GetUserData(CG_USERDATA_CLASS_AVAILABLE_SKILLS), nSkillIndex);
    int nCurrentRank = JsonArrayGetInt(jSkillValues, nSkillIndex);
    int nMaxRank = 1 + RS2DA_GetIntEntry("CHARGEN_SKILL_MAX_LEVEL_1_BONUS");
    int nCost = 1;

    if (!CG_GetIsClassSkill(nSkill))
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

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_SKILLFEAT_WINDOW]
void CG_ClickSkillsFeatsButton()
{
    object oPlayer = OBJECT_SELF;
    
    if (NWM_GetIsWindowOpen(oPlayer, CG_SKILL_WINDOW_ID) || NWM_GetIsWindowOpen(oPlayer, CG_FEAT_WINDOW_ID))
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
    json jSkillRanks = CG_GetMergedSkillRanks();

    if (NWM_GetIsWindowOpen(oPlayer, CG_MAIN_WINDOW_ID, TRUE))
    {
        NWM_CopyUserData(CG_SKILL_WINDOW_ID, CG_USERDATA_SKILLPOINTS_REMAINING);
        NWM_SetUserData(CG_USERDATA_SKILLRANKS, jSkillRanks);   
        NWM_CloseWindow(oPlayer, CG_SKILL_WINDOW_ID);

        CG_OpenFeatsWindow();        
    }  
}

// *** FEATS

json CG_GetLevel1GrantedFeats(int nClass)
{
    return GetLocalJson(GetDataObject(CG_SCRIPT_NAME), CG_CLASS_FEATS_GRANTED_ON_LEVEL1 + IntToString(nClass));
}

int CG_GetHasFeat(int nClass, int nFeat)
{
    return JsonArrayContainsInt(CG_GetLevel1GrantedFeats(nClass), nFeat) || JsonArrayContainsInt(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS), nFeat);
}

int CG_MeetsFeatRequirements(int nRace, int nClass, int nFeat)
{ 
    int nMinAttackBonus = Get2DAInt("feat", "MINATTACKBONUS", nFeat);
    if (nMinAttackBonus != EF_UNSET_INTEGER_VALUE && GetLocalInt(GetDataObject(CG_SCRIPT_NAME), CG_CLASS_BASE_ATTACK_BONUS + IntToString(nClass)) < nMinAttackBonus)
        return FALSE;

    int nMinStr = Get2DAInt("feat", "MINSTR", nFeat);
    if (nMinStr != EF_UNSET_INTEGER_VALUE && CG_GetAdjustedAbilityScore(nRace, nClass, ABILITY_STRENGTH) < nMinStr)
        return FALSE;

    int nMinDex = Get2DAInt("feat", "MINDEX", nFeat);
    if (nMinDex != EF_UNSET_INTEGER_VALUE && CG_GetAdjustedAbilityScore(nRace, nClass, ABILITY_DEXTERITY) < nMinDex)
        return FALSE;

    int nMinInt = Get2DAInt("feat", "MININT", nFeat);
    if (nMinInt != EF_UNSET_INTEGER_VALUE && CG_GetAdjustedAbilityScore(nRace, nClass, ABILITY_INTELLIGENCE) < nMinInt)
        return FALSE; 

    int nMinWis = Get2DAInt("feat", "MINWIS", nFeat);
    if (nMinWis != EF_UNSET_INTEGER_VALUE && CG_GetAdjustedAbilityScore(nRace, nClass, ABILITY_WISDOM) < nMinWis)
        return FALSE;

    int nMinCon = Get2DAInt("feat", "MINCON", nFeat);
    if (nMinCon != EF_UNSET_INTEGER_VALUE && CG_GetAdjustedAbilityScore(nRace, nClass, ABILITY_CONSTITUTION) < nMinCon)
        return FALSE;

    int nMinCha = Get2DAInt("feat", "MINCHA", nFeat);
    if (nMinCha != EF_UNSET_INTEGER_VALUE && CG_GetAdjustedAbilityScore(nRace, nClass, ABILITY_CHARISMA) < nMinCha)
        return FALSE;

    int nMinSpellLevel = Get2DAInt("feat", "MINSPELLLVL", nFeat);
    if (nMinSpellLevel != EF_UNSET_INTEGER_VALUE && GetLocalInt(GetDataObject(CG_SCRIPT_NAME), CG_CLASS_BASE_SPELL_LEVEL + IntToString(nClass)) < nMinSpellLevel)
        return FALSE;

    int nPreReqFeat1 = Get2DAInt("feat", "PREREQFEAT1", nFeat);
    if (nPreReqFeat1 != EF_UNSET_INTEGER_VALUE && !CG_GetHasFeat(nClass, nPreReqFeat1))
        return FALSE;

    int nPreReqFeat2 = Get2DAInt("feat", "PREREQFEAT2", nFeat);
    if (nPreReqFeat2 != EF_UNSET_INTEGER_VALUE && !CG_GetHasFeat(nClass, nPreReqFeat2))
        return FALSE;

    int nFeatIndex, bHasOrPrereqFeat, bOrPrereqFeatAcquired;
    for (nFeatIndex = 0; !bOrPrereqFeatAcquired && nFeatIndex < 5; nFeatIndex++)
    {
        int nOrPreReqFeat = Get2DAInt("feat", "OrReqFeat" + IntToString(nFeatIndex), nFeat);
        if (nOrPreReqFeat != EF_UNSET_INTEGER_VALUE)
        {
            bHasOrPrereqFeat = TRUE;

            if (CG_GetHasFeat(nClass, nOrPreReqFeat))
                bOrPrereqFeatAcquired = TRUE;            
        }
    }
    if (bHasOrPrereqFeat && !bOrPrereqFeatAcquired)
        return FALSE;

    int nReqSkill1 = Get2DAInt("feat", "REQSKILL", nFeat);
    if (nReqSkill1 != EF_UNSET_INTEGER_VALUE)
    {
        if (!CG_GetClassHasSkill(nReqSkill1))
            return FALSE;

        int nReqMinSkillRanks = Get2DAInt("feat", "ReqSkillMinRanks", nFeat);
        if (nReqMinSkillRanks != EF_UNSET_INTEGER_VALUE && JsonArrayGetInt(NWM_GetUserData(CG_USERDATA_SKILLRANKS), nReqSkill1) < nReqMinSkillRanks)
            return FALSE;                    
    }

    int nReqSkill2 = Get2DAInt("feat", "REQSKILL2", nFeat);
    if (nReqSkill2 != EF_UNSET_INTEGER_VALUE)
    {
        if (!CG_GetClassHasSkill(nReqSkill2))
            return FALSE;

        int nReqMinSkillRanks = Get2DAInt("feat", "ReqSkillMinRanks2", nFeat);
        if (nReqMinSkillRanks != EF_UNSET_INTEGER_VALUE && JsonArrayGetInt(NWM_GetUserData(CG_USERDATA_SKILLRANKS), nReqSkill2) < nReqMinSkillRanks)
            return FALSE;                    
    }

    int nMinLevel = Get2DAInt("feat", "MinLevel", nFeat);
    if (nMinLevel != EF_UNSET_INTEGER_VALUE)
    {
        if (1 < nMinLevel)
            return FALSE;

        int nMinLevelClass = Get2DAInt("feat", "MinLevelClass", nFeat); 
        if (nMinLevelClass != EF_UNSET_INTEGER_VALUE && nClass != nMinLevelClass)
            return FALSE;           
    }

    int nMinFortSave = Get2DAInt("feat", "MinFortSave", nFeat);                                                                                             
    if (nMinFortSave != EF_UNSET_INTEGER_VALUE && GetLocalInt(GetDataObject(CG_SCRIPT_NAME), CG_CLASS_BASE_FORTITUDE_SAVING_THROW + IntToString(nClass)) < nMinFortSave)
        return FALSE;

    return TRUE;    
}

void CG_SetBaseFeatValues()
{
    int nRace = NWM_GetUserDataInt(CG_USERDATA_RACE);
    int nNumberNormalFeatsEveryNthLevel = StringToInt(Get2DAString("racialtypes", "NumberNormalFeatsEveryNthLevel", nRace));
    int nExtraFeatsAtFirstLevel = StringToInt(Get2DAString("racialtypes", "ExtraFeatsAtFirstLevel", nRace));
    NWM_SetUserDataInt(CG_USERDATA_NUM_NORMAL_FEATS, nNumberNormalFeatsEveryNthLevel + nExtraFeatsAtFirstLevel);
    
    int nNumBonusFeats = GetLocalInt(GetDataObject(CG_SCRIPT_NAME), CG_CLASS_NUM_LEVEL_1_BONUS_FEATS + IntToString(NWM_GetUserDataInt(CG_USERDATA_CLASS))); 
    NWM_SetUserDataInt(CG_USERDATA_NUM_BONUS_FEATS, nNumBonusFeats);

    NWM_SetUserData(CG_USERDATA_CHOSEN_FEATS, JsonArray());
    NWM_SetUserData(CG_USERDATA_CHOSEN_FEATS_LIST_TYPE, JsonArray());
}

int CG_GetTotalNumChooseableFeats()
{
    return NWM_GetUserDataInt(CG_USERDATA_NUM_NORMAL_FEATS) + NWM_GetUserDataInt(CG_USERDATA_NUM_BONUS_FEATS);
}

void CG_UpdateGrantedFeatsList()
{
    json jNamesArray = JsonArray();
    json jIconsArray = JsonArray();
    sqlquery sql = SqlPrepareQueryModule("SELECT name, icon FROM " + CG_SCRIPT_NAME + "_grantedfeats WHERE class = @class ORDER BY name ASC;");
    SqlBindInt(sql, "@class", NWM_GetUserDataInt(CG_USERDATA_CLASS));

    while (SqlStep(sql))
    {
        jNamesArray = JsonArrayInsertString(jNamesArray, SqlGetString(sql, 0));
        jIconsArray = JsonArrayInsertString(jIconsArray, SqlGetString(sql, 1));
    }

    NWM_SetBind(CG_BIND_LIST_GRANTED_FEATS_PREFIX + CG_BIND_LIST_ICONS, jIconsArray);
    NWM_SetBind(CG_BIND_LIST_GRANTED_FEATS_PREFIX + CG_BIND_LIST_NAMES, jNamesArray);    
}

int CG_GetFeatListType(int nFeat)
{
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);
    sqlquery sql = SqlPrepareQueryModule("SELECT list FROM " + CG_SCRIPT_NAME + "_feats WHERE class = @class AND id = @id;");
    SqlBindInt(sql, "@class", nClass);
    SqlBindInt(sql, "@id", nFeat);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

int CG_IsNormalFeat(int nFeat, int nList)
{
    return (nList & 0x1) || StringToInt(Get2DAString("feat", "ALLCLASSESCANUSE", nFeat));    
}

int CG_IsBonusFeat(int nFeat, int nList)
{
    return (nList & 0x2);    
}

int CG_CanChooseFeat(int nRace, int nClass, int nFeat, int nList, int nNumNormalFeats, int nNumBonusFeats, json jChosenFeats, json jChosenFeatsListType)
{
    if (!nNumNormalFeats && !nNumBonusFeats)
        return FALSE;

    if (CG_GetHasFeat(nClass, nFeat))
        return FALSE;
    
    if (JsonArrayContainsInt(jChosenFeats, nFeat))
        return FALSE;

    if (!CG_MeetsFeatRequirements(nRace, nClass, nFeat))
        return FALSE;        

    int bNormalListFeat = CG_IsNormalFeat(nFeat, nList);
    int bBonusListFeat = CG_IsBonusFeat(nFeat, nList);

    if (!bNormalListFeat && !bBonusListFeat)
        return FALSE;

    int nNormalFeats = nNumNormalFeats; 
    int nBonusFeats = nNumBonusFeats;
    int nChosenFeatIndex, nNumChosenFeats = JsonGetLength(jChosenFeats);
    json jAllocatedFeats = GetJsonArrayOfSize(nNumChosenFeats, JsonInt(FALSE));

    for (nChosenFeatIndex = 0; nChosenFeatIndex < nNumChosenFeats; nChosenFeatIndex++)
    {
        int nChosenFeat = JsonArrayGetInt(jChosenFeats, nChosenFeatIndex);
        int nChosenFeatListType = JsonArrayGetInt(jChosenFeatsListType, nChosenFeatIndex);
        int bIsNormalFeat = CG_IsNormalFeat(nChosenFeat, nChosenFeatListType);
        int bIsBonusFeat = CG_IsBonusFeat(nChosenFeat, nChosenFeatListType);

        if (bIsNormalFeat && !bIsBonusFeat)
        {
            if (!nNormalFeats)
                return FALSE;

            jAllocatedFeats = JsonArraySetInt(jAllocatedFeats, nChosenFeatIndex, TRUE);
            nNormalFeats--;                
        }

        if (!bIsNormalFeat && bIsBonusFeat)
        {
            if (!nBonusFeats)
                return FALSE;

            jAllocatedFeats = JsonArraySetInt(jAllocatedFeats, nChosenFeatIndex, TRUE);
            nBonusFeats--;                  
        }
    }

    int bNewFeatAllocated = FALSE;
    if (bNormalListFeat && !bBonusListFeat)
    {
        if (nNormalFeats)
        {
            nNormalFeats--;
            bNewFeatAllocated = TRUE;
        }
        else 
            return FALSE;
    }

    if (!bNormalListFeat && bBonusListFeat)
    {
        if (nBonusFeats)
        {
            nBonusFeats--;
            bNewFeatAllocated = TRUE;
        }
        else 
            return FALSE;
    }

    for (nChosenFeatIndex = 0; nChosenFeatIndex < nNumChosenFeats; nChosenFeatIndex++)
    {
        if (!JsonArrayGetInt(jAllocatedFeats, nChosenFeatIndex))
        {
            if (nNormalFeats)
                nNormalFeats--;
            else 
            {
                if (nBonusFeats)
                    nBonusFeats--;
                else
                    return FALSE;
            }
        }
    }

    if (!bNewFeatAllocated)
    {
        if (nNormalFeats)
            nNormalFeats--;
        else 
        {
            if (nBonusFeats)
                nBonusFeats--;
            else
                return FALSE;
        }       
    }

    return TRUE;
}

void CG_UpdateAvailableFeatsList()
{
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);
    int nRace = NWM_GetUserDataInt(CG_USERDATA_RACE);
    int nNumNormalFeats = NWM_GetUserDataInt(CG_USERDATA_NUM_NORMAL_FEATS);
    int nNumBonusFeats = NWM_GetUserDataInt(CG_USERDATA_NUM_BONUS_FEATS);   
    json jChosenFeats = NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS);
    json jChosenFeatsListType = NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS_LIST_TYPE);
    string sSearch = NWM_GetBindString(CG_BIND_VALUE_SEARCH_TEXT);    
    string sFeatArray;  
    string sNamesArray;
    string sIconsArray;     
    sqlquery sql = SqlPrepareQueryModule("SELECT id, list, name, icon FROM " + CG_SCRIPT_NAME + "_feats WHERE class = @class AND name LIKE @like ORDER BY name ASC;");
    SqlBindInt(sql, "@class", nClass);
    SqlBindString(sql, "@like", "%" + sSearch + "%");
    while (SqlStep(sql))
    {
        int nFeat = SqlGetInt(sql, 0);
        int nList = SqlGetInt(sql, 1);

        if (!CG_CanChooseFeat(nRace, nClass, nFeat, nList, nNumNormalFeats, nNumBonusFeats, jChosenFeats, jChosenFeatsListType))
            continue;

        sFeatArray += StringJsonArrayElementInt(nFeat);
        sNamesArray += StringJsonArrayElementString(SqlGetString(sql, 2));
        sIconsArray += StringJsonArrayElementString(SqlGetString(sql, 3));
    }

    NWM_SetUserData(CG_USERDATA_AVAILABLE_FEAT_LIST, StringJsonArrayElementsToJsonArray(sFeatArray));
    NWM_SetBind(CG_BIND_LIST_AVAILABLE_FEATS_PREFIX + CG_BIND_LIST_ICONS, StringJsonArrayElementsToJsonArray(sIconsArray));
    NWM_SetBind(CG_BIND_LIST_AVAILABLE_FEATS_PREFIX + CG_BIND_LIST_NAMES, StringJsonArrayElementsToJsonArray(sNamesArray));       
}

void CG_UpdateChosenFeatsList()
{
    json jNamesArray = JsonArray();
    json jIconsArray = JsonArray();    
    json jChosenFeats = NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS);
    int nFeatIndex, nNumFeats = JsonGetLength(jChosenFeats);
    for (nFeatIndex = 0; nFeatIndex < nNumFeats; nFeatIndex++)
    {
        int nFeat = JsonArrayGetInt(jChosenFeats, nFeatIndex);
        jNamesArray = JsonArrayInsertString(jNamesArray, Get2DAStrRefString("feat", "FEAT", nFeat));
        jIconsArray = JsonArrayInsertString(jIconsArray, Get2DAString("feat", "ICON", nFeat));        
    } 

    NWM_SetBind(CG_BIND_LIST_CHOSEN_FEATS_PREFIX + CG_BIND_LIST_ICONS, jIconsArray);
    NWM_SetBind(CG_BIND_LIST_CHOSEN_FEATS_PREFIX + CG_BIND_LIST_NAMES, jNamesArray);   
}

void CG_UpdatingRemainingFeatsText()
{
    int nNumChosenFeats = JsonGetLength(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS));
    int nNumChooseableFeats = CG_GetTotalNumChooseableFeats();
    NWM_SetBindString(CG_BIND_TEXT_POINTS_REMAINING, "Remaining Feats: " + IntToString(nNumChooseableFeats - nNumChosenFeats));
}

void CG_CheckFeatOkButtonStatus()
{
    if (JsonGetLength(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS)) == CG_GetTotalNumChooseableFeats())
        NWM_SetBindBool(CG_ID_BUTTON_OK_ENABLED, TRUE);
    else
        NWM_SetBindBool(CG_ID_BUTTON_OK_ENABLED, FALSE);
}

void CG_VerifyChosenFeats()
{
    int nRace = NWM_GetUserDataInt(CG_USERDATA_RACE);
    int nClass = NWM_GetUserDataInt(CG_USERDATA_CLASS);    
    int nChosenFeatIndex = 0;

    while (nChosenFeatIndex < JsonGetLength(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS)))
    {
        int nFeat = JsonArrayGetInt(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS), nChosenFeatIndex);

        if (!CG_MeetsFeatRequirements(nRace, nClass, nFeat))
        {
            NWM_SetUserData(CG_USERDATA_CHOSEN_FEATS, JsonArrayDel(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS), nChosenFeatIndex));
            NWM_SetUserData(CG_USERDATA_CHOSEN_FEATS_LIST_TYPE, JsonArrayDel(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS_LIST_TYPE), nChosenFeatIndex));
            nChosenFeatIndex = 0;            
        }
        else
            nChosenFeatIndex++;   
    }  
}

void CG_OpenFeatsWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_OpenWindow(oPlayer, CG_FEAT_WINDOW_ID))
    {
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_RACE);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_CLASS);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_BASE_ABILITY_SCORES);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_SKILLRANKS);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_NUM_NORMAL_FEATS);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_NUM_BONUS_FEATS);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_CHOSEN_FEATS);
        NWM_CopyUserData(CG_MAIN_WINDOW_ID, CG_USERDATA_CHOSEN_FEATS_LIST_TYPE);

        CG_VerifyChosenFeats();
        
        CG_UpdateGrantedFeatsList();        
        CG_UpdateAvailableFeatsList();
        CG_UpdateChosenFeatsList();
        CG_UpdatingRemainingFeatsText();
        CG_CheckFeatOkButtonStatus();

        NWM_SetBindWatch(CG_BIND_VALUE_SEARCH_TEXT, TRUE);                      
    }    
}

void CG_AddChosenFeat(int nAvailableFeatIndex)
{
    if (nAvailableFeatIndex == -1)
        return;

    int nFeat = JsonArrayGetInt(NWM_GetUserData(CG_USERDATA_AVAILABLE_FEAT_LIST), nAvailableFeatIndex);
    int nList = CG_GetFeatListType(nFeat);

    NWM_SetUserData(CG_USERDATA_CHOSEN_FEATS, JsonArrayInsertInt(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS), nFeat));
    NWM_SetUserData(CG_USERDATA_CHOSEN_FEATS_LIST_TYPE, JsonArrayInsertInt(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS_LIST_TYPE), nList));

    CG_UpdateAvailableFeatsList();
    CG_UpdateChosenFeatsList();
    CG_UpdatingRemainingFeatsText();
    CG_CheckFeatOkButtonStatus(); 
}

void CG_RemoveChosenFeat(int nChosenFeatIndex)
{
    if (nChosenFeatIndex == -1)
        return;

    NWM_SetUserData(CG_USERDATA_CHOSEN_FEATS, JsonArrayDel(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS), nChosenFeatIndex));
    NWM_SetUserData(CG_USERDATA_CHOSEN_FEATS_LIST_TYPE, JsonArrayDel(NWM_GetUserData(CG_USERDATA_CHOSEN_FEATS_LIST_TYPE), nChosenFeatIndex));
    
    CG_VerifyChosenFeats();
    
    CG_UpdateAvailableFeatsList();
    CG_UpdateChosenFeatsList();
    CG_UpdatingRemainingFeatsText();
    CG_CheckFeatOkButtonStatus(); 
}

// @NWMEVENT[CG_FEAT_WINDOW_ID:NUI_EVENT_MOUSEUP:CG_ID_BUTTON_LIST_ADD_FEAT]
void CG_FeatAddMouseUp()
{
    if (NuiGetMouseButton(NuiGetEventPayload()) == NUI_MOUSE_BUTTON_LEFT)
        CG_AddChosenFeat(NuiGetEventArrayIndex());
}

// @NWMEVENT[CG_FEAT_WINDOW_ID:NUI_EVENT_MOUSEUP:CG_ID_BUTTON_LIST_REMOVE_FEAT]
void CG_FeatRemoveMouseUp()
{
    if (NuiGetMouseButton(NuiGetEventPayload()) == NUI_MOUSE_BUTTON_LEFT)
        CG_RemoveChosenFeat(NuiGetEventArrayIndex());
}

// @NWMEVENT[CG_FEAT_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_OK]
void CG_ClickFeatOkButton()
{
    object oPlayer = OBJECT_SELF;

    if (NWM_GetIsWindowOpen(oPlayer, CG_MAIN_WINDOW_ID, TRUE))
    {
        NWM_CopyUserData(CG_FEAT_WINDOW_ID, CG_USERDATA_CHOSEN_FEATS);
        NWM_CopyUserData(CG_FEAT_WINDOW_ID, CG_USERDATA_CHOSEN_FEATS_LIST_TYPE);
        NWM_CloseWindow(oPlayer, CG_FEAT_WINDOW_ID);     
    }  
}

// @NWMEVENT[CG_FEAT_WINDOW_ID:NUI_EVENT_WATCH:CG_BIND_VALUE_SEARCH_TEXT]
void CG_WatchFeatSearch()
{
    NWM_SetBindBool(CG_BIND_BUTTON_CLEAR_SEARCH_ENABLED, GetStringLength(NWM_GetBindString(CG_BIND_VALUE_SEARCH_TEXT)));
    CG_UpdateAvailableFeatsList();
}

// @NWMEVENT[CG_FEAT_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_CLEAR_SEARCH]
void CG_ClickClearFeatSearchButton()
{
    NWM_SetBindString(CG_BIND_VALUE_SEARCH_TEXT, "");
}
