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

const string DAZSCRIPT_META_SYMBOL                          = "@";
const string DAZSCRIPT_ALIAS_SYMBOL                         = "$";
const string DAZSCRIPT_FUNCTION_SYMBOL                      = "#";

const int DAZSCRIPT_WHILE_SAFETY_LIMIT                      = 100;
const int DAZSCRIPT_MAX_EVAL_DEPTH                          = 16;
const int DAZSCRIPT_MAX_FUNCTION_CALL_DEPTH                 = 8;
const int DAZSCRIPT_MAX_OUTPUT_LENGTH                       = 8192;
const int DAZSCRIPT_DEBUG_VALUE_MAX_LENGTH                  = 256;

const string DAZSCRIPT_INTERNAL_EVAL_DEPTH                  = "__ef_c_dazscript_eval_depth";
const string DAZSCRIPT_INTERNAL_FUNCTION_CALL_DEPTH         = "__ef_c_dazscript_function_call_depth";

const string DAZSCRIPT_EVAL_DEPTH_LIMIT_MESSAGE             = "[EVAL_DEPTH_LIMIT]";
const string DAZSCRIPT_OUTPUT_TRUNCATED_MESSAGE             = "[OUTPUT_TRUNCATED]";

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

string FormatString(string sString, int nDepthOverride = 0);
string Interpret(string sString, int nDepthOverride = 0, json jStack = JSON_NULL);

string MakeCacheKey(string sPrefix, string sString);
json GetCachedJson(string sPrefix, string sInput);
void SetCachedJson(string sPrefix, string sInput, json jValue);

json MakeStackAliasEntry(string sValue, int nAuxType);
string GetStackAliasStorageString(struct Value strValue);
json MakeStackAliasEntryFromValue(struct Value strValue);
json MakeObjectAliasEntry(object oValue);
json MakeParameterEntry(string sText, int bWasQuoted);

int IsParserQuote(string sCharacter);
int IsParserEscapedCharacter(string sString, int nIndex, int nLength);
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

string GetValueAsString(struct Value strValue, string sDefault = "");
string GetValueAsTrimmedString(struct Value strValue, string sDefault = "");
int IsValueIntParameter(struct Value strValue);
int IsValueNumericParameter(struct Value strValue);
int IsValueObjectParameter(struct Value strValue);
int GetValueAsInt(struct Value strValue, int nDefault = 0);
float GetValueAsFloat(struct Value strValue, float fDefault = 0.0);
object GetValueAsObject(struct Value strValue, object oDefault = OBJECT_INVALID);

int IsInvalidValue(struct Value strValue);
int IsErrorValue(struct Value strValue);
struct Value GetErrorValue(string sMessage);

struct Value GetValueFromStackLocation(int nAuxType, int nStackLocation);
struct Value GetValueFromTypedLiteral(string sValue);
struct Value GetValueFromInt(int nValue = 0);
struct Value GetValueFromFloat(float fValue = 0.0f);
struct Value GetValueFromString(string sValue = "");
struct Value GetValueFromObject(object oValue = OBJECT_INVALID);
struct Value GetValueFromJson(json jValue = JSON_NULL);

string RenderAsString(struct Value strValue);
int ValueToBoolish(struct Value strValue);
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

    return RenderAsString(EvalTemplate(jTemplate, jStack));
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

json MakeStackAliasEntry(string sValue, int nAuxType)
{
    json jEntry = JsonObject();
    JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, sValue);
    JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_TYPE, nAuxType);
    return jEntry;
}

string GetStackAliasStorageString(struct Value strValue)
{
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strValue.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strValue.fValue, 0, 9);
        case NWNX_VM_AUXTYPE_STRING:    return strValue.sValue;
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(strValue.oValue);
        case NWNX_VM_AUXTYPE_JSON:      return JsonDump(strValue.jValue);
    }

    return RenderAsString(strValue);
}

json MakeStackAliasEntryFromValue(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return MakeStackAliasEntry(strValue.sErrorMessage, NWNX_VM_AUXTYPE_STRING);

    return MakeStackAliasEntry(GetStackAliasStorageString(strValue), strValue.nAuxType);
}

json MakeObjectAliasEntry(object oValue)
{
    return MakeStackAliasEntry("0x" + ObjectToString(oValue), NWNX_VM_AUXTYPE_OBJECT);
}

json MakeParameterEntry(string sText, int bWasQuoted)
{
    json jEntry = JsonObject();
    JsonObjectSetStringInplace(jEntry, DAZSCRIPT_PARAMETER_TEXT, sText);
    JsonObjectSetIntInplace(jEntry, DAZSCRIPT_PARAMETER_WAS_QUOTED, bWasQuoted);
    return jEntry;
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

json CompileForcedStringTemplate(string sValue)
{
    json jTemplate = JsonArray();
    JsonArrayInsertForceStringNodeInplace(jTemplate, CompileTemplate(sValue));
    return jTemplate;
}

struct Value EvalTemplate(json jTemplate, json jStack)
{
    int nPreviousDepth = JsonObjectGetInt(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH);

    if (nPreviousDepth >= DAZSCRIPT_MAX_EVAL_DEPTH)
        return GetErrorValue(DAZSCRIPT_EVAL_DEPTH_LIMIT_MESSAGE);

    JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH, nPreviousDepth + 1);

    int nIndex, nLength = JsonGetLength(jTemplate);

    if (nLength == 1)
    {
        json jOnlyNode = JsonArrayGet(jTemplate, 0);
        int nOnlyNodeType = JsonArrayGetInt(jOnlyNode, 0);

        if (nOnlyNodeType == DAZSCRIPT_NODE_EXPR)
        {
            struct Value strOnlyValue = EvalCompiledExpressionToValue(jOnlyNode, jStack);
            JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH, nPreviousDepth);
            return strOnlyValue;
        }

        if (nOnlyNodeType == DAZSCRIPT_NODE_FORCE_STRING)
        {
            json jInnerTemplate = JsonArrayGet(jOnlyNode, 1);
            struct Value strInnerValue = EvalTemplate(jInnerTemplate, jStack);

            JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH, nPreviousDepth);

            if (IsErrorValue(strInnerValue))
                return strInnerValue;

            return GetValueFromString(RenderAsString(strInnerValue));
        }

        if (nOnlyNodeType == DAZSCRIPT_NODE_LITERAL)
        {
            struct Value strLiteralValue = GetValueFromTypedLiteral(JsonArrayGetString(jOnlyNode, 1));
            JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH, nPreviousDepth);
            return strLiteralValue;
        }
    }

    string sResult = "";

    for (nIndex = 0; nIndex < nLength; nIndex++)
    {
        json jNode = JsonArrayGet(jTemplate, nIndex);
        int nNodeType = JsonArrayGetInt(jNode, 0);

        if (nNodeType == DAZSCRIPT_NODE_LITERAL)
        {
            sResult += JsonArrayGetString(jNode, 1);
        }
        else if (nNodeType == DAZSCRIPT_NODE_EXPR)
        {
            struct Value strExpressionValue = EvalCompiledExpressionToValue(jNode, jStack);
            if (IsErrorValue(strExpressionValue))
            {
                JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH, nPreviousDepth);
                return strExpressionValue;
            }

            sResult += RenderAsString(strExpressionValue);
        }
        else if (nNodeType == DAZSCRIPT_NODE_FORCE_STRING)
        {
            json jInnerTemplate = JsonArrayGet(jNode, 1);
            struct Value strInnerValue = EvalTemplate(jInnerTemplate, jStack);

            if (IsErrorValue(strInnerValue))
            {
                JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH, nPreviousDepth);
                return strInnerValue;
            }

            sResult += RenderAsString(strInnerValue);
        }

        if (GetStringLength(sResult) > DAZSCRIPT_MAX_OUTPUT_LENGTH)
        {
            sResult = ClampOutputString(sResult);
            JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH, nPreviousDepth);
            return GetValueFromString(sResult);
        }
    }

    JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_EVAL_DEPTH, nPreviousDepth);
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
    return RenderAsString(EvalCompiledExpressionToValue(jExpr, jStack));
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
    if (nKind == DAZSCRIPT_EXPR_ALIAS)
        strValue = ResolveAliasValue(jStack, sBaseName);
    else if (nKind == DAZSCRIPT_EXPR_META)
        strValue = ResolveMetaValue(jStack, sBaseName, sBaseParameters, jBaseCompiledParameters);
    else if (nKind == DAZSCRIPT_EXPR_FUNCTION)
        strValue = ResolveFunctionValue(jStack, sBaseName, sBaseParameters, jBaseCompiledParameters);


    if (IsErrorValue(strValue))
        return strValue;

    if (IsInvalidValue(strValue))
        return GetErrorValue("[INVALID_EXPR:" + sBaseName + "]");

    if (JsonGetLength(jChain) > 0)
    {
        struct PropertyChain strPC;
        strPC.jStack = jStack;
        strPC.sBaseVarName = sBaseName;
        strPC.sFullPropertyPath = sPropertyPath;
        strPC.strValue = strValue;

        strPC = EvalCompiledPropertyChain(strPC, jChain);

        if (IsErrorValue(strPC.strValue))
            return GetErrorValue("[INVALID_PROPERTY_CHAIN:" + sBaseName + ">" + sPropertyPath + " -> FAILED@" + strPC.sCurrentProperty + "]" + strPC.strValue.sErrorMessage);

        if (IsInvalidValue(strPC.strValue))
            return GetErrorValue("[INVALID_PROPERTY_CHAIN:" + sBaseName + ">" + sPropertyPath + " -> FAILED@" + strPC.sCurrentProperty + "]");

        strValue = strPC.strValue;
    }

    return strValue;
}

struct Value GetStackValue(json jStack, string sVarName)
{
    if (!JsonObjectContainsKey(jStack, sVarName))
        return GetErrorValue("[MISSING_VAR:" + sVarName + "]");

    json jStackVar = JsonObjectGet(jStack, sVarName);

    if (JsonGetType(jStackVar) != JSON_TYPE_OBJECT)
        return GetErrorValue("[INVALID_STACK_VAR:" + sVarName + "]");

    int nAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);
    if (nAuxType == NWNX_VM_AUXTYPE_VOID)
        return GetValueFromString(DumpStruct(jStack, sVarName, JsonObjectGetString(jStackVar, NWNX_VM_STRUCT_NAME_KEY)));

    return GetValueFromStackLocation(nAuxType, JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY));
}

struct Value ResolveAliasValue(json jStack, string sAliasName)
{
    if (!JsonObjectContainsKey(jStack, sAliasName))
        return GetErrorValue("[MISSING_ALIAS:" + sAliasName + "]");

    json jEntry = JsonObjectGet(jStack, sAliasName);
    int nAuxType = JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_TYPE);
    string sValue = JsonObjectGetString(jEntry, DAZSCRIPT_ALIAS_VALUE);

    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:    return GetValueFromInt(StringToInt(sValue));
        case NWNX_VM_AUXTYPE_FLOAT:  return GetValueFromFloat(StringToFloat(sValue));
        case NWNX_VM_AUXTYPE_OBJECT: return GetValueFromObject(StringToObject(sValue));
        case NWNX_VM_AUXTYPE_JSON:   return GetValueFromJson(JsonParse(sValue));
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
        return GetErrorValue("[UNKNOWN_META:" + sMetaName + "]");

    return strReturnValue;
}

struct Value ResolveFunctionValue(json jStack, string sFunctionName, string sBaseParameters, json jBaseCompiledParameters)
{
    json jFunction = JsonObjectGet(jStack, sFunctionName);

    if (JsonGetType(jFunction) != JSON_TYPE_OBJECT)
        return GetErrorValue("[UNKNOWN_FUNCTION:" + sFunctionName + "]");

    json jArgNames = JsonObjectGet(jFunction, DAZSCRIPT_FUNCTION_ARGS);
    json jBody = JsonObjectGet(jFunction, DAZSCRIPT_FUNCTION_BODY_COMPILED);

    if (JsonGetType(jBody) != JSON_TYPE_ARRAY)
        return GetErrorValue("[INVALID_FUNCTION_BODY:" + sFunctionName + "]");

    int nFunctionDepth = JsonObjectGetInt(jStack, DAZSCRIPT_INTERNAL_FUNCTION_CALL_DEPTH);
    if (nFunctionDepth >= DAZSCRIPT_MAX_FUNCTION_CALL_DEPTH)
        return GetErrorValue("[FUNCTION_DEPTH_LIMIT:" + sFunctionName + "]");

    JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_FUNCTION_CALL_DEPTH, nFunctionDepth + 1);

    struct PropertyChain strFunction;
    strFunction.jStack = jStack;
    strFunction.sCurrentProperty = sFunctionName;
    strFunction.sCurrentParameters = sBaseParameters;
    strFunction.jCurrentParameters = jBaseCompiledParameters;

    json jCompiledParameters = GetCompiledParameters(strFunction);

    JsonObjectSetIntInplace(jStack, DAZSCRIPT_INTERNAL_FUNCTION_CALL_DEPTH, nFunctionDepth);

    if (JsonGetLength(jCompiledParameters) != JsonGetLength(jArgNames))
        return GetErrorValue("[FUNCTION_ARITY:" + sFunctionName + "]");

    json jFrame = JsonCopyObject(jStack);

    JsonObjectSetIntInplace(jFrame, DAZSCRIPT_INTERNAL_FUNCTION_CALL_DEPTH, nFunctionDepth + 1);

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

    json jCached = GetCachedJson(DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath);
    if (JsonGetType(jCached) == JSON_TYPE_ARRAY)
        return jCached;

    json jRawSegments = SplitTopLevel(sPropertyPath, ">", TRUE);
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
    int nSegment;
    int nNumSegments = JsonGetLength(jSegments);

    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        strPC = GetPropertyValueByType(ApplyCompiledPropertySegment(strPC, JsonArrayGet(jSegments, nSegment)));
        if (strPC.strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID)
        {
            strPC.strValue = GetErrorValue("[UNKNOWN_PROPERTY:" + strPC.sCurrentProperty + "]");
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
        default: strPC.strValue.nAuxType = NWNX_VM_AUXTYPE_INVALID; break;
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
        return GetErrorValue("[PARAM_INDEX_OUT_OF_RANGE]");
    return EvalTemplate(JsonArrayGet(jCompiledParameters, nIndex), strPC.jStack);
}

int IsInvalidValue(struct Value strValue)
{
    return strValue.nAuxType == NWNX_VM_AUXTYPE_INVALID && !strValue.bError;
}

int IsErrorValue(struct Value strValue)
{
    return strValue.bError;
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

string RenderAsString(struct Value strValue)
{
    if (strValue.bError)
        return strValue.sErrorMessage;

    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return strValue.sValue;
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strValue.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strValue.fValue, 0, 2);
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(strValue.oValue);
        case NWNX_VM_AUXTYPE_JSON:      return JsonDump(strValue.jValue);
    }
    return "[INVALID_VALUE]";
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
    if (GetStringLength(sValue) <= DAZSCRIPT_MAX_OUTPUT_LENGTH)
        return sValue;

    int nSuffixLength = GetStringLength(DAZSCRIPT_OUTPUT_TRUNCATED_MESSAGE);
    int nKeepLength = DAZSCRIPT_MAX_OUTPUT_LENGTH - nSuffixLength;

    if (nKeepLength < 0)
        nKeepLength = 0;

    return GetStringLeft(sValue, nKeepLength) + DAZSCRIPT_OUTPUT_TRUNCATED_MESSAGE;
}

string GetValueAsString(struct Value strValue, string sDefault = "")
{
    if (IsErrorValue(strValue))
        return sDefault;

    return RenderAsString(strValue);
}

string GetValueAsTrimmedString(struct Value strValue, string sDefault = "")
{
    return trim(GetValueAsString(strValue, sDefault));
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

    struct Value strReturnValue;

    if (sProperty == "abs")
    {
        strReturnValue = GetValueFromInt(abs(nValue));
    }
    else if (sProperty == "eq" || sProperty == "neq" || sProperty == "gt" || sProperty == "gte" || sProperty == "lt" || sProperty == "lte")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
            {
                int nCompare = GetValueAsInt(strArg0);

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
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "min" || sProperty == "max")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
            {
                int nOther = GetValueAsInt(strArg0);
                if (sProperty == "min")
                    strReturnValue = GetValueFromInt(nValue < nOther ? nValue : nOther);
                else
                    strReturnValue = GetValueFromInt(nValue > nOther ? nValue : nOther);
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "clamp")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsValueIntParameter(strArg0) && IsValueIntParameter(strArg1))
                strReturnValue = GetValueFromInt(clamp(nValue, GetValueAsInt(strArg0), GetValueAsInt(strArg1)));
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sProperty == "mod")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
            {
                int nDivisor = GetValueAsInt(strArg0);
                if (nDivisor != 0)
                    strReturnValue = GetValueFromInt(nValue % nDivisor);
                else
                    strReturnValue = GetErrorValue("[DIVISION_BY_ZERO]");
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "then")
    {
        if (GetParameterCount(strPC) >= 2)
            strReturnValue = EvalCompiledParameter(strPC, nValue != 0 ? 0 : 1);
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sProperty == "plural")
    {
        if (GetParameterCount(strPC) == 1)
            strReturnValue = nValue == 1 ? GetValueFromString() : EvalCompiledParameter(strPC, 0);
        else if (GetParameterCount(strPC) >= 2)
            strReturnValue = EvalCompiledParameter(strPC, nValue != 1);
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_AT_LEAST_1_ARGUMENT]");
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
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueNumericParameter(strArg0))
            {
                float fCompare = GetValueAsFloat(strArg0);
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
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_NUMERIC]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "min" || sProperty == "max")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueNumericParameter(strArg0))
            {
                float fOther = GetValueAsFloat(strArg0);
                if (sProperty == "min")
                    strReturnValue = GetValueFromFloat(fValue < fOther ? fValue : fOther);
                else
                    strReturnValue = GetValueFromFloat(fValue > fOther ? fValue : fOther);
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_NUMERIC]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "clamp")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsValueNumericParameter(strArg0) && IsValueNumericParameter(strArg1))
                strReturnValue = GetValueFromFloat(clampf(fValue, GetValueAsFloat(strArg0), GetValueAsFloat(strArg1)));
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_NUMERIC]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
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
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else
                strReturnValue = GetValueFromInt(FindSubString(sValue, GetValueAsString(strArg0), 0) != -1);
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "startswith" || sProperty == "prefix")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else
                strReturnValue = GetValueFromInt(IsStringPrefix(sValue, GetValueAsString(strArg0)));
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "endswith" || sProperty == "suffix")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else
                strReturnValue = GetValueFromInt(IsStringSuffix(sValue, GetValueAsString(strArg0)));
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "substr" || sProperty == "substring")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
            {
                int nStart = GetValueAsInt(strArg0);
                int nCount = GetStringLength(sValue) - nStart;

                if (GetParameterCount(strPC) >= 2)
                {
                    struct Value strArg1 = EvalCompiledParameter(strPC, 1);
                    if (IsErrorValue(strArg1))
                        strReturnValue = strArg1;
                    else if (IsValueIntParameter(strArg1))
                        nCount = GetValueAsInt(strArg1);
                    else
                        strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
                }

                if (IsInvalidValue(strReturnValue))
                    strReturnValue = GetValueFromString(GetSubString(sValue, nStart, nCount));
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "left" || sProperty == "right")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
            {
                int nLength = GetValueAsInt(strArg0);
                if (sProperty == "left")
                    strReturnValue = GetValueFromString(GetStringLeft(sValue, nLength));
                else
                    strReturnValue = GetValueFromString(GetStringRight(sValue, nLength));
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "replace")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else
            {
                string sSearch = NWNX_Util_RegExpEscape(GetValueAsString(strArg0));
                string sReplace = GetValueAsString(strArg1);
                strReturnValue = GetValueFromString(RegExpReplace(sSearch, sValue, sReplace));
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sProperty == "eq" || sProperty == "neq")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else
            {
                string sCompare = GetValueAsString(strArg0);
                int nResult = sProperty == "eq" ? sValue == sCompare : sValue != sCompare;
                strReturnValue = GetValueFromInt(nResult);
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "capitalize")
    {
        strReturnValue = GetValueFromString(CapitalizeWord(sValue));
    }
    else if (sProperty == "append" || sProperty == "prepend")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else
            {
                string sOther = GetValueAsString(strArg0);
                if (sProperty == "append")
                    strReturnValue = GetValueFromString(sValue + sOther);
                else
                    strReturnValue = GetValueFromString(sOther + sValue);
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
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
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueObjectParameter(strArg0))
            {
                object oOther = GetValueAsObject(strArg0);
                if (GetIsObjectValid(oValue) && GetIsObjectValid(oOther))
                    strReturnValue = GetValueFromFloat(GetDistanceBetween(oValue, oOther));
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_OBJECT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sProperty == "samearea")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueObjectParameter(strArg0))
            {
                object oOther = GetValueAsObject(strArg0);
                int bSameArea = GetIsObjectValid(oValue) && GetIsObjectValid(oOther) && GetArea(oValue) == GetArea(oOther);
                strReturnValue = GetValueFromInt(bSameArea);
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_OBJECT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
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
        int nPrecision = 2;
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
                nPrecision = GetValueAsInt(strArg0, 2);
        }

        if (IsInvalidValue(strReturnValue))
        {
            nPrecision = clamp(nPrecision, 0, 9);
            vector vPosition = GetPosition(oValue);
            string sX = FormatAsFixed(GetValueFromFloat(vPosition.x), nPrecision);
            string sY = FormatAsFixed(GetValueFromFloat(vPosition.y), nPrecision);
            string sZ = FormatAsFixed(GetValueFromFloat(vPosition.z), nPrecision);

            strReturnValue = GetValueFromString("[" + sX + "," + sY + "," + sZ + "]");
        }
    }
    else if (sProperty == "facing")
    {
        strReturnValue = GetValueFromFloat(GetFacing(oValue));
    }
    else if (sProperty == "localvar")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else
            {
                string sType = GetStringLowerCase(GetValueAsTrimmedString(strArg0));
                string sVarName = GetValueAsTrimmedString(strArg1);

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
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }

    strPC.strValue = strReturnValue;
    return strPC;
}


struct PropertyChain GetJsonProperty(struct PropertyChain strPC)
{
    /* NYI
    string sProperty = strPC.sCurrentProperty;
    json jValue = strPC.strValue.jValue;
    */
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
        int nNumParameters = GetParameterCount(strPC);

        if (nNumParameters == 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
            {
                strReturnValue = strArg0;
            }
            else
            {
                struct Value strValue = strPC.strValue;
                string sColor = GetStringLowerCase(GetValueAsTrimmedString(strArg0));

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
                        strReturnValue = GetErrorValue("[INVALID_HEX_COLOR:" + sColor + "]");
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
                        strReturnValue = GetErrorValue("[UNKNOWN_COLOR:" + sColor + "]");
                }
            }
        }
        else if (nNumParameters == 3)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);
            struct Value strArg2 = EvalCompiledParameter(strPC, 2);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsErrorValue(strArg2))
                strReturnValue = strArg2;
            else if (IsValueIntParameter(strArg0) && IsValueIntParameter(strArg1) && IsValueIntParameter(strArg2))
            {
                strReturnValue = GetValueFromString(ColorString(RenderAsString(strPC.strValue),
                    GetValueAsInt(strArg0), GetValueAsInt(strArg1), GetValueAsInt(strArg2)));
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_OR_3_ARGUMENTS]");
    }
    else if (sProperty == "padleft" || sProperty == "padright")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
            {
                int nLength = GetValueAsInt(strArg0);
                string sPadding = " ";

                if (GetParameterCount(strPC) >= 2)
                {
                    struct Value strArg1 = EvalCompiledParameter(strPC, 1);
                    if (IsErrorValue(strArg1))
                        strReturnValue = strArg1;
                    else
                        sPadding = GetValueAsString(strArg1, " ");
                }

                if (IsInvalidValue(strReturnValue))
                {
                    if (strPC.sCurrentProperty == "padleft")
                        strReturnValue = GetValueFromString(LeftPadString(RenderAsString(strPC.strValue), nLength, sPadding));
                    else
                        strReturnValue = GetValueFromString(RightPadString(RenderAsString(strPC.strValue), nLength, sPadding));
                }
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
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
            strReturnValue = GetErrorValue("[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->int]");
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
            strReturnValue = GetErrorValue("[TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->float]");
    }
    else if (sProperty == "string")
    {
        strReturnValue = GetValueFromString(RenderAsString(strPC.strValue));
    }
    else if (sProperty == "fixed")
    {
        int nPrecision = 2;
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
                nPrecision = GetValueAsInt(strArg0, 2);
        }

        if (IsInvalidValue(strReturnValue))
        {
            nPrecision = clamp(nPrecision, 0, 9);
            strReturnValue = GetValueFromString(FormatAsFixed(strPC.strValue, nPrecision));
        }
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
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
                strReturnValue = GetValueFromInt(GetValueAsInt(strArg0));
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sMetaName == "float")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueNumericParameter(strArg0))
                strReturnValue = GetValueFromFloat(GetValueAsFloat(strArg0));
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_NUMERIC]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sMetaName == "object")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueObjectParameter(strArg0))
                strReturnValue = GetValueFromObject(GetValueAsObject(strArg0));
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_OBJECT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sMetaName == "string")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else
                strReturnValue = GetValueFromString(GetValueAsString(strArg0));
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    return strReturnValue;
}


struct Value HandleMetaFunction(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "fn")
    {
        int nParameterCount = GetParameterCount(strPC);

        if (nParameterCount < 2)
            return GetErrorValue("[FN_USAGE:@fn(#name, $arg..., body)]");

        string sFunctionName = GetStringLowerCase(GetRawParameterText(strPC, 0));
        if (GetStringLeft(sFunctionName, 1) == DAZSCRIPT_FUNCTION_SYMBOL)
        {
            json jArgs = JsonArray();
            int nIndex, nLast = nParameterCount - 1;
            for (nIndex = 1; nIndex < nLast; nIndex++)
            {
                JsonArrayInsertStringInplace(jArgs, GetRawParameterText(strPC, nIndex));
            }

            string sBody = GetRawParameterText(strPC, nLast);
            json jCompiledBody = CompileTemplate(sBody);

            if (JsonGetType(jCompiledBody) != JSON_TYPE_ARRAY)
                return GetErrorValue("[INVALID_FUNCTION_BODY:" + sFunctionName + "]");

            json jFunction = JsonObject();
            JsonObjectSetInplace(jFunction, DAZSCRIPT_FUNCTION_ARGS, jArgs);
            JsonObjectSetStringInplace(jFunction, DAZSCRIPT_FUNCTION_BODY, sBody);
            JsonObjectSetInplace(jFunction, DAZSCRIPT_FUNCTION_BODY_COMPILED, jCompiledBody);
            JsonObjectSetInplace(strPC.jStack, sFunctionName, jFunction);
            strReturnValue = GetValueFromString();
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
            struct Value strCondition = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strCondition))
                strReturnValue = strCondition;
            else
                strReturnValue = EvalCompiledParameter(strPC, ValueToBoolish(strCondition) ? 1 : 2);
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_3_ARGUMENTS]");
    }
    else if (sMetaName == "while")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            string sAccumulator = "";
            int nLimit = DAZSCRIPT_WHILE_SAFETY_LIMIT;

            while (nLimit-- > 0)
            {
                struct Value strConditionResult = EvalCompiledParameter(strPC, 0);
                if (IsErrorValue(strConditionResult))
                {
                    strReturnValue = strConditionResult;
                    break;
                }

                if (!ValueToBoolish(strConditionResult))
                    break;

                struct Value strBodyResult = EvalCompiledParameter(strPC, 1);
                if (IsErrorValue(strBodyResult))
                {
                    strReturnValue = strBodyResult;
                    break;
                }

                sAccumulator += RenderAsString(strBodyResult);

                if (GetStringLength(sAccumulator) > DAZSCRIPT_MAX_OUTPUT_LENGTH)
                {
                    sAccumulator = ClampOutputString(sAccumulator);
                    break;
                }
            }

            if (IsInvalidValue(strReturnValue))
                strReturnValue = GetValueFromString(sAccumulator);
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sMetaName == "pick")
    {
        int nNumParameters = GetParameterCount(strPC);
        if (nNumParameters > 0)
        {
            int nIndex = Random(nNumParameters);
            strReturnValue = EvalCompiledParameter(strPC, nIndex);
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_AT_LEAST_1_ARGUMENT]");
    }
    else if (sMetaName == "not")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strParameter = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strParameter))
                strReturnValue = strParameter;
            else
                strReturnValue = GetValueFromInt(!ValueToBoolish(strParameter));
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
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
                struct Value strParameter = EvalCompiledParameter(strPC, nIndex);
                if (IsErrorValue(strParameter))
                {
                    strReturnValue = strParameter;
                    break;
                }

                if (!ValueToBoolish(strParameter))
                {
                    bResult = FALSE;
                    break;
                }
            }

            if (IsInvalidValue(strReturnValue))
                strReturnValue = GetValueFromInt(bResult);
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_AT_LEAST_1_ARGUMENT]");
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
                struct Value strParameter = EvalCompiledParameter(strPC, nIndex);
                if (IsErrorValue(strParameter))
                {
                    strReturnValue = strParameter;
                    break;
                }

                if (ValueToBoolish(strParameter))
                {
                    bResult = TRUE;
                    break;
                }
            }

            if (IsInvalidValue(strReturnValue))
                strReturnValue = GetValueFromInt(bResult);
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_AT_LEAST_1_ARGUMENT]");
    }
    else if (sMetaName == "switch" || sMetaName == "case")
    {
        int nCount = GetParameterCount(strPC);

        if (nCount >= 3)
        {
            struct Value strSelectorValue = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strSelectorValue))
                return strSelectorValue;

            string sSelector = RenderAsString(strSelectorValue);
            int nDefaultIndex = -1;

            if (nCount % 2 == 0)
                nDefaultIndex = nCount - 1;

            int nIndex, nEnd = nDefaultIndex == -1 ? nCount : nDefaultIndex;
            int bMatched = FALSE;

            for (nIndex = 1; nIndex + 1 < nEnd; nIndex += 2)
            {
                struct Value strCaseValue = EvalCompiledParameter(strPC, nIndex);
                if (IsErrorValue(strCaseValue))
                    return strCaseValue;

                string sCase = RenderAsString(strCaseValue);

                if (sSelector == sCase)
                {
                    strReturnValue = EvalCompiledParameter(strPC, nIndex + 1);
                    bMatched = TRUE;
                    break;
                }
            }

            if (!bMatched && nDefaultIndex != -1)
                strReturnValue = EvalCompiledParameter(strPC, nDefaultIndex);

            if (IsInvalidValue(strReturnValue))
                strReturnValue = GetValueFromString();
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_AT_LEAST_3_ARGUMENTS]");
    }
    else if (sMetaName == "foreachpc")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            string sAlias = GetRawParameterText(strPC, 0);

            if (GetStringLength(sAlias) >= 2 && GetStringLeft(sAlias, 1) == DAZSCRIPT_ALIAS_SYMBOL)
            {
                json jCompiledParameters = GetCompiledParameters(strPC);
                json jBody = JsonArrayGet(jCompiledParameters, 1);
                json jFrame = JsonCopyObject(strPC.jStack);
                string sAccumulator;

                object oPC = GetFirstPC();
                while (GetIsObjectValid(oPC))
                {
                    JsonObjectSetInplace(jFrame, sAlias, MakeObjectAliasEntry(oPC));

                    sAccumulator += RenderAsString(EvalTemplate(jBody, jFrame));
                    if (GetStringLength(sAccumulator) > DAZSCRIPT_MAX_OUTPUT_LENGTH)
                    {
                        sAccumulator = ClampOutputString(sAccumulator);
                        break;
                    }
                    oPC = GetNextPC();
                }

                strReturnValue = GetValueFromString(sAccumulator);
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    return strReturnValue;
}

struct Value HandleMetaVariable(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "set")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            string sAlias = GetRawParameterText(strPC, 0);
            if (GetStringLeft(sAlias, 1) == DAZSCRIPT_ALIAS_SYMBOL)
            {
                struct Value strValue = EvalCompiledParameter(strPC, 1);

                if (IsErrorValue(strValue))
                    return strValue;

                JsonObjectSetInplace(strPC.jStack, sAlias, MakeStackAliasEntryFromValue(strValue));
                strReturnValue = GetValueFromString();
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sMetaName == "unset")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            string sAlias = GetRawParameterText(strPC, 0);
            if (GetStringLeft(sAlias, 1) == DAZSCRIPT_ALIAS_SYMBOL)
            {
                JsonObjectDelInplace(strPC.jStack, sAlias);
                strReturnValue = GetValueFromString();
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sMetaName == "cast")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            string sAlias = GetRawParameterText(strPC, 0);
            if (GetStringLeft(sAlias, 1) == DAZSCRIPT_ALIAS_SYMBOL)
            {
                if (JsonObjectContainsKey(strPC.jStack, sAlias))
                {
                    json jStackVar = JsonObjectGet(strPC.jStack, sAlias);
                    string sCast = GetRawParameterText(strPC, 1);
                    if (sCast == "i" || sCast == "int")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, DAZSCRIPT_ALIAS_TYPE, NWNX_VM_AUXTYPE_INT));
                    else if (sCast == "f" || sCast == "float")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, DAZSCRIPT_ALIAS_TYPE, NWNX_VM_AUXTYPE_FLOAT));
                    else if (sCast == "s" || sCast == "string")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, DAZSCRIPT_ALIAS_TYPE, NWNX_VM_AUXTYPE_STRING));
                    else if (sCast == "o" || sCast == "object")
                        JsonObjectSetInplace(strPC.jStack, sAlias, JsonObjectSetInt(jStackVar, DAZSCRIPT_ALIAS_TYPE, NWNX_VM_AUXTYPE_OBJECT));

                    strReturnValue = GetValueFromString();
                }
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sMetaName == "out")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            string sVarName = GetRawParameterText(strPC, 0);
            if (IsStackVar(sVarName) && JsonObjectContainsKey(strPC.jStack, sVarName))
            {
                struct Value strValue = EvalCompiledParameter(strPC, 1);
                if (IsErrorValue(strValue))
                    return strValue;

                json jStackVar = JsonObjectGet(strPC.jStack, sVarName);
                int nOutAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);
                int nStackLocation = JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY);
                string sValue = RenderAsString(strValue);

                if (nOutAuxType == NWNX_VM_AUXTYPE_INT)
                {
                    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
                        NWNX_VM_SetStackIntegerValue(nStackLocation, strValue.nValue);
                    else if (IsInteger(sValue))
                        NWNX_VM_SetStackIntegerValue(nStackLocation, StringToInt(sValue));
                    else
                        strReturnValue = GetErrorValue("[TYPE_MISMATCH:OUT_NOT_INT]");
                }
                else if (nOutAuxType == NWNX_VM_AUXTYPE_FLOAT)
                {
                    if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
                        NWNX_VM_SetStackFloatValue(nStackLocation, strValue.fValue);
                    else if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
                        NWNX_VM_SetStackFloatValue(nStackLocation, IntToFloat(strValue.nValue));
                    else if (IsNumeric(sValue))
                        NWNX_VM_SetStackFloatValue(nStackLocation, StringToFloat(sValue));
                    else
                        strReturnValue = GetErrorValue("[TYPE_MISMATCH:OUT_NOT_FLOAT]");
                }
                else if (nOutAuxType == NWNX_VM_AUXTYPE_OBJECT)
                {
                    if (strValue.nAuxType == NWNX_VM_AUXTYPE_OBJECT)
                        NWNX_VM_SetStackObjectValue(nStackLocation, strValue.oValue);
                    else if (IsObjectString(sValue))
                        NWNX_VM_SetStackObjectValue(nStackLocation, StringToObject(sValue));
                    else
                        strReturnValue = GetErrorValue("[TYPE_MISMATCH:OUT_NOT_OBJECT]");
                }
                else if (nOutAuxType == NWNX_VM_AUXTYPE_STRING)
                {
                    NWNX_VM_SetStackStringValue(nStackLocation, sValue);
                }
                else
                {
                    strReturnValue = GetErrorValue("[TYPE_MISMATCH:OUT_UNSUPPORTED_TYPE]");
                }

                if (IsInvalidValue(strReturnValue))
                    strReturnValue = GetValueFromString();
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    return strReturnValue;
}

struct Value HandleMetaIntrospection(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;

    if (sMetaName == "exists")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            string sName = GetRawParameterText(strPC, 0);
            strReturnValue = GetValueFromInt(SymbolExists(strPC.jStack, sName));
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sMetaName == "type")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            string sName = GetRawParameterText(strPC, 0);
            strReturnValue = GetValueFromString(GetSymbolType(strPC.jStack, sName));
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    else if (sMetaName == "debug")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            string sExpr = GetRawParameterText(strPC, 0);

            string sValue = RenderAsString(EvalCompiledParameter(strPC, 0));
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
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }

    return strReturnValue;
}

struct Value HandleMetaUtility(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;

    if (sMetaName == "bar")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);

            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsValueNumericParameter(strArg0) && IsValueNumericParameter(strArg1))
            {
                float fValue = GetValueAsFloat(strArg0);
                float fMax = GetValueAsFloat(strArg1);
                int nWidth = STRING_BAR_DEFAULT_WIDTH;
                string sFilled = "#";
                string sEmpty = "-";

                if (GetParameterCount(strPC) >= 3)
                {
                    struct Value strArg2 = EvalCompiledParameter(strPC, 2);
                    if (IsErrorValue(strArg2))
                        strReturnValue = strArg2;
                    else if (IsValueIntParameter(strArg2))
                        nWidth = GetValueAsInt(strArg2, STRING_BAR_DEFAULT_WIDTH);
                }

                if (IsInvalidValue(strReturnValue) && GetParameterCount(strPC) >= 4)
                {
                    struct Value strArg3 = EvalCompiledParameter(strPC, 3);
                    if (IsErrorValue(strArg3))
                        strReturnValue = strArg3;
                    else
                        sFilled = GetValueAsString(strArg3, "#");
                }

                if (IsInvalidValue(strReturnValue) && GetParameterCount(strPC) >= 5)
                {
                    struct Value strArg4 = EvalCompiledParameter(strPC, 4);
                    if (IsErrorValue(strArg4))
                        strReturnValue = strArg4;
                    else
                        sEmpty = GetValueAsString(strArg4, "-");
                }

                if (IsInvalidValue(strReturnValue))
                    strReturnValue = GetValueFromString(MakeBarString(fValue, fMax, nWidth, sFilled, sEmpty));
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_NUMERIC]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sMetaName == "roll" || sMetaName == "rollv")
    {
        int nNumParameters = GetParameterCount(strPC);
        int nCount = 1, nSides = 0, nBonus = 0;
        string sSpec = "";

        if (nNumParameters == 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else
            {
                sSpec = GetValueAsTrimmedString(strArg0);
                json jDice = ParseDiceSpec(sSpec);

                if (JsonGetLength(jDice) >= 3)
                {
                    nCount = JsonArrayGetInt(jDice, 0);
                    nSides = JsonArrayGetInt(jDice, 1);
                    nBonus = JsonArrayGetInt(jDice, 2);
                }
            }
        }
        else if (nNumParameters >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsValueIntParameter(strArg0) && IsValueIntParameter(strArg1))
            {
                nCount = GetValueAsInt(strArg0);
                nSides = GetValueAsInt(strArg1);

                if (nNumParameters >= 3)
                {
                    struct Value strArg2 = EvalCompiledParameter(strPC, 2);
                    if (IsErrorValue(strArg2))
                        strReturnValue = strArg2;
                    else if (IsValueIntParameter(strArg2))
                        nBonus = GetValueAsInt(strArg2);
                }

                sSpec = IntToString(nCount) + "d" + IntToString(nSides);

                if (nBonus > 0)
                    sSpec += "+" + IntToString(nBonus);
                else if (nBonus < 0)
                    sSpec += IntToString(nBonus);
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_INT]");
        }

        if (IsInvalidValue(strReturnValue) && nSides > 0)
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
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);

            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsValueObjectParameter(strArg0))
            {
                object oPC = GetValueAsObject(strArg0);
                string sMessage = GetValueAsString(strArg1);

                if (GetIsObjectValid(oPC))
                    SendMessageToPC(oPC, sMessage);

                strReturnValue = GetValueFromString();
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_OBJECT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sMetaName == "print" || sMetaName == "log")
    {
        if (GetParameterCount(strPC) >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else
            {
                PrintString(GetValueAsString(strArg0));
                strReturnValue = GetValueFromString();
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
    }
    return strReturnValue;
}


struct Value HandleMetaMath(struct PropertyChain strPC, string sMetaName)
{
    struct Value strReturnValue;
    if (sMetaName == "add" || sMetaName == "sub" || sMetaName == "mul")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);

            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsValueIntParameter(strArg0) && IsValueIntParameter(strArg1))
            {
                int nValue0 = GetValueAsInt(strArg0);
                int nValue1 = GetValueAsInt(strArg1);

                if (sMetaName == "add")
                    strReturnValue = GetValueFromInt(nValue0 + nValue1);
                else if (sMetaName == "sub")
                    strReturnValue = GetValueFromInt(nValue0 - nValue1);
                else
                    strReturnValue = GetValueFromInt(nValue0 * nValue1);
            }
            else if (IsValueNumericParameter(strArg0) && IsValueNumericParameter(strArg1))
            {
                float fValue0 = GetValueAsFloat(strArg0);
                float fValue1 = GetValueAsFloat(strArg1);

                if (sMetaName == "add")
                    strReturnValue = GetValueFromFloat(fValue0 + fValue1);
                else if (sMetaName == "sub")
                    strReturnValue = GetValueFromFloat(fValue0 - fValue1);
                else
                    strReturnValue = GetValueFromFloat(fValue0 * fValue1);
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_INT_OR_NUMERIC]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sMetaName == "div" || sMetaName == "idiv")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);

            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (sMetaName == "div")
            {
                if (IsValueNumericParameter(strArg0) && IsValueNumericParameter(strArg1))
                {
                    float fValue1 = GetValueAsFloat(strArg0);
                    float fValue2 = GetValueAsFloat(strArg1);
                    if (fabs(fValue2) > FLOAT_EPSILON)
                        strReturnValue = GetValueFromFloat(fValue1 / fValue2);
                    else
                        strReturnValue = GetErrorValue("[DIVISION_BY_ZERO]");
                }
                else
                    strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NUMERIC]");
            }
            else
            {
                if (IsValueIntParameter(strArg0) && IsValueIntParameter(strArg1))
                {
                    int nValue1 = GetValueAsInt(strArg0);
                    int nValue2 = GetValueAsInt(strArg1);
                    if (nValue2 != 0)
                        strReturnValue = GetValueFromInt(nValue1 / nValue2);
                    else
                        strReturnValue = GetErrorValue("[DIVISION_BY_ZERO]");
                }
                else
                    strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_INT]");
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sMetaName == "min" || sMetaName == "max")
    {
        int nIndex, nNumParameters = GetParameterCount(strPC);

        if (nNumParameters >= 1)
        {
            int bAllInt = TRUE;
            int nIntResult = 0;
            float fResult = 0.0;

            for (nIndex = 0; nIndex < nNumParameters; nIndex++)
            {
                struct Value strArg = EvalCompiledParameter(strPC, nIndex);

                if (IsErrorValue(strArg))
                {
                    strReturnValue = strArg;
                    break;
                }
                else if (!IsValueNumericParameter(strArg))
                {
                    strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_INT_OR_NUMERIC]");
                    break;
                }

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

            if (IsInvalidValue(strReturnValue))
            {
                if (bAllInt)
                    strReturnValue = GetValueFromInt(nIntResult);
                else
                    strReturnValue = GetValueFromFloat(fResult);
            }
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_AT_LEAST_1_ARGUMENT]");
    }
    else if (sMetaName == "clamp")
    {
        if (GetParameterCount(strPC) >= 3)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);
            struct Value strArg2 = EvalCompiledParameter(strPC, 2);

            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsErrorValue(strArg2))
                strReturnValue = strArg2;
            else if (IsValueIntParameter(strArg0) && IsValueIntParameter(strArg1) && IsValueIntParameter(strArg2))
            {
                strReturnValue = GetValueFromInt(clamp(GetValueAsInt(strArg0), GetValueAsInt(strArg1), GetValueAsInt(strArg2)));
            }
            else if (IsValueNumericParameter(strArg0) && IsValueNumericParameter(strArg1) && IsValueNumericParameter(strArg2))
            {
                strReturnValue = GetValueFromFloat(clampf(GetValueAsFloat(strArg0), GetValueAsFloat(strArg1), GetValueAsFloat(strArg2)));
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_INT_OR_NUMERIC]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_3_ARGUMENTS]");
    }
    else if (sMetaName == "mod")
    {
        if (GetParameterCount(strPC) >= 2)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            struct Value strArg1 = EvalCompiledParameter(strPC, 1);

            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsErrorValue(strArg1))
                strReturnValue = strArg1;
            else if (IsValueIntParameter(strArg0) && IsValueIntParameter(strArg1))
            {
                int nValue = GetValueAsInt(strArg0);
                int nDivisor = GetValueAsInt(strArg1);

                if (nDivisor != 0)
                    strReturnValue = GetValueFromInt(nValue % nDivisor);
                else
                    strReturnValue = GetErrorValue("[DIVISION_BY_ZERO]");
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENTS_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_2_ARGUMENTS]");
    }
    else if (sMetaName == "random")
    {
        int nNumParameters = GetParameterCount(strPC);
        if (nNumParameters >= 1)
        {
            struct Value strArg0 = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strArg0))
                strReturnValue = strArg0;
            else if (IsValueIntParameter(strArg0))
            {
                int nMax = GetValueAsInt(strArg0);
                int nMin = 0;

                if (nNumParameters >= 2)
                {
                    struct Value strArg1 = EvalCompiledParameter(strPC, 1);
                    if (IsErrorValue(strArg1))
                    {
                        strReturnValue = strArg1;
                    }
                    else if (IsValueIntParameter(strArg1))
                    {
                        nMin = nMax;
                        nMax = GetValueAsInt(strArg1);
                    }
                }

                if (IsInvalidValue(strReturnValue))
                {
                    if (nMax > nMin)
                        strReturnValue = GetValueFromInt(nMin + Random(nMax - nMin));
                    else if (nMax == nMin)
                        strReturnValue = GetValueFromInt(nMin);
                }
            }
            else
                strReturnValue = GetErrorValue("[TYPE_MISMATCH:ARGUMENT_NOT_INT]");
        }
        else
            strReturnValue = GetErrorValue("[ARITY:EXPECTED_1_ARGUMENT]");
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
    return sPrefix != DAZSCRIPT_ALIAS_SYMBOL && sPrefix != DAZSCRIPT_META_SYMBOL && sPrefix != DAZSCRIPT_FUNCTION_SYMBOL;
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
    if (GetStringLength(sValue) <= DAZSCRIPT_DEBUG_VALUE_MAX_LENGTH)
        return sValue;
    return GetStringLeft(sValue, DAZSCRIPT_DEBUG_VALUE_MAX_LENGTH) + "...";
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
