/*
    Script: ef_s_perchest
    Author: Daz

    Description:
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_eventman"
#include "nwnx_player"

const string PC_SCRIPT_NAME                 = "ef_s_perchest";

const string PC_TABLE_NAME                  = "PC_ITEMS";
const string PC_WINDOW_ID                   = "PERCHEST";

const int PC_MAX_ITEMS                      = 25;
const int PC_SAVE_ITEM_OBJECT_STATE         = TRUE;

const string PC_BIND_WINDOW_TITLE           = "window_title";
const string PC_BIND_PROGRESS               = "progress";
const string PC_BIND_PROGRESS_TOOLTIP       = "progress_tooltip";
const string PC_BIND_SEARCH_TEXT            = "search_text";
const string PC_BIND_BUTTON_CLEAR           = "btn_clear";
const string PC_BIND_ICONS_ARRAY            = "icons";
const string PC_BIND_ICON_GROUP             = "icon_group";
const string PC_BIND_TOOLTIPS_ARRAY         = "tooltips";
const string PC_BIND_NAMES_ARRAY            = "names";
const string PC_BIND_NAME_LABEL             = "name_label";
const string PC_BIND_DEPOSIT_MODE           = "deposit_mode";
const string PC_BIND_BUTTON_DEPOSIT         = "btn_deposit";
const string PC_BIND_BUTTON_CLOSE           = "btn_close";

int PC_GetStoredItemAmount(object oPlayer);
void PC_UpdateItemList();
void PC_WithdrawItem();
void PC_SetDepositMode(object oPlayer, int bEnabled);

// @CORE[CORE_SYSTEM_INIT]
void PC_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + PC_TABLE_NAME + " (" +
                    "player_uuid TEXT NOT NULL, " +
                    "item_uuid TEXT NOT NULL, " +
                    "item_name TEXT NOT NULL, " +
                    "item_baseitem INTEGER NOT NULL, " +
                    "item_stacksize INTEGER NOT NULL, " +
                    "item_iconresref TEXT NOT NULL, " +
                    "item_data TEXT_NOT NULL, " +
                    "PRIMARY KEY(player_uuid, item_uuid));";
    sqlquery sql = SqlPrepareQueryCampaign(PC_SCRIPT_NAME, sQuery);
    SqlStep(sql);
}

// @NWNX[NWNX_ON_INPUT_DROP_ITEM_BEFORE:DL]
void PC_DropItem()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, PC_WINDOW_ID, TRUE))
    {
        if (!JsonGetInt(NWM_GetBind(PC_BIND_DEPOSIT_MODE)))
            return;

        object oItem = EM_NWNXGetObject("ITEM");

        if (!GetIsObjectValid(oItem) || GetObjectType(oItem) != OBJECT_TYPE_ITEM || GetLocalInt(oItem, "PC_ITEM_DESTROYED"))
            return;

        if (GetItemPossessor(oItem) != oPlayer)
        {
            SendMessageToPC(oPlayer, "You do not own '" + GetName(oItem) + "'");
            return;
        }

        int nStoredItems = PC_GetStoredItemAmount(oPlayer);
        if (nStoredItems >= PC_MAX_ITEMS)
        {
            EM_NWNXSkipEvent();
            SendMessageToPC(oPlayer, "Your persistent chest is full, withdraw an item first.");
            return;
        }

        int nItemBaseItem = GetBaseItemType(oItem);
        json jItemData = ObjectToJson(oItem, PC_SAVE_ITEM_OBJECT_STATE);
        string sItemIconResRef = GetItemIconResref(oItem, jItemData, nItemBaseItem);
        string sQuery = "INSERT INTO " + PC_TABLE_NAME +
                        "(player_uuid, item_uuid, item_name, item_baseitem, item_stacksize, item_iconresref, item_data) " +
                        "VALUES(@player_uuid, @item_uuid, @item_name, @item_baseitem, @item_stacksize, @item_iconresref, @item_data);";
        sqlquery sql = SqlPrepareQueryCampaign(PC_SCRIPT_NAME, sQuery);

        SqlBindString(sql, "@player_uuid", GetObjectUUID(oPlayer));
        SqlBindString(sql, "@item_uuid", GetObjectUUID(oItem));
        SqlBindString(sql, "@item_name", GetItemName(oItem, GetIdentified(oItem)));
        SqlBindInt(sql, "@item_baseitem", nItemBaseItem);
        SqlBindInt(sql, "@item_stacksize", GetItemStackSize(oItem));
        SqlBindString(sql, "@item_iconresref", sItemIconResRef);
        SqlBindJson(sql, "@item_data", jItemData);
        SqlStep(sql);

        PC_UpdateItemList();

        SetLocalInt(oItem, "PC_ITEM_DESTROYED", TRUE);
        DestroyObject(oItem);
        EM_NWNXSkipEvent();
    }
}

// @NWMWINDOW[PC_WINDOW_ID]
json PC_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 400.0f, 600.0f));
    NB_SetWindowTitle(NuiBind(PC_BIND_WINDOW_TITLE));
      NB_StartColumn();
        NB_StartRow();
          NB_StartElement(NuiProgress(NuiBind(PC_BIND_PROGRESS)));
            NB_SetTooltip(NuiBind(PC_BIND_PROGRESS_TOOLTIP));
          NB_End();
        NB_End();
        NB_StartRow();
          NB_AddElement(NuiTextEdit(JsonString("Search..."), NuiBind(PC_BIND_SEARCH_TEXT), 64, FALSE, FALSE));
          NB_StartElement(NuiButton(JsonString("X")));
            NB_SetId(PC_BIND_BUTTON_CLEAR);
            NB_SetEnabled(NuiBind(PC_BIND_BUTTON_CLEAR));
            NB_SetDimensions(35.0f, 35.0f);
          NB_End();
        NB_End();
        NB_StartRow();
          NB_StartList(NuiBind(PC_BIND_ICONS_ARRAY), 32.0f);
            NB_StartListTemplateCell(32.0f, FALSE);
              NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                NB_SetId(PC_BIND_ICON_GROUP);
                NB_SetMargin(0.0f);
                NB_StartElement(NuiImage(NuiBind(PC_BIND_ICONS_ARRAY), JsonInt(NUI_ASPECT_FIT100), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_TOP)));
                  NB_SetMargin(0.0f);
                  NB_SetTooltip(NuiBind(PC_BIND_TOOLTIPS_ARRAY));
                NB_End();
              NB_End();
            NB_End();
            NB_StartListTemplateCell(0.0f, TRUE);
              NB_StartElement(NuiLabel(NuiBind(PC_BIND_NAMES_ARRAY), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                NB_SetId(PC_BIND_NAME_LABEL);
              NB_End();
            NB_End();
          NB_End();
        NB_End();
        NB_StartRow();
          NB_StartElement(NuiButtonSelect(JsonString("Deposit Mode"), NuiBind(PC_BIND_DEPOSIT_MODE)));
            NB_SetId(PC_BIND_BUTTON_DEPOSIT);
            NB_SetDimensions(150.0f, 35.0f);
          NB_End();
          NB_AddSpacer();
          NB_StartElement(NuiButton(JsonString("Close")));
            NB_SetId(PC_BIND_BUTTON_CLOSE);
            NB_SetDimensions(80.0f, 35.0f);
          NB_End();
        NB_End();
      NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[PC_WINDOW_ID:NUI_EVENT_CLICK:PC_BIND_BUTTON_DEPOSIT]
void PC_ClickDepositModeButton()
{
    PC_SetDepositMode(OBJECT_SELF, JsonGetInt(NWM_GetBind(PC_BIND_DEPOSIT_MODE)));
}

// @NWMEVENT[PC_WINDOW_ID:NUI_EVENT_CLICK:PC_BIND_BUTTON_CLOSE]
void PC_ClickCloseButton()
{
    NWM_Destroy();
}

// @NWMEVENT[PC_WINDOW_ID:NUI_EVENT_CLICK:PC_BIND_BUTTON_CLEAR]
void PC_ClickClearButton()
{
    NWM_SetBindString(PC_BIND_SEARCH_TEXT, "");
}

// @NWMEVENT[PC_WINDOW_ID:NUI_EVENT_WATCH:PC_BIND_SEARCH_TEXT]
void PC_WatchSearch()
{
    json jSearch = NWM_GetBind(PC_BIND_SEARCH_TEXT);
    NWM_SetBindBool(PC_BIND_BUTTON_CLEAR, GetStringLength(JsonGetString(jSearch)));
    PC_UpdateItemList();
}

// @NWMEVENT[PC_WINDOW_ID:NUI_EVENT_CLOSE:NUI_WINDOW_ROOT_GROUP]
void PC_CloseWindow()
{
    PC_SetDepositMode(OBJECT_SELF, FALSE);
}

// @PMBUTTON[Persistent Chest:Manage your persistent chest]
void PC_OpenPersistentChest()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_ToggleWindow(oPlayer, PC_WINDOW_ID))
    {
        NWM_SetBindWatch(PC_BIND_SEARCH_TEXT, TRUE);
        NWM_SetBindString(PC_BIND_WINDOW_TITLE, GetName(oPlayer) + "'s Persistent Chest");
        NWM_SetBindString(PC_BIND_SEARCH_TEXT, "");
    }
}

int PC_GetStoredItemAmount(object oPlayer)
{
    string sQuery = "SELECT COUNT(*) FROM " + PC_TABLE_NAME + " WHERE player_uuid = @player_uuid;";
    sqlquery sql = SqlPrepareQueryCampaign(PC_SCRIPT_NAME, sQuery);
    SqlBindString(sql, "@player_uuid", GetObjectUUID(oPlayer));
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void PC_UpdateItemList()
{
    object oPlayer = NWM_GetPlayer();
    object oDataObject = GetDataObject(PC_SCRIPT_NAME);

    json jUUIDArray = JsonArray();
    json jNamesArray = JsonArray();
    json jTooltipArray = JsonArray();
    json jIconArray = JsonArray();

    int nNumItems = PC_GetStoredItemAmount(oPlayer);
    string sSearch = JsonGetString(NWM_GetBind(PC_BIND_SEARCH_TEXT));
    string sQuery = "SELECT item_uuid, item_name, item_baseitem, item_stacksize, item_iconresref FROM " +
                    PC_TABLE_NAME + " WHERE player_uuid = @player_uuid" + (sSearch != "" ? " AND item_name LIKE @search" : "") + " ORDER BY item_baseitem ASC, item_name ASC;";
    sqlquery sql = SqlPrepareQueryCampaign(PC_SCRIPT_NAME, sQuery);
    SqlBindString(sql, "@player_uuid", GetObjectUUID(oPlayer));
    if (sSearch != "")
        SqlBindString(sql, "@search", "%" + sSearch + "%");

    while (SqlStep(sql))
    {
        string sUUID = SqlGetString(sql, 0);
        string sName = SqlGetString(sql, 1);
        int nBaseItem = SqlGetInt(sql, 2);
        int nStackSize = SqlGetInt(sql, 3);
        string sIconResRef = SqlGetString(sql, 4);

        JsonArrayInsertStringInplace(jUUIDArray, sUUID);
        JsonArrayInsertStringInplace(jNamesArray, sName + (nStackSize > 1 ? " (x" + IntToString(nStackSize) + ")" : ""));
        JsonArrayInsertStringInplace(jTooltipArray, Get2DAStrRefString("baseitems", "Name", nBaseItem));
        JsonArrayInsertStringInplace(jIconArray, sIconResRef);
    }

    NWM_SetUserData("uuid_array", jUUIDArray);
    NWM_SetBind(PC_BIND_ICONS_ARRAY, jIconArray);
    NWM_SetBind(PC_BIND_NAMES_ARRAY, jNamesArray);
    NWM_SetBind(PC_BIND_TOOLTIPS_ARRAY, jTooltipArray);
    NWM_SetBind(PC_BIND_PROGRESS, JsonFloat(IntToFloat(nNumItems) / IntToFloat(PC_MAX_ITEMS)));
    NWM_SetBind(PC_BIND_PROGRESS_TOOLTIP, JsonString(IntToString(nNumItems) + " / " + IntToString(PC_MAX_ITEMS) + " Items Stored"));
}

// @NWMEVENT[PC_WINDOW_ID:NUI_EVENT_MOUSEUP:PC_BIND_ICON_GROUP]
// @NWMEVENT[PC_WINDOW_ID:NUI_EVENT_MOUSEUP:PC_BIND_NAME_LABEL]
void PC_WithdrawItem()
{
    int nItemIndex = NuiGetEventArrayIndex();

    if (nItemIndex < 0)
        return;

    object oPlayer = NWM_GetPlayer();
    string sPlayerUUID = GetObjectUUID(oPlayer);
    string sItemUUID = JsonArrayGetString(NWM_GetUserData("uuid_array"), nItemIndex);

    if (sItemUUID == "")
        return;

    sqlquery sql = SqlPrepareQueryCampaign(PC_SCRIPT_NAME, "SELECT item_data, item_baseitem, item_name FROM " + PC_TABLE_NAME + " WHERE player_uuid = @player_uuid AND item_uuid = @item_uuid;");
    SqlBindString(sql, "@player_uuid", sPlayerUUID);
    SqlBindString(sql, "@item_uuid", sItemUUID);

    if (SqlStep(sql))
    {
        json jItem = SqlGetJson(sql, 0);
        int nBaseItem = SqlGetInt(sql, 1);
        string sItemName = SqlGetString(sql, 2);

        if (GetBaseItemFitsInInventory(nBaseItem, oPlayer))
        {
            sql = SqlPrepareQueryCampaign(PC_SCRIPT_NAME, "DELETE FROM " + PC_TABLE_NAME + " WHERE player_uuid = @player_uuid AND item_uuid = @item_uuid;");
            SqlBindString(sql, "@player_uuid", sPlayerUUID);
            SqlBindString(sql, "@item_uuid", sItemUUID);
            SqlStep(sql);

            JsonToObject(jItem, GetLocation(oPlayer), oPlayer, PC_SAVE_ITEM_OBJECT_STATE);
            PC_UpdateItemList();
        }
        else
        {

            SendMessageToPC(oPlayer, "Item '" + sItemName + "' does not fit in your inventory!");
        }
    }
}

void PC_SetDepositMode(object oPlayer, int bEnabled)
{
    if (bEnabled)
    {
        EM_NWNXDispatchListInsert(oPlayer, PC_SCRIPT_NAME, "NWNX_ON_INPUT_DROP_ITEM_BEFORE");
        NWNX_Player_SetTlkOverride(oPlayer, 553, "Add to Persistent Chest");
        NWNX_Player_SetTlkOverride(oPlayer, 10469, "Deposited Item: <CUSTOM0>");
    }
    else
    {
        EM_NWNXDispatchListRemove(oPlayer, PC_SCRIPT_NAME, "NWNX_ON_INPUT_DROP_ITEM_BEFORE");
        NWNX_Player_SetTlkOverride(oPlayer, 553, "");
        NWNX_Player_SetTlkOverride(oPlayer, 10469, "");
    }
}
