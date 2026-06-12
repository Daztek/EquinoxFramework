/*
    Script: ef_t_dazscript
    Author: Daz
*/

#include "ef_c_dazscript"

void DazScript_TestLazy();
void DazScript_TestParserWhitespace();
void DazScript_TestStringProperties();
void DazScript_TestMetaVars();
void DazScript_TestFunctionParams();
void DazScript_TestMath();
void DazScript_TestOut();
void DazScript_TestParserErrors();
void DazScript_TestParserEvil();
void DazScript_TestJson();
void DazScript_TestErrorHandling();
void DazScript_TestControlFlow();

int g_nPassed = 0;
int g_nFailed = 0;
int g_bVerbosePasses = FALSE;

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
    string sActual = Interpret(sInput, 1);
    DazScript_RecordResult(sName, sActual == sExpected, sInput, "expected:", sExpected, sActual);
}

void DazScript_TestContains(string sName, string sInput, string sExpectedSubstring)
{
    string sActual = Interpret(sInput, 1);
    DazScript_RecordResult(sName, FindSubString(sActual, sExpectedSubstring) >= 0, sInput, "expected has:", sExpectedSubstring, sActual);
}

void DazScript_TestNotContains(string sName, string sInput, string sForbiddenSubstring)
{
    string sActual = Interpret(sInput, 1);
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

void main()
{
    int nNum = 5;
    float fNum = 12.5;
    string sText = "hello";
    string sEmpty = "";
    object oCreature = GetObjectByTag("BT_GUARD");

    DazScript_Test("literal braces",
        "Hello {{oCreature}}",
        "Hello {oCreature}");

    DazScript_Test("object valid",
        "{oCreature>valid>bool}",
        "TRUE");

    DazScript_Test("object tag",
        "{oCreature>tag}",
        "BT_GUARD");

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

    DazScript_TestLazy();
    DazScript_TestParserWhitespace();
    DazScript_TestStringProperties();
    DazScript_TestMetaVars();
    DazScript_TestFunctionParams();
    DazScript_TestMath();
    DazScript_TestOut();
    DazScript_TestParserErrors();
    DazScript_TestParserEvil();
    DazScript_TestJson();
    DazScript_TestErrorHandling();
    DazScript_TestControlFlow();

    PrintString("DazScript tests complete: " + IntToString(g_nPassed) + " passed, " + IntToString(g_nFailed) + " failed.");
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

    Interpret("{@out(sOut,done)}");
    DazScript_TestStateString("out string", sOut, "done");

    Interpret("{@out(nOut,42)}");
    DazScript_TestStateInt("out int", nOut, 42);

    Interpret("{@out(fOut,12.5)}");
    DazScript_TestStateFloat("out float", fOut, 12.5, 0.001);
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

    DazScript_Test("all alias for and",
        "{@all(TRUE, yes, 1)>bool}",
        "TRUE");

    DazScript_Test("any alias for or",
        "{@any(FALSE, 0, yes)>bool}",
        "TRUE");
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

    DazScript_TestContains("evil trailing property delimiter is not silent",
        "{m>string>}",
        "UNKNOWN_PROPERTY:");

    DazScript_TestContains("evil double property delimiter is not silent",
        "{m>string>>upper}",
        "UNKNOWN_PROPERTY:");

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
