/*
    Script: ef_i_string
    Author: Daz
*/

#include "ef_i_math"
#include "ef_i_vm"
#include "nwnx_util"

const int STRING_BAR_DEFAULT_WIDTH = 20;
const int STRING_BAR_MAX_WIDTH = 80;
const string STRING_OBJECT_INVALID = "0x7f000000";

string ltrim(string sString);
string rtrim(string sString);
string trim(string sString);
int HexStringToInt(string sString);
string EFIntToHexString(int nValue);
string LeftPadString(string sString, int nLength, string sCharacter);
string RightPadString(string sString, int nLength, string sCharacter);
string VectorAsString(vector v, int nWidth = 0, int nDecimals = 2);
string SecondsToStringTimestamp(int nSeconds);
int IsInteger(string sValue);
int IsFloat(string sValue);
int IsNumeric(string sValue);
string GetAsciiTable();
string ColorString(string sValue, int nRed, int nGreen, int nBlue);
string CapitalizeWord(string sWord);
int StringToBoolish(string sValue);
int IsStringPrefix(string sValue, string sPrefix);
int IsStringSuffix(string sValue, string sSuffix);
int IsObjectIDString(string sValue);
string RepeatText(string sText, int nCount);
string ObjectIDToString(object oObject);

string ltrim(string sString)
{
    int nLength = GetStringLength(sString), nStart;

    while (nStart < nLength && GetSubString(sString, nStart, 1) == " ")
    {
        nStart++;
    }

    if (nStart == 0)
        return sString;

    return GetSubString(sString, nStart, nLength - nStart);
}

string rtrim(string sString)
{
    int nLength = GetStringLength(sString), nEnd = nLength - 1;

    while (nEnd >= 0 && GetSubString(sString, nEnd, 1) == " ")
    {
        nEnd--;
    }

    if (nEnd == nLength - 1)
        return sString;

    return GetSubString(sString, 0, nEnd + 1);
}

string trim(string sString)
{
    int nLength = GetStringLength(sString), nStart, nEnd = nLength - 1;

    while (nStart < nLength && GetSubString(sString, nStart, 1) == " ")
    {
        nStart++;
    }

    while (nEnd >= nStart && GetSubString(sString, nEnd, 1) == " ")
    {
        nEnd--;
    }

    if (nStart == 0 && nEnd == nLength - 1)
        return sString;

    return GetSubString(sString, nStart, nEnd - nStart + 1);
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

string EFIntToHexString(int nValue)
{
    string sHexChars = "0123456789abcdef";
    string sResult = "";
    int nDigit;

    if (nValue == 0)
        return "0x0";

    while (nValue > 0)
    {
        nDigit = nValue % 16;
        sResult = GetSubString(sHexChars, nDigit, 1) + sResult;
        nValue = nValue / 16;
    }

    return "0x" + sResult;
}

string LeftPadString(string sString, int nLength, string sCharacter)
{
    string sPadding;
    int nPadding = nLength - GetStringLength(sString);
    while (nPadding-- > 0)
        sPadding += sCharacter;
    return sPadding + sString;
}

string RightPadString(string sString, int nLength, string sCharacter)
{
    string sPadding;
    int nPadding = nLength - GetStringLength(sString);
    while (nPadding-- > 0)
        sPadding += sCharacter;
    return sString + sPadding;
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

int IsInteger(string sValue)
{
    return JsonGetLength(RegExpMatch("^-?[0-9]+$", sValue));
}

int IsFloat(string sValue)
{
    return JsonGetLength(RegExpMatch("^-?(?:\\d+\\.\\d*|\\.\\d+)[fF]?$", sValue));
}

int IsNumeric(string sValue)
{
    return IsInteger(sValue) || IsFloat(sValue);
}

string GetAsciiTable()
{
    string sAscii = GetLocalString(GetModule(), "ASCII_TABLE");
    if (sAscii == "")
    {
        sAscii = NWNX_Util_GetAsciiTableString();
        SetLocalString(GetModule(), "ASCII_TABLE", sAscii);
    }
    return sAscii;
}

string ColorString(string sValue, int nRed, int nGreen, int nBlue)
{
    string sAscii = GetAsciiTable();
    return "<c" + GetSubString(sAscii, clamp(nRed, 0, 255), 1) +
                  GetSubString(sAscii, clamp(nGreen, 0, 255), 1) +
                  GetSubString(sAscii, clamp(nBlue, 0, 255), 1) + ">" + sValue + "</c>";
}

string CapitalizeWord(string sWord)
{
    if (sWord == "")
        return "";

    int nLength = GetStringLength(sWord);
    if (nLength <= 0)
        return "";

    return GetStringUpperCase(GetSubString(sWord, 0, 1)) + GetStringLowerCase(GetSubString(sWord, 1, nLength - 1));
}

int StringToBoolish(string sValue)
{
    sValue = GetStringLowerCase(trim(sValue));

    if (sValue == "")
        return FALSE;

    if (sValue == "0" || sValue == "0.0" || sValue == "false" || sValue == "f" ||
        sValue == "no" || sValue == "n" || sValue == "off" || sValue == "null" ||
        sValue == "nil" || sValue == "none")
    {
        return FALSE;
    }

    if (IsNumeric(sValue) && StringToFloat(sValue) == 0.0)
        return FALSE;

    return TRUE;
}

int IsStringPrefix(string sValue, string sPrefix)
{
    return GetStringLeft(sValue, GetStringLength(sPrefix)) == sPrefix;
}

int IsStringSuffix(string sValue, string sSuffix)
{
    return GetStringRight(sValue, GetStringLength(sSuffix)) == sSuffix;
}

int IsObjectIDString(string sValue)
{
    sValue = GetStringLowerCase(trim(sValue));
    if (GetStringLeft(sValue, 2) != "0x" || GetStringLength(sValue) < 3 )
        return FALSE;

    if (sValue == STRING_OBJECT_INVALID)
        return TRUE;

    return StringToObject(sValue) != OBJECT_INVALID;
}

string RepeatText(string sText, int nCount)
{
    string sResult = "";
    int nIndex;

    if (nCount < 0)
        nCount = 0;

    for (nIndex = 0; nIndex < nCount; nIndex++)
    {
        sResult += sText;
    }

    return sResult;
}

string ObjectIDToString(object oObject)
{
    if (!GetIsObjectValid(oObject))
        return STRING_OBJECT_INVALID;
    return "0x" + ObjectToString(oObject);
}
