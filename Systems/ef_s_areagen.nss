/*
    Script: ef_s_areagen
    Author: Daz

    Currently optimized for TILESET_RESREF_MEDIEVAL_RURAL_2
*/

#include "ef_i_core"
#include "ef_s_tileset"
#include "ef_s_gfftools"
#include "ef_s_profiler"
#include "nwnx_area"

const string AG_SCRIPT_NAME                                     = "ef_s_areagen";
const string AG_GENERATOR_DATAOBJECT                            = "AGDataObject";

const int AG_GENERATION_DEFAULT_MAX_ITERATIONS                  = 100;
const float AG_GENERATION_DELAY                                 = 0.15f;
const int AG_GENERATION_TILE_FAILURE_RESET_CHANCE               = 100;
const int AG_GENERATION_TILE_NEIGHBOR_RESET_CHANCE              = 100;
const int AG_DEFAULT_EDGE_TERRAIN_CHANGE_CHANCE                 = 25;

const int AG_INVALID_TILE_ID                                    = -1;

const int AG_AREA_MIN_WIDTH                                     = 1;
const int AG_AREA_MIN_HEIGHT                                    = 1;
const int AG_AREA_MAX_WIDTH                                     = 32;
const int AG_AREA_MAX_HEIGHT                                    = 32;
const int AG_AREA_DEFAULT_WIDTH                                 = 8;
const int AG_AREA_DEFAULT_HEIGHT                                = 8;

const string AG_DATA_KEY_AREA_ID                                = "AreaID";
const string AG_DATA_KEY_JSON_DATA                              = "JsonData";
const string AG_DATA_KEY_TILESET                                = "Tileset";
const string AG_DATA_KEY_MAX_ITERATIONS                         = "MaxIterations";
const string AG_DATA_KEY_EDGE_TERRAIN                           = "EdgeTerrain";
const string AG_DATA_KEY_FLOOR_TERRAIN                          = "FloorTerrain";
const string AG_DATA_KEY_WIDTH                                  = "Width";
const string AG_DATA_KEY_HEIGHT                                 = "Height";
const string AG_DATA_KEY_NUM_TILES                              = "NumTiles";
const string AG_DATA_KEY_ARRAY_TILES                            = "ArrayTiles";
const string AG_DATA_KEY_ARRAY_EDGE_TOP                         = "ArrayEdgeTop";
const string AG_DATA_KEY_ARRAY_EDGE_BOTTOM                      = "ArrayEdgeBottom";
const string AG_DATA_KEY_ARRAY_EDGE_LEFT                        = "ArrayEdgeLeft";
const string AG_DATA_KEY_ARRAY_EDGE_RIGHT                       = "ArrayEdgeRight";
const string AG_DATA_KEY_IGNORE_TOC                             = "IgnoreTOC";
const string AG_DATA_KEY_TILE_OVERRIDE                          = "TileOverride_";
const string AG_DATA_KEY_GENERATION_ITERATIONS                  = "GenerationIterations";
const string AG_DATA_KEY_GENERATION_FINISHED                    = "GenerationFinished";
const string AG_DATA_KEY_GENERATION_FAILED                      = "GenerationFailed";
const string AG_DATA_KEY_GENERATION_CALLBACK                    = "GenerationCallback";
const string AG_DATA_KEY_GENERATION_LOG_STATUS                  = "GenerationLogStatus";
const string AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE    = "GenerationSingleGroupTileChance";
const string AG_DATA_KEY_GENERATION_HEIGHT_FIRST_CHANCE         = "GenerationHeightFirstChance";

const string AG_DATA_KEY_TILE_ID                                = "TileID";
const string AG_DATA_KEY_TILE_LOCKED                            = "Locked";
const string AG_DATA_KEY_TILE_ORIENTATION                       = "Orientation";
const string AG_DATA_KEY_TILE_HEIGHT                            = "Height";

const string AG_DATA_KEY_ENTRANCE_TILE_INDEX                    = "EntranceTileIndex";
const string AG_DATA_KEY_EXIT_TILE_INDEX                        = "ExitTileIndex";
const string AG_DATA_KEY_PATH_NODES                             = "PathNodes";
const string AG_DATA_KEY_PATH_NO_ROAD_CHANCE                    = "PathNoRoadChance";
const string AG_DATA_KEY_PATH_NO_ROAD                           = "PathNoRoad";
const string AG_DATA_KEY_ARRAY_EDGE_TERRAINS                    = "ArrayEdgeTerrains";
const string AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE             = "EdgeTerrainChangeChance";
const string AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS               = "ArrayExitEdgeTerrains";
const string AG_DATA_KEY_AREA_PATH_DOOR_CROSSER_COMBO           = "AreaPathDoorCrosserCombo";
const string AG_DATA_KEY_NUM_PATH_DOOR_CROSSER_COMBOS           = "PathDoorCrosserCombos";
const string AG_DATA_KEY_PATH_DOOR_ID                           = "PathDoorId_";
const string AG_DATA_KEY_PATH_CROSSER_TYPE                      = "PathCrosserType_";

const string AG_FAILED_TILES_ARRAY                              = "FailedTilesArray";
const string AG_IGNORE_TOC_ARRAY                                = "IgnoreTOCArray";

const int AG_NEIGHBOR_TILE_TOP_LEFT                             = 0;
const int AG_NEIGHBOR_TILE_TOP                                  = 1;
const int AG_NEIGHBOR_TILE_TOP_RIGHT                            = 2;
const int AG_NEIGHBOR_TILE_RIGHT                                = 3;
const int AG_NEIGHBOR_TILE_BOTTOM_RIGHT                         = 4;
const int AG_NEIGHBOR_TILE_BOTTOM                               = 5;
const int AG_NEIGHBOR_TILE_BOTTOM_LEFT                          = 6;
const int AG_NEIGHBOR_TILE_LEFT                                 = 7;
const int AG_NEIGHBOR_TILE_MAX                                  = 8;

const int AG_AREA_EDGE_TOP                                      = 0;
const int AG_AREA_EDGE_RIGHT                                    = 1;
const int AG_AREA_EDGE_BOTTOM                                   = 2;
const int AG_AREA_EDGE_LEFT                                     = 3;

struct AG_Tile
{
    int nTileID;
    int nOrientation;
    int nHeight;
};

struct AG_EdgeTileOverride
{
    string sTC1;
    string sTC2;
    string sTC3;
};

struct AG_TilePosition
{
    int nX;
    int nY;
};

object AG_GetAreaDataObject(string sAreaID);
void AG_SetJsonData(string sAreaID, json jData);
json AG_GetJsonData(string sAreaID);
void AG_SetJsonDataByKey(string sAreaID, string sKey, json jValue);
json AG_GetJsonDataByKey(string sAreaID, string sKey);
void AG_SetStringDataByKey(string sAreaID, string sKey, string sValue);
string AG_GetStringDataByKey(string sAreaID, string sKey);
void AG_SetIntDataByKey(string sAreaID, string sKey, int nValue);
int AG_GetIntDataByKey(string sAreaID, string sKey);
void AG_SetCallbackFunction(string sAreaID, string sSystem, string sFunction);
string AG_GetCallbackFunction(string sAreaID);
int AG_GetIgnoreTerrainOrCrosser(string sAreaID, string sTOC);
void AG_SetIgnoreTerrainOrCrosser(string sAreaID, string sTOC, int bIgnore = TRUE);
void AG_Tile_SetID(string sAreaID, string sTileArray, int nTile, int nTileID);
int AG_Tile_GetID(string sAreaID, string sTileArray, int nTile);
void AG_Tile_SetLocked(string sAreaID, string sTileArray, int nTile, int bLocked);
int AG_Tile_GetLocked(string sAreaID, string sTileArray, int nTile);
void AG_Tile_SetOrientation(string sAreaID, string sTileArray, int nTile, int nOrientation);
int AG_Tile_GetOrientation(string sAreaID, string sTileArray, int nTile);
void AG_Tile_SetHeight(string sAreaID, string sTileArray, int nTile, int nHeight);
int AG_Tile_GetHeight(string sAreaID, string sTileArray, int nTile);
void AG_Tile_Set(string sAreaID, string sTileArray, int nTile, int nID, int nOrientation, int nHeight = 0, int bLocked = FALSE);
void AG_Tile_Reset(string sAreaID, string sTileArray, int nTile);
void AG_SetEdgeTileOverride(string sAreaID, string sEdge, int nTile, string sTC1, string sTC2, string sTC3);
int AG_GetHasEdgeTileOverride(string sAreaID, string sEdge, int nTile);
struct AG_EdgeTileOverride AG_GetEdgeTileOverride(string sAreaID, string sEdge, int nTile);
int AG_GetHasTileOverride(string sAreaID, int nTile);
void AG_SetTileOverride(string sAreaID, int nTile, struct TS_TileStruct strTile);
struct TS_TileStruct AG_GetTileOverride(string sAreaID, int nTile);
void AG_InitializeTileArrays(string sAreaID, int nWidth, int nHeight);
void AG_InitializeRandomArea(string sAreaID, string sTileset, string sEdgeTerrain = "", int nWidth = AG_AREA_DEFAULT_WIDTH, int nHeight = AG_AREA_DEFAULT_HEIGHT);
int AG_GetNeighborTile(string sAreaID, int nTile, int nDirection);
void AG_ResetNeighborTiles(string sAreaID, int nTile);
struct TS_TileStruct AG_GetNeighborTileStruct(string sAreaID, int nTile, int nDirection);
string AG_ResolveCorner(string sCorner1, string sCorner2);
string AG_SqlConstructCAEClause(struct TS_TileStruct str);
struct AG_Tile AG_GetRandomMatchingTile(string sAreaID, int nTile, int bSingleGroupTile, int bHeightFirst);
void AG_ProcessTile(string sAreaID, int nWidth, int nX, int nY);
int AG_GenerateRandom(string sAreaID);
void AG_GenerateArea(string sAreaID);
int AG_GetEdgeFromTile(string sAreaID, int nTile);
int AG_GetRandomOtherEdge(int nEdgeToSkip);
int AG_GetTileOrientationFromEdge(string sAreaID, int nEdge, int nTileID);
void AG_CreatePathEntranceDoorTile(string sAreaID, int nTile);
void AG_CreatePathExitDoorTile(string sAreaID);
void AG_CopyEdgeFromArea(string sAreaID, object oArea, int nEdgeToCopy);
int AG_GetNextTile(int nAreaWidth, int nTile, int nEdge);
struct TS_TileStruct AG_GetRoadTileStruct(string sAreaID, int nPoint, int nNumPoints, int nX1, int nY1, int nX2, int nY2, int bNoRoad);
struct AG_Tile AG_GetRandomRoadTile(string sAreaID, struct TS_TileStruct strQuery);
void AG_PlotRoad(string sAreaID);
void AG_AddEdgeTerrain(string sAreaID, string sTerrain);
void AG_GenerateEdge(string sAreaID, int nEdge);
int AG_GetNumPathDoorCrosserCombos(string sAreaID);
void AG_AddPathDoorCrosserCombo(string sAreaID, int nDoorTile, string sCrosser);
int AG_GetPathDoorID(string sAreaID, int nNum);
string AG_GetPathCrosserType(string sAreaID, int nNum);
int AG_GetIsPathDoor(string sAreaID, int nTileID);
void AG_SetAreaPathDoorCrosserCombo(string sAreaID, int nNum);
int AG_GetAreaPathDoor(string sAreaID);
string AG_GetAreaPathCrosserType(string sAreaID);
struct AG_TilePosition AG_GetTilePosition(string sAreaID, int nTile);
void AG_CreateRandomEntrance(string sAreaID, int nEntranceTileID);
json AG_GetTileList(string sAreaID);
object AG_CreateDoor(string sAreaID, int nTileIndex, string sTag, int nDoorIndex = 0);

object AG_GetAreaDataObject(string sAreaID)
{
    return GetDataObject(AG_GENERATOR_DATAOBJECT + sAreaID);
}

void AG_SetJsonData(string sAreaID, json jData)
{
    SetLocalJson(AG_GetAreaDataObject(sAreaID), AG_DATA_KEY_JSON_DATA, jData);
}

json AG_GetJsonData(string sAreaID)
{
    return GetLocalJsonOrDefault(AG_GetAreaDataObject(sAreaID), AG_DATA_KEY_JSON_DATA, JsonObject());
}

void AG_SetJsonDataByKey(string sAreaID, string sKey, json jValue)
{
    AG_SetJsonData(sAreaID, JsonObjectSet(AG_GetJsonData(sAreaID), sKey, jValue));
}

json AG_GetJsonDataByKey(string sAreaID, string sKey)
{
    return JsonObjectGet(AG_GetJsonData(sAreaID), sKey);
}

void AG_SetStringDataByKey(string sAreaID, string sKey, string sValue)
{
    SetLocalString(AG_GetAreaDataObject(sAreaID), sKey, sValue);
}

string AG_GetStringDataByKey(string sAreaID, string sKey)
{
    return GetLocalString(AG_GetAreaDataObject(sAreaID), sKey);
}

void AG_SetIntDataByKey(string sAreaID, string sKey, int nValue)
{
    SetLocalInt(AG_GetAreaDataObject(sAreaID), sKey, nValue);
}

int AG_GetIntDataByKey(string sAreaID, string sKey)
{
    return GetLocalInt(AG_GetAreaDataObject(sAreaID), sKey);
}

void AG_SetCallbackFunction(string sAreaID, string sSystem, string sFunction)
{
    string sScriptChunk = nssInclude(sSystem) + nssVoidMain(nssFunction(sFunction, nssEscape(sAreaID)));
    AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_GENERATION_CALLBACK, sScriptChunk);
}

string AG_GetCallbackFunction(string sAreaID)
{
    return AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_GENERATION_CALLBACK);
}

int AG_GetIgnoreTerrainOrCrosser(string sAreaID, string sTOC)
{
    return JsonGetType(JsonFind(AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC), JsonString(sTOC)));
}

void AG_SetIgnoreTerrainOrCrosser(string sAreaID, string sTOC, int bIgnore = TRUE)
{
    if (bIgnore)
    {
        if (!AG_GetIgnoreTerrainOrCrosser(sAreaID, sTOC))
        {
            AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC, JsonArrayInsertString(AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC), sTOC));
        }
    }
    else
    {
        json jArray = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC);
        json jFind = JsonFind(jArray, JsonString(sTOC));

        if (JsonGetType(jFind) == JSON_TYPE_INTEGER)
        {
            jArray = JsonArrayDel(jArray, JsonGetInt(jFind));
            AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC, jArray);
        }
    }
}

void AG_Tile_SetID(string sAreaID, string sTileArray, int nTile, int nTileID)
{
    AG_SetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_ID + IntToString(nTile), nTileID);
}

int AG_Tile_GetID(string sAreaID, string sTileArray, int nTile)
{
    return AG_GetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_ID + IntToString(nTile));
}

void AG_Tile_SetLocked(string sAreaID, string sTileArray, int nTile, int bLocked)
{
    AG_SetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_LOCKED + IntToString(nTile), bLocked);
}

int AG_Tile_GetLocked(string sAreaID, string sTileArray, int nTile)
{
    return AG_GetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_LOCKED + IntToString(nTile));
}

void AG_Tile_SetOrientation(string sAreaID, string sTileArray, int nTile, int nOrientation)
{
    AG_SetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_ORIENTATION + IntToString(nTile), nOrientation);
}

int AG_Tile_GetOrientation(string sAreaID, string sTileArray, int nTile)
{
    return AG_GetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_ORIENTATION + IntToString(nTile));
}

void AG_Tile_SetHeight(string sAreaID, string sTileArray, int nTile, int nHeight)
{
    AG_SetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_HEIGHT + IntToString(nTile), nHeight);
}

int AG_Tile_GetHeight(string sAreaID, string sTileArray, int nTile)
{
    return AG_GetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_HEIGHT + IntToString(nTile));
}

void AG_Tile_Set(string sAreaID, string sTileArray, int nTile, int nID, int nOrientation, int nHeight = 0, int bLocked = FALSE)
{
    AG_Tile_SetID(sAreaID, sTileArray, nTile, nID);
    AG_Tile_SetOrientation(sAreaID, sTileArray, nTile, nOrientation);
    AG_Tile_SetHeight(sAreaID, sTileArray, nTile, nHeight);
    AG_Tile_SetLocked(sAreaID, sTileArray, nTile, bLocked);
}

void AG_Tile_Reset(string sAreaID, string sTileArray, int nTile)
{
    AG_Tile_SetID(sAreaID, sTileArray, nTile, AG_INVALID_TILE_ID);
    AG_Tile_SetLocked(sAreaID, sTileArray, nTile, FALSE);
    AG_Tile_SetOrientation(sAreaID, sTileArray, nTile, 0);
    AG_Tile_SetHeight(sAreaID, sTileArray, nTile, 0);
}

void AG_SetEdgeTileOverride(string sAreaID, string sEdge, int nTile, string sTC1, string sTC2, string sTC3)
{
    string sKey = sEdge + "_" + IntToString(nTile);
    AG_SetIntDataByKey(sAreaID, sKey, TRUE);
    AG_SetStringDataByKey(sAreaID, sKey + "_TC_1", sTC1);
    AG_SetStringDataByKey(sAreaID, sKey + "_TC_2", sTC2);
    AG_SetStringDataByKey(sAreaID, sKey + "_TC_3", sTC3);
}

int AG_GetHasEdgeTileOverride(string sAreaID, string sEdge, int nTile)
{
    return AG_GetIntDataByKey(sAreaID, sEdge + "_" + IntToString(nTile));
}

struct AG_EdgeTileOverride AG_GetEdgeTileOverride(string sAreaID, string sEdge, int nTile)
{
    struct AG_EdgeTileOverride str;
    string sKey = sEdge + "_" + IntToString(nTile);
    str.sTC1 = AG_GetStringDataByKey(sAreaID, sKey + "_TC_1");
    str.sTC2 = AG_GetStringDataByKey(sAreaID, sKey + "_TC_2");
    str.sTC3 = AG_GetStringDataByKey(sAreaID, sKey + "_TC_3");
    return str;
}

int AG_GetHasTileOverride(string sAreaID, int nTile)
{
    return AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_TILE_OVERRIDE + IntToString(nTile));
}

void AG_SetTileOverride(string sAreaID, int nTile, struct TS_TileStruct strTile)
{
    string sKey = AG_DATA_KEY_TILE_OVERRIDE + IntToString(nTile);
    AG_SetIntDataByKey(sAreaID, sKey, TRUE);

    AG_SetStringDataByKey(sAreaID, sKey + "TL", strTile.sTL);
    AG_SetStringDataByKey(sAreaID, sKey + "TR", strTile.sTR);
    AG_SetStringDataByKey(sAreaID, sKey + "BL", strTile.sBL);
    AG_SetStringDataByKey(sAreaID, sKey + "BR", strTile.sBR);

    AG_SetStringDataByKey(sAreaID, sKey + "T", strTile.sT);
    AG_SetStringDataByKey(sAreaID, sKey + "B", strTile.sB);
    AG_SetStringDataByKey(sAreaID, sKey + "L", strTile.sL);
    AG_SetStringDataByKey(sAreaID, sKey + "R", strTile.sR);
}

struct TS_TileStruct AG_GetTileOverride(string sAreaID, int nTile)
{
    struct TS_TileStruct str;
    string sKey = AG_DATA_KEY_TILE_OVERRIDE + IntToString(nTile);

    str.sTL = AG_GetStringDataByKey(sAreaID, sKey + "TL");
    str.sTR = AG_GetStringDataByKey(sAreaID, sKey + "TR");
    str.sBL = AG_GetStringDataByKey(sAreaID, sKey + "BL");
    str.sBR = AG_GetStringDataByKey(sAreaID, sKey + "BR");

    str.sT = AG_GetStringDataByKey(sAreaID, sKey + "T");
    str.sB = AG_GetStringDataByKey(sAreaID, sKey + "B");
    str.sL = AG_GetStringDataByKey(sAreaID, sKey + "L");
    str.sR = AG_GetStringDataByKey(sAreaID, sKey + "R");

    return str;
}

void AG_InitializeTileArrays(string sAreaID, int nWidth, int nHeight)
{
    int nTile, nNumTiles = nWidth * nHeight;

    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
    }

    for (nTile = 0; nTile < nWidth; nTile++)
    {
        AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, nTile);
        AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, nTile);
    }

    for (nTile = 0; nTile < nHeight; nTile++)
    {
        AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, nTile);
        AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, nTile);
    }
}

void AG_InitializeRandomArea(string sAreaID, string sTileset, string sEdgeTerrain = "", int nWidth = AG_AREA_DEFAULT_WIDTH, int nHeight = AG_AREA_DEFAULT_HEIGHT)
{
    DestroyDataObject(AG_GENERATOR_DATAOBJECT + sAreaID);

    nWidth = nWidth > AG_AREA_MAX_WIDTH ? AG_AREA_MAX_WIDTH :
             nWidth < AG_AREA_MIN_WIDTH ? AG_AREA_MIN_WIDTH : nWidth;
    nHeight = nHeight > AG_AREA_MAX_HEIGHT ? AG_AREA_MAX_HEIGHT :
              nHeight < AG_AREA_MIN_HEIGHT ? AG_AREA_MIN_HEIGHT : nHeight;

    AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_AREA_ID, sAreaID);
    AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET, sTileset);
    AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN, sEdgeTerrain);
    AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_FLOOR_TERRAIN, TS_GetTilesetDefaultFloorTerrain(sTileset));
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_MAX_ITERATIONS, AG_GENERATION_DEFAULT_MAX_ITERATIONS);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH, nWidth);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT, nHeight);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES, nWidth * nHeight);
    AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC, JsonArray());
    AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TERRAINS, JsonArrayInsertString(JsonArray(), sEdgeTerrain));
    AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS, JsonArray());
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE, AG_DEFAULT_EDGE_TERRAIN_CHANGE_CHANCE);

    AG_InitializeTileArrays(sAreaID, nWidth, nHeight);
}

int AG_GetNeighborTile(string sAreaID, int nTile, int nDirection)
{
    int nAreaWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nAreaHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    int nTileX = nTile % nAreaWidth;
    int nTileY = nTile / nAreaWidth;

    switch (nDirection)
    {
        case AG_NEIGHBOR_TILE_TOP_LEFT:
        {
            if (nTileY == (nAreaHeight - 1) || nTileX == 0)
                return AG_INVALID_TILE_ID;
            else
                nTile += (nAreaWidth - 1);
            break;
        }

        case AG_NEIGHBOR_TILE_TOP:
        {
            if (nTileY == (nAreaHeight - 1))
                return AG_INVALID_TILE_ID;
            else
                nTile += nAreaWidth;
            break;
        }

        case AG_NEIGHBOR_TILE_TOP_RIGHT:
        {
            if (nTileY == (nAreaHeight - 1) || nTileX == (nAreaWidth - 1))
                return AG_INVALID_TILE_ID;
            else
                nTile += (nAreaWidth + 1);
            break;
        }

        case AG_NEIGHBOR_TILE_RIGHT:
        {
            if (nTileX == (nAreaWidth - 1))
                return AG_INVALID_TILE_ID;
            else
                nTile += 1;
            break;
        }

        case AG_NEIGHBOR_TILE_BOTTOM_RIGHT:
        {
            if (nTileY == 0 || nTileX == (nAreaWidth - 1))
                return AG_INVALID_TILE_ID;
            else
                nTile -= (nAreaWidth - 1);
            break;
        }

        case AG_NEIGHBOR_TILE_BOTTOM:
        {
            if (nTileY == 0)
                return AG_INVALID_TILE_ID;
            else
                nTile -= nAreaWidth;
            break;
        }

        case AG_NEIGHBOR_TILE_BOTTOM_LEFT:
        {
            if (nTileY == 0 || nTileX == 0)
                return AG_INVALID_TILE_ID;
            else
                nTile -= (nAreaWidth + 1);
            break;
        }

        case AG_NEIGHBOR_TILE_LEFT:
        {
            if (nTileX == 0)
                return AG_INVALID_TILE_ID;
            else
                nTile -= 1;
            break;
        }
    }

    return nTile;
}

void AG_ResetNeighborTiles(string sAreaID, int nTile)
{
    int nDirection;
    for (nDirection = 0; nDirection < AG_NEIGHBOR_TILE_MAX; nDirection++)
    {
        int nNeighborTile = AG_GetNeighborTile(sAreaID, nTile, nDirection);
        if (nNeighborTile != AG_INVALID_TILE_ID)
        {
            if (!AG_Tile_GetLocked(sAreaID, AG_DATA_KEY_ARRAY_TILES, nNeighborTile))
            {
                if (AG_GENERATION_TILE_NEIGHBOR_RESET_CHANCE == 100 || Random(100) < AG_GENERATION_TILE_NEIGHBOR_RESET_CHANCE)
                    AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_TILES, nNeighborTile);
            }
        }
    }
}

struct TS_TileStruct AG_GetNeighborTileStruct(string sAreaID, int nTile, int nDirection)
{
    struct TS_TileStruct str;
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);
    int nNeighborTile = AG_GetNeighborTile(sAreaID, nTile, nDirection);

    if (nNeighborTile != AG_INVALID_TILE_ID)
    {
        int nTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nNeighborTile);
        int nOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_TILES, nNeighborTile);
        int nHeight = AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_TILES, nNeighborTile);

        if (nTileID != AG_INVALID_TILE_ID)
            str = TS_GetCornersAndEdgesByOrientation(sTileset, nTileID, nOrientation);

        if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2 && nHeight)
        {
            str = TS_ReplaceTerrainOrCrosser(str, "GRASS", "GRASS+");
            str = TS_ReplaceTerrainOrCrosser(str, "MOUNTAIN", "MOUNTAIN+");
        }

        if (AG_GetHasTileOverride(sAreaID, nNeighborTile))
        {
            struct TS_TileStruct strOverride = AG_GetTileOverride(sAreaID, nNeighborTile);

            if (strOverride.sT != "") str.sT = strOverride.sT;
            if (strOverride.sB != "") str.sB = strOverride.sB;
            if (strOverride.sL != "") str.sL = strOverride.sL;
            if (strOverride.sR != "") str.sR = strOverride.sR;
            if (strOverride.sTL != "") str.sTL = strOverride.sTL;
            if (strOverride.sTR != "") str.sTR = strOverride.sTR;
            if (strOverride.sBL != "") str.sBL = strOverride.sBL;
            if (strOverride.sBR != "") str.sBR = strOverride.sBR;
        }
    }
    else
    {
        struct AG_TilePosition strTilePos = AG_GetTilePosition(sAreaID, nTile);

        switch (nDirection)
        {
            case AG_NEIGHBOR_TILE_TOP:
            {
                int nEdgeTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, strTilePos.nX);
                if (nEdgeTileID != AG_INVALID_TILE_ID)
                {
                    int nEdgeOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, strTilePos.nX);
                    str = TS_GetCornersAndEdgesByOrientation(sTileset, nEdgeTileID, nEdgeOrientation);
                }
                else if (AG_GetHasEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, strTilePos.nX))
                {
                    struct AG_EdgeTileOverride strEdge = AG_GetEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, strTilePos.nX);
                    str.sBL = strEdge.sTC1;
                    str.sB = strEdge.sTC2;
                    str.sBR = strEdge.sTC3;
                }
                else
                {
                    string sEdgeTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN);
                    str.sBL = sEdgeTerrain;
                    str.sB = sEdgeTerrain;
                    str.sBR = sEdgeTerrain;
                }
                break;
            }

            case AG_NEIGHBOR_TILE_RIGHT:
            {
                int nEdgeTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, strTilePos.nY);
                if (nEdgeTileID != AG_INVALID_TILE_ID)
                {
                    int nEdgeOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, strTilePos.nY);
                    str = TS_GetCornersAndEdgesByOrientation(sTileset, nEdgeTileID, nEdgeOrientation);
                }
                else if (AG_GetHasEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, strTilePos.nY))
                {
                    struct AG_EdgeTileOverride strEdge = AG_GetEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, strTilePos.nY);
                    str.sTL = strEdge.sTC3;
                    str.sL = strEdge.sTC2;
                    str.sBL = strEdge.sTC1;
                }
                else
                {
                    string sEdgeTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN);
                    str.sTL = sEdgeTerrain;
                    str.sL = sEdgeTerrain;
                    str.sBL = sEdgeTerrain;
                }
                break;
            }

            case AG_NEIGHBOR_TILE_BOTTOM:
            {
                int nEdgeTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, strTilePos.nX);
                if (nEdgeTileID != AG_INVALID_TILE_ID)
                {
                    int nEdgeOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, strTilePos.nX);
                    str = TS_GetCornersAndEdgesByOrientation(sTileset, nEdgeTileID, nEdgeOrientation);
                }
                else if (AG_GetHasEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, strTilePos.nX))
                {
                    struct AG_EdgeTileOverride strEdge = AG_GetEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, strTilePos.nX);
                    str.sTL = strEdge.sTC1;
                    str.sT = strEdge.sTC2;
                    str.sTR = strEdge.sTC3;
                }
                else
                {
                    string sEdgeTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN);
                    str.sTL = sEdgeTerrain;
                    str.sT = sEdgeTerrain;
                    str.sTR = sEdgeTerrain;
                }
                break;
            }

            case AG_NEIGHBOR_TILE_LEFT:
            {
                int nEdgeTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, strTilePos.nY);
                if (nEdgeTileID != AG_INVALID_TILE_ID)
                {
                    int nEdgeOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, strTilePos.nY);
                    str = TS_GetCornersAndEdgesByOrientation(sTileset, nEdgeTileID, nEdgeOrientation);
                }
                else if (AG_GetHasEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, strTilePos.nY))
                {
                    struct AG_EdgeTileOverride strEdge = AG_GetEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, strTilePos.nY);
                    str.sTR = strEdge.sTC3;
                    str.sR = strEdge.sTC2;
                    str.sBR = strEdge.sTC1;
                }
                else
                {
                    string sEdgeTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN);
                    str.sTR = sEdgeTerrain;
                    str.sR = sEdgeTerrain;
                    str.sBR = sEdgeTerrain;
                }
                break;
            }
        }
    }

    return str;
}

string AG_ResolveCorner(string sCorner1, string sCorner2)
{
    if (sCorner1 == sCorner2)
        return sCorner1;

    if (sCorner1 == "" && sCorner2 == "")
        return "";

    if (sCorner1 == "" && sCorner2 != "")
        return sCorner2;

    if (sCorner1 != "" && sCorner2 == "")
        return sCorner1;

    return "ERROR";
}

string AG_SqlConstructCAEClause(struct TS_TileStruct str)
{
    string sWhere;
    if (str.sTL != "") sWhere += "AND tl=@tl ";
    if (str.sT != "")  sWhere += "AND t=@t ";
    if (str.sTR != "") sWhere += "AND tr=@tr ";
    if (str.sR != "")  sWhere += "AND r=@r ";
    if (str.sBR != "") sWhere += "AND br=@br ";
    if (str.sB != "")  sWhere += "AND b=@b ";
    if (str.sBL != "") sWhere += "AND bl=@bl ";
    if (str.sL != "")  sWhere += "AND l=@l ";
    return sWhere;
}

struct AG_Tile AG_GetRandomMatchingTile(string sAreaID, int nTile, int bSingleGroupTile, int bHeightFirst)
{
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    struct AG_Tile tile;
    struct TS_TileStruct strQuery;
    struct TS_TileStruct strTop = AG_GetNeighborTileStruct(sAreaID, nTile, AG_NEIGHBOR_TILE_TOP);
    struct TS_TileStruct strRight = AG_GetNeighborTileStruct(sAreaID, nTile, AG_NEIGHBOR_TILE_RIGHT);
    struct TS_TileStruct strBottom = AG_GetNeighborTileStruct(sAreaID, nTile, AG_NEIGHBOR_TILE_BOTTOM);
    struct TS_TileStruct strLeft = AG_GetNeighborTileStruct(sAreaID, nTile, AG_NEIGHBOR_TILE_LEFT);
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);

    strQuery.sT = strTop.sB;
    strQuery.sR = strRight.sL;
    strQuery.sB = strBottom.sT;
    strQuery.sL = strLeft.sR;

    strQuery.sTL = AG_ResolveCorner(strTop.sBL, strLeft.sTR);
    strQuery.sTR = AG_ResolveCorner(strTop.sBR, strRight.sTL);
    strQuery.sBR = AG_ResolveCorner(strRight.sBL, strBottom.sTR);
    strQuery.sBL = AG_ResolveCorner(strBottom.sTL, strLeft.sBR);

    string sRoadCrosser = AG_GetAreaPathCrosserType(sAreaID);
    int bHasRoad = TS_GetHasTerrainOrCrosser(strQuery, sRoadCrosser);

    string sQuery;

    if (bSingleGroupTile)
        sQuery = "SELECT tile_id, orientation, height FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_SINGLE_GROUP_TILES) + " WHERE 1=1 ";
    else
        sQuery = "SELECT tile_id, orientation, height FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) + " WHERE is_group_tile=0 ";

    if (bHeightFirst)
        sQuery += "AND height=1 ";

    sQuery += AG_SqlConstructCAEClause(strQuery);

    int nTOC, nNumTOC = StringArray_Size(oAreaDataObject, AG_IGNORE_TOC_ARRAY);
    for (nTOC = 0; nTOC < nNumTOC; nTOC++)
    {
        string sTOC = StringArray_At(oAreaDataObject, AG_IGNORE_TOC_ARRAY, nTOC);

        if (sTOC == sRoadCrosser && bHasRoad)
            continue;

        sQuery += "AND corners_and_edges NOT LIKE @" + sTOC + " ";
    }

    sQuery += " ORDER BY RANDOM() LIMIT 1;";

    sqlquery sql = SqlPrepareQueryModule(sQuery);

    if (strQuery.sTL != "") SqlBindString(sql, "@tl", strQuery.sTL);
    if (strQuery.sT != "")  SqlBindString(sql, "@t", strQuery.sT);
    if (strQuery.sTR != "") SqlBindString(sql, "@tr", strQuery.sTR);
    if (strQuery.sR != "")  SqlBindString(sql, "@r", strQuery.sR);
    if (strQuery.sBR != "") SqlBindString(sql, "@br", strQuery.sBR);
    if (strQuery.sB != "")  SqlBindString(sql, "@b", strQuery.sB);
    if (strQuery.sBL != "") SqlBindString(sql, "@bl", strQuery.sBL);
    if (strQuery.sL != "")  SqlBindString(sql, "@l", strQuery.sL);

    for (nTOC = 0; nTOC < nNumTOC; nTOC++)
    {
        string sTOC = StringArray_At(oAreaDataObject, AG_IGNORE_TOC_ARRAY, nTOC);

        if (sTOC == sRoadCrosser && bHasRoad)
            continue;

        SqlBindString(sql, "@" + sTOC, "%|" + sTOC + "|%");
    }

    if (SqlStep(sql))
    {
        tile.nTileID = SqlGetInt(sql, 0);
        tile.nOrientation = SqlGetInt(sql, 1);
        tile.nHeight = SqlGetInt(sql, 2);
    }
    else
    {
        tile.nTileID = AG_INVALID_TILE_ID;
        tile.nOrientation = 0;
        tile.nHeight = 0;
    }

    return tile;
}

void AG_ProcessTile(string sAreaID, int nWidth, int nX, int nY)
{
    int nTile = nX + (nY * nWidth);

    if (AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile) != AG_INVALID_TILE_ID)
        return;

    int bTrySingleGroupTile = Random(100) < AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE);
    int bHeightFirst = Random(100) < AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_HEIGHT_FIRST_CHANCE);

    struct AG_Tile tile = AG_GetRandomMatchingTile(sAreaID, nTile, bTrySingleGroupTile, bHeightFirst);
    if (tile.nTileID == AG_INVALID_TILE_ID && bTrySingleGroupTile)
        tile = AG_GetRandomMatchingTile(sAreaID, nTile, FALSE, bHeightFirst);
    if (tile.nTileID == AG_INVALID_TILE_ID && bHeightFirst)
        tile = AG_GetRandomMatchingTile(sAreaID, nTile, FALSE, FALSE);

    if (tile.nTileID != AG_INVALID_TILE_ID)
        AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, tile.nTileID, tile.nOrientation, tile.nHeight);
    else
        IntArray_Insert(AG_GetAreaDataObject(sAreaID), AG_FAILED_TILES_ARRAY, nTile);

    NWNX_Util_SetInstructionsExecuted(0);
}

int AG_GenerateRandomTiles(string sAreaID)
{
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    int nCurrentWidth = nWidth, nCurrentHeight = nHeight;
    int nCount, nCurrentRow, nCurrentColumn;

    IntArray_Clear(oAreaDataObject, AG_FAILED_TILES_ARRAY, TRUE);

    while (nCurrentRow < nWidth && nCurrentColumn < nHeight)
    {
        for (nCount = nCurrentColumn; nCount < nCurrentHeight; nCount++)
        {
            AG_ProcessTile(sAreaID, nWidth, nCurrentRow, nCount);
        }
        nCurrentRow++;

        for (nCount = nCurrentRow; nCount < nCurrentWidth; ++nCount)
        {
            AG_ProcessTile(sAreaID, nWidth, nCount, nCurrentHeight - 1);
        }
        nCurrentHeight--;

        if (nCurrentRow < nCurrentWidth)
        {
            for (nCount = nCurrentHeight - 1; nCount >= nCurrentColumn; --nCount)
            {
                AG_ProcessTile(sAreaID, nWidth, nCurrentWidth - 1, nCount);
            }
            nCurrentWidth--;
        }

        if (nCurrentColumn < nCurrentHeight)
        {
            for (nCount = nCurrentWidth - 1; nCount >= nCurrentRow; --nCount)
            {
                AG_ProcessTile(sAreaID, nWidth, nCount, nCurrentColumn);
            }
            nCurrentColumn++;
        }
    }

    return IntArray_Size(oAreaDataObject, AG_FAILED_TILES_ARRAY);
}

void AG_GenerateArea(string sAreaID)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED))
    {
        if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS))
        {
            WriteLog("* Finished Generating Area: " + sAreaID);
            WriteLog("  > Result: " + (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED) ? "Failure" : "Success") +
                     ", Iterations: " + IntToString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS)));
        }
        string sCallback = AG_GetCallbackFunction(sAreaID);
        if (sCallback != "")
        {
            ExecuteScriptChunk(sCallback, GetModule(), FALSE);
        }
    }
    else
    {
        int nIteration = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS);

        if (!nIteration)
        {
            if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS))
            {
                WriteLog("* Generating Area: " + sAreaID);
                WriteLog("  > Tileset: " + AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET) +
                         ", Width: " + IntToString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH)) +
                         ", Height: " + IntToString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT)));
            }

            object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
            json jIgnoredTOCArray = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC);
            int nTOC, nNumTOC = JsonGetLength(jIgnoredTOCArray);
            for (nTOC = 0; nTOC < nNumTOC; nTOC++)
            {
                StringArray_Insert(oAreaDataObject, AG_IGNORE_TOC_ARRAY, JsonArrayGetString(jIgnoredTOCArray, nTOC));
            }
        }

        if (nIteration < AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_MAX_ITERATIONS))
        {
            object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
            int nTileFailure, nNumTileFailures = AG_GenerateRandomTiles(sAreaID);

            if (nNumTileFailures)
            {
                for (nTileFailure = 0; nTileFailure < nNumTileFailures; nTileFailure++)
                {
                    if (AG_GENERATION_TILE_FAILURE_RESET_CHANCE == 100 || Random(100) < AG_GENERATION_TILE_FAILURE_RESET_CHANCE)
                        AG_ResetNeighborTiles(sAreaID, IntArray_At(oAreaDataObject, AG_FAILED_TILES_ARRAY, nTileFailure));
                }

                AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS, ++nIteration);
            }
            else
            {
                AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, TRUE);
            }
        }
        else
        {
            AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED, TRUE);
            AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, TRUE);
        }

        DelayCommand(AG_GENERATION_DELAY, AG_GenerateArea(sAreaID));
    }
}

int AG_GetEdgeFromTile(string sAreaID, int nTile)
{
    if (nTile == AG_INVALID_TILE_ID)
        return -1;

    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    int nTileX = nTile % nWidth;
    int nTileY = nTile / nWidth;

    if (nTileY == (nHeight - 1) && nTileX > 0 && nTileX < (nWidth - 1))
        return AG_AREA_EDGE_TOP;

    if (nTileX == 0 && nTileY > 0 && nTileY < (nHeight - 1))
        return AG_AREA_EDGE_LEFT;

    if (nTileY == 0 && nTileX > 0 && nTileX < (nWidth -1))
        return AG_AREA_EDGE_BOTTOM;

    if (nTileX == (nWidth - 1) && nTileY > 0 && nTileY < (nHeight - 1))
        return AG_AREA_EDGE_RIGHT;

    return -1;
}

int AG_GetRandomOtherEdge(int nEdgeToSkip)
{
    int nEdge;
    do nEdge = Random(4);
    while (nEdge == nEdgeToSkip);
    return nEdge;
}

int AG_GetTileOrientationFromEdge(string sAreaID, int nEdge, int nTileID)
{
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);

    if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
    {
        if (nTileID == 80 || nTileID == 1161)
        {
            if (nEdge == AG_AREA_EDGE_TOP)
                return 1;
            if (nEdge == AG_AREA_EDGE_RIGHT)
                return 0;
            if (nEdge == AG_AREA_EDGE_BOTTOM)
                return 3;
            if (nEdge == AG_AREA_EDGE_LEFT)
                return 2;
        }
    }
    else if (sTileset == TILESET_RESREF_MINES_AND_CAVERNS && (nTileID == 198))
    {
        if (nEdge == AG_AREA_EDGE_TOP)
            return 0;
        if (nEdge == AG_AREA_EDGE_RIGHT)
            return 3;
        if (nEdge == AG_AREA_EDGE_BOTTOM)
            return 2;
        if (nEdge == AG_AREA_EDGE_LEFT)
            return 1;
    }
    else
        WriteLog("* AG_GetTileOrientationFromEdge: unknown tile: " + sTileset + "(" + IntToString(nTileID) + ")");

    return -1;
}

void AG_CreatePathEntranceDoorTile(string sAreaID, int nTile)
{
    int nEdge = AG_GetEdgeFromTile(sAreaID, nTile);
    int nPathDoorTileID = AG_GetAreaPathDoor(sAreaID);
    int nOrientation = AG_GetTileOrientationFromEdge(sAreaID, nEdge, nPathDoorTileID);

    AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, nPathDoorTileID, nOrientation, 0, TRUE);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX, nTile);
}

void AG_CreatePathExitDoorTile(string sAreaID)
{
    int nEntranceTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);
    int nEntranceEdge = AG_GetEdgeFromTile(sAreaID, nEntranceTile);
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    int nEdge = AG_GetRandomOtherEdge(nEntranceEdge);
    int nPathDoorTileID = AG_GetAreaPathDoor(sAreaID);
    int nOrientation = AG_GetTileOrientationFromEdge(sAreaID, nEdge, nPathDoorTileID);
    int nTile;

    if (nEdge == AG_AREA_EDGE_TOP)
        nTile = (nWidth * (nHeight - 1)) + (Random(nWidth - 2) + 1);
    else if (nEdge == AG_AREA_EDGE_RIGHT)
        nTile = (nWidth - 1) + ((Random(nHeight - 2) + 1) * nWidth);
    else if (nEdge == AG_AREA_EDGE_BOTTOM)
        nTile = (Random(nWidth - 2) + 1);
    else if (nEdge == AG_AREA_EDGE_LEFT)
        nTile = (Random(nHeight - 2) + 1) * nWidth;

    AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, nPathDoorTileID, nOrientation, 0, TRUE);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX, nTile);
}

void AG_CopyEdgeFromArea(string sAreaID, object oArea, int nEdgeToCopy)
{
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    int nOtherWidth = GetAreaSize(AREA_WIDTH, oArea);
    int nOtherHeight = GetAreaSize(AREA_HEIGHT, oArea);

    if (nEdgeToCopy == AG_AREA_EDGE_TOP || nEdgeToCopy == AG_AREA_EDGE_BOTTOM)
    {
        if (nWidth != nOtherWidth)
        {
            WriteLog("* ERROR: AG_CopyEdgeFromArea: Area Width does not match!");
            return;
        }
    }
    else if (nEdgeToCopy == AG_AREA_EDGE_LEFT || nEdgeToCopy == AG_AREA_EDGE_RIGHT)
    {
        if (nHeight != nOtherHeight)
        {
            WriteLog("* ERROR: AG_CopyEdgeFromArea: Area Height does not match!");
            return;
        }
    }

    switch (nEdgeToCopy)
    {
        case AG_AREA_EDGE_TOP:
        {
            int nStart = nOtherWidth * (nOtherHeight - 1);
            int nCount, nNumTiles = nOtherWidth;
            for (nCount = 0; nCount < nNumTiles; nCount++)
            {
                int nTile = nStart + nCount;
                struct NWNX_Area_TileInfo str = NWNX_Area_GetTileInfoByTileIndex(oArea, nTile);
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, nCount, str.nID, str.nOrientation);

                int nTileIndex = nCount;
                if (AG_GetIsPathDoor(sAreaID, str.nID))
                {
                    AG_CreatePathEntranceDoorTile(sAreaID, nTileIndex);
                    AG_CreatePathExitDoorTile(sAreaID);
                }
            }
            break;
        }

        case AG_AREA_EDGE_RIGHT:
        {
            int nStart = nOtherWidth - 1;
            int nCount, nNumTiles = nOtherHeight;
            for (nCount = 0; nCount < nNumTiles; nCount++)
            {
                int nTile = nStart + (nCount * nOtherWidth);
                struct NWNX_Area_TileInfo str = NWNX_Area_GetTileInfoByTileIndex(oArea, nTile);
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, nCount, str.nID, str.nOrientation);

                int nTileIndex = nCount * nWidth;
                if (AG_GetIsPathDoor(sAreaID, str.nID))
                {
                    AG_CreatePathEntranceDoorTile(sAreaID, nTileIndex);
                    AG_CreatePathExitDoorTile(sAreaID);
                }
            }
            break;
        }

        case AG_AREA_EDGE_BOTTOM:
        {
            int nStart = 0;
            int nCount, nNumTiles = nOtherWidth;
            for (nCount = 0; nCount < nNumTiles; nCount++)
            {
                int nTile = nStart + nCount;
                struct NWNX_Area_TileInfo str = NWNX_Area_GetTileInfoByTileIndex(oArea, nTile);
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, nCount, str.nID, str.nOrientation);

                int nTileIndex = (nOtherWidth * (nHeight - 1)) + nCount;
                if (AG_GetIsPathDoor(sAreaID, str.nID))
                {
                    AG_CreatePathEntranceDoorTile(sAreaID, nTileIndex);
                    AG_CreatePathExitDoorTile(sAreaID);
                }
            }
            break;
        }

        case AG_AREA_EDGE_LEFT:
        {
            int nStart = 0;
            int nCount, nNumTiles = nOtherHeight;
            for (nCount = 0; nCount < nNumTiles; nCount++)
            {
                int nTile = nStart + (nCount * nOtherWidth);
                struct NWNX_Area_TileInfo str = NWNX_Area_GetTileInfoByTileIndex(oArea, nTile);
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, nCount, str.nID, str.nOrientation);

                int nTileIndex = (nWidth - 1) + (nCount * nWidth);
                if (AG_GetIsPathDoor(sAreaID, str.nID))
                {
                    AG_CreatePathEntranceDoorTile(sAreaID, nTileIndex);
                    AG_CreatePathExitDoorTile(sAreaID);
                }
            }
            break;
        }
    }
}

int AG_GetNextTile(int nAreaWidth, int nTile, int nEdge)
{
    if (nEdge == AG_AREA_EDGE_TOP)
        return nTile - nAreaWidth;
    if (nEdge == AG_AREA_EDGE_RIGHT)
        return nTile - 1;
    if (nEdge == AG_AREA_EDGE_BOTTOM)
        return nTile + nAreaWidth;
    if (nEdge == AG_AREA_EDGE_LEFT)
        return nTile + 1;
    return nTile;
}

struct TS_TileStruct AG_GetRoadTileStruct(string sAreaID, int nNode, int nNumNodes, int nX1, int nY1, int nX2, int nY2, int bNoRoad)
{
    struct TS_TileStruct str;
    string sRoadCrosser = AG_GetAreaPathCrosserType(sAreaID);
    string sFloorTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_FLOOR_TERRAIN);

    if (bNoRoad)
        str = TS_ReplaceTerrainOrCrosser(str, "", sFloorTerrain);

    if (bNoRoad && nNumNodes != 1)
    {
        if (nNode == 0)
        {
            if (nX1 == 0 && nY1 == -1)
                str.sT = sRoadCrosser;
            if (nX1 == -1 && nY1 == 0)
                str.sR = sRoadCrosser;
            if (nX1 == 0 && nY1 == 1)
                str.sB = sRoadCrosser;
            if (nX1 == 1 && nY1 == 0)
                str.sL = sRoadCrosser;
        }
        else if (nNode == (nNumNodes - 1))
        {
            if (nX2 == 0 && nY2 == -1)
                str.sT = sRoadCrosser;
            if (nX2 == -1 && nY2 == 0)
                str.sR = sRoadCrosser;
            if (nX2 == 0 && nY2 == 1)
                str.sB = sRoadCrosser;
            if (nX2 == 1 && nY2 == 0)
                str.sL = sRoadCrosser;
        }
    }
    else
    {
        if ((nX1 == 0 && nY1 == -1) || (nX2 == 0 && nY2 == -1))
            str.sT = sRoadCrosser;
        if ((nX1 == -1 && nY1 == 0) || (nX2 == -1 && nY2 == 0))
            str.sR = sRoadCrosser;
        if ((nX1 == 0 && nY1 == 1) || (nX2 == 0 && nY2 == 1))
            str.sB = sRoadCrosser;
        if ((nX1 == 1 && nY1 == 0) || (nX2 == 1 && nY2 == 0))
            str.sL = sRoadCrosser;
    }

    return str;
}

struct AG_Tile AG_GetRandomRoadTile(string sAreaID, struct TS_TileStruct strQuery)
{
    struct AG_Tile tile;
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);

    string sQuery = "SELECT tile_id, orientation FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) + " WHERE is_group_tile=0 " +
                    AG_SqlConstructCAEClause(strQuery);
    sQuery += " ORDER BY RANDOM() LIMIT 1;";

    sqlquery sql = SqlPrepareQueryModule(sQuery);

    if (strQuery.sTL != "") SqlBindString(sql, "@tl", strQuery.sTL);
    if (strQuery.sT != "")  SqlBindString(sql, "@t", strQuery.sT);
    if (strQuery.sTR != "") SqlBindString(sql, "@tr", strQuery.sTR);
    if (strQuery.sR != "")  SqlBindString(sql, "@r", strQuery.sR);
    if (strQuery.sBR != "") SqlBindString(sql, "@br", strQuery.sBR);
    if (strQuery.sB != "")  SqlBindString(sql, "@b", strQuery.sB);
    if (strQuery.sBL != "") SqlBindString(sql, "@bl", strQuery.sBL);
    if (strQuery.sL != "")  SqlBindString(sql, "@l", strQuery.sL);

    if (SqlStep(sql))
    {
        tile.nTileID = SqlGetInt(sql, 0);
        tile.nOrientation = SqlGetInt(sql, 1);
        tile.nHeight = 0;
    }
    else
    {
        tile.nTileID = -1;
        tile.nOrientation = -1;
        tile.nHeight = -1;
    }

    return tile;
}

void AG_PlotRoad(string sAreaID)
{
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    int nEntranceTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);
    int nEntranceEdge = AG_GetEdgeFromTile(sAreaID, nEntranceTile);
    nEntranceTile = AG_GetNextTile(nWidth, nEntranceTile, nEntranceEdge);
    int nEntranceX = nEntranceTile % nWidth;
    int nEntranceY = nEntranceTile / nWidth;
    int nExitTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    int nExitEdge = AG_GetEdgeFromTile(sAreaID, nExitTile);
    nExitTile = AG_GetNextTile(nWidth, nExitTile, nExitEdge);
    int nExitX = nExitTile % nWidth;
    int nExitY = nExitTile / nWidth;
    int nDistanceX = nExitX - nEntranceX;
    int nDistanceY = nExitY - nEntranceY;
    int nAbsDistanceX = abs(nDistanceX);
    int nAbsDistanceY = abs(nDistanceY);
    int nSignX = nDistanceX > 0 ? 1 : -1;
    int nSignY = nDistanceY > 0 ? 1 : -1;
    json jPathNodes = JsonArray();
    int nNodeX = nEntranceX;
    int nNodeY = nEntranceY;

    jPathNodes = JsonArrayInsert(jPathNodes, JsonPointInt(nNodeX, nNodeY));

    int nItX = 0, nItY = 0;
    while (nItX < nAbsDistanceX || nItY < nAbsDistanceY)
    {
        if ((1 + 2 * nItX) * nAbsDistanceY < (1 + 2 * nItY) * nAbsDistanceX)
        {
            nNodeX += nSignX;
            nItX++;
        }
        else
        {
            nNodeY += nSignY;
            nItY++;
        }

        jPathNodes = JsonArrayInsert(jPathNodes, JsonPointInt(nNodeX, nNodeY));
    }

    nEntranceTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);
    nExitTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    int bNoRoad = Random(100) < AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_PATH_NO_ROAD_CHANCE);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_PATH_NO_ROAD, bNoRoad);

    int nPreviousX = nEntranceTile % nWidth, nPreviousY = nEntranceTile / nWidth;
    int nNode, nNumNodes = JsonGetLength(jPathNodes);
    for (nNode = 0; nNode < nNumNodes; nNode++)
    {
        json jNode = JsonArrayGet(jPathNodes, nNode);
        int nCurrentX = JsonObjectGetInt(jNode, "x");
        int nCurrentY = JsonObjectGetInt(jNode, "y");
        json jNextNode = JsonArrayGet(jPathNodes, nNode + 1);
        int nNextX = JsonGetType(jNextNode) ? JsonObjectGetInt(jNextNode, "x") : nExitTile % nWidth;
        int nNextY = JsonGetType(jNextNode) ? JsonObjectGetInt(jNextNode, "y") : nExitTile / nWidth;

        int nPreviousDiffX = nCurrentX - nPreviousX;
        int nPreviousDiffY = nCurrentY - nPreviousY;
        int nNextDiffX = nCurrentX - nNextX;
        int nNextDiffY = nCurrentY - nNextY;

        struct TS_TileStruct strQuery = AG_GetRoadTileStruct(sAreaID, nNode, nNumNodes, nPreviousDiffX, nPreviousDiffY, nNextDiffX, nNextDiffY, bNoRoad);

        int nTile = nCurrentX + (nCurrentY * nWidth);
        if (bNoRoad)
        {
            struct AG_Tile strTile = AG_GetRandomRoadTile(sAreaID, strQuery);
            AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, strTile.nTileID, strTile.nOrientation, 0, TRUE);
        }
        else
            AG_SetTileOverride(sAreaID, nTile, strQuery);

        nPreviousX = nCurrentX;
        nPreviousY = nCurrentY;
    }

    jPathNodes = JsonArrayInsert(jPathNodes, JsonPointInt(nEntranceTile % nWidth, nEntranceTile / nWidth), 0);
    jPathNodes = JsonArrayInsert(jPathNodes, JsonPointInt(nExitTile % nWidth, nExitTile / nWidth));
    AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_PATH_NODES, jPathNodes);
}

void AG_AddEdgeTerrain(string sAreaID, string sTerrain)
{
    json jEdgeTerrains = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TERRAINS);
    AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TERRAINS, JsonArrayInsertString(jEdgeTerrains, sTerrain));
}

void AG_GenerateEdge(string sAreaID, int nEdge)
{
    if (AG_GetEdgeFromTile(sAreaID, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX)) == nEdge)
        return;

    json jEdgeTerrains = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TERRAINS);
    int nEdgeTerrain, nNumEdgeTerrains = JsonGetLength(jEdgeTerrains);
    json jUsableEdgeTerrains = JsonArray();

    for (nEdgeTerrain = 0; nEdgeTerrain < nNumEdgeTerrains; nEdgeTerrain++)
    {
        string sEdgeTerrain = JsonArrayGetString(jEdgeTerrains, nEdgeTerrain);
        if (!AG_GetIgnoreTerrainOrCrosser(sAreaID, sEdgeTerrain))
            jUsableEdgeTerrains = JsonArrayInsertString(jUsableEdgeTerrains, sEdgeTerrain);
    }

    int nNumUsableEdgeTerrains = JsonGetLength(jUsableEdgeTerrains);
    if (nNumUsableEdgeTerrains == 1)
        return;

    string sTileArray, sDefaultEdge = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN);
    int nExitTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    int bHasExit = AG_GetEdgeFromTile(sAreaID, nExitTile) == nEdge;
    int nNumTiles, nExitPosition;

    switch (nEdge)
    {
        case AG_AREA_EDGE_TOP:
        {
            sTileArray = AG_DATA_KEY_ARRAY_EDGE_TOP;
            nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
            nExitPosition = nExitTile % nNumTiles;
            break;
        }

        case AG_AREA_EDGE_BOTTOM:
        {
            sTileArray = AG_DATA_KEY_ARRAY_EDGE_BOTTOM;
            nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
            nExitPosition = nExitTile % nNumTiles;
            break;
        }

        case AG_AREA_EDGE_RIGHT:
        {
            sTileArray = AG_DATA_KEY_ARRAY_EDGE_RIGHT;
            nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
            nExitPosition = nExitTile / AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
            break;
        }

        case AG_AREA_EDGE_LEFT:
        {
            sTileArray = AG_DATA_KEY_ARRAY_EDGE_LEFT;
            nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
            nExitPosition = nExitTile / AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
            break;
        }
    }

    int nTile, nPreviousTile = -1, nNextTile = 1;
    string sTC1, sTC2, sTC3;

    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        if (nPreviousTile == -1 || (bHasExit && nTile == nExitPosition) || nTile == (nNumTiles - 1))
        {
            sTC1 = sDefaultEdge;
            sTC3 = sDefaultEdge;
        }
        else
        {
            sTC1 = AG_GetEdgeTileOverride(sAreaID, sTileArray, nPreviousTile).sTC3;

            if (nTile == (nNumTiles - 2) || (bHasExit && nNextTile == nExitPosition))
                sTC3 = sDefaultEdge;
            else
            {
                int nEdgeTerrainChangeChance = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE);

                if (nEdgeTerrainChangeChance == 100 || Random(100) < nEdgeTerrainChangeChance)
                    sTC3 = JsonArrayGetString(jUsableEdgeTerrains, Random(nNumUsableEdgeTerrains));
                else
                    sTC3 = sTC1;
            }
        }

        if (bHasExit)
        {
            json jExitEdgeTerrains = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS);

            if (!JsonArrayContainsString(jExitEdgeTerrains, sTC1))
                jExitEdgeTerrains = JsonArrayInsertString(jExitEdgeTerrains, sTC1);

            if (!JsonArrayContainsString(jExitEdgeTerrains, sTC3))
                jExitEdgeTerrains = JsonArrayInsertString(jExitEdgeTerrains, sTC3);

            AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS, jExitEdgeTerrains);
        }

        AG_SetEdgeTileOverride(sAreaID, sTileArray, nTile, sTC1, sTC2, sTC3);
        nPreviousTile++;
        nNextTile++;
    }
}

int AG_GetNumPathDoorCrosserCombos(string sAreaID)
{
    return AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_PATH_DOOR_CROSSER_COMBOS);
}

void AG_AddPathDoorCrosserCombo(string sAreaID, int nDoorTile, string sCrosser)
{
    int nNum = AG_GetNumPathDoorCrosserCombos(sAreaID);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_PATH_DOOR_ID + IntToString(nNum), nDoorTile);
    AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_PATH_CROSSER_TYPE + IntToString(nNum), sCrosser);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_PATH_DOOR_CROSSER_COMBOS, ++nNum);
}

int AG_GetPathDoorID(string sAreaID, int nNum)
{
    return AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_PATH_DOOR_ID + IntToString(nNum));
}

string AG_GetPathCrosserType(string sAreaID, int nNum)
{
    return AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_PATH_CROSSER_TYPE + IntToString(nNum));
}

int AG_GetIsPathDoor(string sAreaID, int nTileID)
{
    int nCount, nNum = AG_GetNumPathDoorCrosserCombos(sAreaID);
    for (nCount = 0; nCount < nNum; nCount++)
    {
        if (AG_GetPathDoorID(sAreaID, nCount) == nTileID)
            return TRUE;
    }

    return FALSE;
}

void AG_SetAreaPathDoorCrosserCombo(string sAreaID, int nNum)
{
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_AREA_PATH_DOOR_CROSSER_COMBO, nNum);
}

int AG_GetAreaPathDoor(string sAreaID)
{
    return AG_GetPathDoorID(sAreaID, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_AREA_PATH_DOOR_CROSSER_COMBO));
}

string AG_GetAreaPathCrosserType(string sAreaID)
{
    return AG_GetPathCrosserType(sAreaID, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_AREA_PATH_DOOR_CROSSER_COMBO));
}

struct AG_TilePosition AG_GetTilePosition(string sAreaID, int nTile)
{
    struct AG_TilePosition str;
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    str.nX = nTile % nWidth;
    str.nY = nTile / nWidth;
    return str;
}

void AG_CreateRandomEntrance(string sAreaID, int nEntranceTileID)
{
    int nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    int nTile = Random(nNumTiles);
    int nEdge = AG_GetEdgeFromTile(sAreaID, nTile);
    int nOrientation = nEdge == -1 ? Random(4) : AG_GetTileOrientationFromEdge(sAreaID, nEdge, nEntranceTileID);

    AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, nEntranceTileID, nOrientation, 0, TRUE);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX, nTile);
}

json AG_GetTileList(string sAreaID)
{
    string sTiles;
    int nTile, nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        int nTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
        int nOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
        int nHeight = AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);

        sTiles += "{\"Tile_AnimLoop1\":{\"type\":\"byte\",\"value\":1},\"Tile_AnimLoop2\":{\"type\":\"byte\",\"value\":1},\"" +
                  "Tile_AnimLoop3\":{\"type\":\"byte\",\"value\":1},\"Tile_Height\":{\"type\":\"int\",\"value\":" + IntToString(nHeight) +
                  "},\"Tile_ID\":{\"type\":\"int\",\"value\":" + IntToString(nTileID) +
                  " },\"Tile_Orientation\":{\"type\":\"int\",\"value\":" + IntToString(nOrientation) + "}},";
    }

    return StringJsonArrayElementsToJsonArray(sTiles);
}

object AG_CreateDoor(string sAreaID, int nTileIndex, string sTag, int nDoorIndex = 0)
{
    object oArea = GetObjectByTag(sAreaID);
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);
    struct NWNX_Area_TileInfo strTileInfo = NWNX_Area_GetTileInfoByTileIndex(oArea, nTileIndex);
    float fTilesetHeighTransition = TS_GetTilesetHeightTransition(sTileset);
    struct TS_DoorStruct strDoor = TS_GetTilesetTileDoor(sTileset, strTileInfo.nID, nDoorIndex);

    vector vDoorPosition = TS_RotateCanonicalToReal(strTileInfo.nOrientation, strDoor.vPosition);
           vDoorPosition.x += (strTileInfo.nGridX * 10.0f);
           vDoorPosition.y += (strTileInfo.nGridY * 10.0f);
           vDoorPosition.z += (strTileInfo.nHeight * fTilesetHeighTransition);

    switch (strTileInfo.nOrientation)
    {
        case 0: strDoor.fOrientation += 0.0f ; break; // ^_^
        case 1: strDoor.fOrientation += 90.0f; break;
        case 2: strDoor.fOrientation += 180.0f; break;
        case 3: strDoor.fOrientation += 270.0f; break;
    }

    location locSpawn = Location(oArea, vDoorPosition, strDoor.fOrientation);

    return GffTools_CreateDoor(strDoor.nType, locSpawn, sTag);
}
