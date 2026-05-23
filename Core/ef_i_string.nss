/*
    Script: ef_i_string
    Author: Daz
*/

#include "ef_i_math"
#include "ef_i_vm"
#include "nwnx_util"

string ltrim(string s);
string rtrim(string s);
string trim(string s);
int HexStringToInt(string sString);
string EFIntToHexString(int nValue);
string LeftPadString(string sString, int nLength, string sCharacter);
string RightPadString(string sString, int nLength, string sCharacter);
string VectorAsString(vector v, int nWidth = 0, int nDecimals = 2);
string SecondsToStringTimestamp(int nSeconds);
int IsNumeric(string sValue);
string GetAsciiTable();
string ColorString(string sValue, int nRed, int nGreen, int nBlue);

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

int IsNumeric(string sValue)
{
    if (sValue == "") return FALSE;
    if (sValue == "0") return TRUE;
    int nParsed = StringToInt(sValue);
    return (nParsed != 0 || GetStringLeft(sValue, 1) == "0" || sValue == "-0");
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
