/*
    Script: ef_s_endlesspath
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_areagen"
#include "ef_s_eventman"
#include "ef_s_profiler"
#include "ef_s_areamusic"

const string EP_SCRIPT_NAME                         = "ef_s_endlesspath";
const int EP_DEBUG_LOG                              = FALSE;

const string EP_TEMPLATE_AREA_JSON                  = "TemplateArea";
const string EP_DOOR_TAG_PREFIX                     = "EP_DOOR_";
const string EP_AREA_TAG_PREFIX                     = "AR_EP_";

const float EP_POSTPROCESS_DELAY                    = 0.1f;
const int EP_POSTPROCESS_TILE_BATCH                 = 8;
const string EP_EVENT_AREA_POST_PROCESS_FINISHED    = "EP_EVENT_AREA_POST_PROCESS_FINISHED";

const string EP_AREA_TILESET                        = TILESET_RESREF_MEDIEVAL_RURAL_2;
const int EP_MAX_ITERATIONS                         = 100;
const string EP_AREA_DEFAULT_EDGE_TERRAIN           = "";
const int EP_AREA_MINIMUM_LENGTH                    = 8;
const int EP_AREA_RANDOM_LENGTH                     = 12;

const int EP_AREA_SAND_CHANCE                       = 20;
const int EP_AREA_WATER_CHANCE                      = 30;
const int EP_AREA_MOUNTAIN_CHANCE                   = 40;
const int EP_AREA_STREAM_CHANCE                     = 15;
const int EP_AREA_RIDGE_CHANCE                      = 20;
const int EP_AREA_ROAD_CHANCE                       = 20;
const int EP_AREA_GRASS2_CHANCE                     = 25;
const int EP_AREA_WALL_CHANCE                       = 1;
const int EP_AREA_CHASM_CHANCE                      = 10;

const int EP_AREA_SINGLE_GROUP_TILE_CHANCE          = 2;

void EP_BeginPath(object oArea);
string EP_GetTilesTable();
string EP_GetLastAreaID();
string EP_GetNextAreaID();
string EP_GetLastDoorID();
string EP_GetNextDoorID();
void EP_SetLastGenerationData(object oArea, int nEdge, int nWidth, int nHeight);
void EP_ToggleTerrainOrCrosser(string sAreaID, object oPreviousArea, string sCrosser, int nChance);
void EP_SetGenerationType(string sAreaID);
void EP_GenerateArea(string sAreaID, object oPreviousArea, int nEdgeToCopy, int nAreaWidth, int nAreaHeight);
int EP_GetAreaNum(string sAreaID);
int EP_GetIsEPArea(object oArea);
object EP_CreateArea(string sAreaID);
void EP_PostProcess(object oArea, int nCurrentTile = 0, int nNumTiles = 0);

// @CORE[EF_SYSTEM_INIT]
void EP_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + EP_GetTilesTable() + "(" +
             "area_id TEXT NOT NULL, " +
             "tile_index INTEGER NOT NULL, " +
             "tile_x INTEGER NOT NULL, " +
             "tile_y INTEGER NOT NULL, " +
             "tile_id INTEGER NOT NULL, " +
             "entrance_dist INTEGER NOT NULL, " +
             "exit_dist INTEGER NOT NULL, " +
             "path_dist INTEGER NOT NULL, " +
             "group_tile INTEGER NOT NULL, " +
             "num_doors INTEGER NOT NULL, " +
             "PRIMARY KEY(area_id, tile_index));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SetLocalJson(GetDataObject(EP_SCRIPT_NAME), EP_TEMPLATE_AREA_JSON, GffTools_GetScrubbedAreaTemplate(GetArea(GetObjectByTag(EP_GetLastDoorID()))));

    int nSeed = Random(1000000000);
    LogInfo("Seed: " + IntToString(nSeed));
    SqlMersenneTwisterSetSeed(EP_SCRIPT_NAME, nSeed);
}

// @CORE[EF_SYSTEM_LOAD]
void EP_Load()
{
    AreaMusic_AddTrackToTrackList(EP_SCRIPT_NAME, 109, AREAMUSIC_MUSIC_TYPE_DAY_OR_NIGHT);
    AreaMusic_AddTrackToTrackList(EP_SCRIPT_NAME, 128, AREAMUSIC_MUSIC_TYPE_DAY_OR_NIGHT);
    AreaMusic_AddTrackToTrackList(EP_SCRIPT_NAME, 136, AREAMUSIC_MUSIC_TYPE_DAY_OR_NIGHT);
}

void EP_BeginPath(object oArea)
{
    int nAreaWidth = GetAreaSize(AREA_WIDTH, oArea);
    int nAreaHeight = EP_AREA_MINIMUM_LENGTH + SqlMersenneTwisterGetValue(EP_SCRIPT_NAME, EP_AREA_RANDOM_LENGTH + 1);
    string sAreaID = EP_GetNextAreaID();

    EP_GenerateArea(sAreaID, oArea, AG_AREA_EDGE_TOP, nAreaWidth, nAreaHeight);
}

// @EVENT[EVENT_SCRIPT_AREA_ON_ENTER:DL]
void EP_OnAreaEnter()
{
    object oPlayer = GetEnteringObject();
    object oArea = OBJECT_SELF;

    if (GetIsPC(oPlayer))
    {
        if (!GetLocalInt(oArea, "PLAYER_ENTERED"))
        {
            string sPreviousAreaID = EP_GetLastAreaID();
            object oPreviousArea = GetObjectByTag(sPreviousAreaID);
            int nExitTile = AG_GetIntDataByKey(sPreviousAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
            int nExitEdge = AG_GetEdgeFromTile(sPreviousAreaID, nExitTile);
            string sAreaID = EP_GetNextAreaID();

            int nAreaWidth, nAreaHeight;
            if (nExitEdge == AG_AREA_EDGE_TOP || nExitEdge == AG_AREA_EDGE_BOTTOM)
            {
                nAreaWidth = GetAreaSize(AREA_WIDTH, oPreviousArea);
                nAreaHeight = EP_AREA_MINIMUM_LENGTH + AG_Random(sPreviousAreaID, EP_AREA_RANDOM_LENGTH + 1);
            }
            else if (nExitEdge == AG_AREA_EDGE_LEFT || nExitEdge == AG_AREA_EDGE_RIGHT)
            {
                nAreaWidth = EP_AREA_MINIMUM_LENGTH + AG_Random(sPreviousAreaID, EP_AREA_RANDOM_LENGTH + 1);
                nAreaHeight = GetAreaSize(AREA_HEIGHT, oPreviousArea);
            }

            EP_GenerateArea(sAreaID, oPreviousArea, nExitEdge, nAreaWidth, nAreaHeight);
            SetLocalInt(oArea, "PLAYER_ENTERED", TRUE);
        }

        if (!GetHasEffectType(oPlayer, EFFECT_TYPE_HASTE))
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectHaste(), oPlayer);

        ExploreAreaForPlayer(oArea, oPlayer);
        PopUpGUIPanel(oPlayer, GUI_PANEL_MINIMAP);
    }
}

string EP_GetTilesTable()
{
    return EP_SCRIPT_NAME + "_tiles ";
}

string EP_GetLastAreaID()
{
    return EP_AREA_TAG_PREFIX + IntToString(GetLocalInt(GetDataObject(EP_SCRIPT_NAME), "AREA_ID"));
}

string EP_GetNextAreaID()
{
    object oDataObject = GetDataObject(EP_SCRIPT_NAME);
    int nID = GetLocalInt(oDataObject, "AREA_ID") + 1;
    SetLocalInt(oDataObject, "AREA_ID", nID);
    return EP_AREA_TAG_PREFIX + IntToString(nID);
}

string EP_GetLastDoorID()
{
    return EP_DOOR_TAG_PREFIX + IntToString(GetLocalInt(GetDataObject(EP_SCRIPT_NAME), "DOOR_ID"));
}

string EP_GetNextDoorID()
{
    object oDataObject = GetDataObject(EP_SCRIPT_NAME);
    int nID = GetLocalInt(oDataObject, "DOOR_ID") + 1;
    SetLocalInt(oDataObject, "DOOR_ID", nID);
    return EP_DOOR_TAG_PREFIX + IntToString(nID);
}

void EP_SetLastGenerationData(object oArea, int nEdge, int nWidth, int nHeight)
{
    object oDataObject = GetDataObject(EP_SCRIPT_NAME);
    SetLocalObject(oDataObject, "LAST_AREA", oArea);
    SetLocalInt(oDataObject, "LAST_EDGE", nEdge);
    SetLocalInt(oDataObject, "LAST_WIDTH", nWidth);
    SetLocalInt(oDataObject, "LAST_HEIGHT", nHeight);
}

void EP_ToggleTerrainOrCrosser(string sAreaID, object oPreviousArea, string sCrosser, int nChance)
{
    json jExitEdgeTerrains = AG_GetJsonDataByKey(GetTag(oPreviousArea), AG_DATA_KEY_ARRAY_EXIT_EDGE_TERRAINS);
    if (!JsonArrayContainsString(jExitEdgeTerrains, sCrosser))
    {
        AG_SetIgnoreTerrainOrCrosser(sAreaID, sCrosser, !(AG_Random(sAreaID, 100) < nChance));
    }
}

void EP_SetGenerationType(string sAreaID)
{
    int nEntranceTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);
    int nEntranceEdge = AG_GetEdgeFromTile(sAreaID, nEntranceTile);
    int nExitTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    int nExitEdge = AG_GetEdgeFromTile(sAreaID, nExitTile);
    int nGenerationType = AG_GENERATION_TYPE_LINEAR_ASCENDING;

    if ((nEntranceEdge == AG_AREA_EDGE_TOP && nExitEdge == AG_AREA_EDGE_BOTTOM) ||
        (nEntranceEdge == AG_AREA_EDGE_BOTTOM && nExitEdge == AG_AREA_EDGE_TOP))
        nGenerationType = AG_GENERATION_TYPE_ALTERNATING_ROWS_INWARD;
    else if ((nEntranceEdge == AG_AREA_EDGE_RIGHT && nExitEdge == AG_AREA_EDGE_LEFT) ||
             (nEntranceEdge == AG_AREA_EDGE_LEFT && nExitEdge == AG_AREA_EDGE_RIGHT))
        nGenerationType = AG_GENERATION_TYPE_ALTERNATING_COLUMNS_INWARD;
    else
        nGenerationType = AG_GENERATION_TYPE_SPIRAL_INWARD;

    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE, nGenerationType);
}

void EP_GenerateArea(string sAreaID, object oPreviousArea, int nEdgeToCopy, int nAreaWidth, int nAreaHeight)
{
    EP_SetLastGenerationData(oPreviousArea, nEdgeToCopy, nAreaWidth, nAreaHeight);
    AG_InitializeRandomArea(sAreaID, EP_AREA_TILESET, EP_AREA_DEFAULT_EDGE_TERRAIN, nAreaWidth, nAreaHeight);
    AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_GENERATION_RANDOM_NAME, EP_SCRIPT_NAME);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS, EP_DEBUG_LOG);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_MAX_ITERATIONS, EP_MAX_ITERATIONS);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE, EP_AREA_SINGLE_GROUP_TILE_CHANCE);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE, 10 + AG_Random(sAreaID, 16));
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE, AG_Random(sAreaID, 8));
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_ENABLE_CORNER_TILE_VALIDATOR, TRUE);
    AG_SetCallbackFunction(sAreaID, EP_SCRIPT_NAME, "EP_OnAreaGenerated");

    AG_AddEdgeTerrain(sAreaID, "WATER");
    AG_AddEdgeTerrain(sAreaID, "MOUNTAIN");

    AG_SetIgnoreTerrainOrCrosser(sAreaID, "ROAD");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "BRIDGE");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "STREET");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "WALL");

    if (sAreaID != EP_AREA_TAG_PREFIX + "1")
    {
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "SAND", EP_AREA_SAND_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "WATER", EP_AREA_WATER_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "MOUNTAIN", EP_AREA_MOUNTAIN_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "STREAM", EP_AREA_STREAM_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "RIDGE", EP_AREA_RIDGE_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "GRASS2", EP_AREA_GRASS2_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "WALL", EP_AREA_WALL_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "CHASM", EP_AREA_CHASM_CHANCE);
    }

    AG_AddPathDoorCrosserCombo(sAreaID, 80, "ROAD");
    AG_AddPathDoorCrosserCombo(sAreaID, 1161, "STREET");
    AG_SetAreaPathDoorCrosserCombo(sAreaID, AG_Random(sAreaID, 100) < EP_AREA_ROAD_CHANCE ? 0 : 1);

    AG_CopyEdgeFromArea(sAreaID, oPreviousArea, nEdgeToCopy);
    //AG_GenerateEdge(sAreaID, AG_AREA_EDGE_TOP);
    //AG_GenerateEdge(sAreaID, AG_AREA_EDGE_RIGHT);
    //AG_GenerateEdge(sAreaID, AG_AREA_EDGE_BOTTOM);
    //AG_GenerateEdge(sAreaID, AG_AREA_EDGE_LEFT);
    //EP_SetGenerationType(sAreaID);
    AG_PlotRoad(sAreaID);

    AG_GenerateArea(sAreaID);
}

int EP_GetAreaNum(string sAreaID)
{
    int nPrefixLength = GetStringLength(EP_AREA_TAG_PREFIX);
    return StringToInt(GetSubString(sAreaID, nPrefixLength, GetStringLength(sAreaID) - nPrefixLength));
}

int EP_GetIsEPArea(object oArea)
{
    return GetStringLeft(GetTag(oArea), GetStringLength(EP_AREA_TAG_PREFIX)) == EP_AREA_TAG_PREFIX;
}

object EP_CreateArea(string sAreaID)
{
    json jArea = GetLocalJson(GetDataObject(EP_SCRIPT_NAME), EP_TEMPLATE_AREA_JSON);
    jArea = GffReplaceString(jArea, "ARE/value/Tag", sAreaID);
    jArea = GffReplaceInt(jArea, "ARE/value/Height", AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT));
    jArea = GffReplaceInt(jArea, "ARE/value/Width", AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH));
    jArea = GffReplaceLocString(jArea, "ARE/value/Name", "The Endless Path (" +IntToString(EP_GetAreaNum(sAreaID)) + ")");
    jArea = GffReplaceInt(jArea, "GIT/value/AreaProperties/value/MusicDay", 0);
    jArea = GffReplaceInt(jArea, "GIT/value/AreaProperties/value/MusicNight", 0);
    jArea = GffReplaceInt(jArea, "GIT/value/AreaProperties/value/MusicBattle", 0);
    jArea = GffReplaceInt(jArea, "ARE/value/WindPower", AG_Random(sAreaID, 3));
    jArea = GffAddList(jArea, "ARE/value/Tile_List", AG_GetTileList(sAreaID));

    return JsonToObject(jArea, GetStartingLocation());
}

void EP_SetAreaModifiers(object oArea)
{
    // Don't persist player locations in EP areas
    Call(Function("ef_s_perloc", "PerLoc_SetAreaDisabled"), ObjectArg(oArea));
    // Setup dynamic lighting
    Call(Function("ef_s_dynlight", "DynLight_InitArea"), ObjectArg(oArea));
    // Assign Track List
    AreaMusic_SetAreaTrackList(oArea, EP_SCRIPT_NAME);
}

void EP_OnAreaGenerated(string sAreaID)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED))
    {
        if (EP_DEBUG_LOG)
            LogDebug("Area Generation Failure: " + sAreaID + ", retrying...");

        object oDataObject = GetDataObject(EP_SCRIPT_NAME);
        object oArea = GetLocalObject(oDataObject, "LAST_AREA");
        int nEdge = GetLocalInt(oDataObject, "LAST_EDGE");
        int nWidth = GetLocalInt(oDataObject, "LAST_WIDTH");
        int nHeight = GetLocalInt(oDataObject, "LAST_HEIGHT");

        EP_GenerateArea(sAreaID, oArea, nEdge, nWidth, nHeight);
    }
    else
    {
        object oArea = EP_CreateArea(sAreaID);
        EM_SetAreaEventScripts(oArea);
        EM_ObjectDispatchListInsert(oArea, EM_GetObjectDispatchListId(EP_SCRIPT_NAME, EVENT_SCRIPT_AREA_ON_ENTER));

        EP_SetAreaModifiers(oArea);

        object oPreviousDoor = GetObjectByTag(EP_GetLastDoorID());
        object oEntranceDoor = AG_CreateDoor(sAreaID, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX), EP_GetNextDoorID());
        object oExitDoor = AG_CreateDoor(sAreaID, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX), EP_GetNextDoorID());

        SetTransitionTarget(oPreviousDoor, oEntranceDoor);
        SetTransitionTarget(oEntranceDoor, oPreviousDoor);

        AG_ExtractExitEdgeTerrains(sAreaID);

        LogInfo("Creating Area: " + GetTag(oArea) + " -> Generation Type: " + AG_GetGenerationTypeAsString(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE)));
        LogInfo(" > Exit Height: " + IntToString( AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_TILES, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX))));

        DelayCommand(EP_POSTPROCESS_DELAY, EP_PostProcess(oArea));
    }
}

int EP_NearestPathDistance(string sAreaID, int nTileX, int nTileY)
{
    json jPathNodes = AG_GetJsonDataByKey(sAreaID, AG_DATA_KEY_PATH_NODES);

    if (JsonGetType(JsonFind(jPathNodes, JsonPointInt(nTileX, nTileY))) == JSON_TYPE_INTEGER)
        return 0;

    int nNode, nNumNodes = JsonGetLength(jPathNodes), nMinDistance = 1000;

    for (nNode = 0; nNode < nNumNodes; nNode++)
    {
        json jNode = JsonArrayGet(jPathNodes, nNode);
        int nDistanceFromPathNode = abs(nTileX - JsonObjectGetInt(jNode, "x")) + abs(nTileY - JsonObjectGetInt(jNode, "y"));

        if (nDistanceFromPathNode < nMinDistance)
            nMinDistance = nDistanceFromPathNode;

        if (nMinDistance == 1)
            break;
    }

    return nMinDistance;
}

void EP_PostProcess(object oArea, int nCurrentTile = 0, int nNumTiles = 0)
{
    string sAreaID = GetTag(oArea);

    if (nNumTiles == 0)
    {
        nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    }

    if (nCurrentTile == nNumTiles)
    {
        EM_NWNXSignalEvent(EP_EVENT_AREA_POST_PROCESS_FINISHED, oArea);
        return;
    }

    int nEntranceTileIndex = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);
    struct AG_TilePosition strEntrancePosition = AG_GetTilePosition(sAreaID, nEntranceTileIndex);
    vector vEntrancePosition = GetTilePosition(strEntrancePosition.nX, strEntrancePosition.nY);
    int nExitTileIndex = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    struct AG_TilePosition strExitPosition = AG_GetTilePosition(sAreaID, nExitTileIndex);
    string sQuery = "INSERT INTO " + EP_GetTilesTable() + "(area_id, tile_index, tile_x, tile_y, tile_id, entrance_dist, exit_dist, path_dist, group_tile, num_doors) " +
                    "VALUES(@area_id, @tile_index, @tile_x, @tile_y, @tile_id, @entrance_dist, @exit_dist, @path_dist, @group_tile, @num_doors);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    int nCurrentMaxTiles = min(nCurrentTile + EP_POSTPROCESS_TILE_BATCH, nNumTiles);
    int nGrassBitflag = TS_GetTCBitflag(EP_AREA_TILESET, "GRASS");
    int nGrass2Bitflag = TS_GetTCBitflag(EP_AREA_TILESET, "GRASS2");

    SqlBeginTransactionModule();

    for (nCurrentTile; nCurrentTile < nCurrentMaxTiles; nCurrentTile++)
    {
        struct NWNX_Area_TileInfo strTileInfo = NWNX_Area_GetTileInfoByTileIndex(oArea, nCurrentTile);
        int nCAE = TS_GetTileTCBitmask(EP_AREA_TILESET, TS_GetTileEdgesAndCorners(EP_AREA_TILESET, strTileInfo.nID));

        if ((nCAE & nGrassBitflag) || (nCAE & nGrass2Bitflag))
        {
            vector vTilePosition = GetTilePosition(strTileInfo.nGridX, strTileInfo.nGridY);

            if (NWNX_Area_GetPathExists(oArea, vEntrancePosition, vTilePosition, nNumTiles))
            {
                int nDistanceFromEntrance = abs(strEntrancePosition.nX - strTileInfo.nGridX) + abs(strEntrancePosition.nY - strTileInfo.nGridY);
                int nDistanceFromExit = abs(strExitPosition.nX - strTileInfo.nGridX) + abs(strExitPosition.nY - strTileInfo.nGridY);
                int nDistanceFromPath = EP_NearestPathDistance(sAreaID, strTileInfo.nGridX, strTileInfo.nGridY);
                int bIsGroupTile = TS_GetIsTilesetGroupTile(EP_AREA_TILESET, strTileInfo.nID);
                int nNumDoors = TS_GetTilesetNumDoors(EP_AREA_TILESET, strTileInfo.nID);

                SqlBindString(sql, "@area_id", sAreaID);
                SqlBindInt(sql, "@tile_index", nCurrentTile);
                SqlBindInt(sql, "@tile_x", strTileInfo.nGridX);
                SqlBindInt(sql, "@tile_y", strTileInfo.nGridY);
                SqlBindInt(sql, "@tile_id", strTileInfo.nID);
                SqlBindInt(sql, "@entrance_dist", nDistanceFromEntrance);
                SqlBindInt(sql, "@exit_dist", nDistanceFromExit);
                SqlBindInt(sql, "@path_dist", nDistanceFromPath);
                SqlBindInt(sql, "@group_tile", bIsGroupTile);
                SqlBindInt(sql, "@num_doors", nNumDoors);
                SqlStepAndReset(sql);
            }
        }
    }

    SqlCommitTransactionModule();

    DelayCommand(EP_POSTPROCESS_DELAY, EP_PostProcess(oArea, nCurrentTile, nNumTiles));
}

void EP_PortToTile(string sType)
{
    object oPlayer = OBJECT_SELF;
    object oArea = GetArea(oPlayer);

    if (EP_GetIsEPArea(oArea))
    {
        string sAreaID = GetTag(oArea);
        struct AG_TilePosition strPosition = AG_GetTilePosition(sAreaID, AG_GetIntDataByKey(sAreaID, sType));
        vector vPosition = GetTilePosition(strPosition.nX, strPosition.nY);
        location locTile = Location(oArea, vPosition, 0.0f);

        ClearAllActions();
        JumpToLocation(locTile);
    }
}

// @CONSOLE[EPEntrance::]
void EP_PortToEntrance()
{
    EP_PortToTile(AG_DATA_KEY_ENTRANCE_TILE_INDEX);
}

// @CONSOLE[EPExit::]
void EP_PortToExit()
{
    EP_PortToTile(AG_DATA_KEY_EXIT_TILE_INDEX);
}

// @CONSOLE[EPTileInfo::]
string EP_TileInfo()
{
    object oTarget = OBJECT_SELF;
    object oArea = GetArea(oTarget);
    vector vPosition = GetPosition(oTarget);
    struct NWNX_Area_TileInfo str = NWNX_Area_GetTileInfo(oArea, vPosition.x, vPosition.y);
    int nSurfaceMaterial = GetSurfaceMaterial(GetLocation(oTarget));
    return "Tileset: " + GetTilesetResRef(oArea) + ", TileID: " + IntToString(str.nID) + "\n" +
            "GridX: " + IntToString(str.nGridX) + ", GridY: " + IntToString(str.nGridY) + "\n" +
            "Height: " + IntToString(str.nHeight) + "\n" +
            "Orientation: " + IntToString(str.nOrientation) + "\n" +
            "Surface Material: " + Get2DAString("surfacemat", "Label", nSurfaceMaterial) +  " (" + IntToString(nSurfaceMaterial) + ")\n\n" +
            TS_GetTileStructAsString(GetTilesetResRef(oArea), str.nID, str.nOrientation);
}
