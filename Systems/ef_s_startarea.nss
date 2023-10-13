/*
    Script: ef_s_startarea
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_areagen"
#include "ef_s_profiler"

const string SA_SCRIPT_NAME                         = "ef_s_startarea";
const int SA_DEBUG_LOG                              = FALSE;

const string SA_STARTING_AREA_TAG                   = "AR_TOWN";
const string SA_AREA_ID                             = "SAStartingArea";
const string SA_AREA_TILESET                        = TILESET_RESREF_MEDIEVAL_RURAL_2;
const int SA_MAX_ITERATIONS                         = 50;
const string SA_AREA_DEFAULT_EDGE_TERRAIN           = "";
const int SA_AREA_LENGTH                            = 8;
const int SA_AREA_CHUNK_SIZE                        = 2;
const int SA_AREA_SINGLE_GROUP_TILE_CHANCE          = 2;

// @CORE[EF_SYSTEM_INIT]
void SA_Init()
{
    int nSeed = Random(1000000000);
    LogInfo("Seed: " + IntToString(nSeed));
    SqlMersenneTwisterSetSeed(SA_SCRIPT_NAME, nSeed);
}

// @CORE[EF_SYSTEM_LOAD]
void SA_Load()
{
    object oArea = GetObjectByTag(SA_STARTING_AREA_TAG);

    Call(Function("ef_s_grass", "Grass_SetGrass"), ObjectArg(oArea) + StringArg("trm02_grass3d"));

    AG_InitializeRandomArea(SA_AREA_ID, SA_AREA_TILESET, SA_AREA_DEFAULT_EDGE_TERRAIN, SA_AREA_LENGTH, SA_AREA_LENGTH);
    AG_InitializeAreaChunks(SA_AREA_ID, SA_AREA_CHUNK_SIZE);

    AG_SetStringDataByKey(SA_AREA_ID, AG_DATA_KEY_GENERATION_RANDOM_NAME, SA_SCRIPT_NAME);
    AG_SetIntDataByKey(SA_AREA_ID, AG_DATA_KEY_GENERATION_LOG_STATUS, SA_DEBUG_LOG);
    AG_SetIntDataByKey(SA_AREA_ID, AG_DATA_KEY_MAX_ITERATIONS, SA_MAX_ITERATIONS);
    AG_SetIntDataByKey(SA_AREA_ID, AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE, SA_AREA_SINGLE_GROUP_TILE_CHANCE);
    AG_SetIntDataByKey(SA_AREA_ID, AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE, 10 + AG_Random(SA_AREA_ID, 16));
    AG_SetIntDataByKey(SA_AREA_ID, AG_DATA_KEY_GENERATION_TYPE, AG_Random(SA_AREA_ID, 8));
    AG_SetIntDataByKey(SA_AREA_ID, AG_DATA_KEY_ENABLE_CORNER_TILE_VALIDATOR, TRUE);
    AG_SetCallbackFunction(SA_AREA_ID, SA_SCRIPT_NAME, "SA_OnAreaGenerated");

    AG_SetIgnoreTerrainOrCrosser(SA_AREA_ID, "ROAD");
    AG_SetIgnoreTerrainOrCrosser(SA_AREA_ID, "BRIDGE");
    AG_SetIgnoreTerrainOrCrosser(SA_AREA_ID, "STREET");
    AG_SetIgnoreTerrainOrCrosser(SA_AREA_ID, "WALL");

    AG_InitializeChunkFromArea(SA_AREA_ID, oArea, 8);
    AG_InitializeChunkFromArea(SA_AREA_ID, oArea, 9);
    AG_InitializeChunkFromArea(SA_AREA_ID, oArea, 13);

    AG_GenerateArea(SA_AREA_ID);
}

void SA_OnAreaGenerated(string sAreaID)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED))
    {
        if (SA_DEBUG_LOG)
            LogDebug("Area Generation Failure: " + sAreaID + ", retrying...");

        int nChunk, nNumChunks = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_CHUNK_AMOUNT);
        for (nChunk = 0; nChunk < nNumChunks; nChunk++)
        {
            switch (nChunk)
            {
                case 8: case 9: case 13:
                    continue;

                default:
                    AG_ResetChunkTiles(sAreaID, nChunk);
                    break;
            }
        }

        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FINISHED, FALSE);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED, FALSE);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_ITERATIONS, 1);

        AG_GenerateArea(sAreaID);
    }
    else
    {
        LogInfo("Generated Starting Area!");

        json jTileData = JsonArray();
        int nChunk, nNumChunks = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_CHUNK_AMOUNT);
        for (nChunk = 0; nChunk < nNumChunks; nChunk++)
        {
            switch (nChunk)
            {
                case 8: case 9: case 13:
                    continue;

                default:
                {
                    json jChunk = AG_GetChunkArray(sAreaID, nChunk);
                    int nCount, nNumTiles = JsonGetLength(jChunk);
                    for (nCount = 0; nCount < nNumTiles; nCount++)
                    {
                        int nTileIndex = JsonArrayGetInt(jChunk, nCount);
                        struct AG_Tile str = AG_GetTile(sAreaID, nTileIndex);
                        json jTile = AG_GetSetTileTileObject(nTileIndex, str.nTileID, str.nOrientation, str.nHeight);
                        jTileData = JsonArrayInsert(jTileData, jTile);
                    }
                    break;
                }
            }
        }

        object oArea = GetObjectByTag(SA_STARTING_AREA_TAG);
        SetTileJson(oArea, jTileData, SETTILE_FLAG_RELOAD_GRASS | SETTILE_FLAG_RELOAD_BORDER | SETTILE_FLAG_RECOMPUTE_LIGHTING);
        DelayCommand(1.0f, RetVoid(Call(Function("ef_s_endlesspath", "EP_BeginPath"), ObjectArg(oArea))));
    }
}
