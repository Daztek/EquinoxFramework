/*
    Script: ef_i_math
    Author: Daz
*/

int max(int a, int b);
int min(int a, int b);
int clamp(int nValue, int nMin, int nMax);
float clampf(float fValue, float fMin, float fMax);
int floor(float f);
int ceil(float f);
int round(float f);
int log2(int n);

int max(int a, int b)
{
    return a > b ? a : b;
}

int min(int a, int b)
{
    return a < b ? a : b;
}

int clamp(int nValue, int nMin, int nMax)
{
    return nValue < nMin ? nMin : nValue > nMax ? nMax : nValue;
}

float clampf(float fValue, float fMin, float fMax)
{
    return fValue < fMin ? fMin : fValue > fMax ? fMax : fValue;
}

int floor(float f)
{
    return FloatToInt(f);
}

int ceil(float f)
{
    return FloatToInt(f + (IntToFloat(FloatToInt(f)) < f ? 1.0 : 0.0));
}

int round(float f)
{
    return FloatToInt(f + 0.5f);
}

int log2(int n)
{
    int ret; while (n >>= 1) { ret++; } return ret;
}
