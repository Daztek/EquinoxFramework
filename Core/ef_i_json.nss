/*
    Script: ef_i_json
    Author: Daz

    Description: Equinox Framework Json Utility Include
*/

// Convert vVector to a json array
json VectorToJson(vector vVector);
// Convert jVector to vector
vector JsonToVector(json jVector);
// Convert locLocation to a json object
json LocationToJson(location locLocation);
// Convert jLocation to a location
location JsonToLocation(json jLocation);
// Get oObject's local json variable sVarName or jDefault if not set
json GetLocalJsonOrDefault(object oObject, string sVarName, json jDefault);
// Gets local json array sVarName from oObject
json GetLocalJsonArray(object oObject, string sVarName);
// Get sKey as string from jObject
string JsonObjectGetString(json jObject, string sKey);
// Set sKey to sValue as JsonString() on jObject
json JsonObjectSetString(json jObject, string sKey, string sValue);
// Get sKey as int from jObject
int JsonObjectGetInt(json jObject, string sKey);
// Set sKey to nValue as JsonInt() on jObject
json JsonObjectSetInt(json jObject, string sKey, int nValue);
// Get sKey as float from jObject
float JsonObjectGetFloat(json jObject, string sKey);
// Set sKey to fValue as JsonFloat() on jObject
json JsonObjectSetFloat(json jObject, string sKey, float fValue);
// Get sKey as vector from jObject
vector JsonObjectGetVector(json jObject, string sKey);
// Set sKey to vValue as VectorJsonArray() on jObject
json JsonObjectSetVector(json jObject, string sKey, vector vValue);
// Get sKey as location from jObject
location JsonObjectGetLocation(json jObject, string sKey);
// Set sKey to locValue as JsonObjectLocation() on jObject
json JsonObjectSetLocation(json jObject, string sKey, location locValue);
// Gets the string at jArray index position nIndex.
string JsonArrayGetString(json jArray, int nIndex);
// Returns a modified copy of jArray with sValue inserted as JsonString() at position nIndex.
// All succeeding objects in the array will move by one.
// By default (-1), inserts objects at the end of the array ("push").
// nIndex = 0 inserts at the beginning of the array.
// Returns a json null value if jArray is not actually an array, with JsonGetError() filled in.
// Returns a json null value if nIndex is not 0 or -1 and out of bounds, with JsonGetError() filled in.
json JsonArrayInsertString(json jArray, string sValue, int nIndex = -1);
// Returns a modified copy of jArray with position nIndex set to sValue as JsonString.
// Returns a json null value if jArray is not actually an array, with JsonGetError() filled in.
// Returns a json null value if nIndex is out of bounds, with JsonGetError() filled in.
json JsonArraySetString(json jArray, int nIndex, string sValue);
// Gets the int at jArray index position nIndex.
int JsonArrayGetInt(json jArray, int nIndex);
// Returns a modified copy of jArray with nValue inserted as JsonInt() at position nIndex.
// All succeeding objects in the array will move by one.
// By default (-1), inserts objects at the end of the array ("push").
// nIndex = 0 inserts at the beginning of the array.
// Returns a json null value if jArray is not actually an array, with JsonGetError() filled in.
// Returns a json null value if nIndex is not 0 or -1 and out of bounds, with JsonGetError() filled in.
json JsonArrayInsertInt(json jArray, int nValue, int nIndex = -1);
// Returns a modified copy of jArray with position nIndex set to bValue as JsonInt.
// Returns a json null value if jArray is not actually an array, with JsonGetError() filled in.
// Returns a json null value if nIndex is out of bounds, with JsonGetError() filled in.
json JsonArraySetInt(json jArray, int nIndex, int nValue);
// Gets the float at jArray index position nIndex.
float JsonArrayGetFloat(json jArray, int nIndex);
// Returns a modified copy of jArray with fValue inserted as JsonFloat() at position nIndex.
// All succeeding objects in the array will move by one.
// By default (-1), inserts objects at the end of the array ("push").
// nIndex = 0 inserts at the beginning of the array.
// Returns a json null value if jArray is not actually an array, with JsonGetError() filled in.
// Returns a json null value if nIndex is not 0 or -1 and out of bounds, with JsonGetError() filled in.
json JsonArrayInsertFloat(json jArray, float fValue, int nIndex = -1);
// Gets the bool at jArray index position nIndex.
int JsonArrayGetBool(json jArray, int nIndex);
// Returns a modified copy of jArray with bValue inserted as JsonBool() at position nIndex.
// All succeeding objects in the array will move by one.
// By default (-1), inserts objects at the end of the array ("push").
// nIndex = 0 inserts at the beginning of the array.
// Returns a json null value if jArray is not actually an array, with JsonGetError() filled in.
// Returns a json null value if nIndex is not 0 or -1 and out of bounds, with JsonGetError() filled in.
json JsonArrayInsertBool(json jArray, int bValue, int nIndex = -1);
// Returns a modified copy of jArray with position nIndex set to bValue as JsonBool.
// Returns a json null value if jArray is not actually an array, with JsonGetError() filled in.
// Returns a json null value if nIndex is out of bounds, with JsonGetError() filled in.
json JsonArraySetBool(json jArray, int nIndex, int bValue);
// Insert jValue into jObject's array with the key sKey .
json JsonObjectInsertToArrayWithKey(json jObject, string sKey, json jValue);
// Returns the key value of sKey on the object jObect.
// Returns jDefault if sKey does not exist on the object.
json JsonObjectGetOrDefault(json jObject, string sKey, json jDefault);
// Returns TRUE if jArray contains sString
int JsonArrayContainsString(json jArray, string sString);
// Returns a json integer point
json JsonPointInt(int nX, int nY);
// Insert sValue to the local json array sVarName on oObject at nIndex.
void InsertStringToLocalJsonArray(object oObject, string sVarName, string sValue, int nIndex = -1);
// Insert nValue to the local json array sVarName on oObject at nIndex.
void InsertIntToLocalJsonArray(object oObject, string sVarName, int nValue, int nIndex = -1);
// Get the string at nIndex from the local json array sVarName on oObject, or "" on error
string GetStringFromLocalJsonArray(object oObject, string sVarName, int nIndex);
// Get the integer at nIndex from the local json array sVarName on oObject, or 0 on error
int GetIntFromLocalJsonArray(object oObject, string sVarName, int nIndex);
// Returns an empty json string array of size nSize
json GetEmptyJsonStringArray(int nSize);
// Returns an empty json bool array of size nSize
json GetEmptyJsonBoolArray(int nSize);
// Returns an empty json int array of size nSize
json GetEmptyJsonIntArray(int nSize);
// Convert a boolean value to a json bool array element
string StringJsonArrayElementBool(int bValue);
// Convert an integer value to a json integer array element
string StringJsonArrayElementInt(int nValue);
// Convert a string value to a json string array element
string StringJsonArrayElementString(string sValue);
// Convert a string of stringified json elements to a json array
json StringJsonArrayElementsToJsonArray(string sValues);

json VectorToJson(vector vVector)
{
    json jVector = JsonObject();
         jVector = JsonObjectSetFloat(jVector, "x", vVector.x);
         jVector = JsonObjectSetFloat(jVector, "y", vVector.y);
         jVector = JsonObjectSetFloat(jVector, "z", vVector.z);
    return jVector;
}

vector JsonToVector(json jVector)
{
    return Vector(JsonObjectGetFloat(jVector, "x"), JsonObjectGetFloat(jVector, "y"), JsonObjectGetFloat(jVector, "z"));
}

json LocationToJson(location locLocation)
{
    string sAreaTag = GetTag(GetAreaFromLocation(locLocation));
    string sAreaResRef = GetResRef(GetAreaFromLocation(locLocation));
    vector vPosition = GetPositionFromLocation(locLocation);
    float fOrientation = GetFacingFromLocation(locLocation);

    json jLocation = JsonObject();
         jLocation = JsonObjectSetString(jLocation, "area_tag", sAreaTag);
         jLocation = JsonObjectSetString(jLocation, "area_resref", sAreaResRef);
         jLocation = JsonObjectSetVector(jLocation, "position", vPosition);
         jLocation = JsonObjectSetFloat(jLocation, "orientation", fOrientation);

    return jLocation;
}

location JsonToLocation(json jLocation)
{
    object oArea = GetObjectByTag(JsonObjectGetString(jLocation, "area_tag"));
    string sResRef = JsonObjectGetString(jLocation, "area_resref");

    if (!GetIsObjectValid(oArea) || GetResRef(oArea) != sResRef)
        return GetStartingLocation();

    vector vPosition = JsonObjectGetVector(jLocation, "position");
    float fOrientation = JsonObjectGetFloat(jLocation, "orientation");

    return Location(oArea, vPosition, fOrientation);
}

json GetLocalJsonOrDefault(object oObject, string sVarName, json jDefault)
{
    json jReturn = GetLocalJson(oObject, sVarName);
    return !JsonGetType(jReturn) ? jDefault : jReturn;
}

json GetLocalJsonArray(object oObject, string sVarName)
{
    return GetLocalJsonOrDefault(oObject, sVarName, JsonArray());
}

string JsonObjectGetString(json jObject, string sKey)
{
    return JsonGetString(JsonObjectGet(jObject, sKey));
}

json JsonObjectSetString(json jObject, string sKey, string sValue)
{
    return JsonObjectSet(jObject, sKey, JsonString(sValue));
}

int JsonObjectGetInt(json jObject, string sKey)
{
    return JsonGetInt(JsonObjectGet(jObject, sKey));
}

json JsonObjectSetInt(json jObject, string sKey, int nValue)
{
    return JsonObjectSet(jObject, sKey, JsonInt(nValue));
}

float JsonObjectGetFloat(json jObject, string sKey)
{
    return JsonGetFloat(JsonObjectGet(jObject, sKey));
}

json JsonObjectSetFloat(json jObject, string sKey, float fValue)
{
    return JsonObjectSet(jObject, sKey, JsonFloat(fValue));
}

vector JsonObjectGetVector(json jObject, string sKey)
{
    return JsonToVector(JsonObjectGet(jObject, sKey));
}

json JsonObjectSetVector(json jObject, string sKey, vector vValue)
{
    return JsonObjectSet(jObject, sKey, VectorToJson(vValue));
}

location JsonObjectGetLocation(json jObject, string sKey)
{
    return JsonToLocation(JsonObjectGet(jObject, sKey));
}

json JsonObjectSetLocation(json jObject, string sKey, location locValue)
{
    return JsonObjectSet(jObject, sKey, LocationToJson(locValue));
}

string JsonArrayGetString(json jArray, int nIndex)
{
    return JsonGetString(JsonArrayGet(jArray, nIndex));
}

json JsonArrayInsertString(json jArray, string sValue, int nIndex = -1)
{
    return JsonArrayInsert(jArray, JsonString(sValue), nIndex);
}

json JsonArraySetString(json jArray, int nIndex, string sValue)
{
    return JsonArraySet(jArray, nIndex, JsonString(sValue));
}

int JsonArrayGetInt(json jArray, int nIndex)
{
    return JsonGetInt(JsonArrayGet(jArray, nIndex));
}

json JsonArrayInsertInt(json jArray, int nValue, int nIndex = -1)
{
    return JsonArrayInsert(jArray, JsonInt(nValue), nIndex);
}

json JsonArraySetInt(json jArray, int nIndex, int nValue)
{
    return JsonArraySet(jArray, nIndex, JsonInt(nValue));
}

float JsonArrayGetFloat(json jArray, int nIndex)
{
    return JsonGetFloat(JsonArrayGet(jArray, nIndex));
}

json JsonArrayInsertFloat(json jArray, float fValue, int nIndex = -1)
{
    return JsonArrayInsert(jArray, JsonFloat(fValue), nIndex);
}

int JsonArrayGetBool(json jArray, int nIndex)
{
    return JsonGetInt(JsonArrayGet(jArray, nIndex));
}

json JsonArrayInsertBool(json jArray, int bValue, int nIndex = -1)
{
    return JsonArrayInsert(jArray, JsonBool(bValue), nIndex);
}

json JsonArraySetBool(json jArray, int nIndex, int bValue)
{
    return JsonArraySet(jArray, nIndex, JsonBool(bValue));
}

json JsonObjectInsertToArrayWithKey(json jObject, string sKey, json jValue)
{
    return JsonObjectSet(jObject, sKey, JsonArrayInsert(JsonObjectGet(jObject, sKey), jValue));
}

json JsonObjectGetOrDefault(json jObject, string sKey, json jDefault)
{
    json jReturn = JsonObjectGet(jObject, sKey);
    return !JsonGetType(jReturn) ? jDefault : jReturn;
}

int JsonArrayContainsString(json jArray, string sString)
{
    return JsonGetType(JsonFind(jArray, JsonString(sString))) == JSON_TYPE_INTEGER;
}

json JsonPointInt(int nX, int nY)
{
    json jPoint = JsonObject();
         jPoint = JsonObjectSetInt(jPoint, "x", nX);
         jPoint = JsonObjectSetInt(jPoint, "y", nY);
    return jPoint;
}

void InsertStringToLocalJsonArray(object oObject, string sVarName, string sValue, int nIndex = -1)
{
    SetLocalJson(oObject, sVarName, JsonArrayInsertString(GetLocalJsonArray(oObject, sVarName), sValue, nIndex));
}

void InsertIntToLocalJsonArray(object oObject, string sVarName, int nValue, int nIndex = -1)
{
    SetLocalJson(oObject, sVarName, JsonArrayInsertInt(GetLocalJsonArray(oObject, sVarName), nValue, nIndex));
}

string GetStringFromLocalJsonArray(object oObject, string sVarName, int nIndex)
{
    return JsonArrayGetString(GetLocalJsonArray(oObject, sVarName), nIndex);
}

int GetIntFromLocalJsonArray(object oObject, string sVarName, int nIndex)
{
    return JsonArrayGetInt(GetLocalJsonArray(oObject, sVarName), nIndex);
}

json GetEmptyJsonStringArray(int nSize)
{
    json jArray = GetLocalJson(GetModule(), "JSON_EMPTY_STRING_ARRAY_" + IntToString(nSize));

    if (!JsonGetType(jArray))
    {
        jArray = JsonArray();
        int nCount;
        for (nCount = 0; nCount < nSize; nCount++)
        {
            jArray = JsonArrayInsertString(jArray, "");
        }

        SetLocalJson(GetModule(), "JSON_EMPTY_STRING_ARRAY_" + IntToString(nSize), jArray);
    }

    return jArray;
}

json GetEmptyJsonBoolArray(int nSize)
{
    json jArray = GetLocalJson(GetModule(), "JSON_EMPTY_BOOL_ARRAY_" + IntToString(nSize));

    if (!JsonGetType(jArray))
    {
        jArray = JsonArray();
        int nCount;
        for (nCount = 0; nCount < nSize; nCount++)
        {
            jArray = JsonArrayInsertBool(jArray, FALSE);
        }

        SetLocalJson(GetModule(), "JSON_EMPTY_BOOL_ARRAY_" + IntToString(nSize), jArray);
    }

    return jArray;
}

json GetEmptyJsonIntArray(int nSize)
{
    json jArray = GetLocalJson(GetModule(), "JSON_EMPTY_INT_ARRAY_" + IntToString(nSize));

    if (!JsonGetType(jArray))
    {
        jArray = JsonArray();
        int nCount;
        for (nCount = 0; nCount < nSize; nCount++)
        {
            jArray = JsonArrayInsertInt(jArray, 0);
        }

        SetLocalJson(GetModule(), "JSON_EMPTY_INT_ARRAY_" + IntToString(nSize), jArray);
    }

    return jArray;
}

string StringJsonArrayElementBool(int bValue)
{
    return (bValue ? "true" : "false") + ",";
}

string StringJsonArrayElementInt(int nValue)
{
    return IntToString(nValue) + ",";
}

string StringJsonArrayElementString(string sValue)
{
    return "\"" + sValue + "\",";
}

json StringJsonArrayElementsToJsonArray(string sValues)
{
    return JsonParse("[" + (GetStringRight(sValues, 1) == "," ? GetStringLeft(sValues, GetStringLength(sValues) - 1) : sValues) + "]");
}
