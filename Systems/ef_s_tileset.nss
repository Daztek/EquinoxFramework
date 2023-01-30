/*
    Script: ef_s_tileset
    Author: Daz

    Description:
*/

#include "ef_i_core"
#include "ef_s_profiler"
#include "nwnx_tileset"

const string TS_SCRIPT_NAME                     = "ef_s_tileset";

const string TS_LOADED_TILESETS_ARRAY           = "LoadedTilesets";

const string TS_TABLE_NAME_TILES                = "tiles";
const string TS_TABLE_NAME_GROUPS               = "groups";
const string TS_TABLE_NAME_GROUP_TILES          = "grouptiles";
const string TS_TABLE_NAME_SINGLE_GROUP_TILES   = "singlegrouptiles";

const int TS_MAX_TILE_HEIGHT                    = 3;

struct TS_TileStruct
{
    string sTL;
    string sT;
    string sTR;
    string sR;
    string sBR;
    string sB;
    string sBL;
    string sL;
};

struct TS_DoorStruct
{
    int nType;
    vector vPosition;
    float fOrientation;
    string sResRef;
};

object TS_GetTilesetDataObject(string sTileset);
string TS_GetTableName(string sTileset, string sType);
void TS_CreateTilesetTables(string sTileset);
json TS_GetLoadedTilesets();
void TS_SetTilesetLoaded(string sTileset);
int TS_GetTilesetLoaded(string sTileset);

struct TS_TileStruct TS_RotateTileStruct(struct TS_TileStruct strTile);
string TS_SetEdge(string sEdge, string sCorner1, string sCorner2);
struct TS_TileStruct TS_UpperCaseTileStruct(struct TS_TileStruct str);
struct TS_TileStruct TS_GetTileEdgesAndCorners(string sTileset, int nTileID);
struct TS_TileStruct TS_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation);
int TS_GetHasTerrainOrCrosser(struct TS_TileStruct str, string sType);
int TS_GetTerrainAndCrosserIsType(struct TS_TileStruct str, string sTerrainType, string sCrosserType);
int TS_GetNumOfTerrainOrCrosser(struct TS_TileStruct str, string sType);
struct TS_TileStruct TS_ReplaceTerrainOrCrosser(struct TS_TileStruct str, string sOld, string sNew);
struct TS_TileStruct TS_ReplaceTerrain(struct TS_TileStruct str, string sOld, string sNew);
struct TS_TileStruct TS_SetTerrain(struct TS_TileStruct str, string sTerrain);
int TS_GetTerrainIsOfType(struct TS_TileStruct str, string sTerrain);
int TS_GetIsCrosser(string sTileset, string sEdge);
struct TS_TileStruct TS_IncreaseTileHeight(string sTileset, struct TS_TileStruct str, int nHeight);
string TS_StripHeightIndicator(string sTC);
int TS_GetTCBitmask(string sTileset, string sTC);
int TS_GetTileTCBitmask(string sTileset, struct TS_TileStruct str);

int TS_GetTilesetNumTiles(string sTileset);
int TS_GetHasTileHeightTransition(string sTileset);
float TS_GetTilesetHeightTransition(string sTileset);
int TS_GetTilesetNumTerrain(string sTileset);
string TS_GetTilesetTerrain(string sTileset, int nIndex);
int TS_GetTilesetNumCrossers(string sTileset);
string TS_GetTilesetCrosser(string sTileset, int nIndex);
int TS_GetTilesetNumGroups(string sTileset);
string TS_GetTilesetDefaultFloorTerrain(string sTileset);
string TS_GetTilesetDefaultEdgeTerrain(string sTileset);
int TS_GetTilesetNumDoors(string sTileset, int nTileID);
struct TS_DoorStruct TS_GetTilesetTileDoor(string sTileset, int nTileID, int nIndex);
int TS_GetIsTilesetGroupTile(string sTileset, int nTileID);
json TS_GetTilesetTerrainCrosserArray(string sTileset);
json TS_GetTilesetTerrainArray(string sTileset);
json TS_GetTilesetCrosserArray(string sTileset);

void TS_LoadTilesetData(string sTileset);
void TS_ProcessTilesetGroups(string sTileset);
void TS_ProcessTileDoors(string sTileset, int nTileID);
void TS_InsertTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct TS_TileStruct str);
void TS_ProcessTile(string sTileset, int nTileID);
void TS_InsertSingleGroupTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct TS_TileStruct str);
void TS_ProcessSingleGroupTile(string sTileset, int nTileID);

vector TS_RotateCanonicalToReal(int nOrientation, vector vCanonical);
void TS_PrintTileStruct(struct TS_TileStruct str, int nTileID = -1);
string TS_GetTileStructAsString(string sTileset, int nTileID);

// @CORE[EF_SYSTEM_INIT]
void Tileset_Init()
{
    TS_LoadTilesetData(TILESET_RESREF_MEDIEVAL_RURAL_2);
    TS_LoadTilesetData(TILESET_RESREF_MINES_AND_CAVERNS);
}

object TS_GetTilesetDataObject(string sTileset)
{
    return GetDataObject(TS_SCRIPT_NAME + sTileset);
}

string TS_GetTableName(string sTileset, string sType)
{
    return TS_SCRIPT_NAME + "_" + sTileset + "_" + sType;
}

json TS_GetLoadedTilesets()
{
    return GetLocalJsonOrDefault(GetDataObject(TS_SCRIPT_NAME), TS_LOADED_TILESETS_ARRAY, JsonArray());
}

void TS_SetTilesetLoaded(string sTileset)
{
    SetLocalJson(GetDataObject(TS_SCRIPT_NAME), TS_LOADED_TILESETS_ARRAY, JsonArrayInsertString(TS_GetLoadedTilesets(), sTileset));
}

int TS_GetTilesetLoaded(string sTileset)
{
    return JsonArrayContainsString(TS_GetLoadedTilesets(), sTileset);
}

void TS_CreateTilesetTables(string sTileset)
{
    string sQuery; sqlquery sql;

    sQuery = "CREATE TABLE IF NOT EXISTS " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) + " (" +
             "tile_id INTEGER NOT NULL, " +
             "orientation INTEGER NOT NULL, " +
             "height INTEGER NOT NULL, " +
             "tl TEXT NOT NULL, " +
             "t TEXT NOT NULL, " +
             "tr TEXT NOT NULL, " +
             "r TEXT NOT NULL, " +
             "br TEXT NOT NULL, " +
             "b TEXT NOT NULL, " +
             "bl TEXT NOT NULL, " +
             "l TEXT NOT NULL, " +
             "bitmask INTEGER NOT NULL, " +
             "is_group_tile INTEGER NOT NULL, " +
             "PRIMARY KEY(tile_id, orientation, height));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + TS_GetTableName(sTileset, TS_TABLE_NAME_GROUPS) + " (" +
             "group_id INTEGER NOT NULL PRIMARY KEY, " +
             "name TEXT NOT NULL, " +
             "strref INTEGER NOT NULL, " +
             "rows INTEGER NOT NULL, " +
             "columns INTEGER NOT NULL, " +
             "num_tiles INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + TS_GetTableName(sTileset, TS_TABLE_NAME_GROUP_TILES) + " (" +
             "group_id INTEGER NOT NULL, " +
             "tile_index INTEGER NOT NULL, " +
             "tile_id INTEGER NOT NULL, " +
             "PRIMARY KEY(group_id, tile_index));";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE TABLE IF NOT EXISTS " + TS_GetTableName(sTileset, TS_TABLE_NAME_SINGLE_GROUP_TILES) + " (" +
             "tile_id INTEGER NOT NULL, " +
             "orientation INTEGER NOT NULL, " +
             "height INTEGER NOT NULL, " +
             "tl TEXT NOT NULL, " +
             "t TEXT NOT NULL, " +
             "tr TEXT NOT NULL, " +
             "r TEXT NOT NULL, " +
             "br TEXT NOT NULL, " +
             "b TEXT NOT NULL, " +
             "bl TEXT NOT NULL, " +
             "l TEXT NOT NULL, " +
             "bitmask INTEGER NOT NULL, " +
             "PRIMARY KEY(tile_id, orientation, height));";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

// TILE STRUCT FUNCTIONS

struct TS_TileStruct TS_RotateTileStruct(struct TS_TileStruct strTile)
{
    struct TS_TileStruct str;

    str.sTL = strTile.sTR;
    str.sT = strTile.sR;
    str.sTR = strTile.sBR;
    str.sR = strTile.sB;
    str.sBR = strTile.sBL;
    str.sB = strTile.sL;
    str.sBL = strTile.sTL;
    str.sL = strTile.sT;

    return str;
}

string TS_SetEdge(string sEdge, string sCorner1, string sCorner2)
{
    if (sCorner1 == "" && sCorner2 == "" && sEdge == "")
        return "";
    else
        return sEdge == "" ? "[NONE]" : sEdge;
}

struct TS_TileStruct TS_UpperCaseTileStruct(struct TS_TileStruct str)
{
    str.sTL = GetStringUpperCase(str.sTL);
    str.sT = GetStringUpperCase(str.sT);
    str.sTR = GetStringUpperCase(str.sTR);
    str.sR = GetStringUpperCase(str.sR);
    str.sBR = GetStringUpperCase(str.sBR);
    str.sB = GetStringUpperCase(str.sB);
    str.sBL = GetStringUpperCase(str.sBL);
    str.sL = GetStringUpperCase(str.sL);

    return str;
}

struct TS_TileStruct TS_GetTileEdgesAndCorners(string sTileset, int nTileID)
{
    struct NWNX_Tileset_TileEdgesAndCorners strTile = NWNX_Tileset_GetTileEdgesAndCorners(sTileset, nTileID);
    struct TS_TileStruct str;
    str.sTL = strTile.sTopLeft;
    str.sT = strTile.sTop;
    str.sTR = strTile.sTopRight;
    str.sR = strTile.sRight;
    str.sBR = strTile.sBottomRight;
    str.sB = strTile.sBottom;
    str.sBL = strTile.sBottomLeft;
    str.sL = strTile.sLeft;
    str = TS_UpperCaseTileStruct(str);

    str.sT = TS_SetEdge(str.sT, str.sTL, str.sTR);
    str.sR = TS_SetEdge(str.sR, str.sTR, str.sBR);
    str.sB = TS_SetEdge(str.sB, str.sBL, str.sBR);
    str.sL = TS_SetEdge(str.sL, str.sTL, str.sBL);

    return str;
}

struct TS_TileStruct TS_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation)
{
    struct TS_TileStruct str = TS_GetTileEdgesAndCorners(sTileset, nTileID);

    if (!nOrientation)
        return str;

    int nCount;
    for (nCount = 0; nCount < nOrientation; nCount++)
    {
        str = TS_RotateTileStruct(str);
    }

    return str;
}

int TS_GetHasTerrainOrCrosser(struct TS_TileStruct str, string sType)
{
    return (str.sTL == sType || str.sT == sType || str.sTR == sType || str.sR == sType ||
            str.sBR == sType || str.sB == sType || str.sBL == sType || str.sL == sType);
}

int TS_GetTerrainAndCrosserIsType(struct TS_TileStruct str, string sTerrainType, string sCrosserType)
{
    return (str.sTL == sTerrainType && str.sT == sCrosserType && str.sTR == sTerrainType && str.sR == sCrosserType ||
            str.sBR == sTerrainType && str.sB == sCrosserType && str.sBL == sTerrainType && str.sL == sCrosserType);
}

int TS_GetNumOfTerrainOrCrosser(struct TS_TileStruct str, string sType)
{
    return (str.sTL == sType) + (str.sT == sType) + (str.sTR == sType) + (str.sR == sType) +
           (str.sBR == sType) + (str.sB == sType) + (str.sBL == sType) + (str.sL == sType);
}

struct TS_TileStruct TS_ReplaceTerrainOrCrosser(struct TS_TileStruct str, string sOld, string sNew)
{
    if (str.sTL == sOld) str.sTL = sNew;
    if (str.sT  == sOld) str.sT = sNew;
    if (str.sTR == sOld) str.sTR = sNew;
    if (str.sR  == sOld) str.sR = sNew;
    if (str.sBR == sOld) str.sBR = sNew;
    if (str.sB  == sOld) str.sB = sNew;
    if (str.sBL == sOld) str.sBL = sNew;
    if (str.sL  == sOld) str.sL = sNew;

    return str;
}

struct TS_TileStruct TS_ReplaceTerrain(struct TS_TileStruct str, string sOld, string sNew)
{
    if (str.sTL == sOld) str.sTL = sNew;
    if (str.sTR == sOld) str.sTR = sNew;
    if (str.sBR == sOld) str.sBR = sNew;
    if (str.sBL == sOld) str.sBL = sNew;

    return str;
}

struct TS_TileStruct TS_SetTerrain(struct TS_TileStruct str, string sTerrain)
{
    str.sTL = sTerrain;
    str.sTR = sTerrain;
    str.sBR = sTerrain;
    str.sBL = sTerrain;
    return str;
}

int TS_GetTerrainIsOfType(struct TS_TileStruct str, string sTerrain)
{
    return (str.sTL == sTerrain) && (str.sTR == sTerrain) &&
           (str.sBR == sTerrain) && (str.sBL == sTerrain);
}

int TS_GetIsCrosser(string sTileset, string sEdge)
{
    return JsonGetType(JsonFind(TS_GetTilesetCrosserArray(sTileset), JsonString(sEdge))) == JSON_TYPE_INTEGER;
}

struct TS_TileStruct TS_IncreaseTileHeight(string sTileset, struct TS_TileStruct str, int nHeight)
{
    if (!TS_GetHasTileHeightTransition(sTileset))
        return str;

    int nCount;
    string sPlus;
    for (nCount = 0; nCount < nHeight; nCount++)
    {
        sPlus += "+";
    }

    if (str.sTL != "") str.sTL += sPlus;
    if (str.sTR != "") str.sTR += sPlus;
    if (str.sBR != "") str.sBR += sPlus;
    if (str.sBL != "") str.sBL += sPlus;

    return str;
}

string TS_StripHeightIndicator(string sTC)
{
    int nPlus = FindSubString(sTC, "+");
    if (nPlus != -1)
        sTC = GetSubString(sTC, 0, nPlus);

    return sTC;
}

int TS_GetTCBitmask(string sTileset, string sTC)
{
    json jIndex = JsonFind(TS_GetTilesetTerrainCrosserArray(sTileset), JsonString(TS_StripHeightIndicator(sTC)));
    return JsonGetType(jIndex) == JSON_TYPE_INTEGER ? 1 << JsonGetInt(jIndex) : 0;
}

int TS_GetTileTCBitmask(string sTileset, struct TS_TileStruct str)
{
    int nBitmask;

    nBitmask |= TS_GetTCBitmask(sTileset, str.sTL);
    nBitmask |= TS_GetTCBitmask(sTileset, str.sT);
    nBitmask |= TS_GetTCBitmask(sTileset, str.sTR);
    nBitmask |= TS_GetTCBitmask(sTileset, str.sR);
    nBitmask |= TS_GetTCBitmask(sTileset, str.sBR);
    nBitmask |= TS_GetTCBitmask(sTileset, str.sB);
    nBitmask |= TS_GetTCBitmask(sTileset, str.sBL);
    nBitmask |= TS_GetTCBitmask(sTileset, str.sL);

    return nBitmask;
}

// TILESET DATA
int TS_GetTilesetNumTiles(string sTileset)
{
    return GetLocalInt(TS_GetTilesetDataObject(sTileset), "NumTiles");
}

int TS_GetHasTileHeightTransition(string sTileset)
{
    return GetLocalInt(TS_GetTilesetDataObject(sTileset), "HasHeightTransition");
}

float TS_GetTilesetHeightTransition(string sTileset)
{
    return GetLocalFloat(TS_GetTilesetDataObject(sTileset), "HeightTransition");
}

int TS_GetTilesetNumTerrain(string sTileset)
{
    return GetLocalInt(TS_GetTilesetDataObject(sTileset), "NumTerrain");
}

string TS_GetTilesetTerrain(string sTileset, int nIndex)
{
    return GetLocalString(TS_GetTilesetDataObject(sTileset), "Terrain" + IntToString(nIndex));
}

int TS_GetTilesetNumCrossers(string sTileset)
{
    return GetLocalInt(TS_GetTilesetDataObject(sTileset), "NumCrossers");
}

string TS_GetTilesetCrosser(string sTileset, int nIndex)
{
    return GetLocalString(TS_GetTilesetDataObject(sTileset), "Crosser" + IntToString(nIndex));
}

int TS_GetTilesetNumGroups(string sTileset)
{
    return GetLocalInt(TS_GetTilesetDataObject(sTileset), "NumGroups");
}

string TS_GetTilesetDefaultFloorTerrain(string sTileset)
{
    return GetLocalString(TS_GetTilesetDataObject(sTileset), "DefaultFloorTerrain");
}

string TS_GetTilesetDefaultEdgeTerrain(string sTileset)
{
    return GetLocalString(TS_GetTilesetDataObject(sTileset), "DefaultEdgeTerrain");
}

int TS_GetTilesetNumDoors(string sTileset, int nTileID)
{
    return GetLocalInt(TS_GetTilesetDataObject(sTileset), "Tile_" + IntToString(nTileID) + "_NumDoors");
}

json TS_GetTilesetTerrainCrosserArray(string sTileset)
{
    return GetLocalJson(TS_GetTilesetDataObject(sTileset), "TerrainCrosserArray");
}

json TS_GetTilesetTerrainArray(string sTileset)
{
    return GetLocalJson(TS_GetTilesetDataObject(sTileset), "TerrainArray");
}

json TS_GetTilesetCrosserArray(string sTileset)
{
    return GetLocalJson(TS_GetTilesetDataObject(sTileset), "CrosserArray");
}

struct TS_DoorStruct TS_GetTilesetTileDoor(string sTileset, int nTileID, int nIndex)
{
    object oDataObject = TS_GetTilesetDataObject(sTileset);
    int nNumDoors = TS_GetTilesetNumDoors(sTileset, nTileID);
    string sTileVarName = "Tile_" + IntToString(nTileID) + "_Door_" + IntToString(nIndex);
    struct TS_DoorStruct str;

    if (nIndex < nNumDoors && GetLocalInt(oDataObject, sTileVarName))
    {
        str.nType = GetLocalInt(oDataObject, sTileVarName + "_Type");

        location locDoorData = GetLocalLocation(oDataObject, sTileVarName + "_LocationData");
        str.vPosition = GetPositionFromLocation(locDoorData);
        str.fOrientation = GetFacingFromLocation(locDoorData);

        str.sResRef = GetLocalString(oDataObject, sTileVarName + "_ResRef");
    }
    else
        str.nType = -1;

    return str;
}


int TS_GetIsTilesetGroupTile(string sTileset, int nTileID)
{
    string sQuery = "SELECT * FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_GROUP_TILES) + " WHERE tile_id = @tile_id;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@tile_id", nTileID);
    return SqlStep(sql);
}

// LOAD TILESET DATA
void TS_LoadTilesetData(string sTileset)
{
    if (TS_GetTilesetLoaded(sTileset))
        return;

    object oTDO = TS_GetTilesetDataObject(sTileset);

    SqlBeginTransactionModule();

    TS_CreateTilesetTables(sTileset);

    struct NWNX_Tileset_TilesetData str = NWNX_Tileset_GetTilesetData(sTileset);
    SetLocalInt(oTDO, "NumTiles", str.nNumTileData);
    SetLocalInt(oTDO, "HasHeightTransition", str.bHasHeightTransition);
    SetLocalFloat(oTDO, "HeightTransition", str.fHeightTransition);
    SetLocalInt(oTDO, "NumTerrain", str.nNumTerrain);
    SetLocalInt(oTDO, "NumCrossers", str.nNumCrossers);
    SetLocalInt(oTDO, "NumGroups", str.nNumGroups);
    SetLocalString(oTDO, "DefaultFloorTerrain", GetStringUpperCase(str.sFloorTerrain));
    SetLocalString(oTDO, "DefaultEdgeTerrain", GetStringUpperCase(str.sBorderTerrain));

    string sName = (str.nDisplayNameStrRef != -1 ? GetStringByStrRef(str.nDisplayNameStrRef) : str.sUnlocalizedName);

    LogInfo("Loading Tileset Data: " + sTileset + " -> " + sName);

    json jTC = JsonArray(), jTerrain = JsonArray(), jCrosser = JsonArray();
    int nTerrainNum;
    for (nTerrainNum = 0; nTerrainNum < str.nNumTerrain; nTerrainNum++)
    {
        string sTerrain = GetStringUpperCase(NWNX_Tileset_GetTilesetTerrain(sTileset, nTerrainNum));
        SetLocalString(oTDO, "Terrain" + IntToString(nTerrainNum), sTerrain);
        jTC = JsonArrayInsertString(jTC, sTerrain);
        jTerrain = JsonArrayInsertString(jTerrain, sTerrain);
    }

    int nCrosserNum;
    for (nCrosserNum = 0; nCrosserNum < str.nNumCrossers; nCrosserNum++)
    {
        string sCrosser = GetStringUpperCase(NWNX_Tileset_GetTilesetCrosser(sTileset, nCrosserNum));
        SetLocalString(oTDO, "Crosser" + IntToString(nCrosserNum), sCrosser);
        jTC = JsonArrayInsertString(jTC, sCrosser);
        jCrosser = JsonArrayInsertString(jCrosser, sCrosser);
    }

    SetLocalJson(oTDO, "TerrainCrosserArray", jTC);
    SetLocalJson(oTDO, "TerrainArray", jTerrain);
    SetLocalJson(oTDO, "CrosserArray", jTerrain);

    TS_ProcessTilesetGroups(sTileset);

    int nTileID;
    for (nTileID = 0; nTileID < str.nNumTileData; nTileID++)
    {
        TS_ProcessTileDoors(sTileset, nTileID);
        TS_ProcessTile(sTileset, nTileID);
    }

    SqlCommitTransactionModule();

    TS_SetTilesetLoaded(sTileset);

    NWNX_Util_SetInstructionsExecuted(0);
}

void TS_ProcessTilesetGroups(string sTileset)
{
    int nNumGroups = TS_GetTilesetNumGroups(sTileset);

    if (!nNumGroups)
        return;

    object oModule = GetModule();
    object oDataObject = TS_GetTilesetDataObject(sTileset);

    int nGroupNum;
    for (nGroupNum = 0; nGroupNum < nNumGroups; nGroupNum++)
    {
        struct NWNX_Tileset_TilesetGroupData strGroupData = NWNX_Tileset_GetTilesetGroupData(sTileset, nGroupNum);
        int nNumGroupTiles = strGroupData.nRows * strGroupData.nColumns;

        string sQuery = "INSERT INTO " + TS_GetTableName(sTileset, TS_TABLE_NAME_GROUPS) + " (group_id, name, strref, rows, columns, num_tiles) " +
                        "VALUES(@group_id, @name, @strref, @rows, @columns, @num_tiles);";
        sqlquery sql = SqlPrepareQueryModule(sQuery);
        SqlBindInt(sql, "@group_id", nGroupNum);
        SqlBindString(sql, "@name", strGroupData.sName);
        SqlBindInt(sql, "@strref", strGroupData.nStrRef);
        SqlBindInt(sql, "@rows", strGroupData.nRows);
        SqlBindInt(sql, "@columns", strGroupData.nColumns);
        SqlBindInt(sql, "@num_tiles", nNumGroupTiles);
        SqlStep(sql);

        int nGroupTileIndex;
        for (nGroupTileIndex = 0; nGroupTileIndex < nNumGroupTiles; nGroupTileIndex++)
        {
            int nGroupTileID = NWNX_Tileset_GetTilesetGroupTile(sTileset, nGroupNum, nGroupTileIndex);

            sQuery = "INSERT INTO " + TS_GetTableName(sTileset, TS_TABLE_NAME_GROUP_TILES) + " (group_id, tile_index, tile_id) " +
                     "VALUES(@group_id, @tile_index, @tile_id);";
            sql = SqlPrepareQueryModule(sQuery);
            SqlBindInt(sql, "@group_id", nGroupNum);
            SqlBindInt(sql, "@tile_index", nGroupTileIndex);
            SqlBindInt(sql, "@tile_id", nGroupTileID);
            SqlStep(sql);

            if (nNumGroupTiles == 1)
                TS_ProcessSingleGroupTile(sTileset, nGroupTileID);
        }
    }
}

void TS_ProcessTileDoors(string sTileset, int nTileID)
{
    int nNumDoors = NWNX_Tileset_GetTileNumDoors(sTileset, nTileID);

    if (!nNumDoors)
        return;

    object oDataObject = TS_GetTilesetDataObject(sTileset);

    SetLocalInt(oDataObject, "Tile_" + IntToString(nTileID) + "_NumDoors", nNumDoors);

    int nIndex;
    for (nIndex = 0; nIndex < nNumDoors; nIndex++)
    {
        string sTileVarName = "Tile_" + IntToString(nTileID) + "_Door_" + IntToString(nIndex);
        struct NWNX_Tileset_TileDoorData str = NWNX_Tileset_GetTileDoorData(sTileset, nTileID, nIndex);

        if (str.nType != -1)
        {
            SetLocalInt(oDataObject, sTileVarName, TRUE);
            SetLocalInt(oDataObject, sTileVarName + "_Type", str.nType);

            str.fX += 5.0f;
            str.fY += 5.0f;
            str.fOrientation += 90.0f;

            location locDoorData = Location(OBJECT_INVALID, Vector(str.fX, str.fY, str.fZ), str.fOrientation);
            SetLocalLocation(oDataObject, sTileVarName + "_LocationData", locDoorData);

            string sResRef = Get2DAString("doortypes", "TemplateResRef", str.nType);

            SetLocalString(oDataObject, sTileVarName + "_ResRef", sResRef);
        }
    }
}

void TS_InsertTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct TS_TileStruct str)
{
    string sQuery = "INSERT INTO " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) + " (tile_id, orientation, height, tl, t, tr, r, br, b, bl, l, bitmask, is_group_tile) " +
                    "VALUES(@tile_id, @orientation, @height, @tl, @t, @tr, @r, @br, @b, @bl, @l, @bitmask, @is_group_tile);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@tile_id", nTileID);
    SqlBindInt(sql, "@orientation", nOrientation);
    SqlBindInt(sql, "@height", nHeight);
    SqlBindString(sql, "@tl", str.sTL);
    SqlBindString(sql, "@t", str.sT);
    SqlBindString(sql, "@tr", str.sTR);
    SqlBindString(sql, "@r", str.sR);
    SqlBindString(sql, "@br", str.sBR);
    SqlBindString(sql, "@b", str.sB);
    SqlBindString(sql, "@bl", str.sBL);
    SqlBindString(sql, "@l", str.sL);
    SqlBindInt(sql, "@bitmask", TS_GetTileTCBitmask(sTileset, TS_GetTileEdgesAndCorners(sTileset, nTileID)));
    SqlBindInt(sql, "@is_group_tile", TS_GetIsTilesetGroupTile(sTileset, nTileID));
    SqlStep(sql);
}

void TS_ProcessTile(string sTileset, int nTileID)
{
    struct TS_TileStruct strTile = TS_GetTileEdgesAndCorners(sTileset, nTileID);

    if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
    {
        if (TS_GetNumOfTerrainOrCrosser(strTile, "STREET") > 2)
            return;

        if (TS_GetNumOfTerrainOrCrosser(strTile, "ROAD") > 2)
            return;

        if (nTileID == 812 || nTileID == 773 || nTileID == 1021 || nTileID == 541)
            return;

        if (nTileID == 433)
        {
            strTile.sTL = "grass2";
            strTile.sT = "ridge";
            strTile.sTR = "grass+";
            strTile.sR = "ridge";
            strTile.sBR = "grass2";
            strTile.sB = "ridge";
            strTile.sBL = "grass+";
            strTile.sL = "ridge";
            strTile = TS_UpperCaseTileStruct(strTile);
        }
    }

    struct TS_TileStruct str = strTile;

    int nOrientation, nHeight;
    for (nOrientation = 0; nOrientation < 4; nOrientation++)
    {
        TS_InsertTile(sTileset, nTileID, nOrientation, nHeight, str);
        str = TS_RotateTileStruct(str);
    }

    if (TS_GetHasTileHeightTransition(sTileset))
    {
        for (nHeight = 1; nHeight < TS_MAX_TILE_HEIGHT; nHeight++)
        {
            str = TS_IncreaseTileHeight(sTileset, strTile, nHeight);

            for (nOrientation = 0; nOrientation < 4; nOrientation++)
            {
                TS_InsertTile(sTileset, nTileID, nOrientation, nHeight, str);
                str = TS_RotateTileStruct(str);
            }
        }
    }

    EFCore_ResetScriptInstructions();
}

void TS_InsertSingleGroupTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct TS_TileStruct str)
{
    string sQuery = "INSERT INTO " + TS_GetTableName(sTileset, TS_TABLE_NAME_SINGLE_GROUP_TILES) + " (tile_id, orientation, height, tl, t, tr, r, br, b, bl, l, bitmask) " +
                    "VALUES(@tile_id, @orientation, @height, @tl, @t, @tr, @r, @br, @b, @bl, @l, @bitmask);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@tile_id", nTileID);
    SqlBindInt(sql, "@orientation", nOrientation);
    SqlBindInt(sql, "@height", nHeight);
    SqlBindString(sql, "@tl", str.sTL);
    SqlBindString(sql, "@t", str.sT);
    SqlBindString(sql, "@tr", str.sTR);
    SqlBindString(sql, "@r", str.sR);
    SqlBindString(sql, "@br", str.sBR);
    SqlBindString(sql, "@b", str.sB);
    SqlBindString(sql, "@bl", str.sBL);
    SqlBindString(sql, "@l", str.sL);
    SqlBindInt(sql, "@bitmask", TS_GetTileTCBitmask(sTileset, TS_GetTileEdgesAndCorners(sTileset, nTileID)));
    SqlStep(sql);
}

void TS_ProcessSingleGroupTile(string sTileset, int nTileID)
{
    struct TS_TileStruct strTile = TS_GetTileEdgesAndCorners(sTileset, nTileID);

    if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
    {
        if (TS_GetNumOfTerrainOrCrosser(strTile, "STREET") > 2)
            return;

        if (TS_GetNumOfTerrainOrCrosser(strTile, "ROAD") > 2)
            return;

        if (nTileID == 1383)// Forest - Elf Tower
            return;
    }

    struct TS_TileStruct str = strTile;

    int nOrientation, nHeight;
    for (nOrientation = 0; nOrientation < 4; nOrientation++)
    {
        TS_InsertSingleGroupTile(sTileset, nTileID, nOrientation, nHeight, str);
        str = TS_RotateTileStruct(str);
    }

    if (TS_GetHasTileHeightTransition(sTileset))
    {
        for (nHeight = 1; nHeight < TS_MAX_TILE_HEIGHT; nHeight++)
        {
            str = TS_IncreaseTileHeight(sTileset, strTile, nHeight);

            for (nOrientation = 0; nOrientation < 4; nOrientation++)
            {
                TS_InsertSingleGroupTile(sTileset, nTileID, nOrientation, nHeight, str);
                str = TS_RotateTileStruct(str);
            }
        }
    }

    EFCore_ResetScriptInstructions();
}

vector TS_RotateCanonicalToReal(int nOrientation, vector vCanonical)
{
    vector vReal;
    switch (nOrientation)
    {
        case 1:
        {
            vReal.x = 10.0f - vCanonical.y;
            vReal.y = vCanonical.x;
            vReal.z = vCanonical.z;
            break;
        }

        case 2:
        {
            vReal.x = 10.0f - vCanonical.x;
            vReal.y = 10.0f - vCanonical.y;
            vReal.z = vCanonical.z;
            break;
        }

        case 3:
        {
            vReal.x = vCanonical.y;
            vReal.y = 10.0f - vCanonical.x;
            vReal.z = vCanonical.z;
            break;
        }

        default:
            vReal = vCanonical;
            break;

    }

    return vReal;
}

void TS_PrintTileStruct(struct TS_TileStruct str, int nTileID = -1)
{
    PrintString("TILE STRUCT: " + IntToString(nTileID));
    PrintString("TL: " + str.sTL);
    PrintString("T: " + str.sT);
    PrintString("TR: " + str.sTR);
    PrintString("R: " + str.sR);
    PrintString("BR: " + str.sBR);
    PrintString("B: " + str.sB);
    PrintString("BL: " + str.sBL);
    PrintString("L: " + str.sL);
}

string TS_GetTileStructAsString(string sTileset, int nTileID)
{
    struct NWNX_Tileset_TileEdgesAndCorners str = NWNX_Tileset_GetTileEdgesAndCorners(sTileset, nTileID);
    return "TL: " + str.sTopLeft + "\n" +
           "T: " + str.sTop + "\n" +
           "TR: " + str.sTopRight + "\n" +
           "R: " + str.sRight + "\n" +
           "BR: " + str.sBottomRight + "\n" +
           "B: " + str.sBottom + "\n" +
           "BL: " + str.sBottomLeft + "\n" +
           "L: " + str.sLeft;
}
