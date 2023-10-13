/*
    Script: ef_s_worldgen
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_areagen"
#include "ef_s_eventman"
#include "ef_s_profiler"
#include "ef_s_areamusic"

const string WG_SCRIPT_NAME                                     = "ef_s_worldgen";
const int WG_DEBUG_LOG                                          = FALSE;

const string WG_TEMPLATE_AREA_TAG                               = "AR_TEMPLATEAREA";
const string WG_TEMPLATE_AREA_JSON                              = "TemplateArea";
const string WG_AREA_TAG_PREFIX                                 = "AR_W_";

const string WG_WORLD_SEED_NAME                                 = "WG_WORLD_SEED";

const string WG_AREA_TILESET                                    = TILESET_RESREF_MEDIEVAL_RURAL_2;
const int WG_MAX_ITERATIONS                                     = 100;
const string WG_AREA_DEFAULT_EDGE_TERRAIN                       = "";
const int WG_AREA_LENGTH                                        = 8;

const int WG_NEIGHBOR_AREA_TOP_LEFT                             = 0;
const int WG_NEIGHBOR_AREA_TOP                                  = 1;
const int WG_NEIGHBOR_AREA_TOP_RIGHT                            = 2;
const int WG_NEIGHBOR_AREA_RIGHT                                = 3;
const int WG_NEIGHBOR_AREA_BOTTOM_RIGHT                         = 4;
const int WG_NEIGHBOR_AREA_BOTTOM                               = 5;
const int WG_NEIGHBOR_AREA_BOTTOM_LEFT                          = 6;
const int WG_NEIGHBOR_AREA_LEFT                                 = 7;

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
    return WG_AREA_TAG_PREFIX + "10000_10000";
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

void WG_GenerateArea()
{
    string sAreaID = WG_QueueGet();

    LogInfo("Generating Area: " + sAreaID);

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

    if (sAreaID == WG_GetStartingAreaID())
    {
        int nCenterTile = (WG_AREA_LENGTH / 2) + (WG_AREA_LENGTH * (WG_AREA_LENGTH / 2));
        AG_Tile_Set(sAreaID, AG_DATA_KEY_ARRAY_TILES, nCenterTile, 1215, AG_Random(WG_WORLD_SEED_NAME, 4), 0, TRUE);
    }
    else
    {
        object oNeighborArea = GetObjectByTag(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_TOP));
        if (GetIsObjectValid(oNeighborArea))
            AG_CopyEdgeFromArea(sAreaID, oNeighborArea, AG_AREA_EDGE_BOTTOM);

        oNeighborArea = GetObjectByTag(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_RIGHT));
        if (GetIsObjectValid(oNeighborArea))
            AG_CopyEdgeFromArea(sAreaID, oNeighborArea, AG_AREA_EDGE_LEFT);

        oNeighborArea = GetObjectByTag(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_BOTTOM));
        if (GetIsObjectValid(oNeighborArea))
            AG_CopyEdgeFromArea(sAreaID, oNeighborArea, AG_AREA_EDGE_TOP);

        oNeighborArea = GetObjectByTag(WG_GetAreaIDFromDirection(sAreaID, WG_NEIGHBOR_AREA_LEFT));
        if (GetIsObjectValid(oNeighborArea))
            AG_CopyEdgeFromArea(sAreaID, oNeighborArea, AG_AREA_EDGE_RIGHT);
    }

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

        WG_QueuePop();
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
