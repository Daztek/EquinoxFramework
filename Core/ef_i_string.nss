/*
    Script: ef_i_string
    Author: Daz
*/

#include "ef_i_vm"

string ltrim(string s);
string rtrim(string s);
string trim(string s);
int HexStringToInt(string sString);
string LeftPadString(string sString, int nLength, string sCharacter);
string VectorAsString(vector v, int nWidth = 0, int nDecimals = 2);
string SecondsToStringTimestamp(int nSeconds);
string FormatString(string sString, int nDepthOverride = 0);

string ltrim(string s)
{
    while (GetStringLeft(s, 1) == " ")
        s = GetStringRight(s, GetStringLength(s) - 1);

    return s;
}

string rtrim(string s)
{
    while (GetStringRight(s, 1) == " ")
        s = GetStringLeft(s, GetStringLength(s) - 1);

    return s;
}

string trim(string s)
{
    return ltrim(rtrim(s));
}

int HexStringToInt(string sString)
{
    sString = GetStringLowerCase(sString);
    int nResult, nLength = GetStringLength(sString), i;

    for (i = nLength - 1; i >= 0; i--)
    {
        int n = FindSubString("0123456789abcdef", GetSubString(sString, i, 1));
        if (n == -1)
            return nResult;
        nResult |= n << ((nLength - i - 1) * 4);
    }
    return nResult;
}

string LeftPadString(string sString, int nLength, string sCharacter)
{
    int nStringLength = GetStringLength(sString);
    string sPadding;
    while (nStringLength < nLength)
    {
        sPadding += sCharacter;
        nStringLength++;
    }
    return sPadding + sString;
}

string VectorAsString(vector v, int nWidth = 0, int nDecimals = 2)
{
    return "{" + FloatToString(v.x, nWidth, nDecimals) + ", " +
                 FloatToString(v.y, nWidth, nDecimals) + ", " +
                 FloatToString(v.z, nWidth, nDecimals) + "}";
}

string SecondsToStringTimestamp(int nSeconds)
{
    sqlquery sql;
    if (nSeconds > 86400)
        sql = SqlPrepareQueryObject(GetModule(), "SELECT (@seconds / 3600) || ':' || strftime('%M:%S', @seconds / 86400.0);");
    else
        sql = SqlPrepareQueryObject(GetModule(), "SELECT time(@seconds, 'unixepoch');");

    SqlBindInt(sql, "@seconds", nSeconds);
    SqlStep(sql);

    return SqlGetString(sql, 0);
}

string FormatString(string sString, int nDepthOverride = 0)
{
    json jVariables = RegExpIterate("\\{(\\w+)(?::(%[a-z]))?\\}", sString);
    int nIndex, nNumVariables = JsonGetLength(jVariables);
    if (!nNumVariables)
        return sString;

    json jStack = NWNX_VM_GetCurrentStack(2 + nDepthOverride);
    for (nIndex = 0; nIndex < nNumVariables; nIndex++)
    {
        json jVariable = JsonArrayGet(jVariables, nIndex);
        string sFullMatch = JsonArrayGetString(jVariable, 0);
        sFullMatch = "\\" + GetSubString(sFullMatch, 0, GetStringLength(sFullMatch) - 1) + "\\}";
        string sVarName = JsonArrayGetString(jVariable, 1);
        string sFormatSpecifier = JsonArrayGetString(jVariable, 2);

        json jStackVar;
        if (JsonObjectContainsKey(jStack, sVarName))
            jStackVar = JsonObjectGet(jStack, sVarName);

        if (JsonGetType(jStackVar) == JSON_TYPE_OBJECT)
        {
            int nAuxType = JsonObjectGetInt(jStackVar, "type");
            int nStackLocation = JsonObjectGetInt(jStackVar, "stack_location");
            string sValue = "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + " -> " + sFormatSpecifier + "]";

            if (sFormatSpecifier == "" || sFormatSpecifier == "%s")
            {
                switch (nAuxType)
                {
                    case VM_AUXTYPE_STRING: sValue = NWNX_VM_GetStackStringValue(nStackLocation); break;
                    case VM_AUXTYPE_INT:    sValue = IntToString(NWNX_VM_GetStackIntegerValue(nStackLocation)); break;
                    case VM_AUXTYPE_FLOAT:  sValue = FloatToString(NWNX_VM_GetStackFloatValue(nStackLocation)); break;
                    case VM_AUXTYPE_OBJECT:
                    {
                        object oObject = NWNX_VM_GetStackObjectValue(nStackLocation);
                        sValue = "[" + GetName(oObject) + "|" + GetTag(oObject) + "|0x" + ObjectToString(oObject) + "]";
                        break;
                    }
                    case VM_AUXTYPE_LOCATION:
                    {
                        location locLocation = NWNX_VM_GetStackLocationValue(nStackLocation);
                        vector vPosition = GetPositionFromLocation(locLocation);
                        sValue = "[" + GetTag(GetAreaFromLocation(locLocation)) + "|" +
                            FloatToString(vPosition.x, 0, 2) + "," +
                            FloatToString(vPosition.y, 0, 2) + "," +
                            FloatToString(vPosition.z, 0, 2) + "|" +
                            FloatToString(GetFacingFromLocation(locLocation), 0, 2) + "]";
                        break;
                    }
                    case VM_AUXTYPE_JSON: sValue = JsonDump(NWNX_VM_GetStackJsonValue(nStackLocation)); break;
                }
            }
            if (sFormatSpecifier == "%i")
            {
                switch (nAuxType)
                {
                    case VM_AUXTYPE_STRING: sValue = IntToString(StringToInt(NWNX_VM_GetStackStringValue(nStackLocation))); break;
                    case VM_AUXTYPE_INT:    sValue = IntToString(NWNX_VM_GetStackIntegerValue(nStackLocation)); break;
                    case VM_AUXTYPE_FLOAT:  sValue = IntToString(FloatToInt(NWNX_VM_GetStackFloatValue(nStackLocation))); break;
                    case VM_AUXTYPE_OBJECT: sValue = "0x" + ObjectToString(NWNX_VM_GetStackObjectValue(nStackLocation)); break;
                }
            }
            if (sFormatSpecifier == "%f")
            {
                switch (nAuxType)
                {
                    case VM_AUXTYPE_STRING: sValue = FloatToString(StringToFloat(NWNX_VM_GetStackStringValue(nStackLocation)), 0, 2); break;
                    case VM_AUXTYPE_INT:    sValue = FloatToString(IntToFloat(NWNX_VM_GetStackIntegerValue(nStackLocation)), 0, 2); break;
                    case VM_AUXTYPE_FLOAT:  sValue = FloatToString(NWNX_VM_GetStackFloatValue(nStackLocation), 0, 2); break;
                }
            }

            sString = RegExpReplace(sFullMatch, sString, sValue);
        }
        else
        {
            sString = RegExpReplace(sFullMatch, sString, "[MISSING VARIABLE:" + sVarName + "]");
        }
    }

    return sString;
}
