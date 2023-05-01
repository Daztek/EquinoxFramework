/*
    Script: ef_s_vmperf
    Author: Daz
*/

string scope;
int i, x, t1, t2, i1, i2;
int twhile, iwhile;
const int N = 1000;

void VMPerf_Start(string s)
{
    scope = s;
    i1 = GetScriptInstructionsRemaining();
    t1 = GetMicrosecondCounter();
}

void VMPerf_End()
{
    t2 = GetMicrosecondCounter();
    i2 = GetScriptInstructionsRemaining();

    int icnt = (i1 - i2) - iwhile;
    int us = (t2 - t1) - twhile;

    float feff = ((1000000.0f / us) * icnt) / 1000000.0f;
    string msg = scope + ": took " + IntToString(us) + "us, " + IntToString(icnt) + " instructions; Effective frequency: " + FloatToString(feff, 5, 1) + "MHz";

    WriteTimestampedLogEntry(msg);
}

void VMPerf_Init()
{
    i1 = GetScriptInstructionsRemaining();
    t1 = GetMicrosecondCounter();
    x = N; while (--x) { }
    t2 = GetMicrosecondCounter();
    i2 = GetScriptInstructionsRemaining();
    twhile = t2 - t1;
    iwhile = i1 - i2;

    string msg = "twhile = " + IntToString(twhile) + "; iwhile = " + IntToString(iwhile);
    WriteTimestampedLogEntry(msg);
}

// @CONSOLE[VMPerf::]
void VMPerf_Console()
{
    VMPerf_Init();

    VMPerf_Start("for loop");
    x = N; while (--x) {
        for (i = 0; i < 10; i++) { }
    }
    VMPerf_End();

    string s;
    VMPerf_Start("const string cat");
    x = N; while (--x) {
        s = "a" + "b";
    }
    VMPerf_End();

    string s1 = "a", s2 = "b";
    VMPerf_Start("var string cat");
    x = N; while (--x) {
        s = s1 + s2;
    }
    VMPerf_End();
}
