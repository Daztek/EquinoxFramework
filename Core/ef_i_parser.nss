/*
    Script: ef_i_parser
    Author: Daz
*/

#include "ef_i_string"

struct ParserData
{
    int nStartPos;
    int nNewLinePos;
    int bEndOfFile;
    string sData;
    string sDelimiter;
    int nDataLength;
    string sLine;
    int nLineNumber;
    int bTrim;
};

struct ParserData ParserPrepare(string sData, int bTrim = FALSE, string sDelimiter = "\n");
struct ParserData ParserParse(struct ParserData str);
string ParserPeek(struct ParserData str);

struct ParserData ParserPrepare(string sData, int bTrim = FALSE, string sDelimiter = "\n")
{
    struct ParserData str;
    str.sData = sData;
    str.sDelimiter = sDelimiter;
    str.nDataLength = GetStringLength(sData);
    str.bEndOfFile = str.nDataLength == 0;
    str.bTrim = bTrim;
    return str;
}

struct ParserData ParserParse(struct ParserData str)
{
    if (str.bEndOfFile)
        return str;
    if ((str.nNewLinePos = FindSubString(str.sData, str.sDelimiter, str.nStartPos)) != -1)
    {
        str.sLine = GetSubString(str.sData, str.nStartPos, str.nNewLinePos - str.nStartPos);
        if (str.bTrim)
            str.sLine = trim(str.sLine);
        str.nLineNumber++;
        str.nStartPos = str.nNewLinePos + 1;
        return str;
    }
    if (str.nStartPos < str.nDataLength)
    {
        str.sLine = GetSubString(str.sData, str.nStartPos, str.nDataLength - str.nStartPos);
        if (str.bTrim)
            str.sLine = trim(str.sLine);
        str.nLineNumber++;
        str.nStartPos = str.nDataLength;
        return str;
    }
    str.bEndOfFile = TRUE;
    return str;
}

string ParserPeek(struct ParserData str)
{
    if (str.bEndOfFile)
        return "";
    int nNewLinePos = FindSubString(str.sData, str.sDelimiter, str.nStartPos);
    if (nNewLinePos != -1)
    {
        string s = GetSubString(str.sData, str.nStartPos, nNewLinePos - str.nStartPos);
        if (str.bTrim)
            s = trim(s);
        return s;
    }
    return "";
}
