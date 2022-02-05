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

const string EP_LOG_TAG                         = "EndlessPath";
const string EP_SCRIPT_NAME                     = "ef_s_endlesspath";
const int EP_DEBUG_LOG                          = FALSE;

const string EP_TEMPLATE_AREA_JSON              = "TemplateArea";
const string EP_DOOR_TAG_PREFIX                 = "EP_DOOR_";
const string EP_AREA_TAG_PREFIX                 = "AR_EP_";
const string EP_SPAWN_TAG_PREFIX                = "EP_WP_";

const string EP_AREA_TILESET                    = TILESET_RESREF_MEDIEVAL_RURAL_2;
const string EP_AREA_EDGE_TERRAIN               = "TREES";
const int EP_AREA_MINIMUM_LENGTH                = 4;
const int EP_AREA_RANDOM_LENGTH                 = 17;

const int EP_AREA_PATH_NO_ROAD_CHANCE           = 10;
const int EP_AREA_SAND_CHANCE                   = 30;
const int EP_AREA_WATER_CHANCE                  = 40;
const int EP_AREA_MOUNTAIN_CHANCE               = 20;
const int EP_AREA_GRASS2_CHANCE                 = 60;
const int EP_AREA_STREAM_CHANCE                 = 35;
const int EP_AREA_RIDGE_CHANCE                  = 25;
const int EP_AREA_ROAD_CHANCE                   = 40;

string EP_GetLastAreaID();
string EP_GetNextAreaID();
string EP_GetLastDoorID();
string EP_GetNextDoorID();
void EP_SetLastGenerationData(object oArea, int nEdge, int nWidth, int nHeight);
void EP_ToggleTerrainOrCrosser(string sAreaID, object oPreviousArea, string sCrosser, int nChance);
void EP_GenerateArea(string sAreaID, object oPreviousArea, int nEdgeToCopy, int nAreaWidth, int nAreaHeight);
object EP_CreateDoor(object oArea, int nTileIndex);
object EP_CreateArea(string sAreaID);

// @CORE[EF_SYSTEM_INIT]
void EP_Init()
{
    object oTemplateArea = GetArea(GetObjectByTag(EP_GetLastDoorID()));
    json jTemplateArea = ObjectToJson(oTemplateArea);
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/Creature List");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/Door List");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/Encounter List");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/Placeable List");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/SoundList");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/StoreList");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/TriggerList");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/WaypointList");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/AreaEffectList");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/List");
         jTemplateArea = GffRemoveList(jTemplateArea, "GIT/value/VarTable");
         jTemplateArea = GffRemoveString(jTemplateArea, "GIT/value/NWNX_POS");
         jTemplateArea = GffRemoveList(jTemplateArea, "ARE/value/Tile_List");
         jTemplateArea = GffReplaceLocString(jTemplateArea, "ARE/value/Name", "The Endless Path");
         jTemplateArea = GffReplaceInt(jTemplateArea, "GIT/value/AreaProperties/value/MusicDay", 128);

    SetLocalJson(GetDataObject(EP_SCRIPT_NAME), EP_TEMPLATE_AREA_JSON, jTemplateArea);
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
        Events_RemoveObjectFromDispatchList(EP_SCRIPT_NAME, Events_GetObjectEventName(EVENT_SCRIPT_AREA_ON_ENTER), oArea);
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
    }
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
    string sPreviousAreaID = GetTag(oPreviousArea);
    if ((sCrosser == "WATER" && AG_GetIntDataByKey(sPreviousAreaID, AG_DATA_KEY_EXIT_EDGE_HAS_WATER)) ||
        (sCrosser == "MOUNTAIN" && AG_GetIntDataByKey(sPreviousAreaID, AG_DATA_KEY_EXIT_EDGE_HAS_MOUNTAIN)))
        return;

    if (!(Random(100) < nChance))
        AG_SetIgnoreTerrainOrCrosser(sAreaID, sCrosser);
}

void EP_GenerateArea(string sAreaID, object oPreviousArea, int nEdgeToCopy, int nAreaWidth, int nAreaHeight)
{
    EP_SetLastGenerationData(oPreviousArea, nEdgeToCopy, nAreaWidth, nAreaHeight);

    AG_InitializeRandomArea(sAreaID, EP_AREA_TILESET, EP_AREA_EDGE_TERRAIN, nAreaWidth, nAreaHeight);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS, EP_DEBUG_LOG);
    AG_SetCallbackFunction(sAreaID, EP_SCRIPT_NAME, "EP_OnAreaGenerated");

    AG_AddPathDoorCrosserCombo(sAreaID, 80, "ROAD");
    AG_AddPathDoorCrosserCombo(sAreaID, 1161, "STREET");
    AG_SetAreaPathDoorCrosserCombo(sAreaID, Random(100) < EP_AREA_ROAD_CHANCE ? 0 : 1);

    AG_SetIgnoreTerrainOrCrosser(sAreaID, "ROAD");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "WALL");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "BRIDGE");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "STREET");

    if (sAreaID != EP_AREA_TAG_PREFIX + "1")
    {
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "SAND", EP_AREA_SAND_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "WATER", EP_AREA_WATER_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "MOUNTAIN", EP_AREA_MOUNTAIN_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "GRASS2", EP_AREA_GRASS2_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "STREAM", EP_AREA_STREAM_CHANCE);
        EP_ToggleTerrainOrCrosser(sAreaID, oPreviousArea, "RIDGE", EP_AREA_RIDGE_CHANCE);
    }

    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_PATH_NO_ROAD_CHANCE, EP_AREA_PATH_NO_ROAD_CHANCE);
    AG_CopyEdgeFromArea(sAreaID, oPreviousArea, nEdgeToCopy);
    AG_GenerateEdge(sAreaID, AG_AREA_EDGE_TOP);
    AG_GenerateEdge(sAreaID, AG_AREA_EDGE_BOTTOM);
    AG_GenerateEdge(sAreaID, AG_AREA_EDGE_LEFT);
    AG_GenerateEdge(sAreaID, AG_AREA_EDGE_RIGHT);
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
        //case 0: strDoor.fOrientation += 0.0f ; break;
        case 1: strDoor.fOrientation += 90.0f; break;
        case 2: strDoor.fOrientation += 180.0f; break;
        case 3: strDoor.fOrientation += 270.0f; break;
    }

    location locSpawn = Location(oArea, vDoorPosition, strDoor.fOrientation);

    return NWNX_Util_CreateDoor(strDoor.sResRef, locSpawn, sTag, strDoor.nType);
}

object EP_CreateArea(string sAreaID)
{
    json jArea = GetLocalJson(GetDataObject(EP_SCRIPT_NAME), EP_TEMPLATE_AREA_JSON);
    jArea = GffReplaceString(jArea, "ARE/value/Tag", sAreaID);
    jArea = GffReplaceInt(jArea, "ARE/value/Height", AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT));
    jArea = GffReplaceInt(jArea, "ARE/value/Width", AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH));

    jArea = GffReplaceLocString(jArea, "ARE/value/Name", "The Endless Path (" +
        GetSubString(sAreaID, GetStringLength(EP_AREA_TAG_PREFIX), GetStringLength(sAreaID) - GetStringLength(EP_AREA_TAG_PREFIX)) + ")");

    json jTileList = JsonArray();
    int nTile, nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        int nTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
        int nOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
        int nHeight = AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);

        jTileList = GffAddTile(jTileList, nTileID, nOrientation, nHeight);
    }

    jArea = GffAddList(jArea, "ARE/value/Tile_List", jTileList);

    return JsonToObject(jArea, GetStartingLocation());
}

void EP_OnAreaGenerated(string sAreaID)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED))
    {
        WriteLog(EP_LOG_TAG, "* Generation Failure: " + sAreaID + ", retrying...");
        object oDataObject = GetDataObject(EP_SCRIPT_NAME);
        object oArea = GetLocalObject(oDataObject, "LAST_AREA");
        int nEdge = GetLocalInt(oDataObject, "LAST_EDGE");
        int nWidth = GetLocalInt(oDataObject, "LAST_WIDTH");
        int nHeight = GetLocalInt(oDataObject, "LAST_HEIGHT");

        EP_GenerateArea(sAreaID, oArea, nEdge, nWidth, nHeight);
        return;
    }

    object oArea = EP_CreateArea(sAreaID);
    Events_SetAreaEventScripts(oArea);
    Events_AddObjectToDispatchList(EP_SCRIPT_NAME, Events_GetObjectEventName(EVENT_SCRIPT_AREA_ON_ENTER), oArea);

    object oPreviousDoor = GetObjectByTag(EP_GetLastDoorID());
    object oEntranceDoor = EP_CreateDoor(oArea, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX));
    object oExitDoor = EP_CreateDoor(oArea, AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_EXIT_TILE_INDEX));

    SetTransitionTarget(oPreviousDoor, oEntranceDoor);
    SetTransitionTarget(oEntranceDoor, oPreviousDoor);
}

// @PMBUTTON[Check Path]
void EP_CheckPath()
{
    object oPlayer = OBJECT_SELF;
    object oArea = GetArea(oPlayer);
    string sAreaID = GetTag(oArea);
    int nArea = StringToInt(GetSubString(sAreaID, GetStringLength(EP_AREA_TAG_PREFIX), GetStringLength(sAreaID) - GetStringLength(EP_AREA_TAG_PREFIX)));
    object oEntranceDoor = GetObjectByTag(EP_DOOR_TAG_PREFIX + IntToString((nArea * 2) - 1));

    struct ProfilerData pd = Profiler_Start("NWNX_Area_GetPathExists");
    int bPathExists = NWNX_Area_GetPathExists(oArea, GetPosition(oEntranceDoor), GetPosition(oPlayer), AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES));
    Profiler_Stop(pd);

    SendMessageToPC(oPlayer, "GetPathExistsFromEntrance: " + (bPathExists ? "TRUE" : "FALSE"));
}

// @PMBUTTON[PostProcess]
void EP_PostProcessArea()
{
    struct ProfilerData pd = Profiler_Start("EP_PostProcessArea");
    object oArea = GetArea(OBJECT_SELF);
    string sAreaID = GetTag(oArea);
    int nArea = StringToInt(GetSubString(sAreaID, GetStringLength(EP_AREA_TAG_PREFIX), GetStringLength(sAreaID) - GetStringLength(EP_AREA_TAG_PREFIX)));
    object oEntranceDoor = GetObjectByTag(EP_DOOR_TAG_PREFIX + IntToString((nArea * 2) - 1));
    vector vEntranceDoor = GetPosition(oEntranceDoor);

    struct GffTools_PlaceableData pdMarker;
    pdMarker.nModel = 76;
    pdMarker.sTag = EP_SPAWN_TAG_PREFIX;
    pdMarker.sName = "Marker";
    pdMarker.sDescription = "A spawnpoint marker";
    pdMarker.bPlot = TRUE;
    pdMarker.bUseable = TRUE;
    json jMarker = GffTools_GeneratePlaceable(pdMarker);

    int nMarker, nTile, nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        struct NWNX_Area_TileInfo strTileInfo = NWNX_Area_GetTileInfoByTileIndex(oArea, nTile);
        struct TS_TileStruct strTile = TS_GetCornersAndEdgesByOrientation(EP_AREA_TILESET, strTileInfo.nID, strTileInfo.nOrientation);
        string sCAE = TS_GetCornersAndEdgesAsString(strTile);

        if (FindSubString(sCAE, "GRASS") != -1)
        {
            int nTileX = strTileInfo.nGridX, nTileY = strTileInfo.nGridY;

            vector vTilePosition = Vector((nTileX * 10.0f) + 5.0f, (nTileY * 10.0f) + 5.0, 0.0f);
            int bPathExists = NWNX_Area_GetPathExists(oArea, vEntranceDoor, vTilePosition, nNumTiles);

            if (bPathExists)
            {
                vTilePosition.z = GetGroundHeight(Location(oArea, vTilePosition, 0.0f));
                location locSpawn = Location(oArea, vTilePosition, 0.0f);

                if (StringToInt(Get2DAString("surfacemat", "Walk", GetSurfaceMaterial(locSpawn))))
                {
                    object oMarker = GffTools_CreatePlaceable(jMarker, locSpawn, EP_SPAWN_TAG_PREFIX + sAreaID + "_" + IntToString(nMarker++));
                }
            }

            /*
            if (GetStringLeft(strTile.sTL, 5) == "GRASS")
            {
                vector vTilePosition = Vector((nTileX * 10.0f) + 2.5f, (nTileY * 10.0f) + 7.5, 0.0f);
                int bPathExists = NWNX_Area_GetPathExists(oArea, vEntranceDoor, vTilePosition, nNumTiles);

                if (bPathExists)
                {
                    vTilePosition.z = GetGroundHeight(Location(oArea, vTilePosition, 0.0f));
                    location locSpawn = Location(oArea, vTilePosition, 0.0f);

                    if (StringToInt(Get2DAString("surfacemat", "Walk", GetSurfaceMaterial(locSpawn))))
                    {
                        object oMarker = GffTools_CreatePlaceable(jMarker, locSpawn, EP_SPAWN_TAG_PREFIX + sAreaID + "_" + IntToString(nMarker++));
                    }
                }
            }

            if (GetStringLeft(strTile.sTR, 5) == "GRASS")
            {
                vector vTilePosition = Vector((nTileX * 10.0f) + 7.5f, (nTileY * 10.0f) + 7.5, 0.0f);
                int bPathExists = NWNX_Area_GetPathExists(oArea, vEntranceDoor, vTilePosition, nNumTiles);

                if (bPathExists)
                {
                    vTilePosition.z = GetGroundHeight(Location(oArea, vTilePosition, 0.0f));
                    location locSpawn = Location(oArea, vTilePosition, 0.0f);

                    if (StringToInt(Get2DAString("surfacemat", "Walk", GetSurfaceMaterial(locSpawn))))
                    {
                        object oMarker = GffTools_CreatePlaceable(jMarker, locSpawn, EP_SPAWN_TAG_PREFIX + sAreaID + "_" + IntToString(nMarker++));
                    }
                }
            }

            if (GetStringLeft(strTile.sBL, 5) == "GRASS")
            {
                vector vTilePosition = Vector((nTileX * 10.0f) + 2.5f, (nTileY * 10.0f) + 2.5, 0.0f);
                int bPathExists = NWNX_Area_GetPathExists(oArea, vEntranceDoor, vTilePosition, nNumTiles);

                if (bPathExists)
                {
                    vTilePosition.z = GetGroundHeight(Location(oArea, vTilePosition, 0.0f));
                    location locSpawn = Location(oArea, vTilePosition, 0.0f);

                    if (StringToInt(Get2DAString("surfacemat", "Walk", GetSurfaceMaterial(locSpawn))))
                    {
                        object oMarker = GffTools_CreatePlaceable(jMarker, locSpawn, EP_SPAWN_TAG_PREFIX + sAreaID + "_" + IntToString(nMarker++));
                    }
                }
            }

            if (GetStringLeft(strTile.sBR, 5) == "GRASS")
            {
                vector vTilePosition = Vector((nTileX * 10.0f) + 7.5f, (nTileY * 10.0f) + 2.5, 0.0f);
                int bPathExists = NWNX_Area_GetPathExists(oArea, vEntranceDoor, vTilePosition, nNumTiles);

                if (bPathExists)
                {
                    vTilePosition.z = GetGroundHeight(Location(oArea, vTilePosition, 0.0f));
                    location locSpawn = Location(oArea, vTilePosition, 0.0f);

                    if (StringToInt(Get2DAString("surfacemat", "Walk", GetSurfaceMaterial(locSpawn))))
                    {
                        object oMarker = GffTools_CreatePlaceable(jMarker, locSpawn, EP_SPAWN_TAG_PREFIX + sAreaID + "_" + IntToString(nMarker++));
                    }
                }
            }
            */

            //WriteLog(EP_LOG_TAG, "Grass: Tile=" + IntToString(nTile) + " [" + IntToString(nTileX) + "," + IntToString(nTileY) + "] Path: " + (bPathExists ? "TRUE" : "FALSE"));
        }
    }

    Profiler_Stop(pd);
}

