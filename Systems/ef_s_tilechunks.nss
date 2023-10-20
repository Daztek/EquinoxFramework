/*
    Script: ef_s_tilechunks
    Author: Daz

    Description:
*/

#include "ef_i_core"
#include "ef_s_areagen"

const string TC_SCRIPT_NAME                     = "ef_s_tilechunks";
const string TC_AREA_TAG                        = "AR_TILECHUNKS";

const string TC_AREA_ID                         = "TCRandomArea";
const string TC_AREA_TILESET                    = TILESET_RESREF_MEDIEVAL_RURAL_2;
const int TC_AREA_WIDTH                         = 16;
const int TC_AREA_HEIGHT                        = 16;
const int TC_AREA_CHUNK_SIZE                    = 8;
const string TC_AREA_EDGE_TERRAIN               = "";
const int TC_MAX_ITERATIONS                     = 25;

// @CORE[EF_SYSTEM_LOAD]
void TC_Load()
{
    AG_InitializeAreaDataObject(TC_AREA_ID, TC_AREA_TILESET, TC_AREA_EDGE_TERRAIN, TC_AREA_WIDTH, TC_AREA_HEIGHT);
    AG_InitializeAreaChunks(TC_AREA_ID, TC_AREA_CHUNK_SIZE);
    AG_SetIntDataByKey(TC_AREA_ID, AG_DATA_KEY_MAX_ITERATIONS, TC_MAX_ITERATIONS);
    AG_SetIntDataByKey(TC_AREA_ID, AG_DATA_KEY_GENERATION_LOG_STATUS, TRUE);
    AG_SetIntDataByKey(TC_AREA_ID, AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE, 5);
    AG_SetIntDataByKey(TC_AREA_ID, AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE, 25);
    AG_SetCallbackFunction(TC_AREA_ID, TC_SCRIPT_NAME, "TC_OnAreaChunkGenerated");

    AG_SetIgnoreTerrainOrCrosser(TC_AREA_ID, "ROAD");
    AG_SetIgnoreTerrainOrCrosser(TC_AREA_ID, "WALL");
    AG_SetIgnoreTerrainOrCrosser(TC_AREA_ID, "BRIDGE");
    AG_SetIgnoreTerrainOrCrosser(TC_AREA_ID, "STREET");

    AG_SetStringDataByKey(TC_AREA_ID, AG_DATA_KEY_FLOOR_TERRAIN, "GRASS");
}

void TC_OnAreaChunkGenerated(string sAreaID)
{
    int nChunk = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_CURRENT_CHUNK);
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED))
    {
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, FALSE);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED, FALSE);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS, 0);
        AG_ResetChunkTiles(sAreaID, nChunk);
        AG_GenerateAreaChunk(sAreaID, nChunk);
        return;
    }

    object oArea = GetObjectByTag(TC_AREA_TAG);
    json jChunkArray = AG_GetChunkArray(sAreaID, nChunk);
    json jTileData = JsonArray();
    int nCount, nNumTiles = JsonGetLength(jChunkArray);
    for (nCount = 0; nCount < nNumTiles; nCount++)
    {
        int nTile = JsonArrayGetInt(jChunkArray, nCount);
        struct AG_Tile strTile = AG_GetTile(sAreaID, nTile);
        jTileData = JsonArrayInsert(jTileData, AG_GetSetTileTileObject(nTile, strTile.nTileID, strTile.nOrientation, strTile.nHeight));
    }

    AG_LockChunkTiles(sAreaID, nChunk);
    SetTileJson(oArea, jTileData, SETTILE_FLAG_RECOMPUTE_LIGHTING | SETTILE_FLAG_RELOAD_GRASS);
}

// @CONSOLE[GenerateTileChunk::]
void TC_GenerateChunk(int nChunk)
{
    if (nChunk >= 0 && nChunk < AG_GetIntDataByKey(TC_AREA_ID, AG_DATA_KEY_CHUNK_AMOUNT))
        AG_GenerateAreaChunk(TC_AREA_ID, nChunk);
}

// @CONSOLE[ClearTileChunk::]
void TC_ClearChunk(int nChunk)
{
    if (nChunk >= 0 && nChunk < AG_GetIntDataByKey(TC_AREA_ID, AG_DATA_KEY_CHUNK_AMOUNT))
    {
        AG_SetIntDataByKey(TC_AREA_ID, AG_DATA_KEY_CURRENT_CHUNK, -1);
        AG_ResetChunkTiles(TC_AREA_ID, nChunk);
    }
}
