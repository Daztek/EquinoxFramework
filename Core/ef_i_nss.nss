/*
    Scripte: ef_i_nss
    Author: Daz

    Description: Equinox Framework NSS Utility Include
*/

string nssVoidMain(string sContents);
string nssStartingConditional(string sContents);
string nssInclude(string sIncludeFile);
string nssIf(string sLeft, string sComparison = "", string sRight = "");
string nssElseIf(string sLeft, string sComparison = "", string sRight = "");
string nssWhile(string sLeft, string sComparison = "", string sRight = "");
string nssBrackets(string sContents);
string nssEscape(string sString);
string nssSwitch(string sVariable, string sCases);
string nssCaseStatement(int nCase, string sContents, int bBreak = TRUE);
string nssVariable(string sType, string sVarName, string sFunction);
string nssParameter(string sType, string sVarName);
string nssObject(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssString(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssInt(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssFloat(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssVector(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssLocation(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssCassowary(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssJson(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssFunction(string sFunction, string sArguments = "", int bAddSemicolon = TRUE);
// Converts o to Object, s to String, etc
// Only supports the following types: (o)bject, (s)tring, (i)nt, (f)loat, (l)ocation, (v)ector, (j)son
string nssConvertShortType(string sShortType, int bLowerCase = FALSE);
string nssConvertType(string sType);
string nssCompileScript(string sFileName, string sInclude, string sScriptChunk);

string nssVoidMain(string sContents)
{
    return "void main(){" + sContents + "}";
}

string nssStartingConditional(string sContents)
{
    return "int StartingConditional(){return " + sContents + "}";
}

string nssInclude(string sIncludeFile)
{
    return sIncludeFile == "" ? sIncludeFile : "#" + "include \"" + sIncludeFile + "\"";
}

string nssIf(string sLeft, string sComparison, string sRight)
{
    return "if(" + sLeft + sComparison + sRight + ")";
}

string nssElseIf(string sLeft, string sComparison, string sRight)
{
    return "else if(" + sLeft + sComparison + sRight + ")";
}

string nssWhile(string sLeft, string sComparison, string sRight)
{
    return "while " + sLeft + sComparison + sRight + ")";
}

string nssBrackets(string sContents)
{
    return "{" + sContents + " }";
}

string nssEscape(string sString)
{
    return "\"" + sString + "\"";
}

string nssSwitch(string sVariable, string sCases)
{
    return "switch(" + sVariable + "){" + sCases + "}";
}

string nssCaseStatement(int nCase, string sContents, int bBreak = TRUE)
{
    return "case " + IntToString(nCase) + ":{" + sContents + (bBreak ? "break;" : "") + "}";
}

string nssSemicolon(string sString)
{
    return (GetStringRight(sString, 1) == ";") ? sString : sString + ";";
}

string nssVariable(string sType, string sVarName, string sFunction)
{
    return sType + " " + sVarName + (sFunction == "" ? ";" : "=" + nssSemicolon(sFunction));
}

string nssParameter(string sType, string sVarName)
{
    return sType + " " + sVarName;
}

string nssObject(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "object" : "", sVarName, sFunction);
}

string nssString(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "string" : "", sVarName, sFunction);
}

string nssInt(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "int" : "", sVarName, sFunction);
}

string nssFloat(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "float" : "", sVarName, sFunction);
}

string nssVector(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "vector" : "", sVarName, sFunction);
}

string nssLocation(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "location" : "", sVarName, sFunction);
}

string nssCassowary(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "cassowary" : "", sVarName, sFunction);
}

string nssJson(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "json" : "", sVarName, sFunction);
}

string nssFunction(string sFunction, string sArguments, int bAddSemicolon = TRUE)
{
    return sFunction + "(" + sArguments + (bAddSemicolon ? ");" : ")");
}

string nssConvertShortType(string sShortType, int bLowerCase = FALSE)
{
    string sReturn;
    sShortType = GetStringLowerCase(sShortType);

    if (sShortType == "o")      sReturn = "Object";
    else if (sShortType == "s") sReturn = "String";
    else if (sShortType == "i") sReturn = "Int";
    else if (sShortType == "f") sReturn = "Float";
    else if (sShortType == "l") sReturn = "Location";
    else if (sShortType == "v") sReturn = "Vector";
    else if (sShortType == "j") sReturn = "Json";

    return bLowerCase ? GetStringLowerCase(sReturn) : sReturn;
}

string nssConvertType(string sType)
{
    string sReturn;
    sType = GetStringLowerCase(sType);

    if (sType == "object")          sReturn = "o";
    else if (sType == "string")     sReturn = "s";
    else if (sType == "int")        sReturn = "i";
    else if (sType == "float")      sReturn = "f";
    else if (sType == "location")   sReturn = "l";
    else if (sType == "vector")     sReturn = "v";
    else if (sType == "json")       sReturn = "j";

    return sReturn;
}

string nssCompileScript(string sFileName, string sInclude, string sScriptChunk)
{
    return CompileScript(sFileName, nssInclude(sInclude) + nssVoidMain(sScriptChunk));
}
