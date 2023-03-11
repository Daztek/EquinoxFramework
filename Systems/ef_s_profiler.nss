/*
    Script: ef_s_profiler
    Author: Daz

    Description: Equinox Framework Profiler System
*/

#include "ef_i_core"

const string PROFILER_SCRIPT_NAME                       = "ef_s_profiler";

const int PROFILER_OVERHEAD_COMPENSATION_ITERATIONS     = 1000;

struct ProfilerData
{
    string sName;
    int bPrintLog;
    int bInsertStats;
    int nSeconds;
    int nMicroseconds;
};

struct ProfilerData Profiler_Start(string sName, int bPrintLog = TRUE, int bInsertStats = TRUE);
int Profiler_Stop(struct ProfilerData strData);
int Profiler_GetOverheadCompensation();
void Profiler_SetOverheadCompensation(int nOverhead);
int Profiler_Calibrate(int nIterations);

// @CORE[EF_SYSTEM_INIT]
void Profiler_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + PROFILER_SCRIPT_NAME + " (" +
                    "id INTEGER NOT NULL, " +
                    "microseconds INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    int nOverhead = Profiler_Calibrate(PROFILER_OVERHEAD_COMPENSATION_ITERATIONS);
    LogInfo("Overhead Compensation: " + IntToString(nOverhead) + "us");
    Profiler_SetOverheadCompensation(nOverhead);
}

void Profiler_InsertData(int nHash, int nMicroseconds)
{
    sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + PROFILER_SCRIPT_NAME + "(id, microseconds) VALUES(@id, @microseconds);");
    SqlBindInt(sql, "@id", nHash);
    SqlBindInt(sql, "@microseconds", nMicroseconds);
    SqlStep(sql);
}

struct ProfilerData Profiler_Start(string sName, int bPrintLog = TRUE, int bInsertStats = TRUE)
{
    struct ProfilerData pd;
    pd.sName = sName;
    pd.bPrintLog = bPrintLog;
    pd.bInsertStats = bInsertStats;

    struct NWNX_Util_HighResTimestamp ts = NWNX_Util_GetHighResTimeStamp();
    pd.nSeconds = ts.seconds;
    pd.nMicroseconds = ts.microseconds;

    return pd;
}

int Profiler_Stop(struct ProfilerData strData)
{
    struct NWNX_Util_HighResTimestamp endTimestamp = NWNX_Util_GetHighResTimeStamp();
    int nTotalSeconds = endTimestamp.seconds - strData.nSeconds;
    int nTotalMicroSeconds = endTimestamp.microseconds - strData.nMicroseconds - Profiler_GetOverheadCompensation();

    if (nTotalMicroSeconds < 0)
    {
        if (nTotalSeconds > 0)
        {
            nTotalMicroSeconds = 1000000 + nTotalMicroSeconds;
            nTotalSeconds--;
        }
        else
            nTotalMicroSeconds = 0;
    }

    string sStats;
    if (strData.bInsertStats)
    {
        int nHash = HashString(strData.sName);
        Profiler_InsertData(nHash, nTotalMicroSeconds);
        sqlquery sql = SqlPrepareQueryModule("SELECT MIN(microseconds), MAX(microseconds), AVG(microseconds) " +
                                             "FROM " + PROFILER_SCRIPT_NAME + " WHERE id = @id;");
        SqlBindInt(sql, "@id", nHash);

        if(SqlStep(sql))
        {
            sStats = " (MIN: " + IntToString(SqlGetInt(sql, 0)) + "us, MAX: " + IntToString(SqlGetInt(sql, 1)) + "us, AVG: " + IntToString(SqlGetInt(sql, 2)) + "us)";
        }
    }

    if (strData.bPrintLog)
    {
        int nLength = GetStringLength(IntToString(nTotalMicroSeconds));

        string sZeroPadding;
        while (nLength < 6)
        {
            sZeroPadding += "0";
            nLength++;
        }

        LogInfo("[" + strData.sName + "] " + IntToString(nTotalSeconds) + "." + sZeroPadding + IntToString(nTotalMicroSeconds) + " seconds" + sStats);
    }

    return nTotalMicroSeconds;
}

int Profiler_GetOverheadCompensation()
{
    return GetLocalInt(GetDataObject(PROFILER_SCRIPT_NAME), "OVERHEAD_COMPENSATION");
}

void Profiler_SetOverheadCompensation(int nOverhead)
{
    SetLocalInt(GetDataObject(PROFILER_SCRIPT_NAME), "OVERHEAD_COMPENSATION", nOverhead);
}

int Profiler_Calibrate(int nIterations)
{
    int nIteration, nSum;

    for (nIteration = 0; nIteration < nIterations; nIteration++)
    {
        nSum += Profiler_Stop(Profiler_Start("Calibration", FALSE, FALSE));
    }

    return nIterations == 0 ? 0 : nSum / nIterations;
}
