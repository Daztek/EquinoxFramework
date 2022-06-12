/*
    Script: ef_s_quickcast
    Author: Daz

    Notes:
        Requires NWNX_TWEAKS_STRINGTOINT_BASE_TO_AUTO to be enabled.
        Does not work with domain spells or spontaneous spells or sub spells.
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_profiler"
#include "ef_s_targetmode"
#include "ef_s_events"
#include "ef_s_playerdb"

#include "nwnx_player"
#include "nwnx_creature"
#include "nwnx_object"

const string QC_LOG_TAG                             = "QuickCast";
const string QC_SCRIPT_NAME                         = "ef_s_quickcast";

const string QC_SPELLS_2DA_NAME                     = "spells";
const int QC_NUM_SPELL_LEVELS                       = 10;
const string QC_SPELL_TABLE_ARRAY                   = "SpellTableArray";
const string QC_LOAD_QUICKSLOTS_ARRAY               = "LoadQuickCastSlotsArray";
const string QC_BLANK_SLOT_TEXTURE                  = "gui_inv_1x1_ol";

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
const string QC_BIND_SLOT_MM_ICON                   = "slot_mm_icon_";
const string QC_BIND_BUTTON_PAGE_ONE                = "btn_page_1";
const string QC_BIND_BUTTON_PAGE_TWO                = "btn_page_2";
const string QC_BIND_BUTTON_PAGE_THREE              = "btn_page_3";
const string QC_BIND_BUTTON_PAGE_ONE_ENABLED        = "btn_page_1_enabled";
const string QC_BIND_BUTTON_PAGE_TWO_ENABLED        = "btn_page_2_enabled";
const string QC_BIND_BUTTON_PAGE_THREE_ENABLED      = "btn_page_3_enabled";
const string QC_BIND_BUTTON_TARGET                  = "btn_target";

const string QC_SETSLOT_WINDOW_ID                   = "QUICKCASTSETSLOT";
const string QC_BIND_WINDOW_TITLE                   = "window_title";
const string QC_BIND_CLASS_COMBO_ENTRIES            = "class_entries";
const string QC_BIND_CLASS_COMBO_SELECTED           = "class_selected";
const string QC_BIND_METAMAGIC_COMBO_ENTRIES        = "metamagic_entries";
const string QC_BIND_METAMAGIC_COMBO_SELECTED       = "metamagic_selected";
const string QC_BIND_SPELL_SEARCH_INPUT             = "spell_search_input";
const string QC_BIND_BUTTON_CLEAR_SPELL_SEARCH      = "btn_clear_spell";
const string QC_BIND_LIST_ROW_VISIBLE               = "list_visible";
const string QC_BIND_LIST_SPELL_ICON                = "list_icon";
const string QC_BIND_LIST_SPELL_NAME                = "list_name";
const string QC_BIND_LIST_SPELL_COLOR               = "list_color";
const string QC_BIND_BUTTON_CLEAR_SLOT              = "btn_clear_slot";

const string QC_TARGET_MODE                         = "QuickCastTargetMode";

string QC_GetSpellDataTable();
string QC_GetClassSpellTableTable();
string QC_GetPlayerKnownSpellsTable(object oPlayer, int bEscape = TRUE);
string QC_GetPlayerMemorizedSpellsTable(object oPlayer, int bEscape = TRUE);
string QC_GetPlayerQuickCastTable();

void QC_InitializeSpellData();
void QC_InitializePlayerQuickCastTable(object oPlayer);
int QC_GetSpellLevel(string sSpellTable, int nSpellId);
void QC_InsertQuickCastSlot(object oPlayer, int nPageId, int nSlotId, int nMultiClass, int nSpellId, int nMetaMagic, string sTooltip);
void QC_DeleteQuickCastSlot(object oPlayer, int nPageId, int nSlotId);
void QC_LoadQuickCastSlots(object oPlayer, int nPageId);
void QC_SetCurrentSlot(int nSlotId);
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
string QC_GetMetamagicTooltip(int nMetaMagic);
string QC_GetMetamagicIcon(int nMetaMagic);
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
void QC_SetTargetOverride(object oTarget, vector vPosition);
object QC_GetTargetOverrideObject();
vector QC_GetTargetOverridePosition();
int QC_IsValidTarget(object oTarget, int nTargetType);

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
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_PAGE_ONE_ENABLED));
                    NB_SetDimensions((QC_SLOT_SIZE + 4.0f), (QC_SLOT_SIZE + 4.0f));
                NB_End();
                NB_StartElement(NuiButton(JsonString("2")));
                    NB_SetId(QC_BIND_BUTTON_PAGE_TWO);
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_PAGE_TWO_ENABLED));
                    NB_SetDimensions((QC_SLOT_SIZE + 4.0f), (QC_SLOT_SIZE + 4.0f));
                NB_End();
                NB_StartElement(NuiButton(JsonString("3")));
                    NB_SetId(QC_BIND_BUTTON_PAGE_THREE);
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_PAGE_THREE_ENABLED));
                    NB_SetDimensions((QC_SLOT_SIZE + 4.0f), (QC_SLOT_SIZE + 4.0f));
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("T")));
                    NB_SetId(QC_BIND_BUTTON_TARGET);
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
                            NB_StartDrawList(JsonBool(TRUE));
                                NB_AddDrawListItem(NuiDrawListText(NuiBind(QC_BIND_SLOT_USES_VISIBLE + sSlot), NuiColor(0, 0, 0), NuiRect(0.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), NuiBind(QC_BIND_SLOT_USES + sSlot)));
                                NB_AddDrawListItem(NuiDrawListText(NuiBind(QC_BIND_SLOT_USES_VISIBLE + sSlot), NuiColor(0, 0, 0), NuiRect(1.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), NuiBind(QC_BIND_SLOT_USES + sSlot)));
                                NB_AddDrawListItem(NuiDrawListText(NuiBind(QC_BIND_SLOT_USES_VISIBLE + sSlot), NuiColor(0, 0, 0), NuiRect(3.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), NuiBind(QC_BIND_SLOT_USES + sSlot)));
                                NB_AddDrawListItem(NuiDrawListText(NuiBind(QC_BIND_SLOT_USES_VISIBLE + sSlot), NuiColor(0, 0, 0), NuiRect(4.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), NuiBind(QC_BIND_SLOT_USES + sSlot)));
                                NB_AddDrawListItem(NuiDrawListText(NuiBind(QC_BIND_SLOT_USES_VISIBLE + sSlot), NuiColor(0, 0, 0), NuiRect(2.0f, -1.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), NuiBind(QC_BIND_SLOT_USES + sSlot)));
                                NB_AddDrawListItem(NuiDrawListText(NuiBind(QC_BIND_SLOT_USES_VISIBLE + sSlot), NuiColor(0, 0, 0), NuiRect(2.0f, -0.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), NuiBind(QC_BIND_SLOT_USES + sSlot)));
                                NB_AddDrawListItem(NuiDrawListText(NuiBind(QC_BIND_SLOT_USES_VISIBLE + sSlot), NuiColor(0, 255, 0), NuiRect(2.0f, -2.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), NuiBind(QC_BIND_SLOT_USES + sSlot)));
                                NB_AddDrawListItem(NuiDrawListImage(NuiBind(QC_BIND_SLOT_GREYED_OUT + sSlot), JsonString("gui_transprnt"), NuiRect(0.0f, 0.0f, QC_SLOT_SIZE, QC_SLOT_SIZE), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_AddDrawListItem(NuiDrawListImage(NuiBind(QC_BIND_SLOT_MM_VISIBLE + sSlot), NuiBind(QC_BIND_SLOT_MM_ICON + sSlot), NuiRect(QC_SLOT_SIZE - 8.0f, QC_SLOT_SIZE - 8.0f, 8.0f, 8.0f), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
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

    QC_DeletePlayerKnownSpellsTable(oPlayer);
    QC_DeletePlayerMemorizedSpellsTable(oPlayer);

    if (NWM_GetIsWindowOpen(oPlayer, QC_SETSLOT_WINDOW_ID))
        NWM_CloseWindow(oPlayer, QC_SETSLOT_WINDOW_ID);
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_MOUSEUP:QC_BIND_SLOT_ICON]
void QC_SlotMouseUp()
{
    object oPlayer = OBJECT_SELF;

    string sElement = NuiGetEventElement();
    int nSlotId = StringToInt(GetStringRight(sElement, GetStringLength(sElement) - GetStringLength(QC_BIND_SLOT_ICON)));
    int nMouseButton = NuiGetMouseButton(NuiGetEventPayload());

    if (nMouseButton == NUI_MOUSE_BUTTON_MIDDLE)
    {
        if (NWM_GetIsWindowOpen(oPlayer, QC_SETSLOT_WINDOW_ID, TRUE))
            QC_SetCurrentSlot(nSlotId);
        else if (NWM_OpenWindow(oPlayer, QC_SETSLOT_WINDOW_ID))
        {
            QC_PreparePlayerKnownSpells(oPlayer);
            QC_PreparePlayerMemorizedSpells(oPlayer);

            QC_InitializeClassCombo(oPlayer);
            QC_InitializeMetaMagicCombo(oPlayer);

            QC_SetCurrentSlot(nSlotId);
            QC_UpdateSpellList();

            NWM_SetBindWatch(QC_BIND_SPELL_SEARCH_INPUT, TRUE);
            NWM_SetBindWatch(QC_BIND_CLASS_COMBO_SELECTED, TRUE);
            NWM_SetBindWatch(QC_BIND_METAMAGIC_COMBO_SELECTED, TRUE);
        }
    }
    else
    {
        if (NWM_GetBindBool(QC_BIND_SLOT_GREYED_OUT + IntToString(nSlotId)) || GetIsDead(oPlayer))
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
            int nTargetType = QC_GetSpellTargetType(nSpellId);

            if (nMouseButton == NUI_MOUSE_BUTTON_LEFT)
            {
                if (nTargetType == 0x01)
                    NWNX_Creature_AddCastSpellActions(oPlayer, oPlayer, GetPosition(oPlayer), nSpellId, nMultiClass, nMetaMagic);
                else
                {
                    object oTarget = QC_GetTargetOverrideObject();
                    if (QC_IsValidTarget(oTarget, nTargetType))
                        NWNX_Creature_AddCastSpellActions(oPlayer, oTarget, QC_GetTargetOverridePosition(), nSpellId, nMultiClass, nMetaMagic);
                    else
                    {
                        int nValidObjectTypes;
                        if (nTargetType & 0x02) nValidObjectTypes |= OBJECT_TYPE_CREATURE;
                        if (nTargetType & 0x04) nValidObjectTypes |= OBJECT_TYPE_TILE;
                        if (nTargetType & 0x10) nValidObjectTypes |= OBJECT_TYPE_DOOR;
                        if (nTargetType & 0x20) nValidObjectTypes |= OBJECT_TYPE_PLACEABLE;
                        if (nTargetType & 0x40) nValidObjectTypes |= OBJECT_TYPE_TRIGGER;

                        NWM_SetUserData("spellid", JsonInt(nSpellId));
                        NWM_SetUserData("multiclass", JsonInt(nMultiClass));
                        NWM_SetUserData("metamagic", JsonInt(nMetaMagic));
                        NWM_SetUserData("targettype", JsonInt(nTargetType));

                        TargetMode_Enter(oPlayer, QC_TARGET_MODE, nValidObjectTypes);
                    }
                }
            }
            else if (nMouseButton == NUI_MOUSE_BUTTON_RIGHT)
            {
                if (nTargetType & 0x01)
                    NWNX_Creature_AddCastSpellActions(oPlayer, oPlayer, GetPosition(oPlayer), nSpellId, nMultiClass, nMetaMagic);
                else
                    NWNX_Player_PlaySound(oPlayer, "gui_failspell");
            }
        }
    }
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_PAGE_ONE]
void QC_ButtonClickPageOne()
{
    QC_SetPage(OBJECT_SELF, 0);
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_PAGE_TWO]
void QC_ButtonClickPageTwo()
{
    QC_SetPage(OBJECT_SELF, 1);
}

// @NWMEVENT[QC_MAIN_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_PAGE_THREE]
void QC_ButtonClickPageThree()
{
    QC_SetPage(OBJECT_SELF, 2);
}

// @NWMWINDOW[QC_SETSLOT_WINDOW_ID]
json QC_CreateSetSlotWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 500.0f, 400.0f));
    NB_SetWindowTitle(NuiBind(QC_BIND_WINDOW_TITLE));
        NB_StartColumn();
            NB_StartRow();
                NB_StartElement(NuiCombo(NuiBind(QC_BIND_CLASS_COMBO_ENTRIES), NuiBind(QC_BIND_CLASS_COMBO_SELECTED)));
                    NB_SetDimensions(125.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiCombo(NuiBind(QC_BIND_METAMAGIC_COMBO_ENTRIES), NuiBind(QC_BIND_METAMAGIC_COMBO_SELECTED)));
                    NB_SetDimensions(125.0f, 32.0f);
                NB_End();
                NB_StartElement(NuiTextEdit(JsonString("Search spells..."), NuiBind(QC_BIND_SPELL_SEARCH_INPUT), 64, FALSE));
                    NB_SetHeight(32.0f);
                NB_End();
                NB_StartElement(NuiButton(JsonString("X")));
                    NB_SetId(QC_BIND_BUTTON_CLEAR_SPELL_SEARCH);
                    NB_SetEnabled(NuiBind(QC_BIND_BUTTON_CLEAR_SPELL_SEARCH));
                    NB_SetDimensions(32.0f, 32.0f);
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartList(JsonInt(QC_MAX_NUM_SPELLS_IN_LIST), 16.0f);
                    NB_StartListTemplateCell(16.0f, FALSE);
                        NB_StartGroup(FALSE, NUI_SCROLLBARS_NONE);
                            NB_SetVisible(NuiBind(QC_BIND_LIST_ROW_VISIBLE));
                            NB_SetMargin(0.0f);
                            NB_StartElement(NuiImage(NuiBind(QC_BIND_LIST_SPELL_ICON), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_SetVisible(NuiBind(QC_BIND_LIST_ROW_VISIBLE));
                                NB_SetDimensions(16.0f, 16.0f);
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(200.0f, TRUE);
                        NB_StartElement(NuiLabel(NuiBind(QC_BIND_LIST_SPELL_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_SetVisible(NuiBind(QC_BIND_LIST_ROW_VISIBLE));
                            NB_SetForegroundColor(NuiBind(QC_BIND_LIST_SPELL_COLOR));
                            NB_SetId(QC_BIND_LIST_SPELL_NAME);
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("Clear Slot")));
                    NB_SetId(QC_BIND_BUTTON_CLEAR_SLOT);
                    NB_SetDimensions(125.0f, 32.0f);
                NB_End();
                NB_AddSpacer();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_WATCH:QC_BIND_CLASS_COMBO_SELECTED]
void QC_WatchClassCombo()
{
    QC_UpdateSpellList();
    NuiSetClickthroughProtection();
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_WATCH:QC_BIND_METAMAGIC_COMBO_SELECTED]
void QC_WatchMetaMagicCombo()
{
    QC_UpdateSpellList();
    NuiSetClickthroughProtection();
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

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_MOUSEUP:QC_BIND_LIST_SPELL_NAME]
void QC_MouseUpSpellList()
{
    if (NuiGetClickthroughProtection())
        return;

    object oPlayer = OBJECT_SELF;
    int nIndex = NuiGetEventArrayIndex();

    if (nIndex != -1)
    {
        int nSlotId = JsonGetInt(NWM_GetUserData("slotid"));
        int nSpellId = JsonArrayGetInt(NWM_GetUserData("spellids"), nIndex);
        int nMultiClass = NWM_GetBindInt(QC_BIND_CLASS_COMBO_SELECTED);
        int nMetaMagic = NWM_GetBindInt(QC_BIND_METAMAGIC_COMBO_SELECTED);

        if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
            QC_SetSlot(oPlayer, nSlotId, nSpellId, nMultiClass, nMetaMagic);
    }
}

// @NWMEVENT[QC_SETSLOT_WINDOW_ID:NUI_EVENT_CLICK:QC_BIND_BUTTON_CLEAR_SLOT]
void QC_ClickClearSlotButton()
{
    object oPlayer = OBJECT_SELF;
    int nSlotId = JsonGetInt(NWM_GetUserData("slotid"));

    if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        QC_DeleteQuickCastSlot(oPlayer, QC_GetPlayerPageId(oPlayer), nSlotId);
        QC_BlankSlot(oPlayer, nSlotId);
    }
}

// @PMBUTTON[QuickCast Menu:Cast real quick]
void QC_ShowWindow()
{
    object oPlayer = OBJECT_SELF;

    if (QC_GetIsSpellCaster(oPlayer))
    {
        if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID))
            NWM_CloseWindow(oPlayer, QC_MAIN_WINDOW_ID);
        else if (NWM_OpenWindow(oPlayer, QC_MAIN_WINDOW_ID))
        {
            QC_InitializePlayerQuickCastTable(oPlayer);
            QC_SetTargetOverride(OBJECT_INVALID, Vector());
            QC_SetPage(oPlayer, QC_GetPlayerPageId(oPlayer));
        }
    }
    else
        SendMessageToPC(oPlayer, "You must be able to cast spells to use the QuickCast Menu.");
}

// @EVENT[NWNX_ON_DECREMENT_SPELL_COUNT_AFTER]
void QC_DecrementSpellCount()
{
    object oPlayer = OBJECT_SELF;
    if (GetIsPC(oPlayer) && NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        int nSpellId = Events_GetInt("SPELL_ID");
        int nMultiClass = Events_GetInt("CLASS");
        int nMetaMagic = Events_GetInt("METAMAGIC");
        int nClassType = GetClassByPosition(nMultiClass + 1, oPlayer);
        int bMemorizesSpells = StringToInt(Get2DAString("classes", "MemorizesSpells", nClassType));

        sqlquery sql;
        if (bMemorizesSpells)
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
            int nSpellLevel = QC_GetSpellLevel(Get2DAString("classes", "SpellTableColumn", nClassType), nSpellId) + QC_GetMetaMagicLevelAdjustment(nMetaMagic);
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

// @TARGETMODE[QC_TARGET_MODE]
void QC_OnPlayerTarget()
{
    object oPlayer = OBJECT_SELF;
    object oTarget = GetTargetingModeSelectedObject();

    if (oTarget == OBJECT_INVALID)
        return;

    if (NWM_GetIsWindowOpen(oPlayer, QC_MAIN_WINDOW_ID, TRUE))
    {
        int nSpellId = JsonGetInt(NWM_GetUserData("spellid"));
        int nMultiClass = JsonGetInt(NWM_GetUserData("multiclass"));
        int nMetaMagic = JsonGetInt(NWM_GetUserData("metamagic"));
        int nTargetType = JsonGetInt(NWM_GetUserData("targettype"));

        if (oPlayer == oTarget && !(nTargetType & 0x01))
            return;

        NWNX_Creature_AddCastSpellActions(oPlayer, oTarget, GetTargetingModeSelectedPosition(), nSpellId, nMultiClass, nMetaMagic);
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
             "hostile INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + QC_GetClassSpellTableTable() + "(" +
             "spelltable TEXT NOT NULL, " +
             "spellid INTEGER NOT NULL, " +
             "spelllevel INTEGER NOT NULL, " +
             "PRIMARY KEY(spelltable, spellid));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();

    string sInsertSpellDataQuery = "INSERT INTO " + QC_GetSpellDataTable() + "(spellid, name, icon, metamagic, targettype, hostile) VALUES(@spellid, @name, @icon, @metamagic, @targettype, @hostile);";
    string sInsertSpellTableQuery = "INSERT INTO " + QC_GetClassSpellTableTable() + "(spelltable, spellid, spelllevel) VALUES(@spelltable, @spellid, @spelllevel);";

    int nSpell, nNumSpells = Get2DARowCount(QC_SPELLS_2DA_NAME);
    for (nSpell = 0; nSpell < nNumSpells; nSpell++)
    {
        string sName = Get2DAStrRefString(QC_SPELLS_2DA_NAME, "Name", nSpell);
        string sIcon = Get2DAString(QC_SPELLS_2DA_NAME, "IconResRef", nSpell);
        int nMetaMagic = StringToInt(Get2DAString(QC_SPELLS_2DA_NAME, "MetaMagic", nSpell));
        int nTargetType = StringToInt(Get2DAString(QC_SPELLS_2DA_NAME, "TargetType", nSpell));
        int bHostile = StringToInt(Get2DAString(QC_SPELLS_2DA_NAME, "HostileSetting", nSpell));

        // Remove the item target flag, because I'm not dealing with that 8)
        nTargetType = nTargetType & ~0x08;

        sqlquery sql = SqlPrepareQueryModule(sInsertSpellDataQuery);
        SqlBindInt(sql, "@spellid", nSpell);
        SqlBindString(sql, "@name", sName);
        SqlBindString(sql, "@icon", sIcon);
        SqlBindInt(sql, "@metamagic", nMetaMagic);
        SqlBindInt(sql, "@targettype", nTargetType);
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
            WriteLog(QC_LOG_TAG, "SpellTable: " + sSpellTable + " -> " + IntToString(SqlGetInt(sql, 0)) + " spells");
    }
}

void QC_InitializePlayerQuickCastTable(object oPlayer)
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + QC_GetPlayerQuickCastTable() + "(" +
                    "pageid INTEGER NOT NULL, " +
                    "slotid INTEGER NOT NULL, " +
                    "multiclass INTEGER NOT NULL, " +
                    "spellid INTEGER NOT NULL, " +
                    "metamagic INTEGER NOT NULL, " +
                    "spelllevel INTEGER NOT NULL, " + // Note: adjusted for any MetaMagic
                    "tooltip TEXT NOT NULL, " +
                    "PRIMARY KEY(pageid, slotid));";
    SqlStep(SqlPrepareQueryObject(oPlayer, sQuery));
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
    string sQuery = "REPLACE INTO " + QC_GetPlayerQuickCastTable() + "(pageid, slotid, multiclass, spellid, metamagic, spelllevel, tooltip) " +
                    "VALUES(@pageid, @slotid, @multiclass, @spellid, @metamagic, @spelllevel, @tooltip);";
    sqlquery sql = SqlPrepareQueryObject(oPlayer, sQuery);
    SqlBindInt(sql, "@pageid", nPageId);
    SqlBindInt(sql, "@slotid", nSlotId);
    SqlBindInt(sql, "@multiclass", nMultiClass);
    SqlBindInt(sql, "@spellid", nSpellId);
    SqlBindInt(sql, "@metamagic", nMetaMagic);
    SqlBindInt(sql, "@spelllevel", QC_GetSpellLevel(Get2DAString("classes", "SpellTableColumn", GetClassByPosition(nMultiClass + 1, oPlayer)), nSpellId) + QC_GetMetaMagicLevelAdjustment(nMetaMagic));
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

void QC_SetCurrentSlot(int nSlotId)
{
    NWM_SetBindString(QC_BIND_WINDOW_TITLE, "QuickCast: Editing Slot " + IntToString(nSlotId + 1));
    NWM_SetUserData("slotid", JsonInt(nSlotId));
}

void QC_InitializeMetaMagicCombo(object oPlayer)
{
    json jMetaMagic = JsonArray();
         jMetaMagic = JsonArrayInsert(jMetaMagic, NuiComboEntry("None", METAMAGIC_NONE));

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

    sQuery = "INSERT INTO " + sTableName + "(multiclass, spellid, spelllevel) VALUES(@multiclass, @spellid, @spelllevel);";

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
            int nSpellIndex, nNumKnownSpells = NWNX_Creature_GetKnownSpellCount(oPlayer, nClassType, nSpellLevel);
            for (nSpellIndex = 0; nSpellIndex < nNumKnownSpells; nSpellIndex++)
            {
                int nSpellId = NWNX_Creature_GetKnownSpell(oPlayer, nClassType, nSpellLevel, nSpellIndex);

                sqlquery sql = SqlPrepareQueryModule(sQuery);
                SqlBindInt(sql, "@multiclass", nMultiClass);
                SqlBindInt(sql, "@spellid", nSpellId);
                SqlBindInt(sql, "@spelllevel", nSpellLevel);

                SqlStep(sql);
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

    sQuery = "REPLACE INTO " + sTableName + "(multiclass, spellid, metamagic, spelllevel) VALUES(@multiclass, @spellid, @metamagic, @spelllevel);";

    SqlBeginTransactionModule();

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
            int nSpellIndex, nNumMemorizedSpells = NWNX_Creature_GetMemorisedSpellCountByLevel(oPlayer, nClassType, nSpellLevel);
            for (nSpellIndex = 0; nSpellIndex < nNumMemorizedSpells; nSpellIndex++)
            {
                struct NWNX_Creature_MemorisedSpell strSpell = NWNX_Creature_GetMemorisedSpell(oPlayer, nClassType, nSpellLevel, nSpellIndex);

                sqlquery sql = SqlPrepareQueryModule(sQuery);
                SqlBindInt(sql, "@multiclass", nMultiClass);
                SqlBindInt(sql, "@spellid", strSpell.id);
                SqlBindInt(sql, "@metamagic", strSpell.meta);
                SqlBindInt(sql, "@spelllevel", nSpellLevel);

                SqlStep(sql);
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
    int nSpellcastingAbility = SpellcastingAbilityToConstant(Get2DAString("classes", "SpellcastingAbil", nClassType));
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
    string sQuery = "SELECT " + sSpellDataTable + ".spellid, " + sSpellDataTable + ".icon, " + sSpellDataTable + ".name FROM " +
                    sSpellDataTable + " INNER JOIN " + sPlayerKnownSpellTable + " ON " + sPlayerKnownSpellTable + ".spellid = " + sSpellDataTable + ".spellid WHERE (" +
                    sSpellDataTable + ".metamagic & @metamagic) = @metamagic AND " + sPlayerKnownSpellTable + ".multiclass = @multiclass AND (" +
                    sPlayerKnownSpellTable + ".spelllevel + @metamagicleveladjustment) < @maxspelllevel AND " +
                    sSpellDataTable + ".name LIKE @like ORDER BY " + sPlayerKnownSpellTable + ".spelllevel ASC, " + sSpellDataTable + ".name ASC LIMIT @limit;";
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
    string sQuery = "SELECT " + sSpellDataTable + ".spellid, " + sSpellDataTable + ".icon, " + sSpellDataTable + ".name FROM " +
                    sSpellDataTable + " INNER JOIN " + sClassSpellTablesTable + " ON " + sClassSpellTablesTable + ".spelltable = @spelltable AND " +
                    sClassSpellTablesTable + ".spellid = " + sSpellDataTable + ".spellid WHERE (" +
                    sSpellDataTable + ".metamagic & @metamagic) = @metamagic AND (" +
                    sClassSpellTablesTable + ".spelllevel + @metamagicleveladjustment) < @maxspelllevel AND " +
                    sSpellDataTable + ".name LIKE @like ORDER BY " + sClassSpellTablesTable + ".spelllevel ASC, " + sSpellDataTable + ".name ASC LIMIT @limit;";
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

    // This is an optimization, we build the arrays using strings and do a JsonParse() at the end. JsonArrayInsert/Set get costly fast.
    string sVisibleArray;
    string sSpellIdArray;
    string sIconArray;
    string sNameArray;
    string sColorArray;

    string sColorWhite = JsonDump(NuiColor(255, 255, 255));
    string sColorGreen = JsonDump(NuiColor(0, 255, 0));

    sqlquery sql;
    if (bSpellbookRestricted)
        sql = QC_GetKnownSpellsList(oPlayer, nMultiClass, nMetaMagic, sSearch);
    else
        sql = QC_GetClassSpellList(oPlayer, nMultiClass, nMetaMagic, sSearch);

    while (SqlStep(sql))
    {
        int nSpellId = SqlGetInt(sql, 0);
        sVisibleArray += StringJsonArrayElementBool(TRUE);
        sSpellIdArray += StringJsonArrayElementInt(nSpellId);
        sIconArray += StringJsonArrayElementString(SqlGetString(sql, 1));
        sNameArray += StringJsonArrayElementString(SqlGetString(sql, 2));

        if (bMemorizesSpells)
            sColorArray += (QC_GetHasMemorizedSpell(oPlayer, nMultiClass, nSpellId, nMetaMagic) ? sColorGreen : sColorWhite) + ",";
        else
            sColorArray += sColorWhite + ",";
    }

    NWM_SetBind(QC_BIND_LIST_ROW_VISIBLE, StringJsonArrayElementsToJsonArray(sVisibleArray));
    NWM_SetBind(QC_BIND_LIST_SPELL_ICON, StringJsonArrayElementsToJsonArray(sIconArray));
    NWM_SetBind(QC_BIND_LIST_SPELL_NAME, StringJsonArrayElementsToJsonArray(sNameArray));
    NWM_SetBind(QC_BIND_LIST_SPELL_COLOR, StringJsonArrayElementsToJsonArray(sColorArray));
    NWM_SetUserData("spellids", StringJsonArrayElementsToJsonArray(sSpellIdArray));
}

string QC_GetMetamagicTooltip(int nMetaMagic)
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

string QC_GetMetamagicIcon(int nMetaMagic)
{
    switch (nMetaMagic)
    {
        case METAMAGIC_QUICKEN:
            return "qc_mm_qui";
        case METAMAGIC_EMPOWER:
            return "qc_mm_emp";
        case METAMAGIC_EXTEND:
            return "qc_mm_ext";
        case METAMAGIC_MAXIMIZE:
            return "qc_mm_max";
        case METAMAGIC_SILENT:
            return "qc_mm_sil";
        case METAMAGIC_STILL:
            return "qc_mm_sti";
    }

    return "";
}

void QC_SetSpellUsesState(object oPlayer, int nSlotId, int nSpellId, int nMultiClass, int nMetaMagic)
{
    int nUses;
    if (StringToInt(Get2DAString("classes", "MemorizesSpells", GetClassByPosition(nMultiClass + 1, oPlayer))))
        nUses = NWNX_Creature_GetMemorizedSpellReadyCount(oPlayer, nSpellId, nMultiClass, nMetaMagic);
    else
        nUses = NWNX_Creature_GetSpellUsesLeft(oPlayer, nSpellId, nMultiClass, 0, nMetaMagic);

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
    string sMetaMagic = QC_GetMetamagicTooltip(nMetaMagic);
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
        NWM_SetBindString(QC_BIND_SLOT_MM_ICON + sSlotId, QC_GetMetamagicIcon(nMetaMagic));
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

    switch (nPageId)
    {
        case 0:
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_ONE_ENABLED, FALSE);
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_TWO_ENABLED, TRUE);
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_THREE_ENABLED, TRUE);
            break;
        case 1:
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_ONE_ENABLED, TRUE);
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_TWO_ENABLED, FALSE);
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_THREE_ENABLED, TRUE);
            break;
        case 2:
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_ONE_ENABLED, TRUE);
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_TWO_ENABLED, TRUE);
            NWM_SetBindBool(QC_BIND_BUTTON_PAGE_THREE_ENABLED, FALSE);
            break;
    }

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
    string sQuery = "SELECT * FROM " + QC_GetPlayerMemorizedSpellsTable(oPlayer) + " WHERE " +
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

void QC_SetTargetOverride(object oTarget, vector vPosition)
{
    NWM_SetUserData("target", JsonString(ObjectToString(oTarget)));
    NWM_SetUserData("position", VectorToJson(vPosition));
}

object QC_GetTargetOverrideObject()
{
    return StringToObject(JsonGetString(NWM_GetUserData("target")));
}

vector QC_GetTargetOverridePosition()
{
    return JsonToVector(NWM_GetUserData("position"));
}

int QC_IsValidTarget(object oTarget, int nTargetType)
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

