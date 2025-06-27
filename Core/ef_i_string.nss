/*
    Script: ef_i_string
    Author: Daz
*/

string ltrim(string s);
string rtrim(string s);
string trim(string s);
int HexStringToInt(string sString);
string LeftPadString(string sString, int nLength, string sCharacter);
string VectorAsString(vector v, int nWidth = 0, int nDecimals = 2);
string SecondsToStringTimestamp(int nSeconds);

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
