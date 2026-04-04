/*
    Script: ef_s_closedoor
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_eventman"
#include "nwnx_object"
#include "nwnx_util"

const string CLOSEDOOR_SCRIPT_NAME      = "ef_s_closedoor";
const int CLOSEDOOR_EVENT_PRIORITY      = 10;
const float CLOSEDOOR_CLOSE_DELAY       = 7.5f;

// @CORE[CORE_SYSTEM_LOAD]
void CloseDoor_Load()
{
    int nObjectDispatchListId = EM_GetObjectDispatchListId(CLOSEDOOR_SCRIPT_NAME, EVENT_SCRIPT_DOOR_ON_OPEN, CLOSEDOOR_EVENT_PRIORITY);
    sqlquery sql = SqlPrepareQueryModule("SELECT oid FROM gameobjects WHERE type=@type AND ISAUTOCLOSEDOOR(oid);");
    SqlBindInt(sql, "@type", OBJECT_TYPE_INTERNAL_DOOR);
    while (SqlStep(sql))
    {
        object oDoor = SqlGetObjectRef(sql, 0);
        EM_SetObjectEventScript(oDoor, EVENT_SCRIPT_DOOR_ON_OPEN);
        EM_ObjectDispatchListInsert(oDoor, nObjectDispatchListId);
    }
}

// @EVENT[EVENT_SCRIPT_DOOR_ON_OPEN:DL:CLOSEDOOR_EVENT_PRIORITY]
void CloseDoor_OnOpen()
{
    ClearAllActions();
    ActionWait(CLOSEDOOR_CLOSE_DELAY);
    ActionCloseDoor(OBJECT_SELF);
}

// @SQLFUNCTION[ISAUTOCLOSEDOOR:TRUE:TRUE]
int CloseDoor_IsAutoCloseDoor()
{
    return !GetLocalInt(OBJECT_SELF, "NO_AUTO_CLOSE") && NWNX_Object_GetDoorHasVisibleModel(OBJECT_SELF);
}
