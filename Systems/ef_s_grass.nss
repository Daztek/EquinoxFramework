/*
    Script: ef_s_grass
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_endlesspath"

const string GRASS_SCRIPT_NAME     = "ef_s_grass";
const string GRASS_DEFAULT_TEXTURE = "trm02_grass3d";

void Grass_SetGrass(object oArea, string sTexture);

// @CORE[EF_SYSTEM_INIT]
void Grass_Init()
{
    int nSeed = 100;
    LogInfo("Seed: " + IntToString(nSeed));
    SqlMersenneTwisterSetSeed(GRASS_SCRIPT_NAME, nSeed);
}

// @NWNX[EP_EVENT_AREA_POST_PROCESS_FINISHED]
void Grass_OnAreaPostProcessed()
{
    Grass_SetGrass(OBJECT_SELF, GRASS_DEFAULT_TEXTURE);
}

void Grass_SetGrass(object oArea, string sTexture)
{
    float fDensity = 1.0f + ((SqlMersenneTwisterGetValue(GRASS_SCRIPT_NAME, 240) + 1) / 10.0f);
    float fHeight = 0.1f + ((SqlMersenneTwisterGetValue(GRASS_SCRIPT_NAME, 25) + 1) / 10.0f);
    vector vColor = Vector(1.0f, 1.0f, 1.0f);

    LogInfo("Setting Grass for Area: " + GetTag(oArea) + " - > Texture: " + sTexture + ", Density: " + FloatToString(fDensity, 0, 2) + ", Height: " + FloatToString(fHeight, 0, 2));
    SetAreaGrassOverride(oArea, 3, sTexture, fDensity, fHeight, vColor, vColor);
}

// @CONSOLE[SetGrass::]
void Grass_ConsoleSetGrass(int nType = 0)
{
    Grass_SetGrass(GetArea(OBJECT_SELF), nType ? "ttw01_grass01" : GRASS_DEFAULT_TEXTURE);
}
