/*
    Script: ef_i_strfmt
    Author: Daz
*/

#include "ef_i_convert"
#include "ef_i_math"
#include "ef_i_string"
#include "ef_i_dataobject"
#include "ef_i_util"
#include "nwnx_util"
#include "nwnx_vm"

const string STRFMT_SCRIPT_NAME                         = "ef_i_strfmt";

const string STRFMT_TEMPLATE_CACHE_PREFIX               = "StringFormatTemplateCache_";
const string STRFMT_PROPERTY_CHAIN_CACHE_PREFIX         = "StringFormatPropertyChainCache_";
const string STRFMT_PARAMETER_CACHE_PREFIX              = "StringFormatParameterCache_";
const string STRFMT_COMPILED_PARAMETER_CACHE_PREFIX     = "StringFormatCompiledParameterCache_";

const string STRFMT_META_SYMBOL                         = "@";
const string STRFMT_ALIAS_SYMBOL                        = "$";
const string STRFMT_FUNCTION_SYMBOL                     = "#";

const int STRFMT_WHILE_SAFETY_LIMIT                     = 100;
const int STRFMT_MAX_EVAL_DEPTH                         = 16;
const int STRFMT_MAX_FUNCTION_CALL_DEPTH                = 8;
const int STRFMT_MAX_OUTPUT_LENGTH                      = 8192;
const int STRFMT_DEBUG_VALUE_MAX_LENGTH                 = 256;

const string STRFMT_INTERNAL_EVAL_DEPTH                 = "__ef_strfmt_eval_depth";
const string STRFMT_INTERNAL_FUNCTION_CALL_DEPTH        = "__ef_strfmt_function_call_depth";
const string STRFMT_INTERNAL_DANGER_DRAGONS             = "__ef_strfmt_danger_dragons";

const string STRFMT_INVALID_STRING                      = "[STRFMT_INVALID_STRING]";
const string STRFMT_EVAL_DEPTH_LIMIT_MESSAGE            = "[EVAL_DEPTH_LIMIT]";
const string STRFMT_OUTPUT_TRUNCATED_MESSAGE            = "[OUTPUT_TRUNCATED]";

const string STRFMT_ALIAS_TYPE                          = "type";
const string STRFMT_ALIAS_VALUE                         = "value";

const string STRFMT_FUNCTION_ARGS                       = "args";
const string STRFMT_FUNCTION_BODY                       = "body";
const string STRFMT_FUNCTION_BODY_COMPILED              = "body_compiled";

const int STRFMT_NODE_LITERAL                           = 0;
const int STRFMT_NODE_EXPR                              = 1;

const int STRFMT_PROPERTY_SEGMENT_PROPERTY              = 0;
const int STRFMT_PROPERTY_SEGMENT_PARAMETERS            = 1;
const int STRFMT_PROPERTY_SEGMENT_COMPILED_PARAMETERS   = 2;

const int STRFMT_EXPR_VAR                               = 0;
const int STRFMT_EXPR_ALIAS                             = 1;
const int STRFMT_EXPR_META                              = 2;
const int STRFMT_EXPR_FUNCTION                          = 3;

const int STRFMT_EXPR_KIND                              = 1;
const int STRFMT_EXPR_BASE_NAME                         = 2;
const int STRFMT_EXPR_CHAIN                             = 3;
const int STRFMT_EXPR_BASE_PARAMETERS                   = 4;
const int STRFMT_EXPR_PROPERTY_PATH                     = 5;
const int STRFMT_EXPR_BASE_COMPILED_PARAMETERS          = 6;

struct Value
{
    int nAuxType;

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
    json jCurrentParameters;
    struct Value strValue;
    string sErrorMessage;
};

string FormatString(string sString, int nDepthOverride = 0);
string Interpret(string sString, int nDepthOverride = 0, json jStack = JSON_NULL, int bDangerDragons = TRUE);

int GetDragonsAreEnabled(json jStack);

string MakeCacheKey(string sPrefix, string sString);
json GetCachedJson(string sPrefix, string sInput);
void SetCachedJson(string sPrefix, string sInput, json jValue);

json MakeStackAliasEntry(string sValue, int nAuxType);
json MakeObjectAliasEntry(object oValue);

int IsParserQuote(string sCharacter);
int IsParserEscapedCharacter(string sString, int nIndex, int nLength);
json SplitTopLevel(string sString, string sDelimiter, int bIncludeEmpty = TRUE);
int FindTopLevelDelimiter(string sString, string sDelimiter);

json CompileTemplate(string sString);
string EvalTemplate(json jTemplate, json jStack);
void JsonArrayInsertLiteralNodeInplace(json jTemplate, string sLiteral);
void JsonArrayInsertExprNodeInplace(json jTemplate, string sExpr);

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
json ParseParameters(string sParameters);
json ResolveCompiledParameters(json jCompiledParameters, json jStack);
json ResolveParameters(struct PropertyChain strPC);
json GetCompiledParameters(struct PropertyChain strPC);
json GetRawParameters(struct PropertyChain strPC);
int GetParameterCount(struct PropertyChain strPC);
string EvalCompiledParameter(struct PropertyChain strPC, int nIndex);

string GetResolvedStringParameter(json jParameters, int nIndex, string sDefault = "");
string GetResolvedTrimmedParameter(json jParameters, int nIndex, string sDefault = "");
int IsResolvedIntParameter(json jParameters, int nIndex);
int IsResolvedNumericParameter(json jParameters, int nIndex);
int IsResolvedObjectParameter(json jParameters, int nIndex);
int GetResolvedIntParameter(json jParameters, int nIndex, int nDefault = 0);
float GetResolvedFloatParameter(json jParameters, int nIndex, float fDefault = 0.0);
object GetResolvedObjectParameter(json jParameters, int nIndex, object oDefault = OBJECT_INVALID);
int AreResolvedIntParameters(json jParameters, int nCount);
int AreResolvedNumericParameters(json jParameters, int nCount);

struct Value GetValueFromStackLocation(int nAuxType, int nStackLocation);
struct Value GetValueFromInt(int nValue = 0);
struct Value GetValueFromFloat(float fValue = 0.0f);
struct Value GetValueFromString(string sValue = "");
struct Value GetValueFromObject(object oValue = OBJECT_INVALID);
struct Value GetValueFromJson(json jValue = JSON_NULL);

string RenderAsString(struct Value strValue);
string FormatAsFixed(struct Value strValue, int nPrecision);
string FormatAsHex(struct Value strValue);
string FormatAsBoolean(struct Value strValue);
string ClampOutputString(string sValue);

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
string GetAuxTypeDisplayName(int nAuxType);
string GetSymbolType(json jStack, string sName);
int SymbolExists(json jStack, string sName);
string InferDebugValueType(string sValue);
string TruncateDebugValue(string sValue);
string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "");
string InspectObject(object oValue);

string FormatString(string sString, int nDepthOverride = 0)
{
    return Interpret(sString, 1 + nDepthOverride, JsonNull(), FALSE);
}

string Interpret(string sString, int nDepthOverride = 0, json jStack = JSON_NULL, int bDangerDragons = TRUE)
{
    if (sString == "")
        return "";

    if (FindSubString(sString, "{", 0) == -1 && FindSubString(sString, "}", 0) == -1)
        return sString;

    json jTemplate = GetCachedJson(STRFMT_TEMPLATE_CACHE_PREFIX, sString);
    if (!JsonGetType(jTemplate))
    {
        jTemplate = CompileTemplate(sString);
        SetCachedJson(STRFMT_TEMPLATE_CACHE_PREFIX, sString, jTemplate);
    }

    if (!JsonGetType(jStack))
        jStack = NWNX_VM_GetStackVariables(1 + nDepthOverride);

    JsonObjectSetIntInplace(jStack, STRFMT_INTERNAL_DANGER_DRAGONS, bDangerDragons);

    return EvalTemplate(jTemplate, jStack);
}

int GetDragonsAreEnabled(json jStack)
{
    return JsonObjectGetInt(jStack, STRFMT_INTERNAL_DANGER_DRAGONS);
}

string MakeCacheKey(string sPrefix, string sString)
{
    return sPrefix + sString;
}

json GetCachedJson(string sPrefix, string sInput)
{
    return GetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), MakeCacheKey(sPrefix, sInput));
}

void SetCachedJson(string sPrefix, string sInput, json jValue)
{
    SetLocalJson(GetDataObject(STRFMT_SCRIPT_NAME), MakeCacheKey(sPrefix, sInput), jValue);
}

json MakeStackAliasEntry(string sValue, int nAuxType)
{
    json jEntry = JsonObject();
    JsonObjectSetStringInplace(jEntry, STRFMT_ALIAS_VALUE, sValue);
    JsonObjectSetIntInplace(jEntry, STRFMT_ALIAS_TYPE, nAuxType);
    return jEntry;
}

json MakeObjectAliasEntry(object oValue)
{
    return MakeStackAliasEntry("0x" + ObjectToString(oValue), NWNX_VM_AUXTYPE_OBJECT);
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

string EvalTemplate(json jTemplate, json jStack)
{
    int nPreviousDepth = JsonObjectGetInt(jStack, STRFMT_INTERNAL_EVAL_DEPTH);

    if (nPreviousDepth >= STRFMT_MAX_EVAL_DEPTH)
        return STRFMT_EVAL_DEPTH_LIMIT_MESSAGE;

    JsonObjectSetIntInplace(jStack, STRFMT_INTERNAL_EVAL_DEPTH, nPreviousDepth + 1);

    string sResult = "";
    int nIndex, nLength = JsonGetLength(jTemplate);

    for (nIndex = 0; nIndex < nLength; nIndex++)
    {
        json jNode = JsonArrayGet(jTemplate, nIndex);
        int nNodeType = JsonArrayGetInt(jNode, 0);

        if (nNodeType == STRFMT_NODE_LITERAL)
        {
            sResult += JsonArrayGetString(jNode, 1);
        }
        else if (nNodeType == STRFMT_NODE_EXPR)
        {
            sResult += EvalCompiledExpression(jNode, jStack);
        }

        if (GetStringLength(sResult) > STRFMT_MAX_OUTPUT_LENGTH)
        {
            sResult = ClampOutputString(sResult);
            JsonObjectSetIntInplace(jStack, STRFMT_INTERNAL_EVAL_DEPTH, nPreviousDepth);
            return sResult;
        }
    }

    JsonObjectSetIntInplace(jStack, STRFMT_INTERNAL_EVAL_DEPTH, nPreviousDepth);
    return sResult;
}

void JsonArrayInsertLiteralNodeInplace(json jTemplate, string sLiteral)
{
    if (sLiteral == "")
        return;

    json jNode = JsonArray();
    JsonArrayInsertIntInplace(jNode, STRFMT_NODE_LITERAL);
    JsonArrayInsertStringInplace(jNode, sLiteral);
    JsonArrayInsertInplace(jTemplate, jNode);
}

void JsonArrayInsertExprNodeInplace(json jTemplate, string sExpr)
{
    JsonArrayInsertInplace(jTemplate, CompileExpression(sExpr));
}

json CompileExpression(string sExpr)
{
    sExpr = trim(sExpr);

    int nPropertyPosition = FindTopLevelDelimiter(sExpr, ">");
    string sBase, sPropertyPath;

    if (nPropertyPosition == -1)
    {
        sBase = sExpr;
    }
    else
    {
        sBase = trim(GetStringLeft(sExpr, nPropertyPosition));
        sPropertyPath = trim(GetSubString(sExpr, nPropertyPosition + 1, GetStringLength(sExpr) - nPropertyPosition - 1));
    }

    int nKind = STRFMT_EXPR_VAR;
    string sBaseName = sBase, sBaseParameters, sPrefix = GetStringLeft(sBase, 1);
    json jBaseCompiledParameters = JsonArray();

    if (sPrefix == STRFMT_META_SYMBOL)
    {
        nKind = STRFMT_EXPR_META;
        json jBase = CompilePropertySegment(GetSubString(sBase, 1, GetStringLength(sBase) - 1));
        sBaseName = JsonArrayGetString(jBase, STRFMT_PROPERTY_SEGMENT_PROPERTY);
        sBaseParameters = JsonArrayGetString(jBase, STRFMT_PROPERTY_SEGMENT_PARAMETERS);
        jBaseCompiledParameters = JsonArrayGet(jBase, STRFMT_PROPERTY_SEGMENT_COMPILED_PARAMETERS);
    }
    else if (sPrefix == STRFMT_ALIAS_SYMBOL)
    {
        nKind = STRFMT_EXPR_ALIAS;
        sBaseName = sBase;
    }
    else if (sPrefix == STRFMT_FUNCTION_SYMBOL)
    {
        nKind = STRFMT_EXPR_FUNCTION;
        json jBase = CompilePropertySegment(sBase);
        sBaseName = JsonArrayGetString(jBase, STRFMT_PROPERTY_SEGMENT_PROPERTY);
        sBaseParameters = JsonArrayGetString(jBase, STRFMT_PROPERTY_SEGMENT_PARAMETERS);
        jBaseCompiledParameters = JsonArrayGet(jBase, STRFMT_PROPERTY_SEGMENT_COMPILED_PARAMETERS);
    }

    json jChain = JsonArray();

    if (sPropertyPath != "")
        jChain = CompilePropertyChain(sPropertyPath);

    json jExpr = JsonArray();
    JsonArrayInsertIntInplace(jExpr, STRFMT_NODE_EXPR);
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
    return RenderAsString(EvalCompiledExpressionToValue(jExpr, jStack));
}

struct Value EvalCompiledExpressionToValue(json jExpr, json jStack)
{
    int nKind = JsonArrayGetInt(jExpr, STRFMT_EXPR_KIND);
    string sBaseName = JsonArrayGetString(jExpr, STRFMT_EXPR_BASE_NAME);
    json jChain = JsonArrayGet(jExpr, STRFMT_EXPR_CHAIN);
    string sBaseParameters = JsonArrayGetString(jExpr, STRFMT_EXPR_BASE_PARAMETERS);
    string sPropertyPath = JsonArrayGetString(jExpr, STRFMT_EXPR_PROPERTY_PATH);
    json jBaseCompiledParameters = JsonArrayGet(jExpr, STRFMT_EXPR_BASE_COMPILED_PARAMETERS);
    int bDangerDragons = GetDragonsAreEnabled(jStack);

    struct Value strValue;

    if (nKind == STRFMT_EXPR_VAR)
        strValue = GetStackValue(jStack, sBaseName);
    else if (bDangerDragons)
    {
        if (nKind == STRFMT_EXPR_ALIAS)
            strValue = ResolveAliasValue(jStack, sBaseName);
        else if (nKind == STRFMT_EXPR_META)
            strValue = ResolveMetaValue(jStack, sBaseName, sBaseParameters, jBaseCompiledParameters);
        else if (nKind == STRFMT_EXPR_FUNCTION)
            strValue = ResolveFunctionValue(jStack, sBaseName, sBaseParameters, jBaseCompiledParameters);
    }

    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        return GetValueFromString("[INVALID_EXPR:" + sBaseName + "]");

    if (JsonGetLength(jChain) > 0)
    {
        struct PropertyChain strPC;
        strPC.jStack = jStack;
        strPC.sBaseVarName = sBaseName;
        strPC.sFullPropertyPath = sPropertyPath;
        strPC.strValue = strValue;

        strPC = EvalCompiledPropertyChain(strPC, jChain);

        if (strPC.strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
            return GetValueFromString("[INVALID_PROPERTY_CHAIN:" + sBaseName+ ">" + sPropertyPath + " -> FAILED@" + strPC.sCurrentProperty + "]" + strPC.sErrorMessage);

        strValue = strPC.strValue;
    }

    return strValue;
}

struct Value GetStackValue(json jStack, string sVarName)
{
    if (!JsonObjectContainsKey(jStack, sVarName))
        return GetValueFromString("[MISSING_VAR:" + sVarName + "]");

    json jStackVar = JsonObjectGet(jStack, sVarName);

    if (JsonGetType(jStackVar) != JSON_TYPE_OBJECT)
        return GetValueFromString("[INVALID_STACK_VAR:" + sVarName + "]");

    int nAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);
    if (nAuxType == NWNX_VM_AUXTYPE_VOID)
        return GetValueFromString(DumpStruct(jStack, sVarName, JsonObjectGetString(jStackVar, NWNX_VM_STRUCT_NAME_KEY)));

    return GetValueFromStackLocation(nAuxType, JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY));
}

struct Value ResolveAliasValue(json jStack, string sAliasName)
{
    if (!JsonObjectContainsKey(jStack, sAliasName))
        return GetValueFromString("[MISSING_ALIAS:" + sAliasName + "]");

    json jEntry = JsonObjectGet(jStack, sAliasName);
    int nAuxType = JsonObjectGetInt(jEntry, STRFMT_ALIAS_TYPE);
    string sValue = JsonObjectGetString(jEntry, STRFMT_ALIAS_VALUE);

    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:    return GetValueFromInt(StringToInt(sValue));
        case NWNX_VM_AUXTYPE_FLOAT:  return GetValueFromFloat(StringToFloat(sValue));
        case NWNX_VM_AUXTYPE_OBJECT: return GetValueFromObject(StringToObject(sValue));
    }

    return GetValueFromString(sValue);
}

struct Value ResolveMetaValue(json jStack, string sMetaName, string sBaseParameters, json jBaseCompiledParameters)
{
    struct PropertyChain strMeta;
    strMeta.jStack = jStack;
    strMeta.sCurrentProperty = sMetaName;
    strMeta.sCurrentParameters = sBaseParameters;
    strMeta.jCurrentParameters = jBaseCompiledParameters;

    struct Value strReturnValue;

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaPrimitive(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaFunction(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaControlFlow(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaVariable(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaIntrospection(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaUtility(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaOutput(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaMath(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strReturnValue = HandleMetaObject(strMeta, sMetaName);

    if (strReturnValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        return GetValueFromString("[UNKNOWN_META:" + sMetaName + "]");

    return strReturnValue;
}

struct Value ResolveFunctionValue(json jStack, string sFunctionName, string sBaseParameters, json jBaseCompiledParameters)
{
    json jFunction = JsonObjectGet(jStack, sFunctionName);

    if (JsonGetType(jFunction) != JSON_TYPE_OBJECT)
        return GetValueFromString("[UNKNOWN_FUNCTION:" + sFunctionName + "]");

    json jArgNames = JsonObjectGet(jFunction, STRFMT_FUNCTION_ARGS);
    json jBody = JsonObjectGet(jFunction, STRFMT_FUNCTION_BODY_COMPILED);

    if (JsonGetType(jBody) != JSON_TYPE_ARRAY)
        return GetValueFromString("[INVALID_FUNCTION_BODY:" + sFunctionName + "]");

    int nFunctionDepth = JsonObjectGetInt(jStack, STRFMT_INTERNAL_FUNCTION_CALL_DEPTH);
    if (nFunctionDepth >= STRFMT_MAX_FUNCTION_CALL_DEPTH)
        return GetValueFromString("[FUNCTION_DEPTH_LIMIT:" + sFunctionName + "]");

    JsonObjectSetIntInplace(jStack, STRFMT_INTERNAL_FUNCTION_CALL_DEPTH, nFunctionDepth + 1);

    struct PropertyChain strFunction;
    strFunction.jStack = jStack;
    strFunction.sCurrentProperty = sFunctionName;
    strFunction.sCurrentParameters = sBaseParameters;
    strFunction.jCurrentParameters = jBaseCompiledParameters;

    json jValues = ResolveParameters(strFunction);

    JsonObjectSetIntInplace(jStack, STRFMT_INTERNAL_FUNCTION_CALL_DEPTH, nFunctionDepth);

    if (JsonGetLength(jValues) != JsonGetLength(jArgNames))
        return GetValueFromString("[FUNCTION_ARITY:" + sFunctionName + "]");

    json jFrame = JsonCopyObject(jStack);

    JsonObjectSetIntInplace(jFrame, STRFMT_INTERNAL_FUNCTION_CALL_DEPTH, nFunctionDepth + 1);

    int nIndex, nNumArgs = JsonGetLength(jArgNames);
    for (nIndex = 0; nIndex < nNumArgs; nIndex++)
    {
        string sArgName = JsonArrayGetString(jArgNames, nIndex);
        string sArgValue = JsonArrayGetString(jValues, nIndex);

        int nAuxType = NWNX_VM_AUXTYPE_STRING;
        if (IsInteger(sArgValue))
        {
            nAuxType = NWNX_VM_AUXTYPE_INT;
        }
        else if (IsFloat(sArgValue))
        {
            nAuxType = NWNX_VM_AUXTYPE_FLOAT;
        }
        else if (IsObjectString(sArgValue))
        {
            nAuxType = NWNX_VM_AUXTYPE_OBJECT;
        }

        JsonObjectSetInplace(jFrame, sArgName, MakeStackAliasEntry(sArgValue, nAuxType));
    }

    return GetValueFromString(EvalTemplate(jBody, jFrame));
}

json CompilePropertyChain(string sPropertyPath)
{
    sPropertyPath = trim(sPropertyPath);

    json jCached = GetCachedJson(STRFMT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath);
    if (JsonGetType(jCached) == JSON_TYPE_ARRAY)
        return jCached;

    json jRawSegments = SplitTopLevel(sPropertyPath, ">", TRUE);
    json jCompiledSegments = JsonArray();
    int nSegment, nNumSegments = JsonGetLength(jRawSegments);

    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        JsonArrayInsertInplace(jCompiledSegments, CompilePropertySegment(JsonArrayGetString(jRawSegments, nSegment)));
    }

    SetCachedJson(STRFMT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath, jCompiledSegments);
    return jCompiledSegments;
}

json CompilePropertySegment(string sPropertySegment)
{
    sPropertySegment = trim(sPropertySegment);

    string sQuoteChar = "";
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

    string sProperty;
    string sParameters = "";

    if (nParameterStart == -1)
    {
        sProperty = sPropertySegment;
    }
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

    json jSegment = JsonArray();
    JsonArrayInsertStringInplace(jSegment, GetStringLowerCase(sProperty));
    JsonArrayInsertStringInplace(jSegment, sParameters);
    JsonArrayInsertInplace(jSegment, CompileParameters(sParameters));

    return jSegment;
}

struct PropertyChain ApplyCompiledPropertySegment(struct PropertyChain strPC, json jSegment)
{
    strPC.sCurrentProperty = JsonArrayGetString(jSegment, STRFMT_PROPERTY_SEGMENT_PROPERTY);
    strPC.sCurrentParameters = JsonArrayGetString(jSegment, STRFMT_PROPERTY_SEGMENT_PARAMETERS);
    strPC.jCurrentParameters = JsonArrayGet(jSegment, STRFMT_PROPERTY_SEGMENT_COMPILED_PARAMETERS);
    return strPC;
}

struct PropertyChain EvalCompiledPropertyChain(struct PropertyChain strPC, json jSegments)
{
    int nSegment;
    int nNumSegments = JsonGetLength(jSegments);

    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        strPC = GetPropertyValueByType(ApplyCompiledPropertySegment(strPC, JsonArrayGet(jSegments, nSegment)));
        if (strPC.strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
            break;
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
        default: strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID; break;
    }

    if (strPC.strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        strPC = GetSharedProperty(strOriginal);

    return strPC;
}

json CompileParameters(string sParameters)
{
    if (sParameters == "")
        return JsonArray();

    json jCached = GetCachedJson(STRFMT_COMPILED_PARAMETER_CACHE_PREFIX, sParameters);
    if (JsonGetType(jCached) == JSON_TYPE_ARRAY)
        return jCached;

    json jRawParameters = ParseParameters(sParameters);
    json jCompiledParameters = JsonArray();

    int nIndex, nNumParameters = JsonGetLength(jRawParameters);
    for (nIndex = 0; nIndex < nNumParameters; nIndex++)
    {
        JsonArrayInsertInplace(jCompiledParameters, CompileTemplate(JsonArrayGetString(jRawParameters, nIndex)));
    }

    SetCachedJson(STRFMT_COMPILED_PARAMETER_CACHE_PREFIX, sParameters, jCompiledParameters);
    return jCompiledParameters;
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
    int bInQuotes = FALSE, bWasQuoted = FALSE, bLastWasComma = FALSE, bAfterTopLevelQuote = FALSE;
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

                if (nBraceDepth == 0 && nParenDepth == 0)
                {
                    if (trim(sCurrent) == "")
                    {
                        sCurrent = "";
                    }
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
            JsonArrayInsertStringInplace(jParameters, bWasQuoted ? sCurrent : trim(sCurrent));
            sCurrent = "";
            bWasQuoted = FALSE;
            bAfterTopLevelQuote = FALSE;
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

json ResolveCompiledParameters(json jCompiledParameters, json jStack)
{
    json jResolved = JsonArray();
    int nIndex, nNumParameters = JsonGetLength(jCompiledParameters);
    for (nIndex = 0; nIndex < nNumParameters; nIndex++)
    {
        JsonArrayInsertStringInplace(jResolved, EvalTemplate(JsonArrayGet(jCompiledParameters, nIndex), jStack));
    }

    return jResolved;
}

json ResolveParameters(struct PropertyChain str)
{
    return ResolveCompiledParameters(GetCompiledParameters(str), str.jStack);
}

json GetCompiledParameters(struct PropertyChain strPC)
{
    json jCompiledParameters = strPC.jCurrentParameters;
    if (JsonGetType(jCompiledParameters) != JSON_TYPE_ARRAY)
        jCompiledParameters = CompileParameters(strPC.sCurrentParameters);
    return jCompiledParameters;
}

json GetRawParameters(struct PropertyChain strPC)
{
    return ParseParameters(strPC.sCurrentParameters);
}

int GetParameterCount(struct PropertyChain strPC)
{
    return JsonGetLength(GetCompiledParameters(strPC));
}

string EvalCompiledParameter(struct PropertyChain strPC, int nIndex)
{
    json jCompiledParameters = GetCompiledParameters(strPC);
    if (nIndex < 0 || nIndex >= JsonGetLength(jCompiledParameters))
        return "";
    return EvalTemplate(JsonArrayGet(jCompiledParameters, nIndex), strPC.jStack);
}

string GetResolvedStringParameter(json jParameters, int nIndex, string sDefault = "")
{
    if (JsonGetLength(jParameters) <= nIndex)
        return sDefault;
    return JsonArrayGetString(jParameters, nIndex);
}

string GetResolvedTrimmedParameter(json jParameters, int nIndex, string sDefault = "")
{
    return trim(GetResolvedStringParameter(jParameters, nIndex, sDefault));
}

int IsResolvedIntParameter(json jParameters, int nIndex)
{
    if (JsonGetLength(jParameters) <= nIndex)
        return FALSE;
    return IsInteger(GetResolvedTrimmedParameter(jParameters, nIndex));
}

int IsResolvedNumericParameter(json jParameters, int nIndex)
{
    if (JsonGetLength(jParameters) <= nIndex)
        return FALSE;
    return IsNumeric(GetResolvedTrimmedParameter(jParameters, nIndex));
}

int IsResolvedObjectParameter(json jParameters, int nIndex)
{
    if (JsonGetLength(jParameters) <= nIndex)
        return FALSE;
    return IsObjectString(GetResolvedTrimmedParameter(jParameters, nIndex));
}

int GetResolvedIntParameter(json jParameters, int nIndex, int nDefault = 0)
{
    if (!IsResolvedIntParameter(jParameters, nIndex))
        return nDefault;
    return StringToInt(GetResolvedTrimmedParameter(jParameters, nIndex));
}

float GetResolvedFloatParameter(json jParameters, int nIndex, float fDefault = 0.0)
{
    if (!IsResolvedNumericParameter(jParameters, nIndex))
        return fDefault;
    return StringToFloat(GetResolvedTrimmedParameter(jParameters, nIndex));
}

object GetResolvedObjectParameter(json jParameters, int nIndex, object oDefault = OBJECT_INVALID)
{
    if (!IsResolvedObjectParameter(jParameters, nIndex))
        return oDefault;
    object oValue = StringToObject(GetResolvedTrimmedParameter(jParameters, nIndex));
    if (oValue == OBJECT_INVALID)
        return oDefault;
    return oValue;
}

int AreResolvedIntParameters(json jParameters, int nCount)
{
    if (JsonGetLength(jParameters) < nCount)
        return FALSE;
    int nIndex;
    for (nIndex = 0; nIndex < nCount; nIndex++)
    {
        if (!IsResolvedIntParameter(jParameters, nIndex))
            return FALSE;
    }
    return TRUE;
}

int AreResolvedNumericParameters(json jParameters, int nCount)
{
    if (JsonGetLength(jParameters) < nCount)
        return FALSE;
    int nIndex;
    for (nIndex = 0; nIndex < nCount; nIndex++)
    {
        if (!IsResolvedNumericParameter(jParameters, nIndex))
            return FALSE;
    }
    return TRUE;
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

string RenderAsString(struct Value strValue)
{
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return strValue.sValue;
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strValue.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strValue.fValue, 0, 2);
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(strValue.oValue);
        case NWNX_VM_AUXTYPE_JSON:      return JsonDump(strValue.jValue);
    }
    return "[CANNOT_RENDER_AS_STRING:" + AuxTypeToString(strValue.nAuxType) + "]";
}

string FormatAsFixed(struct Value strValue, int nPrecision)
{
    float fValue;
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    fValue = StringToFloat(strValue.sValue); break;
        case NWNX_VM_AUXTYPE_INT:       fValue = IntToFloat(strValue.nValue); break;
        case NWNX_VM_AUXTYPE_FLOAT:     fValue = strValue.fValue; break;
        default: return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->fixed]";
    }
    return FloatToString(fValue, 0, nPrecision);
}

string FormatAsHex(struct Value strValue)
{
    int nValue;
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       nValue = strValue.nValue; break;
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = FloatToInt(strValue.fValue); break;
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(strValue.oValue);
        default: return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->hex]";
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
        case NWNX_VM_AUXTYPE_STRING:    nValue = StringToBoolish(strValue.sValue); break;
        case NWNX_VM_AUXTYPE_OBJECT:    nValue = GetIsObjectValid(strValue.oValue); break;
        default: return "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->boolean]";
    }
    return nValue ? "TRUE" : "FALSE";
}

string ClampOutputString(string sValue)
{
    if (GetStringLength(sValue) <= STRFMT_MAX_OUTPUT_LENGTH)
        return sValue;

    int nSuffixLength = GetStringLength(STRFMT_OUTPUT_TRUNCATED_MESSAGE);
    int nKeepLength = STRFMT_MAX_OUTPUT_LENGTH - nSuffixLength;

    if (nKeepLength < 0)
        nKeepLength = 0;

    return GetStringLeft(sValue, nKeepLength) + STRFMT_OUTPUT_TRUNCATED_MESSAGE;
}

struct PropertyChain GetIntProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    int nValue = strPC.strValue.nValue;

    struct Value strReturnValue;

    if (sProperty == "abs")
    {
        strReturnValue = GetValueFromInt(abs(nValue));
    }
    else if (sProperty == "eq" || sProperty == "neq" || sProperty == "gt" || sProperty == "gte" || sProperty == "lt" || sProperty == "lte")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedIntParameter(jParameters, 0))
        {
            int nCompare = GetResolvedIntParameter(jParameters, 0);

            if (sProperty == "eq")
                strReturnValue = GetValueFromInt(nValue == nCompare);
            else if (sProperty == "neq")
                strReturnValue = GetValueFromInt(nValue != nCompare);
            else if (sProperty == "gt")
                strReturnValue = GetValueFromInt(nValue > nCompare);
            else if (sProperty == "gte")
                strReturnValue = GetValueFromInt(nValue >= nCompare);
            else if (sProperty == "lt")
                strReturnValue = GetValueFromInt(nValue < nCompare);
            else if (sProperty == "lte")
                strReturnValue = GetValueFromInt(nValue <= nCompare);
        }
    }
    else if (sProperty == "min" || sProperty == "max")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedIntParameter(jParameters, 0))
        {
            int nOther = GetResolvedIntParameter(jParameters, 0);
            if (sProperty == "min")
                strReturnValue = GetValueFromInt(nValue < nOther ? nValue : nOther);
            else
                strReturnValue = GetValueFromInt(nValue > nOther ? nValue : nOther);
        }
    }
    else if (sProperty == "clamp")
    {
        json jParameters = ResolveParameters(strPC);
        if (AreResolvedIntParameters(jParameters, 2))
        {
            strReturnValue = GetValueFromInt(clamp(nValue, GetResolvedIntParameter(jParameters, 0), GetResolvedIntParameter(jParameters, 1)));
        }
    }
    else if (sProperty == "mod")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedIntParameter(jParameters, 0))
        {
            int nDivisor = GetResolvedIntParameter(jParameters, 0);
            if (nDivisor != 0)
                strReturnValue = GetValueFromInt(nValue % nDivisor);
        }
    }
    else if (sProperty == "then")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            string sResult = EvalCompiledParameter(strPC, nValue != 0 ? 0 : 1);
            strReturnValue = GetValueFromString(sResult);
        }
    }
    else if (sProperty == "plural")
    {
        if (GetParameterCount(strPC) == 1)
        {
            strReturnValue = GetValueFromString(nValue == 1 ? "" : EvalCompiledParameter(strPC, 0));
        }
        else if (GetParameterCount(strPC) >= 2)
        {
            strReturnValue = GetValueFromString(EvalCompiledParameter(strPC, nValue != 1));
        }
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

    struct Value strReturnValue;

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
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedNumericParameter(jParameters, 0))
        {
            float fCompare = GetResolvedFloatParameter(jParameters, 0);
            float fDiff = fValue - fCompare;
            if (sProperty == "eq")
                strReturnValue = GetValueFromInt(fabs(fDiff) < FLOAT_EPSILON);
            else if (sProperty == "neq")
                strReturnValue = GetValueFromInt(fabs(fDiff) >= FLOAT_EPSILON);
            else if (sProperty == "gt")
                strReturnValue = GetValueFromInt(fDiff > FLOAT_EPSILON);
            else if (sProperty == "gte")
                strReturnValue = GetValueFromInt(fDiff >= -FLOAT_EPSILON);
            else if (sProperty == "lt")
                strReturnValue = GetValueFromInt(fDiff < -FLOAT_EPSILON);
            else if (sProperty == "lte")
                strReturnValue = GetValueFromInt(fDiff <= FLOAT_EPSILON);
        }
    }
    else if (sProperty == "min" || sProperty == "max")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedNumericParameter(jParameters, 0))
        {
            float fOther = GetResolvedFloatParameter(jParameters, 0);
            if (sProperty == "min")
                strReturnValue = GetValueFromFloat(fValue < fOther ? fValue : fOther);
            else
                strReturnValue = GetValueFromFloat(fValue > fOther ? fValue : fOther);
        }
    }
    else if (sProperty == "clamp")
    {
        json jParameters = ResolveParameters(strPC);
        if (AreResolvedNumericParameters(jParameters, 2))
            strReturnValue = GetValueFromFloat(clampf(fValue, GetResolvedFloatParameter(jParameters, 0), GetResolvedFloatParameter(jParameters, 1)));
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct PropertyChain GetStringProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sValue = strPC.strValue.sValue;

    struct Value strReturnValue;

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
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sNeedle = GetResolvedStringParameter(jParameters, 0);
            strReturnValue = GetValueFromInt(FindSubString(sValue, sNeedle, 0) != -1);
        }
    }
    else if (sProperty == "startswith" || sProperty == "prefix")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sPrefix = GetResolvedStringParameter(jParameters, 0);
            strReturnValue = GetValueFromInt(IsStringPrefix(sValue, sPrefix));
        }
    }
    else if (sProperty == "endswith" || sProperty == "suffix")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sSuffix = GetResolvedStringParameter(jParameters, 0);
            strReturnValue = GetValueFromInt(IsStringSuffix(sValue, sSuffix));
        }
    }
    else if (sProperty == "substr" || sProperty == "substring")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedIntParameter(jParameters, 0))
        {
            int nStart = GetResolvedIntParameter(jParameters, 0);
            int nCount = GetStringLength(sValue) - nStart;

            if (IsResolvedIntParameter(jParameters, 1))
                nCount = GetResolvedIntParameter(jParameters, 1);

            strReturnValue = GetValueFromString(GetSubString(sValue, nStart, nCount));
        }
    }
    else if (sProperty == "left" || sProperty == "right")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedIntParameter(jParameters, 0))
        {
            if (sProperty == "left")
                strReturnValue = GetValueFromString(GetStringLeft(sValue, GetResolvedIntParameter(jParameters, 0)));
            else
                strReturnValue = GetValueFromString(GetStringRight(sValue, GetResolvedIntParameter(jParameters, 0)));
        }
    }
    else if (sProperty == "replace")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sSearch = NWNX_Util_RegExpEscape(GetResolvedStringParameter(jParameters, 0));
            string sReplace = GetResolvedStringParameter(jParameters, 1);
            strReturnValue = GetValueFromString(RegExpReplace(sSearch, sValue, sReplace));
        }
    }
    else if (sProperty == "eq" || sProperty == "neq")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sCompare = GetResolvedStringParameter(jParameters, 0);
            int nResult = sProperty == "eq" ? sValue == sCompare : sValue != sCompare;
            strReturnValue = GetValueFromInt(nResult);
        }
    }
    else if (sProperty == "default")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            if (sValue == "")
                strReturnValue = GetValueFromString(EvalCompiledParameter(strPC, 0));
            else
                strReturnValue = strPC.strValue;
        }
    }
    else if (sProperty == "capitalize")
    {
        strReturnValue = GetValueFromString(CapitalizeWord(sValue));
    }
    else if (sProperty == "append" || sProperty == "prepend")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sOther = GetResolvedStringParameter(jParameters, 0);
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

    struct Value strReturnValue;

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
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            object oOther = GetResolvedObjectParameter(jParameters, 0);
            if (GetIsObjectValid(oValue) && GetIsObjectValid(oOther))
                strReturnValue = GetValueFromFloat(GetDistanceBetween(oValue, oOther));
        }
    }
    else if (sProperty == "samearea")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            object oOther = GetResolvedObjectParameter(jParameters, 0);
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
        json jParameters = ResolveParameters(strPC);
        int nPrecision = clamp(GetResolvedIntParameter(jParameters, 0, 2), 0, 9);

        vector vPosition = GetPosition(oValue);
        string sX = FormatAsFixed(GetValueFromFloat(vPosition.x), nPrecision);
        string sY = FormatAsFixed(GetValueFromFloat(vPosition.y), nPrecision);
        string sZ = FormatAsFixed(GetValueFromFloat(vPosition.z), nPrecision);

        strReturnValue = GetValueFromString("[" + sX + "," + sY + "," + sZ + "]");
    }
    else if (sProperty == "facing")
    {
        strReturnValue = GetValueFromFloat(GetFacing(oValue));
    }
    else if (sProperty == "localvar")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sType = GetStringLowerCase(GetResolvedTrimmedParameter(jParameters, 0));
            string sVarName = GetResolvedTrimmedParameter(jParameters, 1);

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
        }
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct PropertyChain GetJsonProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    json jValue = strPC.strValue.jValue;
    struct Value strReturnValue;
    strPC.strValue = strReturnValue;
    return strPC;
}

struct PropertyChain GetSharedProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    struct Value strReturnValue;

    if (sProperty == "color")
    {
        json jParameters = ResolveParameters(strPC);
        int nNumParameters = JsonGetLength(jParameters);

        if (nNumParameters == 1)
        {
            struct Value strValue = strPC.strValue;
            string sColor = GetStringLowerCase(GetResolvedTrimmedParameter(jParameters, 0));

            if (GetStringLeft(sColor, 1) == "#")
            {
                int nColorLen = GetStringLength(sColor);

                if (nColorLen == 4)
                {
                    string sRed = GetSubString(sColor, 1, 1);
                    string sGreen = GetSubString(sColor, 2, 1);
                    string sBlue = GetSubString(sColor, 3, 1);
                    strReturnValue = GetValueFromString(ColorString(RenderAsString(strValue), HexStringToInt(sRed + sRed), HexStringToInt(sGreen + sGreen), HexStringToInt(sBlue + sBlue)));
                }
                else if (nColorLen == 7)
                {
                    int nRed = HexStringToInt(GetSubString(sColor, 1, 2));
                    int nGreen = HexStringToInt(GetSubString(sColor, 3, 2));
                    int nBlue = HexStringToInt(GetSubString(sColor, 5, 2));
                    strReturnValue = GetValueFromString(ColorString(RenderAsString(strValue), nRed, nGreen, nBlue));
                }
                else
                    strPC.sErrorMessage = "[INVALID_HEX_COLOR:" + sColor + "]";
            }
            else
            {
                string sValue = RenderAsString(strValue);
                if (sColor == "black")
                    strReturnValue = GetValueFromString(ColorString(sValue, 0,   0,   0));
                else if (sColor == "white")
                    strReturnValue = GetValueFromString(ColorString(sValue, 255, 255, 255));
                else if (sColor == "red")
                    strReturnValue = GetValueFromString(ColorString(sValue, 255, 0,   0));
                else if (sColor == "lime")
                    strReturnValue = GetValueFromString(ColorString(sValue, 0,   255, 0));
                else if (sColor == "blue")
                    strReturnValue = GetValueFromString(ColorString(sValue, 0,   0,   255));
                else if (sColor == "yellow")
                    strReturnValue = GetValueFromString(ColorString(sValue, 255, 255, 0));
                else if (sColor == "cyan")
                    strReturnValue = GetValueFromString(ColorString(sValue, 0,   255, 255));
                else if (sColor == "magenta")
                    strReturnValue = GetValueFromString(ColorString(sValue, 255, 0,   255));
                else if (sColor == "silver")
                    strReturnValue = GetValueFromString(ColorString(sValue, 192, 192, 192));
                else if (sColor == "grey")
                    strReturnValue = GetValueFromString(ColorString(sValue, 128, 128, 128));
                else if (sColor == "maroon")
                    strReturnValue = GetValueFromString(ColorString(sValue, 128, 0,   0));
                else if (sColor == "olive")
                    strReturnValue = GetValueFromString(ColorString(sValue, 128, 128, 0));
                else if (sColor == "green")
                    strReturnValue = GetValueFromString(ColorString(sValue, 0,   128, 0));
                else if (sColor == "purple")
                    strReturnValue = GetValueFromString(ColorString(sValue, 128, 0,   128));
                else if (sColor == "teal")
                    strReturnValue = GetValueFromString(ColorString(sValue, 0,   128, 128));
                else if (sColor == "navy")
                    strReturnValue = GetValueFromString(ColorString(sValue, 0,   0,   128));
                else
                    strPC.sErrorMessage = "[UNKNOWN_COLOR:" + sColor + "]";
            }
        }
        else if (nNumParameters == 3 && AreResolvedIntParameters(jParameters, 3))
        {
            strReturnValue = GetValueFromString(ColorString(RenderAsString(strPC.strValue),
                GetResolvedIntParameter(jParameters, 0), GetResolvedIntParameter(jParameters, 1), GetResolvedIntParameter(jParameters, 2)));
        }
    }
    else if (sProperty == "padleft" || sProperty == "padright")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedIntParameter(jParameters, 0))
        {
            int nLength = GetResolvedIntParameter(jParameters, 0);
            string sPadding = GetResolvedStringParameter(jParameters, 1, " ");

            if (strPC.sCurrentProperty == "padleft")
                strReturnValue = GetValueFromString(LeftPadString(RenderAsString(strPC.strValue), nLength, sPadding));
            else
                strReturnValue = GetValueFromString(RightPadString(RenderAsString(strPC.strValue), nLength, sPadding));
        }
    }
    else if (sProperty == "int")
    {
        struct Value strValue = strPC.strValue;
        if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
            strReturnValue = strValue;
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
            strReturnValue = GetValueFromInt(FloatToInt(strValue.fValue));
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_STRING)
            strReturnValue = GetValueFromInt(StringToInt(strValue.sValue));
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_OBJECT)
            strReturnValue = GetValueFromInt(HexStringToInt(ObjectToString(strValue.oValue)));
        else
            strPC.sErrorMessage = "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->int]";
    }
    else if (sProperty == "float")
    {
        struct Value strValue = strPC.strValue;
        if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
            strReturnValue = GetValueFromFloat(IntToFloat(strValue.nValue));
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
            strReturnValue = strValue;
        else if (strValue.nAuxType == NWNX_VM_AUXTYPE_STRING)
            strReturnValue = GetValueFromFloat(StringToFloat(strValue.sValue));
        else
            strPC.sErrorMessage = "[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->float]";
    }
    else if (sProperty == "string")
    {
        strReturnValue = GetValueFromString(RenderAsString(strPC.strValue));
    }
    else if (sProperty == "fixed")
    {
        json jParameters = ResolveParameters(strPC);
        int nPrecision = clamp(GetResolvedIntParameter(jParameters, 0, 2), 0, 9);
        strReturnValue = GetValueFromString(FormatAsFixed(strPC.strValue, nPrecision));
    }
    else if (sProperty == "hex")
    {
        strReturnValue = GetValueFromString(FormatAsHex(strPC.strValue));
    }
    else if (sProperty == "bool" || sProperty == "boolean")
    {
        strReturnValue = GetValueFromString(FormatAsBoolean(strPC.strValue));
    }

    strPC.strValue = strReturnValue;
    return strPC;
}

struct Value HandleMetaPrimitive(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "int")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedIntParameter(jParameters, 0))
            strReturnValue = GetValueFromInt(GetResolvedIntParameter(jParameters, 0));
    }
    else if (sMetaName == "float")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedNumericParameter(jParameters, 0))
            strReturnValue = GetValueFromFloat(GetResolvedFloatParameter(jParameters, 0));
    }
    else if (sMetaName == "object")
    {
        json jParameters = ResolveParameters(strPC);
        if (IsResolvedObjectParameter(jParameters, 0))
            strReturnValue = GetValueFromObject(GetResolvedObjectParameter(jParameters, 0));
    }
    else if (sMetaName == "string")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
            strReturnValue = GetValueFromString(GetResolvedStringParameter(jParameters, 0));
    }
    return strReturnValue;
}

struct Value HandleMetaFunction(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "fn")
    {
        json jParameters = GetRawParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sFunctionName = GetStringLowerCase(JsonArrayGetString(jParameters, 0));
            if (GetStringLeft(sFunctionName, 1) == STRFMT_FUNCTION_SYMBOL)
            {
                json jArgs = JsonArray();
                int nIndex, nLast = JsonGetLength(jParameters) - 1;
                for (nIndex = 1; nIndex < nLast; nIndex++)
                {
                    JsonArrayInsertStringInplace(jArgs, JsonArrayGetString(jParameters, nIndex));
                }

                json jFunction = JsonObject();
                JsonObjectSetInplace(jFunction, STRFMT_FUNCTION_ARGS, jArgs);
                JsonObjectSetStringInplace(jFunction, STRFMT_FUNCTION_BODY, JsonArrayGetString(jParameters, nLast));
                JsonObjectSetInplace(jFunction, STRFMT_FUNCTION_BODY_COMPILED, CompileTemplate(JsonArrayGetString(jParameters, nLast)));
                JsonObjectSetInplace(strPC.jStack, sFunctionName, jFunction);
                strReturnValue = GetValueFromString();
            }
        }
    }
    return strReturnValue;
}

struct Value HandleMetaControlFlow(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "if")
    {
        if (GetParameterCount(strPC) >= 3)
        {
            int bCondition = StringToBoolish(EvalCompiledParameter(strPC, 0));
            string sResult = EvalCompiledParameter(strPC, bCondition ? 1 : 2);
            strReturnValue = GetValueFromString(sResult);
        }
    }
    else if (sMetaName == "while")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            string sAccumulator = "";
            int nLimit = STRFMT_WHILE_SAFETY_LIMIT;

            while (nLimit-- > 0)
            {
                string sConditionResult = EvalCompiledParameter(strPC, 0);
                if (!StringToBoolish(sConditionResult))
                    break;

                sAccumulator += EvalCompiledParameter(strPC, 1);

                if (GetStringLength(sAccumulator) > STRFMT_MAX_OUTPUT_LENGTH)
                {
                    sAccumulator = ClampOutputString(sAccumulator);
                    break;
                }
            }

            strReturnValue = GetValueFromString(sAccumulator);
        }
    }
    else if (sMetaName == "pick")
    {
        int nNumParameters = GetParameterCount(strPC);
        if (nNumParameters > 0)
        {
            int nIndex = Random(nNumParameters);
            strReturnValue = GetValueFromString(EvalCompiledParameter(strPC, nIndex));
        }
    }
    else if (sMetaName == "not")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            strReturnValue = GetValueFromInt(!StringToBoolish(EvalCompiledParameter(strPC, 0)));
        }
    }
    else if (sMetaName == "and" || sMetaName == "all")
    {
        int nCount = GetParameterCount(strPC);

        if (nCount >= 1)
        {
            int bResult = TRUE;
            int nIndex;

            for (nIndex = 0; nIndex < nCount; nIndex++)
            {
                if (!StringToBoolish(EvalCompiledParameter(strPC, nIndex)))
                {
                    bResult = FALSE;
                    break;
                }
            }

            strReturnValue = GetValueFromInt(bResult);
        }
    }
    else if (sMetaName == "or" || sMetaName == "any")
    {
        int nCount = GetParameterCount(strPC);

        if (nCount >= 1)
        {
            int bResult = FALSE;
            int nIndex;

            for (nIndex = 0; nIndex < nCount; nIndex++)
            {
                if (StringToBoolish(EvalCompiledParameter(strPC, nIndex)))
                {
                    bResult = TRUE;
                    break;
                }
            }

            strReturnValue = GetValueFromInt(bResult);
        }
    }
    else if (sMetaName == "switch" || sMetaName == "case")
    {
        int nCount = GetParameterCount(strPC);

        if (nCount >= 3)
        {
            string sSelector = EvalCompiledParameter(strPC, 0);
            int nDefaultIndex = -1;

            if (nCount % 2 == 0)
                nDefaultIndex = nCount - 1;

            int nIndex, nEnd = nDefaultIndex == -1 ? nCount : nDefaultIndex;
            int bMatched = FALSE;
            string sResult;

            for (nIndex = 1; nIndex + 1 < nEnd; nIndex += 2)
            {
                string sCase = EvalCompiledParameter(strPC, nIndex);

                if (sSelector == sCase)
                {
                    sResult = EvalCompiledParameter(strPC, nIndex + 1);
                    bMatched = TRUE;
                    break;
                }
            }

            if (!bMatched && nDefaultIndex != -1)
                sResult = EvalCompiledParameter(strPC, nDefaultIndex);

            strReturnValue = GetValueFromString(sResult);
        }
    }
    else if (sMetaName == "foreachpc")
    {
        json jRawParameters = GetRawParameters(strPC);
        if (JsonGetLength(jRawParameters) >= 2)
        {
            string sAlias = JsonArrayGetString(jRawParameters, 0);

            if (GetStringLength(sAlias) >= 2 && GetStringLeft(sAlias, 1) == STRFMT_ALIAS_SYMBOL)
            {
                json jCompiledParameters = GetCompiledParameters(strPC);
                json jBody = JsonArrayGet(jCompiledParameters, 1);
                json jFrame = JsonCopyObject(strPC.jStack);
                string sAccumulator;

                object oPC = GetFirstPC();
                while (GetIsObjectValid(oPC))
                {
                    JsonObjectSetInplace(jFrame, sAlias, MakeObjectAliasEntry(oPC));

                    sAccumulator += EvalTemplate(jBody, jFrame);
                    if (GetStringLength(sAccumulator) > STRFMT_MAX_OUTPUT_LENGTH)
                    {
                        sAccumulator = ClampOutputString(sAccumulator);
                        break;
                    }
                    oPC = GetNextPC();
                }

                strReturnValue = GetValueFromString(sAccumulator);
            }
        }
    }
    return strReturnValue;
}

struct Value HandleMetaVariable(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "set")
    {
        json jParameters = GetRawParameters(strPC);

        if (JsonGetLength(jParameters) >= 2)
        {
            string sAlias = JsonArrayGetString(jParameters, 0);
            if (GetStringLeft(sAlias, 1) == STRFMT_ALIAS_SYMBOL)
            {
                string sValue = EvalCompiledParameter(strPC, 1);

                int nAuxType = NWNX_VM_AUXTYPE_STRING;
                if (IsInteger(sValue))
                    nAuxType = NWNX_VM_AUXTYPE_INT;
                else if (IsFloat(sValue))
                    nAuxType = NWNX_VM_AUXTYPE_FLOAT;
                else if (IsObjectString(sValue))
                    nAuxType = NWNX_VM_AUXTYPE_OBJECT;

                JsonObjectSetInplace(strPC.jStack, sAlias, MakeStackAliasEntry(sValue, nAuxType));
                strReturnValue = GetValueFromString();
            }
        }
    }
    else if (sMetaName == "unset")
    {
        json jParameters = GetRawParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sAlias = JsonArrayGetString(jParameters, 0);
            if (GetStringLeft(sAlias, 1) == STRFMT_ALIAS_SYMBOL)
            {
                JsonObjectDelInplace(strPC.jStack, sAlias);
                strReturnValue = GetValueFromString();
            }
        }
    }
    else if (sMetaName == "cast")
    {
        json jParameters = GetRawParameters(strPC);
        if (JsonGetLength(jParameters) >= 2)
        {
            string sAlias = JsonArrayGetString(jParameters, 0);
            if (GetStringLeft(sAlias, 1) == STRFMT_ALIAS_SYMBOL)
            {
                if (JsonObjectContainsKey(strPC.jStack, sAlias))
                {
                    json jStackVar = JsonObjectGet(strPC.jStack, sAlias);
                    string sCast = JsonArrayGetString(jParameters, 1);
                    if (sCast == "i" || sCast == "int")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, STRFMT_ALIAS_TYPE, NWNX_VM_AUXTYPE_INT));
                    else if (sCast == "f" || sCast == "float")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, STRFMT_ALIAS_TYPE, NWNX_VM_AUXTYPE_FLOAT));
                    else if (sCast == "s" || sCast == "string")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, STRFMT_ALIAS_TYPE, NWNX_VM_AUXTYPE_STRING));
                    else if (sCast == "o" || sCast == "object")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, STRFMT_ALIAS_TYPE, NWNX_VM_AUXTYPE_OBJECT));

                    strReturnValue = GetValueFromString();
                }
            }
        }
    }
    else if (sMetaName == "out")
    {
        json jRawParameters = GetRawParameters(strPC);
        if (JsonGetLength(jRawParameters) >= 2)
        {
            string sVarName = JsonArrayGetString(jRawParameters, 0);
            if (IsStackVar(sVarName) && JsonObjectContainsKey(strPC.jStack, sVarName))
            {
                string sValue = EvalCompiledParameter(strPC, 1);
                json jStackVar = JsonObjectGet(strPC.jStack, sVarName);
                int nOutAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);

                if (nOutAuxType == NWNX_VM_AUXTYPE_INT && IsInteger(sValue))
                    NWNX_VM_SetStackIntegerValue(JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), StringToInt(sValue));
                else if (nOutAuxType == NWNX_VM_AUXTYPE_FLOAT && IsNumeric(sValue))
                    NWNX_VM_SetStackFloatValue(JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), StringToFloat(sValue));
                else if (nOutAuxType == NWNX_VM_AUXTYPE_OBJECT && IsObjectString(sValue))
                    NWNX_VM_SetStackObjectValue(JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), StringToObject(sValue));
                else if (nOutAuxType == NWNX_VM_AUXTYPE_STRING)
                    NWNX_VM_SetStackStringValue(JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY), sValue);

                strReturnValue = GetValueFromString();
            }
        }
    }
    return strReturnValue;
}

struct Value HandleMetaIntrospection(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;

    if (sMetaName == "exists")
    {
        json jParameters = GetRawParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sName = JsonArrayGetString(jParameters, 0);
            strReturnValue = GetValueFromInt(SymbolExists(strPC.jStack, sName));
        }
    }
    else if (sMetaName == "type")
    {
        json jParameters = GetRawParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            string sName = JsonArrayGetString(jParameters, 0);
            strReturnValue = GetValueFromString(GetSymbolType(strPC.jStack, sName));
        }
    }
    else if (sMetaName == "debug")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            json jRawParameters = GetRawParameters(strPC);

            string sExpr = "";
            if (JsonGetLength(jRawParameters) >= 1)
                sExpr = JsonArrayGetString(jRawParameters, 0);

            string sValue = EvalCompiledParameter(strPC, 0);
            string sSymbolType = GetSymbolType(strPC.jStack, sExpr);
            string sValueType = InferDebugValueType(sValue);

            string sDebug =
                "expr=\"" + sExpr + "\"" +
                "; symbol_type=" + sSymbolType +
                "; value_type=" + sValueType +
                "; truthy=" + (StringToBoolish(sValue) ? "TRUE" : "FALSE") +
                "; length=" + IntToString(GetStringLength(sValue)) +
                "; value=\"" + TruncateDebugValue(sValue) + "\"";

            strReturnValue = GetValueFromString(sDebug);
        }
    }

    return strReturnValue;
}

struct Value HandleMetaUtility(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;

    if (sMetaName == "bar")
    {
        json jParameters = ResolveParameters(strPC);
        if (AreResolvedNumericParameters(jParameters, 2))
        {
            float fValue = GetResolvedFloatParameter(jParameters, 0);
            float fMax = GetResolvedFloatParameter(jParameters, 1);
            int nWidth = IsResolvedIntParameter(jParameters, 2) ? GetResolvedIntParameter(jParameters, 2) : STRING_BAR_DEFAULT_WIDTH;
            string sFilled = GetResolvedStringParameter(jParameters, 3, "#");
            string sEmpty = GetResolvedStringParameter(jParameters, 4, "-");

            strReturnValue = GetValueFromString(MakeBarString(fValue, fMax, nWidth, sFilled, sEmpty));
        }
    }
    else if (sMetaName == "roll" || sMetaName == "rollv")
    {
        json jParameters = ResolveParameters(strPC);
        int nCount = 1, nSides = 0, nBonus = 0;
        string sSpec = "";

        if (JsonGetLength(jParameters) == 1)
        {
            sSpec = GetResolvedTrimmedParameter(jParameters, 0);
            json jDice = ParseDiceSpec(sSpec);

            if (JsonGetLength(jDice) >= 3)
            {
                nCount = JsonArrayGetInt(jDice, 0);
                nSides = JsonArrayGetInt(jDice, 1);
                nBonus = JsonArrayGetInt(jDice, 2);
            }
        }
        else if (AreResolvedIntParameters(jParameters, 2))
        {
            nCount = GetResolvedIntParameter(jParameters, 0);
            nSides = GetResolvedIntParameter(jParameters, 1);
            nBonus = IsResolvedIntParameter(jParameters, 2) ? GetResolvedIntParameter(jParameters, 2) : 0;
            sSpec = IntToString(nCount) + "d" + IntToString(nSides);

            if (nBonus > 0)
                sSpec += "+" + IntToString(nBonus);
            else if (nBonus < 0)
                sSpec += IntToString(nBonus);
        }

        if (nSides > 0)
        {
            if (sMetaName == "rollv")
                strReturnValue = GetValueFromString(RollDiceVerbose(nCount, nSides, nBonus, sSpec));
            else
                strReturnValue = GetValueFromInt(RollDiceTotal(nCount, nSides, nBonus));
        }
    }

    return strReturnValue;
}

struct Value HandleMetaOutput(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "sendmessagetopc" || sMetaName == "tell")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 2 && IsResolvedObjectParameter(jParameters, 0))
        {
            object oPC = GetResolvedObjectParameter(jParameters, 0);
            string sMessage = GetResolvedStringParameter(jParameters, 1);

            if (GetIsObjectValid(oPC))
                SendMessageToPC(oPC, sMessage);

            strReturnValue = GetValueFromString();
        }
    }
    else if (sMetaName == "print" || sMetaName == "log")
    {
        json jParameters = ResolveParameters(strPC);
        if (JsonGetLength(jParameters) >= 1)
        {
            PrintString(GetResolvedStringParameter(jParameters, 0));
            strReturnValue = GetValueFromString();
        }
    }
    return strReturnValue;
}

struct Value HandleMetaMath(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "add")
    {
        json jParameters = ResolveParameters(strPC);
        if (AreResolvedIntParameters(jParameters, 2))
            strReturnValue = GetValueFromInt(GetResolvedIntParameter(jParameters, 0) + GetResolvedIntParameter(jParameters, 1));
        else if (AreResolvedNumericParameters(jParameters, 2))
            strReturnValue = GetValueFromFloat(GetResolvedFloatParameter(jParameters, 0) + GetResolvedFloatParameter(jParameters, 1));
    }
    else if (sMetaName == "sub")
    {
        json jParameters = ResolveParameters(strPC);
        if (AreResolvedIntParameters(jParameters, 2))
            strReturnValue = GetValueFromInt(GetResolvedIntParameter(jParameters, 0) - GetResolvedIntParameter(jParameters, 1));
        else if (AreResolvedNumericParameters(jParameters, 2))
            strReturnValue = GetValueFromFloat(GetResolvedFloatParameter(jParameters, 0) - GetResolvedFloatParameter(jParameters, 1));
    }
    else if (sMetaName == "mul")
    {
        json jParameters = ResolveParameters(strPC);
        if (AreResolvedIntParameters(jParameters, 2))
            strReturnValue = GetValueFromInt(GetResolvedIntParameter(jParameters, 0) * GetResolvedIntParameter(jParameters, 1));
        else if (AreResolvedNumericParameters(jParameters, 2))
            strReturnValue = GetValueFromFloat(GetResolvedFloatParameter(jParameters, 0) * GetResolvedFloatParameter(jParameters, 1));
    }
    else if (sMetaName == "div" || sMetaName == "idiv")
    {
        json jParameters = ResolveParameters(strPC);
        if (sMetaName == "div")
        {
            if (AreResolvedNumericParameters(jParameters, 2))
            {
                float fValue1 = GetResolvedFloatParameter(jParameters, 0);
                float fValue2 = GetResolvedFloatParameter(jParameters, 1);
                if (fabs(fValue2) > FLOAT_EPSILON)
                    strReturnValue = GetValueFromFloat(fValue1 / fValue2);
            }
        }
        else
        {
            if (AreResolvedIntParameters(jParameters, 2))
            {
                int nValue1 = GetResolvedIntParameter(jParameters, 0);
                int nValue2 = GetResolvedIntParameter(jParameters, 1);
                if (nValue2 != 0)
                    strReturnValue = GetValueFromInt(nValue1 / nValue2);
            }
        }
    }
    else if (sMetaName == "min" || sMetaName == "max")
    {
        json jParameters = ResolveParameters(strPC);
        int nIndex, nNumParameters = JsonGetLength(jParameters);

        if (nNumParameters >= 1)
        {
            if (AreResolvedIntParameters(jParameters, nNumParameters))
            {
                int nResult = GetResolvedIntParameter(jParameters, 0);
                for (nIndex = 1; nIndex < nNumParameters; nIndex++)
                {
                    int nValue = GetResolvedIntParameter(jParameters, nIndex);
                    if (sMetaName == "min" && nValue < nResult)
                        nResult = nValue;
                    else if (sMetaName == "max" && nValue > nResult)
                        nResult = nValue;
                }
                strReturnValue = GetValueFromInt(nResult);
            }
            else if (AreResolvedNumericParameters(jParameters, nNumParameters))
            {
                float fResult = GetResolvedFloatParameter(jParameters, 0);
                for (nIndex = 1; nIndex < nNumParameters; nIndex++)
                {
                    float fValue = GetResolvedFloatParameter(jParameters, nIndex);
                    if (sMetaName == "min" && fValue < fResult)
                        fResult = fValue;
                    else if (sMetaName == "max" && fValue > fResult)
                        fResult = fValue;
                }
                strReturnValue = GetValueFromFloat(fResult);
            }
        }
    }
    else if (sMetaName == "clamp")
    {
        json jParameters = ResolveParameters(strPC);
        if (AreResolvedIntParameters(jParameters, 3))
            strReturnValue = GetValueFromInt(clamp(GetResolvedIntParameter(jParameters, 0), GetResolvedIntParameter(jParameters, 1), GetResolvedIntParameter(jParameters, 2)));
        else if (AreResolvedNumericParameters(jParameters, 3))
            strReturnValue = GetValueFromFloat(clampf(GetResolvedFloatParameter(jParameters, 0), GetResolvedFloatParameter(jParameters, 1), GetResolvedFloatParameter(jParameters, 2)));
    }
    else if (sMetaName == "mod")
    {
        json jParameters = ResolveParameters(strPC);
        if (AreResolvedIntParameters(jParameters, 2))
        {
            int nValue = GetResolvedIntParameter(jParameters, 0);
            int nDivisor = GetResolvedIntParameter(jParameters, 1);

            if (nDivisor != 0)
                strReturnValue = GetValueFromInt(nValue % nDivisor);
        }
    }
    else if (sMetaName == "random")
    {
        json jParameters = ResolveParameters(strPC);
        int nNumParameters = JsonGetLength(jParameters);
        if (nNumParameters >= 1 && IsResolvedIntParameter(jParameters, 0))
        {
            int nMax = GetResolvedIntParameter(jParameters, 0);
            int nMin = 0;

            if (nNumParameters >= 2 && IsResolvedIntParameter(jParameters, 1))
            {
                nMin = nMax;
                nMax = GetResolvedIntParameter(jParameters, 1);
            }

            if (nMax > nMin)
                strReturnValue = GetValueFromInt(nMin + Random(nMax - nMin));
            else if (nMax == nMin)
                strReturnValue = GetValueFromInt(nMin);
        }
    }
    return strReturnValue;
}

struct Value HandleMetaObject(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "firstpc" || sMetaName == "nextpc")
    {
        if (sMetaName == "firstpc")
            strReturnValue = GetValueFromObject(GetFirstPC());
        else
            strReturnValue = GetValueFromObject(GetNextPC());
    }
    else if (sMetaName == "module")
    {
        strReturnValue = GetValueFromObject(GetModule());
    }
    return strReturnValue;
}

int IsStackVar(string sVarName)
{
    string sPrefix = GetStringLeft(sVarName, 1);
    return sPrefix != STRFMT_ALIAS_SYMBOL && sPrefix != STRFMT_META_SYMBOL && sPrefix != STRFMT_FUNCTION_SYMBOL;
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

    if (sPrefix == STRFMT_FUNCTION_SYMBOL)
        sName = GetStringLowerCase(sName);

    if (!JsonObjectContainsKey(jStack, sName))
        return "missing";

    json jEntry = JsonObjectGet(jStack, sName);

    if (sPrefix == STRFMT_FUNCTION_SYMBOL)
    {
        if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
            return "invalid:function";

        if (JsonGetType(JsonObjectGet(jEntry, STRFMT_FUNCTION_ARGS)) == JSON_TYPE_ARRAY &&
            JsonGetType(JsonObjectGet(jEntry, STRFMT_FUNCTION_BODY_COMPILED)) == JSON_TYPE_ARRAY)
        {
            return "function";
        }

        return "invalid:function";
    }

    if (sPrefix == STRFMT_ALIAS_SYMBOL)
    {
        if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
            return "invalid:alias";

        if (!JsonObjectContainsKey(jEntry, STRFMT_ALIAS_VALUE))
            return "invalid:alias";

        return "alias:" + GetAuxTypeDisplayName(JsonObjectGetInt(jEntry, STRFMT_ALIAS_TYPE));
    }

    if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
        return "invalid";

    if (JsonObjectContainsKey(jEntry, STRFMT_ALIAS_VALUE))
        return "alias:" + GetAuxTypeDisplayName(JsonObjectGetInt(jEntry, STRFMT_ALIAS_TYPE));

    if (JsonObjectContainsKey(jEntry, STRFMT_FUNCTION_ARGS))
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
    if (GetStringLength(sValue) <= STRFMT_DEBUG_VALUE_MAX_LENGTH)
        return sValue;
    return GetStringLeft(sValue, STRFMT_DEBUG_VALUE_MAX_LENGTH) + "...";
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
