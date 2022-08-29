/*
    Script: ef_s_nuibuilder
    Author: Daz

    Description: A simple NUI Window Builder Library
*/

#include "ef_i_core"

const string NB_LOG_TAG                 = "NuiBuilder";
const string NB_SCRIPT_NAME             = "ef_s_nuibuilder";

const int NB_LOG_DEBUG                  = FALSE;
const int NB_LOG_WARNINGS               = TRUE;

const string NB_WINDOW                  = "Window";
const string NB_DEPTH                   = "Depth";
const string NB_TYPE                    = "Type_";
const string NB_DATA                    = "Data_";

const int NB_TYPE_ROOT                  = 0;
const int NB_TYPE_COLUMN                = 1;
const int NB_TYPE_ROW                   = 2;
const int NB_TYPE_GROUP                 = 3;
const int NB_TYPE_ELEMENT               = 4;
const int NB_TYPE_LIST                  = 5;
const int NB_TYPE_LIST_TEMPLATE_CELL    = 6;
const int NB_TYPE_DRAWLIST              = 7;
const int NB_TYPE_DRAWLIST_ITEM         = 8;
const int NB_TYPE_STATIC_COMBO          = 9;
const int NB_TYPE_STATIC_COMBO_ENTRY    = 10;
const int NB_TYPE_STATIC_OPTIONS        = 11;
const int NB_TYPE_STATIC_OPTIONS_ENTRY  = 12;

void NB_LogDebug(string sDebug);
void NB_LogWarning(string sWarning);
int NB_GetDepth();
void NB_SetDepth(int nDepth);
void NB_IncreaseDepth();
void NB_DecreaseDepth();
int NB_GetType();
void NB_SetType(int nType);
json NB_GetData();
void NB_SetData(json jData);
int NB_IsLayoutType(int nType);
int NB_IsElementType(int nType);
string NB_TypeToString(int nType);
void NB_Start(int nType, json jValue);
void NB_End();

void NB_StartColumn();
void NB_StartRow();
void NB_StartGroup(int bBorder = TRUE, int nScrollbar = NUI_SCROLLBARS_AUTO);

void NB_StartElement(json jElement);
void NB_AddElement(json jElement);
void NB_AddSpacer();
void NB_StartList(json jRowCount, float fRowHeight = NUI_STYLE_ROW_HEIGHT, int bBorder = TRUE, int nScroll = NUI_SCROLLBARS_Y);
void NB_StartListTemplateCell(float fWidth, int bVariable);
void NB_StartDrawList(json jScissor);
void NB_AddDrawListItem(json jDrawListItem);
void NB_StartStaticCombo(json jSelected);
void NB_AddStaticComboEntry(string sLabel, int nValue);
void NB_StartStaticOptions(int nDirection, json jValue);
void NB_AddStaticOptionsEntry(string sLabel);

void NB_SetAspect(float fAspect);
void NB_SetEnabled(json jEnabler);
void NB_SetHeight(float fHeight);
void NB_SetId(string sId);
void NB_SetMargin(float fMargin);
void NB_SetPadding(float fPadding);
void NB_SetForegroundColor(json jColor);
void NB_SetTooltip(json jTooltip);
void NB_SetDisabledTooltip(json jDisabledTooltip);
void NB_SetEncouraged(json jEncouraged);
void NB_SetVisible(json jVisible);
void NB_SetWidth(float fWidth);
void NB_SetDimensions(float fWidth, float fHeight);

json NB_GetWindow();
void NB_SetWindow(json jWindow);
void NB_InitializeWindow(json jDefaultGeometry);
void NB_SetWindowVersion(int nVersion);
void NB_SetWindowRoot(json jRoot);
void NB_SetWindowTitle(json jTitle);
void NB_SetWindowGeometry(json jGeometry);
void NB_SetWindowResizable(json jResizable);
void NB_SetWindowCollapsed(json jCollapsed);
void NB_SetWindowClosable(json jCloseable);
void NB_SetWindowTransparent(json jTransparent);
void NB_SetWindowBorder(json jBorder);
void NB_SetWindowTitlebarHidden();
json NB_FinalizeWindow();

void NB_LogDebug(string sDebug)
{
    if (NB_LOG_DEBUG)
        WriteLog(NB_LOG_TAG, "DEBUG: " + sDebug);
}

void NB_LogWarning(string sWarning)
{
    if (NB_LOG_WARNINGS)
        WriteLog(NB_LOG_TAG, "WARNING: " + sWarning);
}

int NB_GetDepth()
{
    return GetLocalInt(GetDataObject(NB_SCRIPT_NAME), NB_DEPTH);
}

void NB_SetDepth(int nDepth)
{
    SetLocalInt(GetDataObject(NB_SCRIPT_NAME), NB_DEPTH, nDepth);
}

void NB_IncreaseDepth()
{
    NB_SetDepth(NB_GetDepth() + 1);
}

void NB_DecreaseDepth()
{
    NB_SetDepth(NB_GetDepth() - 1);
}

int NB_GetType()
{
    return GetLocalInt(GetDataObject(NB_SCRIPT_NAME), NB_TYPE + IntToString(NB_GetDepth()));
}

void NB_SetType(int nType)
{
    SetLocalInt(GetDataObject(NB_SCRIPT_NAME), NB_TYPE + IntToString(NB_GetDepth()), nType);
}

json NB_GetData()
{
    return GetLocalJson(GetDataObject(NB_SCRIPT_NAME), NB_DATA + IntToString(NB_GetDepth()));
}

void NB_SetData(json jData)
{
    SetLocalJson(GetDataObject(NB_SCRIPT_NAME), NB_DATA + IntToString(NB_GetDepth()), jData);
}

int NB_IsLayoutType(int nType)
{
    return nType == NB_TYPE_COLUMN || nType == NB_TYPE_ROW || nType == NB_TYPE_GROUP;
}

int NB_IsElementType(int nType)
{
    return nType == NB_TYPE_ELEMENT || nType == NB_TYPE_LIST || nType == NB_TYPE_STATIC_COMBO || nType == NB_TYPE_STATIC_OPTIONS;
}

string NB_TypeToString(int nType)
{
    switch (nType)
    {
        case NB_TYPE_ROOT:                  return "NB_TYPE_ROOT";
        case NB_TYPE_COLUMN:                return "NB_TYPE_COLUMN";
        case NB_TYPE_ROW:                   return "NB_TYPE_ROW";
        case NB_TYPE_GROUP:                 return "NB_TYPE_GROUP";
        case NB_TYPE_ELEMENT:               return "NB_TYPE_ELEMENT";
        case NB_TYPE_LIST:                  return "NB_TYPE_LIST";
        case NB_TYPE_LIST_TEMPLATE_CELL:    return "NB_TYPE_LIST_TEMPLATE_CELL";
        case NB_TYPE_DRAWLIST:              return "NB_TYPE_DRAWLIST";
        case NB_TYPE_DRAWLIST_ITEM:         return "NB_TYPE_DRAWLIST_ITEM";
        case NB_TYPE_STATIC_COMBO:          return "NB_TYPE_STATIC_COMBO";
        case NB_TYPE_STATIC_COMBO_ENTRY:    return "NB_TYPE_STATIC_COMBO_ENTRY";
        case NB_TYPE_STATIC_OPTIONS:        return "NB_TYPE_STATIC_OPTIONS";
        case NB_TYPE_STATIC_OPTIONS_ENTRY:  return "NB_TYPE_STATIC_OPTIONS_ENTRY";
    }
    return "<UNKNOWN TYPE>";
}

void NB_Start(int nType, json jValue)
{
    NB_IncreaseDepth();
    NB_SetType(nType);
    NB_SetData(jValue);

    NB_LogDebug("[" + IntToString(NB_GetDepth()) + "]  START: '" + NB_TypeToString(nType) + "'");
}

void NB_End()
{
    int nTypeToAdd = NB_GetType();
    json jDataToAdd = NB_GetData();

    NB_LogDebug("[" + IntToString(NB_GetDepth()) + "]    END: '" + NB_TypeToString(nTypeToAdd) + "'");

    NB_DecreaseDepth();

    int nType = NB_GetType();
    json jData = NB_GetData();

    NB_LogDebug("[" + IntToString(NB_GetDepth()) + "] INSERT: '" + NB_TypeToString(nTypeToAdd) + "' -> '" + NB_TypeToString(nType) + "'");

    switch (nType)
    {
        case NB_TYPE_ROOT:
        {
            if (NB_IsLayoutType(nTypeToAdd))
                NB_SetData(jDataToAdd);
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_ROOT} only accepts {NB_TYPE_COLUMN|NB_TYPE_ROW|NB_TYPE_GROUP}.");
            break;
        }
        case NB_TYPE_COLUMN:
        case NB_TYPE_ROW:
        {
            if (NB_IsLayoutType(nTypeToAdd) || NB_IsElementType(nTypeToAdd))
                NB_SetData(JsonObjectInsertToArrayWithKey(jData, "children", jDataToAdd));
            else if (nTypeToAdd == NB_TYPE_DRAWLIST)
                NB_SetData(JsonMerge(jData, jDataToAdd));
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_COLUMN|NB_TYPE_ROW} only accepts {NB_TYPE_COLUMN|NB_TYPE_ROW|NB_TYPE_GROUP|NB_TYPE_ELEMENT|NB_TYPE_LIST|NB_TYPE_STATIC_COMBO|NB_TYPE_STATIC_OPTIONS|NB_TYPE_DRAWLIST}.");
            break;
        }
        case NB_TYPE_GROUP:
        {
            if (NB_IsLayoutType(nTypeToAdd) || NB_IsElementType(nTypeToAdd))
                NB_SetData(JsonObjectSet(jData, "children", JsonArrayInsert(JsonArray(), jDataToAdd)));
            else if (nTypeToAdd == NB_TYPE_DRAWLIST)
                NB_SetData(JsonMerge(jData, jDataToAdd));
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_GROUP} only accepts {NB_TYPE_COLUMN|NB_TYPE_ROW|NB_TYPE_GROUP|NB_TYPE_ELEMENT|NB_TYPE_LIST|NB_TYPE_STATIC_COMBO|NB_TYPE_STATIC_OPTIONS|NB_TYPE_DRAWLIST}.");
            break;
        }
        case NB_TYPE_ELEMENT:
        {
            if (nTypeToAdd == NB_TYPE_DRAWLIST)
                NB_SetData(JsonMerge(jData, jDataToAdd));
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_ELEMENT} only accepts {NB_TYPE_DRAWLIST}.");
            break;
        }
        case NB_TYPE_LIST:
        {
            if (nTypeToAdd == NB_TYPE_LIST_TEMPLATE_CELL)
            {
                if (JsonGetLength(JsonObjectGet(jData,  "row_template")) < 16)
                    NB_SetData(JsonObjectInsertToArrayWithKey(jData, "row_template", jDataToAdd));
                else
                    NB_LogWarning("{NB_TYPE_LIST} only supports up to 16 {NB_TYPE_LIST_TEMPLATE_CELL} elements.");
            }
            else if (nTypeToAdd == NB_TYPE_DRAWLIST)
                NB_SetData(JsonMerge(jData, jDataToAdd));
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_LIST} only accepts {NB_TYPE_LIST_TEMPLATE_CELL|NB_TYPE_DRAWLIST}.");
            break;
        }
        case NB_TYPE_LIST_TEMPLATE_CELL:
        {
            if (NB_IsElementType(nTypeToAdd) || nTypeToAdd == NB_TYPE_GROUP)
                NB_SetData(JsonArraySet(jData, 0, jDataToAdd));
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_LIST_TEMPLATE_CELL} only accepts {NB_TYPE_ELEMENT|NB_TYPE_LIST|NB_TYPE_STATIC_COMBO|NB_TYPE_STATIC_OPTIONS|NB_TYPE_GROUP}.");
            break;
        }
        case NB_TYPE_DRAWLIST:
        {
            if (nTypeToAdd == NB_TYPE_DRAWLIST_ITEM)
                NB_SetData(JsonObjectInsertToArrayWithKey(jData, "draw_list", jDataToAdd));
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_DRAWLIST} only accepts {NB_TYPE_DRAWLIST_ITEM}.");
            break;
        }
        case NB_TYPE_DRAWLIST_ITEM:
        {
            NB_LogWarning("TYPE MISMATCH: {NB_TYPE_DRAWLIST_ITEM} does not accept other types.");
            break;
        }
        case NB_TYPE_STATIC_COMBO:
        {
            if (nTypeToAdd == NB_TYPE_STATIC_COMBO_ENTRY)
                NB_SetData(JsonObjectInsertToArrayWithKey(jData, "elements", jDataToAdd));
            else if (nTypeToAdd == NB_TYPE_DRAWLIST)
                NB_SetData(JsonMerge(jData, jDataToAdd));
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_STATIC_COMBO} only accepts {NB_TYPE_STATIC_COMBO_ENTRY|NB_TYPE_DRAWLIST}.");
            break;
        }
        case NB_TYPE_STATIC_COMBO_ENTRY:
        {
            NB_LogWarning("TYPE MISMATCH: {NB_TYPE_STATIC_COMBO_ENTRY} does not accept other types.");
            break;
        }
        case NB_TYPE_STATIC_OPTIONS:
        {
            if (nTypeToAdd == NB_TYPE_STATIC_OPTIONS_ENTRY)
                NB_SetData(JsonObjectInsertToArrayWithKey(jData, "elements", jDataToAdd));
            else if (nTypeToAdd == NB_TYPE_DRAWLIST)
                NB_SetData(JsonMerge(jData, jDataToAdd));
            else
                NB_LogWarning("TYPE MISMATCH: {NB_TYPE_STATIC_OPTIONS} only accepts {NB_TYPE_STATIC_OPTIONS_ENTRY|NB_TYPE_DRAWLIST}.");
            break;
        }
        case NB_TYPE_STATIC_OPTIONS_ENTRY:
        {
            NB_LogWarning("TYPE MISMATCH: {NB_TYPE_STATIC_OPTIONS_ENTRY} does not accept other types.");
            break;
        }
        default:
            NB_LogWarning("UNKNOWN TYPE: " + IntToString(nTypeToAdd));
        break;
    }
}

void NB_StartColumn()
{
    NB_Start(NB_TYPE_COLUMN, NuiCol(JsonArray()));
}

void NB_StartRow()
{
    NB_Start(NB_TYPE_ROW, NuiRow(JsonArray()));
}

void NB_StartGroup(int bBorder = TRUE, int nScrollbar = NUI_SCROLLBARS_AUTO)
{
    NB_Start(NB_TYPE_GROUP, NuiGroup(JsonNull(), bBorder, nScrollbar));
}

void NB_StartElement(json jElement)
{
    NB_Start(NB_TYPE_ELEMENT, jElement);
}

void NB_AddElement(json jElement)
{
    NB_StartElement(jElement);
    NB_End();
}
void NB_AddSpacer()
{
    NB_AddElement(NuiSpacer());
}

void NB_StartList(json jRowCount, float fRowHeight = NUI_STYLE_ROW_HEIGHT, int bBorder = TRUE, int nScroll = NUI_SCROLLBARS_Y)
{
    NB_Start(NB_TYPE_LIST, NuiList(JsonArray(), jRowCount, fRowHeight, bBorder, nScroll));
}

void NB_StartListTemplateCell(float fWidth, int bVariable)
{
    NB_Start(NB_TYPE_LIST_TEMPLATE_CELL, NuiListTemplateCell(JsonNull(), fWidth, bVariable));
}

void NB_StartDrawList(json jScissor)
{
    NB_Start(NB_TYPE_DRAWLIST, NuiDrawList(JsonObject(), jScissor, JsonArray()));
}

void NB_AddDrawListItem(json jDrawListItem)
{
    NB_Start(NB_TYPE_DRAWLIST_ITEM, jDrawListItem);
    NB_End();
}

void NB_StartStaticCombo(json jSelected)
{
    NB_Start(NB_TYPE_STATIC_COMBO, NuiCombo(JsonArray(), jSelected));
}

void NB_AddStaticComboEntry(string sLabel, int nValue)
{
    NB_Start(NB_TYPE_STATIC_COMBO_ENTRY, NuiComboEntry(sLabel, nValue));
    NB_End();
}

void NB_StartStaticOptions(int nDirection, json jValue)
{
    NB_Start(NB_TYPE_STATIC_OPTIONS, NuiOptions(nDirection, JsonArray(), jValue));
}

void NB_AddStaticOptionsEntry(string sLabel)
{
    NB_Start(NB_TYPE_STATIC_OPTIONS_ENTRY, JsonString(sLabel));
    NB_End();
}

void NB_SetAspect(float fAspect)
{
    NB_SetData(NuiAspect(NB_GetData(), fAspect));
}

void NB_SetEnabled(json jEnabler)
{
    NB_SetData(NuiEnabled(NB_GetData(), jEnabler));
}

void NB_SetHeight(float fHeight)
{
    NB_SetData(NuiHeight(NB_GetData(), fHeight));
}

void NB_SetId(string sId)
{
    NB_SetData(NuiId(NB_GetData(), sId));
}

void NB_SetMargin(float fMargin)
{
    NB_SetData(NuiMargin(NB_GetData(), fMargin));
}

void NB_SetPadding(float fPadding)
{
    NB_SetData(NuiPadding(NB_GetData(), fPadding));
}

void NB_SetForegroundColor(json jColor)
{
    NB_SetData(NuiStyleForegroundColor(NB_GetData(), jColor));
}

void NB_SetTooltip(json jTooltip)
{
    NB_SetData(NuiTooltip(NB_GetData(), jTooltip));
}

void NB_SetDisabledTooltip(json jDisabledTooltip)
{
    NB_SetData(NuiDisabledTooltip(NB_GetData(), jDisabledTooltip));
}

void NB_SetEncouraged(json jEncouraged)
{
    NB_SetData(NuiEncouraged(NB_GetData(), jEncouraged));    
}

void NB_SetVisible(json jVisible)
{
    NB_SetData(NuiVisible(NB_GetData(), jVisible));
}

void NB_SetWidth(float fWidth)
{
    NB_SetData(NuiWidth(NB_GetData(), fWidth));
}

void NB_SetDimensions(float fWidth, float fHeight)
{
    NB_SetWidth(fWidth);
    NB_SetHeight(fHeight);
}

json NB_GetWindow()
{
    return GetLocalJson(GetDataObject(NB_SCRIPT_NAME), NB_WINDOW);
}

void NB_SetWindow(json jWindow)
{
    SetLocalJson(GetDataObject(NB_SCRIPT_NAME), NB_WINDOW, jWindow);
}

void NB_InitializeWindow(json jDefaultGeometry)
{
    NB_LogDebug("* INITIALIZE WINDOW");
    DestroyDataObject(NB_SCRIPT_NAME);
    NB_SetWindow(NuiWindow(JsonNull(), JsonString(""), NuiBind(NUI_WINDOW_GEOMETRY_BIND), JsonBool(FALSE), JsonNull(), JsonBool(TRUE), JsonBool(FALSE), JsonBool(TRUE)));
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), NUI_DEFAULT_GEOMETRY_NAME,  jDefaultGeometry));
}

void NB_SetWindowVersion(int nVersion)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "version",  JsonInt(nVersion)));
}

void NB_SetWindowRoot(json jRoot)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "root",  jRoot));
}

void NB_SetWindowTitle(json jTitle)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "title",  jTitle));
}

void NB_SetWindowGeometry(json jGeometry)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "geometry",  jGeometry));
}

void NB_SetWindowResizable(json jResizable)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "resizable",  jResizable));
}

void NB_SetWindowCollapsed(json jCollapsed)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "collapsed",  jCollapsed));
}

void NB_SetWindowClosable(json jCloseable)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "closable",  jCloseable));
}

void NB_SetWindowTransparent(json jTransparent)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "transparent",  jTransparent));
}

void NB_SetWindowBorder(json jBorder)
{
    NB_SetWindow(JsonObjectSet(NB_GetWindow(), "border",  jBorder));
}

void NB_SetWindowTitlebarHidden()
{
    NB_SetWindowTitle(JsonBool(FALSE));
    NB_SetWindowCollapsed(JsonBool(FALSE));
    NB_SetWindowClosable(JsonBool(FALSE));
}

json NB_FinalizeWindow()
{
    NB_LogDebug("* FINALIZE WINDOW");
    NB_SetWindowRoot(NB_GetData());
    return NB_GetWindow();
}

