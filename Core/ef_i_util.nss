/*
    Script: ef_i_util
    Author: Daz

    Description: Utility Include for the Equinox Framework
*/

const int EF_UNSET_INTEGER_VALUE            = 0x7FFFFFFF;

const int OBJECT_TYPE_INTERNAL_MODULE       = 3;
const int OBJECT_TYPE_INTERNAL_AREA         = 4;
const int OBJECT_TYPE_INTERNAL_CREATURE     = 5;
const int OBJECT_TYPE_INTERNAL_ITEM         = 6;
const int OBJECT_TYPE_INTERNAL_TRIGGER      = 7;
const int OBJECT_TYPE_INTERNAL_PLACEABLE    = 9;
const int OBJECT_TYPE_INTERNAL_DOOR         = 10;
const int OBJECT_TYPE_INTERNAL_AREAOFEFFECT = 11;
const int OBJECT_TYPE_INTERNAL_WAYPOINT     = 12;
const int OBJECT_TYPE_INTERNAL_ENCOUNTER    = 13;
const int OBJECT_TYPE_INTERNAL_STORE        = 14;
const int OBJECT_TYPE_INTERNAL_PORTAL       = 15;
const int OBJECT_TYPE_INTERNAL_SOUND        = 16;

const string _FILE_;
const string _FUNCTION_;
const string _ORIGIN_;
const int _LINE_;
const int _FUNCTIONHASH_;

json GetResRefArray(string sPrefix, int nResType, int bSearchBaseData = FALSE, string sOnlyKeyTable = "", json jArray = JSON_NULL);
void RemoveEffectsWithTag(object oObject, string sTag);
string Get2DAStrRefString(string s2DA, string sColumn, int nRow);
void VoidJsonToObject(json jObject, location locLocation, object oOwner = OBJECT_INVALID, int bLoadObjectState = FALSE);
string GetItemName(object oItem, int bIdentified);
vector GetAreaCenterPosition(object oArea, float fZ = 0.0f);
vector GetTilePosition(int nX, int nY);
int GetLocationWalkable(location loc);
int GetHasEffectType(object oObject, int nEffectType);
int GetHasEffectWithTag(object oObject, string sTag);
int GetTileIndexFromPosition(object oArea, vector vPosition);
void DeleteLocalVector(object oObject, string sVarName);
vector GetLocalVector(object oObject, string sVarName);
void SetLocalVector(object oObject, string sVarName, vector vValue);
int GetIsPlayer(object oObject);
int GetIsLocationValid(location locLocation);
int Get2DAInt(string s2DA, string sColumn, int nRow);
int IncrementLocalInt(object oObject, string sVarName);
int DecrementLocalInt(object oObject, string sVarName);
int GetIsDMExtended(object oCreature, int bIncludePlayerDMs = FALSE);
int GetCurrentTimeSeconds();

json GetResRefArray(string sPrefix, int nResType, int bSearchBaseData = FALSE, string sOnlyKeyTable = "", json jArray = JSON_NULL)
{
    string sResRef;
    int nNth;

    if (JsonGetType(jArray) != JSON_TYPE_ARRAY)
        jArray = JsonArray();

    while ((sResRef = ResManFindPrefix(sPrefix, nResType, ++nNth, bSearchBaseData, sOnlyKeyTable)) != "")
    {
        JsonArrayInsertInplace(jArray, JsonString(sResRef));
    }

    return jArray;
}

void RemoveEffectsWithTag(object oObject, string sTag)
{
    effect eEffect = GetFirstEffect(oObject);
    while (GetIsEffectValid(eEffect))
    {
        if (GetEffectTag(eEffect) == sTag)
            RemoveEffect(oObject, eEffect);
        eEffect = GetNextEffect(oObject);
    }
}

string Get2DAStrRefString(string s2DA, string sColumn, int nRow)
{
    return GetStringByStrRef(StringToInt(Get2DAString(s2DA, sColumn, nRow)));
}

void VoidJsonToObject(json jObject, location locLocation, object oOwner = OBJECT_INVALID, int bLoadObjectState = FALSE)
{
    JsonToObject(jObject, locLocation, oOwner, bLoadObjectState);
}

string GetItemName(object oItem, int bIdentified)
{
    return bIdentified ? GetName(oItem) : Get2DAStrRefString("baseitems", "Name", GetBaseItemType(oItem)) + " (Unidentified)";
}

vector GetAreaCenterPosition(object oArea, float fZ = 0.0f)
{
    float fX = (GetAreaSize(AREA_WIDTH, oArea) * 10.0f) * 0.5f;
    float fY = (GetAreaSize(AREA_HEIGHT, oArea) * 10.0f) * 0.5f;
    return Vector(fX, fY, fZ);
}

vector GetTilePosition(int nX, int nY)
{
    return Vector((nX * 10.0f) + 5.0f, (nY * 10.0f) + 5.0, 0.0f);
}

int GetLocationWalkable(location loc)
{
    return StringToInt(Get2DAString("surfacemat", "Walk", GetSurfaceMaterial(loc)));
}

int GetHasEffectType(object oObject, int nEffectType)
{
    effect eEffect = GetFirstEffect(oObject);
    while (GetIsEffectValid(eEffect))
    {
        if (GetEffectType(eEffect) == nEffectType)
            return TRUE;
        eEffect = GetNextEffect(oObject);
    }
    return FALSE;
}

int GetHasEffectWithTag(object oObject, string sTag)
{
    effect eEffect = GetFirstEffect(oObject);
    while (GetIsEffectValid(eEffect))
    {
        if (GetEffectTag(eEffect) == sTag)
            return TRUE;
        eEffect = GetNextEffect(oObject);
    }
    return FALSE;
}

int GetTileIndexFromPosition(object oArea, vector vPosition)
{
    int nXStartTile = -1;
    int nYStartTile = -1;
    int nTileX, nTileY;
    int nHeight = GetAreaSize(AREA_HEIGHT, oArea);
    int nWidth = GetAreaSize(AREA_WIDTH, oArea);

    for (nTileX = 0; nTileX < 32 && nXStartTile == -1; nTileX++)
    {
        if (vPosition.x >= nTileX * 10.0f && vPosition.x < (nTileX + 1) * 10.0f)
            nXStartTile = nTileX;
    }

    for (nTileY = 0; nTileY < 32 && nYStartTile == -1; nTileY++)
    {
        if (vPosition.y >= nTileY * 10.0f && vPosition.y < (nTileY + 1) * 10.0f)
            nYStartTile = nTileY;
    }

    if ((nXStartTile < 0 || nXStartTile >= nWidth) || (nYStartTile < 0 || nYStartTile >= nHeight))
        return -1;

    return nYStartTile * nWidth + nXStartTile;
}

void DeleteLocalVector(object oObject, string sVarName)
{
    DeleteLocalLocation(oObject, "VECTOR_" + sVarName);
}

vector GetLocalVector(object oObject, string sVarName)
{
    return GetPositionFromLocation(GetLocalLocation(oObject, "VECTOR_" + sVarName));
}

void SetLocalVector(object oObject, string sVarName, vector vValue)
{
    SetLocalLocation(oObject, "VECTOR_" + sVarName, Location(OBJECT_INVALID, vValue, 0.0f));
}

int GetIsPlayer(object oObject)
{
    return GetIsPC(oObject) || GetStringLength(ObjectToString(oObject)) == 8;
}

int GetIsLocationValid(location locLocation)
{
    return GetIsObjectValid(GetAreaFromLocation(locLocation));
}

int Get2DAInt(string s2DA, string sColumn, int nRow)
{
    string sValue = Get2DAString(s2DA, sColumn, nRow);
    return sValue == "" ? EF_UNSET_INTEGER_VALUE : StringToInt(sValue);
}

int IncrementLocalInt(object oObject, string sVarName)
{
    int nCurrent = GetLocalInt(oObject, sVarName);
    SetLocalInt(oObject, sVarName, ++nCurrent);
    return nCurrent;
}

int DecrementLocalInt(object oObject, string sVarName)
{
    int nCurrent = GetLocalInt(oObject, sVarName);
    SetLocalInt(oObject, sVarName, --nCurrent);
    return nCurrent;
}

int GetIsDMExtended(object oCreature, int bIncludePlayerDMs = FALSE)
{
    if (!GetIsObjectValid(oCreature))
        return FALSE;
    if (GetIsDMPossessed(oCreature))
        return TRUE;
    return GetIsDM(oCreature) && (bIncludePlayerDMs || !GetIsPlayerDM(oCreature));
}

int GetCurrentTimeSeconds()
{
    return GetCalendarYear() * 12 * 28 * 24 * 60 * 60 +
            (GetCalendarMonth() - 1) * 28 * 24 * 60 * 60 +
            (GetCalendarDay() - 1) * 24 * 60 * 60 +
            GetTimeHour()  * 60 * 60 +
            GetTimeMinute() * 60 +
            GetTimeSecond();
}
