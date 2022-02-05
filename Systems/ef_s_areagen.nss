/*
    Script: ef_s_areagen
    Author: Daz

    Optimized for TILESET_RESREF_MEDIEVAL_RURAL_2
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_tileset"
#include "nwnx_area"

const string AG_LOG_TAG                                 = "AreaGenerator";
const string AG_SCRIPT_NAME                             = "ef_s_areagen";
const string AG_GENERATOR_DATAOBJECT                    = "AGDataObject";

const int AG_GENERATION_MAX_ITERATIONS                  = 100;
const float AG_GENERATION_DELAY                         = 0.1f;
const int AG_GENERATION_TILE_FAILURE_RESET_CHANCE       = 75;
const int AG_GENERATION_TILE_NEIGHBOR_RESET_CHANCE      = 50;

const int AG_INVALID_TILE_ID                            = -1;

const int AG_AREA_MIN_WIDTH                             = 1;
const int AG_AREA_MIN_HEIGHT                            = 1;
const int AG_AREA_MAX_WIDTH                             = 32;
const int AG_AREA_MAX_HEIGHT                            = 32;
const int AG_AREA_DEFAULT_WIDTH                         = 8;
const int AG_AREA_DEFAULT_HEIGHT                        = 8;

const string AG_DATA_KEY_AREA_ID                        = "AreaID";
const string AG_DATA_KEY_JSON_DATA                      = "JsonData";
const string AG_DATA_KEY_TILESET                        = "Tileset";
const string AG_DATA_KEY_DEFAULT_EDGE_TERRAIN           = "DefaultEdgeTerrain";
const string AG_DATA_KEY_WIDTH                          = "Width";
const string AG_DATA_KEY_HEIGHT                         = "Height";
const string AG_DATA_KEY_NUM_TILES                      = "NumTiles";
const string AG_DATA_KEY_ARRAY_TILES                    = "ArrayTiles";
const string AG_DATA_KEY_ARRAY_EDGE_TOP                 = "ArrayEdgeTop";
const string AG_DATA_KEY_ARRAY_EDGE_BOTTOM              = "ArrayEdgeBottom";
const string AG_DATA_KEY_ARRAY_EDGE_LEFT                = "ArrayEdgeLeft";
const string AG_DATA_KEY_ARRAY_EDGE_RIGHT               = "ArrayEdgeRight";
const string AG_DATA_KEY_IGNORE_TOC                     = "IgnoreTOC";
const string AG_DATA_KEY_TILE_OVERRIDE                  = "TileOverride_";
const string AG_DATA_KEY_GENERATION_ITERATIONS          = "GenerationIterations";
const string AG_DATA_KEY_GENERATION_FINISHED            = "GenerationFinished";
const string AG_DATA_KEY_GENERATION_FAILED              = "GenerationFailed";
const string AG_DATA_KEY_GENERATION_CALLBACK            = "GenerationCallback";
const string AG_DATA_KEY_GENERATION_LOG_STATUS          = "GenerationLogStatus";
const string AG_DATA_KEY_GENERATION_USE_OLD_WAY         = "GenerationOldWay";

const string AG_DATA_KEY_TILE_ID                        = "TileID";
const string AG_DATA_KEY_TILE_LOCKED                    = "Locked";
const string AG_DATA_KEY_TILE_ORIENTATION               = "Orientation";
const string AG_DATA_KEY_TILE_HEIGHT                    = "Height";

const string AG_DATA_KEY_ENTRANCE_TILE_INDEX            = "EntranceTileIndex";
const string AG_DATA_KEY_EXIT_TILE_INDEX                = "ExitTileIndex";
const string AG_DATA_KEY_PATH_NODES                     = "PathNodes";
const string AG_DATA_KEY_PATH_NO_ROAD_CHANCE            = "PathNoRoadChance";
const string AG_DATA_KEY_EXIT_EDGE_HAS_WATER            = "AreaExitEdgeHasWater";
const string AG_DATA_KEY_EXIT_EDGE_HAS_MOUNTAIN         = "AreaExitEdgeHasMountain";
const string AG_DATA_KEY_AREA_PATH_DOOR_CROSSER_COMBO   = "AreaPathDoorCrosserCombo";
const string AG_DATA_KEY_NUM_PATH_DOOR_CROSSER_COMBOS   = "PathDoorCrosserCombos";
const string AG_DATA_KEY_PATH_DOOR_ID                   = "PathDoorId_";
const string AG_DATA_KEY_PATH_CROSSER_TYPE              = "PathCrosserType_";

const int AG_NEIGHBOR_TILE_TOP_LEFT                     = 0;
const int AG_NEIGHBOR_TILE_TOP                          = 1;
const int AG_NEIGHBOR_TILE_TOP_RIGHT                    = 2;
const int AG_NEIGHBOR_TILE_RIGHT                        = 3;
const int AG_NEIGHBOR_TILE_BOTTOM_RIGHT                 = 4;
const int AG_NEIGHBOR_TILE_BOTTOM                       = 5;
const int AG_NEIGHBOR_TILE_BOTTOM_LEFT                  = 6;
const int AG_NEIGHBOR_TILE_LEFT                         = 7;
const int AG_NEIGHBOR_TILE_MAX                          = 8;

const int AG_AREA_EDGE_TOP                              = 0;
const int AG_AREA_EDGE_RIGHT                            = 1;
const int AG_AREA_EDGE_BOTTOM                           = 2;
const int AG_AREA_EDGE_LEFT                             = 3;

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
void AG_Tile_Set(string sAreaID, string sTileArray, int nTile, int nID, int nOrientation, int bLocked = FALSE, int nHeight = 0);
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
struct AG_Tile AG_GetRandomMatchingTile(string sAreaID, int nTile);
json AG_GenerateRandomTiles(string sAreaID);
json AG_ProcessTile(string sAreaID, json jArray, int nWidth, int nX, int nY);
json AG_GenerateRandomTilesInSpiral(string sAreaID);
void AG_GenerateArea(string sAreaID);
int AG_GetEdgeFromTile(string sAreaID, int nTile);
int AG_GetRandomOtherEdge(int nEdgeToSkip);
int AG_GetDoorOrientationFromEdge(string sAreaID, int nEdge, int nDoorTileID);
void AG_CreatePathEntranceDoorTile(string sAreaID, int nTile);
void AG_CreatePathExitDoorTile(string sAreaID);
void AG_CopyEdgeFromArea(string sAreaID, object oArea, int nEdgeToCopy);
int AG_GetNextTile(int nAreaWidth, int nTile, int nEdge);
struct TS_TileStruct AG_GetRoadTileStruct(string sAreaID, int nPoint, int nNumPoints, int nX1, int nY1, int nX2, int nY2, int bNoRoad);
struct AG_Tile AG_GetRandomRoadTile(string sAreaID, struct TS_TileStruct strQuery);
void AG_PlotRoad(string sAreaID);
void AG_GenerateEdge(string sAreaID, int nEdge);
int AG_GetNumPathDoorCrosserCombos(string sAreaID);
void AG_AddPathDoorCrosserCombo(string sAreaID, int nDoorTile, string sCrosser);
int AG_GetPathDoorID(string sAreaID, int nNum);
string AG_GetPathCrosserType(string sAreaID, int nNum);
int AG_GetIsPathDoor(string sAreaID, int nTileID);
void AG_SetAreaPathDoorCrosserCombo(string sAreaID, int nNum);
int AG_GetAreaPathDoor(string sAreaID);
string AG_GetAreaPathCrosserType(string sAreaID);

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

        if (JsonGetType(jFind))
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

void AG_Tile_Set(string sAreaID, string sTileArray, int nTile, int nID, int nOrientation, int bLocked = FALSE, int nHeight = 0)
{
    AG_Tile_SetID(sAreaID, sTileArray, nTile, nID);
    AG_Tile_SetOrientation(sAreaID, sTileArray, nTile, nOrientation);
    AG_Tile_SetLocked(sAreaID, sTileArray, nTile, bLocked);
    AG_Tile_SetHeight(sAreaID, sTileArray, nTile, nHeight);
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
    AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_DEFAULT_EDGE_TERRAIN, sEdgeTerrain);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH, nWidth);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT, nHeight);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES, nWidth * nHeight);
    AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC, JsonArray());

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
    }
    else
    {
        int nAreaWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
        int AreaHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
        int nTileX = nTile % nAreaWidth;
        int nTileY = nTile / nAreaWidth;

        switch (nDirection)
        {
            case AG_NEIGHBOR_TILE_TOP:
            {
                int nEdgeTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, nTileX);
                if (nEdgeTileID != AG_INVALID_TILE_ID)
                {
                    int nEdgeOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, nTileX);
                    str = TS_GetCornersAndEdgesByOrientation(sTileset, nEdgeTileID, nEdgeOrientation);
                }
                else if (AG_GetHasEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, nTileX))
                {
                    struct AG_EdgeTileOverride strEdge = AG_GetEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, nTileX);
                    str.sBL = strEdge.sTC1;
                    str.sB = strEdge.sTC2;
                    str.sBR = strEdge.sTC3;
                }
                else
                {
                    string sEdgeTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_DEFAULT_EDGE_TERRAIN);
                    str.sBL = sEdgeTerrain;
                    str.sB = sEdgeTerrain;
                    str.sBR = sEdgeTerrain;
                }
                break;
            }

            case AG_NEIGHBOR_TILE_RIGHT:
            {
                int nEdgeTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, nTileY);
                if (nEdgeTileID != AG_INVALID_TILE_ID)
                {
                    int nEdgeOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, nTileY);
                    str = TS_GetCornersAndEdgesByOrientation(sTileset, nEdgeTileID, nEdgeOrientation);
                }
                else if (AG_GetHasEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, nTileY))
                {
                    struct AG_EdgeTileOverride strEdge = AG_GetEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, nTileY);
                    str.sTL = strEdge.sTC3;
                    str.sL = strEdge.sTC2;
                    str.sBL = strEdge.sTC1;
                }
                else
                {
                    string sEdgeTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_DEFAULT_EDGE_TERRAIN);
                    str.sTL = sEdgeTerrain;
                    str.sL = sEdgeTerrain;
                    str.sBL = sEdgeTerrain;
                }
                break;
            }

            case AG_NEIGHBOR_TILE_BOTTOM:
            {
                int nEdgeTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, nTileX);
                if (nEdgeTileID != AG_INVALID_TILE_ID)
                {
                    int nEdgeOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, nTileX);
                    str = TS_GetCornersAndEdgesByOrientation(sTileset, nEdgeTileID, nEdgeOrientation);
                }
                else if (AG_GetHasEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, nTileX))
                {
                    struct AG_EdgeTileOverride strEdge = AG_GetEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, nTileX);
                    str.sTL = strEdge.sTC1;
                    str.sT = strEdge.sTC2;
                    str.sTR = strEdge.sTC3;
                }
                else
                {
                    string sEdgeTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_DEFAULT_EDGE_TERRAIN);
                    str.sTL = sEdgeTerrain;
                    str.sT = sEdgeTerrain;
                    str.sTR = sEdgeTerrain;
                }
                break;
            }

            case AG_NEIGHBOR_TILE_LEFT:
            {
                int nEdgeTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, nTileY);
                if (nEdgeTileID != AG_INVALID_TILE_ID)
                {
                    int nEdgeOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, nTileY);
                    str = TS_GetCornersAndEdgesByOrientation(sTileset, nEdgeTileID, nEdgeOrientation);
                }
                else if (AG_GetHasEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, nTileY))
                {
                    struct AG_EdgeTileOverride strEdge = AG_GetEdgeTileOverride(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, nTileY);
                    str.sTR = strEdge.sTC3;
                    str.sR = strEdge.sTC2;
                    str.sBR = strEdge.sTC1;
                }
                else
                {
                    string sEdgeTerrain = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_DEFAULT_EDGE_TERRAIN);
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

struct AG_Tile AG_GetRandomMatchingTile(string sAreaID, int nTile)
{
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

    string sQuery = "SELECT tile_id, orientation FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) + " WHERE is_group_tile=0 " +
                    AG_SqlConstructCAEClause(strQuery);

    json jIgnoredTOCArray = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_IGNORE_TOC);
    int nTOC, nNumTOC = JsonGetLength(jIgnoredTOCArray);
    for (nTOC = 0; nTOC < nNumTOC; nTOC++)
    {
        string sTOC = JsonArrayGetString(jIgnoredTOCArray, nTOC);

        if (sTOC == sRoadCrosser && bHasRoad)
            continue;

        sQuery += "AND corners_and_edges NOT LIKE @" + sTOC + " ";
    }

    sQuery += " ORDER BY RANDOM() LIMIT 1;";

    sqlquery sql = TS_PrepareQuery(sQuery);

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
        string sTOC = JsonArrayGetString(jIgnoredTOCArray, nTOC);

        if (sTOC == sRoadCrosser && bHasRoad)
            continue;

        SqlBindString(sql, "@" + sTOC, "%" + sTOC + "%");
    }

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

json AG_GenerateRandomTiles(string sAreaID)
{
    json jMatchFailures = JsonArray();
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);

    int nTile, nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        if (AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile) != AG_INVALID_TILE_ID)
            continue;

        struct AG_Tile tile = AG_GetRandomMatchingTile(sAreaID, nTile);

        if (tile.nTileID != AG_INVALID_TILE_ID)
        {
            AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, tile.nTileID, tile.nOrientation);
        }
        else
        {
            jMatchFailures = JsonArrayInsertInt(jMatchFailures, nTile);
        }

        NWNX_Util_SetInstructionsExecuted(0);
    }

    return jMatchFailures;
}


json AG_ProcessTile(string sAreaID, json jArray, int nWidth, int nX, int nY)
{
    int nTile = nX + (nY * nWidth);

    if (AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile) != AG_INVALID_TILE_ID)
        return jArray;

    struct AG_Tile tile = AG_GetRandomMatchingTile(sAreaID, nTile);

    if (tile.nTileID != AG_INVALID_TILE_ID)
        AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, tile.nTileID, tile.nOrientation);
    else
        jArray = JsonArrayInsertInt(jArray, nTile);

    NWNX_Util_SetInstructionsExecuted(0);

    return jArray;
}

json AG_GenerateRandomTilesInSpiral(string sAreaID)
{
    json jMatchFailures = JsonArray();
    int nWidth = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
    int nHeight = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
    int nCurrentWidth = nWidth, nCurrentHeight = nHeight;
    int nCount, nCurrentRow, nCurrentColumn;

    while (nCurrentRow < nWidth && nCurrentColumn < nHeight)
    {
        for (nCount = nCurrentColumn; nCount < nCurrentHeight; nCount++)
        {
            jMatchFailures = AG_ProcessTile(sAreaID, jMatchFailures, nWidth, nCurrentRow, nCount);
        }
        nCurrentRow++;

        for (nCount = nCurrentRow; nCount < nCurrentWidth; ++nCount)
        {
            jMatchFailures = AG_ProcessTile(sAreaID, jMatchFailures, nWidth, nCount, nCurrentHeight - 1);
        }
        nCurrentHeight--;

        if (nCurrentRow < nCurrentWidth)
        {
            for (nCount = nCurrentHeight - 1; nCount >= nCurrentColumn; --nCount)
            {
                jMatchFailures = AG_ProcessTile(sAreaID, jMatchFailures, nWidth, nCurrentWidth - 1, nCount);
            }
            nCurrentWidth--;
        }

        if (nCurrentColumn < nCurrentHeight)
        {
            for (nCount = nCurrentWidth - 1; nCount >= nCurrentRow; --nCount)
            {
                jMatchFailures = AG_ProcessTile(sAreaID, jMatchFailures, nWidth, nCount, nCurrentColumn);
            }
            nCurrentColumn++;
        }
    }

    return jMatchFailures;
}

void AG_GenerateArea(string sAreaID)
{
    int bFinished = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED);

    if (bFinished)
    {
        if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS))
        {
            WriteLog(AG_LOG_TAG, "* Finished Generating Area: " + sAreaID);
            WriteLog(AG_LOG_TAG, "  > Result: " + (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED) ? "Failure" : "Success") +
                                 ", Iterations: " + IntToString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS)));
        }
        string sCallback = AG_GetCallbackFunction(sAreaID);
        if (sCallback != "")
        {
            ExecuteCachedScriptChunk(sCallback, GetModule(), FALSE);
        }
    }
    else
    {
        int nIteration = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS);

        if (!nIteration)
        {
            if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS))
            {
                WriteLog(AG_LOG_TAG, "* Generating Area: " + sAreaID);
                WriteLog(AG_LOG_TAG, "  > Tileset: " + AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET) +
                                     ", Width: " + IntToString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH)) +
                                     ", Height: " + IntToString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT)));
            }
        }

        if (nIteration < AG_GENERATION_MAX_ITERATIONS)
        {
            json jMatchFailures;

            if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_USE_OLD_WAY))
                jMatchFailures = AG_GenerateRandomTiles(sAreaID);
            else
                jMatchFailures = AG_GenerateRandomTilesInSpiral(sAreaID);

            int nTileFailure, nNumTileFailures = JsonGetLength(jMatchFailures);

            if (nNumTileFailures)
            {
                int nTileFailureIndex;
                for (nTileFailure = 0; nTileFailure < nNumTileFailures; nTileFailure++)
                {
                    if (AG_GENERATION_TILE_FAILURE_RESET_CHANCE == 100 || Random(100) < AG_GENERATION_TILE_FAILURE_RESET_CHANCE)
                        AG_ResetNeighborTiles(sAreaID, JsonArrayGetInt(jMatchFailures, nTileFailure));
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

int AG_GetDoorOrientationFromEdge(string sAreaID, int nEdge, int nDoorTileID)
{
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);

    if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2 && (nDoorTileID == 80 || nDoorTileID == 1161))
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
    else
        WriteLog(AG_LOG_TAG, "* AG_GetDoorOrientationFromEdge: unknown door tile: " + sTileset + "(" + IntToString(nDoorTileID) + ")");

    return -1;
}

void AG_CreatePathEntranceDoorTile(string sAreaID, int nTile)
{
    int nEdge = AG_GetEdgeFromTile(sAreaID, nTile);
    int nPathDoorTileID = AG_GetAreaPathDoor(sAreaID);
    int nOrientation = AG_GetDoorOrientationFromEdge(sAreaID, nEdge, nPathDoorTileID);

    AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, nPathDoorTileID, nOrientation, TRUE);
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
    int nOrientation = AG_GetDoorOrientationFromEdge(sAreaID, nEdge, nPathDoorTileID);
    int nTile;

    if (nEdge == AG_AREA_EDGE_TOP)
        nTile = (nWidth * (nHeight - 1)) + (Random(nWidth - 2) + 1);
    else if (nEdge == AG_AREA_EDGE_RIGHT)
        nTile = (nWidth - 1) + ((Random(nHeight - 2) + 1) * nWidth);
    else if (nEdge == AG_AREA_EDGE_BOTTOM)
        nTile = (Random(nWidth - 2) + 1);
    else if (nEdge == AG_AREA_EDGE_LEFT)
        nTile = (Random(nHeight - 2) + 1) * nWidth;

    AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, nPathDoorTileID, nOrientation, TRUE);
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
            WriteLog(AG_LOG_TAG, "* ERROR: AG_SetEdgeFromArea: Area Width does not match!");
            return;
        }
    }
    else if (nEdgeToCopy == AG_AREA_EDGE_LEFT || nEdgeToCopy == AG_AREA_EDGE_RIGHT)
    {
        if (nHeight != nOtherHeight)
        {
            WriteLog(AG_LOG_TAG, "* ERROR: AG_SetEdgeFromArea: Area Height does not match!");
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
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_BOTTOM, nCount, str.nID,  str.nOrientation);

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
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_LEFT, nCount, str.nID,  str.nOrientation);

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
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_TOP, nCount, str.nID,  str.nOrientation);

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
                AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_EDGE_RIGHT, nCount, str.nID,  str.nOrientation);

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

    if (bNoRoad)
        str = TS_ReplaceTerrainOrCrosser(str, "", "GRASS");

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

    sqlquery sql = TS_PrepareQuery(sQuery);

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

    AG_SetJsonDataByKey(sAreaID, AG_DATA_KEY_PATH_NODES, jPathNodes);

    nEntranceTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);
    nExitTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    int bNoRoad = Random(100) < AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_PATH_NO_ROAD_CHANCE);

    int nPreviousX = nEntranceTile % nWidth, nPreviousY = nEntranceTile / nWidth;
    int nNode, nNumNodes = JsonGetLength(jPathNodes);
    for (nNode = 0; nNode < nNumNodes; nNode++)
    {
        json jNode = JsonArrayGet(jPathNodes, nNode);
        int nCurrentX = JsonArrayGetInt(jNode, 0);
        int nCurrentY = JsonArrayGetInt(jNode, 1);
        json jNextNode = JsonArrayGet(jPathNodes, nNode + 1);
        int nNextX = JsonGetType(jNextNode) ? JsonArrayGetInt(jNextNode, 0) : nExitTile % nWidth;
        int nNextY = JsonGetType(jNextNode) ? JsonArrayGetInt(jNextNode, 1) : nExitTile / nWidth;

        int nPreviousDiffX = nCurrentX - nPreviousX;
        int nPreviousDiffY = nCurrentY - nPreviousY;
        int nNextDiffX = nCurrentX - nNextX;
        int nNextDiffY = nCurrentY - nNextY;

        struct TS_TileStruct strQuery = AG_GetRoadTileStruct(sAreaID, nNode, nNumNodes, nPreviousDiffX, nPreviousDiffY, nNextDiffX, nNextDiffY, bNoRoad);

        int nTile = nCurrentX + (nCurrentY * nWidth);
        if (bNoRoad)
        {
            struct AG_Tile strTile = AG_GetRandomRoadTile(sAreaID, strQuery);
            AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile, strTile.nTileID, strTile.nOrientation, TRUE);
        }
        else
            AG_SetTileOverride(sAreaID, nTile, strQuery);

        nPreviousX = nCurrentX;
        nPreviousY = nCurrentY;
    }
}

void AG_GenerateEdge(string sAreaID, int nEdge)
{
    if (AG_GetEdgeFromTile(sAreaID, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX)) == nEdge)
        return;

    int bCanUseMountain = !AG_GetIgnoreTerrainOrCrosser(sAreaID, "MOUNTAIN");
    int bCanUseWater = !AG_GetIgnoreTerrainOrCrosser(sAreaID, "WATER");

    if (!bCanUseMountain && !bCanUseWater)
        return;

    string sTileArray, sDefaultEdge = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_DEFAULT_EDGE_TERRAIN);
    int nExitTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    int nNumTiles, bHasExit, nExitPosition;

    switch (nEdge)
    {
        case AG_AREA_EDGE_TOP:
        {
            sTileArray = AG_DATA_KEY_ARRAY_EDGE_TOP;
            nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
            bHasExit = AG_GetEdgeFromTile(sAreaID, nExitTile) == nEdge;
            nExitPosition = nExitTile % nNumTiles;
            break;
        }

        case AG_AREA_EDGE_BOTTOM:
        {
            sTileArray = AG_DATA_KEY_ARRAY_EDGE_BOTTOM;
            nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
            bHasExit = AG_GetEdgeFromTile(sAreaID, nExitTile) == nEdge;
            nExitPosition = nExitTile % nNumTiles;
            break;
        }

        case AG_AREA_EDGE_RIGHT:
        {
            sTileArray = AG_DATA_KEY_ARRAY_EDGE_RIGHT;
            nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
            bHasExit = AG_GetEdgeFromTile(sAreaID, nExitTile) == nEdge;
            nExitPosition = nExitTile / AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH);
            break;
        }

        case AG_AREA_EDGE_LEFT:
        {
            sTileArray = AG_DATA_KEY_ARRAY_EDGE_LEFT;
            nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT);
            bHasExit = AG_GetEdgeFromTile(sAreaID, nExitTile) == nEdge;
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
            {
                sTC3 = sDefaultEdge;
            }
            else
            {
                if (sTC1 == sDefaultEdge)
                {
                    int nRandom = 1 + bCanUseMountain + bCanUseWater;
                    switch (Random(nRandom))
                    {
                        case 0: sTC3 = sDefaultEdge; break;
                        case 1: sTC3 = "MOUNTAIN"; break;
                        case 2: sTC3 = "WATER"; break;
                    }
                }
                else
                {
                    if (!Random(4))
                    {
                        int nRandom = 1 + bCanUseMountain + bCanUseWater;
                        switch (Random(nRandom))
                        {
                            case 0: sTC3 = sDefaultEdge; break;
                            case 1: sTC3 = "MOUNTAIN"; break;
                            case 2: sTC3 = "WATER"; break;
                        }
                    }
                    else
                    {
                        sTC3 = sTC1;
                    }
                }
            }
        }

        if (bHasExit)
        {
            if (sTC1 == "WATER" || sTC3 == "WATER")
                AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_EDGE_HAS_WATER, TRUE);

            if (sTC1 == "MOUNTAIN" || sTC3 == "MOUNTAIN")
                AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_EDGE_HAS_MOUNTAIN, TRUE);
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

