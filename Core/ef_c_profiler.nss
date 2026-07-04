/*
    Script: ef_c_profiler
    Author: Daz
*/

#include "ef_i_dataobject"
#include "ef_i_math"
#include "ef_i_sqlite"
#include "ef_i_util"

const string PROFILER_SCRIPT_NAME                       = "ef_c_profiler";

const string PROFILER_COUNT                             = "Count";
const string PROFILER_DEPTH                             = "Depth";
const string PROFILER_STACK                             = "Stack_";
const string PROFILER_CALL_DEPTH                        = "CallDepth_";
const string PROFILER_CHILD_COUNT                       = "ChildCount_";
const string PROFILER_ORIGIN                            = "Origin_";
const string PROFILER_IDENTIFIER                        = "Identifier_";
const string PROFILER_INSTRUCTIONS                      = "Instructions_";
const string PROFILER_MICROSECONDS                      = "Microseconds_";

const int PROFILER_MICROSECONDS_IN_MILLISECOND          = 1000;
const int PROFILER_MICROSECONDS_IN_SECOND               = 1000000;

const int PROFILER_CALL_INSTRUCTION_OVERHEAD            = 21;
const int PROFILER_CALL_MICROSECOND_OVERHEAD            = 1;
const int PROFILER_CHILD_INSTRUCTION_OVERHEAD           = 261;
const int PROFILER_CHILD_MICROSECOND_OVERHEAD           = 12;

void Profiler_Start(string sIdentifier = "", string sOrigin = _ORIGIN_);
void Profiler_Stop();
string Profiler_Finalize(int bPrint = TRUE, int bStats = TRUE);

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
    if(nMicroseconds < PROFILER_MICROSECONDS_IN_MILLISECOND)
        return IntToString(nMicroseconds) + "us";
    if(nMicroseconds < PROFILER_MICROSECONDS_IN_SECOND)
        return IntToString(nMicroseconds / PROFILER_MICROSECONDS_IN_MILLISECOND) + "." + LeftPadString(IntToString(nMicroseconds % PROFILER_MICROSECONDS_IN_MILLISECOND), 3, "0") + "ms";
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

void Profiler_Start(string sIdentifier = "", string sOrigin = _ORIGIN_)
{
    object oDataObject = GetDataObject(PROFILER_SCRIPT_NAME);
    int nDepth = GetLocalInt(oDataObject, PROFILER_DEPTH);
    int nCount = GetLocalInt(oDataObject, PROFILER_COUNT);

    string sSlot  = IntToString(nCount);
    string sDepth = IntToString(nDepth);

    if (nDepth > 0)
    {
        string sParentSlot = IntToString(GetLocalInt(oDataObject, PROFILER_STACK + IntToString(nDepth - 1)));
        SetLocalInt(oDataObject, PROFILER_CHILD_COUNT + sParentSlot, GetLocalInt(oDataObject, PROFILER_CHILD_COUNT + sParentSlot) + 1);
    }

    SetLocalInt(oDataObject, PROFILER_STACK + sDepth, nCount);
    SetLocalInt(oDataObject, PROFILER_COUNT, nCount + 1);
    SetLocalInt(oDataObject, PROFILER_DEPTH, nDepth + 1);

    SetLocalString(oDataObject, PROFILER_IDENTIFIER + sSlot, sIdentifier);
    SetLocalString(oDataObject, PROFILER_ORIGIN + sSlot, sOrigin);
    SetLocalInt(oDataObject, PROFILER_CALL_DEPTH + sSlot, nDepth);
    SetLocalInt(oDataObject, PROFILER_INSTRUCTIONS + sSlot, GetScriptInstructionsRemaining());
    SetLocalInt(oDataObject, PROFILER_MICROSECONDS + sSlot, GetMicrosecondCounter());
}

void Profiler_Stop()
{
    int nEndMicroseconds = GetMicrosecondCounter();
    int nEndInstructions  = GetScriptInstructionsRemaining();

    object oDataObject = GetDataObject(PROFILER_SCRIPT_NAME);
    int nDepth = GetLocalInt(oDataObject, PROFILER_DEPTH) - 1;
    SetLocalInt(oDataObject, PROFILER_DEPTH, nDepth);

    string sDepth = IntToString(nDepth);
    int nSlot = GetLocalInt(oDataObject, PROFILER_STACK + sDepth);
    string sSlot = IntToString(nSlot);

    int nUsedInstructions = Max(0, GetLocalInt(oDataObject, PROFILER_INSTRUCTIONS + sSlot) - nEndInstructions - PROFILER_CALL_INSTRUCTION_OVERHEAD);
    int nElapsedMicroseconds = Max(0, nEndMicroseconds - GetLocalInt(oDataObject, PROFILER_MICROSECONDS + sSlot) - PROFILER_CALL_MICROSECOND_OVERHEAD);

    SetLocalInt(oDataObject, PROFILER_INSTRUCTIONS + sSlot, nUsedInstructions);
    SetLocalInt(oDataObject, PROFILER_MICROSECONDS + sSlot, nElapsedMicroseconds);
}

string Profiler_Finalize(int bPrint = TRUE, int bStats = TRUE)
{
    object oDataObject = GetDataObject(PROFILER_SCRIPT_NAME);
    int nSlot, nNumSlots = GetLocalInt(oDataObject, PROFILER_COUNT);
    string sRetVal;

    for (nSlot = 0; nSlot < nNumSlots; nSlot++)
    {
        string sIndent, sSlot = IntToString(nSlot);
        int nCallDepthIndex, nCallDepth = GetLocalInt(oDataObject, PROFILER_CALL_DEPTH + sSlot);
        for (nCallDepthIndex = 0; nCallDepthIndex < nCallDepth; nCallDepthIndex++)
        {
            sIndent += "  ";
        }

        string sIdentifier = GetLocalString(oDataObject, PROFILER_IDENTIFIER + sSlot);
        if (sIdentifier == "")
            sIdentifier = GetLocalString(oDataObject, PROFILER_ORIGIN + sSlot);
        int nInstructions = GetLocalInt(oDataObject, PROFILER_INSTRUCTIONS + sSlot);
        int nMicroSeconds = GetLocalInt(oDataObject, PROFILER_MICROSECONDS + sSlot);
        int nChildCount = GetLocalInt(oDataObject, PROFILER_CHILD_COUNT + sSlot);

        nInstructions = Max(0, nInstructions - (PROFILER_CHILD_INSTRUCTION_OVERHEAD * nChildCount));
        nMicroSeconds = Max(0, nMicroSeconds - (PROFILER_CHILD_MICROSECOND_OVERHEAD * nChildCount));

        sRetVal += sIndent + "[" + sIdentifier + "] " + Profiler_FormatTime(nMicroSeconds) + " | " + IntToString(nInstructions) + " Instructions";

        if (bStats && nCallDepth == 0)
        {
            int nHash = HashString(sIdentifier);
            Profiler_Insert(nHash, nMicroSeconds, nInstructions);
            sRetVal += " | " + Profiler_GetTimeStats(nHash);
        }

        if (nSlot < nNumSlots - 1)
            sRetVal += "\n";

        DeleteLocalInt(oDataObject, PROFILER_CHILD_COUNT + sSlot);
    }

    DeleteLocalInt(oDataObject, PROFILER_COUNT);
    DeleteLocalInt(oDataObject, PROFILER_DEPTH);

    if (bPrint)
        PrintString(sRetVal);

    return sRetVal;
}
