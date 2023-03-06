/*
    Script: ef_i_dataobject
    Author: Daz

    Description: Equinox Framework DataObject Utility Include
*/

#include "ef_i_vm"

const string EF_DATAOBJECT_TAG_PREFIX       = "EFDataObject_";

// Create a waypoint at locLocation with sTag
object CreateWaypoint(location locLocation, string sTag);
// Create a new data object with sTag
object CreateDataObject(string sTag, int bDestroyExisting = TRUE);
// Destroy a data object with sTag
void DestroyDataObject(string sTag);
// Get a data object with sTag
object GetDataObject(string sTag, int bCreateIfNotExists = TRUE);
// Get the data object for the calling system
object GetSystemDataObject(string sTag = "");

object CreateWaypoint(location locLocation, string sTag)
{
    return CreateObject(OBJECT_TYPE_WAYPOINT, "nw_waypoint001", locLocation, FALSE, sTag);
}

object CreateDataObject(string sTag, int bDestroyExisting = TRUE)
{
    if (bDestroyExisting)
        DestroyDataObject(sTag);

    object oDataObject = CreateWaypoint(GetStartingLocation(), EF_DATAOBJECT_TAG_PREFIX + sTag);
    SetLocalObject(GetModule(), EF_DATAOBJECT_TAG_PREFIX + sTag, oDataObject);

    return oDataObject;
}

void DestroyDataObject(string sTag)
{
    object oDataObject = GetLocalObject(GetModule(), EF_DATAOBJECT_TAG_PREFIX + sTag);

    if (GetIsObjectValid(oDataObject))
    {
        DeleteLocalObject(GetModule(), EF_DATAOBJECT_TAG_PREFIX + sTag);
        DestroyObject(oDataObject);
    }
}

object GetDataObject(string sTag, int bCreateIfNotExists = TRUE)
{
    object oDataObject = GetLocalObject(GetModule(), EF_DATAOBJECT_TAG_PREFIX + sTag);
    return GetIsObjectValid(oDataObject) ? oDataObject : bCreateIfNotExists ? CreateDataObject(sTag) : OBJECT_INVALID;
}

object GetSystemDataObject(string sTag = "")
{
    return GetDataObject(GetVMFrameScript(1) + sTag != "" ? ("_" + sTag) : "");
}
