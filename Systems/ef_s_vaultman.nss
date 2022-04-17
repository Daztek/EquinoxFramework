/*
    Script: ef_s_vaultman.nss
    Author: Daz

    Description:
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"

#include "nwnx_vault"
#include "nwnx_player"

const string VAULTMAN_LOG_TAG                       = "VaultManager";
const string VAULTMAN_SCRIPT_NAME                   = "ef_s_vaultman";

const string VAULTMAN_NUI_WINDOW_NAME               = "VAULT";
const string VAULTMAN_BIND_LIST_PORTRAITS           = "portraits";
const string VAULTMAN_BIND_LIST_NAMES               = "names";
const string VAULTMAN_BIND_LIST_COLORS              = "colors";
const string VAULTMAN_BIND_LIST_RACES               = "races";
const string VAULTMAN_BIND_LIST_CLASSES             = "classes";
const string VAULTMAN_BIND_INFO_LABEL               = "info_label";
const string VAULTMAN_BIND_BUTTON_SWITCH            = "btn_switch";
const string VAULTMAN_BIND_BUTTON_DELETE            = "btn_delete";
const string VAULTMAN_BIND_BUTTON_CLOSE             = "btn_close";

void VaultMan_UpdateCharacterList();

// @NWMWINDOW[VAULTMAN_NUI_WINDOW_NAME]
json VaultMan_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 400.0f, 500.0f));
    NB_SetWindowTitle(JsonString("Character Vault Manager"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartList(NuiBind(VAULTMAN_BIND_LIST_PORTRAITS), 50.0f);
                    NB_StartListTemplateCell(32.0f, FALSE);
                        NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                            NB_StartElement(NuiImage(NuiBind(VAULTMAN_BIND_LIST_PORTRAITS), JsonInt(NUI_ASPECT_EXACTSCALED), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_TOP)));
                                NB_SetId(VAULTMAN_BIND_LIST_PORTRAITS);
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(0.0f, TRUE);
                        NB_StartElement(NuiLabel(NuiBind(VAULTMAN_BIND_LIST_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP)));
                            NB_SetId(VAULTMAN_BIND_INFO_LABEL);
                            NB_SetForegroundColor(NuiBind(VAULTMAN_BIND_LIST_COLORS));
                            NB_StartDrawList(JsonBool(TRUE));
                                NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiBind(VAULTMAN_BIND_LIST_COLORS), NuiRect(0.0f, 16.67f, 300.0f, 33.33f), NuiBind(VAULTMAN_BIND_LIST_RACES)));
                                NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiBind(VAULTMAN_BIND_LIST_COLORS), NuiRect(0.0f, 33.33f, 300.0f, 16.67f), NuiBind(VAULTMAN_BIND_LIST_CLASSES)));
                            NB_End();
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("Switch")));
                    NB_SetId(VAULTMAN_BIND_BUTTON_SWITCH);
                    NB_SetWidth(100.0f);
                    NB_SetHeight(35.0f);
                NB_End();
                NB_StartElement(NuiButton(JsonString("Delete")));
                    NB_SetId(VAULTMAN_BIND_BUTTON_DELETE);
                    NB_SetWidth(100.0f);
                    NB_SetHeight(35.0f);
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("Close")));
                    NB_SetId(VAULTMAN_BIND_BUTTON_CLOSE);
                    NB_SetWidth(100.0f);
                    NB_SetHeight(35.0f);
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[VAULTMAN_NUI_WINDOW_NAME:NUI_EVENT_CLICK:VAULTMAN_BIND_BUTTON_CLOSE]
void VaultMan_ClickCloseButton()
{
    NWM_Destroy();
}

// @NWMEVENT[VAULTMAN_NUI_WINDOW_NAME:NUI_EVENT_CLICK:VAULTMAN_BIND_BUTTON_SWITCH]
void VaultMan_ClickSwitchButton()
{
    object oPlayer = OBJECT_SELF;
    json jVault = NWM_GetUserData("vault");
    int nSelection = JsonGetInt(NWM_GetUserData("selected"));
    string sFileName = JsonObjectGetString(JsonArrayGet(jVault, nSelection), "filename");

    if (sFileName != "")
    {
        ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_SUMMON_MONSTER_1), GetLocation(oPlayer));
        NWNX_Vault_SwitchCharacter(oPlayer, sFileName, TRUE);
    }
}

// @NWMEVENT[VAULTMAN_NUI_WINDOW_NAME:NUI_EVENT_CLICK:VAULTMAN_BIND_BUTTON_DELETE]
void VaultMan_ClickDeleteButton()
{
    SendMessageToPC(OBJECT_SELF, "NYI");
}

void VaultMan_ChangeSelection()
{
    int nSelection = JsonGetInt(NWM_GetUserData("selected"));
    int nArrayIndex = NuiGetEventArrayIndex();

    if (nSelection != nArrayIndex)
    {
        NWM_SetUserData("selected", JsonInt(nArrayIndex));
        VaultMan_UpdateCharacterList();
    }
}

// @NWMEVENT[VAULTMAN_NUI_WINDOW_NAME:NUI_EVENT_MOUSEDOWN:VAULTMAN_BIND_LIST_PORTRAITS]
void VaultMan_MousedownPortrait()
{
    VaultMan_ChangeSelection();
}

// @NWMEVENT[VAULTMAN_NUI_WINDOW_NAME:NUI_EVENT_MOUSEDOWN:VAULTMAN_BIND_INFO_LABEL]
void VaultMan_MousedownInfoLabel()
{
    VaultMan_ChangeSelection();
}

string VaultMan_GetClasses(struct NWNX_Vault_Character str)
{
    string sClasses;

    if (str.nClass1Id != CLASS_TYPE_INVALID)
        sClasses += Get2DAStrRefString("classes", "Name", str.nClass1Id) + " (" + IntToString(str.nClass1Level) + ")";

    if (str.nClass2Id != CLASS_TYPE_INVALID)
        sClasses += " / " + Get2DAStrRefString("classes", "Name", str.nClass2Id) + " (" + IntToString(str.nClass2Level) + ")";

    if (str.nClass3Id != CLASS_TYPE_INVALID)
        sClasses += " / " + Get2DAStrRefString("classes", "Name", str.nClass3Id) + " (" + IntToString(str.nClass3Level) + ")";

    return sClasses;
}

string VaultMan_GetRace(struct NWNX_Vault_Character str)
{
    string sRace = Get2DAStrRefString("racialtypes", "Name", str.nRace);
    string sGender = str.nGender ? "Female" : "Male";

    return sRace + ", " + sGender;
}

void VaultMan_LoadVault()
{
    object oPlayer = NWM_GetPlayer();
    int nCharacter, nNumCharacters = NWNX_Vault_LoadVault(oPlayer), nSelected;
    struct NWNX_Vault_Character str;
    json jCharacters = JsonArray();
    string sPlayerBic = NWNX_Player_GetBicFileName(oPlayer);

    for (nCharacter = 0; nCharacter < nNumCharacters; nCharacter++)
    {
        str = NWNX_Vault_GetCharacterData(nCharacter);

        json jCharacter = JsonObject();
             jCharacter = JsonObjectSetString(jCharacter, "filename", str.sFileName);
             jCharacter = JsonObjectSetString(jCharacter, "uuid", str.sUUID);
             jCharacter = JsonObjectSetString(jCharacter, "firstname", str.sFirstName);
             jCharacter = JsonObjectSetString(jCharacter, "lastname", str.sLastName);
             jCharacter = JsonObjectSetString(jCharacter, "portrait", str.sPortrait);
             jCharacter = JsonObjectSetString(jCharacter, "classes", VaultMan_GetClasses(str));
             jCharacter = JsonObjectSetString(jCharacter, "race", VaultMan_GetRace(str));
             jCharacter = JsonObjectSetInt(jCharacter, "experience", str.nExperience);
             jCharacter = JsonObjectSetInt(jCharacter, "gold", str.nGold);

         //PrintString(JsonDump(jCharacter));

         if (str.sFileName == sPlayerBic)
            nSelected = nCharacter;

        jCharacters = JsonArrayInsert(jCharacters, jCharacter);
    }

    NWM_SetUserData("vault", jCharacters);
    NWM_SetUserData("selected", JsonInt(nSelected));
}

void VaultMan_UpdateCharacterList()
{
    object oPlayer = NWM_GetPlayer();
    json jCharacters = NWM_GetUserData("vault");
    int nCharacter, nNumCharacters = JsonGetLength(jCharacters);
    json jPortraits = JsonArray(), jNames = JsonArray(), jColors = JsonArray(), jClasses = JsonArray(), jRaces = JsonArray();
    int nSelection = JsonGetInt(NWM_GetUserData("selected"));

    for (nCharacter = 0; nCharacter < nNumCharacters; nCharacter++)
    {
        json jCharacter = JsonArrayGet(jCharacters, nCharacter);
        jPortraits = JsonArrayInsertString(jPortraits, JsonObjectGetString(jCharacter, "portrait") + "s");
        jNames = JsonArrayInsertString(jNames, JsonObjectGetString(jCharacter, "firstname") + " " + JsonObjectGetString(jCharacter, "lastname"));
        jColors = JsonArrayInsert(jColors, nCharacter == nSelection ? NuiColor(0, 255, 0) : NuiColor(255, 255, 255));
        jClasses = JsonArrayInsertString(jClasses, JsonObjectGetString(jCharacter, "classes"));
        jRaces = JsonArrayInsertString(jRaces, JsonObjectGetString(jCharacter, "race"));
    }

    NWM_SetBind(VAULTMAN_BIND_LIST_PORTRAITS, jPortraits);
    NWM_SetBind(VAULTMAN_BIND_LIST_NAMES, jNames);
    NWM_SetBind(VAULTMAN_BIND_LIST_COLORS, jColors);
    NWM_SetBind(VAULTMAN_BIND_LIST_CLASSES, jClasses);
    NWM_SetBind(VAULTMAN_BIND_LIST_RACES, jRaces);
}

// @PMBUTTON[Vault Manager:Manage your character vault]
void VaultTest_ShowWindow()
{
    object oPlayer = OBJECT_SELF;

    if (NWM_GetIsWindowOpen(oPlayer, VAULTMAN_NUI_WINDOW_NAME))
        NWM_CloseWindow(oPlayer, VAULTMAN_NUI_WINDOW_NAME);
    else if (NWM_OpenWindow(oPlayer, VAULTMAN_NUI_WINDOW_NAME))
    {
        VaultMan_LoadVault();
        VaultMan_UpdateCharacterList();
    }
}

