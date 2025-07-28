/*
    Script: ef_s_bt
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_c_profiler"

const string BT_SCRIPT_NAME                     = "ef_s_bt";
const int BT_DEBUG_LOG_TICKS                    = TRUE;
const int BT_DEBUG_LOG_TICK_INFO                = FALSE;
const int BT_DEBUG_LOG_MEMORY_INFO              = FALSE;

const string BT_BLACKBOARD_TAG_PREFIX           = "BTBB_";
const string BT_BLACKBOARD_BASE_MEMORY          = "BaseMemory";
const string BT_BLACKBOARD_TREE_MEMORY          = "TreeMemory";
const string BT_BLACKBOARD_NODE_MEMORY          = "NodeMemory";

const string BT_BEHAVIORTREE_TAG_PREFIX         = "BT_";
const string BT_BEHAVIORTREE_ID                 = "BehaviorTreeID";
const string BT_BEHAVIORTREE_ROOT               = "BehaviorTreeRoot";

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

int BT_GenerateUniqueID();
string BT_NodeStateToString(int nNodeState);
string BT_NodeTypeToString(int nNodeType);

object BT_Blackboard_GetOrCreate(string sTag);
void BT_Blackboard_SetValue(object oBB, string sKey, json jValue, int nBehaviorTreeID = 0, int nNodeID = 0);
json BT_Blackboard_GetValue(object oBB, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0);

json BT_TickInfo_Create(object oBehaviorTree, object oBlackboard, object oTarget = OBJECT_SELF);
object BT_TickInfo_GetBehaviorTree(json jTickInfo);
int BT_TickInfo_GetBehaviorTreeID(json jTickInfo);
object BT_TickInfo_GetBlackboard(json jTickInfo);
json BT_TickInfo_GetOpenNodes(json jTickInfo);
int BT_TickInfo_GetNodeCount(json jTickInfo);
object BT_TickInfo_GetTarget(json jTickInfo);
void BT_TickInfo_EnterNode(json jTickInfo, json jNode);
void BT_TickInfo_OpenNode(json jTickInfo, json jNode);
void BT_TickInfo_TickNode(json jTickInfo, json jNode);
void BT_TickInfo_CloseNode(json jTickInfo, json jNode);
void BT_TickInfo_ExitNode(json jTickInfo, json jNode);

object BT_BehaviorTree_GetOrCreate(string sTag);
int BT_BehaviorTree_GetID(object oBehaviorTree);
void BT_BehaviorTree_SetRoot(object oBehaviorTree, json jRoot);
json BT_BehaviorTree_GetRoot(object oBehaviorTree);
void BT_BehaviorTree_Tick(object oBehaviorTree, object oBlackboard, object oTarget = OBJECT_SELF);

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
string BT_Node_GetDebugInfo(json jNode);

void BT_Node_SetFunction(json jNode, int nFunctionType, string sInclude, string sFunction);
void BT_Node_AddChild(json jNode, json jChild);


/* *** Helper Functions *** */

int BT_GenerateUniqueID()
{
    object oDataObject = GetDataObject(BT_SCRIPT_NAME);
    int nID = GetLocalInt(oDataObject, "BTUniqueID") + 1;
    SetLocalInt(oDataObject, "BTUniqueID", nID);
    return nID;
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
    return "Unknown";
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
    return "Unknown";
}

/* *** Blackboard Functions *** */

object BT_Blackboard_GetOrCreate(string sTag)
{
    object oBlackboard = GetDataObject(BT_BLACKBOARD_TAG_PREFIX + sTag, FALSE);
    if (!GetIsObjectValid(oBlackboard))
    {
        oBlackboard = CreateDataObject(BT_BLACKBOARD_TAG_PREFIX + sTag);
        SetLocalJson(oBlackboard, BT_BLACKBOARD_BASE_MEMORY, JsonObject());
        SetLocalJson(oBlackboard, BT_BLACKBOARD_TREE_MEMORY, JsonObject());
    }
    return oBlackboard;
}

string BT_Blackboard_GetMemoryPointer(int nBehaviorTreeID, int nNodeID, string sKey)
{
    if (nBehaviorTreeID)
    {
        if (nNodeID)
            return "/TID" + IntToString(nBehaviorTreeID) + "/" + BT_BLACKBOARD_NODE_MEMORY + "/NID" + IntToString(nNodeID) + "/" + sKey;
        else
            return "/TID" + IntToString(nBehaviorTreeID) + "/" + sKey;

    }
    return BT_BLACKBOARD_BASE_MEMORY;
}

void BT_Blackboard_SetValue(object oBlackboard, string sKey, json jValue, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    string sPointer = BT_Blackboard_GetMemoryPointer(nBehaviorTreeID, nNodeID, sKey);
    if (sPointer == BT_BLACKBOARD_BASE_MEMORY)
        JsonObjectSetInplace(GetLocalJson(oBlackboard, BT_BLACKBOARD_BASE_MEMORY), sKey, jValue);
    else
        JsonSetAtPointerInplace(GetLocalJson(oBlackboard, BT_BLACKBOARD_TREE_MEMORY), sPointer, jValue);

    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("SET '" + sKey + "' -> '" + JsonDump(jValue) + "' (" + sPointer + ")");
}

json BT_Blackboard_GetValue(object oBlackboard, string sKey, int nBehaviorTreeID = 0, int nNodeID = 0)
{
    json jValue;
    string sPointer = BT_Blackboard_GetMemoryPointer(nBehaviorTreeID, nNodeID, sKey);
    if (sPointer == BT_BLACKBOARD_BASE_MEMORY)
        jValue = JsonObjectGet(GetLocalJson(oBlackboard, BT_BLACKBOARD_BASE_MEMORY), sKey);
    else
        jValue = JsonPointer(GetLocalJson(oBlackboard, BT_BLACKBOARD_TREE_MEMORY), sPointer);

    if (BT_DEBUG_LOG_MEMORY_INFO)
        LogDebug("GET '" + sKey + "' -> '" + JsonDump(jValue) + "' (" + sPointer + ")");

    return jValue;
}

/* *** TickInfo Functions *** */

json BT_TickInfo_Create(object oBehaviorTree, object oBlackboard, object oTarget = OBJECT_SELF)
{
    json jTickInfo = JsonObject();
    JsonObjectSetObjectInplace(jTickInfo, "BehaviorTree", oBehaviorTree);
    JsonObjectSetIntInplace(jTickInfo, "BehaviorTreeID", BT_BehaviorTree_GetID(oBehaviorTree));
    JsonObjectSetObjectInplace(jTickInfo, "Blackboard", oBlackboard);
    JsonObjectSetInplace(jTickInfo, "OpenNodes", JsonArray());
    JsonObjectSetIntInplace(jTickInfo, "NodeCount", 0);
    JsonObjectSetObjectInplace(jTickInfo, "Target", oTarget);
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

object BT_TickInfo_GetTarget(json jTickInfo)
{
    return JsonObjectGetObject(jTickInfo, "Target");
}

void BT_TickInfo_EnterNode(json jTickInfo, json jNode)
{
    if (BT_DEBUG_LOG_TICK_INFO)
        LogDebug("BT_TickInfo_EnterNode: " + BT_Node_GetDebugInfo(jNode));

    JsonSetAtPointerInplace(jTickInfo, "/NodeCount", JsonInt(BT_TickInfo_GetNodeCount(jTickInfo) + 1));
    JsonSetAtPointerInplace(jTickInfo, "/OpenNodes/" + IntToString(JsonGetLength(BT_TickInfo_GetOpenNodes(jTickInfo))), jNode);
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
        JsonSetAtPointerInplace(jTickInfo, "/OpenNodes", jOpenNodes);
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
        SetLocalInt(oBehaviorTree, BT_BEHAVIORTREE_ID, BT_GenerateUniqueID());
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

void BT_BehaviorTree_Tick(object oBehaviorTree, object oBlackboard, object oTarget = OBJECT_SELF)
{
    if (BT_DEBUG_LOG_TICKS)
        LogDebug("--- TICK START ---");

    json jTickInfo = BT_TickInfo_Create(oBehaviorTree, oBlackboard, oTarget);
    BT_BehaviorTree_SetCurrentTickInfo(jTickInfo);

    BT_Node_Execute(BT_BehaviorTree_GetRoot(oBehaviorTree), jTickInfo);

    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    json jLastOpenNodes = BT_Blackboard_GetValue(oBlackboard, "OpenNodes", nBehaviorTreeID);
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
        if (JsonGetInt(BT_Blackboard_GetValue(oBlackboard, "IsOpen", nBehaviorTreeID, BT_Node_GetID(jNode))))
            BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_CLOSE);
    }

    BT_Blackboard_SetValue(oBlackboard, "OpenNodes", jCurrentOpenNodes, nBehaviorTreeID);
    BT_Blackboard_SetValue(oBlackboard, "NodeCount", JsonInt(BT_TickInfo_GetNodeCount(jTickInfo)), nBehaviorTreeID);

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
            nRetVal = ExecuteScriptChunkAndReturnInt(BT_Node_GetInclude(jNode, nFunctionType), sFunction, BT_TickInfo_GetTarget(jTickInfo));
        else
            ExecuteScriptChunkAndReturnVoid(BT_Node_GetInclude(jNode, nFunctionType), sFunction, BT_TickInfo_GetTarget(jTickInfo));

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
            BT_Blackboard_SetValue(BT_TickInfo_GetBlackboard(jTickInfo), "IsOpen", JsonInt(TRUE), BT_TickInfo_GetBehaviorTreeID(jTickInfo), BT_Node_GetID(jNode));
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
            BT_Blackboard_SetValue(BT_TickInfo_GetBlackboard(jTickInfo), "IsOpen", JsonInt(FALSE), BT_TickInfo_GetBehaviorTreeID(jTickInfo), BT_Node_GetID(jNode));
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
    BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_ENTER);

    if (!JsonGetInt(BT_Blackboard_GetValue(BT_TickInfo_GetBlackboard(jTickInfo), "IsOpen", BT_TickInfo_GetBehaviorTreeID(jTickInfo), BT_Node_GetID(jNode))))
        BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_OPEN);

    int nNodeState = BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_TICK);

    if (nNodeState == BT_NODE_STATE_ERROR)
        LogWarning(BT_Node_GetDebugInfo(jNode) + ": node returned an error state");

    if (nNodeState != BT_NODE_STATE_RUNNING)
        BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_CLOSE);

    BT_Node_ExecuteFunction(jNode, jTickInfo, BT_NODE_FUNCTION_EXIT);

    return nNodeState;
}

// *** Node Functions *** */

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
    json jData = JsonObjectGet(jNode, BT_NODE_KEY_DATA);
    return JsonObjectGet(jData, sKey);
}

string BT_Node_GetDebugInfo(json jNode)
{
    return BT_Node_GetName(jNode) + "@" + IntToString(BT_Node_GetID(jNode));
}

/* *** Base Node *** */

json BT_Node_BaseNode(int nNodeType, string sTypeName)
{
    json jNode = JsonObject();
    JsonObjectSetIntInplace(jNode, BT_NODE_KEY_ID, BT_GenerateUniqueID());
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

/* *** Sequence Nodes *** */

json BT_Node_Sequence()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "Sequence");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_Sequence_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Sequence_Tick");
    return jNode;
}

void BT_Node_Sequence_Open(json jNode, json jTickInfo)
{
    object oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    int nNodeID = BT_Node_GetID(jNode);
    BT_Blackboard_SetValue(oBlackboard, "RunningChild", JsonInt(0), nBehaviorTreeID, nNodeID);
}

int BT_Node_Sequence_Tick(json jNode, json jTickInfo)
{
    object oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    int nNodeID = BT_Node_GetID(jNode);
    json jChildren = BT_Node_GetChildren(jNode);
    int nCurrentChild = JsonGetInt(BT_Blackboard_GetValue(oBlackboard, "RunningChild", nBehaviorTreeID, nNodeID));
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = nCurrentChild; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = JsonArrayGet(jChildren, nIndex);
        int nNodeState = BT_Node_Execute(jChildNode, jTickInfo);
        if (nNodeState != BT_NODE_STATE_SUCCESS)
        {
            if (nNodeState == BT_NODE_STATE_RUNNING)
                BT_Blackboard_SetValue(oBlackboard, "RunningChild", JsonInt(nIndex), nBehaviorTreeID, nNodeID);
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


json BT_Node_SequenceWithMemory()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "SequenceWithMemory");
    //BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_SequenceWithMemory_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_SequenceWithMemory_Tick");
    return jNode;
}

void BT_Node_SequenceWithMemory_Open(json jNode, json jTickInfo)
{
    object oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    int nNodeID = BT_Node_GetID(jNode);
    BT_Blackboard_SetValue(oBlackboard, "RunningChild", JsonInt(0), nBehaviorTreeID, nNodeID);
}

int BT_Node_SequenceWithMemory_Tick(json jNode, json jTickInfo)
{
    object oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    int nNodeID = BT_Node_GetID(jNode);
    json jChildren = BT_Node_GetChildren(jNode);
    int nCurrentChild = JsonGetInt(BT_Blackboard_GetValue(oBlackboard, "RunningChild", nBehaviorTreeID, nNodeID));
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = nCurrentChild; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = JsonArrayGet(jChildren, nIndex);
        int nNodeState = BT_Node_Execute(jChildNode, jTickInfo);
        if (nNodeState != BT_NODE_STATE_SUCCESS)
        {
            if (nNodeState == BT_NODE_STATE_RUNNING || nNodeState == BT_NODE_STATE_FAILURE)
                BT_Blackboard_SetValue(oBlackboard, "RunningChild", JsonInt(nIndex), nBehaviorTreeID, nNodeID);
            return nNodeState;
        }
    }

    BT_Blackboard_SetValue(oBlackboard, "RunningChild", JsonInt(0), nBehaviorTreeID, nNodeID);

    return BT_NODE_STATE_SUCCESS;
}

/* *** Fallback Nodes *** */

json BT_Node_Fallback()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_COMPOSITE, "Fallback");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_OPEN, BT_SCRIPT_NAME, "BT_Node_Fallback_Open");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Fallback_Tick");
    return jNode;
}

void BT_Node_Fallback_Open(json jNode, json jTickInfo)
{
    object oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    int nNodeID = BT_Node_GetID(jNode);
    BT_Blackboard_SetValue(oBlackboard, "RunningChild", JsonInt(0), nBehaviorTreeID, nNodeID);
}

int BT_Node_Fallback_Tick(json jNode, json jTickInfo)
{
    object oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    int nNodeID = BT_Node_GetID(jNode);
    json jChildren = BT_Node_GetChildren(jNode);
    int nCurrentChild = JsonGetInt(BT_Blackboard_GetValue(oBlackboard, "RunningChild", nBehaviorTreeID, nNodeID));
    int nIndex, nNumChildren = JsonGetLength(jChildren);
    for (nIndex = nCurrentChild; nIndex < nNumChildren; nIndex++)
    {
        json jChildNode = JsonArrayGet(jChildren, nIndex);
        int nNodeState = BT_Node_Execute(jChildNode, jTickInfo);
        if (nNodeState != BT_NODE_STATE_FAILURE)
        {
            if (nNodeState == BT_NODE_STATE_RUNNING)
                BT_Blackboard_SetValue(oBlackboard, "RunningChild", JsonInt(nIndex), nBehaviorTreeID, nNodeID);
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

    int nNodeState = BT_Node_Execute(jNode, jTickInfo);

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

    int nNodeState = BT_Node_Execute(jNode, jTickInfo);

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

    int nNodeState = BT_Node_Execute(jNode, jTickInfo);

    if (nNodeState != BT_NODE_STATE_RUNNING)
        nNodeState = BT_NODE_STATE_FAILURE;

    return nNodeState;
}

json BT_Node_Repeat(int nNumCycles)
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_DECORATOR, "Repeat");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_Repeat_Tick");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_CLOSE, BT_SCRIPT_NAME, "BT_Node_Repeat_Close");
    BT_Node_SetData(jNode, "NumCycles", JsonInt(nNumCycles));
    return jNode;
}

int BT_Node_Repeat_Tick(json jNode, json jTickInfo)
{
    json jChild = BT_Node_GetChildren(jNode);
    if (JsonGetType(jChild) != JSON_TYPE_OBJECT)
        return BT_NODE_STATE_ERROR;

    object oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    int nNodeID = BT_Node_GetID(jNode);
    int nNumCycles = JsonGetInt(BT_Node_GetData(jNode, "NumCycles"));
    int nRepeatCount = JsonGetInt(BT_Blackboard_GetValue(oBlackboard, "RepeatCount", nBehaviorTreeID, nNodeID));
    int bDoLoop = nRepeatCount < nNumCycles || nNumCycles == -1;

    while (bDoLoop)
    {
        int nNodeState = BT_Node_Execute(jChild, jTickInfo);
        switch (nNodeState)
        {
            case BT_NODE_STATE_SUCCESS:
            {
                BT_Blackboard_SetValue(oBlackboard, "RepeatCount", JsonInt(++nRepeatCount), nBehaviorTreeID, nNodeID);
                bDoLoop = nRepeatCount < nNumCycles || nNumCycles == -1;
                break;
            }

            case BT_NODE_STATE_FAILURE:
            case BT_NODE_STATE_RUNNING:
                return nNodeState;
        }
    }
    return BT_NODE_STATE_SUCCESS;
}

void BT_Node_Repeat_Close(json jNode, json jTickInfo)
{
    object oBlackboard = BT_TickInfo_GetBlackboard(jTickInfo);
    int nBehaviorTreeID = BT_TickInfo_GetBehaviorTreeID(jTickInfo);
    int nNodeID = BT_Node_GetID(jNode);
    BT_Blackboard_SetValue(oBlackboard, "RepeatCount", JsonInt(0), nBehaviorTreeID, nNodeID);
}

/* *** Condition Nodes *** */

/* *** Action Nodes *** */

json BT_Node_TestAction()
{
    json jNode = BT_Node_BaseNode(BT_NODE_TYPE_ACTION, "TestAction");
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_TestAction_Tick");
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
    BT_Node_SetFunction(jNode, BT_NODE_FUNCTION_TICK, BT_SCRIPT_NAME, "BT_Node_WeDidIt_Tick");
    return jNode;
}

int BT_Node_WeDidIt_Tick(json jNode, json jTickInfo)
{
    LogInfo("Woo! We did it! :D");
    return BT_NODE_STATE_SUCCESS;
}

/* *** Testing *** */

void BT_RecursiveTick(object oBehaviorTree, object oBlackboard)
{
    //Profiler_Start("BT_BehaviorTree_Tick");
    BT_BehaviorTree_Tick(oBehaviorTree, oBlackboard, GetModule());
    //PrintString(Profiler_Stop());
    DelayCommand(5.0f, BT_RecursiveTick(oBehaviorTree, oBlackboard));
}

// @CORE[CORE_SYSTEM_POST]
void BT_Post()
{
    object oBlackboard = BT_Blackboard_GetOrCreate("TestBT");
    object oBehaviorTree = BT_BehaviorTree_GetOrCreate("TestBT");

    json jSequenceNode1 = BT_Node_Sequence();
    BT_Node_AddChild(jSequenceNode1, BT_Node_SetName(BT_Node_TestAction(), "TestAction A1"));
    BT_Node_AddChild(jSequenceNode1, BT_Node_SetName(BT_Node_TestAction(), "TestAction A2"));
    BT_Node_AddChild(jSequenceNode1, BT_Node_SetName(BT_Node_TestAction(), "TestAction A3"));

    json jFallbackNode = BT_Node_Fallback();
    BT_Node_AddChild(jFallbackNode, jSequenceNode1);
    BT_Node_AddChild(jFallbackNode, BT_Node_SetName(BT_Node_TestAction(), "TestAction B1"));
    BT_Node_AddChild(jFallbackNode, BT_Node_SetName(BT_Node_TestAction(), "TestAction B2"));

    json jSequenceNode2 = BT_Node_Sequence();

    BT_Node_AddChild(jSequenceNode2, jFallbackNode);
    BT_Node_AddChild(jSequenceNode2, BT_Node_SetName(BT_Node_TestAction(), "TestAction C1"));
    BT_Node_AddChild(jSequenceNode2, BT_Node_SetName(BT_Node_TestAction(), "TestAction C2"));
    BT_Node_AddChild(jSequenceNode2, BT_Node_SetName(BT_Node_TestAction(), "TestAction C3"));
    BT_Node_AddChild(jSequenceNode2, BT_Node_WeDidIt());

    BT_BehaviorTree_SetRoot(oBehaviorTree, jSequenceNode2);

    DelayCommand(5.0f, BT_RecursiveTick(oBehaviorTree, oBlackboard));
}
