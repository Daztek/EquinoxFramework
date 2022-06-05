/*
    Script: ef_s_endlesscave
    Author: Daz
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_areagen"
#include "ef_s_endlesspath"
#include "ef_s_gfftools"
#include "nwnx_object"

const string EC_LOG_TAG                         = "EndlessCave";
const string EC_SCRIPT_NAME                     = "ef_s_endlesscave";
const int EC_DEBUG_LOG                          = FALSE;

const string EC_TEMPLATE_CAVE_AREA_TAG          = "AR_TEMPLATECAVE";
const string EC_TEMPLATE_AREA_JSON              = "TemplateArea";
const string EC_DOOR_TAG_PREFIX                 = "EC_DOOR_";
const string EC_AREA_TAG_PREFIX                 = "AR_EC_";

const float EC_CAVE_GENERATION_DELAY            = 0.1f;
const string EC_AREA_TILESET                    = TILESET_RESREF_MINES_AND_CAVERNS;
const int EC_MAX_ITERATIONS                     = 10;
const string EC_AREA_DEFAULT_EDGE_TERRAIN       = "WALL";

const int EC_AREA_SMALL_MINIMUM_LENGTH          = 4;
const int EC_AREA_SMALL_RANDOM_LENGTH           = 5;
const int EC_AREA_BIG_MINIMUM_LENGTH            = 8;
const int EC_AREA_BIG_RANDOM_LENGHT             = 9;

const int EC_AREA_WATER_CHANCE                  = 25;

const int EC_AREA_CAVE_ENTRANCE_TILE            = 198;
const int EC_AREA_PARENT_MINE_ENTRANCE_TILE_1   = 1098;
const int EC_AREA_PARENT_MINE_ENTRANCE_TILE_2   = 1099;
const int EC_AREA_PARENT_CLIFF_ENTRANCE_TILE    = 156;

const int EC_CAVE_TYPE_CAVE                     = 0;
const int EC_CAVE_TYPE_CLIFF                    = 1;
const int EC_CAVE_TYPE_MINE                     = 2;

int EC_GetRandomLightingScheme();
int EC_GetTypeFromTileID(int nTileID);
string EC_GetNextAreaID();
string EC_GetNextDoorID();
int EC_GetCaveNum(string sAreaID);
void EC_ToggleTerrainOrCrosser(string sAreaID, string sCrosser, int nChance);
void EC_GenerateCave(json jCave);

// @CORE[EF_SYSTEM_INIT]
void EC_Init()
{
    object oTemplateArea = GetObjectByTag(EC_TEMPLATE_CAVE_AREA_TAG);

    SetLocalJson(GetDataObject(EC_SCRIPT_NAME), EC_TEMPLATE_AREA_JSON, GffTools_GetScrubbedAreaTemplate(oTemplateArea));
    DestroyArea(oTemplateArea);
}

// @EVENT[EP_AREA_POST_PROCESS_FINISHED]
void EC_OnAreaPostProcessed()
{
    object oArea = OBJECT_SELF;
    object oDataObject = GetDataObject(EC_SCRIPT_NAME);
    string sParentAreaID = GetTag(oArea);
    json jCaves = JsonArray();

    string sQuery = "SELECT tile_index, tile_id FROM " + EP_GetTilesTable() +
                    "WHERE area_id = @area_id AND group_tile = 1 AND num_doors = 1;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@area_id", sParentAreaID);

    while (SqlStep(sql))
    {
        int nTileIndex = SqlGetInt(sql, 0);
        int nTileID = SqlGetInt(sql, 1);

        if (nTileID == EC_AREA_PARENT_CLIFF_ENTRANCE_TILE || FindSubString(TS_GetCornersAndEdgesAsString(TS_GetTileEdgesAndCorners(EP_AREA_TILESET, nTileID)), "MOUNTAIN") != -1)
        {
            string sCaveAreaID = EC_GetNextAreaID();
            json jCave = JsonObject();
                 jCave = JsonObjectSetString(jCave, "parent_area", sParentAreaID);
                 jCave = JsonObjectSetInt(jCave, "exit_index", nTileIndex);
                 jCave = JsonObjectSetString(jCave, "area_id", sCaveAreaID);
                 jCave = JsonObjectSetInt(jCave, "tile_id", nTileID);
                 jCave = JsonObjectSetInt(jCave, "type", EC_GetTypeFromTileID(nTileID));
                 jCave = JsonObjectSetInt(jCave, "lighting_scheme", EC_GetRandomLightingScheme());
            jCaves = JsonArrayInsert(jCaves, jCave);
            SetLocalJson(oDataObject, sCaveAreaID, jCave);
        }
    }

    int nCave, nNumCaves = JsonGetLength(jCaves);
    if (nNumCaves)
    {
        WriteLog(EC_LOG_TAG, "* Generating Caves for Area: " + sParentAreaID + " -> Amount: " + IntToString(nNumCaves));

        for (nCave = 0; nCave < nNumCaves; nCave++)
        {
            json jCave = JsonArrayGet(jCaves, nCave);

            WriteLog(EC_LOG_TAG, "  > Tile: " + IntToString(JsonObjectGetInt(jCave, "exit_index")) +
                                 ", Type: " + IntToString(JsonObjectGetInt(jCave, "type")) +
                                 ", ID: " + JsonObjectGetString(jCave, "area_id") +
                                 ", Lighting: " + Get2DAString("environment", "LABEL", JsonObjectGetInt(jCave, "lighting_scheme")));

            DelayCommand(EC_CAVE_GENERATION_DELAY * (nCave + 1), EC_GenerateCave(jCave));
        }
    }
}

int EC_GetRandomLightingScheme()
{
    return 12 + Random(10);
}

int EC_GetTypeFromTileID(int nTileID)
{
    switch (nTileID)
    {
        case EC_AREA_PARENT_CLIFF_ENTRANCE_TILE:
            return EC_CAVE_TYPE_CLIFF;

        case EC_AREA_PARENT_MINE_ENTRANCE_TILE_1:
        case EC_AREA_PARENT_MINE_ENTRANCE_TILE_2:
            return EC_CAVE_TYPE_MINE;
    }

    return EC_CAVE_TYPE_CAVE;
}

string EC_GetNextAreaID()
{
    object oDataObject = GetDataObject(EC_SCRIPT_NAME);
    int nID = GetLocalInt(oDataObject, "AREA_ID") + 1;
    SetLocalInt(oDataObject, "AREA_ID", nID);
    return EC_AREA_TAG_PREFIX + IntToString(nID);
}

string EC_GetNextDoorID()
{
    object oDataObject = GetDataObject(EC_SCRIPT_NAME);
    int nID = GetLocalInt(oDataObject, "DOOR_ID") + 1;
    SetLocalInt(oDataObject, "DOOR_ID", nID);
    return EC_DOOR_TAG_PREFIX + IntToString(nID);
}

int EC_GetCaveNum(string sAreaID)
{
    int nPrefixLength = GetStringLength(EC_AREA_TAG_PREFIX);
    return StringToInt(GetSubString(sAreaID, nPrefixLength, GetStringLength(sAreaID) - nPrefixLength));
}

void EC_ToggleTerrainOrCrosser(string sAreaID, string sCrosser, int nChance)
{
    AG_SetIgnoreTerrainOrCrosser(sAreaID, sCrosser, !(Random(100) < nChance));
}

json EC_GetCaveSize()
{
    json jArray = JsonArray();
    int nRandom = Random(100);

    if (nRandom < 80)
    {// Smallish
        jArray = JsonArrayInsertInt(jArray, EC_AREA_SMALL_MINIMUM_LENGTH + Random(EC_AREA_SMALL_RANDOM_LENGTH));
        jArray = JsonArrayInsertInt(jArray, EC_AREA_SMALL_MINIMUM_LENGTH + Random(EC_AREA_SMALL_RANDOM_LENGTH));
    }
    else if (nRandom < 90)
    {// Longish
        jArray = JsonArrayInsertInt(jArray, EC_AREA_SMALL_MINIMUM_LENGTH + Random(EC_AREA_SMALL_RANDOM_LENGTH));
        jArray = JsonArrayInsertInt(jArray, EC_AREA_BIG_MINIMUM_LENGTH + Random(EC_AREA_BIG_RANDOM_LENGHT), Random(2) ? 0 : -1);
    }
    else
    {// Bigish
        jArray = JsonArrayInsertInt(jArray, EC_AREA_BIG_MINIMUM_LENGTH + Random(EC_AREA_BIG_RANDOM_LENGHT));
        jArray = JsonArrayInsertInt(jArray, EC_AREA_BIG_MINIMUM_LENGTH + Random(EC_AREA_BIG_RANDOM_LENGHT));
    }

    return jArray;
}

void EC_GenerateCave(json jCave)
{
    string sAreaID = JsonObjectGetString(jCave, "area_id");
    int nTileID = JsonObjectGetInt(jCave, "tile_id");
    int nType = JsonObjectGetInt(jCave, "type");

    json jAreaSize = EC_GetCaveSize();
    int nAreaWidth = JsonArrayGetInt(jAreaSize, 0);
    int nAreaHeight = JsonArrayGetInt(jAreaSize, 1);

    AG_InitializeRandomArea(sAreaID, EC_AREA_TILESET, EC_AREA_DEFAULT_EDGE_TERRAIN, nAreaWidth, nAreaHeight);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS, EC_DEBUG_LOG);
    AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_MAX_ITERATIONS, EC_MAX_ITERATIONS);
    AG_SetCallbackFunction(sAreaID, EC_SCRIPT_NAME, "EC_OnCaveGenerated");

    AG_SetIgnoreTerrainOrCrosser(sAreaID, "FENCE");
    AG_SetIgnoreTerrainOrCrosser(sAreaID, "BRIDGE");

    if (nType != EC_CAVE_TYPE_MINE)
    {
        AG_SetIgnoreTerrainOrCrosser(sAreaID, "CORRIDOR");
        AG_SetIgnoreTerrainOrCrosser(sAreaID, "TRACKS");
        AG_SetIgnoreTerrainOrCrosser(sAreaID, "DOORWAY");
    }

    EC_ToggleTerrainOrCrosser(sAreaID, "WATER", EC_AREA_WATER_CHANCE);

    AG_CreateRandomEntrance(sAreaID, EC_AREA_CAVE_ENTRANCE_TILE);
    AG_GenerateArea(sAreaID);
}

object EC_CreateArea(json jCave)
{
    string sAreaID = JsonObjectGetString(jCave, "area_id");
    int nType = JsonObjectGetInt(jCave, "type");
    int nLightingScheme = JsonObjectGetInt(jCave, "lighting_scheme");

    json jArea = GetLocalJson(GetDataObject(EC_SCRIPT_NAME), EC_TEMPLATE_AREA_JSON);
    jArea = GffReplaceString(jArea, "ARE/value/Tag", sAreaID);
    jArea = GffReplaceInt(jArea, "ARE/value/Height", AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT));
    jArea = GffReplaceInt(jArea, "ARE/value/Width", AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH));
    jArea = GffReplaceLocString(jArea, "ARE/value/Name", nType == EC_CAVE_TYPE_MINE ? "Abandoned Mine" : "Mysterious Cave");
    jArea = GffAddList(jArea, "ARE/value/Tile_List", AG_GetTileList(sAreaID));
    jArea = GffSetLightingScheme(jArea, nLightingScheme);

    return JsonToObject(jArea, GetStartingLocation());
}

object EC_CreateDoor(string sAreaID, int nTileIndex)
{
    object oArea = GetObjectByTag(sAreaID);
    string sTileset = AG_GetStringDataByKey(sAreaID, AG_DATA_KEY_TILESET);
    struct NWNX_Area_TileInfo strTileInfo = NWNX_Area_GetTileInfoByTileIndex(oArea, nTileIndex);
    float fTilesetHeighTransition = TS_GetTilesetHeightTransition(sTileset);
    struct TS_DoorStruct strDoor = TS_GetTilesetTileDoor(sTileset, strTileInfo.nID, 0);
    string sTag = EC_GetNextDoorID();

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

void EC_OnCaveGenerated(string sAreaID)
{
    json jCave = GetLocalJson(GetDataObject(EC_SCRIPT_NAME), sAreaID);

    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED))
    {
        EC_GenerateCave(jCave);
    }
    else
    {
        string sParentAreaID = JsonObjectGetString(jCave, "parent_area");
        int nParentAreaDoorTile = JsonObjectGetInt(jCave, "exit_index");
        int nCaveAreaDoorTile = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_ENTRANCE_TILE_INDEX);

        object oCaveArea = EC_CreateArea(jCave);
        object oCaveDoor = EC_CreateDoor(sAreaID, nCaveAreaDoorTile);
        object oParentAreaDoor = EC_CreateDoor(sParentAreaID, nParentAreaDoorTile);

        object oMapNote = CreateWaypoint(GetLocation(oParentAreaDoor), "WP_EC_" + GetTag(oParentAreaDoor));
        NWNX_Object_SetMapNote(oMapNote, GetName(oCaveArea));
        SetMapPinEnabled(oMapNote, TRUE);

        SetTransitionTarget(oCaveDoor, oParentAreaDoor);
        SetTransitionTarget(oParentAreaDoor, oCaveDoor);
    }
}

// @GUIEVENT[GUIEVENT_MINIMAP_MAPPIN_CLICK]
void EC_OnMapPinClick()
{
    object oPlayer = OBJECT_SELF;
    object oMapPin = GetLastGuiEventObject();

    if (GetStringLeft(GetTag(oMapPin), 6) == "WP_EC_")
    {
        AssignCommand(oPlayer, ClearAllActions());
        AssignCommand(oPlayer, JumpToObject(oMapPin));
    }
}

