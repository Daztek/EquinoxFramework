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
const int DAZSCRIPT_ENABLE_PERSISTENT_CACHE                 = FALSE;
const int DAZSCRIPT_PERSISTENT_CACHE_VERSION                = 1;

const int DAZSCRIPT_TRACE_EVENT_WIDTH                       = 40;
const int DAZSCRIPT_TRACE_MAX_LENGTH                        = 160;
const string DAZSCRIPT_TRACE_DEPTH_KEY                      = "DazScriptTraceDepth";
const string DAZSCRIPT_TRACE_INDENT_KEY                     = "DazScriptTraceIndent";

const string DAZSCRIPT_TEMPLATE_CACHE_PREFIX                = "DazScriptTemplateCache_";
const string DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX          = "DazScriptPropertyChainCache_";
const string DAZSCRIPT_COMPILED_PARAMETER_CACHE_PREFIX      = "DazScriptCompiledParameterCache_";
const string DAZSCRIPT_PARAMETER_ENTRY_CACHE_PREFIX         = "DazScriptParameterEntryCache_";

const string DAZSCRIPT_ALIAS_TYPE                           = "type";
const string DAZSCRIPT_ALIAS_VALUE                          = "value";
const string DAZSCRIPT_ALIAS_ERROR                          = "error";

const string DAZSCRIPT_PARAMETER_TEXT                       = "text";
const string DAZSCRIPT_PARAMETER_WAS_QUOTED                 = "was_quoted";

const string DAZSCRIPT_PARSE_ERROR                          = "parse_error";
const string DAZSCRIPT_PARSE_CODE                           = "code";
const string DAZSCRIPT_PARSE_AT                             = "at";
const string DAZSCRIPT_PARSE_SOURCE                         = "source";
const string DAZSCRIPT_PARSE_CONTEXT                        = "context";

const int DAZSCRIPT_NODE_LITERAL                            = 0;
const int DAZSCRIPT_NODE_EXPR                               = 1;
const int DAZSCRIPT_NODE_FORCE_STRING                       = 2;

const string DAZSCRIPT_PROPERTY_CHAIN_SYMBOL                = ">";
const string DAZSCRIPT_META_SYMBOL                          = "@";
const string DAZSCRIPT_ALIAS_SYMBOL                         = "$";
const string DAZSCRIPT_FUNCTION_SYMBOL                      = "#";

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

const string DAZSCRIPT_FUNCTION_ARGS                        = "args";
const string DAZSCRIPT_FUNCTION_BODY                        = "body";
const string DAZSCRIPT_FUNCTION_BODY_COMPILED               = "body_compiled";

const int DAZSCRIPT_WHILE_DEFAULT_ITERATION_LIMIT           = 50;
const int DAZSCRIPT_WHILE_MAX_ITERATION_LIMIT               = 250;

struct Parser
{
    string sSource;
    int nLength;
    int nIndex;

    int bInQuotes;
    string sQuoteChar;

    int nBraceDepth;
    int nParenDepth;

    int bError;
    string sErrorCode;
    int nErrorAt;
};

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
string Interpret(string sString, int bTraceEnabled = FALSE, int nDepthOverride = 0, json jStack = JSON_NULL);

string MakeCacheKey(string sPrefix, string sString);
json GetCachedJson(string sPrefix, string sInput);
void SetCachedJson(string sPrefix, string sInput, json jValue);
string GetAliasStoredValueAsString(json jEntry);
json MakeStackAliasEntryFromValue(struct Value strValue);
json MakeParameterEntry(string sText, int bWasQuoted);

int IsKnownAuxType(int nAuxType);
int IsKnownStackAuxType(int nAuxType);
int ValueNeedsDefault(struct Value strValue);
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
int GetCastAuxTypeFromName(string sCast);
string GetValueAsCastString(struct Value strValue);
struct Value CastValueToJson(struct Value strValue);
struct Value CastValueToAuxType(struct Value strValue, int nTargetAuxType);
string GetValueAsText(struct Value strValue, string sDefault = "");
string GetValueAsTrimmedString(struct Value strValue, string sDefault = "");
int IsValueIntParameter(struct Value strValue);
int IsValueNumericParameter(struct Value strValue);
int IsValueObjectParameter(struct Value strValue);
int GetValueAsInt(struct Value strValue, int nDefault = 0);
float GetValueAsFloat(struct Value strValue, float fDefault = 0.0);
object GetValueAsObject(struct Value strValue, object oDefault = OBJECT_INVALID);
struct Value SetStackLocationFromValue(int nAuxType, int nStackLocation, struct Value strValue);
string ValueToText(struct Value strValue);
int ValueToBoolish(struct Value strValue);
struct Value FormatValueAsFixed(struct Value strValue, int nPrecision);
struct Value FormatValueAsHex(struct Value strValue);
struct Value FormatValueAsBoolean(struct Value strValue);
struct Value ConvertJsonToValue(json jValue);
struct Value GetValueFromNamedColor(string sValue, string sColor);
struct Value GetValueFromHexColor(string sValue, string sColor);

int IsParserQuote(string sCharacter);
int IsParserEscapedCharacter(string sString, int nIndex, int nLength);
struct Parser ParserBegin(string sSource);
int ParserAtEnd(struct Parser str);
string ParserChar(struct Parser str);
int ParserIsTopLevel(struct Parser str);
int ParserIsRootDepth(struct Parser str);
int ParserMatches(struct Parser str, string sToken);
struct Parser ParserAdvance(struct Parser str);
int FindTopLevelToken(string sString, string sToken);
json SplitTopLevelToken(string sString, string sToken, int bIncludeEmpty = TRUE);
int FindMatchingTemplateExprEnd(string sString, int nOpenAt);
int FindPropertyCallStart(string sPropertySegment);
int FindMatchingPropertyCallParen(string sString, int nOpenAt);

string GetParserContext(string sSource, int nAt);
json MakeParserError(string sCode, int nAt, string sSource);
json MakeParserErrorPropertySegment(string sProperty, string sParameters, json jError);
json CacheParameterParserError(string sParameters, string sCode, int nAt);
int IsParserError(json jValue);
struct Value GetValueFromParserError(json jError, string sWhere = "");
struct Value CheckParameterParserError(struct PropertyChain strPC);

json CompileTemplate(string sString);
json CompileForcedStringTemplate(string sValue);
void JsonArrayInsertLiteralNodeInplace(json jTemplate, string sLiteral);
void JsonArrayInsertExprNodeInplace(json jTemplate, string sExpr);
void JsonArrayInsertForceStringNodeInplace(json jTemplate, json jInnerTemplate);

json CompileExpression(string sExpr);
json CompilePropertyChain(string sPropertyPath);
json CompilePropertySegment(string sPropertySegment);
json ParseParameterEntries(string sParameters);
json CompileParsedParameters(string sParameters, json jParameterEntries);
json CompileParameters(string sParameters);

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

struct Value EvalTemplate(json jTemplate, json jStack);
struct Value EvalTemplateToString(json jTemplate, json jStack);
struct Value EvalCompiledExpressionToValue(json jExpr, json jStack);
struct Value GetStackValue(json jStack, string sVarName);
struct Value ResolveAliasValue(json jStack, string sAliasName);
struct Value ResolveMetaValue(json jStack, string sMetaName, string sBaseParameters, json jBaseCompiledParameters);
struct Value ResolveFunctionValue(json jStack, string sFunctionName, string sBaseParameters, json jBaseCompiledParameters);
struct PropertyChain ApplyCompiledPropertySegment(struct PropertyChain strPC, json jSegment);
struct PropertyChain EvalCompiledPropertyChain(struct PropertyChain strPC, json jSegments);
struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC);

struct PropertyChain ReturnPropertyChainWithValue(struct PropertyChain strPC, struct Value strValue);
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
struct Value HandleMetaOutput(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaMath(struct PropertyChain strPC, string sMetaName);
struct Value HandleMetaObject(struct PropertyChain strPC, string sMetaName);

int IsTraceEnabled();
void PushTrace();
void PopTrace();
void PushTraceIndent();
void PopTraceIndent();
string GetTraceIndent();
void Trace(string sEvent, string sDetail = "");
void TraceEnter(string sEvent, string sDetail = "");
void TraceExit(string sEvent, string sDetail = "");
string TraceValue(struct Value strValue);
string TraceExprKind(int nKind);
string TraceQuoted(string sText);

int IsStackVar(string sVarName);
int IsSymbol(string sVarName, string sSymbol);
int IsAliasEntry(json jEntry);
int IsErrorAliasEntry(json jEntry);
int IsFunctionEntry(json jEntry);
int IsStackEntry(json jEntry);
string GetAliasEntryType(json jEntry);
string GetStackEntryType(json jEntry);
string GetSymbolType(json jStack, string sName);
int SymbolExists(json jStack, string sName);

string InferDebugValueType(string sValue);
string TruncateDebugValue(string sValue);
string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "");
string InspectObject(object oValue);

string FormatString(string sString, int nDepthOverride = 0)
{
    return Interpret(sString, FALSE, 1 + nDepthOverride, JsonNull());
}

string Interpret(string sString, int bTraceEnabled = FALSE, int nDepthOverride = 0, json jStack = JSON_NULL)
{
    if (sString == "")
        return "";

    if (FindSubString(sString, "{", 0) == -1 && FindSubString(sString, "}", 0) == -1)
        return sString;

    int bPushedTrace = FALSE;
    if (bTraceEnabled)
    {
        PushTrace();
        bPushedTrace = TRUE;
    }

    if (IsTraceEnabled()) { Trace("interpret", sString); }

    json jTemplate = GetCachedJson(DAZSCRIPT_TEMPLATE_CACHE_PREFIX, sString);
    if (!JsonGetType(jTemplate))
    {
        jTemplate = CompileTemplate(sString);
        SetCachedJson(DAZSCRIPT_TEMPLATE_CACHE_PREFIX, sString, jTemplate);
    }

    if (!JsonGetType(jStack))
        jStack = NWNX_VM_GetStackVariables(1 + nDepthOverride);

    sString = ValueToText(EvalTemplate(jTemplate, jStack));

    if (bPushedTrace)
        PopTrace();

    return sString;
}

void DazScript_Init()
{
    if (DAZSCRIPT_ENABLE_PERSISTENT_CACHE)
    {
        if (GetCampaignInt(DAZSCRIPT_SCRIPT_NAME, "PERSISTENT_CACHE_VERSION") != DAZSCRIPT_PERSISTENT_CACHE_VERSION)
        {
            DestroyCampaignDatabase(DAZSCRIPT_SCRIPT_NAME);
            SetCampaignInt(DAZSCRIPT_SCRIPT_NAME, "PERSISTENT_CACHE_VERSION", DAZSCRIPT_PERSISTENT_CACHE_VERSION);
        }

        object oDataObject = RetrieveCampaignObject(DAZSCRIPT_SCRIPT_NAME, "PERSISTENT_CACHE", GetStartingLocation(), OBJECT_INVALID, OBJECT_INVALID, TRUE);
        if (GetIsObjectValid(oDataObject))
            SetDataObject(DAZSCRIPT_SCRIPT_NAME, oDataObject);
        else
            oDataObject = GetDataObject(DAZSCRIPT_SCRIPT_NAME);
    }
}

// @NWNX[NWNX_ON_SHUTDOWN_SERVER]
void DazScript_OnShutdownServer()
{
    if (DAZSCRIPT_ENABLE_PERSISTENT_CACHE)
        StoreCampaignObject(DAZSCRIPT_SCRIPT_NAME, "PERSISTENT_CACHE", GetDataObject(DAZSCRIPT_SCRIPT_NAME), OBJECT_INVALID, TRUE);
}

string MakeCacheKey(string sPrefix, string sString)
{
    return sPrefix + IntToString(GetStringLength(sString)) + "_" + IntToString(HashString(sString));
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
        JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_TYPE, NWNX_VM_AUXTYPE_INVALID);
        JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.sErrorMessage);
        JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_ERROR, TRUE);
        return jEntry;
    }

    if (!IsKnownAuxType(strValue.nAuxType))
    {
        JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_TYPE, NWNX_VM_AUXTYPE_INVALID);
        JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, "INVALID_ALIAS_VALUE");
        JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_ERROR, TRUE);
        return jEntry;
    }

    JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_TYPE, strValue.nAuxType);
    JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_ERROR, FALSE);

    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       JsonObjectSetIntInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.nValue); break;
        case NWNX_VM_AUXTYPE_FLOAT:     JsonObjectSetFloatInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.fValue); break;
        case NWNX_VM_AUXTYPE_STRING:    JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, strValue.sValue); break;
        case NWNX_VM_AUXTYPE_OBJECT:    JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, ObjectIDToString(strValue.oValue));  break;
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

int IsKnownAuxType(int nAuxType)
{
    return nAuxType == NWNX_VM_AUXTYPE_INT || nAuxType == NWNX_VM_AUXTYPE_FLOAT || nAuxType == NWNX_VM_AUXTYPE_STRING ||
           nAuxType == NWNX_VM_AUXTYPE_OBJECT || nAuxType == NWNX_VM_AUXTYPE_JSON;
}

int IsKnownStackAuxType(int nAuxType)
{
    return nAuxType == NWNX_VM_AUXTYPE_INT || nAuxType == NWNX_VM_AUXTYPE_FLOAT || nAuxType == NWNX_VM_AUXTYPE_STRING ||
           nAuxType == NWNX_VM_AUXTYPE_OBJECT || nAuxType == NWNX_VM_AUXTYPE_JSON || nAuxType == NWNX_VM_AUXTYPE_VOID;
}

int ValueNeedsDefault(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return FALSE;
    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:
            return strValue.sValue == "";
        case NWNX_VM_AUXTYPE_OBJECT:
            return !GetIsObjectValid(strValue.oValue);
        case NWNX_VM_AUXTYPE_JSON:
            return JsonGetType(strValue.jValue) == JSON_TYPE_NULL;
    }
    return FALSE;
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
    if (IsInteger(sValue))
        return GetValueFromInt(StringToInt(sValue));
    if (IsFloat(sValue))
        return GetValueFromFloat(StringToFloat(sValue));
    if (IsObjectIDString(sValue))
        return GetValueFromObject(StringToObject(sValue));

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
        case NWNX_VM_AUXTYPE_OBJECT:    return GetValueFromJson(JsonString(ObjectIDToString(strValue.oValue)));
        case NWNX_VM_AUXTYPE_STRING:
        {
            json jParsed = JsonParse(strValue.sValue);
            if (JsonGetError(jParsed) != "")
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
            if (!IsObjectIDString(sValue))
                return GetErrorValue("TYPE_MISMATCH:" + AuxTypeToString(strValue.nAuxType) + "->object");

            return GetValueFromObject(StringToObject(sValue));
        }
    }

    return GetErrorValue("INVALID_CAST_AUXTYPE:" + IntToString(nTargetAuxType));
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
    return IsObjectIDString(GetValueAsTrimmedString(strValue));
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

struct Value SetStackLocationFromValue(int nAuxType, int nStackLocation, struct Value strValue)
{
    struct Value strOutValue = CastValueToAuxType(strValue, nAuxType);
    if (IsErrorValue(strOutValue))
        return GetErrorValue("TYPE_MISMATCH:OUT_NOT_" + GetStringUpperCase(AuxTypeToString(nAuxType, TRUE)));

    if (nAuxType == NWNX_VM_AUXTYPE_INT)
        NWNX_VM_SetStackIntegerValue(nStackLocation, strOutValue.nValue);
    else if (nAuxType == NWNX_VM_AUXTYPE_FLOAT)
        NWNX_VM_SetStackFloatValue(nStackLocation, strOutValue.fValue);
    else if (nAuxType == NWNX_VM_AUXTYPE_OBJECT)
        NWNX_VM_SetStackObjectValue(nStackLocation, strOutValue.oValue);
    else if (nAuxType == NWNX_VM_AUXTYPE_STRING)
        NWNX_VM_SetStackStringValue(nStackLocation, strOutValue.sValue);
    else if (nAuxType == NWNX_VM_AUXTYPE_JSON)
        NWNX_VM_SetStackJsonValue(nStackLocation, strOutValue.jValue);
    else
        return GetErrorValue("TYPE_MISMATCH:OUT_UNSUPPORTED_TYPE");

    return GetValueFromString();
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
        case NWNX_VM_AUXTYPE_OBJECT:    return ObjectIDToString(strValue.oValue);
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
        case NWNX_VM_AUXTYPE_JSON:
        {
            json jValue = strValue.jValue;
            if (JsonGetError(jValue) != "")
                return FALSE;

            int nJsonType = JsonGetType(jValue);
            if (nJsonType == JSON_TYPE_NULL)
                return FALSE;
            if (nJsonType == JSON_TYPE_INTEGER || nJsonType == JSON_TYPE_BOOL)
                return JsonGetInt(jValue) != 0;
            if (nJsonType == JSON_TYPE_FLOAT)
                return fabs(JsonGetFloat(jValue)) >= FLOAT_EPSILON;
            if (nJsonType == JSON_TYPE_STRING)
                return StringToBoolish(JsonGetString(jValue));

            return TRUE;
        }
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

struct Parser ParserBegin(string sSource)
{
    struct Parser str;
    str.sSource = sSource;
    str.nLength = GetStringLength(sSource);
    str.nIndex = 0;
    return str;
}

int ParserAtEnd(struct Parser str)
{
    return str.nIndex >= str.nLength;
}

string ParserChar(struct Parser str)
{
    if (str.nIndex >= str.nLength)
        return "";
    return GetSubString(str.sSource, str.nIndex, 1);
}

int ParserIsTopLevel(struct Parser str)
{
    return !str.bInQuotes && str.nBraceDepth == 0 && str.nParenDepth == 0;
}

int ParserIsRootDepth(struct Parser str)
{
    return str.nBraceDepth == 0 && str.nParenDepth == 0;
}

int ParserMatches(struct Parser str, string sToken)
{
    int nTokenLength = GetStringLength(sToken);
    if (nTokenLength == 0)
        return FALSE;
    if (str.nIndex + nTokenLength > str.nLength)
        return FALSE;
    return GetSubString(str.sSource, str.nIndex, nTokenLength) == sToken;
}

struct Parser ParserAdvance(struct Parser str)
{
    if (str.nIndex >= str.nLength)
        return str;

    string sCharacter = GetSubString(str.sSource, str.nIndex, 1);
    if (str.bInQuotes)
    {
        if (IsParserEscapedCharacter(str.sSource, str.nIndex, str.nLength))
        {
            str.nIndex += 2;
            return str;
        }

        if (sCharacter == str.sQuoteChar)
        {
            str.bInQuotes = FALSE;
            str.sQuoteChar = "";
        }

        str.nIndex++;
        return str;
    }

    if (IsParserQuote(sCharacter))
    {
        str.bInQuotes = TRUE;
        str.sQuoteChar = sCharacter;
        str.nIndex++;
        return str;
    }

    if (sCharacter == "{")
    {
        str.nBraceDepth++;
    }
    else if (sCharacter == "}")
    {
        str.nBraceDepth--;

        if (str.nBraceDepth < 0)
        {
            str.bError = TRUE;
            str.sErrorCode = "UNEXPECTED_CLOSING_BRACE";
            str.nErrorAt = str.nIndex;
        }
    }
    else if (sCharacter == "(" && str.nBraceDepth == 0)
    {
        str.nParenDepth++;
    }
    else if (sCharacter == ")" && str.nBraceDepth == 0)
    {
        str.nParenDepth--;

        if (str.nParenDepth < 0)
        {
            str.bError = TRUE;
            str.sErrorCode = "UNEXPECTED_CLOSING_PAREN";
            str.nErrorAt = str.nIndex;
        }
    }

    str.nIndex++;
    return str;
}

int FindTopLevelToken(string sString, string sToken)
{
    struct Parser str = ParserBegin(sString);
    while (!ParserAtEnd(str))
    {
        if (ParserIsTopLevel(str) && ParserMatches(str, sToken))
            return str.nIndex;
        str = ParserAdvance(str);
        if (str.bError)
            return -1;
    }
    return -1;
}

json SplitTopLevelToken(string sString, string sToken, int bIncludeEmpty = TRUE)
{
    json jParts = JsonArray();
    int nStart, nTokenLength = GetStringLength(sToken);

    if (nTokenLength == 0)
    {
        JsonArrayInsertStringInplace(jParts, sString);
        return jParts;
    }

    struct Parser str = ParserBegin(sString);
    while (!ParserAtEnd(str))
    {
        if (ParserIsTopLevel(str) && ParserMatches(str, sToken))
        {
            string sPart = GetSubString(sString, nStart, str.nIndex - nStart);
            if (bIncludeEmpty || sPart != "")
                JsonArrayInsertStringInplace(jParts, sPart);

            str.nIndex += nTokenLength;
            nStart = str.nIndex;
            continue;
        }
        str = ParserAdvance(str);
    }

    string sFinalPart = GetSubString(sString, nStart, GetStringLength(sString) - nStart);
    if (bIncludeEmpty || sFinalPart != "")
        JsonArrayInsertStringInplace(jParts, sFinalPart);

    return jParts;
}

int FindMatchingTemplateExprEnd(string sString, int nOpenAt)
{
    struct Parser str = ParserBegin(sString);
    str.nIndex = nOpenAt + 1;
    str.nBraceDepth = 1;

    while (!ParserAtEnd(str))
    {
        int nAt = str.nIndex;
        str = ParserAdvance(str);

        if (str.nBraceDepth == 0)
            return nAt;
    }
    return -1;
}

int FindPropertyCallStart(string sPropertySegment)
{
    struct Parser str = ParserBegin(sPropertySegment);
    while (!ParserAtEnd(str))
    {
        if (ParserIsTopLevel(str) && ParserChar(str) == "(")
            return str.nIndex;
        str = ParserAdvance(str);
    }
    return -1;
}

int FindMatchingPropertyCallParen(string sString, int nOpenAt)
{
    struct Parser str = ParserBegin(sString);
    str.nIndex = nOpenAt + 1;
    str.nParenDepth = 1;

    while (!ParserAtEnd(str))
    {
        int nAt = str.nIndex;
        str = ParserAdvance(str);
        if (str.bError)
        {
            if (str.sErrorCode == "UNEXPECTED_CLOSING_BRACE")
                return -2 - str.nErrorAt;

            return -1;
        }
        if (str.nParenDepth == 0)
            return nAt;
    }
    return -1;
}

string GetParserContext(string sSource, int nAt)
{
    int nLength = GetStringLength(sSource);
    nAt = clamp(nAt, 0, nLength);
    int nStart = max(0, nAt - 12);
    int nEnd = min(nLength, nAt + 12);
    string sBefore = GetSubString(sSource, nStart, nAt - nStart);
    string sCurrent = nAt < nLength ? GetSubString(sSource, nAt, 1) : "<eof>";
    string sAfter = GetSubString(sSource, nAt + 1, nEnd - nAt - 1);
    return sBefore + "[" + sCurrent + "]" + sAfter;
}

json MakeParserError(string sCode, int nAt, string sSource)
{
    json jError = JsonObject();
    JsonObjectSetIntInplace(jError, DAZSCRIPT_PARSE_ERROR, TRUE);
    JsonObjectSetStringInplace(jError, DAZSCRIPT_PARSE_CODE, sCode);
    JsonObjectSetIntInplace(jError, DAZSCRIPT_PARSE_AT, nAt);
    JsonObjectSetStringInplace(jError, DAZSCRIPT_PARSE_SOURCE, sSource);
    JsonObjectSetStringInplace(jError, DAZSCRIPT_PARSE_CONTEXT, GetParserContext(sSource, nAt));
    return jError;
}

json MakeParserErrorPropertySegment(string sProperty, string sParameters, json jError)
{
    json jSegment = JsonArray();
    JsonArrayInsertStringInplace(jSegment, GetStringLowerCase(sProperty));
    JsonArrayInsertStringInplace(jSegment, sParameters);
    JsonArrayInsertInplace(jSegment, jError);
    JsonArrayInsertInplace(jSegment, jError);
    return jSegment;
}

json CacheParameterParserError(string sParameters, string sCode, int nAt)
{
    json jError = MakeParserError(sCode, nAt, sParameters);
    SetCachedJson(DAZSCRIPT_PARAMETER_ENTRY_CACHE_PREFIX, sParameters, jError);
    return jError;
}

int IsParserError(json jValue)
{
    return JsonGetType(jValue) == JSON_TYPE_OBJECT && JsonObjectGetInt(jValue, DAZSCRIPT_PARSE_ERROR);
}

struct Value GetValueFromParserError(json jError, string sWhere = "")
{
    string sCode = JsonObjectGetString(jError, DAZSCRIPT_PARSE_CODE);
    string sContext = JsonObjectGetString(jError, DAZSCRIPT_PARSE_CONTEXT);
    int nAt = JsonObjectGetInt(jError, DAZSCRIPT_PARSE_AT);

    string sMessage = "PARSE_ERROR:" + sCode;

    if (sWhere != "")
        sMessage += ":IN_" + sWhere;

    sMessage += ":AT_" + IntToString(nAt);

    if (sContext != "")
        sMessage += ":NEAR:" + sContext;

    return GetErrorValue(sMessage);
}

struct Value CheckParameterParserError(struct PropertyChain strPC)
{
    json jCompiledParameters = GetCompiledParameters(strPC);
    if (IsParserError(jCompiledParameters))
        return GetValueFromParserError(jCompiledParameters, strPC.sCurrentProperty);
    return GetInvalidValue();
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
                JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nIndex - nLiteralStart));

            JsonArrayInsertLiteralNodeInplace(jTemplate, "{");
            nIndex += 2;
            nLiteralStart = nIndex;
            continue;
        }

        if (sCurrent == "}" && nIndex + 1 < nLength && GetSubString(sString, nIndex + 1, 1) == "}")
        {
            if (nIndex > nLiteralStart)
                JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nIndex - nLiteralStart));

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

        int nStart = nIndex;
        int nEnd = FindMatchingTemplateExprEnd(sString, nStart);

        if (nEnd == -1)
            return MakeParserError("UNTERMINATED_TEMPLATE_EXPR", nStart, sString);

        if (nStart > nLiteralStart)
            JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nStart - nLiteralStart));

        JsonArrayInsertExprNodeInplace(jTemplate, GetSubString(sString, nStart + 1, nEnd - nStart - 1));

        nIndex = nEnd + 1;
        nLiteralStart = nIndex;
    }

    if (nLiteralStart < nLength)
        JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nLength - nLiteralStart));

    return jTemplate;
}

json CompileForcedStringTemplate(string sValue)
{
    json jInner = CompileTemplate(sValue);
    if (IsParserError(jInner))
        return jInner;
    json jTemplate = JsonArray();
    JsonArrayInsertForceStringNodeInplace(jTemplate, jInner);
    return jTemplate;
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
    int nPropertyPosition = FindTopLevelToken(sExpr, DAZSCRIPT_PROPERTY_CHAIN_SYMBOL);
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

json CompilePropertyChain(string sPropertyPath)
{
    sPropertyPath = trim(sPropertyPath);
    json jCached = GetCachedJson(DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath);
    if (JsonGetType(jCached) == JSON_TYPE_ARRAY)
        return jCached;

    json jRawSegments = SplitTopLevelToken(sPropertyPath, DAZSCRIPT_PROPERTY_CHAIN_SYMBOL, TRUE);
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
    int nLength = GetStringLength(sPropertySegment);
    int nParameterStart = FindPropertyCallStart(sPropertySegment);

    string sProperty, sParameters;
    if (nParameterStart == -1)
        sProperty = sPropertySegment;
    else
    {
        sProperty = trim(GetStringLeft(sPropertySegment, nParameterStart));
        int nParameterEnd = FindMatchingPropertyCallParen(sPropertySegment, nParameterStart);

        if (nParameterEnd <= -2)
        {
            int nErrorAt = -nParameterEnd - 2;
            json jError = MakeParserError("UNEXPECTED_CLOSING_BRACE", nErrorAt, sPropertySegment);
            return MakeParserErrorPropertySegment(sProperty, "", jError);
        }

        if (nParameterEnd == -1)
        {
            json jError = MakeParserError("UNTERMINATED_PROPERTY_CALL", nLength, sPropertySegment);
            return MakeParserErrorPropertySegment(sProperty, "", jError);
        }

        sParameters = GetSubString(sPropertySegment, nParameterStart + 1, nParameterEnd - nParameterStart - 1);

        string sRemainder = trim(GetSubString(sPropertySegment, nParameterEnd + 1, nLength - nParameterEnd - 1));
        if (sRemainder != "")
        {
            json jError = MakeParserError("TRAILING_TEXT_AFTER_PROPERTY_CALL", nParameterEnd + 1, sPropertySegment);
            return MakeParserErrorPropertySegment(sProperty, sParameters, jError);
        }
    }

    json jParameterEntries = ParseParameterEntries(sParameters);
    json jCompiledParameters = CompileParsedParameters(sParameters, jParameterEntries);

    json jSegment = JsonArray();
    JsonArrayInsertStringInplace(jSegment, GetStringLowerCase(sProperty));
    JsonArrayInsertStringInplace(jSegment, sParameters);
    JsonArrayInsertInplace(jSegment, jCompiledParameters);
    JsonArrayInsertInplace(jSegment, jParameterEntries);

    return jSegment;
}

json ParseParameterEntries(string sParameters)
{
    if (sParameters == "")
        return JsonArray();
    json jEntries = GetCachedJson(DAZSCRIPT_PARAMETER_ENTRY_CACHE_PREFIX, sParameters);
    if (JsonGetType(jEntries) == JSON_TYPE_ARRAY || IsParserError(jEntries))
        return jEntries;

    jEntries = JsonArray();
    string sCurrent;
    int bWasQuoted, bLastWasComma, bAfterTopLevelQuote;
    struct Parser str = ParserBegin(sParameters);

    while (!ParserAtEnd(str))
    {
        string sCharacter = ParserChar(str);
        int bRootDepth = ParserIsRootDepth(str);

        if (str.bInQuotes && IsParserEscapedCharacter(str.sSource, str.nIndex, str.nLength))
        {
            string sNext = GetSubString(str.sSource, str.nIndex + 1, 1);

            if (!bRootDepth)
                sCurrent += sCharacter;

            sCurrent += sNext;

            str = ParserAdvance(str);
            bLastWasComma = FALSE;
            continue;
        }

        if (IsParserQuote(sCharacter))
        {
            if (!str.bInQuotes)
            {
                if (bRootDepth)
                {
                    if (trim(sCurrent) == "")
                        sCurrent = "";
                }
                else
                {
                    sCurrent += sCharacter;
                }
            }
            else if (sCharacter == str.sQuoteChar)
            {
                if (bRootDepth)
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

            str = ParserAdvance(str);
            bLastWasComma = FALSE;
            continue;
        }

        if (str.bInQuotes)
        {
            sCurrent += sCharacter;
            str = ParserAdvance(str);
            bLastWasComma = FALSE;
            continue;
        }

        if (bAfterTopLevelQuote && bRootDepth)
        {
            if (sCharacter == " ")
            {
                str = ParserAdvance(str);
                bLastWasComma = FALSE;
                continue;
            }

            if (sCharacter != ",")
                return CacheParameterParserError(sParameters, "TRAILING_TEXT_AFTER_QUOTED_ARGUMENT", str.nIndex);
        }

        if (sCharacter == "," && bRootDepth)
        {
            JsonArrayInsertInplace(jEntries, MakeParameterEntry(bWasQuoted ? sCurrent : trim(sCurrent), bWasQuoted));

            sCurrent = "";
            bWasQuoted = FALSE;
            bAfterTopLevelQuote = FALSE;
            bLastWasComma = TRUE;

            str = ParserAdvance(str);
            continue;
        }

        str = ParserAdvance(str);

        if (str.bError)
            return CacheParameterParserError(sParameters, str.sErrorCode, str.nErrorAt);

        sCurrent += sCharacter;
        bLastWasComma = FALSE;
    }

    if (str.bInQuotes)
        return CacheParameterParserError(sParameters, "UNTERMINATED_QUOTE", str.nLength);
    if (str.nBraceDepth > 0)
        return CacheParameterParserError(sParameters, "UNTERMINATED_BRACE", str.nLength);
    if (str.nParenDepth > 0)
        return CacheParameterParserError(sParameters, "UNTERMINATED_PAREN", str.nLength);
    if (bLastWasComma)
        return CacheParameterParserError(sParameters, "TRAILING_COMMA_IN_ARGUMENT_LIST", str.nLength - 1);

    JsonArrayInsertInplace(jEntries, MakeParameterEntry(bWasQuoted ? sCurrent : trim(sCurrent), bWasQuoted));

    SetCachedJson(DAZSCRIPT_PARAMETER_ENTRY_CACHE_PREFIX, sParameters, jEntries);
    return jEntries;
}

json CompileParsedParameters(string sParameters, json jParameterEntries)
{
    if (IsParserError(jParameterEntries))
        return jParameterEntries;
    if (sParameters == "")
        return JsonArray();

    json jCached = GetCachedJson(DAZSCRIPT_COMPILED_PARAMETER_CACHE_PREFIX, sParameters);
    if (JsonGetType(jCached) == JSON_TYPE_ARRAY || IsParserError(jCached))
        return jCached;

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

json CompileParameters(string sParameters)
{
    json jParameterEntries = ParseParameterEntries(sParameters);
    return CompileParsedParameters(sParameters, jParameterEntries);
}

json GetCompiledParameters(struct PropertyChain strPC)
{
    json jCompiledParameters = strPC.jCurrentParameters;
    if (JsonGetType(jCompiledParameters) == JSON_TYPE_ARRAY || IsParserError(jCompiledParameters))
        return jCompiledParameters;
    return CompileParameters(strPC.sCurrentParameters);
}

json GetParameterEntries(struct PropertyChain strPC)
{
    json jParameterEntries = strPC.jCurrentParameterEntries;
    if (JsonGetType(jParameterEntries) == JSON_TYPE_ARRAY || IsParserError(jParameterEntries))
        return jParameterEntries;
    return ParseParameterEntries(strPC.sCurrentParameters);
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
    json jCompiledParameters = GetCompiledParameters(strPC);
    if (IsParserError(jCompiledParameters))
        return -1;
    return JsonGetLength(jCompiledParameters);
}

struct Value EvalCompiledParameter(struct PropertyChain strPC, int nIndex)
{
    json jCompiledParameters = GetCompiledParameters(strPC);
    if (IsParserError(jCompiledParameters))
        return GetValueFromParserError(jCompiledParameters, strPC.sCurrentProperty);
    if (nIndex < 0 || nIndex >= JsonGetLength(jCompiledParameters))
        return GetErrorValue("PARAM_INDEX_OUT_OF_RANGE");

    int bTraceEnabled = IsTraceEnabled();
    if (bTraceEnabled) { TraceEnter("arg.enter", strPC.sCurrentProperty + "[" + IntToString(nIndex + 1) + "]" + " raw=" + TraceQuoted(GetRawParameterText(strPC, nIndex))); }

    struct Value strValue = EvalTemplate(JsonArrayGet(jCompiledParameters, nIndex), strPC.jStack);

    if (bTraceEnabled) { TraceExit("arg.exit", strPC.sCurrentProperty + "[" + IntToString(nIndex + 1) + "]" + " => " + TraceValue(strValue)); }

    return strValue;
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
    struct Value strParseError = CheckParameterParserError(strPC);
    if (IsErrorValue(strParseError))
        return strParseError;

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

struct Value EvalTemplate(json jTemplate, json jStack)
{
    if (IsParserError(jTemplate))
        return GetValueFromParserError(jTemplate, "template");

    int nLength = JsonGetLength(jTemplate);

    if (nLength == 1)
    {
        json jSingleNode = JsonArrayGet(jTemplate, 0);
        int nSingleNodeType = JsonArrayGetInt(jSingleNode, 0);

        if (nSingleNodeType == DAZSCRIPT_NODE_LITERAL)
            return GetValueFromTypedLiteral(JsonArrayGetString(jSingleNode, 1));
        if (nSingleNodeType == DAZSCRIPT_NODE_EXPR)
            return EvalCompiledExpressionToValue(jSingleNode, jStack);
        if (nSingleNodeType == DAZSCRIPT_NODE_FORCE_STRING)
            return EvalTemplateToString(JsonArrayGet(jSingleNode, 1), jStack);
        return GetErrorValue("UNKNOWN_TEMPLATE_NODE:" + IntToString(nSingleNodeType));
    }

    return EvalTemplateToString(jTemplate, jStack);
}

struct Value EvalTemplateToString(json jTemplate, json jStack)
{
    if (IsParserError(jTemplate))
        return GetValueFromParserError(jTemplate, "template");

    string sResult = "";
    int nIndex, nLength = JsonGetLength(jTemplate);
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
                return strExpressionValue;
            sResult += ValueToText(strExpressionValue);
        }
        else if (nNodeType == DAZSCRIPT_NODE_FORCE_STRING)
        {
            struct Value strInnerValue = EvalTemplateToString(JsonArrayGet(jNode, 1), jStack);
            if (IsErrorValue(strInnerValue))
                return strInnerValue;
            sResult += strInnerValue.sValue;
        }
        else
        {
            return GetErrorValue("UNKNOWN_TEMPLATE_NODE:" + IntToString(nNodeType));
        }
    }

    return GetValueFromString(sResult);
}

struct Value EvalCompiledExpressionToValue(json jExpr, json jStack)
{
    int bTraceEnabled = IsTraceEnabled();
    int nKind = JsonArrayGetInt(jExpr, DAZSCRIPT_EXPR_KIND);
    string sBaseName = JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_BASE_NAME);
    json jChain = JsonArrayGet(jExpr, DAZSCRIPT_EXPR_CHAIN);
    string sBaseParameters = JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_BASE_PARAMETERS);
    string sPropertyPath = JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_PROPERTY_PATH);
    json jBaseCompiledParameters = JsonArrayGet(jExpr, DAZSCRIPT_EXPR_BASE_COMPILED_PARAMETERS);

    if (bTraceEnabled) { TraceEnter("expr.enter", "kind=" + TraceExprKind(nKind) + "; base=" + sBaseName + "; params=" + TraceQuoted(sBaseParameters) + "; chain=" + TraceQuoted(sPropertyPath)); }

    struct Value strValue;

    if (nKind == DAZSCRIPT_EXPR_VAR)
        strValue = GetStackValue(jStack, sBaseName);
    else if (nKind == DAZSCRIPT_EXPR_ALIAS)
        strValue = ResolveAliasValue(jStack, sBaseName);
    else if (nKind == DAZSCRIPT_EXPR_META)
        strValue = ResolveMetaValue(jStack, sBaseName, sBaseParameters, jBaseCompiledParameters);
    else if (nKind == DAZSCRIPT_EXPR_FUNCTION)
        strValue = ResolveFunctionValue(jStack, sBaseName, sBaseParameters, jBaseCompiledParameters);

    int bHasPropertyChain = (JsonGetLength(jChain) > 0);
    int bTraceBaseValue = bTraceEnabled;

    if ((nKind == DAZSCRIPT_EXPR_META || nKind == DAZSCRIPT_EXPR_FUNCTION) && !bHasPropertyChain)
        bTraceBaseValue = FALSE;

    if (bTraceBaseValue) { Trace("base.value", sBaseName + " => " + TraceValue(strValue)); }

    if (IsErrorValue(strValue))
    {
        if (bTraceEnabled) { TraceExit("expr.exit", TraceValue(strValue)); }
        return strValue;
    }

    if (IsInvalidValue(strValue))
    {
        strValue = GetErrorValue("INVALID_EXPR:" + sBaseName);
        if (bTraceEnabled) { TraceExit("expr.exit", TraceValue(strValue)); }
        return strValue;
    }

    if (bHasPropertyChain)
    {
        struct PropertyChain strPC;
        strPC.jStack = jStack;
        strPC.sBaseVarName = sBaseName;
        strPC.sFullPropertyPath = sPropertyPath;
        strPC.strValue = strValue;

        if (bTraceEnabled) { TraceEnter("chain.enter", "base=" + sBaseName + "; chain=" + TraceQuoted(sPropertyPath) + "; input=" + TraceValue(strValue)); }

        strPC = EvalCompiledPropertyChain(strPC, jChain);

        if (IsErrorValue(strPC.strValue))
        {
            if (GetStringLeft(strPC.strValue.sErrorMessage, 12) == "PARSE_ERROR:")
                strValue = strPC.strValue;
            else
                strValue = GetErrorValue("INVALID_PROPERTY_CHAIN:" + sBaseName + ">" + sPropertyPath + " -> FAILED@" + strPC.sCurrentProperty + " -> " + strPC.strValue.sErrorMessage);

            if (bTraceEnabled) { TraceExit("chain.exit", "base=" + sBaseName + "; chain=" + TraceQuoted(sPropertyPath) + "; result=" + TraceValue(strValue)); TraceExit("expr.exit", TraceValue(strValue)); }
            return strValue;
        }

        if (IsInvalidValue(strPC.strValue))
        {
            strValue = GetErrorValue("INVALID_PROPERTY_CHAIN:" + sBaseName + ">" + sPropertyPath + " -> FAILED@" + strPC.sCurrentProperty);
            if (bTraceEnabled) { TraceExit("chain.exit", "base=" + sBaseName + "; chain=" + TraceQuoted(sPropertyPath) + "; result=" + TraceValue(strValue)); TraceExit("expr.exit", TraceValue(strValue)); }
            return strValue;
        }

        strValue = strPC.strValue;
        if (bTraceEnabled) { TraceExit("chain.exit", "base=" + sBaseName + "; chain=" + TraceQuoted(sPropertyPath) + "; result=" + TraceValue(strValue)); }
    }

    if (bTraceEnabled) { TraceExit("expr.exit", TraceValue(strValue)); }
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
    if (!IsAliasEntry(jEntry))
        return GetErrorValue("INVALID_ALIAS:" + sAliasName);
    if (IsErrorAliasEntry(jEntry))
        return GetErrorValue(GetAliasStoredValueAsString(jEntry));
    int nAuxType = JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_TYPE);
    if (!IsKnownAuxType(nAuxType))
        return GetErrorValue("INVALID_ALIAS_TYPE:" + sAliasName);

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
        case NWNX_VM_AUXTYPE_STRING:
            return GetValueFromString(GetAliasStoredValueAsString(jEntry));
        case NWNX_VM_AUXTYPE_OBJECT:
            return GetValueFromObject(StringToObject(GetAliasStoredValueAsString(jEntry)));
        case NWNX_VM_AUXTYPE_JSON:
            return GetValueFromJson(jValue);
    }

    return GetErrorValue("INVALID_ALIAS_TYPE:" + sAliasName);
}

struct Value ResolveMetaValue(json jStack, string sMetaName, string sBaseParameters, json jBaseCompiledParameters)
{
    int bTraceEnabled = IsTraceEnabled();
    if (bTraceEnabled) { TraceEnter("meta.enter", "base=" + sMetaName + "; params=" + TraceQuoted(sBaseParameters)); }

    struct PropertyChain strMeta;
    strMeta.jStack = jStack;
    strMeta.sCurrentProperty = sMetaName;
    strMeta.sCurrentParameters = sBaseParameters;
    strMeta.jCurrentParameters = jBaseCompiledParameters;

    struct Value strReturnValue = CheckParameterParserError(strMeta);

    if (!IsErrorValue(strReturnValue))
    {
        strReturnValue = GetInvalidValue();

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
            strReturnValue = HandleMetaOutput(strMeta, sMetaName);

        if (IsInvalidValue(strReturnValue))
            strReturnValue = HandleMetaMath(strMeta, sMetaName);

        if (IsInvalidValue(strReturnValue))
            strReturnValue = HandleMetaObject(strMeta, sMetaName);

        if (IsInvalidValue(strReturnValue))
            strReturnValue = GetErrorValue("UNKNOWN_META:" + sMetaName);
    }

    if (bTraceEnabled) { TraceExit("meta.exit", sMetaName + " => " + TraceValue(strReturnValue)); }

    return strReturnValue;
}

struct Value ResolveFunctionValue(json jStack, string sFunctionName, string sBaseParameters, json jBaseCompiledParameters)
{
    int bTraceEnabled = IsTraceEnabled();
    if (bTraceEnabled) { TraceEnter("fn.enter", "base=" + sFunctionName + "; params=" + TraceQuoted(sBaseParameters)); }

    struct Value strReturnValue = GetInvalidValue();

    if (!JsonObjectContainsKey(jStack, sFunctionName))
        strReturnValue = GetErrorValue("UNKNOWN_FUNCTION:" + sFunctionName);
    else
    {
        json jFunction = JsonObjectGet(jStack, sFunctionName);
        if (!IsFunctionEntry(jFunction))
            strReturnValue = GetErrorValue("INVALID_FUNCTION:" + sFunctionName);
        else
        {
            json jArgNames = JsonObjectGet(jFunction, DAZSCRIPT_FUNCTION_ARGS);
            json jBody = JsonObjectGet(jFunction, DAZSCRIPT_FUNCTION_BODY_COMPILED);

            if (JsonGetType(jBody) != JSON_TYPE_ARRAY)
                strReturnValue = GetErrorValue("INVALID_FUNCTION_BODY:" + sFunctionName);
            else
            {
                struct PropertyChain strFunction;
                strFunction.jStack = jStack;
                strFunction.sCurrentProperty = sFunctionName;
                strFunction.sCurrentParameters = sBaseParameters;
                strFunction.jCurrentParameters = jBaseCompiledParameters;

                strReturnValue = CheckParameterParserError(strFunction);

                if (!IsErrorValue(strReturnValue))
                {
                    json jCompiledParameters = GetCompiledParameters(strFunction);
                    if (JsonGetLength(jCompiledParameters) != JsonGetLength(jArgNames))
                        strReturnValue = GetErrorValue("FUNCTION_ARITY:" + sFunctionName);
                    else
                    {
                        json jFrame = JsonCopyObject(jStack);
                        int nIndex, nNumArgs = JsonGetLength(jArgNames);
                        for (nIndex = 0; nIndex < nNumArgs; nIndex++)
                        {
                            string sArgName = JsonArrayGetString(jArgNames, nIndex);

                            if (bTraceEnabled) { TraceEnter("arg.enter", sFunctionName + "[" + IntToString(nIndex + 1) + "]" + " raw=" + TraceQuoted(GetRawParameterText(strFunction, nIndex))); }

                            struct Value strArgValue = EvalTemplate(JsonArrayGet(jCompiledParameters, nIndex), jStack);

                            if (bTraceEnabled) { TraceExit("arg.exit", sFunctionName + "[" + IntToString(nIndex + 1) + "]" + " => " + TraceValue(strArgValue)); }

                            if (IsErrorValue(strArgValue))
                            {
                                strReturnValue = strArgValue;
                                break;
                            }

                            if (bTraceEnabled) { Trace("fn.arg", sFunctionName + ":" + sArgName + " => " + TraceValue(strArgValue)); }

                            JsonObjectSetInplace(jFrame, sArgName, MakeStackAliasEntryFromValue(strArgValue));
                        }

                        if (!IsErrorValue(strReturnValue))
                            strReturnValue = EvalTemplate(jBody, jFrame);
                    }
                }
            }
        }
    }

    if (bTraceEnabled) { TraceExit("fn.exit", sFunctionName + " => " + TraceValue(strReturnValue)); }

    return strReturnValue;
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
    int bTraceEnabled = IsTraceEnabled();
    int nSegment, nNumSegments = JsonGetLength(jSegments);
    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        strPC = ApplyCompiledPropertySegment(strPC, JsonArrayGet(jSegments, nSegment));

        if (bTraceEnabled) { TraceEnter("prop.enter", "segment=" + IntToString(nSegment + 1) + "; property=" + strPC.sCurrentProperty + "; params=" + TraceQuoted(strPC.sCurrentParameters) + "; input=" + TraceValue(strPC.strValue)); }

        strPC = GetPropertyValueByType(strPC);

        if (IsInvalidValue(strPC.strValue))
            strPC.strValue = GetErrorValue("UNKNOWN_PROPERTY:" + strPC.sCurrentProperty);

        if (bTraceEnabled) { TraceExit("prop.exit", strPC.sCurrentProperty + " => " + TraceValue(strPC.strValue)); }

        if (IsErrorValue(strPC.strValue))
            break;
    }
    return strPC;
}

struct PropertyChain GetPropertyValueByType(struct PropertyChain strPC)
{
    struct Value strParseError = CheckParameterParserError(strPC);
    if (IsErrorValue(strParseError))
    {
        strPC.strValue = strParseError;
        return strPC;
    }

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

struct PropertyChain ReturnPropertyChainWithValue(struct PropertyChain strPC, struct Value strValue)
{
    strPC.strValue = strValue;
    return strPC;
}

struct PropertyChain GetIntProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    int nValue = strPC.strValue.nValue;

    if (sProperty == "abs")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(abs(nValue)));

    if (sProperty == "eq" || sProperty == "neq" || sProperty == "gt" || sProperty == "gte" || sProperty == "lt" || sProperty == "lte")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        int nCompare = GetValueAsInt(strArgs.strArg0);
        if (sProperty == "eq")  return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue == nCompare));
        if (sProperty == "neq") return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue != nCompare));
        if (sProperty == "gt")  return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue > nCompare));
        if (sProperty == "gte") return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue >= nCompare));
        if (sProperty == "lt")  return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue < nCompare));
        if (sProperty == "lte") return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue <= nCompare));
    }

    if (sProperty == "min" || sProperty == "max")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        int nOther = GetValueAsInt(strArgs.strArg0);
        if (sProperty == "min")
            return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue < nOther ? nValue : nOther));
        else
            return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue > nOther ? nValue : nOther));
    }

    if (sProperty == "clamp")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(clamp(nValue, GetValueAsInt(strArgs.strArg0), GetValueAsInt(strArgs.strArg1))));
    }

    if (sProperty == "mod")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        int nDivisor = GetValueAsInt(strArgs.strArg0);
        if (nDivisor != 0)
            return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue % nDivisor));
        else
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("DIVISION_BY_ZERO"));
    }

    if (sProperty == "then")
    {
        struct Value strError = CheckArity(strPC, 2, 2);
        if (IsErrorValue(strError))
            return ReturnPropertyChainWithValue(strPC, strError);
        return ReturnPropertyChainWithValue(strPC, EvalCompiledParameter(strPC, nValue != 0 ? 0 : 1));
    }

    if (sProperty == "plural")
    {
        struct Value strError = CheckArity(strPC, 1, 2);
        if (IsErrorValue(strError))
            return ReturnPropertyChainWithValue(strPC, strError);
        if (GetParameterCount(strPC) == 1)
        {
            if (nValue == 1)
                return ReturnPropertyChainWithValue(strPC, GetValueFromString());
            else
                return ReturnPropertyChainWithValue(strPC, EvalCompiledParameter(strPC, 0));
        }
        else
            return ReturnPropertyChainWithValue(strPC, EvalCompiledParameter(strPC, nValue != 1));
    }

    if (sProperty == "incr")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue + 1));

    if (sProperty == "decr")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue - 1));

    if (sProperty == "even" || sProperty == "odd")
    {
        if (sProperty == "even")
            return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue % 2 == 0));
        else
            return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nValue % 2 != 0));
    }

    return ReturnPropertyChainWithValue(strPC, GetInvalidValue());
}

struct PropertyChain GetFloatProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    float fValue = strPC.strValue.fValue;

    if (sProperty == "fabs")
        return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(fabs(fValue)));

    if (sProperty == "floor")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(floor(fValue)));

    if (sProperty == "ceil")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(ceil(fValue)));

    if (sProperty == "round")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(round(fValue)));

    if (sProperty == "eq" || sProperty == "neq" || sProperty == "gt" || sProperty == "gte" || sProperty == "lt" || sProperty == "lte")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_NUMERIC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        float fCompare = GetValueAsFloat(strArgs.strArg0);
        float fDiff = fValue - fCompare;
        if (sProperty == "eq")  return ReturnPropertyChainWithValue(strPC, GetValueFromInt(fabs(fDiff) < FLOAT_EPSILON));
        if (sProperty == "neq") return ReturnPropertyChainWithValue(strPC, GetValueFromInt(fabs(fDiff) >= FLOAT_EPSILON));
        if (sProperty == "gt")  return ReturnPropertyChainWithValue(strPC, GetValueFromInt(fDiff > FLOAT_EPSILON));
        if (sProperty == "gte") return ReturnPropertyChainWithValue(strPC, GetValueFromInt(fDiff >= -FLOAT_EPSILON));
        if (sProperty == "lt")  return ReturnPropertyChainWithValue(strPC, GetValueFromInt(fDiff < -FLOAT_EPSILON));
        if (sProperty == "lte") return ReturnPropertyChainWithValue(strPC, GetValueFromInt(fDiff <= FLOAT_EPSILON));
    }

    if (sProperty == "min" || sProperty == "max")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_NUMERIC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        float fOther = GetValueAsFloat(strArgs.strArg0);
        if (sProperty == "min")
            return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(fValue < fOther ? fValue : fOther));
        else
            return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(fValue > fOther ? fValue : fOther));
    }

    if (sProperty == "clamp")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);
        return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(clampf(fValue, GetValueAsFloat(strArgs.strArg0), GetValueAsFloat(strArgs.strArg1))));
    }

    return ReturnPropertyChainWithValue(strPC, GetInvalidValue());
}

struct PropertyChain GetStringProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    string sValue = strPC.strValue.sValue;

    if (sProperty == "length")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetStringLength(sValue)));

    if (sProperty == "upper")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetStringUpperCase(sValue)));

    if (sProperty == "lower")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetStringLowerCase(sValue)));

    if (sProperty == "trim")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(trim(sValue)));

    if (sProperty == "empty")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(sValue == ""));

    if (sProperty == "notempty")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(sValue != ""));

    if (sProperty == "contains")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(FindSubString(sValue, GetValueAsText(strArgs.strArg0), 0) != -1));
    }

    if (sProperty == "startswith")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(IsStringPrefix(sValue, GetValueAsText(strArgs.strArg0))));
    }

    if (sProperty == "endswith")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(IsStringSuffix(sValue, GetValueAsText(strArgs.strArg0))));
    }

    if (sProperty == "substring")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        int nStart = GetValueAsInt(strArgs.strArg0);
        int nCount = GetStringLength(sValue) - nStart;
        if (strArgs.nCount == 2)
            nCount = GetValueAsInt(strArgs.strArg1);
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetSubString(sValue, nStart, nCount)));
    }

    if (sProperty == "left" || sProperty == "right")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        int nLength = GetValueAsInt(strArgs.strArg0);
        if (sProperty == "left")
            return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetStringLeft(sValue, nLength)));
        else
            return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetStringRight(sValue, nLength)));
    }

    if (sProperty == "replace")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        string sSearch = NWNX_Util_RegExpEscape(GetValueAsText(strArgs.strArg0));
        string sReplace = GetValueAsText(strArgs.strArg1);
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(RegExpReplace(sSearch, sValue, sReplace)));
    }

    if (sProperty == "eq" || sProperty == "neq")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        string sCompare = GetValueAsText(strArgs.strArg0);
        int nResult = sProperty == "eq" ? sValue == sCompare : sValue != sCompare;
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nResult));
    }

    if (sProperty == "capitalize")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(CapitalizeWord(sValue)));

    if (sProperty == "append" || sProperty == "prepend")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        string sOther = GetValueAsText(strArgs.strArg0);
        if (sProperty == "append")
            return ReturnPropertyChainWithValue(strPC, GetValueFromString(sValue + sOther));
        else
            return ReturnPropertyChainWithValue(strPC, GetValueFromString(sOther + sValue));
    }

    return ReturnPropertyChainWithValue(strPC, GetInvalidValue());
}

struct PropertyChain GetObjectProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    object oValue = strPC.strValue.oValue;

    if (!GetIsObjectValid(oValue) && sProperty != "valid")
        return ReturnPropertyChainWithValue(strPC, GetErrorValue("INVALID_OBJECT:SELF"));

    if (sProperty == "name")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetName(oValue)));

    if (sProperty == "tag")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetTag(oValue)));

    if (sProperty == "resref")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetResRef(oValue)));

    if (sProperty == "type")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetObjectTypeName(oValue)));

    if (sProperty == "area")
        return ReturnPropertyChainWithValue(strPC, GetValueFromObject(GetArea(oValue)));

    if (sProperty == "valid")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetIsObjectValid(oValue)));

    if (sProperty == "inspect")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(InspectObject(oValue)));

    if (sProperty == "ispc")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetIsPlayer(oValue)));

    if (sProperty == "isdm")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetIsDM(oValue)));

    if (sProperty == "isplayerdm")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetIsPlayerDM(oValue)));

    if (sProperty == "dead")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetIsDead(oValue)));

    if (sProperty == "hp")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetCurrentHitPoints(oValue)));

    if (sProperty == "maxhp")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetMaxHitPoints(oValue)));

    if (sProperty == "distance")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_OBJECT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        object oOther = GetValueAsObject(strArgs.strArg0);
        if (!GetIsObjectValid(oOther))
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("INVALID_OBJECT:ARG1"));
        else
            return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(GetDistanceBetween(oValue, oOther)));
    }

    if (sProperty == "x" || sProperty == "y" || sProperty == "z")
    {
        vector vPosition = GetPosition(oValue);
        if (sProperty == "x")   return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(vPosition.x));
        if (sProperty == "y")   return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(vPosition.y));
        if (sProperty == "z")   return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(vPosition.z));
    }

    if (sProperty == "position")
    {
        struct Arguments strArgs = EvalArgs(strPC, 0, 1, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        int nPrecision = 2;
        if (strArgs.nCount == 1)
            nPrecision = GetValueAsInt(strArgs.strArg0, 2);
        nPrecision = clamp(nPrecision, 0, 9);

        vector vPosition = GetPosition(oValue);
        string sX = ValueToText(FormatValueAsFixed(GetValueFromFloat(vPosition.x), nPrecision));
        string sY = ValueToText(FormatValueAsFixed(GetValueFromFloat(vPosition.y), nPrecision));
        string sZ = ValueToText(FormatValueAsFixed(GetValueFromFloat(vPosition.z), nPrecision));
        return ReturnPropertyChainWithValue(strPC, GetValueFromString("[" + sX + "," + sY + "," + sZ + "]"));
    }

    if (sProperty == "facing")
        return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(GetFacing(oValue)));

    if (sProperty == "localvar")
    {
        struct Arguments strArgs = EvalTwoArgs(strPC);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        string sType = GetStringLowerCase(GetValueAsTrimmedString(strArgs.strArg0));
        if (sType == "i")
            return ReturnPropertyChainWithValue(strPC, GetValueFromInt(GetLocalInt(oValue, GetValueAsTrimmedString(strArgs.strArg1))));
        else if (sType == "f")
            return ReturnPropertyChainWithValue(strPC, GetValueFromFloat(GetLocalFloat(oValue, GetValueAsTrimmedString(strArgs.strArg1))));
        else if (sType == "s")
            return ReturnPropertyChainWithValue(strPC, GetValueFromString(GetLocalString(oValue, GetValueAsTrimmedString(strArgs.strArg1))));
        else if (sType == "o")
            return ReturnPropertyChainWithValue(strPC, GetValueFromObject(GetLocalObject(oValue, GetValueAsTrimmedString(strArgs.strArg1))));
        else if (sType == "j")
            return ReturnPropertyChainWithValue(strPC, GetValueFromJson(GetLocalJson(oValue, GetValueAsTrimmedString(strArgs.strArg1))));
        else
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("INVALID_LOCALVAR_TYPE:" + sType));
    }

    return ReturnPropertyChainWithValue(strPC, GetInvalidValue());
}

struct PropertyChain GetJsonProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;
    json jValue = strPC.strValue.jValue;

    if (sProperty == "type")
    {
        switch (JsonGetType(jValue))
        {
            case JSON_TYPE_NULL:    return ReturnPropertyChainWithValue(strPC, GetValueFromString("null"));
            case JSON_TYPE_OBJECT:  return ReturnPropertyChainWithValue(strPC, GetValueFromString("object"));
            case JSON_TYPE_ARRAY:   return ReturnPropertyChainWithValue(strPC, GetValueFromString("array"));
            case JSON_TYPE_STRING:  return ReturnPropertyChainWithValue(strPC, GetValueFromString("string"));
            case JSON_TYPE_INTEGER: return ReturnPropertyChainWithValue(strPC, GetValueFromString("int"));
            case JSON_TYPE_FLOAT:   return ReturnPropertyChainWithValue(strPC, GetValueFromString("float"));
            case JSON_TYPE_BOOL:    return ReturnPropertyChainWithValue(strPC, GetValueFromString("bool"));
            default:                return ReturnPropertyChainWithValue(strPC, GetValueFromString("invalid"));
        }
    }

    if (sProperty == "isnull")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_NULL));

    if (sProperty == "isobject")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_OBJECT));

    if (sProperty == "isarray")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_ARRAY));

    if (sProperty == "isstring")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_STRING));

    if (sProperty == "isint" || sProperty == "isinteger")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_INTEGER));

    if (sProperty == "isfloat")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_FLOAT));

    if (sProperty == "isnumber")
    {
        int nType = JsonGetType(jValue);
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(nType == JSON_TYPE_INTEGER || nType == JSON_TYPE_FLOAT));
    }

    if (sProperty == "isbool")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonGetType(jValue) == JSON_TYPE_BOOL));

    if (sProperty == "scalar")
    {
        int nType = JsonGetType(jValue);
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(
            nType == JSON_TYPE_NULL || nType == JSON_TYPE_STRING ||
            nType == JSON_TYPE_INTEGER || nType == JSON_TYPE_FLOAT ||
            nType == JSON_TYPE_BOOL));
    }

    if (sProperty == "length")
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonGetLength(jValue)));

    if (sProperty == "empty" || sProperty == "notempty")
    {
        int nType = JsonGetType(jValue), bEmpty = FALSE;

        if (nType == JSON_TYPE_NULL)
            bEmpty = TRUE;
        else if (nType == JSON_TYPE_STRING)
            bEmpty = JsonGetString(jValue) == "";
        else if (nType == JSON_TYPE_ARRAY || nType == JSON_TYPE_OBJECT)
            bEmpty = JsonGetLength(jValue) == 0;

        if (sProperty == "notempty")
            bEmpty = !bEmpty;

        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(bEmpty));
    }

    if (sProperty == "has")
    {
        struct Arguments strArgs = EvalOneArg(strPC, DAZSCRIPT_ARG_STRING);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);
        if (JsonGetType(jValue) != JSON_TYPE_OBJECT)
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("JSON_NOT_OBJECT"));
        return ReturnPropertyChainWithValue(strPC, GetValueFromInt(JsonObjectContainsKey(jValue, GetValueAsText(strArgs.strArg0))));
    }

    if (sProperty == "get")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_STRING, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);
        if (JsonGetType(jValue) != JSON_TYPE_OBJECT)
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("JSON_NOT_OBJECT"));

        string sKey = GetValueAsText(strArgs.strArg0);
        if (JsonObjectContainsKey(jValue, sKey))
            return ReturnPropertyChainWithValue(strPC, ConvertJsonToValue(JsonObjectGet(jValue, sKey)));
        else if (strArgs.nCount == 2)
            return ReturnPropertyChainWithValue(strPC, strArgs.strArg1);
        else
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("JSON_MISSING_KEY:" + sKey));
    }

    if (sProperty == "at")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);
        if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("JSON_NOT_ARRAY"));

        int nIndex = GetValueAsInt(strArgs.strArg0), nLength = JsonGetLength(jValue);
        if (nIndex < 0)
            nIndex = nLength + nIndex;

        if (nIndex >= 0 && nIndex < nLength)
            return ReturnPropertyChainWithValue(strPC, ConvertJsonToValue(JsonArrayGet(jValue, nIndex)));
        else if (strArgs.nCount == 2)
            return ReturnPropertyChainWithValue(strPC, strArgs.strArg1);
        else
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("JSON_INDEX_OUT_OF_RANGE:" + IntToString(nIndex)));
    }

    if (sProperty == "first" || sProperty == "last")
    {
        struct Arguments strArgs = EvalArgs(strPC, 0, 1, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("JSON_NOT_ARRAY"));

        int nLength = JsonGetLength(jValue);
        if (nLength <= 0)
        {
            if (strArgs.nCount == 1)
                return ReturnPropertyChainWithValue(strPC, strArgs.strArg0);
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("JSON_INDEX_OUT_OF_RANGE:0"));
        }

        int nIndex = sProperty == "first" ? 0 : nLength - 1;
        return ReturnPropertyChainWithValue(strPC, ConvertJsonToValue(JsonArrayGet(jValue, nIndex)));
    }

    if (sProperty == "keys")
    {
        if (JsonGetType(jValue) != JSON_TYPE_OBJECT)
            return ReturnPropertyChainWithValue(strPC, GetErrorValue("JSON_NOT_OBJECT"));
        return ReturnPropertyChainWithValue(strPC, GetValueFromJson(JsonObjectKeys(jValue)));
    }

    if (sProperty == "raw" || sProperty == "dump")
        return ReturnPropertyChainWithValue(strPC, GetValueFromString(JsonDump(jValue)));

    return ReturnPropertyChainWithValue(strPC, GetInvalidValue());
}

struct PropertyChain GetSharedProperty(struct PropertyChain strPC)
{
    string sProperty = strPC.sCurrentProperty;

    if (sProperty == "color")
    {
        int nNumParameters = GetParameterCount(strPC);
        if (nNumParameters == 1)
        {
            struct Arguments strArgs = EvalOneArg(strPC);
            if (IsErrorValue(strArgs.strError))
                return ReturnPropertyChainWithValue(strPC, strArgs.strError);

            string sValue = ValueToText(strPC.strValue);
            string sColor = GetStringLowerCase(GetValueAsTrimmedString(strArgs.strArg0));
            if (GetStringLeft(sColor, 1) == "#")
                return ReturnPropertyChainWithValue(strPC, GetValueFromHexColor(sValue, sColor));
            else
                return ReturnPropertyChainWithValue(strPC, GetValueFromNamedColor(sValue, sColor));
        }

        if (nNumParameters == 3)
        {
            struct Arguments strArgs = EvalThreeArgs(strPC, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                return ReturnPropertyChainWithValue(strPC, strArgs.strError);
            return ReturnPropertyChainWithValue(strPC, GetValueFromString(ColorString(ValueToText(strPC.strValue), GetValueAsInt(strArgs.strArg0), GetValueAsInt(strArgs.strArg1), GetValueAsInt(strArgs.strArg2))));
        }
        return ReturnPropertyChainWithValue(strPC, GetErrorValue("ARITY:EXPECTED_1_OR_3_ARGUMENTS"));
    }

    if (sProperty == "padleft" || sProperty == "padright")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_ANY);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        int nLength = GetValueAsInt(strArgs.strArg0);
        string sPadding = " ";
        if (strArgs.nCount >= 2)
            sPadding = GetValueAsText(strArgs.strArg1, " ");
        if (sProperty == "padleft")
            return ReturnPropertyChainWithValue(strPC, GetValueFromString(LeftPadString(ValueToText(strPC.strValue), nLength, sPadding)));
        else
            return ReturnPropertyChainWithValue(strPC, GetValueFromString(RightPadString(ValueToText(strPC.strValue), nLength, sPadding)));
    }

    if (sProperty == "int")
        return ReturnPropertyChainWithValue(strPC, CastValueToAuxType(strPC.strValue, NWNX_VM_AUXTYPE_INT));

    if (sProperty == "float")
        return ReturnPropertyChainWithValue(strPC, CastValueToAuxType(strPC.strValue, NWNX_VM_AUXTYPE_FLOAT));

    if (sProperty == "string")
        return ReturnPropertyChainWithValue(strPC, CastValueToAuxType(strPC.strValue, NWNX_VM_AUXTYPE_STRING));

    if (sProperty == "fixed")
    {
        struct Arguments strArgs = EvalArgs(strPC, 0, 1, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return ReturnPropertyChainWithValue(strPC, strArgs.strError);

        int nPrecision = 2;
        if (strArgs.nCount == 1)
            nPrecision = GetValueAsInt(strArgs.strArg0, 2);
        return ReturnPropertyChainWithValue(strPC, FormatValueAsFixed(strPC.strValue, nPrecision));
    }

    if (sProperty == "hex")
        return ReturnPropertyChainWithValue(strPC, FormatValueAsHex(strPC.strValue));

    if (sProperty == "bool")
        return ReturnPropertyChainWithValue(strPC, FormatValueAsBoolean(strPC.strValue));

    if (sProperty == "default")
    {
        struct Value strError = CheckArity(strPC, 1, 1);
        if (IsErrorValue(strError))
            return ReturnPropertyChainWithValue(strPC, strError);
        if (ValueNeedsDefault(strPC.strValue))
            return ReturnPropertyChainWithValue(strPC, EvalCompiledParameter(strPC, 0));
        else
            return ReturnPropertyChainWithValue(strPC, strPC.strValue);
    }

    return ReturnPropertyChainWithValue(strPC, GetInvalidValue());
}

struct Value HandleMetaPrimitive(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "int" || sMetaName == "float" || sMetaName == "string" || sMetaName == "object" || sMetaName == "json")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;
        return CastValueToAuxType(strArgs.strArg0, GetCastAuxTypeFromName(sMetaName));
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

        if (IsParserError(jCompiledBody))
            return GetValueFromParserError(jCompiledBody, "function_body");
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

        int nBranch = ValueToBoolish(strCondition) ? 1 : 2;

        if (IsTraceEnabled()) { Trace("if.branch", nBranch == 1 ? "then[1]" : "else[2]"); }

        return EvalCompiledParameter(strPC, nBranch);
    }

    if (sMetaName == "while")
    {
        struct Value strError = CheckArity(strPC, 2, 3);
        if (IsErrorValue(strError))
            return strError;

        int nIterations = 0, nLimit = DAZSCRIPT_WHILE_DEFAULT_ITERATION_LIMIT;
        if (GetParameterCount(strPC) == 3)
        {
            struct Value strLimit = EvalTypedParameter(strPC, 2, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strLimit))
                return strLimit;
            nLimit = clamp(GetValueAsInt(strLimit), 0, DAZSCRIPT_WHILE_MAX_ITERATION_LIMIT);
        }
        int bTraceEnabled = IsTraceEnabled();
        if (bTraceEnabled) { Trace("while.start", "limit=" + IntToString(nLimit)); }

        string sAccumulator;
        while (TRUE)
        {
            struct Value strConditionResult = EvalCompiledParameter(strPC, 0);
            if (IsErrorValue(strConditionResult))
                return strConditionResult;

            if (!ValueToBoolish(strConditionResult))
            {
                if (bTraceEnabled) { Trace("while.exit", "iterations=" + IntToString(nIterations) + "; reason=condition_false"); }
                break;
            }

            if (nIterations >= nLimit)
            {
                struct Value strLimitError = GetErrorValue("WHILE_ITERATION_LIMIT");
                if (bTraceEnabled) { Trace("while.exit", "iterations=" + IntToString(nIterations) + "; reason=limit; " + TraceValue(strLimitError)); }
                return strLimitError;
            }

            int nIteration = nIterations;
            if (bTraceEnabled) TraceEnter("while.iter.start", "iteration=" + IntToString(nIteration));

            nIterations++;
            struct Value strBodyResult = EvalCompiledParameter(strPC, 1);

            if (bTraceEnabled) { TraceExit("while.iter.exit", "iteration=" + IntToString(nIteration) + "; result=" + TraceValue(strBodyResult)); }

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

    if (sMetaName == "switch")
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

        int nIndex, nEnd = nDefaultIndex == -1 ? nCount : nDefaultIndex;
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

    if (sMetaName == "try")
    {
        struct Value strError = CheckArity(strPC, 2, -1);
        if (IsErrorValue(strError))
            return strError;

        int nIndex, nCount = GetParameterCount(strPC);
        struct Value strLastError = GetInvalidValue();

        for (nIndex = 0; nIndex < nCount; nIndex++)
        {
            struct Value strCandidate = EvalCompiledParameter(strPC, nIndex);
            if (!IsErrorValue(strCandidate))
                return strCandidate;
            strLastError = strCandidate;
        }

        return strLastError;
    }

    if (sMetaName == "do")
    {
        int nCount = GetParameterCount(strPC);
        if (nCount < 1)
            return GetErrorValue("ARITY:EXPECTED_AT_LEAST_1_ARGUMENT");

        int nIndex;
        struct Value strResult = GetValueFromString();
        for (nIndex = 0; nIndex < nCount; nIndex++)
        {
            strResult = EvalCompiledParameter(strPC, nIndex);
            if (IsErrorValue(strResult))
                return strResult;
        }
        return strResult;
    }

    return GetInvalidValue();
}

struct Value HandleMetaVariable(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "let")
    {
        struct Value strError = CheckArity(strPC, 3, -1);
        if (IsErrorValue(strError))
            return strError;

        int nCount = GetParameterCount(strPC);
        if (nCount % 2 != 1)
            return GetErrorValue("LET_EXPECTS_BINDINGS_PLUS_BODY");

        json jCompiledParameters = GetCompiledParameters(strPC);
        json jFrame = JsonCopyObject(strPC.jStack);

        int nIndex;
        for (nIndex = 0; nIndex < nCount - 1; nIndex += 2)
        {
            string sAlias = GetRawParameterText(strPC, nIndex);
            if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("LET_ALIAS_IS_NON_ALIAS:" + sAlias);

            struct Value strValue = EvalTemplate(JsonArrayGet(jCompiledParameters, nIndex + 1), jFrame);
            if (IsErrorValue(strValue))
                return strValue;

            JsonObjectSetInplace(jFrame, sAlias, MakeStackAliasEntryFromValue(strValue));
        }

        return EvalTemplate(JsonArrayGet(jCompiledParameters, nCount - 1), jFrame);
    }

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
        int nAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);
        int nStackLocation = JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY);

        return SetStackLocationFromValue(nAuxType, nStackLocation, strValue);
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

struct Value HandleMetaOutput(struct PropertyChain strPC, string sMetaName)
{
    if (sMetaName == "tellpc")
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

    if (sMetaName == "print")
    {
        struct Arguments strArgs = EvalOneArg(strPC);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        PrintString(GetValueAsText(strArgs.strArg0));
        return GetValueFromString();
    }

    if (sMetaName == "trace")
    {
        PushTrace();

        struct Arguments strArgs = EvalOneArg(strPC);

        if (IsErrorValue(strArgs.strError))
        {
            Trace("trace.value", TraceValue(strArgs.strError));
            PopTrace();
            return strArgs.strError;
        }

        Trace("trace.value", TraceValue(strArgs.strArg0));

        PopTrace();

        return strArgs.strArg0;
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
            int nValue1 = GetValueAsInt(strArgs.strArg0);
            int nValue2 = GetValueAsInt(strArgs.strArg1);

            if (sMetaName == "add")
                return GetValueFromInt(nValue1 + nValue2);
            else if (sMetaName == "sub")
                return GetValueFromInt(nValue1 - nValue2);
            else
                return GetValueFromInt(nValue1 * nValue2);
        }
        else
        {
            float fValue1 = GetValueAsFloat(strArgs.strArg0);
            float fValue2 = GetValueAsFloat(strArgs.strArg1);

            if (sMetaName == "add")
                return GetValueFromFloat(fValue1 + fValue2);
            else if (sMetaName == "sub")
                return GetValueFromFloat(fValue1 - fValue2);
            else
                return GetValueFromFloat(fValue1 * fValue2);
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

    if (sMetaName == "objectbytag")
    {
        struct Arguments strArgs = EvalArgs(strPC, 1, 2, DAZSCRIPT_ARG_STRING, DAZSCRIPT_ARG_INT);
        if (IsErrorValue(strArgs.strError))
            return strArgs.strError;

        string sTag = GetValueAsText(strArgs.strArg0);
        int nNth = 0;
        if (strArgs.nCount >= 2)
            nNth = GetValueAsInt(strArgs.strArg1);

        if (sTag == "")
            return GetErrorValue("EMPTY_TAG");
        return GetValueFromObject(GetObjectByTag(sTag, nNth));
    }

    return GetInvalidValue();
}

int IsTraceEnabled()
{
    return GetLocalInt(GetDataObject(DAZSCRIPT_SCRIPT_NAME), DAZSCRIPT_TRACE_DEPTH_KEY) > 0;
}

void PushTrace()
{
    IncrementLocalInt(GetDataObject(DAZSCRIPT_SCRIPT_NAME), DAZSCRIPT_TRACE_DEPTH_KEY);
}

void PopTrace()
{
    object oDataObject = GetDataObject(DAZSCRIPT_SCRIPT_NAME);
    int nDepth = GetLocalInt(oDataObject, DAZSCRIPT_TRACE_DEPTH_KEY) - 1;
    if (nDepth <= 0)
    {
        DeleteLocalInt(oDataObject, DAZSCRIPT_TRACE_DEPTH_KEY);
        DeleteLocalInt(oDataObject, DAZSCRIPT_TRACE_INDENT_KEY);
    }
    else
    {
        SetLocalInt(oDataObject, DAZSCRIPT_TRACE_DEPTH_KEY, nDepth);
    }
}

void PushTraceIndent()
{
    IncrementLocalInt(GetDataObject(DAZSCRIPT_SCRIPT_NAME), DAZSCRIPT_TRACE_INDENT_KEY);
}

void PopTraceIndent()
{
    object oDataObject = GetDataObject(DAZSCRIPT_SCRIPT_NAME);
    int nDepth = GetLocalInt(oDataObject, DAZSCRIPT_TRACE_INDENT_KEY) - 1;
    if (nDepth <= 0)
        DeleteLocalInt(oDataObject, DAZSCRIPT_TRACE_INDENT_KEY);
    else
        SetLocalInt(oDataObject, DAZSCRIPT_TRACE_INDENT_KEY, nDepth);
}

string GetTraceIndent()
{
    int nDepth = GetLocalInt(GetDataObject(DAZSCRIPT_SCRIPT_NAME), DAZSCRIPT_TRACE_INDENT_KEY);
    string sIndent = "";
    while (nDepth > 0)
    {
        sIndent += "  ";
        nDepth--;
    }
    return sIndent;
}

void Trace(string sEvent, string sDetail = "")
{
    string sLine = "[TRACE] " + RightPadString(GetTraceIndent() + sEvent, DAZSCRIPT_TRACE_EVENT_WIDTH, " ");
    if (sDetail != "")
        sLine += " | " + sDetail;
    PrintString(sLine);
}

void TraceEnter(string sEvent, string sDetail = "")
{
    Trace(sEvent, sDetail);
    PushTraceIndent();
}

void TraceExit(string sEvent, string sDetail = "")
{
    PopTraceIndent();
    Trace(sEvent, sDetail);
}

string TraceValue(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return "error " + strValue.sErrorMessage;

    string sType = AuxTypeToString(strValue.nAuxType, TRUE);
    string sText = ValueToText(strValue);

    if (GetStringLength(sText) > DAZSCRIPT_TRACE_MAX_LENGTH)
        sText = GetStringLeft(sText, DAZSCRIPT_TRACE_MAX_LENGTH) + "...";

    if (strValue.nAuxType == NWNX_VM_AUXTYPE_STRING)
        return sType + " \"" + EscapeString(sText) + "\"";

    return sType + " " + sText;
}

string TraceExprKind(int nKind)
{
    switch (nKind)
    {
        case DAZSCRIPT_EXPR_VAR:      return "var";
        case DAZSCRIPT_EXPR_ALIAS:    return "alias";
        case DAZSCRIPT_EXPR_META:     return "meta";
        case DAZSCRIPT_EXPR_FUNCTION: return "function";
    }

    return "unknown";
}

string TraceQuoted(string sText)
{
    if (GetStringLength(sText) > DAZSCRIPT_TRACE_MAX_LENGTH)
        sText = GetStringLeft(sText, DAZSCRIPT_TRACE_MAX_LENGTH) + "...";
    return "\"" + EscapeString(sText) + "\"";
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

int IsAliasEntry(json jEntry)
{
    if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
        return FALSE;
    if (!JsonObjectContainsKey(jEntry, DAZSCRIPT_ALIAS_TYPE))
        return FALSE;
    if (!JsonObjectContainsKey(jEntry, DAZSCRIPT_ALIAS_VALUE))
        return FALSE;
    return TRUE;
}

int IsErrorAliasEntry(json jEntry)
{
    if (!IsAliasEntry(jEntry))
        return FALSE;
    if (!JsonObjectContainsKey(jEntry, DAZSCRIPT_ALIAS_ERROR))
        return FALSE;
    if (!JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_ERROR))
        return FALSE;
    return JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_TYPE) == NWNX_VM_AUXTYPE_INVALID;
}

int IsFunctionEntry(json jEntry)
{
    if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
        return FALSE;
    if (JsonGetType(JsonObjectGet(jEntry, DAZSCRIPT_FUNCTION_ARGS)) != JSON_TYPE_ARRAY)
        return FALSE;
    if (JsonGetType(JsonObjectGet(jEntry, DAZSCRIPT_FUNCTION_BODY)) != JSON_TYPE_STRING)
        return FALSE;
    if (JsonGetType(JsonObjectGet(jEntry, DAZSCRIPT_FUNCTION_BODY_COMPILED)) != JSON_TYPE_ARRAY)
        return FALSE;
    return TRUE;
}

int IsStackEntry(json jEntry)
{
    if (JsonGetType(jEntry) != JSON_TYPE_OBJECT)
        return FALSE;
    if (!JsonObjectContainsKey(jEntry, NWNX_VM_TYPE_KEY))
        return FALSE;
    int nAuxType = JsonObjectGetInt(jEntry, NWNX_VM_TYPE_KEY);
    if (!IsKnownStackAuxType(nAuxType))
        return FALSE;
    if (nAuxType != NWNX_VM_AUXTYPE_VOID && !JsonObjectContainsKey(jEntry, NWNX_VM_STACK_LOCATION_KEY))
        return FALSE;
    return TRUE;
}

string GetAliasEntryType(json jEntry)
{
    if (!IsAliasEntry(jEntry))
        return "invalid:alias";
    if (IsErrorAliasEntry(jEntry))
        return "alias:error";
    int nAuxType = JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_TYPE);
    if (!IsKnownAuxType(nAuxType))
        return "invalid:alias";
    return "alias:" + AuxTypeToString(nAuxType, TRUE);
}

string GetStackEntryType(json jEntry)
{
    if (!IsStackEntry(jEntry))
        return "invalid:stack";
    int nAuxType = JsonObjectGetInt(jEntry, NWNX_VM_TYPE_KEY);
    if (nAuxType == NWNX_VM_AUXTYPE_VOID)
    {
        string sStructName = JsonObjectGetString(jEntry, NWNX_VM_STRUCT_NAME_KEY);
        if (sStructName != "")
            return "struct:" + sStructName;
        return "struct";
    }
    return AuxTypeToString(nAuxType, TRUE);
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
    if (sPrefix == DAZSCRIPT_ALIAS_SYMBOL)
        return GetAliasEntryType(jEntry);
    if (sPrefix == DAZSCRIPT_FUNCTION_SYMBOL)
    {
        if (IsFunctionEntry(jEntry))
            return "function";
        return "invalid:function";
    }
    return GetStackEntryType(jEntry);
}

int SymbolExists(json jStack, string sName)
{
    string sType = GetSymbolType(jStack, sName);
    if (sType == "missing")
        return FALSE;
    if (GetStringLeft(sType, 8) == "invalid:")
        return FALSE;
    return TRUE;
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

    if (IsObjectIDString(sValue))
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
                    string sValue = ValueToText(GetStackValue(jStack, sKey));
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
        return "Object: " + ObjectIDToString(oValue) + "\n" + "Valid: FALSE";

    vector vPosition = GetPosition(oValue);
    object oArea = GetArea(oValue);
    string sHP = IntToString(GetCurrentHitPoints(oValue)) + "/" + IntToString(GetMaxHitPoints(oValue));
    string sPosition = FloatToString(vPosition.x, 0, 2) + ", " + FloatToString(vPosition.y, 0, 2) + ", " + FloatToString(vPosition.z, 0, 2);

    return "Object: " + ObjectIDToString(oValue) + "\n" +
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
