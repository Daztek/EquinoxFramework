/*
    Script: ef_s_endlesspath
    Author: Daz
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_areagen"
#include "ef_s_events"
#include "ef_s_profiler"
#include "ef_s_gfftools"
#include "nwnx_object"

const string EP_LOG_TAG                         = "EndlessPath";
const string EP_SCRIPT_NAME                     = "ef_s_endlesspath";
const int EP_DEBUG_LOG                          = FALSE;

const string EP_TEMPLATE_AREA_JSON              = "TemplateArea";
const string EP_DOOR_TAG_PREFIX                 = "EP_DOOR_";
const string EP_AREA_TAG_PREFIX                 = "AR_EP_";

const float EP_POSTPROCESS_DELAY                = 0.1f;
const string EP_AREA_POST_PROCESS_FINISHED      = "EP_AREA_POST_PROCESS_FINISHED";

const string EP_AREA_TILESET                    = TILESET_RESREF_MEDIEVAL_RURAL_2;
const int EP_MAX_ITERATIONS                     = 25;
const string EP_AREA_DEFAULT_EDGE_TERRAIN       = "TREES";
const int EP_AREA_MINIMUM_LENGTH                = 4;
const int EP_AREA_RANDOM_LENGTH                 = 13;

const int EP_AREA_PATH_NO_ROAD_CHANCE           = 10;
const int EP_AREA_SAND_CHANCE                   = 30;
const int EP_AREA_WATER_CHANCE                  = 35;
const int EP_AREA_MOUNTAIN_CHANCE               = 25;
const int EP_AREA_STREAM_CHANCE                 = 30;
const int EP_AREA_RIDGE_CHANCE                  = 25;
const int EP_AREA_ROAD_CHANCE                   = 25;
const int EP_AREA_GRASS2_CHANCE                 = 25;

const int EP_AREA_SINGLE_GROUP_TILE_CHANCE      = 5;

string EP_GetTilesTable();
string EP_GetLastAreaID();
string EP_GetNextAreaID();
string EP_GetLastDoorID();
string EP_GetNextDoorID();
void EP_SetLastGenerationData(object oArea, int nEdge, int nWidth, int nHeight);
void EP_ToggleTerrainOrCrosser(string sAreaID, object oPreviousArea, string sCrosser, int nChance);
void EP_GenerateArea(string sAreaID, object oPreviousArea, int nEdgeToCopy, int nAreaWidth, int nAreaHeight);
object EP_CreateDoor(object oArea, int nTileIndex);
int EP_GetAreaNum(string sAreaID);
int EP_GetIsEPArea(object oArea);
object EP_CreateArea(string sAreaID);
void EP_PostProcess(object oArea, int nCurrentHeight = 0);

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
}

// @CORE[EF_SYSTEM_LOAD]
void EP_Load()
{
    object oStartingArea = GetArea(GetObjectByTag(EP_GetLastDoorID()));
    int nAreaWidth = GetAreaSize(AREA_WIDTH, oStartingArea);
    int nAreaHeight = EP_AREA_MINIMUM_LENGTH + Random(EP_AREA_RANDOM_LENGTH);
    string sAreaID = EP_GetNextAreaID();

    EP_GenerateArea(sAreaID, oStartingArea, AG_AREA_EDGE_TOP, nAreaWidth, nAreaHeight);
}

// @EVENT[DL:EVENT_SCRIPT_AREA_ON_ENTER]
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
                nAreaHeight = EP_AREA_MINIMUM_LENGTH + Random(EP_AREA_RANDOM_LENGTH);
            }
            else if (nExitEdge == AG_AREA_EDGE_LEFT || nExitEdge == AG_AREA_EDGE_RIGHT)
            {
                nAreaWidth = EP_AREA_MINIMUM_LENGTH + Random(EP_AREA_RANDOM_LENGTH);
                nAreaHeight = GetAreaSize(AREA_HEIGHT, oPreviousArea);
            }

            EP_GenerateArea(sAreaID, oPreviousArea, nExitEdge, nAreaWidth, nAreaHeight);
            SetLocalInt(oArea, "PLAYER_ENTERED", TRUE);
        }

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
        AG_SetIgnoreTerrainOrCrosser(sAreaID, sCrosser, !(Random(100) < nChance));
    }
}

void EP_GenerateArea(string sAreaID, object oPreviousArea, int nEdgeToCopy, int nAreaWidth, int nAreaHeight)
{
    EP_SetLastGenerationData(oPreviousArea, nEdgeToCopy, nAreaWidth, nAreaHeight);
    AG_InitializeRandomArea(sAreaID, EP_AREA_TILESET, EP_AREA_DEFAULT_EDGE_TERRAIN, nAreaWidth, nAreaHeight);

    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS, EP_DEBUG_LOG);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_MAX_ITERATIONS, EP_MAX_ITERATIONS);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE, EP_AREA_SINGLE_GROUP_TILE_CHANCE);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE, 10 + Random(16));
    AG_SetCallbackFunction(sAreaID, EP_SCRIPT_NAME, "EP_OnAreaGenerated");

    AG_AddEdgeTerrain(sAreaID, "WATER");
    AG_AddEdgeTerrain(sAreaID, "MOUNTAIN");
    //AG_AddEdgeTerrain(sAreaID, "GRASS");
    //AG_AddEdgeTerrain(sAreaID, "GRASS2");

    AG_SetIgnoreTerrainOrCrosser(sAreaID, "ROAD");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "WALL");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "BRIDGE");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "STREET");

    if (sAreaID != EP_AREA_TAG_PREFIX + "1")
    {
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "SAND", EP_AREA_SAND_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "WATER", EP_AREA_WATER_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "MOUNTAIN", EP_AREA_MOUNTAIN_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "STREAM", EP_AREA_STREAM_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "RIDGE", EP_AREA_RIDGE_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "GRASS2", EP_AREA_GRASS2_CHANCE);
    }

    AG_AddPathDoorCrosserCombo(sAreaID, 80, "ROAD");
    AG_AddPathDoorCrosserCombo(sAreaID, 1161, "STREET");
    AG_SetAreaPathDoorCrosserCombo(sAreaID, Random(100) < EP_AREA_ROAD_CHANCE ? 0 : 1);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_PATH_NO_ROAD_CHANCE, EP_AREA_PATH_NO_ROAD_CHANCE);

    AG_CopyEdgeFromArea(sAreaID, oPreviousArea, nEdgeToCopy);
    AG_GenerateEdge(sAreaID, AG_AREA_EDGE_TOP);
    AG_GenerateEdge(sAreaID, AG_AREA_EDGE_RIGHT);
    AG_GenerateEdge(sAreaID, AG_AREA_EDGE_BOTTOM);
    AG_GenerateEdge(sAreaID, AG_AREA_EDGE_LEFT);
    AG_PlotRoad(sAreaID);

    AG_GenerateArea(sAreaID);
}

object EP_CreateDoor(object oArea, int nTileIndex)
{
    struct NWNX_Area_TileInfo strTileInfo = NWNX_Area_GetTileInfoByTileIndex(oArea, nTileIndex);
    float fTilesetHeighTransition = TS_GetTilesetHeightTransition(EP_AREA_TILESET);
    struct TS_DoorStruct strDoor = TS_GetTilesetTileDoor(EP_AREA_TILESET, strTileInfo.nID, 0);
    string sTag = EP_GetNextDoorID();

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
    jArea = GffReplaceInt(jArea, "GIT/value/AreaProperties/value/MusicDay", Random(2) ? 128 : 136);
    jArea = GffReplaceInt(jArea, "ARE/value/WindPower", Random(3));
    jArea = GffAddList(jArea, "ARE/value/Tile_List", AG_GetTileList(sAreaID));

    return JsonToObject(jArea, GetStartingLocation());
}

void EP_OnAreaGenerated(string sAreaID)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED))
    {
        if (EP_DEBUG_LOG)
            WriteLog(EP_LOG_TAG, "* Area Generation Failure: " + sAreaID + ", retrying...");

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
        Events_SetAreaEventScripts(oArea);
        Events_AddObjectToDispatchList(EP_SCRIPT_NAME, Events_GetObjectEventName(EVENT_SCRIPT_AREA_ON_ENTER), oArea);

        object oPreviousDoor = GetObjectByTag(EP_GetLastDoorID());
        object oEntranceDoor = EP_CreateDoor(oArea, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX));
        object oExitDoor = EP_CreateDoor(oArea, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX));

        SetTransitionTarget(oPreviousDoor, oEntranceDoor);
        SetTransitionTarget(oEntranceDoor, oPreviousDoor);

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

void EP_PostProcess(object oArea, int nCurrentHeight = 0)
{
    // TODO: Check height/width difference for batching
    
    string sAreaID = GetTag(oArea);
    int nHeight = GetAreaSize(AREA_HEIGHT, oArea);
    int nWidth = GetAreaSize(AREA_WIDTH, oArea);

    if (nCurrentHeight == nHeight)
    {
        Events_SignalEvent(EP_AREA_POST_PROCESS_FINISHED, oArea);
        return;
    }

    object oModule = GetModule();
    int nEntranceTileIndex = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);
    struct AG_TilePosition strEntrancePosition = AG_GetTilePosition(sAreaID, nEntranceTileIndex);
    vector vEntrancePosition = GetTilePosition(strEntrancePosition.nX, strEntrancePosition.nY);
    int nExitTileIndex = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX);
    struct AG_TilePosition strExitPosition = AG_GetTilePosition(sAreaID, nExitTileIndex);
    string sQuery = "INSERT INTO " + EP_GetTilesTable() + "(area_id, tile_index, tile_x, tile_y, tile_id, entrance_dist, exit_dist, path_dist, group_tile, num_doors) " +
                    "VALUES(@area_id, @tile_index, @tile_x, @tile_y, @tile_id, @entrance_dist, @exit_dist, @path_dist, @group_tile, @num_doors);";

    SqlBeginTransactionModule();
    
    int nTile, nNumTiles = (nCurrentHeight + 1) * nWidth;
    for (nTile = nCurrentHeight * nWidth; nTile < nNumTiles; nTile++)
    {
        struct NWNX_Area_TileInfo strTileInfo = NWNX_Area_GetTileInfoByTileIndex(oArea, nTile);
        string sCAE = TS_GetCornersAndEdgesAsString(TS_GetTileEdgesAndCorners(EP_AREA_TILESET, strTileInfo.nID));

        if (FindSubString(sCAE, "GRASS") != -1)
        {
            vector vTilePosition = GetTilePosition(strTileInfo.nGridX, strTileInfo.nGridY);

            if (NWNX_Area_GetPathExists(oArea, vEntrancePosition, vTilePosition, (nHeight * nWidth)))
            {
                location locTile = Location(oArea, vTilePosition, 0.0f);
                int nDistanceFromEntrance = abs(strEntrancePosition.nX - strTileInfo.nGridX) + abs(strEntrancePosition.nY - strTileInfo.nGridY);
                int nDistanceFromExit = abs(strExitPosition.nX - strTileInfo.nGridX) + abs(strExitPosition.nY - strTileInfo.nGridY);
                int nDistanceFromPath = EP_NearestPathDistance(sAreaID, strTileInfo.nGridX, strTileInfo.nGridY);
                int bIsGroupTile = TS_GetIsTilesetGroupTile(EP_AREA_TILESET, strTileInfo.nID);
                int nNumDoors = TS_GetTilesetNumDoors(EP_AREA_TILESET, strTileInfo.nID);

                sqlquery sql = SqlPrepareQueryModule(sQuery);
                SqlBindString(sql, "@area_id", sAreaID);
                SqlBindInt(sql, "@tile_index", nTile);
                SqlBindInt(sql, "@tile_x", strTileInfo.nGridX);
                SqlBindInt(sql, "@tile_y", strTileInfo.nGridY);
                SqlBindInt(sql, "@tile_id", strTileInfo.nID);
                SqlBindInt(sql, "@entrance_dist", nDistanceFromEntrance);
                SqlBindInt(sql, "@exit_dist", nDistanceFromExit);
                SqlBindInt(sql, "@path_dist", nDistanceFromPath);
                SqlBindInt(sql, "@group_tile", bIsGroupTile);
                SqlBindInt(sql, "@num_doors", nNumDoors);
                SqlStep(sql);
            }
        }
    }

    SqlCommitTransactionModule();

    DelayCommand(EP_POSTPROCESS_DELAY, EP_PostProcess(oArea, ++nCurrentHeight));
}

// @CONSOLE[EPSpawnDoors::]
void EP_SpawnDoors()
{
    object oPlayer = OBJECT_SELF;
    object oArea = GetArea(oPlayer);
    int nTileIndex = GetTileIndexFromPosition(oArea, GetPosition(oPlayer));

    if (nTileIndex != -1)
    {
        struct NWNX_Area_TileInfo strTileInfo = NWNX_Area_GetTileInfoByTileIndex(oArea, nTileIndex);
        float fTilesetHeighTransition = TS_GetTilesetHeightTransition(EP_AREA_TILESET);
        int nDoor, nNumDoors = TS_GetTilesetNumDoors(EP_AREA_TILESET, strTileInfo.nID);

        for (nDoor = 0; nDoor < nNumDoors; nDoor++)
        {
            struct TS_DoorStruct strDoor = TS_GetTilesetTileDoor(EP_AREA_TILESET, strTileInfo.nID, nDoor);
            string sTag = "TEST_DOOR";

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
            object oDoor = GffTools_CreateDoor(strDoor.nType, locSpawn, sTag);
        }
    }
}

void PortToTile(string sType)
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
    PortToTile(AG_DATA_KEY_ENTRANCE_TILE_INDEX);
}

// @CONSOLE[EPExit::]
void EP_PortToExit()
{
    PortToTile(AG_DATA_KEY_EXIT_TILE_INDEX);
}

