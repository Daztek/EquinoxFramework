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

const int BT_CACHE_SCRIPT_CHUNKS                = TRUE;
const int BT_GRAPHVIZ_ENABLED                   = FALSE;

const string BT_BLACKBOARD_TAG_PREFIX           = "BTBB_";
const string BT_BLACKBOARD_KEY_IS_OPEN          = "IsOpen";
const string BT_BLACKBOARD_KEY_LAST_OPEN_NODES  = "LastOpenNodes";
const string BT_BLACKBOARD_KEY_RUNNING_CHILD    = "RunningChild";
const string BT_BLACKBOARD_KEY_LAST_RESULT      = "LastResult";

const string BT_BEHAVIORTREE_TAG_PREFIX         = "BT_";
const string BT_BEHAVIORTREE_ID                 = "BehaviorTreeID";
const string BT_BEHAVIORTREE_ROOT_NODE          = "BehaviorTreeRootNode";
const string BT_BEHAVIORTREE_NODES              = "BehaviorTreeNodes";
const string BT_BEHAVIORTREE_FUNCTION_HASHES    = "BehaviorTreeFunctionHashes";
const string BT_BEHAVIORTREE_GRAPHVIZ_ENABLED   = "BehaviorTreeGraphVizEnabled";
const string BT_BEHAVIORTREE_NODE_HAS_FUNCTION  = "BehaviorTreeNodeHasFunction_";

const string BT_BEHAVIORTREE_KEY_ROOT_NODE_ID   = "RootNodeID";
const string BT_BEHAVIORTREE_KEY_NODES          = "Nodes";

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
const string BT_NODE_KEY_TYPE                   = "T";
const string BT_NODE_KEY_TYPENAME               = "TN";
const string BT_NODE_KEY_CHILDREN               = "C";
const string BT_NODE_KEY_NAME                   = "N";
const string BT_NODE_KEY_SCRIPT_CHUNK           = "S";
const string BT_NODE_KEY_FUNCTION_HASH          = "H";
const string BT_NODE_KEY_DATA                   = "D";
const string BT_NODE_KEY_INPUT                  = "I";
const string BT_NODE_KEY_OUTPUT                 = "O";

const int BT_NODE_TYPE_BASE                     = 0;
const int BT_NODE_TYPE_COMPOSITE                = 1;
const int BT_NODE_TYPE_DECORATOR                = 2;
const int BT_NODE_TYPE_CONDITION                = 3;
const int BT_NODE_TYPE_ACTION                   = 4;

const int BT_NODE_PARALLEL_SUCCESS_POLICY_ANY   = 1;
const int BT_NODE_PARALLEL_SUCCESS_POLICY_ALL   = 2;

struct BlackboardContext
{
    object oBlackboard;
    int nBehaviorTreeID;
    int nNodeID;
};

int BT_GetUniqueID();
void BT_SetCurrentBehaviorTree(object oBehaviorTree);
object BT_GetCurrentBehaviorTree();
void BT_SetCurrentBlackboard(object oBlackboard);
object BT_GetCurrentBlackboard();
void BT_SetCurrentOpenNodes(json jOpenNodes);
json BT_GetCurrentOpenNodes();
json BT_GetCurrentNode();
void BT_SetCurrentNode(json jNode);
void BT_SetCurrentSelf(object oSelf);
object BT_GetCurrentSelf();

string BT_NodeStateToString(int nNodeState);
string BT_NodeTypeToString(int nNodeType);
string BT_NodeFunctionTypeToString(int nFunctionType);

void BT_GraphViz_Update(json jNode);
void BT_GraphViz_ResetLastResult(json jNode);

object BT_Blackboard_GetOrCreate(string sTag);
struct BlackboardContext BT_Blackboard_GetGlobalContext();
struct BlackboardContext BT_Blackboard_GetTreeContext();
struct BlackboardContext BT_Blackboard_GetNodeContext(json jNode);
void BT_Blackboard_SetInt(object oBlackboard, string sKey, int nValue, int nBehaviorTreeID = 0, int nNodeID = 0);
int BT_Blackboard_GetInt(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_DeleteInt(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_ContextSetInt(struct BlackboardContext strBlackboardContext, string sKey, int nValue);
int BT_Blackboard_ContextGetInt(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_ContextDeleteInt(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_SetString(object oBlackboard, string sKey, string sValue, int nBehaviorTreeID = 0, int nNodeID = 0);
string BT_Blackboard_GetString(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_DeleteString(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_ContextSetString(struct BlackboardContext strBlackboardContext, string sKey, string sValue);
string BT_Blackboard_ContextGetString(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_ContextDeleteString(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_SetFloat(object oBlackboard, string sKey, float fValue, int nBehaviorTreeID = 0, int nNodeID = 0);
float BT_Blackboard_GetFloat(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_DeleteFloat(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_ContextSetFloat(struct BlackboardContext strBlackboardContext, string sKey, float fValue);
float BT_Blackboard_ContextGetFloat(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_ContextDeleteFloat(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_SetObject(object oBlackboard, string sKey, object oValue, int nBehaviorTreeID = 0, int nNodeID = 0);
object BT_Blackboard_GetObject(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_DeleteObject(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_ContextSetObject(struct BlackboardContext strBlackboardContext, string sKey, object oValue);
object BT_Blackboard_ContextGetObject(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_ContextDeleteObject(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_SetJson(object oBlackboard, string sKey, json jValue, int nBehaviorTreeID = 0, int nNodeID = 0);
json BT_Blackboard_GetJson(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_DeleteJson(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);
void BT_Blackboard_ContextSetJson(struct BlackboardContext strBlackboardContext, string sKey, json jValue);
json BT_Blackboard_ContextGetJson(struct BlackboardContext strBlackboardContext, string sKey);
void BT_Blackboard_ContextDeleteJson(struct BlackboardContext strBlackboardContext, string sKey);

void BT_TickInfo_EnterNode(json jOpenNodes, json jNode);
void BT_TickInfo_OpenNode(json jOpenNodes, json jNode);
void BT_TickInfo_TickNode(json jOpenNodes, json jNode);
void BT_TickInfo_CloseNode(json jOpenNodes, json jNode);
void BT_TickInfo_ExitNode(json jOpenNodes, json jNode);

object BT_BehaviorTree_GetOrCreate(string sTag);
void BT_BehaviorTree_InitializeTree(object oBehaviorTree, json jBehaviorTree);
json BT_BehaviorTree_GetNodeByID(int nNodeID, object oBehaviorTree = OBJECT_INVALID);
string BT_BehaviorTree_GetFunctionByHash(int nHash, object oBehaviorTree = OBJECT_INVALID);
int BT_BehaviorTree_NodeHasFunction(json jNode, int nFunctionType, object oBehaviorTree = OBJECT_INVALID);
int BT_BehaviorTree_GetID(object oBehaviorTree);
void BT_BehaviorTree_SetRootNode(object oBehaviorTree, json jRootNode);
json BT_BehaviorTree_GetRootNode(object oBehaviorTree);
void BT_BehaviorTree_SetNodes(object oBehaviorTree, json jNodes);
json BT_BehaviorTree_GetNodes(object oBehaviorTree);
void BT_BehaviorTree_SetFunctionHashes(object oBehaviorTree, json jFunctionHashes);
json BT_BehaviorTree_GetFunctionHashes(object oBehaviorTree);
void BT_BehaviorTree_SetGraphVizEnabled(object oBehaviorTree, int bEnabled);
int BT_BehaviorTree_GetGraphVizEnabled(object oBehaviorTree);
void BT_BehaviorTree_Tick(object oBehaviorTree, object oBlackboard, object oSelf = OBJECT_SELF);

int BT_Node_ExecuteNodeFunction(json jNode, int nFunctionType);
int BT_Node_ExecuteFunction(json jNode, json jOpenNodes, int nFunctionType);
int BT_Node_Execute(json jNode);

int BT_Node_GetID(json jNode);
int BT_Node_GetType(json jNode);
string BT_Node_GetTypeName(json jNode);
json BT_Node_GetChildren(json jNode);
json BT_Node_SetName(json jNode, string sName);
string BT_Node_GetName(json jNode);
string BT_Node_GetScriptChunk(json jNode, int nFunctionType);
int BT_Node_GetFunctionHash(json jNode, int nFunctionType);
void BT_Node_SetData(json jNode, string sKey, json jValue);
json BT_Node_GetData(json jNode, string sKey);
void BT_Node_SetDataInt(json jNode, string sKey, int nValue);
int BT_Node_GetDataInt(json jNode, string sKey);
void BT_Node_SetDataString(json jNode, string sKey, string sValue);
string BT_Node_GetDataString(json jNode, string sKey);
void BT_Node_SetDataFloat(json jNode, string sKey, float fValue);
float BT_Node_GetDataFloat(json jNode, string sKey);
string BT_Node_GetDebugInfo(json jNode);
void BT_Node_SetInput(json jNode, string sInput);
string BT_Node_GetInput(json jNode);
void BT_Node_SetOutput(json jNode, string sInput);
string BT_Node_GetOutput(json jNode);

void BT_Node_SetFunction(json jNode, int nFunctionType, string sInclude, string sFunction);

json BT_Node_Sequence();
json BT_Node_ReactiveSequence();
json BT_Node_Fallback();
json BT_Node_ReactiveFallback();
json BT_Node_Parallel(int nSuccessPolicy = BT_NODE_PARALLEL_SUCCESS_POLICY_ANY);
json BT_Node_RandomChild();

json BT_Node_Inverter();
json BT_Node_ForceSuccess();
json BT_Node_ForceFailure();
json BT_Node_Timeout(int nTimeout);
json BT_Node_RandomTimeout(int nMinimumTimeout, int nRandomTimeout);
json BT_Node_Probability(int nPercentage);
json BT_Node_Cooldown(int nCooldown);
json BT_Node_RandomCooldown(int nMinimumCooldown, int nRandomCooldown);

/* *** Helper Functions *** */

int BT_GetUniqueID()
{
    return IncrementLocalInt(GetDataObject(BT_SCRIPT_NAME), "BTUniqueID");
}

void BT_SetCurrentBehaviorTree(object oBehaviorTree)
{
    SetLocalObject(GetModule(), "BTCurrentBehaviorTree", oBehaviorTree);
}

object BT_GetCurrentBehaviorTree()
{
    return GetLocalObject(GetModule(), "BTCurrentBehaviorTree");
}

void BT_SetCurrentBlackboard(object oBlackboard)
{
    SetLocalObject(GetModule(), "BTCurrentBlackboard", oBlackboard);
}

object BT_GetCurrentBlackboard()
{
    return GetLocalObject(GetModule(), "BTCurrentBlackboard");
}

void BT_SetCurrentOpenNodes(json jOpenNodes)
{
    SetLocalJson(GetModule(), "BTCurrentOpenNodes", jOpenNodes);
}

json BT_GetCurrentOpenNodes()
{
    return GetLocalJson(GetModule(), "BTCurrentOpenNodes");
}

json BT_GetCurrentNode()
{
    return GetLocalJson(GetModule(), "BTCurrentNode");
}

void BT_SetCurrentNode(json jNode)
{
    SetLocalJson(GetModule(), "BTCurrentNode", jNode);
}

void BT_SetCurrentSelf(object oSelf)
{
    SetLocalObject(GetModule(), "BTCurrentSelf", oSelf);
}

object BT_GetCurrentSelf()
{
    return GetLocalObject(GetModule(), "BTCurrentSelf");
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

string BT_NodeFunctionTypeToString(int nFunctionType)
{
    switch (nFunctionType)
    {
        case BT_NODE_FUNCTION_ENTER: return "Enter";
        case BT_NODE_FUNCTION_OPEN: return "Open";
        case BT_NODE_FUNCTION_TICK: return "Tick";
        case BT_NODE_FUNCTION_CLOSE: return "Close";
        case BT_NODE_FUNCTION_EXIT: return "Exit";
    }
    return "Unknown Function Type";
}

/* *** GraphViz Functions *** */

string BT_GraphViz_GetNodeStateColor(json jNode)
{
    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);

    if (BT_Blackboard_ContextGetInt(strBlackboardContext, BT_BLACKBOARD_KEY_IS_OPEN))
        return "orange";

    int nLastResult = BT_Blackboard_ContextGetInt(strBlackboardContext, BT_BLACKBOARD_KEY_LAST_RESULT);
    switch (nLastResult)
    {
        case BT_NODE_STATE_SUCCESS: return "green";
        case BT_NODE_STATE_FAILURE: return "red";
        case BT_NODE_STATE_RUNNING: return "orange";
    }
    return "gray";
}

string BT_GraphViz_GenerateNodes(json jNode, string sParentID)
{
    object oBehaviorTree = BT_GetCurrentBehaviorTree();
    string sNodeID = "node_" + IntToString(BT_Node_GetID(jNode));
    string sNodeName = BT_Node_GetName(jNode);
    string sNodeType = BT_Node_GetTypeName(jNode);
    string sColor = BT_GraphViz_GetNodeStateColor(jNode);

    string sResult = sNodeID + " [label=\"" + sNodeName + "\\n(" + sNodeType + ")\", fillcolor=" + sColor + ", fontcolor=white, style=filled]; ";

    if (sParentID != "")
        sResult += sParentID + " -> " + sNodeID + ";";

    json jChildren = BT_Node_GetChildren(jNode);
    int nIndex, nCount = JsonGetLength(jChildren);
    for (nIndex = 0; nIndex < nCount; nIndex++)
    {
        sResult += BT_GraphViz_GenerateNodes(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChildren, nIndex), oBehaviorTree), sNodeID);
    }

    return sResult;
}

string BT_GraphViz_GenerateGraphViz(json jNode)
{
    return "digraph BehaviorTree { rankdir=TB; node [shape=box, style=filled]; edge [color=gray50]; " + BT_GraphViz_GenerateNodes(jNode, "") + "}";
}

void BT_GraphViz_Update(json jNode)
{
    struct NWNX_HTTPClient_Request str;
    str.nRequestMethod = NWNX_HTTPCLIENT_REQUEST_METHOD_POST;
    str.sHost = "127.0.0.1";
    str.nPort = 5000;
    str.sPath = "/update";
    str.sData = JsonDump(JsonObjectSetString(JsonObject(), "dot", BT_GraphViz_GenerateGraphViz(jNode)));
    str.nAuthType = NWNX_HTTPCLIENT_AUTH_TYPE_NONE;
    str.nContentType = NWNX_HTTPCLIENT_CONTENT_TYPE_JSON;
    NWNX_HTTPClient_SendRequest(str);
}

void BT_GraphViz_ResetLastResult(json jNode)
{
    object oBehaviorTree = BT_GetCurrentBehaviorTree();
    BT_Blackboard_ContextDeleteInt(BT_Blackboard_GetNodeContext(jNode), BT_BLACKBOARD_KEY_LAST_RESULT);

    json jChildren = BT_Node_GetChildren(jNode);
    int nIndex, nCount = JsonGetLength(jChildren);
    for (nIndex = 0; nIndex < nCount; nIndex++)
    {
        BT_GraphViz_ResetLastResult(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChildren, nIndex), oBehaviorTree));
    }
}

/* *** Blackboard Functions *** */

object BT_Blackboard_GetOrCreate(string sTag)
{
    return GetDataObject(BT_BLACKBOARD_TAG_PREFIX + sTag);
}

struct BlackboardContext BT_Blackboard_GetGlobalContext()
{
    struct BlackboardContext str;
    str.oBlackboard = BT_GetCurrentBlackboard();
    str.nBehaviorTreeID = 0;
    str.nNodeID = 0;
    return str;
}

struct BlackboardContext BT_Blackboard_GetTreeContext()
{
    struct BlackboardContext str;
    str.oBlackboard = BT_GetCurrentBlackboard();
    str.nBehaviorTreeID = BT_BehaviorTree_GetID(BT_GetCurrentBehaviorTree());
    str.nNodeID = 0;
    return str;
}

struct BlackboardContext BT_Blackboard_GetNodeContext(json jNode)
{
    struct BlackboardContext str;
    str.oBlackboard = BT_GetCurrentBlackboard();
    str.nBehaviorTreeID = BT_BehaviorTree_GetID(BT_GetCurrentBehaviorTree());
    str.nNodeID = BT_Node_GetID(jNode);
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

void BT_Blackboard_SetInt(object oBlackboard, string sKey, int nValue, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    SetLocalInt(oBlackboard, sValueKey, nValue);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("SET INT '" + sKey + "' -> '" + IntToString(nValue) + "' (" + sValueKey + ")");
}

int BT_Blackboard_GetInt(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    int nValue = GetLocalInt(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("GET INT '" + sKey + "' -> '" + IntToString(nValue) + "' (" + sValueKey + ")");
    return nValue;
}

void BT_Blackboard_DeleteInt(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    DeleteLocalInt(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("DELETE INT '" + sKey + "' -> (" + sValueKey + ")");
}

void BT_Blackboard_ContextSetInt(struct BlackboardContext strBlackboardContext, string sKey, int nValue)
{
    BT_Blackboard_SetInt(strBlackboardContext.oBlackboard, sKey, nValue, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

int BT_Blackboard_ContextGetInt(struct BlackboardContext strBlackboardContext, string sKey)
{
    return BT_Blackboard_GetInt(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_ContextDeleteInt(struct BlackboardContext strBlackboardContext, string sKey)
{
    BT_Blackboard_DeleteInt(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_SetString(object oBlackboard, string sKey, string sValue, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    SetLocalString(oBlackboard, sValueKey, sValue);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("SET STRING '" + sKey + "' -> '" + sValue + "' (" + sValueKey + ")");
}

string BT_Blackboard_GetString(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    string sValue = GetLocalString(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("GET STRING '" + sKey + "' -> '" + sValue + "' (" + sValueKey + ")");
    return sValue;
}

void BT_Blackboard_DeleteString(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    DeleteLocalString(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("DELETE STRING '" + sKey + "' -> (" + sValueKey + ")");
}

void BT_Blackboard_ContextSetString(struct BlackboardContext strBlackboardContext, string sKey, string sValue)
{
    BT_Blackboard_SetString(strBlackboardContext.oBlackboard, sKey, sValue, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

string BT_Blackboard_ContextGetString(struct BlackboardContext strBlackboardContext, string sKey)
{
    return BT_Blackboard_GetString(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_ContextDeleteString(struct BlackboardContext strBlackboardContext, string sKey)
{
    BT_Blackboard_DeleteString(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_SetFloat(object oBlackboard, string sKey, float fValue, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    SetLocalFloat(oBlackboard, sValueKey, fValue);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("SET FLOAT '" + sKey + "' -> '" + FloatToString(fValue) + "' (" + sValueKey + ")");
}

float BT_Blackboard_GetFloat(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    float fValue = GetLocalFloat(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("GET FLOAT '" + sKey + "' -> '" + FloatToString(fValue) + "' (" + sValueKey + ")");
    return fValue;
}

void BT_Blackboard_DeleteFloat(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    DeleteLocalFloat(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("DELETE FLOAT '" + sKey + "' -> (" + sValueKey + ")");
}

void BT_Blackboard_ContextSetFloat(struct BlackboardContext strBlackboardContext, string sKey, float fValue)
{
    BT_Blackboard_SetFloat(strBlackboardContext.oBlackboard, sKey, fValue, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

float BT_Blackboard_ContextGetFloat(struct BlackboardContext strBlackboardContext, string sKey)
{
    return BT_Blackboard_GetFloat(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_ContextDeleteFloat(struct BlackboardContext strBlackboardContext, string sKey)
{
    BT_Blackboard_DeleteFloat(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_SetObject(object oBlackboard, string sKey, object oValue, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    SetLocalObject(oBlackboard, sValueKey, oValue);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("SET OBJECT '" + sKey + "' -> '" + ObjectToString(oValue) + "' (" + sValueKey + ")");
}

object BT_Blackboard_GetObject(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    object oValue = GetLocalObject(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("GET OBJECT '" + sKey + "' -> '" + ObjectToString(oValue) + "' (" + sValueKey + ")");
    return oValue;
}

void BT_Blackboard_DeleteObject(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    DeleteLocalObject(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("DELETE OBJECT '" + sKey + "' -> (" + sValueKey + ")");
}

void BT_Blackboard_ContextSetObject(struct BlackboardContext strBlackboardContext, string sKey, object oValue)
{
    BT_Blackboard_SetObject(strBlackboardContext.oBlackboard, sKey, oValue, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

object BT_Blackboard_ContextGetObject(struct BlackboardContext strBlackboardContext, string sKey)
{
    return BT_Blackboard_GetObject(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_ContextDeleteObject(struct BlackboardContext strBlackboardContext, string sKey)
{
    BT_Blackboard_DeleteObject(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_SetJson(object oBlackboard, string sKey, json jValue, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    SetLocalJson(oBlackboard, sValueKey, jValue);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("SET JSON '" + sKey + "' -> '" + JsonDump(jValue) + "' (" + sValueKey + ")");
}

json BT_Blackboard_GetJson(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    json jValue = GetLocalJson(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("GET JSON '" + sKey + "' -> '" + JsonDump(jValue) + "' (" + sValueKey + ")");
    return jValue;
}

void BT_Blackboard_DeleteJson(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sValueKey = BT_Blackboard_GetKey(nBehaviorTreeID, nNodeID, sKey);
    DeleteLocalJson(oBlackboard, sValueKey);
    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("DELETE JSON '" + sKey + "' -> (" + sValueKey + ")");
}

void BT_Blackboard_ContextSetJson(struct BlackboardContext strBlackboardContext, string sKey, json jValue)
{
    BT_Blackboard_SetJson(strBlackboardContext.oBlackboard, sKey, jValue, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

json BT_Blackboard_ContextGetJson(struct BlackboardContext strBlackboardContext, string sKey)
{
    return BT_Blackboard_GetJson(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

void BT_Blackboard_ContextDeleteJson(struct BlackboardContext strBlackboardContext, string sKey)
{
    BT_Blackboard_DeleteJson(strBlackboardContext.oBlackboard, sKey, strBlackboardContext.nBehaviorTreeID, strBlackboardContext.nNodeID);
}

/* *** TickInfo Functions *** */

void BT_TickInfo_EnterNode(json jOpenNodes, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_EnterNode: " + BT_Node_GetDebugInfo(jNode));

    JsonArrayInsertIntInplace(jOpenNodes, BT_Node_GetID(jNode));
}

void BT_TickInfo_OpenNode(json jOpenNodes, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_OpenNode: " + BT_Node_GetDebugInfo(jNode));
}

void BT_TickInfo_TickNode(json jOpenNodes, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_TickNode: " + BT_Node_GetDebugInfo(jNode));
}

void BT_TickInfo_CloseNode(json jOpenNodes, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_CloseNode: " + BT_Node_GetDebugInfo(jNode));

    int nNumOpenNodes = JsonGetLength(jOpenNodes);

    if (!nNumOpenNodes) return;

    int nIndex, nNodeID = BT_Node_GetID(jNode), bFound = FALSE;
    for (nIndex = nNumOpenNodes - 1; nIndex >= 0; nIndex--)
    {
        if (JsonArrayGetInt(jOpenNodes, nIndex) == nNodeID)
        {
            bFound = TRUE;
            break;
        }
    }

    if (bFound)
    {
        if (nIndex != (nNumOpenNodes - 1))
            LogWarning(BT_Node_GetDebugInfo(jNode) + ": closing node is not the last element");

        JsonArrayDelInplace(jOpenNodes, nIndex);
    }
}

void BT_TickInfo_ExitNode(json jOpenNodes, json jNode)
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

void BT_BehaviorTree_InitializeTree(object oBehaviorTree, json jBehaviorTree)
{
    int nRootNodeID = JsonObjectGetInt(jBehaviorTree, BT_BEHAVIORTREE_KEY_ROOT_NODE_ID);
    json jNodes = JsonObjectGet(jBehaviorTree, BT_BEHAVIORTREE_KEY_NODES);
    json jRootNode, jFunctionHashes = JsonObject();

    string sRootID = IntToString(nRootNodeID);
    json jNodeKeys = JsonObjectKeys(jNodes);
    int nNodeIndex, nNumNodes = JsonGetLength(jNodeKeys);
    for (nNodeIndex = 0; nNodeIndex < nNumNodes; nNodeIndex++)
    {
        string sNodeID = JsonArrayGetString(jNodeKeys, nNodeIndex);
        json jNode = JsonObjectGet(jNodes, sNodeID);
        int nFunctionType;
        for (nFunctionType = 1; nFunctionType <= BT_NODE_FUNCTION_EXIT; nFunctionType++)
        {
            string sScriptChunk = BT_Node_GetScriptChunk(jNode, nFunctionType);
            if (sScriptChunk != "")
            {
                string sFunctionType = IntToString(nFunctionType);
                int nHash = HashString(sScriptChunk);
                JsonObjectSetIntInplace(jNode, BT_NODE_KEY_FUNCTION_HASH + sFunctionType, nHash);
                JsonObjectDelInplace(jNode, BT_NODE_KEY_SCRIPT_CHUNK + sFunctionType);
                JsonObjectSetStringInplace(jFunctionHashes, IntToString(nHash), sScriptChunk);
                SetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_NODE_HAS_FUNCTION + sNodeID + sFunctionType, TRUE);
            }
        }

        if (sNodeID == sRootID)
            jRootNode = jNode;

        JsonObjectSetInplace(jNodes, sNodeID, jNode);
    }

    BT_BehaviorTree_SetRootNode(oBehaviorTree, jRootNode);
    BT_BehaviorTree_SetNodes(oBehaviorTree, jNodes);
    BT_BehaviorTree_SetFunctionHashes(oBehaviorTree, jFunctionHashes);
}

json BT_BehaviorTree_GetNodeByID(int nNodeID, object oBehaviorTree = OBJECT_INVALID)
{
    if (oBehaviorTree == OBJECT_INVALID)
        oBehaviorTree = BT_GetCurrentBehaviorTree();
    return JsonObjectGet(BT_BehaviorTree_GetNodes(oBehaviorTree), IntToString(nNodeID));
}

string BT_BehaviorTree_GetFunctionByHash(int nHash, object oBehaviorTree = OBJECT_INVALID)
{
    if (!nHash)
        return "";
    if (oBehaviorTree == OBJECT_INVALID)
        oBehaviorTree = BT_GetCurrentBehaviorTree();
    json jFunctionHashes = BT_BehaviorTree_GetFunctionHashes(oBehaviorTree);
    return JsonObjectGetString(jFunctionHashes, IntToString(nHash));
}

int BT_BehaviorTree_NodeHasFunction(json jNode, int nFunctionType, object oBehaviorTree = OBJECT_INVALID)
{
    if (oBehaviorTree == OBJECT_INVALID)
        oBehaviorTree = BT_GetCurrentBehaviorTree();
    return GetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_NODE_HAS_FUNCTION + IntToString(BT_Node_GetID(jNode)) + IntToString(nFunctionType));
}

int BT_BehaviorTree_GetID(object oBehaviorTree)
{
    return GetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_ID);
}

void BT_BehaviorTree_SetRootNode(object oBehaviorTree, json jRootNode)
{
    SetLocalJson(oBehaviorTree, BT_BEHAVIORTREE_ROOT_NODE, jRootNode);
}

json BT_BehaviorTree_GetRootNode(object oBehaviorTree)
{
    return GetLocalJson(oBehaviorTree, BT_BEHAVIORTREE_ROOT_NODE);
}

void BT_BehaviorTree_SetNodes(object oBehaviorTree, json jNodes)
{
    SetLocalJson(oBehaviorTree, BT_BEHAVIORTREE_NODES, jNodes);
}

json BT_BehaviorTree_GetNodes(object oBehaviorTree)
{
    return GetLocalJson(oBehaviorTree, BT_BEHAVIORTREE_NODES);
}

void BT_BehaviorTree_SetFunctionHashes(object oBehaviorTree, json jFunctionHashes)
{
    SetLocalJson(oBehaviorTree, BT_BEHAVIORTREE_FUNCTION_HASHES, jFunctionHashes);
}

json BT_BehaviorTree_GetFunctionHashes(object oBehaviorTree)
{
    return GetLocalJson(oBehaviorTree, BT_BEHAVIORTREE_FUNCTION_HASHES);
}

void BT_BehaviorTree_SetGraphVizEnabled(object oBehaviorTree, int bEnabled)
{
    SetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_GRAPHVIZ_ENABLED, bEnabled);
}

int BT_BehaviorTree_GetGraphVizEnabled(object oBehaviorTree)
{
    return GetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_GRAPHVIZ_ENABLED);
}

void BT_BehaviorTree_Tick(object oBehaviorTree, object oBlackboard, object oSelf = OBJECT_SELF)
{
    if (BT_DEBUG_LOG_TICKS)
        LogDebug("--- TICK START ---");

    json jCurrentOpenNodes = JsonArray();
    BT_SetCurrentBehaviorTree(oBehaviorTree);
    BT_SetCurrentBlackboard(oBlackboard);
    BT_SetCurrentSelf(oSelf);
    BT_SetCurrentOpenNodes(jCurrentOpenNodes);

    json jRootNode = BT_BehaviorTree_GetRootNode(oBehaviorTree);
    int nNodeState = BT_Node_Execute(jRootNode);

    if (BT_GRAPHVIZ_ENABLED && BT_BehaviorTree_GetGraphVizEnabled(oBehaviorTree))
    {
        BT_GraphViz_Update(jRootNode);
        if (nNodeState != BT_NODE_STATE_RUNNING)
            BT_GraphViz_ResetLastResult(jRootNode);
    }

    int nBehaviorTreeID = BT_BehaviorTree_GetID(oBehaviorTree);
    json jLastOpenNodes = BT_Blackboard_GetJson(oBlackboard, BT_BLACKBOARD_KEY_LAST_OPEN_NODES, nBehaviorTreeID);
    int nLastOpenNodesLength = JsonGetLength(jLastOpenNodes);
    int nCurrentOpenNodesLength = JsonGetLength(jCurrentOpenNodes);
    int nIndex, nStart = nLastOpenNodesLength, nNumNodes = min(nLastOpenNodesLength, nCurrentOpenNodesLength);
    for (nIndex = 0; nIndex < nNumNodes; nIndex++)
    {
        if (JsonArrayGet(jLastOpenNodes, nIndex) != JsonArrayGet(jCurrentOpenNodes, nIndex))
        {
            nStart = nIndex;
            break;
        }
    }

    if (nStart == nLastOpenNodesLength && nLastOpenNodesLength > nCurrentOpenNodesLength)
        nStart = nCurrentOpenNodesLength;

    int bGraphVizEnabled = BT_GRAPHVIZ_ENABLED && BT_BehaviorTree_GetGraphVizEnabled(oBehaviorTree);
    for (nIndex = nLastOpenNodesLength - 1; nIndex >= nStart; nIndex--)
    {
        int nNodeID = JsonArrayGetInt(jLastOpenNodes, nIndex);
        if (BT_Blackboard_GetInt(oBlackboard, BT_BLACKBOARD_KEY_IS_OPEN, nBehaviorTreeID, nNodeID))
        {
            BT_Node_ExecuteFunction(BT_BehaviorTree_GetNodeByID(nNodeID, oBehaviorTree), jCurrentOpenNodes, BT_NODE_FUNCTION_CLOSE);
            if (bGraphVizEnabled)
                BT_Blackboard_DeleteInt(oBlackboard, BT_BLACKBOARD_KEY_LAST_RESULT, nBehaviorTreeID, nNodeID);
        }
    }

    BT_Blackboard_SetJson(oBlackboard, BT_BLACKBOARD_KEY_LAST_OPEN_NODES, jCurrentOpenNodes, nBehaviorTreeID);

    if (BT_DEBUG_LOG_TICKS)
        LogDebug("--- TICK END ---");
}

/* *** Node Execution Functions *** */

int BT_Node_ExecuteNodeFunction(json jNode, int nFunctionType)
{
    int nRetVal = BT_NODE_STATE_FAILURE;
    object oBehaviorTree = BT_GetCurrentBehaviorTree();
    if (!BT_BehaviorTree_NodeHasFunction(jNode, nFunctionType, oBehaviorTree))
        return nRetVal;

    string sFunctionScriptChunk = BT_BehaviorTree_GetFunctionByHash(BT_Node_GetFunctionHash(jNode, nFunctionType), oBehaviorTree);
    if (sFunctionScriptChunk != "")
    {
        BT_SetCurrentNode(jNode);
        string sError = ExecuteScriptChunk(sFunctionScriptChunk, BT_GetCurrentSelf(), FALSE);

        if (sError != "")
            LogError(BT_Node_GetDebugInfo(jNode) + " failed to run function '" + BT_NodeFunctionTypeToString(nFunctionType) + "' with error: " + sError);

        if (nFunctionType == BT_NODE_FUNCTION_TICK)
            nRetVal = NWNX_VM_GetScriptReturnValueInt();

        return nRetVal == 0 ? BT_NODE_STATE_ERROR : nRetVal;
    }
    return nRetVal;
}

int BT_Node_ExecuteFunction(json jNode, json jOpenNodes, int nFunctionType)
{
    int nRetVal = 0;
    switch (nFunctionType)
    {
        case BT_NODE_FUNCTION_ENTER:
        {
            BT_TickInfo_EnterNode(jOpenNodes, jNode);
            BT_Node_ExecuteNodeFunction(jNode, nFunctionType);
            break;
        }

        case BT_NODE_FUNCTION_OPEN:
        {
            BT_TickInfo_OpenNode(jOpenNodes, jNode);
            BT_Blackboard_ContextSetInt(BT_Blackboard_GetNodeContext(jNode), BT_BLACKBOARD_KEY_IS_OPEN, TRUE);
            BT_Node_ExecuteNodeFunction(jNode, nFunctionType);
            break;
        }

        case BT_NODE_FUNCTION_TICK:
        {
            BT_TickInfo_TickNode(jOpenNodes, jNode);
            nRetVal = BT_Node_ExecuteNodeFunction(jNode, nFunctionType);
            break;
        }

        case BT_NODE_FUNCTION_CLOSE:
        {
            BT_TickInfo_CloseNode(jOpenNodes, jNode);
            BT_Blackboard_ContextSetInt(BT_Blackboard_GetNodeContext(jNode), BT_BLACKBOARD_KEY_IS_OPEN, FALSE);
            BT_Node_ExecuteNodeFunction(jNode, nFunctionType);
            break;
        }

        case BT_NODE_FUNCTION_EXIT:
        {
            BT_TickInfo_ExitNode(jOpenNodes, jNode);
            BT_Node_ExecuteNodeFunction(jNode, nFunctionType);
            break;
        }
    }

    return nRetVal;
}

int BT_Node_Execute(json jNode)
{
    json jOpenNodes = BT_GetCurrentOpenNodes();
    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);

    BT_Node_ExecuteFunction(jNode, jOpenNodes, BT_NODE_FUNCTION_ENTER);

    if (!BT_Blackboard_ContextGetInt(strBlackboardContext, BT_BLACKBOARD_KEY_IS_OPEN))
        BT_Node_ExecuteFunction(jNode, jOpenNodes, BT_NODE_FUNCTION_OPEN);

    int nNodeState = BT_Node_ExecuteFunction(jNode, jOpenNodes, BT_NODE_FUNCTION_TICK);

    if (BT_GRAPHVIZ_ENABLED && BT_BehaviorTree_GetGraphVizEnabled(BT_GetCurrentBehaviorTree()))
        BT_Blackboard_ContextSetInt(strBlackboardContext, BT_BLACKBOARD_KEY_LAST_RESULT, nNodeState);

    if (nNodeState == BT_NODE_STATE_ERROR)
        LogWarning(BT_Node_GetDebugInfo(jNode) + ": node returned an error state");

    if (nNodeState != BT_NODE_STATE_RUNNING)
        BT_Node_ExecuteFunction(jNode, jOpenNodes, BT_NODE_FUNCTION_CLOSE);

    BT_Node_ExecuteFunction(jNode, jOpenNodes, BT_NODE_FUNCTION_EXIT);

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

string BT_Node_GetScriptChunk(json jNode, int nFunctionType)
{
    return JsonObjectGetString(jNode, BT_NODE_KEY_SCRIPT_CHUNK + IntToString(nFunctionType));
}

int BT_Node_GetFunctionHash(json jNode, int nFunctionType)
{
    return JsonObjectGetInt(jNode, BT_NODE_KEY_FUNCTION_HASH + IntToString(nFunctionType));
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

void BT_Node_SetInput(json jNode, string sInput)
{
    BT_Node_SetDataString(jNode, BT_NODE_KEY_INPUT, sInput);
}

string BT_Node_GetInput(json jNode)
{
    return BT_Node_GetDataString(jNode, BT_NODE_KEY_INPUT);
}

void BT_Node_SetOutput(json jNode, string sInput)
{
    BT_Node_SetDataString(jNode, BT_NODE_KEY_OUTPUT, sInput);
}

string BT_Node_GetOutput(json jNode)
{
    return BT_Node_GetDataString(jNode, BT_NODE_KEY_OUTPUT);
}

/* *** Base Node *** */

json BT_Node_BaseNode(int nNodeType, string sTypeName)
{
    json jNode = JsonObject();
    JsonObjectSetIntInplace(jNode, BT_NODE_KEY_ID, BT_GetUniqueID());
    JsonObjectSetIntInplace(jNode, BT_NODE_KEY_TYPE, nNodeType);
    JsonObjectSetStringInplace(jNode, BT_NODE_KEY_TYPENAME, sTypeName);
    JsonObjectSetInplace(jNode, BT_NODE_KEY_CHILDREN, JsonArray());
    JsonObjectSetInplace(jNode, BT_NODE_KEY_DATA, JsonObject());
    return jNode;
}

void BT_Node_SetFunction(json jNode, int nFunctionType, string sInclude, string sFunction)
{
    string sScriptChunk = nssInclude(sInclude);
    if (nFunctionType == BT_NODE_FUNCTION_TICK)
        sScriptChunk += nssIntMain(nssFunction(sFunction, "BT_GetCurrentNode()"));
    else
        sScriptChunk += nssVoidMain(nssFunction(sFunction, "BT_GetCurrentNode()"));

    JsonObjectSetStringInplace(jNode, BT_NODE_KEY_SCRIPT_CHUNK + IntToString(nFunctionType), sScriptChunk);
    CacheScriptChunk(sScriptChunk, FALSE, BT_CACHE_SCRIPT_CHUNKS);
}

/* *** Composite Nodes *** */

json BT_Node_Sequence()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "Sequence");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_Sequence_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Sequence_Tick");
    return jNode;
}

void BT_Node_Sequence_Open(json jNode)
{
    BT_Blackboard_ContextSetInt(BT_Blackboard_GetNodeContext(jNode), BT_BLACKBOARD_KEY_RUNNING_CHILD, 0);
}

int BT_Node_Sequence_Tick(json jNode)
{
    object oBehaviorTree = BT_GetCurrentBehaviorTree();
    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);
    json jChildren = BT_Node_GetChildren(jNode);
    int nCurrentChild = BT_Blackboard_ContextGetInt(strBlackboardContext, BT_BLACKBOARD_KEY_RUNNING_CHILD);
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = nCurrentChild; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChildren, nIndex), oBehaviorTree);
        int nNodeState = BT_Node_Execute(jChildNode);
        if (nNodeState != BT_NODE_STATE_SUCCESS)
        {
            if (nNodeState == BT_NODE_STATE_RUNNING)
                BT_Blackboard_ContextSetInt(strBlackboardContext, BT_BLACKBOARD_KEY_RUNNING_CHILD, nIndex);
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

int BT_Node_ReactiveSequence_Tick(json jNode)
{
    object oBehaviorTree = BT_GetCurrentBehaviorTree();
    json jChildren = BT_Node_GetChildren(jNode);
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = 0; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChildren, nIndex), oBehaviorTree);
        int nNodeState = BT_Node_Execute(jChildNode);
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

void BT_Node_Fallback_Open(json jNode)
{
    BT_Blackboard_ContextSetInt(BT_Blackboard_GetNodeContext(jNode), BT_BLACKBOARD_KEY_RUNNING_CHILD, 0);
}

int BT_Node_Fallback_Tick(json jNode)
{
    object oBehaviorTree = BT_GetCurrentBehaviorTree();
    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);
    json jChildren = BT_Node_GetChildren(jNode);
    int nCurrentChild = BT_Blackboard_ContextGetInt(strBlackboardContext, BT_BLACKBOARD_KEY_RUNNING_CHILD);
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = nCurrentChild; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChildren, nIndex), oBehaviorTree);
        int nNodeState = BT_Node_Execute(jChildNode);
        if (nNodeState != BT_NODE_STATE_FAILURE)
        {
            if (nNodeState == BT_NODE_STATE_RUNNING)
                BT_Blackboard_ContextSetInt(strBlackboardContext, BT_BLACKBOARD_KEY_RUNNING_CHILD, nIndex);
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

int BT_Node_ReactiveFallback_Tick(json jNode)
{
    object oBehaviorTree = BT_GetCurrentBehaviorTree();
    json jChildren = BT_Node_GetChildren(jNode);
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = 0; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChildren, nIndex), oBehaviorTree);
        int nNodeState = BT_Node_Execute(jChildNode);
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

int BT_Node_Parallel_Tick(json jNode)
{
    object oBehaviorTree = BT_GetCurrentBehaviorTree();
    json jChildren = BT_Node_GetChildren(jNode);
    int nNumChildren = JsonGetLength(jChildren);
    int nSuccessPolicy = BT_Node_GetDataInt(jNode, "SuccessPolicy");

    int nSuccessCount = 0;
    int nFailureCount = 0;
    int nRunningCount = 0;

    int nIndex;
    for (nIndex = 0; nIndex < nNumChildren; nIndex++)
    {
        int nNodeState = BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChildren, nIndex), oBehaviorTree));
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

json BT_Node_RandomChild()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "RandomChild");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_RandomChild_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_RandomChild_Tick");
    return jNode;
}

void BT_Node_RandomChild_Open(json jNode)
{
    json jChildren = BT_Node_GetChildren(jNode);
    int nRandomChildID = JsonArrayGetInt(jChildren, Random(JsonGetLength(jChildren)));
    BT_Blackboard_ContextSetInt(BT_Blackboard_GetNodeContext(jNode), "RandomChildID", nRandomChildID);
}

int BT_Node_RandomChild_Tick(json jNode)
{
    int nRandomChildID = BT_Blackboard_ContextGetInt(BT_Blackboard_GetNodeContext(jNode), "RandomChildID");
    return BT_Node_Execute(BT_BehaviorTree_GetNodeByID(nRandomChildID));
}

/* *** Decorator Nodes *** */

json BT_Node_Inverter()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Inverter");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Inverter_Tick");
    return jNode;
}

int BT_Node_Inverter_Tick(json jNode)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetLength(jChild) != 1)
        return BT_NODE_STATE_ERROR;

    int nNodeState = BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChild, 0)));

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

int BT_Node_ForceSuccess_Tick(json jNode)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetLength(jChild) != 1)
        return BT_NODE_STATE_ERROR;

    int nNodeState = BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChild, 0)));

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

int BT_Node_ForceFailure_Tick(json jNode)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetLength(jChild) != 1)
        return BT_NODE_STATE_ERROR;

    int nNodeState = BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChild, 0)));

    if (nNodeState != BT_NODE_STATE_RUNNING)
        nNodeState = BT_NODE_STATE_FAILURE;

    return nNodeState;
}

json BT_Node_Timeout(int nTimeout)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Timeout");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_Timeout_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Timeout_Tick");
    BT_Node_SetDataInt(jNode, "Timeout", nTimeout);
    return jNode;
}

void BT_Node_Timeout_Open(json jNode)
{
    BT_Blackboard_ContextSetInt(BT_Blackboard_GetNodeContext(jNode), "StartTime", GetCurrentTimeSeconds());
}

int BT_Node_Timeout_Tick(json jNode)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetLength(jChild) != 1)
        return BT_NODE_STATE_ERROR;

    int nTimeout = BT_Node_GetDataInt(jNode, "Timeout");
    int nStartTime = BT_Blackboard_ContextGetInt(BT_Blackboard_GetNodeContext(jNode), "StartTime");

    if (GetCurrentTimeSeconds() - nStartTime > nTimeout)
        return BT_NODE_STATE_FAILURE;
    else
        return BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChild, 0)));
}

json BT_Node_RandomTimeout(int nMinimumTimeout, int nRandomTimeout)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "RandomTimeout");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_RandomTimeout_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_RandomTimeout_Tick");
    BT_Node_SetDataInt(jNode, "MinimumTimeout", nMinimumTimeout);
    BT_Node_SetDataInt(jNode, "RandomTimeout", nRandomTimeout);
    return jNode;
}

void BT_Node_RandomTimeout_Open(json jNode)
{
    int nMinimumTimeout = BT_Node_GetDataInt(jNode, "MinimumTimeout");
    int nRandomTimeout = BT_Node_GetDataInt(jNode, "RandomTimeout");
    int nTimeout = nMinimumTimeout + Random(nRandomTimeout);
    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);
    BT_Blackboard_ContextSetInt(strBlackboardContext, "Timeout", nTimeout);
    BT_Blackboard_ContextSetInt(strBlackboardContext, "StartTime", GetCurrentTimeSeconds());
}

int BT_Node_RandomTimeout_Tick(json jNode)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetLength(jChild) != 1)
        return BT_NODE_STATE_ERROR;

    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);
    int nTimeout = BT_Blackboard_ContextGetInt(strBlackboardContext, "Timeout");
    int nStartTime = BT_Blackboard_ContextGetInt(strBlackboardContext, "StartTime");

    if (GetCurrentTimeSeconds() - nStartTime > nTimeout)
        return BT_NODE_STATE_FAILURE;
    else
        return BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChild, 0)));
}

json BT_Node_Probability(int nPercentage)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Probability");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Probability_Tick");
    BT_Node_SetDataInt(jNode, "Chance", nPercentage);
    return jNode;
}

int BT_Node_Probability_Tick(json jNode)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetLength(jChild) != 1)
        return BT_NODE_STATE_ERROR;

    int nChance = BT_Node_GetDataInt(jNode, "Chance");

    if (Random(100) + 1 <= nChance)
        return BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChild, 0)));
    else
        return BT_NODE_STATE_FAILURE;
}

json BT_Node_Cooldown(int nCooldown)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Cooldown");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Cooldown_Tick");
    BT_Node_SetDataInt(jNode, "Cooldown", nCooldown);
    return jNode;
}

int BT_Node_Cooldown_Tick(json jNode)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetLength(jChild) != 1)
        return BT_NODE_STATE_ERROR;

    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);
    int nCooldown = BT_Node_GetDataInt(jNode, "Cooldown");
    int nLastExecutionTime = BT_Blackboard_ContextGetInt(strBlackboardContext, "LastExecution");

    if (GetCurrentTimeSeconds() - nLastExecutionTime < nCooldown)
        return BT_NODE_STATE_FAILURE;

    int nResult = BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChild, 0)));
    if (nResult == BT_NODE_STATE_SUCCESS)
        BT_Blackboard_ContextSetInt(strBlackboardContext, "LastExecution", GetCurrentTimeSeconds());

    return nResult;
}

json BT_Node_RandomCooldown(int nMinimumCooldown, int nRandomCooldown)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "RandomCooldown");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_RandomCooldown_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_RandomCooldown_Tick");
    BT_Node_SetDataInt(jNode, "MinimumCooldown", nMinimumCooldown);
    BT_Node_SetDataInt(jNode, "RandomCooldown", nRandomCooldown);
    return jNode;
}

void BT_Node_RandomCooldown_Open(json jNode)
{
    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);
    if (!BT_Blackboard_ContextGetInt(strBlackboardContext, "Cooldown"))
    {
        int nMinimumCooldown = BT_Node_GetDataInt(jNode, "MinimumCooldown");
        int nRandomCooldown = BT_Node_GetDataInt(jNode, "RandomCooldown");
        int nCooldown = nMinimumCooldown + Random(nRandomCooldown);
        BT_Blackboard_ContextSetInt(strBlackboardContext, "Cooldown", nCooldown);
    }
}

int BT_Node_RandomCooldown_Tick(json jNode)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetLength(jChild) != 1)
        return BT_NODE_STATE_ERROR;

    struct BlackboardContext strBlackboardContext = BT_Blackboard_GetNodeContext(jNode);
    int nCooldown = BT_Blackboard_ContextGetInt(strBlackboardContext, "Cooldown");
    int nLastExecutionTime = BT_Blackboard_ContextGetInt(strBlackboardContext, "LastExecution");

    if (GetCurrentTimeSeconds() - nLastExecutionTime < nCooldown)
        return BT_NODE_STATE_FAILURE;

    int nResult = BT_Node_Execute(BT_BehaviorTree_GetNodeByID(JsonArrayGetInt(jChild, 0)));
    if (nResult == BT_NODE_STATE_SUCCESS)
    {
        int nMinimumCooldown = BT_Node_GetDataInt(jNode, "MinimumCooldown");
        int nRandomCooldown = BT_Node_GetDataInt(jNode, "RandomCooldown");
        int nNextCooldown = nMinimumCooldown + Random(nRandomCooldown);
        BT_Blackboard_ContextSetInt(strBlackboardContext, "Cooldown", nNextCooldown);
        BT_Blackboard_ContextSetInt(strBlackboardContext, "LastExecution", GetCurrentTimeSeconds());
    }

    return nResult;
}
