/*
    Script: ef_i_array
    Author: Daz
*/

// *** STRING

void StringArray_Insert(object oObject, string sArrayName, string sValue);
void StringArray_Set(object oObject, string sArrayName, int nIndex, string sValue);
int StringArray_Size(object oObject, string sArrayName);
string StringArray_At(object oObject, string sArrayName, int nIndex);
void StringArray_Clear(object oObject, string sArrayName, int bFast = FALSE);
int StringArray_Contains(object oObject, string sArrayName, string sValue);
void StringArray_Delete(object oObject, string sArrayName, int nIndex);
void StringArray_DeleteByValue(object oObject, string sArrayName, string sValue);

void StringArray_Insert(object oObject, string sArrayName, string sValue)
{
    int nSize = StringArray_Size(oObject, sArrayName);
    SetLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nSize), sValue);
    SetLocalInt(oObject, "SA!NUM!" + sArrayName, ++nSize);
}

void StringArray_Set(object oObject, string sArrayName, int nIndex, string sValue)
{
    int nSize = StringArray_Size(oObject, sArrayName);

    if (nIndex < nSize)
        SetLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex), sValue);
}

int StringArray_Size(object oObject, string sArrayName)
{
    return GetLocalInt(oObject, "SA!NUM!" + sArrayName);
}

string StringArray_At(object oObject, string sArrayName, int nIndex)
{
    return GetLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
}

void StringArray_Clear(object oObject, string sArrayName, int bFast = FALSE)
{
    if (bFast)
        DeleteLocalInt(oObject, "SA!NUM!" + sArrayName);
    else
    {
        int nSize = StringArray_Size(oObject, sArrayName), nIndex;

        if (nSize)
        {
            for (nIndex = 0; nIndex < nSize; nIndex++)
            {
                DeleteLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
            }

            DeleteLocalInt(oObject, "SA!NUM!" + sArrayName);
        }
    }
}

int StringArray_Contains(object oObject, string sArrayName, string sValue)
{
    int nSize = StringArray_Size(oObject, sArrayName), nIndex;

    if (nSize)
    {
        for (nIndex = 0; nIndex < nSize; nIndex++)
        {
            string sElement = StringArray_At(oObject, sArrayName, nIndex);

            if (sElement == sValue)
            {
                return nIndex;
            }
        }
    }

    return -1;
}

void StringArray_Delete(object oObject, string sArrayName, int nIndex)
{
    int nSize = StringArray_Size(oObject, sArrayName), nIndexNew;
    if (nIndex < nSize)
    {
        for (nIndexNew = nIndex; nIndexNew < nSize - 1; nIndexNew++)
        {
            StringArray_Set(oObject, sArrayName, nIndexNew, StringArray_At(oObject, sArrayName, nIndexNew + 1));
        }

        DeleteLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nSize - 1));
        SetLocalInt(oObject, "SA!NUM!" + sArrayName, nSize - 1);
    }
}

void StringArray_DeleteByValue(object oObject, string sArrayName, string sValue)
{
    int nSize = StringArray_Size(oObject, sArrayName), nIndex;
    string sElement;

    for (nIndex = 0; nIndex < nSize; nIndex++)
    {
        sElement = StringArray_At(oObject, sArrayName, nIndex);

        if (sElement == sValue)
        {
            StringArray_Delete(oObject, sArrayName, nIndex);
            break;
        }
   }
}

// *** OBJECT

void ObjectArray_Insert(object oObject, string sArrayName, object oValue);
void ObjectArray_Set(object oObject, string sArrayName, int nIndex, object oValue);
int ObjectArray_Size(object oObject, string sArrayName);
object ObjectArray_At(object oObject, string sArrayName, int nIndex);
void ObjectArray_Clear(object oObject, string sArrayName, int bFast = FALSE);
int ObjectArray_Contains(object oObject, string sArrayName, object oValue);
void ObjectArray_Delete(object oObject, string sArrayName, int nIndex);
void ObjectArray_DeleteByValue(object oObject, string sArrayName, object oValue);

void ObjectArray_Insert(object oObject, string sArrayName, object oValue)
{
    int nSize = ObjectArray_Size(oObject, sArrayName);
    SetLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nSize), oValue);
    SetLocalInt(oObject, "OA!NUM!" + sArrayName, ++nSize);
}

void ObjectArray_Set(object oObject, string sArrayName, int nIndex, object oValue)
{
    int nSize = ObjectArray_Size(oObject, sArrayName);

    if (nIndex < nSize)
        SetLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex), oValue);
}

int ObjectArray_Size(object oObject, string sArrayName)
{
    return GetLocalInt(oObject, "OA!NUM!" + sArrayName);
}

object ObjectArray_At(object oObject, string sArrayName, int nIndex)
{
    return GetLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
}

void ObjectArray_Clear(object oObject, string sArrayName, int bFast = FALSE)
{
    if (bFast)
        DeleteLocalInt(oObject, "OA!NUM!" + sArrayName);
    else
    {
        int nSize = ObjectArray_Size(oObject, sArrayName), nIndex;

        if (nSize)
        {
            for (nIndex = 0; nIndex < nSize; nIndex++)
            {
                DeleteLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
            }

            DeleteLocalInt(oObject, "OA!NUM!" + sArrayName);
        }
    }
}

int ObjectArray_Contains(object oObject, string sArrayName, object oValue)
{
    int nSize = ObjectArray_Size(oObject, sArrayName), nIndex;
    object oElement;

    if (nSize)
    {
        for (nIndex = 0; nIndex < nSize; nIndex++)
        {
            oElement = ObjectArray_At(oObject, sArrayName, nIndex);

            if (oElement == oValue)
            {
                return nIndex;
            }
        }
    }

    return -1;
}

void ObjectArray_Delete(object oObject, string sArrayName, int nIndex)
{
    int nSize = ObjectArray_Size(oObject, sArrayName), nIndexNew;
    if (nIndex < nSize)
    {
        for (nIndexNew = nIndex; nIndexNew < nSize - 1; nIndexNew++)
        {
            ObjectArray_Set(oObject, sArrayName, nIndexNew, ObjectArray_At(oObject, sArrayName, nIndexNew + 1));
        }

        DeleteLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nSize - 1));
        SetLocalInt(oObject, "OA!NUM!" + sArrayName, nSize - 1);
    }
}

void ObjectArray_DeleteByValue(object oObject, string sArrayName, object oValue)
{
    int nSize = ObjectArray_Size(oObject, sArrayName), nIndex;
    object oElement;

    for (nIndex = 0; nIndex < nSize; nIndex++)
    {
        oElement = ObjectArray_At(oObject, sArrayName, nIndex);

        if (oElement == oValue)
        {
            ObjectArray_Delete(oObject, sArrayName, nIndex);
            break;
        }
   }
}

// *** INT

void IntArray_Insert(object oObject, string sArrayName, int nValue);
void IntArray_Set(object oObject, string sArrayName, int nIndex, int nValue);
int IntArray_Size(object oObject, string sArrayName);
void IntArray_SetSize(object oObject, string sArrayName, int nSize);
int IntArray_At(object oObject, string sArrayName, int nIndex);
void IntArray_Clear(object oObject, string sArrayName, int bFast = FALSE);
int IntArray_Contains(object oObject, string sArrayName, int nValue);
void IntArray_Delete(object oObject, string sArrayName, int nIndex);
void IntArray_DeleteByValue(object oObject, string sArrayName, int nValue);

void IntArray_Insert(object oObject, string sArrayName, int nValue)
{
    int nSize = IntArray_Size(oObject, sArrayName);
    SetLocalInt(oObject, "IA!ELEMENT!" + sArrayName + "!" + IntToString(nSize), nValue);
    SetLocalInt(oObject, "IA!NUM!" + sArrayName, ++nSize);
}

void IntArray_Set(object oObject, string sArrayName, int nIndex, int nValue)
{
    int nSize = IntArray_Size(oObject, sArrayName);

    if (nIndex < nSize)
        SetLocalInt(oObject, "IA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex), nValue);
}

int IntArray_Size(object oObject, string sArrayName)
{
    return GetLocalInt(oObject, "IA!NUM!" + sArrayName);
}

void IntArray_SetSize(object oObject, string sArrayName, int nSize)
{
    SetLocalInt(oObject, "IA!NUM!" + sArrayName, nSize);
}

int IntArray_At(object oObject, string sArrayName, int nIndex)
{
    return GetLocalInt(oObject, "IA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
}

void IntArray_Clear(object oObject, string sArrayName, int bFast = FALSE)
{
    if (bFast)
        DeleteLocalInt(oObject, "IA!NUM!" + sArrayName);
    else
    {
        int nSize = ObjectArray_Size(oObject, sArrayName), nIndex;

        if (nSize)
        {
            for (nIndex = 0; nIndex < nSize; nIndex++)
            {
                DeleteLocalInt(oObject, "IA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
            }

            DeleteLocalInt(oObject, "IA!NUM!" + sArrayName);
        }
    }
}

int IntArray_Contains(object oObject, string sArrayName, int nValue)
{
    int nSize = IntArray_Size(oObject, sArrayName), nIndex;
    int nElement;

    if (nSize)
    {
        for (nIndex = 0; nIndex < nSize; nIndex++)
        {
            nElement = IntArray_At(oObject, sArrayName, nIndex);

            if (nElement == nValue)
            {
                return nIndex;
            }
        }
    }

    return -1;
}

void IntArray_Delete(object oObject, string sArrayName, int nIndex)
{
    int nSize = IntArray_Size(oObject, sArrayName), nIndexNew;
    if (nIndex < nSize)
    {
        for (nIndexNew = nIndex; nIndexNew < nSize - 1; nIndexNew++)
        {
            IntArray_Set(oObject, sArrayName, nIndexNew, IntArray_At(oObject, sArrayName, nIndexNew + 1));
        }

        DeleteLocalInt(oObject, "IA!ELEMENT!" + sArrayName + "!" + IntToString(nSize - 1));
        SetLocalInt(oObject, "IA!NUM!" + sArrayName, nSize - 1);
    }
}

void IntArray_DeleteByValue(object oObject, string sArrayName, int nValue)
{
    int nSize = IntArray_Size(oObject, sArrayName), nIndex;
    int nElement;

    for (nIndex = 0; nIndex < nSize; nIndex++)
    {
        nElement = IntArray_At(oObject, sArrayName, nIndex);

        if (nElement == nValue)
        {
            IntArray_Delete(oObject, sArrayName, nIndex);
            break;
        }
   }
}
