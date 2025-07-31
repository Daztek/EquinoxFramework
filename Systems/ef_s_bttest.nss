/*
    Script: ef_s_bttest
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_btbuilder"

const string BTT_SCRIPT_NAME            = "ef_s_bttest";

json BT_Node_TestAction()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "TestAction");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_TestAction_Tick");
    return jNode;
}

int BT_Node_TestAction_Tick(json jNode, json jTickInfo)
{
    string sNodeName = BT_Node_GetName(jNode);
    int nRandom = Random(3);

    if (nRandom == 2)
    {
        LogInfo(sNodeName + " :|");
        return BT_NODE_STATE_RUNNING;
    }
    else if (nRandom == 1)
    {
        LogInfo(sNodeName + " :)");
        return BT_NODE_STATE_SUCCESS;
    }
    else
    {
        LogInfo(sNodeName + " :(");
        return BT_NODE_STATE_FAILURE;
    }
}

json BT_Node_WeDidIt()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "WeDidIt");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BTT_SCRIPT_NAME, "BT_Node_WeDidIt_Tick");
    return jNode;
}

int BT_Node_WeDidIt_Tick(json jNode, json jTickInfo)
{
    LogInfo("Woo! We did it! :D");
    return BT_NODE_STATE_SUCCESS;
}

void BTT_RecursiveTick(object oBehaviorTree, object oBlackboard)
{
    BT_BehaviorTree_Tick(oBehaviorTree, oBlackboard, GetModule());
    DelayCommand(2.5f, BTT_RecursiveTick(oBehaviorTree, oBlackboard));
}

// @CORE[CORE_SYSTEM_POST]
void BTT_Post()
{
    BTB_InitializeBehaviorTree();
        BTB_StartSequence("Root Sequence");
            BTB_StartFallback();
                BTB_StartSequence();
                    BTB_AddNode(BT_Node_TestAction(), "TestAction A1");
                    BTB_AddNode(BT_Node_TestAction(), "TestAction A2");
                    BTB_AddNode(BT_Node_TestAction(), "TestAction A3");
                BTB_End();
                BTB_AddNode(BT_Node_TestAction(), "TestAction B1");
                BTB_StartRepeater(3);
                    BTB_AddNode(BT_Node_TestAction(), "TestAction B2");
                BTB_End();
            BTB_End();
            BTB_AddNode(BT_Node_TestAction(), "TestAction C1");
            BTB_StartForceSuccess();
                BTB_AddNode(BT_Node_TestAction(), "TestAction C2");
            BTB_End();
            BTB_AddNode(BT_Node_TestAction(), "TestAction C3");
            BTB_AddNode(BT_Node_WeDidIt());
        BTB_End();
    json jTree = BTB_FinalizeBehaviorTree();
    PrintString(BT_DebugPrintTree(jTree));

    object oBlackboard = BT_Blackboard_GetOrCreate("TestBT");
    object oBehaviorTree = BT_BehaviorTree_GetOrCreate("TestBT");
    BT_BehaviorTree_SetGraphVizEnabled(oBehaviorTree, BT_GRAPHVIZ_ENABLED);
    BT_BehaviorTree_SetRoot(oBehaviorTree, jTree);

    DelayCommand(5.0f, BTT_RecursiveTick(oBehaviorTree, oBlackboard));
}
