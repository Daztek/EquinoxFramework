/*
    Script: ef_i_strfmt
    Author: Daz
*/

#include "ef_i_string"
#include "ef_i_vm"

string FormatString(string sString, int nDepthOverride = 0);
string GetFormattedValue(json jStack, string sVarName, string sFormatSpecifier);
string FormatValueByType(int nAuxType, int nStackLocation, string sFormatSpecifier);
string FormatAsString(int nAuxType, int nStackLocation, string sFormatSpecifier);
string FormatAsInteger(int nAuxType, int nStackLocation, string sFormatSpecifier);
string FormatAsFloat(int nAuxType, int nStackLocation, string sFormatSpecifier);
string FormatAsHex(int nAuxType, int nStackLocation, string sFormatSpecifier);
string FormatAsBoolean(int nAuxType, int nStackLocation, string sFormatSpecifier);
string FormatAsObject(int nAuxType, int nStackLocation, string sFormatSpecifier);
string FormatAsVector(json jStack, string sVarName, string sFormatSpecifier);
string DumpStruct(json jStack, string sVarName, string sStructName, string sInstanceName = "");

string FormatString(string sString, int nDepthOverride = 0)
{
    if (sString == "" || FindSubString(sString, "{", 0) == -1)
        return sString;

    json jVariables = RegExpIterate("\\{([\\w\\.]+)(?::(%[a-z0-9\\.]{0,5}))?\\}", sString);
    int nIndex, nNumVariables = JsonGetLength(jVariables);

    if (!nNumVariables)
        return sString;

    json jStack = NWNX_VM_GetCurrentStack(2 + nDepthOverride);
    string sResult = sString;

    for (nIndex = 0; nIndex < nNumVariables; nIndex++)
    {
        json jVariable = JsonArrayGet(jVariables, nIndex);
        string sFullMatch = JsonArrayGetString(jVariable, 0);
        string sVarName = JsonArrayGetString(jVariable, 1);
        string sFormatSpecifier = JsonArrayGetString(jVariable, 2);

        string sPattern = "\\{" + RegExpEscape(sVarName);
        if (sFormatSpecifier != "")
            sPattern += ":" + RegExpEscape(sFormatSpecifier);
        sPattern += "\\}";

        string sValue = GetFormattedValue(jStack, sVarName, sFormatSpecifier);
        sResult = RegExpReplace(sPattern, sResult, sValue);
    }

    return sResult;
}

string GetFormattedValue(json jStack, string sVarName, string sFormatSpecifier)
{
    if (!JsonObjectContainsKey(jStack, sVarName))
        return "[MISSING_VAR:" + sVarName + "]";

    json jStackVar = JsonObjectGet(jStack, sVarName);
    if (JsonGetType(jStackVar) != JSON_TYPE_OBJECT)
        return "[INVALID_STACK_VAR:" + sVarName + "]";

    int nAuxType = JsonObjectGetInt(jStackVar, "type");

    if (sFormatSpecifier == "")
        sFormatSpecifier = "%s";

    if (nAuxType == NWNX_VM_AUXTYPE_VOID)
    {
        string sStructName = JsonObjectGetString(jStackVar, "struct_name");
        if (sStructName == "vector")
            return FormatAsVector(jStack, sVarName, sFormatSpecifier);
        else
            return DumpStruct(jStack, sVarName, sStructName);
    }

    int nStackLocation = JsonObjectGetInt(jStackVar, "stack_location");
    return FormatValueByType(nAuxType, nStackLocation, sFormatSpecifier);
}

string FormatValueByType(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    if (sFormatSpecifier == "%s")
    {
        return FormatAsString(nAuxType, nStackLocation, sFormatSpecifier);
    }

    if (sFormatSpecifier == "%i")
    {
        return FormatAsInteger(nAuxType, nStackLocation, sFormatSpecifier);
    }

    if (sFormatSpecifier == "%f" ||
        (GetStringLeft(sFormatSpecifier, 2) == "%." && GetStringRight(sFormatSpecifier, 1) == "f"))
    {
        return FormatAsFloat(nAuxType, nStackLocation, sFormatSpecifier);
    }

    if (sFormatSpecifier == "%x")
    {
        return FormatAsHex(nAuxType, nStackLocation, sFormatSpecifier);
    }

    if (sFormatSpecifier == "%b")
    {
        return FormatAsBoolean(nAuxType, nStackLocation, sFormatSpecifier);
    }

    if (sFormatSpecifier == "%o" || GetStringLeft(sFormatSpecifier, 2) == "%o")
    {
        return FormatAsObject(nAuxType, nStackLocation, sFormatSpecifier);
    }

    return "[INVALID_FORMAT:" + sFormatSpecifier + "->" + AuxTypeToString(nAuxType) + "]";
}

string FormatAsString(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return NWNX_VM_GetStackStringValue(nStackLocation);
        case NWNX_VM_AUXTYPE_INT:       return IntToString(NWNX_VM_GetStackIntegerValue(nStackLocation));
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(NWNX_VM_GetStackFloatValue(nStackLocation), 0, 2);
        case NWNX_VM_AUXTYPE_OBJECT:
        {
            object oObject = NWNX_VM_GetStackObjectValue(nStackLocation);
            if (!GetIsObjectValid(oObject))
                return "[INVALID_OBJECT|OID:0x" + ObjectToString(oObject) + "]";
            return GetName(oObject) + "(TAG:" + GetTag(oObject)+ "|OID:0x" + ObjectToString(oObject) + ")";
        }
        case NWNX_VM_AUXTYPE_LOCATION:
        {
            location locLocation = NWNX_VM_GetStackLocationValue(nStackLocation);
            object oArea = GetAreaFromLocation(locLocation);
            if (!GetIsObjectValid(oArea))
                return "[INVALID_LOCATION]";

            vector vPosition = GetPositionFromLocation(locLocation);
            float fFacing = GetFacingFromLocation(locLocation);

            return GetTag(oArea) + "[" + FloatToString(vPosition.x, 0, 2) + "," + FloatToString(vPosition.y, 0, 2) + "," +
                FloatToString(vPosition.z, 0, 2) + "]@" + FloatToString(fFacing, 0, 1);
        }
        case NWNX_VM_AUXTYPE_JSON:
        {
            json jValue = NWNX_VM_GetStackJsonValue(nStackLocation);
            string sJson = JsonDump(jValue);
            if (GetStringLength(sJson) > 200)
                sJson = GetStringLeft(sJson, 197) + "...";
            return sJson;
        }
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%s]";
}

string FormatAsInteger(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:
        {
            string sValue = NWNX_VM_GetStackStringValue(nStackLocation);
            int nParsed = StringToInt(sValue);
            if (nParsed == 0 && sValue != "0" && GetStringLeft(sValue, 1) != "0")
                return "[PARSE_ERROR:" + sValue + "]";
            return IntToString(nParsed);
        }
        case NWNX_VM_AUXTYPE_INT:       return IntToString(NWNX_VM_GetStackIntegerValue(nStackLocation));
        case NWNX_VM_AUXTYPE_FLOAT:     return IntToString(FloatToInt(NWNX_VM_GetStackFloatValue(nStackLocation)));
        case NWNX_VM_AUXTYPE_OBJECT:    return IntToString(HexStringToInt(ObjectToString(NWNX_VM_GetStackObjectValue(nStackLocation))));
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%i]";
}

string FormatAsFloat(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    int nPrecision = 2;
    if (GetStringLength(sFormatSpecifier) > 2 && (GetStringLeft(sFormatSpecifier, 2) == "%." && GetStringRight(sFormatSpecifier, 1) == "f"))
    {
        nPrecision = StringToInt(GetSubString(sFormatSpecifier, 2, GetStringLength(sFormatSpecifier) - 3));
        if (nPrecision > 18)
            nPrecision = 18;
    }

    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_STRING:    return FloatToString(StringToFloat(NWNX_VM_GetStackStringValue(nStackLocation)), 0, nPrecision);
        case NWNX_VM_AUXTYPE_INT:       return FloatToString(IntToFloat(NWNX_VM_GetStackIntegerValue(nStackLocation)), 0, nPrecision);
        case NWNX_VM_AUXTYPE_FLOAT:     return FloatToString(NWNX_VM_GetStackFloatValue(nStackLocation), 0, nPrecision);
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%f]";
}

string FormatAsHex(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    int nValue;
    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       nValue = NWNX_VM_GetStackIntegerValue(nStackLocation); break;
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = FloatToInt(NWNX_VM_GetStackFloatValue(nStackLocation)); break;
        case NWNX_VM_AUXTYPE_OBJECT:    return "0x" + ObjectToString(NWNX_VM_GetStackObjectValue(nStackLocation));
        default:                return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%x]";
    }
    return EFIntToHexString(nValue);
}

string FormatAsBoolean(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    int nValue;
    switch (nAuxType)
    {
        case NWNX_VM_AUXTYPE_INT:       nValue = NWNX_VM_GetStackIntegerValue(nStackLocation); break;
        case NWNX_VM_AUXTYPE_FLOAT:     nValue = NWNX_VM_GetStackFloatValue(nStackLocation) != 0.0; break;
        case NWNX_VM_AUXTYPE_STRING:    nValue = NWNX_VM_GetStackStringValue(nStackLocation) != ""; break;
        case NWNX_VM_AUXTYPE_OBJECT:    nValue = GetIsObjectValid(NWNX_VM_GetStackObjectValue(nStackLocation)); break;
        case NWNX_VM_AUXTYPE_JSON:      nValue = JsonGetType(NWNX_VM_GetStackJsonValue(nStackLocation)) != JSON_TYPE_NULL; break;
        default:                return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%b]";
    }
    return nValue ? "TRUE" : "FALSE";
}

string FormatAsObject(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    if (nAuxType == NWNX_VM_AUXTYPE_OBJECT)
    {
        if (GetStringLength(sFormatSpecifier) == 3)
        {
            string sFormatType = GetStringRight(sFormatSpecifier, 1);
            if (sFormatType == "x")
                return FormatAsHex(nAuxType, nStackLocation, "%x");
            else if (sFormatType == "i")
                return FormatAsInteger(nAuxType, nStackLocation, "%i");
            else if (sFormatType == "n")
                return GetName(NWNX_VM_GetStackObjectValue(nStackLocation));
            else if (sFormatType == "t")
                return GetTag(NWNX_VM_GetStackObjectValue(nStackLocation));
        }
        else
            return FormatAsString(nAuxType, nStackLocation, "%s");
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%o]";
}

string FormatAsVector(json jStack, string sVarName, string sFormatSpecifier)
{
    string sX = FormatValueByType(NWNX_VM_AUXTYPE_FLOAT, JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".x"), "stack_location"), sFormatSpecifier);
    string sY = FormatValueByType(NWNX_VM_AUXTYPE_FLOAT, JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".y"), "stack_location"), sFormatSpecifier);
    string sZ = FormatValueByType(NWNX_VM_AUXTYPE_FLOAT, JsonObjectGetInt(JsonObjectGet(jStack, sVarName + ".z"), "stack_location"), sFormatSpecifier);
    return "[" + sX + "," + sY + "," + sZ + "]";
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
        if (GetStringLeft(sKey, nVarNameLength) == sVarName && sKey != sVarName)
        {
            string sMemberPath = GetSubString(sKey, nVarNameLength + 1, GetStringLength(sKey) - nVarNameLength - 1);
            if (FindSubString(sMemberPath, ".", 0) == -1)
            {
                json jStructVar = JsonObjectGet(jStack, sKey);
                int nAuxType = JsonObjectGetInt(jStructVar, "type");

                if (nAuxType == NWNX_VM_AUXTYPE_VOID)
                {
                    string sChildStructName = JsonObjectGetString(jStructVar, "struct_name");
                    if (sChildStructName != "vector")
                        sResult += DumpStruct(jStack, sKey, sChildStructName, sMemberPath);
                    else
                    {
                        string sValue = GetFormattedValue(jStack, sKey, "%s");
                        sResult += "vector " + sMemberPath + " = " + sValue + "; ";
                    }
                }
                else
                {
                    string sValue = GetFormattedValue(jStack, sKey, "%s");
                    string sVariableType = GetStringLowerCase(AuxTypeToString(nAuxType));
                    sResult += sVariableType + " " + sMemberPath + " = " + sValue + "; ";
                }
            }
        }
    }

    sResult += "} ";
    return sResult;
}
