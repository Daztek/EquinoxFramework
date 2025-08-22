/*
    Script: ef_i_string
    Author: Daz
*/

#include "ef_i_vm"

string ltrim(string s);
string rtrim(string s);
string trim(string s);
int HexStringToInt(string sString);
string EFIntToHexString(int nValue);
string LeftPadString(string sString, int nLength, string sCharacter);
string VectorAsString(vector v, int nWidth = 0, int nDecimals = 2);
string SecondsToStringTimestamp(int nSeconds);
string RegExpEscape(string sInput);

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

string RegExpEscape(string sInput)
{
    sInput = RegExpReplace("\\\\", sInput, "\\\\");
    sInput = RegExpReplace("\\.", sInput, "\\.");
    sInput = RegExpReplace("\\^", sInput, "\\^");
    sInput = RegExpReplace("\\$", sInput, "\\$");
    sInput = RegExpReplace("\\*", sInput, "\\*");
    sInput = RegExpReplace("\\+", sInput, "\\+");
    sInput = RegExpReplace("\\?", sInput, "\\?");
    sInput = RegExpReplace("\\{", sInput, "\\{");
    sInput = RegExpReplace("\\}", sInput, "\\}");
    sInput = RegExpReplace("\\[", sInput, "\\[");
    sInput = RegExpReplace("\\]", sInput, "\\]");
    sInput = RegExpReplace("\\(", sInput, "\\(");
    sInput = RegExpReplace("\\)", sInput, "\\)");
    sInput = RegExpReplace("\\|", sInput, "\\|");
    return sInput;
}
