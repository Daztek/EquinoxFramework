/*
    Script: ef_s_customip
    Author: Daz

     @SKIPSYSTEM
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_eventman"
#include "ef_s_playerdb"
#include "nwnx_effect"

const string CIP_SCRIPT_NAME                    = "ef_s_customip";
const int CIP_CUSTOM_TYPE                       = 88;

struct CIP_EventData
{
    object oCreature;
    object oItem;
    int bLoading;
    int nInventorySlot;
    int nProperty;
    int nSubType;
    string sTag;
    int nCostTable;
    int nCostTableValue;
    int nParam1;
    int nParam1Value;
};

struct CIP_EventData CIP_GetItemPropertyEventData();

// @CORE[EF_SYSTEM_INIT]
void CIP_Init()
{
    EM_NWNXAddIDToWhitelist("NWNX_ON_ITEMPROPERTY_EFFECT", CIP_CUSTOM_TYPE);
}

// @NWNX[NWNX_ON_ITEMPROPERTY_EFFECT_APPLIED_BEFORE]
void CIP_OnItemPropertyApplied()
{
    struct CIP_EventData str = CIP_GetItemPropertyEventData();
    LogInfo("Applied Property: " + IntToString(str.nProperty) + ", Slot: " + IntToString(str.nInventorySlot));

    if (str.nProperty == CIP_CUSTOM_TYPE)
    {
        if (!str.bLoading)
        {

        }
        else
        {

        }
    }
}

// @NWNX[NWNX_ON_ITEMPROPERTY_EFFECT_REMOVED_BEFORE]
void CIP_OnItemPropertyRemoved()
{
    struct CIP_EventData str = CIP_GetItemPropertyEventData();
    LogInfo("Removed Property: " + IntToString(str.nProperty) + ", Slot: " + IntToString(str.nInventorySlot));

    if (str.nProperty == CIP_CUSTOM_TYPE)
    {

    }
}

// @CONSOLE[ApplyIPRS::]
void IPRS_ApplyIP(int nSubType = 0, int bRemoveAll = 1)
{
    object oItem = GetItemPossessedBy(GetFirstPC(), "TEST_ITEM");

    if (!GetIsObjectValid(oItem))
        return;

    if (bRemoveAll)
    {
        itemproperty ip = GetFirstItemProperty(oItem);
        while (GetIsItemPropertyValid(ip))
        {
            RemoveItemProperty(oItem, ip);
            ip = GetNextItemProperty(oItem);
        }
    }

    itemproperty ip;
    switch (nSubType)
    {
        case 0: ip = ItemPropertyCustom(CIP_CUSTOM_TYPE); break;
    }

    AddItemProperty(DURATION_TYPE_PERMANENT, ip, oItem);
}

struct CIP_EventData CIP_GetItemPropertyEventData()
{
    struct CIP_EventData str;
    str.oCreature = EM_NWNXGetObject("CREATURE");
    str.oItem = OBJECT_SELF;
    str.bLoading = EM_NWNXGetInt("LOADING_GAME");
    str.nInventorySlot = EM_NWNXGetInt("INVENTORY_SLOT");
    str.nProperty = EM_NWNXGetInt("PROPERTY");
    str.nSubType = EM_NWNXGetInt("SUBTYPE");
    str.sTag = EM_NWNXGetString("TAG");
    str.nCostTable = EM_NWNXGetInt("COST_TABLE");
    str.nCostTableValue = EM_NWNXGetInt("COST_TABLE_VALUE");
    str.nParam1 = EM_NWNXGetInt("PARAM1");
    str.nParam1Value = EM_NWNXGetInt("PARAM1_VALUE");
    return str;
}
