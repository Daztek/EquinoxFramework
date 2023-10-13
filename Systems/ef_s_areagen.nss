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

const int AG_ENABLE_SEEDED_RANDOM                               = TRUE;
const int AG_GENERATION_DEFAULT_MAX_ITERATIONS                  = 100;
const float AG_GENERATION_DELAY                                 = 0.1f;
const int AG_GENERATION_TILE_BATCH                              = 32;
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
const string AG_DATA_KEY_GENERATION_TYPE                        = "GenerationType";
const string AG_DATA_KEY_GENERATION_RANDOM_NAME                 = "GenerationRandomName";
const string AG_DATA_KEY_ENABLE_CORNER_TILE_VALIDATOR           = "EnableCornerTileValidator";

const string AG_DATA_KEY_TILE_ID                                = "TileID";
const string AG_DATA_KEY_TILE_LOCKED                            = "Locked";
const string AG_DATA_KEY_TILE_ORIENTATION                       = "Orientation";
const string AG_DATA_KEY_TILE_HEIGHT                            = "Height";
const string AG_DATA_KEY_TILE_IGNORETOCBITMASK                  = "IgnoreTOCBitmask";

const string AG_DATA_KEY_ENTRANCE_TILE_INDEX                    = "EntranceTileIndex";
const string AG_DATA_KEY_EXIT_TILE_INDEX                        = "ExitTileIndex";
const string AG_DATA_KEY_PATH_NODES                             = "PathNodes";
const string AG_DATA_KEY_ARRAY_EDGE_TERRAINS                    = "ArrayEdgeTerrains";
const string AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE             = "EdgeTerrainChangeChance";
const string AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS               = "ArrayExitEdgeTerrains";
const string AG_DATA_KEY_AREA_PATH_DOOR_CROSSER_COMBO           = "AreaPathDoorCrosserCombo";
const string AG_DATA_KEY_NUM_PATH_DOOR_CROSSER_COMBOS           = "PathDoorCrosserCombos";
const string AG_DATA_KEY_PATH_DOOR_ID                           = "PathDoorId_";
const string AG_DATA_KEY_PATH_CROSSER_TYPE                      = "PathCrosserType_";

const string AG_GENERATION_TILE_ARRAY                           = "GenerationTileArray";
const string AG_FAILED_TILES_ARRAY                              = "FailedTilesArray";
const string AG_IGNORE_TOC_ARRAY                                = "IgnoreTOCArray";

const string AG_DATA_KEY_CHUNK_SIZE                             = "ChunkSize";
const string AG_DATA_KEY_CHUNK_AMOUNT                           = "ChunkAmount";
const string AG_DATA_KEY_CHUNK_NUM_TILES                        = "ChunkNumTiles";
const string AG_DATA_KEY_CHUNK_ARRAY                            = "ChunkArray_";
const string AG_DATA_KEY_CURRENT_CHUNK                          = "CurrentChunk";

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

const int AG_GENERATION_TYPE_SPIRAL_INWARD                      = 0;
const int AG_GENERATION_TYPE_SPIRAL_OUTWARD                     = 1;
const int AG_GENERATION_TYPE_LINEAR_ASCENDING                   = 2;
const int AG_GENERATION_TYPE_LINEAR_DESCENDING                  = 3;
const int AG_GENERATION_TYPE_ALTERNATING_ROWS_INWARD            = 4;
const int AG_GENERATION_TYPE_ALTERNATING_ROWS_OUTWARD           = 5;
const int AG_GENERATION_TYPE_ALTERNATING_COLUMNS_INWARD         = 6;
const int AG_GENERATION_TYPE_ALTERNATING_COLUMNS_OUTWARD        = 7;

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
struct AG_Tile AG_GetTile(string sAreaID, int nTile, string sTileArray = AG_DATA_KEY_ARRAY_TILES);
void AG_Tile_SetID(string sAreaID, string sTileArray, int nTile, int nTileID);
int AG_Tile_GetID(string sAreaID, string sTileArray, int nTile);
void AG_Tile_SetLocked(string sAreaID, string sTileArray, int nTile, int bLocked);
int AG_Tile_GetLocked(string sAreaID, string sTileArray, int nTile);
void AG_Tile_SetOrientation(string sAreaID, string sTileArray, int nTile, int nOrientation);
int AG_Tile_GetOrientation(string sAreaID, string sTileArray, int nTile);
void AG_Tile_SetHeight(string sAreaID, string sTileArray, int nTile, int nHeight);
int AG_Tile_GetHeight(string sAreaID, string sTileArray, int nTile);
void AG_Tile_SetIgnoreTOCBitmask(string sAreaID, string sTileArray, int nTile, int nBitmask);
int AG_Tile_GetIgnoreTOCBitmask(string sAreaID, string sTileArray, int nTile);
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
void AG_ResetNeighborTileChunk(string sAreaID, int nTile);
void AG_ResetGrid(string sAreaID);
struct TS_TileStruct AG_GetNeighborTileStruct(string sAreaID, int nTile, int nDirection);
string AG_ResolveCorner(string sCorner1, string sCorner2);
string AG_SqlConstructCAEClause(struct TS_TileStruct str);
struct AG_Tile AG_GetRandomMatchingTile(string sAreaID, int nTile, int bSingleGroupTile);
void AG_ProcessTile(string sAreaID, int nTileID);
void AG_GenerateTiles(string sAreaID, int nCurrentTile = 0, int nNumTiles = 0);
void AG_GenerateGenerationTileArray(string sAreaID);
void AG_GenerateArea(string sAreaID);
int AG_GetEdgeFromTile(string sAreaID, int nTile);
int AG_GetRandomOtherEdge(string sAreaID, int nEdgeToSkip);
int AG_GetTileOrientationFromEdge(string sAreaID, int nEdge, int nTileID);
void AG_CreatePathEntranceDoorTile(string sAreaID, int nTile, int nHeight);
void AG_CreatePathExitDoorTile(string sAreaID);
void AG_CopyEdgeFromArea(string sAreaID, object oArea, int nEdgeToCopy);
void AG_ExtractExitEdgeTerrains(string sAreaID);
int AG_GetNextTile(int nAreaWidth, int nTile, int nEdge);
struct TS_TileStruct AG_GetRoadTileStruct(string sAreaID, int nX1, int nY1, int nX2, int nY2);
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
int AG_Random(string sAreaID, int nMaxInteger);
string AG_GetRandomQueryString(string sAreaID);
json AG_GetSetTileTileObject(int nIndex, int nTileID, int nOrientation, int nHeight);
string AG_GetGenerationTypeAsString(int nGenerationType);
int AG_GetChunkIndexFromTile(string sAreaID, int nTile);
void AG_SetChunkArray(string sAreaID, int nChunk, json jArray);
json AG_GetChunkArray(string sAreaID, int nChunk);
void AG_InsertTileToChunk(string sAreaID, int nChunk, int nTile);
void AG_InitializeAreaChunks(string sAreaID, int nChunkSize);
void AG_LockChunkTiles(string sAreaID, int nChunk);
void AG_ResetChunkTiles(string sAreaID, int nChunk);
void AG_GenerateTileChunk(string sAreaID, int nChunk, int nCurrentTile = 0, int nNumTiles = 0);
void AG_GenerateAreaChunk(string sAreaID, int nChunk);
void AG_InitializeChunkFromArea(string sAreaID, object oArea, int nChunk);
int AG_CheckCornerTileTerrain(string sTerrain1, string sTerrain2, string sTerrain3);
int AG_ValidateCornerTile(string sAreaID, int nTile, struct AG_Tile strTile);

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

struct AG_Tile AG_GetTile(string sAreaID, int nTile, string sTileArray = AG_DATA_KEY_ARRAY_TILES)
{
    struct AG_Tile str;
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    string sTile = IntToString(nTile);
    str.nTileID = GetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_ID + sTile);
    str.nOrientation = GetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_ORIENTATION + sTile);
    str.nHeight = GetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_HEIGHT + sTile);
    return str;
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

void AG_Tile_SetIgnoreTOCBitmask(string sAreaID, string sTileArray, int nTile, int nBitmask)
{
    AG_SetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_IGNORETOCBITMASK + IntToString(nTile), nBitmask);
}

int AG_Tile_GetIgnoreTOCBitmask(string sAreaID, string sTileArray, int nTile)
{
    return AG_GetIntDataByKey(sAreaID, sTileArray + AG_DATA_KEY_TILE_IGNORETOCBITMASK + IntToString(nTile));
}

void AG_Tile_Set(string sAreaID, string sTileArray, int nTile, int nID, int nOrientation, int nHeight = 0, int bLocked = FALSE)
{
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    string sTile = IntToString(nTile);
    SetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_ID + sTile, nID);
    SetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_ORIENTATION + sTile, nOrientation);
    SetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_HEIGHT + sTile, nHeight);
    SetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_LOCKED + sTile, bLocked);
}

void AG_Tile_Reset(string sAreaID, string sTileArray, int nTile)
{
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    string sTile = IntToString(nTile);
    SetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_ID + sTile, AG_INVALID_TILE_ID);
    SetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_ORIENTATION + sTile, 0);
    SetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_HEIGHT + sTile, 0);
    SetLocalInt(oAreaDataObject, sTileArray + AG_DATA_KEY_TILE_LOCKED + sTile, FALSE);
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
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_CURRENT_CHUNK, -1);

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
                AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_TILES, nNeighborTile);
            }
        }
    }

    if (!AG_Tile_GetLocked(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile))
        AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
}

void AG_ResetNeighborTileChunk(string sAreaID, int nTile)
{
    int nNeighborTile = AG_GetNeighborTile(sAreaID, nTile, AG_NEIGHBOR_TILE_TOP_LEFT);
    if (nNeighborTile != AG_INVALID_TILE_ID)
        AG_ResetNeighborTiles(sAreaID, nNeighborTile);

    nNeighborTile = AG_GetNeighborTile(sAreaID, nTile, AG_NEIGHBOR_TILE_TOP_RIGHT);
    if (nNeighborTile != AG_INVALID_TILE_ID)
        AG_ResetNeighborTiles(sAreaID, nNeighborTile);

    nNeighborTile = AG_GetNeighborTile(sAreaID, nTile, AG_NEIGHBOR_TILE_BOTTOM_LEFT);
    if (nNeighborTile != AG_INVALID_TILE_ID)
        AG_ResetNeighborTiles(sAreaID, nNeighborTile);

    nNeighborTile = AG_GetNeighborTile(sAreaID, nTile, AG_NEIGHBOR_TILE_BOTTOM_RIGHT);
    if (nNeighborTile != AG_INVALID_TILE_ID)
        AG_ResetNeighborTiles(sAreaID, nNeighborTile);

    AG_ResetNeighborTiles(sAreaID, nTile);
}

void AG_ResetGrid(string sAreaID)
{
    int nTile, nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        if (!AG_Tile_GetLocked(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile) &&
            AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile) != AG_INVALID_TILE_ID)
            AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
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

        if (nHeight)
            str = TS_IncreaseTileHeight(sTileset, str, nHeight);
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

                    int nEdgeHeight = AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, strTilePos.nX);
                    if (nEdgeHeight)
                        str = TS_IncreaseTileHeight(sTileset, str, nEdgeHeight);

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

                    int nEdgeHeight = AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, strTilePos.nY);
                    if (nEdgeHeight)
                        str = TS_IncreaseTileHeight(sTileset, str, nEdgeHeight);
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

                    int nEdgeHeight = AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, strTilePos.nX);
                    if (nEdgeHeight)
                        str = TS_IncreaseTileHeight(sTileset, str, nEdgeHeight);
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

                    int nEdgeHeight = AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, strTilePos.nY);
                    if (nEdgeHeight)
                        str = TS_IncreaseTileHeight(sTileset, str, nEdgeHeight);
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

struct AG_Tile AG_GetRandomMatchingTile(string sAreaID, int nTile, int bSingleGroupTile)
{
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);
    struct AG_Tile tile; tile.nTileID = AG_INVALID_TILE_ID;
    struct TS_TileStruct strQuery;
    struct TS_TileStruct strTop = AG_GetNeighborTileStruct(sAreaID, nTile, AG_NEIGHBOR_TILE_TOP);
    struct TS_TileStruct strRight = AG_GetNeighborTileStruct(sAreaID, nTile, AG_NEIGHBOR_TILE_RIGHT);
    struct TS_TileStruct strBottom = AG_GetNeighborTileStruct(sAreaID, nTile, AG_NEIGHBOR_TILE_BOTTOM);
    struct TS_TileStruct strLeft = AG_GetNeighborTileStruct(sAreaID, nTile, AG_NEIGHBOR_TILE_LEFT);

    strQuery.sTL = AG_ResolveCorner(strTop.sBL, strLeft.sTR);
    if (strQuery.sTL == "ERROR") return tile;

    strQuery.sTR = AG_ResolveCorner(strTop.sBR, strRight.sTL);
    if (strQuery.sTR == "ERROR") return tile;

    strQuery.sBR = AG_ResolveCorner(strRight.sBL, strBottom.sTR);
    if (strQuery.sBR == "ERROR") return tile;

    strQuery.sBL = AG_ResolveCorner(strBottom.sTL, strLeft.sBR);
    if (strQuery.sBL == "ERROR") return tile;

    strQuery.sT = TS_SetEdge(strTop.sB, strQuery.sTL, strQuery.sTR);
    strQuery.sR = TS_SetEdge(strRight.sL, strQuery.sTR, strQuery.sBR);
    strQuery.sB = TS_SetEdge(strBottom.sT, strQuery.sBL, strQuery.sBR);
    strQuery.sL = TS_SetEdge(strLeft.sR, strQuery.sTL, strQuery.sBL);

    string sPathCrosser = AG_GetAreaPathCrosserType(sAreaID);
    int bHasPath = TS_GetHasTerrainOrCrosser(strQuery, sPathCrosser);

    string sQuery;

    if (bSingleGroupTile)
        sQuery = "SELECT tile_id, orientation, height FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_SINGLE_GROUP_TILES) + " WHERE 1=1 ";
    else
        sQuery = "SELECT tile_id, orientation, height FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) + " WHERE is_group_tile=0 ";

    sQuery += AG_SqlConstructCAEClause(strQuery);
    sQuery += "AND (bitmask & @tocbitmask) = 0 ";
    sQuery += "ORDER BY " + AG_GetRandomQueryString(sAreaID) + " LIMIT 1;";

    sqlquery sql = SqlPrepareQueryModule(sQuery);

    if (strQuery.sTL != "") SqlBindString(sql, "@tl", strQuery.sTL);
    if (strQuery.sT != "")  SqlBindString(sql, "@t", strQuery.sT);
    if (strQuery.sTR != "") SqlBindString(sql, "@tr", strQuery.sTR);
    if (strQuery.sR != "")  SqlBindString(sql, "@r", strQuery.sR);
    if (strQuery.sBR != "") SqlBindString(sql, "@br", strQuery.sBR);
    if (strQuery.sB != "")  SqlBindString(sql, "@b", strQuery.sB);
    if (strQuery.sBL != "") SqlBindString(sql, "@bl", strQuery.sBL);
    if (strQuery.sL != "")  SqlBindString(sql, "@l", strQuery.sL);

    int nTOC, nNumTOC = StringArray_Size(oAreaDataObject, AG_IGNORE_TOC_ARRAY), nBitmask;
    for (nTOC = 0; nTOC < nNumTOC; nTOC++)
    {
        string sTOC = StringArray_At(oAreaDataObject, AG_IGNORE_TOC_ARRAY, nTOC);

        if (bHasPath && sTOC == sPathCrosser)
            continue;

        nBitmask |= TS_GetTCBitflag(sTileset, sTOC);
    }
    nBitmask |= AG_Tile_GetIgnoreTOCBitmask(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
    SqlBindInt(sql, "@tocbitmask", nBitmask);

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

void AG_ProcessTile(string sAreaID, int nTile)
{
    if (AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile) != AG_INVALID_TILE_ID)
        return;

    int bTrySingleGroupTile = AG_Random(sAreaID, 100) < AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE);

    struct AG_Tile tile = AG_GetRandomMatchingTile(sAreaID, nTile, bTrySingleGroupTile);
    if (tile.nTileID == AG_INVALID_TILE_ID && bTrySingleGroupTile)
        tile = AG_GetRandomMatchingTile(sAreaID, nTile, FALSE);

    if (tile.nTileID == AG_INVALID_TILE_ID || !AG_ValidateCornerTile(sAreaID, nTile, tile))
        IntArray_Insert(AG_GetAreaDataObject(sAreaID), AG_FAILED_TILES_ARRAY, nTile);
    else
        AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, tile.nTileID, tile.nOrientation, tile.nHeight);

    EFCore_ResetScriptInstructions();
}

void AG_GenerateTiles(string sAreaID, int nCurrentTile = 0, int nNumTiles = 0)
{
    //Profiler_Start("AG_GenerateTiles: " + sAreaID);

    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);

    if (nNumTiles == 0)
    {
        nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
        IntArray_Clear(oAreaDataObject, AG_FAILED_TILES_ARRAY, TRUE);
    }

    if (nCurrentTile == nNumTiles)
    {
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS) + 1);
        AG_GenerateArea(sAreaID);
        //Profiler_Stop();
        return;
    }

    int nGenerationType = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE);
    int nCurrentMaxTiles = min(nCurrentTile + AG_GENERATION_TILE_BATCH, nNumTiles);

    //PrintString("nCurrentMaxTiles: " + IntToString(nCurrentTile) + " nCurrentMaxTiles: " + IntToString(nCurrentMaxTiles));

    switch (nGenerationType)
    {
        case AG_GENERATION_TYPE_SPIRAL_INWARD:
        case AG_GENERATION_TYPE_ALTERNATING_ROWS_INWARD:
        case AG_GENERATION_TYPE_ALTERNATING_COLUMNS_INWARD:
        {
            for (nCurrentTile; nCurrentTile < nCurrentMaxTiles; nCurrentTile++)
            {
                AG_ProcessTile(sAreaID, IntArray_At(oAreaDataObject, AG_GENERATION_TILE_ARRAY, nCurrentTile));
            }
            break;
        }

        case AG_GENERATION_TYPE_SPIRAL_OUTWARD:
        case AG_GENERATION_TYPE_ALTERNATING_ROWS_OUTWARD:
        case AG_GENERATION_TYPE_ALTERNATING_COLUMNS_OUTWARD:
        {
            for (nCurrentTile; nCurrentTile < nCurrentMaxTiles; nCurrentTile++)
            {
                AG_ProcessTile(sAreaID, IntArray_At(oAreaDataObject, AG_GENERATION_TILE_ARRAY, (nNumTiles - 1) - nCurrentTile));
            }
            break;
        }

        case AG_GENERATION_TYPE_LINEAR_ASCENDING:
        {
            for (nCurrentTile; nCurrentTile < nCurrentMaxTiles; nCurrentTile++)
            {
                AG_ProcessTile(sAreaID, nCurrentTile);
            }
            break;
        }

        case AG_GENERATION_TYPE_LINEAR_DESCENDING:
        {
            for (nCurrentTile; nCurrentTile < nCurrentMaxTiles; nCurrentTile++)
            {
                AG_ProcessTile(sAreaID, (nNumTiles - 1) - nCurrentTile);
            }
            break;
        }
    }

    DelayCommand(AG_GENERATION_DELAY, AG_GenerateTiles(sAreaID, nCurrentTile, nNumTiles));

    //Profiler_Stop();
}

void AG_GenerateGenerationTileArray(string sAreaID)
{
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    int nGenerationType = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE);
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);

    IntArray_Clear(oAreaDataObject, AG_GENERATION_TILE_ARRAY, TRUE);

    switch(nGenerationType)
    {
        case AG_GENERATION_TYPE_SPIRAL_INWARD:
        case AG_GENERATION_TYPE_SPIRAL_OUTWARD:
        {
            int nCurrentWidth = nWidth, nCurrentHeight = nHeight;
            int nCount, nCurrentRow, nCurrentColumn;

            while (nCurrentRow < nWidth && nCurrentColumn < nHeight)
            {
                for (nCount = nCurrentColumn; nCount < nCurrentHeight; nCount++)
                {
                    IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, nCurrentRow + (nCount * nWidth));
                }
                nCurrentRow++;

                for (nCount = nCurrentRow; nCount < nCurrentWidth; ++nCount)
                {
                    IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, nCount + ((nCurrentHeight - 1) * nWidth));
                }
                nCurrentHeight--;

                if (nCurrentRow < nCurrentWidth)
                {
                    for (nCount = nCurrentHeight - 1; nCount >= nCurrentColumn; --nCount)
                    {
                        IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, (nCurrentWidth - 1) + (nCount * nWidth));
                    }
                    nCurrentWidth--;
                }

                if (nCurrentColumn < nCurrentHeight)
                {
                    for (nCount = nCurrentWidth - 1; nCount >= nCurrentRow; --nCount)
                    {
                        IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, nCount + (nCurrentColumn * nWidth));
                    }
                    nCurrentColumn++;
                }
            }
            break;
        }

        case AG_GENERATION_TYPE_ALTERNATING_ROWS_INWARD:
        case AG_GENERATION_TYPE_ALTERNATING_ROWS_OUTWARD:
        {
            int nCurrentHeight, nMiddle = nHeight / 2;
            while (nCurrentHeight < nMiddle)
            {
                int nFront = nCurrentHeight;
                int nBack = nHeight - (nCurrentHeight + 1);

                int nTile;
                for (nTile = 0; nTile < nWidth; nTile++)
                {
                    IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, (nFront * nWidth) + nTile);
                }

                for (nTile = 0; nTile < nWidth; nTile++)
                {
                    IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, (nBack * nWidth) + nTile);
                }

                if ((nHeight % 2) && nCurrentHeight == (nMiddle - 1))
                {
                    for (nTile = 0; nTile < nWidth; nTile++)
                    {
                        IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, ((nBack - 1) * nWidth) + nTile);
                    }
                }

                nCurrentHeight++;
            }

            break;
        }

        case AG_GENERATION_TYPE_ALTERNATING_COLUMNS_INWARD:
        case AG_GENERATION_TYPE_ALTERNATING_COLUMNS_OUTWARD:
        {
            int nCurrentWidth, nMiddle = (nWidth / 2);
            while (nCurrentWidth < nMiddle)
            {
                int nFront = nCurrentWidth;
                int nBack = nWidth - (nCurrentWidth + 1);

                int nTile;
                for (nTile = 0; nTile < nHeight; nTile++)
                {
                    IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, nFront + (nWidth * nTile));
                }

                for (nTile = 0; nTile < nHeight; nTile++)
                {
                    IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, nBack + (nWidth * nTile));
                }

                if ((nWidth % 2) && nCurrentWidth == (nMiddle - 1))
                {
                    for (nTile = 0; nTile < nHeight; nTile++)
                    {
                        IntArray_Insert(oAreaDataObject, AG_GENERATION_TILE_ARRAY, (nBack - 1) + (nWidth * nTile));
                    }
                }

                nCurrentWidth++;
            }
            break;
        }
    }
}

void AG_GenerateArea(string sAreaID)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED))
    {
        if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS))
        {
            LogInfo("Finished Generating Area: " + sAreaID);
            LogInfo("> Result: " + (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED) ? "FAILURE" : "Success") +
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

        //PrintString("ITERATION: " + IntToString(nIteration) + " " + sAreaID);

        if (!nIteration)
        {
            if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS))
            {
                LogInfo("Generating Area: " + sAreaID);
                LogInfo("> Tileset: " + AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET) +
                         ", Width: " + IntToString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH)) +
                         ", Height: " + IntToString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT)));
                LogInfo("> Generation Type: " + AG_GetGenerationTypeAsString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE)));
            }

            object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
            json jIgnoredTOCArray = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC);
            int nTOC, nNumTOC = JsonGetLength(jIgnoredTOCArray);
            for (nTOC = 0; nTOC < nNumTOC; nTOC++)
            {
                StringArray_Insert(oAreaDataObject, AG_IGNORE_TOC_ARRAY, JsonArrayGetString(jIgnoredTOCArray, nTOC));
            }

            AG_GenerateGenerationTileArray(sAreaID);
            DelayCommand(AG_GENERATION_DELAY, AG_GenerateTiles(sAreaID));
        }
        else if (nIteration < AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_MAX_ITERATIONS))
        {
            object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
            int nTileFailure, nNumTileFailures = IntArray_Size(oAreaDataObject, AG_FAILED_TILES_ARRAY);
            if (nNumTileFailures)
            {
                for (nTileFailure = 0; nTileFailure < nNumTileFailures; nTileFailure++)
                {
                    AG_ResetNeighborTiles(sAreaID, IntArray_At(oAreaDataObject, AG_FAILED_TILES_ARRAY, nTileFailure));
                }

                DelayCommand(AG_GENERATION_DELAY, AG_GenerateTiles(sAreaID, 0, 0));
            }
            else
            {
                AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, TRUE);
                DelayCommand(AG_GENERATION_DELAY, AG_GenerateArea(sAreaID));
            }
        }
        else
        {
            AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED, TRUE);
            AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, TRUE);
            DelayCommand(AG_GENERATION_DELAY, AG_GenerateArea(sAreaID));
        }
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

int AG_GetRandomOtherEdge(string sAreaID, int nEdgeToSkip)
{
    int nEdge;
    do nEdge = AG_Random(sAreaID, 4);
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
        LogWarning("Unknown tile: " + sTileset + "(" + IntToString(nTileID) + ")");

    return -1;
}

void AG_CreatePathEntranceDoorTile(string sAreaID, int nTile, int nHeight)
{
    int nEdge = AG_GetEdgeFromTile(sAreaID, nTile);
    int nPathDoorTileID = AG_GetAreaPathDoor(sAreaID);
    int nOrientation = AG_GetTileOrientationFromEdge(sAreaID, nEdge, nPathDoorTileID);

    AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, nPathDoorTileID, nOrientation, nHeight, TRUE);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX, nTile);
}

void AG_CreatePathExitDoorTile(string sAreaID)
{
    int nEntranceTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);
    int nEntranceEdge = AG_GetEdgeFromTile(sAreaID, nEntranceTile);
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    int nExitEdge = AG_GetRandomOtherEdge(sAreaID, nEntranceEdge);
    int nPathDoorTileID = AG_GetAreaPathDoor(sAreaID);
    int nOrientation = AG_GetTileOrientationFromEdge(sAreaID, nExitEdge, nPathDoorTileID);
    int nExitTile, nRandom;

    if (nExitEdge == AG_AREA_EDGE_TOP)
    {
        nRandom = min((nWidth / 4) + AG_Random(sAreaID, (nWidth / 2) + 1), nWidth - 2);
        nExitTile = (nWidth * (nHeight - 1)) + nRandom;
    }
    else if (nExitEdge == AG_AREA_EDGE_RIGHT)
    {
        nRandom = min((nHeight / 4) + AG_Random(sAreaID, (nHeight / 2) + 1), nHeight - 2);
        nExitTile = (nWidth - 1) + (nRandom * nWidth);
    }
    else if (nExitEdge == AG_AREA_EDGE_BOTTOM)
    {
        nRandom = min((nWidth / 4) + AG_Random(sAreaID, (nWidth / 2) + 1), nWidth - 2);
        nExitTile = nRandom;
    }
    else if (nExitEdge == AG_AREA_EDGE_LEFT)
    {
        nRandom = min((nHeight / 4) + AG_Random(sAreaID, (nHeight / 2) + 1), nHeight - 2);
        nExitTile = nRandom * nWidth;
    }

    int nExitHeight = clamp(AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_TILES, nEntranceTile) + (AG_Random(sAreaID, 3) - 1), 0, TS_MAX_TILE_HEIGHT - 1);
    AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nExitTile, nPathDoorTileID, nOrientation, nExitHeight, TRUE);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX, nExitTile);
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
            LogError("Area Width does not match!");
            return;
        }
    }
    else if (nEdgeToCopy == AG_AREA_EDGE_LEFT || nEdgeToCopy == AG_AREA_EDGE_RIGHT)
    {
        if (nHeight != nOtherHeight)
        {
            LogError("Area Height does not match!");
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
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, nCount, str.nID, str.nOrientation, str.nHeight);

                int nTileIndex = nCount;
                if (AG_GetIsPathDoor(sAreaID, str.nID))
                {
                    AG_CreatePathEntranceDoorTile(sAreaID, nTileIndex, str.nHeight);
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
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, nCount, str.nID, str.nOrientation, str.nHeight);

                int nTileIndex = nCount * nWidth;
                if (AG_GetIsPathDoor(sAreaID, str.nID))
                {
                    AG_CreatePathEntranceDoorTile(sAreaID, nTileIndex, str.nHeight);
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
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, nCount, str.nID, str.nOrientation, str.nHeight);

                int nTileIndex = (nOtherWidth * (nHeight - 1)) + nCount;
                if (AG_GetIsPathDoor(sAreaID, str.nID))
                {
                    AG_CreatePathEntranceDoorTile(sAreaID, nTileIndex, str.nHeight);
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
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, nCount, str.nID, str.nOrientation, str.nHeight);

                int nTileIndex = (nWidth - 1) + (nCount * nWidth);
                if (AG_GetIsPathDoor(sAreaID, str.nID))
                {
                    AG_CreatePathEntranceDoorTile(sAreaID, nTileIndex, str.nHeight);
                    AG_CreatePathExitDoorTile(sAreaID);
                }
            }
            break;
        }
    }
}

void AG_ExtractExitEdgeTerrains(string sAreaID)
{
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);
    int nExitTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    int nExitEdge = AG_GetEdgeFromTile(sAreaID, nExitTile);

    json jExitEdgeTerrains = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS);

    switch (nExitEdge)
    {
        case AG_AREA_EDGE_TOP:
        {
            int nStart = nWidth * (nHeight - 1);
            int nCount, nNumTiles = nWidth;
            for (nCount = 0; nCount < nNumTiles; nCount++)
            {
                int nTile = nStart + nCount;
                int nTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
                int nOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
                struct TS_TileStruct strTC = TS_GetCornersAndEdgesByOrientation(sTileset, nTileID, nOrientation);

                jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, TS_StripHeightIndicator(strTC.sTL));
                jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, TS_StripHeightIndicator(strTC.sTR));
            }
            break;
        }

        case AG_AREA_EDGE_RIGHT:
        {
            int nStart = nWidth - 1;
            int nCount, nNumTiles = nHeight;
            for (nCount = 0; nCount < nNumTiles; nCount++)
            {
                int nTile = nStart + (nCount * nWidth);
                int nTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
                int nOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
                struct TS_TileStruct strTC = TS_GetCornersAndEdgesByOrientation(sTileset, nTileID, nOrientation);

                jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, TS_StripHeightIndicator(strTC.sTR));
                jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, TS_StripHeightIndicator(strTC.sBR));
            }
            break;
        }

        case AG_AREA_EDGE_BOTTOM:
        {
            int nStart = 0;
            int nCount, nNumTiles = nWidth;
            for (nCount = 0; nCount < nNumTiles; nCount++)
            {
                int nTile = nStart + nCount;
                int nTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
                int nOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
                struct TS_TileStruct strTC = TS_GetCornersAndEdgesByOrientation(sTileset, nTileID, nOrientation);

                jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, TS_StripHeightIndicator(strTC.sBL));
                jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, TS_StripHeightIndicator(strTC.sBR));
            }
            break;
        }

        case AG_AREA_EDGE_LEFT:
        {
            int nStart = 0;
            int nCount, nNumTiles = nHeight;
            for (nCount = 0; nCount < nNumTiles; nCount++)
            {
                int nTile = nStart + (nCount * nWidth);
                int nTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
                int nOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
                struct TS_TileStruct strTC = TS_GetCornersAndEdgesByOrientation(sTileset, nTileID, nOrientation);

                jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, TS_StripHeightIndicator(strTC.sTL));
                jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, TS_StripHeightIndicator(strTC.sBL));
            }
            break;
        }
    }

    AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS, jExitEdgeTerrains);

    //PrintString("Exit Terrain: " + JsonDump(jExitEdgeTerrains));
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

struct TS_TileStruct AG_GetRoadTileStruct(string sAreaID, int nX1, int nY1, int nX2, int nY2)
{
    string sRoadCrosser = AG_GetAreaPathCrosserType(sAreaID);
    struct TS_TileStruct str;

    if ((nX1 == 0 && nY1 == -1) || (nX2 == 0 && nY2 == -1))
        str.sT = sRoadCrosser;
    if ((nX1 == -1 && nY1 == 0) || (nX2 == -1 && nY2 == 0))
        str.sR = sRoadCrosser;
    if ((nX1 == 0 && nY1 == 1) || (nX2 == 0 && nY2 == 1))
        str.sB = sRoadCrosser;
    if ((nX1 == 1 && nY1 == 0) || (nX2 == 1 && nY2 == 0))
        str.sL = sRoadCrosser;

    return str;
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

        struct TS_TileStruct strQuery = AG_GetRoadTileStruct(sAreaID, nPreviousDiffX, nPreviousDiffY, nNextDiffX, nNextDiffY);
        AG_SetTileOverride(sAreaID, (nCurrentX + (nCurrentY * nWidth)), strQuery);

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

                if (nEdgeTerrainChangeChance == 100 || AG_Random(sAreaID, 100) < nEdgeTerrainChangeChance)
                    sTC3 = JsonArrayGetString(jUsableEdgeTerrains, AG_Random(sAreaID, nNumUsableEdgeTerrains));
                else
                    sTC3 = sTC1;
            }
        }

        if (bHasExit)
        {
            json jExitEdgeTerrains = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS);

            jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, sTC1);
            jExitEdgeTerrains = JsonArrayInsertUniqueString(jExitEdgeTerrains, sTC3);

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
    int nTile = AG_Random(sAreaID, nNumTiles);
    int nEdge = AG_GetEdgeFromTile(sAreaID, nTile);
    int nOrientation = nEdge == -1 ? AG_Random(sAreaID, 4) : AG_GetTileOrientationFromEdge(sAreaID, nEdge, nEntranceTileID);

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

int AG_Random(string sAreaID, int nMaxInteger)
{
    if (SQL_ENABLE_MERSENNE_TWISTER && AG_ENABLE_SEEDED_RANDOM)
    {
        string sRandomName = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_GENERATION_RANDOM_NAME);
        return sRandomName == "" ? Random(nMaxInteger) : SqlMersenneTwisterGetValue(sRandomName, nMaxInteger);
    }
    else
    {
        return Random(nMaxInteger);
    }
}

string AG_GetRandomQueryString(string sAreaID)
{
    if (SQL_ENABLE_MERSENNE_TWISTER && AG_ENABLE_SEEDED_RANDOM)
    {
        string sRandomName = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_GENERATION_RANDOM_NAME);
        return sRandomName == "" ? "RANDOM()" : "MT_VALUE('" + sRandomName + "')";
    }
    else
    {
        return "RANDOM()";
    }
}

json AG_GetSetTileTileObject(int nIndex, int nTileID, int nOrientation, int nHeight)
{
    json jTile = JsonObject();
         jTile = JsonObjectSetInt(jTile, "index", nIndex);
         jTile = JsonObjectSetInt(jTile, "tileid", nTileID);
         jTile = JsonObjectSetInt(jTile, "orientation", nOrientation);
         jTile = JsonObjectSetInt(jTile, "height", nHeight);
    return jTile;
}

string AG_GetGenerationTypeAsString(int nGenerationType)
{
    switch (nGenerationType)
    {
        case AG_GENERATION_TYPE_SPIRAL_INWARD: return "SPIRAL_INWARD";
        case AG_GENERATION_TYPE_SPIRAL_OUTWARD: return "SPIRAL_OUTWARD";
        case AG_GENERATION_TYPE_LINEAR_ASCENDING: return "LINEAR_ASCENDING";
        case AG_GENERATION_TYPE_LINEAR_DESCENDING: return "LINEAR_DESCENDING";
        case AG_GENERATION_TYPE_ALTERNATING_ROWS_INWARD: return "ALTERNATING_ROWS_INWARD";
        case AG_GENERATION_TYPE_ALTERNATING_ROWS_OUTWARD: return "ALTERNATING_ROWS_OUTWARD";
        case AG_GENERATION_TYPE_ALTERNATING_COLUMNS_INWARD: return "ALTERNATING_COLUMNS_INWARD";
        case AG_GENERATION_TYPE_ALTERNATING_COLUMNS_OUTWARD: return "ALTERNATING_COLUMNS_OUTWARD";
    }
    return "ERROR";
}

int AG_GetChunkIndexFromTile(string sAreaID, int nTile)
{
    int nAreaWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nChunkSize = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_CHUNK_SIZE);
    return (((nTile / nAreaWidth) / nChunkSize) * (nAreaWidth / nChunkSize)) + ((nTile % nAreaWidth) / nChunkSize);
}

void AG_SetChunkArray(string sAreaID, int nChunk, json jArray)
{
    SetLocalJson(AG_GetAreaDataObject(sAreaID), AG_DATA_KEY_CHUNK_ARRAY + IntToString(nChunk), jArray);
}

json AG_GetChunkArray(string sAreaID, int nChunk)
{
    return GetLocalJson(AG_GetAreaDataObject(sAreaID), AG_DATA_KEY_CHUNK_ARRAY + IntToString(nChunk));
}

void AG_InsertTileToChunk(string sAreaID, int nChunk, int nTile)
{
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    json jChunkArray = GetLocalJson(oAreaDataObject, AG_DATA_KEY_CHUNK_ARRAY + IntToString(nChunk));
         jChunkArray = JsonArrayInsertInt(jChunkArray, nTile);
    SetLocalJson(oAreaDataObject, AG_DATA_KEY_CHUNK_ARRAY + IntToString(nChunk), jChunkArray);
}

void AG_InitializeAreaChunks(string sAreaID, int nChunkSize)
{
    int nAreaWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nAreaHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);

    if (nAreaWidth != nAreaHeight || (nAreaWidth % nChunkSize) != 0)
    {
        LogError("AG_InitializeChunks: nAreaWidth != nHeight || (nAreaWidth % nChunkSize) != 0");
        return;
    }

    int nChunk, nNumChunks = (nAreaWidth / nChunkSize) * (nAreaHeight / nChunkSize);
    for (nChunk = 0; nChunk < nNumChunks; nChunk++)
    {
        AG_SetChunkArray(sAreaID, nChunk, JsonArray());
    }

    int nTileX, nTileY;
    for (nTileY = 0; nTileY < nAreaHeight; nTileY++)
    {
        for (nTileX = 0; nTileX < nAreaWidth; nTileX++)
        {
            AG_InsertTileToChunk(sAreaID, ((nTileY / nChunkSize) * (nAreaWidth / nChunkSize)) + (nTileX / nChunkSize), (nTileY * nAreaWidth) + nTileX);
        }
    }

    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_CHUNK_SIZE, nChunkSize);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_CHUNK_AMOUNT, nNumChunks);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_CHUNK_NUM_TILES, nChunkSize * nChunkSize);
}

void AG_LockChunkTiles(string sAreaID, int nChunk)
{
    json jChunkArray = AG_GetChunkArray(sAreaID, nChunk);
    int nTile, nNumTiles = JsonGetLength(jChunkArray);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        AG_Tile_SetLocked(sAreaID, AG_DATA_KEY_ARRAY_TILES, JsonArrayGetInt(jChunkArray, nTile), TRUE);
    }
}

void AG_ResetChunkTiles(string sAreaID, int nChunk)
{
    json jChunkArray = AG_GetChunkArray(sAreaID, nChunk);
    int nTile, nNumTiles = JsonGetLength(jChunkArray);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        AG_Tile_Reset(sAreaID, AG_DATA_KEY_ARRAY_TILES, JsonArrayGetInt(jChunkArray, nTile));
    }
}

void AG_GenerateTileChunk(string sAreaID, int nChunk, int nCurrentTile = 0, int nNumTiles = 0)
{
    //Profiler_Start("AG_GenerateTileChunk: " + sAreaID + "[" + IntToString(nChunk) + "]");

    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);

    if (nNumTiles == 0)
    {
        nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_CHUNK_NUM_TILES);
        IntArray_Clear(oAreaDataObject, AG_FAILED_TILES_ARRAY, TRUE);
    }

    if (nCurrentTile == nNumTiles)
    {
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS) + 1);
        AG_GenerateAreaChunk(sAreaID, nChunk);
        return;
    }

    int nCurrentMaxTiles = min(nCurrentTile + AG_GENERATION_TILE_BATCH, nNumTiles);
    json jChunkArray = AG_GetChunkArray(sAreaID, nChunk);

    for (nCurrentTile; nCurrentTile < nCurrentMaxTiles; nCurrentTile++)
    {
        AG_ProcessTile(sAreaID, JsonArrayGetInt(jChunkArray, nCurrentTile));
    }

    DelayCommand(AG_GENERATION_DELAY, AG_GenerateTileChunk(sAreaID, nChunk, nCurrentTile, nNumTiles));

    //Profiler_Stop();
}

void AG_GenerateAreaChunk(string sAreaID, int nChunk)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED) &&
        AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_CURRENT_CHUNK) != nChunk)
    {
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, FALSE);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED, FALSE);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS, 0);
    }

    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED))
    {
        if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS))
        {
            LogInfo("Finished Generating Area Chunk: " + sAreaID + "[" + IntToString(nChunk) + "]");
            LogInfo("> Result: " + (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED) ? "FAILURE" : "Success") +
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
                LogInfo("Generating Area Chunk: " + sAreaID + "[" + IntToString(nChunk) + "]");
                LogInfo("> Tileset: " + AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET) +
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

            AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_CURRENT_CHUNK, nChunk);
            DelayCommand(AG_GENERATION_DELAY, AG_GenerateTileChunk(sAreaID, nChunk));
        }
        else if (nIteration < AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_MAX_ITERATIONS))
        {
            object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
            int nTileFailure, nNumTileFailures = IntArray_Size(oAreaDataObject, AG_FAILED_TILES_ARRAY);
            if (nNumTileFailures)
            {
                for (nTileFailure = 0; nTileFailure < nNumTileFailures; nTileFailure++)
                {
                    AG_ResetNeighborTiles(sAreaID, IntArray_At(oAreaDataObject, AG_FAILED_TILES_ARRAY, nTileFailure));
                }

                DelayCommand(AG_GENERATION_DELAY, AG_GenerateTileChunk(sAreaID, nChunk));
            }
            else
            {
                AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, TRUE);
                DelayCommand(AG_GENERATION_DELAY, AG_GenerateAreaChunk(sAreaID, nChunk));
            }
        }
        else
        {
            AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED, TRUE);
            AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, TRUE);
            DelayCommand(AG_GENERATION_DELAY, AG_GenerateAreaChunk(sAreaID, nChunk));
        }
    }
}

void AG_InitializeChunkFromArea(string sAreaID, object oArea, int nChunk)
{
    json jChunk = AG_GetChunkArray(sAreaID, nChunk);
    int nCount, nNumTiles = JsonGetLength(jChunk);
    for (nCount = 0; nCount < nNumTiles; nCount++)
    {
        int nTileIndex = JsonArrayGetInt(jChunk, nCount);
        struct NWNX_Area_TileInfo str = NWNX_Area_GetTileInfoByTileIndex(oArea, nTileIndex);
        AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTileIndex, str.nID, str.nOrientation, str.nHeight, TRUE);
    }
}

int AG_CheckCornerTileTerrain(string sTerrain1, string sTerrain2, string sTerrain3)
{
    return ((sTerrain1 == "GRASS" || sTerrain1 == "TREES" || sTerrain1 == "MOUNTAIN") &&
            (sTerrain2 == "GRASS" || sTerrain2 == "TREES" || sTerrain2 == "MOUNTAIN") &&
            (sTerrain3 == "GRASS" || sTerrain3 == "TREES" || sTerrain3 == "MOUNTAIN")
           ) ||
           ((sTerrain1 == "WATER" && sTerrain2== "WATER" && sTerrain3 == "WATER") ||
            (sTerrain1 == "SAND" && sTerrain2 == "SAND" && sTerrain3 == "SAND") ||
            (sTerrain1 == "CHASM" && sTerrain2 == "CHASM" && sTerrain3 == "CHASM"));
}

int AG_ValidateCornerTile(string sAreaID, int nTile, struct AG_Tile strTile)
{
    if (!AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENABLE_CORNER_TILE_VALIDATOR))
        return TRUE;

    int bValid = TRUE;
    int nAreaWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nAreaHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    if (nTile == 0 || nTile == (nAreaWidth - 1) || nTile == (nAreaWidth * (nAreaHeight - 1)) || nTile == ((nAreaWidth * nAreaHeight) - 1))
    {
        string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);
        struct TS_TileStruct str = TS_GetCornersAndEdgesByOrientation(sTileset, strTile.nTileID, strTile.nOrientation);

        if (nTile == 0)
            bValid = AG_CheckCornerTileTerrain(str.sTL, str.sBR, str.sBL);
        else if (nTile == (nAreaWidth - 1))
            bValid = AG_CheckCornerTileTerrain(str.sTR, str.sBL, str.sBR);
        else if (nTile == (nAreaWidth * (nAreaHeight - 1)))
            bValid = AG_CheckCornerTileTerrain(str.sTR, str.sBL, str.sTL);
        else if (nTile == ((nAreaWidth * nAreaHeight) - 1))
            bValid = AG_CheckCornerTileTerrain(str.sTL, str.sBR, str.sTR);
    }

    return bValid;
}
