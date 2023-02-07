const int NUI_DIRECTION_HORIZONTAL         = 0;
const int NUI_DIRECTION_VERTICAL           = 1;

const int NUI_MOUSE_BUTTON_LEFT            = 0;
const int NUI_MOUSE_BUTTON_MIDDLE          = 1;
const int NUI_MOUSE_BUTTON_RIGHT           = 2;

const int NUI_SCROLLBARS_NONE              = 0;
const int NUI_SCROLLBARS_X                 = 1;
const int NUI_SCROLLBARS_Y                 = 2;
const int NUI_SCROLLBARS_BOTH              = 3;
const int NUI_SCROLLBARS_AUTO              = 4;

const int NUI_ASPECT_FIT                   = 0;
const int NUI_ASPECT_FILL                  = 1;
const int NUI_ASPECT_FIT100                = 2;
const int NUI_ASPECT_EXACT                 = 3;
const int NUI_ASPECT_EXACTSCALED           = 4;
const int NUI_ASPECT_STRETCH               = 5;

const int NUI_HALIGN_CENTER                = 0;
const int NUI_HALIGN_LEFT                  = 1;
const int NUI_HALIGN_RIGHT                 = 2;

const int NUI_VALIGN_MIDDLE                = 0;
const int NUI_VALIGN_TOP                   = 1;
const int NUI_VALIGN_BOTTOM                = 2;

// -----------------------
// Style

const float NUI_STYLE_PRIMARY_WIDTH        = 150.0;
const float NUI_STYLE_PRIMARY_HEIGHT       = 50.0;

const float NUI_STYLE_SECONDARY_WIDTH      = 150.0;
const float NUI_STYLE_SECONDARY_HEIGHT     = 35.0;

const float NUI_STYLE_TERTIARY_WIDTH       = 100.0;
const float NUI_STYLE_TERTIARY_HEIGHT      = 30.0;

const float NUI_STYLE_ROW_HEIGHT           = 25.0;

// -----------------------
// Window

// Special cases:
// * Set the window title to JsonBool(FALSE), Collapse to JsonBool(FALSE) and bClosable to FALSE
//   to hide the title bar.
//   Note: You MUST provide a way to close the window some other way, or the user will be stuck with it.
// - jRoot: Layout-ish (NuiRow, NuiCol, NuiGroup)
// - jTitle: Bind:String
// - jGeometry: Bind:Rect, Set x&y to -1.0 to center window
// - jResizable: Bind:Bool, Set to JsonBool(TRUE) or JsonNull() to let user resize without binding.
// - jCollapsed: Bind:Bool, Set to a static value JsonBool(FALSE) to disable collapsing. Set to JsonNull() to let user collapse without binding. For better UX, leave collapsing on.
// - jCloseable: Bind:Bool, You must provide a way to close the window if you set this to FALSE. For better UX, handle the window "closed" event
// - jTransparent: Bind:Bool, Do not render background
// - jBorder: Bind:Bool, Render a border
// - jAcceptsInput: Bind:Bool, Set JsonBool(FALSE) to disable all input. All hover, clicks and keypresses will fall through.
json NuiWindow(json jRoot, json jTitle, json jGeometry, json jResizable, json jCollapsed, json jClosable, json jTransparent, json jBorder, json jAcceptsInput);

// -----------------------
// Values

// Create a dynamic bind. Unlike static values, these can change at runtime:
//    NuiBind("mybindlabel");
//    NuiSetBind(.., "mybindlabel", JsonString("hi"));
// To create static values, just use the json types directly:
//    JsonString("hi");
json NuiBind(string sId);

// Tag the given element with a id.
// Only tagged elements will send events to the server.
json NuiId(json jElem, string sId);

// A shim/helper that can be used to render or bind a strref where otherwise
// a string value would go.
json NuiStrRef(int nStrRef);

// -----------------------
// Layout

// A column will auto-space all elements inside of it and advise the parent
// about it's desired size.
// - jList: Layout[] or Element[]
json NuiCol(json jList);

// A row will auto-space all elements inside of it and advise the parent
// about it's desired size.
// - jList: Layout[] or Element[]
json NuiRow(json jList);

// A group, usually with a border and some padding, holding a single element. Can scroll.
// Will not advise parent of size, so you need to let it fill a span (col/row) as if it was
// a element.
// - jChild: Layout or Element
json NuiGroup(json jChild, int bBorder = TRUE, int nScroll = NUI_SCROLLBARS_AUTO);

// Modifiers/Attributes: These are all static and cannot be bound, since the UI system
// cannot easily reflow once the layout is set up. You need to swap the layout if you
// want to change element geometry.

// - jElem: Element
// - fWidth: Float: Element width in pixels (strength=required).
json NuiWidth(json jElem, float fWidth);

// - jElem: Element
// - fHeight: Float: Height in pixels (strength=required).
json NuiHeight(json jElem, float fHeight);

// - jElem: Element
// - fAspect: Float: Ratio of x/y
json NuiAspect(json jElem, float fAspect);

// Set a margin on the widget. The margin is the spacing outside of the widget.
json NuiMargin(json jElem, float fMargin);

// Set padding on the widget. The margin is the spacing inside of the widget.
json NuiPadding(json jElem, float fPadding);

// Disabled elements are non-interactive and greyed out.
// - jElem: Element
// - jEnabled: Bind:Bool
json NuiEnabled(json jElem, json jEnabler);

// Invisible elements do not render at all, but still take up layout space.
// - jElem: Element
// - jVisible: Bind:Bool
json NuiVisible(json jElem, json jVisible);

// Tooltips show on mouse hover.
// - jElem: Element
// - jTooltip: Bind:String
json NuiTooltip(json jElem, json jTooltip);

// Tooltips for disabled elements show on mouse hover.
// - jElem: Element
// - jTooltip: Bind:String
json NuiDisabledTooltip(json jElem, json jTooltip);

// Encouraged elements have a breathing animated glow inside of it.
// - jElem: Element
// - jEncouraged: Bind:Bool
json NuiEncouraged(json jElem, json jEncouraged);

// -----------------------
// Props & Style

json NuiVec(float x, float y);

json NuiRect(float x, float y, float w, float h);

json NuiColor(int r, int g, int b, int a = 255);

// Style the foreground color of the widget. This is dependent on the widget
// in question and only supports solid/full colors right now (no texture skinning).
// For example, labels would style their text color; progress bars would style the bar.
// - jElem: Element
// - jColor: Bind:Color
json NuiStyleForegroundColor(json jElem, json jColor);

// -----------------------
// Widgets

// A special widget that just takes up layout space.
// If you add multiple spacers to a span, they will try to size equally.
//  e.g.: [ <spacer> <button|w=50> <spacer> ] will try to center the button.
json NuiSpacer();

// Create a label field. Labels are single-line stylable non-editable text fields.
// - jValue: Bind:String
// - jHAlign: Bind:Int:NUI_HALIGN_*
// - jVAlign: Bind:Int:NUI_VALIGN_*
json NuiLabel(json jValue, json jHAlign, json jVAlign);

// Create a non-editable text field. Note: This text field internally implies a NuiGroup wrapped
// around it, which is providing the optional border and scrollbars.
// - jValue: Bind:String
// - bBorder: Bool
// - nScroll: Int:NUI_SCROLLBARS_*
json NuiText(json jValue, int bBorder = TRUE, int nScroll = NUI_SCROLLBARS_AUTO);

// A clickable button with text as the label.
// Sends "click" events on click.
// - jLabel: Bind:String
json NuiButton(json jLabel);

// A clickable button with an image as the label.
// Sends "click" events on click.
// - jResRef: Bind:String
json NuiButtonImage(json jResRef);

// A clickable button with text as the label.
// Same as the normal button, but this one is a toggle.
// Sends "click" events on click.
// - jLabel: Bind:String
// - jValue: Bind:Bool
json NuiButtonSelect(json jLabel, json jValue);

// A checkbox with a label to the right of it.
// - jLabel: Bind:String
// - jBool: Bind:Bool
json NuiCheck(json jLabel, json jBool);

// A image, with no border or padding.
// - jResRef: Bind:String
// - jAspect: Bind:Int:NUI_ASPECT_*
// - jHAlign: Bind:Int:NUI_HALIGN_*
// - jVAlign: Bind:Int:NUI_VALIGN_*
json NuiImage(json jResRef, json jAspect, json jHAlign, json jVAlign);

// Optionally render only subregion of jImage.
// jRegion is a NuiRect (x, y, w, h) to indicate the render region inside the image.
json NuiImageRegion(json jImage, json jRegion);

// A combobox/dropdown.
// - jElements: Bind:ComboEntry[]
// - jSelected: Bind:Int (index into jElements)
json NuiCombo(json jElements, json jSelected);

json NuiComboEntry(string sLabel, int nValue);

// A floating-point slider. A good step size for normal-sized sliders is 0.01.
// - jValue: Bind:Float
// - jMin: Bind:Float
// - jMax: Bind:Float
// - jStepSize: Bind:Float
json NuiSliderFloat(json jValue, json jMin, json jMax, json jStepSize);

// A integer/discrete slider.
// - jValue: Bind:Int
// - jMin: Bind:Int
// - jMax: Bind:Int
// - jStepSize: Bind:Int
json NuiSlider(json jValue, json jMin, json jMax, json jStepSize);

// A progress bar. Progress is always from 0.0 to 1.0.
// - jValue: Bind:Float (0.0->1.0
json NuiProgress(json jValue);

// A editable text field.
// - jPlaceholder: Bind:String
// - jValue: Bind:String
// - nMaxLength: UInt >= 1, <= 65535
// - bMultiLine: Bool
// - bWordWrap: Bool
json NuiTextEdit(json jPlaceholder, json jValue, int nMaxLength, int bMultiline, int bWordWrap = TRUE);

// Creates a list view of elements.
// jTemplate needs to be an array of NuiListTemplateCell instances.
// All binds referenced in jTemplate should be arrays of rRowCount size;
// e.g. when rendering a NuiLabel(), the bound label String should be an array of strings.
// You can pass in one of the template jRowCount into jSize as a convenience. The array
// size will be uses as the Int bind.
// fRowHeight defines the height of the rendered rows.
// - jTemplate: NuiListTemplateCell[] (max: 16)
// - jRowCount: Bind:Int
// - bBorder: Bool
// - nScroll: Int:NUI_SCROLLBARS_*, Note: Cannot be AUTO
json NuiList(json jTemplate, json jRowCount, float fRowHeight = NUI_STYLE_ROW_HEIGHT, int bBorder = TRUE, int nScroll = NUI_SCROLLBARS_Y);

// - jElem: Element
// - fWidth: Float:0 = auto, >1 = pixel width
// - bVariable: Bool:Cell can grow if space is available; otherwise static
json NuiListTemplateCell(json jElem, float fWidth, int bVariable);

// A simple color picker, with no border or spacing.
// - jColor: Bind:Color
json NuiColorPicker(json jColor);

// A list of options (radio buttons). Only one can be selected
// at a time. jValue is updated every time a different element is
// selected. The special value -1 means "nothing".
// - nDirection: NUI_DIRECTION_*
// - jElements: JsonArray of string labels
// - jValue: Bind:UInt
json NuiOptions(int nDirection, json jElements, json jValue);

// A group of buttons. Only one can be selected at a time. jValue
// is updated every time a different button is selected. The special
// value -1 means "nothing".
// - nDirection: NUI_DIRECTION_*
// - jElements: JsonArray of string labels
// - jValue: Bind:Int
json NuiToggles(int nDirection, json jElements,  json jValue);

const int NUI_CHART_TYPE_LINES                 = 0;
const int NUI_CHART_TYPE_COLUMN                = 1;

// - nType: Int:NUI_CHART_TYPE_*
// - jLegend: Bind:String
// - jColor: Bind:NuiColor
// - jData: Bind:Float[]
json NuiChartSlot(int nType, json jLegend, json jColor, json jData);

// Renders a chart.
// Currently, min and max values are determined automatically and
// cannot be influenced.
// - jSlots: NuiChartSlot[]
json NuiChart( json jSlots);

// -----------------------
// Draw Lists

// Draw lists are raw painting primitives on top of widgets.
// They are anchored to the widget x/y coordinates, and are always
// painted in order of definition, without culling. You cannot bind
// the draw_list itself, but most parameters on individual draw_list
// entries can be bound.

const int NUI_DRAW_LIST_ITEM_TYPE_POLYLINE     = 0;
const int NUI_DRAW_LIST_ITEM_TYPE_CURVE        = 1;
const int NUI_DRAW_LIST_ITEM_TYPE_CIRCLE       = 2;
const int NUI_DRAW_LIST_ITEM_TYPE_ARC          = 3;
const int NUI_DRAW_LIST_ITEM_TYPE_TEXT         = 4;
const int NUI_DRAW_LIST_ITEM_TYPE_IMAGE        = 5;
const int NUI_DRAW_LIST_ITEM_TYPE_LINE         = 6;

// You can order draw list items to be painted either before, or after the
// builtin render of the widget in question. This enables you to paint "behind"
// a widget.

const int NUI_DRAW_LIST_ITEM_ORDER_BEFORE      = -1;
const int NUI_DRAW_LIST_ITEM_ORDER_AFTER       = 1;

// Always render draw list item (default).
const int NUI_DRAW_LIST_ITEM_RENDER_ALWAYS       = 0;
// Only render when NOT hovering.
const int NUI_DRAW_LIST_ITEM_RENDER_MOUSE_OFF    = 1;
// Only render when mouse is hovering.
const int NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER  = 2;
// Only render while LMB is held down.
const int NUI_DRAW_LIST_ITEM_RENDER_MOUSE_LEFT   = 3;
// Only render while RMB is held down.
const int NUI_DRAW_LIST_ITEM_RENDER_MOUSE_RIGHT  = 4;
// Only render while MMB is held down.
const int NUI_DRAW_LIST_ITEM_RENDER_MOUSE_MIDDLE = 5;

// - jEnabled: Bind:Bool
// - jColor: Bind:Color
// - jFill: Bind:Bool
// - jLineThickness: Bind:Float
// - jPoints: Bind:Float[] Always provide points in pairs
// - nOrder: Int:NUI_DRAW_LIST_ITEM_ORDER_*
// - nRender: Int:NUI_DRAW_LIST_ITEM_RENDER_*
json NuiDrawListPolyLine(json jEnabled, json jColor, json jFill, json jLineThickness, json jPoints, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER, int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

// - jEnabled: Bind:Bool
// - jColor: Bind:Color
// - jLineThickness: Bind:Float
// - jA: Bind:Vec2
// - jB: Bind:Vec2
// - jCtrl0: Bind:Vec2
// - jCtrl1: Bind:Vec2
// - nOrder: Int:NUI_DRAW_LIST_ITEM_ORDER_*
// - nRender: Int:NUI_DRAW_LIST_ITEM_RENDER_*
json NuiDrawListCurve(json jEnabled, json jColor, json jLineThickness, json jA, json jB, json jCtrl0, json jCtrl1, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER, int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

// - jEnabled: Bind:Bool
// - jColor: Bind:Color
// - jFill: Bind:Bool
// - jLineThickness: Bind:Float
// - jRect: Bind:Rect
// - nOrder: Int:NUI_DRAW_LIST_ITEM_ORDER_*
// - nRender: Int:NUI_DRAW_LIST_ITEM_RENDER_*
json NuiDrawListCircle(json jEnabled, json jColor, json jFill, json jLineThickness, json jRect, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER, int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

// - jEnabled: Bind:Bool
// - jColor: Bind:Color
// - jFill: Bind:Bool
// - jLineThickness: Bind:Float
// - jCenter: Bind:Rect
// - jRadius: Bind:Float
// - jAMin: Bind:Float
// - jAMax: Bind:Float
// - nOrder: Int:NUI_DRAW_LIST_ITEM_ORDER_*
// - nRender: Int:NUI_DRAW_LIST_ITEM_RENDER_*
json NuiDrawListArc(json jEnabled, json jColor, json jFill, json jLineThickness, json jCenter, json jRadius, json jAMin, json jAMax, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER, int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

// - jEnabled: Bind:Bool
// - jColor: Bind:Color
// - jRect: Bind:Rect
// - jText: Bind:String
// - nOrder: Int:NUI_DRAW_LIST_ITEM_ORDER_*
// - nRender: Int:NUI_DRAW_LIST_ITEM_RENDER_*
json NuiDrawListText(json jEnabled, json jColor, json jRect, json jText, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER, int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

// - jEnabled: Bind:Bool
// - jResRef: Bind:String
// - jPos: Bind:Rect
// - jAspect: Bind:Int:NUI_ASPECT_*
// - jHAlign: Bind:Int:NUI_HALIGN_*
// - jVAlign: Bind:Int:NUI_VALIGN_*
// - nOrder: Int:NUI_DRAW_LIST_ITEM_ORDER_*
// - nRender: Int:NUI_DRAW_LIST_ITEM_RENDER_*
json NuiDrawListImage(json jEnabled, json jResRef, json jPos, json jAspect, json jHAlign, json jVAlign, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER, int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

// - jDrawListImage: DrawListItemImage
// - jRegion: Bind:NuiRect
json NuiDrawListImageRegion(json jDrawListImage, json jRegion);

// - jEnabled: Bind:Bool
// - jColor: Bind:Color
// - jLineThickness: Bind:Float
// - jA: Bind:Vec2
// - jB: Bind:Vec2
// - nOrder: Int:NUI_DRAW_LIST_ITEM_ORDER_*
// - nRender: Int:NUI_DRAW_LIST_ITEM_RENDER_*
json NuiDrawListLine(json jEnabled, json jColor, json jLineThickness, json jA, json jB, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER, int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

// - jElem: Element
// - jScissor: Bind:Bool, Constrain painted elements to widget bounds.
// - jList: DrawListItem[]
json NuiDrawList(json jElem, json jScissor, json jList);

// -----------------------
// Implementation

json
NuiWindow(
  json jRoot,
  json jTitle,
  json jGeometry,
  json jResizable,
  json jCollapsed,
  json jClosable,
  json jTransparent,
  json jBorder,
  json jAcceptsInput
)
{
  json ret = JsonObject();
  // Currently hardcoded and here to catch backwards-incompatible data in the future.
  ret = JsonObjectSet(ret, "version", JsonInt(1));
  ret = JsonObjectSet(ret, "title", jTitle);
  ret = JsonObjectSet(ret, "root", jRoot);
  ret = JsonObjectSet(ret, "geometry", jGeometry);
  ret = JsonObjectSet(ret, "resizable", jResizable);
  ret = JsonObjectSet(ret, "collapsed", jCollapsed);
  ret = JsonObjectSet(ret, "closable", jClosable);
  ret = JsonObjectSet(ret, "transparent", jTransparent);
  ret = JsonObjectSet(ret, "border", jBorder);
  ret = JsonObjectSet(ret, "accepts_input", jAcceptsInput);
  return ret;
}

json
NuiElement(
  string sType,
  json jLabel,
  json jValue
)
{
    json ret = JsonObject();
    ret = JsonObjectSet(ret, "type", JsonString(sType));
    ret = JsonObjectSet(ret, "label", jLabel);
    ret = JsonObjectSet(ret, "value", jValue);
    return ret;
}

json
NuiBind(
  string sId
)
{
  return JsonObjectSet(JsonObject(), "bind", JsonString(sId));
}

json
NuiId(
  json jElem,
  string sId
)
{
  return JsonObjectSet(jElem, "id", JsonString(sId));
}

json
NuiStrRef(
    int nStrRef
)
{
    json ret = JsonObject();
    ret = JsonObjectSet(ret, "strref", JsonInt(nStrRef));
    return ret;
}

json
NuiCol(
  json jList
)
{
  return JsonObjectSet(NuiElement("col", JsonNull(), JsonNull()), "children", jList);
}

json
NuiRow(
  json jList
)
{
  return JsonObjectSet(NuiElement("row", JsonNull(), JsonNull()), "children", jList);
}

json
NuiGroup(
  json jChild,
  int bBorder = TRUE,
  int nScroll = NUI_SCROLLBARS_AUTO
)
{
  json ret = NuiElement("group", JsonNull(), JsonNull());
  ret = JsonObjectSet(ret, "children", JsonArrayInsert(JsonArray(), jChild));
  ret = JsonObjectSet(ret, "border", JsonBool(bBorder));
  ret = JsonObjectSet(ret, "scrollbars", JsonInt(nScroll));
  return ret;
}

json
NuiWidth(json jElem, float fWidth)
{
  return JsonObjectSet(jElem, "width", JsonFloat(fWidth));
}

json
NuiHeight(json jElem, float fHeight)
{
  return JsonObjectSet(jElem, "height", JsonFloat(fHeight));
}

json
NuiAspect(json jElem, float fAspect)
{
  return JsonObjectSet(jElem, "aspect", JsonFloat(fAspect));
}

json
NuiMargin(
  json jElem,
  float fMargin
)
{
  return JsonObjectSet(jElem, "margin", JsonFloat(fMargin));
}

json
NuiPadding(
  json jElem,
  float fPadding
)
{
  return JsonObjectSet(jElem, "padding", JsonFloat(fPadding));
}

json
NuiEnabled(
  json jElem,
  json jEnabler
)
{
  return JsonObjectSet(jElem, "enabled", jEnabler);
}

json
NuiVisible(
  json jElem,
  json jVisible
)
{
  return JsonObjectSet(jElem, "visible", jVisible);
}

json
NuiTooltip(
  json jElem,
  json jTooltip
)
{
  return JsonObjectSet(jElem, "tooltip", jTooltip);
}

json
NuiDisabledTooltip(
  json jElem,
  json jTooltip
)
{
  return JsonObjectSet(jElem, "disabled_tooltip", jTooltip);
}

json
NuiEncouraged(
  json jElem,
  json jEncouraged
)
{
  return JsonObjectSet(jElem, "encouraged", jEncouraged);
}

json
NuiVec(float x, float y)
{
  json ret = JsonObject();
  ret = JsonObjectSet(ret, "x", JsonFloat(x));
  ret = JsonObjectSet(ret, "y", JsonFloat(y));
  return ret;
}

json
NuiRect(float x, float y, float w, float h)
{
  json ret = JsonObject();
  ret = JsonObjectSet(ret, "x", JsonFloat(x));
  ret = JsonObjectSet(ret, "y", JsonFloat(y));
  ret = JsonObjectSet(ret, "w", JsonFloat(w));
  ret = JsonObjectSet(ret, "h", JsonFloat(h));
  return ret;
}

json
NuiColor(int r, int g, int b, int a = 255)
{
  json ret = JsonObject();
  ret = JsonObjectSet(ret, "r", JsonInt(r));
  ret = JsonObjectSet(ret, "g", JsonInt(g));
  ret = JsonObjectSet(ret, "b", JsonInt(b));
  ret = JsonObjectSet(ret, "a", JsonInt(a));
  return ret;
}

json
NuiStyleForegroundColor(
  json jElem,
  json jColor
)
{
  return JsonObjectSet(jElem, "foreground_color", jColor);
}

json
NuiSpacer()
{
  return NuiElement("spacer", JsonNull(), JsonNull());
}

json
NuiLabel(
  json jValue,
  json jHAlign,
  json jVAlign
)
{
  json ret = NuiElement("label", JsonNull(), jValue);
  ret = JsonObjectSet(ret, "text_halign", jHAlign);
  ret = JsonObjectSet(ret, "text_valign", jVAlign);
  return ret;
}

json
NuiText(
  json jValue,
  int bBorder = TRUE,
  int nScroll = NUI_SCROLLBARS_AUTO
)
{
  json ret = NuiElement("text", JsonNull(), jValue);
  ret = JsonObjectSet(ret, "border", JsonBool(bBorder));
  ret = JsonObjectSet(ret, "scrollbars", JsonInt(nScroll));
  return ret;
}

json
NuiButton(
  json jLabel
)
{
  return NuiElement("button", jLabel, JsonNull());
}

json
NuiButtonImage(
  json jResRef
)
{
  return NuiElement("button_image", jResRef, JsonNull());
}

json
NuiButtonSelect(
  json jLabel,
  json jValue
)
{
  return NuiElement("button_select", jLabel, jValue);
}

json
NuiCheck(
  json jLabel,
  json jBool
)
{
  return NuiElement("check", jLabel, jBool);
}

json
NuiImage(
  json jResRef,
  json jAspect,
  json jHAlign,
  json jVAlign
)
{
  json img = NuiElement("image", JsonNull(), jResRef);
  img = JsonObjectSet(img, "image_aspect", jAspect);
  img = JsonObjectSet(img, "image_halign", jHAlign);
  img = JsonObjectSet(img, "image_valign", jVAlign);
  return img;
}

json
NuiImageRegion(
    json jImage,
    json jRegion
)
{
    return JsonObjectSet(jImage, "image_region", jRegion);
}

json
NuiCombo(
  json jElements,
  json jSelected
)
{
  return JsonObjectSet(NuiElement("combo", JsonNull(), jSelected), "elements", jElements);
}

json
NuiComboEntry(
  string sLabel,
  int nValue
)
{
  return JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonString(sLabel)), JsonInt(nValue));
}

json
NuiSliderFloat(
  json jValue,
  json jMin,
  json jMax,
  json jStepSize
)
{
  json ret = NuiElement("sliderf", JsonNull(), jValue);
  ret = JsonObjectSet(ret, "min", jMin);
  ret = JsonObjectSet(ret, "max", jMax);
  ret = JsonObjectSet(ret, "step", jStepSize);
  return ret;
}

json
NuiSlider(
  json jValue,
  json jMin,
  json jMax,
  json jStepSize
)
{
  json ret = NuiElement("slider", JsonNull(), jValue);
  ret = JsonObjectSet(ret, "min", jMin);
  ret = JsonObjectSet(ret, "max", jMax);
  ret = JsonObjectSet(ret, "step", jStepSize);
  return ret;
}

json
NuiProgress(
  json jValue
)
{
  return NuiElement("progress", JsonNull(), jValue);
}

json
NuiTextEdit(
  json jPlaceholder,
  json jValue,
  int nMaxLength,
  int bMultiline,
  int bWordWrap = TRUE
)
{
  json ret = NuiElement("textedit", jPlaceholder, jValue);
  ret = JsonObjectSet(ret, "max", JsonInt(nMaxLength));
  ret = JsonObjectSet(ret, "multiline", JsonBool(bMultiline));
  ret = JsonObjectSet(ret, "wordwrap", JsonBool(bWordWrap));
  return ret;
}

json
NuiList(
  json jTemplate,
  json jRowCount,
  float fRowHeight = NUI_STYLE_ROW_HEIGHT,
  int bBorder = TRUE,
  int nScroll = NUI_SCROLLBARS_Y
)
{
  json ret = NuiElement("list", JsonNull(), JsonNull());
  ret = JsonObjectSet(ret, "row_template", jTemplate);
  ret = JsonObjectSet(ret, "row_count", jRowCount);
  ret = JsonObjectSet(ret, "row_height", JsonFloat(fRowHeight));
  ret = JsonObjectSet(ret, "border", JsonBool(bBorder));
  ret = JsonObjectSet(ret, "scrollbars", JsonInt(nScroll));
  return ret;
}

json
NuiListTemplateCell(
  json jElem,
  float fWidth,
  int bVariable
)
{
  json ret = JsonArray();
  ret = JsonArrayInsert(ret, jElem);
  ret = JsonArrayInsert(ret, JsonFloat(fWidth));
  ret = JsonArrayInsert(ret, JsonBool(bVariable));
  return ret;
}

json
NuiColorPicker(
  json jColor
)
{
  json ret = NuiElement("color_picker", JsonNull(), jColor);
  return ret;
}

json
NuiOptions(
  int nDirection,
  json jElements,
  json jValue
)
{
  json ret = NuiElement("options", JsonNull(), jValue);
  ret = JsonObjectSet(ret, "direction", JsonInt(nDirection));
  ret = JsonObjectSet(ret, "elements", jElements);
  return ret;
}

json
NuiToggles(
  int nDirection,
  json jElements,
  json jValue
)
{
  json ret = NuiElement("tabbar", JsonNull(), jValue);
  ret = JsonObjectSet(ret, "direction", JsonInt(nDirection));
  ret = JsonObjectSet(ret, "elements", jElements);
  return ret;
}

json
NuiChartSlot(
  int nType,
  json jLegend,
  json jColor,
  json jData
)
{
  json ret = JsonObject();
  ret = JsonObjectSet(ret, "type", JsonInt(nType));
  ret = JsonObjectSet(ret, "legend", jLegend);
  ret = JsonObjectSet(ret, "color", jColor);
  ret = JsonObjectSet(ret, "data", jData);
  return ret;
}

json
NuiChart(
  json jSlots
)
{
  json ret = NuiElement("chart", JsonNull(), jSlots);
  return ret;
}

json
NuiDrawListItem(
  int nType,
  json jEnabled,
  json jColor,
  json jFill,
  json jLineThickness,
  int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER,
  int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
)
{
  json ret = JsonObject();
  ret = JsonObjectSet(ret, "type", JsonInt(nType));
  ret = JsonObjectSet(ret, "enabled", jEnabled);
  ret = JsonObjectSet(ret, "color", jColor);
  ret = JsonObjectSet(ret, "fill", jFill);
  ret = JsonObjectSet(ret, "line_thickness", jLineThickness);
  ret = JsonObjectSet(ret, "order", JsonInt(nOrder));
  ret = JsonObjectSet(ret, "render", JsonInt(nRender));
  return ret;
}

json
NuiDrawListPolyLine(
  json jEnabled,
  json jColor,
  json jFill,
  json jLineThickness,
  json jPoints,
  int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER,
  int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
)
{
  json ret = NuiDrawListItem(NUI_DRAW_LIST_ITEM_TYPE_POLYLINE, jEnabled, jColor, jFill, jLineThickness, nOrder, nRender);
  ret = JsonObjectSet(ret, "points", jPoints);
  return ret;
}

json
NuiDrawListCurve(
  json jEnabled,
  json jColor,
  json jLineThickness,
  json jA,
  json jB,
  json jCtrl0,
  json jCtrl1,
  int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER,
  int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
)
{
  json ret = NuiDrawListItem(NUI_DRAW_LIST_ITEM_TYPE_CURVE, jEnabled, jColor, JsonBool(0), jLineThickness, nOrder, nRender);
  ret = JsonObjectSet(ret, "a", jA);
  ret = JsonObjectSet(ret, "b", jB);
  ret = JsonObjectSet(ret, "ctrl0", jCtrl0);
  ret = JsonObjectSet(ret, "ctrl1", jCtrl1);
  return ret;
}

json
NuiDrawListCircle(
  json jEnabled,
  json jColor,
  json jFill,
  json jLineThickness,
  json jRect,
  int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER,
  int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
)
{
  json ret = NuiDrawListItem(NUI_DRAW_LIST_ITEM_TYPE_CIRCLE, jEnabled, jColor, jFill, jLineThickness, nOrder, nRender);
  ret = JsonObjectSet(ret, "rect", jRect);
  return ret;
}

json
NuiDrawListArc(
  json jEnabled,
  json jColor,
  json jFill,
  json jLineThickness,
  json jCenter,
  json jRadius,
  json jAMin,
  json jAMax,
  int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER,
  int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
)
{
  json ret = NuiDrawListItem(NUI_DRAW_LIST_ITEM_TYPE_ARC, jEnabled, jColor, jFill, jLineThickness, nOrder, nRender);
  ret = JsonObjectSet(ret, "c", jCenter);
  ret = JsonObjectSet(ret, "radius", jRadius);
  ret = JsonObjectSet(ret, "amin", jAMin);
  ret = JsonObjectSet(ret, "amax", jAMax);
  return ret;
}

json
NuiDrawListText(
  json jEnabled,
  json jColor,
  json jRect,
  json jText,
  int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER,
  int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
)
{
  json ret = NuiDrawListItem(NUI_DRAW_LIST_ITEM_TYPE_TEXT, jEnabled, jColor, JsonNull(), JsonNull(), nOrder, nRender);
  ret = JsonObjectSet(ret, "rect", jRect);
  ret = JsonObjectSet(ret, "text", jText);
  return ret;
}

json
NuiDrawListImage(
  json jEnabled,
  json jResRef,
  json jRect,
  json jAspect,
  json jHAlign,
  json jVAlign,
  int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER,
  int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
)
{
  json ret = NuiDrawListItem(NUI_DRAW_LIST_ITEM_TYPE_IMAGE, jEnabled, JsonNull(), JsonNull(), JsonNull(), nOrder, nRender);
  ret = JsonObjectSet(ret, "image", jResRef);
  ret = JsonObjectSet(ret, "rect", jRect);
  ret = JsonObjectSet(ret, "image_aspect", jAspect);
  ret = JsonObjectSet(ret, "image_halign", jHAlign);
  ret = JsonObjectSet(ret, "image_valign", jVAlign);
  return ret;
}

json
NuiDrawListImageRegion(
  json jDrawListImage,
  json jRegion
)
{
    return JsonObjectSet(jDrawListImage, "image_region", jRegion);
}

json
NuiDrawListLine(
  json jEnabled,
  json jColor,
  json jLineThickness,
  json jA,
  json jB,
  int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER,
  int nRender = NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
)
{
  json ret = NuiDrawListItem(NUI_DRAW_LIST_ITEM_TYPE_LINE, jEnabled, jColor, JsonNull(), jLineThickness, nOrder, nRender);
  ret = JsonObjectSet(ret, "a", jA);
  ret = JsonObjectSet(ret, "b", jB);
  return ret;
}

json
NuiDrawList(
  json jElem,
  json jScissor,
  json jList
)
{
  json ret = JsonObjectSet(jElem, "draw_list", jList);
  ret = JsonObjectSet(ret, "draw_list_scissor", jScissor);
  return ret;
}

// json
// NuiCanvas(
//   json jList
// )
// {
//   json ret = NuiElement("canvas", JsonNull(), jList);
//   return ret;
// }
