/*
    Script: ef_s_dynlight
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_eventman"
#include "nw_inc_dynlight"
#include "nwnx_area"

const string DYNLIGHT_SCRIPT_NAME                       = "ef_s_dynlight";

const int DYNLIGHT_ENABLE_DYNAMIC_LIGHTING              = FALSE;

const string DYNLIGHT_AREA_DYNAMIC_LIGHTING_ENABLED     = "DynLightAreaDynamicLightingEnabled";
const float DYNLIGHT_UPDATE_INTERVAL                    = 15.0f;

void DynLight_InitArea(object oArea);
void DynLight_IntervalHandler();

// @CORE[EF_SYSTEM_LOAD]
void DynLight_Load()
{
    if (DYNLIGHT_ENABLE_DYNAMIC_LIGHTING)
    {
        object oArea = GetFirstArea();
        while (oArea != OBJECT_INVALID)
        {
            DynLight_InitArea(oArea);
            oArea = GetNextArea();
        }

        DynLight_IntervalHandler();
    }
}

void DynLight_InitArea(object oArea)
{
    if(DYNLIGHT_ENABLE_DYNAMIC_LIGHTING && GetIsAreaNatural(oArea) && GetIsAreaAboveGround(oArea))
    {
        SetLocalInt(oArea, DYNLIGHT_AREA_DYNAMIC_LIGHTING_ENABLED, TRUE);
        SetLocalInt(oArea, NW_DYNAMIC_LIGHT_ORIGINAL_AREA_FOG_COLOR, GetFogColor(FOG_TYPE_SUN, oArea));
        SetLocalInt(oArea, NW_DYNAMIC_LIGHT_ORIGINAL_AREA_AMBIENT_COLOR, GetAreaLightColor(AREA_LIGHT_COLOR_SUN_AMBIENT, oArea));
        SetLocalInt(oArea, NW_DYNAMIC_LIGHT_ORIGINAL_AREA_DIFFUSE_COLOR, GetAreaLightColor(AREA_LIGHT_COLOR_SUN_DIFFUSE, oArea));
        EM_ObjectDispatchListInsert(oArea, EM_GetObjectDispatchListId(DYNLIGHT_SCRIPT_NAME, EVENT_SCRIPT_AREA_ON_ENTER));
    }
}

void DynLight_UpdateAreaLight(object oArea, float fFadeTime = 0.0f)
{
    if (fFadeTime > 0.0f)
        fFadeTime += NW_DYNAMIC_LIGHT_FADE_TIME_OVERLAP;

    vector vSunDirection = GetSunlightDirectionFromTime(NW_DYNAMIC_LIGHT_MODULE_GLOBAL_LATITUDE_DEFAULT, fFadeTime);
    vector vMoonDirection = GetMoonlightDirectionFromTime(NW_DYNAMIC_LIGHT_MODULE_GLOBAL_LATITUDE_DEFAULT, fFadeTime);

    SetAreaLightDirection(AREA_LIGHT_DIRECTION_SUN, vSunDirection, oArea, fFadeTime);
    SetAreaLightDirection(AREA_LIGHT_DIRECTION_MOON, vMoonDirection, oArea, fFadeTime);
    ApplyRedshift(oArea, asin(vSunDirection.z), fFadeTime);
}

void DynLight_IntervalHandler()
{
    json jUpdatedAreas = JsonArray();
    object oPlayer = GetFirstPC();
    while (oPlayer != OBJECT_INVALID)
    {
        object oArea = GetArea(oPlayer);

        if (GetIsObjectValid(oArea) &&
            GetLocalInt(oArea, DYNLIGHT_AREA_DYNAMIC_LIGHTING_ENABLED) &&
            !JsonArrayContainsString(jUpdatedAreas, ObjectToString(oArea)))
        {
            DynLight_UpdateAreaLight(oArea, DYNLIGHT_UPDATE_INTERVAL);
            jUpdatedAreas = JsonArrayInsertString(jUpdatedAreas, ObjectToString(oArea));
        }

        oPlayer = GetNextPC();
    }

    DelayCommand(DYNLIGHT_UPDATE_INTERVAL, DynLight_IntervalHandler());
}

// @EVENT[EVENT_SCRIPT_AREA_ON_ENTER:DL]
void DynLight_OnAreaEnter()
{
    object oArea = OBJECT_SELF;

    if (GetIsPC(GetEnteringObject()) &&
        GetLocalInt(oArea, DYNLIGHT_AREA_DYNAMIC_LIGHTING_ENABLED) &&
        NWNX_Area_GetNumberOfPlayersInArea(oArea) == 1)
    {
        DynLight_UpdateAreaLight(oArea);
    }
}
