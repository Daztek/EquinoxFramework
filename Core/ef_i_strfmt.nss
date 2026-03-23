/*
    Script: ef_i_strfmt
    Author: Daz
*/

#include "ef_i_convert"
#include "ef_i_math"
#include "ef_i_string"
#include "ef_i_dataobject"
#include "nwnx_util"
#include "nwnx_vm"

const string STRFMT_SCRIPT_NAME     = "ef_i_strfmt";
const string STRFMT_CACHE_PREFIX    = "StringFormatCache_";

struct Value
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
    string sCurrentParameters;
    struct Value strValue;
};

string FormatString(string sString, int nDepthOverride = 0);
string GetFormattedValue(json jStack, string sVarName, string sFormatSpecifier);
string FormatValueByType(struct Value strValue);
string FormatAsString(struct Value strValue);
string FormatAsInteger(struct Value strValue);
string FormatAsFloat(struct Value strValue);
string FormatAsHex(struct Value strValue);
string FormatAsBoolean(struct Value strValue);
string FormatAsVector(json jStack, string sVarName, string sFormatSpecifier);
string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "");

struct Value GetValueFromStackLocation(int nAuxType, int nStackLocation, string sFormatSpecifier);
struct Value GetValueFromInt(int nValue, string sFormatSpecifier);
struct Value GetValueFromFloat(float fValue, string sFormatSpecifier);
struct Value GetValueFromString(string sValue, string sFormatSpecifier);
struct Value GetValueFromObject(object oValue, string sFormatSpecifier);
struct Value GetValueFromLocation(location locValue, string sFormatSpecifier);
struct Value GetValueFromJson(json jValue, string sFormatSpecifier);

struct PropertyChain ParsePropertyAndParameters(struct PropertyChain strPC, string sPropertySegment);
json ParseParameters(string sParameters);
string GetPropertyValue(struct PropertyChain strPC);
struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC);
struct PropertyChain GetIntProperty(struct PropertyChain strPC);
struct PropertyChain GetFloatProperty(struct PropertyChain strPC);
struct PropertyChain GetStringProperty(struct PropertyChain strPC);
struct PropertyChain GetObjectProperty(struct PropertyChain strPC);
struct PropertyChain GetLocationProperty(struct PropertyChain strPC);
struct PropertyChain GetJsonProperty(struct PropertyChain strPC);

string FormatString(string sString, int nDepthOverride = 0)
{
    if (sString == "" || FindSubString(sString, "{", 0) == -1)
        return sString;

    object oDataObject = GetDataObject(STRFMT_SCRIPT_NAME);
    int nHash = HashString(sString);
    json jVariables = GetLocalJson(oDataObject, STRFMT_CACHE_PREFIX + IntToString(nHash));

    if (!JsonGetType(jVariables))
    {
        jVariables = RegExpIterate("\\{([\\w\\.>\\(\\),0-9]+)(?::(%[a-z0-9\\.]{0,5}))?\\}", sString);
        SetLocalJson(oDataObject, STRFMT_CACHE_PREFIX + IntToString(nHash), jVariables);
    }

    int nIndex, nNumVariables = JsonGetLength(jVariables);

    if (!nNumVariables)
        return sString;

    json jStack = NWNX_VM_GetStackVariables(2 + nDepthOverride);
    string sResult = sString;

    for (nIndex = 0; nIndex < nNumVariables; nIndex++)
    {
        json jVariable = JsonArrayGet(jVariables, nIndex);
        string sPattern = NWNX_Util_RegExpEscape(JsonArrayGetString(jVariable, 0));
        string sVarName = JsonArrayGetString(jVariable, 1);
        string sFormatSpecifier = GetStringLowerCase(JsonArrayGetString(jVariable, 2));
        string sValue = GetFormattedValue(jStack, sVarName, sFormatSpecifier);
        sResult = RegExpReplace(sPattern, sResult, sValue, REGEXP_ECMASCRIPT, REGEXP_FORMAT_FIRST_ONLY);
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
        strPC.strValue = GetValueFromStackLocation(JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY), JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), sFormatSpecifier);

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

    return FormatValueByType(GetValueFromStackLocation(nAuxType, JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), sFormatSpecifier));
}

string FormatValueByType(struct Value strValue)
{
    if (strValue.sFormatSpecifier == "%s")
    {
        return FormatAsString(strValue);
    }

    if (strValue.sFormatSpecifier == "%i")
    {
        return FormatAsInteger(strValue);
    }

    if (strValue.sFormatSpecifier == "%f" ||
        (GetStringLeft(strValue.sFormatSpecifier, 2) == "%." && GetStringRight(strValue.sFormatSpecifier, 1) == "f"))
    {
        return FormatAsFloat(strValue);
    }

    if (strValue.sFormatSpecifier == "%x")
    {
        return FormatAsHex(strValue);
    }

    if (strValue.sFormatSpecifier == "%b")
    {
        return FormatAsBoolean(strValue);
    }

    return "[INVALID_FORMAT:" + strValue.sFormatSpecifier + "->" + AuxTypeToString(strValue.nAuxType) + "]";
}

string FormatAsString(struct Value strValue)
{
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return strValue.sValue;
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strValue.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strValue.fValue, 0, 2);
        case NWNX_VM_AUXTYPE_OBJECT:
        {
            if (!GetIsObjectValid(strValue.oValue))
                return "[INVALID_OBJECT|OID:0x" + ObjectToString(strValue.oValue) + "]";
            return GetName(strValue.oValue) + "(TAG:" + GetTag(strValue.oValue)+ "|OID:0x" + ObjectToString(strValue.oValue) + ")";
        }
        case NWNX_VM_AUXTYPE_LOCATION:
        {
            object oArea = GetAreaFromLocation(strValue.locValue);
            if (!GetIsObjectValid(oArea))
                return "[INVALID_LOCATION]";

            vector vPosition = GetPositionFromLocation(strValue.locValue);
            float fFacing = GetFacingFromLocation(strValue.locValue);

            return GetTag(oArea) + "[" + FloatToString(vPosition.x, 0, 2) + "," + FloatToString(vPosition.y, 0, 2) + "," +
                FloatToString(vPosition.z, 0, 2) + "]@" + FloatToString(fFacing, 0, 1);
        }
        case NWNX_VM_AUXTYPE_JSON:
        {
            string sJson = JsonDump(strValue.jValue);
            if (GetStringLength(sJson) > 200)
                sJson = GetStringLeft(sJson, 197) + "...";
            return sJson;
        }
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->%s]";
}

string FormatAsInteger(struct Value strValue)
{
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:
        {
            int nParsed = StringToInt(strValue.sValue);
            if (nParsed == 0 && strValue.sValue != "0" && GetStringLeft(strValue.sValue, 1) != "0")
                return "[PARSE_ERROR:" + strValue.sValue + "]";
            return IntToString(nParsed);
        }
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strValue.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return IntToString(FloatToInt(strValue.fValue));
        case NWNX_VM_AUXTYPE_OBJECT:    return IntToString(HexStringToInt(ObjectToString(strValue.oValue)));
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->%i]";
}

string FormatAsFloat(struct Value strValue)
{
    int nPrecision = 2;
    int nPrecisionLength = GetStringLength(strValue.sFormatSpecifier);
    if (nPrecisionLength > 2 && (GetStringLeft(strValue.sFormatSpecifier, 2) == "%." && GetStringRight(strValue.sFormatSpecifier, 1) == "f"))
        nPrecision = clamp(StringToInt(GetSubString(strValue.sFormatSpecifier, 2, nPrecisionLength - 3)), 0, 9);

    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return FloatToString(StringToFloat(strValue.sValue), 0, nPrecision);
        case NWNX_VM_AUXTYPE_INT:       return FloatToString(IntToFloat(strValue.nValue), 0, nPrecision);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strValue.fValue, 0, nPrecision);
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->%f]";
}

string FormatAsHex(struct Value strValue)
{
    int nValue;
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       nValue = strValue.nValue; break;
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = FloatToInt(strValue.fValue); break;
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(strValue.oValue);
        default: return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->%x]";
    }
    return EFIntToHexString(nValue);
}

string FormatAsBoolean(struct Value strValue)
{
    int nValue;
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       nValue = strValue.nValue; break;
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = strValue.fValue != 0.0; break;
        case NWNX_VM_AUXTYPE_STRING:    nValue = strValue.sValue != ""; break;
        case NWNX_VM_AUXTYPE_OBJECT:    nValue = GetIsObjectValid(strValue.oValue); break;
        case NWNX_VM_AUXTYPE_JSON:      nValue = JsonGetType(strValue.jValue) != JSON_TYPE_NULL; break;
        default:                return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->%b]";
    }
    return nValue ? "TRUE" : "FALSE";
}

string FormatAsVector(json jStack, string sVarName, string sFormatSpecifier)
{
    string sX = FormatValueByType(GetValueFromStackLocation(NWNX_VM_AUXTYPE_FLOAT,
        JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".x"), NWNX_VM_STACK_LOCATION_KEY), sFormatSpecifier));
    string sY = FormatValueByType(GetValueFromStackLocation(NWNX_VM_AUXTYPE_FLOAT,
        JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".y"), NWNX_VM_STACK_LOCATION_KEY), sFormatSpecifier));
    string sZ = FormatValueByType(GetValueFromStackLocation(NWNX_VM_AUXTYPE_FLOAT,
        JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".z"), NWNX_VM_STACK_LOCATION_KEY), sFormatSpecifier));
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
                    if (sChildStructName == "vector")
                        sResult += "vector " + sMemberPath + " = " + FormatAsVector(jStack, sKey, "%s") + "; ";
                    else
                        sResult += DumpStruct(jStack, sKey, sChildStructName, sMemberPath);
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

struct Value GetValueFromStackLocation(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    struct Value str;
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

struct Value GetValueFromInt(int nValue, string sFormatSpecifier)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_INT;
    str.sFormatSpecifier = sFormatSpecifier;
    str.nValue = nValue;
    return str;
}

struct Value GetValueFromFloat(float fValue, string sFormatSpecifier)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_FLOAT;
    str.sFormatSpecifier = sFormatSpecifier;
    str.fValue = fValue;
    return str;
}

struct Value GetValueFromString(string sValue, string sFormatSpecifier)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_STRING;
    str.sFormatSpecifier = sFormatSpecifier;
    str.sValue = sValue;
    return str;
}

struct Value GetValueFromObject(object oValue, string sFormatSpecifier)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_OBJECT;
    str.sFormatSpecifier = sFormatSpecifier;
    str.oValue = oValue;
    return str;
}

struct Value GetValueFromLocation(location locValue, string sFormatSpecifier)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_LOCATION;
    str.sFormatSpecifier = sFormatSpecifier;
    str.locValue = locValue;
    return str;
}

struct Value GetValueFromJson(json jValue, string sFormatSpecifier)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_JSON;
    str.sFormatSpecifier = sFormatSpecifier;
    str.jValue = jValue;
    return str;
}

struct PropertyChain ParsePropertyAndParameters(struct PropertyChain strPC, string sPropertySegment)
{
    int nParameterStart = FindSubString(sPropertySegment, "(", 0);
    if (nParameterStart == -1)
    {
        strPC.sCurrentProperty = sPropertySegment;
        strPC.sCurrentParameters = "";
    }
    else
    {
        strPC.sCurrentProperty = GetStringLeft(sPropertySegment, nParameterStart);
        int nParameterEnd = FindSubString(sPropertySegment, ")", nParameterStart);
        if (nParameterEnd != -1)
            strPC.sCurrentParameters = GetSubString(sPropertySegment, nParameterStart + 1, nParameterEnd - nParameterStart - 1);
        else
            strPC.sCurrentParameters = "";
    }
    strPC.sCurrentProperty = GetStringLowerCase(strPC.sCurrentProperty);
    return strPC;
}

json ParseParameters(string sParameters)
{
    if (sParameters == "")
        return JsonArray();

    json jParams = JsonArray();
    json jMatches = RegExpIterate("([^,]+)", sParameters);

    int nIndex, nCount = JsonGetLength(jMatches);
    for (nIndex = 0; nIndex < nCount; nIndex++)
    {
        string sParam = trim(JsonArrayGetString(JsonArrayGet(jMatches, nIndex), 1));
        JsonArrayInsertInplace(jParams, JsonString(sParam));
    }

    return jParams;
}

string GetPropertyValue(struct PropertyChain strPC)
{
    do
    {
        int nPropertyPosition = FindSubString(strPC.sRemainingPropertyPath, ">", 0);
        if (nPropertyPosition == -1)
        {
            strPC = ParsePropertyAndParameters(strPC, strPC.sRemainingPropertyPath);
            strPC.sRemainingPropertyPath = "";
            strPC = GetPropertyValueByType(strPC);
            break;
        }

        string sPropertySegment = GetStringLeft(strPC.sRemainingPropertyPath, nPropertyPosition);
        strPC.sRemainingPropertyPath = GetSubString(strPC.sRemainingPropertyPath, nPropertyPosition + 1,
            GetStringLength(strPC.sRemainingPropertyPath) - nPropertyPosition - 1);

        strPC = ParsePropertyAndParameters(strPC, sPropertySegment);
        strPC = GetPropertyValueByType(strPC);
    }
    while (strPC.sRemainingPropertyPath != "" && strPC.strValue.nAuxType != NWNX_VM_AUXTYPE_INVALID);

    if (strPC.strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        return "[INVALID_PROPERTY_CHAIN:" + strPC.sBaseVarName + ">" + strPC.sFullPropertyPath + ":FAILED@" + strPC.sCurrentProperty + "]";
    else
        return FormatValueByType(strPC.strValue);
}

struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC)
{
    switch (strPC.strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       strPC = GetIntProperty(strPC); break;
        case NWNX_VM_AUXTYPE_FLOAT:     strPC = GetFloatProperty(strPC); break;
        case NWNX_VM_AUXTYPE_STRING:    strPC = GetStringProperty(strPC); break;
        case NWNX_VM_AUXTYPE_OBJECT:    strPC = GetObjectProperty(strPC); break;
        case NWNX_VM_AUXTYPE_LOCATION:  strPC = GetLocationProperty(strPC); break;
        case NWNX_VM_AUXTYPE_JSON:      strPC = GetJsonProperty(strPC); break;
        default: strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID; break;
    }
    return strPC;
}

int EvaluateIntComparison(int nValue, string sOperator, int nCompare)
{
    if (sOperator == "eq") return nValue == nCompare;
    if (sOperator == "neq") return nValue != nCompare;
    if (sOperator == "gt") return nValue > nCompare;
    if (sOperator == "gte") return nValue >= nCompare;
    if (sOperator == "lt") return nValue < nCompare;
    if (sOperator == "lte") return nValue <= nCompare;
    return FALSE;
}

struct PropertyChain GetIntProperty(struct PropertyChain strPC)
{
    if (strPC.sCurrentProperty == "abs")
        strPC.strValue = GetValueFromInt(abs(strPC.strValue.nValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "eq" || strPC.sCurrentProperty == "neq" || strPC.sCurrentProperty == "gt" ||
            strPC.sCurrentProperty == "gte" || strPC.sCurrentProperty == "lt" || strPC.sCurrentProperty == "lte")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sValue = trim(JsonArrayGetString(jParameters, 0));
            if (IsNumeric(sValue))
            {
                int bResult = EvaluateIntComparison(strPC.strValue.nValue, strPC.sCurrentProperty, StringToInt(sValue));
                strPC.strValue = GetValueFromInt(bResult, strPC.strValue.sFormatSpecifier);
            }
            else
                strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
        }
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else if (strPC.sCurrentProperty == "then")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sValue = (strPC.strValue.nValue != 0) ? JsonArrayGetString(jParameters, 0) : JsonArrayGetString(jParameters, 1);
            if (IsNumeric(sValue))
            {
                if (FindSubString(sValue, ".", 0) != -1)
                    strPC.strValue = GetValueFromFloat(StringToFloat(sValue), strPC.strValue.sFormatSpecifier);
                else
                    strPC.strValue = GetValueFromInt(StringToInt(sValue), strPC.strValue.sFormatSpecifier);
            }
            else
                strPC.strValue = GetValueFromString(sValue, strPC.strValue.sFormatSpecifier);
        }
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else
        strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}

int EvaluateFloatComparison(float fValue, string sOperator, float fCompare)
{
    if (sOperator == "eq") return fValue == fCompare;
    if (sOperator == "neq") return fValue != fCompare;
    if (sOperator == "gt") return fValue > fCompare;
    if (sOperator == "gte") return fValue >= fCompare;
    if (sOperator == "lt") return fValue < fCompare;
    if (sOperator == "lte") return fValue <= fCompare;
    return FALSE;
}

struct PropertyChain GetFloatProperty(struct PropertyChain strPC)
{
    if (strPC.sCurrentProperty == "fabs")
        strPC.strValue = GetValueFromFloat(fabs(strPC.strValue.fValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "floor")
        strPC.strValue = GetValueFromInt(floor(strPC.strValue.fValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "ceil")
        strPC.strValue = GetValueFromInt(ceil(strPC.strValue.fValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "round")
        strPC.strValue = GetValueFromInt(round(strPC.strValue.fValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "eq" || strPC.sCurrentProperty == "neq" || strPC.sCurrentProperty == "gt" ||
            strPC.sCurrentProperty == "gte" || strPC.sCurrentProperty == "lt" || strPC.sCurrentProperty == "lte")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sValue = trim(JsonArrayGetString(jParameters, 0));
            if (IsNumeric(sValue))
            {
                int bResult = EvaluateFloatComparison(strPC.strValue.fValue, strPC.sCurrentProperty, StringToFloat(sValue));
                strPC.strValue = GetValueFromInt(bResult, strPC.strValue.sFormatSpecifier);
            }
            else
                strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
        }
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else
        strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}

struct PropertyChain GetStringProperty(struct PropertyChain strPC)
{
    if (strPC.sCurrentProperty == "length")
        strPC.strValue = GetValueFromInt(GetStringLength(strPC.strValue.sValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "upper")
        strPC.strValue = GetValueFromString(GetStringUpperCase(strPC.strValue.sValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "lower")
        strPC.strValue = GetValueFromString(GetStringLowerCase(strPC.strValue.sValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "trim")
        strPC.strValue = GetValueFromString(trim(strPC.strValue.sValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "sub" || strPC.sCurrentProperty == "substring")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        int nParameterCount = JsonGetLength(jParameters);
        if (nParameterCount >= 1)
        {
            int nStart = StringToInt(JsonArrayGetString(jParameters, 0)), nCount = -1;
            if (nParameterCount >= 2)
                nCount = StringToInt(JsonArrayGetString(jParameters, 1));
            strPC.strValue = GetValueFromString(GetSubString(strPC.strValue.sValue, nStart, nCount), strPC.strValue.sFormatSpecifier);
        }
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else if (strPC.sCurrentProperty == "left")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sResult = GetStringLeft(strPC.strValue.sValue, StringToInt(JsonArrayGetString(jParameters, 0)));
            strPC.strValue = GetValueFromString(sResult, strPC.strValue.sFormatSpecifier);
        }
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else if (strPC.sCurrentProperty == "right")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sResult = GetStringRight(strPC.strValue.sValue, StringToInt(JsonArrayGetString(jParameters, 0)));
            strPC.strValue = GetValueFromString(sResult, strPC.strValue.sFormatSpecifier);
        }
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else if (strPC.sCurrentProperty == "replace")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sSearch = JsonArrayGetString(jParameters, 0);
            string sReplace = JsonArrayGetString(jParameters, 1);
            string sResult = RegExpReplace(sSearch, strPC.strValue.sValue, sReplace);
            strPC.strValue = GetValueFromString(sResult, strPC.strValue.sFormatSpecifier);
        }
        else
        {
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
        }
    }
    else if (strPC.sCurrentProperty == "eq" || strPC.sCurrentProperty == "neq")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sCompare = JsonArrayGetString(jParameters, 0);
            int nResult = strPC.sCurrentProperty == "eq" ? strPC.strValue.sValue == sCompare : strPC.strValue.sValue != sCompare;
            strPC.strValue = GetValueFromInt(nResult, strPC.strValue.sFormatSpecifier);
        }
        else
        {
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
        }
    }
    else
        strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}

struct PropertyChain GetObjectProperty(struct PropertyChain strPC)
{
    if (strPC.sCurrentProperty == "name")
        strPC.strValue = GetValueFromString(GetName(strPC.strValue.oValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "tag")
        strPC.strValue = GetValueFromString(GetTag(strPC.strValue.oValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "resref")
        strPC.strValue = GetValueFromString(GetResRef(strPC.strValue.oValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "type")
        strPC.strValue = GetValueFromString(GetObjectTypeName(strPC.strValue.oValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "area")
        strPC.strValue = GetValueFromObject(GetArea(strPC.strValue.oValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "valid")
        strPC.strValue = GetValueFromInt(GetIsObjectValid(strPC.strValue.oValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "location")
        strPC.strValue = GetValueFromLocation(GetLocation(strPC.strValue.oValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "x" || strPC.sCurrentProperty == "y" || strPC.sCurrentProperty == "z")
    {
        vector vPosition = GetPosition(strPC.strValue.oValue);
        if (strPC.sCurrentProperty == "x")
            strPC.strValue = GetValueFromFloat(vPosition.x, strPC.strValue.sFormatSpecifier);
        else if (strPC.sCurrentProperty == "y")
            strPC.strValue = GetValueFromFloat(vPosition.y, strPC.strValue.sFormatSpecifier);
        else if (strPC.sCurrentProperty == "z")
            strPC.strValue = GetValueFromFloat(vPosition.z, strPC.strValue.sFormatSpecifier);
    }
    else if (strPC.sCurrentProperty == "position")
    {
        vector vPosition = GetPosition(strPC.strValue.oValue);
        string sX = FormatValueByType(GetValueFromFloat(vPosition.x, strPC.strValue.sFormatSpecifier));
        string sY = FormatValueByType(GetValueFromFloat(vPosition.y, strPC.strValue.sFormatSpecifier));
        string sZ = FormatValueByType(GetValueFromFloat(vPosition.z, strPC.strValue.sFormatSpecifier));
        strPC.strValue = GetValueFromString("[" + sX + "," + sY + ","  + sZ + "]", "%s");
    }
    else if (strPC.sCurrentProperty == "localvar")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sType = GetStringLowerCase(JsonArrayGetString(jParameters, 0));
            string sVarName = JsonArrayGetString(jParameters, 1);

            if (sType == "i")
                strPC.strValue = GetValueFromInt(GetLocalInt(strPC.strValue.oValue, sVarName), strPC.strValue.sFormatSpecifier);
            else if (sType == "f")
                strPC.strValue = GetValueFromFloat(GetLocalFloat(strPC.strValue.oValue, sVarName), strPC.strValue.sFormatSpecifier);
            else if (sType == "s")
                strPC.strValue = GetValueFromString(GetLocalString(strPC.strValue.oValue, sVarName), strPC.strValue.sFormatSpecifier);
            else if (sType == "o")
                strPC.strValue = GetValueFromObject(GetLocalObject(strPC.strValue.oValue, sVarName), strPC.strValue.sFormatSpecifier);
            else if (sType == "j")
                strPC.strValue = GetValueFromJson(GetLocalJson(strPC.strValue.oValue, sVarName), strPC.strValue.sFormatSpecifier);
            else
                strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
        }
        else
        {
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
        }
    }
    else
        strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}

struct PropertyChain GetLocationProperty(struct PropertyChain strPC)
{
    if (strPC.sCurrentProperty == "area")
        strPC.strValue = GetValueFromObject(GetAreaFromLocation(strPC.strValue.locValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "x" || strPC.sCurrentProperty == "y" || strPC.sCurrentProperty == "z")
    {
        vector vPosition = GetPositionFromLocation(strPC.strValue.locValue);
        if (strPC.sCurrentProperty == "x")
            strPC.strValue = GetValueFromFloat(vPosition.x, strPC.strValue.sFormatSpecifier);
        else if (strPC.sCurrentProperty == "y")
            strPC.strValue = GetValueFromFloat(vPosition.y, strPC.strValue.sFormatSpecifier);
        else if (strPC.sCurrentProperty == "z")
            strPC.strValue = GetValueFromFloat(vPosition.z, strPC.strValue.sFormatSpecifier);
    }
    else if (strPC.sCurrentProperty == "facing")
        strPC.strValue = GetValueFromFloat(GetFacingFromLocation(strPC.strValue.locValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "position")
    {
        vector vPosition = GetPositionFromLocation(strPC.strValue.locValue);
        string sX = FormatValueByType(GetValueFromFloat(vPosition.x, strPC.strValue.sFormatSpecifier));
        string sY = FormatValueByType(GetValueFromFloat(vPosition.y, strPC.strValue.sFormatSpecifier));
        string sZ = FormatValueByType(GetValueFromFloat(vPosition.z, strPC.strValue.sFormatSpecifier));
        strPC.strValue = GetValueFromString("[" + sX + "," + sY + ","  + sZ + "]", "%s");
    }
    else if (strPC.sCurrentProperty == "valid")
        strPC.strValue = GetValueFromInt(GetIsObjectValid(GetAreaFromLocation(strPC.strValue.locValue)), strPC.strValue.sFormatSpecifier);
    else
        strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}

struct Value GetJsonValueByType(json jValue, string sFormatSpecifier)
{
    struct Value strValue;
    int nType = JsonGetType(jValue);
    switch (nType)
    {
        case JSON_TYPE_NULL:
        case JSON_TYPE_OBJECT:
        case JSON_TYPE_ARRAY:
            strValue = GetValueFromJson(jValue, sFormatSpecifier);
            break;
        case JSON_TYPE_STRING:
            strValue = GetValueFromString(JsonGetString(jValue), sFormatSpecifier);
            break;
        case JSON_TYPE_INTEGER:
        case JSON_TYPE_BOOL:
            strValue = GetValueFromInt(JsonGetInt(jValue), sFormatSpecifier);
            break;
        case JSON_TYPE_FLOAT:
            strValue = GetValueFromFloat(JsonGetFloat(jValue), sFormatSpecifier);
            break;
        default: strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID; break;
    }
    return strValue;
}

struct PropertyChain GetJsonProperty(struct PropertyChain strPC)
{
    int nType = JsonGetType(strPC.strValue.jValue);
    if (strPC.sCurrentProperty == "idx" && nType == JSON_TYPE_ARRAY)
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 1)
        {
            int nIndex = StringToInt(JsonArrayGetString(jParameters, 0));
            if (nIndex >= 0 && nIndex < JsonGetLength(strPC.strValue.jValue))
                strPC.strValue = GetJsonValueByType(JsonArrayGet(strPC.strValue.jValue, nIndex), strPC.strValue.sFormatSpecifier);
            else
                strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
        }
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else if (strPC.sCurrentProperty == "key" && nType == JSON_TYPE_OBJECT)
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sKey = JsonArrayGetString(jParameters, 0);
            if (JsonObjectContainsKey(strPC.strValue.jValue, sKey))
                strPC.strValue = GetJsonValueByType(JsonObjectGet(strPC.strValue.jValue, sKey), strPC.strValue.sFormatSpecifier);
            else
                strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
        }
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else if (strPC.sCurrentProperty == "length")
    {
        strPC.strValue = GetValueFromInt(JsonGetLength(strPC.strValue.jValue), strPC.strValue.sFormatSpecifier);
    }
    else if (strPC.sCurrentProperty == "keys" && nType == JSON_TYPE_OBJECT)
        strPC.strValue = GetJsonValueByType(JsonObjectKeys(strPC.strValue.jValue), strPC.strValue.sFormatSpecifier);
    else if (strPC.sCurrentProperty == "contains" && nType == JSON_TYPE_OBJECT)
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 1)
            strPC.strValue = GetValueFromInt(JsonObjectContainsKey(strPC.strValue.jValue, JsonArrayGetString(jParameters, 0)), strPC.strValue.sFormatSpecifier);
        else
            strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    }
    else
        strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    return strPC;
}
