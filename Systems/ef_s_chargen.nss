/*
    Script: ef_s_chargen
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_profiler"

const string CG_LOG_TAG                             = "CharacterGemeration";
const string CG_SCRIPT_NAME                         = "ef_s_chargen";

const string CG_CHARACTER_BASE                      = "CharacterBase";

const string CG_MAIN_WINDOW_ID                      = "CG_MAIN";
const string CG_BIND_FIRSTNAME_VALUE                = "firstname";
const string CG_BIND_FIRSTNAME_BUTTON               = "btn_firstname";
const string CG_BIND_LASTNAME_VALUE                 = "lastname";
const string CG_BIND_LASTNAME_BUTTON                = "btn_lastname";
const string CG_BIND_GENDER_VALUE                   = "gender";
const string CG_BIND_RACE_VALUE                     = "race";
const string CG_BIND_CLASS_VALUE                    = "class";
const string CG_BIND_ALIGNMENT_COMBO_ENTRIES        = "alignment_combo_entries";
const string CG_BIND_ALIGNMENT_VALUE                = "alignment";
const string CG_BIND_ABILITIES_BUTTON               = "btn_abilities";

const string CG_ABILITIES_WINDOW_ID                 = "CG_ABILITIES";

const string CG_USERDATA_BASE_ABILITY_SCORES        = "base_ability_scores";

string CG_GetRandomCharacterName(int bFirstName);
void CG_SetCharacter(json jCharacter);
json CG_GetCharacter();
json CG_GetCharacterBase();

void CG_UpdateAlignmentCombo();

void CG_SetGender(int nGender);
void CG_SetRace(int nRace);
void CG_SetAlignment(int nCombinedAlignment);

void CG_UpdateBaseAbilityScores();

// @CORE[EF_SYSTEM_INIT]
void CG_Init()
{

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
                NB_StartStaticOptions(NUI_DIRECTION_HORIZONTAL, NuiBind(CG_BIND_GENDER_VALUE));
                    NB_SetDimensions(348.0f, 32.0f);
                    NB_AddStaticOptionsEntry("Male");
                    NB_AddStaticOptionsEntry("Female");
                NB_End();
            NB_End();            

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Race:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartStaticCombo(NuiBind(CG_BIND_RACE_VALUE));
                    NB_SetDimensions(348.0f, 32.0f);
                    int nRace, nNumRaces = Get2DARowCount("racialtypes");
                    for (nRace = 0; nRace < nNumRaces; nRace++)
                    {
                        if (!StringToInt(Get2DAString("racialtypes", "PlayerRace", nRace)))
                            continue;

                        NB_AddStaticComboEntry(Get2DAStrRefString("racialtypes", "Name", nRace), nRace);
                    }
                NB_End();
            NB_End();            
            
            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("First Name:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiTextEdit(JsonString(""), NuiBind(CG_BIND_FIRSTNAME_VALUE), 256, FALSE));
                    NB_SetHeight(32.0f);
                NB_End();
                NB_StartElement(NuiButtonImage(JsonString("ir_cheer")));
                    NB_SetDimensions(32.0f, 32.0f);
                    NB_SetId(CG_BIND_FIRSTNAME_BUTTON);
                NB_End();
            NB_End();

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Last Name:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiTextEdit(JsonString(""), NuiBind(CG_BIND_LASTNAME_VALUE), 256, FALSE));
                    NB_SetHeight(32.0f);
                NB_End();
                NB_StartElement(NuiButtonImage(JsonString("ir_cheer")));
                    NB_SetDimensions(32.0f, 32.0f);
                    NB_SetId(CG_BIND_LASTNAME_BUTTON);
                NB_End();                
            NB_End();

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Class:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartStaticCombo(NuiBind(CG_BIND_CLASS_VALUE));
                    NB_SetDimensions(348.0f, 32.0f);
                    int nClass, nNumClasses = Get2DARowCount("classes");
                    for (nClass = 0; nClass < nNumClasses; nClass++)
                    {
                        if (!StringToInt(Get2DAString("classes", "PlayerClass", nClass)) || Get2DAString("classes", "PreReqTable", nClass) != "")
                            continue;

                        NB_AddStaticComboEntry(Get2DAStrRefString("classes", "Name", nClass), nClass);
                    }
                NB_End();
            NB_End();

            NB_StartRow();                
                NB_StartElement(NuiLabel(JsonString("Alignment:"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                    NB_SetDimensions(128.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiCombo(NuiBind(CG_BIND_ALIGNMENT_COMBO_ENTRIES), NuiBind(CG_BIND_ALIGNMENT_VALUE)));
                    NB_SetDimensions(348.0f, 32.0f);
                NB_End();
            NB_End();

            NB_StartRow();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("Abilities")));
                    NB_SetDimensions(150.0f, 32.0f);
                    NB_SetId(CG_BIND_ABILITIES_BUTTON);
                NB_End();
                NB_AddSpacer();
            NB_End();                                                                             

        NB_End();            
    return NB_FinalizeWindow();
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_BIND_FIRSTNAME_BUTTON]
void CG_ClickFirstNameButton()
{
    NWM_SetBindString(CG_BIND_FIRSTNAME_VALUE, CG_GetRandomCharacterName(TRUE));
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_BIND_LASTNAME_BUTTON]
void CG_ClickLastNameButton()
{
    NWM_SetBindString(CG_BIND_LASTNAME_VALUE, CG_GetRandomCharacterName(FALSE));
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_WATCH:CG_BIND_RACE_VALUE]
void CG_WatchRaceBind()
{
    CG_UpdateBaseAbilityScores();
}

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_WATCH:CG_BIND_CLASS_VALUE]
void CG_WatchClassBind()
{
    CG_UpdateAlignmentCombo();
}

const string CG_BIND_LIST_ABILITY_NAMES                 = "list_ability_names";
const string CG_BIND_LIST_ABILITY_VALUES                = "list_ability_values"; 

const string CG_BIND_LIST_ABILITY_BUTTON                = "list_ability_button";
const string CG_BIND_ABILITY_POINTS                     = "ability_points_remaining";
const string CG_BIND_ABILITY_OK_BUTTON                  = "btn_ability_ok";
const string CG_BING_ABILITY_OK_BUTTON_ENABLED          = "btn_ability_ok_enabled";

// @NWMEVENT[CG_MAIN_WINDOW_ID:NUI_EVENT_CLICK:CG_BIND_ABILITIES_BUTTON]
void CG_ClickAbilitiesButton()
{
    object oPlayer = OBJECT_SELF;

    json jBaseAbilityScores = NWM_GetUserData(CG_USERDATA_BASE_ABILITY_SCORES);

    if (NWM_GetIsWindowOpen(oPlayer, CG_ABILITIES_WINDOW_ID))
        NWM_CloseWindow(oPlayer, CG_ABILITIES_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, CG_ABILITIES_WINDOW_ID))
    {      
        json jAbilityNames = JsonArray();
        json jAbilityValues = JsonArray();
        int nAbility;
        for (nAbility = 0; nAbility < 6; nAbility++)
        {
            jAbilityNames = JsonArrayInsertString(jAbilityNames, AbilityConstantToName(nAbility) + ":");
            
            int nBaseAbility = JsonArrayGetInt(jBaseAbilityScores, nAbility);
            int nModifier = (nBaseAbility - 10) / 2;
            
            jAbilityValues = JsonArrayInsertString(jAbilityValues, IntToString(nBaseAbility) + " (" + IntToString(nModifier) + ")");
        }
        NWM_SetBind(CG_BIND_LIST_ABILITY_NAMES, jAbilityNames);
        NWM_SetBind(CG_BIND_LIST_ABILITY_VALUES, jAbilityValues);

        NWM_SetBindString(CG_BIND_ABILITY_POINTS, "30");
    }
}

// @NWMWINDOW[CG_ABILITIES_WINDOW_ID]
json CG_CreateAbilitiesWindow()
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
                            NB_SetId(CG_BIND_LIST_ABILITY_BUTTON);
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
                NB_StartElement(NuiText(NuiBind(CG_BIND_ABILITY_POINTS), TRUE, NUI_SCROLLBARS_NONE));
                    NB_SetDimensions(40.0f, 32.0f);
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("OK")));
                    NB_SetDimensions(100.0f, 32.0f);
                    NB_SetId(CG_BIND_ABILITY_OK_BUTTON);
                    NB_SetEnabled(NuiBind(CG_BING_ABILITY_OK_BUTTON_ENABLED));
                NB_End();             
            NB_End();                
        NB_End();
    return NB_FinalizeWindow();        
}

// @NWMEVENT[CG_ABILITIES_WINDOW_ID:NUI_EVENT_MOUSEUP:CG_BIND_LIST_ABILITY_BUTTON]
void CG_AbilityButtonMouseUp()
{
    json jPayload = NuiGetEventPayload();
    int nMouseButton = NuiGetMouseButton(jPayload);

    if (nMouseButton == NUI_MOUSE_BUTTON_LEFT)
    {
        int nAbility = NuiGetEventArrayIndex();
        float fMouseY = NuiGetMouseY(jPayload);
        
        if (fMouseY <= 14.0f)
        {
            PrintString("Increase: " + IntToString(nAbility));
        }
        else 
        {
            PrintString("Decrease: " + IntToString(nAbility));
        }
    }
}

// @PMBUTTON[Character Creator:Create a new character]
void CG_ShowMainWindow()
{
    object oPlayer = OBJECT_SELF;

    if (NWM_GetIsWindowOpen(oPlayer, CG_MAIN_WINDOW_ID))
        NWM_CloseWindow(oPlayer, CG_MAIN_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, CG_MAIN_WINDOW_ID))
    {      
        struct ProfilerData pd = Profiler_Start("CharacterGen");
        
        CG_SetCharacter(CG_GetCharacterBase());

        CG_UpdateAlignmentCombo();
        CG_UpdateBaseAbilityScores();

        NWM_SetBindWatch(CG_BIND_RACE_VALUE, TRUE);
        NWM_SetBindWatch(CG_BIND_CLASS_VALUE, TRUE);

        PrintString("Class Bind: " + IntToString(NWM_GetBindInt(CG_BIND_CLASS_VALUE)));

        Profiler_Stop(pd);
    }
}

string CG_GetRandomCharacterName(int bFirstName)
{
    int nRace = NWM_GetBindInt(CG_BIND_RACE_VALUE);
    int nGender = NWM_GetBindInt(CG_BIND_GENDER_VALUE);

    string sName;
    if (bFirstName)
        sName = RandomName(2 + ((nRace == 3 ? 4 : nRace == 4 ? 3 : nRace) * 3) + nGender > 0);
    else 
        sName = RandomName(2 + (nRace * 3) + 2);

    return sName;
}

void CG_SetCharacter(json jCharacter)
{
    NWM_SetUserData("character", jCharacter);
}

json CG_GetCharacter()
{
    return NWM_GetUserData("character");    
}

json CG_GetCharacterBase()
{
    json jBase = GetLocalJson(GetDataObject(CG_SCRIPT_NAME), CG_CHARACTER_BASE);

    if (!JsonGetType(jBase))
    {
        jBase = JsonObject();
        jBase = GffAddByte(jBase, "Gender", 0);   
        jBase = GffAddByte(jBase, "Appearance_Head", 1);   

        jBase = GffAddByte(jBase, "BodyPart_Neck", 1);
        jBase = GffAddByte(jBase, "BodyPart_Pelvis", 1);
        jBase = GffAddByte(jBase, "BodyPart_Torso", 1);
        jBase = GffAddByte(jBase, "BodyPart_Belt", 0);
        jBase = GffAddByte(jBase, "BodyPart_LBicep", 1);
        jBase = GffAddByte(jBase, "BodyPart_LFArm", 1);
        jBase = GffAddByte(jBase, "BodyPart_LFoot", 1);
        jBase = GffAddByte(jBase, "BodyPart_LHand", 1);         
        jBase = GffAddByte(jBase, "BodyPart_LFShin", 1);
        jBase = GffAddByte(jBase, "BodyPart_LShoul", 0);
        jBase = GffAddByte(jBase, "BodyPart_LThigh", 1);
        jBase = GffAddByte(jBase, "BodyPart_RBicep", 1);
        jBase = GffAddByte(jBase, "BodyPart_RFArm", 1);
        jBase = GffAddByte(jBase, "BodyPart_RHand", 1);  
        jBase = GffAddByte(jBase, "ArmorPart_RFoot", 1);
        jBase = GffAddByte(jBase, "BodyPart_RFShin", 1);
        jBase = GffAddByte(jBase, "BodyPart_RShoul", 0);
        jBase = GffAddByte(jBase, "BodyPart_RThigh", 1);

        jBase = GffAddByte(jBase, "IsPC", 1);
        jBase = GffAddInt(jBase, "FootstepType", -1);
        jBase = GffAddByte(jBase, "Interruptable", 1);
        jBase = GffAddByte(jBase, "IsCommandable", 1);
        jBase = GffAddByte(jBase, "IsDestroyable", 1);
        jBase = GffAddByte(jBase, "IsRaiseable", 1);                  
        jBase = GffAddByte(jBase, "MovementRate", 0);

        SetLocalJson(GetDataObject(CG_SCRIPT_NAME), CG_CHARACTER_BASE, jBase);
    }

    return jBase;        
}

void CG_SetGender(int nGender)
{
    json jCharacter = CG_GetCharacter();
         jCharacter = GffReplaceByte(jCharacter, "Gender", nGender);
    CG_SetCharacter(jCharacter);         
}

void CG_SetRace(int nRace)
{
    int nAppearance = StringToInt(Get2DAString("racialtypes", "Appearance", nRace));
    int nCreatureSize = StringToInt(Get2DAString("appearance","SIZECATEGORY", nAppearance));

    json jCharacter = CG_GetCharacter();    
         jCharacter = GffReplaceByte(jCharacter, "Race", nRace);    
         jCharacter = GffReplaceByte(jCharacter, "Appearance_Type", nAppearance);
         jCharacter = GffReplaceInt(jCharacter, "CreatureSize", nCreatureSize);
    CG_SetCharacter(jCharacter);               
}

void CG_SetClass(int nClass)
{
    json jClassObject = JsonObject();
         jClassObject = GffAddInt(jClassObject, "Class", nClass);
         jClassObject = GffAddShort(jClassObject, "ClassLevel", 1);

    json jCharacter = CG_GetCharacter();     
    jCharacter = GffReplaceList(jCharacter, "ClassList", JsonArrayInsert(JsonArray(), jClassObject));
    CG_SetCharacter(jCharacter); 
}

void CG_SetAlignment(int nCombinedAlignment)
{
    int nLawfulChaoticConstant = StringToInt(GetStringLeft(IntToString(nCombinedAlignment), 1));
    int nGoodEvilConstant = StringToInt(GetStringRight(IntToString(nCombinedAlignment), 1));
    int nLawfulChaotic = nLawfulChaoticConstant == ALIGNMENT_LAWFUL ? 85 : nLawfulChaoticConstant == ALIGNMENT_CHAOTIC ? 15 : 50;
    int nGoodEvil = nGoodEvilConstant == ALIGNMENT_GOOD ? 85 : nGoodEvilConstant == ALIGNMENT_EVIL ? 15 : 50;
    
    json jCharacter = CG_GetCharacter();    
         jCharacter = GffReplaceByte(jCharacter, "LawfulChaotic", nLawfulChaotic);    
         jCharacter = GffReplaceByte(jCharacter, "GoodEvil", nGoodEvil);
    CG_SetCharacter(jCharacter);     
}

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

void CG_UpdateAlignmentCombo()
{
    int nClass = NWM_GetBindInt(CG_BIND_CLASS_VALUE);
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
    
    NWM_SetBind(CG_BIND_ALIGNMENT_COMBO_ENTRIES, jComboEntries);    
}

void CG_UpdateBaseAbilityScores()
{
    int nRace = NWM_GetBindInt(CG_BIND_RACE_VALUE);
    json jAbilities = GetJsonArrayOfSize(6, JsonInt(8));

    string sSetBaseAbility = Lambda(
        "{ return JsonArraySetInt(arg1, AbilityToConstant(arg2), JsonArrayGetInt(arg1, AbilityToConstant(arg2)) + StringToInt(Get2DAString(\"racialtypes\", arg2 + \"Adjust\", arg3))); }", 
        "jsi", "j", CG_SCRIPT_NAME);

    jAbilities = RetJson(Call(sSetBaseAbility, JsonArg(jAbilities) + StringArg("Str") + IntArg(nRace)));
    jAbilities = RetJson(Call(sSetBaseAbility, JsonArg(jAbilities) + StringArg("Dex") + IntArg(nRace)));
    jAbilities = RetJson(Call(sSetBaseAbility, JsonArg(jAbilities) + StringArg("Con") + IntArg(nRace)));
    jAbilities = RetJson(Call(sSetBaseAbility, JsonArg(jAbilities) + StringArg("Int") + IntArg(nRace)));
    jAbilities = RetJson(Call(sSetBaseAbility, JsonArg(jAbilities) + StringArg("Wis") + IntArg(nRace)));
    jAbilities = RetJson(Call(sSetBaseAbility, JsonArg(jAbilities) + StringArg("Cha") + IntArg(nRace)));

    PrintString(JsonDump(jAbilities));

    NWM_SetUserData(CG_USERDATA_BASE_ABILITY_SCORES, jAbilities);
}

// @CORE[EF_SYSTEM_POST]
void CG_POST()
{
    int nClass = CLASS_TYPE_BARBARIAN;

    // 24 14 34
    // 21 11 31
    // 25 15 35

    PrintString("LG: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_LAWFUL, ALIGNMENT_GOOD)) + 
                ", NG: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_NEUTRAL, ALIGNMENT_GOOD)) +
                ", CG: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_CHAOTIC, ALIGNMENT_GOOD)));

    PrintString("LN: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_LAWFUL, ALIGNMENT_NEUTRAL)) + 
                ", TN: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_NEUTRAL, ALIGNMENT_NEUTRAL)) +
                ", CN: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_CHAOTIC, ALIGNMENT_NEUTRAL)));

    PrintString("LE: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_LAWFUL, ALIGNMENT_EVIL)) + 
                ", NE: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_NEUTRAL, ALIGNMENT_EVIL)) +
                ", CE: " + IntToString(CG_GetIsAlignmentAllowed(nClass, ALIGNMENT_CHAOTIC, ALIGNMENT_EVIL)));                                 
}