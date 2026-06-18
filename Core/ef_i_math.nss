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

int Max(int a, int b);
int Min(int a, int b);
int Clamp(int nValue, int nMin, int nMax);
float Clampf(float fValue, float fMin, float fMax);
int Floor(float f);
int Ceil(float f);
int Round(float f);
int Log2(int n);

int Max(int a, int b)
{
    return a > b ? a : b;
}

int Min(int a, int b)
{
    return a < b ? a : b;
}

int Clamp(int nValue, int nMin, int nMax)
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

float Clampf(float fValue, float fMin, float fMax)
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

int Floor(float f)
{
    return FloatToInt(f);
}

int Ceil(float f)
{
    return FloatToInt(f + (IntToFloat(FloatToInt(f)) < f ? 1.0 : 0.0));
}

int Round(float f)
{
    return FloatToInt(f + 0.5f);
}

int Log2(int n)
{
    int ret; while (n >>= 1) { ret++; } return ret;
}
