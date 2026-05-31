/*
    Script: ef_i_math
    Author: Daz
*/

const float FLOAT_EPSILON = 0.000001f;

struct Vector2
{
    int nX;
    int nY;
};

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
    if (nMin > nMax)
    {
        int nTmp = nMin;
        nMin = nMax;
        nMax = nTmp;
    }

    if (nValue < nMin)
        return nMin;

    if (nValue > nMax)
        return nMax;

    return nValue;
}

float clampf(float fValue, float fMin, float fMax)
{
    if (fMin > fMax)
    {
        float fTmp = fMin;
        fMin = fMax;
        fMax = fTmp;
    }

    if (fValue < fMin)
        return fMin;

    if (fValue > fMax)
        return fMax;

    return fValue;
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
