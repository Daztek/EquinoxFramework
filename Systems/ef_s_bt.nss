/*
    Script: ef_s_bt
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "nwnx_httpclient"

const string BT_SCRIPT_NAME                     = "ef_s_bt";

const int BT_DEBUG_LOG_TICKS                    = FALSE;
const int BT_DEBUG_LOG_TICK_INFO                = FALSE;
const int BT_DEBUG_LOG_MEMORY_INFO              = FALSE;

const int BT_GRAPHVIZ_ENABLED                   = TRUE;

const string BT_BLACKBOARD_TAG_PREFIX           = "BTBB_";
const string BT_BLACKBOARD_KEY_IS_OPEN           = "IsOpen";
const string BT_BLACKBOARD_KEY_OPEN_NODES        = "OpenNodes";
const string BT_BLACKBOARD_KEY_NODE_COUNT        = "NodeCount";
const string BT_BLACKBOARD_KEY_RUNNING_CHILD     = "RunningChild";
const string BT_BLACKBOARD_KEY_LAST_RESULT       = "LastResult";

const string BT_BEHAVIORTREE_TAG_PREFIX         = "BT_";
const string BT_BEHAVIORTREE_ID                 = "BehaviorTreeID";
const string BT_BEHAVIORTREE_ROOT               = "BehaviorTreeRoot";
const string BT_BEHAVIORTREE_GRAPHVIZ_ENABLED   = "BehaviorTreeGraphVizEnabled";

const int BT_NODE_FUNCTION_ENTER                = 1;
const int BT_NODE_FUNCTION_OPEN                 = 2;
const int BT_NODE_FUNCTION_TICK                 = 3;
const int BT_NODE_FUNCTION_CLOSE                = 4;
const int BT_NODE_FUNCTION_EXIT                 = 5;

const int BT_NODE_STATE_SUCCESS                 = 1;
const int BT_NODE_STATE_FAILURE                 = 2;
const int BT_NODE_STATE_RUNNING                 = 3;
const int BT_NODE_STATE_ERROR                   = 4;

const string BT_NODE_KEY_ID                     = "ID";
const string BT_NODE_KEY_TYPE                   = "Type";
const string BT_NODE_KEY_TYPENAME               = "TypeName";
const string BT_NODE_KEY_CHILDREN               = "Children";
const string BT_NODE_KEY_NAME                   = "Name";
const string BT_NODE_KEY_INCLUDE                = "Include_";
const string BT_NODE_KEY_FUNCTION               = "Function_";
const string BT_NODE_KEY_DATA                   = "Data";

const int BT_NODE_TYPE_BASE                     = 0;
const int BT_NODE_TYPE_COMPOSITE                = 1;
const int BT_NODE_TYPE_DECORATOR                = 2;
const int BT_NODE_TYPE_CONDITION                = 3;
const int BT_NODE_TYPE_ACTION                   = 4;

const int BT_NODE_PARALLEL_SUCCESS_POLICY_ANY   = 1;
const int BT_NODE_PARALLEL_SUCCESS_POLICY_ALL   = 2;

struct BlackboardInfo
{
    object oBlackboard;
    int nBehaviorTreeID;
    int nNodeID;
};

int BT_GetUniqueID();
string BT_DebugPrintTree(json jNode, int nDepth = 0);
string BT_NodeStateToString(int nNodeState);
string BT_NodeTypeToString(int nNodeType);

void BT_GraphViz_Update(json jTickInfo, json jNode);
void BT_GraphViz_ResetLastResult(json jTickInfo, json jNode);

object BT_Blackboard_GetOrCreate(string sTag);
struct BlackboardInfo BT_Blackboard_GetInfo(json jTickInfo, json jNode = JSON_NULL);
void BT_Blackboard_SetValue(object oBlackboard, string sKey, json jValue, int nBehaviorTreeID = 0, int nNodeID = 0);
json BT_Blackboard_GetValue(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_DeleteValue(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_StructSetValue(struct BlackboardInfo strBlackboardInfo, string sKey, json jValue);
json BT_Blackboard_StructGetValue(struct BlackboardInfo strBlackboardInfo, string sKey);
void BT_Blackboard_StructDeleteValue(struct BlackboardInfo strBlackboardInfo, string sKey);

json BT_TickInfo_Create(object oBehaviorTree, object oBlackboard, object oSelf = OBJECT_SELF);
object BT_TickInfo_GetBehaviorTree(json jTickInfo);
int BT_TickInfo_GetBehaviorTreeID(json jTickInfo);
object BT_TickInfo_GetBlackboard(json jTickInfo);
json BT_TickInfo_GetOpenNodes(json jTickInfo);
int BT_TickInfo_GetNodeCount(json jTickInfo);
object BT_TickInfo_GetSelf(json jTickInfo);
void BT_TickInfo_EnterNode(json jTickInfo, json jNode);
void BT_TickInfo_OpenNode(json jTickInfo, json jNode);
void BT_TickInfo_TickNode(json jTickInfo, json jNode);
void BT_TickInfo_CloseNode(json jTickInfo, json jNode);
void BT_TickInfo_ExitNode(json jTickInfo, json jNode);

object BT_BehaviorTree_GetOrCreate(string sTag);
int BT_BehaviorTree_GetID(object oBehaviorTree);
void BT_BehaviorTree_SetRoot(object oBehaviorTree, json jRoot);
json BT_BehaviorTree_GetRoot(object oBehaviorTree);
void BT_BehaviorTree_SetGraphVizEnabled(object oBehaviorTree, int bEnabled);
int BT_BehaviorTree_GetGraphVizEnabled(object oBehaviorTree);
void BT_BehaviorTree_Tick(object oBehaviorTree, object oBlackboard, object oSelf = OBJECT_SELF);

int BT_Node_ExecuteNodeFunction(json jNode, json jTickInfo, int nFunctionType);
int BT_Node_ExecuteFunction(json jNode, json jTickInfo, int nFunctionType);
int BT_Node_Execute(json jNode, json jTickInfo);

int BT_Node_GetID(json jNode);
int BT_Node_GetType(json jNode);
string BT_Node_GetTypeName(json jNode);
json BT_Node_GetChildren(json jNode);
json BT_Node_SetName(json jNode, string sName);
string BT_Node_GetName(json jNode);
string BT_Node_GetInclude(json jNode, int nFunctionType);
string BT_Node_GetFunction(json jNode, int nFunctionType);
void BT_Node_SetData(json jNode, string sKey, json jValue);
json BT_Node_GetData(json jNode, string sKey);
void BT_Node_SetDataInt(json jNode, string sKey, int nValue);
int BT_Node_GetDataInt(json jNode, string sKey);
void BT_Node_SetDataString(json jNode, string sKey, string sValue);
string BT_Node_GetDataString(json jNode, string sKey);
void BT_Node_SetDataFloat(json jNode, string sKey, float fValue);
float BT_Node_GetDataFloat(json jNode, string sKey);
string BT_Node_GetDebugInfo(json jNode);

void BT_Node_SetFunction(json jNode, int nFunctionType, string sInclude, string sFunction);
void BT_Node_AddChild(json jNode, json jChild);

json BT_Node_Sequence();
json BT_Node_ReactiveSequence();
json BT_Node_Fallback();
json BT_Node_ReactiveFallback();
json BT_Node_Parallel(int nSuccessPolicy = BT_NODE_PARALLEL_SUCCESS_POLICY_ANY);

json BT_Node_Inverter();
json BT_Node_ForceSuccess();
json BT_Node_ForceFailure();
json BT_Node_Repeater(int nNumberOfRepeats);
json BT_Node_Timeout(int nSeconds);
json BT_Node_Probability(int nPercentage);
json BT_Node_Cooldown(int nSeconds);

/* *** Helper Functions *** */

int BT_GetUniqueID()
{
    return IncrementLocalInt(GetDataObject(BT_SCRIPT_NAME), "BTUniqueID");
}

string BT_DebugPrintTree(json jNode, int nDepth = 0)
{
    string sIndent = "";
    int nIndex;
    for (nIndex = 0; nIndex < nDepth; nIndex++)
    {
        sIndent += "  ";
    }

    string sResult = sIndent + "|- " + BT_Node_GetName(jNode) + " [" + BT_Node_GetTypeName(jNode) + "]\n";

    json jChildren = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChildren) == JSON_TYPE_ARRAY)
    {
        int nCount = JsonGetLength(jChildren);
        for (nIndex = 0; nIndex < nCount; nIndex++)
        {
            sResult += BT_DebugPrintTree(JsonArrayGet(jChildren, nIndex), nDepth + 1);
        }
    }
    else if (JsonGetType(jChildren) == JSON_TYPE_OBJECT)
    {
        sResult += BT_DebugPrintTree(jChildren, nDepth + 1);
    }

    return sResult;
}

string BT_NodeStateToString(int nNodeState)
{
    switch (nNodeState)
    {
        case BT_NODE_STATE_SUCCESS: return "Success";
        case BT_NODE_STATE_FAILURE: return "Failure";
        case BT_NODE_STATE_RUNNING: return "Running";
        case BT_NODE_STATE_ERROR: return "Error";
    }
    return "Unknown Node State";
}

string BT_NodeTypeToString(int nNodeType)
{
    switch (nNodeType)
    {
        case BT_NODE_TYPE_BASE: return "Base";
        case BT_NODE_TYPE_COMPOSITE: return "Composite";
        case BT_NODE_TYPE_DECORATOR: return "Decorator";
        case BT_NODE_TYPE_CONDITION: return "Condition";
        case BT_NODE_TYPE_ACTION: return "Action";
    }
    return "Unknown Node Type";
}

/* *** GraphViz Functions *** */

string BT_GraphViz_GetNodeStateColor(json jTickInfo, json jNode)
{
    struct BlackboardInfo strBlackboardInfo = BT_Blackboard_GetInfo(jTickInfo, jNode);

    if (JsonGetInt(BT_Blackboard_StructGetValue(strBlackboardInfo, BT_BLACKBOARD_KEY_IS_OPEN)))
        return "orange";

    int nLastResult = JsonGetInt(BT_Blackboard_StructGetValue(strBlackboardInfo, BT_BLACKBOARD_KEY_LAST_RESULT));
    switch (nLastResult)
    {
        case BT_NODE_STATE_SUCCESS: return "green";
        case BT_NODE_STATE_FAILURE: return "red";
        case BT_NODE_STATE_RUNNING: return "orange";
    }
    return "gray";
}

string BT_GraphViz_GenerateNodes(json jTickInfo, json jNode, string sParentID)
{
    string sNodeID = "node_" + IntToString(BT_Node_GetID(jNode));
    string sNodeName = BT_Node_GetName(jNode);
    string sNodeType = BT_Node_GetTypeName(jNode);
    string sColor = BT_GraphViz_GetNodeStateColor(jTickInfo, jNode);

    string sResult = sNodeID + " [label=\"" + sNodeName + "\\n(" + sNodeType + ")\", fillcolor=" + sColor + ", fontcolor=white, style=filled]; ";

    if (sParentID != "")
        sResult += sParentID + " -> " + sNodeID + ";";

    json jChildren = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChildren) == JSON_TYPE_ARRAY)
    {
        int nIndex, nCount = JsonGetLength(jChildren);
        for (nIndex = 0; nIndex < nCount; nIndex++)
        {
            sResult += BT_GraphViz_GenerateNodes(jTickInfo, JsonArrayGet(jChildren, nIndex), sNodeID);
        }
    }
    else if (JsonGetType(jChildren) == JSON_TYPE_OBJECT)
    {
        sResult += BT_GraphViz_GenerateNodes(jTickInfo, jChildren, sNodeID);
    }

    return sResult;
}

string BT_GraphViz_GenerateGraphViz(json jTickInfo, json jNode)
{
    return "digraph BehaviorTree { rankdir=TB; node [shape=box, style=filled]; edge [color=gray50]; " + BT_GraphViz_GenerateNodes(jTickInfo, jNode, "") + "}";
}

void BT_GraphViz_Update(json jTickInfo, json jNode)
{
    struct NWNX_HTTPClient_Request str;
    str.nRequestMethod = NWNX_HTTPCLIENT_REQUEST_METHOD_POST;
    str.sHost = "127.0.0.1";
    str.nPort = 5000;
    str.sPath = "/update";
    str.sData = JsonDump(JsonObjectSetString(JsonObject(), "dot", BT_GraphViz_GenerateGraphViz(jTickInfo, jNode)));
    str.nAuthType = NWNX_HTTPCLIENT_AUTH_TYPE_NONE;
    str.nContentType = NWNX_HTTPCLIENT_CONTENT_TYPE_JSON;
    NWNX_HTTPClient_SendRequest(str);
}

void BT_GraphViz_ResetLastResult(json jTickInfo, json jNode)
{
    struct BlackboardInfo strBlackboardInfo = BT_Blackboard_GetInfo(jTickInfo, jNode);

    BT_Blackboard_StructDeleteValue(strBlackboardInfo, BT_BLACKBOARD_KEY_LAST_RESULT);

    json jChildren = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChildren) == JSON_TYPE_ARRAY)
    {
        int nIndex, nCount = JsonGetLength(jChildren);
        for (nIndex = 0; nIndex < nCount; nIndex++)
        {
            BT_GraphViz_ResetLastResult(jTickInfo, JsonArrayGet(jChildren, nIndex));
        }
    }
    else if (JsonGetType(jChildren) == JSON_TYPE_OBJECT)
    {
        BT_GraphViz_ResetLastResult(jTickInfo, jChildren);
    }
}

/* *** Blackboard Functions *** */

object BT_Blackboard_GetOrCreate(string sTag)
{
    return GetDataObject(BT_BLACKBOARD_TAG_PREFIX + sTag);
}

struct BlackboardInfo BT_Blackboard_GetInfo(json jTickInfo, json jNode = JSON_NULL)
{
    struct BlackboardInfo str;
    str.oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    str.nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    str.nNodeID = JsonGetType(jNode) ? BT_Node_GetID(jNode) : 0;
    return str;
}

string BT_Blackboard_GetKey(int nBehaviorTreeID, int nNodeID, string sKey)
{
    if (nBehaviorTreeID)
    {
        if (nNodeID)
            return "TID" + IntToString(nBehaviorTreeID) + "_NID" + IntToString(nNodeID) + "_" + sKey;
        else
            return "TID" + IntToString(nBehaviorTreeID) + "_" + sKey;

    }
    return "GLOBAL_" + sKey;
}

void BT_Blackboard_SetValue(object oBlackboard, string sKey, json jValue, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    SetLocalJson(oBlackboard, sValueKey, jValue);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("SET '" + sKey + "' -> '" + JsonDump(jValue) + "' (" + sValueKey + ")");
}

json BT_Blackboard_GetValue(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    json jValue = GetLocalJson(oBlackboard, sValueKey);

    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("GET '" + sKey + "' -> '" + JsonDump(jValue) + "' (" + sValueKey + ")");

    return jValue;
}

void BT_Blackboard_DeleteValue(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    DeleteLocalJson(oBlackboard, sValueKey);

    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("DELETE '" + sKey + "' -> (" + sValueKey + ")");
}

void BT_Blackboard_StructSetValue(struct BlackboardInfo strBlackboardInfo, string sKey, json jValue)
{
    BT_Blackboard_SetValue(strBlackboardInfo.oBlackboard, sKey, jValue, strBlackboardInfo.nBehaviorTreeID, strBlackboardInfo.nNodeID);
}

json BT_Blackboard_StructGetValue(struct BlackboardInfo strBlackboardInfo, string sKey)
{
    return BT_Blackboard_GetValue(strBlackboardInfo.oBlackboard, sKey, strBlackboardInfo.nBehaviorTreeID, strBlackboardInfo.nNodeID);
}

void BT_Blackboard_StructDeleteValue(struct BlackboardInfo strBlackboardInfo, string sKey)
{
    BT_Blackboard_DeleteValue(strBlackboardInfo.oBlackboard, sKey, strBlackboardInfo.nBehaviorTreeID, strBlackboardInfo.nNodeID);
}

/* *** TickInfo Functions *** */

json BT_TickInfo_Create(object oBehaviorTree, object oBlackboard, object oSelf = OBJECT_SELF)
{
    json jTickInfo = JsonObject();
    JsonObjectSetObjectInplace(jTickInfo, "BehaviorTree", oBehaviorTree);
    JsonObjectSetIntInplace(jTickInfo, "BehaviorTreeID", BT_BehaviorTree_GetID(oBehaviorTree));
    JsonObjectSetObjectInplace(jTickInfo, "Blackboard", oBlackboard);
    JsonObjectSetInplace(jTickInfo, "OpenNodes", JsonArray());
    JsonObjectSetIntInplace(jTickInfo, "NodeCount", 0);
    JsonObjectSetObjectInplace(jTickInfo, "Self", oSelf);
    return jTickInfo;
}

object BT_TickInfo_GetBehaviorTree(json jTickInfo)
{
    return JsonObjectGetObject(jTickInfo, "BehaviorTree");
}

int BT_TickInfo_GetBehaviorTreeID(json jTickInfo)
{
    return JsonObjectGetInt(jTickInfo, "BehaviorTreeID");
}

object BT_TickInfo_GetBlackboard(json jTickInfo)
{
    return JsonObjectGetObject(jTickInfo, "Blackboard");
}

json BT_TickInfo_GetOpenNodes(json jTickInfo)
{
    return JsonObjectGet(jTickInfo, "OpenNodes");
}

int BT_TickInfo_GetNodeCount(json jTickInfo)
{
    return JsonObjectGetInt(jTickInfo, "NodeCount");
}

object BT_TickInfo_GetSelf(json jTickInfo)
{
    return JsonObjectGetObject(jTickInfo, "Self");
}

void BT_TickInfo_EnterNode(json jTickInfo, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_EnterNode: " + BT_Node_GetDebugInfo(jNode));

    JsonSetAtPointerInplace(jTickInfo, "/" + BT_BLACKBOARD_KEY_NODE_COUNT, JsonInt(BT_TickInfo_GetNodeCount(jTickInfo) + 1));
    JsonSetAtPointerInplace(jTickInfo, "/" + BT_BLACKBOARD_KEY_OPEN_NODES + "/" + IntToString(JsonGetLength(BT_TickInfo_GetOpenNodes(jTickInfo))), jNode);
}

void BT_TickInfo_OpenNode(json jTickInfo, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_OpenNode: " + BT_Node_GetDebugInfo(jNode));
}

void BT_TickInfo_TickNode(json jTickInfo, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_TickNode: " + BT_Node_GetDebugInfo(jNode));
}

void BT_TickInfo_CloseNode(json jTickInfo, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_CloseNode: " + BT_Node_GetDebugInfo(jNode));

    json jOpenNodes = BT_TickInfo_GetOpenNodes(jTickInfo);
    int nNumNodes = JsonGetLength(jOpenNodes);
    if (!nNumNodes) return;

    int nIndex, nNodeID = BT_Node_GetID(jNode), bFound = FALSE;
    for (nIndex = nNumNodes - 1; nIndex >= 0; nIndex--)
    {
        if (BT_Node_GetID(JsonArrayGet(jOpenNodes, nIndex)) == nNodeID)
        {
            bFound = TRUE;
            break;
        }
    }

    if (bFound)
    {
        if (nIndex != (nNumNodes - 1))
            LogWarning(BT_Node_GetDebugInfo(jNode) + ": closing node is not the last element");

        JsonArrayDelInplace(jOpenNodes, nIndex);
        JsonSetAtPointerInplace(jTickInfo, "/" + BT_BLACKBOARD_KEY_OPEN_NODES, jOpenNodes);
    }
}

void BT_TickInfo_ExitNode(json jTickInfo, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_ExitNode: " + BT_Node_GetDebugInfo(jNode));
}

/* *** Behavior Tree Functions *** */

object BT_BehaviorTree_GetOrCreate(string sTag)
{
    object oBehaviorTree = GetDataObject(BT_BEHAVIORTREE_TAG_PREFIX + sTag, FALSE);
    if (!GetIsObjectValid(oBehaviorTree))
    {
        oBehaviorTree = CreateDataObject(BT_BEHAVIORTREE_TAG_PREFIX + sTag);
        SetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_ID, BT_GetUniqueID());
    }
    return oBehaviorTree;
}

int BT_BehaviorTree_GetID(object oBehaviorTree)
{
    return GetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_ID);
}

void BT_BehaviorTree_SetRoot(object oBehaviorTree, json jRoot)
{
    SetLocalJson(oBehaviorTree, BT_BEHAVIORTREE_ROOT, jRoot);
}

json BT_BehaviorTree_GetRoot(object oBehaviorTree)
{
    return GetLocalJson(oBehaviorTree, BT_BEHAVIORTREE_ROOT);
}

void BT_BehaviorTree_SetGraphVizEnabled(object oBehaviorTree, int bEnabled)
{
    SetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_GRAPHVIZ_ENABLED, bEnabled);
}

int BT_BehaviorTree_GetGraphVizEnabled(object oBehaviorTree)
{
    return GetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_GRAPHVIZ_ENABLED);
}

void BT_BehaviorTree_SetCurrentTickInfo(json jTickInfo)
{
    SetLocalJson(GetModule(), "BTCurrentTickInfo", jTickInfo);
}

json BT_BehaviorTree_GetCurrentTickInfo()
{
    return GetLocalJson(GetModule(), "BTCurrentTickInfo");
}

json BT_BehaviorTree_GetCurrentNode()
{
    return GetLocalJson(GetModule(), "BTCurrentNode");
}

void BT_BehaviorTree_SetCurrentNode(json jNode)
{
    SetLocalJson(GetModule(), "BTCurrentNode", jNode);
}

void BT_BehaviorTree_Tick(object oBehaviorTree, object oBlackboard, object oSelf = OBJECT_SELF)
{
    if (BT_DEBUG_LOG_TICKS)
        LogDebug("--- TICK START ---");

    json jTickInfo = BT_TickInfo_Create(oBehaviorTree, oBlackboard, oSelf);
    BT_BehaviorTree_SetCurrentTickInfo(jTickInfo);

    json jRoot = BT_BehaviorTree_GetRoot(oBehaviorTree);
    int nNodeState = BT_Node_Execute(jRoot, jTickInfo);

    if (BT_GRAPHVIZ_ENABLED && BT_BehaviorTree_GetGraphVizEnabled(oBehaviorTree))
    {
        BT_GraphViz_Update(jTickInfo, jRoot);
        if (nNodeState != BT_NODE_STATE_RUNNING)
            BT_GraphViz_ResetLastResult(jTickInfo, jRoot);
    }

    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    json jLastOpenNodes = BT_Blackboard_GetValue(oBlackboard, BT_BLACKBOARD_KEY_OPEN_NODES, nBehaviorTreeID);
    int nLastOpenNodesLength = JsonGetLength(jLastOpenNodes);
    json jCurrentOpenNodes = BT_TickInfo_GetOpenNodes(jTickInfo);
    int nCurrentOpenNodesLength = JsonGetLength(jCurrentOpenNodes);

    int nIndex, nStart = nLastOpenNodesLength, nNumNodes = min(nLastOpenNodesLength, nCurrentOpenNodesLength);
    for (nIndex = 0; nIndex < nNumNodes; nIndex++)
    {
        if (BT_Node_GetID(JsonArrayGet(jLastOpenNodes, nIndex)) != BT_Node_GetID(JsonArrayGet(jCurrentOpenNodes, nIndex)))
        {
            nStart = nIndex;
            break;
        }
    }

    if (nStart == nLastOpenNodesLength && nLastOpenNodesLength > nCurrentOpenNodesLength)
        nStart = nCurrentOpenNodesLength;

    for (nIndex = nLastOpenNodesLength - 1; nIndex >= nStart; nIndex--)
    {
        json jNode = JsonArrayGet(jLastOpenNodes, nIndex);
        if (JsonGetInt(BT_Blackboard_GetValue(oBlackboard, BT_BLACKBOARD_KEY_IS_OPEN, nBehaviorTreeID, BT_Node_GetID(jNode))))
        {
            BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_CLOSE);
        }
    }

    BT_Blackboard_SetValue(oBlackboard, BT_BLACKBOARD_KEY_OPEN_NODES, jCurrentOpenNodes, nBehaviorTreeID);
    BT_Blackboard_SetValue(oBlackboard, BT_BLACKBOARD_KEY_NODE_COUNT, JsonInt(BT_TickInfo_GetNodeCount(jTickInfo)), nBehaviorTreeID);

    if (BT_DEBUG_LOG_TICKS)
        LogDebug("--- TICK END ---");
}

/* *** Node Execution Functions *** */

int BT_Node_ExecuteNodeFunction(json jNode, json jTickInfo, int nFunctionType)
{
    string sFunction = BT_Node_GetFunction(jNode, nFunctionType);
    if (sFunction != "")
    {
        BT_BehaviorTree_SetCurrentNode(jNode);
        int nRetVal = BT_NODE_STATE_FAILURE;
        if (nFunctionType == BT_NODE_FUNCTION_TICK)
            nRetVal = ExecuteScriptChunkAndReturnInt(BT_Node_GetInclude(jNode, nFunctionType), sFunction, BT_TickInfo_GetSelf(jTickInfo));
        else
            ExecuteScriptChunkAndReturnVoid(BT_Node_GetInclude(jNode, nFunctionType), sFunction, BT_TickInfo_GetSelf(jTickInfo));

        return nRetVal != 0 ? nRetVal : BT_NODE_STATE_FAILURE;
    }
    return BT_NODE_STATE_FAILURE;
}

int BT_Node_ExecuteFunction(json jNode, json jTickInfo, int nFunctionType)
{
    int nRetVal = 0;
    switch (nFunctionType)
    {
        case BT_NODE_FUNCTION_ENTER:
        {
            BT_TickInfo_EnterNode(jTickInfo, jNode);
            BT_Node_ExecuteNodeFunction(jNode, jTickInfo, nFunctionType);
            break;
        }

        case BT_NODE_FUNCTION_OPEN:
        {
            BT_TickInfo_OpenNode(jTickInfo, jNode);
            BT_Blackboard_SetValue(BT_TickInfo_GetBlackboard(jTickInfo), BT_BLACKBOARD_KEY_IS_OPEN, JsonInt(TRUE),
                BT_TickInfo_GetBehaviorTreeID(jTickInfo), BT_Node_GetID(jNode));
            BT_Node_ExecuteNodeFunction(jNode, jTickInfo, nFunctionType);
            break;
        }

        case BT_NODE_FUNCTION_TICK:
        {
            BT_TickInfo_TickNode(jTickInfo, jNode);
            nRetVal = BT_Node_ExecuteNodeFunction(jNode, jTickInfo, nFunctionType);
            break;
        }

        case BT_NODE_FUNCTION_CLOSE:
        {
            BT_TickInfo_CloseNode(jTickInfo, jNode);
            BT_Blackboard_SetValue(BT_TickInfo_GetBlackboard(jTickInfo), BT_BLACKBOARD_KEY_IS_OPEN, JsonInt(FALSE),
                BT_TickInfo_GetBehaviorTreeID(jTickInfo), BT_Node_GetID(jNode));
            BT_Node_ExecuteNodeFunction(jNode, jTickInfo, nFunctionType);
            break;
        }

        case BT_NODE_FUNCTION_EXIT:
        {
            BT_TickInfo_ExitNode(jTickInfo, jNode);
            BT_Node_ExecuteNodeFunction(jNode, jTickInfo, nFunctionType);
            break;
        }
    }

    return nRetVal;
}

int BT_Node_Execute(json jNode, json jTickInfo)
{
    struct BlackboardInfo strBlackboardInfo = BT_Blackboard_GetInfo(jTickInfo, jNode);

    BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_ENTER);

    if (!JsonGetInt(BT_Blackboard_StructGetValue(strBlackboardInfo, BT_BLACKBOARD_KEY_IS_OPEN)))
        BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_OPEN);

    int nNodeState = BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_TICK);

    if (BT_GRAPHVIZ_ENABLED && BT_BehaviorTree_GetGraphVizEnabled(BT_TickInfo_GetBehaviorTree(jTickInfo)))
        BT_Blackboard_StructSetValue(strBlackboardInfo, BT_BLACKBOARD_KEY_LAST_RESULT, JsonInt(nNodeState));

    if (nNodeState == BT_NODE_STATE_ERROR)
        LogWarning(BT_Node_GetDebugInfo(jNode) + ": node returned an error state");

    if (nNodeState != BT_NODE_STATE_RUNNING)
        BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_CLOSE);

    BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_EXIT);

    return nNodeState;
}

/* *** Node Functions *** */

int BT_Node_GetID(json jNode)
{
    return JsonObjectGetInt(jNode, BT_NODE_KEY_ID);
}

int BT_Node_GetType(json jNode)
{
    return JsonObjectGetInt(jNode, BT_NODE_KEY_TYPE);
}

string BT_Node_GetTypeName(json jNode)
{
    return JsonObjectGetString(jNode, BT_NODE_KEY_TYPENAME);
}

json BT_Node_GetChildren(json jNode)
{
    return JsonObjectGet(jNode, BT_NODE_KEY_CHILDREN);
}

json BT_Node_SetName(json jNode, string sName)
{
    JsonObjectSetStringInplace(jNode, BT_NODE_KEY_NAME, sName);
    return jNode;
}

string BT_Node_GetName(json jNode)
{
    string sName = JsonObjectGetString(jNode, BT_NODE_KEY_NAME);
    return sName == "" ? BT_Node_GetTypeName(jNode) : sName;
}

string BT_Node_GetInclude(json jNode, int nFunctionType)
{
    return JsonObjectGetString(jNode, BT_NODE_KEY_INCLUDE + IntToString(nFunctionType));
}

string BT_Node_GetFunction(json jNode, int nFunctionType)
{
    return JsonObjectGetString(jNode, BT_NODE_KEY_FUNCTION + IntToString(nFunctionType));
}

void BT_Node_SetData(json jNode, string sKey, json jValue)
{
    JsonSetAtPointerInplace(jNode, "/" + BT_NODE_KEY_DATA + "/" + sKey, jValue);
}

json BT_Node_GetData(json jNode, string sKey)
{
    return JsonObjectGet(JsonObjectGet(jNode, BT_NODE_KEY_DATA), sKey);
}

void BT_Node_SetDataInt(json jNode, string sKey, int nValue)
{
    BT_Node_SetData(jNode, sKey, JsonInt(nValue));
}

int BT_Node_GetDataInt(json jNode, string sKey)
{
    return JsonGetInt(BT_Node_GetData(jNode, sKey));
}

void BT_Node_SetDataString(json jNode, string sKey, string sValue)
{
    BT_Node_SetData(jNode, sKey, JsonString(sValue));
}

string BT_Node_GetDataString(json jNode, string sKey)
{
    return JsonGetString(BT_Node_GetData(jNode, sKey));
}

void BT_Node_SetDataFloat(json jNode, string sKey, float fValue)
{
    BT_Node_SetData(jNode, sKey, JsonFloat(fValue));
}

float BT_Node_GetDataFloat(json jNode, string sKey)
{
    return JsonGetFloat(BT_Node_GetData(jNode, sKey));
}

string BT_Node_GetDebugInfo(json jNode)
{
    return BT_Node_GetName(jNode) + "@" + IntToString(BT_Node_GetID(jNode));
}

/* *** Base Node *** */

json BT_Node_BaseNode(int nNodeType, string sTypeName)
{
    json jNode = JsonObject();
    JsonObjectSetIntInplace(jNode, BT_NODE_KEY_ID, BT_GetUniqueID());
    JsonObjectSetIntInplace(jNode, BT_NODE_KEY_TYPE, nNodeType);
    JsonObjectSetStringInplace(jNode, BT_NODE_KEY_TYPENAME, sTypeName);

    if (nNodeType == BT_NODE_TYPE_COMPOSITE)
        JsonObjectSetInplace(jNode, BT_NODE_KEY_CHILDREN, JsonArray());
    else
        JsonObjectSetInplace(jNode, BT_NODE_KEY_CHILDREN, JsonNull());

    JsonObjectSetInplace(jNode, BT_NODE_KEY_DATA, JsonObject());
    return jNode;
}

void BT_Node_SetFunction(json jNode, int nFunctionType, string sInclude, string sFunction)
{
    string sFunctionChunk = nssFunction(sFunction, "BT_BehaviorTree_GetCurrentNode(), BT_BehaviorTree_GetCurrentTickInfo()");
    JsonObjectSetStringInplace(jNode, BT_NODE_KEY_INCLUDE + IntToString(nFunctionType), sInclude);
    JsonObjectSetStringInplace(jNode, BT_NODE_KEY_FUNCTION + IntToString(nFunctionType), sFunctionChunk);
}

void BT_Node_AddChild(json jNode, json jChild)
{
    int nNodeType = BT_Node_GetType(jNode);
    if (nNodeType == BT_NODE_TYPE_COMPOSITE)
        JsonSetAtPointerInplace(jNode, "/" + BT_NODE_KEY_CHILDREN + "/" + IntToString(JsonGetLength(BT_Node_GetChildren(jNode))), jChild);
    else if (nNodeType == BT_NODE_TYPE_DECORATOR)
        JsonObjectSetInplace(jNode, BT_NODE_KEY_CHILDREN, jChild);
    else
        LogWarning(BT_Node_GetDebugInfo(jNode) +  " is of type '" + BT_NodeTypeToString(nNodeType) + "' and does not want children :(");
}

/* *** Composite Nodes *** */

json BT_Node_Sequence()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "Sequence");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_Sequence_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Sequence_Tick");
    return jNode;
}

void BT_Node_Sequence_Open(json jNode, json jTickInfo)
{
    BT_Blackboard_StructSetValue(BT_Blackboard_GetInfo(jTickInfo, jNode), BT_BLACKBOARD_KEY_RUNNING_CHILD, JsonInt(0));
}

int BT_Node_Sequence_Tick(json jNode, json jTickInfo)
{
    struct BlackboardInfo strBlackboardInfo = BT_Blackboard_GetInfo(jTickInfo, jNode);
    json jChildren = BT_Node_GetChildren(jNode);
    int nCurrentChild = JsonGetInt(BT_Blackboard_StructGetValue(strBlackboardInfo, BT_BLACKBOARD_KEY_RUNNING_CHILD));
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = nCurrentChild; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = JsonArrayGet(jChildren, nIndex);
        int nNodeState = BT_Node_Execute(jChildNode, jTickInfo);
        if (nNodeState != BT_NODE_STATE_SUCCESS)
        {
            if (nNodeState == BT_NODE_STATE_RUNNING)
                BT_Blackboard_StructSetValue(strBlackboardInfo, BT_BLACKBOARD_KEY_RUNNING_CHILD, JsonInt(nIndex));
            return nNodeState;
        }
    }

    return BT_NODE_STATE_SUCCESS;
}

json BT_Node_ReactiveSequence()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "ReactiveSequence");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_ReactiveSequence_Tick");
    return jNode;
}

int BT_Node_ReactiveSequence_Tick(json jNode, json jTickInfo)
{
    json jChildren = BT_Node_GetChildren(jNode);
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = 0; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = JsonArrayGet(jChildren, nIndex);
        int nNodeState = BT_Node_Execute(jChildNode, jTickInfo);
        if (nNodeState != BT_NODE_STATE_SUCCESS)
            return nNodeState;
    }

    return BT_NODE_STATE_SUCCESS;
}

json BT_Node_Fallback()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "Fallback");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_Fallback_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Fallback_Tick");
    return jNode;
}

void BT_Node_Fallback_Open(json jNode, json jTickInfo)
{
    BT_Blackboard_StructSetValue(BT_Blackboard_GetInfo(jTickInfo, jNode), BT_BLACKBOARD_KEY_RUNNING_CHILD, JsonInt(0));
}

int BT_Node_Fallback_Tick(json jNode, json jTickInfo)
{
    struct BlackboardInfo strBlackboardInfo = BT_Blackboard_GetInfo(jTickInfo, jNode);
    json jChildren = BT_Node_GetChildren(jNode);
    int nCurrentChild = JsonGetInt(BT_Blackboard_StructGetValue(strBlackboardInfo, BT_BLACKBOARD_KEY_RUNNING_CHILD));
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = nCurrentChild; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = JsonArrayGet(jChildren, nIndex);
        int nNodeState = BT_Node_Execute(jChildNode, jTickInfo);
        if (nNodeState != BT_NODE_STATE_FAILURE)
        {
            if (nNodeState == BT_NODE_STATE_RUNNING)
                BT_Blackboard_StructSetValue(strBlackboardInfo, BT_BLACKBOARD_KEY_RUNNING_CHILD, JsonInt(nIndex));
            return nNodeState;
        }
    }

    return BT_NODE_STATE_FAILURE;
}

json BT_Node_ReactiveFallback()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "ReactiveFallback");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_ReactiveFallback_Tick");
    return jNode;
}

int BT_Node_ReactiveFallback_Tick(json jNode, json jTickInfo)
{
    json jChildren = BT_Node_GetChildren(jNode);
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = 0; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = JsonArrayGet(jChildren, nIndex);
        int nNodeState = BT_Node_Execute(jChildNode, jTickInfo);
        if (nNodeState != BT_NODE_STATE_FAILURE)
            return nNodeState;
    }

    return BT_NODE_STATE_FAILURE;
}

json BT_Node_Parallel(int nSuccessPolicy = BT_NODE_PARALLEL_SUCCESS_POLICY_ANY)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "Parallel");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Parallel_Tick");
    BT_Node_SetDataInt(jNode, "SuccessPolicy", nSuccessPolicy);
    return jNode;
}

int BT_Node_Parallel_Tick(json jNode, json jTickInfo)
{
    json jChildren = BT_Node_GetChildren(jNode);
    int nNumChildren = JsonGetLength(jChildren);
    int nSuccessPolicy = BT_Node_GetDataInt(jNode, "SuccessPolicy");

    int nSuccessCount = 0;
    int nFailureCount = 0;
    int nRunningCount = 0;

    int nIndex;
    for (nIndex = 0; nIndex < nNumChildren; nIndex++)
    {
        int nNodeState = BT_Node_Execute(JsonArrayGet(jChildren, nIndex), jTickInfo);
        switch (nNodeState)
        {
            case BT_NODE_STATE_SUCCESS: nSuccessCount++; break;
            case BT_NODE_STATE_FAILURE: nFailureCount++; break;
            case BT_NODE_STATE_RUNNING: nRunningCount++; break;
        }
    }

    if (nSuccessPolicy == BT_NODE_PARALLEL_SUCCESS_POLICY_ANY)
    {
        if (nSuccessCount > 0)
            return BT_NODE_STATE_SUCCESS;
        else if (nRunningCount > 0)
            return BT_NODE_STATE_RUNNING;
        else
            return BT_NODE_STATE_FAILURE;
    }
    else if (nSuccessPolicy == BT_NODE_PARALLEL_SUCCESS_POLICY_ALL)
    {
        if (nSuccessCount == nNumChildren)
            return BT_NODE_STATE_SUCCESS;
        else if (nFailureCount > 0)
            return BT_NODE_STATE_FAILURE;
        else
            return BT_NODE_STATE_RUNNING;
    }

    return BT_NODE_STATE_ERROR;
}

/* *** Decorator Nodes *** */

json BT_Node_Inverter()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Inverter");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Inverter_Tick");
    return jNode;
}

int BT_Node_Inverter_Tick(json jNode, json jTickInfo)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChild) != JSON_TYPE_OBJECT)
        return BT_NODE_STATE_ERROR;

    int nNodeState = BT_Node_Execute(jChild, jTickInfo);

    if (nNodeState == BT_NODE_STATE_SUCCESS)
        nNodeState = BT_NODE_STATE_FAILURE;
    else if (nNodeState == BT_NODE_STATE_FAILURE)
        nNodeState = BT_NODE_STATE_SUCCESS;

    return nNodeState;
}

json BT_Node_ForceSuccess()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "ForceSuccess");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_ForceSuccess_Tick");
    return jNode;
}

int BT_Node_ForceSuccess_Tick(json jNode, json jTickInfo)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChild) != JSON_TYPE_OBJECT)
        return BT_NODE_STATE_ERROR;

    int nNodeState = BT_Node_Execute(jChild, jTickInfo);

    if (nNodeState != BT_NODE_STATE_RUNNING)
        nNodeState = BT_NODE_STATE_SUCCESS;

    return nNodeState;
}

json BT_Node_ForceFailure()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "ForceFailure");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_ForceFailure_Tick");
    return jNode;
}

int BT_Node_ForceFailure_Tick(json jNode, json jTickInfo)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChild) != JSON_TYPE_OBJECT)
        return BT_NODE_STATE_ERROR;

    int nNodeState = BT_Node_Execute(jChild, jTickInfo);

    if (nNodeState != BT_NODE_STATE_RUNNING)
        nNodeState = BT_NODE_STATE_FAILURE;

    return nNodeState;
}

json BT_Node_Repeater(int nNumberOfRepeats)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Repeater");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Repeater_Tick");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_CLOSE, BT_SCRIPT_NAME, "BT_Node_Repeater_Close");
    BT_Node_SetDataInt(jNode, "NumberOfRepeats", nNumberOfRepeats);
    return jNode;
}

int BT_Node_Repeater_Tick(json jNode, json jTickInfo)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChild) != JSON_TYPE_OBJECT)
        return BT_NODE_STATE_ERROR;

    struct BlackboardInfo strBlackboardInfo = BT_Blackboard_GetInfo(jTickInfo, jNode);
    int nNumberOfRepeats = BT_Node_GetDataInt(jNode, "NumberOfRepeats");
    int nCurrentRepeatCount = JsonGetInt(BT_Blackboard_StructGetValue(strBlackboardInfo, "RepeatCount"));
    int bDoLoop = nCurrentRepeatCount < nNumberOfRepeats || nNumberOfRepeats == -1;

    while (bDoLoop)
    {
        int nNodeState = BT_Node_Execute(jChild, jTickInfo);
        switch (nNodeState)
        {
            case BT_NODE_STATE_SUCCESS:
            {
                BT_Blackboard_StructSetValue(strBlackboardInfo, "RepeatCount", JsonInt(++nCurrentRepeatCount));
                bDoLoop = nCurrentRepeatCount < nNumberOfRepeats || nNumberOfRepeats == -1;
                break;
            }

            case BT_NODE_STATE_FAILURE:
            case BT_NODE_STATE_RUNNING:
                return nNodeState;
        }
    }
    return BT_NODE_STATE_SUCCESS;
}

void BT_Node_Repeater_Close(json jNode, json jTickInfo)
{
    BT_Blackboard_StructSetValue(BT_Blackboard_GetInfo(jTickInfo, jNode), "RepeatCount", JsonInt(0));
}

json BT_Node_Timeout(int nSeconds)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Timeout");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_Timeout_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Timeout_Tick");
    BT_Node_SetDataInt(jNode, "Duration", nSeconds);
    return jNode;
}

void BT_Node_Timeout_Open(json jNode, json jTickInfo)
{
    BT_Blackboard_StructSetValue(BT_Blackboard_GetInfo(jTickInfo, jNode), "StartTime", JsonInt(SqlGetUnixEpoch()));
}

int BT_Node_Timeout_Tick(json jNode, json jTickInfo)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChild) != JSON_TYPE_OBJECT)
        return BT_NODE_STATE_ERROR;

    int nDuration = BT_Node_GetDataInt(jNode, "Duration");
    int nStartTime = JsonGetInt(BT_Blackboard_StructGetValue(BT_Blackboard_GetInfo(jTickInfo, jNode), "StartTime"));

    if (SqlGetUnixEpoch() - nStartTime > nDuration)
        return BT_NODE_STATE_FAILURE;
    else
        return BT_Node_Execute(jChild, jTickInfo);
}

json BT_Node_Probability(int nPercentage)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Probability");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Probability_Tick");
    BT_Node_SetDataInt(jNode, "Chance", nPercentage);
    return jNode;
}

int BT_Node_Probability_Tick(json jNode, json jTickInfo)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChild) != JSON_TYPE_OBJECT)
        return BT_NODE_STATE_ERROR;

    int nChance = BT_Node_GetDataInt(jNode, "Chance");

    if (Random(100) + 1 <= nChance)
        return BT_Node_Execute(jChild, jTickInfo);
    else
        return BT_NODE_STATE_FAILURE;
}

json BT_Node_Cooldown(int nSeconds)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Cooldown");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Cooldown_Tick");
    BT_Node_SetDataInt(jNode, "CooldownDuration", nSeconds);
    return jNode;
}

int BT_Node_Cooldown_Tick(json jNode, json jTickInfo)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChild) != JSON_TYPE_OBJECT)
        return BT_NODE_STATE_ERROR;

    struct BlackboardInfo strBlackboardInfo = BT_Blackboard_GetInfo(jTickInfo, jNode);
    int nCooldownDuration = BT_Node_GetDataInt(jNode, "CooldownDuration");
    int nLastExecutionTime = JsonGetInt(BT_Blackboard_StructGetValue(strBlackboardInfo, "LastExecution"));

    if (SqlGetUnixEpoch() - nLastExecutionTime < nCooldownDuration)
        return BT_NODE_STATE_FAILURE;

    int nResult = BT_Node_Execute(jChild, jTickInfo);
    if (nResult == BT_NODE_STATE_SUCCESS)
        BT_Blackboard_StructSetValue(strBlackboardInfo, "LastExecution", JsonInt(SqlGetUnixEpoch()));

    return nResult;
}
