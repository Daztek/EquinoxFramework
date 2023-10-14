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

const string WG_SCRIPT_NAME                                     = "ef_s_worldgen";
const int WG_DEBUG_LOG                                          = FALSE;

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
const int WG_AREA_LENGTH                                        = 9;

const int WG_NEIGHBOR_AREA_TOP_LEFT                             = 0;
const int WG_NEIGHBOR_AREA_TOP                                  = 1;
const int WG_NEIGHBOR_AREA_TOP_RIGHT                            = 2;
const int WG_NEIGHBOR_AREA_RIGHT                                = 3;
const int WG_NEIGHBOR_AREA_BOTTOM_RIGHT                         = 4;
const int WG_NEIGHBOR_AREA_BOTTOM                               = 5;
const int WG_NEIGHBOR_AREA_BOTTOM_LEFT                          = 6;
const int WG_NEIGHBOR_AREA_LEFT                                 = 7;

const int WG_AREA_SAND_CHANCE                                   = 20;
const int WG_AREA_WATER_CHANCE                                  = 30;
const int WG_AREA_MOUNTAIN_CHANCE                               = 35;
const int WG_AREA_STREAM_CHANCE                                 = 15;
const int WG_AREA_RIDGE_CHANCE                                  = 20;
const int WG_AREA_GRASS2_CHANCE                                 = 25;
const int WG_AREA_CHASM_CHANCE                                  = 10;

const string WG_AREA_GENERATION_QUEUE                           = "AreaGenerationQueue";

void WG_InitializeTemplateArea();
json WG_GetTemplateAreaJson();
void WG_SetWorldSeed();

string WG_GetStartingAreaID();
int WG_GetIsWGArea(object oArea);
string WG_GetAreaIDFromDirection(string sAreaID, int nDirection);

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

void WG_InsertGenerationType(int nGenerationType);

void WG_UpdateMap(object oPlayer);

// @CORE[EF_SYSTEM_INIT]
void WG_Init()
{
    WG_InitializeTemplateArea();
    WG_SetWorldSeed();
    WG_InitializeQueue();
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
    else
    {
        FloatingTextStringOnCreature("Area not generated! Position in queue: " + IntToString(WG_QueuePosition(sNextAreaID)), oPlayer, FALSE, FALSE);
    }
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

// @CONSOLE[WGQueueContents::]
string WG_QueueContents()
{
    return "World Gen Queue Size: " + IntToString(WG_QueueSize()) + "\n" + JsonDump(WG_GetQueue(), 0);
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

void WG_SetWorldSeed()
{
    int nSeed = Random(1000000000);
    SqlMersenneTwisterSetSeed(WG_WORLD_SEED_NAME, nSeed);
    LogInfo("World Seed: " + IntToString(nSeed));
}

string WG_GetStartingAreaID()
{
    return WG_AREA_TAG_PREFIX + IntToString(WG_AREA_STARTING_X) + "_" + IntToString(WG_AREA_STARTING_Y);
}

int WG_GetIsWGArea(object oArea)
{
    return GetStringLeft(GetTag(oArea), GetStringLength(WG_AREA_TAG_PREFIX)) == WG_AREA_TAG_PREFIX;
}

string WG_GetAreaIDFromDirection(string sAreaID, int nDirection)
{
    int nPrefixLength = GetStringLength(WG_AREA_TAG_PREFIX);
    string sCoordinates = GetSubString(sAreaID, nPrefixLength, GetStringLength(sAreaID) - nPrefixLength);
    int nDelimiter = FindSubString(sCoordinates, "_");
    int nX = StringToInt(GetSubString(sCoordinates, 0, nDelimiter));
    int nY = StringToInt(GetSubString(sCoordinates, nDelimiter + 1, GetStringLength(sCoordinates) - nDelimiter - 1));

    switch (nDirection)
    {
        case WG_NEIGHBOR_AREA_TOP_LEFT:     { nX -= 1; nY += 1; break; }
        case WG_NEIGHBOR_AREA_TOP:          {          nY += 1; break; }
        case WG_NEIGHBOR_AREA_TOP_RIGHT:    { nX += 1; nY += 1; break; }
        case WG_NEIGHBOR_AREA_RIGHT:        { nX += 1;          break; }
        case WG_NEIGHBOR_AREA_BOTTOM_RIGHT: { nX += 1; nY -= 1; break; }
        case WG_NEIGHBOR_AREA_BOTTOM:       {          nY -= 1; break; }
        case WG_NEIGHBOR_AREA_BOTTOM_LEFT:  { nX -= 1; nY -= 1; break; }
        case WG_NEIGHBOR_AREA_LEFT:         { nX -= 1;          break; }
    }

    return WG_AREA_TAG_PREFIX + IntToString(nX) + "_" + IntToString(nY);
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

void WG_GenerateArea()
{
    string sAreaID = WG_QueueGet();
    LogInfo("Processing Area: " + sAreaID);

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
        object oNeighborArea = GetObjectByTag(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_TOP));
        if (GetIsObjectValid(oNeighborArea))
        {
            AG_CopyEdgeFromArea(sAreaID, oNeighborArea, AG_AREA_EDGE_BOTTOM);
            jEdgeTOCs = JsonSetOp(jEdgeTOCs, JSON_SET_UNION, AG_GetEdgeTOCs(GetTag(oNeighborArea), AG_AREA_EDGE_BOTTOM));
        }

        oNeighborArea = GetObjectByTag(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_RIGHT));
        if (GetIsObjectValid(oNeighborArea))
        {
            AG_CopyEdgeFromArea(sAreaID, oNeighborArea, AG_AREA_EDGE_LEFT);
            jEdgeTOCs = JsonSetOp(jEdgeTOCs, JSON_SET_UNION, AG_GetEdgeTOCs(GetTag(oNeighborArea), AG_AREA_EDGE_LEFT));
        }

        oNeighborArea = GetObjectByTag(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_BOTTOM));
        if (GetIsObjectValid(oNeighborArea))
        {
            AG_CopyEdgeFromArea(sAreaID, oNeighborArea, AG_AREA_EDGE_TOP);
            jEdgeTOCs = JsonSetOp(jEdgeTOCs, JSON_SET_UNION, AG_GetEdgeTOCs(GetTag(oNeighborArea), AG_AREA_EDGE_TOP));
        }

        oNeighborArea = GetObjectByTag(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_LEFT));
        if (GetIsObjectValid(oNeighborArea))
        {
            AG_CopyEdgeFromArea(sAreaID, oNeighborArea, AG_AREA_EDGE_RIGHT);
            jEdgeTOCs = JsonSetOp(jEdgeTOCs, JSON_SET_UNION, AG_GetEdgeTOCs(GetTag(oNeighborArea), AG_AREA_EDGE_RIGHT));
        }

        jEdgeTOCs = JsonArrayTransform(jEdgeTOCs, JSON_ARRAY_UNIQUE);
    }

    WG_ToggleTOCs(sAreaID, jEdgeTOCs, "SAND", WG_AREA_SAND_CHANCE);
    WG_ToggleTOCs(sAreaID, jEdgeTOCs, "WATER", WG_AREA_WATER_CHANCE);
    WG_ToggleTOCs(sAreaID, jEdgeTOCs, "MOUNTAIN", WG_AREA_MOUNTAIN_CHANCE);
    WG_ToggleTOCs(sAreaID, jEdgeTOCs, "STREAM", WG_AREA_STREAM_CHANCE);
    WG_ToggleTOCs(sAreaID, jEdgeTOCs, "RIDGE", WG_AREA_RIDGE_CHANCE);
    WG_ToggleTOCs(sAreaID, jEdgeTOCs, "GRASS2", WG_AREA_GRASS2_CHANCE);
    WG_ToggleTOCs(sAreaID, jEdgeTOCs, "CHASM", WG_AREA_CHASM_CHANCE);

    AG_GenerateArea(sAreaID);
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
        EM_SetAreaEventScripts(oArea);
        WG_SetAreaModifiers(oArea);

        LogInfo("Generated Area: " + GetTag(oArea));

        //if (sAreaID == WG_GetStartingAreaID())
        {
            string sNextAreaID = WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_TOP);
            if (!GetIsObjectValid(GetObjectByTag(sNextAreaID)))
                WG_QueuePush(sNextAreaID);

            sNextAreaID = WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_RIGHT);
            if (!GetIsObjectValid(GetObjectByTag(sNextAreaID)))
                WG_QueuePush(sNextAreaID);

            sNextAreaID = WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_BOTTOM);
            if (!GetIsObjectValid(GetObjectByTag(sNextAreaID)))
                WG_QueuePush(sNextAreaID);

            sNextAreaID = WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_LEFT);
            if (!GetIsObjectValid(GetObjectByTag(sNextAreaID)))
                WG_QueuePush(sNextAreaID);
        }

        InsertStringToLocalJsonArray(GetDataObject(WG_SCRIPT_NAME), WG_GENERATED_AREAS_ARRAY, sAreaID);
        WG_InsertGenerationType(AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE));

        WG_QueuePop();

        WG_UpdateMap(GetFirstPC());

        if (!WG_QueueEmpty())
            WG_GenerateArea();
    }
}

object WG_CreateArea(string sAreaID)
{
    json jArea = WG_GetTemplateAreaJson();
    jArea = GffReplaceString(jArea, "ARE/value/Tag", sAreaID);
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
    // Don't persist player locations in WG areas
    Call(Function("ef_s_perloc", "PerLoc_SetAreaDisabled"), ObjectArg(oArea));
    // Setup dynamic lighting
    Call(Function("ef_s_dynlight", "DynLight_InitArea"), ObjectArg(oArea));
    // Assign Track List
    AreaMusic_SetAreaTrackList(oArea, WG_SCRIPT_NAME);

    // Grass
    float fDensity = 20.0f;
    float fHeight = 1.0f;
    vector vColor = Vector(1.0f, 1.0f, 1.0f);
    SetAreaGrassOverride(oArea, 3, "trm02_grass3d", fDensity, fHeight, vColor, vColor);
}

void WG_InsertGenerationType(int nGenerationType)
{
    object oDataObject = GetDataObject(WG_SCRIPT_NAME);
    json jArray = GetLocalJsonOrDefault(oDataObject, "GenerationTypeList", GetJsonArrayOfSize(8, JsonInt(0)));
    jArray = JsonArraySetInt(jArray, nGenerationType, JsonArrayGetInt(jArray, nGenerationType) + 1);
    SetLocalJson(oDataObject, "GenerationTypeList", jArray);
}

// @CONSOLE[WGDisplayGenerationTypes::]
string WG_DisplayGenerationTypes()
{
    object oDataObject = GetDataObject(WG_SCRIPT_NAME);
    json jArray = GetLocalJsonOrDefault(oDataObject, "GenerationTypeList", GetJsonArrayOfSize(8, JsonInt(0)));
    string sGenerationTypes;
    int nType, nNumTypes = 8;
    for (nType = 0; nType < nNumTypes; nType++)
    {
        sGenerationTypes += AG_GetGenerationTypeAsString(nType) + ": " + IntToString(JsonArrayGetInt(jArray, nType)) + "\n";
    }
    return sGenerationTypes;
}

// WORLD MAP

const string WG_MAP_WINDOW_ID               = "WORLDMAP";
const float WG_MAP_AREA_SIZE                = 24.0f;
const int WG_MAP_NUM_COLUMNS                = 15;
const int WG_MAP_NUM_ROWS                   = 15;

const string WG_MAP_BIND_BUTTON_REFRESH     = "btn_refresh";
const string WG_MAP_BIND_COLOR              = "_color";

// @NWMWINDOW[WG_MAP_WINDOW_ID]
json WG_CreateWindow()
{
    float fWidth = ((WG_MAP_AREA_SIZE + 4.0f) * IntToFloat(WG_MAP_NUM_COLUMNS)) + 10.0f;
    float fHeight = 33.0f + ((WG_MAP_AREA_SIZE + 8.0f) * IntToFloat(WG_MAP_NUM_ROWS)) + 8.0f;
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, fWidth, fHeight));
    NB_SetWindowTitle(JsonString("World Map"));
    NB_SetWindowTransparent(JsonBool(TRUE));
    NB_SetWindowBorder(JsonBool(FALSE));
        NB_StartColumn();

            int nRow;
            for (nRow = 0; nRow < WG_MAP_NUM_ROWS; nRow++)
            {
                NB_StartRow();

                    NB_AddSpacer();

                    int nColumn;
                    for (nColumn = 0; nColumn < WG_MAP_NUM_COLUMNS; nColumn++)
                    {
                        string sX = IntToString(WG_AREA_STARTING_X - (WG_MAP_NUM_COLUMNS / 2) + nColumn);
                        string sY = IntToString(WG_AREA_STARTING_Y + (WG_MAP_NUM_ROWS / 2) - nRow);
                        string sAreaTag = WG_AREA_TAG_PREFIX + sX + "_" + sY;

                        NB_StartElement(NuiImage(JsonString("gui_inv_1x1_ol"), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
                            NB_SetId(sAreaTag);
                            NB_SetDimensions(WG_MAP_AREA_SIZE, WG_MAP_AREA_SIZE);
                            NB_SetTooltip(JsonString(WG_AREA_TAG_PREFIX + sX + "_" + sY));
                            NB_StartDrawList(JsonBool(FALSE));
                                NB_AddDrawListItem(
                                    NuiDrawListRect(
                                        JsonBool(TRUE), NuiBind(WG_MAP_BIND_COLOR + sAreaTag), JsonBool(TRUE), JsonFloat(1.0f),
                                        NuiRect(0.0f, 0.0f, WG_MAP_AREA_SIZE, WG_MAP_AREA_SIZE),
                                        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
                                        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));

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

void WG_UpdateMap(object oPlayer)
{
    if (NWM_GetIsWindowOpen(oPlayer, WG_MAP_WINDOW_ID, TRUE))
    {
        json jGeneratedAreas = GetLocalJson(GetDataObject(WG_SCRIPT_NAME), WG_GENERATED_AREAS_ARRAY);
        int nArea, nNumAreas = JsonGetLength(jGeneratedAreas);
        for (nArea = 0; nArea < nNumAreas; nArea++)
        {
            NWM_SetBind(WG_MAP_BIND_COLOR + JsonArrayGetString(jGeneratedAreas, nArea), NuiColor(0, 225, 0, 200));
        }

        json jQueuedAreas = WG_GetQueue();
        nNumAreas = JsonGetLength(jQueuedAreas);
        for (nArea = 0; nArea < nNumAreas; nArea++)
        {
            NWM_SetBind(WG_MAP_BIND_COLOR + JsonArrayGetString(jQueuedAreas, nArea), NuiColor(225, 0, 0, 200));
        }

        object oArea = GetArea(oPlayer);
        if (WG_GetIsWGArea(oArea))
        {
            NWM_SetBind(WG_MAP_BIND_COLOR + GetTag(oArea), NuiColor(0, 0, 225, 200));
        }
    }
}

// @PMBUTTON[World Map:Display the world map!]
void WG_ShowMapWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, WG_MAP_WINDOW_ID))
        NWM_CloseWindow(oPlayer, WG_MAP_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, WG_MAP_WINDOW_ID))
    {
        WG_UpdateMap(oPlayer);
    }
}

// @EVENT[EVENT_SCRIPT_AREA_ON_ENTER::]
void WG_OnAreaEnter()
{
    object oPlayer = GetEnteringObject();
    if (WG_GetIsWGArea(OBJECT_SELF))
        WG_UpdateMap(oPlayer);
}
