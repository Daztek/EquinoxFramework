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

