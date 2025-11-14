/*
    Script: ef_i_json
    Author: Daz
*/

#include "nwnx_json"
#include "nwnx_vm"

const string JSON_STRUCT_VALUE_KEY  = "value";

json VectorToJson(vector vVector);
vector JsonToVector(json jVector);
json LocationToJson(location locLocation);
location JsonToLocation(json jLocation);
json GetLocalJsonOrDefault(object oObject, string sVarName, json jDefault);
json GetLocalJsonArray(object oObject, string sVarName);
string JsonObjectGetString(json jObject, string sKey);
json JsonObjectSetString(json jObject, string sKey, string sValue);
int JsonObjectGetInt(json jObject, string sKey);
json JsonObjectSetInt(json jObject, string sKey, int nValue);
float JsonObjectGetFloat(json jObject, string sKey);
json JsonObjectSetFloat(json jObject, string sKey, float fValue);
vector JsonObjectGetVector(json jObject, string sKey);
json JsonObjectSetVector(json jObject, string sKey, vector vValue);
location JsonObjectGetLocation(json jObject, string sKey);
json JsonObjectSetLocation(json jObject, string sKey, location locValue);
string JsonArrayGetString(json jArray, int nIndex);
json JsonArrayInsertString(json jArray, string sValue, int nIndex = -1);
json JsonArrayInsertUniqueString(json jArray, string sValue, int nIndex = -1);
json JsonArraySetString(json jArray, int nIndex, string sValue);
int JsonArrayGetInt(json jArray, int nIndex);
json JsonArrayInsertInt(json jArray, int nValue, int nIndex = -1);
json JsonArrayInsertUniqueInt(json jArray, int nValue, int nIndex = -1);
json JsonArraySetInt(json jArray, int nIndex, int nValue);
float JsonArrayGetFloat(json jArray, int nIndex);
json JsonArrayInsertFloat(json jArray, float fValue, int nIndex = -1);
int JsonArrayGetBool(json jArray, int nIndex);
json JsonArrayInsertBool(json jArray, int bValue, int nIndex = -1);
json JsonArraySetBool(json jArray, int nIndex, int bValue);
json JsonObjectInsertToArrayWithKey(json jObject, string sKey, json jValue);
json JsonObjectGetOrDefault(json jObject, string sKey, json jDefault);
int JsonArrayContainsString(json jArray, string sValue);
int JsonArrayContainsInt(json jArray, int nValue);
json JsonPointInt(int nX, int nY);
void InsertStringToLocalJsonArray(object oObject, string sVarName, string sValue, int nIndex = -1);
void InsertIntToLocalJsonArray(object oObject, string sVarName, int nValue, int nIndex = -1);
string GetStringFromLocalJsonArray(object oObject, string sVarName, int nIndex);
int GetIntFromLocalJsonArray(object oObject, string sVarName, int nIndex);
string StringJsonArrayElementBool(int bValue);
string StringJsonArrayElementInt(int nValue);
string StringJsonArrayElementString(string sValue);
json StringJsonArrayElementsToJsonArray(string sValues);
json GetJsonArrayOfSize(int nSize, json jDefaultValue);
json GetJsonArrayFromTokenizedString(string sTokens, string sDelimiter = ":");
void JsonArrayInsertStringInplace(json jArray, string sValue, int nIndex = -1);
void JsonArrayInsertIntInplace(json jArray, int nValue, int nIndex = -1);
void JsonArrayInsertFloatInplace(json jArray, float fValue, int nIndex = -1);
void JsonObjectSetIntInplace(json jObject, string sKey, int nValue);
void JsonObjectSetStringInplace(json jObject, string sKey, string sValue);
void JsonObjectSetFloatInplace(json jObject, string sKey, float fValue);
void JsonArrayInsertBoolInplace(json jArray, int bValue, int nIndex = -1);
void JsonArraySetBoolInplace(json jArray, int nIndex, int bValue);
void JsonObjectSetVectorInplace(json jObject, string sKey, vector vValue);
void JsonSetAtPointerInplace(json jParent, string sPointer, json jValue);
void JsonObjectSetObjectInplace(json jObject, string sKey, object oValue);
object JsonObjectGetObject(json jObject, string sKey);
json JsonObjectRef(object oObject);
object JsonGetObjectRef(json jValue);
int JsonObjectContainsKey(json jObject, string sKey);
json StructToJson(string sStructVarName, int nDepthOverride = 0);
int JsonToStruct(string sStructVarName, json jStruct, int nDepthOverride = 0);

json VectorToJson(vector vVector)
{
    json jVector = JsonObject();
    JsonObjectSetFloatInplace(jVector, "x", vVector.x);
    JsonObjectSetFloatInplace(jVector, "y", vVector.y);
    JsonObjectSetFloatInplace(jVector, "z", vVector.z);
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
    JsonObjectSetStringInplace(jLocation, "area_tag", sAreaTag);
    JsonObjectSetStringInplace(jLocation, "area_resref", sAreaResRef);
    JsonObjectSetVectorInplace(jLocation, "position", vPosition);
    JsonObjectSetFloatInplace(jLocation, "orientation", fOrientation);

    return jLocation;
}

location JsonToLocation(json jLocation)
{
    object oArea = GetObjectByTag(JsonObjectGetString(jLocation, "area_tag"));
    string sResRef = JsonObjectGetString(jLocation, "area_resref");

    if (!GetIsObjectValid(oArea) || GetResRef(oArea) != sResRef)
        return Location(OBJECT_INVALID, Vector(0.0f, 0.0f, 0.0f), 0.0f);

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

json JsonArrayInsertUniqueString(json jArray, string sValue, int nIndex = -1)
{
    if (!JsonArrayContainsString(jArray, sValue))
        return JsonArrayInsertString(jArray, sValue, nIndex);
    else
        return jArray;
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

json JsonArrayInsertUniqueInt(json jArray, int nValue, int nIndex = -1)
{
    if (!JsonArrayContainsInt(jArray, nValue))
        return JsonArrayInsertInt(jArray, nValue, nIndex);
    else
        return jArray;
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

int JsonArrayContainsString(json jArray, string sValue)
{
    return JsonGetType(JsonFind(jArray, JsonString(sValue))) == JSON_TYPE_INTEGER;
}

int JsonArrayContainsInt(json jArray, int nValue)
{
    return JsonGetType(JsonFind(jArray, JsonInt(nValue))) == JSON_TYPE_INTEGER;
}

json JsonPointInt(int nX, int nY)
{
    json jPoint = JsonObject();
    JsonObjectSetIntInplace(jPoint, "x", nX);
    JsonObjectSetIntInplace(jPoint, "y", nY);
    return jPoint;
}

void InsertStringToLocalJsonArray(object oObject, string sVarName, string sValue, int nIndex = -1)
{
    json jArray = GetLocalJson(oObject, sVarName);
    if (JsonGetType(jArray) != JSON_TYPE_ARRAY)
    {
        jArray = JsonArray();
        SetLocalJson(oObject, sVarName, jArray);
    }
    JsonArrayInsertStringInplace(jArray, sValue, nIndex);
}

void InsertIntToLocalJsonArray(object oObject, string sVarName, int nValue, int nIndex = -1)
{
    json jArray = GetLocalJson(oObject, sVarName);
    if (JsonGetType(jArray) != JSON_TYPE_ARRAY)
    {
        jArray = JsonArray();
        SetLocalJson(oObject, sVarName, jArray);
    }
    JsonArrayInsertIntInplace(jArray, nValue, nIndex);
}

string GetStringFromLocalJsonArray(object oObject, string sVarName, int nIndex)
{
    return JsonArrayGetString(GetLocalJsonArray(oObject, sVarName), nIndex);
}

int GetIntFromLocalJsonArray(object oObject, string sVarName, int nIndex)
{
    return JsonArrayGetInt(GetLocalJsonArray(oObject, sVarName), nIndex);
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

json GetJsonArrayOfSize(int nSize, json jDefaultValue)
{
    json jArray = JsonArray();
    int nCount;
    for (nCount = 0; nCount < nSize; nCount++)
    {
        JsonArrayInsertInplace(jArray, jDefaultValue);
    }
    return jArray;
}

json GetJsonArrayFromTokenizedString(string sTokens, string sDelimiter = ":")
{
    json jArray = JsonArray();
	int nStart, nEnd;

	while ((nEnd = FindSubString(sTokens, sDelimiter, nStart)) != -1)
	{
		JsonArrayInsertStringInplace(jArray, GetSubString(sTokens, nStart, nEnd - nStart));
		nStart = nEnd + 1;
	}

	nEnd = GetStringLength(sTokens);
	if (nEnd >= nStart)
		JsonArrayInsertStringInplace(jArray, GetSubString(sTokens, nStart, nEnd - nStart));

	return jArray;
}

void JsonArrayInsertStringInplace(json jArray, string sValue, int nIndex = -1)
{
    JsonArrayInsertInplace(jArray, JsonString(sValue), nIndex);
}

void JsonArrayInsertIntInplace(json jArray, int nValue, int nIndex = -1)
{
    JsonArrayInsertInplace(jArray, JsonInt(nValue), nIndex);
}

void JsonArrayInsertFloatInplace(json jArray, float fValue, int nIndex = -1)
{
    JsonArrayInsertInplace(jArray, JsonFloat(fValue), nIndex);
}

void JsonObjectSetIntInplace(json jObject, string sKey, int nValue)
{
    JsonObjectSetInplace(jObject, sKey, JsonInt(nValue));
}

void JsonObjectSetStringInplace(json jObject, string sKey, string sValue)
{
    JsonObjectSetInplace(jObject, sKey, JsonString(sValue));
}

void JsonObjectSetFloatInplace(json jObject, string sKey, float fValue)
{
    JsonObjectSetInplace(jObject, sKey, JsonFloat(fValue));
}

void JsonArrayInsertBoolInplace(json jArray, int bValue, int nIndex = -1)
{
    JsonArrayInsertInplace(jArray, JsonBool(bValue), nIndex);
}

void JsonArraySetBoolInplace(json jArray, int nIndex, int bValue)
{
    JsonArraySetInplace(jArray, nIndex, JsonBool(bValue));
}

void JsonObjectSetVectorInplace(json jObject, string sKey, vector vValue)
{
    JsonObjectSetInplace(jObject, sKey, VectorToJson(vValue));
}

void JsonSetAtPointerInplace(json jParent, string sPointer, json jValue)
{
    NWNX_Json_SetAtPointerInplace(jParent, sPointer, jValue);
}

void JsonObjectSetObjectInplace(json jObject, string sKey, object oValue)
{
    JsonObjectSetStringInplace(jObject, sKey, ObjectToString(oValue));
}

object JsonObjectGetObject(json jObject, string sKey)
{
    return StringToObject(JsonObjectGetString(jObject, sKey));
}

json JsonObjectRef(object oObject)
{
    return JsonString(ObjectToString(oObject));
}

object JsonGetObjectRef(json jValue)
{
    return StringToObject(JsonGetString(jValue));
}

int JsonObjectContainsKey(json jObject, string sKey)
{
    return NWNX_Json_JsonObjectContainsKey(jObject, sKey);
}

json StructToJsonImpl(string sMemberStructVarName, string sParentStructVarName, json jStack, json jStackKeys)
{
    string sStructVarName;
    if (sParentStructVarName == "")
        sStructVarName = sMemberStructVarName;
    else
        sStructVarName = sParentStructVarName + "." + sMemberStructVarName;

    if (!JsonObjectContainsKey(jStack, sStructVarName))
        return JsonNull();
    json jStructVar = JsonObjectGet(jStack, sStructVarName);
    if (JsonObjectGetInt(jStructVar, NWNX_VM_TYPE_KEY) != NWNX_VM_AUXTYPE_VOID)
        return JsonNull();
    string sStructName = JsonObjectGetString(jStructVar, NWNX_VM_STRUCT_NAME_KEY);
    if (sStructName == "")
        return JsonNull();

    json jStruct = JsonObject();
    JsonObjectSetStringInplace(jStruct, NWNX_VM_STRUCT_NAME_KEY, sStructName);

    int nStructVarNameLength = GetStringLength(sStructVarName);
    int nKey, nNumStackKeys = JsonGetLength(jStackKeys);
    for (nKey = 0; nKey < nNumStackKeys; nKey++)
    {
        string sKey = JsonArrayGetString(jStackKeys, nKey);
        if (GetStringLeft(sKey, nStructVarNameLength) == sStructVarName && sKey != sStructVarName)
        {
            string sMemberName = GetSubString(sKey, nStructVarNameLength + 1, GetStringLength(sKey) - nStructVarNameLength - 1);
            if (FindSubString(sMemberName, ".", 0) == -1)
            {
                json jStructVar = JsonObjectGet(jStack, sKey);
                int nAuxType = JsonObjectGetInt(jStructVar, NWNX_VM_TYPE_KEY);
                int nStackLocation = JsonObjectGetInt(jStructVar, NWNX_VM_STACK_LOCATION_KEY);

                json jStructMember = JsonObject();
                JsonObjectSetIntInplace(jStructMember, NWNX_VM_TYPE_KEY, nAuxType);

                switch (nAuxType)
                {
                    case NWNX_VM_AUXTYPE_INT:
                        JsonObjectSetIntInplace(jStructMember, JSON_STRUCT_VALUE_KEY, NWNX_VM_GetStackIntegerValue(nStackLocation));
                        break;
                    case NWNX_VM_AUXTYPE_FLOAT:
                        JsonObjectSetFloatInplace(jStructMember, JSON_STRUCT_VALUE_KEY, NWNX_VM_GetStackFloatValue(nStackLocation));
                        break;
                    case NWNX_VM_AUXTYPE_STRING:
                        JsonObjectSetStringInplace(jStructMember, JSON_STRUCT_VALUE_KEY, NWNX_VM_GetStackStringValue(nStackLocation));
                        break;
                    case NWNX_VM_AUXTYPE_OBJECT:
                        JsonObjectSetStringInplace(jStructMember, JSON_STRUCT_VALUE_KEY, ObjectToString(NWNX_VM_GetStackObjectValue(nStackLocation)));
                        break;
                    case NWNX_VM_AUXTYPE_LOCATION:
                        JsonObjectSetInplace(jStructMember, JSON_STRUCT_VALUE_KEY, LocationToJson(NWNX_VM_GetStackLocationValue(nStackLocation)));
                        break;
                    case NWNX_VM_AUXTYPE_JSON:
                        JsonObjectSetInplace(jStructMember, JSON_STRUCT_VALUE_KEY, NWNX_VM_GetStackJsonValue(nStackLocation));
                        break;
                    case NWNX_VM_AUXTYPE_VOID:
                        JsonObjectSetInplace(jStructMember, JSON_STRUCT_VALUE_KEY, StructToJsonImpl(sMemberName, sStructVarName, jStack, jStackKeys));
                        break;
                }
                JsonObjectSetInplace(jStruct, sMemberName, jStructMember);
            }
        }
    }

    return jStruct;
}

json StructToJson(string sStructVarName, int nDepthOverride = 0)
{
    json jStack = NWNX_VM_GetStackVariables(2 + nDepthOverride);
    return StructToJsonImpl(sStructVarName, "", jStack, JsonObjectKeys(jStack));
}

int JsonToStructImpl(string sMemberStructVarName, string sParentStructVarName, json jStruct, json jStack)
{
    string sStructVarName;
    if (sParentStructVarName == "")
        sStructVarName = sMemberStructVarName;
    else
        sStructVarName = sParentStructVarName + "." + sMemberStructVarName;

    if (sStructVarName == "" || !JsonGetType(jStruct))
        return FALSE;
    if (!JsonObjectContainsKey(jStack, sStructVarName))
        return FALSE;
    if (JsonObjectGetString(JsonObjectGet(jStack, sStructVarName), NWNX_VM_STRUCT_NAME_KEY) != JsonObjectGetString(jStruct, NWNX_VM_STRUCT_NAME_KEY))
        return FALSE;

    int nRetVal = TRUE;
    jStruct = JsonObjectDel(jStruct, NWNX_VM_STRUCT_NAME_KEY);
    json jStructKeys = JsonObjectKeys(jStruct);
    int nStructKey, nNumStructKeys = JsonGetLength(jStructKeys);
    for (nStructKey = 0; nStructKey < nNumStructKeys; nStructKey++)
    {
        string sStructKey = JsonArrayGetString(jStructKeys, nStructKey);
        string sTargetKey = sStructVarName + "." + sStructKey;
        if (JsonObjectContainsKey(jStack, sTargetKey))
        {
            json jStructMember = JsonObjectGet(jStruct, sStructKey);
            int nAuxType = JsonObjectGetInt(jStructMember, NWNX_VM_TYPE_KEY);
            json jTargetStructMember = JsonObjectGet(jStack, sTargetKey);
            int nTargetAuxType = JsonObjectGetInt(jTargetStructMember, NWNX_VM_TYPE_KEY);

            if (nAuxType == nTargetAuxType)
            {
                int nTargetStackLocation = JsonObjectGetInt(jTargetStructMember, NWNX_VM_STACK_LOCATION_KEY);
                switch (nAuxType)
                {
                    case NWNX_VM_AUXTYPE_INT:
                        NWNX_VM_SetStackIntegerValue(nTargetStackLocation, JsonObjectGetInt(jStructMember, JSON_STRUCT_VALUE_KEY));
                        break;
                    case NWNX_VM_AUXTYPE_FLOAT:
                        NWNX_VM_SetStackFloatValue(nTargetStackLocation, JsonObjectGetFloat(jStructMember, JSON_STRUCT_VALUE_KEY));
                        break;
                    case NWNX_VM_AUXTYPE_STRING:
                        NWNX_VM_SetStackStringValue(nTargetStackLocation, JsonObjectGetString(jStructMember, JSON_STRUCT_VALUE_KEY));
                        break;
                    case NWNX_VM_AUXTYPE_OBJECT:
                        NWNX_VM_SetStackObjectValue(nTargetStackLocation, StringToObject(JsonObjectGetString(jStructMember, JSON_STRUCT_VALUE_KEY)));
                        break;
                    case NWNX_VM_AUXTYPE_LOCATION:
                        NWNX_VM_SetStackLocationValue(nTargetStackLocation, JsonToLocation(JsonObjectGet(jStructMember, JSON_STRUCT_VALUE_KEY)));
                        break;
                    case NWNX_VM_AUXTYPE_JSON:
                        NWNX_VM_SetStackJsonValue(nTargetStackLocation, JsonObjectGet(jStructMember, JSON_STRUCT_VALUE_KEY));
                        break;
                    case NWNX_VM_AUXTYPE_VOID:
                        nRetVal &= JsonToStructImpl(sStructKey, sStructVarName, JsonObjectGet(jStructMember, JSON_STRUCT_VALUE_KEY), jStack);
                        break;
                }
            }
            else
            {
                nRetVal &= FALSE;
            }
        }
        else
        {
            nRetVal &= FALSE;
        }
    }
    return nRetVal;
}

int JsonToStruct(string sStructVarName, json jStruct, int nDepthOverride = 0)
{
    json jStack = NWNX_VM_GetStackVariables(2 + nDepthOverride);
    return JsonToStructImpl(sStructVarName, "", jStruct, jStack);
}
