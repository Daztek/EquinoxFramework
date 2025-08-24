/*
    Script: ef_i_strfmt
    Author: Daz
*/

#include "ef_i_convert"
#include "ef_i_string"
#include "ef_i_util"
#include "ef_i_vm"
#include "nwnx_object"

struct FormatValue
{
    int nAuxType;
    string sFormatSpecifier;

    int nValue;
    float fValue;
    string sValue;
    object oValue;
    json jValue;
    location locValue;
};

struct PropertyChain
{
    string sBaseVarName;
    string sFullPropertyPath;
    string sRemainingPropertyPath;
    string sCurrentProperty;
    struct FormatValue strFormat;
};

struct FormatValue GetFormatValueFromStackLocation(int nAuxType, int nStackLocation, string sFormatSpecifier);
struct FormatValue GetFormatValueFromInt(int nValue, string sFormatSpecifier);
struct FormatValue GetFormatValueFromFloat(float fValue, string sFormatSpecifier);
struct FormatValue GetFormatValueFromString(string sValue, string sFormatSpecifier);
struct FormatValue GetFormatValueFromObject(object oValue, string sFormatSpecifier);
struct FormatValue GetFormatValueFromLocation(location locValue, string sFormatSpecifier);
struct FormatValue GetFormatValueFromJson(json jValue, string sFormatSpecifier);

string FormatString(string sString, int nDepthOverride = 0);
string GetFormattedValue(json jStack, string sVarName, string sFormatSpecifier);
string FormatValueByType(struct FormatValue strFormat);
string FormatAsString(struct FormatValue strFormat);
string FormatAsInteger(struct FormatValue strFormat);
string FormatAsFloat(struct FormatValue strFormat);
string FormatAsHex(struct FormatValue strFormat);
string FormatAsBoolean(struct FormatValue strFormat);
string FormatAsVector(json jStack, string sVarName, string sFormatSpecifier);
string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "");

string GetPropertyValue(struct PropertyChain strPC);
struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC);
struct PropertyChain GetIntProperty(struct PropertyChain strPC);
struct PropertyChain GetFloatProperty(struct PropertyChain strPC);
struct PropertyChain GetStringProperty(struct PropertyChain strPC);
struct PropertyChain GetObjectProperty(struct PropertyChain strPC);
struct PropertyChain GetLocationProperty(struct PropertyChain strPC);
struct PropertyChain GetJsonProperty(struct PropertyChain strPC);

struct FormatValue GetFormatValueFromStackLocation(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    struct FormatValue str;
    str.nAuxType = nAuxType;
    str.sFormatSpecifier = sFormatSpecifier;
    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT: str.nValue = NWNX_VM_GetStackIntegerValue(nStackLocation); break;
        case NWNX_VM_AUXTYPE_FLOAT: str.fValue = NWNX_VM_GetStackFloatValue(nStackLocation); break;
        case NWNX_VM_AUXTYPE_STRING: str.sValue = NWNX_VM_GetStackStringValue(nStackLocation); break;
        case NWNX_VM_AUXTYPE_OBJECT: str.oValue = NWNX_VM_GetStackObjectValue(nStackLocation); break;
        case NWNX_VM_AUXTYPE_LOCATION: str.locValue = NWNX_VM_GetStackLocationValue(nStackLocation); break;
        case NWNX_VM_AUXTYPE_JSON: str.jValue = NWNX_VM_GetStackJsonValue(nStackLocation); break;
    }
    return str;
}

struct FormatValue GetFormatValueFromInt(int nValue, string sFormatSpecifier)
{
    struct FormatValue str;
    str.nAuxType = NWNX_VM_AUXTYPE_INT;
    str.sFormatSpecifier = sFormatSpecifier;
    str.nValue = nValue;
    return str;
}

struct FormatValue GetFormatValueFromFloat(float fValue, string sFormatSpecifier)
{
    struct FormatValue str;
    str.nAuxType = NWNX_VM_AUXTYPE_FLOAT;
    str.sFormatSpecifier = sFormatSpecifier;
    str.fValue = fValue;
    return str;
}

struct FormatValue GetFormatValueFromString(string sValue, string sFormatSpecifier)
{
    struct FormatValue str;
    str.nAuxType = NWNX_VM_AUXTYPE_STRING;
    str.sFormatSpecifier = sFormatSpecifier;
    str.sValue = sValue;
    return str;
}

struct FormatValue GetFormatValueFromObject(object oValue, string sFormatSpecifier)
{
    struct FormatValue str;
    str.nAuxType = NWNX_VM_AUXTYPE_OBJECT;
    str.sFormatSpecifier = sFormatSpecifier;
    str.oValue = oValue;
    return str;
}

struct FormatValue GetFormatValueFromLocation(location locValue, string sFormatSpecifier)
{
    struct FormatValue str;
    str.nAuxType = NWNX_VM_AUXTYPE_LOCATION;
    str.sFormatSpecifier = sFormatSpecifier;
    str.locValue = locValue;
    return str;
}

struct FormatValue GetFormatValueFromJson(json jValue, string sFormatSpecifier)
{
    struct FormatValue str;
    str.nAuxType = NWNX_VM_AUXTYPE_JSON;
    str.sFormatSpecifier = sFormatSpecifier;
    str.jValue = jValue;
    return str;
}

string FormatString(string sString, int nDepthOverride = 0)
{
    if (sString == "" || FindSubString(sString, "{", 0) == -1)
        return sString;

    json jVariables = RegExpIterate("\\{([\\w\\.>]+)(?::(%[a-z0-9\\.]{0,5}))?\\}", sString);
    int nIndex, nNumVariables = JsonGetLength(jVariables);

    if (!nNumVariables)
        return sString;

    json jStack = NWNX_VM_GetCurrentStack(2 + nDepthOverride);
    string sResult = sString;

    for (nIndex = 0; nIndex < nNumVariables; nIndex++)
    {
        json jVariable = JsonArrayGet(jVariables, nIndex);
        string sFullMatch = JsonArrayGetString(jVariable, 0);
        string sVarName = JsonArrayGetString(jVariable, 1);
        string sFormatSpecifier = GetStringLowerCase(JsonArrayGetString(jVariable, 2));

        string sPattern = "\\{" + RegExpEscape(sVarName);
        if (sFormatSpecifier != "")
            sPattern += ":" + RegExpEscape(sFormatSpecifier);
        sPattern += "\\}";

        string sValue = GetFormattedValue(jStack, sVarName, sFormatSpecifier);
        sResult = RegExpReplace(sPattern, sResult, sValue);
    }

    return sResult;
}

string GetFormattedValue(json jStack, string sVarName, string sFormatSpecifier)
{
    if (sFormatSpecifier == "")
        sFormatSpecifier = "%s";

    int nPropertyPosition = FindSubString(sVarName, ">", 0);
    if (nPropertyPosition != -1)
    {
        string sBaseVarName = GetStringLeft(sVarName, nPropertyPosition);

        if (!JsonObjectContainsKey(jStack, sBaseVarName))
            return "[MISSING_VAR:" + sBaseVarName + "]";

        json jStackVar = JsonObjectGet(jStack, sBaseVarName);

        string sPropertyPath = GetSubString(sVarName, nPropertyPosition + 1, GetStringLength(sVarName) - nPropertyPosition - 1);

        struct PropertyChain strPC;
        strPC.sBaseVarName = sBaseVarName;
        strPC.sFullPropertyPath = sPropertyPath;
        strPC.sRemainingPropertyPath = sPropertyPath;
        strPC.sCurrentProperty = "";
        strPC.strFormat = GetFormatValueFromStackLocation(
            JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY),
            JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY),
            sFormatSpecifier);

        return GetPropertyValue(strPC);
    }

    if (!JsonObjectContainsKey(jStack, sVarName))
        return "[MISSING_VAR:" + sVarName + "]";

    json jStackVar = JsonObjectGet(jStack, sVarName);
    if (JsonGetType(jStackVar) != JSON_TYPE_OBJECT)
        return "[INVALID_STACK_VAR:" + sVarName + "]";

    int nAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);

    if (nAuxType == NWNX_VM_AUXTYPE_VOID)
    {
        string sStructName = JsonObjectGetString(jStackVar, NWNX_VM_STRUCT_NAME_KEY);
        if (sStructName == "vector")
            return FormatAsVector(jStack, sVarName, sFormatSpecifier);
        else
            return DumpStruct(jStack, sVarName, sStructName);
    }

    int nStackLocation = JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY);
    return FormatValueByType(GetFormatValueFromStackLocation(nAuxType, nStackLocation, sFormatSpecifier));
}

string FormatValueByType(struct FormatValue strFormat)
{
    if (strFormat.sFormatSpecifier == "%s")
    {
        return FormatAsString(strFormat);
    }

    if (strFormat.sFormatSpecifier == "%i")
    {
        return FormatAsInteger(strFormat);
    }

    if (strFormat.sFormatSpecifier == "%f" ||
        (GetStringLeft(strFormat.sFormatSpecifier, 2) == "%." && GetStringRight(strFormat.sFormatSpecifier, 1) == "f"))
    {
        return FormatAsFloat(strFormat);
    }

    if (strFormat.sFormatSpecifier == "%x")
    {
        return FormatAsHex(strFormat);
    }

    if (strFormat.sFormatSpecifier == "%b")
    {
        return FormatAsBoolean(strFormat);
    }

    return "[INVALID_FORMAT:" + strFormat.sFormatSpecifier + "->" + AuxTypeToString(strFormat.nAuxType) + "]";
}

string FormatAsString(struct FormatValue strFormat)
{
    switch (strFormat.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return strFormat.sValue;
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strFormat.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strFormat.fValue, 0, 2);
        case NWNX_VM_AUXTYPE_OBJECT:
        {
            if (!GetIsObjectValid(strFormat.oValue))
                return "[INVALID_OBJECT|OID:0x" + ObjectToString(strFormat.oValue) + "]";
            return GetName(strFormat.oValue) + "(TAG:" + GetTag(strFormat.oValue)+ "|OID:0x" + ObjectToString(strFormat.oValue) + ")";
        }
        case NWNX_VM_AUXTYPE_LOCATION:
        {
            object oArea = GetAreaFromLocation(strFormat.locValue);
            if (!GetIsObjectValid(oArea))
                return "[INVALID_LOCATION]";

            vector vPosition = GetPositionFromLocation(strFormat.locValue);
            float fFacing = GetFacingFromLocation(strFormat.locValue);

            return GetTag(oArea) + "[" + FloatToString(vPosition.x, 0, 2) + "," + FloatToString(vPosition.y, 0, 2) + "," +
                FloatToString(vPosition.z, 0, 2) + "]@" + FloatToString(fFacing, 0, 1);
        }
        case NWNX_VM_AUXTYPE_JSON:
        {
            string sJson = JsonDump(strFormat.jValue);
            if (GetStringLength(sJson) > 200)
                sJson = GetStringLeft(sJson, 197) + "...";
            return sJson;
        }
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(strFormat.nAuxType) + "->%s]";
}

string FormatAsInteger(struct FormatValue strFormat)
{
    switch (strFormat.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:
        {
            int nParsed = StringToInt(strFormat.sValue);
            if (nParsed == 0 && strFormat.sValue != "0" && GetStringLeft(strFormat.sValue, 1) != "0")
                return "[PARSE_ERROR:" + strFormat.sValue + "]";
            return IntToString(nParsed);
        }
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strFormat.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return IntToString(FloatToInt(strFormat.fValue));
        case NWNX_VM_AUXTYPE_OBJECT:    return IntToString(HexStringToInt(ObjectToString(strFormat.oValue)));
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(strFormat.nAuxType) + "->%i]";
}

string FormatAsFloat(struct FormatValue strFormat)
{
    int nPrecision = 2;
    if (GetStringLength(strFormat.sFormatSpecifier) > 2 &&
        (GetStringLeft(strFormat.sFormatSpecifier, 2) == "%." && GetStringRight(strFormat.sFormatSpecifier, 1) == "f"))
    {
        nPrecision = StringToInt(GetSubString(strFormat.sFormatSpecifier, 2, GetStringLength(strFormat.sFormatSpecifier) - 3));
        if (nPrecision > 18)
            nPrecision = 18;
    }

    switch (strFormat.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return FloatToString(StringToFloat(strFormat.sValue), 0, nPrecision);
        case NWNX_VM_AUXTYPE_INT:       return FloatToString(IntToFloat(strFormat.nValue), 0, nPrecision);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strFormat.fValue, 0, nPrecision);
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(strFormat.nAuxType) + "->%f]";
}

string FormatAsHex(struct FormatValue strFormat)
{
    int nValue;
    switch (strFormat.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       nValue = strFormat.nValue; break;
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = FloatToInt(strFormat.fValue); break;
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(strFormat.oValue);
        default:                return "[TYPE_MISMATCH:" + AuxTypeToString(strFormat.nAuxType) + "->%x]";
    }
    return EFIntToHexString(nValue);
}

string FormatAsBoolean(struct FormatValue strFormat)
{
    int nValue;
    switch (strFormat.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       nValue = strFormat.nValue; break;
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = strFormat.fValue != 0.0; break;
        case NWNX_VM_AUXTYPE_STRING:    nValue = strFormat.sValue != ""; break;
        case NWNX_VM_AUXTYPE_OBJECT:    nValue = GetIsObjectValid(strFormat.oValue); break;
        case NWNX_VM_AUXTYPE_JSON:      nValue = JsonGetType(strFormat.jValue) != JSON_TYPE_NULL; break;
        default:                return "[TYPE_MISMATCH:" + AuxTypeToString(strFormat.nAuxType) + "->%b]";
    }
    return nValue ? "TRUE" : "FALSE";
}

string FormatAsVector(json jStack, string sVarName, string sFormatSpecifier)
{
    struct FormatValue str;
    str = GetFormatValueFromStackLocation(NWNX_VM_AUXTYPE_FLOAT,
        JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".x"), NWNX_VM_STACK_LOCATION_KEY), sFormatSpecifier);
    string sX = FormatValueByType(str);
    str = GetFormatValueFromStackLocation(NWNX_VM_AUXTYPE_FLOAT,
        JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".y"), NWNX_VM_STACK_LOCATION_KEY), sFormatSpecifier);
    string sY = FormatValueByType(str);
    str = GetFormatValueFromStackLocation(NWNX_VM_AUXTYPE_FLOAT,
        JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".z"), NWNX_VM_STACK_LOCATION_KEY), sFormatSpecifier);
    string sZ = FormatValueByType(str);
    return "[" + sX + "," + sY + "," + sZ + "]";
}

string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "")
{
    json jStackKeys = JsonObjectKeys(jStack);
    int nVarNameLength = GetStringLength(sVarName);
    int nKey, nNumKeys = JsonGetLength(jStackKeys);
    string sResult = "struct " + sStructName + " " + (sInstanceName  != "" ? sInstanceName : sVarName) + " { ";

    for (nKey = 0; nKey < nNumKeys; nKey++)
    {
        string sKey = JsonArrayGetString(jStackKeys, nKey);
        if (GetStringLeft(sKey, nVarNameLength) == sVarName && sKey != sVarName)
        {
            string sMemberPath = GetSubString(sKey, nVarNameLength + 1, GetStringLength(sKey) - nVarNameLength - 1);
            if (FindSubString(sMemberPath, ".", 0) == -1)
            {
                json jStructVar = JsonObjectGet(jStack, sKey);
                int nAuxType = JsonObjectGetInt(jStructVar, NWNX_VM_TYPE_KEY);

                if (nAuxType == NWNX_VM_AUXTYPE_VOID)
                {
                    string sChildStructName = JsonObjectGetString(jStructVar, NWNX_VM_STRUCT_NAME_KEY);
                    if (sChildStructName != "vector")
                        sResult += DumpStruct(jStack, sKey, sChildStructName, sMemberPath);
                    else
                    {
                        string sValue = GetFormattedValue(jStack, sKey, "%s");
                        sResult += "vector " + sMemberPath + " = " + sValue + "; ";
                    }
                }
                else
                {
                    string sValue = GetFormattedValue(jStack, sKey, "%s");
                    string sVariableType = GetStringLowerCase(AuxTypeToString(nAuxType));
                    sResult += sVariableType + " " + sMemberPath + " = " + sValue + "; ";
                }
            }
        }
    }

    sResult += "} ";
    return sResult;
}

string GetPropertyValue(struct PropertyChain strPC)
{
    do
    {
        int nPropertyPosition = FindSubString(strPC.sRemainingPropertyPath, ">", 0);
        if (nPropertyPosition == -1)
        {
            strPC.sCurrentProperty = strPC.sRemainingPropertyPath;
            strPC.sRemainingPropertyPath = "";
            strPC = GetPropertyValueByType(strPC);
            break;
        }
        strPC.sCurrentProperty = GetStringLeft(strPC.sRemainingPropertyPath, nPropertyPosition);
        strPC.sRemainingPropertyPath = GetSubString(strPC.sRemainingPropertyPath, nPropertyPosition + 1,
            GetStringLength(strPC.sRemainingPropertyPath) - nPropertyPosition - 1);

        strPC = GetPropertyValueByType(strPC);
    }
    while (strPC.sRemainingPropertyPath != "" && strPC.strFormat.nAuxType != NWNX_VM_AUXTYPE_INVALID);

    if (strPC.strFormat.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        return "[INVALID_PROPERT_CHAIN:" + strPC.sBaseVarName + ">" + strPC.sFullPropertyPath + "]";
    else
        return FormatValueByType(strPC.strFormat);
}

struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC)
{
    switch (strPC.strFormat.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT: strPC = GetIntProperty(strPC); break;
        case NWNX_VM_AUXTYPE_FLOAT: strPC = GetFloatProperty(strPC); break;
        case NWNX_VM_AUXTYPE_STRING: strPC = GetStringProperty(strPC); break;
        case NWNX_VM_AUXTYPE_OBJECT: strPC = GetObjectProperty(strPC); break;
        case NWNX_VM_AUXTYPE_LOCATION: strPC = GetLocationProperty(strPC); break;
        case NWNX_VM_AUXTYPE_JSON: strPC = GetJsonProperty(strPC); break;
        default: strPC.strFormat.nAuxType = NWNX_VM_AUXTYPE_INVALID; break;
    }
    return strPC;
}

struct PropertyChain GetIntProperty(struct PropertyChain strPC)
{
    strPC.strFormat.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    return strPC;
}

struct PropertyChain GetFloatProperty(struct PropertyChain strPC)
{
    strPC.strFormat.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    return strPC;
}

struct PropertyChain GetStringProperty(struct PropertyChain strPC)
{
    if (strPC.sCurrentProperty == "length")
        strPC.strFormat = GetFormatValueFromInt(GetStringLength(strPC.strFormat.sValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "upper")
        strPC.strFormat = GetFormatValueFromString(GetStringUpperCase(strPC.strFormat.sValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "lower")
        strPC.strFormat = GetFormatValueFromString(GetStringLowerCase(strPC.strFormat.sValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "trim")
        strPC.strFormat = GetFormatValueFromString(trim(strPC.strFormat.sValue), strPC.strFormat.sFormatSpecifier);
    else
        strPC.strFormat.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}

struct PropertyChain GetObjectProperty(struct PropertyChain strPC)
{
    if (strPC.sCurrentProperty == "name")
        strPC.strFormat = GetFormatValueFromString(GetName(strPC.strFormat.oValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "tag")
        strPC.strFormat = GetFormatValueFromString(GetTag(strPC.strFormat.oValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "resref")
        strPC.strFormat = GetFormatValueFromString(GetResRef(strPC.strFormat.oValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "type")
        strPC.strFormat = GetFormatValueFromString(GetObjectTypeName(strPC.strFormat.oValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "area")
        strPC.strFormat = GetFormatValueFromObject(GetArea(strPC.strFormat.oValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "valid")
        strPC.strFormat = GetFormatValueFromInt(GetIsObjectValid(strPC.strFormat.oValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "location")
        strPC.strFormat = GetFormatValueFromLocation(GetLocation(strPC.strFormat.oValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "x" || strPC.sCurrentProperty == "y" || strPC.sCurrentProperty == "z")
    {
        vector vPosition = GetPosition(strPC.strFormat.oValue);
        if (strPC.sCurrentProperty == "x")
            strPC.strFormat = GetFormatValueFromFloat(vPosition.x, strPC.strFormat.sFormatSpecifier);
        else if (strPC.sCurrentProperty == "y")
            strPC.strFormat = GetFormatValueFromFloat(vPosition.y, strPC.strFormat.sFormatSpecifier);
        else if (strPC.sCurrentProperty == "z")
            strPC.strFormat = GetFormatValueFromFloat(vPosition.z, strPC.strFormat.sFormatSpecifier);
    }
    else if (strPC.sCurrentProperty == "position")
    {
        vector vPosition = GetPosition(strPC.strFormat.oValue);
        string sX = FormatValueByType(GetFormatValueFromFloat(vPosition.x, strPC.strFormat.sFormatSpecifier));
        string sY = FormatValueByType(GetFormatValueFromFloat(vPosition.y, strPC.strFormat.sFormatSpecifier));
        string sZ = FormatValueByType(GetFormatValueFromFloat(vPosition.z, strPC.strFormat.sFormatSpecifier));
        strPC.strFormat = GetFormatValueFromString("[" + sX + "," + sY + ","  + sZ + "]", "%s");
    }
    else
        strPC.strFormat.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}

struct PropertyChain GetLocationProperty(struct PropertyChain strPC)
{
    if (strPC.sCurrentProperty == "area")
        strPC.strFormat = GetFormatValueFromObject(GetAreaFromLocation(strPC.strFormat.locValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "x" || strPC.sCurrentProperty == "y" || strPC.sCurrentProperty == "z")
    {
        vector vPosition = GetPositionFromLocation(strPC.strFormat.locValue);
        if (strPC.sCurrentProperty == "x")
            strPC.strFormat = GetFormatValueFromFloat(vPosition.x, strPC.strFormat.sFormatSpecifier);
        else if (strPC.sCurrentProperty == "y")
            strPC.strFormat = GetFormatValueFromFloat(vPosition.y, strPC.strFormat.sFormatSpecifier);
        else if (strPC.sCurrentProperty == "z")
            strPC.strFormat = GetFormatValueFromFloat(vPosition.z, strPC.strFormat.sFormatSpecifier);
    }
    else if (strPC.sCurrentProperty == "facing")
        strPC.strFormat = GetFormatValueFromFloat(GetFacingFromLocation(strPC.strFormat.locValue), strPC.strFormat.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "position")
    {
        vector vPosition = GetPositionFromLocation(strPC.strFormat.locValue);
        string sX = FormatValueByType(GetFormatValueFromFloat(vPosition.x, strPC.strFormat.sFormatSpecifier));
        string sY = FormatValueByType(GetFormatValueFromFloat(vPosition.y, strPC.strFormat.sFormatSpecifier));
        string sZ = FormatValueByType(GetFormatValueFromFloat(vPosition.z, strPC.strFormat.sFormatSpecifier));
        strPC.strFormat = GetFormatValueFromString("[" + sX + "," + sY + ","  + sZ + "]", "%s");
    }
    else if (strPC.sCurrentProperty == "valid")
        strPC.strFormat = GetFormatValueFromInt(GetIsObjectValid(GetAreaFromLocation(strPC.strFormat.locValue)), strPC.strFormat.sFormatSpecifier);
    else
        strPC.strFormat.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}

struct PropertyChain GetJsonProperty(struct PropertyChain strPC)
{
    strPC.strFormat.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    return strPC;
}
