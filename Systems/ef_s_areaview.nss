/*
    Script: ef_s_areaview
    Author: Daz

    Description:
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_gfftools"
#include "ef_s_areagen"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"
#include "ef_s_profiler"
#include "nwnx_player"

const string AV_LOG_TAG                         = "AreaView";
const string AV_SCRIPT_NAME                     = "ef_s_areaview";

const string AV_WINDOW_ID                       = "AREAVIEW";
const string AV_BIND_GENERATE_BUTTON            = "btn_generate";

const int AV_VISUALEFFECT_START_ROW             = 1000;
const string AV_VISUALEFFECT_DUMMY_NAME         = "dummy_tile_";

const float AV_TILES_TILE_SIZE                  = 10.0f;
const float AV_TILES_TILE_SCALE                 = 0.1f;

const string AV_WP_CENTER_TAG                   = "AV_CENTER_WP";

const string AV_DISPLAY_PLACEABLE               = "DisplayPlaceable";
const string AV_DISPLAY_PLACEABLE_TAG           = "AV_AREA_DISPLAY";

const string AV_AREA_ID                         = "AVRandomArea";
const string AV_AREA_TILESET                    = TILESET_RESREF_MEDIEVAL_CITY_2;
const int AV_AREA_WIDTH                         = 9;
const int AV_AREA_HEIGHT                        = 9;
const string AV_AREA_EDGE_TERRAIN               = "BUILDING";

const int AV_MAX_ITERATIONS                     = 100;

void AV_InitSolver(cassowary cSolver);
void AV_SetupSolvers();
cassowary AV_GetXSolver();
cassowary AV_GetYSolver();
void AV_OnAreaGenerated(string sAreaID);

// @CORE[EF_SYSTEM_INIT]
void AV_Init()
{
    AV_SetupSolvers();
    CassowarySuggestValue(AV_GetXSolver(), "LENGTH", IntToFloat(AV_AREA_WIDTH));
    CassowarySuggestValue(AV_GetYSolver(), "LENGTH", IntToFloat(AV_AREA_HEIGHT));
}

// @CORE[EF_SYSTEM_LOAD]
void AV_Load()
{
    object oDataObject = GetDataObject(AV_SCRIPT_NAME);

    struct GffTools_PlaceableData pd;
    pd.nModel = GFFTOOLS_INVISIBLE_PLACEABLE_MODEL_ID;
    pd.sName = "AreaDisplay";
    pd.sTag = AV_DISPLAY_PLACEABLE_TAG;
    pd.bPlot = TRUE;
    SetLocalJson(oDataObject, AV_DISPLAY_PLACEABLE, GffTools_GeneratePlaceable(pd));
}

// @NWMWINDOW[AV_WINDOW_ID]
json AV_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 200.0f, 80.0f));
    NB_SetWindowTitle(JsonString("Area Viewer"));
      NB_StartColumn();
        NB_StartRow();
          NB_AddSpacer();
          NB_StartElement(NuiButton(JsonString("Generate")));
            NB_SetId(AV_BIND_GENERATE_BUTTON);
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

// @NWMEVENT[AV_WINDOW_ID:NUI_EVENT_CLICK:AV_BIND_GENERATE_BUTTON]
void AV_ClickGenerateButton()
{
    int nWidth = 20;//Random(AV_AREA_WIDTH) + 4;
    int nHeight = 20;//Random(AV_AREA_HEIGHT) + 4;

    CassowarySuggestValue(AV_GetXSolver(), "LENGTH", IntToFloat(nWidth));
    CassowarySuggestValue(AV_GetYSolver(), "LENGTH", IntToFloat(nHeight));

    AG_InitializeRandomArea(AV_AREA_ID, AV_AREA_TILESET, AV_AREA_EDGE_TERRAIN, nWidth, nHeight);
    AG_SetIntDataByKey(AV_AREA_ID, AG_DATA_KEY_MAX_ITERATIONS, AV_MAX_ITERATIONS);
    AG_SetIntDataByKey(AV_AREA_ID, AG_DATA_KEY_GENERATION_LOG_STATUS, TRUE);
    AG_SetIntDataByKey(AV_AREA_ID, AG_DATA_KEY_GENERATION_SINGLE_GROUP_TILE_CHANCE, 0);
    AG_SetCallbackFunction(AV_AREA_ID, AV_SCRIPT_NAME, "AV_OnAreaGenerated");

    //AG_SetIgnoreTerrainOrCrosser(AV_AREA_ID, "FLOOR");
    //AG_SetIgnoreTerrainOrCrosser(AV_AREA_ID, "WALL");
    AG_SetIgnoreTerrainOrCrosser(AV_AREA_ID, "CASTLE");
    AG_SetIgnoreTerrainOrCrosser(AV_AREA_ID, "ROAD");
    AG_SetIgnoreTerrainOrCrosser(AV_AREA_ID, "WALL");
    AG_SetIgnoreTerrainOrCrosser(AV_AREA_ID, "BRIDGE");
    //AG_SetIgnoreTerrainOrCrosser(AV_AREA_ID, "DOORWAY");
    //AG_SetIgnoreTerrainOrCrosser(AV_AREA_ID, "BRIDGE");

    //AG_AddEdgeTerrain(AV_AREA_ID, "TREES");
    //AG_AddEdgeTerrain(AV_AREA_ID, "TREES");

    //AG_SetStringDataByKey(AV_AREA_ID, AG_DATA_KEY_FLOOR_TERRAIN, "GRASS");
    //AG_AddPathDoorCrosserCombo(AV_AREA_ID, 181, "ROAD");
    //AG_AddPathDoorCrosserCombo(AV_AREA_ID, 1161, "STREET");
    //AG_SetAreaPathDoorCrosserCombo(AV_AREA_ID, Random(AG_GetNumPathDoorCrosserCombos(AV_AREA_ID)));

    //AG_CopyEdgeFromArea(AV_AREA_ID, GetObjectByTag("AR_MEDCITY"), AG_AREA_EDGE_TOP);
    //AG_GenerateEdge(AV_AREA_ID, AG_AREA_EDGE_TOP);
    //AG_GenerateEdge(AV_AREA_ID, AG_AREA_EDGE_BOTTOM);
    //AG_GenerateEdge(AV_AREA_ID, AG_AREA_EDGE_LEFT);
    //AG_GenerateEdge(AV_AREA_ID, AG_AREA_EDGE_RIGHT);

    //AG_CreateRandomEntrance(AV_AREA_ID, 198);

   // AG_PlotRoad(AV_AREA_ID);

    //AV_OnAreaGenerated(AV_AREA_ID);
    AG_GenerateArea(AV_AREA_ID);
}

// @PMBUTTON[Area Viewer:View some procedurally generated areas]
void AV_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_GetIsWindowOpen(oPlayer, AV_WINDOW_ID))
        NWM_CloseWindow(oPlayer, AV_WINDOW_ID);
    else if (NWM_OpenWindow(oPlayer, AV_WINDOW_ID))
    {

    }
}

void AV_InitSolver(cassowary cSolver)
{
    string sScale = FloatToString(AV_TILES_TILE_SIZE * AV_TILES_TILE_SCALE, 0, 2);
    CassowaryConstrain(cSolver, "MAX == (LENGTH - 1) * " + sScale);
    CassowaryConstrain(cSolver, "CENTER == MAX * 0.5");
    CassowaryConstrain(cSolver, "OUTPUT == (CENTER + (INPUT * " + sScale + ")) - MAX");
}

void AV_SetupSolvers()
{
    object oDataObject = GetDataObject(AV_SCRIPT_NAME);
    cassowary cSolverX, cSolverY;

    AV_InitSolver(cSolverX);
    AV_InitSolver(cSolverY);

    SetLocalCassowary(oDataObject, "SolverX", cSolverX);
    SetLocalCassowary(oDataObject, "SolverY", cSolverY);
}

cassowary AV_GetXSolver()
{
    return GetLocalCassowary(GetDataObject(AV_SCRIPT_NAME), "SolverX");
}

cassowary AV_GetYSolver()
{
    return GetLocalCassowary(GetDataObject(AV_SCRIPT_NAME), "SolverY");
}

float AV_GetSolverValue(cassowary cSolver, float fInput)
{
    CassowarySuggestValue(cSolver, "INPUT", fInput);
    return CassowaryGetValue(cSolver, "OUTPUT");
}

void AG_DelayedApplyEffect(object oDisplay, int nTile, int nTileID, int nOrientation, int nHeight)
{
    cassowary cSolverX = AV_GetXSolver();
    cassowary cSolverY = AV_GetYSolver();

    int nWidth = FloatToInt(CassowaryGetValue(cSolverX, "LENGTH"));
    int nTileX = nTile % nWidth;
    int nTileY = nTile / nWidth;
    float fX = AV_GetSolverValue(cSolverX, IntToFloat(nTileX));
    float fY = AV_GetSolverValue(cSolverY, IntToFloat(nTileY));
    float fZ = 0.5f + (nHeight * (TS_GetTilesetHeightTransition(AV_AREA_TILESET) * AV_TILES_TILE_SCALE));
    vector vTranslate = Vector(fX, fY, fZ);
    vector vRotate = Vector((nOrientation * 90.0f), 0.0f, 0.0f);
    effect eTile = TagEffect(EffectVisualEffect(AV_VISUALEFFECT_START_ROW + nTile, FALSE, AV_TILES_TILE_SCALE, vTranslate, vRotate), "TILE_" + IntToString(nTile));

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTile, oDisplay);
}

void AV_OnAreaGenerated(string sAreaID)
{
    object oDisplay = GetObjectByTag(AV_DISPLAY_PLACEABLE_TAG);
    location locSpawn = GetLocation(GetObjectByTag(AV_WP_CENTER_TAG));

    if (GetIsObjectValid(oDisplay))
        DestroyObject(oDisplay);

    oDisplay = GffTools_CreatePlaceable(GetLocalJson(GetDataObject(AV_SCRIPT_NAME), AV_DISPLAY_PLACEABLE), locSpawn);

    int nTile, nNumTiles = AG_GetIntDataByKey(sAreaID, AG_DATA_KEY_NUM_TILES);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        int nTileID = AG_Tile_GetID(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
        if (nTileID != AG_INVALID_TILE_ID)
        {
            int nOrientation = AG_Tile_GetOrientation(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
            int nHeight = AG_Tile_GetHeight(sAreaID, AG_DATA_KEY_ARRAY_TILES, nTile);
            string sModel = NWNX_Tileset_GetTileModel(AV_AREA_TILESET, nTileID);

            NWNX_Player_SetResManOverride(GetFirstPC(), 2002, AV_VISUALEFFECT_DUMMY_NAME + IntToString(nTile), sModel);
            DelayCommand(0.01f * nTile, AG_DelayedApplyEffect(oDisplay, nTile, nTileID, nOrientation, nHeight));
        }
    }

}

