/*
    Script: ef_c_mediator
    Author: Daz
*/

#include "ef_i_dataobject"
#include "ef_i_sqlite"
#include "ef_i_util"
#include "ef_i_vm"
#include "ef_c_log"

const string MEDIATOR_SCRIPT_NAME                       = "ef_c_mediator";
const int MEDIATOR_PARSE_SYSTEM_FUNCTION_DEFINITIONS    = TRUE;
const int MEDIATOR_PRECACHE_SYSTEM_FUNCTIONS            = FALSE;

const string MEDIATOR_FUNCTION_EXISTS                   = "MediatorFunctionExists_";
const string MEDIATOR_INVALID_FUNCTION                  = "MediatorInvalidFunction";
const string MEDIATOR_CALLSTACK_DEPTH                   = "MediatorCallStackDepth";
const string MEDIATOR_CALLSTACK_FUNCTION                = "MediatorCallStackFunction_";
const string MEDIATOR_CALLSTACK_RETURN_TYPE             = "MediatorCallStackReturnType_";
const string MEDIATOR_ARGUMENT_COUNT                    = "MediatorArgumentCount";
const string MEDIATOR_ARGUMENT_PREFIX                   = "MediatorArgument_";
const string MEDIATOR_RETURN_VALUE_PREFIX               = "MediatorReturnValue_";
const string MEDIATOR_FUNCTION_SCRIPT_CHUNK             = "MediatorFunctionScriptChunk_";
const string MEDIATOR_FUNCTION_PARAMETERS               = "MediatorFunctionParameters_";
const string MEDIATOR_FUNCTION_RETURN_TYPE              = "MediatorFunctionReturnType_";
const string MEDIATOR_LAMBDA_ID                         = "MediatorLambdaId_";
const string MEDIATOR_LAMBDA_FUNCTION                   = "Lambda::";
const string MEDIATOR_CLOSURE_ID                        = "MediatorClosureId_";
const string MEDIATOR_CLOSURE_FUNCTION                  = "Closure::";


int FunctionExists(string sSystem, string sFunction);
int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF);
string Function(string sSystem, string sFunction);
string Lambda(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "");
string Closure(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "");
string MutableClosure(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "");
string ObjectArg(object oValue);
string IntArg(int nValue);
string FloatArg(float fValue);
string StringArg(string sValue);
string JsonArg(json jValue);
string VectorArg(vector vValue);
string LocationArg(location locValue);
object RetObject(int nCallStackDepth);
int RetInt(int nCallStackDepth);
float RetFloat(int nCallStackDepth);
string RetString(int nCallStackDepth);
json RetJson(int nCallStackDepth);
vector RetVector(int nCallStackDepth);
location RetLocation(int nCallStackDepth);
void RetVoid(int nCallStackDepth);

void Mediator_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + MEDIATOR_SCRIPT_NAME + " (" +
                    "system TEXT NOT NULL, " +
                    "function TEXT NOT NULL, " +
                    "returntype TEXT NOT NULL, " +
                    "parameters TEXT NOT NULL, " +
                    "scriptchunk TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

int Mediator_ParseFunctionDefinition(string sLine, string sSystem)
{
    if (MEDIATOR_PARSE_SYSTEM_FUNCTION_DEFINITIONS &&
        GetStringRight(sLine, 2) == ");" &&
        (GetStringLeft(sLine, 4) == "void" ||
        GetStringLeft(sLine, 6) == "object" ||
        GetStringLeft(sLine, 3) == "int" ||
        GetStringLeft(sLine, 6) == "string" ||
        GetStringLeft(sLine, 4) == "json" ||
        GetStringLeft(sLine, 5) == "float" ||
        GetStringLeft(sLine, 6) == "vector" ||
        GetStringLeft(sLine, 8) == "location") &&
        FindSubString(sLine, "=", 0) == -1)
    {

        json jMatch = RegExpMatch("(?!.*\\s?(?:action|effect|event|itemproperty|sqlquery|struct|talent|cassowary)\\s?.*)" +
                                  "(void|object|int|float|string|json|vector|location)\\s(\\w+)\\((.*)\\);", sLine);
        if (JsonGetLength(jMatch))
        {
            string sReturnType = nssConvertType(JsonArrayGetString(jMatch, 1));
            string sFunctionName = JsonArrayGetString(jMatch, 2);
            string sRawParameters = JsonArrayGetString(jMatch, 3);
            string sParameters;

            if (sRawParameters != "")
            {
                json jRawParameters = RegExpIterate("(object|int|float|string|json|vector|location)\\s", sRawParameters);
                int nRawParameter, nNumRawParameters = JsonGetLength(jRawParameters);
                for(nRawParameter = 0; nRawParameter < nNumRawParameters; nRawParameter++)
                {
                    sParameters += nssConvertType(JsonArrayGetString(JsonArrayGet(jRawParameters, nRawParameter), 1));
                }
            }

            string sArguments;
            int nArgument, nNumArguments = GetStringLength(sParameters);
            for (nArgument = 0; nArgument < nNumArguments; nArgument++)
            {
                sArguments += (!nArgument ? "" : ", ") +
                    nssFunction("GetLocal" + nssConvertShortType(GetSubString(sParameters, nArgument, 1)),
                        "oFDO, " + nssEscape(MEDIATOR_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            }

            string sFunctionBody = nssObject("oFDO", nssFunction("GetDataObject", nssEscape(MEDIATOR_SCRIPT_NAME)));
                sFunctionBody += nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "oFDO", FALSE)));

            if (sReturnType != "")
            {
                sFunctionBody += nssFunction("DeleteLocal" + nssConvertShortType(sReturnType),
                                    "oFDO, " + nssEscape(MEDIATOR_RETURN_VALUE_PREFIX) + "+sCallStackDepth");
                sFunctionBody += nssFunction("SetLocal" + nssConvertShortType(sReturnType),
                                    "oFDO, " + nssEscape(MEDIATOR_RETURN_VALUE_PREFIX) + "+sCallStackDepth, " + nssFunction(sFunctionName, sArguments, FALSE));
            }
            else
                sFunctionBody += nssFunction(sFunctionName, sArguments);

            string sScriptChunk = nssInclude(MEDIATOR_SCRIPT_NAME) + nssInclude(sSystem) + nssVoidMain(sFunctionBody);

            if (MEDIATOR_PRECACHE_SYSTEM_FUNCTIONS)
                CacheScriptChunk(sScriptChunk);

            string sQuery = "INSERT INTO " + MEDIATOR_SCRIPT_NAME + "(system, function, returntype, parameters, scriptchunk) " +
                            "VALUES(@system, @function, @returntype, @parameters, @scriptchunk);";
            sqlquery sql = SqlPrepareQueryModule(sQuery);
            SqlBindString(sql, "@system", sSystem);
            SqlBindString(sql, "@function", sFunctionName);
            SqlBindString(sql, "@returntype", sReturnType);
            SqlBindString(sql, "@parameters", sParameters);
            SqlBindString(sql, "@scriptchunk", sScriptChunk);
            SqlStep(sql);

            return TRUE;
        }
    }

    return FALSE;
}

int GetCallStackDepth(object oFDO)
{
    return GetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH);
}

int IncrementCallStackDepth(string sFunction, string sReturnType, object oFDO)
{
    int nCallStackDepth = GetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH) + 1;
    SetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH, nCallStackDepth);
    SetLocalString(oFDO, MEDIATOR_CALLSTACK_FUNCTION + IntToString(nCallStackDepth), sFunction);
    SetLocalString(oFDO, MEDIATOR_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth), sReturnType);
    return nCallStackDepth;
}

int DecrementCallStackDepth(object oFDO)
{
    int nCallStackDepth = GetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH) - 1;
    SetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH, nCallStackDepth);
    return nCallStackDepth;
}

string GetCallStackReturnType(object oFDO, int nCallStackDepth)
{
    return GetLocalString(oFDO, MEDIATOR_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth));
}

string GetCallStackFunction(object oFDO, int nCallStackDepth)
{
    return GetLocalString(oFDO, MEDIATOR_CALLSTACK_FUNCTION + IntToString(nCallStackDepth));
}

void ClearArgumentCount(object oFDO)
{
    DeleteLocalInt(oFDO, MEDIATOR_ARGUMENT_COUNT);
}

int IncrementArgumentCount(object oFDO)
{
    int nCount = GetLocalInt(oFDO, MEDIATOR_ARGUMENT_COUNT);
    SetLocalInt(oFDO, MEDIATOR_ARGUMENT_COUNT, nCount + 1);
    return nCount;
}

int GetNextLambdaId(object oFDO)
{
    return IncrementLocalInt(oFDO, MEDIATOR_LAMBDA_ID);
}

int GetLambdaIdFromFunction(string sFunction)
{
    int nPrefixLength = GetStringLength(MEDIATOR_LAMBDA_FUNCTION);
    if (GetStringLeft(sFunction, nPrefixLength) == MEDIATOR_LAMBDA_FUNCTION)
        return StringToInt(GetStringRight(sFunction, GetStringLength(sFunction) - nPrefixLength));
    return 0;
}

int GetNextClosureId(object oFDO)
{
    return IncrementLocalInt(oFDO, MEDIATOR_CLOSURE_ID);
}

int GetClosureIdFromFunction(string sFunction)
{
    int nPrefixLength = GetStringLength(MEDIATOR_CLOSURE_FUNCTION);
    if (GetStringLeft(sFunction, nPrefixLength) == MEDIATOR_CLOSURE_FUNCTION)
        return StringToInt(GetStringRight(sFunction, GetStringLength(sFunction) - nPrefixLength));
    return 0;
}

int FunctionExists(string sSystem, string sFunction)
{
    object oDataObject = GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nExists = GetLocalInt(oDataObject, MEDIATOR_FUNCTION_EXISTS + sSystem + sFunction);
    if (!nExists)
    {
        sqlquery sql = SqlPrepareQueryModule("SELECT function FROM " + MEDIATOR_SCRIPT_NAME + " WHERE " +
            "system = @system AND function = @function;");
        SqlBindString(sql, "@system", sSystem);
        SqlBindString(sql, "@function", sFunction);
        nExists = SqlStep(sql) + 1;
        SetLocalInt(oDataObject, MEDIATOR_FUNCTION_EXISTS + sSystem + sFunction, nExists);
    }
    return nExists == 2 ? TRUE : FALSE;
}

int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nLambdaId = GetLambdaIdFromFunction(sFunction);
    int nClosureId = GetClosureIdFromFunction(sFunction);
    int nCallStackDepth = 0;

    if (!MEDIATOR_PARSE_SYSTEM_FUNCTION_DEFINITIONS && !nLambdaId && !nClosureId)
    {
        LogError("Function Parsing Disabled: could not execute '" + sFunction + "'");
        return nCallStackDepth;
    }

    ClearArgumentCount(oFDO);

    if (sFunction != MEDIATOR_INVALID_FUNCTION || nLambdaId || nClosureId)
    {
        string sParameters = GetLocalString(oFDO, MEDIATOR_FUNCTION_PARAMETERS + sFunction);
        string sReturnType = GetLocalString(oFDO, MEDIATOR_FUNCTION_RETURN_TYPE + sFunction);

        if (sParameters == sArgs)
        {
            nCallStackDepth = IncrementCallStackDepth(sFunction, sReturnType, oFDO);
            string sScriptChunk = GetLocalString(oFDO, MEDIATOR_FUNCTION_SCRIPT_CHUNK + sFunction);
            string sError = ExecuteScriptChunk(sScriptChunk, oTarget, FALSE);
            DecrementCallStackDepth(oFDO);

            if (sError != "")
                LogError("Failed to execute '" + sFunction + "' with error: " + sError);
        }
        else
        {
            LogError("Parameter Mismatch: EXPECTED: '" + sFunction + "(" + sParameters + ")' -> GOT: '"  + sFunction + "(" + sArgs + ")'");
        }
    }
    else
    {
        LogError("Function '" + sFunction + "' does not exist");
    }

    return nCallStackDepth;
}

string Function(string sSystem, string sFunction)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    string sFunctionSymbol = sSystem + "_" + sFunction;
    string sScriptChunk = GetLocalString(oFDO, MEDIATOR_FUNCTION_SCRIPT_CHUNK + sFunctionSymbol);

    if (sScriptChunk == "")
    {
        string sQuery = "SELECT returntype, parameters, scriptchunk FROM " + MEDIATOR_SCRIPT_NAME + " WHERE " +
                        "system = @system AND function = @function;";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindString(sql, "@system", sSystem);
        SqlBindString(sql, "@function", sFunction);

        if (SqlStep(sql))
        {
            SetLocalString(oFDO, MEDIATOR_FUNCTION_RETURN_TYPE + sFunctionSymbol, SqlGetString(sql, 0));
            SetLocalString(oFDO, MEDIATOR_FUNCTION_PARAMETERS + sFunctionSymbol, SqlGetString(sql, 1));
            sScriptChunk = SqlGetString(sql, 2);
        }
        else
            sScriptChunk = MEDIATOR_INVALID_FUNCTION;

        SetLocalString(oFDO, MEDIATOR_FUNCTION_SCRIPT_CHUNK + sFunctionSymbol, sScriptChunk);
    }

    return sFunctionSymbol;
}

string Lambda(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "")
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    string sHash = IntToString(HashString(sReturnType + sBody + sParameters));
    int nLambdaId = GetLocalInt(oFDO, MEDIATOR_LAMBDA_ID + sHash);

    if (!nLambdaId)
    {
        nLambdaId = GetNextLambdaId(oFDO);
        string sLambdaSymbol = MEDIATOR_LAMBDA_FUNCTION + IntToString(nLambdaId);
        string sArguments, sLambdaParameters;
        int nArgument, nNumArguments = GetStringLength(sParameters);

        sLambdaParameters += "(";
        for (nArgument = 0; nArgument < nNumArguments; nArgument++)
        {
            string sParameter = GetSubString(sParameters, nArgument, 1);
            sArguments += (!nArgument ? "" : ", ") +
                nssFunction("GetLocal" + nssConvertShortType(sParameter),
                    "oFDO, " + nssEscape(MEDIATOR_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            sLambdaParameters += (!nArgument ? "" : ", ") +
                nssParameter(nssConvertShortType(sParameter, TRUE), "arg" + IntToString(nArgument + 1));
        }
        sLambdaParameters += ")";

        string sLambdaFunction = (sReturnType == "" ? "void " : nssConvertShortType(sReturnType, TRUE) + " ") + "LambdaFunction" + sLambdaParameters + sBody;
        string sFunctionBody = nssObject("oFDO", nssFunction("GetDataObject", nssEscape(MEDIATOR_SCRIPT_NAME))) +
            nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "oFDO", FALSE)));

        if (sReturnType != "")
        {
            sFunctionBody += nssFunction("DeleteLocal" + nssConvertShortType(sReturnType),
                                "oFDO, " + nssEscape(MEDIATOR_RETURN_VALUE_PREFIX) + "+sCallStackDepth");
            sFunctionBody += nssFunction("SetLocal" + nssConvertShortType(sReturnType),
                                "oFDO, " + nssEscape(MEDIATOR_RETURN_VALUE_PREFIX) + "+sCallStackDepth, " + nssFunction("LambdaFunction", sArguments, FALSE));
        }
        else
            sFunctionBody += nssFunction("LambdaFunction", sArguments);

        SetLocalInt(oFDO, MEDIATOR_LAMBDA_ID + sHash, nLambdaId);

        SetLocalString(oFDO, MEDIATOR_FUNCTION_RETURN_TYPE + sLambdaSymbol, sReturnType);
        SetLocalString(oFDO, MEDIATOR_FUNCTION_PARAMETERS + sLambdaSymbol, sParameters);

        string sScriptChunk = nssInclude(MEDIATOR_SCRIPT_NAME) + nssInclude(sInclude) + sLambdaFunction + nssVoidMain(sFunctionBody);
        SetLocalString(oFDO, MEDIATOR_FUNCTION_SCRIPT_CHUNK + sLambdaSymbol, sScriptChunk);

        return sLambdaSymbol;
    }

    return MEDIATOR_LAMBDA_FUNCTION + IntToString(nLambdaId);
}

string Closure(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "")
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    struct VMFrame strFrame = GetVMFrame(2);
    string sHash = IntToString(HashString(sReturnType + sBody + sParameters + strFrame.sFunction + IntToString(strFrame.nLine)));
    int nClosureId = GetLocalInt(oFDO, MEDIATOR_CLOSURE_ID + sHash);

    if (!nClosureId)
    {
        nClosureId = GetNextClosureId(oFDO);
        string sClosureSymbol = MEDIATOR_CLOSURE_FUNCTION + IntToString(nClosureId);
        string sArguments, sClosureParameters;
        int nArgument, nNumArguments = GetStringLength(sParameters);

        sClosureParameters += "(";
        for (nArgument = 0; nArgument < nNumArguments; nArgument++)
        {
            string sParameter = GetSubString(sParameters, nArgument, 1);
            sArguments += (!nArgument ? "" : ", ") +
                nssFunction("GetLocal" + nssConvertShortType(sParameter),
                    "oFDO, " + nssEscape(MEDIATOR_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            sClosureParameters += (!nArgument ? "" : ", ") +
                nssParameter(nssConvertShortType(sParameter, TRUE), "arg" + IntToString(nArgument + 1));
        }
        sClosureParameters += ")";

        json jStack = NWNX_VM_GetCurrentStack(2);
        int nIndex, nNumVariables = JsonGetLength(jStack);
        string sGetStackVars;
        for (nIndex = 0; nIndex < nNumVariables; nIndex++)
        {
            json jVar = JsonArrayGet(jStack, nIndex);
            string sName = JsonObjectGetString(jVar, "name");

            if (FindSubString(sBody, sName, 0) == -1)
                continue;

            string sType = JsonObjectGetString(jVar, "type");
            int nStackLocation = JsonObjectGetInt(jVar, "stack_location");

            if (sType == "i")
            {
                sGetStackVars += nssInt(sName, IntToString(NWNX_VM_GetStackIntegerValue(nStackLocation)));
            }
            else if (sType == "f")
            {
                sGetStackVars += nssFloat(sName, FloatToString(NWNX_VM_GetStackFloatValue(nStackLocation), 18, 9));
            }
            else if (sType == "o")
            {
                sGetStackVars += nssObject(sName, nssFunction("StringToObject", nssEscape(ObjectToString(NWNX_VM_GetStackObjectValue(nStackLocation)))));
            }
            else if (sType == "s")
            {
                sGetStackVars += nssString(sName, nssEscape(NWNX_VM_GetStackStringValue(nStackLocation)));
            }
            else if (sType == "e2")
            {
                string sLocation = RegExpReplace("\"", JsonDump(LocationToJson(NWNX_VM_GetStackLocationValue(nStackLocation))), "\\\"");
                sGetStackVars += nssLocation(sName, nssFunction("JsonToLocation", nssFunction("JsonParse", nssEscape(sLocation), FALSE)));
            }
            else if (sType == "e7")
            {
                string sJson = RegExpReplace("\"", JsonDump(NWNX_VM_GetStackJsonValue(nStackLocation)), "\\\"");
                sGetStackVars += nssJson(sName, nssFunction("JsonParse", nssEscape(sJson)));
            }
        }

        sBody = GetSubString(sBody, 1, GetStringLength(sBody));
        sBody = "{ " + sGetStackVars + " " + sBody;

        string sClosureFunction = (sReturnType == "" ? "void " : nssConvertShortType(sReturnType, TRUE) + " ") + "ClosureFunction" + sClosureParameters + sBody;
        string sFunctionBody = nssObject("oFDO", nssFunction("GetDataObject", nssEscape(MEDIATOR_SCRIPT_NAME))) +
            nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "oFDO", FALSE)));

        if (sReturnType != "")
        {
            sFunctionBody += nssFunction("DeleteLocal" + nssConvertShortType(sReturnType),
                                "oFDO, " + nssEscape(MEDIATOR_RETURN_VALUE_PREFIX) + "+sCallStackDepth");
            sFunctionBody += nssFunction("SetLocal" + nssConvertShortType(sReturnType),
                                "oFDO, " + nssEscape(MEDIATOR_RETURN_VALUE_PREFIX) + "+sCallStackDepth, " + nssFunction("ClosureFunction", sArguments, FALSE));
        }
        else
            sFunctionBody += nssFunction("ClosureFunction", sArguments);

        SetLocalInt(oFDO, MEDIATOR_CLOSURE_ID + sHash, nClosureId);

        SetLocalString(oFDO, MEDIATOR_FUNCTION_RETURN_TYPE + sClosureSymbol, sReturnType);
        SetLocalString(oFDO, MEDIATOR_FUNCTION_PARAMETERS + sClosureSymbol, sParameters);

        string sScriptChunk = nssInclude(MEDIATOR_SCRIPT_NAME) + nssInclude(sInclude) + sClosureFunction + nssVoidMain(sFunctionBody);
        SetLocalString(oFDO, MEDIATOR_FUNCTION_SCRIPT_CHUNK + sClosureSymbol, sScriptChunk);

        return sClosureSymbol;
    }

    return MEDIATOR_CLOSURE_FUNCTION + IntToString(nClosureId);
}

string MutableClosure(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "")
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    struct VMFrame strFrame = GetVMFrame(2);
    string sHash = IntToString(HashString(sReturnType + sBody + sParameters + strFrame.sFunction + IntToString(strFrame.nLine)));
    int nClosureId = GetLocalInt(oFDO, MEDIATOR_CLOSURE_ID + sHash);

    if (!nClosureId)
    {
        nClosureId = GetNextClosureId(oFDO);
        string sClosureSymbol = MEDIATOR_CLOSURE_FUNCTION + IntToString(nClosureId);
        string sArguments, sClosureParameters;
        int nArgument, nNumArguments = GetStringLength(sParameters);

        sClosureParameters += "(";
        for (nArgument = 0; nArgument < nNumArguments; nArgument++)
        {
            string sParameter = GetSubString(sParameters, nArgument, 1);
            sArguments += (!nArgument ? "" : ", ") +
                nssFunction("GetLocal" + nssConvertShortType(sParameter),
                    "oFDO, " + nssEscape(MEDIATOR_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            sClosureParameters += (!nArgument ? "" : ", ") +
                nssParameter(nssConvertShortType(sParameter, TRUE), "arg" + IntToString(nArgument + 1));
        }
        sClosureParameters += ")";

        json jStack = NWNX_VM_GetCurrentStack(2);
        int nIndex, nNumVariables = JsonGetLength(jStack);
        string sGetStackVars, sSetStackVars;
        for (nIndex = 0; nIndex < nNumVariables; nIndex++)
        {
            json jVar = JsonArrayGet(jStack, nIndex);
            string sName = JsonObjectGetString(jVar, "name");

            if (FindSubString(sBody, sName, 0) == -1)
                continue;

            string sType = JsonObjectGetString(jVar, "type");
            int nStackLocation = JsonObjectGetInt(jVar, "stack_location");

            if (sType == "i")
            {
                sGetStackVars += nssInt(sName, nssFunction("NWNX_VM_GetStackIntegerValue", IntToString(nStackLocation)));
                sSetStackVars += nssFunction("NWNX_VM_SetStackIntegerValue", IntToString(nStackLocation) + ", " + sName);
            }
            else if (sType == "f")
            {
                sGetStackVars += nssFloat(sName, nssFunction("NWNX_VM_GetStackFloatValue", IntToString(nStackLocation)));
                sSetStackVars += nssFunction("NWNX_VM_SetStackFloatValue", IntToString(nStackLocation) + ", " + sName);
            }
            else if (sType == "o")
            {
                sGetStackVars += nssObject(sName, nssFunction("NWNX_VM_GetStackObjectValue", IntToString(nStackLocation)));
                sSetStackVars += nssFunction("NWNX_VM_SetStackObjectValue", IntToString(nStackLocation) + ", " + sName);
            }
            else if (sType == "s")
            {
                sGetStackVars += nssString(sName, nssFunction("NWNX_VM_GetStackStringValue", IntToString(nStackLocation)));
                sSetStackVars += nssFunction("NWNX_VM_SetStackStringValue", IntToString(nStackLocation) + ", " + sName);
            }
            else if (sType == "e2")
            {
                sGetStackVars += nssLocation(sName, nssFunction("NWNX_VM_GetStackLocationValue", IntToString(nStackLocation)));
                sSetStackVars += nssFunction("NWNX_VM_SetStackLocationValue", IntToString(nStackLocation) + ", " + sName);
            }
            else if (sType == "e7")
            {
                sGetStackVars += nssJson(sName, nssFunction("NWNX_VM_GetStackJsonValue", IntToString(nStackLocation)));
                sSetStackVars += nssFunction("NWNX_VM_SetStackJsonValue", IntToString(nStackLocation) + ", " + sName);
            }
        }

        if (FindSubString(sBody, "return") == -1)
        {
            sBody = GetSubString(sBody, 1, GetStringLength(sBody) - 2);
            sBody = "{ " + sGetStackVars + " " + sBody + " " + sSetStackVars + " }";
        }
        else
        {
            sBody = GetSubString(sBody, 1, GetStringLength(sBody) - 2);
            sBody = "{ " + sGetStackVars + " " + sBody +  " }";
            sBody = RegExpReplace("\\breturn\\b[^;]+;", sBody, "{ " + sSetStackVars + " $& }");
        }

        string sClosureFunction = (sReturnType == "" ? "void " : nssConvertShortType(sReturnType, TRUE) + " ") + "ClosureFunction" + sClosureParameters + sBody;
        string sFunctionBody = nssObject("oFDO", nssFunction("GetDataObject", nssEscape(MEDIATOR_SCRIPT_NAME))) +
            nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "oFDO", FALSE)));

        if (sReturnType != "")
        {
            sFunctionBody += nssFunction("DeleteLocal" + nssConvertShortType(sReturnType),
                                "oFDO, " + nssEscape(MEDIATOR_RETURN_VALUE_PREFIX) + "+sCallStackDepth");
            sFunctionBody += nssFunction("SetLocal" + nssConvertShortType(sReturnType),
                                "oFDO, " + nssEscape(MEDIATOR_RETURN_VALUE_PREFIX) + "+sCallStackDepth, " + nssFunction("ClosureFunction", sArguments, FALSE));
        }
        else
            sFunctionBody += nssFunction("ClosureFunction", sArguments);

        SetLocalInt(oFDO, MEDIATOR_CLOSURE_ID + sHash, nClosureId);

        SetLocalString(oFDO, MEDIATOR_FUNCTION_RETURN_TYPE + sClosureSymbol, sReturnType);
        SetLocalString(oFDO, MEDIATOR_FUNCTION_PARAMETERS + sClosureSymbol, sParameters);

        string sScriptChunk = nssInclude(MEDIATOR_SCRIPT_NAME) + nssInclude(sInclude) + sClosureFunction + nssVoidMain(sFunctionBody);
        SetLocalString(oFDO, MEDIATOR_FUNCTION_SCRIPT_CHUNK + sClosureSymbol, sScriptChunk);

        return sClosureSymbol;
    }

    return MEDIATOR_CLOSURE_FUNCTION + IntToString(nClosureId);
}

string ObjectArg(object oValue)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    SetLocalObject(oFDO, MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount(oFDO)), oValue);
    return "o";
}

string IntArg(int nValue)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    SetLocalInt(oFDO, MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount(oFDO)), nValue);
    return "i";
}

string FloatArg(float fValue)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    SetLocalFloat(oFDO, MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount(oFDO)), fValue);
    return "f";
}

string StringArg(string sValue)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    SetLocalString(oFDO, MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount(oFDO)), sValue);
    return "s";
}

string JsonArg(json jValue)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    SetLocalJson(oFDO, MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount(oFDO)), jValue);
    return "j";
}

string VectorArg(vector vValue)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    SetLocalVector(oFDO, MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount(oFDO)), vValue);
    return "v";
}

string LocationArg(location locValue)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    SetLocalLocation(oFDO, MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount(oFDO)), locValue);
    return "l";
}

int ValidateReturnType(object oFDO, int nCallStackDepth, string sRequestedType)
{
    if (nCallStackDepth == 0)
    {
        LogError("Tried to get return value for an invalid call stack depth");
        return FALSE;
    }

    string sReturnType = GetCallStackReturnType(oFDO, nCallStackDepth);
    if (sReturnType != sRequestedType)
    {
        LogError("Tried to get return type '" + sRequestedType + "' for function '" +
                 GetCallStackFunction(oFDO, nCallStackDepth) + "' with return type: " + sReturnType);
        return FALSE;
    }

    return TRUE;
}

object RetObject(int nCallStackDepth)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    if (ValidateReturnType(oFDO, nCallStackDepth, "o"))
        return GetLocalObject(oFDO, MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return OBJECT_INVALID;
}

int RetInt(int nCallStackDepth)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    if (ValidateReturnType(oFDO, nCallStackDepth, "i"))
        return GetLocalInt(oFDO, MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return 0;
}

float RetFloat(int nCallStackDepth)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    if (ValidateReturnType(oFDO, nCallStackDepth, "f"))
        return GetLocalFloat(oFDO, MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return 0.0f;
}

string RetString(int nCallStackDepth)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    if (ValidateReturnType(oFDO, nCallStackDepth, "s"))
        return GetLocalString(oFDO, MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return "";
}

json RetJson(int nCallStackDepth)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    if (ValidateReturnType(oFDO, nCallStackDepth, "j"))
        return GetLocalJson(oFDO, MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return JsonNull();
}

vector RetVector(int nCallStackDepth)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    if (ValidateReturnType(oFDO, nCallStackDepth, "v"))
        return GetLocalVector(oFDO, MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return Vector(0.0f, 0.0f, 0.0f);
}

location RetLocation(int nCallStackDepth)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    if (ValidateReturnType(oFDO, nCallStackDepth, "l"))
        return GetLocalLocation(oFDO, MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return Location(OBJECT_INVALID, Vector(0.0f, 0.0f, 0.0f), 0.0f);
}

void RetVoid(int nCallStackDepth)
{

}
