/*
    Script: ef_i_strfmt
    Author: Daz
*/

#include "ef_i_string"
#include "ef_i_vm"

string FormatString(string sString, int nDepthOverride = 0);
string GetFormattedValue(json jStack, string sVarName, string sFormatSpecifier);
string FormatValueByType(int nAuxType, int nStackLocation, string sFormatSpecifier);
string FormatAsString(int nAuxType, int nStackLocation);
string FormatAsInteger(int nAuxType, int nStackLocation);
string FormatAsFloat(int nAuxType, int nStackLocation);
string FormatAsHex(int nAuxType, int nStackLocation);
string FormatAsBoolean(int nAuxType, int nStackLocation);
string RegExpEscape(string sInput);

string FormatString(string sString, int nDepthOverride = 0)
{
    if (sString == "")
        return sString;

    json jVariables = RegExpIterate("\\{([\\w\\.]+)(?::(%[a-z]))?\\}", sString);
    int nIndex, nNumVariables = JsonGetLength(jVariables);

    if (!nNumVariables)
        return sString;

    json jStack = NWNX_VM_GetCurrentStack(2 + nDepthOverride);
    string sResult = sString;

    for (nIndex = nNumVariables - 1; nIndex >= 0; nIndex--)
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
        return "[MISSING:" + sVarName + "]";

    json jStackVar = JsonObjectGet(jStack, sVarName);
    if (JsonGetType(jStackVar) != JSON_TYPE_OBJECT)
        return "[INVALID_STACK_VAR:" + sVarName + "]";

    int nAuxType = JsonObjectGetInt(jStackVar, "type");
    int nStackLocation = JsonObjectGetInt(jStackVar, "stack_location");
    if (sFormatSpecifier == "")
        sFormatSpecifier = "%s";

    return FormatValueByType(nAuxType, nStackLocation, sFormatSpecifier);
}

string FormatValueByType(int nAuxType, int nStackLocation, string sFormatSpecifier)
{
    if (sFormatSpecifier == "%s")
        return FormatAsString(nAuxType, nStackLocation);
    else if (sFormatSpecifier == "%i")
        return FormatAsInteger(nAuxType, nStackLocation);
    else if (sFormatSpecifier == "%f")
        return FormatAsFloat(nAuxType, nStackLocation);
    else if (sFormatSpecifier == "%x")
        return FormatAsHex(nAuxType, nStackLocation);
    else if (sFormatSpecifier == "%b")
        return FormatAsBoolean(nAuxType, nStackLocation);

    return "[INVALID_FORMAT:" + sFormatSpecifier + " -> " + AuxTypeToString(nAuxType) + "]";
}

string FormatAsString(int nAuxType, int nStackLocation)
{
    switch (nAuxType)
    {
        case VM_AUXTYPE_STRING: return NWNX_VM_GetStackStringValue(nStackLocation);
        case VM_AUXTYPE_INT:    return IntToString(NWNX_VM_GetStackIntegerValue(nStackLocation));
        case VM_AUXTYPE_FLOAT:  return FloatToString(NWNX_VM_GetStackFloatValue(nStackLocation), 0, 4);
        case VM_AUXTYPE_OBJECT:
        {
            object oObject = NWNX_VM_GetStackObjectValue(nStackLocation);
            if (!GetIsObjectValid(oObject))
                return "[INVALID_OBJECT:0x" + ObjectToString(oObject) + "]";
            return GetName(oObject) + " (" + GetTag(oObject)+ ":0x" + ObjectToString(oObject) + ")";
        }
        case VM_AUXTYPE_LOCATION:
        {
            location locLocation = NWNX_VM_GetStackLocationValue(nStackLocation);
            object oArea = GetAreaFromLocation(locLocation);
            if (!GetIsObjectValid(oArea))
                return "[INVALID_LOCATION]";

            vector vPos = GetPositionFromLocation(locLocation);
            float fFacing = GetFacingFromLocation(locLocation);

            return GetTag(oArea) + "[" + FloatToString(vPos.x, 0, 2) + "," +
                    FloatToString(vPos.y, 0, 2) + "," + FloatToString(vPos.z, 0, 2) + "]@" +
                    FloatToString(fFacing, 0, 1);
        }
        case VM_AUXTYPE_JSON:
        {
            json jValue = NWNX_VM_GetStackJsonValue(nStackLocation);
            string sJson = JsonDump(jValue);
            if (GetStringLength(sJson) > 200)
                sJson = GetStringLeft(sJson, 197) + "...";
            return sJson;
        }
    }
    return "[UNSUPPORTED_TYPE:" + AuxTypeToString(nAuxType) + "]";
}

string FormatAsInteger(int nAuxType, int nStackLocation)
{
    switch (nAuxType)
    {
        case VM_AUXTYPE_STRING:
        {
            string sValue = NWNX_VM_GetStackStringValue(nStackLocation);
            int nParsed = StringToInt(sValue);
            if (nParsed == 0 && sValue != "0" && GetStringLeft(sValue, 1) != "0")
                return "[PARSE_ERROR:" + sValue + "]";
            return IntToString(nParsed);
        }
        case VM_AUXTYPE_INT:    return IntToString(NWNX_VM_GetStackIntegerValue(nStackLocation));
        case VM_AUXTYPE_FLOAT:  return IntToString(FloatToInt(NWNX_VM_GetStackFloatValue(nStackLocation)));
        case VM_AUXTYPE_OBJECT: return IntToString(HexStringToInt(ObjectToString(NWNX_VM_GetStackObjectValue(nStackLocation))));
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%i]";
}

string FormatAsFloat(int nAuxType, int nStackLocation)
{
    switch (nAuxType)
    {
        case VM_AUXTYPE_STRING: return FloatToString(StringToFloat(NWNX_VM_GetStackStringValue(nStackLocation)), 0, 4);
        case VM_AUXTYPE_INT:    return FloatToString(IntToFloat(NWNX_VM_GetStackIntegerValue(nStackLocation)), 0, 2);
        case VM_AUXTYPE_FLOAT:  return FloatToString(NWNX_VM_GetStackFloatValue(nStackLocation), 0, 4);
    }
    return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%f]";
}

string FormatAsHex(int nAuxType, int nStackLocation)
{
    int nValue;
    switch (nAuxType)
    {
        case VM_AUXTYPE_INT:    nValue = NWNX_VM_GetStackIntegerValue(nStackLocation); break;
        case VM_AUXTYPE_FLOAT:  nValue = FloatToInt(NWNX_VM_GetStackFloatValue(nStackLocation)); break;
        case VM_AUXTYPE_OBJECT: return "0x" + ObjectToString(NWNX_VM_GetStackObjectValue(nStackLocation));
        default:                return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%x]";
    }
    return EFIntToHexString(nValue);
}

string FormatAsBoolean(int nAuxType, int nStackLocation)
{
    int nValue;
    switch (nAuxType)
    {
        case VM_AUXTYPE_INT:    nValue = NWNX_VM_GetStackIntegerValue(nStackLocation); break;
        case VM_AUXTYPE_FLOAT:  nValue = NWNX_VM_GetStackFloatValue(nStackLocation) != 0.0; break;
        case VM_AUXTYPE_STRING: nValue = NWNX_VM_GetStackStringValue(nStackLocation) != ""; break;
        case VM_AUXTYPE_OBJECT: nValue = GetIsObjectValid(NWNX_VM_GetStackObjectValue(nStackLocation)); break;
        case VM_AUXTYPE_JSON:   nValue = JsonGetType(NWNX_VM_GetStackJsonValue(nStackLocation)) != JSON_TYPE_NULL; break;
        default:                return "[TYPE_MISMATCH:" + AuxTypeToString(nAuxType) + "->%b]";
    }
    return nValue ? "TRUE" : "FALSE";
}
