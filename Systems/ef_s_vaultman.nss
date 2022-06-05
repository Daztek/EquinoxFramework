/*
    Script: ef_s_vaultman.nss
    Author: Daz
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_profiler"

#include "nwnx_player"
#include "nwnx_vault"

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
        NB_SetDimensions(100.0f, 35.0f);
       NB_End();
       NB_StartElement(NuiButton(JsonString("Delete")));
        NB_SetId(VAULTMAN_BIND_BUTTON_DELETE);
        NB_SetDimensions(100.0f, 35.0f);
       NB_End();
       NB_AddSpacer();
       NB_StartElement(NuiButton(JsonString("Close")));
        NB_SetId(VAULTMAN_BIND_BUTTON_CLOSE);
        NB_SetDimensions(100.0f, 35.0f);
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
    int nCharacterId = JsonObjectGetInt(JsonArrayGet(jVault, nSelection), "id");

    if (nCharacterId != 0)
    {
        ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_SUMMON_MONSTER_3), GetLocation(oPlayer));
        NWNX_Vault_SwitchCharacter(oPlayer, nCharacterId, TRUE);
    }
}

// @NWMEVENT[VAULTMAN_NUI_WINDOW_NAME:NUI_EVENT_CLICK:VAULTMAN_BIND_BUTTON_DELETE]
void VaultMan_ClickDeleteButton()
{
    SendMessageToPC(OBJECT_SELF, "NYI");
}

void VaultMan_ChangeSelection()
{
    int nCurrent = JsonGetInt(NWM_GetUserData("selected"));
    int nNew = NuiGetEventArrayIndex();

    if (nCurrent != nNew)
    {
        NWM_SetUserData("selected", JsonInt(nNew));
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

string VaultMan_GetClasses(int nClass1Id, int nClass2Id, int nClass3Id)
{
    string sClasses = "(";

    if (nClass1Id != CLASS_TYPE_INVALID)
        sClasses += Get2DAStrRefString("classes", "Name", nClass1Id);

    if (nClass2Id != CLASS_TYPE_INVALID)
        sClasses += "/" + Get2DAStrRefString("classes", "Name", nClass2Id);

    if (nClass3Id != CLASS_TYPE_INVALID)
        sClasses += "/" + Get2DAStrRefString("classes", "Name", nClass3Id);

    sClasses += ")";

    return sClasses;
}

string VaultMan_GetRace(int nRace, int nGender)
{
    string sRace = Get2DAStrRefString("racialtypes", "Name", nRace);
    string sGender = nGender ? "Female" : "Male";

    return sRace + ", " + sGender;
}

void VaultMan_LoadVault()
{
    object oPlayer = NWM_GetPlayer();
    int nCount, nSelected, nPlayerId = StringToInt(NWNX_Player_GetBicFileName(oPlayer));
    string sCDKey = GetPCPublicCDKey(oPlayer);
    json jCharacters = JsonArray();

    string sQuery = "SELECT vault_characters.id, vault_characters.owner, " +
                        "json_extract(vault_characters.character, '$.FirstName.value.0'), " +
                        "json_extract(vault_characters.character, '$.LastName.value.0'), " +
                        "json_extract(vault_characters.character, '$.Portrait.value'), " +
                        "json_extract(vault_characters.character, '$.Race.value'), " +
                        "json_extract(vault_characters.character, '$.Gender.value'), " +
                        "IFNULL(json_extract(vault_characters.character, '$.ClassList.value[0].Class.value'), 255), " +
                        "IFNULL(json_extract(vault_characters.character, '$.ClassList.value[1].Class.value'), 255), " +
                        "IFNULL(json_extract(vault_characters.character, '$.ClassList.value[2].Class.value'), 255) " +
                    "FROM vault_characters INNER JOIN vault_access ON vault_access.id = vault_characters.id WHERE vault_access.cdkey = @cdkey;";

    sqlquery sql = SqlPrepareQueryCampaign("servervault", sQuery);
    SqlBindString(sql, "@cdkey", sCDKey);

    while (SqlStep(sql))
    {
        int nId = SqlGetInt(sql, 0);
        string sOwner = SqlGetString(sql, 1);

        json jCharacter = JsonObject();
             jCharacter = JsonObjectSetInt(jCharacter, "id", nId);
             jCharacter = JsonObjectSetString(jCharacter, "owner", sOwner);
             jCharacter = JsonObjectSetInt(jCharacter, "shared", sCDKey != sOwner);
             jCharacter = JsonObjectSetString(jCharacter, "firstname", SqlGetString(sql, 2));
             jCharacter = JsonObjectSetString(jCharacter, "lastname", SqlGetString(sql, 3));
             jCharacter = JsonObjectSetString(jCharacter, "portrait", SqlGetString(sql, 4));
             jCharacter = JsonObjectSetString(jCharacter, "race", VaultMan_GetRace(SqlGetInt(sql, 5), SqlGetInt(sql, 6)));
             jCharacter = JsonObjectSetString(jCharacter, "classes", VaultMan_GetClasses(SqlGetInt(sql, 7), SqlGetInt(sql, 8), SqlGetInt(sql, 9)));

        if (nId == nPlayerId)
            nSelected = nCount;

        jCharacters = JsonArrayInsert(jCharacters, jCharacter);
        nCount++;
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
        struct ProfilerData pd = Profiler_Start("VaultMan_LoadVault");
        VaultMan_LoadVault();
        Profiler_Stop(pd);

        pd = Profiler_Start("VaultMan_UpdateCharacterList");
        VaultMan_UpdateCharacterList();
        Profiler_Stop(pd);
    }
}

int VaultDB_InsertCharacter(string sOwner, json jCharacter)
{
    sqlquery sql = SqlPrepareQueryCampaign("servervault", "INSERT INTO vault_characters (owner, character, timestamp) VALUES(@owner, @character, strftime('%s','now'));");
    SqlBindString(sql, "@owner", sOwner);
    SqlBindJson(sql, "@character", jCharacter);
    SqlStep(sql);

    return SqlGetLastInsertIdCampaign("servervault");
}

void VaultDB_UpdateCharacterById(int nCharacterId, json jCharacter)
{
    sqlquery sql = SqlPrepareQueryCampaign("servervault", "UPDATE vault_characters SET character = @character, timestamp = strftime('%s','now') WHERE id = @id;");
    SqlBindJson(sql, "@character", jCharacter);
    SqlBindInt(sql, "@id", nCharacterId);
    SqlStep(sql);
}

json VaultDB_GetCharacterDataById(int nCharacterId)
{
    sqlquery sql = SqlPrepareQueryCampaign("servervault", "SELECT character FROM vault_characters WHERE id = @id;");
    SqlBindInt(sql, "@id", nCharacterId);

    return SqlStep(sql) ? SqlGetJson(sql, 0) : JsonNull();
}

void VaultDB_DeleteCharacterById(int nCharacterId)
{
    sqlquery sql = SqlPrepareQueryCampaign("servervault", "DELETE FROM vault_characters WHERE id = @id;");
    SqlBindInt(sql, "@id", nCharacterId);
    SqlStep(sql);
}

// @ PMBUTTON[Print Character Json]
void Vault_CharacterJson()
{
    PrintString(JsonDump(NWNX_Vault_GetCharacterJson(OBJECT_SELF)));
}

// @ PMBUTTON[LeveldownTest]
void Vault_LevelDownTest()
{
    object oPlayer = OBJECT_SELF;
    int nCharacterId = StringToInt(NWNX_Player_GetBicFileName(oPlayer));

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_AC_BONUS), GetLocation(oPlayer));

    if (nCharacterId == 1)
    {
        // Save our current character
        VaultDB_UpdateCharacterById(nCharacterId, NWNX_Vault_GetCharacterJson(oPlayer));
        // Leveldown
        SetXP(oPlayer, 2000);
        // Insert a temp character
        nCharacterId = VaultDB_InsertCharacter("TEMP", NWNX_Vault_GetCharacterJson(oPlayer));
        // Switch to our leveled down character, don't save current
        NWNX_Vault_SwitchCharacter(oPlayer, nCharacterId, FALSE);
    }
    else
    {
        json jMainCharacter = VaultDB_GetCharacterDataById(1);
        json jTempCharacter = NWNX_Vault_GetCharacterJson(oPlayer);
        // Replace our main character's items and gold with the temp character's state
        jMainCharacter = GffReplaceList(jMainCharacter, "Equip_ItemList", GffGetList(jTempCharacter, "Equip_ItemList"));
        jMainCharacter = GffReplaceList(jMainCharacter, "ItemList", GffGetList(jTempCharacter, "ItemList"));
        jMainCharacter = GffReplaceDword(jMainCharacter, "Gold", JsonGetInt(GffGetDword(jTempCharacter, "Gold")));
        // Update our main character
        VaultDB_UpdateCharacterById(1, jMainCharacter);
        // Switch back to our main
        NWNX_Vault_SwitchCharacter(oPlayer, 1, FALSE);
        // Delete our temp character
        VaultDB_DeleteCharacterById(nCharacterId);
    }
}

