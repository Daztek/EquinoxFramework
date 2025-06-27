/*
    Script: ef_i_ringbuffer
    Author: Daz
*/

#include "ef_i_json"

const string RINGBUFFER_SIZE    = "RBSIZE_";
const string RINGBUFFER_DATA    = "RBDATA_";
const string RINGBUFFER_HEAD    = "RBHEAD_";
const string RINGBUFFER_TAIL    = "RBTAIL_";
const string RINGBUFFER_COUNT   = "RBCOUNT_";

void RingBuffer_Init(object oObject, string sName, int nSize);
void RingBuffer_Clear(object oObject, string sName);
int RingBuffer_GetCount(object oObject, string sName);
int RingBuffer_GetSize(object oObject, string sName);
int RingBuffer_IsEmpty(object oObject, string sName);
int RingBuffer_IsFull(object oObject, string sName);
int RingBuffer_PushJson(object oObject, string sName, json jValue);
int RingBuffer_PushString(object oObject, string sName, string sValue);
int RingBuffer_PushInt(object oObject, string sName, int nValue);
int RingBuffer_PushFloat(object oObject, string sName, float fValue);
json RingBuffer_PopJson(object oObject, string sName);
string RingBuffer_PopString(object oObject, string sName);
int RingBuffer_PopInt(object oObject, string sName);
float RingBuffer_PopFloat(object oObject, string sName);
json RingBuffer_PeekJson(object oObject, string sName);
string RingBuffer_PeekString(object oObject, string sName);
int RingBuffer_PeekInt(object oObject, string sName);
float RingBuffer_PeekFloat(object oObject, string sName);
json RingBuffer_ToArray(object oObject, string sName);

void RingBuffer_Init(object oObject, string sName, int nSize)
{
    if (nSize <= 0)
        return;

    SetLocalInt(oObject, RINGBUFFER_SIZE + sName, nSize);
    SetLocalJson(oObject, RINGBUFFER_DATA + sName, GetJsonArrayOfSize(nSize, JsonNull()));
    SetLocalInt(oObject, RINGBUFFER_HEAD + sName, 0);
    SetLocalInt(oObject, RINGBUFFER_TAIL + sName, 0);
    SetLocalInt(oObject, RINGBUFFER_COUNT + sName, 0);
}

void RingBuffer_Clear(object oObject, string sName)
{
    SetLocalJson(oObject, RINGBUFFER_DATA + sName, GetJsonArrayOfSize(GetLocalInt(oObject, RINGBUFFER_SIZE + sName), JsonNull()));
    SetLocalInt(oObject, RINGBUFFER_HEAD + sName, 0);
    SetLocalInt(oObject, RINGBUFFER_TAIL + sName, 0);
    SetLocalInt(oObject, RINGBUFFER_COUNT + sName, 0);
}

int RingBuffer_GetCount(object oObject, string sName)
{
    return GetLocalInt(oObject, RINGBUFFER_COUNT + sName);
}

int RingBuffer_GetSize(object oObject, string sName)
{
    return GetLocalInt(oObject, RINGBUFFER_SIZE + sName);
}

int RingBuffer_IsEmpty(object oObject, string sName)
{
    return RingBuffer_GetCount(oObject, sName) == 0;
}

int RingBuffer_IsFull(object oObject, string sName)
{
    return RingBuffer_GetCount(oObject, sName) == RingBuffer_GetSize(oObject, sName);
}

int RingBuffer_PushJson(object oObject, string sName, json jValue)
{
    int nSize = GetLocalInt(oObject, RINGBUFFER_SIZE + sName);
    if (nSize <= 0)
        return FALSE;

    int nHead = GetLocalInt(oObject, RINGBUFFER_HEAD + sName);
    int nCount = GetLocalInt(oObject, RINGBUFFER_COUNT + sName);

    JsonArraySetInplace(GetLocalJson(oObject, RINGBUFFER_DATA + sName), nHead, jValue);
    SetLocalInt(oObject, RINGBUFFER_HEAD + sName, (nHead + 1) % nSize);

    if (nCount == nSize)
        SetLocalInt(oObject, RINGBUFFER_TAIL + sName, (GetLocalInt(oObject, RINGBUFFER_TAIL + sName) + 1) % nSize);
    else
        SetLocalInt(oObject, RINGBUFFER_COUNT + sName, nCount + 1);

    return TRUE;
}

int RingBuffer_PushString(object oObject, string sName, string sValue)
{
    return RingBuffer_PushJson(oObject, sName, JsonString(sValue));
}

int RingBuffer_PushInt(object oObject, string sName, int nValue)
{
    return RingBuffer_PushJson(oObject, sName, JsonInt(nValue));
}

int RingBuffer_PushFloat(object oObject, string sName, float fValue)
{
    return RingBuffer_PushJson(oObject, sName, JsonFloat(fValue));
}

json RingBuffer_PopJson(object oObject, string sName)
{
    int nCount = GetLocalInt(oObject, RINGBUFFER_COUNT + sName);
    if (nCount == 0)
        return JsonNull();

    json jArray = GetLocalJson(oObject, RINGBUFFER_DATA + sName);
    int nTail = GetLocalInt(oObject, RINGBUFFER_TAIL + sName);
    json jValue = JsonArrayGet(jArray, nTail);

    JsonArraySetInplace(jArray, nTail, JsonNull());
    SetLocalInt(oObject, RINGBUFFER_TAIL + sName, (nTail + 1) % GetLocalInt(oObject, RINGBUFFER_SIZE + sName));
    SetLocalInt(oObject, RINGBUFFER_COUNT + sName, nCount - 1);

    return jValue;
}

string RingBuffer_PopString(object oObject, string sName)
{
    json jValue = RingBuffer_PopJson(oObject, sName);
    if (JsonGetType(jValue) == JSON_TYPE_STRING)
        return JsonGetString(jValue);
    return "";
}

int RingBuffer_PopInt(object oObject, string sName)
{
    json jValue = RingBuffer_PopJson(oObject, sName);
    if (JsonGetType(jValue) == JSON_TYPE_INTEGER)
        return JsonGetInt(jValue);
    return 0;
}

float RingBuffer_PopFloat(object oObject, string sName)
{
    json jValue = RingBuffer_PopJson(oObject, sName);
    if (JsonGetType(jValue) == JSON_TYPE_FLOAT)
        return JsonGetFloat(jValue);
    return 0.0f;
}

json RingBuffer_PeekJson(object oObject, string sName)
{
    int nCount = GetLocalInt(oObject, RINGBUFFER_COUNT + sName);
    if (nCount == 0)
        return JsonNull();
    return JsonArrayGet(GetLocalJson(oObject, RINGBUFFER_DATA + sName), GetLocalInt(oObject, RINGBUFFER_TAIL + sName));
}

string RingBuffer_PeekString(object oObject, string sName)
{
    json jValue = RingBuffer_PeekJson(oObject, sName);
    if (JsonGetType(jValue) == JSON_TYPE_STRING)
        return JsonGetString(jValue);
    return "";
}

int RingBuffer_PeekInt(object oObject, string sName)
{
    json jValue = RingBuffer_PeekJson(oObject, sName);
    if (JsonGetType(jValue) == JSON_TYPE_INTEGER)
        return JsonGetInt(jValue);
    return 0;
}

float RingBuffer_PeekFloat(object oObject, string sName)
{
    json jValue = RingBuffer_PeekJson(oObject, sName);
    if (JsonGetType(jValue) == JSON_TYPE_FLOAT)
        return JsonGetFloat(jValue);
    return 0.0f;
}

json RingBuffer_ToArray(object oObject, string sName)
{
    int nCount = GetLocalInt(oObject, RINGBUFFER_COUNT + sName);
    if (nCount == 0)
        return JsonArray();

    json jArray = GetLocalJson(oObject, RINGBUFFER_DATA + sName), jResult = JsonArray();
    int nTail = GetLocalInt(oObject, RINGBUFFER_TAIL + sName);
    int nSize = GetLocalInt(oObject, RINGBUFFER_SIZE + sName), nIndex;

    for (nIndex = 0; nIndex < nCount; nIndex++)
    {
        JsonArrayInsertInplace(jResult, JsonArrayGet(jArray, (nTail + nIndex) % nSize));
    }

    return jResult;
}
