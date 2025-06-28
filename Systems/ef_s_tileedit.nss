/*
    Script: ef_s_tileedit
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_c_profiler"
#include "ef_s_areagen"
#include "ef_s_tileset"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_gfftools"

const string TE_SCRIPT_NAME                     = "ef_s_tileedit";

const string TE_TILE_COLOR_ARRAY                = "TileColorArray_";

const string TE_WINDOW_ID_MAIN                  = "TILEEDIT_MAIN_WINDOW";
const string TE_WINDOW_ID_FILTERS               = "TILEEDIT_FILTERS_WINDOW";
const string TE_WINDOW_ID_AREATILES             = "TILEEDIT_AREATILES_WINDOW";

const string TE_BUTTON_FILTERS_WINDOW           = "btn_filters";
const string TE_BUTTON_ATS_WINDOW               = "btn_ats";
const string TE_BUTTON_FILTERS_WINDOW_APPLY     = "btn_filters_apply";
const string TE_BUTTON_FILTERS_WINDOW_CANCEL    = "btn_filters_cancel";

const string TE_BIND_WINDOW_COLLAPSED           = "collapsed";
const string TE_BIND_ICON_TILE                  = "icon_tile";
const string TE_BIND_LABEL_TILE                 = "lbl_tile";
const string TE_BIND_BUTTON_SELECT_TILE         = "btn_tile";

const string TE_BIND_LIST_TILE_NAME             = "lst_tile_name";

const string TE_BIND_SELECTED_TILE_NAME         = "selected_tile";

const string TE_BIND_SELECTED_TILE_COLOR_TL     = "sel_tile_col_tl";
const string TE_BIND_SELECTED_TILE_COLOR_T      = "sel_tile_col_t";
const string TE_BIND_SELECTED_TILE_COLOR_TR     = "sel_tile_col_tr";
const string TE_BIND_SELECTED_TILE_COLOR_R      = "sel_tile_col_r";
const string TE_BIND_SELECTED_TILE_COLOR_BR     = "sel_tile_col_br";
const string TE_BIND_SELECTED_TILE_COLOR_B      = "sel_tile_col_b";
const string TE_BIND_SELECTED_TILE_COLOR_BL     = "sel_tile_col_bl";
const string TE_BIND_SELECTED_TILE_COLOR_L      = "sel_tile_col_l";

const string TE_BIND_LIST_TILE_COLOR_TL         = "list_tile_col_tl";
const string TE_BIND_LIST_TILE_COLOR_T          = "list_tile_col_t";
const string TE_BIND_LIST_TILE_COLOR_TR         = "list_tile_col_tr";
const string TE_BIND_LIST_TILE_COLOR_R          = "list_tile_col_r";
const string TE_BIND_LIST_TILE_COLOR_BR         = "list_tile_col_br";
const string TE_BIND_LIST_TILE_COLOR_B          = "list_tile_col_b";
const string TE_BIND_LIST_TILE_COLOR_BL         = "list_tile_col_bl";
const string TE_BIND_LIST_TILE_COLOR_L          = "list_tile_col_l";

const string TE_BIND_LIST_FILTER_TC_NAME        = "lst_filter_tc_name";
const string TE_BIND_LIST_FILTER_TC_TOGGLE      = "lst_filter_tc_toggle";
const string TE_BIND_LIST_FILTER_TC_MIN         = "lst_filter_tc_min";
const string TE_BIND_LIST_FILTER_TC_MAX         = "lst_filter_tc_max";
const string TE_BIND_LIST_FILTER_TC_LABEL       = "lst_filter_tc_label";

const string TE_WINDOW_USERDATA_MAIN_TILESET    = "UserDataTileset";
const string TE_WINDOW_USERDATA_MAIN_TILE_IDS   = "UserDataMainTileIDs";
const string TE_WINDOW_USERDATA_FILTER_NAME     = "UserDataFilterName";
const string TE_WINDOW_USERDATA_FILTER_TOGGLE   = "UserDataFilterToggle";
const string TE_WINDOW_USERDATA_FILTER_MIN      = "UserDataFilterMin";
const string TE_WINDOW_USERDATA_FILTER_MAX      = "UserDataFilterMax";
const string TE_WINDOW_USERDATA_FILTER_LABEL    = "UserDataFilterLabel";

const float TE_AT_TILE_SIZE                     = 42.0f;
const string TE_AT_LAYOUT_CACHE                 = "ATLayoutCache_";
const string TE_AT_TILES_PREFIX                 = "tile_";

json TE_GetAreaTilesLayoutJson(int nAreaWidth, int nAreaHeight);

void TE_CreateTileTable(string sTileset);
string TE_GetTCCountColumns(string sTileset, int bBind);
void TE_BindTCCountColumns(sqlquery sql, string sTileset, struct TS_TileStruct str);
void TE_CreateTCColorArray(string sTileset);
json TE_GetTCColorArray(string sTileset);
void TE_LoadTileset(string sTileset);

void TE_InitializeFilterUserData();
string TE_GetFilterWhereClause(string sTileset);
json TE_GetTCColor(json jTCColorArray, int nFlag);
void TE_UpdateTileList();
void TE_SetAreaTilesColorBinds(object oArea, int nAreaWidth, int nAreaHeight);

// @CORE[EF_SYSTEM_INIT]
void TE_Init()
{

}

// @CORE[EF_SYSTEM_LOAD]
void TE_Load()
{
    json jTilesets = GetResRefArray("", RESTYPE_SET, TRUE);
    int nTileset, nNumTilesets = JsonGetLength(jTilesets);
    for (nTileset = 0; nTileset < nNumTilesets; nTileset++)
    {
        string sTileset = JsonArrayGetString(jTilesets, nTileset);
        if (TS_GetTilesetLoaded(sTileset))
            TE_LoadTileset(sTileset);
    }
}

// @NWMWINDOW[TE_WINDOW_ID_MAIN]
json TE_CreateMainWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, 0.0f, 650.0f, 500.0f));
    NB_SetWindowTitle(JsonString("Tile Editor"));
    NB_SetWindowCollapsed(NuiBind(TE_BIND_WINDOW_COLLAPSED));
        NB_StartColumn();
            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("Filters")));
                    NB_SetDimensions(100.0f, 32.0f);
                    NB_SetId(TE_BUTTON_FILTERS_WINDOW);
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("Area Tile Selection")));
                    NB_SetDimensions(200.0f, 32.0f);
                    NB_SetId(TE_BUTTON_ATS_WINDOW);
                NB_End();
            NB_End();
            NB_StartRow();
                float fIconSize = 21.0f;
                float fOffset = 4.0f;
                NB_StartList(NuiBind(TE_BIND_LIST_TILE_NAME), fIconSize + fOffset);
                    NB_SetWidth(250.0f);
                    NB_StartListTemplateCell(fIconSize, FALSE);
                        NB_StartElement(NuiSpacer());
                            NB_SetDimensions(fIconSize + fOffset, fIconSize + fOffset);

                            float fSquareSize = fIconSize / 3;
                            NB_StartDrawList(JsonBool(TRUE));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(TE_BIND_LIST_TILE_COLOR_TL), JsonBool(TRUE), JsonFloat(0.0f),
                                        NuiRect((fOffset / 2) + 0 * fSquareSize, (fOffset / 2) + 0 * fSquareSize, fSquareSize, fSquareSize),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(TE_BIND_LIST_TILE_COLOR_T), JsonBool(TRUE), JsonFloat(0.0f),
                                        NuiRect((fOffset / 2) + 1 * fSquareSize, (fOffset / 2) + 0 * fSquareSize, fSquareSize, fSquareSize),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(TE_BIND_LIST_TILE_COLOR_TR), JsonBool(TRUE), JsonFloat(0.0f),
                                        NuiRect((fOffset / 2) + 2 * fSquareSize, (fOffset / 2) + 0 * fSquareSize, fSquareSize, fSquareSize),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(TE_BIND_LIST_TILE_COLOR_L), JsonBool(TRUE), JsonFloat(0.0f),
                                        NuiRect((fOffset / 2) + 0 * fSquareSize, (fOffset / 2) + 1 * fSquareSize, fSquareSize, fSquareSize),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(TE_BIND_LIST_TILE_COLOR_R), JsonBool(TRUE), JsonFloat(0.0f),
                                        NuiRect((fOffset / 2) + 2 * fSquareSize, (fOffset / 2) + 1 * fSquareSize, fSquareSize, fSquareSize),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(TE_BIND_LIST_TILE_COLOR_BL), JsonBool(TRUE), JsonFloat(0.0f),
                                        NuiRect((fOffset / 2) + 0 * fSquareSize, (fOffset / 2) + 2 * fSquareSize, fSquareSize, fSquareSize),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(TE_BIND_LIST_TILE_COLOR_B), JsonBool(TRUE), JsonFloat(0.0f),
                                        NuiRect((fOffset / 2) + 1 * fSquareSize, (fOffset / 2) + 2 * fSquareSize, fSquareSize, fSquareSize),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(TE_BIND_LIST_TILE_COLOR_BR), JsonBool(TRUE), JsonFloat(0.0f),
                                        NuiRect((fOffset / 2) + 2 * fSquareSize, (fOffset / 2) + 2 * fSquareSize, fSquareSize, fSquareSize),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_AddDrawListItem(
                                    NuiDrawListLine(
                                        JsonBool(TRUE), NuiColor(225, 225, 225), JsonFloat(2.0f),
                                        NuiVec(0.0f, (fOffset) + (3 * fSquareSize) + 2.0f), NuiVec((3 * fSquareSize) + fOffset, (fOffset) + (3 * fSquareSize) + 2.0f),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                            NB_End();
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(200.0f, TRUE);
                        NB_StartElement(NuiSpacer());
                            NB_SetId(TE_BIND_LIST_TILE_NAME);
                            NB_StartDrawList(JsonBool(TRUE));
                                NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiColor(255, 255, 255), NuiRect(fOffset, fOffset, 200.0f, fIconSize), NuiBind(TE_BIND_LIST_TILE_NAME), NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_OFF));
                                NB_AddDrawListItem(NuiDrawListText(JsonBool(TRUE), NuiColor(50, 150, 250), NuiRect(fOffset, fOffset, 200.0f, fIconSize), NuiBind(TE_BIND_LIST_TILE_NAME), NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER));
                            NB_End();
                        NB_End();
                    NB_End();
                NB_End();
                NB_StartColumn();
                    NB_SetMargin(0.0f);
                    NB_StartRow();
                        NB_AddSpacer();
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_SetMargin(0.0f);
                            NB_SetDimensions(368.0f, 32.0f);
                            NB_AddElement(NuiLabel(NuiBind(TE_BIND_SELECTED_TILE_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();
                    NB_StartRow();
                        NB_StartElement(NuiSpacer());
                            NB_SetWidth(4.0f);
                        NB_End();
                        NB_StartGroup(TRUE, NUI_SCROLLBARS_NONE);
                            NB_SetMargin(0.0f);
                            NB_SetDimensions(158.0f, 158.0f);
                            NB_StartElement(NuiSpacer());
                                NB_SetDimensions(150.0f, 150.0f);
                                NB_StartDrawList(JsonBool(TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(TE_BIND_SELECTED_TILE_COLOR_TL), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(0.0f, 0.0f, 50.0f, 50.0f),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(TE_BIND_SELECTED_TILE_COLOR_T), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(50.0f, 0.0f, 50.0f, 50.0f),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(TE_BIND_SELECTED_TILE_COLOR_TR), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(100.0f, 0.0f, 50.0f, 50.0f),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(TE_BIND_SELECTED_TILE_COLOR_L), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(0.0f, 50.0f, 50.0f, 50.0f),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(TE_BIND_SELECTED_TILE_COLOR_R), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(100.0f, 50.0f, 50.0f, 50.0f),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(TE_BIND_SELECTED_TILE_COLOR_BL), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(0.0f, 100.0f, 50.0f, 50.0f),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(TE_BIND_SELECTED_TILE_COLOR_B), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(50.0f, 100.0f, 50.0f, 50.0f),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(TE_BIND_SELECTED_TILE_COLOR_BR), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(100.0f, 100.0f, 50.0f, 50.0f),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                                NB_End();
                            NB_End();
                        NB_End();
                        NB_StartColumn();
                            NB_StartRow();
                                NB_StartElement(NuiLabel(JsonString("Orientation: 0"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                    NB_SetDimensions(150.0f, 20.0f);
                                NB_End();
                                NB_AddSpacer();
                            NB_End();
                            NB_StartRow();
                                NB_StartElement(NuiLabel(JsonString("Height: 0"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                                    NB_SetDimensions(150.0f, 20.0f);
                                NB_End();
                                NB_AddSpacer();
                            NB_End();
                            NB_StartRow();
                                NB_AddSpacer();
                            NB_End();
                        NB_End();
                        NB_AddSpacer();
                    NB_End();
                    NB_StartRow();
                        NB_AddSpacer();
                    NB_End();
                    NB_StartRow();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Rotate")));
                            //NB_SetId(CONSOLE_BIND_BUTTON_CLEAR_ARGS);
                            //NB_SetEnabled(NuiBind(CONSOLE_BIND_BUTTON_CLEAR_ARGS_ENABLED));
                            NB_SetDimensions(125.0f, 40.0f);
                        NB_End();
                        NB_AddSpacer();
                        NB_StartElement(NuiButton(JsonString("Apply")));
                            //NB_SetId(CONSOLE_BIND_BUTTON_EXECUTE);
                            //NB_SetEnabled(NuiBind(CONSOLE_BIND_BUTTON_EXECUTE_ENABLED));
                            NB_SetDimensions(125.0f, 40.0f);
                        NB_End();
                        NB_AddSpacer();
                    NB_End();
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMWINDOW[TE_WINDOW_ID_FILTERS]
json TE_CreateFiltersWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, 0.0f, 350.0f, 500.0f));
    NB_SetWindowTitle(JsonString("Tile Filters"));
        NB_StartColumn();
            NB_StartRow();
                NB_StartList(NuiBind(TE_BIND_LIST_FILTER_TC_NAME), 24.0f);
                    NB_StartListTemplateCell(125.0f, FALSE);
                        NB_StartElement(NuiCheck(NuiBind(TE_BIND_LIST_FILTER_TC_NAME), NuiBind(TE_BIND_LIST_FILTER_TC_TOGGLE)));
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(50.0f, FALSE);
                        NB_StartElement(NuiSlider(NuiBind(TE_BIND_LIST_FILTER_TC_MIN), JsonInt(0), JsonInt(4), JsonInt(1)));
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(50.0f, FALSE);
                        NB_StartElement(NuiSlider(NuiBind(TE_BIND_LIST_FILTER_TC_MAX), JsonInt(0), JsonInt(4), JsonInt(1)));
                        NB_End();
                    NB_End();
                    NB_StartListTemplateCell(50.0f, TRUE);
                        NB_StartElement(NuiLabel(NuiBind(TE_BIND_LIST_FILTER_TC_LABEL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
                        NB_End();
                    NB_End();
                NB_End();
            NB_End();
            NB_StartRow();
                NB_StartElement(NuiButton(JsonString("Cancel")));
                    NB_SetDimensions(100.0f, 32.0f);
                    NB_SetId(TE_BUTTON_FILTERS_WINDOW_CANCEL);
                NB_End();
                NB_AddSpacer();
                NB_StartElement(NuiButton(JsonString("Apply")));
                    NB_SetDimensions(100.0f, 32.0f);
                    NB_SetId(TE_BUTTON_FILTERS_WINDOW_APPLY);
                NB_End();
            NB_End();
        NB_End();
    return NB_FinalizeWindow();
}

json TE_GetAreaTilesLayoutJson(int nAreaWidth, int nAreaHeight)
{
    json jLayout = GetLocalJson(GetDataObject(TE_SCRIPT_NAME), TE_AT_LAYOUT_CACHE + IntToString(nAreaHeight) + "_" + IntToString(nAreaWidth));
    if (!JsonGetType(jLayout))
    {
        NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 200.0f, 100.0f));
            NB_StartColumn();

                float fTCSize = TE_AT_TILE_SIZE / 3;
                int nRow;
                for (nRow = 0; nRow < nAreaHeight; nRow++)
                {
                    NB_StartRow();

                        NB_AddSpacer();

                        int nColumn;
                        for (nColumn = 0; nColumn < nAreaWidth; nColumn++)
                        {
                            int nIndex = (nAreaHeight - nRow) * nAreaWidth - (nAreaWidth - nColumn);
                            string sID = TE_AT_TILES_PREFIX + IntToString(nIndex);
                            string sColorBind = sID + "_colors";

                            NB_StartElement(NuiImage(JsonString("gui_inv_1x1_ol"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                                NB_SetId(sID);
                                NB_SetDimensions(TE_AT_TILE_SIZE, TE_AT_TILE_SIZE);
                                NB_SetTooltip(JsonString(IntToString(nIndex)));

                                NB_StartDrawList(JsonBool(TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(0.0f, 0.0f, TE_AT_TILE_SIZE, TE_AT_TILE_SIZE),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(0.0f, 0.0f, fTCSize, fTCSize),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(fTCSize * 1, 0.0f, fTCSize, fTCSize),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(fTCSize * 2, 0.0f, fTCSize, fTCSize),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(0.0f, fTCSize * 1, fTCSize, fTCSize),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(fTCSize * 2, fTCSize * 1, fTCSize, fTCSize),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(0.0f, fTCSize * 2, fTCSize, fTCSize),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(fTCSize * 1, fTCSize * 2, fTCSize, fTCSize),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                    NB_AddDrawListItem(
                                        NuiDrawListRect(
                                            JsonBool(TRUE), NuiBind(sColorBind), JsonBool(TRUE), JsonFloat(0.0f),
                                            NuiRect(fTCSize * 2, fTCSize * 2, fTCSize, fTCSize),
                                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, TRUE));
                                NB_End();

                            NB_End();

                            ResetScriptInstructions();
                        }

                        NB_AddSpacer();

                    NB_End();
                }

            NB_End();
        jLayout = NB_GetData();
        SetLocalJson(GetDataObject(TE_SCRIPT_NAME), TE_AT_LAYOUT_CACHE + IntToString(nAreaHeight) + "_" + IntToString(nAreaWidth), jLayout);
    }
    return jLayout;
}

// @NWMWINDOW[TE_WINDOW_ID_AREATILES]
json TE_CreateAreaTileSelectionWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 200.0f, 100.0f));
    NB_SetWindowTitle(JsonString("Area Tiles"));
    NB_SetWindowTransparent(JsonBool(TRUE));
    NB_SetWindowBorder(JsonBool(FALSE));
        NB_StartColumn();
        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[TE_WINDOW_ID_MAIN:NUI_EVENT_CLOSE:NUI_WINDOW_ROOT_GROUP]
void QC_MainWindowClose()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, TE_WINDOW_ID_FILTERS))
        NWM_CloseWindow(oPlayer, TE_WINDOW_ID_FILTERS);
    if (NWM_GetIsWindowOpen(oPlayer, TE_WINDOW_ID_AREATILES))
        NWM_CloseWindow(oPlayer, TE_WINDOW_ID_AREATILES);
}

// @NWMEVENT[TE_WINDOW_ID_MAIN:NUI_EVENT_CLICK:TE_BUTTON_FILTERS_WINDOW]
void TE_ToggleFiltersWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_ToggleWindow(oPlayer, TE_WINDOW_ID_FILTERS))
    {
        NWM_CopyUserData(TE_WINDOW_ID_MAIN, TE_WINDOW_USERDATA_FILTER_NAME);
        NWM_CopyUserData(TE_WINDOW_ID_MAIN, TE_WINDOW_USERDATA_FILTER_TOGGLE);
        NWM_CopyUserData(TE_WINDOW_ID_MAIN, TE_WINDOW_USERDATA_FILTER_MIN);
        NWM_CopyUserData(TE_WINDOW_ID_MAIN, TE_WINDOW_USERDATA_FILTER_MAX);
        NWM_CopyUserData(TE_WINDOW_ID_MAIN, TE_WINDOW_USERDATA_FILTER_LABEL);

        NWM_SetBindWatch(TE_BIND_LIST_FILTER_TC_TOGGLE, TRUE);
        NWM_SetBindWatch(TE_BIND_LIST_FILTER_TC_MIN, TRUE);
        NWM_SetBindWatch(TE_BIND_LIST_FILTER_TC_MAX, TRUE);

        NWM_SetBind(TE_BIND_LIST_FILTER_TC_NAME, NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_NAME));
        NWM_SetBind(TE_BIND_LIST_FILTER_TC_TOGGLE, NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_TOGGLE));
        NWM_SetBind(TE_BIND_LIST_FILTER_TC_MIN, NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_MIN));
        NWM_SetBind(TE_BIND_LIST_FILTER_TC_MAX, NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_MAX));
        NWM_SetBind(TE_BIND_LIST_FILTER_TC_LABEL, NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_LABEL));
    }
}

// @NWMEVENT[TE_WINDOW_ID_MAIN:NUI_EVENT_CLICK:TE_BUTTON_ATS_WINDOW]
void TE_ToggleATSWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_ToggleWindow(oPlayer, TE_WINDOW_ID_AREATILES))
    {
        Profiler_Start("TE_ToggleATSWindow");
        object oArea = GetArea(oPlayer);
        int nAreaWidth = GetAreaSize(AREA_WIDTH, oArea);
        int nAreaHeight = GetAreaSize(AREA_HEIGHT, oArea);
        float fWidth = ((TE_AT_TILE_SIZE + 4.0f) * IntToFloat(nAreaWidth)) + 10.0f;
        float fHeight = 33.0f + ((TE_AT_TILE_SIZE + 8.0f) * IntToFloat(nAreaHeight)) + 8.0f;
        NWM_SetRootWindowLayout(TE_GetAreaTilesLayoutJson(nAreaWidth, nAreaHeight));
        NWM_SetBind(NUI_WINDOW_GEOMETRY_BIND, NuiRect(-1.0, -1.0f, fWidth, fHeight));
        TE_SetAreaTilesColorBinds(oArea, nAreaWidth, nAreaHeight);
        LogInfo(Profiler_Stop());
    }
}

// @NWMEVENT[TE_WINDOW_ID_FILTERS:NUI_EVENT_WATCH:TE_BIND_LIST_FILTER_TC_TOGGLE]
void TE_WatchFilterToggleBind()
{
    int nTC = NuiGetEventArrayIndex();
    if (nTC != -1)
    {
        json jToggleArray = NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_TOGGLE);
        jToggleArray = JsonArraySetBool(jToggleArray, nTC, JsonArrayGetBool(NWM_GetBind(TE_BIND_LIST_FILTER_TC_TOGGLE), nTC));
        NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_TOGGLE, jToggleArray);
    }
}

void TE_UpdateFilterLabel(int nIndex)
{
    int nMin = JsonArrayGetInt(NWM_GetBind(TE_BIND_LIST_FILTER_TC_MIN), nIndex);
    int nMax = JsonArrayGetInt(NWM_GetBind(TE_BIND_LIST_FILTER_TC_MAX), nIndex);
    json jLabelArray = NWM_GetBind(TE_BIND_LIST_FILTER_TC_LABEL);
    jLabelArray = JsonArraySetString(jLabelArray, nIndex, IntToString(nMin) + "-" + IntToString(nMax));
    NWM_SetBind(TE_BIND_LIST_FILTER_TC_LABEL, jLabelArray);
    NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_LABEL, jLabelArray);
}

// @NWMEVENT[TE_WINDOW_ID_FILTERS:NUI_EVENT_WATCH:TE_BIND_LIST_FILTER_TC_MIN]
void TE_WatchFilterMinBind()
{
    int nIndex = NuiGetEventArrayIndex();
    if (nIndex != -1)
    {
        json jMinArray = NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_MIN);
        jMinArray = JsonArraySetInt(jMinArray, nIndex, JsonArrayGetInt(NWM_GetBind(TE_BIND_LIST_FILTER_TC_MIN), nIndex));
        NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_MIN, jMinArray);
        TE_UpdateFilterLabel(nIndex);
    }
}

// @NWMEVENT[TE_WINDOW_ID_FILTERS:NUI_EVENT_WATCH:TE_BIND_LIST_FILTER_TC_MAX]
void TE_WatchFilterMaxBind()
{
    int nIndex = NuiGetEventArrayIndex();
    if (nIndex != -1)
    {
        json jMaxArray = NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_MAX);
        jMaxArray = JsonArraySetInt(jMaxArray, nIndex, JsonArrayGetInt(NWM_GetBind(TE_BIND_LIST_FILTER_TC_MAX), nIndex));
        NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_MAX, jMaxArray);
        TE_UpdateFilterLabel(nIndex);
    }
}

// @NWMEVENT[TE_WINDOW_ID_FILTERS:NUI_EVENT_CLICK:TE_BUTTON_FILTERS_WINDOW_CANCEL]
void TE_ButtonFiltersCancel()
{
    object oPlayer = OBJECT_SELF;
    NWM_CloseWindow(oPlayer, TE_WINDOW_ID_FILTERS);
}

// @NWMEVENT[TE_WINDOW_ID_FILTERS:NUI_EVENT_CLICK:TE_BUTTON_FILTERS_WINDOW_APPLY]
void TE_ButtonFiltersApply()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, TE_WINDOW_ID_MAIN, TRUE))
    {
        NWM_CopyUserData(TE_WINDOW_ID_FILTERS, TE_WINDOW_USERDATA_FILTER_TOGGLE);
        NWM_CopyUserData(TE_WINDOW_ID_FILTERS, TE_WINDOW_USERDATA_FILTER_MIN);
        NWM_CopyUserData(TE_WINDOW_ID_FILTERS, TE_WINDOW_USERDATA_FILTER_MAX);
        NWM_CopyUserData(TE_WINDOW_ID_FILTERS, TE_WINDOW_USERDATA_FILTER_LABEL);
        TE_UpdateTileList();
    }
}

// @PMBUTTON[Tile Editor:Open the area tile editor]
void TE_ToggleMainWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, TE_WINDOW_ID_MAIN))
        NWM_CloseWindow(oPlayer, TE_WINDOW_ID_MAIN);
    else
    {
        string sTileset = GetTilesetResRef(GetArea(oPlayer));
        if (TS_GetTilesetLoaded(sTileset))
        {
            if (NWM_OpenWindow(oPlayer, TE_WINDOW_ID_MAIN))
            {
                NWM_SetUserDataString(TE_WINDOW_USERDATA_MAIN_TILESET, sTileset);
                TE_InitializeFilterUserData();
                TE_UpdateTileList();
            }
        }
        else
        {
            SendMessageToPC(oPlayer, "Tileset for this area is not loaded!");
        }
    }
}

// TILE DATABASE
void TE_CreateTileTable(string sTileset)
{
    string sTCCountColumns;
    json jTCArray = TS_GetTilesetTerrainCrosserArray(sTileset);
    int nTC, nNumTC = JsonGetLength(jTCArray);
    for (nTC = 0; nTC < nNumTC; nTC++)
    {
        sTCCountColumns += JsonArrayGetString(jTCArray, nTC) + "_count INTEGER, ";
    }

    string sQuery = "CREATE TABLE IF NOT EXISTS " + TE_SCRIPT_NAME + sTileset + " (" +
                    "tile_id INTEGER NOT NULL PRIMARY KEY, " +
                    "bitmask INTEGER NOT NULL, " +
                    "tl INTEGER NOT NULL, " +
                    "t INTEGER NOT NULL, " +
                    "tr INTEGER NOT NULL, " +
                    "r INTEGER NOT NULL, " +
                    "br INTEGER NOT NULL, " +
                    "b INTEGER NOT NULL, " +
                    "bl INTEGER NOT NULL, " +
                    "l INTEGER NOT NULL, " +
                    sTCCountColumns +
                    "model TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

string TE_GetTCCountColumns(string sTileset, int bBind)
{
    string sTCCountColumns;
    json jTCArray = TS_GetTilesetTerrainCrosserArray(sTileset);
    int nTC, nNumTC = JsonGetLength(jTCArray);
    for (nTC = 0; nTC < nNumTC; nTC++)
    {
        sTCCountColumns += (bBind ? "@" : "") + JsonArrayGetString(jTCArray, nTC) + "_count, ";
    }
    return sTCCountColumns;
}

void TE_BindTCCountColumns(sqlquery sql, string sTileset, struct TS_TileStruct str)
{
    string sTCCountColumns;
    json jTCArray = TS_GetTilesetTerrainCrosserArray(sTileset);
    int nTC, nNumTC = JsonGetLength(jTCArray);
    for (nTC = 0; nTC < nNumTC; nTC++)
    {
        string sTC = JsonArrayGetString(jTCArray, nTC);
        SqlBindInt(sql, "@" + sTC + "_count", TS_GetNumOfTerrainOrCrosser(str, sTC, TRUE));
    }
}

void TE_CreateTCColorArray(string sTileset)
{
    json jColorArray = JsonArray();
    json jTCArray = TS_GetTilesetTerrainCrosserArray(sTileset);
    int nTC, nNumTC = JsonGetLength(jTCArray);
    for (nTC = 0; nTC < nNumTC; nTC++)
    {
        string sTC = JsonArrayGetString(jTCArray, nTC);

        if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
        {
            if (sTC == "SAND")
                JsonArrayInsertInplace(jColorArray, NuiColor(200, 200, 75, 255));
            else if (sTC == "WATER")
                JsonArrayInsertInplace(jColorArray, NuiColor(25, 25, 200, 255));
            else if (sTC == "TREES")
                JsonArrayInsertInplace(jColorArray, NuiColor(25, 75, 25, 255));
            else if (sTC == "GRASS")
                JsonArrayInsertInplace(jColorArray, NuiColor(25, 125, 25, 255));
            else if (sTC == "CHASM")
                JsonArrayInsertInplace(jColorArray, NuiColor(75, 75, 75, 255));
            else if (sTC == "GRASS2")
                JsonArrayInsertInplace(jColorArray, NuiColor(25, 175, 25, 255));
            else if (sTC == "MOUNTAIN")
                JsonArrayInsertInplace(jColorArray, NuiColor(125, 125, 125, 255));
            else if (sTC == "ROAD")
                JsonArrayInsertInplace(jColorArray, NuiColor(175, 125, 75, 255));
            else if (sTC == "STREAM")
                JsonArrayInsertInplace(jColorArray, NuiColor(75, 150, 200, 255));
            else if (sTC == "WALL")
                JsonArrayInsertInplace(jColorArray, NuiColor(100, 100, 100, 255));
            else if (sTC == "BRIDGE")
                JsonArrayInsertInplace(jColorArray, NuiColor(125, 200, 200, 255));
            else if (sTC == "RIDGE")
                JsonArrayInsertInplace(jColorArray, NuiColor(100, 150, 50, 255));
            else if (sTC == "STREET")
                JsonArrayInsertInplace(jColorArray, NuiColor(150, 150, 150, 255));
        }
    }

    SetLocalJson(GetDataObject(TE_SCRIPT_NAME), TE_TILE_COLOR_ARRAY + sTileset, jColorArray);
}

json TE_GetTCColorArray(string sTileset)
{
    return GetLocalJson(GetDataObject(TE_SCRIPT_NAME), TE_TILE_COLOR_ARRAY + sTileset);
}

void TE_LoadTileset(string sTileset)
{
    LogInfo("Loading Tile Data: " + sTileset);

    SqlBeginTransactionModule();

    TE_CreateTileTable(sTileset);

    sqlquery sqlInsert = SqlPrepareQueryModule("INSERT INTO " + TE_SCRIPT_NAME + sTileset +
        "(tile_id, bitmask, tl, t, tr, r, br, b, bl, l, " + TE_GetTCCountColumns(sTileset, FALSE) + "model) " +
        "VALUES(@tile_id, @bitmask, @tl, @t, @tr, @r, @br, @b, @bl, @l, " + TE_GetTCCountColumns(sTileset, TRUE) + "@model);");
    sqlquery sqlSelect = SqlPrepareQueryModule("SELECT tile_id, bitmask FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) +
        " WHERE orientation = 0 AND height = 0 AND is_group_tile = 0;");
    while (SqlStep(sqlSelect))
    {
        int nTileID = SqlGetInt(sqlSelect, 0);
        struct TS_TileStruct str = TS_GetTileEdgesAndCorners(sTileset, nTileID);

        SqlBindInt(sqlInsert, "@tile_id", nTileID);
        SqlBindInt(sqlInsert, "@bitmask", SqlGetInt(sqlSelect, 1));
        SqlBindInt(sqlInsert, "@tl", TS_GetTCBitflag(sTileset, str.sTL));
        SqlBindInt(sqlInsert, "@t", TS_GetTCBitflag(sTileset, str.sT));
        SqlBindInt(sqlInsert, "@tr", TS_GetTCBitflag(sTileset, str.sTR));
        SqlBindInt(sqlInsert, "@r", TS_GetTCBitflag(sTileset, str.sR));
        SqlBindInt(sqlInsert, "@br", TS_GetTCBitflag(sTileset, str.sBR));
        SqlBindInt(sqlInsert, "@b", TS_GetTCBitflag(sTileset, str.sB));
        SqlBindInt(sqlInsert, "@bl", TS_GetTCBitflag(sTileset, str.sBL));
        SqlBindInt(sqlInsert, "@l", TS_GetTCBitflag(sTileset, str.sL));
        TE_BindTCCountColumns(sqlInsert, sTileset, str);
        SqlBindString(sqlInsert, "@model", NWNX_Tileset_GetTileModel(sTileset, nTileID));
        SqlStepAndReset(sqlInsert);
    }

    SqlCommitTransactionModule();

    TE_CreateTCColorArray(sTileset);

    ResetScriptInstructions();
}

// WINDOW STUFF

void TE_InitializeFilterUserData()
{
    string sTileset = NWM_GetUserDataString(TE_WINDOW_USERDATA_MAIN_TILESET);
    json jTCArray = TS_GetTilesetTerrainCrosserArray(sTileset);
    int nTC, nNumTC = JsonGetLength(jTCArray);

    json jNameArray = JsonArray();
    json jToggleArray = JsonArray();
    json jMinArray = JsonArray();
    json jMaxArray = JsonArray();
    json jLabelArray = JsonArray();

    for (nTC = 0; nTC < nNumTC; nTC++)
    {
        JsonArrayInsertStringInplace(jNameArray, JsonArrayGetString(jTCArray, nTC));
        JsonArrayInsertBoolInplace(jToggleArray, TRUE);
        JsonArrayInsertIntInplace(jMinArray, 0);
        JsonArrayInsertIntInplace(jMaxArray, 4);
        JsonArrayInsertStringInplace(jLabelArray, "0-4");
    }

    NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_NAME, jNameArray);
    NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_TOGGLE, jToggleArray);
    NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_MIN, jMinArray);
    NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_MAX, jMaxArray);
    NWM_SetUserData(TE_WINDOW_USERDATA_FILTER_LABEL, jLabelArray);
}

string TE_GetFilterWhereClause(string sTileset)
{
    json jTCArray = TS_GetTilesetTerrainCrosserArray(sTileset);
    json jToggleArray = NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_TOGGLE);
    json jMinArray = NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_MIN);
    json jMaxArray = NWM_GetUserData(TE_WINDOW_USERDATA_FILTER_MAX);

    int nBitmask, nTC, nNumTC = JsonGetLength(jToggleArray);
    string sNumClause;
    for (nTC = 0; nTC < nNumTC; nTC++)
    {
        if (!JsonArrayGetInt(jToggleArray, nTC))
            nBitmask |= (1 << nTC);
        else
        {
            string sColumn = JsonArrayGetString(jTCArray, nTC) + "_count";
            string sMin = IntToString(JsonArrayGetInt(jMinArray, nTC));
            string sMax = IntToString(JsonArrayGetInt(jMaxArray, nTC));
            sNumClause += " AND (" + sColumn + " >= " + sMin + " AND " + sColumn + " <= " + sMax + ")";
        }
    }

    return " WHERE (bitmask & " + IntToString(nBitmask) + ") = 0" + sNumClause + ";";
}

json TE_GetTCColor(json jTCColorArray, int nFlag)
{
    return nFlag ? JsonArrayGet(jTCColorArray, log2(nFlag)) : NuiColor(0, 0, 0, 0);
}

void TE_UpdateTileList()
{
    Profiler_Start("TE_UpdateTileList");

    json jTileIDArray = JsonArray();
    json jNameArray = JsonArray();
    json jTileColorTLArray = JsonArray();
    json jTileColorTArray = JsonArray();
    json jTileColorTRArray = JsonArray();
    json jTileColorRArray = JsonArray();
    json jTileColorBRArray = JsonArray();
    json jTileColorBArray = JsonArray();
    json jTileColorBLArray = JsonArray();
    json jTileColorLArray = JsonArray();

    string sTileset = NWM_GetUserDataString(TE_WINDOW_USERDATA_MAIN_TILESET);
    json jTCColorArray = TE_GetTCColorArray(sTileset);
    string sWhere = TE_GetFilterWhereClause(sTileset);
    string sQuery = "SELECT tile_id, tl, t, tr, r, br, b, bl, l, model FROM " + TE_SCRIPT_NAME + sTileset + sWhere;
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    int nCount;
    while (SqlStep(sql))
    {
        int nTileID = SqlGetInt(sql, 0);
        JsonArrayInsertIntInplace(jTileIDArray, nTileID);
        JsonArrayInsertStringInplace(jNameArray, SqlGetString(sql, 9) + " (" + IntToString(nTileID) + ")");
        JsonArrayInsertInplace(jTileColorTLArray, TE_GetTCColor(jTCColorArray, SqlGetInt(sql, 1)));
        JsonArrayInsertInplace(jTileColorTArray, TE_GetTCColor(jTCColorArray, SqlGetInt(sql, 2)));
        JsonArrayInsertInplace(jTileColorTRArray, TE_GetTCColor(jTCColorArray, SqlGetInt(sql, 3)));
        JsonArrayInsertInplace(jTileColorRArray, TE_GetTCColor(jTCColorArray, SqlGetInt(sql, 4)));
        JsonArrayInsertInplace(jTileColorBRArray, TE_GetTCColor(jTCColorArray, SqlGetInt(sql, 5)));
        JsonArrayInsertInplace(jTileColorBArray, TE_GetTCColor(jTCColorArray, SqlGetInt(sql, 6)));
        JsonArrayInsertInplace(jTileColorBLArray, TE_GetTCColor(jTCColorArray, SqlGetInt(sql, 7)));
        JsonArrayInsertInplace(jTileColorLArray, TE_GetTCColor(jTCColorArray, SqlGetInt(sql, 8)));

        if (!(nCount++ % 100))
            ResetScriptInstructions();
    }

    NWM_SetUserData(TE_WINDOW_USERDATA_MAIN_TILE_IDS, jTileIDArray);

    NWM_SetBind(TE_BIND_LIST_TILE_NAME, jNameArray);
    NWM_SetBind(TE_BIND_LIST_TILE_COLOR_TL, jTileColorTLArray);
    NWM_SetBind(TE_BIND_LIST_TILE_COLOR_T, jTileColorTArray);
    NWM_SetBind(TE_BIND_LIST_TILE_COLOR_TR, jTileColorTRArray);
    NWM_SetBind(TE_BIND_LIST_TILE_COLOR_R, jTileColorRArray);
    NWM_SetBind(TE_BIND_LIST_TILE_COLOR_BR, jTileColorBRArray);
    NWM_SetBind(TE_BIND_LIST_TILE_COLOR_B, jTileColorBArray);
    NWM_SetBind(TE_BIND_LIST_TILE_COLOR_BL, jTileColorBLArray);
    NWM_SetBind(TE_BIND_LIST_TILE_COLOR_L, jTileColorLArray);

    LogInfo(Profiler_Stop());
}

void TE_SetAreaTilesColorBinds(object oArea, int nAreaWidth, int nAreaHeight)
{
    string sTileset = GetTilesetResRef(oArea);
    json jTCColorArray = TE_GetTCColorArray(sTileset);
    json jBlack = NuiColor(0, 0, 0, 255);
    int nTileIndex, nNumTiles = nAreaWidth * nAreaHeight;
    for (nTileIndex = 0; nTileIndex < nNumTiles; nTileIndex++)
    {
        struct NWNX_Area_TileInfo strTileInfo = NWNX_Area_GetTileInfoByTileIndex(oArea, nTileIndex);
        struct TS_TileStruct strTile = TS_GetCornersAndEdgesByOrientation(sTileset, strTileInfo.nID, strTileInfo.nOrientation);

        json jTileColors = JsonArray();
        JsonArrayInsertInplace(jTileColors, jBlack);
        JsonArrayInsertInplace(jTileColors, TE_GetTCColor(jTCColorArray, TS_GetTCBitflag(sTileset, strTile.sTL)));
        JsonArrayInsertInplace(jTileColors, TE_GetTCColor(jTCColorArray, TS_GetTCBitflag(sTileset, strTile.sT)));
        JsonArrayInsertInplace(jTileColors, TE_GetTCColor(jTCColorArray, TS_GetTCBitflag(sTileset, strTile.sTR)));
        JsonArrayInsertInplace(jTileColors, TE_GetTCColor(jTCColorArray, TS_GetTCBitflag(sTileset, strTile.sL)));
        JsonArrayInsertInplace(jTileColors, TE_GetTCColor(jTCColorArray, TS_GetTCBitflag(sTileset, strTile.sR)));
        JsonArrayInsertInplace(jTileColors, TE_GetTCColor(jTCColorArray, TS_GetTCBitflag(sTileset, strTile.sBL)));
        JsonArrayInsertInplace(jTileColors, TE_GetTCColor(jTCColorArray, TS_GetTCBitflag(sTileset, strTile.sB)));
        JsonArrayInsertInplace(jTileColors, TE_GetTCColor(jTCColorArray, TS_GetTCBitflag(sTileset, strTile.sBR)));
        NWM_SetBind(TE_AT_TILES_PREFIX + IntToString(nTileIndex) + "_colors", jTileColors);
    }
}
