/*
    Script: ef_c_mediator
    Author: Daz
*/

#include "ef_i_dataobject"
#include "ef_i_sqlite"
#include "ef_i_util"
#include "ef_c_log"

const string MEDIATOR_SCRIPT_NAME                       = "ef_c_mediator";
const int MEDIATOR_PARSE_SYSTEM_FUNCTION_DEFINITIONS    = TRUE;
const int MEDIATOR_PRECACHE_SYSTEM_FUNCTIONS            = FALSE;

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

int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF);
string Function(string sSystem, string sFunction);
string Lambda(string sBody, string sParameters = "", string sReturnType = "", string sInclude = "");
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
        GetStringLeft(sLine, 5) == "object" ||
        GetStringLeft(sLine, 3) == "int" ||
        GetStringLeft(sLine, 5) == "string" ||
        GetStringLeft(sLine, 4) == "json" ||
        GetStringLeft(sLine, 5) == "float" ||
        GetStringLeft(sLine, 5) == "vector" ||
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
                sFunctionBody += nssString("sCallStackDepth", nssFunction("IntToString", nssFunction("GetCallStackDepth", "", FALSE)));

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

int GetCallStackDepth(object oFDO = OBJECT_INVALID)
{
    if (oFDO == OBJECT_INVALID) oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    return GetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH);
}

int IncrementCallStackDepth(string sFunction, string sReturnType, object oFDO = OBJECT_INVALID)
{
    if (oFDO == OBJECT_INVALID) oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nCallStackDepth = GetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH);
    SetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH, ++nCallStackDepth);
    SetLocalString(oFDO, MEDIATOR_CALLSTACK_FUNCTION + IntToString(nCallStackDepth), sFunction);
    SetLocalString(oFDO, MEDIATOR_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth), sReturnType);
    return nCallStackDepth;
}

int DecrementCallStackDepth(object oFDO = OBJECT_INVALID)
{
    if (oFDO == OBJECT_INVALID) oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nCallStackDepth = GetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH);
    SetLocalInt(oFDO, MEDIATOR_CALLSTACK_DEPTH, --nCallStackDepth);
    return nCallStackDepth;
}

string GetCallStackReturnType(int nCallStackDepth)
{
    return GetLocalString(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_CALLSTACK_RETURN_TYPE + IntToString(nCallStackDepth));
}

string GetCallStackFunction(int nCallStackDepth)
{
    return GetLocalString(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_CALLSTACK_FUNCTION + IntToString(nCallStackDepth));
}

void ClearArgumentCount(object oFDO = OBJECT_INVALID)
{
    if (oFDO == OBJECT_INVALID) oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    DeleteLocalInt(oFDO, MEDIATOR_ARGUMENT_COUNT);
}

int IncrementArgumentCount()
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nCount = GetLocalInt(oFDO, MEDIATOR_ARGUMENT_COUNT);
    SetLocalInt(oFDO, MEDIATOR_ARGUMENT_COUNT, nCount + 1);
    return nCount;
}

int GetNextLambdaId()
{
    return IncrementLocalInt(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_LAMBDA_ID);
}

int GetLambdaIdFromFunction(string sFunction)
{
    int nPrefixLength = GetStringLength(MEDIATOR_LAMBDA_FUNCTION);
    if (GetStringLeft(sFunction, nPrefixLength) == MEDIATOR_LAMBDA_FUNCTION)
        return StringToInt(GetStringRight(sFunction, GetStringLength(sFunction) - nPrefixLength));
    return 0;
}

int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nLambdaId = GetLambdaIdFromFunction(sFunction);
    int nCallStackDepth = 0;

    if (!MEDIATOR_PARSE_SYSTEM_FUNCTION_DEFINITIONS && !nLambdaId)
    {
        LogError("Function Parsing Disabled: could not execute '" + sFunction + "'");
        return nCallStackDepth;
    }

    ClearArgumentCount(oFDO);

    if (sFunction != MEDIATOR_INVALID_FUNCTION || nLambdaId)
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
        nLambdaId = GetNextLambdaId();
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

string ObjectArg(object oValue)
{
    SetLocalObject(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), oValue);
    return "o";
}

string IntArg(int nValue)
{
    SetLocalInt(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), nValue);
    return "i";
}

string FloatArg(float fValue)
{
    SetLocalFloat(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), fValue);
    return "f";
}

string StringArg(string sValue)
{
    SetLocalString(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), sValue);
    return "s";
}

string JsonArg(json jValue)
{
    SetLocalJson(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), jValue);
    return "j";
}

string VectorArg(vector vValue)
{
    SetLocalVector(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), vValue);
    return "v";
}

string LocationArg(location locValue)
{
    SetLocalLocation(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_ARGUMENT_PREFIX + IntToString(IncrementArgumentCount()), locValue);
    return "l";
}

int ValidateReturnType(int nCallStackDepth, string sRequestedType)
{
    if (nCallStackDepth == 0)
    {
        LogError("Tried to get return value for an invalid call stack depth");
        return FALSE;
    }

    string sReturnType = GetCallStackReturnType(nCallStackDepth);
    if (sReturnType != sRequestedType)
    {
        LogError("Tried to get return type '" + sRequestedType + "' for function '" +
                 GetCallStackFunction(nCallStackDepth) + "' with return type: " + sReturnType);
        return FALSE;
    }

    return TRUE;
}

object RetObject(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "o"))
        return GetLocalObject(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return OBJECT_INVALID;
}

int RetInt(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "i"))
        return GetLocalInt(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return 0;
}

float RetFloat(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "f"))
        return GetLocalFloat(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return 0.0f;
}

string RetString(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "s"))
        return GetLocalString(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return "";
}

json RetJson(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "j"))
        return GetLocalJson(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return JsonNull();
}

vector RetVector(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "v"))
        return GetLocalVector(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return Vector(0.0f, 0.0f, 0.0f);
}

location RetLocation(int nCallStackDepth)
{
    if (ValidateReturnType(nCallStackDepth, "l"))
        return GetLocalLocation(GetDataObject(MEDIATOR_SCRIPT_NAME), MEDIATOR_RETURN_VALUE_PREFIX + IntToString(nCallStackDepth));
    else
        return Location(OBJECT_INVALID, Vector(0.0f, 0.0f, 0.0f), 0.0f);
}

void RetVoid(int nCallStackDepth)
{

}
