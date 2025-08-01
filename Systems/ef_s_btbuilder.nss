/*
    Script: ef_s_btbuilder
    Author: Daz
*/

/*
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
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_bt"

const string BTB_SCRIPT_NAME            = "ef_s_btbuilder";

const int BTB_LOG_DEBUG                 = FALSE;
const int BTB_LOG_WARNINGS              = TRUE;

const string BTB_DEPTH                  = "Depth";
const string BTB_TYPE                   = "Type_";
const string BTB_DATA                   = "Data_";

const int BTB_NODE_TYPE_ROOT            = BT_NODE_TYPE_BASE;
const int BTB_NODE_TYPE_COMPOSITE       = BT_NODE_TYPE_COMPOSITE;
const int BTB_NODE_TYPE_DECORATOR       = BT_NODE_TYPE_DECORATOR;
const int BTB_NODE_TYPE_CONDITION       = BT_NODE_TYPE_CONDITION;
const int BTB_NODE_TYPE_ACTION          = BT_NODE_TYPE_ACTION;

void BTB_LogDebug(string sDebug);
void BTB_LogWarning(string sWarning);
int BTB_GetDepth();
void BTB_SetDepth(int nDepth);
void BTB_IncreaseDepth();
void BTB_DecreaseDepth();
int BTB_GetType();
void BTB_SetType(int nType);
json BTB_GetData();
void BTB_SetData(json jData);

int BTB_IsValidNodeType(int nNodeType);
string BTB_NodeTypeToString(int nNodeType);
void BTB_CheckNoChildren(int nTypeToAdd, json jDataToAdd);

void BTB_InitializeBehaviorTree();
json BTB_FinalizeBehaviorTree();
void BTB_StartNode(json jNode, string sName = "");
void BTB_End();
void BTB_AddNode(json jNode, string sName = "");

void BTB_StartSequence(string sName = "");
void BTB_StartReactiveSequence(string sName = "");
void BTB_StartFallback(string sName = "");
void BTB_StartReactiveFallback(string sName = "");
void BTB_StartParallel(int nSuccessPolicy = BT_NODE_PARALLEL_SUCCESS_POLICY_ANY, string sName = "");

void BTB_StartInverter();
void BTB_StartForceSuccess();
void BTB_StartForceFailure();
void BTB_StartRepeater(int nNumberOfRepeats);
void BTB_StartTimeout(int nTimeout);
void BTB_StartRandomTimeout(int nMinimumTimeout, int nRandomTimeout);
void BTB_StartProbability(int nPercentage);
void BTB_StartCooldown(int nCooldown);
void BTB_StartRandomCooldown(int nMinimumCooldown, int nRandomCooldown);

void BTB_SetNodeName(string sName);

void BTB_LogDebug(string sDebug)
{
    if (BTB_LOG_DEBUG)
        LogDebug(sDebug);
}

void BTB_LogWarning(string sWarning)
{
    if (BTB_LOG_WARNINGS)
        LogWarning(sWarning);
}

object BTB_GetDataObject()
{
    return GetDataObject(BTB_SCRIPT_NAME);
}

int BTB_GetDepth()
{
    return GetLocalInt(BTB_GetDataObject(), BTB_DEPTH);
}

void BTB_SetDepth(int nDepth)
{
    SetLocalInt(BTB_GetDataObject(), BTB_DEPTH, nDepth);
}

void BTB_IncreaseDepth()
{
    BTB_SetDepth(BTB_GetDepth() + 1);
}

void BTB_DecreaseDepth()
{
    BTB_SetDepth(BTB_GetDepth() - 1);
}

int BTB_GetType()
{
    return GetLocalInt(BTB_GetDataObject(), BTB_TYPE + IntToString(BTB_GetDepth()));
}

void BTB_SetType(int nType)
{
    SetLocalInt(BTB_GetDataObject(), BTB_TYPE + IntToString(BTB_GetDepth()), nType);
}

json BTB_GetData()
{
    return GetLocalJson(BTB_GetDataObject(), BTB_DATA + IntToString(BTB_GetDepth()));
}

void BTB_SetData(json jData)
{
    SetLocalJson(BTB_GetDataObject(), BTB_DATA + IntToString(BTB_GetDepth()), jData);
}

int BTB_IsValidNodeType(int nNodeType)
{
    switch (nNodeType)
    {
        case BTB_NODE_TYPE_COMPOSITE:
        case BTB_NODE_TYPE_DECORATOR:
        case BTB_NODE_TYPE_CONDITION:
        case BTB_NODE_TYPE_ACTION:
            return TRUE;
    }
    return FALSE;
}

string BTB_NodeTypeToString(int nNodeType)
{
    switch (nNodeType)
    {
        case BTB_NODE_TYPE_ROOT: return "BTB_NODE_TYPE_ROOT";
        case BTB_NODE_TYPE_COMPOSITE: return "BTB_NODE_TYPE_COMPOSITE";
        case BTB_NODE_TYPE_DECORATOR: return "BTB_NODE_TYPE_DECORATOR";
        case BTB_NODE_TYPE_CONDITION: return "BTB_NODE_TYPE_CONDITION";
        case BTB_NODE_TYPE_ACTION: return "BTB_NODE_TYPE_ACTION";
    }
    return "<UNKNOWN NODE TYPE>(" + IntToString(nNodeType) + ")";
}

void BTB_CheckNoChildren(int nTypeToAdd, json jDataToAdd)
{
    if ((nTypeToAdd == BT_NODE_TYPE_COMPOSITE && !JsonGetLength(JsonObjectGet(jDataToAdd, BT_NODE_KEY_CHILDREN))) ||
        (nTypeToAdd == BT_NODE_TYPE_DECORATOR && JsonGetType(JsonObjectGet(jDataToAdd, BT_NODE_KEY_CHILDREN)) != JSON_TYPE_OBJECT))
        BTB_LogWarning("{" + BTB_NodeTypeToString(nTypeToAdd) + "} HAS NO CHILD(REN).");
}

void BTB_InitializeBehaviorTree()
{
    BTB_LogDebug("* INITIALIZE BEHAVIOR TREE");
    BTB_SetDepth(0);
}

json BTB_FinalizeBehaviorTree()
{
    BTB_LogDebug("* FINALIZE BEHAVIOR TREE");
    return BTB_GetData();
}

void BTB_StartNode(json jNode, string sName = "")
{
    BTB_IncreaseDepth();
    int nType = JsonObjectGetInt(jNode, BT_NODE_KEY_TYPE);
    if (sName != "")
        BT_Node_SetName(jNode, sName);
    BTB_SetType(nType);
    BTB_SetData(jNode);

    BTB_LogDebug("[" + IntToString(BTB_GetDepth()) + "]  START: '" + BTB_NodeTypeToString(nType) + "'");
}

void BTB_End()
{
    int nTypeToAdd = BTB_GetType();
    json jDataToAdd = BTB_GetData();

    BTB_LogDebug("[" + IntToString(BTB_GetDepth()) + "]    END: '" + BTB_NodeTypeToString(nTypeToAdd) + "'");

    BTB_DecreaseDepth();

    int nType = BTB_GetType();
    json jData = BTB_GetData();

    BTB_LogDebug("[" + IntToString(BTB_GetDepth()) + "] INSERT: '" + BTB_NodeTypeToString(nTypeToAdd) + "' -> '" + BTB_NodeTypeToString(nType) + "'");

    switch (nType)
    {
        case BTB_NODE_TYPE_ROOT:
        {
            if (BTB_IsValidNodeType(nTypeToAdd))
            {
                BTB_CheckNoChildren(nTypeToAdd, jDataToAdd);
                BTB_SetData(jDataToAdd);
            }
            else
                BTB_LogWarning("TYPE MISMATCH: {BTB_NODE_TYPE_ROOT} does not accept {" + BTB_NodeTypeToString(nTypeToAdd) + "}.");
            break;
        }
        case BTB_NODE_TYPE_COMPOSITE:
        {
            if (BTB_IsValidNodeType(nTypeToAdd))
            {
                BTB_CheckNoChildren(nTypeToAdd, jDataToAdd);
                BTB_SetData(JsonObjectInsertToArrayWithKey(jData, BT_NODE_KEY_CHILDREN, jDataToAdd));
            }
            else
                BTB_LogWarning("TYPE MISMATCH: {BTB_NODE_TYPE_COMPOSITE} does not accept {" + BTB_NodeTypeToString(nTypeToAdd) + "}.");
            break;
        }
        case BTB_NODE_TYPE_DECORATOR:
        {
            if (BTB_IsValidNodeType(nTypeToAdd))
            {
                BTB_CheckNoChildren(nTypeToAdd, jDataToAdd);
                BTB_SetData(JsonObjectSet(jData, BT_NODE_KEY_CHILDREN, jDataToAdd));
            }
            else
                BTB_LogWarning("TYPE MISMATCH: {BTB_NODE_TYPE_DECORATOR} does not accept {" + BTB_NodeTypeToString(nTypeToAdd) + "}.");
            break;
        }

        case BTB_NODE_TYPE_CONDITION:
        case BTB_NODE_TYPE_ACTION:
        {
            BTB_LogWarning("TYPE MISMATCH: {BTB_NODE_TYPE_CONDITION|BTB_NODE_TYPE_ACTION} does not accept children.");
            break;
        }

        default:
            BTB_LogWarning("UNKNOWN TYPE: " + IntToString(nTypeToAdd));
        break;
    }
}

void BTB_AddNode(json jNode, string sName = "")
{
    BTB_StartNode(jNode, sName);
    BTB_End();
}

// Composite Node Helpers

void BTB_StartSequence(string sName = "")
{
    BTB_StartNode(BT_Node_Sequence(), sName);
}

void BTB_StartReactiveSequence(string sName = "")
{
    BTB_StartNode(BT_Node_ReactiveSequence(), sName);
}

void BTB_StartFallback(string sName = "")
{
    BTB_StartNode(BT_Node_Fallback(), sName);
}

void BTB_StartReactiveFallback(string sName = "")
{
    BTB_StartNode(BT_Node_ReactiveFallback(), sName);
}

void BTB_StartParallel(int nSuccessPolicy = BT_NODE_PARALLEL_SUCCESS_POLICY_ANY, string sName = "")
{
    BTB_StartNode(BT_Node_Parallel(nSuccessPolicy), sName);
}

// Decorator Node Helpers

void BTB_StartInverter()
{
    BTB_StartNode(BT_Node_Inverter());
}

void BTB_StartForceSuccess()
{
    BTB_StartNode(BT_Node_ForceSuccess());
}

void BTB_StartForceFailure()
{
    BTB_StartNode(BT_Node_ForceFailure());
}

void BTB_StartRepeater(int nNumberOfRepeats)
{
    BTB_StartNode(BT_Node_Repeater(nNumberOfRepeats));
}

void BTB_StartTimeout(int nTimeout)
{
    BTB_StartNode(BT_Node_Timeout(nTimeout));
}

void BTB_StartRandomTimeout(int nMinimumTimeout, int nRandomTimeout)
{
    BTB_StartNode(BT_Node_RandomTimeout(nMinimumTimeout, nRandomTimeout));
}

void BTB_StartProbability(int nPercentage)
{
    BTB_StartNode(BT_Node_Probability(nPercentage));
}

void BTB_StartCooldown(int nSeconds)
{
    BTB_StartNode(BT_Node_Cooldown(nSeconds));
}

void BTB_StartRandomCooldown(int nMinimumCooldown, int nRandomCooldown)
{
    BTB_StartNode(BT_Node_RandomCooldown(nMinimumCooldown, nRandomCooldown));
}

void BTB_SetNodeName(string sName)
{
    BT_Node_SetName(BTB_GetData(), sName);
}
