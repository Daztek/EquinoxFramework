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

const string TS_EMPTY_CROSSER_NAME              = "TSEMPTY";

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
void TS_CreateTOCIndexes(string sTableName);
void TS_CreateTilesetTables(string sTileset);
json TS_GetLoadedTilesets();
void TS_SetTilesetLoaded(string sTileset);
int TS_GetTilesetLoaded(string sTileset);

struct TS_TileStruct TS_RotateTileStruct(struct TS_TileStruct strTile);
struct TS_TileStruct TS_RotateTileStructFromDefault(struct TS_TileStruct strTile, int nOrientation);
string TS_SetEdge(string sEdge, string sCorner1, string sCorner2);
struct TS_TileStruct TS_UpperCaseTileStruct(struct TS_TileStruct str);
struct TS_TileStruct TS_GetTileEdgesAndCorners(string sTileset, int nTileID);
struct TS_TileStruct TS_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation);
struct TS_TileStruct TS_GetCornersAndEdgesByOrientationAndHeight(string sTileset, int nTileID, int nOrientation, int nHeight);
int TS_GetHasTerrainOrCrosser(struct TS_TileStruct str, string sType);
int TS_GetTerrainAndCrosserIsType(struct TS_TileStruct str, string sTerrainType, string sCrosserType);
int TS_GetNumOfTerrainOrCrosser(struct TS_TileStruct str, string sType, int bStripHeightIndicator = FALSE);
struct TS_TileStruct TS_ReplaceTerrainOrCrosser(struct TS_TileStruct str, string sOld, string sNew);
struct TS_TileStruct TS_ReplaceTerrain(struct TS_TileStruct str, string sOld, string sNew);
struct TS_TileStruct TS_SetTerrain(struct TS_TileStruct str, string sTerrain);
struct TS_TileStruct TS_StripHeightIndicatorFromStruct(struct TS_TileStruct str);
int TS_GetTerrainIsUniform(struct TS_TileStruct str);
int TS_GetTerrainIsOfType(struct TS_TileStruct str, string sTerrain);
int TS_GetIsCrosser(string sTileset, string sEdge);
struct TS_TileStruct TS_IncreaseTileHeight(string sTileset, struct TS_TileStruct str, int nHeight);
string TS_StripHeightIndicator(string sTC);
int TS_GetTCBitflag(string sTileset, string sTC);
int TS_GetTileTCBitmask(string sTileset, struct TS_TileStruct str);
int TS_GetTerrainHeight(string sTC);
int TS_GetIsUniformTile(struct TS_TileStruct str);
int TS_CalculateTileHeight(struct TS_TileStruct str);

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
void TS_InsertTile(sqlquery sql, string sTileset, int nTileID, int nOrientation, int nHeight, struct TS_TileStruct str);
void TS_ProcessTile(string sTileset, int nTileID);
void TS_InsertSingleGroupTile(sqlquery sql, string sTileset, int nTileID, int nOrientation, int nHeight, struct TS_TileStruct str);
void TS_ProcessSingleGroupTile(string sTileset, int nTileID);

vector TS_RotateCanonicalToReal(int nOrientation, vector vCanonical);
void TS_PrintTileStruct(struct TS_TileStruct str, int nTileID = -1);
string TS_GetTileStructAsString(string sTileset, int nTileID, int nOrientation);

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

void TS_CreateTOCIndexes(string sTableName)
{
    string sQuery;

    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_all_tl ON " + sTableName + " (tl, t, tr, r, br, b, bl, l);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_all_tr ON " + sTableName + " (tr, r, br, b, bl, l, tl, t);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_all_br ON " + sTableName + " (br, b, bl, l, tl, t, tr, r);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_all_bl ON " + sTableName + " (bl, l, tl, t, tr, r, br, b);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_top ON " + sTableName + " (tl, t, tr);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_right ON " + sTableName + " (tr, r, br);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_bottom ON " + sTableName + " (bl, b, br);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_left ON " + sTableName + " (tl, l, bl);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_tl_tr ON " + sTableName + " (tl, tr);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_tr_br ON " + sTableName + " (tr, br);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_br_lr ON " + sTableName + " (br, bl);";
    SqlStep(SqlPrepareQueryModule(sQuery));
    sQuery = "CREATE INDEX IF NOT EXISTS idx_toc_bl_tl ON " + sTableName + " (bl, tl);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

void TS_CreateTilesetTables(string sTileset)
{
    string sQuery; sqlquery sql;

    sQuery = "CREATE TABLE IF NOT EXISTS " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) + " (" +
             "tile_id INTEGER NOT NULL, " +
             "orientation INTEGER NOT NULL, " +
             "height INTEGER NOT NULL, " +
             "tl INTEGER NOT NULL, " +
             "t INTEGER NOT NULL, " +
             "tr INTEGER NOT NULL, " +
             "r INTEGER NOT NULL, " +
             "br INTEGER NOT NULL, " +
             "b INTEGER NOT NULL, " +
             "bl INTEGER NOT NULL, " +
             "l INTEGER NOT NULL, " +
             "bitmask INTEGER NOT NULL, " +
             "is_group_tile INTEGER NOT NULL, " +
             "PRIMARY KEY(tile_id, orientation, height));";
    SqlStep(SqlPrepareQueryModule(sQuery));
    TS_CreateTOCIndexes(TS_GetTableName(sTileset, TS_TABLE_NAME_TILES));

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
             "tl INTEGER NOT NULL, " +
             "t INTEGER NOT NULL, " +
             "tr INTEGER NOT NULL, " +
             "r INTEGER NOT NULL, " +
             "br INTEGER NOT NULL, " +
             "b INTEGER NOT NULL, " +
             "bl INTEGER NOT NULL, " +
             "l INTEGER NOT NULL, " +
             "bitmask INTEGER NOT NULL, " +
             "PRIMARY KEY(tile_id, orientation, height));";
    SqlStep(SqlPrepareQueryModule(sQuery));
    TS_CreateTOCIndexes(TS_GetTableName(sTileset, TS_TABLE_NAME_SINGLE_GROUP_TILES));
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

struct TS_TileStruct TS_RotateTileStructFromDefault(struct TS_TileStruct strTile, int nOrientation)
{
    if (!nOrientation)
        return strTile;

    struct TS_TileStruct str;
    switch (nOrientation)
    {
        case 1:
        {
            str.sTL = strTile.sTR;
            str.sT = strTile.sR;
            str.sTR = strTile.sBR;
            str.sR = strTile.sB;
            str.sBR = strTile.sBL;
            str.sB = strTile.sL;
            str.sBL = strTile.sTL;
            str.sL = strTile.sT;
            break;
        }

        case 2:
        {
            str.sTL = strTile.sBR;
            str.sT = strTile.sB;
            str.sTR = strTile.sBL;
            str.sR = strTile.sL;
            str.sBR = strTile.sTL;
            str.sB = strTile.sT;
            str.sBL = strTile.sTR;
            str.sL = strTile.sR;
            break;
        }

        case 3:
        {
            str.sTL = strTile.sBL;
            str.sT = strTile.sL;
            str.sTR = strTile.sTL;
            str.sR = strTile.sT;
            str.sBR = strTile.sTR;
            str.sB = strTile.sR;
            str.sBL = strTile.sBR;
            str.sL = strTile.sB;
            break;
        }
    }

    return str;
}

string TS_SetEdge(string sEdge, string sCorner1, string sCorner2)
{
    return sEdge == "" ? TS_EMPTY_CROSSER_NAME : sEdge;
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
    object oDataObject = GetDataObject(TS_SCRIPT_NAME);
    struct TS_TileStruct str;
    json jTile = GetLocalJson(oDataObject, "TILEDATA_" + sTileset + IntToString(nTileID));
    if (!JsonGetType(jTile))
    {
        struct NWNX_Tileset_TileEdgesAndCorners strTile = NWNX_Tileset_GetTileEdgesAndCorners(sTileset, nTileID);

        if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
        {
            switch (nTileID)
            {
                case 204:
                    strTile.sLeft = "";
                    strTile.sRight = "";
                break;

                case 433:
                    strTile.sTopLeft = "grass";
                    strTile.sTop = "ridge";
                    strTile.sTopRight = "grass2";
                    strTile.sRight = "ridge";
                    strTile.sBottomRight = "grass";
                    strTile.sBottom = "ridge";
                    strTile.sBottomLeft = "grass2";
                    strTile.sLeft = "ridge";
                break;
            }
        }

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

        json jTile = JsonObject();
        JsonObjectSetStringInplace(jTile, "TL", str.sTL);
        JsonObjectSetStringInplace(jTile, "T", str.sT);
        JsonObjectSetStringInplace(jTile, "TR", str.sTR);
        JsonObjectSetStringInplace(jTile, "R", str.sR);
        JsonObjectSetStringInplace(jTile, "BR", str.sBR);
        JsonObjectSetStringInplace(jTile, "B", str.sB);
        JsonObjectSetStringInplace(jTile, "BL", str.sBL);
        JsonObjectSetStringInplace(jTile, "L", str.sL);
        SetLocalJson(oDataObject, "TILEDATA_" + sTileset + IntToString(nTileID), jTile);
    }
    else
    {
        str.sTL = JsonObjectGetString(jTile, "TL");
        str.sT = JsonObjectGetString(jTile, "T");
        str.sTR = JsonObjectGetString(jTile, "TR");
        str.sR = JsonObjectGetString(jTile, "R");
        str.sBR = JsonObjectGetString(jTile, "BR");
        str.sB = JsonObjectGetString(jTile, "B");
        str.sBL = JsonObjectGetString(jTile, "BL");
        str.sL = JsonObjectGetString(jTile, "L");
    }

    return str;
}

struct TS_TileStruct TS_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation)
{
    return TS_RotateTileStructFromDefault(TS_GetTileEdgesAndCorners(sTileset, nTileID), nOrientation);
}

struct TS_TileStruct TS_GetCornersAndEdgesByOrientationAndHeight(string sTileset, int nTileID, int nOrientation, int nHeight)
{
    struct TS_TileStruct str = TS_RotateTileStructFromDefault(TS_GetTileEdgesAndCorners(sTileset, nTileID), nOrientation);
    if (nHeight) str = TS_IncreaseTileHeight(sTileset, str, nHeight);
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

int TS_GetNumOfTerrainOrCrosser(struct TS_TileStruct str, string sType, int bStripHeightIndicator = FALSE)
{
    if (bStripHeightIndicator)
        str = TS_StripHeightIndicatorFromStruct(str);

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

struct TS_TileStruct TS_StripHeightIndicatorFromStruct(struct TS_TileStruct str)
{
    str.sTL = TS_StripHeightIndicator(str.sTL);
    str.sT = TS_StripHeightIndicator(str.sT);
    str.sTR = TS_StripHeightIndicator(str.sTR);
    str.sR = TS_StripHeightIndicator(str.sR);
    str.sBR = TS_StripHeightIndicator(str.sBR);
    str.sB = TS_StripHeightIndicator(str.sB);
    str.sBL = TS_StripHeightIndicator(str.sBL);
    str.sL = TS_StripHeightIndicator(str.sL);
    return str;
}

int TS_GetTerrainIsUniform(struct TS_TileStruct str)
{
    return str.sTL == str.sTR && str.sTL == str.sBR && str.sTL == str.sBL;
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
    if (!nHeight || !TS_GetHasTileHeightTransition(sTileset))
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

int TS_GetTCBitflag(string sTileset, string sTC)
{
    json jIndex = JsonFind(TS_GetTilesetTerrainCrosserArray(sTileset), JsonString(TS_StripHeightIndicator(sTC)));
    return JsonGetType(jIndex) == JSON_TYPE_INTEGER ? 1 << JsonGetInt(jIndex) : 0;
}

int TS_GetTileTCBitmask(string sTileset, struct TS_TileStruct str)
{
    int nBitmask;

    nBitmask |= TS_GetTCBitflag(sTileset, str.sTL);
    nBitmask |= TS_GetTCBitflag(sTileset, str.sT);
    nBitmask |= TS_GetTCBitflag(sTileset, str.sTR);
    nBitmask |= TS_GetTCBitflag(sTileset, str.sR);
    nBitmask |= TS_GetTCBitflag(sTileset, str.sBR);
    nBitmask |= TS_GetTCBitflag(sTileset, str.sB);
    nBitmask |= TS_GetTCBitflag(sTileset, str.sBL);
    nBitmask |= TS_GetTCBitflag(sTileset, str.sL);

    return nBitmask;
}

int TS_GetTerrainHeight(string sTC)
{
    int nPlus = FindSubString(sTC, "+");
    if (nPlus == -1) return 0;
    return GetStringLength(sTC) - nPlus;
}

int TS_GetIsUniformTile(struct TS_TileStruct str)
{
    return str.sTR == str.sTL && str.sBL == str.sTL && str.sBR == str.sTL &&
           str.sR == str.sT && str.sB == str.sT && str.sL == str.sT;
}

int TS_CalculateTileHeight(struct TS_TileStruct str)
{
    int nDivide, nHeight;

    if (str.sTL != "")
    {
        nDivide++;
        nHeight += TS_GetTerrainHeight(str.sTL);
    }

    if (str.sTR != "")
    {
        nDivide++;
        nHeight += TS_GetTerrainHeight(str.sTR);
    }

    if (str.sBL != "")
    {
        nDivide++;
        nHeight += TS_GetTerrainHeight(str.sBL);
    }

    if (str.sBR != "")
    {
        nDivide++;
        nHeight += TS_GetTerrainHeight(str.sBR);
    }

    return nDivide ? nHeight / nDivide : 0;
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
    string sQuery = "SELECT tile_id FROM " + TS_GetTableName(sTileset, TS_TABLE_NAME_GROUP_TILES) + " WHERE tile_id = @tile_id;";
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
        JsonArrayInsertStringInplace(jTC, sTerrain);
        JsonArrayInsertStringInplace(jTerrain, sTerrain);
    }

    int nCrosserNum;
    for (nCrosserNum = 0; nCrosserNum < str.nNumCrossers + 1; nCrosserNum++)
    {
        string sCrosser;
        if (nCrosserNum == str.nNumCrossers)
            sCrosser = TS_EMPTY_CROSSER_NAME;
        else
            sCrosser = GetStringUpperCase(NWNX_Tileset_GetTilesetCrosser(sTileset, nCrosserNum));

        SetLocalString(oTDO, "Crosser" + IntToString(nCrosserNum), sCrosser);
        JsonArrayInsertStringInplace(jTC, sCrosser);
        JsonArrayInsertStringInplace(jCrosser, sCrosser);
    }

    SetLocalJson(oTDO, "TerrainCrosserArray", jTC);
    SetLocalJson(oTDO, "TerrainArray", jTerrain);
    SetLocalJson(oTDO, "CrosserArray", jCrosser);

    SqlBeginTransactionModule();

    TS_CreateTilesetTables(sTileset);

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

void TS_InsertTile(sqlquery sql, string sTileset, int nTileID, int nOrientation, int nHeight, struct TS_TileStruct str)
{
    SqlBindInt(sql, "@tile_id", nTileID);
    SqlBindInt(sql, "@orientation", nOrientation);
    SqlBindInt(sql, "@height", nHeight);
    SqlBindInt(sql, "@tl", HashString(str.sTL));
    SqlBindInt(sql, "@t", HashString(str.sT));
    SqlBindInt(sql, "@tr", HashString(str.sTR));
    SqlBindInt(sql, "@r", HashString(str.sR));
    SqlBindInt(sql, "@br", HashString(str.sBR));
    SqlBindInt(sql, "@b", HashString(str.sB));
    SqlBindInt(sql, "@bl", HashString(str.sBL));
    SqlBindInt(sql, "@l", HashString(str.sL));
    SqlBindInt(sql, "@bitmask", TS_GetTileTCBitmask(sTileset, str));
    SqlBindInt(sql, "@is_group_tile", TS_GetIsTilesetGroupTile(sTileset, nTileID));
    SqlStepAndReset(sql);
}

void TS_ProcessTile(string sTileset, int nTileID)
{
    struct TS_TileStruct strTile = TS_GetTileEdgesAndCorners(sTileset, nTileID);

    if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
    {
        if (TS_GetHasTerrainOrCrosser(strTile, "STREET") && TS_GetNumOfTerrainOrCrosser(strTile, "STREET") != 2)
            return;

        if (TS_GetHasTerrainOrCrosser(strTile, "ROAD") && TS_GetNumOfTerrainOrCrosser(strTile, "ROAD") != 2)
            return;

        if (nTileID == 812 || nTileID == 773 || nTileID == 1021 || nTileID == 541)
            return;
    }

    string sQuery = "INSERT INTO " + TS_GetTableName(sTileset, TS_TABLE_NAME_TILES) + " (tile_id, orientation, height, tl, t, tr, r, br, b, bl, l, bitmask, is_group_tile) " +
                    "VALUES(@tile_id, @orientation, @height, @tl, @t, @tr, @r, @br, @b, @bl, @l, @bitmask, @is_group_tile);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);

    struct TS_TileStruct str;
    int nHeight, nMaxHeight = TS_GetHasTileHeightTransition(sTileset) ? TS_MAX_TILE_HEIGHT : 1, nOrientation;
    for (nHeight = 0; nHeight < nMaxHeight; nHeight++)
    {
        str = TS_IncreaseTileHeight(sTileset, strTile, nHeight);

        for (nOrientation = 0; nOrientation < 4; nOrientation++)
        {
            TS_InsertTile(sql, sTileset, nTileID, nOrientation, nHeight, str);
            str = TS_RotateTileStruct(str);
        }
    }

    EFCore_ResetScriptInstructions();
}

void TS_InsertSingleGroupTile(sqlquery sql, string sTileset, int nTileID, int nOrientation, int nHeight, struct TS_TileStruct str)
{
    SqlBindInt(sql, "@tile_id", nTileID);
    SqlBindInt(sql, "@orientation", nOrientation);
    SqlBindInt(sql, "@height", nHeight);
    SqlBindInt(sql, "@tl", HashString(str.sTL));
    SqlBindInt(sql, "@t", HashString(str.sT));
    SqlBindInt(sql, "@tr", HashString(str.sTR));
    SqlBindInt(sql, "@r", HashString(str.sR));
    SqlBindInt(sql, "@br", HashString(str.sBR));
    SqlBindInt(sql, "@b", HashString(str.sB));
    SqlBindInt(sql, "@bl", HashString(str.sBL));
    SqlBindInt(sql, "@l", HashString(str.sL));
    SqlBindInt(sql, "@bitmask", TS_GetTileTCBitmask(sTileset, str));
    SqlStepAndReset(sql);
}

void TS_ProcessSingleGroupTile(string sTileset, int nTileID)
{
    struct TS_TileStruct strTile = TS_GetTileEdgesAndCorners(sTileset, nTileID);

    if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
    {
        if (TS_GetHasTerrainOrCrosser(strTile, "STREET") && TS_GetNumOfTerrainOrCrosser(strTile, "STREET") != 2)
            return;

        if (TS_GetHasTerrainOrCrosser(strTile, "ROAD") && TS_GetNumOfTerrainOrCrosser(strTile, "ROAD") != 2)
            return;

        if (nTileID == 1383)// Forest - Elf Tower
            return;
    }

    string sQuery = "INSERT INTO " + TS_GetTableName(sTileset, TS_TABLE_NAME_SINGLE_GROUP_TILES) + " (tile_id, orientation, height, tl, t, tr, r, br, b, bl, l, bitmask) " +
                    "VALUES(@tile_id, @orientation, @height, @tl, @t, @tr, @r, @br, @b, @bl, @l, @bitmask);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);

    struct TS_TileStruct str;
    int nHeight, nMaxHeight = TS_GetHasTileHeightTransition(sTileset) ? TS_MAX_TILE_HEIGHT : 1, nOrientation;
    for (nHeight = 0; nHeight < nMaxHeight; nHeight++)
    {
        str = TS_IncreaseTileHeight(sTileset, strTile, nHeight);

        for (nOrientation = 0; nOrientation < 4; nOrientation++)
        {
            TS_InsertSingleGroupTile(sql, sTileset, nTileID, nOrientation, nHeight, str);
            str = TS_RotateTileStruct(str);
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

string TS_GetTileStructAsString(string sTileset, int nTileID, int nOrientation)
{
    struct TS_TileStruct str = TS_GetCornersAndEdgesByOrientation(sTileset, nTileID, nOrientation);

    return "TL: " + str.sTL + "\n" +
           "T: " + str.sT + "\n" +
           "TR: " + str.sTR + "\n" +
           "R: " + str.sR + "\n" +
           "BR: " + str.sBR + "\n" +
           "B: " + str.sB + "\n" +
           "BL: " + str.sBL + "\n" +
           "L: " + str.sL;
}
