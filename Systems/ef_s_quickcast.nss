/*
    Script: ef_s_quickcast
    Author: Daz

    Notes:
        Does not work with domain spells or spontaneous spells.
*/

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_profiler"
#include "ef_s_targetmode"
#include "ef_s_eventman"
#include "ef_s_playerdb"

#include "nwnx_player"
#include "nwnx_creature"
#include "nwnx_object"

const string QC_SCRIPT_NAME                         = "ef_s_quickcast";

const string QC_SPELLS_2DA_NAME                     = "spells";
const int QC_NUM_SPELL_LEVELS                       = 10;
const string QC_SPELL_TABLE_ARRAY                   = "SpellTableArray";
const string QC_LOAD_QUICKSLOTS_ARRAY               = "LoadQuickCastSlotsArray";
const string QC_BLANK_SLOT_TEXTURE                  = "gui_transprnt";
const string QC_OUTLINE_SLOT_TEXTURE                = "gui_inv_1x1_ol";

const int QC_NUM_ROWS                               = 6;
const int QC_NUM_SLOTS_PER_ROW                      = 8;
const float QC_SLOT_SIZE                            = 24.0f;
const int QC_MAX_NUM_SPELLS_IN_LIST                 = 200;

const string QC_MAIN_WINDOW_ID                      = "QUICKCAST";
const string QC_BIND_SLOT_ICON                      = "slot_icon_";
const string QC_BIND_SLOT_TOOLTIP                   = "slot_tooltip_";
const string QC_BIND_SLOT_USES                      = "slot_uses_";
const string QC_BIND_SLOT_USES_VISIBLE              = "slot_uses_visible_";
const string QC_BIND_SLOT_GREYED_OUT                = "slot_greyedout_";
const string QC_BIND_SLOT_MM_VISIBLE                = "slot_mm_visible_";
const string QC_BIND_SLOT_MM_REGION                 = "slot_mm_region_";
const string QC_BIND_BUTTON_PAGE                    = "btn_page_";
const string QC_BIND_BUTTON_PAGE_ONE                = "btn_page_1";
const string QC_BIND_BUTTON_PAGE_TWO                = "btn_page_2";
const string QC_BIND_BUTTON_PAGE_THREE              = "btn_page_3";
const string QC_BIND_BUTTON_PAGE_ONE_ENABLED        = "btn_page_1_enabled";
const string QC_BIND_BUTTON_PAGE_TWO_ENABLED        = "btn_page_2_enabled";
const string QC_BIND_BUTTON_PAGE_THREE_ENABLED      = "btn_page_3_enabled";
const string QC_BIND_BUTTON_EDIT_SLOTS              = "btn_edit_slots";
const string QC_BIND_BUTTON_TARGET                  = "btn_target";

const string QC_SETSLOT_WINDOW_ID                   = "QUICKCASTSETSLOT";
const string QC_BIND_CLASS_COMBO_ENTRIES            = "class_entries";
const string QC_BIND_CLASS_COMBO_SELECTED           = "class_selected";
const string QC_BIND_METAMAGIC_COMBO_ENTRIES        = "metamagic_entries";
const string QC_BIND_METAMAGIC_COMBO_SELECTED       = "metamagic_selected";
const string QC_BIND_SPELL_SEARCH_INPUT             = "spell_search_input";
const string QC_BIND_BUTTON_CLEAR_SPELL_SEARCH      = "btn_clear_spell";
const string QC_BIND_LIST_SPELL_ICON                = "list_icon";
const string QC_BIND_LIST_SPELL_NAME                = "list_name";
const string QC_BIND_LIST_SPELL_COLOR               = "list_color";
const string QC_BIND_BUTTON_COPY_MEMORIZED          = "btn_copy_memorized";

const string QC_SELECTTARGET_WINDOW_ID              = "QUICKCASTSELECTTARGET";
const string QC_BIND_TARGETTYPE_COMBO_ENTRIES       = "targettype_entries";
const string QC_BIND_TARGETTYPE_COMBO_SELECTED      = "targettype_selected";
const string QC_BIND_BUTTON_CUSTOM_TARGET           = "btn_customtarget";

const string QC_CAST_TARGET_MODE                    = "QCCastTargetMode";
const string QC_CUSTOM_TARGET_TARGET_MODE           = "QCCustomTargetTargetMode";

const int QC_PLAYER_TARGET_TYPE_MANUAL              = 0;
const int QC_PLAYER_TARGET_TYPE_CUSTOM              = 1;
const int QC_PLAYER_TARGET_TYPE_NEAREST_HOSTILE     = 2;

const int QC_DRAGMODE_MOVE_SLOT                     = 1;
const int QC_DRAGMODE_SET_SLOT                      = 2;

string QC_GetSpellDataTable();
string QC_GetClassSpellTableTable();
string QC_GetChildSpellsTable();
string QC_GetPlayerKnownSpellsTable(object oPlayer, int bEscape = TRUE);
string QC_GetPlayerMemorizedSpellsTable(object oPlayer, int bEscape = TRUE);
string QC_GetPlayerQuickCastTable();

void QC_InitializeSpellData();
void QC_InitializePlayerQuickCastTable(object oPlayer);
int QC_GetMasterSpell(int nSpellId);
int QC_GetSpellLevel(string sSpellTable, int nSpellId);
void QC_InsertQuickCastSlot(object oPlayer, int nPageId, int nSlotId, int nMultiClass, int nSpellId, int nMetaMagic, string sTooltip);
void QC_DeleteQuickCastSlot(object oPlayer, int nPageId, int nSlotId);
void QC_LoadQuickCastSlots(object oPlayer, int nPageId);
void QC_InitializeMetaMagicCombo(object oPlayer);
void QC_InitializeClassCombo(object oPlayer);
void QC_PreparePlayerKnownSpells(object oPlayer);
void QC_DeletePlayerKnownSpellsTable(object oPlayer);
void QC_PreparePlayerMemorizedSpells(object oPlayer);
void QC_DeletePlayerMemorizedSpellsTable(object oPlayer);
int QC_GetPlayerMaxSpellLevel(object oPlayer, int nMultiClass);
int QC_GetMetaMagicLevelAdjustment(int nMetaMagic);
sqlquery QC_GetKnownSpellsList(object oPlayer, int nMultiClass, int nMetaMagic, string sSearch);
sqlquery QC_GetClassSpellList(object oPlayer, int nMultiClass, int nMetaMagic, string sSearch);
void QC_UpdateSpellList();
string QC_GetMetaMagicTooltip(int nMetaMagic);
json QC_GetMetaMagicRect(int nMetaMagic);
void QC_SetSpellUsesState(object oPlayer, int nSlotId, int nSpellId, int nMultiClass, int nMetaMagic);
void QC_SetSlot(object oPlayer, int nSlotId, int nSpellId, int nMultiClass, int nMetaMagic);
void QC_UpdateSlot(object oPlayer, int nSlotId, int nSpellId, int nMultiClass, int nMetaMagic, string sTooltip);
void QC_BlankSlot(object oPlayer, int nSlotId);
int QC_GetSpellTargetType(int nSpellId);
void QC_SetPlayerPageId(object oPlayer, int nPageId);
int QC_GetPlayerPageId(object oPlayer);
void QC_SetPage(object oPlayer, int nPageId);
void QC_RefreshAllSpellUses(object oPlayer);
int QC_GetHasMemorizedSpell(object oPlayer, int nMulticlass, int nSpellId, int nMetaMagic);
int QC_GetIsSpellCaster(object oPlayer);
void QC_SetCustomTarget(object oTarget, vector vPosition);
object QC_GetCustomTargetObject();
vector QC_GetCustomTargetPosition();
int QC_IsValidCustomTarget(object oTarget, int nTargetType);
void QC_InitializeTargetTypeCombo();
void QC_SetPlayerTargetType(int nTargetType);
int QC_GetPlayerTargetType();
int QC_GetSpellHasTargetType(int nSpellId, int nTargetType);
void QC_SetDragModeData(int nDragMode, json jData);
int QC_GetDragModeType();
json QC_GetDragModeData();
void QC_ClearDragMode();

// @CORE[EF_SYSTEM_INIT]
void QC_Init()
{
    QC_InitializeSpellData();
    IntArray_SetSize(GetDataObject(QC_SCRIPT_NAME), QC_LOAD_QUICKSLOTS_ARRAY, QC_NUM_ROWS * QC_NUM_SLOTS_PER_ROW);
}

// @NWMWINDOW[QC_MAIN_WINDOW_ID]
json QC_CreateMainWindow()
{
    float fWidth = ((QC_SLOT_SIZE + 4.0f) * IntToFloat(QC_NUM_SLOTS_PER_ROW)) + 10.0f;
    float fHeight = 33.0f + ((QC_SLOT_SIZE + 8.0f) * IntToFloat(QC_NUM_ROWS + 1)) + 8.0f;
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, fWidth, fHeight));
    NB_SetWindowTitle(JsonString("QuickCast"));
    NB_SetWindowTransparent(JsonBool(TRUE));
    NB_SetWindowBorder(JsonBool(FALSE));
        NB_StartColumn();
            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("1")));
                    NB_SetId(QC_BIND_BUTTON_PAGE_ONE);
                    NB_SetTooltip(JsonString("Page One"));
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_PAGE_ONE_ENABLED));
                    NB_SetDimensions((QC_SLOT_SIZE + 4.0f), (QC_SLOT_SIZE + 4.0f));
                NB_End();
                NB_StartElement(NuiButton(JsonString("2")));
                    NB_SetId(QC_BIND_BUTTON_PAGE_TWO);
                    NB_SetTooltip(JsonString("Page Two"));
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_PAGE_TWO_ENABLED));
                    NB_SetDimensions((QC_SLOT_SIZE + 4.0f), (QC_SLOT_SIZE + 4.0f));
                NB_End();
                NB_StartElement(NuiButton(JsonString("3")));
                    NB_SetId(QC_BIND_BUTTON_PAGE_THREE);
                    NB_SetTooltip(JsonString("Page Three"));
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_PAGE_THREE_ENABLED));
                    NB_SetDimensions((QC_SLOT_SIZE + 4.0f), (QC_SLOT_SIZE + 4.0f));
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("E")));
                    NB_SetId(QC_BIND_BUTTON_EDIT_SLOTS);
                    NB_SetTooltip(JsonString("Edit Slots"));
                    NB_SetDimensions((QC_SLOT_SIZE + 4.0f), (QC_SLOT_SIZE + 4.0f));
                NB_End();
                NB_StartElement(NuiButton(JsonString("T")));
                    NB_SetId(QC_BIND_BUTTON_TARGET);
                    NB_SetTooltip(JsonString("Select Target"));
                    NB_SetDimensions((QC_SLOT_SIZE + 4.0f), (QC_SLOT_SIZE + 4.0f));
                NB_End();
            NB_End();

            int nRow;
            for (nRow = 0; nRow < QC_NUM_ROWS; nRow++)
            {
                NB_StartRow();

                    NB_AddSpacer();

                    int nSlot;
                    for (nSlot = 0; nSlot < QC_NUM_SLOTS_PER_ROW; nSlot++)
                    {
                        string sSlot = IntToString((nRow * QC_NUM_SLOTS_PER_ROW) + nSlot);
                        NB_StartElement(NuiImage(NuiBind(QC_BIND_SLOT_ICON + sSlot), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_SetDimensions(QC_SLOT_SIZE, QC_SLOT_SIZE);
                            NB_SetId(QC_BIND_SLOT_ICON + sSlot);
                            NB_SetTooltip(NuiBind(QC_BIND_SLOT_TOOLTIP + sSlot));
                            NB_StartDrawList(JsonBool(FALSE));
                                json jUsesBindVisible = NuiBind(QC_BIND_SLOT_USES_VISIBLE + sSlot);
                                json jUsesBindText = NuiBind(QC_BIND_SLOT_USES + sSlot);
                                NB_AddDrawListItem(NuiDrawListText(jUsesBindVisible, NuiColor(0, 0, 0), NuiRect(0.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), jUsesBindText));
                                NB_AddDrawListItem(NuiDrawListText(jUsesBindVisible, NuiColor(0, 0, 0), NuiRect(1.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), jUsesBindText));
                                NB_AddDrawListItem(NuiDrawListText(jUsesBindVisible, NuiColor(0, 0, 0), NuiRect(3.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), jUsesBindText));
                                NB_AddDrawListItem(NuiDrawListText(jUsesBindVisible, NuiColor(0, 0, 0), NuiRect(4.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), jUsesBindText));
                                NB_AddDrawListItem(NuiDrawListText(jUsesBindVisible, NuiColor(0, 0, 0), NuiRect(2.0f, -1.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), jUsesBindText));
                                NB_AddDrawListItem(NuiDrawListText(jUsesBindVisible, NuiColor(0, 0, 0), NuiRect(2.0f, -0.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), jUsesBindText));
                                NB_AddDrawListItem(NuiDrawListText(jUsesBindVisible, NuiColor(0, 255, 0), NuiRect(2.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), jUsesBindText));
                                NB_AddDrawListItem(
                                    NuiDrawListImage(
                                        NuiBind(QC_BIND_SLOT_GREYED_OUT + sSlot), JsonString("gui_transprnt"),
                                        NuiRect(0.0f, 0.0f, QC_SLOT_SIZE, QC_SLOT_SIZE),
                                        JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_AddDrawListItem(
                                    NuiDrawListImageRegion(
                                        NuiDrawListImage(
                                            NuiBind(QC_BIND_SLOT_MM_VISIBLE + sSlot), JsonString("gui_icon_metamag"),
                                            NuiRect(QC_SLOT_SIZE - 8.0f, QC_SLOT_SIZE - 8.0f, 8.0f, 8.0f),
                                            JsonInt(NUI_ASPECT_STRETCH),  JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
                                        NuiBind(QC_BIND_SLOT_MM_REGION + sSlot)));
                                NB_AddDrawListItem(
                                    NuiDrawListImage(
                                        JsonBool(TRUE), JsonString(QC_OUTLINE_SLOT_TEXTURE),
                                        NuiRect(0.0f, 0.0f, QC_SLOT_SIZE, QC_SLOT_SIZE),
                                        JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE),
                                        NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER));
                            NB_End();
                        NB_End();
                    }

                    NB_AddSpacer();

                NB_End();
            }

        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_CLOSE:NUI_WINDOW_ROOT_GROUP]
void QC_MainWindowClose()
{
    object oPlayer = OBJECT_SELF;

    // Most events get fired in ef_s_eventman from a sqlite query
    // which apparently locks the table so we can't delete it
    // So we delay table deletion until the next frame...
    DelayCommand(0.0f, QC_DeletePlayerKnownSpellsTable(oPlayer));
    DelayCommand(0.0f, QC_DeletePlayerMemorizedSpellsTable(oPlayer));

    if (NWM_GetIsWindowOpen(oPlayer, QC_SETSLOT_WINDOW_ID))
        NWM_CloseWindow(oPlayer, QC_SETSLOT_WINDOW_ID);

    if (NWM_GetIsWindowOpen(oPlayer, QC_SELECTTARGET_WINDOW_ID))
        NWM_CloseWindow(oPlayer, QC_SELECTTARGET_WINDOW_ID);
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_MOUSEDOWN:QC_BIND_SLOT_ICON]
void QC_SlotMouseDown()
{
    object oPlayer = OBJECT_SELF;
    int nSlotId = NuiGetIdFromElement(NuiGetEventElement(), QC_BIND_SLOT_ICON);
    int nMouseButton = NuiGetMouseButton(NuiGetEventPayload());

    if (NWM_GetIsWindowOpen(oPlayer, QC_SETSLOT_WINDOW_ID))
    {
        if (nMouseButton == NUI_MOUSE_BUTTON_LEFT)
        {
            QC_SetDragModeData(QC_DRAGMODE_MOVE_SLOT, JsonInt(nSlotId));
            NWNX_Player_PlaySound(oPlayer, "it_pickup");
        }
    }
    else
    {
        if (NWM_GetBindBool(QC_BIND_SLOT_GREYED_OUT + IntToString(nSlotId)) || GetIsDead(oPlayer) || !GetCommandable(oPlayer))
        {
            NWNX_Player_PlaySound(oPlayer, "gui_failspell");
            return;
        }

        string sQuery = "SELECT spellid, multiclass, metamagic FROM " + QC_GetPlayerQuickCastTable() + " WHERE pageid = @pageid AND slotid = @slotid;";
        sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
        SqlBindInt(sql, "@pageid", QC_GetPlayerPageId(oPlayer));
        SqlBindInt(sql, "@slotid", nSlotId);

        if (SqlStep(sql))
        {
            int nSpellId = SqlGetInt(sql, 0);
            int nMultiClass = SqlGetInt(sql, 1);
            int nMetaMagic = SqlGetInt(sql, 2);
            int nSpellTargetType = QC_GetSpellTargetType(nSpellId);

            if (nMouseButton == NUI_MOUSE_BUTTON_LEFT)
            {
                if (nSpellTargetType == 0x01)
                    NWNX_Creature_AddCastSpellActions(oPlayer, oPlayer, GetPosition(oPlayer), nSpellId, nMultiClass, nMetaMagic);
                else
                {
                    int nPlayerTargetType = QC_GetPlayerTargetType();

                    switch (QC_GetPlayerTargetType())
                    {
                        case QC_PLAYER_TARGET_TYPE_CUSTOM:
                        {
                            object oTarget = QC_GetCustomTargetObject();
                            if (QC_IsValidCustomTarget(oTarget, nSpellTargetType))
                                NWNX_Creature_AddCastSpellActions(oPlayer, oTarget, QC_GetCustomTargetPosition(), nSpellId, nMultiClass, nMetaMagic);
                            else
                                NWNX_Player_PlaySound(oPlayer, "gui_failspell");
                            break;
                        }

                        case QC_PLAYER_TARGET_TYPE_NEAREST_HOSTILE:
                        {
                            object oNearestHostile = GetNearestCreature(CREATURE_TYPE_IS_ALIVE, TRUE, oPlayer, 1,
                                                                        CREATURE_TYPE_PERCEPTION, PERCEPTION_SEEN_AND_HEARD,
                                                                        CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY);
                            if (QC_IsValidCustomTarget(oNearestHostile, nSpellTargetType))
                                NWNX_Creature_AddCastSpellActions(oPlayer, oNearestHostile, GetPosition(oNearestHostile), nSpellId, nMultiClass, nMetaMagic);
                            else
                                NWNX_Player_PlaySound(oPlayer, "gui_failspell");
                            break;
                        }

                        default:
                        {
                            int nValidObjectTypes;
                            if (nSpellTargetType & 0x02) nValidObjectTypes |= OBJECT_TYPE_CREATURE;
                            if (nSpellTargetType & 0x04) nValidObjectTypes |= OBJECT_TYPE_TILE;
                            if (nSpellTargetType & 0x10) nValidObjectTypes |= OBJECT_TYPE_DOOR;
                            if (nSpellTargetType & 0x20) nValidObjectTypes |= OBJECT_TYPE_PLACEABLE;
                            if (nSpellTargetType & 0x40) nValidObjectTypes |= OBJECT_TYPE_TRIGGER;

                            NWM_SetUserDataInt("spellid", nSpellId);
                            NWM_SetUserDataInt("multiclass", nMultiClass);
                            NWM_SetUserDataInt("metamagic", nMetaMagic);
                            NWM_SetUserDataInt("targettype", nSpellTargetType);

                            TargetMode_SetSpellData(oPlayer, nSpellId);
                            TargetMode_Enter(oPlayer, QC_CAST_TARGET_MODE, nValidObjectTypes);
                            break;
                        }
                    }
                }
            }
            else if (nMouseButton == NUI_MOUSE_BUTTON_RIGHT)
            {
                if (nSpellTargetType & 0x01)
                    NWNX_Creature_AddCastSpellActions(oPlayer, oPlayer, GetPosition(oPlayer), nSpellId, nMultiClass, nMetaMagic);
                else
                    NWNX_Player_PlaySound(oPlayer, "gui_failspell");
            }
        }
    }
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_MOUSEUP:QC_BIND_SLOT_ICON]
void QC_SlotMouseUp()
{
    object oPlayer = OBJECT_SELF;
    int nSlotId = NuiGetIdFromElement(NuiGetEventElement(), QC_BIND_SLOT_ICON);
    int nMouseButton = NuiGetMouseButton(NuiGetEventPayload());

    if (NWM_GetIsWindowOpen(oPlayer, QC_SETSLOT_WINDOW_ID))
    {
        switch (nMouseButton)
        {
            case NUI_MOUSE_BUTTON_LEFT:
            {
                int nDragModeType = QC_GetDragModeType();
                json jDragModeData = QC_GetDragModeData();

                switch (nDragModeType)
                {
                    case QC_DRAGMODE_MOVE_SLOT:
                    {
                        int nPreviousSlotId = JsonGetInt(jDragModeData);
                        if (nPreviousSlotId != nSlotId)
                        {
                            int nPageId = QC_GetPlayerPageId(oPlayer);
                            string sQuery = "SELECT spellid, multiclass, metamagic FROM " + QC_GetPlayerQuickCastTable() + " WHERE pageid = @pageid AND slotid = @slotid;";
                            sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
                            SqlBindInt(sql, "@pageid", nPageId);
                            SqlBindInt(sql, "@slotid", nPreviousSlotId);

                            if (SqlStep(sql))
                            {
                                int nPreviousSpellId = SqlGetInt(sql, 0);
                                int nPreviousMultiClass = SqlGetInt(sql, 1);
                                int nPreviousMetaMagic = SqlGetInt(sql, 2);

                                sql = SqlPrepareQueryObject(oPlayer, sQuery);
                                SqlBindInt(sql, "@pageid", nPageId);
                                SqlBindInt(sql, "@slotid", nSlotId);

                                if (SqlStep(sql))
                                {
                                    QC_SetSlot(oPlayer, nPreviousSlotId, SqlGetInt(sql, 0), SqlGetInt(sql, 1), SqlGetInt(sql, 2));
                                }
                                else
                                {
                                    QC_DeleteQuickCastSlot(oPlayer, nPageId, nPreviousSlotId);
                                    QC_BlankSlot(oPlayer, nPreviousSlotId);
                                }

                                QC_SetSlot(oPlayer, nSlotId, nPreviousSpellId, nPreviousMultiClass, nPreviousMetaMagic);
                                NWNX_Player_PlaySound(oPlayer, "it_paper");
                            }
                        }

                        QC_ClearDragMode();
                        break;
                    }

                    case QC_DRAGMODE_SET_SLOT:
                    {
                        int nSpellId = JsonObjectGetInt(jDragModeData, "spellid");
                        int nMultiClass = JsonObjectGetInt(jDragModeData, "multiclass");
                        int nMetaMagic = JsonObjectGetInt(jDragModeData, "metamagic");

                        QC_SetSlot(oPlayer, nSlotId, nSpellId, nMultiClass, nMetaMagic);
                        NWNX_Player_PlaySound(oPlayer, "gui_learnspell");
                        QC_ClearDragMode();
                        break;
                    }
                }
                break;
            }

            case NUI_MOUSE_BUTTON_RIGHT:
            {
                QC_DeleteQuickCastSlot(oPlayer, QC_GetPlayerPageId(oPlayer), nSlotId);
                QC_BlankSlot(oPlayer, nSlotId);
                NWNX_Player_PlaySound(oPlayer, "gui_spell_erase");
                break;
            }
        }
    }
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_PAGE]
void QC_ButtonClickPage()
{
    object oPlayer = OBJECT_SELF;
    int nPageId = NuiGetIdFromElement(NuiGetEventElement(), QC_BIND_BUTTON_PAGE) - 1;
    if (nPageId >= 0)
        QC_SetPage(oPlayer, nPageId);
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_EDIT_SLOTS]
void QC_ButtonClickEditSlots()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_ToggleWindow(oPlayer, QC_SETSLOT_WINDOW_ID))
    {
        QC_PreparePlayerKnownSpells(oPlayer);
        QC_PreparePlayerMemorizedSpells(oPlayer);

        QC_InitializeClassCombo(oPlayer);
        QC_InitializeMetaMagicCombo(oPlayer);

        QC_UpdateSpellList();

        NWM_SetBindWatch(QC_BIND_SPELL_SEARCH_INPUT, TRUE);
        NWM_SetBindWatch(QC_BIND_CLASS_COMBO_SELECTED, TRUE);
        NWM_SetBindWatch(QC_BIND_METAMAGIC_COMBO_SELECTED, TRUE);
    }
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_TARGET]
void QC_ButtonClickSelectTargetWindow()
{
    object oPlayer = OBJECT_SELF;
    int nTargetType = QC_GetPlayerTargetType();

    if (NWM_ToggleWindow(oPlayer, QC_SELECTTARGET_WINDOW_ID))
    {
        QC_InitializeTargetTypeCombo();
        NWM_SetBindBool(QC_BIND_BUTTON_CUSTOM_TARGET, nTargetType == QC_PLAYER_TARGET_TYPE_CUSTOM);
        NWM_SetBindInt(QC_BIND_TARGETTYPE_COMBO_SELECTED, nTargetType);
        NWM_SetBindWatch(QC_BIND_TARGETTYPE_COMBO_SELECTED, TRUE);
    }
}

// @NWMWINDOW[QC_SETSLOT_WINDOW_ID]
json QC_CreateSetSlotWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 500.0f, 400.0f));
    NB_SetWindowTitle(JsonString("QuickCast: Edit Slots"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartElement(NuiCombo(NuiBind(QC_BIND_CLASS_COMBO_ENTRIES), NuiBind(QC_BIND_CLASS_COMBO_SELECTED)));
                    NB_SetDimensions(125.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiCombo(NuiBind(QC_BIND_METAMAGIC_COMBO_ENTRIES), NuiBind(QC_BIND_METAMAGIC_COMBO_SELECTED)));
                    NB_SetDimensions(125.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiTextEdit(JsonString("Search spells..."), NuiBind(QC_BIND_SPELL_SEARCH_INPUT), 64, FALSE, FALSE));
                    NB_SetHeight(32.0f);
                NB_End();
                NB_StartElement(NuiButton(JsonString("X")));
                    NB_SetId(QC_BIND_BUTTON_CLEAR_SPELL_SEARCH);
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_CLEAR_SPELL_SEARCH));
                    NB_SetDimensions(32.0f, 32.0f);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartList(NuiBind(QC_BIND_LIST_SPELL_ICON), 16.0f);
                    NB_StartListTemplateCell(16.0f, FALSE);
                        NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                            NB_SetMargin(0.0f);
                            NB_StartElement(NuiImage(NuiBind(QC_BIND_LIST_SPELL_ICON), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_SetDimensions(16.0f, 16.0f);
                                NB_SetId(QC_BIND_LIST_SPELL_NAME);
                                NB_SetForegroundColor(NuiBind(QC_BIND_LIST_SPELL_COLOR));
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(300.0f, TRUE);
                        NB_StartElement(NuiSpacer());
                            NB_SetId(QC_BIND_LIST_SPELL_NAME);
                            NB_StartDrawList(JsonBool(FALSE));
                                NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiBind(QC_BIND_LIST_SPELL_COLOR), NuiRect(0.0f, 0.0f, 300.0f, 16.0f), NuiBind(QC_BIND_LIST_SPELL_NAME), NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_OFF));
                                NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiColor(50, 150, 250), NuiRect(0.0f, 0.0f, 300.0f, 16.0f), NuiBind(QC_BIND_LIST_SPELL_NAME), NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER));
                            NB_End();
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
            NB_StartRow();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("Copy Memorized")));
                    NB_SetId(QC_BIND_BUTTON_COPY_MEMORIZED);
                    NB_SetDimensions(150.0f, 32.0f);
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_WATCH:QC_BIND_CLASS_COMBO_SELECTED]
void QC_WatchClassCombo()
{
    QC_UpdateSpellList();
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_WATCH:QC_BIND_METAMAGIC_COMBO_SELECTED]
void QC_WatchMetaMagicCombo()
{
    QC_UpdateSpellList();
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_WATCH:QC_BIND_SPELL_SEARCH_INPUT]
void QC_WatchSpellSearch()
{
    NWM_SetBindBool(QC_BIND_BUTTON_CLEAR_SPELL_SEARCH, GetStringLength(NWM_GetBindString(QC_BIND_SPELL_SEARCH_INPUT)));
    QC_UpdateSpellList();
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_CLEAR_SPELL_SEARCH]
void QC_ClickClearSearchButton()
{
    NWM_SetBindString(QC_BIND_SPELL_SEARCH_INPUT, "");
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_MOUSEDOWN:QC_BIND_LIST_SPELL_NAME]
void QC_MouseDownSpellList()
{
    object oPlayer = OBJECT_SELF;
    int nIndex = NuiGetEventArrayIndex();

    if (nIndex != -1)
    {
        int nSpellId = JsonArrayGetInt(NWM_GetUserData("spellids"), nIndex);
        int nMultiClass = NWM_GetBindInt(QC_BIND_CLASS_COMBO_SELECTED);
        int nMetaMagic = NWM_GetBindInt(QC_BIND_METAMAGIC_COMBO_SELECTED);

        if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
        {
            json jData = JsonObject();
                 jData = JsonObjectSetInt(jData, "spellid", nSpellId);
                 jData = JsonObjectSetInt(jData, "multiclass", nMultiClass);
                 jData = JsonObjectSetInt(jData, "metamagic", nMetaMagic);

            QC_SetDragModeData(QC_DRAGMODE_SET_SLOT, jData);
            NWNX_Player_PlaySound(oPlayer, "it_pickup");
        }
    }
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_COPY_MEMORIZED]
void QC_ClickCopyMemorizedButton()
{
    object oPlayer = OBJECT_SELF;
    int nMultiClass = NWM_GetBindInt(QC_BIND_CLASS_COMBO_SELECTED);
    int nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);
    int bMemorizesSpells = StringToInt(Get2DAString("classes", "MemorizesSpells", nClassType));

    if (!bMemorizesSpells)
        return;

    if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        int nPageId = QC_GetPlayerPageId(oPlayer);
        string sQuery = "DELETE FROM " + QC_GetPlayerQuickCastTable() + " WHERE pageid = @pageid;";
        sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
        SqlBindInt(sql, "@pageid", nPageId);
        SqlStep(sql);
        QC_LoadQuickCastSlots(oPlayer, nPageId);

        sQuery = "SELECT spellid, metamagic FROM " + QC_GetPlayerMemorizedSpellsTable(oPlayer) + " WHERE multiclass = @multiclass;";
        sql = SqlPrepareQueryModule(sQuery);
        SqlBindInt(sql, "@multiclass", nMultiClass);

        int nSlotId = 0;
        while (SqlStep(sql))
        {
            int nSpellId = SqlGetInt(sql, 0);
            int nMetaMagic = SqlGetInt(sql, 1);

            int bIsMasterSpell = FALSE;
            string sGetChildSpellsQuery = "SELECT childid FROM " + QC_GetChildSpellsTable() + " WHERE masterid = @masterid;";
            sqlquery sqlGetChildSpells = SqlPrepareQueryModule(sGetChildSpellsQuery);
            SqlBindInt(sqlGetChildSpells, "@masterid", QC_GetMasterSpell(nSpellId));

            while (SqlStep(sqlGetChildSpells))
            {
                bIsMasterSpell = TRUE;
                int nChildSpellId = SqlGetInt(sqlGetChildSpells, 0);
                QC_SetSlot(oPlayer, nSlotId, nChildSpellId, nMultiClass, nMetaMagic);
                nSlotId++;
            }

            if (!bIsMasterSpell)
            {
                QC_SetSlot(oPlayer, nSlotId, nSpellId, nMultiClass, nMetaMagic);
                nSlotId++;
            }
        }
    }
}

// @NWMWINDOW[QC_SELECTTARGET_WINDOW_ID]
json QC_CreateSelectTargetWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 300.0f, 200.0f));
    NB_SetWindowTitle(JsonString("QuickCast: Select Target"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartElement(NuiCombo(NuiBind(QC_BIND_TARGETTYPE_COMBO_ENTRIES), NuiBind(QC_BIND_TARGETTYPE_COMBO_SELECTED)));
                    NB_SetDimensions(200.0f, 32.0f);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("Custom Target")));
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_CUSTOM_TARGET));
                    NB_SetId(QC_BIND_BUTTON_CUSTOM_TARGET);
                    NB_SetDimensions(150.0f, 32.0f);
                NB_End();
                NB_AddSpacer();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[QC_SELECTTARGET_WINDOW_ID:NUI_EVENT_WATCH:QC_BIND_TARGETTYPE_COMBO_SELECTED]
void QC_WatchTargetTypeCombo()
{
    object oPlayer = OBJECT_SELF;
    int nTargetType = NWM_GetBindInt(QC_BIND_TARGETTYPE_COMBO_SELECTED);

    NWM_SetBindBool(QC_BIND_BUTTON_CUSTOM_TARGET, nTargetType == QC_PLAYER_TARGET_TYPE_CUSTOM);

    if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        QC_SetPlayerTargetType(nTargetType);
    }
}

// @NWMEVENT[QC_SELECTTARGET_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_CUSTOM_TARGET]
void QC_ButtonClickCustomTarget()
{
    object oPlayer = OBJECT_SELF;
    TargetMode_Enter(oPlayer, QC_CUSTOM_TARGET_TARGET_MODE, OBJECT_TYPE_CREATURE | OBJECT_TYPE_TILE | OBJECT_TYPE_DOOR | OBJECT_TYPE_PLACEABLE | OBJECT_TYPE_TRIGGER);
}

// @PMBUTTON[QuickCast Menu:Cast real quick]
void QC_ShowWindow()
{
    object oPlayer = OBJECT_SELF;

    if (QC_GetIsSpellCaster(oPlayer))
    {
        if (NWM_ToggleWindow(oPlayer, QC_MAIN_WINDOW_ID))
        {
            QC_InitializePlayerQuickCastTable(oPlayer);
            QC_SetCustomTarget(OBJECT_INVALID, Vector());
            QC_SetPage(oPlayer, QC_GetPlayerPageId(oPlayer));
        }
    }
    else
        SendMessageToPC(oPlayer, "You must be able to cast spells to use the QuickCast Menu.");
}

// @NWNX[NWNX_ON_DECREMENT_SPELL_COUNT_AFTER]
void QC_DecrementSpellCount()
{
    object oPlayer = OBJECT_SELF;
    if (GetIsPC(oPlayer) && NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        int nSpellId = EM_NWNXGetInt("SPELL_ID");
        int nMultiClass = EM_NWNXGetInt("CLASS");
        int nMetaMagic = EM_NWNXGetInt("METAMAGIC");
        int nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);
        int bMemorizesSpells = StringToInt(Get2DAString("classes", "MemorizesSpells", nClassType));

        sqlquery sql;
        if (bMemorizesSpells)
        {
            int nMasterSpellId = QC_GetMasterSpell(nSpellId);

            if (nSpellId == nMasterSpellId)
            {
                string sQuery = "SELECT slotid FROM " + QC_GetPlayerQuickCastTable() + " " +
                                "WHERE pageid = @pageid AND multiclass = @multiclass AND spellid = @spellid AND metamagic = @metamagic;";
                sql = SqlPrepareQueryObject(oPlayer, sQuery);
                SqlBindInt(sql, "@pageid", QC_GetPlayerPageId(oPlayer));
                SqlBindInt(sql, "@multiclass", nMultiClass);
                SqlBindInt(sql, "@spellid", nSpellId);
                SqlBindInt(sql, "@metamagic", nMetaMagic);
            }
            else
            {
                string sQuery = "SELECT slotid FROM " + QC_GetPlayerQuickCastTable() + " " +
                                "WHERE pageid = @pageid AND multiclass = @multiclass AND masterid = @masterid AND metamagic = @metamagic;";
                sql = SqlPrepareQueryObject(oPlayer, sQuery);
                SqlBindInt(sql, "@pageid", QC_GetPlayerPageId(oPlayer));
                SqlBindInt(sql, "@multiclass", nMultiClass);
                SqlBindInt(sql, "@masterid", QC_GetMasterSpell(nSpellId));
                SqlBindInt(sql, "@metamagic", nMetaMagic);
            }
        }
        else
        {
            int nSpellLevel = QC_GetSpellLevel(Get2DAString("classes", "SpellTableColumn", nClassType), QC_GetMasterSpell(nSpellId)) + QC_GetMetaMagicLevelAdjustment(nMetaMagic);
            string sQuery = "SELECT slotid FROM " + QC_GetPlayerQuickCastTable() + " " +
                            "WHERE pageid = @pageid AND multiclass = @multiclass AND spelllevel = @spelllevel;";
            sql = SqlPrepareQueryObject(oPlayer, sQuery);
            SqlBindInt(sql, "@pageid", QC_GetPlayerPageId(oPlayer));
            SqlBindInt(sql, "@multiclass", nMultiClass);
            SqlBindInt(sql, "@spelllevel", nSpellLevel);
        }

        while (SqlStep(sql))
        {
            QC_SetSpellUsesState(oPlayer, SqlGetInt(sql, 0), nSpellId, nMultiClass, nMetaMagic);
        }
    }
}

// @REST[REST_EVENTTYPE_REST_FINISHED]
void QC_OnPlayerRestFinished()
{
    QC_RefreshAllSpellUses(OBJECT_SELF);
}

// @REST[REST_EVENTTYPE_REST_CANCELLED]
void QC_OnPlayerRestCancelled()
{
    QC_RefreshAllSpellUses(OBJECT_SELF);
}

// @TARGETMODE[QC_CAST_TARGET_MODE]
void QC_OnPlayerTarget()
{
    object oPlayer = OBJECT_SELF;
    object oTarget = GetTargetingModeSelectedObject();

    if (oTarget == OBJECT_INVALID)
        return;

    if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        int nSpellId = NWM_GetUserDataInt("spellid");
        int nMultiClass = NWM_GetUserDataInt("multiclass");
        int nMetaMagic = NWM_GetUserDataInt("metamagic");
        int nTargetType = NWM_GetUserDataInt("targettype");

        if (oPlayer == oTarget && !(nTargetType & 0x01))
            return;

        NWNX_Creature_AddCastSpellActions(oPlayer, oTarget, GetTargetingModeSelectedPosition(), nSpellId, nMultiClass, nMetaMagic);
    }
}

// @TARGETMODE[QC_CUSTOM_TARGET_TARGET_MODE]
void QC_OnPlayerCustomTarget()
{
    object oPlayer = OBJECT_SELF;
    object oTarget = GetTargetingModeSelectedObject();

    if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        QC_SetCustomTarget(oTarget, GetTargetingModeSelectedPosition());
    }
}

// @CONSOLE[QuickCastClearPage::]
void QC_ConsoleClearPage()
{
    object oPlayer = OBJECT_SELF;
    int nPageId = QC_GetPlayerPageId(oPlayer);
    string sQuery = "DELETE FROM " + QC_GetPlayerQuickCastTable() + " WHERE pageid = @pageid;";
    sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
    SqlBindInt(sql, "@pageid", nPageId);
    SqlStep(sql);

    if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        QC_LoadQuickCastSlots(oPlayer, nPageId);
    }
}

string QC_GetSpellDataTable()
{
    return QC_SCRIPT_NAME + "_spelldata";
}

string QC_GetClassSpellTableTable()
{
    return QC_SCRIPT_NAME + "_classspelltables";
}

string QC_GetChildSpellsTable()
{
    return QC_SCRIPT_NAME + "_childspells";
}

string QC_GetPlayerKnownSpellsTable(object oPlayer, int bEscape = TRUE)
{
    return (bEscape ? "'" : "") + QC_SCRIPT_NAME + "_playerknownspells_" + GetObjectUUID(oPlayer) + (bEscape ? "'" : "");
}

string QC_GetPlayerMemorizedSpellsTable(object oPlayer, int bEscape = TRUE)
{
    return (bEscape ? "'" : "") + QC_SCRIPT_NAME + "_playermemorizedspells_" + GetObjectUUID(oPlayer) + (bEscape ? "'" : "");
}

string QC_GetPlayerQuickCastTable()
{
    return QC_SCRIPT_NAME + "_data";
}

void QC_InitializeSpellData()
{
    object oDataObject = GetDataObject(QC_SCRIPT_NAME);
    int nClass, nNumClasses = Get2DARowCount("classes");
    for (nClass = 0; nClass < nNumClasses; nClass++)
    {
        string sSpellTable = Get2DAString("classes", "SpellTableColumn", nClass);

        if (sSpellTable == "")
            continue;

        if (StringArray_Contains(oDataObject, QC_SPELL_TABLE_ARRAY, sSpellTable) == -1)
            StringArray_Insert(oDataObject, QC_SPELL_TABLE_ARRAY, sSpellTable);
    }

    int nSpellTableArraySize = StringArray_Size(oDataObject, QC_SPELL_TABLE_ARRAY);

    string sQuery = "CREATE TABLE IF NOT EXISTS " + QC_GetSpellDataTable() + "(" +
                    "spellid INTEGER NOT NULL PRIMARY KEY, " +
                    "name TEXT NOT NULL COLLATE NOCASE, " +
                    "icon TEXT NOT NULL, " +
                    "metamagic INTEGER NOT NULL, " +
                    "targettype INTEGER NOT NULL, " +
                    "master INTEGER NOT NULL, " +
                    "hostile INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + QC_GetClassSpellTableTable() + "(" +
             "spelltable TEXT NOT NULL, " +
             "spellid INTEGER NOT NULL, " +
             "spelllevel INTEGER NOT NULL, " +
             "PRIMARY KEY(spelltable, spellid));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + QC_GetChildSpellsTable() + "(" +
             "masterid INTEGER NOT NULL, " +
             "childid INTEGER NOT NULL, " +
             "PRIMARY KEY(masterid, childid));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();

    string sInsertSpellDataQuery = "INSERT INTO " + QC_GetSpellDataTable() + "(spellid, name, icon, metamagic, targettype, master, hostile) VALUES(@spellid, @name, @icon, @metamagic, @targettype, @master, @hostile);";
    string sInsertSpellTableQuery = "INSERT INTO " + QC_GetClassSpellTableTable() + "(spelltable, spellid, spelllevel) VALUES(@spelltable, @spellid, @spelllevel);";
    string sInsertChildSpellQuery = "INSERT INTO " + QC_GetChildSpellsTable() + "(masterid, childid) VALUES(@masterid, @childid);";

    int nSpell, nNumSpells = Get2DARowCount(QC_SPELLS_2DA_NAME);
    for (nSpell = 0; nSpell < nNumSpells; nSpell++)
    {
        string sName = Get2DAStrRefString(QC_SPELLS_2DA_NAME, "Name", nSpell);
        string sIcon = Get2DAString(QC_SPELLS_2DA_NAME, "IconResRef", nSpell);
        int nMetaMagic = HexStringToInt(Get2DAString(QC_SPELLS_2DA_NAME, "MetaMagic", nSpell));
        int nTargetType = HexStringToInt(Get2DAString(QC_SPELLS_2DA_NAME, "TargetType", nSpell));
        int nMasterSpellId = StringToInt(Get2DAString(QC_SPELLS_2DA_NAME, "Master", nSpell));
        int bHostile = StringToInt(Get2DAString(QC_SPELLS_2DA_NAME, "HostileSetting", nSpell));

        // Remove the item target flag, because I'm not dealing with that 8)
        nTargetType = nTargetType & ~0x08;

        sqlquery sql = SqlPrepareQueryModule(sInsertSpellDataQuery);
        SqlBindInt(sql, "@spellid", nSpell);
        SqlBindString(sql, "@name", sName);
        SqlBindString(sql, "@icon", sIcon);
        SqlBindInt(sql, "@metamagic", nMetaMagic);
        SqlBindInt(sql, "@targettype", nTargetType);
        SqlBindInt(sql, "@master", nMasterSpellId);
        SqlBindInt(sql, "@hostile", bHostile);
        SqlStep(sql);

        int nSpellTable;
        for (nSpellTable = 0; nSpellTable < nSpellTableArraySize; nSpellTable++)
        {
            string sSpellTable = StringArray_At(oDataObject, QC_SPELL_TABLE_ARRAY, nSpellTable);
            string sSpellLevel = Get2DAString(QC_SPELLS_2DA_NAME, sSpellTable, nSpell);

            if (sSpellLevel != "")
            {
                int nSpellLevel = StringToInt(sSpellLevel);

                sqlquery sql = SqlPrepareQueryModule(sInsertSpellTableQuery);
                SqlBindString(sql, "@spelltable", sSpellTable);
                SqlBindInt(sql, "@spellid", nSpell);
                SqlBindInt(sql, "@spelllevel", nSpellLevel);
                SqlStep(sql);
            }
        }

        // NOTE:
        // SpellId 771 (Dragon_Breath_Prismatic) has Aid as its SubRadSpell1 for whatever reason...
        // Gonna skip the subradial spell checking for it
        if (nSpell == 771) continue;
        // Ugh

        int nRadialSlot;
        for (nRadialSlot = 1; nRadialSlot <= 5; nRadialSlot++)
        {
            string sChildSpellId = Get2DAString("spells", "SubRadSpell" + IntToString(nRadialSlot), nSpell);

            if (sChildSpellId != "")
            {
                sqlquery sql = SqlPrepareQueryModule(sInsertChildSpellQuery);
                SqlBindInt(sql, "@masterid", nSpell);
                SqlBindInt(sql, "@childid", StringToInt(sChildSpellId));
                SqlStep(sql);
            }
        }
    }

    SqlCommitTransactionModule();

    int nSpellTable;
    for (nSpellTable = 0; nSpellTable < nSpellTableArraySize; nSpellTable++)
    {
        string sSpellTable = StringArray_At(oDataObject, QC_SPELL_TABLE_ARRAY, nSpellTable);
        string sQuery = "SELECT COUNT(*) FROM " + QC_GetClassSpellTableTable() + " WHERE spelltable = @spelltable;";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindString(sql, "@spelltable", sSpellTable);

        if (SqlStep(sql))
            LogInfo("SpellTable: " + sSpellTable + " -> " + IntToString(SqlGetInt(sql, 0)) + " spells");
    }
}

void QC_InitializePlayerQuickCastTable(object oPlayer)
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + QC_GetPlayerQuickCastTable() + "(" +
                    "pageid INTEGER NOT NULL, " +
                    "slotid INTEGER NOT NULL, " +
                    "multiclass INTEGER NOT NULL, " +
                    "spellid INTEGER NOT NULL, " +
                    "masterid INTEGER NOT NULL, " +
                    "metamagic INTEGER NOT NULL, " +
                    "spelllevel INTEGER NOT NULL, " + // Note: adjusted for any MetaMagic
                    "tooltip TEXT NOT NULL, " +
                    "PRIMARY KEY(pageid, slotid));";
    SqlStep(SqlPrepareQueryObject(oPlayer, sQuery));
}

int QC_GetMasterSpell(int nSpellId)
{
    string sQuery = "SELECT masterid FROM " + QC_GetChildSpellsTable() + " WHERE childid = @childid;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@childid", nSpellId);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : nSpellId;
}

int QC_GetSpellLevel(string sSpellTable, int nSpellId)
{
    string sQuery = "SELECT spelllevel FROM " + QC_GetClassSpellTableTable() + " WHERE spelltable = @spelltable AND spellid = @spellid;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@spelltable", sSpellTable);
    SqlBindInt(sql, "@spellid", nSpellId);

    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void QC_InsertQuickCastSlot(object oPlayer, int nPageId, int nSlotId, int nMultiClass, int nSpellId, int nMetaMagic, string sTooltip)
{
    string sQuery = "REPLACE INTO " + QC_GetPlayerQuickCastTable() + "(pageid, slotid, multiclass, spellid, masterid, metamagic, spelllevel, tooltip) " +
                    "VALUES(@pageid, @slotid, @multiclass, @spellid, @masterid, @metamagic, @spelllevel, @tooltip);";
    sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
    SqlBindInt(sql, "@pageid", nPageId);
    SqlBindInt(sql, "@slotid", nSlotId);
    SqlBindInt(sql, "@multiclass", nMultiClass);
    SqlBindInt(sql, "@spellid", nSpellId);
    SqlBindInt(sql, "@masterid", QC_GetMasterSpell(nSpellId));
    SqlBindInt(sql, "@metamagic", nMetaMagic);
    SqlBindInt(sql, "@spelllevel", QC_GetSpellLevel(Get2DAString("classes", "SpellTableColumn", GetClassByPosition(nMultiClass + 1, oPlayer)), QC_GetMasterSpell(nSpellId)) + QC_GetMetaMagicLevelAdjustment(nMetaMagic));
    SqlBindString(sql, "@tooltip", sTooltip);
    SqlStep(sql);
}

void QC_DeleteQuickCastSlot(object oPlayer, int nPageId, int nSlotId)
{
    string sQuery = "DELETE FROM " + QC_GetPlayerQuickCastTable() + " WHERE pageid = @pageid AND slotid = @slotid;";
    sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
    SqlBindInt(sql, "@pageid", nPageId);
    SqlBindInt(sql, "@slotid", nSlotId);
    SqlStep(sql);
}

void QC_LoadQuickCastSlots(object oPlayer, int nPageId)
{
    object oDataObject = GetDataObject(QC_SCRIPT_NAME);
    string sQuery = "SELECT slotid, spellid, multiclass, metamagic, tooltip FROM " + QC_GetPlayerQuickCastTable() + " WHERE pageid = @pageid;";
    sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
    SqlBindInt(sql, "@pageid", nPageId);

    while (SqlStep(sql))
    {
        int nSlotId = SqlGetInt(sql, 0);
        int nSpellId = SqlGetInt(sql, 1);
        int nMultiClass = SqlGetInt(sql, 2);
        int nMetaMagic = SqlGetInt(sql, 3);
        string sTooltip = SqlGetString(sql, 4);

        IntArray_Set(oDataObject, QC_LOAD_QUICKSLOTS_ARRAY, nSlotId, TRUE);
        QC_UpdateSlot(oPlayer, nSlotId, nSpellId, nMultiClass, nMetaMagic, sTooltip);
    }

    int nSlot, nNumSlots = QC_NUM_ROWS * QC_NUM_SLOTS_PER_ROW;
    for (nSlot = 0; nSlot < nNumSlots; nSlot++)
    {
        if (IntArray_At(oDataObject, QC_LOAD_QUICKSLOTS_ARRAY, nSlot))
            IntArray_Set(oDataObject, QC_LOAD_QUICKSLOTS_ARRAY, nSlot, FALSE);
        else
            QC_BlankSlot(oPlayer, nSlot);
    }
}

void QC_InitializeMetaMagicCombo(object oPlayer)
{
    json jMetaMagic = JsonArray();
         jMetaMagic = JsonArrayInsert(jMetaMagic, NuiComboEntry("Metamagic", METAMAGIC_NONE));

    if (GetHasFeat(FEAT_EMPOWER_SPELL, oPlayer))
        jMetaMagic = JsonArrayInsert(jMetaMagic, NuiComboEntry("Empower", METAMAGIC_EMPOWER));
    if (GetHasFeat(FEAT_EXTEND_SPELL, oPlayer))
        jMetaMagic = JsonArrayInsert(jMetaMagic, NuiComboEntry("Extend", METAMAGIC_EXTEND));
    if (GetHasFeat(FEAT_MAXIMIZE_SPELL, oPlayer))
        jMetaMagic = JsonArrayInsert(jMetaMagic, NuiComboEntry("Maximize", METAMAGIC_MAXIMIZE));
    if (GetHasFeat(FEAT_QUICKEN_SPELL, oPlayer))
        jMetaMagic = JsonArrayInsert(jMetaMagic, NuiComboEntry("Quicken", METAMAGIC_QUICKEN));
    if (GetHasFeat(FEAT_SILENCE_SPELL, oPlayer))
        jMetaMagic = JsonArrayInsert(jMetaMagic, NuiComboEntry("Silent", METAMAGIC_SILENT));
    if (GetHasFeat(FEAT_STILL_SPELL, oPlayer))
        jMetaMagic = JsonArrayInsert(jMetaMagic, NuiComboEntry("Still", METAMAGIC_STILL));

    NWM_SetBind(QC_BIND_METAMAGIC_COMBO_ENTRIES, jMetaMagic);
}

void QC_InitializeClassCombo(object oPlayer)
{
    json jClasses = JsonArray();

    int nMultiClass;
    for (nMultiClass = 0; nMultiClass < 3; nMultiClass++)
    {
        int nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);

        if (Get2DAString("classes", "SpellCaster", nClassType) == "1")
            jClasses = JsonArrayInsert(jClasses, NuiComboEntry(Get2DAStrRefString("classes", "Name", nClassType), nMultiClass));
    }

    NWM_SetBind(QC_BIND_CLASS_COMBO_ENTRIES, jClasses);
}

void QC_PreparePlayerKnownSpells(object oPlayer)
{
    if (SqlGetTableExistsObject(GetModule(), QC_GetPlayerKnownSpellsTable(oPlayer, FALSE)))
        return;

    string sTableName = QC_GetPlayerKnownSpellsTable(oPlayer);
    string sQuery = "CREATE TABLE IF NOT EXISTS " + sTableName + " (" +
                    "multiclass INTEGER NOT NULL, " +
                    "spellid INTEGER NOT NULL, " +
                    "spelllevel INTEGER NOT NULL, " +
                    "PRIMARY KEY(multiclass, spellid, spelllevel));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    string sInsertQuery = "INSERT INTO " + sTableName + "(multiclass, spellid, spelllevel) VALUES(@multiclass, @spellid, @spelllevel);";
    string sSelectChildSpellsQuery = "SELECT childid FROM " + QC_GetChildSpellsTable() + " WHERE masterid = @masterid;";

    SqlBeginTransactionModule();

    int nMultiClass;
    for (nMultiClass = 0; nMultiClass < 3; nMultiClass++)
    {
        int nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);

        if (nClassType == CLASS_TYPE_INVALID ||
            !StringToInt(Get2DAString("classes", "SpellCaster", nClassType)) ||
            !StringToInt(Get2DAString("classes", "SpellbookRestricted", nClassType)))
            continue;

        int nSpellLevel;
        for (nSpellLevel = 0; nSpellLevel < QC_NUM_SPELL_LEVELS; nSpellLevel++)
        {
            int nSpellIndex, nNumKnownSpells = GetKnownSpellCount(oPlayer, nClassType, nSpellLevel);
            for (nSpellIndex = 0; nSpellIndex < nNumKnownSpells; nSpellIndex++)
            {
                int nSpellId = GetKnownSpellId(oPlayer, nClassType, nSpellLevel, nSpellIndex);

                int bIsMasterSpell = FALSE;
                sqlquery sqlGetChildSpells = SqlPrepareQueryModule(sSelectChildSpellsQuery);
                SqlBindInt(sqlGetChildSpells, "@masterid", nSpellId);

                while (SqlStep(sqlGetChildSpells))
                {
                    bIsMasterSpell = TRUE;

                    int nChildSpellId = SqlGetInt(sqlGetChildSpells, 0);

                    sqlquery sql = SqlPrepareQueryModule(sInsertQuery);
                    SqlBindInt(sql, "@multiclass", nMultiClass);
                    SqlBindInt(sql, "@spellid", nChildSpellId);
                    SqlBindInt(sql, "@spelllevel", nSpellLevel);
                    SqlStep(sql);
                }

                if (!bIsMasterSpell)
                {
                    sqlquery sql = SqlPrepareQueryModule(sInsertQuery);
                    SqlBindInt(sql, "@multiclass", nMultiClass);
                    SqlBindInt(sql, "@spellid", nSpellId);
                    SqlBindInt(sql, "@spelllevel", nSpellLevel);
                    SqlStep(sql);
                }
            }
        }
    }

    SqlCommitTransactionModule();
}

void QC_DeletePlayerKnownSpellsTable(object oPlayer)
{
    SqlStep(SqlPrepareQueryModule("DROP TABLE IF EXISTS " + QC_GetPlayerKnownSpellsTable(oPlayer) + ";"));
}

void QC_PreparePlayerMemorizedSpells(object oPlayer)
{
    if (SqlGetTableExistsObject(GetModule(), QC_GetPlayerMemorizedSpellsTable(oPlayer, FALSE)))
        return;

    string sTableName = QC_GetPlayerMemorizedSpellsTable(oPlayer);
    string sQuery = "CREATE TABLE IF NOT EXISTS " + sTableName + " (" +
                    "multiclass INTEGER NOT NULL, " +
                    "spellid INTEGER NOT NULL, " +
                    "metamagic INTEGER NOT NULL, "+
                    "spelllevel INTEGER NOT NULL, " +
                    "PRIMARY KEY(multiclass, spellid, spelllevel, metamagic));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();

    sqlquery sql = SqlPrepareQueryModule("REPLACE INTO " + sTableName + "(multiclass, spellid, metamagic, spelllevel) VALUES(@multiclass, @spellid, @metamagic, @spelllevel);");

    int nMultiClass;
    for (nMultiClass = 0; nMultiClass < 3; nMultiClass++)
    {
        int nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);

        if (nClassType == CLASS_TYPE_INVALID ||
            !StringToInt(Get2DAString("classes", "SpellCaster", nClassType)) ||
            !StringToInt(Get2DAString("classes", "MemorizesSpells", nClassType)))
            continue;

        int nSpellLevel;
        for (nSpellLevel = 0; nSpellLevel < QC_NUM_SPELL_LEVELS; nSpellLevel++)
        {
            int nSpellIndex, nNumMemorizedSpells = GetMemorizedSpellCountByLevel(oPlayer, nClassType, nSpellLevel);
            for (nSpellIndex = 0; nSpellIndex < nNumMemorizedSpells; nSpellIndex++)
            {
                int nSpellId = GetMemorizedSpellId(oPlayer, nClassType, nSpellLevel, nSpellIndex);
                if (nSpellId == -1)
                    continue;

                SqlBindInt(sql, "@multiclass", nMultiClass);
                SqlBindInt(sql, "@spellid", nSpellId);
                SqlBindInt(sql, "@metamagic", GetMemorizedSpellMetaMagic(oPlayer, nClassType, nSpellLevel, nSpellIndex));
                SqlBindInt(sql, "@spelllevel", nSpellLevel);
                SqlStepAndReset(sql);
            }
        }
    }

    SqlCommitTransactionModule();
}

void QC_DeletePlayerMemorizedSpellsTable(object oPlayer)
{
    SqlStep(SqlPrepareQueryModule("DROP TABLE IF EXISTS " + QC_GetPlayerMemorizedSpellsTable(oPlayer) + ";"));
}

int QC_GetPlayerMaxSpellLevel(object oPlayer, int nMultiClass)
{
    int nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);
    int nClassLevels = GetLevelByClass(nClassType, oPlayer);
    int nSpellcastingAbility = AbilityToConstant(Get2DAString("classes", "SpellcastingAbil", nClassType));
    string sSpellgainTable = Get2DAString("classes", "SpellGainTable", nClassType);
    int nAbilityScore = GetAbilityScore(oPlayer, nSpellcastingAbility, TRUE) - 9;
        nAbilityScore = nAbilityScore < 0 ? 0 : nAbilityScore > 10 ? 10 : nAbilityScore;
    int nNumSpellLevelsForLevel = StringToInt(Get2DAString(sSpellgainTable, "NumSpellLevels", nClassLevels - 1));
    return nAbilityScore > nNumSpellLevelsForLevel ? nNumSpellLevelsForLevel : nAbilityScore;
}

int QC_GetMetaMagicLevelAdjustment(int nMetaMagic)
{
    return StringToInt(Get2DAString("metamagic", "LevelAdjustment", MetaMagicConstantTo2DARow(nMetaMagic)));
}

sqlquery QC_GetKnownSpellsList(object oPlayer, int nMultiClass, int nMetaMagic, string sSearch)
{
    string sPlayerKnownSpellTable = QC_GetPlayerKnownSpellsTable(oPlayer);
    string sSpellDataTable = QC_GetSpellDataTable();
    string sQuery = "SELECT spelldata.spellid, spelldata.icon, spelldata.name FROM " +
                    sSpellDataTable + " AS spelldata INNER JOIN " + sPlayerKnownSpellTable + " AS playerknownspells ON playerknownspells.spellid = spelldata.spellid WHERE (" +
                    "spelldata.metamagic & @metamagic) = @metamagic AND playerknownspells.multiclass = @multiclass AND (" +
                    "playerknownspells.spelllevel + @metamagicleveladjustment) < @maxspelllevel AND " +
                    "spelldata.name LIKE @like ORDER BY playerknownspells.spelllevel ASC, spelldata.name ASC LIMIT @limit;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@metamagic", nMetaMagic);
    SqlBindInt(sql, "@multiclass", nMultiClass);
    SqlBindInt(sql, "@metamagicleveladjustment", QC_GetMetaMagicLevelAdjustment(nMetaMagic));
    SqlBindInt(sql, "@maxspelllevel", QC_GetPlayerMaxSpellLevel(oPlayer, nMultiClass));
    SqlBindString(sql, "@like", "%" + sSearch + "%");
    SqlBindInt(sql, "@limit", QC_MAX_NUM_SPELLS_IN_LIST);

    return sql;
}

sqlquery QC_GetClassSpellList(object oPlayer, int nMultiClass, int nMetaMagic, string sSearch)
{
    string sClassSpellTablesTable = QC_GetClassSpellTableTable();
    string sSpellDataTable = QC_GetSpellDataTable();
    string sQuery = "SELECT spelldata.spellid, spelldata.icon, spelldata.name FROM " +
                    sSpellDataTable + " AS spelldata INNER JOIN " + sClassSpellTablesTable + " AS classspells ON classspells.spelltable = @spelltable AND " +
                    "classspells.spellid = spelldata.spellid WHERE (" +
                    "spelldata.metamagic & @metamagic) = @metamagic AND (" +
                    "classspells.spelllevel + @metamagicleveladjustment) < @maxspelllevel AND " +
                    "spelldata.name LIKE @like ORDER BY classspells.spelllevel ASC, spelldata.name ASC LIMIT @limit;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@spelltable", Get2DAString("classes", "SpellTableColumn", GetClassByPosition(nMultiClass + 1, oPlayer)));
    SqlBindInt(sql, "@metamagic", nMetaMagic);
    SqlBindInt(sql, "@metamagicleveladjustment", QC_GetMetaMagicLevelAdjustment(nMetaMagic));
    SqlBindInt(sql, "@maxspelllevel", QC_GetPlayerMaxSpellLevel(oPlayer, nMultiClass));
    SqlBindString(sql, "@like", "%" + sSearch + "%");
    SqlBindInt(sql, "@limit", QC_MAX_NUM_SPELLS_IN_LIST);

    return sql;
}

void QC_UpdateSpellList()
{
    object oPlayer = OBJECT_SELF;
    int nMultiClass = NWM_GetBindInt(QC_BIND_CLASS_COMBO_SELECTED);
    int nMetaMagic = NWM_GetBindInt(QC_BIND_METAMAGIC_COMBO_SELECTED);
    string sSearch = NWM_GetBindString(QC_BIND_SPELL_SEARCH_INPUT);
    int nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);
    int bSpellbookRestricted = StringToInt(Get2DAString("classes", "SpellbookRestricted", nClassType));
    int bMemorizesSpells = StringToInt(Get2DAString("classes", "MemorizesSpells", nClassType));
    json jSpellIdArray = JsonArray();
    json jIconArray = JsonArray();
    json jNameArray = JsonArray();
    json jColorArray = JsonArray();

    json jColorWhite = NuiColor(255, 255, 255);
    json jColorGreen = NuiColor(0, 200, 100);

    sqlquery sql;
    if (bSpellbookRestricted)
        sql = QC_GetKnownSpellsList(oPlayer, nMultiClass, nMetaMagic, sSearch);
    else
        sql = QC_GetClassSpellList(oPlayer, nMultiClass, nMetaMagic, sSearch);

    string sChildSpellTable = QC_GetChildSpellsTable();
    string sSpellDataTable = QC_GetSpellDataTable();
    string sSelectChildSpellsQuery = "SELECT spelldata.spellid, spelldata.icon, spelldata.name FROM " +
                                     sSpellDataTable + " AS spelldata INNER JOIN " + sChildSpellTable + " AS childspells ON childspells.childid = spelldata.spellid " +
                                     "WHERE childspells.masterid = @masterid;";

    while (SqlStep(sql))
    {
        if (bMemorizesSpells)
        {
            int nMasterSpellId = SqlGetInt(sql, 0);
            string sMasterIcon = SqlGetString(sql, 1);
            string sMasterName = SqlGetString(sql, 2);

            int bIsMasterSpell = FALSE;
            sqlquery sqlGetChildSpells = SqlPrepareQueryModule(sSelectChildSpellsQuery);
            SqlBindInt(sqlGetChildSpells, "@masterid", nMasterSpellId);

            while (SqlStep(sqlGetChildSpells))
            {
                bIsMasterSpell = TRUE;
                int nChildSpellId = SqlGetInt(sqlGetChildSpells, 0);
                string sChildIcon = SqlGetString(sqlGetChildSpells, 1);
                string sChildName = SqlGetString(sqlGetChildSpells, 2);

                jSpellIdArray = JsonArrayInsertInt(jSpellIdArray, nChildSpellId);
                jIconArray = JsonArrayInsertString(jIconArray, sChildIcon);
                jNameArray = JsonArrayInsertString(jNameArray, sChildName);
                jColorArray = JsonArrayInsert(jColorArray, QC_GetHasMemorizedSpell(oPlayer, nMultiClass, QC_GetMasterSpell(nChildSpellId), nMetaMagic) ? jColorGreen : jColorWhite);
            }

            if (!bIsMasterSpell)
            {
                jSpellIdArray = JsonArrayInsertInt(jSpellIdArray, nMasterSpellId);
                jIconArray = JsonArrayInsertString(jIconArray, sMasterIcon);
                jNameArray = JsonArrayInsertString(jNameArray, sMasterName);
                jColorArray = JsonArrayInsert(jColorArray, QC_GetHasMemorizedSpell(oPlayer, nMultiClass, nMasterSpellId, nMetaMagic) ? jColorGreen : jColorWhite);
            }
        }
        else
        {
            jSpellIdArray = JsonArrayInsertInt(jSpellIdArray, SqlGetInt(sql, 0));
            jIconArray = JsonArrayInsertString(jIconArray, SqlGetString(sql, 1));
            jNameArray = JsonArrayInsertString(jNameArray, SqlGetString(sql, 2));
            jColorArray = JsonArrayInsert(jColorArray, jColorWhite);
        }
    }

    NWM_SetBind(QC_BIND_LIST_SPELL_ICON, jIconArray);
    NWM_SetBind(QC_BIND_LIST_SPELL_NAME, jNameArray);
    NWM_SetBind(QC_BIND_LIST_SPELL_COLOR, jColorArray);
    NWM_SetUserData("spellids", jSpellIdArray);
}

string QC_GetMetaMagicTooltip(int nMetaMagic)
{
    switch (nMetaMagic)
    {
        case METAMAGIC_QUICKEN:
            return "Quickened ";
        case METAMAGIC_EMPOWER:
            return "Empowered ";
        case METAMAGIC_EXTEND:
            return "Extended ";
        case METAMAGIC_MAXIMIZE:
            return "Maximized ";
        case METAMAGIC_SILENT:
            return "Silenced ";
        case METAMAGIC_STILL:
            return "Stilled ";
    }

    return "";
}

json QC_GetMetaMagicRect(int nMetaMagic)
{
    switch (nMetaMagic)
    {
        case METAMAGIC_EMPOWER:
            return NuiRect(1.0f, 0.0f, 8.0f, 8.0f);
        case METAMAGIC_EXTEND:
            return NuiRect(11.0f, 0.0f, 8.0f, 8.0f);
        case METAMAGIC_MAXIMIZE:
            return NuiRect(21.0f, 0.0f, 8.0f, 8.0f);
        case METAMAGIC_QUICKEN:
            return NuiRect(31.0f, 0.0f, 8.0f, 8.0f);
        case METAMAGIC_SILENT:
            return NuiRect(41.0f, 0.0f, 8.0f, 8.0f);
        case METAMAGIC_STILL:
            return NuiRect(51.0f, 0.0f, 8.0f, 8.0f);
    }

    return NuiRect(0.0f, 0.0f, 0.0f, 0.0f);
}

void QC_SetSpellUsesState(object oPlayer, int nSlotId, int nSpellId, int nMultiClass, int nMetaMagic)
{
    int nUses, nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);
    if (StringToInt(Get2DAString("classes", "MemorizesSpells", nClassType)))
        nUses = GetSpellUsesLeft(oPlayer, nClassType, QC_GetMasterSpell(nSpellId), nMetaMagic);
    else
        nUses = GetSpellUsesLeft(oPlayer, nClassType, nSpellId, nMetaMagic);

    string sSlotId = IntToString(nSlotId);

    if (nUses)
    {
        NWM_SetBindString(QC_BIND_SLOT_USES + sSlotId, IntToString(nUses));
        NWM_SetBindBool(QC_BIND_SLOT_USES_VISIBLE + sSlotId, TRUE);
        NWM_SetBindBool(QC_BIND_SLOT_GREYED_OUT + sSlotId, FALSE);
    }
    else
    {
        NWM_SetBindBool(QC_BIND_SLOT_USES_VISIBLE + sSlotId, FALSE);
        NWM_SetBindBool(QC_BIND_SLOT_GREYED_OUT + sSlotId, TRUE);
    }
}

void QC_SetSlot(object oPlayer, int nSlotId, int nSpellId, int nMultiClass, int nMetaMagic)
{
    string sMetaMagic = QC_GetMetaMagicTooltip(nMetaMagic);
    string sSpellName = Get2DAStrRefString(QC_SPELLS_2DA_NAME, "Name", nSpellId);
    string sClassName = Get2DAStrRefString("classes", "Name", GetClassByPosition(nMultiClass + 1, OBJECT_SELF));
    string sTooltip = sMetaMagic + sSpellName + " (" + sClassName + ")";

    QC_InsertQuickCastSlot(oPlayer, QC_GetPlayerPageId(oPlayer), nSlotId, nMultiClass, nSpellId, nMetaMagic, sTooltip);
    QC_UpdateSlot(oPlayer, nSlotId, nSpellId, nMultiClass, nMetaMagic, sTooltip);
}

void QC_UpdateSlot(object oPlayer, int nSlotId, int nSpellId, int nMultiClass, int nMetaMagic, string sTooltip)
{
    string sSlotId = IntToString(nSlotId);

    if (nMetaMagic == METAMAGIC_NONE)
        NWM_SetBindBool(QC_BIND_SLOT_MM_VISIBLE + sSlotId, FALSE);
    else
    {
        NWM_SetBindBool(QC_BIND_SLOT_MM_VISIBLE + sSlotId, TRUE);
        NWM_SetBind(QC_BIND_SLOT_MM_REGION + sSlotId, QC_GetMetaMagicRect(nMetaMagic));
    }

    NWM_SetBindString(QC_BIND_SLOT_ICON + sSlotId, Get2DAString(QC_SPELLS_2DA_NAME, "IconResRef", nSpellId));
    NWM_SetBindString(QC_BIND_SLOT_TOOLTIP + sSlotId, sTooltip);

    QC_SetSpellUsesState(oPlayer, nSlotId, nSpellId, nMultiClass, nMetaMagic);
}

void QC_BlankSlot(object oPlayer, int nSlotId)
{
    string sSlotId = IntToString(nSlotId);

    NWM_SetBindString(QC_BIND_SLOT_ICON + sSlotId, QC_BLANK_SLOT_TEXTURE);
    NWM_SetBindString(QC_BIND_SLOT_TOOLTIP + sSlotId, "");
    NWM_SetBindString(QC_BIND_SLOT_USES + sSlotId, "");
    NWM_SetBindBool(QC_BIND_SLOT_MM_VISIBLE + sSlotId, FALSE);
    NWM_SetBindBool(QC_BIND_SLOT_USES_VISIBLE + sSlotId, FALSE);
    NWM_SetBindBool(QC_BIND_SLOT_GREYED_OUT + sSlotId, FALSE);
}

int QC_GetSpellTargetType(int nSpellId)
{
    string sQuery = "SELECT targettype FROM " + QC_GetSpellDataTable() + " WHERE spellid = @spellid;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@spellid", nSpellId);

    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void QC_SetPlayerPageId(object oPlayer, int nPageId)
{
    PlayerDB_SetInt(oPlayer, QC_SCRIPT_NAME, "PageId", nPageId);
}

int QC_GetPlayerPageId(object oPlayer)
{
    return PlayerDB_GetInt(oPlayer, QC_SCRIPT_NAME, "PageId");
}

void QC_SetPage(object oPlayer, int nPageId)
{
    QC_SetPlayerPageId(oPlayer, nPageId);
    NWM_SetBindBool(QC_BIND_BUTTON_PAGE_ONE_ENABLED, nPageId != 0);
    NWM_SetBindBool(QC_BIND_BUTTON_PAGE_TWO_ENABLED, nPageId != 1);
    NWM_SetBindBool(QC_BIND_BUTTON_PAGE_THREE_ENABLED, nPageId != 2);
    QC_LoadQuickCastSlots(oPlayer, nPageId);
}

void QC_RefreshAllSpellUses(object oPlayer)
{
    if (GetIsPC(oPlayer) && NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        string sQuery = "SELECT slotid, spellid, multiclass, metamagic FROM " + QC_GetPlayerQuickCastTable() + " WHERE pageid = @pageid;";
        sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
        SqlBindInt(sql, "@pageid", QC_GetPlayerPageId(oPlayer));

        while (SqlStep(sql))
        {
            QC_SetSpellUsesState(oPlayer, SqlGetInt(sql, 0), SqlGetInt(sql, 1), SqlGetInt(sql, 2), SqlGetInt(sql, 3));
        }
    }
}

int QC_GetHasMemorizedSpell(object oPlayer, int nMulticlass, int nSpellId, int nMetaMagic)
{
    string sQuery = "SELECT spellid FROM " + QC_GetPlayerMemorizedSpellsTable(oPlayer) + " WHERE " +
                    "multiclass = @multiclass AND spellid = @spellid AND metamagic = @metamagic;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@multiclass", nMulticlass);
    SqlBindInt(sql, "@spellid", nSpellId);
    SqlBindInt(sql, "@metamagic", nMetaMagic);
    return SqlStep(sql);
}

int QC_GetIsSpellCaster(object oPlayer)
{
    int nMultiClass;
    for (nMultiClass = 0; nMultiClass < 3; nMultiClass++)
    {
        if (StringToInt(Get2DAString("classes", "SpellCaster", GetClassByPosition(nMultiClass + 1, oPlayer))))
            return TRUE;
    }

    return FALSE;
}

void QC_SetCustomTarget(object oTarget, vector vPosition)
{
    object oPlayer = OBJECT_SELF;

    NWM_SetUserDataString("target", ObjectToString(oTarget));
    NWM_SetUserData("position", VectorToJson(vPosition));

    if (GetIsObjectValid(oTarget))
    {
        int nVisualEffect = VFX_FNF_GAS_EXPLOSION_MIND;

        if (GetArea(oPlayer) == oTarget)
            NWNX_Player_ShowVisualEffect(oPlayer, nVisualEffect, vPosition);
        else
            NWNX_Player_ApplyInstantVisualEffectToObject(oPlayer, oTarget, nVisualEffect);
    }
}

object QC_GetCustomTargetObject()
{
    return StringToObject(NWM_GetUserDataString("target"));
}

vector QC_GetCustomTargetPosition()
{
    return JsonToVector(NWM_GetUserData("position"));
}

int QC_IsValidCustomTarget(object oTarget, int nTargetType)
{
    object oPlayer = OBJECT_SELF;
    if (!GetIsObjectValid(oTarget) ||
         GetArea(oTarget) != GetArea(oPlayer) ||
         (oTarget == oPlayer && !(nTargetType & 0x01)))
        return FALSE;

    int nObjectType = NWNX_Object_GetInternalObjectType(oTarget);
    if (nObjectType == NWNX_OBJECT_TYPE_INTERNAL_CREATURE && (nTargetType & 0x02))
        return TRUE;
    if (nObjectType == NWNX_OBJECT_TYPE_INTERNAL_AREA && (nTargetType & 0x04))
        return TRUE;
    if (nObjectType == NWNX_OBJECT_TYPE_INTERNAL_DOOR && (nTargetType & 0x10))
        return TRUE;
    if (nObjectType == NWNX_OBJECT_TYPE_INTERNAL_PLACEABLE && (nTargetType & 0x20))
        return TRUE;
    if (nObjectType == NWNX_OBJECT_TYPE_INTERNAL_TRIGGER && (nTargetType & 0x40))
        return TRUE;

    return FALSE;
}

void QC_InitializeTargetTypeCombo()
{
    json jTargetTypes = JsonArray();
         jTargetTypes = JsonArrayInsert(jTargetTypes, NuiComboEntry("Manual", QC_PLAYER_TARGET_TYPE_MANUAL));
         jTargetTypes = JsonArrayInsert(jTargetTypes, NuiComboEntry("Custom", QC_PLAYER_TARGET_TYPE_CUSTOM));
         jTargetTypes = JsonArrayInsert(jTargetTypes, NuiComboEntry("Nearest Hostile", QC_PLAYER_TARGET_TYPE_NEAREST_HOSTILE));

    NWM_SetBind(QC_BIND_TARGETTYPE_COMBO_ENTRIES, jTargetTypes);
}

void QC_SetPlayerTargetType(int nTargetType)
{
    NWM_SetUserDataInt("player_target_type", nTargetType);
}

int QC_GetPlayerTargetType()
{
    return NWM_GetUserDataInt("player_target_type");
}

int QC_GetSpellHasTargetType(int nSpellId, int nTargetType)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT ((targettype & @targettype) = @targettype) FROM " + QC_GetSpellDataTable() + " WHERE spellid = @spellid;");
    SqlBindInt(sql, "@targettype", nTargetType);
    SqlBindInt(sql, "@spellid", nSpellId);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : FALSE;
}

void QC_SetDragModeData(int nDragMode, json jData)
{
    NWM_SetUserDataInt("dragmode_type", nDragMode);
    NWM_SetUserData("dragmode_data", jData);
}

int QC_GetDragModeType()
{
    return NWM_GetUserDataInt("dragmode_type");
}

json QC_GetDragModeData()
{
    return NWM_GetUserData("dragmode_data");
}

void QC_ClearDragMode()
{
    NWM_DeleteUserData("dragmode_type");
    NWM_DeleteUserData("dragmode_data");
}
