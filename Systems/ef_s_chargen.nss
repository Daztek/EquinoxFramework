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

const string CG_RULESET_ABILITY_COST_INCREMENT_2    = "RulesetAbilityCostIncrement2";
const string CG_RULESET_ABILITY_COST_INCREMENT_3    = "RulesetAbilityCostIncrement3";
const string CG_RULESET_ABILITY_COST_INCREMENT_4    = "RulesetAbilityCostIncrement4";
const string CG_RULESET_BASE_ABILITY_MIN            = "RulesetBaseAbilityMin";
const string CG_RULESET_BASE_ABILITY_MIN_PRIMARY    = "RulesetBaseAbilityMinPrimary";
const string CG_RULESET_BASE_ABILITY_MAX            = "RulesetBaseAbilityMax";
const string CG_RULESET_ABILITY_NEUTRAL_VALUE       = "RulesetAbilityNeutralValue";
const string CG_RULESET_ABILITY_MODIFIER_INCREMENT  = "RulesetAbilityModifierIncrement";
const string CG_RULESET_SKILL_MAX_LEVEL_1_BONUS     = "RulesetSkillMaxLevel1Bonus";

const string CG_MAIN_WINDOW_ID                      = "CG_MAIN";
const string CG_ABILITY_WINDOW_ID                   = "CG_ABILITY";

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
const string CG_ID_BUTTON_SKILL_WINDOW              = "btn_skill_window";
const string CG_ID_BUTTON_FEAT_WINDOW               = "btn_feat_window";
const string CG_ID_BUTTON_LIST_ABILITY              = "btn_list_ability";
const string CG_ID_BUTTON_ABILITY_OK                = "btn_ability_ok";

const string CG_BUTTON_ABILITY_OK_ENABLED           = "btn_ability_ok_enabled";

const string CG_BIND_LIST_ABILITY_NAMES             = "list_ability_names";
const string CG_BIND_LIST_ABILITY_VALUES            = "list_ability_values";

const string CG_BIND_TEXT_POINT_BUY_NUMBER          = "text_point_buy_number";

const string CG_USERDATA_ABILITY_POINT_BUY_NUMBER   = "AbilityPointBuyNumber";
const string CG_USERDATA_BASE_ABILITY_SCORES        = "BaseAbilityScores";

void CG_LoadRaceData();
void CG_LoadClassData();
void CG_LoadRulesetData();
int CG_GetRulesetData(string sEntry);

void CG_LoadRaceComboBox();
void CG_LoadClassComboBox();
void CG_UpdateAlignmentComboBox();

void CG_SetAbilityPointBuyNumber(int nPoints);
int CG_GetAbilityPointBuyNumber();
void CG_ModifyAbilityPointBuyNumber(int nModify);
int CG_GetRacialAbilityAdjust(int nRace, int nAbility);
void CG_SetBaseAbilityScores();

// @CORE[EF_SYSTEM_INIT]
void CG_Init()
{
    CG_LoadRaceData();
    CG_LoadClassData();
}

// @CORE[EF_SYSTEM_LOAD]
void CG_Load()
{
    CG_LoadRulesetData();
}

// *** DATA FUNCTIONS

void CG_LoadRaceData()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + CG_SCRIPT_NAME + "_races (" +
                    "id INTEGER NOT NULL, " +
                    "name TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();
    
    sQuery = "INSERT INTO " + CG_SCRIPT_NAME + "_races(id, name) VALUES(@id, @name);";
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
    
    sQuery = "INSERT INTO " + CG_SCRIPT_NAME + "_classes(id, name) VALUES(@id, @name);";
    int nRow, nNumRows = Get2DARowCount("racialtypes");
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

void CG_LoadRulesetData()
{
    object oDataObject = GetDataObject(CG_SCRIPT_NAME);

    SetLocalInt(oDataObject, CG_RULESET_ABILITY_COST_INCREMENT_2, RS2DA_GetIntEntry("CHARGEN_ABILITY_COST_INCREMENT2"));
    SetLocalInt(oDataObject, CG_RULESET_ABILITY_COST_INCREMENT_3, RS2DA_GetIntEntry("CHARGEN_ABILITY_COST_INCREMENT3"));   
    SetLocalInt(oDataObject, CG_RULESET_ABILITY_COST_INCREMENT_4, RS2DA_GetIntEntry("CHARGEN_ABILITY_COST_INCREMENT4"));
    SetLocalInt(oDataObject, CG_RULESET_BASE_ABILITY_MIN, RS2DA_GetIntEntry("CHARGEN_BASE_ABILITY_MIN"));
    SetLocalInt(oDataObject, CG_RULESET_BASE_ABILITY_MIN_PRIMARY, RS2DA_GetIntEntry("CHARGEN_BASE_ABILITY_MIN_PRIMARY"));
    SetLocalInt(oDataObject, CG_RULESET_BASE_ABILITY_MAX, RS2DA_GetIntEntry("CHARGEN_BASE_ABILITY_MAX"));
    SetLocalInt(oDataObject, CG_RULESET_ABILITY_NEUTRAL_VALUE, RS2DA_GetIntEntry("CHARGEN_ABILITY_NEUTRAL_VALUE")); 
    SetLocalInt(oDataObject, CG_RULESET_ABILITY_MODIFIER_INCREMENT, RS2DA_GetIntEntry("CHARGEN_ABILITY_MODIFIER_INCREMENT"));
    SetLocalInt(oDataObject, CG_RULESET_SKILL_MAX_LEVEL_1_BONUS, RS2DA_GetIntEntry("CHARGEN_SKILL_MAX_LEVEL_1_BONUS"));                       
}

int CG_GetRulesetData(string sEntry)
{
    return GetLocalInt(GetDataObject(CG_SCRIPT_NAME), sEntry);
}

// *** WINDOWS

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
                    NB_SetDimensions(348.0f, 32.0f);
                    NB_AddStaticOptionsEntry("Male");
                    NB_AddStaticOptionsEntry("Female");
                NB_End();
            NB_End();            

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Race:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiCombo(NuiBind(CG_BIND_COMBO_ENTRIES_RACE), NuiBind(CG_BIND_VALUE_RACE)));
                    NB_SetDimensions(348.0f, 32.0f);
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
                    NB_SetDimensions(348.0f, 32.0f);
                NB_End();
            NB_End();

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Alignment:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiCombo(NuiBind(CG_BIND_COMBO_ENTRIES_ALIGNMENT), NuiBind(CG_BIND_VALUE_ALIGNMENT)));
                    NB_SetDimensions(348.0f, 32.0f);
                NB_End();
            NB_End();

            NB_StartRow();                
                NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                    NB_SetHeight(24.0f);
                    NB_AddElement(NuiLabel(JsonString("Packages"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                NB_End();
            NB_End();            

            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("Abilities")));
                    NB_SetDimensions(150.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_ABILITY_WINDOW);
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("Skills")));
                    NB_SetDimensions(150.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_SKILL_WINDOW);
                NB_End();
                NB_AddSpacer(); 
                NB_StartElement(NuiButton(JsonString("Feats")));
                    NB_SetDimensions(150.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_FEAT_WINDOW);
                NB_End();                              
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
                NB_StartList(NuiBind(CG_BIND_LIST_ABILITY_NAMES), 28.0f, TRUE, NUI_SCROLLBARS_NONE);
                    NB_SetHeight(200.0f);
                    
                    NB_StartListTemplateCell(2.0f, FALSE);
                        NB_AddSpacer();
                    NB_End();                        
                    
                    NB_StartListTemplateCell(100.0f, FALSE);
                        NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_ABILITY_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();

                    NB_StartListTemplateCell(30.0f, TRUE);
                        NB_AddSpacer();
                    NB_End();                     

                    NB_StartListTemplateCell(50.0f, FALSE);
                        NB_StartElement(NuiLabel(NuiBind(CG_BIND_LIST_ABILITY_VALUES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();                  

                    NB_StartListTemplateCell(14.0f, FALSE);
                        NB_StartElement(NuiSpacer());
                            NB_SetId(CG_ID_BUTTON_LIST_ABILITY);
                            NB_StartDrawList(JsonBool(FALSE));                                
                                NB_AddDrawListItem(
                                    NuiDrawListImage(
                                        JsonBool(TRUE),
                                        JsonString("nui_cnt_up"),
                                        NuiRect(0.0f, 0.0f, 14.0f, 14.0f),
                                        JsonInt(NUI_ASPECT_EXACTSCALED),
                                        JsonInt(NUI_VALIGN_MIDDLE),
                                        JsonInt(NUI_HALIGN_CENTER)
                                    ));
                                NB_AddDrawListItem(
                                    NuiDrawListImage(
                                        JsonBool(TRUE),
                                        JsonString("nui_cnt_down"),
                                        NuiRect(0.0f, 14.0f, 14.0f, 14.0f),
                                        JsonInt(NUI_ASPECT_EXACTSCALED),
                                        JsonInt(NUI_VALIGN_MIDDLE),
                                        JsonInt(NUI_HALIGN_CENTER)
                                    )); 
                            NB_End();
                        NB_End();
                    NB_End();                      

                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiText(NuiBind(CG_BIND_TEXT_POINT_BUY_NUMBER), TRUE, NUI_SCROLLBARS_NONE));
                    NB_SetDimensions(40.0f, 32.0f);
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("OK")));
                    NB_SetDimensions(100.0f, 32.0f);
                    NB_SetId(CG_ID_BUTTON_ABILITY_OK);
                    NB_SetEnabled(NuiBind(CG_BUTTON_ABILITY_OK_ENABLED));
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
    PrintString("Race Changed: " + IntToString(NWM_GetBindInt(CG_BIND_VALUE_RACE)));

    CG_SetBaseAbilityScores();
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
    int nRace = NWM_GetBindInt(CG_BIND_VALUE_RACE);
    int nGender = NWM_GetBindInt(CG_BIND_VALUE_GENDER);
    NWM_SetBindString(CG_BIND_VALUE_FIRST_NAME, CG_GetRandomCharacterName(nRace, nGender, TRUE));
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_RANDOM_LAST_NAME]
void CG_ClickLastNameButton()
{
    int nRace = NWM_GetBindInt(CG_BIND_VALUE_RACE);
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
    PrintString("Class Changed: " + IntToString(NWM_GetBindInt(CG_BIND_VALUE_CLASS)));

    CG_UpdateAlignmentComboBox();
    CG_SetBaseAbilityScores();
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
    int nClass = NWM_GetBindInt(CG_BIND_VALUE_CLASS);
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

// TODO: Also make this work with class ability adjustments

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

int CG_CalculateAbilityModifier(int nAbilityValue)
{
    int nAbilityNeutralValue = CG_GetRulesetData(CG_RULESET_ABILITY_NEUTRAL_VALUE);
    int nAbilityModifierIncrement = CG_GetRulesetData(CG_RULESET_ABILITY_MODIFIER_INCREMENT);

    if (nAbilityValue < nAbilityNeutralValue && (nAbilityNeutralValue % 2 == 0))
        return ((nAbilityValue - (nAbilityNeutralValue + 1)) / nAbilityModifierIncrement);
    else
        return ((nAbilityValue - nAbilityNeutralValue) / nAbilityModifierIncrement);
}

void CG_SetBaseAbilityScores()
{
    int nRace = NWM_GetBindInt(CG_BIND_VALUE_RACE);
    int nClass = NWM_GetBindInt(CG_BIND_VALUE_CLASS);
    int nAbilityMin = CG_GetRulesetData(CG_RULESET_BASE_ABILITY_MIN); 
    int nAbilityMinPrimary = CG_GetRulesetData(CG_RULESET_BASE_ABILITY_MIN_PRIMARY);

    CG_SetAbilityPointBuyNumber(StringToInt(Get2DAString("racialtypes", "AbilitiesPointBuyNumber", nRace)));
    json jAbilities = GetJsonArrayOfSize(6, JsonInt(nAbilityMin));

    if (StringToInt(Get2DAString("classes", "SpellCaster", nClass)))
    {
        int nSpellcastingAbility = AbilityToConstant(Get2DAString("classes", "SpellcastingAbil", nClass));
        int nCurrentAbilityValue = JsonArrayGetInt(jAbilities, nSpellcastingAbility);
        int nRacialAbilityAdjust = CG_GetRacialAbilityAdjust(nRace, nSpellcastingAbility);
        int nPointBuyChange = CG_GetAbilityPointBuyNumber() - (nAbilityMinPrimary - nAbilityMin);

        CG_SetAbilityPointBuyNumber(nPointBuyChange + nRacialAbilityAdjust);
        jAbilities = JsonArraySetInt(jAbilities, nSpellcastingAbility, nAbilityMinPrimary - nRacialAbilityAdjust);
    }    
    
    PrintString("Base Ability Scores: " + JsonDump(jAbilities));
    PrintString("Point Buy Number: " + IntToString(CG_GetAbilityPointBuyNumber()));

    NWM_SetUserData(CG_USERDATA_BASE_ABILITY_SCORES, jAbilities);
}

void CG_SetAbilityNames()
{
    json jAbilityNames = JsonArray();
    int nAbility;
    for (nAbility = 0; nAbility < 6; nAbility++)
    {
        jAbilityNames = JsonArrayInsertString(jAbilityNames, AbilityConstantToName(nAbility) + ":");
    }
    NWM_SetBind(CG_BIND_LIST_ABILITY_NAMES, jAbilityNames);    
}

void CG_UpdateAbilityValues()
{
    int nRace = NWM_GetUserDataInt(CG_BIND_VALUE_RACE);
    json jBaseAbilityScores = NWM_GetUserData(CG_USERDATA_BASE_ABILITY_SCORES);
    json jAbilityValues = JsonArray();
    int nAbility;
    for (nAbility = 0; nAbility < 6; nAbility++)
    {
        int nAbilityValue = JsonArrayGetInt(jBaseAbilityScores, nAbility) + CG_GetRacialAbilityAdjust(nRace, nAbility);        
        int nModifier = CG_CalculateAbilityModifier(nAbilityValue);        
        jAbilityValues = JsonArrayInsertString(jAbilityValues, IntToString(nAbilityValue) + " (" + (nModifier >= 0 ? "+" : "" ) + IntToString(nModifier) + ")");
    }

    NWM_SetBind(CG_BIND_LIST_ABILITY_VALUES, jAbilityValues);
}

int CG_CalculatePointCost(int nAbilityValue)
{
	if (nAbilityValue < CG_GetRulesetData(CG_RULESET_ABILITY_COST_INCREMENT_2))
		return 1;
	if (nAbilityValue < CG_GetRulesetData(CG_RULESET_ABILITY_COST_INCREMENT_3))
		return 2;
	if (nAbilityValue < CG_GetRulesetData(CG_RULESET_ABILITY_COST_INCREMENT_4))
		return 3;
	return 4;
}

int CG_CheckAbilityAboveMinimum(int nAbility, int nBaseValue)
{
    if (AbilityToConstant(Get2DAString("classes", "SpellcastingAbil", NWM_GetUserDataInt(CG_BIND_VALUE_CLASS))) == nAbility)
        return (nBaseValue + CG_GetRacialAbilityAdjust(NWM_GetUserDataInt(CG_BIND_VALUE_RACE), nAbility)) > CG_GetRulesetData(CG_RULESET_BASE_ABILITY_MIN_PRIMARY);
    else
        return nBaseValue > CG_GetRulesetData(CG_RULESET_BASE_ABILITY_MIN);
}

void CG_AdjustAbility(int nAbility, int bIncrement)
{
    json jBaseAbilityScores = NWM_GetUserData(CG_USERDATA_BASE_ABILITY_SCORES);
    int nAbilityValue = JsonArrayGetInt(jBaseAbilityScores, nAbility);
    int nPointBuyNumber = CG_GetAbilityPointBuyNumber();

    if (bIncrement)
    {        
        int nAbilityPointCost = CG_CalculatePointCost(nAbilityValue);
        if (nAbilityValue < CG_GetRulesetData(CG_RULESET_BASE_ABILITY_MAX) && nAbilityPointCost <= nPointBuyNumber)
        {
            jBaseAbilityScores = JsonArraySetInt(jBaseAbilityScores, nAbility, nAbilityValue + 1);
            CG_ModifyAbilityPointBuyNumber(-nAbilityPointCost);
            NWM_SetUserData(CG_USERDATA_BASE_ABILITY_SCORES, jBaseAbilityScores);
            NWM_SetBindString(CG_BIND_TEXT_POINT_BUY_NUMBER, IntToString(CG_GetAbilityPointBuyNumber()));            
            CG_UpdateAbilityValues();
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
            NWM_SetBindString(CG_BIND_TEXT_POINT_BUY_NUMBER, IntToString(CG_GetAbilityPointBuyNumber()));
            CG_UpdateAbilityValues();            
        }
    }    
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_ID_BUTTON_ABILITY_WINDOW]
void CG_ClickAbilitiesButton()
{
    object oPlayer = OBJECT_SELF;
    int nRace = NWM_GetBindInt(CG_BIND_VALUE_RACE);
    int nClass = NWM_GetBindInt(CG_BIND_VALUE_CLASS);
    int nPointBuyNumber = CG_GetAbilityPointBuyNumber();
    json jBaseAbilityScores = NWM_GetUserData(CG_USERDATA_BASE_ABILITY_SCORES);

    if (NWM_GetIsWindowOpen(oPlayer, CG_ABILITY_WINDOW_ID))
        NWM_CloseWindow(oPlayer, CG_ABILITY_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, CG_ABILITY_WINDOW_ID))
    {      
        CG_SetAbilityPointBuyNumber(nPointBuyNumber);
        NWM_SetUserDataInt(CG_BIND_VALUE_RACE, nRace);
        NWM_SetUserDataInt(CG_BIND_VALUE_CLASS, nClass);
        NWM_SetUserData(CG_USERDATA_BASE_ABILITY_SCORES, jBaseAbilityScores);

        CG_SetAbilityNames();
        CG_UpdateAbilityValues();       

        NWM_SetBindString(CG_BIND_TEXT_POINT_BUY_NUMBER, IntToString(nPointBuyNumber));
    }
}

// @NWMEVENT[CG_ABILITY_WINDOW_ID:NUI_EVENT_MOUSEUP:CG_ID_BUTTON_LIST_ABILITY]
void CG_AbilityAdjustmentButtonMouseUp()
{
    json jPayload = NuiGetEventPayload();
    int nMouseButton = NuiGetMouseButton(jPayload);

    if (nMouseButton == NUI_MOUSE_BUTTON_LEFT)
    {    
        CG_AdjustAbility(NuiGetEventArrayIndex(), NuiGetMouseY(jPayload) <= 14.0f);
    }
}

// ***
