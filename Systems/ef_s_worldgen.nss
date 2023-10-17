/*
    Script: ef_s_worldgen
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_areagen"
#include "ef_s_eventman"
#include "ef_s_profiler"
#include "ef_s_areamusic"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_gfftools"

#include "nwnx_player"

const string WG_SCRIPT_NAME                                     = "ef_s_worldgen";
const int WG_DEBUG_LOG                                          = FALSE;
const int WG_ENABLE_AREA_CACHING                                = FALSE;
const int WG_ENABLE_VFX_EDGE                                    = TRUE;

const int WG_AREA_LENGTH                                        = 5;
const int WG_WORLD_WIDTH                                        = 15;
const int WG_WORLD_HEIGHT                                       = 15;
const int WG_VFX_TILE_BORDER_SIZE                               = 5;

const int WG_AREA_SAND_CHANCE                                   = 15;
const int WG_AREA_WATER_CHANCE                                  = 25;
const int WG_AREA_TREES_CHANCE                                  = 25;
const int WG_AREA_CHASM_CHANCE                                  = 10;
const int WG_AREA_GRASS2_CHANCE                                 = 25;
const int WG_AREA_MOUNTAIN_CHANCE                               = 35;
const int WG_AREA_STREAM_CHANCE                                 = 10;
const int WG_AREA_RIDGE_CHANCE                                  = 20;

const string WG_TEMPLATE_AREA_TAG                               = "AR_TEMPLATEAREA";
const string WG_TEMPLATE_AREA_JSON                              = "TemplateArea";
const string WG_AREA_TAG_PREFIX                                 = "AR_W_";
const int WG_AREA_STARTING_X                                    = 10000;
const int WG_AREA_STARTING_Y                                    = 10000;

const string WG_GENERATED_AREAS_ARRAY                           = "GeneratedAreas";

const string WG_WORLD_SEED_NAME                                 = "WG_WORLD_SEED";

const string WG_AREA_TILESET                                    = TILESET_RESREF_MEDIEVAL_RURAL_2;
const int WG_MAX_ITERATIONS                                     = 100;
const string WG_AREA_DEFAULT_EDGE_TERRAIN                       = "";

const int WG_NEIGHBOR_AREA_TOP                                  = 0;
const int WG_NEIGHBOR_AREA_RIGHT                                = 1;
const int WG_NEIGHBOR_AREA_BOTTOM                               = 2;
const int WG_NEIGHBOR_AREA_LEFT                                 = 3;
const int WG_NEIGHBOR_AREA_TOP_LEFT                             = 4;
const int WG_NEIGHBOR_AREA_TOP_RIGHT                            = 5;
const int WG_NEIGHBOR_AREA_BOTTOM_RIGHT                         = 6;
const int WG_NEIGHBOR_AREA_BOTTOM_LEFT                          = 7;

const string WG_AREA_GENERATION_QUEUE                           = "AreaGenerationQueue";

const string WG_MAP_WINDOW_ID                                   = "WORLDMAP";
const float WG_MAP_AREA_SIZE                                    = 20.0f;
const string WG_MAP_BIND_BUTTON_REFRESH                         = "btn_refresh";
const string WG_MAP_BIND_COLOR                                  = "_color";

const int WG_MAP_COLOR_PLAYER                                   = 1;
const int WG_MAP_COLOR_AVAILABLE                                = 2;
const int WG_MAP_COLOR_QUEUED                                   = 3;
const int WG_MAP_COLOR_GENERATING                               = 4;

const string WG_AREA_CACHE_TABLE_NAME                           = "area_cache";

const string WG_VFX_PLACEABLE_TEMPLATE                          = "VFXPlaceableTemplate";
const string WG_VFX_PLACEABLE_TAG                               = "VFCPLC";
const string WG_VFX_TILE_ID_ARRAY                               = "VFXTileIDArray_";
const string WG_VFX_TILE_MODEL_ARRAY                            = "VFXTileModelArray_";
const int WG_VFX_START_ROW                                      = 1000;
const string WG_VFX_DUMMY_NAME                                  = "dummy_tile_";

void WG_InitializeTemplateArea();
json WG_GetTemplateAreaJson();
void WG_SetWorldSeed(int nSeed);
int WG_GetWorldSeed();
int WG_GetStateHash();

string WG_GetAreaID(int nX, int nY);
string WG_GetStartingAreaID();
struct AG_TilePosition WG_GetAreaCoordinates(string sAreaID);
int WG_GetAreaOutOfBounds(string sAreaID);
int WG_GetIsWGArea(object oArea);
string WG_GetAreaIDFromDirection(string sAreaID, int nDirection);
void WG_MoveToArea(object oPlayer, object oCurrentArea, int nDirection);

void WG_InitializeQueue();
json WG_GetQueue();
void WG_QueuePush(string sAreaID);
void WG_QueuePop();
string WG_QueueGet();
int WG_QueueSize();
int WG_QueueEmpty();
int WG_QueuePosition(string sAreaID);

void WG_GenerateArea();
void WG_OnAreaGenerated(string sAreaID);
object WG_CreateArea(string sAreaID);
void WG_SetAreaModifiers(object oArea);

json WG_GetAreaMapColor(int nColor);
void WG_UpdateMapFull();
void WG_UpdateMapArea(string sAreaID, int nColor, object oPlayer = OBJECT_INVALID);

void WG_InitializeAreaCache();
int WG_GetAreaIsCached(string sAreaID);
void WG_CacheArea(string sAreaID);
int WG_GetCachedArea(string sAreaID);

json WG_GetVFXPlaceableTemplate();
json WG_GetAreaTileIDArray(string sAreaID);
json WG_GetAreaTileModelArray(string sAreaID);
void WG_ApplyTileModelVFX(object oPlaceable, string sAreaID, struct AG_Tile strTile, string sTileModel);
void WG_SpawnVFXEdge(string sAreaID, string sOtherAreaID, int nEdge);
void WG_SpawnVFXEdgeCorner(string sAreaID, int nNeighborDirection);

// @CORE[EF_SYSTEM_INIT]
void WG_Init()
{
    WG_InitializeTemplateArea();
    WG_SetWorldSeed(Random(2147483647));
    WG_InitializeQueue();
    WG_InitializeAreaCache();
}

// @CORE[EF_SYSTEM_LOAD]
void WG_Load()
{
    WG_QueuePush(WG_GetStartingAreaID());
    WG_GenerateArea();
    AreaMusic_AddTrackToTrackList(WG_SCRIPT_NAME, 109, AREAMUSIC_MUSIC_TYPE_DAY_OR_NIGHT);
    AreaMusic_AddTrackToTrackList(WG_SCRIPT_NAME, 128, AREAMUSIC_MUSIC_TYPE_DAY_OR_NIGHT);
    AreaMusic_AddTrackToTrackList(WG_SCRIPT_NAME, 136, AREAMUSIC_MUSIC_TYPE_DAY_OR_NIGHT);
}

// @NWMWINDOW[WG_MAP_WINDOW_ID]
json WG_CreateWindow()
{
    float fWidth = ((WG_MAP_AREA_SIZE + 4.0f) * IntToFloat(WG_WORLD_WIDTH)) + 10.0f;
    float fHeight = 33.0f + ((WG_MAP_AREA_SIZE + 8.0f) * IntToFloat(WG_WORLD_HEIGHT)) + 8.0f;
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, fWidth, fHeight));
    NB_SetWindowTitle(JsonString("World Map"));
    NB_SetWindowTransparent(JsonBool(TRUE));
    NB_SetWindowBorder(JsonBool(FALSE));
        NB_StartColumn();

            int nRow;
            for (nRow = 0; nRow < WG_WORLD_HEIGHT; nRow++)
            {
                NB_StartRow();

                    NB_AddSpacer();

                    int nColumn;
                    for (nColumn = 0; nColumn < WG_WORLD_WIDTH; nColumn++)
                    {
                        int nX = WG_AREA_STARTING_X - (WG_WORLD_WIDTH / 2) + nColumn;
                        int nY = WG_AREA_STARTING_Y + (WG_WORLD_HEIGHT / 2) - nRow;
                        string sAreaID = WG_GetAreaID(nX, nY);

                        NB_StartElement(NuiImage(JsonString("gui_inv_1x1_ol"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_SetId(sAreaID);
                            NB_SetDimensions(WG_MAP_AREA_SIZE, WG_MAP_AREA_SIZE);
                            NB_SetTooltip(JsonString(sAreaID));
                            NB_StartDrawList(JsonBool(FALSE));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(WG_MAP_BIND_COLOR + sAreaID), JsonBool(TRUE), JsonFloat(1.0f),
                                        NuiRect(0.0f, 0.0f, WG_MAP_AREA_SIZE, WG_MAP_AREA_SIZE),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
                            NB_End();
                        NB_End();
                    }

                    NB_AddSpacer();

                NB_End();
            }

        NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[WG_MAP_WINDOW_ID:NUI_EVENT_MOUSEUP:WG_AREA_TAG_PREFIX]
void WG_ClickMapArea()
{
    object oPlayer = OBJECT_SELF;
    object oArea = GetObjectByTag(NuiGetEventElement());

    if (GetIsObjectValid(oArea))
    {
        location loc = Location(oArea, GetAreaCenterPosition(oArea), GetFacing(oPlayer));
        AssignCommand(oPlayer, JumpToLocation(loc));
    }
}

// @EVENT[EVENT_SCRIPT_AREA_ON_ENTER:DL:]
void WG_OnAreaEnter()
{
    object oPlayer = GetEnteringObject();
    if (GetIsPC(oPlayer))
        WG_UpdateMapArea(GetTag(OBJECT_SELF), WG_MAP_COLOR_PLAYER, oPlayer);
}

// @EVENT[EVENT_SCRIPT_AREA_ON_EXIT:DL:]
void WG_OnAreaExit()
{
    object oPlayer = GetExitingObject();
    if (GetIsPC(oPlayer))
        WG_UpdateMapArea(GetTag(OBJECT_SELF), WG_MAP_COLOR_AVAILABLE, oPlayer);
}

// @NWNX[NWNX_ON_CREATURE_ON_AREA_EDGE_ENTER]
void WG_OnAreaEdgeEnter()
{
    object oPlayer = OBJECT_SELF;
    object oArea = EM_NWNXGetObject("AREA");

    if (!GetIsPC(oPlayer) || !WG_GetIsWGArea(oArea))
        return;

    if (EM_NWNXGetInt("TOP"))
        WG_MoveToArea(oPlayer, oArea, WG_NEIGHBOR_AREA_TOP);
    else if (EM_NWNXGetInt("RIGHT"))
        WG_MoveToArea(oPlayer, oArea, WG_NEIGHBOR_AREA_RIGHT);
    else if (EM_NWNXGetInt("BOTTOM"))
        WG_MoveToArea(oPlayer, oArea, WG_NEIGHBOR_AREA_BOTTOM);
    else if (EM_NWNXGetInt("LEFT"))
        WG_MoveToArea(oPlayer, oArea, WG_NEIGHBOR_AREA_LEFT);
}

// @NWNX[NWNX_ON_SERVER_SEND_AREA_BEFORE]
void WG_OnServerSendAreaBefore()
{
    object oPlayer = OBJECT_SELF;
    object oArea = EM_NWNXGetObject("AREA");

    if (WG_GetIsWGArea(oArea))
    {
        string sAreaID = GetTag(oArea);
        json jTileIDArray = WG_GetAreaTileIDArray(sAreaID);
        json jTileModelArray = WG_GetAreaTileModelArray(sAreaID);
        int nModel, nNumModels = JsonGetLength(jTileIDArray);
        for (nModel = 0; nModel < nNumModels; nModel++)
        {
            int nTileID = JsonArrayGetInt(jTileIDArray, nModel);
            string sTileModel = JsonArrayGetString(jTileModelArray, nModel);
            NWNX_Player_SetResManOverride(oPlayer, 2002, WG_VFX_DUMMY_NAME + IntToString(nTileID), sTileModel);
        }
    }
}

// @CONSOLE[WGQueueContents::]
string WG_QueueContents()
{
    return "World Gen Queue Size: " + IntToString(WG_QueueSize()) + "\n" + JsonDump(WG_GetQueue(), 0);
}

// @PMBUTTON[World Map:Display the world map!]
void WG_ShowMapWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, WG_MAP_WINDOW_ID))
        NWM_CloseWindow(oPlayer, WG_MAP_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, WG_MAP_WINDOW_ID))
    {
        WG_UpdateMapFull();
    }
}

void WG_InitializeTemplateArea()
{
    object oArea = GetObjectByTag(WG_TEMPLATE_AREA_TAG);
    SetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_TEMPLATE_AREA_JSON, GffTools_GetScrubbedAreaTemplate(oArea));
    DestroyArea(oArea);
}

json WG_GetTemplateAreaJson()
{
    return GetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_TEMPLATE_AREA_JSON);
}

void WG_SetWorldSeed(int nSeed)
{
    SetLocalInt(GetDataObject(WG_SCRIPT_NAME), WG_WORLD_SEED_NAME, nSeed);
    SqlMersenneTwisterSetSeed(WG_WORLD_SEED_NAME, nSeed);
    LogInfo("World Seed: " + IntToString(nSeed));
}

int WG_GetWorldSeed()
{
    return GetLocalInt(GetDataObject(WG_SCRIPT_NAME), WG_WORLD_SEED_NAME);
}

int WG_GetStateHash()
{
    int nHash = GetLocalInt(GetDataObject(WG_SCRIPT_NAME), "StateHash");
    if (!nHash)
    {
        nHash = HashString("SEED:" + IntToString(WG_GetWorldSeed()) +
                           "AREASIZE:" + IntToString(WG_AREA_LENGTH) +
                           "WSX:" + IntToString(WG_AREA_STARTING_X) +
                           "WSY:" + IntToString(WG_AREA_STARTING_Y));
        SetLocalInt(GetDataObject(WG_SCRIPT_NAME), "StateHash", nHash);
    }
    return nHash;
}

string WG_GetAreaID(int nX, int nY)
{
    return WG_AREA_TAG_PREFIX + IntToString(nX) + "_" + IntToString(nY);
}

string WG_GetStartingAreaID()
{
    return WG_GetAreaID(WG_AREA_STARTING_X, WG_AREA_STARTING_Y);
}

struct AG_TilePosition WG_GetAreaCoordinates(string sAreaID)
{
    struct AG_TilePosition str;
    int nPrefixLength = GetStringLength(WG_AREA_TAG_PREFIX);
    string sCoordinates = GetSubString(sAreaID, nPrefixLength, GetStringLength(sAreaID) - nPrefixLength);
    int nDelimiter = FindSubString(sCoordinates, "_");
    str.nX = StringToInt(GetSubString(sCoordinates, 0, nDelimiter));
    str.nY = StringToInt(GetSubString(sCoordinates, nDelimiter + 1, GetStringLength(sCoordinates) - nDelimiter - 1));
    return str;
}

int WG_GetAreaOutOfBounds(string sAreaID)
{
    int nMinX = WG_AREA_STARTING_X - (WG_WORLD_WIDTH / 2);
    int nMaxX = nMinX + (WG_WORLD_WIDTH - 1);
    int nMaxY = WG_AREA_STARTING_Y + (WG_WORLD_HEIGHT / 2);
    int nMinY = nMaxY - (WG_WORLD_HEIGHT - 1);
    struct AG_TilePosition str = WG_GetAreaCoordinates(sAreaID);
    return str.nX < nMinX || str.nX > nMaxX || str.nY < nMinY || str.nY > nMaxY;
}

int WG_GetIsWGArea(object oArea)
{
    return GetStringLeft(GetTag(oArea), GetStringLength(WG_AREA_TAG_PREFIX)) == WG_AREA_TAG_PREFIX;
}

string WG_GetAreaIDFromDirection(string sAreaID, int nDirection)
{
    struct AG_TilePosition str = WG_GetAreaCoordinates(sAreaID);
    switch (nDirection)
    {
        case WG_NEIGHBOR_AREA_TOP:          {              str.nY += 1; break; }
        case WG_NEIGHBOR_AREA_RIGHT:        { str.nX += 1;              break; }
        case WG_NEIGHBOR_AREA_BOTTOM:       {              str.nY -= 1; break; }
        case WG_NEIGHBOR_AREA_LEFT:         { str.nX -= 1;              break; }
        case WG_NEIGHBOR_AREA_TOP_LEFT:     { str.nX -= 1; str.nY += 1; break; }
        case WG_NEIGHBOR_AREA_TOP_RIGHT:    { str.nX += 1; str.nY += 1; break; }
        case WG_NEIGHBOR_AREA_BOTTOM_RIGHT: { str.nX += 1; str.nY -= 1; break; }
        case WG_NEIGHBOR_AREA_BOTTOM_LEFT:  { str.nX -= 1; str.nY -= 1; break; }
    }
    return WG_GetAreaID(str.nX, str.nY);
}

void WG_MoveToArea(object oPlayer, object oCurrentArea, int nDirection)
{
    string sCurrentAreaID = GetTag(oCurrentArea);
    string sNextAreaID = WG_GetAreaIDFromDirection(sCurrentAreaID, nDirection);
    object oNextArea = GetObjectByTag(sNextAreaID);

    if (GetIsObjectValid(oNextArea))
    {
        vector vPosition, vCurrent = GetPosition(oPlayer);
        switch (nDirection)
        {
            case WG_NEIGHBOR_AREA_TOP:
                vPosition = Vector(vCurrent.x, 1.0f, vCurrent.z);
            break;

            case WG_NEIGHBOR_AREA_RIGHT:
                vPosition = Vector(1.0f, vCurrent.y, vCurrent.z);
            break;

            case WG_NEIGHBOR_AREA_BOTTOM:
                vPosition = Vector(vCurrent.x, (WG_AREA_LENGTH * 10.0f) - 1.0f, vCurrent.z);
            break;

            case WG_NEIGHBOR_AREA_LEFT:
                vPosition = Vector((WG_AREA_LENGTH * 10.0f) - 1.0f, vCurrent.y, vCurrent.z);
            break;
        }

        location loc = Location(oNextArea, vPosition, GetFacing(oPlayer));

        AssignCommand(oPlayer, JumpToLocation(loc));
    }
    else if (!WG_GetAreaOutOfBounds(sNextAreaID))
    {
        FloatingTextStringOnCreature("Area not generated! Position in queue: " + IntToString(WG_QueuePosition(sNextAreaID)), oPlayer, FALSE, FALSE);
    }
    else
    {
        FloatingTextStringOnCreature("You've reached the end of the world!", oPlayer, FALSE, FALSE);
    }
}

void WG_InitializeQueue()
{
    SetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_AREA_GENERATION_QUEUE, JSON_ARRAY);
}

json WG_GetQueue()
{
    return GetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_AREA_GENERATION_QUEUE);
}

void WG_QueuePush(string sAreaID)
{
    json jQueue = WG_GetQueue();
    if (!JsonArrayContainsString(jQueue, sAreaID))
        JsonArrayInsertStringInplace(jQueue, sAreaID);
}

void WG_QueuePop()
{
    JsonArrayDelInplace(WG_GetQueue(), 0);
}

string WG_QueueGet()
{
    return JsonArrayGetString(WG_GetQueue(), 0);
}

int WG_QueueSize()
{
    return JsonGetLength(WG_GetQueue());
}

int WG_QueueEmpty()
{
    return !WG_QueueSize();
}

int WG_QueuePosition(string sAreaID)
{
    json jPosition = JsonFind(WG_GetQueue(), JsonString(sAreaID));
    return !JsonGetType(jPosition) ? -1 : JsonGetInt(jPosition);
}

void WG_ToggleTOCs(string sAreaID, json jEdgeTOCs, string sTOC, int nChance)
{
    if (!JsonArrayContainsString(jEdgeTOCs, sTOC))
    {
        AG_SetIgnoreTerrainOrCrosser(sAreaID, sTOC, !(AG_Random(sAreaID, 100) < nChance));
    }
}

json WG_CopyAreaEdge(string sAreaID, int nNeighborDirection, int nDestinationEdge, json jEdgeTOCs)
{
    string sNeighborAreaID = WG_GetAreaIDFromDirection(sAreaID, nNeighborDirection);
    object oNeighborArea = GetObjectByTag(sNeighborAreaID);
    if (GetIsObjectValid(oNeighborArea))
    {
        AG_CopyEdgeFromArea(sAreaID, oNeighborArea, nDestinationEdge);
        jEdgeTOCs = JsonSetOp(jEdgeTOCs, JSON_SET_UNION, AG_GetEdgeTOCs(sNeighborAreaID, nDestinationEdge));
    }
    return jEdgeTOCs;
}

void WG_GenerateArea()
{
    string sAreaID = WG_QueueGet();

    LogInfo("Processing Area: " + sAreaID);

    if (!WG_GetCachedArea(sAreaID))
    {
        AG_InitializeRandomArea(sAreaID, WG_AREA_TILESET, WG_AREA_DEFAULT_EDGE_TERRAIN, WG_AREA_LENGTH, WG_AREA_LENGTH);
        AG_SetStringDataByKey(sAreaID, AG_DATA_KEY_GENERATION_RANDOM_NAME, WG_WORLD_SEED_NAME);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_LOG_STATUS, WG_DEBUG_LOG);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_MAX_ITERATIONS, WG_MAX_ITERATIONS);
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE, AG_Random(WG_WORLD_SEED_NAME, 8));
        AG_SetIntDataByKey(sAreaID, AG_DATA_KEY_ENABLE_CORNER_TILE_VALIDATOR, TRUE);
        AG_SetCallbackFunction(sAreaID, WG_SCRIPT_NAME, "WG_OnAreaGenerated");

        AG_SetIgnoreTerrainOrCrosser(sAreaID, "ROAD");
        AG_SetIgnoreTerrainOrCrosser(sAreaID, "BRIDGE");
        AG_SetIgnoreTerrainOrCrosser(sAreaID, "STREET");
        AG_SetIgnoreTerrainOrCrosser(sAreaID, "WALL");

        json jEdgeTOCs = JsonArray();

        if (sAreaID == WG_GetStartingAreaID())
        {
            int nCenterTile = (WG_AREA_LENGTH / 2) + (WG_AREA_LENGTH * (WG_AREA_LENGTH / 2));
            AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nCenterTile, 1215, AG_Random(WG_WORLD_SEED_NAME, 4), 0, TRUE);
        }
        else
        {
            jEdgeTOCs = WG_CopyAreaEdge(sAreaID, WG_NEIGHBOR_AREA_TOP, AG_AREA_EDGE_BOTTOM, jEdgeTOCs);
            jEdgeTOCs = WG_CopyAreaEdge(sAreaID, WG_NEIGHBOR_AREA_RIGHT, AG_AREA_EDGE_LEFT, jEdgeTOCs);
            jEdgeTOCs = WG_CopyAreaEdge(sAreaID, WG_NEIGHBOR_AREA_BOTTOM, AG_AREA_EDGE_TOP, jEdgeTOCs);
            jEdgeTOCs = WG_CopyAreaEdge(sAreaID, WG_NEIGHBOR_AREA_LEFT, AG_AREA_EDGE_RIGHT, jEdgeTOCs);
            jEdgeTOCs = JsonArrayTransform(jEdgeTOCs, JSON_ARRAY_UNIQUE);
        }

        WG_ToggleTOCs(sAreaID, jEdgeTOCs, "SAND", WG_AREA_SAND_CHANCE);
        WG_ToggleTOCs(sAreaID, jEdgeTOCs, "WATER", WG_AREA_WATER_CHANCE);
        WG_ToggleTOCs(sAreaID, jEdgeTOCs, "TREES", WG_AREA_TREES_CHANCE);
        WG_ToggleTOCs(sAreaID, jEdgeTOCs, "CHASM", WG_AREA_CHASM_CHANCE);
        WG_ToggleTOCs(sAreaID, jEdgeTOCs, "GRASS2", WG_AREA_GRASS2_CHANCE);
        WG_ToggleTOCs(sAreaID, jEdgeTOCs, "MOUNTAIN", WG_AREA_MOUNTAIN_CHANCE);
        WG_ToggleTOCs(sAreaID, jEdgeTOCs, "STREAM", WG_AREA_STREAM_CHANCE);
        WG_ToggleTOCs(sAreaID, jEdgeTOCs, "RIDGE", WG_AREA_RIDGE_CHANCE);
    }

    DelayCommand(0.5f, AG_GenerateArea(sAreaID));
}

void WG_QueueArea(string sAreaID)
{
    if (!GetIsObjectValid(GetObjectByTag(sAreaID)) && !WG_GetAreaOutOfBounds(sAreaID))
    {
        WG_QueuePush(sAreaID);
        WG_UpdateMapArea(sAreaID, WG_MAP_COLOR_QUEUED);
    }
}

void WG_CreateVFXEdge(string sAreaID, int nNeighborDirection)
{
    string sNeighborAreaID = WG_GetAreaIDFromDirection(sAreaID, nNeighborDirection);
    if (GetIsObjectValid(GetObjectByTag(sNeighborAreaID)))
    {
        WG_SpawnVFXEdge(sAreaID, sNeighborAreaID, nNeighborDirection);
        WG_SpawnVFXEdge(sNeighborAreaID, sAreaID, (nNeighborDirection + 2) % 4);
    }
}

void WG_CreateVFXEdgeCorner(string sAreaID, int nNeighborDirection)
{
    string sNeighborAreaID = WG_GetAreaIDFromDirection(sAreaID, nNeighborDirection);
    if (GetIsObjectValid(GetObjectByTag(sNeighborAreaID)))
    {
        WG_SpawnVFXEdgeCorner(sAreaID, nNeighborDirection);
        WG_SpawnVFXEdgeCorner(sNeighborAreaID, (((nNeighborDirection - 4) + 2) % 4) + 4);
    }
}

void WG_OnAreaGenerated(string sAreaID)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED))
    {
        WG_GenerateArea();
    }
    else
    {
        object oArea = WG_CreateArea(sAreaID);
        int bCached = WG_GetAreaIsCached(sAreaID);

        LogInfo("Generated Area " + (bCached ? "From Cache" : "") +  ": " + sAreaID);

        if (!bCached)
            WG_CacheArea(sAreaID);

        EM_SetAreaEventScripts(oArea);
        EM_ObjectDispatchListInsert(oArea, EM_GetObjectDispatchListId(WG_SCRIPT_NAME, EVENT_SCRIPT_AREA_ON_ENTER));
        EM_ObjectDispatchListInsert(oArea, EM_GetObjectDispatchListId(WG_SCRIPT_NAME, EVENT_SCRIPT_AREA_ON_EXIT));
        WG_SetAreaModifiers(oArea);
        WG_UpdateMapArea(sAreaID, WG_MAP_COLOR_AVAILABLE);
        InsertStringToLocalJsonArray(GetDataObject(WG_SCRIPT_NAME), WG_GENERATED_AREAS_ARRAY, sAreaID);

        //if (sAreaID == WG_GetStartingAreaID())
        {
            WG_QueueArea(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_TOP));
            WG_QueueArea(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_RIGHT));
            WG_QueueArea(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_BOTTOM));
            WG_QueueArea(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_LEFT));
        }

        if (WG_ENABLE_VFX_EDGE && sAreaID != WG_GetStartingAreaID())
        {
            WG_CreateVFXEdge(sAreaID, WG_NEIGHBOR_AREA_TOP);
            WG_CreateVFXEdge(sAreaID, WG_NEIGHBOR_AREA_RIGHT);
            WG_CreateVFXEdge(sAreaID, WG_NEIGHBOR_AREA_BOTTOM);
            WG_CreateVFXEdge(sAreaID, WG_NEIGHBOR_AREA_LEFT);
            WG_CreateVFXEdgeCorner(sAreaID, WG_NEIGHBOR_AREA_TOP_LEFT);
            WG_CreateVFXEdgeCorner(sAreaID, WG_NEIGHBOR_AREA_TOP_RIGHT);
            WG_CreateVFXEdgeCorner(sAreaID, WG_NEIGHBOR_AREA_BOTTOM_RIGHT);
            WG_CreateVFXEdgeCorner(sAreaID, WG_NEIGHBOR_AREA_BOTTOM_LEFT);
        }

        WG_QueuePop();
        if (!WG_QueueEmpty())
        {
            WG_UpdateMapArea(WG_QueueGet(), WG_MAP_COLOR_GENERATING);
            WG_GenerateArea();
        }
    }
}

object WG_CreateArea(string sAreaID)
{
    json jArea = WG_GetTemplateAreaJson();
    jArea = GffReplaceString(jArea, "ARE/value/Tag", sAreaID);
    jArea = GffReplaceResRef(jArea, "ARE/value/Tileset", WG_AREA_TILESET);
    jArea = GffReplaceInt(jArea, "ARE/value/Height", AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_HEIGHT));
    jArea = GffReplaceInt(jArea, "ARE/value/Width", AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_WIDTH));
    jArea = GffReplaceLocString(jArea, "ARE/value/Name", sAreaID);
    jArea = GffReplaceInt(jArea, "GIT/value/AreaProperties/value/MusicDay", 0);
    jArea = GffReplaceInt(jArea, "GIT/value/AreaProperties/value/MusicNight", 0);
    jArea = GffReplaceInt(jArea, "GIT/value/AreaProperties/value/MusicBattle", 0);
    jArea = GffReplaceInt(jArea, "ARE/value/WindPower", AG_Random(sAreaID, 2) + 1);
    jArea = GffAddList(jArea, "ARE/value/Tile_List", AG_GetTileList(sAreaID));
    return JsonToObject(jArea, GetStartingLocation());
}

void WG_SetAreaModifiers(object oArea)
{
    Call(Function("ef_s_perloc", "PerLoc_SetAreaDisabled"), ObjectArg(oArea));
    Call(Function("ef_s_dynlight", "DynLight_InitArea"), ObjectArg(oArea));
    AreaMusic_SetAreaTrackList(oArea, WG_SCRIPT_NAME);
    SetAreaGrassOverride(oArea, 3, "trm02_grass3d", 10.0f, 1.0f, Vector(1.0f, 1.0f, 1.0f), Vector(1.0f, 1.0f, 1.0f));
}

json WG_GetAreaMapColor(int nColor)
{
    switch (nColor)
    {
        case WG_MAP_COLOR_PLAYER:       return NuiColor(0, 0, 250, 200);
        case WG_MAP_COLOR_AVAILABLE:    return NuiColor(0, 250, 0, 200);
        case WG_MAP_COLOR_QUEUED:       return NuiColor(250, 0, 0, 200);
        case WG_MAP_COLOR_GENERATING:   return NuiColor(250, 125, 0, 200);
    }
    return NuiColor(0, 0, 0, 0);
}

void WG_UpdateMapFull()
{
    json jGeneratedAreas = GetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_GENERATED_AREAS_ARRAY);
    json jColor = WG_GetAreaMapColor(WG_MAP_COLOR_AVAILABLE);
    int nArea, nNumAreas = JsonGetLength(jGeneratedAreas);
    for (nArea = 0; nArea < nNumAreas; nArea++)
    {
        NWM_SetBind(WG_MAP_BIND_COLOR + JsonArrayGetString(jGeneratedAreas, nArea), jColor);
    }

    json jQueuedAreas = WG_GetQueue();
    jColor = WG_GetAreaMapColor(WG_MAP_COLOR_QUEUED);
    nNumAreas = JsonGetLength(jQueuedAreas);
    for (nArea = 0; nArea < nNumAreas; nArea++)
    {
        if (!nArea)
            NWM_SetBind(WG_MAP_BIND_COLOR + JsonArrayGetString(jQueuedAreas, nArea), WG_GetAreaMapColor(WG_MAP_COLOR_GENERATING));
        else
            NWM_SetBind(WG_MAP_BIND_COLOR + JsonArrayGetString(jQueuedAreas, nArea), jColor);
    }

    object oArea = GetArea(NWM_GetPlayer());
    if (WG_GetIsWGArea(oArea))
    {
        NWM_SetBind(WG_MAP_BIND_COLOR + GetTag(oArea), WG_GetAreaMapColor(WG_MAP_COLOR_PLAYER));
    }
}

void WG_UpdateMapArea(string sAreaID, int nColor, object oPlayer = OBJECT_INVALID)
{
    if (oPlayer != OBJECT_INVALID)
    {
        if (NWM_GetIsWindowOpen(oPlayer, WG_MAP_WINDOW_ID, TRUE))
            NWM_SetBind(WG_MAP_BIND_COLOR + sAreaID, WG_GetAreaMapColor(nColor));
    }
    else
    {
        oPlayer = GetFirstPC();
        while (GetIsObjectValid(oPlayer))
        {
            if (NWM_GetIsWindowOpen(oPlayer, WG_MAP_WINDOW_ID, TRUE))
                NWM_SetBind(WG_MAP_BIND_COLOR + sAreaID, WG_GetAreaMapColor(nColor));
            oPlayer = GetNextPC();
        }
    }
}

void WG_InitializeAreaCache()
{
    if (!WG_ENABLE_AREA_CACHING)
        return;

    string sQuery = "CREATE TABLE IF NOT EXISTS " + WG_AREA_CACHE_TABLE_NAME + "(" +
                    "area_id TEXT NOT NULL, " +
                    "hash INT NOT NULL, " +
                    "dataobject BLOB NOT NULL, " +
                    "PRIMARY KEY(area_id, hash));";
    SqlStep(SqlPrepareQueryCampaign(WG_SCRIPT_NAME, sQuery));
}

int WG_GetAreaIsCached(string sAreaID)
{
    if (!WG_ENABLE_AREA_CACHING)
        return FALSE;

    string sQuery = "SELECT area_id FROM " + WG_AREA_CACHE_TABLE_NAME + " " +
                    "WHERE area_id = @area_id AND hash = @hash;";
    sqlquery sql = SqlPrepareQueryCampaign(WG_SCRIPT_NAME, sQuery);
    SqlBindString(sql, "@area_id", sAreaID);
    SqlBindInt(sql, "@hash", WG_GetStateHash());
    return SqlStep(sql);
}

void WG_CacheArea(string sAreaID)
{
    if (!WG_ENABLE_AREA_CACHING)
        return;

    string sQuery = "INSERT INTO " + WG_AREA_CACHE_TABLE_NAME + "(area_id, hash, dataobject) " +
                    "VALUES(@area_id, @hash, @dataobject);";
    sqlquery sql = SqlPrepareQueryCampaign(WG_SCRIPT_NAME, sQuery);
    SqlBindString(sql, "@area_id", sAreaID);
    SqlBindInt(sql, "@hash", WG_GetStateHash());
    SqlBindJson(sql, "@dataobject", ObjectToJson(AG_GetAreaDataObject(sAreaID), TRUE));
    SqlStep(sql);
}

int WG_GetCachedArea(string sAreaID)
{
    if (!WG_ENABLE_AREA_CACHING)
        return FALSE;

    string sQuery = "SELECT dataobject FROM " + WG_AREA_CACHE_TABLE_NAME + " " +
                    "WHERE area_id = @area_id AND hash = @hash;";
    sqlquery sql = SqlPrepareQueryCampaign(WG_SCRIPT_NAME, sQuery);
    SqlBindString(sql, "@area_id", sAreaID);
    SqlBindInt(sql, "@hash", WG_GetStateHash());
    if (SqlStep(sql))
    {
        AG_SetAreaDataObject(sAreaID, JsonToObject(SqlGetJson(sql, 0), GetStartingLocation(), OBJECT_INVALID, TRUE));
        return TRUE;
    }

    return FALSE;
}

json WG_GetVFXPlaceableTemplate()
{
    json jTemplate = GetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_VFX_PLACEABLE_TEMPLATE);
    if (!JsonGetType(jTemplate))
    {
        struct GffTools_PlaceableData pd;
        pd.nModel = GFFTOOLS_INVISIBLE_PLACEABLE_MODEL_ID;
        pd.sName = "VFXPlaceable";
        pd.sTag = WG_VFX_PLACEABLE_TAG;
        pd.bPlot = TRUE;
        jTemplate = GffTools_GeneratePlaceable(pd);
        SetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_VFX_PLACEABLE_TEMPLATE, GffTools_GeneratePlaceable(pd));
    }

    return jTemplate;
}

json WG_GetAreaTileIDArray(string sAreaID)
{
    json jArray = GetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_VFX_TILE_ID_ARRAY + sAreaID);
    if (!JsonGetType(jArray))
    {
        jArray = JsonArray();
        SetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_VFX_TILE_ID_ARRAY + sAreaID, jArray);
    }
    return jArray;
}

json WG_GetAreaTileModelArray(string sAreaID)
{
    json jArray = GetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_VFX_TILE_MODEL_ARRAY + sAreaID);
    if (!JsonGetType(jArray))
    {
        jArray = JsonArray();
        SetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_VFX_TILE_MODEL_ARRAY + sAreaID, jArray);
    }
    return jArray;
}

void WG_ApplyTileModelVFX(object oPlaceable, string sAreaID, struct AG_Tile strTile, string sTileModel)
{
    object oPlayer = GetFirstPC();
    while (oPlayer != OBJECT_INVALID)
    {
        if (GetTag(GetArea(oPlayer)) == sAreaID)
        {
            NWNX_Player_SetResManOverride(oPlayer, 2002, WG_VFX_DUMMY_NAME + IntToString(strTile.nTileID), sTileModel);
        }
        oPlayer = GetNextPC();
    }

    float fZ = strTile.nHeight * TS_GetTilesetHeightTransition(WG_AREA_TILESET);
    vector vTranslate = Vector(0.0f, 0.0f, fZ);
    vector vRotate = Vector(90.0f + (strTile.nOrientation * 90.0f), 0.0f, 0.0f);
    effect eTile = EffectVisualEffect(WG_VFX_START_ROW + strTile.nTileID, FALSE, 1.0f, vTranslate, vRotate);
    DelayCommand(0.25f, ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTile, oPlaceable));
}

void WG_SpawnVFXEdge(string sAreaID, string sOtherAreaID, int nEdge)
{
    object oArea = GetObjectByTag(sAreaID);
    json jPlaceable = WG_GetVFXPlaceableTemplate();
    json jTileIDArray = WG_GetAreaTileIDArray(sAreaID);
    json jTileModelArray = WG_GetAreaTileModelArray(sAreaID);
    int nEdgeToCopyFrom = (nEdge + 2) % 4;

    switch (nEdgeToCopyFrom)
    {
        case AG_AREA_EDGE_TOP:
        {
            int nBorderRow;
            for (nBorderRow = 0; nBorderRow < WG_VFX_TILE_BORDER_SIZE; nBorderRow++)
            {
                int nStart = WG_AREA_LENGTH * ((WG_AREA_LENGTH - 1) - nBorderRow);
                int nCount, nNumTiles = WG_AREA_LENGTH;
                for (nCount = 0; nCount < nNumTiles; nCount++)
                {
                    int nTile = nStart + nCount;
                    struct AG_Tile strTile = AG_GetTile(sOtherAreaID, nTile);
                    string sTileModel = NWNX_Tileset_GetTileModel(WG_AREA_TILESET, strTile.nTileID);

                    if (!JsonArrayContainsInt(jTileIDArray, strTile.nTileID))
                    {
                        JsonArrayInsertIntInplace(jTileIDArray, strTile.nTileID);
                        JsonArrayInsertStringInplace(jTileModelArray, sTileModel);
                    }

                    // BOTTOM
                    vector vPosition = Vector(5.0f + (nCount * 10.0f), 5.0f, 0.0f);
                    object oPlaceable = GffTools_CreatePlaceable(jPlaceable, Location(oArea, vPosition, 0.0f), WG_VFX_PLACEABLE_TAG);
                    SetObjectVisibleDistance(oPlaceable, (WG_AREA_LENGTH * 2) * 10.0f);
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_X, 10.0f * (nBorderRow + 1));
                    WG_ApplyTileModelVFX(oPlaceable, sAreaID, strTile, sTileModel);
                }
            }
            break;
        }

        case AG_AREA_EDGE_RIGHT:
        {
            int nBorderRow;
            for (nBorderRow = 0; nBorderRow < WG_VFX_TILE_BORDER_SIZE; nBorderRow++)
            {
                int nStart = WG_AREA_LENGTH - 1 - nBorderRow;
                int nCount, nNumTiles = WG_AREA_LENGTH;
                for (nCount = 0; nCount < nNumTiles; nCount++)
                {
                    int nTile = nStart + (nCount * WG_AREA_LENGTH);
                    struct AG_Tile strTile = AG_GetTile(sOtherAreaID, nTile);
                    string sTileModel = NWNX_Tileset_GetTileModel(WG_AREA_TILESET, strTile.nTileID);

                    if (!JsonArrayContainsInt(jTileIDArray, strTile.nTileID))
                    {
                        JsonArrayInsertIntInplace(jTileIDArray, strTile.nTileID);
                        JsonArrayInsertStringInplace(jTileModelArray, sTileModel);
                    }

                    // LEFT
                    vector vPosition = Vector(5.0f, 5.0f + (nCount * 10.0f), 0.0f);
                    object oPlaceable = GffTools_CreatePlaceable(jPlaceable, Location(oArea, vPosition, 0.0f), WG_VFX_PLACEABLE_TAG);
                    SetObjectVisibleDistance(oPlaceable, (WG_AREA_LENGTH * 2) * 10.0f);
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Y, -10.0f * (nBorderRow + 1));
                    WG_ApplyTileModelVFX(oPlaceable, sAreaID, strTile, sTileModel);
                }
            }
            break;
        }

        case AG_AREA_EDGE_BOTTOM:
        {
            int nBorderRow;
            for (nBorderRow = 0; nBorderRow < WG_VFX_TILE_BORDER_SIZE; nBorderRow++)
            {
                int nStart = nBorderRow * WG_AREA_LENGTH;
                int nCount, nNumTiles = WG_AREA_LENGTH;
                for (nCount = 0; nCount < nNumTiles; nCount++)
                {
                    int nTile = nStart + nCount;
                    struct AG_Tile strTile = AG_GetTile(sOtherAreaID, nTile);
                    string sTileModel = NWNX_Tileset_GetTileModel(WG_AREA_TILESET, strTile.nTileID);

                    if (!JsonArrayContainsInt(jTileIDArray, strTile.nTileID))
                    {
                        JsonArrayInsertIntInplace(jTileIDArray, strTile.nTileID);
                        JsonArrayInsertStringInplace(jTileModelArray, sTileModel);
                    }

                    // TOP
                    vector vPosition = Vector(5.0f + (nCount * 10.0f), (WG_AREA_LENGTH * 10.0f) - 5.0f, 0.0f);
                    object oPlaceable = GffTools_CreatePlaceable(jPlaceable, Location(oArea, vPosition, 0.0f), WG_VFX_PLACEABLE_TAG);
                    SetObjectVisibleDistance(oPlaceable, (WG_AREA_LENGTH * 2) * 10.0f);
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_X, -10.0f * (nBorderRow + 1));
                    WG_ApplyTileModelVFX(oPlaceable, sAreaID, strTile, sTileModel);
                }
            }
            break;
        }

        case AG_AREA_EDGE_LEFT:
        {
            int nBorderRow;
            for (nBorderRow = 0; nBorderRow < WG_VFX_TILE_BORDER_SIZE; nBorderRow++)
            {
                int nStart = 1 * nBorderRow;
                int nCount, nNumTiles = WG_AREA_LENGTH;
                for (nCount = 0; nCount < nNumTiles; nCount++)
                {
                    int nTile = nStart + (nCount * WG_AREA_LENGTH);
                    struct AG_Tile strTile = AG_GetTile(sOtherAreaID, nTile);
                    string sTileModel = NWNX_Tileset_GetTileModel(WG_AREA_TILESET, strTile.nTileID);

                    if (!JsonArrayContainsInt(jTileIDArray, strTile.nTileID))
                    {
                        JsonArrayInsertIntInplace(jTileIDArray, strTile.nTileID);
                        JsonArrayInsertStringInplace(jTileModelArray, sTileModel);
                    }

                    // RIGHT
                    vector vPosition = Vector((WG_AREA_LENGTH * 10.0f) - 5.0f, 5.0f + (nCount * 10.0f), 0.0f);
                    object oPlaceable = GffTools_CreatePlaceable(jPlaceable, Location(oArea, vPosition, 0.0f), WG_VFX_PLACEABLE_TAG);
                    SetObjectVisibleDistance(oPlaceable, (WG_AREA_LENGTH * 2) * 10.0f);
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Y, 10.0f * (nBorderRow + 1));
                    WG_ApplyTileModelVFX(oPlaceable, sAreaID, strTile, sTileModel);
                }
            }
            break;
        }
    }
}

void WG_SpawnVFXEdgeCorner(string sAreaID, int nNeighborDirection)
{
    object oArea = GetObjectByTag(sAreaID);
    json jPlaceable = WG_GetVFXPlaceableTemplate();
    json jTileIDArray = WG_GetAreaTileIDArray(sAreaID);
    json jTileModelArray = WG_GetAreaTileModelArray(sAreaID);
    string sOtherAreaID = WG_GetAreaIDFromDirection(sAreaID, nNeighborDirection);

    switch (nNeighborDirection)
    {
        case WG_NEIGHBOR_AREA_TOP_LEFT:
        {
            int nX, nY;
            for (nX = 0; nX < WG_VFX_TILE_BORDER_SIZE; nX++)
            {
                for (nY = 0; nY < WG_VFX_TILE_BORDER_SIZE; nY++)
                {
                    int nTile = ((WG_AREA_LENGTH - 1) - nX) + (nY * WG_AREA_LENGTH);
                    struct AG_Tile strTile = AG_GetTile(sOtherAreaID, nTile);
                    string sTileModel = NWNX_Tileset_GetTileModel(WG_AREA_TILESET, strTile.nTileID);

                    if (!JsonArrayContainsInt(jTileIDArray, strTile.nTileID))
                    {
                        JsonArrayInsertIntInplace(jTileIDArray, strTile.nTileID);
                        JsonArrayInsertStringInplace(jTileModelArray, sTileModel);
                    }

                    vector vPosition = Vector(5.0f, (WG_AREA_LENGTH * 10.0f) - 5.0f, 0.0f);
                    object oPlaceable = GffTools_CreatePlaceable(jPlaceable, Location(oArea, vPosition, 0.0f), WG_VFX_PLACEABLE_TAG);
                    SetObjectVisibleDistance(oPlaceable, (WG_AREA_LENGTH * 2) * 10.0f);
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_X, -10.0f * (nY + 1));
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Y, -10.0f * (nX + 1));
                    WG_ApplyTileModelVFX(oPlaceable, sAreaID, strTile, sTileModel);
                }
            }
            break;
        }

        case WG_NEIGHBOR_AREA_TOP_RIGHT:
        {
            int nX, nY;
            for (nX = 0; nX < WG_VFX_TILE_BORDER_SIZE; nX++)
            {
                for (nY = 0; nY < WG_VFX_TILE_BORDER_SIZE; nY++)
                {
                    int nTile = nX + (nY * WG_AREA_LENGTH);
                    struct AG_Tile strTile = AG_GetTile(sOtherAreaID, nTile);
                    string sTileModel = NWNX_Tileset_GetTileModel(WG_AREA_TILESET, strTile.nTileID);

                    if (!JsonArrayContainsInt(jTileIDArray, strTile.nTileID))
                    {
                        JsonArrayInsertIntInplace(jTileIDArray, strTile.nTileID);
                        JsonArrayInsertStringInplace(jTileModelArray, sTileModel);
                    }

                    vector vPosition = Vector((WG_AREA_LENGTH * 10.0f) - 5.0f, (WG_AREA_LENGTH * 10.0f) - 5.0f, 0.0f);
                    object oPlaceable = GffTools_CreatePlaceable(jPlaceable, Location(oArea, vPosition, 0.0f), WG_VFX_PLACEABLE_TAG);
                    SetObjectVisibleDistance(oPlaceable, (WG_AREA_LENGTH * 2) * 10.0f);
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_X, -10.0f * (nY + 1));
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Y, 10.0f * (nX + 1));
                    WG_ApplyTileModelVFX(oPlaceable, sAreaID, strTile, sTileModel);
                }
            }
            break;
        }

        case WG_NEIGHBOR_AREA_BOTTOM_RIGHT:
        {
            int nX, nY;
            for (nX = 0; nX < WG_VFX_TILE_BORDER_SIZE; nX++)
            {
                for (nY = 0; nY < WG_VFX_TILE_BORDER_SIZE; nY++)
                {
                    int nTile = nX + (((WG_AREA_LENGTH - 1) - nY) * WG_AREA_LENGTH);
                    struct AG_Tile strTile = AG_GetTile(sOtherAreaID, nTile);
                    string sTileModel = NWNX_Tileset_GetTileModel(WG_AREA_TILESET, strTile.nTileID);

                    if (!JsonArrayContainsInt(jTileIDArray, strTile.nTileID))
                    {
                        JsonArrayInsertIntInplace(jTileIDArray, strTile.nTileID);
                        JsonArrayInsertStringInplace(jTileModelArray, sTileModel);
                    }

                    vector vPosition = Vector((WG_AREA_LENGTH * 10.0f) - 5.0f, 5.0f, 0.0f);
                    object oPlaceable = GffTools_CreatePlaceable(jPlaceable, Location(oArea, vPosition, 0.0f), WG_VFX_PLACEABLE_TAG);
                    SetObjectVisibleDistance(oPlaceable, (WG_AREA_LENGTH * 2) * 10.0f);
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_X, 10.0f * (nY + 1));
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Y, 10.0f * (nX + 1));
                    WG_ApplyTileModelVFX(oPlaceable, sAreaID, strTile, sTileModel);
                }
            }
            break;
        }

        case WG_NEIGHBOR_AREA_BOTTOM_LEFT:
        {
            int nX, nY;
            for (nX = 0; nX < WG_VFX_TILE_BORDER_SIZE; nX++)
            {
                for (nY = 0; nY < WG_VFX_TILE_BORDER_SIZE; nY++)
                {
                    int nTile = ((WG_AREA_LENGTH - 1) - nX) + (((WG_AREA_LENGTH - 1) - nY) * WG_AREA_LENGTH);
                    struct AG_Tile strTile = AG_GetTile(sOtherAreaID, nTile);
                    string sTileModel = NWNX_Tileset_GetTileModel(WG_AREA_TILESET, strTile.nTileID);

                    if (!JsonArrayContainsInt(jTileIDArray, strTile.nTileID))
                    {
                        JsonArrayInsertIntInplace(jTileIDArray, strTile.nTileID);
                        JsonArrayInsertStringInplace(jTileModelArray, sTileModel);
                    }

                    vector vPosition = Vector(5.0f, 5.0f, 0.0f);
                    object oPlaceable = GffTools_CreatePlaceable(jPlaceable, Location(oArea, vPosition, 0.0f), WG_VFX_PLACEABLE_TAG);
                    SetObjectVisibleDistance(oPlaceable, (WG_AREA_LENGTH * 2) * 10.0f);
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_X, 10.0f * (nY + 1));
                    SetObjectVisualTransform(oPlaceable, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Y, -10.0f * (nX + 1));
                    WG_ApplyTileModelVFX(oPlaceable, sAreaID, strTile, sTileModel);
                }
            }
            break;
        }
    }
}
