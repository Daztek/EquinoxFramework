/*
    Script: ef_s_modinit
    Author: Daz
*/

#include "ef_i_core"
#include "nwnx_area"

const string MODINIT_SCRIPT_NAME        = "ef_s_modinit";

// @CORE[EF_SYSTEM_INIT]
void ModInit_Init()
{
    SetTlkOverride(66168, "Login Refused");
    SetTlkOverride(57925, "Character is currently in use by another player.");

    NWNX_Area_SetDefaultObjectUiDiscoveryMask(OBJECT_INVALID, OBJECT_TYPE_ALL, OBJECT_UI_DISCOVERY_HILITE_MOUSEOVER | OBJECT_UI_DISCOVERY_TEXTBUBBLE_MOUSEOVER, TRUE);
}
