/*
    Script: ef_s_bttest
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_c_profiler"
#include "ef_s_btbuilder"
#include "ef_s_objecttag"

const string BTT_SCRIPT_NAME            = "ef_s_bttest";

const string BTT_GUARD_TAG              = "BT_GUARD";
const string BTT_PATROL_WP_PREFIX       = "WP_PATROL_";
const int BTT_NUM_PATROL_WAYPOINTS      = 5;

json BT_Node_GetNextPatrolWaypoint(string sTargetObjectVariable, string sWaypointPrefix, int nNumberOfWaypoints, float fDistanceTolerance)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "GetNextPatrolWaypoint");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_GetNextPatrolWaypoint_Tick");
    BT_Node_SetDataString(jNode, "TargetObjectVariable", sTargetObjectVariable);
    BT_Node_SetDataString(jNode, "WaypointPrefix", sWaypointPrefix);
    BT_Node_SetDataInt(jNode, "NumberOfWaypoints", nNumberOfWaypoints);
    BT_Node_SetDataFloat(jNode, "DistanceTolerance", fDistanceTolerance);
    return jNode;
}

int BT_Node_GetNextPatrolWaypoint_Tick(json jNode, json jTickInfo)
{
    object oSelf = OBJECT_SELF;
    string sWaypointPrefix = BT_Node_GetDataString(jNode, "WaypointPrefix");
    int nNumberOfWayPoints = BT_Node_GetDataInt(jNode, "NumberOfWaypoints");

    object oNextWaypoint = OBJECT_INVALID;
    float fCurrentDistance = 1000.0f;
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
        float fDistanceTolerance = BT_Node_GetDataFloat(jNode, "DistanceTolerance");
        if (fCurrentDistance < fDistanceTolerance)
            oNextWaypoint = GetObjectByTag(sWaypointPrefix + IntToString((nSelectedIndex % nNumberOfWayPoints) + 1));
        string sTargetObjectVariable = BT_Node_GetDataString(jNode, "TargetObjectVariable");
        BT_Blackboard_ContextSetObject(BT_Blackboard_GetTreeContext(jTickInfo), sTargetObjectVariable, oNextWaypoint);
        return BT_NODE_STATE_SUCCESS;
    }

    return BT_NODE_STATE_FAILURE;
}

json BT_Node_MoveToObject(string sTargetObjectVariable, float fDistanceTolerance, int bRun = FALSE)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "MoveToObject");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_MoveToObject_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_MoveToObject_Tick");
    BT_Node_SetDataString(jNode, "TargetObjectVariable", sTargetObjectVariable);
    BT_Node_SetDataFloat(jNode, "DistanceTolerance", fDistanceTolerance);
    BT_Node_SetDataInt(jNode, "Run", bRun);
    return jNode;
}

void BT_Node_MoveToObject_Open(json jNode, json jTickInfo)
{
    ClearAllActions();
}

int BT_Node_MoveToObject_Tick(json jNode, json jTickInfo)
{
    string sTargetObjectVariable = BT_Node_GetDataString(jNode, "TargetObjectVariable");
    object oTarget = BT_Blackboard_ContextGetObject(BT_Blackboard_GetTreeContext(jTickInfo), sTargetObjectVariable);

    if (!GetIsObjectValid(oTarget))
        return BT_NODE_STATE_FAILURE;

    object oSelf = OBJECT_SELF;
    float fDistance = GetDistanceBetween(oSelf, oTarget);
    float fDistanceTolerance = BT_Node_GetDataFloat(jNode, "DistanceTolerance");

    if (fDistance <= fDistanceTolerance)
        return BT_NODE_STATE_SUCCESS;

    if (GetCurrentAction(oSelf) != ACTION_MOVETOPOINT)
    {
        int bRun = BT_Node_GetDataInt(jNode, "Run");
        ClearAllActions();
        ActionMoveToObject(oTarget, bRun, 1.0f);
    }

    return BT_NODE_STATE_RUNNING;
}

json BT_Node_SpeakString(string sText)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "SpeakString");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_SpeakString_Tick");
    BT_Node_SetDataString(jNode, "Text", sText);
    return jNode;
}

int BT_Node_SpeakString_Tick(json jNode, json jTickInfo)
{
    string sText = BT_Node_GetDataString(jNode, "Text");
    SpeakString(sText, TALKVOLUME_TALK);
    return BT_NODE_STATE_SUCCESS;
}

json BT_Node_PlayLoopingAnimation(int nAnimation, int nDuration)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "PlayLoopingAnimation");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BTT_SCRIPT_NAME, "BT_Node_PlayLoopingAnimation_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_PlayLoopingAnimation_Tick");
    BT_Node_SetDataInt(jNode, "Animation", nAnimation);
    BT_Node_SetDataInt(jNode, "Duration", nDuration);
    return jNode;
}

void BT_Node_PlayLoopingAnimation_Open(json jNode, json jTickInfo)
{
    int nAnimation = BT_Node_GetDataInt(jNode, "Animation");

    ClearAllActions();
    ActionPlayAnimation(nAnimation, 1.0f, 86400.0f);
    BT_Blackboard_ContextSetInt(BT_Blackboard_GetNodeContext(jTickInfo, jNode), "StartTime", SqlGetUnixEpoch());
}

int BT_Node_PlayLoopingAnimation_Tick(json jNode, json jTickInfo)
{
    int nDuration = BT_Node_GetDataInt(jNode, "Duration");
    int nStartTime = BT_Blackboard_ContextGetInt(BT_Blackboard_GetNodeContext(jTickInfo, jNode), "StartTime");

    if (SqlGetUnixEpoch() - nStartTime > nDuration)
        return BT_NODE_STATE_SUCCESS;
    else
        return BT_NODE_STATE_RUNNING;
}

json BT_Node_GetNearestSeat(string sTargetObjectVariable, string sSeatObjectTag)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "GetNearestSeat");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_GetNearestSeat_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_GetNearestSeat_Tick");
    BT_Node_SetDataString(jNode, "TargetObjectVariable", sTargetObjectVariable);
    BT_Node_SetDataString(jNode, "SeatObjectTag", sSeatObjectTag);
    return jNode;
}

void BT_Node_GetNearestSeat_Open(json jNode, json jTickInfo)
{
    string sTargetObjectVariable = BT_Node_GetDataString(jNode, "TargetObjectVariable");
    BT_Blackboard_ContextSetObject(BT_Blackboard_GetTreeContext(jTickInfo), sTargetObjectVariable, OBJECT_INVALID);
}

int BT_Node_GetNearestSeat_Tick(json jNode, json jTickInfo)
{
    object oSelf = OBJECT_SELF;
    string sSeatObjectTag = BT_Node_GetDataString(jNode, "SeatObjectTag");
    object oSeat = ObjectTag_GetNearestObjectWithTag(oSelf, sSeatObjectTag);

    if (GetIsObjectValid(oSeat))
    {
        string sTargetObjectVariable = BT_Node_GetDataString(jNode, "TargetObjectVariable");
        BT_Blackboard_ContextSetObject(BT_Blackboard_GetTreeContext(jTickInfo), sTargetObjectVariable, oSeat);
        return BT_NODE_STATE_SUCCESS;
    }

    return BT_NODE_STATE_FAILURE;
}


json BT_Node_Sit(string sTargetObjectVariable)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "Sit");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_Sit_Tick");
    BT_Node_SetDataString(jNode, "TargetObjectVariable", sTargetObjectVariable);
    return jNode;
}

int BT_Node_Sit_Tick(json jNode, json jTickInfo)
{
    object oSelf = OBJECT_SELF;
    string sTargetObjectVariable = BT_Node_GetDataString(jNode, "TargetObjectVariable");
    object oSeat = BT_Blackboard_ContextGetObject(BT_Blackboard_GetTreeContext(jTickInfo), sTargetObjectVariable);

    if (GetIsObjectValid(oSeat))
    {
        object oSittingCreature = GetSittingCreature(oSeat);
        if (GetIsObjectValid(oSittingCreature) && oSittingCreature != oSelf)
            return BT_NODE_STATE_FAILURE;

        if (GetCurrentAction(oSelf) != ACTION_SIT)
        {
            ClearAllActions();
            ActionSit(oSeat);
        }
        return BT_NODE_STATE_RUNNING;
    }

    return BT_NODE_STATE_FAILURE;
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
    string sSeatObject = "SeatObject";
    string sWaypointObject = "WaypointObject";

    BTB_InitializeBehaviorTree();
        BTB_StartReactiveFallback();
            BTB_StartSequence("Rest");
                BTB_StartRandomCooldown(120, 61);
                    BTB_AddNode(BT_Node_GetNearestSeat(sSeatObject, "SEAT"));
                BTB_End();
                BTB_AddNode(BT_Node_MoveToObject(sSeatObject, 2.5f, FALSE));
                BTB_StartForceSuccess();
                    BTB_StartProbability(25);
                        BTB_AddNode(BT_Node_SpeakString("Whew."));
                    BTB_End();
                BTB_End();
                BTB_StartRandomTimeout(15, 16);
                    BTB_AddNode(BT_Node_Sit(sSeatObject));
                BTB_End();
            BTB_End();
            BTB_StartSequence("Patrol");
                BTB_AddNode(BT_Node_GetNextPatrolWaypoint(sWaypointObject, BTT_PATROL_WP_PREFIX, BTT_NUM_PATROL_WAYPOINTS, 5.0f));
                BTB_AddNode(BT_Node_MoveToObject(sWaypointObject, 2.5f, FALSE));
                BTB_AddNode(BT_Node_PlayLoopingAnimation(ANIMATION_LOOPING_LOOK_FAR, 2));
                BTB_StartForceSuccess();
                    BTB_StartRandomCooldown(30, 31);
                        BTB_AddNode(BT_Node_SpeakString("Nothin' to see here..."));
                    BTB_End();
                BTB_End();
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
