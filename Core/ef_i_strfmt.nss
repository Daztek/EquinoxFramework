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

const string STRFMT_SCRIPT_NAME                     = "ef_i_strfmt";
const string STRFMT_VARIABLE_CACHE_PREFIX           = "StringFormatVariableCache_";
const string STRFMT_PARAMETER_CACHE_PREFIX          = "StringFormatParameterCache_";
const string STRFMT_PROPERTY_SEGMENT_CACHE_PREFIX   = "StringFormatPropertySegementCache_";
const string STRFMT_PROPERTY_CACHE_PREFIX           = "StringFormatPropertyCache_";
const string STRFMT_INVALID_STRING                  = "[STRFMT_INVALID_STRING]";
const float STRFMT_FLOAT_EPSILON                    = 0.0001f;

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
    json jStack;
    string sBaseVarName;
    string sFullPropertyPath;
    string sCurrentProperty;
    string sCurrentParameters;
    struct Value strValue;
};

string FormatString(string sString, int nDepthOverride = 0, json jStack = JSON_NULL);
string GetCacheKey(string sPrefix, string sString);
json ExtractVariableTokens(string sString);
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
json ResolveParameters(struct PropertyChain str);
string GetPropertyValue(struct PropertyChain strPC);
struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC);
string HandleColorProperty(struct PropertyChain strPC, json jParameters);
string HandlePaddingProperty(struct PropertyChain strPC, json jParameters);
struct Value HandleSharedProperty(struct PropertyChain strPC, string sProperty, string sFormatSpecifier);
struct PropertyChain GetIntProperty(struct PropertyChain strPC);
struct PropertyChain GetFloatProperty(struct PropertyChain strPC);
struct PropertyChain GetStringProperty(struct PropertyChain strPC);
struct PropertyChain GetObjectProperty(struct PropertyChain strPC);
struct PropertyChain GetLocationProperty(struct PropertyChain strPC);
struct PropertyChain GetJsonProperty(struct PropertyChain strPC);

string FormatString(string sString, int nDepthOverride = 0, json jStack = JSON_NULL)
{
    if (sString == "" || FindSubString(sString, "{", 0) == -1)
        return sString;

    int bHasEscapes = FindSubString(sString, "{{", 0) != -1 || FindSubString(sString, "}}", 0) != -1;
    string sCacheKey = GetCacheKey(STRFMT_VARIABLE_CACHE_PREFIX, sString);
    json jVariables = GetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), sCacheKey);

    if (!JsonGetType(jVariables))
    {
        jVariables = ExtractVariableTokens(sString);
        SetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), sCacheKey, jVariables);
    }

    int nIndex, nNumVariables = JsonGetLength(jVariables);

    if (!nNumVariables)
    {
        if (bHasEscapes)
        {
            sString = RegExpReplace("\\{\\{", sString, "{");
            sString = RegExpReplace("\\}\\}", sString, "}");
        }
        return sString;
    }

    if (!JsonGetType(jStack))
        jStack = NWNX_VM_GetStackVariables(1 + nDepthOverride);

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

    if (bHasEscapes)
    {
        sResult = RegExpReplace("\\{\\{", sResult, "{");
        sResult = RegExpReplace("\\}\\}", sResult, "}");
    }

    return sResult;
}

string GetCacheKey(string sPrefix, string sString)
{
    return sPrefix + IntToString(HashString(sString)) + "_" + IntToString(GetStringLength(sString)) + "_" + GetStringLeft(sString, 32);
}

json ExtractVariableTokens(string sString)
{
    json jTokens = JsonArray();
    int nIndex = FindSubString(sString, "{"), nLength = GetStringLength(sString);
    if (nIndex == -1)
        return jTokens;

    while (nIndex < nLength)
    {
        if (GetSubString(sString, nIndex, 1) != "{")
        {
            nIndex++;
            continue;
        }

        if (nIndex + 1 < nLength && GetSubString(sString, nIndex + 1, 1) == "{")
        {
            nIndex += 2;
            continue;
        }

        int nDepth = 1, nStart = nIndex;
        nIndex++;

        while (nIndex < nLength && nDepth > 0)
        {
            string sCharacter = GetSubString(sString, nIndex, 1);
            if (sCharacter == "{")
                nDepth++;
            else if (sCharacter == "}")
                nDepth--;
            nIndex++;
        }

        if (nDepth != 0)
            break;

        string sToken = GetSubString(sString, nStart + 1, nIndex - nStart - 2);
        string sVarName = sToken, sFormatSpecifier;
        int nTokenLength = GetStringLength(sToken), nTokenDepth = 0, nTokenIndex;
        for (nTokenIndex = 0; nTokenIndex < nTokenLength; nTokenIndex++)
        {
            string sTokenCharacter = GetSubString(sToken, nTokenIndex, 1);
            if (sTokenCharacter == "{")
                nTokenDepth++;
            else if (sTokenCharacter == "}")
                nTokenDepth--;
            else if (sTokenCharacter == ":" && nTokenDepth == 0)
            {
                sVarName = GetStringLeft(sToken, nTokenIndex);
                sFormatSpecifier = GetSubString(sToken, nTokenIndex + 1, nTokenLength - nTokenIndex - 1);
                break;
            }
        }

        json jToken = JsonArray();
        JsonArrayInsertStringInplace(jToken, GetSubString(sString, nStart, nIndex - nStart));
        JsonArrayInsertStringInplace(jToken, sVarName);
        JsonArrayInsertStringInplace(jToken, sFormatSpecifier);
        JsonArrayInsertInplace(jTokens, jToken);
    }
    return jTokens;
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
        strPC.jStack = jStack;
        strPC.sBaseVarName = sBaseVarName;
        strPC.sFullPropertyPath = sPropertyPath;
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
        return FormatAsString(strValue);

    if (strValue.sFormatSpecifier == "%i")
        return FormatAsInteger(strValue);

    if (strValue.sFormatSpecifier == "%f" ||
        (GetStringLeft(strValue.sFormatSpecifier, 2) == "%." && GetStringRight(strValue.sFormatSpecifier, 1) == "f"))
    {
        return FormatAsFloat(strValue);
    }

    if (strValue.sFormatSpecifier == "%x")
        return FormatAsHex(strValue);

    if (strValue.sFormatSpecifier == "%b")
        return FormatAsBoolean(strValue);

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
        case NWNX_VM_AUXTYPE_JSON: return JsonDump(strValue.jValue);
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
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = fabs(strValue.fValue) >= STRFMT_FLOAT_EPSILON; break;
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
        if (GetStringLeft(sKey, nVarNameLength + 1) == sVarName + ".")
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
                    if (nAuxType == NWNX_VM_AUXTYPE_STRING)
                        sValue = "\"" + sValue + "\"";
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
    string sCacheKey = GetCacheKey(STRFMT_PROPERTY_CACHE_PREFIX, sPropertySegment);
    json jProperty = GetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), sCacheKey);

    if (JsonGetType(jProperty) == JSON_TYPE_ARRAY)
    {
        strPC.sCurrentProperty = JsonArrayGetString(jProperty, 0);
        strPC.sCurrentParameters = JsonArrayGetString(jProperty, 1);
        return strPC;
    }

    int nParameterStart = FindSubString(sPropertySegment, "(", 0);
    if (nParameterStart == -1)
    {
        strPC.sCurrentProperty = sPropertySegment;
        strPC.sCurrentParameters = "";
    }
    else
    {
        strPC.sCurrentProperty = GetStringLeft(sPropertySegment, nParameterStart);

        int nParameterEnd = -1;
        int nParenDepth = 1, nBraceDepth = 0;
        int nIndex, nLength = GetStringLength(sPropertySegment);
        for (nIndex = nParameterStart + 1; nIndex < nLength; nIndex++)
        {
            string sCharacter = GetSubString(sPropertySegment, nIndex, 1);
            if (sCharacter == "{")
                nBraceDepth++;
            else if (sCharacter == "}")
                nBraceDepth--;
            else if (nBraceDepth == 0 && sCharacter == "(")
                nParenDepth++;
            else if (nBraceDepth == 0 && sCharacter == ")")
            {
                nParenDepth--;
                if (nParenDepth == 0)
                {
                    nParameterEnd = nIndex;
                    break;
                }
            }
        }

        if (nParameterEnd != -1)
            strPC.sCurrentParameters = GetSubString(sPropertySegment, nParameterStart + 1, nParameterEnd - nParameterStart - 1);
        else
            strPC.sCurrentParameters = "";
    }
    strPC.sCurrentProperty = GetStringLowerCase(strPC.sCurrentProperty);

    jProperty = JsonArray();
    JsonArrayInsertStringInplace(jProperty, strPC.sCurrentProperty);
    JsonArrayInsertStringInplace(jProperty, strPC.sCurrentParameters);
    SetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), sCacheKey, jProperty);

    return strPC;
}

json ParseParameters(string sParameters)
{
    if (sParameters == "")
        return JsonArray();

    string sCacheKey = GetCacheKey(STRFMT_PARAMETER_CACHE_PREFIX, sParameters);
    json jParameters = GetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), sCacheKey);
    if (JsonGetType(jParameters) == JSON_TYPE_ARRAY)
        return jParameters;

    jParameters = JsonArray();
    string sCurrent = "", sQuoteChar = "";
    int bInQuotes = FALSE, bWasQuoted = FALSE, bLastWasComma = FALSE;
    int nBraceDepth = 0, nParenDepth = 0;
    int nIndex, nLength = GetStringLength(sParameters);

    for (nIndex = 0; nIndex < nLength; nIndex++)
    {
        string sCharacter = GetSubString(sParameters, nIndex, 1);

        if (bInQuotes && sCharacter == "\\" && nIndex + 1 < nLength)
        {
            string sNext = GetSubString(sParameters, nIndex + 1, 1);
            if (sNext == "\"" || sNext == "'" || sNext == "\\")
            {
                if (nBraceDepth > 0 || nParenDepth > 0)
                    sCurrent += sCharacter;

                sCurrent += sNext;
                nIndex++;
                bLastWasComma = FALSE;
                continue;
            }
            sCurrent += sCharacter;
            bLastWasComma = FALSE;
            continue;
        }

        if (sCharacter == "\"" || sCharacter == "'")
        {
            if (!bInQuotes)
            {
                bInQuotes = TRUE;
                sQuoteChar = sCharacter;

                if (nBraceDepth > 0 || nParenDepth > 0)
                    sCurrent += sCharacter;
            }
            else if (sCharacter == sQuoteChar)
            {
                bInQuotes = FALSE;
                if (nBraceDepth == 0 && nParenDepth == 0)
                    bWasQuoted = TRUE;
                if (nBraceDepth > 0 || nParenDepth > 0)
                    sCurrent += sCharacter;
            }
            else
                sCurrent += sCharacter;

            bLastWasComma = FALSE;
            continue;
        }

        if (bInQuotes)
        {
            sCurrent += sCharacter;
            bLastWasComma = FALSE;
            continue;
        }

        if (sCharacter == "{")
        {
            nBraceDepth++;
            sCurrent += sCharacter;
        }
        else if (sCharacter == "}")
        {
            nBraceDepth--;
            sCurrent += sCharacter;
        }
        else if (sCharacter == "(" && nBraceDepth == 0)
        {
            nParenDepth++;
            sCurrent += sCharacter;
        }
        else if (sCharacter == ")" && nBraceDepth == 0)
        {
            nParenDepth--;
            sCurrent += sCharacter;
        }
        else if (sCharacter == "," && nBraceDepth == 0 && nParenDepth == 0)
        {
            JsonArrayInsertStringInplace(jParameters, bWasQuoted ? sCurrent : trim(sCurrent));
            sCurrent = "";
            bWasQuoted = FALSE;
            bLastWasComma = TRUE;
            continue;
        }
        else
            sCurrent += sCharacter;

        bLastWasComma = FALSE;
    }

    if (bInQuotes)
        return JsonArray();

    if (!bLastWasComma)
        JsonArrayInsertStringInplace(jParameters, bWasQuoted ? sCurrent : trim(sCurrent));

    SetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), sCacheKey, jParameters);
    return jParameters;
}

json ResolveParameters(struct PropertyChain str)
{
    json jParameters = ParseParameters(str.sCurrentParameters);
    json jResolved = JsonArray();
    int nIndex, nNumParameters = JsonGetLength(jParameters);
    for (nIndex = 0; nIndex < nNumParameters; nIndex++)
    {
        JsonArrayInsertStringInplace(jResolved, FormatString(JsonArrayGetString(jParameters, nIndex), 0, str.jStack));
    }
    return jResolved;
}

string GetPropertyValue(struct PropertyChain strPC)
{
    string sCacheKey = GetCacheKey(STRFMT_PROPERTY_SEGMENT_CACHE_PREFIX, strPC.sFullPropertyPath);
    json jSegments = GetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), sCacheKey);

    if (!JsonGetType(jSegments))
    {
        jSegments = JsonArray();

        int nLength = GetStringLength(strPC.sFullPropertyPath);
        int nIndex, nSegmentStart = 0, nBraceDepth = 0, nParenDepth = 0;

        for (nIndex = 0; nIndex <= nLength; nIndex++)
        {
            string sCharacter = nIndex < nLength ? GetSubString(strPC.sFullPropertyPath, nIndex, 1) : ">";

            if (sCharacter == "{")
                nBraceDepth++;
            else if (sCharacter == "}")
                nBraceDepth--;
            else if (nBraceDepth == 0 && sCharacter == "(")
                nParenDepth++;
            else if (nBraceDepth == 0 && sCharacter == ")")
                nParenDepth--;
            else if (sCharacter == ">" && nBraceDepth == 0 && nParenDepth == 0)
            {
                JsonArrayInsertStringInplace(jSegments, GetSubString(strPC.sFullPropertyPath, nSegmentStart, nIndex - nSegmentStart));
                nSegmentStart = nIndex + 1;
            }
        }

        SetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), sCacheKey, jSegments);
    }

    int nSegment, nNumSegments = JsonGetLength(jSegments);
    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        strPC = ParsePropertyAndParameters(strPC, JsonArrayGetString(jSegments, nSegment));
        strPC = GetPropertyValueByType(strPC);

        if (strPC.strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
            break;
    }

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

string HandleColorProperty(struct PropertyChain strPC, json jParameters)
{
    int nNumParameters = JsonGetLength(jParameters);

    if (nNumParameters == 1)
    {
        struct Value strValue = strPC.strValue;
        string sColor = trim(GetStringLowerCase(JsonArrayGetString(jParameters, 0)));

        if (GetStringLeft(sColor, 1) == "#")
        {
            int nColorLen = GetStringLength(sColor);

            if (nColorLen == 4)
            {
                string sRed = GetSubString(sColor, 1, 1);
                string sGreen = GetSubString(sColor, 2, 1);
                string sBlue = GetSubString(sColor, 3, 1);
                return ColorString(FormatAsString(strValue),
                    HexStringToInt(sRed + sRed), HexStringToInt(sGreen + sGreen), HexStringToInt(sBlue + sBlue));
            }

            if (nColorLen == 7)
            {
                int nRed = HexStringToInt(GetSubString(sColor, 1, 2));
                int nGreen = HexStringToInt(GetSubString(sColor, 3, 2));
                int nBlue = HexStringToInt(GetSubString(sColor, 5, 2));
                return ColorString(FormatAsString(strValue), nRed, nGreen, nBlue);
            }

            return "[INVALID_HEX_COLOR:" + sColor + "](" + FormatAsString(strValue) + ")";
        }

        if (sColor == "black")      return ColorString(FormatAsString(strValue), 0,   0,   0);
        if (sColor == "white")      return ColorString(FormatAsString(strValue), 255, 255, 255);
        if (sColor == "red")        return ColorString(FormatAsString(strValue), 255, 0,   0);
        if (sColor == "lime")       return ColorString(FormatAsString(strValue), 0,   255, 0);
        if (sColor == "blue")       return ColorString(FormatAsString(strValue), 0,   0,   255);
        if (sColor == "yellow")     return ColorString(FormatAsString(strValue), 255, 255, 0);
        if (sColor == "cyan")       return ColorString(FormatAsString(strValue), 0,   255, 255);
        if (sColor == "magenta")    return ColorString(FormatAsString(strValue), 255, 0,   255);
        if (sColor == "silver")     return ColorString(FormatAsString(strValue), 192, 192, 192);
        if (sColor == "grey")       return ColorString(FormatAsString(strValue), 128, 128, 128);
        if (sColor == "maroon")     return ColorString(FormatAsString(strValue), 128, 0,   0);
        if (sColor == "olive")      return ColorString(FormatAsString(strValue), 128, 128, 0);
        if (sColor == "green")      return ColorString(FormatAsString(strValue), 0,   128, 0);
        if (sColor == "purple")     return ColorString(FormatAsString(strValue), 128, 0,   128);
        if (sColor == "teal")       return ColorString(FormatAsString(strValue), 0,   128, 128);
        if (sColor == "navy")       return ColorString(FormatAsString(strValue), 0,   0,   128);

        return "[UNKNOWN_COLOR:" + sColor + "](" + FormatAsString(strValue) + ")";
    }

    if (nNumParameters == 3)
    {
        return ColorString(FormatAsString(strPC.strValue),
            StringToInt(JsonArrayGetString(jParameters, 0)),
            StringToInt(JsonArrayGetString(jParameters, 1)),
            StringToInt(JsonArrayGetString(jParameters, 2)));
    }

    return STRFMT_INVALID_STRING;
}

string HandlePaddingProperty(struct PropertyChain strPC, json jParameters)
{
    int nNumParameters = JsonGetLength(jParameters);
    if (nNumParameters >= 1)
    {
        string sLength = trim(JsonArrayGetString(jParameters, 0));
        if (IsInteger(sLength))
        {
            string sPadding = " ";
            if (nNumParameters >= 2)
                sPadding = JsonArrayGetString(jParameters, 1);

            if (strPC.sCurrentProperty == "padleft")
                return LeftPadString(FormatAsString(strPC.strValue), StringToInt(sLength), sPadding);
            else
                return RightPadString(FormatAsString(strPC.strValue), StringToInt(sLength), sPadding);
        }
    }
    return STRFMT_INVALID_STRING;
}

struct Value HandleSharedProperty(struct PropertyChain strPC, string sProperty, string sFormatSpecifier)
{
    struct Value strReturnValue;
    strReturnValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    if (sProperty == "color")
    {
        string sColored = HandleColorProperty(strPC, ResolveParameters(strPC));
        if (sColored != STRFMT_INVALID_STRING)
            strReturnValue = GetValueFromString(sColored, sFormatSpecifier);
    }
    else if (sProperty == "padleft" || sProperty == "padright")
    {
        string sPadded = HandlePaddingProperty(strPC, ResolveParameters(strPC));
        if (sPadded != STRFMT_INVALID_STRING)
            strReturnValue = GetValueFromString(sPadded, sFormatSpecifier);
    }

    return strReturnValue;
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
    string sProperty = strPC.sCurrentProperty;
    string sFormatSpecifier = strPC.strValue.sFormatSpecifier;
    int nValue = strPC.strValue.nValue;

    struct Value strReturnValue;
    strReturnValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    if (sProperty == "abs")
    {
        strReturnValue = GetValueFromInt(abs(nValue), sFormatSpecifier);
    }
    else if (sProperty == "eq" || sProperty == "neq" || sProperty == "gt" || sProperty == "gte" || sProperty == "lt" || sProperty == "lte")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sValue = trim(JsonArrayGetString(jParameters, 0));
            if (IsInteger(sValue))
            {
                int bResult = EvaluateIntComparison(nValue, sProperty, StringToInt(sValue));
                strReturnValue = GetValueFromInt(bResult, sFormatSpecifier);
            }
        }
    }
    else if (sProperty == "then")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            strReturnValue = GetValueFromString(nValue != 0 ? JsonArrayGetString(jParameters, 0) : JsonArrayGetString(jParameters, 1), sFormatSpecifier);
        }
    }
    else if (sProperty == "plural")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
            strReturnValue = GetValueFromString(JsonArrayGetString(jParameters, nValue != 1), sFormatSpecifier);
    }
    else
    {
        strReturnValue = HandleSharedProperty(strPC, sProperty, sFormatSpecifier);
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

int EvaluateFloatComparison(float fValue, string sOperator, float fCompare)
{
    if (sOperator == "eq") return fabs(fValue - fCompare) < STRFMT_FLOAT_EPSILON;
    if (sOperator == "neq") return fabs(fValue - fCompare) >= STRFMT_FLOAT_EPSILON;
    if (sOperator == "gt") return fValue > fCompare;
    if (sOperator == "gte") return fValue >= fCompare;
    if (sOperator == "lt") return fValue < fCompare;
    if (sOperator == "lte") return fValue <= fCompare;
    return FALSE;
}

struct PropertyChain GetFloatProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sFormatSpecifier = strPC.strValue.sFormatSpecifier;
    float fValue = strPC.strValue.fValue;

    struct Value strReturnValue;
    strReturnValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    if (sProperty == "fabs")
    {
        strReturnValue = GetValueFromFloat(fabs(fValue), sFormatSpecifier);
    }
    else if (sProperty == "floor")
    {
        strReturnValue = GetValueFromInt(floor(fValue), sFormatSpecifier);
    }
    else if (sProperty == "ceil")
    {
        strReturnValue = GetValueFromInt(ceil(fValue), sFormatSpecifier);
    }
    else if (sProperty == "round")
    {
        strReturnValue = GetValueFromInt(round(fValue), sFormatSpecifier);
    }
    else if (sProperty == "eq" || sProperty == "neq" || sProperty == "gt" || sProperty == "gte" || sProperty == "lt" || sProperty == "lte")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sValue = trim(JsonArrayGetString(jParameters, 0));
            if (IsNumeric(sValue))
            {
                int bResult = EvaluateFloatComparison(fValue, sProperty, StringToFloat(sValue));
                strReturnValue = GetValueFromInt(bResult, sFormatSpecifier);
            }
        }
    }
    else
    {
        strReturnValue = HandleSharedProperty(strPC, sProperty, sFormatSpecifier);
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct PropertyChain GetStringProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sFormatSpecifier = strPC.strValue.sFormatSpecifier;
    string sValue = strPC.strValue.sValue;

    struct Value strReturnValue;
    strReturnValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    if (sProperty == "length")
    {
        strReturnValue = GetValueFromInt(GetStringLength(sValue), sFormatSpecifier);
    }
    else if (sProperty == "upper")
    {
        strReturnValue = GetValueFromString(GetStringUpperCase(sValue), sFormatSpecifier);
    }
    else if (sProperty == "lower")
    {
        strReturnValue = GetValueFromString(GetStringLowerCase(sValue), sFormatSpecifier);
    }
    else if (sProperty == "trim")
    {
        strReturnValue = GetValueFromString(trim(sValue), sFormatSpecifier);
    }
    else if (sProperty == "sub" || sProperty == "substring")
    {
        json jParameters = ResolveParameters(strPC);
        int nParameterCount = JsonGetLength(jParameters);
        if (nParameterCount >= 1)
        {
            int nStart = StringToInt(JsonArrayGetString(jParameters, 0)), nCount;
            if (nParameterCount >= 2)
                nCount = StringToInt(JsonArrayGetString(jParameters, 1));
            else
                nCount = GetStringLength(sValue) - nStart;
            strReturnValue = GetValueFromString(GetSubString(sValue, nStart, nCount), sFormatSpecifier);
        }
    }
    else if (sProperty == "left")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sResult = GetStringLeft(sValue, StringToInt(JsonArrayGetString(jParameters, 0)));
            strReturnValue = GetValueFromString(sResult, sFormatSpecifier);
        }
    }
    else if (sProperty == "right")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sResult = GetStringRight(sValue, StringToInt(JsonArrayGetString(jParameters, 0)));
            strReturnValue = GetValueFromString(sResult, sFormatSpecifier);
        }
    }
    else if (sProperty == "replace")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sSearch = NWNX_Util_RegExpEscape(JsonArrayGetString(jParameters, 0));
            string sReplace = JsonArrayGetString(jParameters, 1);
            string sResult = RegExpReplace(sSearch, sValue, sReplace);
            strReturnValue = GetValueFromString(sResult, sFormatSpecifier);
        }
    }
    else if (sProperty == "eq" || sProperty == "neq")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sCompare = JsonArrayGetString(jParameters, 0);
            int nResult = sProperty == "eq" ? sValue == sCompare : sValue != sCompare;
            strReturnValue = GetValueFromInt(nResult, sFormatSpecifier);
        }
    }
    else if (sProperty == "default")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            if (sValue == "")
                strReturnValue = GetValueFromString(JsonArrayGetString(jParameters, 0), sFormatSpecifier);
            else
                strReturnValue = strPC.strValue;
        }
    }
    else if (sProperty == "capitalize")
    {
        strReturnValue = GetValueFromString(CapitalizeWord(sValue), sFormatSpecifier);
    }
    else
    {
        strReturnValue = HandleSharedProperty(strPC, sProperty, sFormatSpecifier);
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct PropertyChain GetObjectProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sFormatSpecifier = strPC.strValue.sFormatSpecifier;
    object oValue = strPC.strValue.oValue;

    struct Value strReturnValue;
    strReturnValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    if (sProperty == "name")
    {
        strReturnValue = GetValueFromString(GetName(oValue), sFormatSpecifier);
    }
    else if (sProperty == "tag")
    {
        strReturnValue = GetValueFromString(GetTag(oValue), sFormatSpecifier);
    }
    else if (sProperty == "resref")
    {
        strReturnValue = GetValueFromString(GetResRef(oValue), sFormatSpecifier);
    }
    else if (sProperty == "type")
    {
        strReturnValue = GetValueFromString(GetObjectTypeName(oValue), sFormatSpecifier);
    }
    else if (sProperty == "area")
    {
        strReturnValue = GetValueFromObject(GetArea(oValue), sFormatSpecifier);
    }
    else if (sProperty == "valid")
    {
        strReturnValue = GetValueFromInt(GetIsObjectValid(oValue), sFormatSpecifier);
    }
    else if (sProperty == "location")
    {
        strReturnValue = GetValueFromLocation(GetLocation(oValue), sFormatSpecifier);
    }
    else if (sProperty == "x" || sProperty == "y" || sProperty == "z")
    {
        vector vPosition = GetPosition(oValue);
        if (sProperty == "x")
            strReturnValue = GetValueFromFloat(vPosition.x, sFormatSpecifier);
        else if (sProperty == "y")
            strReturnValue = GetValueFromFloat(vPosition.y, sFormatSpecifier);
        else if (sProperty == "z")
            strReturnValue = GetValueFromFloat(vPosition.z, sFormatSpecifier);
    }
    else if (sProperty == "position")
    {
        vector vPosition = GetPosition(oValue);
        string sX = FormatValueByType(GetValueFromFloat(vPosition.x, sFormatSpecifier));
        string sY = FormatValueByType(GetValueFromFloat(vPosition.y, sFormatSpecifier));
        string sZ = FormatValueByType(GetValueFromFloat(vPosition.z, sFormatSpecifier));
        strReturnValue = GetValueFromString("[" + sX + "," + sY + ","  + sZ + "]", sFormatSpecifier);
    }
    else if (sProperty == "localvar")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sType = GetStringLowerCase(JsonArrayGetString(jParameters, 0));
            string sVarName = JsonArrayGetString(jParameters, 1);

            if (sType == "i")
                strReturnValue = GetValueFromInt(GetLocalInt(oValue, sVarName), sFormatSpecifier);
            else if (sType == "f")
                strReturnValue = GetValueFromFloat(GetLocalFloat(oValue, sVarName), sFormatSpecifier);
            else if (sType == "s")
                strReturnValue = GetValueFromString(GetLocalString(oValue, sVarName), sFormatSpecifier);
            else if (sType == "o")
                strReturnValue = GetValueFromObject(GetLocalObject(oValue, sVarName), sFormatSpecifier);
            else if (sType == "j")
                strReturnValue = GetValueFromJson(GetLocalJson(oValue, sVarName), sFormatSpecifier);
        }
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct PropertyChain GetLocationProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sFormatSpecifier = strPC.strValue.sFormatSpecifier;
    location locValue = strPC.strValue.locValue;

    struct Value strReturnValue;
    strReturnValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    if (sProperty == "area")
    {
        strReturnValue = GetValueFromObject(GetAreaFromLocation(locValue), sFormatSpecifier);
    }
    else if (sProperty == "x" || sProperty == "y" || sProperty == "z")
    {
        vector vPosition = GetPositionFromLocation(locValue);
        if (sProperty == "x")
            strReturnValue = GetValueFromFloat(vPosition.x, sFormatSpecifier);
        else if (sProperty == "y")
            strReturnValue = GetValueFromFloat(vPosition.y, sFormatSpecifier);
        else if (sProperty == "z")
            strReturnValue = GetValueFromFloat(vPosition.z, sFormatSpecifier);
    }
    else if (sProperty == "facing")
    {
        strReturnValue = GetValueFromFloat(GetFacingFromLocation(locValue), sFormatSpecifier);
    }
    else if (sProperty == "position")
    {
        vector vPosition = GetPositionFromLocation(locValue);
        string sX = FormatValueByType(GetValueFromFloat(vPosition.x, sFormatSpecifier));
        string sY = FormatValueByType(GetValueFromFloat(vPosition.y, sFormatSpecifier));
        string sZ = FormatValueByType(GetValueFromFloat(vPosition.z, sFormatSpecifier));
        strReturnValue = GetValueFromString("[" + sX + "," + sY + ","  + sZ + "]", "%s");
    }
    else if (sProperty == "valid")
    {
        strReturnValue = GetValueFromInt(GetIsObjectValid(GetAreaFromLocation(locValue)), sFormatSpecifier);
    }

    strPC.strValue = strReturnValue;
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
    string sProperty = strPC.sCurrentProperty;
    string sFormatSpecifier = strPC.strValue.sFormatSpecifier;
    json jValue = strPC.strValue.jValue;

    struct Value strReturnValue;
    strReturnValue.nAuxType = NWNX_VM_AUXTYPE_INVALID;

    int nType = JsonGetType(jValue);
    if (sProperty == "idx" && nType == JSON_TYPE_ARRAY)
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            int nIndex = StringToInt(JsonArrayGetString(jParameters, 0));
            if (nIndex >= 0 && nIndex < JsonGetLength(jValue))
                strReturnValue = GetJsonValueByType(JsonArrayGet(jValue, nIndex), sFormatSpecifier);
        }
    }
    else if (sProperty == "key" && nType == JSON_TYPE_OBJECT)
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sKey = JsonArrayGetString(jParameters, 0);
            if (JsonObjectContainsKey(jValue, sKey))
                strReturnValue = GetJsonValueByType(JsonObjectGet(jValue, sKey), sFormatSpecifier);
        }
    }
    else if (sProperty == "length")
    {
        strReturnValue = GetValueFromInt(JsonGetLength(jValue), sFormatSpecifier);
    }
    else if (sProperty == "keys" && nType == JSON_TYPE_OBJECT)
    {
        strReturnValue = GetJsonValueByType(JsonObjectKeys(jValue), sFormatSpecifier);
    }
    else if (sProperty == "contains" && nType == JSON_TYPE_OBJECT)
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
            strReturnValue = GetValueFromInt(JsonObjectContainsKey(jValue, JsonArrayGetString(jParameters, 0)), sFormatSpecifier);
    }
    else if (sProperty == "default")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            if (JsonGetType(jValue) == JSON_TYPE_NULL)
                strReturnValue = GetValueFromString(JsonArrayGetString(jParameters, 0), sFormatSpecifier);
            else
                strReturnValue = strPC.strValue;
        }
    }

    strPC.strValue = strReturnValue;
    return strPC;
}
