/*
    Script: ef_s_ambientnpc
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"

const string AMNPC_SCRIPT_NAME              = "ef_s_ambientnpc";

const string AMNPC_NPC_TEMPLATE             = "AmNPCTemplate";
const string AMNPC_DEFAULT_TAG              = "AMBIENT_NPC";

void AmNPC_SetupTemplateNPC();
json AmNPC_GetTemplateNPC();

// @CORE[CORE_SYSTEM_INIT]
void AmNPC_Init()
{
    AmNPC_SetupTemplateNPC();
}

void AmNPC_SetupTemplateNPC()
{
    object oNPC = CreateObject(OBJECT_TYPE_CREATURE, "nw_beggmale", GetStartingLocation(), FALSE, AMNPC_DEFAULT_TAG);
    SetCreatureAppearanceType(oNPC, APPEARANCE_TYPE_HUMAN);
    int nIndex;
    for (nIndex = CREATURE_PART_RIGHT_FOOT; nIndex <= CREATURE_PART_LEFT_HAND; nIndex++)
    {
        if (nIndex == CREATURE_PART_BELT ||
            nIndex == CREATURE_PART_RIGHT_SHOULDER ||
            nIndex == CREATURE_PART_LEFT_SHOULDER)
            continue;

        SetCreatureBodyPart(nIndex, CREATURE_MODEL_TYPE_SKIN, oNPC);
    }

    json jNPC = ObjectToJson(oNPC, FALSE);
        jNPC = GffRemoveDword(jNPC, "AreaId");
        jNPC = GffRemoveString(jNPC, "NWNX_POS");
        jNPC = GffReplaceLocString(jNPC, "FirstName", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptAttacked", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptDamaged", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptDeath", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptDialogue", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptDisturbed", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptEndRound", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptHeartbeat", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptOnBlocked", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptOnNotice", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptRested", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptSpawn", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptSpellAt", "");
        jNPC = GffReplaceResRef(jNPC, "ScriptUserDefine", "");

    SetLocalJson(GetDataObject(AMNPC_SCRIPT_NAME), AMNPC_NPC_TEMPLATE, jNPC);

    DestroyObject(oNPC);

    //PrintString(JsonDump(jNPC));
}

json AmNPC_GetTemplateNPC()
{
    return GetLocalJson(GetDataObject(AMNPC_SCRIPT_NAME), AMNPC_NPC_TEMPLATE);
}
