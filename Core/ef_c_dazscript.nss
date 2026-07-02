/*
    Script: ef_c_dazscript
    Author: Daz
*/

#include "ef_i_convert"
#include "ef_i_math"
#include "ef_i_string"
#include "ef_i_dataobject"
#include "ef_i_util"
#include "ef_i_sqlite"
#include "ef_i_json"
#include "ef_i_vm"
#include "nwnx_util"
#include "nwnx_vm"

const string DAZSCRIPT_SCRIPT_NAME                          = "ef_c_dazscript";
const int DAZSCRIPT_ENABLE_PERSISTENT_CACHE                 = FALSE;
const int DAZSCRIPT_PERSISTENT_CACHE_VERSION                = 1;

const int DAZSCRIPT_TRACE_EVENT_WIDTH                       = 40;
const int DAZSCRIPT_TRACE_MAX_LENGTH                        = 64;
const string DAZSCRIPT_TRACE_DEPTH_KEY                      = "DazScriptTraceDepth";
const string DAZSCRIPT_TRACE_INDENT_KEY                     = "DazScriptTraceIndent";

const string DAZSCRIPT_TEMPLATE_CACHE_PREFIX                = "DazScriptTemplateCache_";
const string DAZSCRIPT_EXPRESSION_CACHE_PREFIX              = "DazScriptExpressionCache_";
const string DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX          = "DazScriptPropertyChainCache_";
const string DAZSCRIPT_PROPERTY_SEGMENT_CACHE_PREFIX        = "DazScriptPropertySegmentCache_";
const string DAZSCRIPT_PARAMETER_LIST_CACHE_PREFIX          = "DazScriptParameterListCache_";

const string DAZSCRIPT_ALIAS_TYPE                           = "type";
const string DAZSCRIPT_ALIAS_VALUE                          = "value";
const string DAZSCRIPT_ALIAS_ERROR                          = "error";

const string DAZSCRIPT_PARSE_ERROR                          = "parse_error";
const string DAZSCRIPT_PARSE_CODE                           = "code";
const string DAZSCRIPT_PARSE_AT                             = "at";
const string DAZSCRIPT_PARSE_SOURCE                         = "source";
const string DAZSCRIPT_PARSE_CONTEXT                        = "context";
const string DAZSCRIPT_PARSE_WHERE                          = "where";

const int DAZSCRIPT_NODE_LITERAL                            = 0;
const int DAZSCRIPT_NODE_EXPR                               = 1;
const int DAZSCRIPT_NODE_FORCE_STRING                       = 2;

const string DAZSCRIPT_PROPERTY_CHAIN_SYMBOL                = ">";
const string DAZSCRIPT_META_SYMBOL                          = "@";
const string DAZSCRIPT_ALIAS_SYMBOL                         = "$";
const string DAZSCRIPT_FUNCTION_SYMBOL                      = "#";

const string DAZSCRIPT_THIS_ALIAS                           = DAZSCRIPT_ALIAS_SYMBOL + "this";

const int DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY               = 0;
const int DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY_HASH          = 1;
const int DAZSCRIPT_PROPERTY_SEGMENT_PARAMETERS             = 2;
const int DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_LIST         = 3;
const int DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_COUNT        = 4;

const int DAZSCRIPT_PARAMETER_ITEM_TEXT                     = 0;
const int DAZSCRIPT_PARAMETER_ITEM_WAS_QUOTED               = 1;
const int DAZSCRIPT_PARAMETER_ITEM_MODE                     = 2;
const int DAZSCRIPT_PARAMETER_ITEM_TEMPLATE                 = 3;

const int DAZSCRIPT_PARAMETER_MODE_TEMPLATE                 = 0;
const int DAZSCRIPT_PARAMETER_MODE_STRING_LITERAL           = 1;
const int DAZSCRIPT_PARAMETER_MODE_INT_LITERAL              = 2;
const int DAZSCRIPT_PARAMETER_MODE_FLOAT_LITERAL            = 3;
const int DAZSCRIPT_PARAMETER_MODE_OBJECT_LITERAL           = 4;
const int DAZSCRIPT_PARAMETER_MODE_RAW_LITERAL              = 5;

const int DAZSCRIPT_EXPR_VAR                                = 0;
const int DAZSCRIPT_EXPR_ALIAS                              = 1;
const int DAZSCRIPT_EXPR_META                               = 2;
const int DAZSCRIPT_EXPR_FUNCTION                           = 3;

const int DAZSCRIPT_EXPR_KIND                               = 1;
const int DAZSCRIPT_EXPR_BASE_NAME                          = 2;
const int DAZSCRIPT_EXPR_BASE_NAME_HASH                     = 3;
const int DAZSCRIPT_EXPR_CHAIN                              = 4;
const int DAZSCRIPT_EXPR_BASE_PARAMETERS                    = 5;
const int DAZSCRIPT_EXPR_PROPERTY_PATH                      = 6;
const int DAZSCRIPT_EXPR_BASE_PARAMETER_LIST                = 7;
const int DAZSCRIPT_EXPR_BASE_PARAMETER_COUNT               = 8;

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

const int DAZSCRIPT_SQL_ROWS_DEFAULT_LIMIT                  = 50;
const int DAZSCRIPT_SQL_ROWS_MAX_LIMIT                      = 250;

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
    sqlquery sqlValue;
    json jValue;

    int bError;
    string sErrorMessage;
};

struct ArgContext
{
    json jStack;

    string sName;
    int nNameHash;

    string sParameters;
    json jParameterList;
    int nParameterCount;
};

struct ChainContext
{
    string sBaseVarName;
    string sFullPropertyPath;

    struct ArgContext strArgs;
    struct Value strValue;
};

struct ArgumentPair
{
    int nCount;
    struct Value strArg0;
    struct Value strArg1;
    struct Value strError;
};

struct ThreeArguments
{
    struct Value strArg0;
    struct Value strArg1;
    struct Value strArg2;
    struct Value strError;
};

string Interpret(string sString, int bTraceEnabled = FALSE, int nDepthOverride = 0, json jStack = JSON_NULL);
struct Value Eval(string sString, int bTraceEnabled = FALSE, int nDepthOverride = 0, json jStack = JSON_NULL);

string MakeCacheKey(string sPrefix, string sString);
json GetCachedJson(string sPrefix, string sInput);
void SetCachedJson(string sPrefix, string sInput, json jValue);

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

int IsAliasValueAuxType(int nAuxType);
int IsStackEntryAuxType(int nAuxType);
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
struct Value GetValueFromSqlQuery(sqlquery sqlValue);
struct Value GetValueFromJson(json jValue = JSON_NULL);
int GetCastAuxTypeFromName(string sCast);
string GetValueAsCastString(struct Value strValue);
struct Value CastValueToJson(struct Value strValue);
struct Value CastValueToAuxType(struct Value strValue, int nTargetAuxType);
string GetValueText(struct Value strValue, string sErrorFallback = "");
string GetTrimmedValueText(struct Value strValue, string sErrorFallback = "");
int IsValueIntParameter(struct Value strValue);
int IsValueNumericParameter(struct Value strValue);
int IsValueObjectParameter(struct Value strValue);
int IsValueJsonParameter(struct Value strValue);
int GetValueAsInt(struct Value strValue, int nDefault = 0);
float GetValueAsFloat(struct Value strValue, float fDefault = 0.0);
object GetValueAsObject(struct Value strValue, object oDefault = OBJECT_INVALID);
json GetValueAsJson(struct Value strValue, json jDefault = JSON_NULL);
string FormatValueForDisplay(struct Value strValue);
int IsValueTruthy(struct Value strValue);
struct Value ValueToJsonValue(struct Value strValue);
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
json ValidateParserSyntax(string sSource);

string GetParserContext(string sSource, int nAt);
json MakeParserError(string sCode, int nAt, string sSource);
json SetParserErrorWhere(json jError, string sWhere);
json CacheParameterParserError(string sParameters, string sCode, int nAt);
int IsParserError(json jValue);
struct Value GetValueFromParserError(json jError, string sWhere = "");
int GetCompiledParameterCount(json jParameterList);

json CompileTemplate(string sString);
json CompileTemplateCached(string sString);
json CompileForcedStringTemplate(string sValue);
void JsonArrayInsertLiteralNodeInplace(json jTemplate, string sLiteral);
void JsonArrayInsertForceStringNodeInplace(json jTemplate, json jInnerTemplate);
json CompileExpression(string sExpr);
json CompileExpressionCached(string sString);
json CompilePropertyChain(string sPropertyPath);
json CompilePropertySegment(string sPropertySegment);
json CompilePropertySegmentCached(string sPropertySegment);
int ParameterTextNeedsTemplateCompile(string sText);
json MakeLiteralParameterTemplate(string sText, int bWasQuoted);
json MakeParameterItem(string sText, int bWasQuoted);
json CompileParameterList(string sParameters);

struct ArgContext PrepareCompiledCall(json jStack, json jCall, int nNameIndex, int nNameHashIndex, int nParametersIndex, int nParameterListIndex, int nParameterCountIndex);
struct ArgContext PrepareCompiledExpressionBase(json jStack, json jExpr);
struct ArgContext PrepareCompiledPropertySegment(json jStack, json jSegment, int bTraceEnabled);
json GetParameterTemplate(struct ArgContext strArgCtx, int nIndex);
string GetRawParameterText(struct ArgContext strArgCtx, int nIndex, string sDefault = "");
int GetRawParameterWasQuoted(struct ArgContext strArgCtx, int nIndex);
struct Value EvalParameter(struct ArgContext strArgCtx, int nIndex);
struct Value EvalParameterUsingStack(struct ArgContext strArgCtx, int nIndex, json jEvalStack);
struct Value EvalJsonArrayParameter(struct ArgContext strArgCtx, int nIndex, string sErrorCode);
string GetArgTypeName(int nArgType);
int IsValueArgType(struct Value strValue, int nArgType);
struct Value CheckArity(struct ArgContext strArgCtx, int nMin, int nMax);
struct Value CheckZeroArgs(struct ArgContext strArgCtx);
struct Value EvalTypedParameter(struct ArgContext strArgCtx, int nIndex, int nArgType);
struct Value EvalSingleArg(struct ArgContext strArgCtx, int nArgType = DAZSCRIPT_ARG_ANY);
struct ArgumentPair EvalOptionalArg(struct ArgContext strArgCtx, int nArgType = DAZSCRIPT_ARG_ANY);
struct ArgumentPair EvalTwoArgs(struct ArgContext strArgCtx, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY);
struct ArgumentPair EvalArgPair(struct ArgContext strArgCtx, int nMin, int nMax, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY);
struct ThreeArguments EvalThreeArgs(struct ArgContext strArgCtx, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY, int nType2 = DAZSCRIPT_ARG_ANY);

struct Value EvalTemplate(json jTemplate, json jStack);
struct Value EvalTemplateToString(json jTemplate, json jStack);
struct Value EvalCompiledExpressionToValue(json jExpr, json jStack);
struct Value GetStackValue(json jStack, string sVarName);
struct Value ResolveAliasValue(json jStack, string sAliasName);
struct Value ResolveMetaValue(struct ArgContext strMeta);
struct Value ResolveFunctionValue(struct ArgContext strFunction);

struct ChainContext EvalCompiledPropertyChain(struct ChainContext strCtx, json jSegments);
struct Value ResolveCurrentPropertyByValueType(struct ChainContext strCtx);

struct Value ResolveIntProperty(struct ChainContext strCtx);
struct Value ResolveFloatProperty(struct ChainContext strCtx);
struct Value ResolveStringProperty(struct ChainContext strCtx);
struct Value ResolveObjectProperty(struct ChainContext strCtx);
struct Value ResolveSqlQueryProperty(struct ChainContext strCtx);
struct Value ResolveJsonProperty(struct ChainContext strCtx);
struct Value ResolveSharedProperty(struct ChainContext strCtx);

struct Value HandleMetaPrimitive(struct ArgContext strArgCtx);
struct Value HandleMetaFunction(struct ArgContext strArgCtx);
struct Value HandleMetaControlFlow(struct ArgContext strArgCtx);
struct Value HandleMetaCollection(struct ArgContext strArgCtx);
struct Value HandleMetaAggregate(struct ArgContext strArgCtx);
struct Value HandleMetaVariable(struct ArgContext strArgCtx);
struct Value HandleMetaIntrospection(struct ArgContext strArgCtx);
struct Value HandleMetaOutput(struct ArgContext strArgCtx);
struct Value HandleMetaMath(struct ArgContext strArgCtx);
struct Value HandleMetaObject(struct ArgContext strArgCtx);
struct Value HandleMetaSqlQuery(struct ArgContext strArgCtx);

struct Value CheckSqlQueryError(sqlquery sqlQuery);
struct Value CheckSqlStateIs(sqlquery sqlQuery, int nState);
struct Value CheckSqlStateIsNot(sqlquery sqlQuery, int nState);
int IsValidSqlAuxType(int nAuxType);
int GetSqlAuxTypeFromShortType(string sChar);
struct Value ValidateSqlRowSpec(string sSpec, int nColumnCount, string sErrorPrefix);
struct Value BuildSqlRowSchemaInplace(json jColumnNames, json jColumnAuxTypes, sqlquery sqlQuery, string sSpec, int nColumnCount);
struct Value GetSqlCurrentRowAsJson(sqlquery sqlQuery, json jColumnNames, json jColumnAuxTypes);
struct Value GetValueFromSqlColumn(sqlquery sqlQuery, int nIndex, int nAuxType);

struct Value ValidateLoopAliases(string sMetaName, int bHasIndexAlias, string sIndexAlias, string sValueAlias);
struct Value BindArrayLoopAliasesInplace(json jFrame, json jCollection, int nIndex, int bHasIndexAlias, string sIndexAlias, string sValueAlias);

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
string GetAliasStoredValueAsString(json jEntry);
json MakeStackAliasEntryFromValue(struct Value strValue);
struct Value SetStackLocationFromValue(int nAuxType, int nStackLocation, struct Value strValue);

string InferDebugValueType(string sValue);
string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "");

object g_oDazScriptDataObject;

string Interpret(string sString, int bTraceEnabled = FALSE, int nDepthOverride = 0, json jStack = JSON_NULL)
{
    struct Value strEval = Eval(sString, bTraceEnabled, 1 + nDepthOverride, jStack);
    return FormatValueForDisplay(strEval);
}

struct Value Eval(string sString, int bTraceEnabled = FALSE, int nDepthOverride = 0, json jStack = JSON_NULL)
{
    g_oDazScriptDataObject = GetDataObject(DAZSCRIPT_SCRIPT_NAME);

    int bPushedTrace = FALSE;
    if (bTraceEnabled)
    {
        PushTrace();
        bPushedTrace = TRUE;
    }

    if (IsTraceEnabled()) { Trace("eval.input", EscapeString(sString)); }

    if (!JsonGetType(jStack))
        jStack = NWNX_VM_GetStackVariables(1 + nDepthOverride);

    struct Value strEval = EvalTemplate(CompileTemplateCached(sString), jStack);

    if (bPushedTrace)
        PopTrace();

    return strEval;
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
    return GetLocalJson(g_oDazScriptDataObject, MakeCacheKey(sPrefix, sInput));
}

void SetCachedJson(string sPrefix, string sInput, json jValue)
{
    SetLocalJson(g_oDazScriptDataObject, MakeCacheKey(sPrefix, sInput), jValue);
}

int IsTraceEnabled()
{
    return GetLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_DEPTH_KEY) > 0;
}

void PushTrace()
{
    IncrementLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_DEPTH_KEY);
}

void PopTrace()
{
    int nDepth = GetLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_DEPTH_KEY) - 1;
    if (nDepth <= 0)
    {
        DeleteLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_DEPTH_KEY);
        DeleteLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_INDENT_KEY);
    }
    else
    {
        SetLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_DEPTH_KEY, nDepth);
    }
}

void PushTraceIndent()
{
    IncrementLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_INDENT_KEY);
}

void PopTraceIndent()
{
    int nDepth = GetLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_INDENT_KEY) - 1;
    if (nDepth <= 0)
        DeleteLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_INDENT_KEY);
    else
        SetLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_INDENT_KEY, nDepth);
}

string GetTraceIndent()
{
    int nDepth = GetLocalInt(g_oDazScriptDataObject, DAZSCRIPT_TRACE_INDENT_KEY);
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
    string sText = FormatValueForDisplay(strValue);

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

int IsAliasValueAuxType(int nAuxType)
{
    return nAuxType == NWNX_VM_AUXTYPE_INT || nAuxType == NWNX_VM_AUXTYPE_FLOAT || nAuxType == NWNX_VM_AUXTYPE_STRING ||
           nAuxType == NWNX_VM_AUXTYPE_OBJECT || nAuxType == NWNX_VM_AUXTYPE_JSON;
}

int IsStackEntryAuxType(int nAuxType)
{
    return nAuxType == NWNX_VM_AUXTYPE_INT || nAuxType == NWNX_VM_AUXTYPE_FLOAT || nAuxType == NWNX_VM_AUXTYPE_STRING ||
           nAuxType == NWNX_VM_AUXTYPE_OBJECT || nAuxType == NWNX_VM_AUXTYPE_SQLQUERY || nAuxType == NWNX_VM_AUXTYPE_JSON ||
           nAuxType == NWNX_VM_AUXTYPE_VOID;
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
        case NWNX_VM_AUXTYPE_SQLQUERY: str.sqlValue = NWNX_VM_GetStackSqlQueryValue(nStackLocation); break;
        case NWNX_VM_AUXTYPE_JSON: str.jValue = NWNX_VM_GetStackJsonValue(nStackLocation); break;
    }
    return str;
}

struct Value GetValueFromTypedLiteral(string sValue)
{
    if (sValue != Trim(sValue))
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

struct Value GetValueFromSqlQuery(sqlquery sqlValue)
{
    struct Value str;
    str.nAuxType = NWNX_VM_AUXTYPE_SQLQUERY;
    str.sqlValue = sqlValue;
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
    sCast = GetStringLowerCase(Trim(sCast));
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

    return FormatValueForDisplay(strValue);
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

            sValue = Trim(sValue);
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

            sValue = Trim(sValue);
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

string GetValueText(struct Value strValue, string sErrorFallback = "")
{
    if (IsErrorValue(strValue))
        return sErrorFallback;
    return FormatValueForDisplay(strValue);
}

string GetTrimmedValueText(struct Value strValue, string sErrorFallback = "")
{
    return Trim(GetValueText(strValue, sErrorFallback));
}

int IsValueIntParameter(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return FALSE;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
        return TRUE;
    return IsInteger(GetTrimmedValueText(strValue));
}

int IsValueNumericParameter(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return FALSE;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT || strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
        return TRUE;
    return IsNumeric(GetTrimmedValueText(strValue));
}

int IsValueObjectParameter(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return FALSE;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_OBJECT)
        return TRUE;
    return IsObjectIDString(GetTrimmedValueText(strValue));
}

int IsValueJsonParameter(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return FALSE;

    return !IsErrorValue(CastValueToJson(strValue));
}

int GetValueAsInt(struct Value strValue, int nDefault = 0)
{
    if (!IsValueIntParameter(strValue))
        return nDefault;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
        return strValue.nValue;
    return StringToInt(GetTrimmedValueText(strValue));
}

float GetValueAsFloat(struct Value strValue, float fDefault = 0.0)
{
    if (!IsValueNumericParameter(strValue))
        return fDefault;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_INT)
        return IntToFloat(strValue.nValue);
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_FLOAT)
        return strValue.fValue;
    return StringToFloat(GetTrimmedValueText(strValue));
}

object GetValueAsObject(struct Value strValue, object oDefault = OBJECT_INVALID)
{
    if (!IsValueObjectParameter(strValue))
        return oDefault;
    if (strValue.nAuxType == NWNX_VM_AUXTYPE_OBJECT)
        return strValue.oValue;
    object oValue = StringToObject(GetTrimmedValueText(strValue));
    if (oValue == OBJECT_INVALID)
        return oDefault;
    return oValue;
}

json GetValueAsJson(struct Value strValue, json jDefault = JSON_NULL)
{
    struct Value strJson = CastValueToJson(strValue);
    if (IsErrorValue(strJson))
        return jDefault;

    return strJson.jValue;
}

string FormatValueForDisplay(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return "[" + strValue.sErrorMessage + "]";

    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return strValue.sValue;
        case NWNX_VM_AUXTYPE_INT:       return IntToString(strValue.nValue);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(strValue.fValue, 0, 9);
        case NWNX_VM_AUXTYPE_OBJECT:    return ObjectIDToString(strValue.oValue);
        case NWNX_VM_AUXTYPE_SQLQUERY:  return "<SQL QUERY=\"" + Truncate(SqlGetQuery(strValue.sqlValue), 64) + "\"; STATE=" + SqlStateToString(SqlGetState(strValue.sqlValue)) + ">";
        case NWNX_VM_AUXTYPE_JSON:      return JsonDump(strValue.jValue);
    }
    return "[UNHANDLED_AUXTYPE:" + AuxTypeToString(strValue.nAuxType) + "]";
}

int IsValueTruthy(struct Value strValue)
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

struct Value ValueToJsonValue(struct Value strValue)
{
    if (IsErrorValue(strValue))
        return strValue;

    switch (strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:    return GetValueFromJson(JsonInt(strValue.nValue));
        case NWNX_VM_AUXTYPE_FLOAT:  return GetValueFromJson(JsonFloat(strValue.fValue));
        case NWNX_VM_AUXTYPE_STRING: return GetValueFromJson(JsonString(strValue.sValue));
        case NWNX_VM_AUXTYPE_OBJECT: return GetValueFromJson(JsonString(ObjectIDToString(strValue.oValue)));
        case NWNX_VM_AUXTYPE_JSON:   return GetValueFromJson(strValue.jValue);
    }

    return GetErrorValue("INVALID_JSON_VALUE_AUXTYPE:" + IntToString(strValue.nAuxType));
}

struct Value FormatValueAsFixed(struct Value strValue, int nPrecision)
{
    nPrecision = Clamp(nPrecision, 0, 9);
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
    return GetValueFromString(IsValueTruthy(strValue) ? "TRUE" : "FALSE");
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

    string sFinalPart = GetSubString(sString, nStart, str.nLength - nStart);
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

json ValidateParserSyntax(string sSource)
{
    struct Parser str = ParserBegin(sSource);
    while (!ParserAtEnd(str))
    {
        str = ParserAdvance(str);
        if (str.bError)
            return MakeParserError(str.sErrorCode, str.nErrorAt, sSource);
    }

    if (str.bInQuotes)
        return MakeParserError("UNTERMINATED_QUOTE", str.nLength, sSource);
    if (str.nBraceDepth > 0)
        return MakeParserError("UNTERMINATED_BRACE", str.nLength, sSource);
    if (str.nParenDepth > 0)
        return MakeParserError("UNTERMINATED_PAREN", str.nLength, sSource);

    return JsonNull();
}

string GetParserContext(string sSource, int nAt)
{
    int nLength = GetStringLength(sSource);
    nAt = Clamp(nAt, 0, nLength);
    int nStart = Max(0, nAt - 12);
    int nEnd = Min(nLength, nAt + 12);
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

json SetParserErrorWhere(json jError, string sWhere)
{
    if (!IsParserError(jError) || sWhere == "")
        return jError;

    json jContextualError = JsonCopyObject(jError);
    JsonObjectSetStringInplace(jContextualError, DAZSCRIPT_PARSE_WHERE, GetStringLowerCase(sWhere));
    return jContextualError;
}

json CacheParameterParserError(string sParameters, string sCode, int nAt)
{
    json jError = MakeParserError(sCode, nAt, sParameters);
    SetCachedJson(DAZSCRIPT_PARAMETER_LIST_CACHE_PREFIX, sParameters, jError);
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

    if (JsonObjectContainsKey(jError, DAZSCRIPT_PARSE_WHERE))
    {
        string sStoredWhere = JsonObjectGetString(jError, DAZSCRIPT_PARSE_WHERE);
        if (sStoredWhere != "")
            sWhere = sStoredWhere;
    }

    string sMessage = "PARSE_ERROR:" + sCode;

    if (sWhere != "")
        sMessage += ":IN_" + sWhere;

    sMessage += ":AT_" + IntToString(nAt);

    if (sContext != "")
        sMessage += ":NEAR:" + sContext;

    return GetErrorValue(sMessage);
}

int GetCompiledParameterCount(json jParameterList)
{
    if (IsParserError(jParameterList))
        return -1;
    return JsonGetLength(jParameterList);
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

        json jExpr = CompileExpressionCached(GetSubString(sString, nStart + 1, nEnd - nStart - 1));
        if (IsParserError(jExpr))
            return jExpr;

        JsonArrayInsertInplace(jTemplate, jExpr);

        nIndex = nEnd + 1;
        nLiteralStart = nIndex;
    }

    if (nLiteralStart < nLength)
        JsonArrayInsertLiteralNodeInplace(jTemplate, GetSubString(sString, nLiteralStart, nLength - nLiteralStart));

    return jTemplate;
}

json CompileTemplateCached(string sString)
{
    json jTemplate = GetCachedJson(DAZSCRIPT_TEMPLATE_CACHE_PREFIX, sString);
    if (JsonGetType(jTemplate) == JSON_TYPE_ARRAY || IsParserError(jTemplate))
        return jTemplate;

    jTemplate = CompileTemplate(sString);
    SetCachedJson(DAZSCRIPT_TEMPLATE_CACHE_PREFIX, sString, jTemplate);
    return jTemplate;
}

json CompileForcedStringTemplate(string sValue)
{
    json jInner = CompileTemplateCached(sValue);
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

    int nLength = JsonGetLength(jTemplate);
    if (nLength > 0)
    {
        json jPrevious = JsonArrayGet(jTemplate, nLength - 1);
        if (JsonArrayGetInt(jPrevious, 0) == DAZSCRIPT_NODE_LITERAL)
        {
            JsonSetAtPointerInplace(jTemplate, "/" + IntToString(nLength - 1) + "/1", JsonString(JsonArrayGetString(jPrevious, 1) + sLiteral));
            return;
        }
    }

    json jNode = JsonArray();
    JsonArrayInsertIntInplace(jNode, DAZSCRIPT_NODE_LITERAL);
    JsonArrayInsertStringInplace(jNode, sLiteral);
    JsonArrayInsertInplace(jTemplate, jNode);
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
    string sOriginalExpr = sExpr;
    sExpr = Trim(sExpr);
    if (sExpr == "")
        return MakeParserError("EMPTY_TEMPLATE_EXPR", 0, sOriginalExpr);
    int nPropertyPosition = FindTopLevelToken(sExpr, DAZSCRIPT_PROPERTY_CHAIN_SYMBOL);
    string sBase, sPropertyPath;

    if (nPropertyPosition == -1)
        sBase = sExpr;
    else
    {
        sBase = Trim(GetStringLeft(sExpr, nPropertyPosition));
        sPropertyPath = Trim(GetSubString(sExpr, nPropertyPosition + 1, GetStringLength(sExpr) - nPropertyPosition - 1));
        if (sBase == "")
            return MakeParserError("EMPTY_BASE_EXPR", 0, sExpr);
        if (sPropertyPath == "")
            return MakeParserError("EMPTY_PROPERTY_SEGMENT", nPropertyPosition + 1, sExpr);
    }

    int nKind = DAZSCRIPT_EXPR_VAR;
    string sBaseName = sBase, sBaseParameters, sPrefix = GetStringLeft(sBase, 1);
    json jBaseParameterList = JsonArray();
    int nBaseParameterCount = 0;

    if (sPrefix == DAZSCRIPT_META_SYMBOL)
    {
        nKind = DAZSCRIPT_EXPR_META;
        string sMetaBase = Trim(GetSubString(sBase, 1, GetStringLength(sBase) - 1));
        if (sMetaBase == "" || GetStringLeft(sMetaBase, 1) == "(")
            return MakeParserError("EMPTY_META_NAME", 1, sExpr);

        json jBase = CompilePropertySegmentCached(sMetaBase);
        if (IsParserError(jBase))
            return jBase;

        sBaseName = JsonArrayGetString(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY);
        sBaseParameters = JsonArrayGetString(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETERS);
        jBaseParameterList = JsonArrayGet(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_LIST);
        nBaseParameterCount = JsonArrayGetInt(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_COUNT);
    }
    else if (sPrefix == DAZSCRIPT_ALIAS_SYMBOL)
    {
        nKind = DAZSCRIPT_EXPR_ALIAS;
        sBaseName = sBase;

        json jAliasSyntaxError = ValidateParserSyntax(sBaseName);
        if (IsParserError(jAliasSyntaxError))
            return jAliasSyntaxError;

        if (sBaseName == DAZSCRIPT_ALIAS_SYMBOL)
            return MakeParserError("EMPTY_ALIAS_NAME", 1, sExpr);
    }
    else if (sPrefix == DAZSCRIPT_FUNCTION_SYMBOL)
    {
        nKind = DAZSCRIPT_EXPR_FUNCTION;
        string sFunctionBase = Trim(GetSubString(sBase, 1, GetStringLength(sBase) - 1));
        if (sFunctionBase == "" || GetStringLeft(sFunctionBase, 1) == "(")
            return MakeParserError("EMPTY_FUNCTION_NAME", 1, sExpr);

        json jBase = CompilePropertySegmentCached(sBase);
        if (IsParserError(jBase))
            return jBase;

        sBaseName = JsonArrayGetString(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY);
        sBaseParameters = JsonArrayGetString(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETERS);
        jBaseParameterList = JsonArrayGet(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_LIST);
        nBaseParameterCount = JsonArrayGetInt(jBase, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_COUNT);
    }
    else
    {
        json jBaseSyntaxError = ValidateParserSyntax(sBaseName);
        if (IsParserError(jBaseSyntaxError))
            return jBaseSyntaxError;
    }

    if (sBaseName == "")
    {
        if (nKind == DAZSCRIPT_EXPR_META)
            return MakeParserError("EMPTY_META_NAME", 1, sExpr);
        if (nKind == DAZSCRIPT_EXPR_FUNCTION)
            return MakeParserError("EMPTY_FUNCTION_NAME", 1, sExpr);
        return MakeParserError("EMPTY_BASE_EXPR", 0, sExpr);
    }

    json jChain = JsonArray();

    if (sPropertyPath != "")
    {
        jChain = CompilePropertyChain(sPropertyPath);
        if (IsParserError(jChain))
            return jChain;
    }

    json jExpr = JsonArray();
    JsonArrayInsertIntInplace(jExpr, DAZSCRIPT_NODE_EXPR);
    JsonArrayInsertIntInplace(jExpr, nKind);
    JsonArrayInsertStringInplace(jExpr, sBaseName);
    JsonArrayInsertIntInplace(jExpr, HashString(sBaseName));
    JsonArrayInsertInplace(jExpr, jChain);
    JsonArrayInsertStringInplace(jExpr, sBaseParameters);
    JsonArrayInsertStringInplace(jExpr, sPropertyPath);
    JsonArrayInsertInplace(jExpr, jBaseParameterList);
    JsonArrayInsertIntInplace(jExpr, nBaseParameterCount);

    return jExpr;
}

json CompileExpressionCached(string sString)
{
    json jTemplate = GetCachedJson(DAZSCRIPT_EXPRESSION_CACHE_PREFIX, sString);
    if (JsonGetType(jTemplate) == JSON_TYPE_ARRAY || IsParserError(jTemplate))
        return jTemplate;

    jTemplate = CompileExpression(sString);
    SetCachedJson(DAZSCRIPT_EXPRESSION_CACHE_PREFIX, sString, jTemplate);
    return jTemplate;
}

json CompilePropertyChain(string sPropertyPath)
{
    string sOriginalPath = sPropertyPath;
    sPropertyPath = Trim(sPropertyPath);

    if (sPropertyPath == "")
        return MakeParserError("EMPTY_PROPERTY_SEGMENT", 0, sOriginalPath);

    json jCached = GetCachedJson(DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath);
    if (JsonGetType(jCached) == JSON_TYPE_ARRAY || IsParserError(jCached))
        return jCached;

    json jRawSegments = SplitTopLevelToken(sPropertyPath, DAZSCRIPT_PROPERTY_CHAIN_SYMBOL, TRUE);
    json jCompiledSegments = JsonArray();
    int nSegment, nNumSegments = JsonGetLength(jRawSegments);

    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        json jSegment = CompilePropertySegmentCached(JsonArrayGetString(jRawSegments, nSegment));
        if (IsParserError(jSegment))
        {
            SetCachedJson(DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath, jSegment);
            return jSegment;
        }

        JsonArrayInsertInplace(jCompiledSegments, jSegment);
    }

    SetCachedJson(DAZSCRIPT_PROPERTY_CHAIN_CACHE_PREFIX, sPropertyPath, jCompiledSegments);
    return jCompiledSegments;
}

json CompilePropertySegment(string sPropertySegment)
{
    string sOriginalSegment = sPropertySegment;
    sPropertySegment = Trim(sPropertySegment);
    int nLength = GetStringLength(sPropertySegment);

    if (sPropertySegment == "")
    {
        json jError = MakeParserError("EMPTY_PROPERTY_SEGMENT", 0, sOriginalSegment);
        return jError;
    }

    int nParameterStart = FindPropertyCallStart(sPropertySegment);

    string sProperty, sParameters;
    if (nParameterStart == -1)
    {
        json jSyntaxError = ValidateParserSyntax(sPropertySegment);
        if (IsParserError(jSyntaxError))
            return SetParserErrorWhere(jSyntaxError, sPropertySegment);
        sProperty = sPropertySegment;
    }
    else
    {
        sProperty = Trim(GetStringLeft(sPropertySegment, nParameterStart));
        int nParameterEnd = FindMatchingPropertyCallParen(sPropertySegment, nParameterStart);

        if (sProperty == "")
        {
            json jError = MakeParserError("EMPTY_PROPERTY_NAME", nParameterStart, sPropertySegment);
            return jError;
        }

        if (nParameterEnd <= -2)
        {
            int nErrorAt = -nParameterEnd - 2;
            json jError = MakeParserError("UNEXPECTED_CLOSING_BRACE", nErrorAt, sPropertySegment);
            return SetParserErrorWhere(jError, sProperty);
        }

        if (nParameterEnd == -1)
        {
            json jError = MakeParserError("UNTERMINATED_PROPERTY_CALL", nLength, sPropertySegment);
            return SetParserErrorWhere(jError, sProperty);
        }

        sParameters = GetSubString(sPropertySegment, nParameterStart + 1, nParameterEnd - nParameterStart - 1);

        string sRemainder = Trim(GetSubString(sPropertySegment, nParameterEnd + 1, nLength - nParameterEnd - 1));
        if (sRemainder != "")
        {
            json jError = MakeParserError("TRAILING_TEXT_AFTER_PROPERTY_CALL", nParameterEnd + 1, sPropertySegment);
            return SetParserErrorWhere(jError, sProperty);
        }
    }

    if (sProperty == "")
    {
        json jError = MakeParserError("EMPTY_PROPERTY_NAME", 0, sPropertySegment);
        return jError;
    }

    sProperty = GetStringLowerCase(sProperty);

    json jParameterList = CompileParameterList(sParameters);
    if (IsParserError(jParameterList))
        return SetParserErrorWhere(jParameterList, sProperty);

    int nParameterCount = GetCompiledParameterCount(jParameterList);

    json jSegment = JsonArray();
    JsonArrayInsertStringInplace(jSegment, sProperty);
    JsonArrayInsertIntInplace(jSegment, HashString(sProperty));
    JsonArrayInsertStringInplace(jSegment, sParameters);
    JsonArrayInsertInplace(jSegment, jParameterList);
    JsonArrayInsertIntInplace(jSegment, nParameterCount);

    return jSegment;
}

json CompilePropertySegmentCached(string sPropertySegment)
{
    sPropertySegment = Trim(sPropertySegment);
    json jTemplate = GetCachedJson(DAZSCRIPT_PROPERTY_SEGMENT_CACHE_PREFIX, sPropertySegment);
    if (JsonGetType(jTemplate) == JSON_TYPE_ARRAY || IsParserError(jTemplate))
        return jTemplate;

    jTemplate = CompilePropertySegment(sPropertySegment);
    SetCachedJson(DAZSCRIPT_PROPERTY_SEGMENT_CACHE_PREFIX, sPropertySegment, jTemplate);
    return jTemplate;
}

int ParameterTextNeedsTemplateCompile(string sText)
{
    if (FindSubString(sText, "{", 0) != -1)
        return TRUE;
    if (FindSubString(sText, "}", 0) != -1)
        return TRUE;
    return FALSE;
}

json MakeLiteralParameterTemplate(string sText, int bWasQuoted)
{
    json jTemplate = JsonArray();

    if (bWasQuoted)
    {
        json jInnerTemplate = JsonArray();
        JsonArrayInsertLiteralNodeInplace(jInnerTemplate, sText);
        JsonArrayInsertForceStringNodeInplace(jTemplate, jInnerTemplate);
        return jTemplate;
    }

    JsonArrayInsertLiteralNodeInplace(jTemplate, sText);
    return jTemplate;
}

json MakeParameterItem(string sText, int bWasQuoted)
{
    json jParameter = JsonArray();

    JsonArrayInsertStringInplace(jParameter, sText);
    JsonArrayInsertIntInplace(jParameter, bWasQuoted);

    if (!ParameterTextNeedsTemplateCompile(sText))
    {
        if (bWasQuoted)
        {
            JsonArrayInsertIntInplace(jParameter, DAZSCRIPT_PARAMETER_MODE_STRING_LITERAL);
            JsonArrayInsertInplace(jParameter, JsonString(sText));
            return jParameter;
        }

        string sLower = GetStringLowerCase(sText);

        if (sLower == "true")
        {
            JsonArrayInsertIntInplace(jParameter, DAZSCRIPT_PARAMETER_MODE_INT_LITERAL);
            JsonArrayInsertInplace(jParameter, JsonInt(TRUE));
            return jParameter;
        }

        if (sLower == "false")
        {
            JsonArrayInsertIntInplace(jParameter, DAZSCRIPT_PARAMETER_MODE_INT_LITERAL);
            JsonArrayInsertInplace(jParameter, JsonInt(FALSE));
            return jParameter;
        }

        if (IsInteger(sText))
        {
            JsonArrayInsertIntInplace(jParameter, DAZSCRIPT_PARAMETER_MODE_INT_LITERAL);
            JsonArrayInsertInplace(jParameter, JsonInt(StringToInt(sText)));
            return jParameter;
        }

        if (IsFloat(sText))
        {
            JsonArrayInsertIntInplace(jParameter, DAZSCRIPT_PARAMETER_MODE_FLOAT_LITERAL);
            JsonArrayInsertInplace(jParameter, JsonFloat(StringToFloat(sText)));
            return jParameter;
        }

        if (IsObjectIDString(sText))
        {
            JsonArrayInsertIntInplace(jParameter, DAZSCRIPT_PARAMETER_MODE_OBJECT_LITERAL);
            JsonArrayInsertInplace(jParameter, JsonString(sText));
            return jParameter;
        }

        JsonArrayInsertIntInplace(jParameter, DAZSCRIPT_PARAMETER_MODE_RAW_LITERAL);
        JsonArrayInsertInplace(jParameter, JsonString(sText));
        return jParameter;
    }

    JsonArrayInsertIntInplace(jParameter, DAZSCRIPT_PARAMETER_MODE_TEMPLATE);

    json jTemplate;
    if (bWasQuoted)
        jTemplate = CompileForcedStringTemplate(sText);
    else
        jTemplate = CompileTemplateCached(sText);

    JsonArrayInsertInplace(jParameter, jTemplate);
    return jParameter;
}

json CompileParameterList(string sParameters)
{
    if (Trim(sParameters) == "")
        return JsonArray();
    json jParameterList = GetCachedJson(DAZSCRIPT_PARAMETER_LIST_CACHE_PREFIX, sParameters);
    if (JsonGetType(jParameterList) == JSON_TYPE_ARRAY || IsParserError(jParameterList))
        return jParameterList;

    jParameterList = JsonArray();
    string sCurrent;
    int bWasQuoted, bLastWasComma, bAfterTopLevelQuote, nQuotedTemplateEnd = -1;
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

        if (str.bInQuotes && bRootDepth)
        {
            if (nQuotedTemplateEnd >= 0 && str.nIndex > nQuotedTemplateEnd)
                nQuotedTemplateEnd = -1;

            if (nQuotedTemplateEnd < 0)
            {
                if (ParserMatches(str, "{{"))
                {
                    sCurrent += "{{";
                    str.nIndex += 2;
                    bLastWasComma = FALSE;
                    continue;
                }

                if (ParserMatches(str, "}}"))
                {
                    sCurrent += "}}";
                    str.nIndex += 2;
                    bLastWasComma = FALSE;
                    continue;
                }

                if (sCharacter == "{")
                {
                    int nEnd = FindMatchingTemplateExprEnd(str.sSource, str.nIndex);

                    if (nEnd != -1)
                        nQuotedTemplateEnd = nEnd;
                }
            }
        }

        if (IsParserQuote(sCharacter))
        {
            if (!str.bInQuotes)
            {
                if (bRootDepth)
                {
                    if (Trim(sCurrent) == "")
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
                    if (nQuotedTemplateEnd >= str.nIndex)
                    {
                        sCurrent += sCharacter;
                        str.nIndex++;
                        bLastWasComma = FALSE;
                        continue;
                    }

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
            JsonArrayInsertInplace(jParameterList, MakeParameterItem(bWasQuoted ? sCurrent : Trim(sCurrent), bWasQuoted));

            sCurrent = "";
            bWasQuoted = FALSE;
            bAfterTopLevelQuote = FALSE;
            bLastWasComma = TRUE;
            nQuotedTemplateEnd = -1;

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

    JsonArrayInsertInplace(jParameterList, MakeParameterItem(bWasQuoted ? sCurrent : Trim(sCurrent), bWasQuoted));

    SetCachedJson(DAZSCRIPT_PARAMETER_LIST_CACHE_PREFIX, sParameters, jParameterList);
    return jParameterList;
}

struct ArgContext PrepareCompiledCall(json jStack, json jCall, int nNameIndex, int nNameHashIndex, int nParametersIndex, int nParameterListIndex, int nParameterCountIndex)
{
    struct ArgContext strArgCtx;
    strArgCtx.jStack = jStack;
    strArgCtx.sName = JsonArrayGetString(jCall, nNameIndex);
    strArgCtx.nNameHash = JsonArrayGetInt(jCall, nNameHashIndex);
    strArgCtx.sParameters = JsonArrayGetString(jCall, nParametersIndex);
    strArgCtx.jParameterList = JsonArrayGet(jCall, nParameterListIndex);
    strArgCtx.nParameterCount = JsonArrayGetInt(jCall, nParameterCountIndex);
    return strArgCtx;
}

struct ArgContext PrepareCompiledExpressionBase(json jStack, json jExpr)
{
    return PrepareCompiledCall(jStack, jExpr, DAZSCRIPT_EXPR_BASE_NAME, DAZSCRIPT_EXPR_BASE_NAME_HASH,
        DAZSCRIPT_EXPR_BASE_PARAMETERS, DAZSCRIPT_EXPR_BASE_PARAMETER_LIST, DAZSCRIPT_EXPR_BASE_PARAMETER_COUNT);
}

struct ArgContext PrepareCompiledPropertySegment(json jStack, json jSegment, int bTraceEnabled)
{
    struct ArgContext strArgCtx;
    strArgCtx.jStack = jStack;
    strArgCtx.sName = JsonArrayGetString(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY);
    strArgCtx.nNameHash = JsonArrayGetInt(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_PROPERTY_HASH);
    strArgCtx.nParameterCount = JsonArrayGetInt(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_COUNT);

    if (bTraceEnabled || strArgCtx.nParameterCount > 0)
    {
        strArgCtx.sParameters = JsonArrayGetString(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETERS);
        strArgCtx.jParameterList = JsonArrayGet(jSegment, DAZSCRIPT_PROPERTY_SEGMENT_PARAMETER_LIST);
    }

    return strArgCtx;
}

json GetParameterTemplate(struct ArgContext strArgCtx, int nIndex)
{
    if (IsParserError(strArgCtx.jParameterList))
        return strArgCtx.jParameterList;
    if (nIndex < 0 || nIndex >= strArgCtx.nParameterCount)
        return JsonNull();

    json jParameter = JsonArrayGet(strArgCtx.jParameterList, nIndex);
    int nMode = JsonArrayGetInt(jParameter, DAZSCRIPT_PARAMETER_ITEM_MODE);

    if (nMode != DAZSCRIPT_PARAMETER_MODE_TEMPLATE)
    {
        return MakeLiteralParameterTemplate(
            JsonArrayGetString(jParameter, DAZSCRIPT_PARAMETER_ITEM_TEXT),
            JsonArrayGetInt(jParameter, DAZSCRIPT_PARAMETER_ITEM_WAS_QUOTED)
        );
    }

    return JsonArrayGet(jParameter, DAZSCRIPT_PARAMETER_ITEM_TEMPLATE);
}

string GetRawParameterText(struct ArgContext strArgCtx, int nIndex, string sDefault = "")
{
    if (IsParserError(strArgCtx.jParameterList))
        return sDefault;
    if (nIndex < 0 || nIndex >= strArgCtx.nParameterCount)
        return sDefault;
    return JsonArrayGetString(JsonArrayGet(strArgCtx.jParameterList, nIndex), DAZSCRIPT_PARAMETER_ITEM_TEXT);
}

int GetRawParameterWasQuoted(struct ArgContext strArgCtx, int nIndex)
{
    if (IsParserError(strArgCtx.jParameterList))
        return FALSE;
    if (nIndex < 0 || nIndex >= strArgCtx.nParameterCount)
        return FALSE;
    return JsonArrayGetInt(JsonArrayGet(strArgCtx.jParameterList, nIndex), DAZSCRIPT_PARAMETER_ITEM_WAS_QUOTED);
}

struct Value EvalParameter(struct ArgContext strArgCtx, int nIndex)
{
    if (IsParserError(strArgCtx.jParameterList))
        return GetValueFromParserError(strArgCtx.jParameterList, strArgCtx.sName);

    if (nIndex < 0 || nIndex >= strArgCtx.nParameterCount)
        return GetErrorValue("PARAM_INDEX_OUT_OF_RANGE");

    json jParameter = JsonArrayGet(strArgCtx.jParameterList, nIndex);
    int nMode = JsonArrayGetInt(jParameter, DAZSCRIPT_PARAMETER_ITEM_MODE);

    int bTraceEnabled = IsTraceEnabled();
    if (bTraceEnabled) { TraceEnter("arg.enter", strArgCtx.sName + "[" + IntToString(nIndex + 1) + "] raw=" + TraceQuoted(JsonArrayGetString(jParameter, DAZSCRIPT_PARAMETER_ITEM_TEXT))); }

    struct Value strValue;

    switch (nMode)
    {
        case DAZSCRIPT_PARAMETER_MODE_STRING_LITERAL:
        case DAZSCRIPT_PARAMETER_MODE_RAW_LITERAL:
            strValue = GetValueFromString(JsonArrayGetString(jParameter, DAZSCRIPT_PARAMETER_ITEM_TEMPLATE));
            break;

        case DAZSCRIPT_PARAMETER_MODE_INT_LITERAL:
            strValue = GetValueFromInt(JsonArrayGetInt(jParameter, DAZSCRIPT_PARAMETER_ITEM_TEMPLATE));
            break;

        case DAZSCRIPT_PARAMETER_MODE_FLOAT_LITERAL:
            strValue = GetValueFromFloat(JsonGetFloat(JsonArrayGet(jParameter, DAZSCRIPT_PARAMETER_ITEM_TEMPLATE)));
            break;

        case DAZSCRIPT_PARAMETER_MODE_OBJECT_LITERAL:
            strValue = GetValueFromObject(StringToObject(JsonArrayGetString(jParameter, DAZSCRIPT_PARAMETER_ITEM_TEMPLATE)));
            break;

        case DAZSCRIPT_PARAMETER_MODE_TEMPLATE:
            strValue = EvalTemplate(JsonArrayGet(jParameter, DAZSCRIPT_PARAMETER_ITEM_TEMPLATE), strArgCtx.jStack);
            break;

        default:
            strValue = GetErrorValue("UNKNOWN_PARAMETER_MODE:" + IntToString(nMode));
            break;
    }

    if (bTraceEnabled) { TraceExit("arg.exit", strArgCtx.sName + "[" + IntToString(nIndex + 1) + "] => " + TraceValue(strValue)); }

    return strValue;
}

struct Value EvalParameterUsingStack(struct ArgContext strArgCtx, int nIndex, json jEvalStack)
{
    strArgCtx.jStack = jEvalStack;
    return EvalParameter(strArgCtx, nIndex);
}

struct Value EvalJsonArrayParameter(struct ArgContext strArgCtx, int nIndex, string sErrorCode)
{
    struct Value strValue = EvalParameter(strArgCtx, nIndex);
    if (IsErrorValue(strValue))
        return strValue;

    strValue = CastValueToJson(strValue);
    if (IsErrorValue(strValue))
        return strValue;

    if (JsonGetType(strValue.jValue) != JSON_TYPE_ARRAY)
        return GetErrorValue(sErrorCode);

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
        case DAZSCRIPT_ARG_JSON:    return IsValueJsonParameter(strValue);
    }
    return FALSE;
}

struct Value CheckArity(struct ArgContext strArgCtx, int nMin, int nMax)
{
    if (strArgCtx.nParameterCount < nMin)
    {
        if (nMin == nMax)
            return GetErrorValue("ARITY:EXPECTED_" + IntToString(nMin) + "_ARGUMENTS");
        return GetErrorValue("ARITY:EXPECTED_AT_LEAST_" + IntToString(nMin) + "_ARGUMENTS");
    }
    if (nMax >= 0 && strArgCtx.nParameterCount > nMax)
    {
        if (nMin == nMax)
            return GetErrorValue("ARITY:EXPECTED_" + IntToString(nMax) + "_ARGUMENTS");
        return GetErrorValue("ARITY:EXPECTED_" + IntToString(nMin) + "_TO_" + IntToString(nMax) + "_ARGUMENTS");
    }

    return GetInvalidValue();
}

struct Value CheckZeroArgs(struct ArgContext strArgCtx)
{
    return CheckArity(strArgCtx, 0, 0);
}

struct Value EvalTypedParameter(struct ArgContext strArgCtx, int nIndex, int nArgType)
{
    struct Value strArg = EvalParameter(strArgCtx, nIndex);
    if (IsErrorValue(strArg))
        return strArg;
    if (!IsValueArgType(strArg, nArgType))
        return GetErrorValue("TYPE_MISMATCH:ARG" + IntToString(nIndex + 1) + "_NOT_" + GetStringUpperCase(GetArgTypeName(nArgType)));
    return strArg;
}

struct Value EvalSingleArg(struct ArgContext strArgCtx, int nArgType = DAZSCRIPT_ARG_ANY)
{
    struct Value strError = CheckArity(strArgCtx, 1, 1);
    if (IsErrorValue(strError))
        return strError;

    return EvalTypedParameter(strArgCtx, 0, nArgType);
}

struct ArgumentPair EvalOptionalArg(struct ArgContext strArgCtx, int nArgType = DAZSCRIPT_ARG_ANY)
{
    return EvalArgPair(strArgCtx, 0, 1, nArgType);
}

struct ArgumentPair EvalTwoArgs(struct ArgContext strArgCtx, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY)
{
    return EvalArgPair(strArgCtx, 2, 2, nType0, nType1);
}

struct ArgumentPair EvalArgPair(struct ArgContext strArgCtx, int nMin, int nMax, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY)
{
    struct ArgumentPair strArgs;
    strArgs.strError = CheckArity(strArgCtx, nMin, nMax);
    if (IsErrorValue(strArgs.strError))
        return strArgs;

    strArgs.nCount = strArgCtx.nParameterCount;

    if (strArgs.nCount > 0)
    {
        strArgs.strArg0 = EvalTypedParameter(strArgCtx, 0, nType0);
        if (IsErrorValue(strArgs.strArg0))
        {
            strArgs.strError = strArgs.strArg0;
            return strArgs;
        }
    }

    if (strArgs.nCount > 1)
    {
        strArgs.strArg1 = EvalTypedParameter(strArgCtx, 1, nType1);
        if (IsErrorValue(strArgs.strArg1))
        {
            strArgs.strError = strArgs.strArg1;
            return strArgs;
        }
    }

    return strArgs;
}

struct ThreeArguments EvalThreeArgs(struct ArgContext strArgCtx, int nType0 = DAZSCRIPT_ARG_ANY, int nType1 = DAZSCRIPT_ARG_ANY, int nType2 = DAZSCRIPT_ARG_ANY)
{
    struct ThreeArguments strArgs;
    strArgs.strError = CheckArity(strArgCtx, 3, 3);
    if (IsErrorValue(strArgs.strError))
        return strArgs;

    strArgs.strArg0 = EvalTypedParameter(strArgCtx, 0, nType0);
    if (IsErrorValue(strArgs.strArg0))
    {
        strArgs.strError = strArgs.strArg0;
        return strArgs;
    }

    strArgs.strArg1 = EvalTypedParameter(strArgCtx, 1, nType1);
    if (IsErrorValue(strArgs.strArg1))
    {
        strArgs.strError = strArgs.strArg1;
        return strArgs;
    }

    strArgs.strArg2 = EvalTypedParameter(strArgCtx, 2, nType2);
    if (IsErrorValue(strArgs.strArg2))
    {
        strArgs.strError = strArgs.strArg2;
        return strArgs;
    }

    return strArgs;
}

struct Value EvalTemplate(json jTemplate, json jStack)
{
    if (IsParserError(jTemplate))
        return GetValueFromParserError(jTemplate, "template");

    if (JsonGetLength(jTemplate) == 1)
    {
        json jSingleNode = JsonArrayGet(jTemplate, 0);
        switch (JsonArrayGetInt(jSingleNode, 0))
        {
            case DAZSCRIPT_NODE_LITERAL: return GetValueFromTypedLiteral(JsonArrayGetString(jSingleNode, 1));
            case DAZSCRIPT_NODE_EXPR: return EvalCompiledExpressionToValue(jSingleNode, jStack);
            case DAZSCRIPT_NODE_FORCE_STRING: return EvalTemplateToString(JsonArrayGet(jSingleNode, 1), jStack);
        }
        return GetErrorValue("UNKNOWN_TEMPLATE_NODE:" + IntToString(JsonArrayGetInt(jSingleNode, 0)));
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
            sResult += FormatValueForDisplay(strExpressionValue);
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
    int bNeedsFullBase = nKind == DAZSCRIPT_EXPR_META || nKind == DAZSCRIPT_EXPR_FUNCTION || bTraceEnabled;

    struct ArgContext strBase;
    string sName;

    if (bNeedsFullBase)
    {
        strBase = PrepareCompiledExpressionBase(jStack, jExpr);
        sName = strBase.sName;
    }
    else
    {
        sName = JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_BASE_NAME);
        strBase.jStack = jStack;
        strBase.sName = sName;
    }

    if (bTraceEnabled) { TraceEnter("expr.enter", "kind=" + TraceExprKind(nKind) + "; base=" + sName + "; params=" + TraceQuoted(strBase.sParameters) + "; chain=" + TraceQuoted(JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_PROPERTY_PATH))); }

    struct Value strValue;

    if (nKind == DAZSCRIPT_EXPR_VAR)
        strValue = GetStackValue(jStack, sName);
    else if (nKind == DAZSCRIPT_EXPR_ALIAS)
        strValue = ResolveAliasValue(jStack, sName);
    else if (nKind == DAZSCRIPT_EXPR_META)
        strValue = ResolveMetaValue(strBase);
    else if (nKind == DAZSCRIPT_EXPR_FUNCTION)
        strValue = ResolveFunctionValue(strBase);
    else
        strValue = GetErrorValue("UNKNOWN_EXPR_KIND:" + IntToString(nKind));

    json jChain = JsonArrayGet(jExpr, DAZSCRIPT_EXPR_CHAIN);
    int bHasPropertyChain = (JsonGetLength(jChain) > 0);
    int bTraceBaseValue = bTraceEnabled;

    if ((nKind == DAZSCRIPT_EXPR_META || nKind == DAZSCRIPT_EXPR_FUNCTION) && !bHasPropertyChain)
        bTraceBaseValue = FALSE;

    if (bTraceBaseValue) { Trace("base.value", sName + " => " + TraceValue(strValue)); }

    if (IsErrorValue(strValue))
    {
        if (bTraceEnabled) { TraceExit("expr.exit", TraceValue(strValue)); }
        return strValue;
    }

    if (IsInvalidValue(strValue))
    {
        strValue = GetErrorValue("INVALID_EXPR:" + sName);
        if (bTraceEnabled) { TraceExit("expr.exit", TraceValue(strValue)); }
        return strValue;
    }

    if (bHasPropertyChain)
    {
        string sPropertyPath = JsonArrayGetString(jExpr, DAZSCRIPT_EXPR_PROPERTY_PATH);

        struct ChainContext strCtx;
        strCtx.strArgs.jStack = jStack;
        strCtx.sBaseVarName = sName;
        strCtx.sFullPropertyPath = sPropertyPath;
        strCtx.strValue = strValue;

        if (bTraceEnabled) { TraceEnter("chain.enter", "base=" + sName + "; chain=" + TraceQuoted(sPropertyPath) + "; input=" + TraceValue(strValue)); }

        strCtx = EvalCompiledPropertyChain(strCtx, jChain);

        if (IsErrorValue(strCtx.strValue))
        {
            if (GetStringLeft(strCtx.strValue.sErrorMessage, 12) == "PARSE_ERROR:")
                strValue = strCtx.strValue;
            else
                strValue = GetErrorValue("INVALID_PROPERTY_CHAIN:" + sName + ">" + sPropertyPath + " -> FAILED@" + strCtx.strArgs.sName + " -> " + strCtx.strValue.sErrorMessage);

            if (bTraceEnabled) { TraceExit("chain.exit", "base=" + sName + "; chain=" + TraceQuoted(sPropertyPath) + "; result=" + TraceValue(strValue)); TraceExit("expr.exit", TraceValue(strValue)); }
            return strValue;
        }

        if (IsInvalidValue(strCtx.strValue))
        {
            strValue = GetErrorValue("INVALID_PROPERTY_CHAIN:" + sName + ">" + sPropertyPath + " -> FAILED@" + strCtx.strArgs.sName);
            if (bTraceEnabled) { TraceExit("chain.exit", "base=" + sName + "; chain=" + TraceQuoted(sPropertyPath) + "; result=" + TraceValue(strValue)); TraceExit("expr.exit", TraceValue(strValue)); }
            return strValue;
        }

        strValue = strCtx.strValue;
        if (bTraceEnabled) { TraceExit("chain.exit", "base=" + sName + "; chain=" + TraceQuoted(sPropertyPath) + "; result=" + TraceValue(strValue)); }
    }

    if (bTraceEnabled) { TraceExit("expr.exit", TraceValue(strValue)); }
    return strValue;
}

struct Value GetStackValue(json jStack, string sVarName)
{
    json jStackVar = JsonObjectGet(jStack, sVarName);
    if (JsonGetType(jStackVar) != JSON_TYPE_OBJECT)
        return GetErrorValue("MISSING_OR_INVALID_STACK_VAR:" + sVarName);
    int nAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);
    if (nAuxType == NWNX_VM_AUXTYPE_VOID)
        return GetValueFromString(DumpStruct(jStack, sVarName, JsonObjectGetString(jStackVar, NWNX_VM_STRUCT_NAME_KEY)));

    return GetValueFromStackLocation(nAuxType, JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY));
}

struct Value ResolveAliasValue(json jStack, string sAliasName)
{
    json jEntry = JsonObjectGet(jStack, sAliasName);
    if (!IsAliasEntry(jEntry))
        return GetErrorValue("MISSING_OR_INVALID_ALIAS:" + sAliasName);
    if (IsErrorAliasEntry(jEntry))
        return GetErrorValue(GetAliasStoredValueAsString(jEntry));
    int nAuxType = JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_TYPE);
    if (!IsAliasValueAuxType(nAuxType))
        return GetErrorValue("INVALID_ALIAS_TYPE:" + sAliasName);

    json jValue = JsonObjectGet(jEntry, DAZSCRIPT_ALIAS_VALUE);

    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:
        {
            if (JsonGetType(jValue) == JSON_TYPE_INTEGER)
                return GetValueFromInt(JsonObjectGetInt(jEntry, DAZSCRIPT_ALIAS_VALUE));

            return GetValueFromInt(StringToInt(GetAliasStoredValueAsString(jEntry)));
        }
        case NWNX_VM_AUXTYPE_FLOAT:
        {
            int nJsonType = JsonGetType(jValue);
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

struct Value ResolveMetaValue(struct ArgContext strMeta)
{
    int bTraceEnabled = IsTraceEnabled();
    if (bTraceEnabled) { TraceEnter("meta.enter", "name=" + strMeta.sName + "; params=" + TraceQuoted(strMeta.sParameters)); }

    struct Value strReturnValue = GetInvalidValue();

    switch (strMeta.nNameHash)
    {
        case "int": case "float": case "string": case "object": case "json":
        case "jsonarray": case "arr": case "jsonobject": case "obj":
            strReturnValue = HandleMetaPrimitive(strMeta);
            break;

        case "fn": case "eval":
            strReturnValue = HandleMetaFunction(strMeta);
            break;

        case "if": case "while": case "pick": case "not": case "and": case "all": case "or":
        case "any": case "switch": case "foreachpc": case "try": case "catch": case "do":
            strReturnValue = HandleMetaControlFlow(strMeta);
            break;

        case "foreach": case "map": case "each": case "filter": case "reduce":
            strReturnValue = HandleMetaCollection(strMeta);
            break;

        case "count": case "sum": case "avg":
            strReturnValue = HandleMetaAggregate(strMeta);
            break;

        case "let": case "set": case "unset": case "cast": case "out": case "with":
            strReturnValue = HandleMetaVariable(strMeta);
            break;

        case "exists": case "type": case "debug":
            strReturnValue = HandleMetaIntrospection(strMeta);
            break;

        case "tellpc": case "print": case "trace":
            strReturnValue = HandleMetaOutput(strMeta);
            break;

        case "add": case "sub": case "mul":  case "div": case "idiv":
        case "min": case "max": case "clamp": case "mod": case "random":
            strReturnValue = HandleMetaMath(strMeta);
            break;

        case "firstpc": case "nextpc": case "module": case "objectbytag":
            strReturnValue = HandleMetaObject(strMeta);
            break;

        case "sqlobject": case "sqlcampaign": case "sqlmodule":
            strReturnValue = HandleMetaSqlQuery(strMeta);
            break;

        default:
            strReturnValue = GetErrorValue("UNKNOWN_META:" + strMeta.sName);
            break;
        }

    if (IsInvalidValue(strReturnValue))
        strReturnValue = GetErrorValue("UNKNOWN_META:" + strMeta.sName);

    if (bTraceEnabled) { TraceExit("meta.exit", strMeta.sName + " => " + TraceValue(strReturnValue)); }

    return strReturnValue;
}

struct Value ResolveFunctionValue(struct ArgContext strFunction)
{
    int bTraceEnabled = IsTraceEnabled();
    if (bTraceEnabled) { TraceEnter("fn.enter", "name=" + strFunction.sName + "; params=" + TraceQuoted(strFunction.sParameters)); }

    struct Value strReturnValue = GetInvalidValue();

    json jFunction = JsonObjectGet(strFunction.jStack, strFunction.sName);
    if (!IsFunctionEntry(jFunction))
        strReturnValue = GetErrorValue("MISSING_OR_INVALID_FUNCTION:" + strFunction.sName);
    else
    {
        json jArgNames = JsonObjectGet(jFunction, DAZSCRIPT_FUNCTION_ARGS);
        json jBody = JsonObjectGet(jFunction, DAZSCRIPT_FUNCTION_BODY_COMPILED);

        if (JsonGetType(jBody) != JSON_TYPE_ARRAY)
            strReturnValue = GetErrorValue("INVALID_FUNCTION_BODY:" + strFunction.sName);
        else
        {
            if (strFunction.nParameterCount != JsonGetLength(jArgNames))
                strReturnValue = GetErrorValue("FUNCTION_ARITY:" + strFunction.sName);
            else
            {
                json jFrame = JsonCopyObject(strFunction.jStack);
                int nIndex, nNumArgs = JsonGetLength(jArgNames);
                for (nIndex = 0; nIndex < nNumArgs; nIndex++)
                {
                    string sArgName = JsonArrayGetString(jArgNames, nIndex);

                    struct Value strArgValue = EvalParameter(strFunction, nIndex);

                    if (IsErrorValue(strArgValue))
                    {
                        strReturnValue = strArgValue;
                        break;
                    }

                    if (bTraceEnabled) { Trace("fn.arg", strFunction.sName + ":" + sArgName + " => " + TraceValue(strArgValue)); }

                    JsonObjectSetInplace(jFrame, sArgName, MakeStackAliasEntryFromValue(strArgValue));
                }

                if (!IsErrorValue(strReturnValue))
                    strReturnValue = EvalTemplate(jBody, jFrame);
            }
        }
    }

    if (bTraceEnabled) { TraceExit("fn.exit", strFunction.sName + " => " + TraceValue(strReturnValue)); }

    return strReturnValue;
}

struct ChainContext EvalCompiledPropertyChain(struct ChainContext strCtx, json jSegments)
{
    int bTraceEnabled = IsTraceEnabled();
    int nSegment, nNumSegments = JsonGetLength(jSegments);
    for (nSegment = 0; nSegment < nNumSegments; nSegment++)
    {
        strCtx.strArgs = PrepareCompiledPropertySegment(strCtx.strArgs.jStack, JsonArrayGet(jSegments, nSegment), bTraceEnabled);

        if (bTraceEnabled) { TraceEnter("prop.enter", "segment=" + IntToString(nSegment + 1) + "; property=" + strCtx.strArgs.sName + "; params=" + TraceQuoted(strCtx.strArgs.sParameters) + "; input=" + TraceValue(strCtx.strValue)); }

        strCtx.strValue = ResolveCurrentPropertyByValueType(strCtx);

        if (IsInvalidValue(strCtx.strValue))
            strCtx.strValue = GetErrorValue("UNKNOWN_PROPERTY:" + strCtx.strArgs.sName);

        if (bTraceEnabled) { TraceExit("prop.exit", strCtx.strArgs.sName + " => " + TraceValue(strCtx.strValue)); }

        if (IsErrorValue(strCtx.strValue))
            break;
    }
    return strCtx;
}

struct Value ResolveCurrentPropertyByValueType(struct ChainContext strCtx)
{
    struct Value strValue;
    switch (strCtx.strValue.nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT: strValue = ResolveIntProperty(strCtx); break;
        case NWNX_VM_AUXTYPE_FLOAT: strValue = ResolveFloatProperty(strCtx); break;
        case NWNX_VM_AUXTYPE_STRING: strValue = ResolveStringProperty(strCtx); break;
        case NWNX_VM_AUXTYPE_OBJECT: strValue = ResolveObjectProperty(strCtx); break;
        case NWNX_VM_AUXTYPE_SQLQUERY: strValue = ResolveSqlQueryProperty(strCtx); break;
        case NWNX_VM_AUXTYPE_JSON: strValue = ResolveJsonProperty(strCtx); break;
        default: strValue = GetInvalidValue(); break;
    }

    if (IsErrorValue(strValue))
        return strValue;

    if (IsInvalidValue(strValue))
        strValue = ResolveSharedProperty(strCtx);

    return strValue;
}

struct Value ResolveIntProperty(struct ChainContext strCtx)
{
    int nValue = strCtx.strValue.nValue;

    switch (strCtx.strArgs.nNameHash)
    {
        case "abs":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(abs(nValue));
        }

        case "eq": case "neq": case "gt": case "gte": case "lt": case "lte":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArg))
                return strArg;

            int nCompare = GetValueAsInt(strArg);
            switch (strCtx.strArgs.nNameHash)
            {
                case "eq":  return GetValueFromInt(nValue == nCompare);
                case "neq": return GetValueFromInt(nValue != nCompare);
                case "gt":  return GetValueFromInt(nValue > nCompare);
                case "gte": return GetValueFromInt(nValue >= nCompare);
                case "lt":  return GetValueFromInt(nValue < nCompare);
                case "lte": return GetValueFromInt(nValue <= nCompare);
            }
            break;
        }

        case "min": case "max":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArg))
                return strArg;

            int nOther = GetValueAsInt(strArg);
            if (strCtx.strArgs.nNameHash == h"min")
                return GetValueFromInt(nValue < nOther ? nValue : nOther);
            else
                return GetValueFromInt(nValue > nOther ? nValue : nOther);
        }

        case "clamp":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strCtx.strArgs, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;
            return GetValueFromInt(Clamp(nValue, GetValueAsInt(strArgs.strArg0), GetValueAsInt(strArgs.strArg1)));
        }

        case "mod":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArg))
                return strArg;

            int nDivisor = GetValueAsInt(strArg);
            if (nDivisor != 0)
                return GetValueFromInt(nValue % nDivisor);
            else
                return GetErrorValue("DIVISION_BY_ZERO");
        }

        case "then":
        {
            struct Value strError = CheckArity(strCtx.strArgs, 2, 2);
            if (IsErrorValue(strError))
                return strError;
            return EvalParameter(strCtx.strArgs, nValue != 0 ? 0 : 1);
        }

        case "plural":
        {
            struct Value strError = CheckArity(strCtx.strArgs, 1, 2);
            if (IsErrorValue(strError))
                return strError;
            if (strCtx.strArgs.nParameterCount == 1)
            {
                if (nValue == 1)
                    return GetValueFromString();
                else
                    return EvalParameter(strCtx.strArgs, 0);
            }
            else
                return EvalParameter(strCtx.strArgs, nValue != 1);
        }

        case "incr":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(nValue + 1);
        }

        case "decr":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(nValue - 1);
        }

        case "even": case "odd":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;

            if (strCtx.strArgs.nNameHash == h"even")
                return GetValueFromInt(nValue % 2 == 0);
            else
                return GetValueFromInt(nValue % 2 != 0);
        }
    }

    return GetInvalidValue();
}

struct Value ResolveFloatProperty(struct ChainContext strCtx)
{
    float fValue = strCtx.strValue.fValue;

    switch (strCtx.strArgs.nNameHash)
    {
        case "abs":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromFloat(fabs(fValue));
        }

        case "floor":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(Floor(fValue));
        }

        case "ceil":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(Ceil(fValue));
        }

        case "round":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(Round(fValue));
        }

        case "eq": case "neq": case "gt": case "gte": case "lt": case "lte":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs, DAZSCRIPT_ARG_NUMERIC);
            if (IsErrorValue(strArg))
                return strArg;

            float fCompare = GetValueAsFloat(strArg);
            float fDiff = fValue - fCompare;
            switch (strCtx.strArgs.nNameHash)
            {
                case "eq":  return GetValueFromInt(fabs(fDiff) < FLOAT_EPSILON);
                case "neq": return GetValueFromInt(fabs(fDiff) >= FLOAT_EPSILON);
                case "gt":  return GetValueFromInt(fDiff > FLOAT_EPSILON);
                case "gte": return GetValueFromInt(fDiff >= -FLOAT_EPSILON);
                case "lt":  return GetValueFromInt(fDiff < -FLOAT_EPSILON);
                case "lte": return GetValueFromInt(fDiff <= FLOAT_EPSILON);
            }
            break;
        }

        case "min": case "max":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs, DAZSCRIPT_ARG_NUMERIC);
            if (IsErrorValue(strArg))
                return strArg;

            float fOther = GetValueAsFloat(strArg);
            if (strCtx.strArgs.nNameHash == h"min")
                return GetValueFromFloat(fValue < fOther ? fValue : fOther);
            else
                return GetValueFromFloat(fValue > fOther ? fValue : fOther);
        }

        case "clamp":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strCtx.strArgs, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;
            return GetValueFromFloat(Clampf(fValue, GetValueAsFloat(strArgs.strArg0), GetValueAsFloat(strArgs.strArg1)));
        }
    }

    return GetInvalidValue();
}

struct Value ResolveStringProperty(struct ChainContext strCtx)
{
    string sValue = strCtx.strValue.sValue;

    switch (strCtx.strArgs.nNameHash)
    {
        case "length":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(GetStringLength(sValue));
        }

        case "upper":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(GetStringUpperCase(sValue));
        }

        case "lower":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(GetStringLowerCase(sValue));
        }

        case "trim":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(Trim(sValue));
        }

        case "empty":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(sValue == "");
        }

        case "notempty":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(sValue != "");
        }

        case "contains":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs);
            if (IsErrorValue(strArg))
                return strArg;
            return GetValueFromInt(FindSubString(sValue, GetValueText(strArg), 0) != -1);
        }

        case "startswith":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs);
            if (IsErrorValue(strArg))
                return strArg;
            return GetValueFromInt(IsStringPrefix(sValue, GetValueText(strArg)));
        }

        case "endswith":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs);
            if (IsErrorValue(strArg))
                return strArg;
            return GetValueFromInt(IsStringSuffix(sValue, GetValueText(strArg)));
        }

        case "substring":
        {
            struct ArgumentPair strArgs = EvalArgPair(strCtx.strArgs, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            int nStart = GetValueAsInt(strArgs.strArg0);
            int nCount = GetStringLength(sValue) - nStart;
            if (strArgs.nCount == 2)
                nCount = GetValueAsInt(strArgs.strArg1);
            return GetValueFromString(GetSubString(sValue, nStart, nCount));
        }

        case "left": case "right":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArg))
                return strArg;

            int nLength = GetValueAsInt(strArg);
            if (strCtx.strArgs.nNameHash == h"left")
                return GetValueFromString(GetStringLeft(sValue, nLength));
            else
                return GetValueFromString(GetStringRight(sValue, nLength));
        }

        case "replace":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strCtx.strArgs);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            string sSearch = NWNX_Util_RegExpEscape(GetValueText(strArgs.strArg0));
            string sReplace = GetValueText(strArgs.strArg1);
            return GetValueFromString(RegExpReplace(sSearch, sValue, sReplace));
        }

        case "eq": case "neq":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs);
            if (IsErrorValue(strArg))
                return strArg;

            string sCompare = GetValueText(strArg);
            int nResult = strCtx.strArgs.nNameHash == h"eq" ? sValue == sCompare : sValue != sCompare;
            return GetValueFromInt(nResult);
        }

        case "capitalize":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(CapitalizeWord(sValue));
        }

        case "append": case "prepend":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs);
            if (IsErrorValue(strArg))
                return strArg;

            string sOther = GetValueText(strArg);
            if (strCtx.strArgs.nNameHash == h"append")
                return GetValueFromString(sValue + sOther);
            else
                return GetValueFromString(sOther + sValue);
        }

        case "render":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return EvalTemplate(CompileTemplateCached(sValue), strCtx.strArgs.jStack);
        }
    }

    return GetInvalidValue();
}

struct Value ResolveObjectProperty(struct ChainContext strCtx)
{
    object oValue = strCtx.strValue.oValue;

    switch (strCtx.strArgs.nNameHash)
    {
        case "name":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(GetName(oValue));
        }

        case "tag":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(GetTag(oValue));
        }

        case "resref":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(GetResRef(oValue));
        }

        case "type":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(GetObjectTypeName(oValue));
        }

        case "area":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromObject(GetArea(oValue));
        }

        case "valid":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(GetIsObjectValid(oValue));
        }

        case "ispc":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(GetIsPlayer(oValue));
        }

        case "isdm":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(GetIsDM(oValue));
        }

        case "isplayerdm":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(GetIsPlayerDM(oValue));
        }

        case "dead":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(GetIsDead(oValue));
        }

        case "hp":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(GetCurrentHitPoints(oValue));
        }

        case "maxhp":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(GetMaxHitPoints(oValue));
        }

        case "x": case "y": case "z":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            vector vPosition = GetPosition(oValue);
            if (strCtx.strArgs.nNameHash == h"x") return GetValueFromFloat(vPosition.x);
            if (strCtx.strArgs.nNameHash == h"y") return GetValueFromFloat(vPosition.y);
            if (strCtx.strArgs.nNameHash == h"z") return GetValueFromFloat(vPosition.z);
            break;
        }

        case "position":
        {
            struct ArgumentPair strArg = EvalOptionalArg(strCtx.strArgs, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArg.strError))
                return strArg.strError;

            int nPrecision = 2;
            if (strArg.nCount > 0)
                nPrecision = GetValueAsInt(strArg.strArg0, 2);
            nPrecision = Clamp(nPrecision, 0, 9);

            vector vPosition = GetPosition(oValue);
            string sX = FormatValueForDisplay(FormatValueAsFixed(GetValueFromFloat(vPosition.x), nPrecision));
            string sY = FormatValueForDisplay(FormatValueAsFixed(GetValueFromFloat(vPosition.y), nPrecision));
            string sZ = FormatValueForDisplay(FormatValueAsFixed(GetValueFromFloat(vPosition.z), nPrecision));
            return GetValueFromString("[" + sX + "," + sY + "," + sZ + "]");
        }

        case "facing":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromFloat(GetFacing(oValue));
        }

        case "localvar":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strCtx.strArgs);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            string sType = GetStringLowerCase(GetTrimmedValueText(strArgs.strArg0));
            if (sType == "i")
                return GetValueFromInt(GetLocalInt(oValue, GetTrimmedValueText(strArgs.strArg1)));
            else if (sType == "f")
                return GetValueFromFloat(GetLocalFloat(oValue, GetTrimmedValueText(strArgs.strArg1)));
            else if (sType == "s")
                return GetValueFromString(GetLocalString(oValue, GetTrimmedValueText(strArgs.strArg1)));
            else if (sType == "o")
                return GetValueFromObject(GetLocalObject(oValue, GetTrimmedValueText(strArgs.strArg1)));
            else if (sType == "j")
                return GetValueFromJson(GetLocalJson(oValue, GetTrimmedValueText(strArgs.strArg1)));
            else
                return GetErrorValue("INVALID_LOCALVAR_TYPE:" + sType);
        }
    }

    return GetInvalidValue();
}

struct Value ResolveSqlQueryProperty(struct ChainContext strCtx)
{
    sqlquery sqlValue = strCtx.strValue.sqlValue;

    switch (strCtx.strArgs.nNameHash)
    {
        case "query":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(SqlGetQuery(sqlValue));
        }

        case "state":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(SqlGetState(sqlValue));
        }

        case "statestr":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(SqlStateToString(SqlGetState(sqlValue)));
        }

        case "error":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(SqlGetError(sqlValue));
        }

        case "columncount":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            strError = CheckSqlStateIsNot(sqlValue, SQLQUERY_STATE_EMPTY);
            if (IsErrorValue(strError))
                return strError;

            return GetValueFromInt(SqlGetColumnCount(sqlValue));
        }

        case "columnname":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArg))
                return strArg;
            struct Value strError = CheckSqlStateIsNot(sqlValue, SQLQUERY_STATE_EMPTY);
            if (IsErrorValue(strError))
                return strError;

            int nIndex = GetValueAsInt(strArg);
            if (nIndex < 0 || nIndex >= SqlGetColumnCount(sqlValue))
                return GetErrorValue("COLUMN_INDEX_OUT_OF_RANGE:" + IntToString(nIndex));
            return GetValueFromString(SqlGetColumnName(sqlValue, nIndex));
        }

        case "columns":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            strError = CheckSqlStateIsNot(sqlValue, SQLQUERY_STATE_EMPTY);
            if (IsErrorValue(strError))
                return strError;

            json jColumns = JsonArray();
            int nIndex, nNumColumns = SqlGetColumnCount(sqlValue);
            for (nIndex = 0; nIndex < nNumColumns; nIndex++)
            {
                JsonArrayInsertStringInplace(jColumns, SqlGetColumnName(sqlValue, nIndex));
            }
            return GetValueFromJson(jColumns);
        }

        case "bind": case "bindi": case "bindf": case "binds": case "bindo": case "bindj":
        {
            int nValueArgType = DAZSCRIPT_ARG_ANY;
            switch(strCtx.strArgs.nNameHash)
            {
                case "bindi": nValueArgType = DAZSCRIPT_ARG_INT; break;
                case "bindf": nValueArgType = DAZSCRIPT_ARG_NUMERIC; break;
                case "binds": nValueArgType = DAZSCRIPT_ARG_ANY; break;
                case "bindo": nValueArgType = DAZSCRIPT_ARG_OBJECT; break;
                case "bindj": nValueArgType = DAZSCRIPT_ARG_JSON; break;
            }

            struct ArgumentPair strArgs = EvalTwoArgs(strCtx.strArgs, DAZSCRIPT_ARG_STRING, nValueArgType);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;
            struct Value strError = CheckSqlStateIs(sqlValue, SQLQUERY_STATE_PREPARED);
            if (IsErrorValue(strError))
                return strError;

            string sBind = GetTrimmedValueText(strArgs.strArg0);
            if (sBind == "")
                return GetErrorValue("EMPTY_BIND_NAME");

            if (GetStringLeft(sBind, 1) != "@")
                sBind = "@" + sBind;

            switch(strCtx.strArgs.nNameHash)
            {
                case "bindi": SqlBindInt(sqlValue, sBind, GetValueAsInt(strArgs.strArg1)); break;
                case "bindf": SqlBindFloat(sqlValue, sBind, GetValueAsFloat(strArgs.strArg1)); break;
                case "binds": SqlBindString(sqlValue, sBind, GetValueText(strArgs.strArg1)); break;
                case "bindo": SqlBindObjectRef(sqlValue, sBind, GetValueAsObject(strArgs.strArg1)); break;
                case "bindj": SqlBindJson(sqlValue, sBind, GetValueAsJson(strArgs.strArg1)); break;
                default:
                {
                    switch (strArgs.strArg1.nAuxType)
                    {
                        case NWNX_VM_AUXTYPE_INT: SqlBindInt(sqlValue, sBind, strArgs.strArg1.nValue); break;
                        case NWNX_VM_AUXTYPE_FLOAT: SqlBindFloat(sqlValue, sBind, strArgs.strArg1.fValue); break;
                        case NWNX_VM_AUXTYPE_OBJECT: SqlBindObjectRef(sqlValue, sBind, strArgs.strArg1.oValue); break;
                        case NWNX_VM_AUXTYPE_JSON: SqlBindJson(sqlValue, sBind, strArgs.strArg1.jValue); break;
                        default: SqlBindString(sqlValue, sBind, GetValueText(strArgs.strArg1));
                    }
                }
            }

            strError = CheckSqlQueryError(sqlValue);
            if (IsErrorValue(strError))
                return strError;

            return GetValueFromSqlQuery(sqlValue);
        }

        case "exec":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            strError = CheckSqlStateIs(sqlValue, SQLQUERY_STATE_PREPARED);
            if (IsErrorValue(strError))
                return strError;

            if (SqlGetColumnCount(sqlValue) > 0)
                return GetErrorValue("SQL_EXEC_REQUIRES_NO_COLUMNS");

            SqlStep(sqlValue);
            strError = CheckSqlQueryError(sqlValue);
            if (IsErrorValue(strError))
                return strError;

            return GetValueFromString();
        }

        case "reset":
        {
            struct ArgumentPair strArg = EvalOptionalArg(strCtx.strArgs, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArg.strError))
                return strArg.strError;
            struct Value strError = CheckSqlStateIsNot(sqlValue, SQLQUERY_STATE_EMPTY);
            if (IsErrorValue(strError))
                return strError;

            int bClearBinds = FALSE;
            if (strArg.nCount > 0)
                bClearBinds = IsValueTruthy(strArg.strArg0);

            strError = CheckSqlQueryError(sqlValue);
            if (IsErrorValue(strError))
                return strError;

            SqlResetQuery(sqlValue, bClearBinds);
            return GetValueFromSqlQuery(sqlValue);
        }

        case "scalar":
        {
            struct ArgumentPair strArgs = EvalArgPair(strCtx.strArgs, 1, 2, DAZSCRIPT_ARG_STRING, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            struct Value strError = CheckSqlStateIs(sqlValue, SQLQUERY_STATE_PREPARED);
            if (IsErrorValue(strError))
                return strError;

            string sType = GetTrimmedValueText(strArgs.strArg0);
            int nAuxType = GetCastAuxTypeFromName(sType);

            if (!IsValidSqlAuxType(nAuxType))
                return GetErrorValue("INVALID_SCALAR_AUXTYPE:" + sType);

            if (SqlGetColumnCount(sqlValue) < 1)
                return GetErrorValue("SQL_NO_COLUMNS");

            int bStepped = SqlStep(sqlValue);
            strError = CheckSqlQueryError(sqlValue);
            if (IsErrorValue(strError))
                return strError;

            if (!bStepped)
            {
                if (strArgs.nCount == 2)
                    return CastValueToAuxType(strArgs.strArg1, nAuxType);
                return GetErrorValue("SQL_NO_ROW_DATA");
            }

            struct Value strScalar = GetValueFromSqlColumn(sqlValue, 0, nAuxType);
            if (IsErrorValue(strScalar))
                return strScalar;

            strError = CheckSqlQueryError(sqlValue);
            if (IsErrorValue(strError))
                return strError;

            return strScalar;
        }

        case "row": case "rows":
        {
            int bRows = (strCtx.strArgs.nNameHash == h"rows");
            struct ArgumentPair strArgs = EvalArgPair(strCtx.strArgs, 0, 2, DAZSCRIPT_ARG_ANY, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;
            struct Value strError = CheckSqlStateIs(sqlValue, SQLQUERY_STATE_PREPARED);
            if (IsErrorValue(strError))
                return strError;

            int nColumnCount = SqlGetColumnCount(sqlValue);
            strError = CheckSqlQueryError(sqlValue);
            if (IsErrorValue(strError))
                return strError;
            if (nColumnCount < 1)
                return GetErrorValue("SQL_NO_COLUMNS");

            string sSpec = "";
            int nLimit = 1;
            if (bRows)
                nLimit = DAZSCRIPT_SQL_ROWS_DEFAULT_LIMIT;

            if (strArgs.nCount == 1)
            {
                if (strArgs.strArg0.nAuxType == NWNX_VM_AUXTYPE_STRING)
                    sSpec = GetTrimmedValueText(strArgs.strArg0);
                else if (bRows && IsValueIntParameter(strArgs.strArg0))
                    nLimit = GetValueAsInt(strArgs.strArg0);
                else
                    return GetErrorValue(bRows ? "INVALID_ROWS_ARGUMENT_1" : "INVALID_ROW_ARGUMENT_1");
            }

            if (strArgs.nCount == 2)
            {
                if (!bRows)
                    return GetErrorValue("ROW_TOO_MANY_ARGUMENTS");
                if (strArgs.strArg0.nAuxType != NWNX_VM_AUXTYPE_STRING)
                    return GetErrorValue("INVALID_ROWS_SPEC");
                if (!IsValueIntParameter(strArgs.strArg1))
                    return GetErrorValue("INVALID_ROWS_LIMIT");

                sSpec = GetTrimmedValueText(strArgs.strArg0);
                nLimit = GetValueAsInt(strArgs.strArg1);
            }

            if (nLimit < 1)
                return GetErrorValue("SQL_ROWS_LIMIT_MUST_BE_POSITIVE");
            if (nLimit > DAZSCRIPT_SQL_ROWS_MAX_LIMIT)
                return GetErrorValue("SQL_ROWS_LIMIT_TOO_HIGH");

            strError = ValidateSqlRowSpec(sSpec, nColumnCount, "INVALID_ROW_AUXTYPE:");
            if (IsErrorValue(strError))
                return strError;

            json jColumnNames = JsonArray();
            json jColumnAuxTypes = JsonArray();
            strError = BuildSqlRowSchemaInplace(jColumnNames, jColumnAuxTypes, sqlValue, sSpec, nColumnCount);
            if (IsErrorValue(strError))
                return strError;

            if (bRows)
            {
                json jRows = JsonArray();

                int nRows = 0;
                while (nRows < nLimit)
                {
                    int bStepped = SqlStep(sqlValue);
                    strError = CheckSqlQueryError(sqlValue);
                    if (IsErrorValue(strError))
                        return strError;

                    if (!bStepped)
                        break;

                    struct Value strRow = GetSqlCurrentRowAsJson(sqlValue, jColumnNames, jColumnAuxTypes);
                    if (IsErrorValue(strRow))
                        return strRow;

                    JsonArrayInsertInplace(jRows, strRow.jValue);
                    nRows++;
                }

                return GetValueFromJson(jRows);
            }

            int bStepped = SqlStep(sqlValue);

            strError = CheckSqlQueryError(sqlValue);
            if (IsErrorValue(strError))
                return strError;

            if (!bStepped)
                return GetErrorValue("SQL_NO_ROW_DATA");

            return GetSqlCurrentRowAsJson(sqlValue, jColumnNames, jColumnAuxTypes);
        }
    }

    return GetInvalidValue();
}

struct Value ResolveJsonProperty(struct ChainContext strCtx)
{
    json jValue = strCtx.strValue.jValue;

    switch (strCtx.strArgs.nNameHash)
    {
        case "type":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;

            switch (JsonGetType(jValue))
            {
                case JSON_TYPE_NULL:    return GetValueFromString("null");
                case JSON_TYPE_OBJECT:  return GetValueFromString("object");
                case JSON_TYPE_ARRAY:   return GetValueFromString("array");
                case JSON_TYPE_STRING:  return GetValueFromString("string");
                case JSON_TYPE_INTEGER: return GetValueFromString("int");
                case JSON_TYPE_FLOAT:   return GetValueFromString("float");
                case JSON_TYPE_BOOL:    return GetValueFromString("bool");
                default:                return GetValueFromString("invalid");
            }
        }

        case "isnull": case "isobject": case "isarray": case "isstring": case "isint":
        case "isfloat": case "isnumber": case "isbool": case "scalar":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;

            int nType = JsonGetType(jValue);
            switch (strCtx.strArgs.nNameHash)
            {
                case "isnull":    return GetValueFromInt(nType == JSON_TYPE_NULL);
                case "isobject":  return GetValueFromInt(nType == JSON_TYPE_OBJECT);
                case "isarray":   return GetValueFromInt(nType == JSON_TYPE_ARRAY);
                case "isstring":  return GetValueFromInt(nType == JSON_TYPE_STRING);
                case "isint":     return GetValueFromInt(nType == JSON_TYPE_INTEGER);
                case "isfloat":   return GetValueFromInt(nType == JSON_TYPE_FLOAT);
                case "isnumber":  return GetValueFromInt(nType == JSON_TYPE_INTEGER || nType == JSON_TYPE_FLOAT);
                case "isbool":    return GetValueFromInt(nType == JSON_TYPE_BOOL);
                case "scalar":    return GetValueFromInt(nType == JSON_TYPE_NULL || nType == JSON_TYPE_STRING || nType == JSON_TYPE_INTEGER || nType == JSON_TYPE_FLOAT || nType == JSON_TYPE_BOOL);
            }
        }

        case "length":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(JsonGetLength(jValue));
        }

        case "empty": case "notempty":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;

            int nType = JsonGetType(jValue), bEmpty = FALSE;
            if (nType == JSON_TYPE_NULL)
                bEmpty = TRUE;
            else if (nType == JSON_TYPE_STRING)
                bEmpty = JsonGetString(jValue) == "";
            else if (nType == JSON_TYPE_ARRAY || nType == JSON_TYPE_OBJECT)
                bEmpty = JsonGetLength(jValue) == 0;

            if (strCtx.strArgs.nNameHash == h"notempty")
                bEmpty = !bEmpty;

            return GetValueFromInt(bEmpty);
        }

        case "has":
        {
            struct Value strArg = EvalSingleArg(strCtx.strArgs, DAZSCRIPT_ARG_STRING);
            if (IsErrorValue(strArg))
                return strArg;
            if (JsonGetType(jValue) != JSON_TYPE_OBJECT)
                return GetErrorValue("JSON_NOT_OBJECT");
            return GetValueFromInt(JsonObjectContainsKey(jValue, GetValueText(strArg)));
        }

        case "get":
        {
            struct ArgumentPair strArgs = EvalArgPair(strCtx.strArgs, 1, 2, DAZSCRIPT_ARG_STRING, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;
            if (JsonGetType(jValue) != JSON_TYPE_OBJECT)
                return GetErrorValue("JSON_NOT_OBJECT");

            string sKey = GetValueText(strArgs.strArg0);
            if (JsonObjectContainsKey(jValue, sKey))
                return ConvertJsonToValue(JsonObjectGet(jValue, sKey));
            else if (strArgs.nCount == 2)
                return strArgs.strArg1;
            else
                return GetErrorValue("JSON_MISSING_KEY:" + sKey);
        }

        case "at":
        {
            struct ArgumentPair strArgs = EvalArgPair(strCtx.strArgs, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;
            if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
                return GetErrorValue("JSON_NOT_ARRAY");

            int nIndex = GetValueAsInt(strArgs.strArg0), nLength = JsonGetLength(jValue);
            if (nIndex < 0)
                nIndex = nLength + nIndex;

            if (nIndex >= 0 && nIndex < nLength)
                return ConvertJsonToValue(JsonArrayGet(jValue, nIndex));
            else if (strArgs.nCount == 2)
                return strArgs.strArg1;
            else
                return GetErrorValue("JSON_INDEX_OUT_OF_RANGE:" + IntToString(nIndex));
        }

        case "first": case "last":
        {
            struct ArgumentPair strArg = EvalOptionalArg(strCtx.strArgs, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArg.strError))
                return strArg.strError;

            if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
                return GetErrorValue("JSON_NOT_ARRAY");

            int nLength = JsonGetLength(jValue);
            if (nLength <= 0)
            {
                if (strArg.nCount > 0)
                    return strArg.strArg0;
                return GetErrorValue("JSON_INDEX_OUT_OF_RANGE:0");
            }

            int nIndex = strCtx.strArgs.nNameHash == h"first" ? 0 : nLength - 1;
            return ConvertJsonToValue(JsonArrayGet(jValue, nIndex));
        }

        case "keys":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            if (JsonGetType(jValue) != JSON_TYPE_OBJECT)
                return GetErrorValue("JSON_NOT_OBJECT");
            return GetValueFromJson(JsonObjectKeys(jValue));
        }

        case "raw": case "dump":
        {
            struct ArgumentPair strArg = EvalOptionalArg(strCtx.strArgs, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArg.strError))
                return strArg.strError;
            int nIndent = -1;
            if (strArg.nCount > 0)
                nIndent = Max(-1, GetValueAsInt(strArg.strArg0, -1));
            return GetValueFromString(JsonDump(jValue, nIndent));
        }

        case "join":
        {
            struct ArgumentPair strArg = EvalOptionalArg(strCtx.strArgs, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArg.strError))
                return strArg.strError;
            if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
                return GetErrorValue("JSON_NOT_ARRAY");

            string sSeparator = "";
            if (strArg.nCount > 0)
                sSeparator = GetValueText(strArg.strArg0);

            string sResult = "";
            int nIndex, nLength = JsonGetLength(jValue);
            for (nIndex = 0; nIndex < nLength; nIndex++)
            {
                if (nIndex > 0)
                    sResult += sSeparator;

                struct Value strItem = ConvertJsonToValue(JsonArrayGet(jValue, nIndex));
                if (IsErrorValue(strItem))
                    return strItem;

                sResult += FormatValueForDisplay(strItem);
            }

            return GetValueFromString(sResult);
        }

        case "sort":
        {
            struct ArgumentPair strArg = EvalOptionalArg(strCtx.strArgs, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArg.strError))
                return strArg.strError;
            if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
                return GetErrorValue("JSON_NOT_ARRAY");

            int nTransform = JSON_ARRAY_SORT_ASCENDING;
            if (strArg.nCount > 0)
            {
                string sDirection = GetStringLowerCase(GetTrimmedValueText(strArg.strArg0));
                if (sDirection == "" || sDirection == "asc" || sDirection == "ascending")
                    nTransform = JSON_ARRAY_SORT_ASCENDING;
                else if (sDirection == "desc" || sDirection == "descending")
                    nTransform = JSON_ARRAY_SORT_DESCENDING;
                else
                    return GetErrorValue("SORT_DIRECTION_INVALID:" + sDirection);
            }

            return GetValueFromJson(JsonArrayTransform(jValue, nTransform));
        }

        case "shuffle":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
                return GetErrorValue("JSON_NOT_ARRAY");
            return GetValueFromJson(JsonArrayTransform(jValue, JSON_ARRAY_SHUFFLE));
        }

        case "reverse":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
                return GetErrorValue("JSON_NOT_ARRAY");
            return GetValueFromJson(JsonArrayTransform(jValue, JSON_ARRAY_REVERSE));
        }

        case "unique":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
                return GetErrorValue("JSON_NOT_ARRAY");
            return GetValueFromJson(JsonArrayTransform(jValue, JSON_ARRAY_UNIQUE));
        }

        case "coalesce":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            if (JsonGetType(jValue) != JSON_TYPE_ARRAY)
                return GetErrorValue("JSON_NOT_ARRAY");
            return ConvertJsonToValue(JsonArrayTransform(jValue, JSON_ARRAY_COALESCE));
        }
    }

    return GetInvalidValue();
}

struct Value ResolveSharedProperty(struct ChainContext strCtx)
{
    switch (strCtx.strArgs.nNameHash)
    {
        case "color":
        {
            if (strCtx.strArgs.nParameterCount == 1)
            {
                struct Value strArg = EvalSingleArg(strCtx.strArgs);
                if (IsErrorValue(strArg))
                    return strArg;

                string sValue = FormatValueForDisplay(strCtx.strValue);
                string sColor = GetStringLowerCase(GetTrimmedValueText(strArg));
                if (GetStringLeft(sColor, 1) == "#")
                    return GetValueFromHexColor(sValue, sColor);
                else
                    return GetValueFromNamedColor(sValue, sColor);
            }

            if (strCtx.strArgs.nParameterCount == 3)
            {
                struct ThreeArguments strArgs = EvalThreeArgs(strCtx.strArgs, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
                if (IsErrorValue(strArgs.strError))
                    return strArgs.strError;
                return GetValueFromString(ColorString(FormatValueForDisplay(strCtx.strValue), GetValueAsInt(strArgs.strArg0), GetValueAsInt(strArgs.strArg1), GetValueAsInt(strArgs.strArg2)));
            }
            return GetErrorValue("ARITY:EXPECTED_1_OR_3_ARGUMENTS");
        }

        case "padleft": case "padright":
        {
            struct ArgumentPair strArgs = EvalArgPair(strCtx.strArgs, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            int nLength = GetValueAsInt(strArgs.strArg0);
            string sPadding = " ";
            if (strArgs.nCount >= 2)
                sPadding = GetValueText(strArgs.strArg1, " ");
            if (strCtx.strArgs.nNameHash == h"padleft")
                return GetValueFromString(LeftPadString(FormatValueForDisplay(strCtx.strValue), nLength, sPadding));
            else
                return GetValueFromString(RightPadString(FormatValueForDisplay(strCtx.strValue), nLength, sPadding));
        }

        case "int": case "float": case "string": case "object": case "json":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return CastValueToAuxType(strCtx.strValue, GetCastAuxTypeFromName(strCtx.strArgs.sName));
        }

        case "fixed":
        {
            struct ArgumentPair strArg = EvalOptionalArg(strCtx.strArgs, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArg.strError))
                return strArg.strError;

            int nPrecision = 2;
            if (strArg.nCount > 0)
                nPrecision = GetValueAsInt(strArg.strArg0, 2);
            return FormatValueAsFixed(strCtx.strValue, nPrecision);
        }

        case "hex":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return FormatValueAsHex(strCtx.strValue);
        }

        case "bool":
        {
            struct Value strError = CheckZeroArgs(strCtx.strArgs);
            if (IsErrorValue(strError))
                return strError;
            return FormatValueAsBoolean(strCtx.strValue);
        }

        case "default":
        {
            struct Value strError = CheckArity(strCtx.strArgs, 1, 1);
            if (IsErrorValue(strError))
                return strError;
            if (ValueNeedsDefault(strCtx.strValue))
                return EvalParameter(strCtx.strArgs, 0);
            else
                return strCtx.strValue;
        }

        case "tee":
        {
            struct Value strError = CheckArity(strCtx.strArgs, 1, 1);
            if (IsErrorValue(strError))
                return strError;
            if (!IsAliasValueAuxType(strCtx.strValue.nAuxType))
                return GetErrorValue("TYPE_MISMATCH:" + AuxTypeToString(strCtx.strValue.nAuxType));
            json jFrame = JsonCopyObject(strCtx.strArgs.jStack);
            JsonObjectSetInplace(jFrame, DAZSCRIPT_THIS_ALIAS, MakeStackAliasEntryFromValue(strCtx.strValue));
            strError = EvalParameterUsingStack(strCtx.strArgs, 0, jFrame);
            if (IsErrorValue(strError))
                return strError;

            return strCtx.strValue;
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaPrimitive(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "int": case "float": case "string": case "object": case "json":
        {
            struct Value strArg = EvalSingleArg(strArgCtx);
            if (IsErrorValue(strArg))
                return strArg;
            return CastValueToAuxType(strArg, GetCastAuxTypeFromName(strArgCtx.sName));
        }

        case "jsonarray": case "arr":
        {
            json jArray = JsonArray();

            int nIndex;
            for (nIndex = 0; nIndex < strArgCtx.nParameterCount; nIndex++)
            {
                struct Value strValue = EvalParameter(strArgCtx, nIndex);
                if (IsErrorValue(strValue))
                    return strValue;
                strValue = ValueToJsonValue(strValue);
                if (IsErrorValue(strValue))
                    return strValue;
                JsonArrayInsertInplace(jArray, strValue.jValue);
            }
            return GetValueFromJson(jArray);
        }

        case "jsonobject": case "obj":
        {
            if (strArgCtx.nParameterCount % 2 != 0)
                return GetErrorValue(GetStringUpperCase(strArgCtx.sName) + "_USAGE:@" +  strArgCtx.sName + "(key,value,...)");

            json jObject = JsonObject();

            int nIndex;
            for (nIndex = 0; nIndex < strArgCtx.nParameterCount; nIndex += 2)
            {
                struct Value strKey = EvalTypedParameter(strArgCtx, nIndex, DAZSCRIPT_ARG_STRING);
                if (IsErrorValue(strKey))
                    return strKey;
                struct Value strValue = EvalParameter(strArgCtx, nIndex + 1);
                if (IsErrorValue(strValue))
                    return strValue;
                strValue = ValueToJsonValue(strValue);
                if (IsErrorValue(strValue))
                    return strValue;

                JsonObjectSetInplace(jObject, GetValueText(strKey), strValue.jValue);
            }

            return GetValueFromJson(jObject);
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaFunction(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "fn":
        {
            if (strArgCtx.nParameterCount < 2)
                return GetErrorValue("FN_USAGE:@fn(#name, $arg..., body)");

            string sFunctionName = GetStringLowerCase(GetRawParameterText(strArgCtx, 0));
            if (!IsSymbol(sFunctionName, DAZSCRIPT_FUNCTION_SYMBOL))
                return GetErrorValue("INVALID_FUNCTION_NAME:" + sFunctionName);

            json jArgs = JsonArray();
            int nIndex, nLast = strArgCtx.nParameterCount - 1;
            for (nIndex = 1; nIndex < nLast; nIndex++)
            {
                string sAlias = GetRawParameterText(strArgCtx, nIndex);
                if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
                    return GetErrorValue("FUNCTION_PARAMETER_IS_NON_ALIAS:" + sAlias);
                if (JsonArrayContainsString(jArgs, sAlias))
                    return GetErrorValue("DUPLICATE_FUNCTION_PARAMETER:" + sAlias);

                JsonArrayInsertStringInplace(jArgs, sAlias);
            }

            string sBody = GetRawParameterText(strArgCtx, nLast);
            json jCompiledBody = CompileTemplateCached(sBody);

            if (IsParserError(jCompiledBody))
                return GetValueFromParserError(jCompiledBody, "function_body");
            if (JsonGetType(jCompiledBody) != JSON_TYPE_ARRAY)
                return GetErrorValue("INVALID_FUNCTION_BODY:" + sFunctionName);

            json jFunction = JsonObject();
            JsonObjectSetInplace(jFunction, DAZSCRIPT_FUNCTION_ARGS, jArgs);
            JsonObjectSetStringInplace(jFunction, DAZSCRIPT_FUNCTION_BODY, sBody);
            JsonObjectSetInplace(jFunction, DAZSCRIPT_FUNCTION_BODY_COMPILED, jCompiledBody);
            JsonObjectSetInplace(strArgCtx.jStack, sFunctionName, jFunction);

            return GetValueFromString();
        }

        case "eval":
        {
            struct Value strArg = EvalSingleArg(strArgCtx, DAZSCRIPT_ARG_STRING);
            if (IsErrorValue(strArg))
                return strArg;
            return EvalTemplate(CompileTemplateCached(GetValueText(strArg)), strArgCtx.jStack);
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaControlFlow(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "if":
        {
            struct Value strError = CheckArity(strArgCtx, 3, 3);
            if (IsErrorValue(strError))
                return strError;
            struct Value strCondition = EvalParameter(strArgCtx, 0);
            if (IsErrorValue(strCondition))
                return strCondition;

            int nBranch = IsValueTruthy(strCondition) ? 1 : 2;

            if (IsTraceEnabled()) { Trace("if.branch", nBranch == 1 ? "then[1]" : "else[2]"); }

            return EvalParameter(strArgCtx, nBranch);
        }

        case "while":
        {
            struct Value strError = CheckArity(strArgCtx, 2, 3);
            if (IsErrorValue(strError))
                return strError;

            int nIterations = 0, nLimit = DAZSCRIPT_WHILE_DEFAULT_ITERATION_LIMIT;
            if (strArgCtx.nParameterCount == 3)
            {
                struct Value strLimit = EvalTypedParameter(strArgCtx, 2, DAZSCRIPT_ARG_INT);
                if (IsErrorValue(strLimit))
                    return strLimit;
                nLimit = Clamp(GetValueAsInt(strLimit), 0, DAZSCRIPT_WHILE_MAX_ITERATION_LIMIT);
            }

            int bTraceEnabled = IsTraceEnabled();

            if (bTraceEnabled) { Trace("while.start", "limit=" + IntToString(nLimit)); }

            string sAccumulator;
            while (TRUE)
            {
                struct Value strConditionResult = EvalParameter(strArgCtx, 0);
                if (IsErrorValue(strConditionResult))
                    return strConditionResult;

                if (!IsValueTruthy(strConditionResult))
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
                struct Value strBodyResult = EvalParameter(strArgCtx, 1);

                if (bTraceEnabled) { TraceExit("while.iter.exit", "iteration=" + IntToString(nIteration) + "; result=" + TraceValue(strBodyResult)); }

                if (IsErrorValue(strBodyResult))
                    return strBodyResult;

                sAccumulator += FormatValueForDisplay(strBodyResult);
            }

            return GetValueFromString(sAccumulator);
        }

        case "pick":
        {
            struct Value strError = CheckArity(strArgCtx, 1, -1);
            if (IsErrorValue(strError))
                return strError;

            int nIndex = Random(strArgCtx.nParameterCount);
            return EvalParameter(strArgCtx, nIndex);
        }

        case "not":
        {
            struct Value strArg = EvalSingleArg(strArgCtx);
            if (IsErrorValue(strArg))
                return strArg;
            return GetValueFromInt(!IsValueTruthy(strArg));
        }

        case "and": case "all":
        {
            struct Value strError = CheckArity(strArgCtx, 1, -1);
            if (IsErrorValue(strError))
                return strError;

            int nIndex, bResult = TRUE;
            for (nIndex = 0; nIndex < strArgCtx.nParameterCount; nIndex++)
            {
                struct Value strParameter = EvalParameter(strArgCtx, nIndex);
                if (IsErrorValue(strParameter))
                    return strParameter;

                if (!IsValueTruthy(strParameter))
                {
                    bResult = FALSE;
                    break;
                }
            }

            return GetValueFromInt(bResult);
        }

        case "or": case "any":
        {
            struct Value strError = CheckArity(strArgCtx, 1, -1);
            if (IsErrorValue(strError))
                return strError;

            int nIndex, bResult = FALSE;
            for (nIndex = 0; nIndex < strArgCtx.nParameterCount; nIndex++)
            {
                struct Value strParameter = EvalParameter(strArgCtx, nIndex);
                if (IsErrorValue(strParameter))
                    return strParameter;

                if (IsValueTruthy(strParameter))
                {
                    bResult = TRUE;
                    break;
                }
            }

            return GetValueFromInt(bResult);
        }

        case "switch":
        {
            struct Value strError = CheckArity(strArgCtx, 3, -1);
            if (IsErrorValue(strError))
                return strError;

            struct Value strSelectorValue = EvalParameter(strArgCtx, 0);
            if (IsErrorValue(strSelectorValue))
                return strSelectorValue;

            string sSelector = FormatValueForDisplay(strSelectorValue);
            int nDefaultIndex = -1;

            if (strArgCtx.nParameterCount % 2 == 0)
                nDefaultIndex = strArgCtx.nParameterCount - 1;

            int nIndex, nEnd = nDefaultIndex == -1 ? strArgCtx.nParameterCount : nDefaultIndex;
            for (nIndex = 1; nIndex + 1 < nEnd; nIndex += 2)
            {
                struct Value strCaseValue = EvalParameter(strArgCtx, nIndex);
                if (IsErrorValue(strCaseValue))
                    return strCaseValue;

                string sCase = FormatValueForDisplay(strCaseValue);
                if (sSelector == sCase)
                    return EvalParameter(strArgCtx, nIndex + 1);
            }

            if (nDefaultIndex != -1)
                return EvalParameter(strArgCtx, nDefaultIndex);

            return GetValueFromString();
        }

        case "foreachpc":
        {
            struct Value strError = CheckArity(strArgCtx, 2, 2);
            if (IsErrorValue(strError))
                return strError;

            string sAlias = GetRawParameterText(strArgCtx, 0);
            if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("FOREACHPC_ALIAS_IS_NON_ALIAS:" + sAlias);

            json jBody = GetParameterTemplate(strArgCtx, 1);
            json jFrame = JsonCopyObject(strArgCtx.jStack);
            string sAccumulator = "";

            object oPC = GetFirstPC();
            while (GetIsObjectValid(oPC))
            {
                JsonObjectSetInplace(jFrame, sAlias, MakeStackAliasEntryFromValue(GetValueFromObject(oPC)));
                struct Value strBodyResult = EvalTemplate(jBody, jFrame);

                if (IsErrorValue(strBodyResult))
                    return strBodyResult;

                sAccumulator += FormatValueForDisplay(strBodyResult);
                oPC = GetNextPC();
            }

            return GetValueFromString(sAccumulator);
        }

        case "try":
        {
            struct Value strError = CheckArity(strArgCtx, 2, -1);
            if (IsErrorValue(strError))
                return strError;

            struct Value strLastError = GetInvalidValue();

            int nIndex;
            for (nIndex = 0; nIndex < strArgCtx.nParameterCount; nIndex++)
            {
                struct Value strCandidate = EvalParameter(strArgCtx, nIndex);
                if (!IsErrorValue(strCandidate))
                    return strCandidate;
                strLastError = strCandidate;
            }

            return strLastError;
        }

        case "catch":
        {
            struct Value strError = CheckArity(strArgCtx, 3, 4);
            if (IsErrorValue(strError))
                return strError;

            string sErrorAlias = GetRawParameterText(strArgCtx, 1);
            if (!IsSymbol(sErrorAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("CATCH_ALIAS_IS_NON_ALIAS:" + sErrorAlias);

            struct Value strCandidate = EvalParameter(strArgCtx, 0);
            if (!IsErrorValue(strCandidate))
                return strCandidate;

            json jFrame = JsonCopyObject(strArgCtx.jStack);
            JsonObjectSetInplace(jFrame, sErrorAlias, MakeStackAliasEntryFromValue(GetValueFromString(strCandidate.sErrorMessage)));

            if (strArgCtx.nParameterCount == 3)
                return EvalParameterUsingStack(strArgCtx, 2, jFrame);

            struct Value strPredicate = EvalParameterUsingStack(strArgCtx, 2, jFrame);
            if (IsErrorValue(strPredicate))
                return strPredicate;
            if (!IsValueTruthy(strPredicate))
                return strCandidate;

            return EvalParameterUsingStack(strArgCtx, 3, jFrame);
        }

        case "do":
        {
            if (strArgCtx.nParameterCount < 1)
                return GetErrorValue("ARITY:EXPECTED_AT_LEAST_1_ARGUMENT");

            int nIndex;
            struct Value strResult = GetValueFromString();
            for (nIndex = 0; nIndex < strArgCtx.nParameterCount; nIndex++)
            {
                strResult = EvalParameter(strArgCtx, nIndex);
                if (IsErrorValue(strResult))
                    return strResult;
            }
            return strResult;
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaCollection(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        // @foreach(collection, $value, body)
        // @foreach(collection, $key, $value, body)
        case "foreach":
        {
            if (strArgCtx.nParameterCount != 3 && strArgCtx.nParameterCount != 4)
                return GetErrorValue("FOREACH_USAGE:@foreach(collection,$value,body) OR @foreach(collection,$key,$value,body)");

            int bHasKeyAlias = strArgCtx.nParameterCount == 4;
            string sKeyAlias = bHasKeyAlias ? GetRawParameterText(strArgCtx, 1) : "";
            string sValueAlias = GetRawParameterText(strArgCtx, bHasKeyAlias ? 2 : 1);
            int nBodyIndex = bHasKeyAlias ? 3 : 2;

            if (bHasKeyAlias && !IsSymbol(sKeyAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("FOREACH_KEY_ALIAS_IS_NON_ALIAS:" + sKeyAlias);
            if (!IsSymbol(sValueAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("FOREACH_VALUE_ALIAS_IS_NON_ALIAS:" + sValueAlias);
            if (bHasKeyAlias && sKeyAlias == sValueAlias)
                return GetErrorValue("FOREACH_DUPLICATE_ALIAS:" + sKeyAlias);

            struct Value strCollection = EvalParameter(strArgCtx, 0);
            if (IsErrorValue(strCollection))
                return strCollection;
            strCollection = CastValueToJson(strCollection);
            if (IsErrorValue(strCollection))
                return strCollection;

            json jCollection = strCollection.jValue;
            int nJsonType = JsonGetType(jCollection);

            if (nJsonType != JSON_TYPE_ARRAY && nJsonType != JSON_TYPE_OBJECT)
                return GetErrorValue("FOREACH_JSON_NOT_ARRAY_OR_OBJECT");

            json jBody = GetParameterTemplate(strArgCtx, nBodyIndex);
            json jFrame = JsonCopyObject(strArgCtx.jStack);
            string sAccumulator = "";
            int nIndex, nLength;
            if (nJsonType == JSON_TYPE_ARRAY)
            {
                nLength = JsonGetLength(jCollection);
                for (nIndex = 0; nIndex < nLength; nIndex++)
                {
                    if (bHasKeyAlias)
                        JsonObjectSetInplace(jFrame, sKeyAlias, MakeStackAliasEntryFromValue(GetValueFromInt(nIndex)));

                    struct Value strItem = ConvertJsonToValue(JsonArrayGet(jCollection, nIndex));
                    if (IsErrorValue(strItem))
                        return strItem;

                    JsonObjectSetInplace(jFrame, sValueAlias, MakeStackAliasEntryFromValue(strItem));

                    struct Value strBodyResult = EvalTemplate(jBody, jFrame);
                    if (IsErrorValue(strBodyResult))
                        return strBodyResult;

                    sAccumulator += FormatValueForDisplay(strBodyResult);
                }
            }
            else
            {
                json jKeys = JsonObjectKeys(jCollection);
                nLength = JsonGetLength(jKeys);

                for (nIndex = 0; nIndex < nLength; nIndex++)
                {
                    string sKey = JsonArrayGetString(jKeys, nIndex);

                    if (bHasKeyAlias)
                        JsonObjectSetInplace(jFrame, sKeyAlias, MakeStackAliasEntryFromValue(GetValueFromString(sKey)));

                    struct Value strItem = ConvertJsonToValue(JsonObjectGet(jCollection, sKey));
                    if (IsErrorValue(strItem))
                        return strItem;

                    JsonObjectSetInplace(jFrame, sValueAlias, MakeStackAliasEntryFromValue(strItem));

                    struct Value strBodyResult = EvalTemplate(jBody, jFrame);
                    if (IsErrorValue(strBodyResult))
                        return strBodyResult;

                    sAccumulator += FormatValueForDisplay(strBodyResult);
                }
            }

            return GetValueFromString(sAccumulator);
        }

        //@map(array, $value, body)
        //@map(array, $index, $value, body)
        case "map":
        {
            if (strArgCtx.nParameterCount != 3 && strArgCtx.nParameterCount != 4)
                return GetErrorValue("MAP_USAGE:@map(array,$value,body) OR @map(array,$index,$value,body)");

            int bHasIndexAlias = strArgCtx.nParameterCount == 4;
            string sIndexAlias = bHasIndexAlias ? GetRawParameterText(strArgCtx, 1) : "";
            string sValueAlias = GetRawParameterText(strArgCtx, bHasIndexAlias ? 2 : 1);
            int nBodyIndex = bHasIndexAlias ? 3 : 2;

            struct Value strValidate = ValidateLoopAliases(strArgCtx.sName, bHasIndexAlias, sIndexAlias, sValueAlias);
            if (IsErrorValue(strValidate))
                return strValidate;
            struct Value strCollection = EvalJsonArrayParameter(strArgCtx, 0, "MAP_JSON_NOT_ARRAY");
            if (IsErrorValue(strCollection))
                return strCollection;

            json jBody = GetParameterTemplate(strArgCtx, nBodyIndex);
            json jFrame = JsonCopyObject(strArgCtx.jStack);
            json jResult = JsonArray();

            int nIndex, nLength = JsonGetLength(strCollection.jValue);
            for (nIndex = 0; nIndex < nLength; nIndex++)
            {
                struct Value strItem = BindArrayLoopAliasesInplace(jFrame, strCollection.jValue, nIndex, bHasIndexAlias, sIndexAlias, sValueAlias);
                if (IsErrorValue(strItem))
                    return strItem;

                struct Value strMapped = EvalTemplate(jBody, jFrame);
                if (IsErrorValue(strMapped))
                    return strMapped;

                struct Value strResult = ValueToJsonValue(strMapped);
                if (IsErrorValue(strResult))
                    return strResult;
                JsonArrayInsertInplace(jResult, strResult.jValue);
            }

            return GetValueFromJson(jResult);
        }

        // @each(array, body)
        case "each":
        {
            if (strArgCtx.nParameterCount != 2)
                return GetErrorValue("EACH_USAGE:@each(array,body)");

            struct Value strCollection = EvalJsonArrayParameter(strArgCtx, 0, "EACH_JSON_NOT_ARRAY");
            if (IsErrorValue(strCollection))
                return strCollection;

            json jBody = GetParameterTemplate(strArgCtx, 1);
            json jFrame = JsonCopyObject(strArgCtx.jStack);
            json jResult = JsonArray();

            int nIndex, nLength = JsonGetLength(strCollection.jValue);
            for (nIndex = 0; nIndex < nLength; nIndex++)
            {
                struct Value strItem = ConvertJsonToValue(JsonArrayGet(strCollection.jValue, nIndex));
                if (IsErrorValue(strItem))
                    return strItem;

                JsonObjectSetInplace(jFrame, DAZSCRIPT_THIS_ALIAS, MakeStackAliasEntryFromValue(strItem));

                struct Value strEach = EvalTemplate(jBody, jFrame);
                if (IsErrorValue(strEach))
                    return strEach;

                struct Value strResult = ValueToJsonValue(strEach);
                if (IsErrorValue(strResult))
                    return strResult;
                JsonArrayInsertInplace(jResult, strResult.jValue);
            }

            return GetValueFromJson(jResult);
        }

        // @filter(array, $value, predicate)
        // @filter(array, $index, $value, predicate)
        case "filter":
        {
            if (strArgCtx.nParameterCount != 3 && strArgCtx.nParameterCount != 4)
                return GetErrorValue("FILTER_USAGE:@filter(array,$value,predicate) OR @filter(array,$index,$value,predicate)");

            int bHasIndexAlias = strArgCtx.nParameterCount == 4;
            string sIndexAlias = bHasIndexAlias ? GetRawParameterText(strArgCtx, 1) : "";
            string sValueAlias = GetRawParameterText(strArgCtx, bHasIndexAlias ? 2 : 1);
            int nPredicateIndex = bHasIndexAlias ? 3 : 2;

            struct Value strValidate = ValidateLoopAliases(strArgCtx.sName, bHasIndexAlias, sIndexAlias, sValueAlias);
            if (IsErrorValue(strValidate))
                return strValidate;
            struct Value strCollection = EvalJsonArrayParameter(strArgCtx, 0, "FILTER_JSON_NOT_ARRAY");
            if (IsErrorValue(strCollection))
                return strCollection;

            json jPredicate = GetParameterTemplate(strArgCtx, nPredicateIndex);
            json jFrame = JsonCopyObject(strArgCtx.jStack);
            json jResult = JsonArray();

            int nIndex, nLength = JsonGetLength(strCollection.jValue);
            for (nIndex = 0; nIndex < nLength; nIndex++)
            {
                struct Value strItem = BindArrayLoopAliasesInplace(jFrame, strCollection.jValue, nIndex, bHasIndexAlias, sIndexAlias, sValueAlias);
                if (IsErrorValue(strItem))
                    return strItem;
                struct Value strPredicate = EvalTemplate(jPredicate, jFrame);
                if (IsErrorValue(strPredicate))
                    return strPredicate;

                if (IsValueTruthy(strPredicate))
                    JsonArrayInsertInplace(jResult, JsonArrayGet(strCollection.jValue, nIndex));
            }

            return GetValueFromJson(jResult);
        }

        // @reduce(array, initial, $acc, $value, body)
        // @reduce(array, initial, $acc, $index, $value, body)
        case "reduce":
        {
            if (strArgCtx.nParameterCount != 5 && strArgCtx.nParameterCount != 6)
                return GetErrorValue("REDUCE_USAGE:@reduce(array,initial,$acc,$value,body) OR @reduce(array,initial,$acc,$index,$value,body)");

            int bHasIndexAlias = strArgCtx.nParameterCount == 6;
            string sAccumulatorAlias = GetRawParameterText(strArgCtx, 2);
            string sIndexAlias = bHasIndexAlias ? GetRawParameterText(strArgCtx, 3) : "";
            string sValueAlias = GetRawParameterText(strArgCtx, bHasIndexAlias ? 4 : 3);
            int nBodyIndex = bHasIndexAlias ? 5 : 4;

            if (!IsSymbol(sAccumulatorAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("REDUCE_ACCUMULATOR_ALIAS_IS_NON_ALIAS:" + sAccumulatorAlias);
            if (bHasIndexAlias && !IsSymbol(sIndexAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("REDUCE_INDEX_ALIAS_IS_NON_ALIAS:" + sIndexAlias);
            if (!IsSymbol(sValueAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("REDUCE_VALUE_ALIAS_IS_NON_ALIAS:" + sValueAlias);
            if (sAccumulatorAlias == sValueAlias)
                return GetErrorValue("REDUCE_DUPLICATE_ALIAS:" + sAccumulatorAlias);
            if (bHasIndexAlias && sAccumulatorAlias == sIndexAlias)
                return GetErrorValue("REDUCE_DUPLICATE_ALIAS:" + sAccumulatorAlias);
            if (bHasIndexAlias && sIndexAlias == sValueAlias)
                return GetErrorValue("REDUCE_DUPLICATE_ALIAS:" + sIndexAlias);

            struct Value strCollection = EvalJsonArrayParameter(strArgCtx, 0, "REDUCE_JSON_NOT_ARRAY");
            if (IsErrorValue(strCollection))
                return strCollection;

            struct Value strAccumulator = EvalParameter(strArgCtx, 1);
            if (IsErrorValue(strAccumulator))
                return strAccumulator;

            json jBody = GetParameterTemplate(strArgCtx, nBodyIndex);
            json jFrame = JsonCopyObject(strArgCtx.jStack);

            int nIndex, nLength = JsonGetLength(strCollection.jValue);
            for (nIndex = 0; nIndex < nLength; nIndex++)
            {
                JsonObjectSetInplace(jFrame, sAccumulatorAlias, MakeStackAliasEntryFromValue(strAccumulator));
                struct Value strItem = BindArrayLoopAliasesInplace(jFrame, strCollection.jValue, nIndex, bHasIndexAlias, sIndexAlias, sValueAlias);
                if (IsErrorValue(strItem))
                    return strItem;
                strAccumulator = EvalTemplate(jBody, jFrame);
                if (IsErrorValue(strAccumulator))
                    return strAccumulator;
            }

            return strAccumulator;
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaAggregate(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        // @count(array)
        // @count(array, $value, predicate)
        // @count(array, $index, $value, predicate)
        case "count":
        {
            if (strArgCtx.nParameterCount != 1 && strArgCtx.nParameterCount != 3 && strArgCtx.nParameterCount != 4)
                return GetErrorValue("COUNT_USAGE:@count(array) OR @count(array,$value,predicate) OR @count(array,$index,$value,predicate)");

            struct Value strCollection = EvalJsonArrayParameter(strArgCtx, 0, "COUNT_JSON_NOT_ARRAY");
            if (IsErrorValue(strCollection))
                return strCollection;

            int nIndex, nLength = JsonGetLength(strCollection.jValue);
            if (strArgCtx.nParameterCount == 1)
                return GetValueFromInt(nLength);

            int bHasIndexAlias = strArgCtx.nParameterCount == 4;
            string sIndexAlias = bHasIndexAlias ? GetRawParameterText(strArgCtx, 1) : "";
            string sValueAlias = GetRawParameterText(strArgCtx, bHasIndexAlias ? 2 : 1);
            int nPredicateIndex = bHasIndexAlias ? 3 : 2;

            struct Value strValidate = ValidateLoopAliases(strArgCtx.sName, bHasIndexAlias, sIndexAlias, sValueAlias);
            if (IsErrorValue(strValidate))
                return strValidate;

            json jPredicate = GetParameterTemplate(strArgCtx, nPredicateIndex);
            json jFrame = JsonCopyObject(strArgCtx.jStack);
            int nMatched = 0;

            for (nIndex = 0; nIndex < nLength; nIndex++)
            {
                struct Value strItem = BindArrayLoopAliasesInplace(jFrame, strCollection.jValue, nIndex, bHasIndexAlias, sIndexAlias, sValueAlias);
                if (IsErrorValue(strItem))
                    return strItem;
                struct Value strPredicate = EvalTemplate(jPredicate, jFrame);
                if (IsErrorValue(strPredicate))
                    return strPredicate;
                if (IsValueTruthy(strPredicate))
                    nMatched++;
            }

            return GetValueFromInt(nMatched);
        }

        // @sum(array)
        // @sum(array, $value, selector)
        // @sum(array, $index, $value, selector)
        // @avg(array)
        // @avg(array, $value, selector)
        // @avg(array, $index, $value, selector)
        case "sum": case "avg":
        {
            if (strArgCtx.nParameterCount != 1 && strArgCtx.nParameterCount != 3 && strArgCtx.nParameterCount != 4)
            {
                string sMetaName = strArgCtx.sName;
                return GetErrorValue(GetStringUpperCase(sMetaName) + "_USAGE:@" + sMetaName + "(array) OR @" + sMetaName + "(array,$value,selector) OR @" + sMetaName + "(array,$index,$value,selector)");
            }
            struct Value strCollection = EvalJsonArrayParameter(strArgCtx, 0, GetStringUpperCase(strArgCtx.sName) + "_JSON_NOT_ARRAY");
            if (IsErrorValue(strCollection))
                return strCollection;

            int bHasSelector = strArgCtx.nParameterCount != 1;
            int bHasIndexAlias = strArgCtx.nParameterCount == 4;
            string sIndexAlias = bHasIndexAlias ? GetRawParameterText(strArgCtx, 1) : "";
            string sValueAlias = bHasSelector ? GetRawParameterText(strArgCtx, bHasIndexAlias ? 2 : 1) : "";
            int nSelectorIndex = bHasIndexAlias ? 3 : 2;

            if (bHasSelector)
            {
                struct Value strValidate = ValidateLoopAliases(strArgCtx.sName, bHasIndexAlias, sIndexAlias, sValueAlias);
                if (IsErrorValue(strValidate))
                    return strValidate;
            }

            json jSelector, jFrame;
            if (bHasSelector)
            {
                jSelector = GetParameterTemplate(strArgCtx, nSelectorIndex);
                jFrame = JsonCopyObject(strArgCtx.jStack);
            }

            int nIndex, nLength = JsonGetLength(strCollection.jValue);
            if (strArgCtx.nNameHash == h"avg" && nLength == 0)
                return GetErrorValue("AVG_EMPTY_ARRAY");

            int bAllInt = TRUE;
            int nIntTotal = 0;
            float fTotal = 0.0;

            for (nIndex = 0; nIndex < nLength; nIndex++)
            {
                struct Value strValue = ConvertJsonToValue(JsonArrayGet(strCollection.jValue, nIndex));
                if (IsErrorValue(strValue))
                    return strValue;

                if (bHasSelector)
                {
                    if (bHasIndexAlias)
                        JsonObjectSetInplace(jFrame, sIndexAlias, MakeStackAliasEntryFromValue(GetValueFromInt(nIndex)));

                    JsonObjectSetInplace(jFrame, sValueAlias, MakeStackAliasEntryFromValue(strValue));

                    strValue = EvalTemplate(jSelector, jFrame);
                    if (IsErrorValue(strValue))
                        return strValue;
                }

                if (!IsValueNumericParameter(strValue))
                    return GetErrorValue(GetStringUpperCase(strArgCtx.sName) + "_VALUE_NOT_NUMERIC:" + TraceValue(strValue));

                if (IsValueIntParameter(strValue))
                {
                    int nValue = GetValueAsInt(strValue);
                    nIntTotal += nValue;
                    fTotal += IntToFloat(nValue);
                }
                else
                {
                    bAllInt = FALSE;
                    fTotal += GetValueAsFloat(strValue);
                }
            }

            if (strArgCtx.nNameHash == h"avg")
                return GetValueFromFloat(fTotal / IntToFloat(nLength));

            if (bAllInt)
                return GetValueFromInt(nIntTotal);
            return GetValueFromFloat(fTotal);
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaVariable(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "let":
        {
            struct Value strError = CheckArity(strArgCtx, 3, -1);
            if (IsErrorValue(strError))
                return strError;

            if (strArgCtx.nParameterCount % 2 != 1)
                return GetErrorValue("LET_EXPECTS_BINDINGS_PLUS_BODY");

            json jFrame = JsonCopyObject(strArgCtx.jStack);

            int nIndex;
            for (nIndex = 0; nIndex < strArgCtx.nParameterCount - 1; nIndex += 2)
            {
                string sAlias = GetRawParameterText(strArgCtx, nIndex);
                if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
                    return GetErrorValue("LET_ALIAS_IS_NON_ALIAS:" + sAlias);

                struct Value strValue = EvalParameterUsingStack(strArgCtx, nIndex + 1, jFrame);
                if (IsErrorValue(strValue))
                    return strValue;

                JsonObjectSetInplace(jFrame, sAlias, MakeStackAliasEntryFromValue(strValue));
            }

            return EvalParameterUsingStack(strArgCtx, strArgCtx.nParameterCount - 1, jFrame);
        }

        case "set":
        {
            struct Value strError = CheckArity(strArgCtx, 2, 2);
            if (IsErrorValue(strError))
                return strError;

            string sAlias = GetRawParameterText(strArgCtx, 0);
            if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("SET_ALIAS_IS_NON_ALIAS:" + sAlias);
            struct Value strValue = EvalParameter(strArgCtx, 1);
            if (IsErrorValue(strValue))
                return strValue;

            JsonObjectSetInplace(strArgCtx.jStack, sAlias, MakeStackAliasEntryFromValue(strValue));
            return GetValueFromString();
        }

        case "unset":
        {
            struct Value strError = CheckArity(strArgCtx, 1, 1);
            if (IsErrorValue(strError))
                return strError;

            string sAlias = GetRawParameterText(strArgCtx, 0);
            if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("UNSET_ALIAS_IS_NON_ALIAS:" + sAlias);

            JsonObjectDelInplace(strArgCtx.jStack, sAlias);
            return GetValueFromString();
        }

        case "cast":
        {
            struct Value strError = CheckArity(strArgCtx, 2, 2);
            if (IsErrorValue(strError))
                return strError;

            string sAlias = GetRawParameterText(strArgCtx, 0);
            if (!IsSymbol(sAlias, DAZSCRIPT_ALIAS_SYMBOL))
                return GetErrorValue("CAST_ALIAS_IS_NON_ALIAS:" + sAlias);

            if (!JsonObjectContainsKey(strArgCtx.jStack, sAlias))
                return GetErrorValue("UNKNOWN_ALIAS:" + sAlias);

            string sCast = GetRawParameterText(strArgCtx, 1);
            int nTargetAuxType = GetCastAuxTypeFromName(sCast);

            if (nTargetAuxType == NWNX_VM_AUXTYPE_INVALID)
                return GetErrorValue("INVALID_CAST_TYPE:" + sCast);

            struct Value strCurrentValue = ResolveAliasValue(strArgCtx.jStack, sAlias);
            if (IsErrorValue(strCurrentValue))
                return strCurrentValue;

            struct Value strCastedValue = CastValueToAuxType(strCurrentValue, nTargetAuxType);
            if (IsErrorValue(strCastedValue))
                return strCastedValue;

            JsonObjectSetInplace(strArgCtx.jStack, sAlias, MakeStackAliasEntryFromValue(strCastedValue));
            return GetValueFromString();
        }

        case "out":
        {
            struct Value strError = CheckArity(strArgCtx, 2, 2);
            if (IsErrorValue(strError))
                return strError;

            string sVarName = GetRawParameterText(strArgCtx, 0);
            if (!IsStackVar(sVarName))
                return GetErrorValue("OUT_ARGUMENT_IS_NON_STACKVAR:" + sVarName);
            if (!JsonObjectContainsKey(strArgCtx.jStack, sVarName))
                return GetErrorValue("UNKNOWN_STACK_VAR:" + sVarName);

            struct Value strValue = EvalParameter(strArgCtx, 1);
            if (IsErrorValue(strValue))
                return strValue;

            json jStackVar = JsonObjectGet(strArgCtx.jStack, sVarName);
            int nAuxType = JsonObjectGetInt(jStackVar, NWNX_VM_TYPE_KEY);
            int nStackLocation = JsonObjectGetInt(jStackVar, NWNX_VM_STACK_LOCATION_KEY);

            return SetStackLocationFromValue(nAuxType, nStackLocation, strValue);
        }

        case "with":
        {
            struct Value strError = CheckArity(strArgCtx, 2, 2);
            if (IsErrorValue(strError))
                return strError;

            string sRaw = GetRawParameterText(strArgCtx, 0);
            struct Value strValue;
            if (!GetRawParameterWasQuoted(strArgCtx, 0) && IsSymbol(sRaw, DAZSCRIPT_ALIAS_SYMBOL))
                strValue = ResolveAliasValue(strArgCtx.jStack, sRaw);
            else
                strValue = EvalParameter(strArgCtx, 0);
            if (IsErrorValue(strValue))
                return strValue;

            json jFrame = JsonCopyObject(strArgCtx.jStack);
            JsonObjectSetInplace(jFrame, DAZSCRIPT_THIS_ALIAS, MakeStackAliasEntryFromValue(strValue));
            return EvalParameterUsingStack(strArgCtx, 1, jFrame);
        }
    }
    return GetInvalidValue();
}

struct Value HandleMetaIntrospection(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "exists":
        {
            struct Value strError = CheckArity(strArgCtx, 1, 1);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromInt(SymbolExists(strArgCtx.jStack, GetRawParameterText(strArgCtx, 0)));
        }

        case "type":
        {
            struct Value strError = CheckArity(strArgCtx, 1, 1);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromString(GetSymbolType(strArgCtx.jStack, GetRawParameterText(strArgCtx, 0)));
        }

        case "debug":
        {
            struct Value strError = CheckArity(strArgCtx, 1, 1);
            if (IsErrorValue(strError))
                return strError;

            string sExpr = GetRawParameterText(strArgCtx, 0);
            struct Value strValue = EvalParameter(strArgCtx, 0);
            if (IsErrorValue(strValue))
                return strValue;

            string sValue = FormatValueForDisplay(strValue);
            string sSymbolType = GetSymbolType(strArgCtx.jStack, sExpr);
            string sValueType = InferDebugValueType(sValue);

            string sDebug =
                "expr=\"" + sExpr + "\"" +
                "; symbol_type=" + sSymbolType +
                "; value_type=" + sValueType +
                "; truthy=" + (IsValueTruthy(strValue) ? "TRUE" : "FALSE") +
                "; length=" + IntToString(GetStringLength(sValue)) +
                "; value=\"" + Truncate(sValue, 128) + "\"";

            return GetValueFromString(sDebug);
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaOutput(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "tellpc":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strArgCtx, DAZSCRIPT_ARG_OBJECT, DAZSCRIPT_ARG_ANY);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            object oPC = GetValueAsObject(strArgs.strArg0);
            if (!GetIsObjectValid(oPC))
                return GetErrorValue("INVALID_OBJECT:ARG1");

            SendMessageToPC(oPC, GetValueText(strArgs.strArg1));
            return GetValueFromString();
        }

        case "print":
        {
            struct Value strArg = EvalSingleArg(strArgCtx);
            if (IsErrorValue(strArg))
                return strArg;
            PrintString(GetValueText(strArg));
            return GetValueFromString();
        }

        case "trace":
        {
            PushTrace();

            struct Value strArg = EvalSingleArg(strArgCtx);

            if (IsErrorValue(strArg))
            {
                Trace("trace.value", TraceValue(strArg));
                PopTrace();
                return strArg;
            }

            Trace("trace.value", TraceValue(strArg));

            PopTrace();

            return strArg;
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaMath(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "add": case "sub": case "mul":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strArgCtx, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            if (IsValueIntParameter(strArgs.strArg0) && IsValueIntParameter(strArgs.strArg1))
            {
                int nValue1 = GetValueAsInt(strArgs.strArg0);
                int nValue2 = GetValueAsInt(strArgs.strArg1);

                if (strArgCtx.nNameHash == h"add")
                    return GetValueFromInt(nValue1 + nValue2);
                else if (strArgCtx.nNameHash == h"sub")
                    return GetValueFromInt(nValue1 - nValue2);
                else
                    return GetValueFromInt(nValue1 * nValue2);
            }
            else
            {
                float fValue1 = GetValueAsFloat(strArgs.strArg0);
                float fValue2 = GetValueAsFloat(strArgs.strArg1);

                if (strArgCtx.nNameHash == h"add")
                    return GetValueFromFloat(fValue1 + fValue2);
                else if (strArgCtx.nNameHash == h"sub")
                    return GetValueFromFloat(fValue1 - fValue2);
                else
                    return GetValueFromFloat(fValue1 * fValue2);
            }
        }

        case "div": case "idiv":
        {
            if (strArgCtx.nNameHash == h"div")
            {
                struct ArgumentPair strArgs = EvalTwoArgs(strArgCtx, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
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
                struct ArgumentPair strArgs = EvalTwoArgs(strArgCtx, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
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

        case "min": case "max":
        {
            struct Value strError = CheckArity(strArgCtx, 1, -1);
            if (IsErrorValue(strError))
                return strError;

            int nIndex, bAllInt = TRUE, nIntResult = 0;
            float fResult = 0.0;

            for (nIndex = 0; nIndex < strArgCtx.nParameterCount; nIndex++)
            {
                struct Value strArg = EvalParameter(strArgCtx, nIndex);
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
                            if (strArgCtx.nNameHash == h"min" && nValue < nIntResult)
                                nIntResult = nValue;
                            else if (strArgCtx.nNameHash == h"max" && nValue > nIntResult)
                                nIntResult = nValue;
                        }
                    }
                    else
                    {
                        bAllInt = FALSE;
                    }

                    if (strArgCtx.nNameHash == h"min" && fValue < fResult)
                        fResult = fValue;
                    else if (strArgCtx.nNameHash == h"max" && fValue > fResult)
                        fResult = fValue;
                }
            }

            if (bAllInt)
                return GetValueFromInt(nIntResult);
            else
                return GetValueFromFloat(fResult);
        }

        case "clamp":
        {
            struct ThreeArguments strArgs = EvalThreeArgs(strArgCtx, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC, DAZSCRIPT_ARG_NUMERIC);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;
            if (IsValueIntParameter(strArgs.strArg0) && IsValueIntParameter(strArgs.strArg1) && IsValueIntParameter(strArgs.strArg2))
                return GetValueFromInt(Clamp(GetValueAsInt(strArgs.strArg0), GetValueAsInt(strArgs.strArg1), GetValueAsInt(strArgs.strArg2)));
            return GetValueFromFloat(Clampf(GetValueAsFloat(strArgs.strArg0), GetValueAsFloat(strArgs.strArg1), GetValueAsFloat(strArgs.strArg2)));
        }

        case "mod":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strArgCtx, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            int nDivisor = GetValueAsInt(strArgs.strArg1);
            if (nDivisor != 0)
                return GetValueFromInt(GetValueAsInt(strArgs.strArg0) % nDivisor);
            else
                return GetErrorValue("DIVISION_BY_ZERO");
        }

        case "random":
        {
            struct ArgumentPair strArgs = EvalArgPair(strArgCtx, 1, 2, DAZSCRIPT_ARG_INT, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            int nMax = GetValueAsInt(strArgs.strArg0), nMin = 0;
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
    }

    return GetInvalidValue();
}

struct Value HandleMetaObject(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "firstpc": case "nextpc":
        {
            struct Value strError = CheckZeroArgs(strArgCtx);
            if (IsErrorValue(strError))
                return strError;
            if (strArgCtx.nNameHash == h"firstpc")
                return GetValueFromObject(GetFirstPC());
            else
                return GetValueFromObject(GetNextPC());
        }

        case "module":
        {
            struct Value strError = CheckZeroArgs(strArgCtx);
            if (IsErrorValue(strError))
                return strError;
            return GetValueFromObject(GetModule());
        }

        case "objectbytag":
        {
            struct ArgumentPair strArgs = EvalArgPair(strArgCtx, 1, 2, DAZSCRIPT_ARG_STRING, DAZSCRIPT_ARG_INT);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            string sTag = GetValueText(strArgs.strArg0);
            int nNth = 0;
            if (strArgs.nCount >= 2)
                nNth = GetValueAsInt(strArgs.strArg1);

            if (sTag == "")
                return GetErrorValue("EMPTY_TAG");
            return GetValueFromObject(GetObjectByTag(sTag, nNth));
        }
    }

    return GetInvalidValue();
}

struct Value HandleMetaSqlQuery(struct ArgContext strArgCtx)
{
    switch (strArgCtx.nNameHash)
    {
        case "sqlobject":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strArgCtx, DAZSCRIPT_ARG_OBJECT, DAZSCRIPT_ARG_STRING);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            object oObject = GetValueAsObject(strArgs.strArg0);
            if (!GetIsObjectValid(oObject))
                return GetErrorValue("INVALID_OBJECT:ARG1");

            string sQuery = GetTrimmedValueText(strArgs.strArg1);
            if (sQuery == "")
                return GetErrorValue("EMPTY_SQL_QUERY");

            sqlquery sqlQuery = SqlPrepareQueryObject(oObject, sQuery);
            struct Value strError = CheckSqlQueryError(sqlQuery);
            if (IsErrorValue(strError))
                return strError;

            return GetValueFromSqlQuery(sqlQuery);
        }

        case "sqlcampaign":
        {
            struct ArgumentPair strArgs = EvalTwoArgs(strArgCtx, DAZSCRIPT_ARG_STRING, DAZSCRIPT_ARG_STRING);
            if (IsErrorValue(strArgs.strError))
                return strArgs.strError;

            string sDatabase = GetTrimmedValueText(strArgs.strArg0);
            if (sDatabase == "")
                return GetErrorValue("EMPTY_DATABASE_NAME");

            string sQuery = GetTrimmedValueText(strArgs.strArg1);
            if (sQuery == "")
                return GetErrorValue("EMPTY_SQL_QUERY");

            sqlquery sqlQuery = SqlPrepareQueryCampaign(sDatabase, sQuery);
            struct Value strError = CheckSqlQueryError(sqlQuery);
            if (IsErrorValue(strError))
                return strError;

            return GetValueFromSqlQuery(sqlQuery);
        }

        case "sqlmodule":
        {
            struct Value strArg = EvalSingleArg(strArgCtx, DAZSCRIPT_ARG_STRING);
            if (IsErrorValue(strArg))
                return strArg;

            string sQuery = GetTrimmedValueText(strArg);
            if (sQuery == "")
                return GetErrorValue("EMPTY_SQL_QUERY");

            sqlquery sqlQuery = SqlPrepareQueryObject(GetModule(), sQuery);
            struct Value strError = CheckSqlQueryError(sqlQuery);
            if (IsErrorValue(strError))
                return strError;

            return GetValueFromSqlQuery(sqlQuery);
        }
    }

    return GetInvalidValue();
}

struct Value CheckSqlQueryError(sqlquery sqlQuery)
{
    string sError = SqlGetError(sqlQuery);
    if (sError != "")
        return GetErrorValue("SQLERROR:" + sError);
    return GetInvalidValue();
}

struct Value CheckSqlStateIs(sqlquery sqlQuery, int nState)
{
    int nCurrentState = SqlGetState(sqlQuery);
    if (nCurrentState != nState)
        return GetErrorValue("INVALID_SQLQUERY_STATE:EXPECTED_" + SqlStateToString(nState) + "_GOT_" + SqlStateToString(nCurrentState));
    return GetInvalidValue();
}

struct Value CheckSqlStateIsNot(sqlquery sqlQuery, int nState)
{
    int nCurrentState = SqlGetState(sqlQuery);
    if (nCurrentState == nState)
        return GetErrorValue("INVALID_SQLQUERY_STATE:QUERY_MUST_NOT_BE_" + SqlStateToString(nState));
    return GetInvalidValue();
}

int IsValidSqlAuxType(int nAuxType)
{
    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:
        case NWNX_VM_AUXTYPE_FLOAT:
        case NWNX_VM_AUXTYPE_STRING:
        case NWNX_VM_AUXTYPE_OBJECT:
        case NWNX_VM_AUXTYPE_JSON:
            return TRUE;
    }
    return FALSE;
}

int GetSqlAuxTypeFromShortType(string sChar)
{
    if (sChar == "i") return NWNX_VM_AUXTYPE_INT;
    if (sChar == "f") return NWNX_VM_AUXTYPE_FLOAT;
    if (sChar == "s") return NWNX_VM_AUXTYPE_STRING;
    if (sChar == "j") return NWNX_VM_AUXTYPE_JSON;
    if (sChar == "o") return NWNX_VM_AUXTYPE_OBJECT;
    return NWNX_VM_AUXTYPE_INVALID;
}

struct Value ValidateSqlRowSpec(string sSpec, int nColumnCount, string sErrorPrefix)
{
    if (sSpec == "")
        return GetInvalidValue();

    if (GetStringLength(sSpec) != nColumnCount)
        return GetErrorValue("SQL_ROW_SPEC_COLUMN_COUNT_MISMATCH");

    int nIndex;
    for (nIndex = 0; nIndex < nColumnCount; nIndex++)
    {
        string sCharacter = GetSubString(sSpec, nIndex, 1);
        int nAuxType = GetSqlAuxTypeFromShortType(sCharacter);
        if (!IsValidSqlAuxType(nAuxType))
            return GetErrorValue(sErrorPrefix + sCharacter);
    }

    return GetInvalidValue();
}

struct Value BuildSqlRowSchemaInplace(json jColumnNames, json jColumnAuxTypes, sqlquery sqlQuery, string sSpec, int nColumnCount)
{
    int nIndex, bHasSpec = (sSpec != "");
    for (nIndex = 0; nIndex < nColumnCount; nIndex++)
    {
        string sName = SqlGetColumnName(sqlQuery, nIndex);
        if (sName == "")
            sName = "col" + IntToString(nIndex);

        int nAuxType = NWNX_VM_AUXTYPE_STRING;
        if (bHasSpec)
            nAuxType = GetSqlAuxTypeFromShortType(GetSubString(sSpec, nIndex, 1));

        if (!IsValidSqlAuxType(nAuxType))
            return GetErrorValue("INVALID_ROW_AUXTYPE:" + IntToString(nAuxType));

        JsonArrayInsertStringInplace(jColumnNames, sName);
        JsonArrayInsertIntInplace(jColumnAuxTypes, nAuxType);
    }

    return CheckSqlQueryError(sqlQuery);
}

struct Value GetSqlCurrentRowAsJson(sqlquery sqlQuery, json jColumnNames, json jColumnAuxTypes)
{
    json jRow = JsonObject();
    int nIndex, nColumnCount = JsonGetLength(jColumnNames);
    for (nIndex = 0; nIndex < nColumnCount; nIndex++)
    {
        string sName = JsonArrayGetString(jColumnNames, nIndex);
        int nAuxType = JsonArrayGetInt(jColumnAuxTypes, nIndex);

        struct Value strValue = GetValueFromSqlColumn(sqlQuery, nIndex, nAuxType);
        if (IsErrorValue(strValue))
            return strValue;

        strValue = ValueToJsonValue(strValue);
        if (IsErrorValue(strValue))
            return strValue;

        JsonObjectSetInplace(jRow, sName, strValue.jValue);
    }

    struct Value strError = CheckSqlQueryError(sqlQuery);
    if (IsErrorValue(strError))
        return strError;

    return GetValueFromJson(jRow);
}

struct Value GetValueFromSqlColumn(sqlquery sqlQuery, int nIndex, int nAuxType)
{
    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:    return GetValueFromInt(SqlGetInt(sqlQuery, nIndex));
        case NWNX_VM_AUXTYPE_FLOAT:  return GetValueFromFloat(SqlGetFloat(sqlQuery, nIndex));
        case NWNX_VM_AUXTYPE_STRING: return GetValueFromString(SqlGetString(sqlQuery, nIndex));
        case NWNX_VM_AUXTYPE_OBJECT: return GetValueFromObject(SqlGetObjectRef(sqlQuery, nIndex));
        case NWNX_VM_AUXTYPE_JSON:   return GetValueFromJson(SqlGetJson(sqlQuery, nIndex));
    }
    return GetErrorValue("INVALID_SQL_COLUMN_AUXTYPE:" + IntToString(nAuxType));
}

struct Value ValidateLoopAliases(string sMetaName, int bHasIndexAlias, string sIndexAlias, string sValueAlias)
{
    sMetaName = GetStringUpperCase(sMetaName);
    if (bHasIndexAlias && !IsSymbol(sIndexAlias, DAZSCRIPT_ALIAS_SYMBOL))
        return GetErrorValue(sMetaName + "_INDEX_ALIAS_IS_NON_ALIAS:" + sIndexAlias);
    if (!IsSymbol(sValueAlias, DAZSCRIPT_ALIAS_SYMBOL))
        return GetErrorValue(sMetaName + "_VALUE_ALIAS_IS_NON_ALIAS:" + sValueAlias);
    if (bHasIndexAlias && sIndexAlias == sValueAlias)
        return GetErrorValue(sMetaName + "_DUPLICATE_ALIAS:" + sIndexAlias);
    return GetInvalidValue();
}

struct Value BindArrayLoopAliasesInplace(json jFrame, json jCollection, int nIndex, int bHasIndexAlias, string sIndexAlias, string sValueAlias)
{
    if (bHasIndexAlias)
        JsonObjectSetInplace(jFrame, sIndexAlias, MakeStackAliasEntryFromValue(GetValueFromInt(nIndex)));
    struct Value strItem = ConvertJsonToValue(JsonArrayGet(jCollection, nIndex));
    if (IsErrorValue(strItem))
        return strItem;
    JsonObjectSetInplace(jFrame, sValueAlias, MakeStackAliasEntryFromValue(strItem));
    return GetInvalidValue();
}

int IsStackVar(string sVarName)
{
    if (sVarName == "")
        return FALSE;
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
    if (!IsStackEntryAuxType(nAuxType))
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
    if (!IsAliasValueAuxType(nAuxType))
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
    sName = Trim(sName);
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

    if (!IsAliasValueAuxType(strValue.nAuxType))
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
        default:                        JsonObjectSetStringInplace(jEntry, DAZSCRIPT_ALIAS_VALUE, FormatValueForDisplay(strValue)); break;
    }
    return jEntry;
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

string InferDebugValueType(string sValue)
{
    string sLower = GetStringLowerCase(Trim(sValue));

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
                    string sValue = FormatValueForDisplay(GetStackValue(jStack, sKey));
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
