/*
    Script: ef_s_dyntiles
    Author: Daz

    Description:
*/

#include "ef_i_core"
#include "ef_s_gfftools"
#include "ef_s_areagen"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "nwnx_player"

const string DT_SCRIPT_NAME                     = "ef_s_dyntiles";

const string DT_AREA_TAG                        = "AR_DYNTILES";

const string DT_GENERATING_AREA                 = "GeneratingArea";

const string DT_TILE_STARTING_ARRAY             = "TileStartingArray";
const string DT_TILE_SPAWN_ARRAY                = "TileSpawnArray";
const string DT_TILE_OBJECT_ARRAY               = "TileObjectArray";

const string DT_WINDOW_ID                       = "DYNAMICTILES";
const string DT_BIND_GENERATE_BUTTON            = "btn_generate";

const string DT_AREA_ID                         = "DTRandomArea";
const string DT_AREA_TILESET                    = TILESET_RESREF_MEDIEVAL_RURAL_2;
const int DT_AREA_WIDTH                         = 12;
const int DT_AREA_HEIGHT                        = 12;
const string DT_AREA_EDGE_TERRAIN               = "";
const int DT_MAX_ITERATIONS                     = 100;

const int DT_VISUALEFFECT_START_ROW             = 1000;
const string DT_VISUALEFFECT_DUMMY_NAME         = "dummy_tile_";

const float DT_TILE_OBJECT_HEIGHT               = 30.0f;
const float DT_START_DELAY                      = 3.0f;
const float DT_LERP_SPEED                       = 1.5f;

// @CORE[EF_SYSTEM_INIT]
void DT_Init()
{
    object oDataObject = GetSystemDataObject();
    object oArea = GetObjectByTag(DT_AREA_TAG);

    json jStartingTiles = JsonArray();
    json jTileArray = JsonArray();
    int nTile, nNumTiles = DT_AREA_WIDTH * DT_AREA_HEIGHT;
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        struct NWNX_Area_TileInfo str = NWNX_Area_GetTileInfoByTileIndex(oArea, nTile);

        jStartingTiles = JsonArrayInsert(jStartingTiles, AG_GetSetTileTileObject(nTile, str.nID, str.nOrientation, str.nHeight));
        jTileArray = JsonArrayInsertInt(jTileArray, nTile);
    }
    SetLocalJson(oDataObject, DT_TILE_STARTING_ARRAY, jStartingTiles);
    SetLocalJson(oDataObject, DT_TILE_SPAWN_ARRAY, jTileArray);

    struct GffTools_PlaceableData pdTilePlaceable;
    pdTilePlaceable.nModel = GFFTOOLS_INVISIBLE_PLACEABLE_MODEL_ID;
    pdTilePlaceable.sTag = "DT_TILE_PLC";
    pdTilePlaceable.bPlot = TRUE;
    pdTilePlaceable.fFacingAdjustment = 90.0f;
    json jTilePlaceable = GffTools_GeneratePlaceable(pdTilePlaceable);

    int nTileX, nTileY;
    for (nTileY = 0; nTileY < DT_AREA_HEIGHT; nTileY++)
    {
        for (nTileX = 0; nTileX < DT_AREA_WIDTH; nTileX++)
        {
            vector vTile = Vector(5.0f + (nTileX * 10.0f), 5.0f + (nTileY * 10.0f), DT_TILE_OBJECT_HEIGHT);
            location locTile = Location(oArea, vTile, 0.0f);
            object oTile = GffTools_CreatePlaceable(jTilePlaceable, locTile);

            SetObjectVisibleDistance(oTile, 256.0f);
            ObjectArray_Insert(oDataObject, DT_TILE_OBJECT_ARRAY, oTile);
        }
    }
}

// @NWMWINDOW[DT_WINDOW_ID]
json DT_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 200.0f, 80.0f));
    NB_SetWindowTitle(JsonString("Dynamic Tiles"));
      NB_StartColumn();
        NB_StartRow();
          NB_AddSpacer();
          NB_StartElement(NuiButton(JsonString("Generate")));
            NB_SetId(DT_BIND_GENERATE_BUTTON);
            NB_SetHeight(24.0f);
          NB_End();
          NB_AddSpacer();
        NB_End();
        NB_StartRow();
          NB_AddSpacer();
        NB_End();
      NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[DT_WINDOW_ID:NUI_EVENT_CLICK:DT_BIND_GENERATE_BUTTON]
void DT_ClickGenerateButton()
{
    if (GetLocalInt(GetSystemDataObject(), DT_GENERATING_AREA))
        return;

    SetLocalInt(GetSystemDataObject(), DT_GENERATING_AREA, TRUE);

    AG_InitializeRandomArea(DT_AREA_ID, DT_AREA_TILESET, DT_AREA_EDGE_TERRAIN, DT_AREA_WIDTH, DT_AREA_HEIGHT);
    AG_SetIntDataByKey(DT_AREA_ID, AG_DATA_KEY_MAX_ITERATIONS, DT_MAX_ITERATIONS);
    AG_SetIntDataByKey(DT_AREA_ID, AG_DATA_KEY_GENERATION_LOG_STATUS, TRUE);
    AG_SetIntDataByKey(DT_AREA_ID, AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE, 5);
    AG_SetIntDataByKey(DT_AREA_ID, AG_DATA_KEY_EDGE_TERRAIN_CHANGE_CHANCE, 25);
    AG_SetIntDataByKey(DT_AREA_ID, AG_DATA_KEY_GENERATION_TYPE, Random(8));
    AG_SetCallbackFunction(DT_AREA_ID, DT_SCRIPT_NAME, "DT_OnAreaGenerated");

    AG_SetIgnoreTerrainOrCrosser(DT_AREA_ID, "ROAD");
    AG_SetIgnoreTerrainOrCrosser(DT_AREA_ID, "WALL");
    AG_SetIgnoreTerrainOrCrosser(DT_AREA_ID, "BRIDGE");
    AG_SetIgnoreTerrainOrCrosser(DT_AREA_ID, "STREET");
    //AG_SetIgnoreTerrainOrCrosser(DT_AREA_ID, "MOUNTAIN");

    //AG_AddEdgeTerrain(DT_AREA_ID, "WATER");
    //AG_AddEdgeTerrain(DT_AREA_ID, "MOUNTAIN");
    //AG_AddEdgeTerrain(DT_AREA_ID, "GRASS");
    //AG_AddEdgeTerrain(DT_AREA_ID, "GRASS2");

    AG_SetStringDataByKey(DT_AREA_ID, AG_DATA_KEY_FLOOR_TERRAIN, "GRASS");

    //AG_GenerateEdge(DT_AREA_ID, AG_AREA_EDGE_TOP);
    //AG_GenerateEdge(DT_AREA_ID, AG_AREA_EDGE_BOTTOM);
    //AG_GenerateEdge(DT_AREA_ID, AG_AREA_EDGE_LEFT);
    //AG_GenerateEdge(DT_AREA_ID, AG_AREA_EDGE_RIGHT);

    AG_GenerateArea(DT_AREA_ID);
}

// @PMBUTTON[Dynamic Tiles:View some procedurally generated areas, in realtime!]
void DT_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, DT_WINDOW_ID))
        NWM_CloseWindow(oPlayer, DT_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, DT_WINDOW_ID))
    {

    }
}

void DT_StartLerp(object oTile, int nHeight)
{
    float fZ = (nHeight * TS_GetTilesetHeightTransition(DT_AREA_TILESET)) - DT_TILE_OBJECT_HEIGHT;
    SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, fZ, OBJECT_VISUAL_TRANSFORM_LERP_EASE_IN, DT_LERP_SPEED);
}

void DT_ResetLerp(object oTile)
{
    SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, 0.0f);
}

void DT_SetTile(object oArea, int nTile, struct AG_Tile strTile)
{
    object oTile = ObjectArray_At(GetSystemDataObject(), DT_TILE_OBJECT_ARRAY, nTile);
    location locTile = GetLocation(oTile);
    vector vTranslate = Vector(0.0f, 0.0f, 6.0f);
    effect eVfx = EffectVisualEffect(VFX_FNF_BLINDDEAF, FALSE, 2.5f, vTranslate);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eVfx, oTile);

    vTranslate = Vector(0.0f, 0.0f, 0.0f);
    vector vRotate = Vector((strTile.nOrientation * 90.0f), 0.0f, 0.0f);
    effect eTile = EffectVisualEffect(DT_VISUALEFFECT_START_ROW + nTile, FALSE, 1.0f, vTranslate, vRotate);
    DelayCommand(DT_START_DELAY, ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eTile, oTile, DT_LERP_SPEED + 0.2f));

    DelayCommand(DT_START_DELAY, DT_StartLerp(oTile, strTile.nHeight));
    DelayCommand(DT_START_DELAY + DT_LERP_SPEED + 0.1f, SetTile(locTile, strTile.nTileID, strTile.nOrientation, strTile.nHeight, SETTILE_FLAG_RELOAD_GRASS));
    DelayCommand(DT_START_DELAY + DT_LERP_SPEED + 0.5f, DT_ResetLerp(oTile));
}

void DT_ReloadTileStuff(object oArea)
{
    RecomputeStaticLighting(oArea);
    SetLocalInt(GetSystemDataObject(), DT_GENERATING_AREA, FALSE);
}

int DT_GetTileFromGenerationType(object oAreaDataObject, int nGenerationType, int nNumTiles, int nTile)
{
    switch (nGenerationType)
    {
        case AG_GENERATION_TYPE_SPIRAL_INWARD:
        case AG_GENERATION_TYPE_ALTERNATING_ROWS_INWARD:
        case AG_GENERATION_TYPE_ALTERNATING_COLUMNS_INWARD:
            return IntArray_At(oAreaDataObject, AG_GENERATION_TILE_ARRAY, nTile);

        case AG_GENERATION_TYPE_SPIRAL_OUTWARD:
        case AG_GENERATION_TYPE_ALTERNATING_ROWS_OUTWARD:
        case AG_GENERATION_TYPE_ALTERNATING_COLUMNS_OUTWARD:
                return IntArray_At(oAreaDataObject, AG_GENERATION_TILE_ARRAY, (nNumTiles - 1) - nTile);

        case AG_GENERATION_TYPE_LINEAR_ASCENDING:
            return nTile;

        case AG_GENERATION_TYPE_LINEAR_DESCENDING:
            return (nNumTiles - 1) - nTile;
    }
    return nTile;
}

void DT_OnAreaGenerated(string sAreaID)
{
    if (AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_FAILED))
    {
        SetLocalInt(GetSystemDataObject(), DT_GENERATING_AREA, FALSE);
        DT_ClickGenerateButton();
        return;
    }

    object oPlayer = GetFirstPC();
    object oArea = GetObjectByTag(DT_AREA_TAG);
    object oAreaDataObject = AG_GetAreaDataObject(sAreaID);
    int nGenerationType = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_GENERATION_TYPE);
    int nMin = TS_MAX_TILE_HEIGHT, nMax = 0;
    float fDelay;

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_MYSTICAL_EXPLOSION, FALSE, 5.0f), Location(oArea, GetAreaCenterPosition(oArea, 6.0f), 0.0f));
    SetTileJson(oArea, GetLocalJson(GetSystemDataObject(), DT_TILE_STARTING_ARRAY), SETTILE_FLAG_RELOAD_GRASS | SETTILE_FLAG_RECOMPUTE_LIGHTING);

    int nCount, nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    for (nCount = 0; nCount < nNumTiles; nCount++)
    {
        fDelay += 0.25f;
        int nTile = DT_GetTileFromGenerationType(oAreaDataObject, nGenerationType, nNumTiles, nCount);
        struct AG_Tile strTile = AG_GetTile(sAreaID, nTile);

        nMin = min(nMin, strTile.nHeight);
        nMax = max(nMax, strTile.nHeight);
        NWNX_Player_SetResManOverride(oPlayer, 2002, DT_VISUALEFFECT_DUMMY_NAME + IntToString(nTile), NWNX_Tileset_GetTileModel(DT_AREA_TILESET, strTile.nTileID));
        DelayCommand(fDelay, DT_SetTile(oArea, nTile, strTile));
    }

    LogInfo("TileHeight: Min=" + IntToString(nMin) + ", Max=" + IntToString(nMax));

    DelayCommand(fDelay + DT_START_DELAY + DT_LERP_SPEED + 0.5f, DT_ReloadTileStuff(oArea));
}
