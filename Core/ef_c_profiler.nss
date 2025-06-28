/*
    Script: ef_c_profiler
    Author: Daz
*/

#include "ef_i_dataobject"
#include "ef_i_math"
#include "ef_i_sqlite"
#include "ef_i_vm"

const string PROFILER_SCRIPT_NAME                       = "ef_c_profiler";

const string PROFILER_CALLING_FUNCTION                  = "CallingFunction";
const string PROFILER_IDENTIFIER_STRING                 = "IdentifierString";
const string PROFILER_START_INSTRUCTIONS                = "StartInstructions";
const string PROFILER_START_MICROSECONDS                = "StartMicroseconds";

const int PROFILER_MICROSECONDS_IN_SECOND               = 1000000;
const int PROFILER_INSTRUCTION_OVERHEAD                 = 17;
const int PROFILER_MICROSECOND_OVERHEAD                 = 1;

void Profiler_Start(string sIdentifier = "");
string Profiler_Stop();

void Profiler_Init()
{
    SqlStep(SqlPrepareQueryModule("CREATE TABLE IF NOT EXISTS " + PROFILER_SCRIPT_NAME + " (" +
                                  "hash INTEGER NOT NULL, microseconds INTEGER NOT NULL, " +
                                  "instructions INTEGER NOT NULL);"));
}

void Profiler_Insert(int nHash, int nMicroseconds, int nInstructions)
{
    sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + PROFILER_SCRIPT_NAME + "(hash, microseconds, instructions) VALUES(@hash, @microseconds, @instructions);");
    SqlBindInt(sql, "@hash", nHash);
    SqlBindInt(sql, "@microseconds", nMicroseconds);
    SqlBindInt(sql, "@instructions", nInstructions);
    SqlStep(sql);
}

string Profiler_FormatTime(int nMicroseconds)
{
    return IntToString(nMicroseconds / PROFILER_MICROSECONDS_IN_SECOND) + "." + LeftPadString(IntToString(nMicroseconds % PROFILER_MICROSECONDS_IN_SECOND), 6, "0") + "s";
}

string Profiler_GetTimeStats(int nHash)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT MIN(microseconds), MAX(microseconds), AVG(microseconds) FROM " + PROFILER_SCRIPT_NAME + " WHERE hash = @hash;");
    SqlBindInt(sql, "@hash", nHash);

    if(SqlStep(sql))
    {
        return "Stats: (Min: " + Profiler_FormatTime(SqlGetInt(sql, 0)) +
                     ", Max: " + Profiler_FormatTime(SqlGetInt(sql, 1)) +
                     ", Avg: " + Profiler_FormatTime(SqlGetInt(sql, 2)) + ")";
    }
    return "Stats: (Min: N/A, Max: N/A, Avg: N/A)";
}

void Profiler_Start(string sIdentifier = "")
{
    struct VMFrame strFrame = GetVMFrame(1);
    object oDataObject = GetDataObject(PROFILER_SCRIPT_NAME);
    SetLocalString(oDataObject, PROFILER_CALLING_FUNCTION, strFrame.sFile + "::" + strFrame.sFunction + ":" + IntToString(strFrame.nLine));
    SetLocalString(oDataObject, PROFILER_IDENTIFIER_STRING, sIdentifier);
    SetLocalInt(oDataObject, PROFILER_START_INSTRUCTIONS, GetScriptInstructionsRemaining());
    SetLocalInt(oDataObject, PROFILER_START_MICROSECONDS, GetMicrosecondCounter());
}

string Profiler_Stop()
{
    int nEndMicroseconds = GetMicrosecondCounter();
    int nEndInstructions = GetScriptInstructionsRemaining();
    object oDataObject = GetDataObject(PROFILER_SCRIPT_NAME);
    string sIdentifierString = GetLocalString(oDataObject, PROFILER_IDENTIFIER_STRING);
    string sHashString = sIdentifierString == "" ? GetLocalString(oDataObject, PROFILER_CALLING_FUNCTION) : sIdentifierString;
    int nHash = HashString(sHashString);
    int nUsedInstructions = max(0, GetLocalInt(oDataObject, PROFILER_START_INSTRUCTIONS) - nEndInstructions - PROFILER_INSTRUCTION_OVERHEAD);
    int nElapsedMicroseconds = max(0, nEndMicroseconds - GetLocalInt(oDataObject, PROFILER_START_MICROSECONDS) - PROFILER_MICROSECOND_OVERHEAD);

    Profiler_Insert(nHash, nElapsedMicroseconds, nUsedInstructions);

    return "[" + sHashString + "] Time: " + Profiler_FormatTime(nElapsedMicroseconds) +
            " | Instructions: " + IntToString(nUsedInstructions) + " | " + Profiler_GetTimeStats(nHash);
}
