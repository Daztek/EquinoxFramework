/*
    Script: ef_s_bttest
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_c_profiler"
#include "ef_s_btbuilder"

const string BTT_SCRIPT_NAME            = "ef_s_bttest";

const string BTT_GUARD_TAG              = "BT_GUARD";
const string BTT_PATROL_WP_PREFIX       = "WP_PATROL_";
const int BTT_NUM_PATROL_WAYPOINTS      = 5;
const float BTT_DISTANCE_TOLERANCE      = 2.5f;

json BT_Node_SelectNextPatrolWaypoint(string sWaypointPrefix, int nNumberOfWaypoints)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "SelectNextPatrolWaypoint");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_SelectNextPatrolWaypoint_Tick");
    BT_Node_SetData(jNode, "WaypointPrefix", JsonString(sWaypointPrefix));
    BT_Node_SetData(jNode, "NumberOfWaypoints", JsonInt(nNumberOfWaypoints));
    return jNode;
}

int BT_Node_SelectNextPatrolWaypoint_Tick(json jNode, json jTickInfo)
{
    object oSelf = BT_TickInfo_GetSelf(jTickInfo);
    string sWaypointPrefix = JsonGetString(BT_Node_GetData(jNode, "WaypointPrefix"));
    int nNumberOfWayPoints = JsonGetInt(BT_Node_GetData(jNode, "NumberOfWaypoints"));

    object oNextWaypoint = OBJECT_INVALID;
    float fCurrentDistance = 500.0f;
    int nIndex, nSelectedIndex;
    for (nIndex = 1; nIndex <= nNumberOfWayPoints; nIndex++)
    {
        object oWaypoint = GetObjectByTag(sWaypointPrefix + IntToString(nIndex));
        float fDistance = GetDistanceBetween(oSelf, oWaypoint);
        if (fDistance < fCurrentDistance)
        {
            fCurrentDistance = fDistance;
            oNextWaypoint = oWaypoint;
            nSelectedIndex = nIndex;
        }
    }

    if (GetIsObjectValid(oNextWaypoint))
    {
        if (fCurrentDistance <= BTT_DISTANCE_TOLERANCE)
            oNextWaypoint = GetObjectByTag(sWaypointPrefix + IntToString((nSelectedIndex % nNumberOfWayPoints) + 1));
        BT_Blackboard_SetValue(BT_TickInfo_GetBlackboard(jTickInfo), "MoveToObject",
            JsonString(ObjectToString(oNextWaypoint)), BT_TickInfo_GetBehaviorTreeID(jTickInfo));
        return BT_NODE_STATE_SUCCESS;
    }

    return BT_NODE_STATE_FAILURE;
}

json BT_Node_MoveToObject(float fDistanceTolerance)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "MoveToObject");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_MoveToObject_Tick");
    BT_Node_SetData(jNode, "DistanceTolerance", JsonFloat(fDistanceTolerance));
    return jNode;
}

int BT_Node_MoveToObject_Tick(json jNode, json jTickInfo)
{
    object oSelf = BT_TickInfo_GetSelf(jTickInfo);
    float fDistanceTolerance = JsonGetFloat(BT_Node_GetData(jNode, "DistanceTolerance"));
    object oTarget = StringToObject(JsonGetString(BT_Blackboard_GetValue(BT_TickInfo_GetBlackboard(jTickInfo),
        "MoveToObject", BT_TickInfo_GetBehaviorTreeID(jTickInfo))));
    float fDistance = GetDistanceBetween(oSelf, oTarget);

    if (fDistance <= fDistanceTolerance)
        return BT_NODE_STATE_SUCCESS;

    if (GetCurrentAction(oSelf) != ACTION_MOVETOPOINT)
    {
        AssignCommand(oSelf, ClearAllActions());
        AssignCommand(oSelf, ActionMoveToObject(oTarget, FALSE, 1.0f));
    }

    return BT_NODE_STATE_RUNNING;
}

json BT_Node_SpeakString(string sText)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "SpeakString");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_SpeakString_Tick");
    BT_Node_SetData(jNode, "Text", JsonString(sText));
    return jNode;
}

int BT_Node_SpeakString_Tick(json jNode, json jTickInfo)
{
    object oSelf = BT_TickInfo_GetSelf(jTickInfo);
    string sText = JsonGetString(BT_Node_GetData(jNode, "Text"));

    string sScriptChunk = nssFunction("SpeakString", nssEscape(sText) + ", TALKVOLUME_TALK");
    ExecuteScriptChunk(sScriptChunk, oSelf, TRUE);

    return BT_NODE_STATE_SUCCESS;
}

json BT_Node_PlayLoopingAnimation(int nAnimation, int nDuration)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "PlayLoopingAnimation");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BTT_SCRIPT_NAME, "BT_Node_PlayLoopingAnimation_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_PlayLoopingAnimation_Tick");
    BT_Node_SetData(jNode, "Animation", JsonInt(nAnimation));
    BT_Node_SetData(jNode, "Duration", JsonInt(nDuration));
    return jNode;
}

void BT_Node_PlayLoopingAnimation_Open(json jNode, json jTickInfo)
{
    object oSelf = BT_TickInfo_GetSelf(jTickInfo);
    int nAnimation = JsonGetInt(BT_Node_GetData(jNode, "Animation"));

    AssignCommand(oSelf, ClearAllActions());
    AssignCommand(oSelf, ActionPlayAnimation(nAnimation, 1.0f, 600.0f));

    BT_Blackboard_StructSetValue(BT_Blackboard_GetInfo(jTickInfo, jNode), "StartTime", JsonInt(SqlGetUnixEpoch()));
}

int BT_Node_PlayLoopingAnimation_Tick(json jNode, json jTickInfo)
{
    int nDuration = JsonGetInt(BT_Node_GetData(jNode, "Duration"));
    int nStartTime = JsonGetInt(BT_Blackboard_StructGetValue(BT_Blackboard_GetInfo(jTickInfo, jNode), "StartTime"));

    if (SqlGetUnixEpoch() - nStartTime > nDuration)
    {
        object oSelf = BT_TickInfo_GetSelf(jTickInfo);
        AssignCommand(oSelf, ClearAllActions());
        AssignCommand(oSelf, ActionPlayAnimation(ANIMATION_LOOPING_PAUSE, 1.0f, 0.1f));
        return BT_NODE_STATE_SUCCESS;
    }

    return BT_NODE_STATE_RUNNING;
}

void BTT_RecursiveTick(object oBehaviorTree, object oBlackboard, object oSelf)
{
    Profiler_Start("BTT_RecursiveTick");
    BT_BehaviorTree_Tick(oBehaviorTree, oBlackboard, oSelf);
    PrintString(Profiler_Stop());
    DelayCommand(2.5f, BTT_RecursiveTick(oBehaviorTree, oBlackboard, oSelf));
}

// @CORE[CORE_SYSTEM_POST]
void BTT_Post()
{
    BTB_InitializeBehaviorTree();
        BTB_StartReactiveFallback();
            BTB_StartCooldown(30);
                BTB_AddNode(BT_Node_SpeakString("Nothin' happening here..."));
            BTB_End();
            BTB_StartSequence();
                BTB_AddNode(BT_Node_SelectNextPatrolWaypoint(BTT_PATROL_WP_PREFIX, BTT_NUM_PATROL_WAYPOINTS));
                BTB_AddNode(BT_Node_MoveToObject(2.0f));
                BTB_AddNode(BT_Node_PlayLoopingAnimation(ANIMATION_LOOPING_LOOK_FAR, 3));
            BTB_End();
        BTB_End();
    json jTree = BTB_FinalizeBehaviorTree();
    PrintString(BT_DebugPrintTree(jTree));

    object oGuard = GetObjectByTag(BTT_GUARD_TAG);
    object oBlackboard = BT_Blackboard_GetOrCreate("GuardPatrolBB");
    object oBehaviorTree = BT_BehaviorTree_GetOrCreate("GuardPatrolBT");
    BT_BehaviorTree_SetGraphVizEnabled(oBehaviorTree, BT_GRAPHVIZ_ENABLED);
    BT_BehaviorTree_SetRoot(oBehaviorTree, jTree);

    DelayCommand(5.0f, BTT_RecursiveTick(oBehaviorTree, oBlackboard, oGuard));
}
