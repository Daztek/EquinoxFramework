/*
    Script: ef_s_closedoor
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_eventman"
#include "nwnx_object"

const string CLOSEDOOR_SCRIPT_NAME      = "ef_s_closedoor";
const int CLOSEDOOR_EVENT_PRIORITY      = 10;
const float CLOSEDOOR_CLOSE_DELAY       = 7.5f;

// @CORE[CORE_SYSTEM_LOAD]
void CloseDoor_Load()
{
    object oDoor;
    int nNth = 0;
    int nObjectDispatchListId = EM_GetObjectDispatchListId(CLOSEDOOR_SCRIPT_NAME, EVENT_SCRIPT_DOOR_ON_OPEN, CLOSEDOOR_EVENT_PRIORITY);

    while ((oDoor = NWNX_Util_GetLastCreatedObject(10, ++nNth)) != OBJECT_INVALID)
    {
        if (NWNX_Object_GetDoorHasVisibleModel(oDoor) && !GetLocalInt(oDoor, "NO_AUTO_CLOSE"))
        {
            EM_SetObjectEventScript(oDoor, EVENT_SCRIPT_DOOR_ON_OPEN);
            EM_ObjectDispatchListInsert(oDoor, nObjectDispatchListId);
        }
    }
}

// @EVENT[EVENT_SCRIPT_DOOR_ON_OPEN:DL:CLOSEDOOR_EVENT_PRIORITY]
void CloseDoor_OnOpen()
{
    ClearAllActions();
    ActionWait(CLOSEDOOR_CLOSE_DELAY);
    ActionCloseDoor(OBJECT_SELF);
}
