/*
    Script: ef_i_gff
    Author: Daz

    Description: Equinox Framework Gff Utility Include
*/

#include "ef_i_json"
#include "nw_inc_gff"

// Create a json local int object
json GffLocalVarInt(string sName, int nValue);
// Create a json local float object
json GffLocalVarFloat(string sName, float fValue);
// Create a json local string object
json GffLocalVarString(string sName, string sValue);
// Add a local variable to a non-area json gff object's vartable
json GffAddLocalVariable(json jGff, json jVariable);
// Add a tile to a tile list
json GffAddTile(json jTileList, int nTileID, int nOrientation, int nHeight);
// Set an area's lighting scheme
json GffSetLightingScheme(json jArea, int nIndex);

json GffLocalVarInt(string sName, int nValue)
{
    json j = JsonObject();
         j = GffAddString(j, "Name", sName);
         j = GffAddDword(j, "Type", 1);
         j = GffAddInt(j, "Value", nValue);
    return j;
}

json GffLocalVarFloat(string sName, float fValue)
{
    json j = JsonObject();
         j = GffAddString(j, "Name", sName);
         j = GffAddDword(j, "Type", 2);
         j = GffAddFloat(j, "Value", fValue);
    return j;
}

json GffLocalVarString(string sName, string sValue)
{
    json j = JsonObject();
         j = GffAddString(j, "Name", sName);
         j = GffAddDword(j, "Type", 3);
         j = GffAddString(j, "Value", sValue);
    return j;
}

json GffAddLocalVariable(json jGff, json jLocalVariable)
{
    if (GffGetFieldExists(jGff, "VarTable", GFF_FIELD_TYPE_LIST))
        jGff = GffReplaceList(jGff, "VarTable", JsonArrayInsert(GffGetList(jGff, "VarTable"), jLocalVariable));
    else
        jGff = GffAddList(jGff, "VarTable", JsonArrayInsert(JsonArray(), jLocalVariable));

    return jGff;
}

json GffAddTile(json jTileList, int nTileID, int nOrientation, int nHeight)
{
    json jTile = JsonObject();
    jTile = GffAddInt(jTile, "Tile_ID", nTileID);
    jTile = GffAddInt(jTile, "Tile_Orientation", nOrientation);
    jTile = GffAddInt(jTile, "Tile_Height", nHeight);
    return JsonArrayInsert(jTileList, jTile);
}

int GetEnvironmentColor(int nIndex, string sColor)
{
    int nRed = StringToInt(Get2DAString("environment", sColor + "RED", nIndex));
    int nGreen = StringToInt(Get2DAString("environment", sColor + "GREEN", nIndex));
    int nBlue = StringToInt(Get2DAString("environment", sColor + "BLUE", nIndex));

    return nRed | ((nGreen << 8) & 0x0000FF00) | ((nBlue << 16) & 0x00FF0000);
}

json GffSetLightingScheme(json jArea, int nIndex)
{
    jArea = GffReplaceDword(jArea, "ARE/value/SunAmbientColor", GetEnvironmentColor(nIndex, "LIGHT_AMB_"));
    jArea = GffReplaceDword(jArea, "ARE/value/SunDiffuseColor", GetEnvironmentColor(nIndex, "LIGHT_DIFF_"));
    jArea = GffReplaceDword(jArea, "ARE/value/SunFogColor", GetEnvironmentColor(nIndex, "LIGHT_FOG_"));
    jArea = GffReplaceByte(jArea, "ARE/value/SunFogAmount", StringToInt(Get2DAString("environment", "LIGHT_FOG", nIndex)));
    jArea = GffReplaceByte(jArea, "ARE/value/SunShadows", StringToInt(Get2DAString("environment", "LIGHT_SHADOWS", nIndex)));

    jArea = GffReplaceDword(jArea, "ARE/value/MoonAmbientColor", GetEnvironmentColor(nIndex, "DARK_AMB_"));
    jArea = GffReplaceDword(jArea, "ARE/value/MoonDiffuseColor", GetEnvironmentColor(nIndex, "DARK_DIFF_"));
    jArea = GffReplaceDword(jArea, "ARE/value/MoonFogColor", GetEnvironmentColor(nIndex, "DARK_FOG_"));
    jArea = GffReplaceByte(jArea, "ARE/value/MoonFogAmount", StringToInt(Get2DAString("environment", "DARK_FOG", nIndex)));
    jArea = GffReplaceByte(jArea, "ARE/value/MoonShadows", StringToInt(Get2DAString("environment", "DARK_SHADOWS", nIndex)));

    jArea = GffReplaceByte(jArea, "ARE/value/ShadowOpacity", FloatToInt(StringToFloat(Get2DAString("environment", "SHADOW_ALPHA", nIndex)) * 100));

    jArea = GffReplaceByte(jArea, "ARE/value/LightingScheme", nIndex);

    return jArea;
}

