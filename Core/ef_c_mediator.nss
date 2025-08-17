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
const int MEDIATOR_VALIDATE_CLOSURE_CAPTURE_LIST        = TRUE;

const int MEDIATIOR_OVERRIDE_GLOBAL_CACHE_SETTING       = FALSE;
const int MEDIATOR_PRECACHE_SYSTEM_FUNCTIONS            = FALSE;
const int MEDIATOR_CACHE_CLOSURE_ON_CREATION            = FALSE;

const string MEDIATOR_FUNCTION_EXISTS                   = "MediatorFunctionExists_";
const string MEDIATOR_INVALID_FUNCTION                  = "MediatorInvalidFunction";
const string MEDIATOR_ARGUMENT_COUNT                    = "MediatorArgumentCount";
const string MEDIATOR_ARGUMENT_PREFIX                   = "MediatorArgument_";
const string MEDIATOR_FUNCTION_SCRIPT_CHUNK             = "MediatorFunctionScriptChunk_";
const string MEDIATOR_FUNCTION_PARAMETERS               = "MediatorFunctionParameters_";
const string MEDIATOR_FUNCTION_RETURN_TYPE              = "MediatorFunctionReturnType_";
const string MEDIATOR_CLOSURE_ID                        = "MediatorClosureId_";
const string MEDIATOR_CLOSURE_FUNCTION                  = "Closure_";

int FunctionExists(string sSystem, string sFunction);
int Call(string sFunction, string sArgs = "", object oTarget = OBJECT_SELF);
string Function(string sSystem, string sFunction);
string Closure(string sFunctionBody, string sCaptureList = "", string sParameters = "", string sReturnType = "", string sInclude = "", int nDepthOffset = 0);
string ObjectArg(object oValue);
string IntArg(int nValue);
string FloatArg(float fValue);
string StringArg(string sValue);
string JsonArg(json jValue);
string VectorArg(vector vValue);
string LocationArg(location locValue);
object RetObject(int bSuccess);
int RetInt(int bSuccess);
float RetFloat(int bSuccess);
string RetString(int bSuccess);
json RetJson(int bSuccess);
void RetVoid(int bSuccess);

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
        GetStringLeft(sLine, 5) == "float") &&
        FindSubString(sLine, "=", 0) == -1)
    {
        json jMatch = RegExpMatch("(?!.*\\s?(?:action|effect|event|itemproperty|sqlquery|struct|talent|cassowary|vector|location)\\s?.*)" +
                                  "(void|object|int|float|string|json)\\s(\\w+)\\((.*)\\);", sLine);
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

            string sDataObject = nssObject("oFDO", nssFunction("GetDataObject", nssEscape(MEDIATOR_SCRIPT_NAME)));
            string sFunctionBody;
            if (sReturnType != "")
                sFunctionBody = nssConvertShortType(sReturnType, TRUE) + " main() { " + sDataObject + " return " + nssFunction(sFunctionName, sArguments) + "}";
            else
                sFunctionBody = nssVoidMain(sDataObject + nssFunction(sFunctionName, sArguments));

            string sScriptChunk = nssInclude(MEDIATOR_SCRIPT_NAME) + nssInclude(sSystem) + sFunctionBody;

            if (MEDIATOR_PRECACHE_SYSTEM_FUNCTIONS)
                CacheScriptChunk(sScriptChunk, FALSE, MEDIATIOR_OVERRIDE_GLOBAL_CACHE_SETTING);

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
    int nClosureId = GetClosureIdFromFunction(sFunction);

    if (!MEDIATOR_PARSE_SYSTEM_FUNCTION_DEFINITIONS && !nClosureId)
    {
        LogError("Function Parsing Disabled: could not execute '" + sFunction + "'");
        return FALSE;
    }

    ClearArgumentCount(oFDO);

    if (sFunction != MEDIATOR_INVALID_FUNCTION || nClosureId)
    {
        string sParameters = GetLocalString(oFDO, MEDIATOR_FUNCTION_PARAMETERS + sFunction);
        if (sParameters == sArgs)
        {
            string sScriptChunk = GetLocalString(oFDO, MEDIATOR_FUNCTION_SCRIPT_CHUNK + sFunction);
            string sError = ExecuteScriptChunk(sScriptChunk, oTarget, FALSE);

            if (sError == "")
                return TRUE;

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

    return FALSE;
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

string Closure(string sFunctionBody, string sCaptureList = "", string sParameters = "", string sReturnType = "", string sInclude = "", int nDepthOffset = 0)
{
    object oFDO = GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nDepth = 2 + nDepthOffset;
    struct VMFrame strFrame = GetVMFrame(nDepth);
    string sHash = IntToString(HashString(sReturnType + sFunctionBody + sParameters + sCaptureList + strFrame.sFunction + IntToString(strFrame.nLine)));
    int nClosureId = GetLocalInt(oFDO, MEDIATOR_CLOSURE_ID + sHash);

    if (!nClosureId)
    {
        nClosureId = GetNextClosureId(oFDO);
        string sClosureSymbol = MEDIATOR_CLOSURE_FUNCTION + IntToString(nClosureId);
        string sArguments, sClosureFunctionParameters;
        int nArgument, nNumArguments = GetStringLength(sParameters);

        sClosureFunctionParameters += "(";
        for (nArgument = 0; nArgument < nNumArguments; nArgument++)
        {
            string sParameter = GetSubString(sParameters, nArgument, 1);
            sArguments += (!nArgument ? "" : ", ") +
                nssFunction("GetLocal" + nssConvertShortType(sParameter),
                    "oFDO, " + nssEscape(MEDIATOR_ARGUMENT_PREFIX + IntToString(nArgument)), FALSE);
            sClosureFunctionParameters += (!nArgument ? "" : ", ") +
                nssParameter(nssConvertShortType(sParameter, TRUE), "arg" + IntToString(nArgument + 1));
        }
        sClosureFunctionParameters += ")";

        if (sCaptureList != "")
        {
            if (MEDIATOR_VALIDATE_CLOSURE_CAPTURE_LIST)
            {
                json jValidateCaptureList = RegExpMatch("^[=&]\\w+(\\s*,\\s*[=&]\\w+)*$", sCaptureList);
                if (!JsonGetType(jValidateCaptureList) || !JsonGetLength(jValidateCaptureList))
                {
                    LogError("Invalid capture list syntax: " + sCaptureList);
                    return MEDIATOR_INVALID_FUNCTION;
                }
            }

            json jStack = NWNX_VM_GetCurrentStack(nDepth);
            int nIndex, nNumVariables = JsonGetLength(jStack);
            string sGetStackVars, sSetStackVars;
            for (nIndex = 0; nIndex < nNumVariables; nIndex++)
            {
                json jVar = JsonArrayGet(jStack, nIndex);
                string sName = JsonObjectGetString(jVar, "name");

                if (FindSubString(sCaptureList, sName, 0) == -1 )
                    continue;

                json jMatch = RegExpMatch("([=&]{1})(" + sName + ")", sCaptureList);
                string sCaptureType = JsonArrayGetString(jMatch, 1);
                string sType = JsonObjectGetString(jVar, "type");
                int nStackLocation = JsonObjectGetInt(jVar, "stack_location");

                if (sType == "i")
                {
                    if (sCaptureType == "&")
                    {
                        sGetStackVars += nssInt(sName, nssFunction("NWNX_VM_GetStackIntegerValue", IntToString(nStackLocation)));
                        sSetStackVars += nssFunction("NWNX_VM_SetStackIntegerValue", IntToString(nStackLocation) + ", " + sName);
                    }
                    else if (sCaptureType == "=")
                    {
                        sGetStackVars += nssInt(sName, IntToString(NWNX_VM_GetStackIntegerValue(nStackLocation)));
                    }
                }
                else if (sType == "f")
                {
                    if (sCaptureType == "&")
                    {
                        sGetStackVars += nssFloat(sName, nssFunction("NWNX_VM_GetStackFloatValue", IntToString(nStackLocation)));
                        sSetStackVars += nssFunction("NWNX_VM_SetStackFloatValue", IntToString(nStackLocation) + ", " + sName);
                    }
                    else if (sCaptureType == "=")
                    {
                        sGetStackVars += nssFloat(sName, FloatToString(NWNX_VM_GetStackFloatValue(nStackLocation), 18, 9));
                    }
                }
                else if (sType == "o")
                {
                    if (sCaptureType == "&")
                    {
                        sGetStackVars += nssObject(sName, nssFunction("NWNX_VM_GetStackObjectValue", IntToString(nStackLocation)));
                        sSetStackVars += nssFunction("NWNX_VM_SetStackObjectValue", IntToString(nStackLocation) + ", " + sName);
                    }
                    else if (sCaptureType == "=")
                    {
                        sGetStackVars += nssObject(sName, nssFunction("StringToObject", nssEscape(ObjectToString(NWNX_VM_GetStackObjectValue(nStackLocation)))));
                    }
                }
                else if (sType == "s")
                {
                    if (sCaptureType == "&")
                    {
                        sGetStackVars += nssString(sName, nssFunction("NWNX_VM_GetStackStringValue", IntToString(nStackLocation)));
                        sSetStackVars += nssFunction("NWNX_VM_SetStackStringValue", IntToString(nStackLocation) + ", " + sName);
                    }
                    else if (sCaptureType == "=")
                    {
                        sGetStackVars += nssString(sName, nssEscape(NWNX_VM_GetStackStringValue(nStackLocation)));
                    }
                }
                else if (sType == "e2")
                {
                    if (sCaptureType == "&")
                    {
                        sGetStackVars += nssLocation(sName, nssFunction("NWNX_VM_GetStackLocationValue", IntToString(nStackLocation)));
                        sSetStackVars += nssFunction("NWNX_VM_SetStackLocationValue", IntToString(nStackLocation) + ", " + sName);
                    }
                    else if (sCaptureType == "=")
                    {
                        string sLocation = RegExpReplace("\"", JsonDump(LocationToJson(NWNX_VM_GetStackLocationValue(nStackLocation))), "\\\"");
                        sGetStackVars += nssLocation(sName, nssFunction("JsonToLocation", nssFunction("JsonParse", nssEscape(sLocation), FALSE)));
                    }
                }
                else if (sType == "e7")
                {
                    if (sCaptureType == "&")
                    {
                        sGetStackVars += nssJson(sName, nssFunction("NWNX_VM_GetStackJsonValue", IntToString(nStackLocation)));
                        sSetStackVars += nssFunction("NWNX_VM_SetStackJsonValue", IntToString(nStackLocation) + ", " + sName);
                    }
                    else if (sCaptureType == "=")
                    {
                        string sJson = RegExpReplace("\"", JsonDump(NWNX_VM_GetStackJsonValue(nStackLocation)), "\\\"");
                        sGetStackVars += nssJson(sName, nssFunction("JsonParse", nssEscape(sJson)));
                    }
                }
            }
            sFunctionBody = trim(sFunctionBody);
            if (FindSubString(sFunctionBody, "return") == -1)
            {
                sFunctionBody = GetSubString(sFunctionBody, 1, GetStringLength(sFunctionBody) - 2);
                sFunctionBody = "{ " + sGetStackVars + " " + sFunctionBody + " " + sSetStackVars + " }";
            }
            else
            {
                sFunctionBody = GetSubString(sFunctionBody, 1, GetStringLength(sFunctionBody) - 2);
                sFunctionBody = "{ " + sGetStackVars + " " + sFunctionBody +  " }";
                sFunctionBody = RegExpReplace("\\breturn\\b[^;]+;", sFunctionBody, "{ " + sSetStackVars + " $& }");
            }
        }

        string sClosureFunction = (sReturnType == "" ? "void " : nssConvertShortType(sReturnType, TRUE) + " ") + "ClosureFunction" + sClosureFunctionParameters + sFunctionBody;
        string sDataObject = nssObject("oFDO", nssFunction("GetDataObject", nssEscape(MEDIATOR_SCRIPT_NAME)));

        string sClosureMainFunction;
        if (sReturnType != "")
            sClosureMainFunction += nssConvertShortType(sReturnType, TRUE) + " main() { " + sDataObject + " return " + nssFunction("ClosureFunction", sArguments) + "}";
        else
            sClosureMainFunction += nssVoidMain(sDataObject + nssFunction("ClosureFunction", sArguments));

        string sScriptChunk = nssInclude(MEDIATOR_SCRIPT_NAME) + nssInclude(sInclude) + sClosureFunction + sClosureMainFunction;

        if (MEDIATOR_CACHE_CLOSURE_ON_CREATION)
            CacheScriptChunk(sScriptChunk, FALSE, MEDIATIOR_OVERRIDE_GLOBAL_CACHE_SETTING);

        SetLocalInt(oFDO, MEDIATOR_CLOSURE_ID + sHash, nClosureId);
        SetLocalString(oFDO, MEDIATOR_FUNCTION_RETURN_TYPE + sClosureSymbol, sReturnType);
        SetLocalString(oFDO, MEDIATOR_FUNCTION_PARAMETERS + sClosureSymbol, sParameters);
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

int ValidateReturnType(int nRequestedReturnType)
{
    int nReturnType = NWNX_VM_GetScriptReturnValueType();
    if (nReturnType == nRequestedReturnType)
        return TRUE;
    else
    {
        LogError("Return Type Mismatch: GOT: " + IntToString(nReturnType) + ", EXPECTED: " + IntToString(nRequestedReturnType));
        return FALSE;
    }
}

object RetObject(int bSuccess)
{
    if (bSuccess && ValidateReturnType(NWNX_VM_SCRIPT_RETURN_VALUE_TYPE_OBJECT))
        return NWNX_VM_GetScriptReturnValueObject();
    else
        return OBJECT_INVALID;
}

int RetInt(int bSuccess)
{
    if (bSuccess && ValidateReturnType(NWNX_VM_SCRIPT_RETURN_VALUE_TYPE_INT))
        return NWNX_VM_GetScriptReturnValueInt();
    else
        return 0;
}

float RetFloat(int bSuccess)
{
    if (bSuccess && ValidateReturnType(NWNX_VM_SCRIPT_RETURN_VALUE_TYPE_FLOAT))
        return NWNX_VM_GetScriptReturnValueFloat();
    else
        return 0.0f;
}

string RetString(int bSuccess)
{
    if (bSuccess && ValidateReturnType(NWNX_VM_SCRIPT_RETURN_VALUE_TYPE_STRING))
        return NWNX_VM_GetScriptReturnValueString();
    else
        return "";
}

json RetJson(int bSuccess)
{
    if (bSuccess && ValidateReturnType(NWNX_VM_SCRIPT_RETURN_VALUE_TYPE_JSON))
        return NWNX_VM_GetScriptReturnValueJson();
    else
        return JsonNull();
}

void RetVoid(int bSuccess)
{

}
