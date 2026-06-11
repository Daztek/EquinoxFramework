/*
    Script: ef_c_dazscript
    Author: Daz
*/

#include "ef_i_convert"
#include "ef_i_math"
#include "ef_i_string"
#include "ef_i_dataobject"
#include "ef_i_util"
#include "nwnx_util"
#include "nwnx_vm"

const string DAZSCRIPT_SCRIPT_NAME                          = "ef_c_dazscript";

const string DAZSCRIPT_TEMPLATE_CACHE_PREFIX                = "DazScriptTemplateCache_";
const string DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX          = "DazScriptPropertyChainCache_";
const string DAZSCRIPT_COMPILED_PARAMETER_CACHE_PREFIX      = "DazScriptCompiledParameterCache_";
const string DAZSCRIPT_PARAMETER_ENTRY_CACHE_PREFIX         = "DazScriptParameterEntryCache_";

const string DAZSCRIPT_PROPERTY_CHAIN_SYMBOL_CANONICAL      = ">";
const string DAZSCRIPT_PROPERTY_CHAIN_SYMBOL_ALT            = "->";

const string DAZSCRIPT_META_SYMBOL                          = "@";
const string DAZSCRIPT_ALIAS_SYMBOL                         = "$";
const string DAZSCRIPT_FUNCTION_SYMBOL                      = "#";

const string DAZSCRIPT_ALIAS_TYPE                           = "type";
const string DAZSCRIPT_ALIAS_VALUE                          = "value";

const string DAZSCRIPT_FUNCTION_ARGS                        = "args";
const string DAZSCRIPT_FUNCTION_BODY                        = "body";
const string DAZSCRIPT_FUNCTION_BODY_COMPILED               = "body_compiled";

const string DAZSCRIPT_PARAMETER_TEXT                       = "text";
const string DAZSCRIPT_PARAMETER_WAS_QUOTED                 = "was_quoted";

const int DAZSCRIPT_NODE_LITERAL                            = 0;
const int DAZSCRIPT_NODE_EXPR                               = 1;
const int DAZSCRIPT_NODE_FORCE_STRING                       = 2;

const int DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY               = 0;
const int DAZSCRIPT_PROPERTY_SEGMENT_PARAMETERS             = 1;
const int DAZSCRIPT_PROPERTY_SEGMENT_COMPILED_PARAMETERS    = 2;
const int DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_ENTRIES      = 3;

const int DAZSCRIPT_EXPR_VAR                                = 0;
const int DAZSCRIPT_EXPR_ALIAS                              = 1;
const int DAZSCRIPT_EXPR_META                               = 2;
const int DAZSCRIPT_EXPR_FUNCTION                           = 3;

const int DAZSCRIPT_EXPR_KIND                               = 1;
const int DAZSCRIPT_EXPR_BASE_NAME                          = 2;
const int DAZSCRIPT_EXPR_CHAIN                              = 3;
const int DAZSCRIPT_EXPR_BASE_PARAMETERS                    = 4;
const int DAZSCRIPT_EXPR_PROPERTY_PATH                      = 5;
const int DAZSCRIPT_EXPR_BASE_COMPILED_PARAMETERS           = 6;

const int DAZSCRIPT_ARG_ANY                                 = 0;
const int DAZSCRIPT_ARG_INT                                 = 1;
const int DAZSCRIPT_ARG_NUMERIC                             = 2;
const int DAZSCRIPT_ARG_OBJECT                              = 3;
const int DAZSCRIPT_ARG_STRING                              = 4;
const int DAZSCRIPT_ARG_JSON                                = 5;

struct Value
{
    int nAuxType;

    int nValue;
    float fValue;
    string sValue;
    object oValue;
    json jValue;

    int bError;
    string sErrorMessage;
};

struct PropertyChain
{
    json jStack;
    string sBaseVarName;
    string sFullPropertyPath;
    string sCurrentProperty;
    string sCurrentParameters;
    json jCurrentParameters;
    json jCurrentParameterEntries;
    struct Value strValue;
};

struct Arguments
{
    int nCount;
    struct Value strArg0;
    struct Value strArg1;
    struct Value strArg2;
    struct Value strArg3;
    struct Value strArg4;
    struct Value strError;
};

string FormatString(string sString, int nDepthOverride = 0);
string Interpret(string sString, int nDepthOverride = 0, json jStack = JSON_NULL);

string MakeCacheKey(string sPrefix, string sString);
json GetCachedJson(string sPrefix, string sInput);
void SetCachedJson(string sPrefix, string sInput, json jValue);

string GetAliasStoredValueAsString(json jEntry);
json MakeStackAliasEntryFromValue(struct Value strValue);
json MakeParameterEntry(string sText, int bWasQuoted);

int GetCastAuxTypeFromName(string sCast);
string GetValueAsCastString(struct Value strValue);
struct Value CastValueToJson(struct Value strValue);
struct Value CastValueToAuxType(struct Value strValue, int nTargetAuxType);

int IsParserQuote(string sCharacter);
int IsParserEscapedCharacter(string sString, int nIndex, int nLength);
string NormalizePropertyChainOperators(string sString);
json SplitTopLevel(string sString, string sDelimiter, int bIncludeEmpty = TRUE);
int FindTopLevelDelimiter(string sString, string sDelimiter);

json CompileTemplate(string sString);
json CompileForcedStringTemplate(string sValue);
struct Value EvalTemplate(json jTemplate, json jStack);
void JsonArrayInsertLiteralNodeInplace(json jTemplate, string sLiteral);
void JsonArrayInsertExprNodeInplace(json jTemplate, string sExpr);
void JsonArrayInsertForceStringNodeInplace(json jTemplate, json jInnerTemplate);

json CompileExpression(string sExpr);
string EvalCompiledExpression(json jExpr, json jStack);
struct Value EvalCompiledExpressionToValue(json jExpr, json jStack);

struct Value GetStackValue(json jStack, string sVarName);
struct Value ResolveAliasValue(json jStack, string sAliasName);
struct Value ResolveMetaValue(json jStack, string sMetaName, string sBaseParameters, json jBaseCompiledParameters);
struct Value ResolveFunctionValue(json jStack, string sFunctionName, string sBaseParameters, json jBaseCompiledParameters);

json CompilePropertyChain(string sPropertyPath);
json CompilePropertySegment(string sPropertySegment);
struct PropertyChain ApplyCompiledPropertySegment(struct PropertyChain strPC, json jSegment);
struct PropertyChain EvalCompiledPropertyChain(struct PropertyChain strPC, json jSegments);
struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC);

json CompileParameters(string sParameters);
json ParseParameterEntries(string sParameters);
json GetCompiledParameters(struct PropertyChain strPC);
json GetParameterEntries(struct PropertyChain strPC);
string GetRawParameterText(struct PropertyChain strPC, int nIndex, string sDefault = "");
int GetRawParameterWasQuoted(struct PropertyChain strPC, int nIndex);
int GetParameterCount(struct PropertyChain strPC);
struct Value EvalCompiledParameter(struct PropertyChain strPC, int nIndex);

string GetArgTypeName(int nArgType);
int IsValueArgType(struct Value strValue, int nArgType);
struct Value CheckArity(struct PropertyChain strPC, int nMin, int nMax);
struct Value EvalTypedParameter(struct PropertyChain strPC, int nIndex, int nArgType);
struct Arguments EvalArgs(struct PropertyChain strPC, int nMin, int nMax, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY, int nType2 = DAZSCRIPT_ARG_ANY, int nType3 = DAZSCRIPT_ARG_ANY, int nType4 = DAZSCRIPT_ARG_ANY);
struct Arguments EvalOneArg(struct PropertyChain strPC, int nType0 = DAZSCRIPT_ARG_ANY);
struct Arguments EvalTwoArgs(struct PropertyChain strPC, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY);
struct Arguments EvalThreeArgs(struct PropertyChain strPC, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY, int nType2 = DAZSCRIPT_ARG_ANY);

string GetValueAsText(struct Value strValue, string sDefault = "");
string GetValueAsTrimmedString(struct Value strValue, string sDefault = "");
int IsValueIntParameter(struct Value strValue);
int IsValueNumericParameter(struct Value strValue);
int IsValueObjectParameter(struct Value strValue);
int GetValueAsInt(struct Value strValue, int nDefault = 0);
float GetValueAsFloat(struct Value strValue, float fDefault = 0.0);
object GetValueAsObject(struct Value strValue, object oDefault = OBJECT_INVALID);

int IsInvalidValue(struct Value strValue);
int IsErrorValue(struct Value strValue);
struct Value GetInvalidValue();
struct Value GetErrorValue(string sMessage);

struct Value GetValueFromStackLocation(int nAuxType, int nStackLocation);
struct Value GetValueFromTypedLiteral(string sValue);
struct Value GetValueFromInt(int nValue = 0);
struct Value GetValueFromFloat(float fValue = 0.0f);
struct Value GetValueFromString(string sValue = "");
struct Value GetValueFromObject(object oValue = OBJECT_INVALID);
struct Value GetValueFromJson(json jValue = JSON_NULL);

string ValueToText(struct Value strValue);
int ValueToBoolish(struct Value strValue);
struct Value FormatValueAsFixed(struct Value strValue, int nPrecision);
struct Value FormatValueAsHex(struct Value strValue);
struct Value FormatValueAsBoolean(struct Value strValue);

struct PropertyChain GetIntProperty(struct PropertyChain strPC);
struct PropertyChain GetFloatProperty(struct PropertyChain strPC);
struct PropertyChain GetStringProperty(struct PropertyChain strPC);
struct PropertyChain GetObjectProperty(struct PropertyChain strPC);
struct PropertyChain GetJsonProperty(struct PropertyChain strPC);
struct PropertyChain GetSharedProperty(struct PropertyChain strPC);

struct Value HandleMetaPrimitive(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaFunction(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaControlFlow(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaVariable(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaIntrospection(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaUtility(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaOutput(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaMath(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaObject(struct PropertyChain strPC, string sMetaName);

int IsStackVar(string sVarName);
int IsSymbol(string sVarName, string sSymbol);
string GetAuxTypeDisplayName(int nAuxType);
string GetSymbolType(json jStack, string sName);
int SymbolExists(json jStack, string sName);
string InferDebugValueType(string sValue);
string TruncateDebugValue(string sValue);
string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "");
string InspectObject(object oValue);

string FormatString(string sString, int nDepthOverride = 0)
{
    return Interpret(sString, 1 + nDepthOverride, JsonNull());
}

string Interpret(string sString, int nDepthOverride = 0, json jStack = JSON_NULL)
{
    if (sString == "")
        return "";

    if (FindSubString(sString, "{", 0) == -1 && FindSubString(sString, "}", 0) == -1)
        return sString;

    json jTemplate = GetCachedJson(DAZSCRIPT_TEMPLATE_CACHE_PREFIX, sString);
    if (!JsonGetType(jTemplate))
    {
        jTemplate = CompileTemplate(sString);
        SetCachedJson(DAZSCRIPT_TEMPLATE_CACHE_PREFIX, sString, jTemplate);
    }

    if (!JsonGetType(jStack))
        jStack = NWNX_VM_GetStackVariables(1 + nDepthOverride);

    return ValueToText(EvalTemplate(jTemplate, jStack));
}

string MakeCacheKey(string sPrefix, string sString)
{
    return sPrefix + sString;
}

json GetCachedJson(string sPrefix, string sInput)
{
    return GetLocalJson(GetDataObject(DAZSCRIPT_SCRIPT_NAME), MakeCacheKey(sPrefix, sInput));
}

void SetCachedJson(string sPrefix, string sInput, json jValue)
{
    SetLocalJson(GetDataObject(DAZSCRIPT_SCRIPT_NAME), MakeCacheKey(sPrefix, sInput), jValue);
}

string GetAliasStoredValueAsString(json jEntry)
{
    json jValue = JsonObjectGet(jEntry, DAZSCRIPT_ALIAS_VALUE);
    switch (JsonGetType(jValue))
    {
        case JSON_TYPE_STRING: return JsonGetString(jValue);
        case JSON_TYPE_INTEGER: return IntToString(JsonGetInt(jValue));
        case JSON_TYPE_FLOAT: return FloatToString(JsonGetFloat(jValue), 0, 9);
    }
    return JsonDump(jValue);
}

json MakeStackAliasEntryFromValue(struct Value strValue)
{
    json jEntry = JsonObject();

    if (IsErrorValue(strValue))
    {
        JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.sErrorMessage);
        JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_TYPE, NWNX_VM_AUXTYPE_STRING);
        return jEntry;
    }

    JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_TYPE, strValue.nAuxType);
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.nValue); break;
        case NWNX_VM_AUXTYPE_FLOAT:     JsonObjectSetFloatInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.fValue); break;
        case NWNX_VM_AUXTYPE_STRING:    JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.sValue); break;
        case NWNX_VM_AUXTYPE_OBJECT:    JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, "0x" + ObjectToString(strValue.oValue));  break;
        case NWNX_VM_AUXTYPE_JSON:      JsonObjectSetInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.jValue); break;
        default:                        JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, ValueToText(strValue)); break;
    }
    return jEntry;
}

json MakeParameterEntry(string sText, int bWasQuoted)
{
    json jEntry = JsonObject();
    JsonObjectSetStringInplace(jEntry, DAZSCRIPT_PARAMETER_TEXT, sText);
    JsonObjectSetIntInplace(jEntry, DAZSCRIPT_PARAMETER_WAS_QUOTED, bWasQuoted);
    return jEntry;
}

int GetCastAuxTypeFromName(string sCast)
{
    sCast = GetStringLowerCase(trim(sCast));
    if (sCast == "i" || sCast == "int")     return NWNX_VM_AUXTYPE_INT;
    if (sCast == "f" || sCast == "float")   return NWNX_VM_AUXTYPE_FLOAT;
    if (sCast == "s" || sCast == "string")  return NWNX_VM_AUXTYPE_STRING;
    if (sCast == "o" || sCast == "object")  return NWNX_VM_AUXTYPE_OBJECT;
    if (sCast == "j" || sCast == "json")    return NWNX_VM_AUXTYPE_JSON;
    return NWNX_VM_AUXTYPE_INVALID;
}

string GetValueAsCastString(struct Value strValue)
{
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_JSON)
    {
        json jEntry = JsonObject();
        JsonObjectSetInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.jValue);
        return GetAliasStoredValueAsString(jEntry);
    }

    return ValueToText(strValue);
}

struct Value CastValueToJson(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return strValue;

    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_JSON:      return strValue;
        case NWNX_VM_AUXTYPE_INT:       return GetValueFromJson(JsonInt(strValue.nValue));
        case NWNX_VM_AUXTYPE_FLOAT:     return GetValueFromJson(JsonFloat(strValue.fValue));
        case NWNX_VM_AUXTYPE_OBJECT:    return GetValueFromJson(JsonString("0x" + ObjectToString(strValue.oValue)));
        case NWNX_VM_AUXTYPE_STRING:
        {
            json jParsed = JsonParse(strValue.sValue);
            if (!JsonGetType(jParsed) && JsonGetError(jParsed) != "")
                return GetErrorValue("INVALID_JSON:" + strValue.sValue);

            return GetValueFromJson(jParsed);
        }
    }
    return GetErrorValue("TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->json");
}

struct Value CastValueToAuxType(struct Value strValue, int nTargetAuxType)
{
    if (IsErrorValue(strValue))
        return strValue;

    if (nTargetAuxType == NWNX_VM_AUXTYPE_JSON)
        return CastValueToJson(strValue);

    string sValue = GetValueAsCastString(strValue);
    switch (nTargetAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:
        {
            if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
                return strValue;

            if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
                return GetValueFromInt(FloatToInt(strValue.fValue));

            if (strValue.nAuxType == NWNX_VM_AUXTYPE_OBJECT)
                return GetValueFromInt(HexStringToInt(ObjectToString(strValue.oValue)));

            sValue = trim(sValue);
            if (!IsInteger(sValue))
                return GetErrorValue("TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->int");

            return GetValueFromInt(StringToInt(sValue));
        }
        case NWNX_VM_AUXTYPE_FLOAT:
        {
            if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
                return strValue;

            if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
                return GetValueFromFloat(IntToFloat(strValue.nValue));

            sValue = trim(sValue);
            if (!IsNumeric(sValue))
                return GetErrorValue("TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->float");

            return GetValueFromFloat(StringToFloat(sValue));
        }
        case NWNX_VM_AUXTYPE_STRING:
        {
            return GetValueFromString(sValue);
        }
        case NWNX_VM_AUXTYPE_OBJECT:
        {
            if (strValue.nAuxType == NWNX_VM_AUXTYPE_OBJECT)
                return strValue;

            sValue = trim(sValue);
            if (!IsObjectString(sValue))
                return GetErrorValue("TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->object");

            return GetValueFromObject(StringToObject(sValue));
        }
    }

    return GetErrorValue("INVALID_CAST_AUXTYPE:" + IntToString(nTargetAuxType));
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

string NormalizePropertyChainOperators(string sString)
{
    if (FindSubString(sString, DAZSCRIPT_PROPERTY_CHAIN_SYMBOL_ALT) == -1)
        return sString;

    int nLength = GetStringLength(sString);
    int nBraceDepth = 0, nParenDepth = 0, bInQuotes = FALSE;
    string sOut, sQuoteChar;

    int nIndex;
    for (nIndex = 0; nIndex < nLength; nIndex++)
    {
        string sCharacter = GetSubString(sString, nIndex, 1);
        if (bInQuotes)
        {
            sOut += sCharacter;
            if (IsParserEscapedCharacter(sString, nIndex, nLength))
            {
                nIndex++;
                if (nIndex < nLength)
                    sOut += GetSubString(sString, nIndex, 1);
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
            sOut += sCharacter;
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

        if (nBraceDepth == 0 && nParenDepth == 0 && nIndex + 1 < nLength && GetSubString(sString, nIndex, 2) == DAZSCRIPT_PROPERTY_CHAIN_SYMBOL_ALT)
        {
            sOut += DAZSCRIPT_PROPERTY_CHAIN_SYMBOL_CANONICAL;
            nIndex++;
            continue;
        }

        sOut += sCharacter;
    }

    return sOut;
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

json CompileTemplate(string sString)
{
    json jTemplate = JsonArray();
    int nIndex, nLiteralStart, nLength = GetStringLength(sString);

    while (nIndex < nLength)
    {
        string sCurrent = GetSubString(sString, nIndex, 1);
        if (sCurrent == "{" && nIndex + 1 < nLength && GetSubString(sString, nIndex + 1, 1) == "{")
        {
            if (nIndex > nLiteralStart)
            {
                JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nIndex - nLiteralStart));
            }

            JsonArrayInsertLiteralNodeInplace(jTemplate, "{");
            nIndex += 2;
            nLiteralStart = nIndex;
            continue;
        }

        if (sCurrent == "}" && nIndex + 1 < nLength && GetSubString(sString, nIndex + 1, 1) == "}")
        {
            if (nIndex > nLiteralStart)
            {
                JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nIndex - nLiteralStart));
            }

            JsonArrayInsertLiteralNodeInplace(jTemplate, "}");
            nIndex += 2;
            nLiteralStart = nIndex;
            continue;
        }

        if (sCurrent != "{")
        {
            nIndex++;
            continue;
        }

        int nStart = nIndex, nDepth = 1, bInQuotes = FALSE;
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
            {
                nDepth++;
            }
            else if (sCharacter == "}")
            {
                nDepth--;
            }

            nIndex++;
        }

        if (nDepth != 0)
        {
            nIndex = nLength;
            break;
        }

        if (nStart > nLiteralStart)
        {
            JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nStart - nLiteralStart));
        }

        JsonArrayInsertExprNodeInplace(jTemplate, GetSubString(sString, nStart + 1, nIndex - nStart - 2));

        nLiteralStart = nIndex;
    }

    if (nLiteralStart < nLength)
    {
        JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nLength - nLiteralStart));
    }

    return jTemplate;
}

json CompileForcedStringTemplate(string sValue)
{
    json jTemplate = JsonArray();
    JsonArrayInsertForceStringNodeInplace(jTemplate, CompileTemplate(sValue));
    return jTemplate;
}

struct Value EvalTemplate(json jTemplate, json jStack)
{
    int nIndex, nLength = JsonGetLength(jTemplate);

    if (nLength == 1)
    {
        json jSingleNode = JsonArrayGet(jTemplate, 0);
        int nSingleNodeType = JsonArrayGetInt(jSingleNode, 0);

        if (nSingleNodeType == DAZSCRIPT_NODE_EXPR)
            return EvalCompiledExpressionToValue(jSingleNode, jStack);

        if (nSingleNodeType == DAZSCRIPT_NODE_FORCE_STRING)
        {
            struct Value strInnerValue = EvalTemplate(JsonArrayGet(jSingleNode, 1), jStack);
            if (IsErrorValue(strInnerValue))
                return strInnerValue;
            return GetValueFromString(ValueToText(strInnerValue));
        }

        if (nSingleNodeType == DAZSCRIPT_NODE_LITERAL)
            return GetValueFromTypedLiteral(JsonArrayGetString(jSingleNode, 1));
    }

    string sResult = "";
    for (nIndex = 0; nIndex < nLength; nIndex++)
    {
        json jNode = JsonArrayGet(jTemplate, nIndex);
        int nNodeType = JsonArrayGetInt(jNode, 0);

        if (nNodeType == DAZSCRIPT_NODE_LITERAL)
            sResult += JsonArrayGetString(jNode, 1);
        else if (nNodeType == DAZSCRIPT_NODE_EXPR)
        {
            struct Value strExpressionValue = EvalCompiledExpressionToValue(jNode, jStack);
            if (IsErrorValue(strExpressionValue))
                return strExpressionValue;
            sResult += ValueToText(strExpressionValue);
        }
        else if (nNodeType == DAZSCRIPT_NODE_FORCE_STRING)
        {
            struct Value strInnerValue = EvalTemplate(JsonArrayGet(jNode, 1), jStack);
            if (IsErrorValue(strInnerValue))
                return strInnerValue;
            sResult += ValueToText(strInnerValue);
        }
    }

    return GetValueFromString(sResult);
}

void JsonArrayInsertLiteralNodeInplace(json jTemplate, string sLiteral)
{
    if (sLiteral == "")
        return;

    json jNode = JsonArray();
    JsonArrayInsertIntInplace(jNode, DAZSCRIPT_NODE_LITERAL);
    JsonArrayInsertStringInplace(jNode, sLiteral);
    JsonArrayInsertInplace(jTemplate, jNode);
}

void JsonArrayInsertExprNodeInplace(json jTemplate, string sExpr)
{
    JsonArrayInsertInplace(jTemplate, CompileExpression(sExpr));
}

void JsonArrayInsertForceStringNodeInplace(json jTemplate, json jInnerTemplate)
{
    json jNode = JsonArray();
    JsonArrayInsertIntInplace(jNode, DAZSCRIPT_NODE_FORCE_STRING);
    JsonArrayInsertInplace(jNode, jInnerTemplate);
    JsonArrayInsertInplace(jTemplate, jNode);
}

json CompileExpression(string sExpr)
{
    sExpr = trim(sExpr);
    sExpr = NormalizePropertyChainOperators(sExpr);

    int nPropertyPosition = FindTopLevelDelimiter(sExpr, DAZSCRIPT_PROPERTY_CHAIN_SYMBOL_CANONICAL);
    string sBase, sPropertyPath;

    if (nPropertyPosition == -1)
        sBase = sExpr;
    else
    {
        sBase = trim(GetStringLeft(sExpr, nPropertyPosition));
        sPropertyPath = trim(GetSubString(sExpr, nPropertyPosition + 1, GetStringLength(sExpr) - nPropertyPosition - 1));
    }

    int nKind = DAZSCRIPT_EXPR_VAR;
    string sBaseName = sBase, sBaseParameters, sPrefix = GetStringLeft(sBase, 1);
    json jBaseCompiledParameters = JsonArray();

    if (sPrefix == DAZSCRIPT_META_SYMBOL)
    {
        nKind = DAZSCRIPT_EXPR_META;
        json jBase = CompilePropertySegment(GetSubString(sBase, 1, GetStringLength(sBase) - 1));
        sBaseName = JsonArrayGetString(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY);
        sBaseParameters = JsonArrayGetString(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETERS);
        jBaseCompiledParameters = JsonArrayGet(jBase, DAZSCRIPT_PROPERTY_SEGMENT_COMPILED_PARAMETERS);
    }
    else if (sPrefix == DAZSCRIPT_ALIAS_SYMBOL)
    {
        nKind = DAZSCRIPT_EXPR_ALIAS;
        sBaseName = sBase;
    }
    else if (sPrefix == DAZSCRIPT_FUNCTION_SYMBOL)
    {
        nKind = DAZSCRIPT_EXPR_FUNCTION;
        json jBase = CompilePropertySegment(sBase);
        sBaseName = JsonArrayGetString(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY);
        sBaseParameters = JsonArrayGetString(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETERS);
        jBaseCompiledParameters = JsonArrayGet(jBase, DAZSCRIPT_PROPERTY_SEGMENT_COMPILED_PARAMETERS);
    }

    json jChain = JsonArray();

    if (sPropertyPath != "")
        jChain = CompilePropertyChain(sPropertyPath);

    json jExpr = JsonArray();
    JsonArrayInsertIntInplace(jExpr, DAZSCRIPT_NODE_EXPR);
    JsonArrayInsertIntInplace(jExpr, nKind);
    JsonArrayInsertStringInplace(jExpr, sBaseName);
    JsonArrayInsertInplace(jExpr, jChain);
    JsonArrayInsertStringInplace(jExpr, sBaseParameters);
    JsonArrayInsertStringInplace(jExpr, sPropertyPath);
    JsonArrayInsertInplace(jExpr, jBaseCompiledParameters);

    return jExpr;
}

string EvalCompiledExpression(json jExpr, json jStack)
{
    return ValueToText(EvalCompiledExpressionToValue(jExpr, jStack));
}

struct Value EvalCompiledExpressionToValue(json jExpr, json jStack)
{
    int nKind = JsonArrayGetInt(jExpr, DAZSCRIPT_EXPR_KIND);
    string sBaseName = JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_BASE_NAME);
    json jChain = JsonArrayGet(jExpr, DAZSCRIPT_EXPR_CHAIN);
    string sBaseParameters = JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_BASE_PARAMETERS);
    string sPropertyPath = JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_PROPERTY_PATH);
    json jBaseCompiledParameters = JsonArrayGet(jExpr, DAZSCRIPT_EXPR_BASE_COMPILED_PARAMETERS);

    struct Value strValue;

    if (nKind == DAZSCRIPT_EXPR_VAR)
        strValue = GetStackValue(jStack, sBaseName);
    else if (nKind == DAZSCRIPT_EXPR_ALIAS)
        strValue = ResolveAliasValue(jStack, sBaseName);
    else if (nKind == DAZSCRIPT_EXPR_META)
        strValue = ResolveMetaValue(jStack, sBaseName, sBaseParameters, jBaseCompiledParameters);
    else if (nKind == DAZSCRIPT_EXPR_FUNCTION)
        strValue = ResolveFunctionValue(jStack, sBaseName, sBaseParameters, jBaseCompiledParameters);

    if (IsErrorValue(strValue))
        return strValue;

    if (IsInvalidValue(strValue))
        return GetErrorValue("INVALID_EXPR:" + sBaseName);

    if (JsonGetLength(jChain) > 0)
    {
        struct PropertyChain strPC;
        strPC.jStack = jStack;
        strPC.sBaseVarName = sBaseName;
        strPC.sFullPropertyPath = sPropertyPath;
        strPC.strValue = strValue;

        strPC = EvalCompiledPropertyChain(strPC, jChain);

        if (IsErrorValue(strPC.strValue))
            return GetErrorValue("INVALID_PROPERTY_CHAIN:" + sBaseName + ">" + sPropertyPath + " -> FAILED@" + strPC.sCurrentProperty + " -> " + strPC.strValue.sErrorMessage);

        if (IsInvalidValue(strPC.strValue))
            return GetErrorValue("INVALID_PROPERTY_CHAIN:" + sBaseName + ">" + sPropertyPath + " -> FAILED@" + strPC.sCurrentProperty);

        strValue = strPC.strValue;
    }

    return strValue;
}

struct Value GetStackValue(json jStack, string sVarName)
{
    if (!JsonObjectContainsKey(jStack, sVarName))
        return GetErrorValue("MISSING_VAR:" + sVarName);

    json jStackVar = JsonObjectGet(jStack, sVarName);

    if (JsonGetType(jStackVar) != JSON_TYPE_OBJECT)
        return GetErrorValue("INVALID_STACK_VAR:" + sVarName);

    int nAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);
    if (nAuxType == NWNX_VM_AUXTYPE_VOID)
        return GetValueFromString(DumpStruct(jStack, sVarName, JsonObjectGetString(jStackVar, NWNX_VM_STRUCT_NAME_KEY)));

    return GetValueFromStackLocation(nAuxType, JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY));
}

struct Value ResolveAliasValue(json jStack, string sAliasName)
{
    if (!JsonObjectContainsKey(jStack, sAliasName))
        return GetErrorValue("MISSING_ALIAS:" + sAliasName);

    json jEntry = JsonObjectGet(jStack, sAliasName);
    int nAuxType = JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_TYPE);
    json jValue = JsonObjectGet(jEntry, DAZSCRIPT_ALIAS_VALUE);
    int nJsonType = JsonGetType(jValue);

    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:
        {
            if (nJsonType == JSON_TYPE_INTEGER)
                return GetValueFromInt(JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_VALUE));
            return GetValueFromInt(StringToInt(GetAliasStoredValueAsString(jEntry)));
        }
        case NWNX_VM_AUXTYPE_FLOAT:
        {
            if (nJsonType == JSON_TYPE_FLOAT)
                return GetValueFromFloat(JsonObjectGetFloat(jEntry, DAZSCRIPT_ALIAS_VALUE));
            if (nJsonType == JSON_TYPE_INTEGER)
                return GetValueFromFloat(IntToFloat(JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_VALUE)));
            return GetValueFromFloat(StringToFloat(GetAliasStoredValueAsString(jEntry)));
        }
        case NWNX_VM_AUXTYPE_OBJECT:
            return GetValueFromObject(StringToObject(GetAliasStoredValueAsString(jEntry)));
        case NWNX_VM_AUXTYPE_JSON:
            return GetValueFromJson(jValue);
    }

    return GetValueFromString(GetAliasStoredValueAsString(jEntry));
}

struct Value ResolveMetaValue(json jStack, string sMetaName, string sBaseParameters, json jBaseCompiledParameters)
{
    struct PropertyChain strMeta;
    strMeta.jStack = jStack;
    strMeta.sCurrentProperty = sMetaName;
    strMeta.sCurrentParameters = sBaseParameters;
    strMeta.jCurrentParameters = jBaseCompiledParameters;

    struct Value strReturnValue = GetInvalidValue();

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaPrimitive(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaFunction(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaControlFlow(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaVariable(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaIntrospection(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaUtility(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaOutput(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaMath(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        strReturnValue = HandleMetaObject(strMeta, sMetaName);

    if (IsInvalidValue(strReturnValue))
        return GetErrorValue("UNKNOWN_META:" + sMetaName);

    return strReturnValue;
}

struct Value ResolveFunctionValue(json jStack, string sFunctionName, string sBaseParameters, json jBaseCompiledParameters)
{
    json jFunction = JsonObjectGet(jStack, sFunctionName);

    if (JsonGetType(jFunction) != JSON_TYPE_OBJECT)
        return GetErrorValue("UNKNOWN_FUNCTION:" + sFunctionName);

    json jArgNames = JsonObjectGet(jFunction, DAZSCRIPT_FUNCTION_ARGS);
    json jBody = JsonObjectGet(jFunction, DAZSCRIPT_FUNCTION_BODY_COMPILED);

    if (JsonGetType(jBody) != JSON_TYPE_ARRAY)
        return GetErrorValue("INVALID_FUNCTION_BODY:" + sFunctionName);

    struct PropertyChain strFunction;
    strFunction.jStack = jStack;
    strFunction.sCurrentProperty = sFunctionName;
    strFunction.sCurrentParameters = sBaseParameters;
    strFunction.jCurrentParameters = jBaseCompiledParameters;

    json jCompiledParameters = GetCompiledParameters(strFunction);
    if (JsonGetLength(jCompiledParameters) != JsonGetLength(jArgNames))
        return GetErrorValue("FUNCTION_ARITY:" + sFunctionName);

    json jFrame = JsonCopyObject(jStack);
    int nIndex, nNumArgs = JsonGetLength(jArgNames);
    for (nIndex = 0; nIndex < nNumArgs; nIndex++)
    {
        string sArgName = JsonArrayGetString(jArgNames, nIndex);
        struct Value strArgValue = EvalTemplate(JsonArrayGet(jCompiledParameters, nIndex), jStack);

        if (IsErrorValue(strArgValue))
            return strArgValue;

        JsonObjectSetInplace(jFrame, sArgName, MakeStackAliasEntryFromValue(strArgValue));
    }

    return EvalTemplate(jBody, jFrame);
}

json CompilePropertyChain(string sPropertyPath)
{
    sPropertyPath = trim(sPropertyPath);
    sPropertyPath = NormalizePropertyChainOperators(sPropertyPath);

    json jCached = GetCachedJson(DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath);
    if (JsonGetType(jCached) == JSON_TYPE_ARRAY)
        return jCached;

    json jRawSegments = SplitTopLevel(sPropertyPath, DAZSCRIPT_PROPERTY_CHAIN_SYMBOL_CANONICAL, TRUE);
    json jCompiledSegments = JsonArray();
    int nSegment, nNumSegments = JsonGetLength(jRawSegments);

    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        JsonArrayInsertInplace(jCompiledSegments, CompilePropertySegment(JsonArrayGetString(jRawSegments, nSegment)));
    }

    SetCachedJson(DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath, jCompiledSegments);
    return jCompiledSegments;
}

json CompilePropertySegment(string sPropertySegment)
{
    sPropertySegment = trim(sPropertySegment);

    string sQuoteChar;
    int nIndex, nLength = GetStringLength(sPropertySegment), nParameterStart = -1, bInQuotes;

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

    string sProperty, sParameters;
    if (nParameterStart == -1)
        sProperty = sPropertySegment;
    else
    {
        sProperty = trim(GetStringLeft(sPropertySegment, nParameterStart));

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
            sParameters = GetSubString(sPropertySegment, nParameterStart + 1, nParameterEnd - nParameterStart - 1);
    }

    json jParameterEntries = ParseParameterEntries(sParameters);
    json jSegment = JsonArray();
    JsonArrayInsertStringInplace(jSegment, GetStringLowerCase(sProperty));
    JsonArrayInsertStringInplace(jSegment, sParameters);
    JsonArrayInsertInplace(jSegment, CompileParameters(sParameters));
    JsonArrayInsertInplace(jSegment, jParameterEntries);

    return jSegment;
}

struct PropertyChain ApplyCompiledPropertySegment(struct PropertyChain strPC, json jSegment)
{
    strPC.sCurrentProperty = JsonArrayGetString(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY);
    strPC.sCurrentParameters = JsonArrayGetString(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETERS);
    strPC.jCurrentParameters = JsonArrayGet(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_COMPILED_PARAMETERS);
    strPC.jCurrentParameterEntries = JsonArrayGet(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_ENTRIES);
    return strPC;
}

struct PropertyChain EvalCompiledPropertyChain(struct PropertyChain strPC, json jSegments)
{
    int nSegment, nNumSegments = JsonGetLength(jSegments);
    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        strPC = GetPropertyValueByType(ApplyCompiledPropertySegment(strPC, JsonArrayGet(jSegments, nSegment)));
        if (IsErrorValue(strPC.strValue))
            break;
        if (IsInvalidValue(strPC.strValue))
        {
            strPC.strValue = GetErrorValue("UNKNOWN_PROPERTY:" + strPC.sCurrentProperty);
            break;
        }
    }
    return strPC;
}

struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC)
{
    struct PropertyChain strOriginal = strPC;

    switch (strPC.strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       strPC = GetIntProperty(strPC); break;
        case NWNX_VM_AUXTYPE_FLOAT:     strPC = GetFloatProperty(strPC); break;
        case NWNX_VM_AUXTYPE_STRING:    strPC = GetStringProperty(strPC); break;
        case NWNX_VM_AUXTYPE_OBJECT:    strPC = GetObjectProperty(strPC); break;
        case NWNX_VM_AUXTYPE_JSON:      strPC = GetJsonProperty(strPC); break;
        default: strPC.strValue = GetInvalidValue(); break;
    }

    if (IsErrorValue(strPC.strValue))
        return strPC;

    if (IsInvalidValue(strPC.strValue))
        strPC = GetSharedProperty(strOriginal);

    return strPC;
}

json CompileParameters(string sParameters)
{
    if (sParameters == "")
        return JsonArray();

    json jCached = GetCachedJson(DAZSCRIPT_COMPILED_PARAMETER_CACHE_PREFIX, sParameters);
    if (JsonGetType(jCached) == JSON_TYPE_ARRAY)
        return jCached;

    json jParameterEntries = ParseParameterEntries(sParameters);
    json jCompiledParameters = JsonArray();

    int nIndex, nNumParameters = JsonGetLength(jParameterEntries);
    for (nIndex = 0; nIndex < nNumParameters; nIndex++)
    {
        json jEntry = JsonArrayGet(jParameterEntries, nIndex);
        string sText = JsonObjectGetString(jEntry, DAZSCRIPT_PARAMETER_TEXT);
        int bWasQuoted = JsonObjectGetInt(jEntry, DAZSCRIPT_PARAMETER_WAS_QUOTED);

        if (bWasQuoted)
            JsonArrayInsertInplace(jCompiledParameters, CompileForcedStringTemplate(sText));
        else
            JsonArrayInsertInplace(jCompiledParameters, CompileTemplate(sText));
    }

    SetCachedJson(DAZSCRIPT_COMPILED_PARAMETER_CACHE_PREFIX, sParameters, jCompiledParameters);
    return jCompiledParameters;
}

json ParseParameterEntries(string sParameters)
{
    if (sParameters == "")
        return JsonArray();

    json jEntries = GetCachedJson(DAZSCRIPT_PARAMETER_ENTRY_CACHE_PREFIX, sParameters);
    if (JsonGetType(jEntries) == JSON_TYPE_ARRAY)
        return jEntries;

    jEntries = JsonArray();

    string sCurrent, sQuoteChar;
    int bInQuotes, bWasQuoted, bLastWasComma, bAfterTopLevelQuote;
    int nBraceDepth, nParenDepth;
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

                if (nBraceDepth == 0 && nParenDepth == 0)
                {
                    if (trim(sCurrent) == "")
                        sCurrent = "";
                }
                else
                {
                    sCurrent += sCharacter;
                }
            }
            else if (sCharacter == sQuoteChar)
            {
                bInQuotes = FALSE;

                if (nBraceDepth == 0 && nParenDepth == 0)
                {
                    bWasQuoted = TRUE;
                    bAfterTopLevelQuote = TRUE;
                }
                else
                {
                    sCurrent += sCharacter;
                }
            }
            else
            {
                sCurrent += sCharacter;
            }

            bLastWasComma = FALSE;
            continue;
        }

        if (bInQuotes)
        {
            sCurrent += sCharacter;
            bLastWasComma = FALSE;
            continue;
        }

        if (bAfterTopLevelQuote && nBraceDepth == 0 && nParenDepth == 0)
        {
            if (sCharacter == " ")
            {
                bLastWasComma = FALSE;
                continue;
            }
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
            JsonArrayInsertInplace(jEntries, MakeParameterEntry(bWasQuoted ? sCurrent : trim(sCurrent), bWasQuoted));

            sCurrent = "";
            bWasQuoted = FALSE;
            bAfterTopLevelQuote = FALSE;
            bLastWasComma = TRUE;
            continue;
        }
        else
        {
            sCurrent += sCharacter;
        }

        bLastWasComma = FALSE;
    }

    if (bInQuotes)
        return JsonArray();

    if (!bLastWasComma)
        JsonArrayInsertInplace(jEntries, MakeParameterEntry(bWasQuoted ? sCurrent : trim(sCurrent), bWasQuoted));

    SetCachedJson(DAZSCRIPT_PARAMETER_ENTRY_CACHE_PREFIX, sParameters, jEntries);
    return jEntries;
}

json GetCompiledParameters(struct PropertyChain strPC)
{
    json jCompiledParameters = strPC.jCurrentParameters;
    if (JsonGetType(jCompiledParameters) != JSON_TYPE_ARRAY)
        jCompiledParameters = CompileParameters(strPC.sCurrentParameters);
    return jCompiledParameters;
}

json GetParameterEntries(struct PropertyChain strPC)
{
    json jParameterEntries = strPC.jCurrentParameterEntries;
    if (JsonGetType(jParameterEntries) != JSON_TYPE_ARRAY)
        jParameterEntries = ParseParameterEntries(strPC.sCurrentParameters);
    return jParameterEntries;
}

string GetRawParameterText(struct PropertyChain strPC, int nIndex, string sDefault = "")
{
    json jParameterEntries = GetParameterEntries(strPC);
    if (nIndex < 0 || nIndex >= JsonGetLength(jParameterEntries))
        return sDefault;
    return JsonObjectGetString(JsonArrayGet(jParameterEntries, nIndex), DAZSCRIPT_PARAMETER_TEXT);
}

int GetRawParameterWasQuoted(struct PropertyChain strPC, int nIndex)
{
    json jParameterEntries = GetParameterEntries(strPC);
    if (nIndex < 0 || nIndex >= JsonGetLength(jParameterEntries))
        return FALSE;
    return JsonObjectGetInt(JsonArrayGet(jParameterEntries, nIndex), DAZSCRIPT_PARAMETER_WAS_QUOTED);
}

int GetParameterCount(struct PropertyChain strPC)
{
    return JsonGetLength(GetCompiledParameters(strPC));
}

struct Value EvalCompiledParameter(struct PropertyChain strPC, int nIndex)
{
    json jCompiledParameters = GetCompiledParameters(strPC);
    if (nIndex < 0 || nIndex >= JsonGetLength(jCompiledParameters))
        return GetErrorValue("PARAM_INDEX_OUT_OF_RANGE");
    return EvalTemplate(JsonArrayGet(jCompiledParameters, nIndex), strPC.jStack);
}

string GetArgTypeName(int nArgType)
{
    switch (nArgType)
    {
        case DAZSCRIPT_ARG_ANY:       return "any";
        case DAZSCRIPT_ARG_INT:       return "int";
        case DAZSCRIPT_ARG_NUMERIC:   return "numeric";
        case DAZSCRIPT_ARG_OBJECT:    return "object";
        case DAZSCRIPT_ARG_STRING:    return "string";
        case DAZSCRIPT_ARG_JSON:      return "json";
    }

    return "unknown";
}

int IsValueArgType(struct Value strValue, int nArgType)
{
    if (IsErrorValue(strValue))
        return FALSE;
    switch (nArgType)
    {
        case DAZSCRIPT_ARG_ANY:     return TRUE;
        case DAZSCRIPT_ARG_INT:     return IsValueIntParameter(strValue);
        case DAZSCRIPT_ARG_NUMERIC: return IsValueNumericParameter(strValue);
        case DAZSCRIPT_ARG_OBJECT:  return IsValueObjectParameter(strValue);
        case DAZSCRIPT_ARG_STRING:  return strValue.nAuxType == NWNX_VM_AUXTYPE_STRING;
        case DAZSCRIPT_ARG_JSON:    return strValue.nAuxType == NWNX_VM_AUXTYPE_JSON;
    }
    return FALSE;
}

struct Value CheckArity(struct PropertyChain strPC, int nMin, int nMax)
{
    int nCount = GetParameterCount(strPC);
    if (nCount < nMin)
    {
        if (nMin == nMax)
            return GetErrorValue("ARITY:EXPECTED_" + IntToString(nMin) + "_ARGUMENTS");
        return GetErrorValue("ARITY:EXPECTED_AT_LEAST_" + IntToString(nMin) + "_ARGUMENTS");
    }
    if (nMax >= 0 && nCount > nMax)
    {
        if (nMin == nMax)
            return GetErrorValue("ARITY:EXPECTED_" + IntToString(nMax) + "_ARGUMENTS");
        return GetErrorValue("ARITY:EXPECTED_" + IntToString(nMin) + "_TO_" + IntToString(nMax) + "_ARGUMENTS");
    }

    struct Value strValue;
    return strValue;
}

struct Value EvalTypedParameter(struct PropertyChain strPC, int nIndex, int nArgType)
{
    struct Value strArg = EvalCompiledParameter(strPC, nIndex);
    if (IsErrorValue(strArg))
        return strArg;
    if (!IsValueArgType(strArg, nArgType))
        return GetErrorValue("TYPE_MISMATCH:ARG" + IntToString(nIndex + 1) + "_NOT_" + GetStringUpperCase(GetArgTypeName(nArgType)));
    return strArg;
}

struct Arguments EvalArgs(struct PropertyChain strPC, int nMin, int nMax, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY, int nType2 = DAZSCRIPT_ARG_ANY, int nType3 = DAZSCRIPT_ARG_ANY, int nType4 = DAZSCRIPT_ARG_ANY)
{
    struct Arguments strArgs;
    strArgs.nCount = GetParameterCount(strPC);
    strArgs.strError = CheckArity(strPC, nMin, nMax);

    if (IsErrorValue(strArgs.strError))
        return strArgs;

    if (strArgs.nCount > 0)
    {
        strArgs.strArg0 = EvalTypedParameter(strPC, 0, nType0);
        if (IsErrorValue(strArgs.strArg0))
        {
            strArgs.strError = strArgs.strArg0;
            return strArgs;
        }
    }

    if (strArgs.nCount > 1)
    {
        strArgs.strArg1 = EvalTypedParameter(strPC, 1, nType1);
        if (IsErrorValue(strArgs.strArg1))
        {
            strArgs.strError = strArgs.strArg1;
            return strArgs;
        }
    }

    if (strArgs.nCount > 2)
    {
        strArgs.strArg2 = EvalTypedParameter(strPC, 2, nType2);
        if (IsErrorValue(strArgs.strArg2))
        {
            strArgs.strError = strArgs.strArg2;
            return strArgs;
        }
    }

    if (strArgs.nCount > 3)
    {
        strArgs.strArg3 = EvalTypedParameter(strPC, 3, nType3);
        if (IsErrorValue(strArgs.strArg3))
        {
            strArgs.strError = strArgs.strArg3;
            return strArgs;
        }
    }

    if (strArgs.nCount > 4)
    {
        strArgs.strArg4 = EvalTypedParameter(strPC, 4, nType4);
        if (IsErrorValue(strArgs.strArg4))
        {
            strArgs.strError = strArgs.strArg4;
            return strArgs;
        }
    }

    return strArgs;
}

struct Arguments EvalOneArg(struct PropertyChain strPC, int nType0 = DAZSCRIPT_ARG_ANY)
{
    return EvalArgs(strPC, 1, 1, nType0);
}

struct Arguments EvalTwoArgs(struct PropertyChain strPC, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY)
{
    return EvalArgs(strPC, 2, 2, nType0, nType1);
}

struct Arguments EvalThreeArgs(struct PropertyChain strPC, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY, int nType2 = DAZSCRIPT_ARG_ANY)
{
    return EvalArgs(strPC, 3, 3, nType0, nType1, nType2);
}

int IsInvalidValue(struct Value strValue)
{
    return strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID && !strValue.bError;
}

int IsErrorValue(struct Value strValue)
{
    return strValue.bError;
}

struct Value GetInvalidValue()
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    return str;
}

struct Value GetErrorValue(string sMessage)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_INVALID;
    str.bError = TRUE;
    str.sErrorMessage = sMessage;
    return str;
}

struct Value GetValueFromStackLocation(int nAuxType, int nStackLocation)
{
    struct Value str;
    str.nAuxType = nAuxType;
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

struct Value GetValueFromTypedLiteral(string sValue)
{
    if (sValue != trim(sValue))
        return GetValueFromString(sValue);
    string sLower = GetStringLowerCase(sValue);

    if (sLower == "true")
        return GetValueFromInt(TRUE);
    if (sLower == "false")
        return GetValueFromInt(FALSE);
    if (sLower == STRING_OBJECT_INVALID)
        return GetValueFromObject(OBJECT_INVALID);
    if (IsInteger(sValue))
        return GetValueFromInt(StringToInt(sValue));
    if (IsFloat(sValue))
        return GetValueFromFloat(StringToFloat(sValue));
    if (GetStringLength(sValue) >= 3 && GetStringLeft(sValue, 2) == "0x")
    {
        object oValue = StringToObject(sValue);
        if (oValue != OBJECT_INVALID)
            return GetValueFromObject(oValue);
    }

    return GetValueFromString(sValue);
}

struct Value GetValueFromInt(int nValue = 0)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_INT;
    str.nValue = nValue;
    return str;
}

struct Value GetValueFromFloat(float fValue = 0.0f)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_FLOAT;
    str.fValue = fValue;
    return str;
}

struct Value GetValueFromString(string sValue = "")
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_STRING;
    str.sValue = sValue;
    return str;
}

struct Value GetValueFromObject(object oValue = OBJECT_INVALID)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_OBJECT;
    str.oValue = oValue;
    return str;
}

struct Value GetValueFromJson(json jValue = JSON_NULL)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_JSON;
    str.jValue = jValue;
    return str;
}

string ValueToText(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return "[" + strValue.sErrorMessage + "]";

    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return strValue.sValue;
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strValue.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strValue.fValue, 0, 9);
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(strValue.oValue);
        case NWNX_VM_AUXTYPE_JSON:      return JsonDump(strValue.jValue);
    }
    return "[UNHANDLED_AUXTYPE:" + AuxTypeToString(strValue.nAuxType) + "]";
}

int ValueToBoolish(struct Value strValue)
{
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       return strValue.nValue != 0;
        case NWNX_VM_AUXTYPE_FLOAT:     return fabs(strValue.fValue) >= FLOAT_EPSILON;
        case NWNX_VM_AUXTYPE_STRING:    return StringToBoolish(strValue.sValue);
        case NWNX_VM_AUXTYPE_OBJECT:    return GetIsObjectValid(strValue.oValue);
        case NWNX_VM_AUXTYPE_JSON:      return JsonGetType(strValue.jValue) != JSON_TYPE_NULL;
    }
    return FALSE;
}

struct Value FormatValueAsFixed(struct Value strValue, int nPrecision)
{
    nPrecision = clamp(nPrecision, 0, 9);
    if (IsValueNumericParameter(strValue))
        return GetValueFromString(FloatToString(GetValueAsFloat(strValue), 0, nPrecision));
    return GetErrorValue("TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->fixed");
}

struct Value FormatValueAsHex(struct Value strValue)
{
    if (IsValueIntParameter(strValue))
        return GetValueFromString(IntToHexString(GetValueAsInt(strValue)));
    return GetErrorValue("TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->hex");
}

struct Value FormatValueAsBoolean(struct Value strValue)
{
    return GetValueFromString(ValueToBoolish(strValue) ? "TRUE" : "FALSE");
}

string GetValueAsText(struct Value strValue, string sDefault = "")
{
    if (IsErrorValue(strValue))
        return sDefault;
    return ValueToText(strValue);
}

string GetValueAsTrimmedString(struct Value strValue, string sDefault = "")
{
    return trim(GetValueAsText(strValue, sDefault));
}

int IsValueIntParameter(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return FALSE;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
        return TRUE;
    return IsInteger(GetValueAsTrimmedString(strValue));
}

int IsValueNumericParameter(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return FALSE;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT || strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
        return TRUE;
    return IsNumeric(GetValueAsTrimmedString(strValue));
}

int IsValueObjectParameter(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return FALSE;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_OBJECT)
        return TRUE;
    return IsObjectString(GetValueAsTrimmedString(strValue));
}

int GetValueAsInt(struct Value strValue, int nDefault = 0)
{
    if (!IsValueIntParameter(strValue))
        return nDefault;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
        return strValue.nValue;
    return StringToInt(GetValueAsTrimmedString(strValue));
}

float GetValueAsFloat(struct Value strValue, float fDefault = 0.0)
{
    if (!IsValueNumericParameter(strValue))
        return fDefault;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
        return IntToFloat(strValue.nValue);
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
        return strValue.fValue;
    return StringToFloat(GetValueAsTrimmedString(strValue));
}

object GetValueAsObject(struct Value strValue, object oDefault = OBJECT_INVALID)
{
    if (!IsValueObjectParameter(strValue))
        return oDefault;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_OBJECT)
        return strValue.oValue;
    object oValue = StringToObject(GetValueAsTrimmedString(strValue));
    if (oValue == OBJECT_INVALID)
        return oDefault;
    return oValue;
}

struct PropertyChain GetIntProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    int nValue = strPC.strValue.nValue;

    struct Value strReturnValue = GetInvalidValue();

    if (sProperty == "abs")
    {
        strReturnValue = GetValueFromInt(abs(nValue));
    }
    else if (sProperty == "eq" || sProperty == "neq" || sProperty == "gt" || sProperty == "gte" || sProperty == "lt" || sProperty == "lte")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            int nCompare = GetValueAsInt(strArgs.strArg0);
            if (sProperty == "eq")          strReturnValue = GetValueFromInt(nValue == nCompare);
            else if (sProperty == "neq")    strReturnValue = GetValueFromInt(nValue != nCompare);
            else if (sProperty == "gt")     strReturnValue = GetValueFromInt(nValue > nCompare);
            else if (sProperty == "gte")    strReturnValue = GetValueFromInt(nValue >= nCompare);
            else if (sProperty == "lt")     strReturnValue = GetValueFromInt(nValue < nCompare);
            else if (sProperty == "lte")    strReturnValue = GetValueFromInt(nValue <= nCompare);
        }
    }
    else if (sProperty == "min" || sProperty == "max")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            int nOther = GetValueAsInt(strArgs.strArg0);
            if (sProperty == "min")
                strReturnValue = GetValueFromInt(nValue < nOther ? nValue : nOther);
            else
                strReturnValue = GetValueFromInt(nValue > nOther ? nValue : nOther);
        }
    }
    else if (sProperty == "clamp")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
            strReturnValue = GetValueFromInt(clamp(nValue, GetValueAsInt(strArgs.strArg0), GetValueAsInt(strArgs.strArg1)));
    }
    else if (sProperty == "mod")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            int nDivisor = GetValueAsInt(strArgs.strArg0);
            if (nDivisor != 0)
                strReturnValue = GetValueFromInt(nValue % nDivisor);
            else
                strReturnValue = GetErrorValue("DIVISION_BY_ZERO");
        }
    }
    else if (sProperty == "then")
    {
        struct Value strError = CheckArity(strPC, 2, 2);
        if (IsErrorValue(strError))
            strReturnValue = strError;
        else
            strReturnValue = EvalCompiledParameter(strPC, nValue != 0 ? 0 : 1);
    }
    else if (sProperty == "plural")
    {
        struct Value strError = CheckArity(strPC, 1, 2);
        if (IsErrorValue(strError))
            strReturnValue = strError;
        else if (GetParameterCount(strPC) == 1)
        {
            if (nValue == 1)
                strReturnValue = GetValueFromString();
            else
                strReturnValue = EvalCompiledParameter(strPC, 0);
        }
        else
            strReturnValue = EvalCompiledParameter(strPC, nValue != 1);
    }
    else if (sProperty == "increment" || sProperty == "incr")
    {
        strReturnValue = GetValueFromInt(nValue + 1);
    }
    else if (sProperty == "decrement" || sProperty == "decr")
    {
        strReturnValue = GetValueFromInt(nValue - 1);
    }
    else if (sProperty == "even" || sProperty == "odd")
    {
        if (sProperty == "even")
            strReturnValue = GetValueFromInt(nValue % 2 == 0);
        else
            strReturnValue = GetValueFromInt(nValue % 2 != 0);
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct PropertyChain GetFloatProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    float fValue = strPC.strValue.fValue;

    struct Value strReturnValue = GetInvalidValue();

    if (sProperty == "fabs")
    {
        strReturnValue = GetValueFromFloat(fabs(fValue));
    }
    else if (sProperty == "floor")
    {
        strReturnValue = GetValueFromInt(floor(fValue));
    }
    else if (sProperty == "ceil")
    {
        strReturnValue = GetValueFromInt(ceil(fValue));
    }
    else if (sProperty == "round")
    {
        strReturnValue = GetValueFromInt(round(fValue));
    }
    else if (sProperty == "eq" || sProperty == "neq" || sProperty == "gt" || sProperty == "gte" || sProperty == "lt" || sProperty == "lte")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_NUMERIC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            float fCompare = GetValueAsFloat(strArgs.strArg0);
            float fDiff = fValue - fCompare;
            if (sProperty == "eq")          strReturnValue = GetValueFromInt(fabs(fDiff) < FLOAT_EPSILON);
            else if (sProperty == "neq")    strReturnValue = GetValueFromInt(fabs(fDiff) >= FLOAT_EPSILON);
            else if (sProperty == "gt")     strReturnValue = GetValueFromInt(fDiff > FLOAT_EPSILON);
            else if (sProperty == "gte")    strReturnValue = GetValueFromInt(fDiff >= -FLOAT_EPSILON);
            else if (sProperty == "lt")     strReturnValue = GetValueFromInt(fDiff < -FLOAT_EPSILON);
            else if (sProperty == "lte")    strReturnValue = GetValueFromInt(fDiff <= FLOAT_EPSILON);
        }
    }
    else if (sProperty == "min" || sProperty == "max")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_NUMERIC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            float fOther = GetValueAsFloat(strArgs.strArg0);
            if (sProperty == "min")
                strReturnValue = GetValueFromFloat(fValue < fOther ? fValue : fOther);
            else
                strReturnValue = GetValueFromFloat(fValue > fOther ? fValue : fOther);
        }
    }
    else if (sProperty == "clamp")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
            strReturnValue = GetValueFromFloat(clampf(fValue, GetValueAsFloat(strArgs.strArg0), GetValueAsFloat(strArgs.strArg1)));
    }

    strPC.strValue = strReturnValue;
    return strPC;
}


struct PropertyChain GetStringProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sValue = strPC.strValue.sValue;

    struct Value strReturnValue = GetInvalidValue();

    if (sProperty == "length")
    {
        strReturnValue = GetValueFromInt(GetStringLength(sValue));
    }
    else if (sProperty == "upper")
    {
        strReturnValue = GetValueFromString(GetStringUpperCase(sValue));
    }
    else if (sProperty == "lower")
    {
        strReturnValue = GetValueFromString(GetStringLowerCase(sValue));
    }
    else if (sProperty == "trim")
    {
        strReturnValue = GetValueFromString(trim(sValue));
    }
    else if (sProperty == "empty")
    {
        strReturnValue = GetValueFromInt(sValue == "");
    }
    else if (sProperty == "notempty")
    {
        strReturnValue = GetValueFromInt(sValue != "");
    }
    else if (sProperty == "contains")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
            strReturnValue = GetValueFromInt(FindSubString(sValue, GetValueAsText(strArgs.strArg0), 0) != -1);
    }
    else if (sProperty == "startswith" || sProperty == "prefix")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
            strReturnValue = GetValueFromInt(IsStringPrefix(sValue, GetValueAsText(strArgs.strArg0)));
    }
    else if (sProperty == "endswith" || sProperty == "suffix")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
            strReturnValue = GetValueFromInt(IsStringSuffix(sValue, GetValueAsText(strArgs.strArg0)));
    }
    else if (sProperty == "substr" || sProperty == "substring")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            int nStart = GetValueAsInt(strArgs.strArg0);
            int nCount = GetStringLength(sValue) - nStart;
            if (strArgs.nCount == 2)
                nCount = GetValueAsInt(strArgs.strArg1);
            strReturnValue = GetValueFromString(GetSubString(sValue, nStart, nCount));
        }
    }
    else if (sProperty == "left" || sProperty == "right")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            int nLength = GetValueAsInt(strArgs.strArg0);
            if (sProperty == "left")
                strReturnValue = GetValueFromString(GetStringLeft(sValue, nLength));
            else
                strReturnValue = GetValueFromString(GetStringRight(sValue, nLength));
        }
    }
    else if (sProperty == "replace")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            string sSearch = NWNX_Util_RegExpEscape(GetValueAsText(strArgs.strArg0));
            string sReplace = GetValueAsText(strArgs.strArg1);
            strReturnValue = GetValueFromString(RegExpReplace(sSearch, sValue, sReplace));
        }
    }
    else if (sProperty == "eq" || sProperty == "neq")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            string sCompare = GetValueAsText(strArgs.strArg0);
            int nResult = sProperty == "eq" ? sValue == sCompare : sValue != sCompare;
            strReturnValue = GetValueFromInt(nResult);
        }
    }
    else if (sProperty == "capitalize")
    {
        strReturnValue = GetValueFromString(CapitalizeWord(sValue));
    }
    else if (sProperty == "append" || sProperty == "prepend")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            string sOther = GetValueAsText(strArgs.strArg0);
            if (sProperty == "append")
                strReturnValue = GetValueFromString(sValue + sOther);
            else
                strReturnValue = GetValueFromString(sOther + sValue);
        }
    }

    strPC.strValue = strReturnValue;
    return strPC;
}


struct PropertyChain GetObjectProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    object oValue = strPC.strValue.oValue;

    struct Value strReturnValue = GetInvalidValue();

    if (sProperty == "name")
    {
        strReturnValue = GetValueFromString(GetName(oValue));
    }
    else if (sProperty == "tag")
    {
        strReturnValue = GetValueFromString(GetTag(oValue));
    }
    else if (sProperty == "resref")
    {
        strReturnValue = GetValueFromString(GetResRef(oValue));
    }
    else if (sProperty == "type")
    {
        strReturnValue = GetValueFromString(GetObjectTypeName(oValue));
    }
    else if (sProperty == "area")
    {
        strReturnValue = GetValueFromObject(GetArea(oValue));
    }
    else if (sProperty == "valid")
    {
        strReturnValue = GetValueFromInt(GetIsObjectValid(oValue));
    }
    else if (sProperty == "inspect")
    {
        strReturnValue = GetValueFromString(InspectObject(oValue));
    }
    else if (sProperty == "ispc")
    {
        strReturnValue = GetValueFromInt(GetIsPlayer(oValue));
    }
    else if (sProperty == "isdm")
    {
        strReturnValue = GetValueFromInt(GetIsDM(oValue));
    }
    else if (sProperty == "isplayerdm")
    {
        strReturnValue = GetValueFromInt(GetIsPlayerDM(oValue));
    }
    else if (sProperty == "dead")
    {
        strReturnValue = GetValueFromInt(GetIsDead(oValue));
    }
    else if (sProperty == "hp")
    {
        strReturnValue = GetValueFromInt(GetCurrentHitPoints(oValue));
    }
    else if (sProperty == "maxhp")
    {
        strReturnValue = GetValueFromInt(GetMaxHitPoints(oValue));
    }
    else if (sProperty == "distance")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_OBJECT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            object oOther = GetValueAsObject(strArgs.strArg0);

            if (!GetIsObjectValid(oValue))
                strReturnValue = GetErrorValue("INVALID_OBJECT:SELF");
            else if (!GetIsObjectValid(oOther))
                strReturnValue = GetErrorValue("INVALID_OBJECT:ARG1");
            else
                strReturnValue = GetValueFromFloat(GetDistanceBetween(oValue, oOther));
        }
    }
    else if (sProperty == "samearea")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_OBJECT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            object oOther = GetValueAsObject(strArgs.strArg0);
            int bSameArea = GetIsObjectValid(oValue) && GetIsObjectValid(oOther) && GetArea(oValue) == GetArea(oOther);
            strReturnValue = GetValueFromInt(bSameArea);
        }
    }
    else if (sProperty == "x" || sProperty == "y" || sProperty == "z")
    {
        vector vPosition = GetPosition(oValue);
        if (sProperty == "x")
            strReturnValue = GetValueFromFloat(vPosition.x);
        else if (sProperty == "y")
            strReturnValue = GetValueFromFloat(vPosition.y);
        else
            strReturnValue = GetValueFromFloat(vPosition.z);
    }
    else if (sProperty == "position")
    {
        struct Arguments strArgs = EvalArgs(strPC, 0, 1, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else if (!GetIsObjectValid(oValue))
            strReturnValue = GetErrorValue("INVALID_OBJECT:SELF");
        else
        {
            int nPrecision = 2;
            if (strArgs.nCount == 1)
                nPrecision = GetValueAsInt(strArgs.strArg0, 2);
            nPrecision = clamp(nPrecision, 0, 9);
            vector vPosition = GetPosition(oValue);
            string sX = ValueToText(FormatValueAsFixed(GetValueFromFloat(vPosition.x), nPrecision));
            string sY = ValueToText(FormatValueAsFixed(GetValueFromFloat(vPosition.y), nPrecision));
            string sZ = ValueToText(FormatValueAsFixed(GetValueFromFloat(vPosition.z), nPrecision));
            strReturnValue = GetValueFromString("[" + sX + "," + sY + "," + sZ + "]");
        }
    }
    else if (sProperty == "facing")
    {
        strReturnValue = GetValueFromFloat(GetFacing(oValue));
    }
    else if (sProperty == "localvar")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else if (!GetIsObjectValid(oValue))
            strReturnValue = GetErrorValue("INVALID_OBJECT:SELF");
        else
        {
            string sType = GetStringLowerCase(GetValueAsTrimmedString(strArgs.strArg0));
            string sVarName = GetValueAsTrimmedString(strArgs.strArg1);
            if (sType == "i")
                strReturnValue = GetValueFromInt(GetLocalInt(oValue, sVarName));
            else if (sType == "f")
                strReturnValue = GetValueFromFloat(GetLocalFloat(oValue, sVarName));
            else if (sType == "s")
                strReturnValue = GetValueFromString(GetLocalString(oValue, sVarName));
            else if (sType == "o")
                strReturnValue = GetValueFromObject(GetLocalObject(oValue, sVarName));
            else if (sType == "j")
                strReturnValue = GetValueFromJson(GetLocalJson(oValue, sVarName));
            else
                strReturnValue = GetErrorValue("INVALID_LOCALVAR_TYPE:" + sType);
        }
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct Value ConvertJsonToValue(json jValue)
{
    switch (JsonGetType(jValue))
    {
        case JSON_TYPE_NULL:
        case JSON_TYPE_OBJECT:
        case JSON_TYPE_ARRAY:
            return GetValueFromJson(jValue);

        case JSON_TYPE_STRING:
            return GetValueFromString(JsonGetString(jValue));

        case JSON_TYPE_INTEGER:
        case JSON_TYPE_BOOL:
            return GetValueFromInt(JsonGetInt(jValue));

        case JSON_TYPE_FLOAT:
            return GetValueFromFloat(JsonGetFloat(jValue));
    }
    return GetErrorValue("INVALID_JSON_VARIABLE");
}

struct PropertyChain GetJsonProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    json jValue = strPC.strValue.jValue;

    struct Value strReturnValue = GetInvalidValue();

    if (sProperty == "type")
    {
        switch (JsonGetType(jValue))
        {
            case JSON_TYPE_NULL:    strReturnValue = GetValueFromString("null"); break;
            case JSON_TYPE_OBJECT:  strReturnValue = GetValueFromString("object"); break;
            case JSON_TYPE_ARRAY:   strReturnValue = GetValueFromString("array"); break;
            case JSON_TYPE_STRING:  strReturnValue = GetValueFromString("string"); break;
            case JSON_TYPE_INTEGER: strReturnValue = GetValueFromString("int"); break;
            case JSON_TYPE_FLOAT:   strReturnValue = GetValueFromString("float"); break;
            case JSON_TYPE_BOOL:    strReturnValue = GetValueFromString("bool"); break;
            default:                strReturnValue = GetValueFromString("invalid"); break;
        }
    }
    else if (sProperty == "null")
    {
        strReturnValue = GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_NULL);
    }
    else if (sProperty == "object")
    {
        strReturnValue = GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_OBJECT);
    }
    else if (sProperty == "array")
    {
        strReturnValue = GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_ARRAY);
    }
    else if (sProperty == "length")
    {
        strReturnValue = GetValueFromInt(JsonGetLength(jValue));
    }
    else if (sProperty == "has")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_STRING);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else if (JsonGetType(jValue) != JSON_TYPE_OBJECT)
            strReturnValue = GetErrorValue("JSON_NOT_OBJECT");
        else
            strReturnValue = GetValueFromInt(JsonObjectContainsKey(jValue, GetValueAsText(strArgs.strArg0)));
    }
    else if (sProperty == "get")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_STRING, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else if (JsonGetType(jValue) != JSON_TYPE_OBJECT)
            strReturnValue = GetErrorValue("JSON_NOT_OBJECT");
        else
        {
            string sKey = GetValueAsText(strArgs.strArg0);
            if (JsonObjectContainsKey(jValue, sKey))
                strReturnValue = ConvertJsonToValue(JsonObjectGet(jValue, sKey));
            else if (strArgs.nCount == 2)
                strReturnValue = strArgs.strArg1;
            else
                strReturnValue = GetErrorValue("JSON_MISSING_KEY:" + sKey);
        }
    }
    else if (sProperty == "at")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
            strReturnValue = GetErrorValue("JSON_NOT_ARRAY");
        else
        {
            int nLength = JsonGetLength(jValue);
            int nIndex = GetValueAsInt(strArgs.strArg0);

            if (nIndex < 0)
                nIndex = nLength + nIndex;

            if (nIndex >= 0 && nIndex < nLength)
                strReturnValue = ConvertJsonToValue(JsonArrayGet(jValue, nIndex));
            else if (strArgs.nCount == 2)
                strReturnValue = strArgs.strArg1;
            else
                strReturnValue = GetErrorValue("JSON_INDEX_OUT_OF_RANGE:" + IntToString(nIndex));
        }
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct Value GetValueFromNamedColor(string sValue, string sColor)
{
    if (sColor == "black")
        return GetValueFromString(ColorString(sValue, 0,   0,   0));
    else if (sColor == "white")
        return GetValueFromString(ColorString(sValue, 255, 255, 255));
    else if (sColor == "red")
        return GetValueFromString(ColorString(sValue, 255, 0,   0));
    else if (sColor == "lime")
        return GetValueFromString(ColorString(sValue, 0,   255, 0));
    else if (sColor == "blue")
        return GetValueFromString(ColorString(sValue, 0,   0,   255));
    else if (sColor == "yellow")
        return GetValueFromString(ColorString(sValue, 255, 255, 0));
    else if (sColor == "cyan")
        return GetValueFromString(ColorString(sValue, 0,   255, 255));
    else if (sColor == "magenta")
        return GetValueFromString(ColorString(sValue, 255, 0,   255));
    else if (sColor == "silver")
        return GetValueFromString(ColorString(sValue, 192, 192, 192));
    else if (sColor == "grey")
        return GetValueFromString(ColorString(sValue, 128, 128, 128));
    else if (sColor == "maroon")
        return GetValueFromString(ColorString(sValue, 128, 0,   0));
    else if (sColor == "olive")
        return GetValueFromString(ColorString(sValue, 128, 128, 0));
    else if (sColor == "green")
        return GetValueFromString(ColorString(sValue, 0,   128, 0));
    else if (sColor == "purple")
        return GetValueFromString(ColorString(sValue, 128, 0,   128));
    else if (sColor == "teal")
        return GetValueFromString(ColorString(sValue, 0,   128, 128));
    else if (sColor == "navy")
        return GetValueFromString(ColorString(sValue, 0,   0,   128));
    return GetErrorValue("UNKNOWN_COLOR:" + sColor);
}

struct Value GetValueFromHexColor(string sValue, string sColor)
{
    int nColorLen = GetStringLength(sColor);
    if (nColorLen == 4)
    {
        string sRed = GetSubString(sColor, 1, 1);
        string sGreen = GetSubString(sColor, 2, 1);
        string sBlue = GetSubString(sColor, 3, 1);
        return GetValueFromString(ColorString(sValue, HexStringToInt(sRed + sRed), HexStringToInt(sGreen + sGreen), HexStringToInt(sBlue + sBlue)));
    }
    else if (nColorLen == 7)
    {
        int nRed = HexStringToInt(GetSubString(sColor, 1, 2));
        int nGreen = HexStringToInt(GetSubString(sColor, 3, 2));
        int nBlue = HexStringToInt(GetSubString(sColor, 5, 2));
        return GetValueFromString(ColorString(sValue, nRed, nGreen, nBlue));
    }
    return GetErrorValue("INVALID_HEX_COLOR:" + sColor);
}

struct PropertyChain GetSharedProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;

    struct Value strReturnValue = GetInvalidValue();

    if (sProperty == "color")
    {
        int nNumParameters = GetParameterCount(strPC);
        if (nNumParameters == 1)
        {
            struct Arguments strArgs = EvalOneArg(strPC);
            if (IsErrorValue(strArgs.strError))
                strReturnValue = strArgs.strError;
            else
            {
                string sValue = ValueToText(strPC.strValue);
                string sColor = GetStringLowerCase(GetValueAsTrimmedString(strArgs.strArg0));
                if (GetStringLeft(sColor, 1) == "#")
                    strReturnValue = GetValueFromHexColor(sValue, sColor);
                else
                    strReturnValue = GetValueFromNamedColor(sValue, sColor);
            }
        }
        else if (nNumParameters == 3)
        {
            struct Arguments strArgs = EvalThreeArgs(strPC, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                strReturnValue = strArgs.strError;
            else
                strReturnValue = GetValueFromString(ColorString(ValueToText(strPC.strValue), GetValueAsInt(strArgs.strArg0), GetValueAsInt(strArgs.strArg1), GetValueAsInt(strArgs.strArg2)));
        }
        else
        {
            strReturnValue = GetErrorValue("ARITY:EXPECTED_1_OR_3_ARGUMENTS");
        }
    }
    else if (sProperty == "padleft" || sProperty == "padright")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            int nLength = GetValueAsInt(strArgs.strArg0);
            string sPadding = " ";
            if (strArgs.nCount >= 2)
                sPadding = GetValueAsText(strArgs.strArg1, " ");
            if (sProperty == "padleft")
                strReturnValue = GetValueFromString(LeftPadString(ValueToText(strPC.strValue), nLength, sPadding));
            else
                strReturnValue = GetValueFromString(RightPadString(ValueToText(strPC.strValue), nLength, sPadding));
        }
    }
    else if (sProperty == "int")
    {
        strReturnValue = CastValueToAuxType(strPC.strValue, NWNX_VM_AUXTYPE_INT);
    }
    else if (sProperty == "float")
    {
        strReturnValue = CastValueToAuxType(strPC.strValue, NWNX_VM_AUXTYPE_FLOAT);
    }
    else if (sProperty == "string")
    {
        strReturnValue = CastValueToAuxType(strPC.strValue, NWNX_VM_AUXTYPE_STRING);
    }
    else if (sProperty == "fixed")
    {
        struct Arguments strArgs = EvalArgs(strPC, 0, 1, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            strReturnValue = strArgs.strError;
        else
        {
            int nPrecision = 2;
            if (strArgs.nCount == 1)
                nPrecision = GetValueAsInt(strArgs.strArg0, 2);
            strReturnValue = FormatValueAsFixed(strPC.strValue, nPrecision);
        }
    }
    else if (sProperty == "hex")
    {
        strReturnValue = FormatValueAsHex(strPC.strValue);
    }
    else if (sProperty == "bool" || sProperty == "boolean")
    {
        strReturnValue = FormatValueAsBoolean(strPC.strValue);
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct Value HandleMetaPrimitive(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "int")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;
        return CastValueToAuxType(strArgs.strArg0, NWNX_VM_AUXTYPE_INT);
    }

    if (sMetaName == "float")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;
        return CastValueToAuxType(strArgs.strArg0, NWNX_VM_AUXTYPE_FLOAT);
    }

    if (sMetaName == "object")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;
        return CastValueToAuxType(strArgs.strArg0, NWNX_VM_AUXTYPE_OBJECT);
    }

    if (sMetaName == "string")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;
        return CastValueToAuxType(strArgs.strArg0, NWNX_VM_AUXTYPE_STRING);
    }

    return GetInvalidValue();
}

struct Value HandleMetaFunction(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "fn")
    {
        int nParameterCount = GetParameterCount(strPC);
        if (nParameterCount < 2)
            return GetErrorValue("FN_USAGE:@fn(#name, $arg..., body)");

        string sFunctionName = GetStringLowerCase(GetRawParameterText(strPC, 0));
        if (!IsSymbol(sFunctionName, DAZSCRIPT_FUNCTION_SYMBOL))
            return GetErrorValue("INVALID_FUNCTION_NAME:" + sFunctionName);

        json jArgs = JsonArray();
        int nIndex, nLast = nParameterCount - 1;
        for (nIndex = 1; nIndex < nLast; nIndex++)
        {
            string sAlias = GetRawParameterText(strPC, nIndex);
            if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("FUNCTION_PARAMETER_IS_NON_ALIAS:" + sAlias);
            if (JsonArrayContainsString(jArgs, sAlias))
                return GetErrorValue("DUPLICATE_FUNCTION_PARAMETER:" + sAlias);

            JsonArrayInsertStringInplace(jArgs, sAlias);
        }

        string sBody = GetRawParameterText(strPC, nLast);
        json jCompiledBody = CompileTemplate(sBody);

        if (JsonGetType(jCompiledBody) != JSON_TYPE_ARRAY)
            return GetErrorValue("INVALID_FUNCTION_BODY:" + sFunctionName);

        json jFunction = JsonObject();
        JsonObjectSetInplace(jFunction, DAZSCRIPT_FUNCTION_ARGS, jArgs);
        JsonObjectSetStringInplace(jFunction, DAZSCRIPT_FUNCTION_BODY, sBody);
        JsonObjectSetInplace(jFunction, DAZSCRIPT_FUNCTION_BODY_COMPILED, jCompiledBody);
        JsonObjectSetInplace(strPC.jStack, sFunctionName, jFunction);

        return GetValueFromString();
    }

    return GetInvalidValue();
}

struct Value HandleMetaControlFlow(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "if")
    {
        struct Value strError = CheckArity(strPC, 3, 3);
        if (IsErrorValue(strError))
            return strError;

        struct Value strCondition = EvalCompiledParameter(strPC, 0);
        if (IsErrorValue(strCondition))
            return strCondition;

        return EvalCompiledParameter(strPC, ValueToBoolish(strCondition) ? 1 : 2);
    }

    if (sMetaName == "while")
    {
        struct Value strError = CheckArity(strPC, 2, 2);
        if (IsErrorValue(strError))
            return strError;

        string sAccumulator;
        while (TRUE)
        {
            struct Value strConditionResult = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strConditionResult))
                return strConditionResult;

            if (!ValueToBoolish(strConditionResult))
                break;

            struct Value strBodyResult = EvalCompiledParameter(strPC, 1);
            if (IsErrorValue(strBodyResult))
                return strBodyResult;

            sAccumulator += ValueToText(strBodyResult);
        }
        return GetValueFromString(sAccumulator);
    }

    if (sMetaName == "pick")
    {
        struct Value strError = CheckArity(strPC, 1, -1);
        if (IsErrorValue(strError))
            return strError;

        int nNumParameters = GetParameterCount(strPC);
        int nIndex = Random(nNumParameters);
        return EvalCompiledParameter(strPC, nIndex);
    }

    if (sMetaName == "not")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        return GetValueFromInt(!ValueToBoolish(strArgs.strArg0));
    }

    if (sMetaName == "and" || sMetaName == "all")
    {
        struct Value strError = CheckArity(strPC, 1, -1);
        if (IsErrorValue(strError))
            return strError;

        int nIndex, nCount = GetParameterCount(strPC), bResult = TRUE;
        for (nIndex = 0; nIndex < nCount; nIndex++)
        {
            struct Value strParameter = EvalCompiledParameter(strPC, nIndex);
            if (IsErrorValue(strParameter))
                return strParameter;

            if (!ValueToBoolish(strParameter))
            {
                bResult = FALSE;
                break;
            }
        }

        return GetValueFromInt(bResult);
    }

    if (sMetaName == "or" || sMetaName == "any")
    {
        struct Value strError = CheckArity(strPC, 1, -1);
        if (IsErrorValue(strError))
            return strError;

        int nIndex, nCount = GetParameterCount(strPC), bResult = FALSE;
        for (nIndex = 0; nIndex < nCount; nIndex++)
        {
            struct Value strParameter = EvalCompiledParameter(strPC, nIndex);
            if (IsErrorValue(strParameter))
                return strParameter;

            if (ValueToBoolish(strParameter))
            {
                bResult = TRUE;
                break;
            }
        }

        return GetValueFromInt(bResult);
    }

    if (sMetaName == "switch" || sMetaName == "case")
    {
        struct Value strError = CheckArity(strPC, 3, -1);
        if (IsErrorValue(strError))
            return strError;

        int nCount = GetParameterCount(strPC);
        struct Value strSelectorValue = EvalCompiledParameter(strPC, 0);
        if (IsErrorValue(strSelectorValue))
            return strSelectorValue;

        string sSelector = ValueToText(strSelectorValue);
        int nDefaultIndex = -1;

        if (nCount % 2 == 0)
            nDefaultIndex = nCount - 1;

        int nIndex, nEnd = nDefaultIndex == -1 ? nCount : nDefaultIndex, bMatched;
        for (nIndex = 1; nIndex + 1 < nEnd; nIndex += 2)
        {
            struct Value strCaseValue = EvalCompiledParameter(strPC, nIndex);
            if (IsErrorValue(strCaseValue))
                return strCaseValue;

            string sCase = ValueToText(strCaseValue);
            if (sSelector == sCase)
                return EvalCompiledParameter(strPC, nIndex + 1);
        }

        if (nDefaultIndex != -1)
            return EvalCompiledParameter(strPC, nDefaultIndex);

        return GetValueFromString();
    }

    if (sMetaName == "foreachpc")
    {
        struct Value strError = CheckArity(strPC, 2, 2);
        if (IsErrorValue(strError))
            return strError;

        string sAlias = GetRawParameterText(strPC, 0);
        if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
            return GetErrorValue("FOREACHPC_ALIAS_IS_NON_ALIAS:" + sAlias);

        json jCompiledParameters = GetCompiledParameters(strPC);
        json jBody = JsonArrayGet(jCompiledParameters, 1);
        json jFrame = JsonCopyObject(strPC.jStack);
        string sAccumulator = "";

        object oPC = GetFirstPC();
        while (GetIsObjectValid(oPC))
        {
            JsonObjectSetInplace(jFrame, sAlias, MakeStackAliasEntryFromValue(GetValueFromObject(oPC)));
            struct Value strBodyResult = EvalTemplate(jBody, jFrame);

            if (IsErrorValue(strBodyResult))
                return strBodyResult;

            sAccumulator += ValueToText(strBodyResult);
            oPC = GetNextPC();
        }

        return GetValueFromString(sAccumulator);
    }

    return GetInvalidValue();
}

struct Value HandleMetaVariable(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "set")
    {
        struct Value strError = CheckArity(strPC, 2, 2);
        if (IsErrorValue(strError))
            return strError;

        string sAlias = GetRawParameterText(strPC, 0);
        if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
            return GetErrorValue("SET_ALIAS_IS_NON_ALIAS:" + sAlias);

        struct Value strValue = EvalCompiledParameter(strPC, 1);
        if (IsErrorValue(strValue))
            return strValue;

        JsonObjectSetInplace(strPC.jStack, sAlias, MakeStackAliasEntryFromValue(strValue));
        return GetValueFromString();
    }

    if (sMetaName == "unset")
    {
        struct Value strError = CheckArity(strPC, 1, 1);
        if (IsErrorValue(strError))
            return strError;

        string sAlias = GetRawParameterText(strPC, 0);
        if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
            return GetErrorValue("UNSET_ALIAS_IS_NON_ALIAS:" + sAlias);

        JsonObjectDelInplace(strPC.jStack, sAlias);
        return GetValueFromString();
    }

    if (sMetaName == "cast")
    {
        struct Value strError = CheckArity(strPC, 2, 2);
        if (IsErrorValue(strError))
            return strError;

        string sAlias = GetRawParameterText(strPC, 0);
        if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
            return GetErrorValue("CAST_ALIAS_IS_NON_ALIAS:" + sAlias);

        if (!JsonObjectContainsKey(strPC.jStack, sAlias))
            return GetErrorValue("UNKNOWN_ALIAS:" + sAlias);

        string sCast = GetRawParameterText(strPC, 1);
        int nTargetAuxType = GetCastAuxTypeFromName(sCast);

        if (nTargetAuxType == NWNX_VM_AUXTYPE_INVALID)
            return GetErrorValue("INVALID_CAST_TYPE:" + sCast);

        struct Value strCurrentValue = ResolveAliasValue(strPC.jStack, sAlias);
        if (IsErrorValue(strCurrentValue))
            return strCurrentValue;

        struct Value strCastedValue = CastValueToAuxType(strCurrentValue, nTargetAuxType);
        if (IsErrorValue(strCastedValue))
            return strCastedValue;

        JsonObjectSetInplace(strPC.jStack, sAlias, MakeStackAliasEntryFromValue(strCastedValue));
        return GetValueFromString();
    }

    if (sMetaName == "out")
    {
        struct Value strError = CheckArity(strPC, 2, 2);
        if (IsErrorValue(strError))
            return strError;

        string sVarName = GetRawParameterText(strPC, 0);
        if (!IsStackVar(sVarName))
            return GetErrorValue("OUT_ARGUMENT_IS_NON_STACKVAR:" + sVarName);
        if (!JsonObjectContainsKey(strPC.jStack, sVarName))
            return GetErrorValue("UNKNOWN_STACK_VAR:" + sVarName);

        struct Value strValue = EvalCompiledParameter(strPC, 1);
        if (IsErrorValue(strValue))
            return strValue;

        json jStackVar = JsonObjectGet(strPC.jStack, sVarName);
        int nOutAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);
        int nStackLocation = JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY);

        if (nOutAuxType == NWNX_VM_AUXTYPE_INT)
        {
            struct Value strOutValue = CastValueToAuxType(strValue, NWNX_VM_AUXTYPE_INT);
            if (IsErrorValue(strOutValue))
                return GetErrorValue("TYPE_MISMATCH:OUT_NOT_INT");
            NWNX_VM_SetStackIntegerValue(nStackLocation, strOutValue.nValue);
        }
        else if (nOutAuxType == NWNX_VM_AUXTYPE_FLOAT)
        {
            struct Value strOutValue = CastValueToAuxType(strValue, NWNX_VM_AUXTYPE_FLOAT);
            if (IsErrorValue(strOutValue))
                return GetErrorValue("TYPE_MISMATCH:OUT_NOT_FLOAT");
            NWNX_VM_SetStackFloatValue(nStackLocation, strOutValue.fValue);
        }
        else if (nOutAuxType == NWNX_VM_AUXTYPE_OBJECT)
        {
            struct Value strOutValue = CastValueToAuxType(strValue, NWNX_VM_AUXTYPE_OBJECT);
            if (IsErrorValue(strOutValue))
                return GetErrorValue("TYPE_MISMATCH:OUT_NOT_OBJECT");
            NWNX_VM_SetStackObjectValue(nStackLocation, strOutValue.oValue);
        }
        else if (nOutAuxType == NWNX_VM_AUXTYPE_STRING)
        {
            struct Value strOutValue = CastValueToAuxType(strValue, NWNX_VM_AUXTYPE_STRING);
            if (IsErrorValue(strOutValue))
                return GetErrorValue("TYPE_MISMATCH:OUT_NOT_STRING");
            NWNX_VM_SetStackStringValue(nStackLocation, strOutValue.sValue);
        }
        else
        {
            return GetErrorValue("TYPE_MISMATCH:OUT_UNSUPPORTED_TYPE");
        }

        return GetValueFromString();
    }

    return GetInvalidValue();
}

struct Value HandleMetaIntrospection(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "exists")
    {
        struct Value strError = CheckArity(strPC, 1, 1);
        if (IsErrorValue(strError))
            return strError;
        return GetValueFromInt(SymbolExists(strPC.jStack, GetRawParameterText(strPC, 0)));
    }

    if (sMetaName == "type")
    {
        struct Value strError = CheckArity(strPC, 1, 1);
        if (IsErrorValue(strError))
            return strError;
        return GetValueFromString(GetSymbolType(strPC.jStack, GetRawParameterText(strPC, 0)));
    }

    if (sMetaName == "debug")
    {
        struct Value strError = CheckArity(strPC, 1, 1);
        if (IsErrorValue(strError))
            return strError;

        string sExpr = GetRawParameterText(strPC, 0);
        struct Value strValue = EvalCompiledParameter(strPC, 0);
        if (IsErrorValue(strValue))
            return strValue;

        string sValue = ValueToText(strValue);
        string sSymbolType = GetSymbolType(strPC.jStack, sExpr);
        string sValueType = InferDebugValueType(sValue);

        string sDebug =
            "expr=\"" + sExpr + "\"" +
            "; symbol_type=" + sSymbolType +
            "; value_type=" + sValueType +
            "; truthy=" + (ValueToBoolish(strValue) ? "TRUE" : "FALSE") +
            "; length=" + IntToString(GetStringLength(sValue)) +
            "; value=\"" + TruncateDebugValue(sValue) + "\"";

        return GetValueFromString(sDebug);
    }

    return GetInvalidValue();
}

struct Value HandleMetaUtility(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "bar")
    {
        struct Arguments strArgs = EvalArgs(strPC, 2, 5, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_ANY, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        float fValue = GetValueAsFloat(strArgs.strArg0);
        float fMax = GetValueAsFloat(strArgs.strArg1);
        int nWidth = STRING_BAR_DEFAULT_WIDTH;
        string sFilled = "#";
        string sEmpty = "-";

        if (strArgs.nCount >= 3)
            nWidth = GetValueAsInt(strArgs.strArg2, STRING_BAR_DEFAULT_WIDTH);
        if (strArgs.nCount >= 4)
            sFilled = GetValueAsText(strArgs.strArg3, "#");
        if (strArgs.nCount >= 5)
            sEmpty = GetValueAsText(strArgs.strArg4, "-");

        return GetValueFromString(MakeBarString(fValue, fMax, nWidth, sFilled, sEmpty));
    }

    if (sMetaName == "roll" || sMetaName == "rollv")
    {
        struct Value strError = CheckArity(strPC, 1, 3);
        if (IsErrorValue(strError))
            return strError;

        int nNumParameters = GetParameterCount(strPC);
        int nCount = 1, nSides = 0, nBonus = 0;
        string sSpec = "";

        if (nNumParameters == 1)
        {
            struct Arguments strArgs = EvalOneArg(strPC);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            sSpec = GetValueAsTrimmedString(strArgs.strArg0);
            json jDice = ParseDiceSpec(sSpec);

            if (JsonGetLength(jDice) >= 3)
            {
                nCount = JsonArrayGetInt(jDice, 0);
                nSides = JsonArrayGetInt(jDice, 1);
                nBonus = JsonArrayGetInt(jDice, 2);
            }
            else
                return GetErrorValue("INVALID_DICE_SPEC:" + sSpec);
        }
        else
        {
            struct Arguments strArgs = EvalArgs(strPC, 2, 3, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            nCount = GetValueAsInt(strArgs.strArg0);
            nSides = GetValueAsInt(strArgs.strArg1);

            if (strArgs.nCount >= 3)
                nBonus = GetValueAsInt(strArgs.strArg2);

            sSpec = IntToString(nCount) + "d" + IntToString(nSides);

            if (nBonus > 0)
                sSpec += "+" + IntToString(nBonus);
            else if (nBonus < 0)
                sSpec += IntToString(nBonus);
        }

        if (nCount <= 0)
            return GetErrorValue("INVALID_DICE_COUNT:" + IntToString(nCount));
        else if (nSides <= 0)
            return GetErrorValue("INVALID_DICE_SIDES:" + IntToString(nSides));
        else
        {
            if (sMetaName == "rollv")
                return GetValueFromString(RollDiceVerbose(nCount, nSides, nBonus, sSpec));
            else
                return GetValueFromInt(RollDiceTotal(nCount, nSides, nBonus));
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaOutput(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "sendmessagetopc" || sMetaName == "tell")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_OBJECT, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        object oPC = GetValueAsObject(strArgs.strArg0);

        if (!GetIsObjectValid(oPC))
            return GetErrorValue("INVALID_OBJECT:ARG1");

        SendMessageToPC(oPC, GetValueAsText(strArgs.strArg1));
        return GetValueFromString();
    }

    if (sMetaName == "print" || sMetaName == "log")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        PrintString(GetValueAsText(strArgs.strArg0));
        return GetValueFromString();
    }

    return GetInvalidValue();
}

struct Value HandleMetaMath(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "add" || sMetaName == "sub" || sMetaName == "mul")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        if (IsValueIntParameter(strArgs.strArg0) && IsValueIntParameter(strArgs.strArg1))
        {
            int nValue0 = GetValueAsInt(strArgs.strArg0);
            int nValue1 = GetValueAsInt(strArgs.strArg1);

            if (sMetaName == "add")
                return GetValueFromInt(nValue0 + nValue1);
            else if (sMetaName == "sub")
                return GetValueFromInt(nValue0 - nValue1);
            else
                return GetValueFromInt(nValue0 * nValue1);
        }
        else
        {
            float fValue0 = GetValueAsFloat(strArgs.strArg0);
            float fValue1 = GetValueAsFloat(strArgs.strArg1);

            if (sMetaName == "add")
                return GetValueFromFloat(fValue0 + fValue1);
            else if (sMetaName == "sub")
                return GetValueFromFloat(fValue0 - fValue1);
            else
                return GetValueFromFloat(fValue0 * fValue1);
        }
    }

    if (sMetaName == "div" || sMetaName == "idiv")
    {
        if (sMetaName == "div")
        {
            struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            float fValue1 = GetValueAsFloat(strArgs.strArg0);
            float fValue2 = GetValueAsFloat(strArgs.strArg1);

            if (fabs(fValue2) > FLOAT_EPSILON)
                return GetValueFromFloat(fValue1 / fValue2);
            else
                return GetErrorValue("DIVISION_BY_ZERO");
        }
        else
        {
            struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            int nValue1 = GetValueAsInt(strArgs.strArg0);
            int nValue2 = GetValueAsInt(strArgs.strArg1);

            if (nValue2 != 0)
                return GetValueFromInt(nValue1 / nValue2);
            else
                return GetErrorValue("DIVISION_BY_ZERO");
        }
    }

    if (sMetaName == "min" || sMetaName == "max")
    {
        struct Value strError = CheckArity(strPC, 1, -1);
        if (IsErrorValue(strError))
            return strError;

        int nIndex, nNumParameters = GetParameterCount(strPC);
        int bAllInt = TRUE, nIntResult = 0;
        float fResult = 0.0;

        for (nIndex = 0; nIndex < nNumParameters; nIndex++)
        {
            struct Value strArg = EvalCompiledParameter(strPC, nIndex);
            if (IsErrorValue(strArg))
                 return strArg;
            if (!IsValueNumericParameter(strArg))
                return GetErrorValue("TYPE_MISMATCH:ARGUMENTS_NOT_NUMERIC");

            float fValue = GetValueAsFloat(strArg);
            if (nIndex == 0)
            {
                fResult = fValue;

                if (IsValueIntParameter(strArg))
                    nIntResult = GetValueAsInt(strArg);
                else
                    bAllInt = FALSE;
            }
            else
            {
                if (IsValueIntParameter(strArg))
                {
                    int nValue = GetValueAsInt(strArg);
                    if (bAllInt)
                    {
                        if (sMetaName == "min" && nValue < nIntResult)
                            nIntResult = nValue;
                        else if (sMetaName == "max" && nValue > nIntResult)
                            nIntResult = nValue;
                    }
                }
                else
                {
                    bAllInt = FALSE;
                }

                if (sMetaName == "min" && fValue < fResult)
                    fResult = fValue;
                else if (sMetaName == "max" && fValue > fResult)
                    fResult = fValue;
            }
        }

        if (bAllInt)
            return GetValueFromInt(nIntResult);
        else
            return GetValueFromFloat(fResult);
    }

    if (sMetaName == "clamp")
    {
        struct Arguments strArgs = EvalThreeArgs(strPC, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;
        if (IsValueIntParameter(strArgs.strArg0) && IsValueIntParameter(strArgs.strArg1) && IsValueIntParameter(strArgs.strArg2))
            return GetValueFromInt(clamp(GetValueAsInt(strArgs.strArg0), GetValueAsInt(strArgs.strArg1), GetValueAsInt(strArgs.strArg2)));
        return GetValueFromFloat(clampf(GetValueAsFloat(strArgs.strArg0), GetValueAsFloat(strArgs.strArg1), GetValueAsFloat(strArgs.strArg2)));
    }

    if (sMetaName == "mod")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        int nValue = GetValueAsInt(strArgs.strArg0);
        int nDivisor = GetValueAsInt(strArgs.strArg1);
        if (nDivisor != 0)
            return GetValueFromInt(nValue % nDivisor);
        else
            return GetErrorValue("DIVISION_BY_ZERO");
    }

    if (sMetaName == "random")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        int nMax = GetValueAsInt(strArgs.strArg0);
        int nMin = 0;

        if (strArgs.nCount >= 2)
        {
            nMin = nMax;
            nMax = GetValueAsInt(strArgs.strArg1);
        }

        if (nMax > nMin)
            return GetValueFromInt(nMin + Random(nMax - nMin));
        else if (nMax == nMin)
            return GetValueFromInt(nMin);
        else
            return GetErrorValue("INVALID_RANDOM_RANGE:" + IntToString(nMin) + "_TO_" + IntToString(nMax));
    }

    return GetInvalidValue();
}

struct Value HandleMetaObject(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "firstpc" || sMetaName == "nextpc")
    {
        if (sMetaName == "firstpc")
            return GetValueFromObject(GetFirstPC());
        else
            return GetValueFromObject(GetNextPC());
    }

    if (sMetaName == "module")
    {
        return GetValueFromObject(GetModule());
    }

    return GetInvalidValue();
}

int IsStackVar(string sVarName)
{
    string sPrefix = GetStringLeft(sVarName, 1);
    return sPrefix != DAZSCRIPT_ALIAS_SYMBOL && sPrefix != DAZSCRIPT_META_SYMBOL && sPrefix != DAZSCRIPT_FUNCTION_SYMBOL;
}

int IsSymbol(string sVarName, string sSymbol)
{
    return GetStringLeft(sVarName, 1) == sSymbol && GetStringLength(sVarName) >= 2;
}

string GetAuxTypeDisplayName(int nAuxType)
{
    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       return "int";
        case NWNX_VM_AUXTYPE_FLOAT:     return "float";
        case NWNX_VM_AUXTYPE_STRING:    return "string";
        case NWNX_VM_AUXTYPE_OBJECT:    return "object";
        case NWNX_VM_AUXTYPE_JSON:      return "json";
        case NWNX_VM_AUXTYPE_VOID:      return "void";
    }

    return "invalid";
}

string GetSymbolType(json jStack, string sName)
{
    sName = trim(sName);

    if (sName == "")
        return "missing";

    string sPrefix = GetStringLeft(sName, 1);

    if (sPrefix == DAZSCRIPT_FUNCTION_SYMBOL)
        sName = GetStringLowerCase(sName);

    if (!JsonObjectContainsKey(jStack, sName))
        return "missing";

    json jEntry = JsonObjectGet(jStack, sName);

    if (sPrefix == DAZSCRIPT_FUNCTION_SYMBOL)
    {
        if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
            return "invalid:function";

        if (JsonGetType(JsonObjectGet(jEntry, DAZSCRIPT_FUNCTION_ARGS)) == JSON_TYPE_ARRAY &&
            JsonGetType(JsonObjectGet(jEntry, DAZSCRIPT_FUNCTION_BODY_COMPILED)) == JSON_TYPE_ARRAY)
        {
            return "function";
        }

        return "invalid:function";
    }

    if (sPrefix == DAZSCRIPT_ALIAS_SYMBOL)
    {
        if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
            return "invalid:alias";

        if (!JsonObjectContainsKey(jEntry, DAZSCRIPT_ALIAS_VALUE))
            return "invalid:alias";

        return "alias:" + GetAuxTypeDisplayName(JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_TYPE));
    }

    if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
        return "invalid";

    if (JsonObjectContainsKey(jEntry, DAZSCRIPT_ALIAS_VALUE))
        return "alias:" + GetAuxTypeDisplayName(JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_TYPE));

    if (JsonObjectContainsKey(jEntry, DAZSCRIPT_FUNCTION_ARGS))
        return "function";

    int nAuxType = JsonObjectGetInt(jEntry, NWNX_VM_TYPE_KEY);

    if (nAuxType == NWNX_VM_AUXTYPE_VOID)
    {
        string sStructName = JsonObjectGetString(jEntry, NWNX_VM_STRUCT_NAME_KEY);
        if (sStructName != "")
            return "struct:" + sStructName;

        return "struct";
    }

    return GetAuxTypeDisplayName(nAuxType);
}

int SymbolExists(json jStack, string sName)
{
    return GetSymbolType(jStack, sName) != "missing";
}

string InferDebugValueType(string sValue)
{
    string sLower = GetStringLowerCase(trim(sValue));

    if (sLower == "true" || sLower == "false")
        return "boolish";

    if (IsInteger(sValue))
        return "int";

    if (IsFloat(sValue))
        return "float";

    if (sLower == STRING_OBJECT_INVALID)
        return "object-invalid";

    if (StringToObject(sValue) != OBJECT_INVALID)
        return "object-ish";

    return "string";
}

string TruncateDebugValue(string sValue)
{
    if (GetStringLength(sValue) <= 256)
        return sValue;
    return GetStringLeft(sValue, 256) + "...";
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
                    string sValue = EvalCompiledExpression(CompileExpression(sKey), jStack);
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

string InspectObject(object oValue)
{
    if (!GetIsObjectValid(oValue))
        return "Object: " + ObjectToString(oValue) + "\n" + "Valid: FALSE";

    vector vPosition = GetPosition(oValue);
    object oArea = GetArea(oValue);
    string sHP = IntToString(GetCurrentHitPoints(oValue)) + "/" + IntToString(GetMaxHitPoints(oValue));
    string sPosition = FloatToString(vPosition.x, 0, 2) + ", " + FloatToString(vPosition.y, 0, 2) + ", " + FloatToString(vPosition.z, 0, 2);

    return "Object: " + ObjectToString(oValue) + "\n" +
            "Name: " + GetName(oValue) + "\n" +
            "Tag: " + GetTag(oValue) + "\n" +
            "ResRef: " + GetResRef(oValue) + "\n" +
            "Type: " + GetObjectTypeName(oValue) + "\n" +
            "Area: " + (GetIsObjectValid(oArea) ? GetName(oArea) : "") + "\n" +
            "HP: " + sHP + "\n" +
            "Position: " + sPosition + "\n" +
            "Facing: " + FloatToString(GetFacing(oValue), 0, 2) + "\n" +
            "Valid: TRUE";
}
