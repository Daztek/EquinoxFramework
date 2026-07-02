/*
    Script: ef_s_npcgen
    Author: Daz
*/

#include "ef_i_gff"
#include "ef_s_eventman"
#include "nwnx_nwsqliteext"

const string NPCGEN_SCRIPT_NAME             = "ef_s_ambientnpc";
const string NPCGEN_NPC_TEMPLATE            = "NPCGenTemplate";
const string NPCGEN_DEFAULT_TAG             = "GENERATED_NPC";

void NPCGen_SetupTemplateNPC();
json NPCGen_GetTemplateNPC();

// @CORE[CORE_SYSTEM_INIT]
void NPCGen_Init()
{
    NPCGen_SetupTemplateNPC();
    NWNX_NWSQLiteExtensions_CreateVirtual2DATable("soundset", "00111");
}

void NPCGen_SetupTemplateNPC()
{
    object oNPC = CreateObject(OBJECT_TYPE_CREATURE, "nw_beggmale", GetStartingLocation(), FALSE, NPCGEN_DEFAULT_TAG);
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

    EM_ClearObjectEventScripts(oNPC);

    json jNPC = ObjectToJson(oNPC, FALSE);
        jNPC = GffReplaceWord(jNPC, "SoundSetFile", 0);
        jNPC = GffRemoveDword(jNPC, "AreaId");
        jNPC = GffRemoveString(jNPC, "NWNX_POS");
        jNPC = GffReplaceLocString(jNPC, "FirstName", "Template");
        jNPC = GffReplaceLocString(jNPC, "LastName", "NPC");

    SetLocalJson(GetDataObject(NPCGEN_SCRIPT_NAME), NPCGEN_NPC_TEMPLATE, jNPC);

    DestroyObject(oNPC);

    //PrintString(JsonDump(jNPC));
}

json NPCGen_GetTemplateNPC()
{
    return GetLocalJson(GetDataObject(NPCGEN_SCRIPT_NAME), NPCGEN_NPC_TEMPLATE);
}
