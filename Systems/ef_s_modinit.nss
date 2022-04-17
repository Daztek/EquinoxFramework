/*
    Script: ef_s_modinit
    Author: Daz
*/

//void main() {}

#include "ef_i_core"
#include "nwnx_feedback"

const string MODINIT_LOG_TAG            = "ModuleInit";
const string MODINIT_SCRIPT_NAME        = "ef_s_modinit";

// @CORE[EF_SYSTEM_INIT]
void ModInit_Init()
{
    // Alignment TLK Overrides
    SetTlkOverride(111, "Select a starting Element for your character.");
    SetTlkOverride(112, "Fire");            // Lawful Good
    SetTlkOverride(113, "???");             // Lawful Neutral
    SetTlkOverride(114, "???");             // Lawful Evil
    SetTlkOverride(115, "Cold");            // Neutral Good
    SetTlkOverride(116, "???");             // Neutral Neutral
    SetTlkOverride(117, "???");             // Neutral Evil
    SetTlkOverride(118, "Acid");            // Chaotic Good
    SetTlkOverride(119, "???");             // Chaotic Neutral
    SetTlkOverride(120, "???");             // Chaotic Evil

    SetTlkOverride(452, "You may enhance your attacks with Fire.");     // Lawful Good Description
    SetTlkOverride(453, "???");                                         // Lawful Neutral Description
    SetTlkOverride(451, "???");                                         // Lawful Evil Description
    SetTlkOverride(455, "You may enhance your attacks with Cold.");     // Neutral Good Description
    SetTlkOverride(456, "???");                                         // Neutral Neutral Description
    SetTlkOverride(454, "???");                                         // Neutral Evil Description
    SetTlkOverride(449, "You may enhance your attacks with Acid.");     // Chaotic Good Description
    SetTlkOverride(450, "???");                                         // Chaotic Neutral Description
    SetTlkOverride(448, "???");                                         // Chaotic Evil Description

    SetTlkOverride(468, "Fire Attacks");                                // Lawful Good Long Name
    SetTlkOverride(469, "???");                                         // Lawful Neutral Long Name
    SetTlkOverride(467, "???");                                         // Lawful Evil Long Name
    SetTlkOverride(471, "Cold Attacks");                                // Neutral Good Long Name
    SetTlkOverride(472, "???");                                         // Neutral Neutral Long Name
    SetTlkOverride(470, "???");                                         // Neutral Evil Long Name
    SetTlkOverride(465, "Acid Attacks");                                // Chaotic Good Long Name
    SetTlkOverride(466, "???");                                         // Chaotic Neutral Long Name
    SetTlkOverride(464, "???");                                         // Chaotic Evil Long Name

    // Misc Character Gen TLK Overrides
    SetTlkOverride(447, "The choice of making your character Male or Female is purely an aesthetic one, as both are equally capable.");
    SetTlkOverride(484, "Alas, you only have one choice, go forth Adventurer.");
    SetTlkOverride(159, "DO NOT USE");
    SetTlkOverride(487, "Please select the Default Adventurer package, otherwise you won't be able to proceed.");

    // Disable Combat Feedback
    NWNX_Feedback_SetCombatLogMessageMode(TRUE);
    NWNX_Feedback_SetCombatLogMessageHidden(NWNX_FEEDBACK_COMBATLOG_COMPLEX_DAMAGE, TRUE);
    NWNX_Feedback_SetCombatLogMessageHidden(NWNX_FEEDBACK_COMBATLOG_FEEDBACK, TRUE);
    NWNX_Feedback_SetCombatLogMessageHidden(NWNX_FEEDBACK_COMBATLOG_POSTAURSTRING, TRUE);
    NWNX_Feedback_SetCombatLogMessageHidden(NWNX_FEEDBACK_COMBATLOG_ENTERTARGETINGMODE, TRUE);
}

