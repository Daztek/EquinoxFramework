/*
    Script: ef_s_closedoor
    Author: Daz

    Description: An Equinox Framework System that automatically closes doors.
*/

#include "ef_i_core"
#include "ef_s_events"
#include "nwnx_object"

const string CLOSEDOOR_LOG_TAG      = "CloseDoor";
const string CLOSEDOOR_SCRIPT_NAME  = "ef_s_closedoor";

const float CLOSEDOOR_CLOSE_DELAY   = 7.5f;

// @CORE[EF_SYSTEM_LOAD]
void CloseDoor_Load()
{
    object oDoor;
    int nNth = 0;
    string sDoorOnOpenEvent = Events_GetObjectEventName(EVENT_SCRIPT_DOOR_ON_OPEN, EVENTS_OBJECT_EVENT_TYPE_AFTER);

    while ((oDoor = NWNX_Util_GetLastCreatedObject(10, ++nNth)) != OBJECT_INVALID)
    {
        if (NWNX_Object_GetDoorHasVisibleModel(oDoor))
        {
            Events_SetObjectEventScript(oDoor, EVENT_SCRIPT_DOOR_ON_OPEN);
            Events_AddObjectToDispatchList(CLOSEDOOR_SCRIPT_NAME, sDoorOnOpenEvent, oDoor);
        }
    }
}

// @EVENT[DL:EVENT_SCRIPT_DOOR_ON_OPEN:A]
void CloseDoor_OnOpen()
{
    ClearAllActions();
    ActionWait(CLOSEDOOR_CLOSE_DELAY);
    ActionCloseDoor(OBJECT_SELF);
}

