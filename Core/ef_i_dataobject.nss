/*
    Script: ef_i_dataobject
    Author: Daz
*/

const string DATAOBJECT_TAG_PREFIX       = "DO_";

object CreateWaypoint(location locLocation, string sTag);
void SetDataObject(string sTag, object oDataObject);
object CreateDataObject(string sTag, int bDestroyExisting = TRUE);
void DestroyDataObject(string sTag);
object GetDataObject(string sTag, int bCreateIfNotExists = TRUE);

object CreateWaypoint(location locLocation, string sTag)
{
    return CreateObject(OBJECT_TYPE_WAYPOINT, "nw_waypoint001", locLocation, FALSE, sTag);
}

void SetDataObject(string sTag, object oDataObject)
{
    SetLocalObject(GetModule(), DATAOBJECT_TAG_PREFIX + sTag, oDataObject);
}

object CreateDataObject(string sTag, int bDestroyExisting = TRUE)
{
    if (bDestroyExisting)
        DestroyDataObject(sTag);

    object oDataObject = CreateWaypoint(GetStartingLocation(), DATAOBJECT_TAG_PREFIX + sTag);
    SetDataObject(sTag, oDataObject);

    return oDataObject;
}

void DestroyDataObject(string sTag)
{
    object oDataObject = GetLocalObject(GetModule(), DATAOBJECT_TAG_PREFIX + sTag);

    if (GetIsObjectValid(oDataObject))
    {
        DeleteLocalObject(GetModule(), DATAOBJECT_TAG_PREFIX + sTag);
        DestroyObject(oDataObject);
    }
}

object GetDataObject(string sTag, int bCreateIfNotExists = TRUE)
{
    object oDataObject = GetLocalObject(GetModule(), DATAOBJECT_TAG_PREFIX + sTag);
    return oDataObject != OBJECT_INVALID ? oDataObject : bCreateIfNotExists ? CreateDataObject(sTag) : OBJECT_INVALID;
}
