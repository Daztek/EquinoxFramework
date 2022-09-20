/*
    Script: ef_i_util
    Author: Daz

    Description: Utility Include for the Equinox Framework
*/

#include "ef_i_nss"
#include "ef_i_gff"
#include "nwnx_util"

const string EF_DATAOBJECT_TAG_PREFIX       = "EFDataObject_";
const string EF_DEFAULT_SCRIPT_ALIAS        = "NWNX";
const int EF_UNSET_INTEGER_VALUE            = 0x7FFFFFFF;

// Write a message to the log
void WriteLog(string sName, string sMessage);

// Create a waypoint at locLocation with sTag
object CreateWaypoint(location locLocation, string sTag);
// Create a new data object with sTag
object CreateDataObject(string sTag, int bDestroyExisting = TRUE);
// Destroy a data object with sTag
void DestroyDataObject(string sTag);
// Get a data object with sTag
object GetDataObject(string sTag, int bCreateIfNotExists = TRUE);

// Get an array of resrefs by type
json GetResRefArray(string sPrefix, int nResType, int bSearchBaseData = FALSE, string sOnlyKeyTable = "");

// Execute a script chunk.
// The script chunk runs immediately, same as ExecuteScript().
// The script is jitted in place and cached.
// Note that the script chunk will run as if a separate script. This is not eval().
// By default, the script chunk is wrapped into void main() {}. Pass in bWrapIntoMain = FALSE to override.
// Returns "" on success, or the compilation error.
string ExecuteCachedScriptChunk(string sScriptChunk, object oObject = OBJECT_SELF, int bWrapIntoMain = TRUE, int bFlushCachedChunk = FALSE);

// Get the int value of sConstant or nErrorValue on error
int GetConstantIntValue(string sConstant, string sInclude = "", int nErrorValue = 0);
// Get the string value of sConstant or sErrorValue on error
string GetConstantStringValue(string sConstant, string sInclude = "", string sErrorValue = "");

// Convenience wrapper for NWNX_Util_AddScript()
string AddScript(string sFileName, string sInclude, string sScriptChunk, string sAlias = EF_DEFAULT_SCRIPT_ALIAS);

// Run sScriptChunk and return its json result
json ExecuteScriptChunkAndReturnJson(string sInclude, string sScriptChunk, object oObject, int bFlushCachedChunk = FALSE);

// Remove all effects with sTag from oObject
void RemoveEffectsWithTag(object oObject, string sTag);

// Get a string from the talk table using a strref from a 2da.
string Get2DAStrRefString(string s2DA, string sColumn, int nRow);

// Void Wrapper for JsonToObject
void VoidJsonToObject(json jObject, location locLocation, object oOwner = OBJECT_INVALID, int bLoadObjectState = FALSE);

// Get an item's name depending on identified state
string GetItemName(object oItem, int bIdentified);

// Get the icon resref of an item
string GetItemIconResref(object oItem, json jItem, int nBaseItem);

// Get the center of oArea
vector GetAreaCenterPosition(object oArea, float fZ = 0.0f);

// Get the center position of a tile by its X/Y position
vector GetTilePosition(int nX, int nY);

// Returns TRUE if the location is walkable
int GetLocationWalkable(location loc);

// Returns TRUE if oObject has nEffectType
int GetHasEffectType(object oObject, int nEffectType);

// Returns TRUE if oObject has an effect with sTag
int GetHasEffectWithTag(object oObject, string sTag);

// Convert nSeconds to a string timestamp
string SecondsToStringTimestamp(int nSeconds);

// Get the tile index of the tile at vPosition in oArea.
int GetTileIndexFromPosition(object oArea, vector vPosition);

// Returns the higher of a or b
int max(int a, int b);
// Returns the lower of a or b
int min(int a, int b);
// Returns nValue bounded by nMin and nMax
int clamp(int nValue, int nMin, int nMax);

// Delete oObject's local vector variable sVarName
void DeleteLocalVector(object oObject, string sVarName);
// Get oObject's local vector variable sVarname
vector GetLocalVector(object oObject, string sVarName);
// Set oObject's local vector variable sVarname to vValue
void SetLocalVector(object oObject, string sVarName, vector vValue);

// Convert an 0xFF string to its int value
int HexStringToInt(string sString);

// Calls GetIsPC() but also checks the object id length for cases where the PC object isn't valid anymore
int GetIsPlayer(object oObject);

// Returns TRUE if locLocation is valid
int GetIsLocationValid(location locLocation);

// Get an integer from a 2da, returns EF_UNSET_INTEGER_VALUE if not set.
int Get2DAInt(string s2DA, string sColumn, int nRow);

void WriteLog(string sName, string sMessage)
{
    WriteTimestampedLogEntry("[" + sName + "] " + sMessage);
}

object CreateWaypoint(location locLocation, string sTag)
{
    return CreateObject(OBJECT_TYPE_WAYPOINT, "nw_waypoint001", locLocation, FALSE, sTag);
}

object CreateDataObject(string sTag, int bDestroyExisting = TRUE)
{
    if (bDestroyExisting)
        DestroyDataObject(sTag);

    object oDataObject = CreateWaypoint(GetStartingLocation(), EF_DATAOBJECT_TAG_PREFIX + sTag);
    SetLocalObject(GetModule(), EF_DATAOBJECT_TAG_PREFIX + sTag, oDataObject);

    return oDataObject;
}

void DestroyDataObject(string sTag)
{
    object oDataObject = GetLocalObject(GetModule(), EF_DATAOBJECT_TAG_PREFIX + sTag);

    if (GetIsObjectValid(oDataObject))
    {
        DeleteLocalObject(GetModule(), EF_DATAOBJECT_TAG_PREFIX + sTag);
        DestroyObject(oDataObject);
    }
}

object GetDataObject(string sTag, int bCreateIfNotExists = TRUE)
{
    object oDataObject = GetLocalObject(GetModule(), EF_DATAOBJECT_TAG_PREFIX + sTag);
    return GetIsObjectValid(oDataObject) ? oDataObject : bCreateIfNotExists ? CreateDataObject(sTag) : OBJECT_INVALID;
}

json GetResRefArray(string sPrefix, int nResType, int bSearchBaseData = FALSE, string sOnlyKeyTable = "")
{
    json jArray = JsonArray();
    string sResRef;
    int nNth;

    while ((sResRef = ResManFindPrefix(sPrefix, nResType, ++nNth)) != "")
    {
        jArray = JsonArrayInsertString(jArray, sResRef);
    }

    return jArray;
}

void NWNX_Optimizations_FlushCachedChunks(string sScriptChunk = "")
{
    NWNX_PushArgumentString(sScriptChunk);
    NWNX_CallFunction("NWNX_Optimizations", "FlushCachedChunks");
}

string NWNX_Optimizations_CacheScriptChunk(string sScriptChunk, int bWrapIntoMain)
{
    NWNX_PushArgumentInt(bWrapIntoMain);
    NWNX_PushArgumentString(sScriptChunk);
    NWNX_CallFunction("NWNX_Optimizations", "CacheScriptChunk");
    return NWNX_GetReturnValueString();
}

string ExecuteCachedScriptChunk(string sScriptChunk, object oObject = OBJECT_SELF, int bWrapIntoMain = TRUE, int bFlushCachedChunk = FALSE)
{
    if (bFlushCachedChunk)
        NWNX_Optimizations_FlushCachedChunks(sScriptChunk);

    return ExecuteScriptChunk(sScriptChunk, oObject, bWrapIntoMain);
}

int GetConstantIntValue(string sConstant, string sInclude = "", int nErrorValue = 0)
{
    object oModule = GetModule();
    string sScriptChunk = nssInclude(sInclude) + nssVoidMain("SetLocalInt(OBJECT_SELF, \"CONVERT_CONSTANT\", " + sConstant + ");");
    string sError = ExecuteCachedScriptChunk(sScriptChunk, oModule, FALSE);
    int nRet = GetLocalInt(oModule, "CONVERT_CONSTANT");
    DeleteLocalInt(oModule, "CONVERT_CONSTANT");
    return sError == "" ? nRet : nErrorValue;
}

string GetConstantStringValue(string sConstant, string sInclude = "", string sErrorValue = "")
{
    object oModule = GetModule();
    string sScriptChunk = nssInclude(sInclude) + nssVoidMain("SetLocalString(OBJECT_SELF, \"CONVERT_CONSTANT\", " + sConstant + ");");
    string sError = ExecuteCachedScriptChunk(sScriptChunk, oModule, FALSE);
    string sRet = GetLocalString(oModule, "CONVERT_CONSTANT");
    DeleteLocalString(oModule, "CONVERT_CONSTANT");
    return sError == "" ? sRet : sErrorValue;
}

string AddScript(string sFileName, string sInclude, string sScriptChunk, string sAlias = EF_DEFAULT_SCRIPT_ALIAS)
{
    return NWNX_Util_AddScript(sFileName, nssInclude(sInclude) + nssVoidMain(sScriptChunk), FALSE, sAlias);
}

json ExecuteScriptChunkAndReturnJson(string sInclude, string sScriptChunk, object oObject, int bFlushCachedChunk = FALSE)
{
    object oModule = GetModule();
    string sScript = nssInclude(sInclude) + nssVoidMain(nssJson("jReturn", sScriptChunk) +
        nssFunction("SetLocalJson", nssFunction("GetModule", "", FALSE) + ", " + nssEscape("EF_TEMP_VAR") + ", jReturn"));
    string sResult = ExecuteCachedScriptChunk(sScript, oObject, FALSE, bFlushCachedChunk);
    json jReturn = GetLocalJson(oModule, "EF_TEMP_VAR");
    DeleteLocalJson(oModule, "EF_TEMP_VAR");

    if (sResult != "")
        WriteLog("WARNING", "ExecuteScriptChunkAndReturnJson() failed with error: " + sResult);


    return jReturn;
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

string GetItemIconResref(object oItem, json jItem, int nBaseItem)
{
    if (nBaseItem == BASE_ITEM_CLOAK)
        return "iit_cloak";
    else if (nBaseItem == BASE_ITEM_SPELLSCROLL || nBaseItem == BASE_ITEM_ENCHANTED_SCROLL)
    {
        if (GetItemHasItemProperty(oItem, ITEM_PROPERTY_CAST_SPELL))
        {
            itemproperty ip = GetFirstItemProperty(oItem);
            while (GetIsItemPropertyValid(ip))
            {
                if (GetItemPropertyType(ip) == ITEM_PROPERTY_CAST_SPELL)
                    return Get2DAString("iprp_spells", "Icon", GetItemPropertySubType(ip));

                ip = GetNextItemProperty(oItem);
            }
        }
    }
    else if (Get2DAString("baseitems", "ModelType", nBaseItem) == "0")
    {
        json jSimpleModel = GffGetByte(jItem, "ModelPart1");
        if (JsonGetType(jSimpleModel) == JSON_TYPE_INTEGER)
        {
            string sSimpleModelId = IntToString(JsonGetInt(jSimpleModel));
            while (GetStringLength(sSimpleModelId) < 3)
            {
                sSimpleModelId = "0" + sSimpleModelId;
            }

            string sDefaultIcon = Get2DAString("baseitems", "DefaultIcon", nBaseItem);
            switch (nBaseItem)
            {
                case BASE_ITEM_MISCSMALL:
                case BASE_ITEM_CRAFTMATERIALSML:
                    sDefaultIcon = "iit_smlmisc_" + sSimpleModelId;
                    break;
                case BASE_ITEM_MISCMEDIUM:
                case BASE_ITEM_CRAFTMATERIALMED:
                case 112:/* Crafting Base Material */
                    sDefaultIcon = "iit_midmisc_" + sSimpleModelId;
                    break;
                case BASE_ITEM_MISCLARGE:
                    sDefaultIcon = "iit_talmisc_" + sSimpleModelId;
                    break;
                case BASE_ITEM_MISCTHIN:
                    sDefaultIcon = "iit_thnmisc_" + sSimpleModelId;
                    break;
            }

            int nLength = GetStringLength(sDefaultIcon);
            if (GetSubString(sDefaultIcon, nLength - 4, 1) == "_")
                sDefaultIcon = GetStringLeft(sDefaultIcon, nLength - 4);
            string sIcon = sDefaultIcon + "_" + sSimpleModelId;
            if (ResManGetAliasFor(sIcon, RESTYPE_TGA) != "")
                return sIcon;
        }
    }

    return Get2DAString("baseitems", "DefaultIcon", nBaseItem);
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

string SecondsToStringTimestamp(int nSeconds)
{
    sqlquery sql;
    if (nSeconds > 86400)
        sql = SqlPrepareQueryObject(GetModule(), "SELECT (@seconds / 3600) || ':' || strftime('%M:%S', @seconds / 86400.0);");
    else
        sql = SqlPrepareQueryObject(GetModule(), "SELECT time(@seconds, 'unixepoch');");

    SqlBindInt(sql, "@seconds", nSeconds);
    SqlStep(sql);

    return SqlGetString(sql, 0);
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

int max(int a, int b)
{
    return a > b ? a : b;
}

int min(int a, int b)
{
    return a < b ? a : b;
}

int clamp(int nValue, int nMin, int nMax)
{
    return nValue < nMin ? nMin : nValue > nMax ? nMax : nValue;
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

int HexStringToInt(string sString)
{
    sString = GetStringLowerCase(sString);
    int nResult, nLength = GetStringLength(sString), i;

    for (i = nLength - 1; i >= 0; i--)
    {
        int n = FindSubString("0123456789abcdef", GetSubString(sString, i, 1));
        if (n == -1)
            return nResult;
        nResult |= n << ((nLength - i - 1) * 4);
    }
    return nResult;
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
