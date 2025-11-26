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
const string BTT_PATROL_WAYPOINT_PREFIX = "WP_EFPATROL_";
const string BTT_PATROL_OBJECT_TAG      = "PatrolWaypoint";
const string BTT_PATROL_CONNECTIONS     = "Connections";

// @CORE[CORE_SYSTEM_LOAD]
void BTT_Load()
{
    string sQuery = "SELECT oid FROM gameobjects WHERE type = @type AND tag LIKE @tag ESCAPE '!';";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@type", OBJECT_TYPE_INTERNAL_WAYPOINT);
    SqlBindString(sql, "@tag", SqlEscapeWildcard(BTT_PATROL_WAYPOINT_PREFIX, "_", "!") + "%");

    while (SqlStep(sql))
    {
        object oPatrolWaypoint = SqlGetObjectRef(sql, 0);
        string sConnections = GetLocalString(oPatrolWaypoint, BTT_PATROL_CONNECTIONS);
        if (sConnections != "")
        {
            json jConnections = JsonArray();
            json jRegex = RegExpIterate("[^,\\s][^,]*[^,\\s]*|[^,\\s]+", sConnections);
            int nIndex, nNumItems = JsonGetLength(jRegex);
            for (nIndex = 0; nIndex < nNumItems; nIndex++)
            {
                JsonArrayInsertInplace(jConnections, JsonArrayGet(JsonArrayGet(jRegex, nIndex), 0));
            }
            SetLocalJson(oPatrolWaypoint, BTT_PATROL_CONNECTIONS, jConnections);
            ObjectTag_Add(oPatrolWaypoint, BTT_PATROL_OBJECT_TAG);
        }
        else
        {
            LogWarning("Patrol Waypoint without Connections: {oPatrolWaypoint}");
        }
    }
}

json BT_Node_GetNextPatrolWaypoint(string sWaypointObjectTag, float fDistanceTolerance, string sOutput)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "GetNextPatrolWaypoint");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_GetNextPatrolWaypoint_Tick");
    BT_Node_SetOutput(jNode, sOutput);
    BT_Node_SetDataString(jNode, "WaypointObjectTag", sWaypointObjectTag);
    BT_Node_SetDataFloat(jNode, "DistanceTolerance", fDistanceTolerance);
    return jNode;
}

int BT_Node_GetNextPatrolWaypoint_Tick(json jNode)
{
    object oSelf = OBJECT_SELF;
    string sWaypointObjectTag = BT_Node_GetDataString(jNode, "WaypointObjectTag");
    object oNearestWaypoint = ObjectTag_GetNearestObjectWithTag(oSelf, sWaypointObjectTag);

    if (GetIsObjectValid(oNearestWaypoint))
    {
        float fDistanceTolerance = BT_Node_GetDataFloat(jNode, "DistanceTolerance");
        if (GetDistanceBetween(oSelf, oNearestWaypoint) < fDistanceTolerance)
        {
            json jConnections = GetLocalJson(oNearestWaypoint, BTT_PATROL_CONNECTIONS);
            string sNextWaypointTag = BTT_PATROL_WAYPOINT_PREFIX + JsonArrayGetString(jConnections, Random(JsonGetLength(jConnections)));
            oNearestWaypoint = GetObjectByTag(sNextWaypointTag);

            if (!GetIsObjectValid(oNearestWaypoint))
                return BT_NODE_STATE_FAILURE;
        }
        BT_Blackboard_ContextSetObject(BT_Blackboard_GetTreeContext(), BT_Node_GetOutput(jNode), oNearestWaypoint);
        return BT_NODE_STATE_SUCCESS;
    }

    return BT_NODE_STATE_FAILURE;
}

json BT_Node_MoveToObject(string sInput, float fDistanceTolerance, int bRun = FALSE)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "MoveToObject");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BTT_SCRIPT_NAME, "BT_Node_MoveToObject_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_MoveToObject_Tick");
    BT_Node_SetInput(jNode, sInput);
    BT_Node_SetDataFloat(jNode, "DistanceTolerance", fDistanceTolerance);
    BT_Node_SetDataInt(jNode, "Run", bRun);
    return jNode;
}

void BT_Node_MoveToObject_Open(json jNode)
{
    ClearAllActions();
}

int BT_Node_MoveToObject_Tick(json jNode)
{
    object oTarget = BT_Blackboard_ContextGetObject(BT_Blackboard_GetTreeContext(), BT_Node_GetInput(jNode));

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

int BT_Node_SpeakString_Tick(json jNode)
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

void BT_Node_PlayLoopingAnimation_Open(json jNode)
{
    int nAnimation = BT_Node_GetDataInt(jNode, "Animation");
    int nDuration = BT_Node_GetDataInt(jNode, "Duration");

    ClearAllActions();
    ActionPlayAnimation(nAnimation, 1.0f, IntToFloat(nDuration));
    BT_Blackboard_ContextSetInt(BT_Blackboard_GetNodeContext(jNode), "StartTime", GetCurrentTimeSeconds());
}

int BT_Node_PlayLoopingAnimation_Tick(json jNode)
{
    int nDuration = BT_Node_GetDataInt(jNode, "Duration");
    int nStartTime = BT_Blackboard_ContextGetInt(BT_Blackboard_GetNodeContext(jNode), "StartTime");

    if (GetCurrentTimeSeconds() - nStartTime > nDuration)
    {
        ClearAllActions();
        return BT_NODE_STATE_SUCCESS;
    }
    else
        return BT_NODE_STATE_RUNNING;
}

json BT_Node_GetNearestSeat(string sSeatObjectTag, string sOutput)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "GetNearestSeat");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_GetNearestSeat_Tick");
    BT_Node_SetOutput(jNode, sOutput);
    BT_Node_SetDataString(jNode, "SeatObjectTag", sSeatObjectTag);
    return jNode;
}

int BT_Node_GetNearestSeat_Tick(json jNode)
{
    object oSelf = OBJECT_SELF;
    string sSeatObjectTag = BT_Node_GetDataString(jNode, "SeatObjectTag");
    object oSeat = ObjectTag_GetNearestObjectWithTag(oSelf, sSeatObjectTag);

    if (GetIsObjectValid(oSeat))
    {
        BT_Blackboard_ContextSetObject(BT_Blackboard_GetTreeContext(), BT_Node_GetOutput(jNode), oSeat);
        return BT_NODE_STATE_SUCCESS;
    }

    return BT_NODE_STATE_FAILURE;
}

json BT_Node_Sit(string sInput)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "Sit");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_Sit_Tick");
    BT_Node_SetInput(jNode, sInput);
    return jNode;
}

int BT_Node_Sit_Tick(json jNode)
{
    object oSeat = BT_Blackboard_ContextGetObject(BT_Blackboard_GetTreeContext(), BT_Node_GetInput(jNode));

    if (GetIsObjectValid(oSeat))
    {
        object oSelf = OBJECT_SELF;
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

json BT_Node_ManageTorch(string sTorchTag)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "ManageTorch");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_ManageTorch_Tick");
    BT_Node_SetDataString(jNode, "TorchTag", sTorchTag);
    return jNode;
}

int BT_Node_ManageTorch_Tick(json jNode)
{
    string sTorchTag = BT_Node_GetDataString(jNode, "TorchTag");
    object oEquippedItem = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, OBJECT_SELF);
    int bHasTorchEquipped = GetIsObjectValid(oEquippedItem) && GetTag(oEquippedItem) == sTorchTag;
    int bShouldHaveTorchEquipped = GetIsDusk() || GetIsNight();

    if (bShouldHaveTorchEquipped && !bHasTorchEquipped)
    {
        object oTorch = GetItemPossessedBy(OBJECT_SELF, sTorchTag);
        if (GetIsObjectValid(oTorch))
        {
            ClearAllActions();
            ActionEquipItem(oTorch, INVENTORY_SLOT_LEFTHAND);
        }
    }
    else if (!bShouldHaveTorchEquipped && bHasTorchEquipped)
    {
        ClearAllActions();
        ActionUnequipItem(oEquippedItem);
    }

    return BT_NODE_STATE_SUCCESS;
}

void BTT_RecursiveTick(object oBehaviorTree, object oBlackboard, object oSelf)
{
    //Profiler_Start("BTT_RecursiveTick");
    BT_BehaviorTree_Tick(oBehaviorTree, oBlackboard, oSelf);
    //PrintString(Profiler_Stop());
    DelayCommand(3.0f, BTT_RecursiveTick(oBehaviorTree, oBlackboard, oSelf));
}

// @CORE[CORE_SYSTEM_POST]
void BTT_Post()
{
    string SEAT_OBJECT = "SeatObject";
    string WAYPOINT_OBJECT = "WaypointObject";

    BTB_InitializeBehaviorTree();
        BTB_StartReactiveFallback();
            BTB_StartSequence("Rest");
                BTB_StartRandomCooldown(120, 61);
                    BTB_AddNode(BT_Node_GetNearestSeat("SEAT", SEAT_OBJECT));
                BTB_End();
                BTB_AddNode(BT_Node_MoveToObject(SEAT_OBJECT, 2.0f, FALSE));
                BTB_StartForceSuccess();
                    BTB_StartProbability(25);
                        BTB_StartRandomChild("Rest Lines");
                            BTB_AddNode(BT_Node_SpeakString("Time for a lil' break..."));
                            BTB_AddNode(BT_Node_SpeakString("Whew."));
                            BTB_AddNode(BT_Node_SpeakString("Ahh..."));
                        BTB_End();
                    BTB_End();
                BTB_End();
                BTB_StartRandomTimeout(15, 16);
                    BTB_AddNode(BT_Node_Sit(SEAT_OBJECT));
                BTB_End();
            BTB_End();
            BTB_StartSequence("Patrol");
                BTB_AddNode(BT_Node_GetNextPatrolWaypoint(BTT_PATROL_OBJECT_TAG, 5.0f, WAYPOINT_OBJECT));
                BTB_AddNode(BT_Node_MoveToObject(WAYPOINT_OBJECT, 2.0f, FALSE));
                BTB_StartRandomChild("Idle Animations");
                    BTB_AddNode(BT_Node_PlayLoopingAnimation(ANIMATION_LOOPING_LOOK_FAR, 3), "LookFar");
                    BTB_AddNode(BT_Node_PlayLoopingAnimation(ANIMATION_FIREFORGET_PAUSE_SCRATCH_HEAD, 2), "ScratchHead");
                    BTB_AddNode(BT_Node_PlayLoopingAnimation(ANIMATION_FIREFORGET_PAUSE_BORED, 4), "Bored");
                BTB_End();
                BTB_StartForceSuccess();
                    BTB_StartRandomCooldown(30, 31);
                        BTB_StartRandomChild("Patrol Lines");
                            BTB_AddNode(BT_Node_SpeakString("Nothin' to see here..."));
                            BTB_AddNode(BT_Node_SpeakString("Any no-gooders 'ere?"));
                            BTB_AddNode(BT_Node_SpeakString("Hmm..."));
                        BTB_End();
                    BTB_End();
                BTB_End();
                BTB_AddNode(BT_Node_ManageTorch("NW_IT_TORCH001"));
            BTB_End();
        BTB_End();
    json jBehaviorTree = BTB_FinalizeBehaviorTree();
    PrintString(BTB_DebugPrintTree(JsonObjectGetInt(jBehaviorTree, BTB_ROOT_NODE_ID), JsonObjectGet(jBehaviorTree, BTB_NODES)));
    //PrintString(JsonDump(jBehaviorTree));

    object oGuard = GetObjectByTag(BTT_GUARD_TAG);
    object oBlackboard = BT_Blackboard_GetOrCreate("GuardPatrolBB");
    object oBehaviorTree = BT_BehaviorTree_GetOrCreate("GuardPatrolBT");
    BT_BehaviorTree_SetGraphVizEnabled(oBehaviorTree, BT_GRAPHVIZ_ENABLED);
    BT_BehaviorTree_InitializeTree(oBehaviorTree, jBehaviorTree);

    DelayCommand(5.0f, BTT_RecursiveTick(oBehaviorTree, oBlackboard, oGuard));
}
