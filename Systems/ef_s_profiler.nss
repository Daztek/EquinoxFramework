/*
    Script: ef_s_profiler
    Author: Daz

    Description: Equinox Framework Profiler System
*/

#include "ef_i_core"

//void main() {}

const string PROFILER_LOG_TAG                           = "Profiler";
const string PROFILER_SCRIPT_NAME                       = "ef_s_profiler";

const int PROFILER_OVERHEAD_COMPENSATION_ITERATIONS     = 1000;

struct ProfilerData
{
    string sName;
    int bEnableStats;
    int bSkipLog;
    int nSeconds;
    int nMicroseconds;
};

struct ProfilerData Profiler_Start(string sName, int bSkipLog = FALSE, int bEnableStats = TRUE);
int Profiler_Stop(struct ProfilerData strData);
int Profiler_GetOverheadCompensation();
void Profiler_SetOverheadCompensation(int nOverhead);
int Profiler_Calibrate(int nIterations);

// @CORE[EF_SYSTEM_INIT]
void Profiler_Init()
{
    int nOverhead = Profiler_Calibrate(PROFILER_OVERHEAD_COMPENSATION_ITERATIONS);
    WriteLog(PROFILER_LOG_TAG, "* Overhead Compensation: " + IntToString(nOverhead) + "us");
    Profiler_SetOverheadCompensation(nOverhead);
}

struct ProfilerData Profiler_Start(string sName, int bSkipLog = FALSE, int bEnableStats = TRUE)
{
    struct ProfilerData pd;
    pd.sName = sName;
    pd.bEnableStats = bEnableStats;
    pd.bSkipLog = bSkipLog;

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
    if (strData.bEnableStats)
    {
        object oDataObject = GetDataObject(PROFILER_SCRIPT_NAME + "_" + strData.sName);
        int nMin, nMax, nCount = GetLocalInt(oDataObject, "PROFILER_COUNT") + 1;
        SetLocalInt(oDataObject, "PROFILER_COUNT", nCount);

        if (nCount == 1)
        {
            nMin = nTotalMicroSeconds;
            nMax = nTotalMicroSeconds;

            SetLocalInt(oDataObject, "PROFILER_MIN", nTotalMicroSeconds);
            SetLocalInt(oDataObject, "PROFILER_MAX", nTotalMicroSeconds);
        }
        else
        {
            nMin = GetLocalInt(oDataObject, "PROFILER_MIN");
            if (nTotalMicroSeconds < nMin)
            {
                nMin = nTotalMicroSeconds;
                SetLocalInt(oDataObject, "PROFILER_MIN", nTotalMicroSeconds);
            }

            nMax = GetLocalInt(oDataObject, "PROFILER_MAX");
            if (nTotalMicroSeconds > nMax)
            {
                nMax = nTotalMicroSeconds;
                SetLocalInt(oDataObject, "PROFILER_MAX", nTotalMicroSeconds);
            }
        }

        int nSum = GetLocalInt(oDataObject, "PROFILER_SUM") + nTotalMicroSeconds;
        SetLocalInt(oDataObject, "PROFILER_SUM", nSum);

        sStats = " (MIN: " + IntToString(nMin) + "us, MAX: " + IntToString(nMax) + "us, AVG: " + IntToString((nSum / nCount)) + "us)";
    }

    if (!strData.bSkipLog)
    {
        int nLength = GetStringLength(IntToString(nTotalMicroSeconds));

        string sZeroPadding;
        while (nLength < 6)
        {
            sZeroPadding += "0";
            nLength++;
        }

        WriteLog(PROFILER_LOG_TAG, "[" + strData.sName + "] " + IntToString(nTotalSeconds) + "." + sZeroPadding + IntToString(nTotalMicroSeconds) + " seconds" + sStats);
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
    int i, nSum;

    for (i = 0; i < nIterations; i++)
    {
        nSum += Profiler_Stop(Profiler_Start("Calibration", TRUE, FALSE));
    }

    return nIterations == 0 ? 0 : nSum / nIterations;
}

