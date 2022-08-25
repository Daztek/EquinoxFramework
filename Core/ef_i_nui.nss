/*
    Script: ef_i_nui
    Author: Daz

    Description: Equinox Framework NUI Utility Include
*/

#include "ef_i_json"
#include "nw_inc_nui"

const string NUI_WINDOW_ROOT_GROUP          = "_window_";

const string NUI_WINDOW_GEOMETRY_BIND       = "NUIWindowGeometry";

const string NUI_EVENT_OPEN                 = "open";
const string NUI_EVENT_CLOSE                = "close";
const string NUI_EVENT_CLICK                = "click";
const string NUI_EVENT_WATCH                = "watch";
const string NUI_EVENT_MOUSEDOWN            = "mousedown";
const string NUI_EVENT_MOUSEUP              = "mouseup";
const string NUI_EVENT_MOUSESCROLL          = "mousescroll";
const string NUI_EVENT_FOCUS                = "focus";
const string NUI_EVENT_BLUR                 = "blur";

const string NUI_DEFAULT_GEOMETRY_NAME      = "default_geometry";

const float NUI_TITLEBAR_HEIGHT             = 33.0f;

json NuiGetAdjustedWindowGeometryRect(object oPlayer, json jRect);
float NuiGetMouseScrollDelta(json jPayload);
int NuiGetMouseButton(json jPayload);
void NuiSetClickthroughProtection(object oPlayer = OBJECT_SELF, float fSeconds = 0.5f);
int NuiGetClickthroughProtection(object oPlayer = OBJECT_SELF);
int NuiGetIdFromElement(string sElement, string sPrefix);
json NuiRectReplacePosition(json jOldRect, json jNewRect);
void PrintNuiRect(json jRect);
int GetIsDefaultNuiRect(json jRect);
int GetNuiRectSizeMatches(json jRect1, json jRect2);

json NuiGetAdjustedWindowGeometryRect(object oPlayer, json jRect)
{
    float fX = JsonObjectGetFloat(jRect, "x"); 
    float fY = JsonObjectGetFloat(jRect, "y");
    
    if (fX != -1.0f && fY != -1.0f)
        return jRect;

    float fWidth = JsonObjectGetFloat(jRect, "w");
    float fHeight = JsonObjectGetFloat(jRect, "h");  
    float fGuiScale = IntToFloat(GetPlayerDeviceProperty(oPlayer, PLAYER_DEVICE_PROPERTY_GUI_SCALE)) / 100.0f;

    if (fX == -1.0f)
        fX = IntToFloat(GetPlayerDeviceProperty(oPlayer, PLAYER_DEVICE_PROPERTY_GUI_WIDTH) / 2) - ((fWidth * 0.5f) * fGuiScale);
    if (fY == -1.0f)
        fY = IntToFloat(GetPlayerDeviceProperty(oPlayer, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT) / 2) - ((fHeight * 0.5f) * fGuiScale);

    return NuiRect(fX, fY, fWidth, fHeight);
}

float NuiGetMouseScrollDelta(json jPayload)
{
    return JsonObjectGetFloat(JsonObjectGet(jPayload, "mouse_scroll"), "y");
}

int NuiGetMouseButton(json jPayload)
{
    return JsonObjectGetInt(jPayload, "mouse_btn");
}

void NuiSetClickthroughProtection(object oPlayer = OBJECT_SELF, float fSeconds = 0.5f)
{
    SetLocalInt(oPlayer, "CLICKTHROUGH_PROTECTION", NuiGetClickthroughProtection(oPlayer) + 1);
    DelayCommand(fSeconds, SetLocalInt(oPlayer, "CLICKTHROUGH_PROTECTION", NuiGetClickthroughProtection(oPlayer) - 1));
}

int NuiGetClickthroughProtection(object oPlayer = OBJECT_SELF)
{
    return GetLocalInt(oPlayer, "CLICKTHROUGH_PROTECTION");
}

int NuiGetIdFromElement(string sElement, string sPrefix)
{
    return StringToInt(GetStringRight(sElement, GetStringLength(sElement) - GetStringLength(sPrefix)));
}

json NuiRectReplacePosition(json jOldRect, json jNewRect)
{
    jOldRect = JsonObjectSet(jOldRect, "x", JsonObjectGet(jNewRect, "x"));
    jOldRect = JsonObjectSet(jOldRect, "y", JsonObjectGet(jNewRect, "y"));
    return jOldRect;
}

void PrintNuiRect(json jRect)
{
    string sX = FloatToString(JsonObjectGetFloat(jRect, "x"), 0, 2);
    string sY = FloatToString(JsonObjectGetFloat(jRect, "y"), 0, 2);
    string sW = FloatToString(JsonObjectGetFloat(jRect, "w"), 0, 2);
    string sH = FloatToString(JsonObjectGetFloat(jRect, "h"), 0, 2);

    PrintString("NuiRect: x=" + sX + ", y=" + sY + ", w=" + sW + ", h=" +sH);
}

int GetIsDefaultNuiRect(json jRect)
{
    return JsonObjectGetFloat(jRect, "x") == 0.0f && 
           JsonObjectGetFloat(jRect, "y") == 0.0f &&
           JsonObjectGetFloat(jRect, "w") == 0.0f &&
           JsonObjectGetFloat(jRect, "h") == 0.0f;    
}

int GetNuiRectSizeMatches(json jRect1, json jRect2)
{
    return JsonObjectGetFloat(jRect1, "w") == JsonObjectGetFloat(jRect2, "w") &&
           JsonObjectGetFloat(jRect1, "h") == JsonObjectGetFloat(jRect2, "h");
}
