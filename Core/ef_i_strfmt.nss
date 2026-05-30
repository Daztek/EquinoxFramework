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
const string STRFMT_PROPERTY_SEGMENT_CACHE_PREFIX   = "StringFormatPropertySegmentCache_";
const string STRFMT_PROPERTY_CACHE_PREFIX           = "StringFormatPropertyCache_";
const string STRFMT_PROPERTY_POSITION_CACHE_PREFIX  = "StringFormatPropertyPositionCache_";
const string STRFMT_INVALID_STRING                  = "[STRFMT_INVALID_STRING]";
const string STRFMT_META_SYMBOL                     = "@";

const int STRFMT_WHILE_SAFETY_LIMIT                 = 100;

const string STRFMT_ALIAS_SYMBOL                    = "$";
const string STRFMT_ALIAS_TYPE                      = "type";
const string STRFMT_ALIAS_VALUE                     = "value";

const string STRFMT_FUNCTION_SYMBOL                 = "&";
const string STRFMT_FUNCTION_ARGS                   = "args";
const string STRFMT_FUNCTION_BODY                   = "body";

struct Value
{
    int nAuxType;
    string sFormatSpecifier;

    int nValue;
    float fValue;
    string sValue;
    object oValue;
    json jValue;
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
string MakeCacheKey(string sPrefix, string sString);
json GetCachedJson(string sPrefix, string sInput);
void SetCachedJson(string sPrefix, string sInput, json jValue);
int IsParserQuote(string sCharacter);
int IsParserEscapedCharacter(string sString, int nIndex, int nLength);
json ExtractTokens(string sString);
int FindTopLevelDelimiter(string sString, string sDelimiter);
json SplitTopLevel(string sString, string sDelimiter, int bIncludeEmpty = TRUE);
int FindPropertyPosition(string sVarName);

string GetFormattedValue(json jStack, string sVarName, string sFormatSpecifier);
string FormatValueByType(struct Value strValue);
string FormatAsString(struct Value strValue);
string FormatAsInteger(struct Value strValue);
string FormatAsFloat(struct Value strValue);
string FormatAsHex(struct Value strValue);
string FormatAsBoolean(struct Value strValue);
string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "");

struct Value GetValueFromStackLocation(int nAuxType, int nStackLocation, string sFormatSpecifier);
struct Value GetValueFromInt(int nValue, string sFormatSpecifier);
struct Value GetValueFromFloat(float fValue, string sFormatSpecifier);
struct Value GetValueFromString(string sValue, string sFormatSpecifier);
struct Value GetValueFromObject(object oValue, string sFormatSpecifier);
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
struct PropertyChain GetJsonProperty(struct PropertyChain strPC);

string GetMetaValue(json jStack, string sVarName, string sFormatSpecifier);
struct Value HandleMetaPrimitive(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier);
struct Value HandleMetaFunction(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier);
struct Value HandleMetaControlFlow(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier);
struct Value HandleMetaVariable(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier);
struct Value HandleMetaMath(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier);

string GetAliasValue(json jStack, string sVarName, string sFormatSpecifier);
json MakeStackAliasEntry(string sValue, int nAuxType);

string GetFunctionValue(json jStack, string sVarName, string sFormatSpecifier);

string FormatString(string sString, int nDepthOverride = 0, json jStack = JSON_NULL)
{
    if (sString == "" || FindSubString(sString, "{", 0) == -1)
        return sString;

    int bHasEscapes = FindSubString(sString, "{{", 0) != -1 || FindSubString(sString, "}}", 0) != -1;
    json jVariables = GetCachedJson(STRFMT_VARIABLE_CACHE_PREFIX, sString);

    if (!JsonGetType(jVariables))
    {
        jVariables = ExtractTokens(sString);
        SetCachedJson(STRFMT_VARIABLE_CACHE_PREFIX, sString, jVariables);
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

    string sResult = "";
    int nLast = 0;
    for (nIndex = 0; nIndex < nNumVariables; nIndex++)
    {
        json jVariable = JsonArrayGet(jVariables, nIndex);
        string sVarName = JsonArrayGetString(jVariable, 0);
        string sFormatSpecifier = GetStringLowerCase(JsonArrayGetString(jVariable, 1));
        string sValue = GetFormattedValue(jStack, sVarName, sFormatSpecifier);
        int nStart = JsonArrayGetInt(jVariable, 2);
        int nEnd = JsonArrayGetInt(jVariable, 3);

        sResult += GetSubString(sString, nLast, nStart - nLast);
        sResult += sValue;
        nLast = nEnd;
    }
    sResult += GetSubString(sString, nLast, GetStringLength(sString) - nLast);

    if (bHasEscapes)
    {
        sResult = RegExpReplace("\\{\\{", sResult, "{");
        sResult = RegExpReplace("\\}\\}", sResult, "}");
    }

    return sResult;
}

string MakeCacheKey(string sPrefix, string sString)
{
    return sPrefix + IntToString(HashString(sString)) + "_" + IntToString(GetStringLength(sString)) + "_" + GetStringLeft(sString, 32);
}

json GetCachedJson(string sPrefix, string sInput)
{
    return GetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), MakeCacheKey(sPrefix, sInput));
}

void SetCachedJson(string sPrefix, string sInput, json jValue)
{
    SetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), MakeCacheKey(sPrefix, sInput), jValue);
}

int IsParserQuote(string sCharacter)
{
    return sCharacter == "\"" || sCharacter == "'";
}

int IsParserEscapedCharacter(string sString, int nIndex, int nLength)
{
    if (GetSubString(sString, nIndex, 1) != "\\" || nIndex + 1 >= nLength)
        return FALSE;

    string sNext = GetSubString(sString, nIndex + 1, 1);
    return sNext == "\"" || sNext == "'" || sNext == "\\";
}

json ExtractTokens(string sString)
{
    int nIndex = FindSubString(sString, "{");
    if (nIndex == -1)
        return JsonArray();

    json jTokens = JsonArray();
    int nLength = GetStringLength(sString);

    while (nIndex < nLength)
    {
        string sCurrent = GetSubString(sString, nIndex, 1);

        if (sCurrent != "{")
        {
            nIndex++;
            continue;
        }

        if (nIndex + 1 < nLength && GetSubString(sString, nIndex + 1, 1) == "{")
        {
            nIndex += 2;
            continue;
        }

        int nStart = nIndex;
        int nDepth = 1;
        int nColonPos = -1;
        int bInQuotes = FALSE;
        string sQuoteChar = "";
        nIndex++;

        while (nIndex < nLength && nDepth > 0)
        {
            string sCharacter = GetSubString(sString, nIndex, 1);

            if (bInQuotes)
            {
                if (IsParserEscapedCharacter(sString, nIndex, nLength))
                {
                    nIndex += 2;
                    continue;
                }
                if (sCharacter == sQuoteChar)
                    bInQuotes = FALSE;
                nIndex++;
                continue;
            }

            if (IsParserQuote(sCharacter))
            {
                bInQuotes = TRUE;
                sQuoteChar = sCharacter;
            }
            else if (sCharacter == "{")
                nDepth++;
            else if (sCharacter == "}")
                nDepth--;
            else if (sCharacter == ":" && nDepth == 1 && nColonPos == -1)
                nColonPos = nIndex;

            nIndex++;
        }

        if (nDepth != 0)
            continue;

        string sVarName, sFormatSpecifier;
        if (nColonPos != -1)
        {
            sVarName = GetSubString(sString, nStart + 1, nColonPos - nStart - 1);
            sFormatSpecifier = GetSubString(sString, nColonPos + 1, nIndex - nColonPos - 2);
        }
        else
        {
            sVarName = GetSubString(sString, nStart + 1, nIndex - nStart - 2);
            sFormatSpecifier = "";
        }

        json jToken = JsonArray();
        JsonArrayInsertStringInplace(jToken, sVarName);
        JsonArrayInsertStringInplace(jToken, sFormatSpecifier);
        JsonArrayInsertIntInplace(jToken, nStart);
        JsonArrayInsertIntInplace(jToken, nIndex);
        JsonArrayInsertInplace(jTokens, jToken);
    }

    return jTokens;
}

json SplitTopLevel(string sString, string sDelimiter, int bIncludeEmpty = TRUE)
{
    json jParts = JsonArray();
    int nLength = GetStringLength(sString);
    int nStart = 0, nBraceDepth = 0, nParenDepth = 0;
    int bInQuotes = FALSE;
    string sQuoteChar = "";

    int nIndex;
    for (nIndex = 0; nIndex <= nLength; nIndex++)
    {
        string sCharacter = nIndex < nLength ? GetSubString(sString, nIndex, 1) : sDelimiter;

        if (bInQuotes)
        {
            if (IsParserEscapedCharacter(sString, nIndex, nLength))
            {
                nIndex++;
                continue;
            }

            if (sCharacter == sQuoteChar)
                bInQuotes = FALSE;

            continue;
        }

        if (IsParserQuote(sCharacter))
        {
            bInQuotes = TRUE;
            sQuoteChar = sCharacter;
            continue;
        }

        if (sCharacter == "{")
            nBraceDepth++;
        else if (sCharacter == "}")
            nBraceDepth--;
        else if (sCharacter == "(" && nBraceDepth == 0)
            nParenDepth++;
        else if (sCharacter == ")" && nBraceDepth == 0)
            nParenDepth--;
        else if (sCharacter == sDelimiter && nBraceDepth == 0 && nParenDepth == 0)
        {
            string sPart = GetSubString(sString, nStart, nIndex - nStart);
            if (bIncludeEmpty || sPart != "")
                JsonArrayInsertStringInplace(jParts, sPart);

            nStart = nIndex + 1;
        }
    }

    return jParts;
}

int FindTopLevelDelimiter(string sString, string sDelimiter)
{
    json jParts = SplitTopLevel(sString, sDelimiter, TRUE);
    if (JsonGetLength(jParts) <= 1)
        return -1;
    return GetStringLength(JsonArrayGetString(jParts, 0));
}

int FindPropertyPosition(string sVarName)
{
    if (FindSubString(sVarName, ">") == -1)
        return -1;

    json jCached = GetCachedJson(STRFMT_PROPERTY_POSITION_CACHE_PREFIX, sVarName);
    if (JsonGetType(jCached) == JSON_TYPE_INTEGER)
        return JsonGetInt(jCached);

    int nPosition = FindTopLevelDelimiter(sVarName, ">");
    SetCachedJson(STRFMT_PROPERTY_POSITION_CACHE_PREFIX, sVarName, JsonInt(nPosition));
    return nPosition;
}

string GetFormattedValue(json jStack, string sVarName, string sFormatSpecifier)
{
    if (sFormatSpecifier == "")
        sFormatSpecifier = "%s";

    string sPrefix = GetStringLeft(sVarName, 1);
    if (sPrefix == STRFMT_META_SYMBOL)
        return GetMetaValue(jStack, sVarName, sFormatSpecifier);
    if (sPrefix == STRFMT_ALIAS_SYMBOL)
        return GetAliasValue(jStack, sVarName, sFormatSpecifier);
    if (sPrefix == STRFMT_FUNCTION_SYMBOL)
        return GetFunctionValue(jStack, sVarName, sFormatSpecifier);

    int nPropertyPosition = FindPropertyPosition(sVarName);
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
        return DumpStruct(jStack, sVarName, JsonObjectGetString(jStackVar, NWNX_VM_STRUCT_NAME_KEY));

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
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(strValue.oValue);
        case NWNX_VM_AUXTYPE_JSON:      return JsonDump(strValue.jValue);
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->%s]";
}

string FormatAsInteger(struct Value strValue)
{
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return IntToString(StringToInt(strValue.sValue));
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
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = fabs(strValue.fValue) >= FLOAT_EPSILON; break;
        case NWNX_VM_AUXTYPE_STRING:    nValue = strValue.sValue != ""; break;
        case NWNX_VM_AUXTYPE_OBJECT:    nValue = GetIsObjectValid(strValue.oValue); break;
        case NWNX_VM_AUXTYPE_JSON:      nValue = JsonGetType(strValue.jValue) != JSON_TYPE_NULL; break;
        default: return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->%b]";
    }
    return nValue ? "TRUE" : "FALSE";
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
                    sResult += DumpStruct(jStack, sKey, JsonObjectGetString(jStructVar, NWNX_VM_STRUCT_NAME_KEY), sMemberPath);
                else
                {
                    string sValue = GetFormattedValue(jStack, sKey, "%s");
                    if (nAuxType == NWNX_VM_AUXTYPE_STRING)
                        sValue = "\"" + sValue + "\"";
                    sResult += GetStringLowerCase(AuxTypeToString(nAuxType)) + " " + sMemberPath + " = " + sValue + "; ";
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
    json jProperty = GetCachedJson(STRFMT_PROPERTY_CACHE_PREFIX, sPropertySegment);
    if (JsonGetType(jProperty) == JSON_TYPE_ARRAY)
    {
        strPC.sCurrentProperty = JsonArrayGetString(jProperty, 0);
        strPC.sCurrentParameters = JsonArrayGetString(jProperty, 1);
        return strPC;
    }

    int nParameterStart = -1;
    int bInQuotes = FALSE;
    string sQuoteChar = "";

    int nIndex, nLength = GetStringLength(sPropertySegment);
    for (nIndex = 0; nIndex < nLength; nIndex++)
    {
        string sCharacter = GetSubString(sPropertySegment, nIndex, 1);

        if (bInQuotes)
        {
            if (IsParserEscapedCharacter(sPropertySegment, nIndex, nLength))
            {
                nIndex++;
                continue;
            }

            if (sCharacter == sQuoteChar)
                bInQuotes = FALSE;

            continue;
        }

        if (IsParserQuote(sCharacter))
        {
            bInQuotes = TRUE;
            sQuoteChar = sCharacter;
            continue;
        }

        if (sCharacter == "(")
        {
            nParameterStart = nIndex;
            break;
        }
    }

    if (nParameterStart == -1)
    {
        strPC.sCurrentProperty = sPropertySegment;
        strPC.sCurrentParameters = "";
    }
    else
    {
        strPC.sCurrentProperty = GetStringLeft(sPropertySegment, nParameterStart);

        int nParameterEnd = -1, nParenDepth = 1, nBraceDepth = 0;
        bInQuotes = FALSE;
        sQuoteChar = "";

        for (nIndex = nParameterStart + 1; nIndex < nLength; nIndex++)
        {
            string sCharacter = GetSubString(sPropertySegment, nIndex, 1);

            if (bInQuotes)
            {
                if (IsParserEscapedCharacter(sPropertySegment, nIndex, nLength))
                {
                    nIndex++;
                    continue;
                }

                if (sCharacter == sQuoteChar)
                    bInQuotes = FALSE;

                continue;
            }

            if (IsParserQuote(sCharacter))
            {
                bInQuotes = TRUE;
                sQuoteChar = sCharacter;
                continue;
            }

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

    SetCachedJson(STRFMT_PROPERTY_CACHE_PREFIX, sPropertySegment, jProperty);

    return strPC;
}

json ParseParameters(string sParameters)
{
    if (sParameters == "")
        return JsonArray();

    json jParameters = GetCachedJson(STRFMT_PARAMETER_CACHE_PREFIX, sParameters);
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

    SetCachedJson(STRFMT_PARAMETER_CACHE_PREFIX, sParameters, jParameters);

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
    json jSegments = GetCachedJson(STRFMT_PROPERTY_SEGMENT_CACHE_PREFIX, strPC.sFullPropertyPath);
    if (JsonGetType(jSegments) != JSON_TYPE_ARRAY)
    {
        jSegments = SplitTopLevel(strPC.sFullPropertyPath, ">", TRUE);
        SetCachedJson(STRFMT_PROPERTY_SEGMENT_CACHE_PREFIX, strPC.sFullPropertyPath, jSegments);
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
    else if (sProperty == "int")
    {
        struct Value strValue = strPC.strValue;
        if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
            strReturnValue = strValue;
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
            strReturnValue = GetValueFromInt(FloatToInt(strValue.fValue), sFormatSpecifier);
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_STRING)
            strReturnValue = GetValueFromInt(StringToInt(strValue.sValue), sFormatSpecifier);
    }
    else if (sProperty == "float")
    {
        struct Value strValue = strPC.strValue;
        if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
            strReturnValue = GetValueFromFloat(IntToFloat(strValue.nValue), sFormatSpecifier);
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
            strReturnValue = strValue;
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_STRING)
            strReturnValue = GetValueFromFloat(StringToFloat(strValue.sValue), sFormatSpecifier);
    }
    else if (sProperty == "string")
    {
        struct Value strValue = strPC.strValue;
        if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
            strReturnValue = GetValueFromString(IntToString(strValue.nValue), sFormatSpecifier);
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
            strReturnValue = GetValueFromString(FloatToString(strValue.fValue), sFormatSpecifier);
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_STRING)
            strReturnValue = strValue;
    }

    return strReturnValue;
}

struct PropertyChain GetIntProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sFormatSpecifier = strPC.strValue.sFormatSpecifier;
    int nValue = strPC.strValue.nValue;

    struct Value strReturnValue;

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
                int nCompare = StringToInt(sValue);
                if (sProperty == "eq")
                    strReturnValue = GetValueFromInt(nValue == nCompare, sFormatSpecifier);
                else if (sProperty == "neq")
                    strReturnValue = GetValueFromInt(nValue != nCompare, sFormatSpecifier);
                else if (sProperty == "gt")
                    strReturnValue = GetValueFromInt(nValue > nCompare, sFormatSpecifier);
                else if (sProperty == "gte")
                    strReturnValue = GetValueFromInt(nValue >= nCompare, sFormatSpecifier);
                else if (sProperty == "lt")
                    strReturnValue = GetValueFromInt(nValue < nCompare, sFormatSpecifier);
                else if (sProperty == "lte")
                    strReturnValue = GetValueFromInt(nValue <= nCompare, sFormatSpecifier);
            }
        }
    }
    else if (sProperty == "then")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sResult = FormatString(nValue != 0 ? JsonArrayGetString(jParameters, 0) : JsonArrayGetString(jParameters, 1), 0, strPC.jStack);
            strReturnValue = GetValueFromString(sResult, sFormatSpecifier);
        }
    }
    else if (sProperty == "plural")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
            strReturnValue = GetValueFromString(JsonArrayGetString(jParameters, nValue != 1), sFormatSpecifier);
    }
    else if (sProperty == "increment" || sProperty == "incr")
    {
        strReturnValue = GetValueFromInt(nValue + 1, sFormatSpecifier);
    }
    else if (sProperty == "decrement" || sProperty == "decr")
    {
        strReturnValue = GetValueFromInt(nValue - 1, sFormatSpecifier);
    }
    else if (sProperty == "even" || sProperty == "odd")
    {
        if (sProperty == "even")
            strReturnValue = GetValueFromInt(nValue % 2 == 0, sFormatSpecifier);
        else
            strReturnValue = GetValueFromInt(nValue % 2 != 0, sFormatSpecifier);
    }
    else
    {
        strReturnValue = HandleSharedProperty(strPC, sProperty, sFormatSpecifier);
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct PropertyChain GetFloatProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sFormatSpecifier = strPC.strValue.sFormatSpecifier;
    float fValue = strPC.strValue.fValue;

    struct Value strReturnValue;

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
                float fCompare = StringToFloat(sValue);
                float fDiff = fValue - fCompare;
                if (sProperty == "eq")
                    strReturnValue = GetValueFromInt(fabs(fDiff) < FLOAT_EPSILON, sFormatSpecifier);
                else if (sProperty == "neq")
                    strReturnValue = GetValueFromInt(fabs(fDiff) >= FLOAT_EPSILON, sFormatSpecifier);
                else if (sProperty == "gt")
                    strReturnValue = GetValueFromInt(fDiff > FLOAT_EPSILON, sFormatSpecifier);
                else if (sProperty == "gte")
                    strReturnValue = GetValueFromInt(fDiff >= -FLOAT_EPSILON, sFormatSpecifier);
                else if (sProperty == "lt")
                    strReturnValue = GetValueFromInt(fDiff < -FLOAT_EPSILON, sFormatSpecifier);
                else if (sProperty == "lte")
                    strReturnValue = GetValueFromInt(fDiff <= FLOAT_EPSILON, sFormatSpecifier);
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
    else if (sProperty == "substr" || sProperty == "substring")
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
            strReturnValue = GetValueFromString(GetStringLeft(sValue, StringToInt(JsonArrayGetString(jParameters, 0))), sFormatSpecifier);
    }
    else if (sProperty == "right")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
            strReturnValue = GetValueFromString(GetStringRight(sValue, StringToInt(JsonArrayGetString(jParameters, 0))), sFormatSpecifier);
    }
    else if (sProperty == "replace")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sSearch = NWNX_Util_RegExpEscape(JsonArrayGetString(jParameters, 0));
            string sReplace = JsonArrayGetString(jParameters, 1);
            strReturnValue = GetValueFromString(RegExpReplace(sSearch, sValue, sReplace), sFormatSpecifier);
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
    else if (sProperty == "append" || sProperty == "prepend")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            if (sProperty == "append")
                strReturnValue = GetValueFromString(sValue + JsonArrayGetString(jParameters, 0), sFormatSpecifier);
            else
                strReturnValue = GetValueFromString(JsonArrayGetString(jParameters, 0) + sValue, sFormatSpecifier);
        }
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
    else if (sProperty == "facing")
    {
        strReturnValue = GetValueFromFloat(GetFacing(oValue), sFormatSpecifier);
    }
    else if (sProperty == "localvar")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sType = GetStringLowerCase(trim(JsonArrayGetString(jParameters, 0)));
            string sVarName = trim(JsonArrayGetString(jParameters, 1));

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

string GetMetaValue(json jStack, string sVarName, string sFormatSpecifier)
{
    int nVarNameLength = GetStringLength(sVarName);
    int nPropertyPosition = FindPropertyPosition(sVarName);
    string sMetaToken = nPropertyPosition == -1 ?
        GetSubString(sVarName, 1, nVarNameLength - 1) : GetSubString(sVarName, 1, nPropertyPosition - 1);

    struct PropertyChain strMeta;
    strMeta.jStack = jStack;
    strMeta = ParsePropertyAndParameters(strMeta, sMetaToken);

    string sMetaName = strMeta.sCurrentProperty;
    struct Value strReturnValue;

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaPrimitive(strMeta, sMetaName, sFormatSpecifier);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaFunction(strMeta, sMetaName, sFormatSpecifier);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaControlFlow(strMeta, sMetaName, sFormatSpecifier);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaVariable(strMeta, sMetaName, sFormatSpecifier);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaMath(strMeta, sMetaName, sFormatSpecifier);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        return "[UNKNOWN_META:" + sMetaName + "]";

    if (nPropertyPosition == -1)
        return FormatValueByType(strReturnValue);

    struct PropertyChain strPC;
    strPC.jStack = jStack;
    strPC.sBaseVarName = sVarName;
    strPC.sFullPropertyPath = GetSubString(sVarName, nPropertyPosition + 1, nVarNameLength - nPropertyPosition - 1);
    strPC.strValue = strReturnValue;

    return GetPropertyValue(strPC);
}

struct Value HandleMetaPrimitive(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier)
{
    struct Value strReturnValue;
    if (sMetaName == "int")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sValue = trim(JsonArrayGetString(jParameters, 0));
            if (IsInteger(sValue))
                strReturnValue = GetValueFromInt(StringToInt(sValue), sFormatSpecifier);
        }
    }
    else if (sMetaName == "float")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sValue = trim(JsonArrayGetString(jParameters, 0));
            if (IsNumeric(sValue))
                strReturnValue = GetValueFromFloat(StringToFloat(sValue), sFormatSpecifier);
        }
    }
    else if (sMetaName == "string")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
            strReturnValue = GetValueFromString(JsonArrayGetString(jParameters, 0), sFormatSpecifier);
    }
    return strReturnValue;
}

struct Value HandleMetaFunction(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier)
{
    struct Value strReturnValue;
    if (sMetaName == "fn")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);

        if (JsonGetLength(jParameters) >= 2)
        {
            string sFunctionName = GetStringLowerCase(trim(JsonArrayGetString(jParameters, 0)));
            if (GetStringLeft(sFunctionName, 1) == "&")
            {
                json jArgs = JsonArray();
                int nIndex, nLast = JsonGetLength(jParameters) - 1;
                for (nIndex = 1; nIndex < nLast; nIndex++)
                {
                    JsonArrayInsertStringInplace(jArgs, trim(JsonArrayGetString(jParameters, nIndex)));
                }

                json jFunction = JsonObject();
                JsonObjectSetInplace(jFunction, STRFMT_FUNCTION_ARGS, jArgs);
                JsonObjectSetStringInplace(jFunction, STRFMT_FUNCTION_BODY, JsonArrayGetString(jParameters, nLast));
                JsonObjectSetInplace(strPC.jStack, sFunctionName, jFunction);
                strReturnValue = GetValueFromString("", sFormatSpecifier);
            }
        }
    }
    return strReturnValue;
}

struct Value HandleMetaControlFlow(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier)
{
    struct Value strReturnValue;
    if (sMetaName == "if")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 3)
        {
            string sCondition = FormatString(JsonArrayGetString(jParameters, 0), 0, strPC.jStack);
            int nCondition = StringToInt(sCondition);
            string sResult = FormatString(nCondition ? JsonArrayGetString(jParameters, 1) : JsonArrayGetString(jParameters, 2), 0, strPC.jStack);
            strReturnValue = GetValueFromString(sResult, sFormatSpecifier);
        }
    }
    else if (sMetaName == "while")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sCondition = JsonArrayGetString(jParameters, 0);
            string sBody = JsonArrayGetString(jParameters, 1);
            string sAccumulator  = "";
            int nLimit = STRFMT_WHILE_SAFETY_LIMIT;

            while (nLimit-- > 0)
            {
                string sConditionResult = FormatString(sCondition, 0, strPC.jStack);
                if (sConditionResult == "0" || sConditionResult == "")
                    break;
                sAccumulator += FormatString(sBody, 0, strPC.jStack);
            }
            strReturnValue = GetValueFromString(sAccumulator, sFormatSpecifier);
        }
    }
    else if (sMetaName == "pick")
    {
        json jParameters = ResolveParameters(strPC);
        int nNumParameters = JsonGetLength(jParameters);
        if (nNumParameters >= 1)
            strReturnValue = GetValueFromString(JsonArrayGetString(jParameters, Random(nNumParameters)), sFormatSpecifier);
    }
    return strReturnValue;
}

struct Value HandleMetaVariable(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier)
{
    struct Value strReturnValue;
    if (sMetaName == "let")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sAlias = trim(JsonArrayGetString(jParameters, 0));
            if (GetStringLeft(sAlias, 1) == STRFMT_ALIAS_SYMBOL)
            {
                string sValue = FormatString(JsonArrayGetString(jParameters, 1), 0, strPC.jStack);
                int nAuxType = NWNX_VM_AUXTYPE_STRING;
                if (IsInteger(sValue))
                    nAuxType = NWNX_VM_AUXTYPE_INT;
                else if (IsFloat(sValue))
                    nAuxType = NWNX_VM_AUXTYPE_FLOAT;
                JsonObjectSetInplace(strPC.jStack, sAlias, MakeStackAliasEntry(sValue, nAuxType));
                strReturnValue = GetValueFromString("", sFormatSpecifier);
            }
        }
    }
    else if (sMetaName == "out")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sVarName = trim(JsonArrayGetString(jParameters, 0));
            if (JsonObjectContainsKey(strPC.jStack, sVarName))
            {
                string sValue = JsonArrayGetString(jParameters, 1);
                json jStackVar = JsonObjectGet(strPC.jStack, sVarName);
                int nOutAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);

                if (nOutAuxType == NWNX_VM_AUXTYPE_INT && IsInteger(sValue))
                    NWNX_VM_SetStackIntegerValue(JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), StringToInt(sValue));
                else if (nOutAuxType == NWNX_VM_AUXTYPE_FLOAT && IsNumeric(sValue))
                    NWNX_VM_SetStackFloatValue(JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), StringToFloat(sValue));
                else if (nOutAuxType == NWNX_VM_AUXTYPE_STRING)
                    NWNX_VM_SetStackStringValue(JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), sValue);

                strReturnValue = GetValueFromString("", sFormatSpecifier);
            }
        }
    }
    else if (sMetaName == "cast")
    {
        json jParameters = ParseParameters(strPC.sCurrentParameters);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sAlias = trim(JsonArrayGetString(jParameters, 0));
            if (GetStringLeft(sAlias, 1) == STRFMT_ALIAS_SYMBOL)
            {
                if (JsonObjectContainsKey(strPC.jStack, sAlias))
                {
                    json jStackVar = JsonObjectGet(strPC.jStack, sAlias);
                    string sCast = trim(JsonArrayGetString(jParameters, 1));
                    if (sCast == "int")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, STRFMT_ALIAS_TYPE, NWNX_VM_AUXTYPE_INT));
                    else if (sCast == "float")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, STRFMT_ALIAS_TYPE, NWNX_VM_AUXTYPE_FLOAT));
                    else if (sCast == "string")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, STRFMT_ALIAS_TYPE, NWNX_VM_AUXTYPE_STRING));
                    else if (sCast == "object")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, STRFMT_ALIAS_TYPE, NWNX_VM_AUXTYPE_OBJECT));

                    strReturnValue = GetValueFromString("", sFormatSpecifier);
                }
            }
        }
    }
    return strReturnValue;
}

struct Value HandleMetaMath(struct PropertyChain strPC, string sMetaName, string sFormatSpecifier)
{
    struct Value strReturnValue;
    if (sMetaName == "add")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sValue1 = trim(JsonArrayGetString(jParameters, 0));
            string sValue2 = trim(JsonArrayGetString(jParameters, 1));
            if (IsInteger(sValue1) && IsInteger(sValue2))
                strReturnValue = GetValueFromInt(StringToInt(sValue1) + StringToInt(sValue2), sFormatSpecifier);
            else if (IsNumeric(sValue1) && IsNumeric(sValue2))
                strReturnValue = GetValueFromFloat(StringToFloat(sValue1) + StringToFloat(sValue2), sFormatSpecifier);
        }
    }
    else if (sMetaName == "sub")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sValue1 = trim(JsonArrayGetString(jParameters, 0));
            string sValue2 = trim(JsonArrayGetString(jParameters, 1));
            if (IsInteger(sValue1) && IsInteger(sValue2))
                strReturnValue = GetValueFromInt(StringToInt(sValue1) - StringToInt(sValue2), sFormatSpecifier);
            else if (IsNumeric(sValue1) && IsNumeric(sValue2))
                strReturnValue = GetValueFromFloat(StringToFloat(sValue1) - StringToFloat(sValue2), sFormatSpecifier);
        }
    }
    else if (sMetaName == "mul")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sValue1 = trim(JsonArrayGetString(jParameters, 0));
            string sValue2 = trim(JsonArrayGetString(jParameters, 1));
            if (IsInteger(sValue1) && IsInteger(sValue2))
                strReturnValue = GetValueFromInt(StringToInt(sValue1) * StringToInt(sValue2), sFormatSpecifier);
            else if (IsNumeric(sValue1) && IsNumeric(sValue2))
                strReturnValue = GetValueFromFloat(StringToFloat(sValue1) * StringToFloat(sValue2), sFormatSpecifier);
        }
    }
    else if (sMetaName == "div" || sMetaName == "idiv")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sValue1 = trim(JsonArrayGetString(jParameters, 0));
            string sValue2 = trim(JsonArrayGetString(jParameters, 1));
            if (sMetaName == "idiv")
            {
                if (IsInteger(sValue1) && IsInteger(sValue2))
                {
                    int nDiv = StringToInt(sValue2);
                    if (nDiv != 0)
                        strReturnValue = GetValueFromInt(StringToInt(sValue1) / nDiv, sFormatSpecifier);
                }
            }
            else if (IsNumeric(sValue1) && IsNumeric(sValue2))
            {
                float fDiv = StringToFloat(sValue2);
                if (fabs(fDiv) > FLOAT_EPSILON)
                    strReturnValue = GetValueFromFloat(StringToFloat(sValue1) / fDiv, sFormatSpecifier);
            }
        }
    }
    else if (sMetaName == "random")
    {
        json jParameters = ResolveParameters(strPC);
        int nNumParameters = JsonGetLength(jParameters);
        if (nNumParameters >= 1)
        {
            string sParameter0 = trim(JsonArrayGetString(jParameters, 0));
            if (IsInteger(sParameter0))
            {
                int nMax = StringToInt(sParameter0);
                int nMin = 0;

                if (nNumParameters >= 2)
                {
                    string sParameter1 = trim(JsonArrayGetString(jParameters, 1));
                    if (IsInteger(sParameter1))
                    {
                        nMin = nMax;
                        nMax = StringToInt(sParameter1);
                    }
                }

                if (nMax > nMin)
                    strReturnValue = GetValueFromInt(nMin + Random(nMax - nMin), sFormatSpecifier);
                else if (nMax == nMin)
                    strReturnValue = GetValueFromInt(nMin, sFormatSpecifier);
            }
        }
    }
    return strReturnValue;
}

string GetAliasValue(json jStack, string sVarName, string sFormatSpecifier)
{
    int nPropertyPosition = FindPropertyPosition(sVarName);
    string sBaseAliasName = nPropertyPosition == -1 ? sVarName : GetStringLeft(sVarName, nPropertyPosition);

    if (!JsonObjectContainsKey(jStack, sBaseAliasName))
        return "[MISSING_ALIAS:" + sBaseAliasName + "]";

    json jEntry = JsonObjectGet(jStack, sBaseAliasName);
    int nAuxType = JsonObjectGetInt(jEntry, STRFMT_ALIAS_TYPE);
    string sValue = JsonObjectGetString(jEntry, STRFMT_ALIAS_VALUE);
    struct Value strAliasValue;

    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT: strAliasValue = GetValueFromInt(StringToInt(sValue), sFormatSpecifier); break;
        case NWNX_VM_AUXTYPE_FLOAT: strAliasValue = GetValueFromFloat(StringToFloat(sValue), sFormatSpecifier); break;
        case NWNX_VM_AUXTYPE_OBJECT: strAliasValue = GetValueFromObject(StringToObject(sValue), sFormatSpecifier); break;
        default: strAliasValue = GetValueFromString(sValue, sFormatSpecifier);
    }

    if (nPropertyPosition == -1)
        return FormatValueByType(strAliasValue);

    struct PropertyChain strPC;
    strPC.jStack = jStack;
    strPC.sBaseVarName = sBaseAliasName;
    strPC.sFullPropertyPath = GetSubString(sVarName, nPropertyPosition + 1, GetStringLength(sVarName) - nPropertyPosition - 1);
    strPC.strValue = strAliasValue;
    return GetPropertyValue(strPC);
}

json MakeStackAliasEntry(string sValue, int nAuxType)
{
    json jEntry = JsonObject();
    JsonObjectSetStringInplace(jEntry, STRFMT_ALIAS_VALUE, sValue);
    JsonObjectSetIntInplace(jEntry, STRFMT_ALIAS_TYPE, nAuxType);
    return jEntry;
}

string GetFunctionValue(json jStack, string sVarName, string sFormatSpecifier)
{
    int nPropertyPosition = FindPropertyPosition(sVarName);
    string sBaseFunctionName = nPropertyPosition == -1 ? sVarName : GetStringLeft(sVarName, nPropertyPosition);

    struct PropertyChain strFunction;
    strFunction.jStack = jStack;
    strFunction = ParsePropertyAndParameters(strFunction, sBaseFunctionName);

    string sFunctionName = strFunction.sCurrentProperty;
    json jFunction = JsonObjectGet(jStack, sFunctionName);

    if (JsonGetType(jFunction) != JSON_TYPE_OBJECT)
        return "[UNKNOWN_FUNCTION:" + sFunctionName + "]";

    json jArgNames = JsonObjectGet(jFunction, STRFMT_FUNCTION_ARGS);
    string sBody = JsonObjectGetString(jFunction, STRFMT_FUNCTION_BODY);
    json jValues = ResolveParameters(strFunction);

    if (JsonGetLength(jValues) != JsonGetLength(jArgNames))
        return "[FUNCTION_ARITY:" + sFunctionName + "]";

    json jFrame = JsonCopyObject(jStack);
    int nIndex, nNumArgs = JsonGetLength(jArgNames);

    for (nIndex = 0; nIndex < nNumArgs; nIndex++)
    {
        string sArgName = JsonArrayGetString(jArgNames, nIndex);
        string sArgValue = JsonArrayGetString(jValues, nIndex);
        JsonObjectSetInplace(jFrame, sArgName, MakeStackAliasEntry(sArgValue, NWNX_VM_AUXTYPE_STRING));
    }

    string sResult = FormatString(sBody, 0, jFrame);
    if (nPropertyPosition == -1)
        return sResult;

    struct PropertyChain strPC;
    strPC.jStack = jStack;
    strPC.sBaseVarName = sBaseFunctionName;
    strPC.sFullPropertyPath = GetSubString(sVarName, nPropertyPosition + 1, GetStringLength(sVarName) - nPropertyPosition - 1);
    strPC.strValue = GetValueFromString(sResult, sFormatSpecifier);

    return GetPropertyValue(strPC);
}
