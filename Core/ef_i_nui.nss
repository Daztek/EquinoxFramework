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

json NuiGetCenteredGeometryRect(object oPlayer, float fWindowWidth, float fWindowHeight);
float NuiGetMouseScrollDelta(json jPayload);
int NuiGetMouseButton(json jPayload);
void NuiSetClickthroughProtection(object oPlayer = OBJECT_SELF, float fSeconds = 0.5f);
int NuiGetClickthroughProtection(object oPlayer = OBJECT_SELF);
int NuiGetIdFromElement(string sElement, string sPrefix);

json NuiGetCenteredGeometryRect(object oPlayer, float fWindowWidth, float fWindowHeight)
{
    float fGuiScale = IntToFloat(GetPlayerDeviceProperty(oPlayer, PLAYER_DEVICE_PROPERTY_GUI_SCALE)) / 100.0f;

    float fX = IntToFloat(GetPlayerDeviceProperty(oPlayer, PLAYER_DEVICE_PROPERTY_GUI_WIDTH) / 2) - ((fWindowWidth * 0.5f) * fGuiScale);
    float fY = IntToFloat(GetPlayerDeviceProperty(oPlayer, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT) / 2) - ((fWindowHeight * 0.5f) * fGuiScale);

    return NuiRect(fX, fY, fWindowWidth, fWindowHeight);
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
