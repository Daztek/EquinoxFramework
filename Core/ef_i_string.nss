/*
    Script: ef_i_string
    Author: Daz
*/

#include "ef_i_math"
#include "ef_i_vm"
#include "nwnx_util"

const int STRING_BAR_DEFAULT_WIDTH = 20;
const int STRING_BAR_MAX_WIDTH = 80;


string ltrim(string s);
string rtrim(string s);
string trim(string s);
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
int IsObjectString(string sValue);
string RepeatText(string sText, int nCount);
string MakeBarString(float fValue, float fMax, int nWidth, string sFilled = "#", string sEmpty = "-");

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

    string sFirst = GetSubString(sWord, 0, 1);
    string sRest = GetSubString(sWord, 1, nLength - 1);
    return GetStringUpperCase(sFirst) + GetStringLowerCase(sRest);
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

int IsObjectString(string sValue)
{
    sValue = GetStringLowerCase(trim(sValue));

    if (sValue == "0x7f000000")
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

string MakeBarString(float fValue, float fMax, int nWidth, string sFilled = "#", string sEmpty = "-")
{
    if (nWidth <= 0)
        nWidth = STRING_BAR_DEFAULT_WIDTH;

    if (nWidth > STRING_BAR_MAX_WIDTH)
        nWidth = STRING_BAR_MAX_WIDTH;

    if (sFilled == "")
        sFilled = "#";

    if (sEmpty == "")
        sEmpty = "-";

    float fRatio = 0.0;

    if (fabs(fMax) > FLOAT_EPSILON)
        fRatio = fValue / fMax;

    if (fRatio < 0.0)
        fRatio = 0.0;

    if (fRatio > 1.0)
        fRatio = 1.0;

    int nFilled = FloatToInt((fRatio * IntToFloat(nWidth)) + 0.5);
    int nEmpty = nWidth - nFilled;

    string sPercent = FloatToString(fRatio * 100.0, 0, 0);

    return "[" + RepeatText(sFilled, nFilled) + RepeatText(sEmpty, nEmpty) + "] " + sPercent + "%";
}
