/*
    Script: ef_i_parser
    Author: Daz
*/

#include "ef_i_string"

const string PARSER_DEFAULT_DELIMITER   = "\n";
const int PARSER_DELIMITER_NOT_FOUND    = -1;

struct ParserData
{
    int nCurrentPos;
    int nDelimiterPos;
    int bEndOfFile;
    string sData;
    string sDelimiter;
    int nDelimiterLength;
    int nDataLength;
    string sLine;
    int nLineNumber;
    int bTrim;
};

struct ParserData ParserPrepare(string sData, int bTrim = FALSE, string sDelimiter = PARSER_DEFAULT_DELIMITER);
struct ParserData ParserParse(struct ParserData str);
string ParserPeek(struct ParserData str);

struct ParserData ParserPrepare(string sData, int bTrim = FALSE, string sDelimiter = PARSER_DEFAULT_DELIMITER)
{
    struct ParserData str;
    str.sData = sData;
    str.sDelimiter = sDelimiter;
    str.nDelimiterLength = GetStringLength(sDelimiter);
    str.nDataLength = GetStringLength(sData);
    str.bEndOfFile = str.nDataLength == 0;
    str.bTrim = bTrim;
    return str;
}

struct ParserData ParserParse(struct ParserData str)
{
    if (str.bEndOfFile)
        return str;
    if ((str.nDelimiterPos = FindSubString(str.sData, str.sDelimiter, str.nCurrentPos)) != PARSER_DELIMITER_NOT_FOUND)
    {
        str.sLine = GetSubString(str.sData, str.nCurrentPos, str.nDelimiterPos - str.nCurrentPos);
        if (str.bTrim)
            str.sLine = trim(str.sLine);
        str.nLineNumber++;
        str.nCurrentPos = str.nDelimiterPos + str.nDelimiterLength;
        return str;
    }
    if (str.nCurrentPos < str.nDataLength)
    {
        str.sLine = GetSubString(str.sData, str.nCurrentPos, str.nDataLength - str.nCurrentPos);
        if (str.bTrim)
            str.sLine = trim(str.sLine);
        str.nLineNumber++;
        str.nCurrentPos = str.nDataLength;
        return str;
    }
    str.bEndOfFile = TRUE;
    return str;
}

string ParserPeek(struct ParserData str)
{
    if (str.bEndOfFile)
        return "";
    int nNewLinePos = FindSubString(str.sData, str.sDelimiter, str.nCurrentPos);
    if (nNewLinePos != PARSER_DELIMITER_NOT_FOUND)
    {
        string s = GetSubString(str.sData, str.nCurrentPos, nNewLinePos - str.nCurrentPos);
        if (str.bTrim)
            s = trim(s);
        return s;
    }
    return "";
}
