/*
    Script: ef_t_dazscript
    Author: Daz
*/

#include "ef_c_dazscript"

void DazScript_ResetInstructionCounter();
void DazScript_PrintPass(string sName);
void DazScript_PrintFailure(string sName, string sInput, string sExpectationLabel, string sExpected, string sActual);
void DazScript_RecordResult(string sName, int bPassed, string sInput, string sExpectationLabel, string sExpected, string sActual);
void DazScript_Test(string sName, string sInput, string sExpected);
void DazScript_TestContains(string sName, string sInput, string sExpectedSubstring);
void DazScript_TestNotContains(string sName, string sInput, string sForbiddenSubstring);
void DazScript_TestStateString(string sName, string sActual, string sExpected);
void DazScript_TestStateInt(string sName, int nActual, int nExpected);
void DazScript_TestStateFloat(string sName, float fActual, float fExpected, float fTolerance);
void DazScript_TestStateJson(string sName, json jActual, string sExpectedDump);

void DazScript_TestSmoke();
void DazScript_TestPrimitives();
void DazScript_TestJson();
void DazScript_TestForeach();
void DazScript_TestMoreJsonLikeCollectionOrAggregate();

void DazScript_TestParserWhitespace();
void DazScript_TestStringProperties();
void DazScript_TestParserErrors();
void DazScript_TestParserEvil();

void DazScript_TestMetaVars();
void DazScript_TestRender();
void DazScript_TestFunctionParams();
void DazScript_TestLazy();
void DazScript_TestControlFlow();

void DazScript_TestMath();
void DazScript_TestOut();
void DazScript_TestSymbolTypes();
void DazScript_TestErrorHandling();

int g_nPassed = 0;
int g_nFailed = 0;
int g_bVerbosePasses = FALSE;
object g_oCreature = OBJECT_INVALID;

void DazScript_ResetInstructionCounter()
{
    NWNX_VM_SetInstructionsExecuted(0);
}

void DazScript_PrintPass(string sName)
{

    if (g_bVerbosePasses)
        PrintString("[PASS] " + sName);
}

void DazScript_PrintFailure(string sName, string sInput, string sExpectationLabel, string sExpected, string sActual)
{
    PrintString("[FAIL] " + sName);
    if (sInput != "")
        PrintString("  input:    " + sInput);
    PrintString("  " + sExpectationLabel + " " + sExpected);
    PrintString("  actual:   " + sActual);
}

void DazScript_RecordResult(string sName, int bPassed, string sInput, string sExpectationLabel, string sExpected, string sActual)
{
    if (bPassed)
    {
        g_nPassed++;
        DazScript_PrintPass(sName);
    }
    else
    {
        g_nFailed++;
        DazScript_PrintFailure(sName, sInput, sExpectationLabel, sExpected, sActual);
    }

    DazScript_ResetInstructionCounter();
}

void DazScript_Test(string sName, string sInput, string sExpected)
{
    string sActual = Interpret(sInput, FALSE, 1);
    DazScript_RecordResult(sName, sActual == sExpected, sInput, "expected:", sExpected, sActual);
}

void DazScript_TestContains(string sName, string sInput, string sExpectedSubstring)
{
    string sActual = Interpret(sInput, FALSE, 1);
    DazScript_RecordResult(sName, FindSubString(sActual, sExpectedSubstring) >= 0, sInput, "expected has:", sExpectedSubstring, sActual);
}

void DazScript_TestNotContains(string sName, string sInput, string sForbiddenSubstring)
{
    string sActual = Interpret(sInput, FALSE, 1);
    DazScript_RecordResult(sName, FindSubString(sActual, sForbiddenSubstring) == -1, sInput, "should avoid:", sForbiddenSubstring, sActual);
}

void DazScript_TestStateString(string sName, string sActual, string sExpected)
{
    DazScript_RecordResult(sName, sActual == sExpected, "", "expected:", sExpected, sActual);
}

void DazScript_TestStateInt(string sName, int nActual, int nExpected)
{
    DazScript_RecordResult(sName, nActual == nExpected, "", "expected:", IntToString(nExpected), IntToString(nActual));
}

void DazScript_TestStateFloat(string sName, float fActual, float fExpected, float fTolerance)
{
    DazScript_RecordResult(sName, fabs(fActual - fExpected) <= fTolerance, "", "expected:", FloatToString(fExpected), FloatToString(fActual));
}

void DazScript_TestStateJson(string sName, json jActual, string sExpectedDump)
{
    string sActual = JsonDump(jActual);
    DazScript_RecordResult(sName, sActual == sExpectedDump, "", "expected:", sExpectedDump, sActual);
}

void DazScript_SetupSqlTests()
{
    sqlquery q;

    q = SqlPrepareQueryModule(
        "CREATE TABLE IF NOT EXISTS test_players (" +
        "id INTEGER PRIMARY KEY," +
        "name TEXT," +
        "level INTEGER," +
        "xp INTEGER," +
        "gold INTEGER," +
        "rating REAL," +
        "payload TEXT," +
        "owner INTEGER" +
        ");");
    SqlStep(q);

    q = SqlPrepareQueryModule(
        "REPLACE INTO test_players (id, name, level, xp, gold, rating, payload, owner) " +
        "VALUES (@id, @name, @level, @xp, @gold, @rating, @payload, @owner);");

    SqlBindInt(q, "@id", 1);
    SqlBindString(q, "@name", "Test Player 1");
    SqlBindInt(q, "@level", 3);
    SqlBindInt(q, "@xp", 1000);
    SqlBindInt(q, "@gold", 125);
    SqlBindFloat(q, "@rating", 1.5);
    SqlBindJson(q, "@payload", JsonParse("{\"class\":\"fighter\",\"active\":true}"));
    SqlBindObjectRef(q, "@owner", g_oCreature);
    SqlStep(q);

    SqlResetQuery(q, TRUE);

    SqlBindInt(q, "@id", 2);
    SqlBindString(q, "@name", "Test Player 2");
    SqlBindInt(q, "@level", 6);
    SqlBindInt(q, "@xp", 2500);
    SqlBindInt(q, "@gold", 475);
    SqlBindFloat(q, "@rating", 2.5);
    SqlBindJson(q, "@payload", JsonParse("{\"class\":\"wizard\",\"active\":false}"));
    SqlBindObjectRef(q, "@owner", g_oCreature);
    SqlStep(q);

    SqlResetQuery(q, TRUE);

    SqlBindInt(q, "@id", 3);
    SqlBindString(q, "@name", "Test Player 3");
    SqlBindInt(q, "@level", 6);
    SqlBindInt(q, "@xp", 6250);
    SqlBindInt(q, "@gold", 475);
    SqlBindFloat(q, "@rating", 3.75);
    SqlBindJson(q, "@payload", JsonParse("{\"class\":\"rogue\",\"active\":true}"));
    SqlBindObjectRef(q, "@owner", g_oCreature);
    SqlStep(q);
}

void DazScript_TestSmoke()
{
    int nNum = 5;
    float fNum = 12.5;
    string sText = "hello";
    string sEmpty = "";
    object oCreature = g_oCreature;

    DazScript_Test("literal braces",
        "Hello {{oCreature}}",
        "Hello {oCreature}");

    DazScript_Test("object valid",
        "{oCreature>valid>bool}",
        "TRUE");

    DazScript_Test("object tag",
        "{oCreature>tag}",
        "DAZSCRIPT_CREATURE");

    DazScript_Test("basic int",
        "{nNum>int}",
        "5");

    DazScript_Test("basic float",
        "{fNum>fixed(1)}",
        "12.5");

    DazScript_Test("basic string",
        "{sText}",
        "hello");

    DazScript_Test("string capitalize",
        "{sText>capitalize}",
        "Hello");

    DazScript_Test("int comparison",
        "{nNum>gte(5)>bool}",
        "TRUE");

    DazScript_Test("int clamp",
        "{@int(150)>clamp(0, 100)}",
        "100");

    DazScript_Test("float clamp",
        "{@float(12.5)>clamp(0.0, 10.0)>fixed(1)}",
        "10.0");

    DazScript_Test("math add int",
        "{@add(2, 3)}",
        "5");

    DazScript_Test("math add float",
        "{@add(2.5, 3.5)>fixed(1)}",
        "6.0");

    DazScript_Test("math min",
        "{@min(8, 3, 5)}",
        "3");

    DazScript_Test("math max float",
        "{@max(8.5, 3.0, 5.0)>fixed(1)}",
        "8.5");

    DazScript_Test("bool not",
        "{@not(FALSE)>bool}",
        "TRUE");

    DazScript_Test("bool and",
        "{@and(TRUE, 1, yes)>bool}",
        "TRUE");

    DazScript_Test("bool or",
        "{@or(FALSE, 0, yes)>bool}",
        "TRUE");

    DazScript_Test("if true branch",
        "{@if(TRUE, yes, no)}",
        "yes");

    DazScript_Test("if false branch",
        "{@if(FALSE, yes, no)}",
        "no");

    DazScript_Test("set alias",
        "{@set($x, 123)}{$x}",
        "123");

    DazScript_Test("function",
        "{@fn(#greet, $name, Hello {$name})}{#greet(Daz)}",
        "Hello Daz");

    DazScript_Test("pick simple smoke",
        "{@pick(a)}",
        "a");

    DazScript_Test("debug exists missing",
        "{@exists($missing)>bool}",
        "FALSE");

    DazScript_Test("type alias",
        "{@set($x, 123)}{@type($x)}",
        "alias:int");

    string sValue = "one";
    DazScript_Test("cache stack value first run", "{sValue}", "one");

    sValue = "two";
    DazScript_Test("cache stack value second run", "{sValue}", "two");
}

void DazScript_TestPrimitives()
{
    object oCreature = g_oCreature;

    DazScript_Test("primitive int from string trims",
        "{@int('  42  ')}",
        "42");

    DazScript_Test("primitive int from float truncates",
        "{@int(12.9)}",
        "12");

    DazScript_TestContains("primitive int rejects non numeric string",
        "{@int(abc)}",
        "TYPE_MISMATCH:STRING->int");

    DazScript_Test("primitive float from int",
        "{@float(12)>fixed(1)}",
        "12.0");

    DazScript_Test("primitive float from string trims",
        "{@float('  12.5  ')>fixed(1)}",
        "12.5");

    DazScript_TestContains("primitive float rejects non numeric string",
        "{@float(abc)}",
        "TYPE_MISMATCH:STRING->float");

    DazScript_Test("primitive string from int",
        "{@string(123)>append(x)}",
        "123x");

    DazScript_Test("primitive string preserves quoted spaces",
        "{@string('  abc  ')}",
        "  abc  ");

    DazScript_Test("primitive object pass-through",
        "{@object({oCreature})>tag}",
        "DAZSCRIPT_CREATURE");

    DazScript_TestContains("primitive object rejects normal string",
        "{@object(not_an_object)}",
        "TYPE_MISMATCH:STRING->object");

    DazScript_TestContains("primitive shorthand int meta rejected",
        "{@i(123)}",
        "UNKNOWN_META:i");

    DazScript_TestContains("primitive shorthand json meta rejected",
        "{@j('1')}",
        "UNKNOWN_META:j");

    DazScript_Test("quoted true remains string",
        "{@string('true')}",
        "true");

    DazScript_Test("quoted false remains string",
        "{@string('false')}",
        "false");

    DazScript_Test("quoted numeric remains string text",
        "{@string('123')>append(x)}",
        "123x");

    DazScript_Test("quoted float remains string text",
        "{@string('12.50')}",
        "12.50");

    DazScript_Test("quoted interpolation still works",
        "{@set($x, 42)}{@string('value={$x}')}",
        "value=42");

    DazScript_Test("quoted numeric alias remains string",
        "{@set($x, '123')}{@type($x)}|{$x}",
        "alias:string|123");

    DazScript_Test("quoted float alias preserves text",
        "{@set($x, '12.50')}{@type($x)}|{$x}",
        "alias:string|12.50");

    DazScript_Test("unquoted float alias remains float",
        "{@set($x, 12.50)}{@type($x)}|{$x>fixed(1)}",
        "alias:float|12.5");
}

void DazScript_TestJson()
{
    json jObj = JsonObject();
    JsonObjectSetStringInplace(jObj, "name", "Daz");
    JsonObjectSetIntInplace(jObj, "hp", 42);
    JsonObjectSetFloatInplace(jObj, "ratio", 12.5);

    json jArr = JsonArray();
    JsonArrayInsertStringInplace(jArr, "first");
    JsonArrayInsertIntInplace(jArr, 2);
    JsonArrayInsertStringInplace(jArr, "last");

    DazScript_Test("json object type",
        "{jObj>type}",
        "object");

    DazScript_Test("json object length",
        "{jObj>length}",
        "3");

    DazScript_Test("json has true",
        "{jObj>has(name)>bool}",
        "TRUE");

    DazScript_Test("json has false",
        "{jObj>has(missing)>bool}",
        "FALSE");

    DazScript_Test("json get string unwraps",
        "{jObj>get(name)>upper}",
        "DAZ");

    DazScript_Test("json get int unwraps",
        "{jObj>get(hp)>gte(40)>bool}",
        "TRUE");

    DazScript_Test("json get float unwraps",
        "{jObj>get(ratio)>fixed(1)}",
        "12.5");

    DazScript_Test("json get default",
        "{jObj>get(missing, fallback)}",
        "fallback");

    DazScript_TestContains("json missing key error",
        "{jObj>get(missing)}",
        "JSON_MISSING_KEY:missing");

    DazScript_Test("json array type",
        "{jArr>type}",
        "array");

    DazScript_Test("json array length",
        "{jArr>length}",
        "3");

    DazScript_Test("json array at first",
        "{jArr>at(0)}",
        "first");

    DazScript_Test("json array at negative index",
        "{jArr>at(-1)}",
        "last");

    DazScript_Test("json array at default",
        "{jArr>at(99, none)}",
        "none");

    DazScript_Test("json array at int unwraps",
        "{jArr>at(1)>incr}",
        "3");

    DazScript_TestContains("json not array error",
        "{jObj>at(0)}",
        "JSON_NOT_ARRAY");

    DazScript_TestContains("json not object error",
        "{jArr>get(name)}",
        "JSON_NOT_OBJECT");

    DazScript_Test("json primitive object type",
        "{@json('{{\"name\":\"Daz\",\"hp\":42,\"ratio\":12.5}}')>type}",
        "object");

    DazScript_Test("json primitive object get string",
        "{@json('{{\"name\":\"Daz\",\"hp\":42}}')>get(name)}",
        "Daz");

    DazScript_Test("json primitive object get int",
        "{@json('{{\"name\":\"Daz\",\"hp\":42}}')>get(hp)>incr}",
        "43");

    DazScript_Test("json primitive object get float",
        "{@json('{{\"ratio\":12.5}}')>get(ratio)>fixed(1)}",
        "12.5");

    DazScript_Test("json primitive parser preserves comma and property delimiter",
        "{@json('{{\"text\":\"a,b>c\"}}')>get(text)}",
        "a,b>c");

    DazScript_Test("json primitive nested object",
        "{@json('{{\"outer\":{{\"inner\":7}}}}')>get(outer)>get(inner)>incr}",
        "8");

    DazScript_Test("json primitive nested array",
        "{@json('{{\"nums\":[1,2,3]}}')>get(nums)>at(1)}",
        "2");

    DazScript_Test("json primitive array type",
        "{@json('[\"first\",2,\"last\"]')>type}",
        "array");

    DazScript_Test("json primitive array length",
        "{@json('[\"first\",2,\"last\"]')>length}",
        "3");

    DazScript_Test("json primitive array negative index",
        "{@json('[\"first\",2,\"last\"]')>at(-1)}",
        "last");

    DazScript_Test("json primitive root string type",
        "{@json('\"hello\"')>type}",
        "string");

    DazScript_Test("json primitive root string cast",
        "{@json('\"hello\"')>string>upper}",
        "HELLO");

    DazScript_Test("json primitive root int type",
        "{@json('123')>type}",
        "int");

    DazScript_Test("json primitive root int cast",
        "{@json('123')>int>incr}",
        "124");

    DazScript_Test("json primitive root float type",
        "{@json('12.5')>type}",
        "float");

    DazScript_Test("json primitive root float cast",
        "{@json('12.5')>float>fixed(1)}",
        "12.5");

    DazScript_Test("json primitive null type",
        "{@json('null')>type}",
        "null");

    DazScript_Test("json root true type bool",
        "{@json('true')>type}",
        "bool");

    DazScript_Test("json root false type bool",
        "{@json('false')>type}",
        "bool");

    DazScript_Test("json scalar bool true",
        "{@json('true')>scalar>bool}",
        "TRUE");

    DazScript_Test("json scalar bool false true",
        "{@json('false')>scalar>bool}",
        "TRUE");

    DazScript_Test("json boolish null false",
        "{@json('null')>bool}",
        "FALSE");

    DazScript_Test("json boolish true true",
        "{@json('true')>bool}",
        "TRUE");

    DazScript_Test("json boolish false false",
        "{@json('false')>bool}",
        "FALSE");

    DazScript_Test("json boolish int zero false",
        "{@json('0')>bool}",
        "FALSE");

    DazScript_Test("json boolish int positive true",
        "{@json('1')>bool}",
        "TRUE");

    DazScript_Test("json boolish int negative true",
        "{@json('-1')>bool}",
        "TRUE");

    DazScript_Test("json boolish float zero false",
        "{@json('0.0')>bool}",
        "FALSE");

    DazScript_Test("json boolish float positive true",
        "{@json('0.25')>bool}",
        "TRUE");

    DazScript_Test("json boolish empty string false",
        "{@json('\"\"')>bool}",
        "FALSE");

    DazScript_Test("json boolish string false false",
        "{@json('\"false\"')>bool}",
        "FALSE");

    DazScript_Test("json boolish string zero false",
        "{@json('\"0\"')>bool}",
        "FALSE");

    DazScript_Test("json boolish string off false",
        "{@json('\"off\"')>bool}",
        "FALSE");

    DazScript_Test("json boolish string null false",
        "{@json('\"null\"')>bool}",
        "FALSE");

    DazScript_Test("json boolish string true true",
        "{@json('\"true\"')>bool}",
        "TRUE");

    DazScript_Test("json boolish string yes true",
        "{@json('\"yes\"')>bool}",
        "TRUE");

    DazScript_Test("json boolish string text true",
        "{@json('\"hello\"')>bool}",
        "TRUE");

    DazScript_Test("json boolish empty array true",
        "{@json('[]')>bool}",
        "TRUE");

    DazScript_Test("json boolish populated array true",
        "{@json('[0]')>bool}",
        "TRUE");

    DazScript_Test("json boolish empty object true",
        "{@json('{{}}')>bool}",
        "TRUE");

    DazScript_Test("json boolish populated object true",
        "{@json('{{\"x\":0}}')>bool}",
        "TRUE");

    DazScript_Test("json primitive null predicate",
        "{@json('null')>isnull>bool}",
        "TRUE");

    DazScript_Test("json primitive object predicate",
        "{@json('{{\"x\":1}}')>isobject>bool}",
        "TRUE");

    DazScript_Test("json primitive array predicate",
        "{@json('[1,2,3]')>isarray>bool}",
        "TRUE");

    DazScript_Test("json isstring true",
        "{@json('\"x\"')>isstring>bool}",
        "TRUE");

    DazScript_Test("json isint true",
        "{@json('123')>isint>bool}",
        "TRUE");

    DazScript_Test("json isinteger true",
        "{@json('123')>isinteger>bool}",
        "TRUE");

    DazScript_Test("json isfloat true",
        "{@json('12.5')>isfloat>bool}",
        "TRUE");

    DazScript_Test("json isnumber int true",
        "{@json('123')>isnumber>bool}",
        "TRUE");

    DazScript_Test("json isnumber float true",
        "{@json('12.5')>isnumber>bool}",
        "TRUE");

    DazScript_Test("json isnumber string false",
        "{@json('\"123\"')>isnumber>bool}",
        "FALSE");

    DazScript_Test("json isbool true",
        "{@json('true')>isbool>bool}",
        "TRUE");

    DazScript_Test("json scalar string true",
        "{@json('\"x\"')>scalar>bool}",
        "TRUE");

    DazScript_Test("json scalar object false",
        "{@json('{{\"x\":1}}')>scalar>bool}",
        "FALSE");

    DazScript_Test("json scalar array false",
        "{@json('[1,2,3]')>scalar>bool}",
        "FALSE");

    DazScript_Test("json primitive bool true unwraps from object",
        "{@json('{{\"flag\":true}}')>get(flag)>bool}",
        "TRUE");

    DazScript_Test("json primitive bool false unwraps from object",
        "{@json('{{\"flag\":false}}')>get(flag)>bool}",
        "FALSE");

    DazScript_Test("json primitive missing key default",
        "{@json('{{\"x\":1}}')>get(missing, fallback)}",
        "fallback");

    DazScript_TestContains("json primitive missing key error",
        "{@json('{{\"x\":1}}')>get(missing)}",
        "JSON_MISSING_KEY:missing");

    DazScript_TestContains("json primitive invalid object syntax",
        "{@json('{{bad}}')}",
        "INVALID_JSON:{bad}");

    DazScript_TestContains("json primitive invalid array trailing comma",
        "{@json('[1,2,]')}",
        "INVALID_JSON:[1,2,]");

    DazScript_Test("json empty null true",
        "{@json('null')>empty>bool}",
        "TRUE");

    DazScript_Test("json empty string true",
        "{@json('\"\"')>empty>bool}",
        "TRUE");

    DazScript_Test("json empty array true",
        "{@json('[]')>empty>bool}",
        "TRUE");

    DazScript_Test("json empty object true",
        "{@json('{{}}')>empty>bool}",
        "TRUE");

    DazScript_Test("json empty populated array false",
        "{@json('[1]')>empty>bool}",
        "FALSE");

    DazScript_Test("json empty populated object false",
        "{@json('{{\"x\":1}}')>empty>bool}",
        "FALSE");

    DazScript_Test("json notempty populated string true",
        "{@json('\"x\"')>notempty>bool}",
        "TRUE");

    DazScript_Test("json notempty int true",
        "{@json('0')>notempty>bool}",
        "TRUE");

    DazScript_Test("json notempty bool false still true",
        "{@json('false')>notempty>bool}",
        "TRUE");

    DazScript_Test("json object keys type array",
        "{@json('{{\"hp\":42,\"name\":\"Daz\"}}')>keys>type}",
        "array");

    DazScript_Test("json object keys length",
        "{@json('{{\"hp\":42,\"name\":\"Daz\"}}')>keys>length}",
        "2");

    DazScript_Test("json object keys first",
        "{@json('{{\"hp\":42}}')>keys>first}",
        "hp");

    DazScript_TestContains("json keys on array error",
        "{@json('[1,2,3]')>keys}",
        "JSON_NOT_OBJECT");

    DazScript_Test("json dump object",
        "{@json('{{\"x\":1}}')>dump}",
        "{\"x\":1}");

    DazScript_Test("json raw array",
        "{@json('[1,2,3]')>raw}",
        "[1,2,3]");

    DazScript_Test("json array first",
        "{@json('[\"a\",\"b\",\"c\"]')>first}",
        "a");

    DazScript_Test("json array last",
        "{@json('[\"a\",\"b\",\"c\"]')>last}",
        "c");

    DazScript_Test("json array first default",
        "{@json('[]')>first(fallback)}",
        "fallback");

    DazScript_Test("json array last default",
        "{@json('[]')>last(fallback)}",
        "fallback");

    DazScript_TestContains("json array first empty error",
        "{@json('[]')>first}",
        "JSON_INDEX_OUT_OF_RANGE:0");

    DazScript_TestContains("json first on object error",
        "{@json('{{\"x\":1}}')>first}",
        "JSON_NOT_ARRAY");

    DazScript_Test("json unquoted true casts to json int",
        "{@json(true)>type}",
        "int");

    DazScript_Test("array sort asc",
        "{@json('[3,1,2]')>sort>join(',')}",
        "1,2,3");

    DazScript_Test("array sort desc",
        "{@json('[3,1,2]')>sort(desc)>join(',')}",
        "3,2,1");

    DazScript_Test("array reverse",
        "{@json('[1,2,3]')>reverse>join(',')}",
        "3,2,1");

    DazScript_Test("array unique preserves order",
        "{@json('[2,1,2,3,1]')>unique>join(',')}",
        "2,1,3");

    DazScript_Test("array coalesce",
        "{@json('[null,null,\"fallback\"]')>coalesce}",
        "fallback");

    DazScript_Test("array coalesce keeps zero",
        "{@json('[null,0,\"fallback\"]')>coalesce}",
        "0");

    DazScript_TestContains("array sort bad direction",
        "{@json('[1,2,3]')>sort(sideways)}",
        "SORT_DIRECTION_INVALID:sideways");
}

void DazScript_TestForeach()
{
    DazScript_Test("foreach array values",
        "{@foreach({@json('[\"a\",\"b\",\"c\"]')}, $v, '{$v}')}",
        "abc");

    DazScript_Test("foreach array index and value",
        "{@foreach({@json('[\"a\",\"b\"]')}, $i, $v, '{$i}:{$v};')}",
        "0:a;1:b;");

    DazScript_Test("foreach empty array returns empty string",
        "{@foreach({@json('[]')}, $v, bad)}",
        "");

    DazScript_Test("foreach stringified json array",
        "{@foreach('[1,2,3]', $v, '{$v}')}",
        "123");

    DazScript_Test("foreach object value only",
        "{@foreach({@json('{{\"x\":42}}')}, $v, '{$v}')}",
        "42");

    DazScript_Test("foreach object key and value",
        "{@foreach({@json('{{\"hp\":42}}')}, $key, $value, '{$key}={$value};')}",
        "hp=42;");

    DazScript_Test("foreach object key property chain",
        "{@foreach({@json('{{\"name\":\"Daz\"}}')}, $key, $value, '{$key>capitalize}={$value};')}",
        "Name=Daz;");

    DazScript_Test("foreach row json direct access",
        "{@foreach({@json('[{{\"id\":1,\"name\":\"Ann\"}},{{\"id\":2,\"name\":\"Bob\"}}]')}, $row, '{$row>get(id)}:{$row>get(name)};')}",
        "1:Ann;2:Bob;");

    DazScript_Test("foreach nested same-quote parser",
        "{@foreach({@json('[{{\"id\":1}},{{\"id\":2}}]')}, $row, '{@foreach({$row}, $key, $value, '{$key}={$value};')}\n')}",
        "id=1;\nid=2;\n");

    DazScript_Test("foreach nested output can be chained",
        "{@foreach({@json('[{{\"x\":1}}]')}, $row, '{@foreach({$row}, $key, $value, ' {$key} = {$value} ')>trim}')}",
        "x = 1");

    DazScript_Test("foreach alias type follows json scalar",
        "{@foreach({@json('[\"s\",7]')}, $v, '{@type($v)};')}",
        "alias:string;alias:int;");

    DazScript_Test("foreach alias does not leak",
        "{@foreach({@json('[1]')}, $v, '{$v}')}{@exists($v)>bool}",
        "1FALSE");

    DazScript_Test("foreach nested alias shadow does not leak",
        "{@foreach({@json('[1,2]')}, $v, '{@foreach({@json('[\"a\",\"b\"]')}, $v, '{$v}')}:{$v};')}",
        "ab:1;ab:2;");

    DazScript_TestContains("foreach rejects scalar json",
        "{@foreach({@json('7')}, $v, '{$v}')}",
        "FOREACH_JSON_NOT_ARRAY_OR_OBJECT");

    DazScript_TestContains("foreach requires value alias",
        "{@foreach({@json('[1]')}, v, '{$v}')}",
        "FOREACH_VALUE_ALIAS_IS_NON_ALIAS:v");

    DazScript_TestContains("foreach requires key alias",
        "{@foreach({@json('{{\"x\":1}}')}, key, $value, '{$value}')}",
        "FOREACH_KEY_ALIAS_IS_NON_ALIAS:key");

    DazScript_TestContains("foreach usage error",
        "{@foreach({@json('[1]')}, $v)}",
        "FOREACH_USAGE:@foreach(collection,$value,body) OR @foreach(collection,$key,$value,body)");
}

void DazScript_TestMoreJsonLikeCollectionOrAggregate()
{
    DazScript_Test("map array doubles ints",
        "{@map({@json('[1,2,3]')}, $v, {@mul({$v}, 2)})>raw}",
        "[2,4,6]");

    DazScript_Test("map array index and value",
        "{@map({@json('[\"a\",\"b\"]')}, $i, $v, '{$i}:{$v}')>raw}",
        "[\"0:a\",\"1:b\"]");

    DazScript_Test("map preserves string results as json strings",
        "{@map({@json('[1,2]')}, $v, 'item {$v}')>raw}",
        "[\"item 1\",\"item 2\"]");

    DazScript_Test("map preserves object results as json objects",
        "{@map({@json('[{{\"x\":1}},{{\"x\":2}}]')}, $row, {$row})>length}",
        "2");

    DazScript_Test("map empty array returns empty array",
        "{@map({@json('[]')}, $v, bad)>raw}",
        "[]");

    DazScript_Test("filter keeps values with true predicate",
        "{@filter({@json('[1,2,3,4,5]')}, $v, {$v>gt(2)})>raw}",
        "[3,4,5]");

    DazScript_Test("filter preserves original values",
        "{@filter({@json('[{{\"name\":\"Ann\",\"gold\":100}},{{\"name\":\"Bob\",\"gold\":600}}]')}, $row, {$row>get(gold)>lt(500)})>at(0)>get(name)}",
        "Ann");

    DazScript_Test("filter index alias",
        "{@filter({@json('[\"a\",\"b\",\"c\",\"d\"]')}, $i, $v, {$i>odd})>raw}",
        "[\"b\",\"d\"]");

    DazScript_Test("filter empty array returns empty array",
        "{@filter({@json('[]')}, $v, bad)>raw}",
        "[]");

    DazScript_Test("reduce sums ints",
        "{@reduce({@json('[1,2,3,4]')}, 0, $sum, $v, {@add({$sum}, {$v})})}",
        "10");

    DazScript_Test("reduce concatenates strings",
        "{@reduce({@json('[\"a\",\"b\",\"c\"]')}, '', $out, $v, '{$out}{$v}')}",
        "abc");

    DazScript_Test("reduce index alias",
        "{@reduce({@json('[10,20,30]')}, 0, $sum, $i, $v, {@add({$sum}, {$i})})}",
        "3");

    DazScript_Test("reduce empty array returns initial value",
        "{@reduce({@json('[]')}, 42, $sum, $v, {@add({$sum}, {$v})})}",
        "42");

    DazScript_Test("sum numeric array",
        "{@sum({@json('[1,2,3,4]')})}",
        "10");

    DazScript_Test("sum selector",
        "{@sum({@json('[{{\"gold\":100}},{{\"gold\":250}}]')}, $row, {$row>get(gold)})}",
        "350");

    DazScript_Test("sum index alias",
        "{@sum({@json('[10,20,30]')}, $i, $v, {$i})}",
        "3");

    DazScript_Test("sum float array",
        "{@sum({@json('[1.5,2.5]')})>fixed(1)}",
        "4.0");

    DazScript_Test("avg numeric array",
        "{@avg({@json('[2,4,6]')})>fixed(1)}",
        "4.0");

    DazScript_Test("avg selector",
        "{@avg({@json('[{{\"gold\":100}},{{\"gold\":300}}]')}, $row, {$row>get(gold)})>fixed(1)}",
        "200.0");

    DazScript_Test("count array",
        "{@count({@json('[1,2,3]')})}",
        "3");

    DazScript_Test("count predicate",
        "{@count({@json('[1,2,3,4,5]')}, $v, {$v>gt(2)})}",
        "3");

    DazScript_Test("count index alias",
        "{@count({@json('[\"a\",\"b\",\"c\",\"d\"]')}, $i, $v, {$i>odd})}",
        "2");

    DazScript_TestContains("sum rejects non numeric",
        "{@sum({@json('[1,\"x\"]')})}",
        "SUM_VALUE_NOT_NUMERIC");

    DazScript_TestContains("avg empty array errors",
        "{@avg({@json('[]')})}",
        "AVG_EMPTY_ARRAY");

    DazScript_TestContains("count rejects scalar json",
        "{@count({@json('7')})}",
        "COUNT_JSON_NOT_ARRAY");

    DazScript_TestContains("sum requires value alias",
        "{@sum({@json('[1]')}, v, {$v})}",
        "SUM_VALUE_ALIAS_IS_NON_ALIAS:v");

    DazScript_Test("join default separator",
        "{@json('[\"a\",\"b\",\"c\"]')>join}",
        "abc");

    DazScript_Test("join custom separator",
        "{@json('[\"a\",\"b\",\"c\"]')>join(', ')}",
        "a, b, c");

    DazScript_Test("join newline separator",
        "{@json('[\"a\",\"b\"]')>join('\n')}",
        "a\nb");

    DazScript_Test("join empty array returns empty string",
        "{@json('[]')>join(', ')}",
        "");

    DazScript_Test("map filter reduce join sql composition",
        "{@set($rows,{@sqlmodule('SELECT name, gold FROM test_players ORDER BY id;')>rows(si)})}" +
        "{@set($rich,{@filter({$rows}, $row, {$row>get(gold)>gte(400)})})}" +
        "{@map({$rich}, $row, '{$row>get(name)}={$row>get(gold)}')>join('|')} " +
        "total={@reduce({$rich}, 0, $sum, $row, {@add({$sum}, {$row>get(gold)})})}",
        "Test Player 2=475|Test Player 3=475 total=950");

    DazScript_TestContains("map rejects scalar json",
        "{@map({@json('7')}, $v, {$v})}",
        "MAP_JSON_NOT_ARRAY");

    DazScript_TestContains("map requires value alias",
        "{@map({@json('[1]')}, v, {$v})}",
        "MAP_VALUE_ALIAS_IS_NON_ALIAS:v");

    DazScript_TestContains("map usage error",
        "{@map({@json('[1]')}, $v)}",
        "MAP_USAGE:@map(array,$value,body) OR @map(array,$index,$value,body)");

    DazScript_TestContains("filter rejects scalar json",
        "{@filter({@json('7')}, $v, {$v})}",
        "FILTER_JSON_NOT_ARRAY");

    DazScript_TestContains("filter requires value alias",
        "{@filter({@json('[1]')}, v, {$v})}",
        "FILTER_VALUE_ALIAS_IS_NON_ALIAS:v");

    DazScript_TestContains("filter usage error",
        "{@filter({@json('[1]')}, $v)}",
        "FILTER_USAGE:@filter(array,$value,predicate) OR @filter(array,$index,$value,predicate)");

    DazScript_TestContains("reduce rejects scalar json",
        "{@reduce({@json('7')}, 0, $sum, $v, {$sum})}",
        "REDUCE_JSON_NOT_ARRAY");

    DazScript_TestContains("reduce requires accumulator alias",
        "{@reduce({@json('[1]')}, 0, sum, $v, {$v})}",
        "REDUCE_ACCUMULATOR_ALIAS_IS_NON_ALIAS:sum");

    DazScript_TestContains("reduce usage error",
        "{@reduce({@json('[1]')}, 0, $sum, $v)}",
        "REDUCE_USAGE:@reduce(array,initial,$acc,$value,body) OR @reduce(array,initial,$acc,$index,$value,body)");

    DazScript_TestContains("join rejects object",
        "{@json('{{\"x\":1}}')>join(',')}",
        "JSON_NOT_ARRAY");

    DazScript_Test("sortby int asc",
        "{@sortby({@json('[3,1,2]')},$v,{$v})>join(',')}",
        "1,2,3");

    DazScript_Test("sortby int desc",
        "{@sortby({@json('[3,1,2]')},$v,{$v},desc)>join(',')}",
        "3,2,1");

    DazScript_Test("sortby index alias",
        "{@sortby({@json('[3,1,2]')},$i,$v,{$i},desc)>join(',')}",
        "2,1,3");

    DazScript_Test("sortby object int key",
        "{@map({@sortby({@json('[{{\"n\":\"b\",\"g\":2}},{{\"n\":\"a\",\"g\":1}}]')},$row,{$row>get(g)})},$row,{$row>get(n)})>join(',')}",
        "a,b");

    DazScript_Test("sortby object string key",
        "{@map({@sortby({@json('[{{\"n\":\"b\"}},{{\"n\":\"a\"}}]')},$row,{$row>get(n)})},$row,{$row>get(n)})>join(',')}",
        "a,b");

    DazScript_TestContains("sortby usage",
        "{@sortby({@json('[1,2,3]')})}",
        "SORTBY_USAGE");

    DazScript_TestContains("sortby duplicate alias",
        "{@sortby({@json('[1,2,3]')},$x,$x,{$x})}",
        "SORTBY_DUPLICATE_ALIAS:$x");

    DazScript_TestContains("sortby bad direction",
        "{@sortby({@json('[1,2,3]')},$v,{$v},sideways)}",
        "SORTBY_DIRECTION_INVALID:sideways");

    DazScript_Test("sortby stable equal keys",
        "{@map({@sortby({@json('[{{\"n\":\"a\",\"g\":1}},{{\"n\":\"b\",\"g\":1}},{{\"n\":\"c\",\"g\":2}}]')},$row,{$row>get(g)})},$row,{$row>get(n)})>join(',')}",
        "a,b,c");

    DazScript_TestContains("sortby mixed key types",
        "{@sortby({@json('[1,\"2\"]')},$v,{$v})}",
        "SORTBY_MIXED_KEY_TYPES");

    DazScript_Test("sortby raw alias key desc",
        "{@sortby({@json('[3,1,2]')},$v,$v,desc)>join(',')}",
        "3,2,1");

    DazScript_Test("sortby raw alias key asc",
        "{@sortby({@json('[3,1,2]')},$v,$v,asc)>join(',')}",
        "1,2,3");

    DazScript_Test("sortby index alias still works",
        "{@sortby({@json('[3,1,2]')},$i,$v,{$i},desc)>join(',')}",
        "2,1,3");
}

void DazScript_TestParserWhitespace()
{
    DazScript_Test("parser trims expression whitespace",
        "{ @string( hello ) }",
        "hello");

    DazScript_Test("parser trims meta name whitespace",
        "{ @int( 123 ) > int }",
        "123");

    DazScript_Test("parser trims property whitespace",
        "{ @int( 150 ) > clamp( 0, 100 ) > int }",
        "100");

    DazScript_Test("quoted param ignores leading syntax space",
        "{@string( 'hello')}",
        "hello");

    DazScript_Test("quoted param ignores trailing syntax space",
        "{@string('hello' )}",
        "hello");

    DazScript_Test("quoted param preserves intentional spaces",
        "{@string('  hello  ')}",
        "  hello  ");

    DazScript_Test("quoted param preserves comma",
        "{@string('a,b,c')}",
        "a,b,c");

    DazScript_Test("quoted param preserves parens and comma",
        "{@string('a (b), c')}",
        "a (b), c");

    DazScript_Test("param quoted empty string",
        "{@string('')}",
        "");

    DazScript_Test("param quoted spaces only",
        "{@string('   ')}",
        "   ");
}

void DazScript_TestStringProperties()
{
    string sText = "hello";
    string sEmpty = "";

    DazScript_Test("property chain whitespace",
        "{ sText > upper > lower > capitalize }",
        "Hello");

    DazScript_Test("string trim property",
        "{@string('  hello  ')>trim}",
        "hello");

    DazScript_Test("string append quoted leading data",
        "{sText>append(' world')}",
        "hello world");

    DazScript_Test("string prepend quoted trailing data",
        "{sText>prepend('say ')}",
        "say hello");

    DazScript_Test("string substring",
        "{sText>substring(1, 3)}",
        "ell");

    DazScript_Test("string left",
        "{sText>left(2)}",
        "he");

    DazScript_Test("string right",
        "{sText>right(2)}",
        "lo");

    DazScript_Test("string contains",
        "{sText>contains('ell')>bool}",
        "TRUE");

    DazScript_Test("string startswith",
        "{sText>startswith('he')>bool}",
        "TRUE");

    DazScript_Test("string endswith",
        "{sText>endswith('lo')>bool}",
        "TRUE");

    DazScript_Test("string empty",
        "{sEmpty>empty>bool}",
        "TRUE");

    DazScript_Test("string notempty",
        "{sText>notempty>bool}",
        "TRUE");

    DazScript_Test("padleft with quoted pad char",
        "{sText>padleft(7, '.')}",
        "..hello");

    DazScript_Test("padright with quoted pad char",
        "{sText>padright(7, '.')}",
        "hello..");
}

void DazScript_TestParserErrors()
{
    string m = "5";

    DazScript_Test("parser allows quoted closing brace",
        "{@string('}')}",
        "}");

    DazScript_Test("parser allows quoted property delimiter",
        "{m>append('>tail')}",
        "5>tail");

    DazScript_TestContains("parser error trailing property call text",
        "{m>string>eq(5)aa}",
        "PARSE_ERROR:TRAILING_TEXT_AFTER_PROPERTY_CALL:IN_eq");

    DazScript_TestContains("parser error trailing property call context",
        "{m>string>eq(5)aa}",
        "NEAR:eq(5)[a]a");

    DazScript_TestContains("parser error unterminated property call",
        "{m>string>eq(}",
        "PARSE_ERROR:UNTERMINATED_PROPERTY_CALL:IN_eq");

    DazScript_TestContains("parser error trailing text after quoted arg",
        "{@string('hello'wat)}",
        "PARSE_ERROR:TRAILING_TEXT_AFTER_QUOTED_ARGUMENT:IN_string");

    DazScript_TestContains("parser error unterminated template expression",
        "Hello {@string('unterminated)}",
        "PARSE_ERROR:UNTERMINATED_TEMPLATE_EXPR:IN_template");

    DazScript_TestContains("parser error preserved through function call",
        "{@fn(#echo, $x, {$x})}{#echo('hello'wat)}",
        "PARSE_ERROR:TRAILING_TEXT_AFTER_QUOTED_ARGUMENT:IN_#echo");

    DazScript_TestNotContains("parser error not wrapped as invalid property chain",
        "{m>string>eq(5)aa}",
        "INVALID_PROPERTY_CHAIN");

    DazScript_TestContains("parser error trailing comma meta arg",
        "{@add(1, 2,)}",
        "PARSE_ERROR:TRAILING_COMMA_IN_ARGUMENT_LIST:IN_add");

    DazScript_TestContains("parser error trailing comma property arg",
        "{@int(5)>clamp(0, 10,)}",
        "PARSE_ERROR:TRAILING_COMMA_IN_ARGUMENT_LIST:IN_clamp");

    DazScript_TestContains("parser error trailing comma function arg",
        "{@fn(#echo, $x, {$x})}{#echo(test,)}",
        "PARSE_ERROR:TRAILING_COMMA_IN_ARGUMENT_LIST:IN_#echo");

    DazScript_TestContains("parser error preserved through function body",
        "{@fn(#bad, $x, 'Hello {$x')}",
        "PARSE_ERROR:UNTERMINATED_TEMPLATE_EXPR:IN_function_body");

    DazScript_TestNotContains("parser error function body not invalid body",
        "{@fn(#bad, $x, 'Hello {$x')}",
        "INVALID_FUNCTION_BODY");

    DazScript_TestContains("parser eof context unterminated meta call",
        "{@string(}",
        "PARSE_ERROR:UNTERMINATED_PROPERTY_CALL:IN_string");

    DazScript_TestContains("parser eof context shows eof for meta call",
        "{@string(}",
        "NEAR:string([<eof>]");

    DazScript_TestContains("parser eof context unterminated property call",
        "{m>string>eq(}",
        "PARSE_ERROR:UNTERMINATED_PROPERTY_CALL:IN_eq");

    DazScript_TestContains("parser eof context shows eof for property call",
        "{m>string>eq(}",
        "NEAR:eq([<eof>]");
}

void DazScript_TestParserEvil()
{
    string m = "5";

    DazScript_TestContains("evil base meta trailing call text",
        "{@string(ok)wat}",
        "PARSE_ERROR:TRAILING_TEXT_AFTER_PROPERTY_CALL:IN_string");

    DazScript_TestContains("evil unknown meta malformed call gives parse first",
        "{@doesnotexist(}",
        "PARSE_ERROR:UNTERMINATED_PROPERTY_CALL:IN_doesnotexist");

    DazScript_TestContains("evil function trailing call text",
        "{@fn(#echo, $x, {$x})}{#echo(ok)wat}",
        "PARSE_ERROR:TRAILING_TEXT_AFTER_PROPERTY_CALL:IN_#echo");

    DazScript_TestContains("evil function unterminated call",
        "{@fn(#echo, $x, {$x})}{#echo(}",
        "PARSE_ERROR:UNTERMINATED_PROPERTY_CALL:IN_#echo");

    DazScript_Test("evil escaped single quote in quoted arg",
        "{@string('a\\'b')}",
        "a'b");

    DazScript_Test("evil escaped backslash in quoted arg",
        "{@string('a\\\\b')}",
        "a\\b");

    DazScript_TestContains("evil escaped quote still catches trailing text",
        "{@string('a\\'b'wat)}",
        "PARSE_ERROR:TRAILING_TEXT_AFTER_QUOTED_ARGUMENT:IN_string");

    DazScript_Test("evil quoted syntax soup remains literal",
        "{@string('a,b,(c)>d}')}",
        "a,b,(c)>d}");

    DazScript_Test("evil property delimiter inside nested expression arg",
        "{m>append({@string('>tail')})}",
        "5>tail");

    DazScript_TestContains("evil nested parse error in property arg bubbles",
        "{m>append({@string(ok)wat})}",
        "PARSE_ERROR:TRAILING_TEXT_AFTER_PROPERTY_CALL:IN_string");

    DazScript_TestContains("evil selected lazy branch surfaces parse error",
        "{@if(FALSE, ok, {@string(bad)wat})}",
        "PARSE_ERROR:TRAILING_TEXT_AFTER_PROPERTY_CALL:IN_string");

    DazScript_Test("evil unselected lazy branch ignores parse error",
        "{@if(TRUE, ok, {@string(bad)wat})}",
        "ok");

    DazScript_Test("evil and short-circuit ignores parse error",
        "{@and(FALSE, {@string(bad)wat})>bool}",
        "FALSE");

    DazScript_Test("evil or short-circuit ignores parse error",
        "{@or(TRUE, {@string(bad)wat})>bool}",
        "TRUE");

    DazScript_TestContains("evil trailing property delimiter is parse error",
        "{m>string>}",
        "PARSE_ERROR:EMPTY_PROPERTY_SEGMENT");

    DazScript_TestContains("evil double property delimiter is parse error",
        "{m>string>>upper}",
        "PARSE_ERROR:EMPTY_PROPERTY_SEGMENT");

    DazScript_TestContains("evil empty template expression is parse error",
        "{}",
        "PARSE_ERROR:EMPTY_TEMPLATE_EXPR");

    DazScript_TestContains("evil empty base expression is parse error",
        "{>upper}",
        "PARSE_ERROR:EMPTY_BASE_EXPR");

    DazScript_TestContains("evil empty meta name is parse error",
        "{@}",
        "PARSE_ERROR:EMPTY_META_NAME");

    DazScript_TestContains("evil empty meta call name is parse error",
        "{@()}",
        "PARSE_ERROR:EMPTY_META_NAME");

    DazScript_TestContains("evil empty function name is parse error",
        "{#}",
        "PARSE_ERROR:EMPTY_FUNCTION_NAME");

    DazScript_TestContains("evil empty function call name is parse error",
        "{#()}",
        "PARSE_ERROR:EMPTY_FUNCTION_NAME");

    DazScript_TestContains("evil empty alias name is parse error",
        "{$}",
        "PARSE_ERROR:EMPTY_ALIAS_NAME");

    DazScript_TestContains("evil unexpected closing paren in base is parse error",
        "{m)}",
        "PARSE_ERROR:UNEXPECTED_CLOSING_PAREN");

    DazScript_TestNotContains("evil property parse error not invalid chain",
        "{m>string>append(x)wat}",
        "INVALID_PROPERTY_CHAIN");

    DazScript_TestNotContains("evil nested parse error not invalid chain",
        "{m>append({@string(ok)wat})}",
        "INVALID_PROPERTY_CHAIN");

    DazScript_Test("evil canonical operator ignored inside quoted property arg",
        "{m>append('a>b')}",
        "5a>b");

    DazScript_Test("evil parens inside quoted property arg",
        "{m>append('(x,y)')}",
        "5(x,y)");

    DazScript_Test("evil comma inside quoted meta arg",
        "{@string('a,b')}",
        "a,b");

    DazScript_TestContains("evil unmatched paren in property call",
        "{m>append((x)}",
        "PARSE_ERROR:UNTERMINATED_PROPERTY_CALL:IN_append");

    DazScript_TestContains("evil unmatched paren in meta call",
        "{@string((x)}",
        "PARSE_ERROR:UNTERMINATED_PROPERTY_CALL:IN_string");

    DazScript_Test("evil comma inside nested expression arg",
        "{@string('a,b')>append(c)}",
        "a,bc");
}

void DazScript_TestMetaVars()
{
    DazScript_Test("set alias with whitespace",
        "{ @set( $x, 123 ) }{ $x }",
        "123");

    DazScript_Test("set quoted alias preserves spaces",
        "{@set($x, '  padded  ')}{$x}",
        "  padded  ");

    DazScript_Test("alias increment",
        "{@set($x, 5)}{$x>incr}",
        "6");

    DazScript_Test("alias decrement",
        "{@set($x, 5)}{$x>decr}",
        "4");

    DazScript_Test("exists alias true",
        "{@set($x, 123)}{@exists($x)>bool}",
        "TRUE");

    DazScript_Test("unset alias",
        "{@set($x, 123)}{@unset($x)}{@exists($x)>bool}",
        "FALSE");

    DazScript_Test("type int alias",
        "{@set($x, 123)}{@type($x)}",
        "alias:int");

    DazScript_Test("type float alias",
        "{@set($x, 12.5)}{@type($x)}",
        "alias:float");

    DazScript_Test("type string alias",
        "{@set($x, abc)}{@type($x)}",
        "alias:string");

    DazScript_Test("cast alias to string",
        "{@set($x, 123)}{@cast($x, string)}{@type($x)}",
        "alias:string");

    DazScript_Test("cast alias string to json type",
        "{@set($x, '{{\"hp\":42}}')}{@cast($x, json)}{@type($x)}",
        "alias:json");

    DazScript_Test("cast alias string to json access",
        "{@set($x, '{{\"hp\":42}}')}{@cast($x, json)}{$x>get(hp)}",
        "42");

    DazScript_Test("cast alias shorthand j to json",
        "{@set($x, '{{\"hp\":42}}')}{@cast($x, j)}{$x>get(hp)}",
        "42");

    DazScript_Test("cast alias int to json root type",
        "{@set($x, 5)}{@cast($x, json)}{$x>type}",
        "int");

    DazScript_TestContains("cast alias invalid json string",
        "{@set($x, '{{bad}}')}{@cast($x, json)}",
        "INVALID_JSON:{bad}");

    DazScript_Test("plural full sentence plural",
        "{@set($count,2)}{$count>plural( 'There is {$count} player online.', 'There are {$count} players online.')}",
        "There are 2 players online.");

    DazScript_Test("plural full sentence singular",
        "{@set($count,1)}{$count>plural( 'There is {$count} player online.', 'There are {$count} players online.' )}",
        "There is 1 player online.");

    DazScript_Test("plural suffix singular",
        "{@int(1)>plural(s)}",
        "");

    DazScript_Test("plural suffix plural",
        "{@int(2)>plural(s)}",
        "s");

    DazScript_Test("then true branch",
        "{@int(1)>then(yes, no)}",
        "yes");

    DazScript_Test("then false branch",
        "{@int(0)>then(yes, no)}",
        "no");

    DazScript_Test("let scoped alias",
        "{@let($x, 123, {$x})}",
        "123");

    DazScript_Test("let alias does not leak",
        "{@let($x, 123, {$x})}{@exists($x)>bool}",
        "123FALSE");

    DazScript_Test("let shadows outer alias",
        "{@set($x, outer)}{@let($x, inner, {$x})}:{$x}",
        "inner:outer");

    DazScript_Test("let sequential bindings",
        "{@let($a, 2, $b, {$a>incr}, '{$a},{$b}')}",
        "2,3");

    DazScript_Test("let inner set remains scoped",
        "{@set($x, outer)}{@let($x, inner, {@set($x, changed)}{$x})}:{$x}",
        "changed:outer");

    DazScript_TestContains("let requires alias syntax",
        "{@let(x, 1, body)}",
        "LET_ALIAS_IS_NON_ALIAS:x");

    DazScript_TestContains("let requires odd argument count",
        "{@let($x, 1, $y, 2)}",
        "LET_EXPECTS_BINDINGS_PLUS_BODY");

    DazScript_Test("try primary success",
        "{@try(ok, fallback)}",
        "ok");

    DazScript_Test("try catches missing var",
        "{@try({missingVar}, fallback)}",
        "fallback");

    DazScript_Test("try catches bad property chain",
        "{@try({@int(5)>nosuchproperty}, fallback)}",
        "fallback");

    DazScript_Test("try variadic fallback",
        "{@try({missingVar}, {@int(5)>bad}, final)}",
        "final");

    DazScript_TestContains("try all branches failed returns last error",
        "{@try({missingVar}, {@int(5)>bad})}",
        "INVALID_PROPERTY_CHAIN");

    DazScript_TestContains("set returns rhs error",
        "{@set($x, {@div(1, 0)})}",
        "DIVISION_BY_ZERO");

    DazScript_Test("set error does not create alias",
        "{@try({@set($x, {@div(1, 0)})}, caught)}:{@exists($x)>bool}",
        "caught:FALSE");

    DazScript_Test("set error leaves existing alias unchanged",
        "{@set($x, ok)}{@try({@set($x, {@div(1, 0)})}, caught)}:{$x}",
        "caught:ok");
}

void DazScript_TestRender()
{
    string sName = "Daz";
    string sTemplate = "Hello {sName}";

    DazScript_Test("render basic stack var",
        "{sTemplate>render}",
        "Hello Daz");

    string sNested = "{sTemplate>render}!";
    DazScript_Test("render nested partial",
        "{sNested>render}",
        "Hello Daz!");

    string sInt = "{@add(2, 3)}";
    DazScript_Test("render preserves typed int result",
        "{@add({sInt>render}, 10)}",
        "15");

    string sPlain = "plain text";
    DazScript_Test("render plain string",
        "{sPlain>render}",
        "plain text");

    string sBad = "{$row>get(gol)}";
    DazScript_TestContains("render missing key bubbles context",
        "{@map({@json('[{{\"gold\":5}}]')}, $row, {sBad>render})}",
        "JSON_MISSING_KEY:gol");

    string sBroken = "{$row>get(gold)";
    DazScript_TestContains("render parse error bubbles",
        "{@map({@json('[{{\"gold\":5}}]')}, $row, {sBroken>render})}",
        "PARSE_ERROR:UNTERMINATED_TEMPLATE_EXPR");

    string sGold = "{$row>get(gold)}";
    string sLine = "{@let($gold,{sGold>render},Gold={$gold})}";

    DazScript_Test("render inside map preserves row alias",
        "{@map({@json('[{{\"gold\":5}},{{\"gold\":7}}]')}, $row, {sLine>render})>join('|')}",
        "Gold=5|Gold=7");

    string sGoldLet = "{@let($gold,5,Gold={$gold})}";
    DazScript_Test("render let alias does not leak",
        "{sGoldLet>render}{@exists($gold)>bool}",
        "Gold=5FALSE");

    string sUnusedBad = "{@string(bad)wat}";
    DazScript_Test("render lazy unselected branch ignored",
        "{@if(TRUE, ok, {sUnusedBad>render})}",
        "ok");

    string sPluralOne = "{@string(bad)wat}";
    string sPluralMany = "many";

    DazScript_Test("render plural lazy selected branch only",
        "{@int(2)>plural({sPluralOne>render}, {sPluralMany>render})}",
        "many");

    string sObj = "{@json('{{\"name\":\"Daz\"}}')}";
    DazScript_Test("render preserves json result",
        "{sObj>render>get(name)}",
        "Daz");
}

void DazScript_TestFunctionParams()
{
    DazScript_Test("function trims unquoted args",
        "{@fn(#pair, $a, $b, {$a}:{$b})}{#pair( left , right )}",
        "left:right");

    DazScript_Test("function preserves quoted arg spaces",
        "{@fn(#wrap, $x, [{$x}])}{#wrap( ' x ' )}",
        "[ x ]");

    DazScript_Test("function body property chain",
        "{@fn(#lower, $x, {$x>lower})}{#lower(HeLLo)}",
        "hello");

    DazScript_Test("function nested expression arg",
        "{@fn(#show, $x, value={$x})}{#show({@add(2, 3)})}",
        "value=5");

    DazScript_Test("function can use alias from caller stack",
        "{@set($prefix, Hello)}{@fn(#greet, $name, {$prefix} {$name})}{#greet(Daz)}",
        "Hello Daz");

    DazScript_Test("function quoted numeric arg remains string",
        "{@fn(#showtype, $x, {@type($x)}|{$x})}{#showtype('12.50')}",
        "alias:string|12.50");

    DazScript_Test("function unquoted numeric arg remains float",
        "{@fn(#showtype, $x, {@type($x)}|{$x>fixed(1)})}{#showtype(12.50)}",
        "alias:float|12.5");
}

void DazScript_TestLazy()
{
    string sOut = "";

    DazScript_Test("if lazy false branch",
        "{@if(TRUE, ok, {@out(sOut,bad)})}|{sOut}",
        "ok|");

    sOut = "";
    DazScript_Test("or lazy unused branch",
        "{@or(TRUE, {@out(sOut,bad)})>bool}|{sOut}",
        "TRUE|");

    sOut = "";
    DazScript_Test("and lazy unused branch",
        "{@and(FALSE, {@out(sOut,bad)})>bool}|{sOut}",
        "FALSE|");

    sOut = "";
    DazScript_Test("try lazy fallback skipped on success",
        "{@try(ok, {@out(sOut,bad)})}|{sOut}",
        "ok|");

    sOut = "";
    DazScript_Test("try fallback evaluated on failure",
        "{@try({missingVar}, {@out(sOut,changed)}fallback)}|{sOut}",
        "fallback|changed");
}

void DazScript_TestControlFlow()
{
    DazScript_Test("switch matched case",
        "{@switch(b, a, no, b, yes, fallback)}",
        "yes");

    DazScript_Test("switch default case",
        "{@switch(c, a, no, b, no, fallback)}",
        "fallback");

    DazScript_Test("switch no match and no default",
        "{@switch(c, a, no, b, no)}",
        "");

    DazScript_Test("while accumulates body output",
        "{@set($i,0)}{@while({$i>lt(3)}, {@set($i, {$i>incr})}{$i})}",
        "123");

    DazScript_Test("do returns last value",
        "{@do(1, 2, 3)}",
        "3");

    DazScript_Test("do sequences set",
        "{@do({@set($x, 1)}, {@set($x, {@add({$x}, 1)})}, {$x})}",
        "2");

    DazScript_Test("do preserves int return",
        "{@add({@do({@set($x, 1)}, 2)}, 3)}",
        "5");

    DazScript_TestContains("do stops on error",
        "{@do(1, {@div(1, 0)}, 3)}",
        "DIVISION_BY_ZERO");

    DazScript_Test("do in while body",
        "{@set($i, 0)}{@while({$i>lt(3)}, {@do({@set($out, {$i})}, {@set($i, {$i>incr})}, {$out})})}",
        "012");

    DazScript_Test("all alias for and",
        "{@all(TRUE, yes, 1)>bool}",
        "TRUE");

    DazScript_Test("any alias for or",
        "{@any(FALSE, 0, yes)>bool}",
        "TRUE");

    DazScript_TestContains("while default iteration limit errors",
        "{@while(TRUE, x)}",
        "WHILE_ITERATION_LIMIT");

    DazScript_TestContains("while explicit iteration limit errors",
        "{@set($i, 0)}{@while({$i>lt(5)}, {@set($i, {$i>incr})}, 2)}",
        "WHILE_ITERATION_LIMIT");

    DazScript_Test("while completes before explicit limit",
        "{@set($i, 0)}{@while({$i>lt(3)}, {@set($i, {$i>incr})}{$i}, 5)}",
        "123");

    string sWhileOut = "";

    DazScript_TestContains("while zero limit errors immediately",
        "{@while(TRUE, {@out(sWhileOut, bad)}, 0)}",
        "WHILE_ITERATION_LIMIT");

    DazScript_TestStateString("while zero limit skips body",
        sWhileOut,
        "");
}

void DazScript_TestMath()
{
    DazScript_Test("math sub int",
        "{@sub(10, 3)}",
        "7");

    DazScript_Test("math mul int",
        "{@mul(4, 3)}",
        "12");

    DazScript_Test("math div float",
        "{@div(7, 2)>fixed(1)}",
        "3.5");

    DazScript_Test("math idiv int",
        "{@idiv(7, 2)}",
        "3");

    DazScript_Test("math mod",
        "{@mod(7, 4)}",
        "3");

    DazScript_Test("math clamp meta int",
        "{@clamp(150, 0, 100)}",
        "100");

    DazScript_Test("math clamp meta float",
        "{@clamp(12.5, 0.0, 10.0)>fixed(1)}",
        "10.0");

    DazScript_Test("random equal bounds deterministic",
        "{@random(5, 5)}",
        "5");

    DazScript_Test("int abs",
        "{@int(-5)>abs}",
        "5");

    DazScript_Test("int even false",
        "{@int(5)>even>bool}",
        "FALSE");

    DazScript_Test("int odd true",
        "{@int(5)>odd>bool}",
        "TRUE");

    DazScript_Test("float floor",
        "{@float(12.8)>floor}",
        "12");

    DazScript_Test("float ceil",
        "{@float(12.1)>ceil}",
        "13");
}

void DazScript_TestOut()
{
    string sOut = "";
    int nOut = 0;
    float fOut = 0.0;
    json jOut = JsonParse("{}");

    Interpret("{@out(sOut,done)}");
    DazScript_TestStateString("out string", sOut, "done");

    Interpret("{@out(nOut,42)}");
    DazScript_TestStateInt("out int", nOut, 42);

    Interpret("{@out(fOut,12.5)}");
    DazScript_TestStateFloat("out float", fOut, 12.5, 0.001);

    Interpret("{@out(jOut, '{{\"hp\":42}}')}");
    DazScript_TestStateJson("out json object from string", jOut, "{\"hp\":42}");

    Interpret("{@out(jOut, '[1,2,3]')}");
    DazScript_TestStateJson("out json array from string", jOut, "[1,2,3]");

    Interpret("{@out(jOut, {@json('{{\"name\":\"Daz\"}}')})}");
    DazScript_TestStateJson("out json from json primitive", jOut, "{\"name\":\"Daz\"}");

    Interpret("{@out(jOut, 42)}");
    DazScript_TestStateJson("out json from int", jOut, "42");

    Interpret("{@out(jOut, true)}");
    DazScript_TestStateJson("out json from bool true", jOut, "1");

    Interpret("{@out(jOut, false)}");
    DazScript_TestStateJson("out json from bool false", jOut, "0");

    Interpret("{@out(jOut, 'true')}");
    DazScript_TestStateJson("out json from quoted bool true", jOut, "true");

    Interpret("{@out(jOut, 'false')}");
    DazScript_TestStateJson("out json from quoted bool false", jOut, "false");

    DazScript_TestContains("out json invalid string error",
        "{@out(jOut, '{{bad}}')}",
        "TYPE_MISMATCH:OUT_NOT_JSON");
}

void DazScript_TestSymbolTypes()
{
    json jStack = JsonObject();

    JsonObjectSetInplace(jStack, "$err", MakeStackAliasEntryFromValue(GetErrorValue("BOOM")));

    DazScript_TestStateString("symbol type error alias",
        GetSymbolType(jStack, "$err"),
        "alias:error");

    DazScript_TestStateInt("symbol exists error alias",
        SymbolExists(jStack, "$err"),
        TRUE);

    struct Value strErrorAlias = ResolveAliasValue(jStack, "$err");

    DazScript_TestStateInt("resolve error alias is error",
        IsErrorValue(strErrorAlias),
        TRUE);

    DazScript_TestStateString("resolve error alias message",
        strErrorAlias.sErrorMessage,
        "BOOM");

    json jBadAlias = JsonObject();
    JsonObjectSetIntInplace(jBadAlias, DAZSCRIPT_ALIAS_TYPE, NWNX_VM_AUXTYPE_INVALID);
    JsonObjectSetStringInplace(jBadAlias, DAZSCRIPT_ALIAS_VALUE, "not an error");
    JsonObjectSetIntInplace(jBadAlias, DAZSCRIPT_ALIAS_ERROR, FALSE);
    JsonObjectSetInplace(jStack, "$bad", jBadAlias);

    DazScript_TestStateString("symbol type non-error invalid alias",
        GetSymbolType(jStack, "$bad"),
        "invalid:alias");

    DazScript_TestStateInt("symbol exists non-error invalid alias false",
        SymbolExists(jStack, "$bad"),
        FALSE);

    struct Value strBadAlias = ResolveAliasValue(jStack, "$bad");

    DazScript_TestStateInt("resolve non-error invalid alias is error",
        IsErrorValue(strBadAlias),
        TRUE);

    DazScript_TestStateString("resolve non-error invalid alias message",
        strBadAlias.sErrorMessage,
        "INVALID_ALIAS_TYPE:$bad");

    json jMalformedAlias = JsonObject();
    JsonObjectSetStringInplace(jMalformedAlias, DAZSCRIPT_ALIAS_VALUE, "missing type");
    JsonObjectSetInplace(jStack, "$malformed", jMalformedAlias);

    DazScript_TestStateString("symbol type malformed alias",
        GetSymbolType(jStack, "$malformed"),
        "invalid:alias");

    DazScript_TestStateInt("symbol exists malformed alias false",
        SymbolExists(jStack, "$malformed"),
        FALSE);

    json jMalformedFunction = JsonObject();
    JsonObjectSetInplace(jStack, "#badfn", jMalformedFunction);

    DazScript_TestStateString("symbol type malformed function",
        GetSymbolType(jStack, "#badfn"),
        "invalid:function");

    DazScript_TestStateInt("symbol exists malformed function false",
        SymbolExists(jStack, "#badfn"),
        FALSE);

    json jMalformedStackVar = JsonObject();
    JsonObjectSetInplace(jStack, "badStack", jMalformedStackVar);

    DazScript_TestStateString("symbol type malformed stack var",
        GetSymbolType(jStack, "badStack"),
        "invalid:stack");

    DazScript_TestStateInt("symbol exists malformed stack var false",
        SymbolExists(jStack, "badStack"),
        FALSE);

    json jMadeFromInvalid = MakeStackAliasEntryFromValue(GetInvalidValue());

    DazScript_TestStateString("invalid value becomes error alias",
        GetAliasEntryType(jMadeFromInvalid),
        "alias:error");
}

void DazScript_TestErrorHandling()
{
    string m = "hello";

    DazScript_TestContains("unknown meta error",
        "{@doesnotexist()}",
        "UNKNOWN_META:doesnotexist");

    DazScript_TestContains("unknown property error includes property name",
        "{m>string>doesnotexist}",
        "UNKNOWN_PROPERTY:doesnotexist");

    DazScript_TestContains("arity error too few args",
        "{@add(1)}",
        "ARITY:EXPECTED_2_ARGUMENTS");

    DazScript_TestContains("arity error too many args",
        "{@clamp(1, 2, 3, 4)}",
        "ARITY:EXPECTED_3_ARGUMENTS");

    DazScript_TestContains("type mismatch for int arg",
        "{@int(5)>clamp(a, 10)}",
        "TYPE_MISMATCH:ARG1_NOT_INT");

    DazScript_TestContains("division by zero error",
        "{@div(5, 0)}",
        "DIVISION_BY_ZERO");

    DazScript_TestContains("invalid cast type error",
        "{@set($x, 1)}{@cast($x, banana)}",
        "INVALID_CAST_TYPE:banana");

    DazScript_TestContains("set requires alias syntax",
        "{@set(x, 1)}",
        "SET_ALIAS_IS_NON_ALIAS:x");

    DazScript_TestContains("function arity error",
        "{@fn(#one, $x, {$x})}{#one(a, b)}",
        "FUNCTION_ARITY:#one");
}

void DazScript_TestSql()
{
    DazScript_SetupSqlTests();

    DazScript_Test("sql module scalar int",
        "{@sqlmodule('SELECT COUNT(*) FROM test_players;')>scalar(i)}",
        "3");

    DazScript_Test("sql module scalar string",
        "{@sqlmodule('SELECT name FROM test_players WHERE id = @id;')>bind(id,2)>scalar(s)}",
        "Test Player 2");

    DazScript_Test("sql bind with explicit at prefix",
        "{@sqlmodule('SELECT name FROM test_players WHERE id = @id;')>bind('@id',3)>scalar(s)}",
        "Test Player 3");

    DazScript_Test("sql scalar float",
        "{@sqlmodule('SELECT rating FROM test_players WHERE id = 2;')>scalar(f)>fixed(1)}",
        "2.5");

    DazScript_Test("sql scalar default on no row",
        "{@sqlmodule('SELECT name FROM test_players WHERE id = 999;')>scalar(s,'missing')}",
        "missing");

    DazScript_TestContains("sql scalar no row strict",
        "{@sqlmodule('SELECT name FROM test_players WHERE id = 999;')>scalar(s)}",
        "SQL_NO_ROW_DATA");

    DazScript_TestContains("sql scalar invalid type",
        "{@sqlmodule('SELECT name FROM test_players WHERE id = 1;')>scalar(x)}",
        "INVALID_SCALAR_AUXTYPE:x");

    DazScript_TestContains("sql scalar no columns",
        "{@sqlmodule('UPDATE test_players SET gold = gold WHERE id = 1;')>scalar(s)}",
        "SQL_NO_COLUMNS");

    DazScript_Test("sql exec update is quiet",
        "{@sqlmodule('UPDATE test_players SET gold = 500 WHERE id = @id;')>bind(id,1)>exec}",
        "");

    DazScript_Test("sql exec updated row visible",
        "{@sqlmodule('SELECT gold FROM test_players WHERE id = 1;')>scalar(i)}",
        "500");

    DazScript_TestContains("sql exec rejects result columns",
        "{@sqlmodule('SELECT id FROM test_players;')>exec}",
        "SQL_EXEC_REQUIRES_NO_COLUMNS");

    DazScript_Test("sql columncount",
        "{@sqlmodule('SELECT id, name FROM test_players;')>columncount}",
        "2");

    DazScript_Test("sql columnname",
        "{@sqlmodule('SELECT id, name AS player_name FROM test_players;')>columnname(1)}",
        "player_name");

    DazScript_Test("sql columns",
        "{@sqlmodule('SELECT id, name AS player_name FROM test_players;')>columns}",
        "[\"id\",\"player_name\"]");

    DazScript_Test("sql row default id string",
        "{@sqlmodule('SELECT id, name FROM test_players WHERE id = 2;')>row>get(id)}",
        "2");

    DazScript_Test("sql row default name string",
        "{@sqlmodule('SELECT id, name FROM test_players WHERE id = 2;')>row>get(name)}",
        "Test Player 2");

    DazScript_Test("sql row typed compact id",
        "{@sqlmodule('SELECT id, name FROM test_players WHERE id = 2;')>row(is)>get(id)}",
        "2");

    DazScript_Test("sql row typed compact name",
        "{@sqlmodule('SELECT id, name FROM test_players WHERE id = 2;')>row(is)>get(name)}",
        "Test Player 2");

    DazScript_Test("sql row typed json get class",
        "{@sqlmodule('SELECT payload FROM test_players WHERE id = 1;')>row(j)>get(payload)>get(class)}",
        "fighter");

    DazScript_Test("sql row typed float",
        "{@sqlmodule('SELECT rating FROM test_players WHERE id = 1;')>row(f)>get(rating)>fixed(1)}",
        "1.5");

    DazScript_TestContains("sql row no row strict",
        "{@sqlmodule('SELECT id, name FROM test_players WHERE id = 999;')>row(is)}",
        "SQL_NO_ROW_DATA");

    DazScript_TestContains("sql row spec mismatch",
        "{@sqlmodule('SELECT id, name FROM test_players WHERE id = 1;')>row(i)}",
        "SQL_ROW_SPEC_COLUMN_COUNT_MISMATCH");

    DazScript_TestContains("sql row invalid spec char",
        "{@sqlmodule('SELECT id, name FROM test_players WHERE id = 1;')>row(ix)}",
        "INVALID_ROW_AUXTYPE:x");

    DazScript_Test("sql rows typed limit at get",
        "{@sqlmodule('SELECT id, name FROM test_players ORDER BY id;')>rows(is,2)>at(1)>get(name)}",
        "Test Player 2");

    DazScript_Test("sql rows limit as first arg",
        "{@sqlmodule('SELECT id, name FROM test_players ORDER BY id;')>rows(2)>at(1)>get(name)}",
        "Test Player 2");

    DazScript_Test("sql rows empty result is empty array",
        "{@sqlmodule('SELECT id, name FROM test_players WHERE id = 999;')>rows(is)>length}",
        "0");

    DazScript_TestContains("sql rows limit zero",
        "{@sqlmodule('SELECT id, name FROM test_players;')>rows(is,0)}",
        "SQL_ROWS_LIMIT_MUST_BE_POSITIVE");

    DazScript_TestContains("sql rows limit too high",
        "{@sqlmodule('SELECT id, name FROM test_players;')>rows(is,999999)}",
        "SQL_ROWS_LIMIT_TOO_HIGH");

    DazScript_TestContains("sql rows invalid first arg",
        "{@sqlmodule('SELECT id, name FROM test_players;')>rows(1.5)}",
        "INVALID_ROWS_ARGUMENT");

    DazScript_Test("sql rows compose with json at get",
        "{@sqlmodule('SELECT id, name FROM test_players ORDER BY id;')>rows(is,3)>at(2)>get(name)}",
        "Test Player 3");

    DazScript_Test("sql nested scalar in chain arg",
        "{@sqlmodule('SELECT id, name FROM test_players ORDER BY id;')>rows(is)>at({@sub({@sqlmodule('SELECT COUNT(*) FROM test_players;')>scalar(i)},1)})>get(name)}",
        "Test Player 3");

    DazScript_TestContains("sql empty query",
        "{@sqlmodule('')}",
        "EMPTY_SQL_QUERY");

    DazScript_TestContains("sql empty bind name",
        "{@sqlmodule('SELECT id FROM test_players WHERE id = @id;')>bind('',1)>scalar(i)}",
        "EMPTY_BIND_NAME");

    DazScript_Test("sql rows foreach formatter",
        "{@set($rows,{@sqlmodule('SELECT id, name, xp FROM test_players ORDER BY id;')>rows(isi)})}" +
        "{@foreach({$rows}, $row," +
            "'{@foreach({$row},$key,$value," +
                "'{$key>capitalize} = {@if({@type($value)>eq(alias:string)},'\"{$value}\"',{$value})}; ')>trim}\n'" +
        ")}",
        "Id = 1; Name = \"Test Player 1\"; Xp = 1000;\n" +
        "Id = 2; Name = \"Test Player 2\"; Xp = 2500;\n" +
        "Id = 3; Name = \"Test Player 3\"; Xp = 6250;\n");

    string sQuery = "SELECT json_extract(@payload, '$.class');";

    DazScript_Test("sql bind json from json value",
        "{@sqlmodule({sQuery})>bindj(payload,{@json('{{\"class\":\"fighter\"}}')})>scalar(s)}",
        "fighter");

    DazScript_Test("sql bind json from json string",
        "{@sqlmodule({sQuery})>bindj(payload,'{{\"class\":\"wizard\"}}')>scalar(s)}",
        "wizard");
}

void main()
{
    g_oCreature = CreateObject(OBJECT_TYPE_CREATURE, "nw_commale", GetStartingLocation(), FALSE, "DAZSCRIPT_CREATURE");

    DazScript_SetupSqlTests();

    DazScript_TestSmoke();
    DazScript_TestPrimitives();
    DazScript_TestJson();
    DazScript_TestForeach();
    DazScript_TestMoreJsonLikeCollectionOrAggregate();
    DazScript_TestParserWhitespace();
    DazScript_TestStringProperties();
    DazScript_TestMetaVars();
    DazScript_TestRender();
    DazScript_TestFunctionParams();
    DazScript_TestLazy();
    DazScript_TestControlFlow();
    DazScript_TestMath();
    DazScript_TestOut();
    DazScript_TestSymbolTypes();
    DazScript_TestParserErrors();
    DazScript_TestErrorHandling();
    DazScript_TestParserEvil();
    DazScript_TestSql();

    DestroyObject(g_oCreature);

    PrintString("DazScript tests complete: " + IntToString(g_nPassed) + " passed, " + IntToString(g_nFailed) + " failed.");
}
