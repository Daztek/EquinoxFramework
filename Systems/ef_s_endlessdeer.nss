/*
    Script: ef_s_endlessdeer
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_areagen"
#include "ef_s_endlesspath"
#include "ef_s_aibehaviors"

const string ED_SCRIPT_NAME             = "ef_s_endlessdeer";

const int ED_ENTRANCE_DISTANCE          = 3;
const int ED_EXIT_DISTANCE              = 3;
const int ED_PATH_DISTANCE              = 2;
const int ED_GROUP_TILE                 = FALSE;

const float ED_SPAWN_DELAY              = 0.05f;

int ED_GetNumSpawnTiles(string sAreaID)
{
    string sQuery = "SELECT COUNT(tile_index) FROM " + EP_GetTilesTable() +
                    "WHERE area_id=@area_id AND entrance_dist >= @entrance_dist AND exit_dist >= @exit_dist AND path_dist >= @path_dist AND group_tile = @group_tile;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@area_id", sAreaID);
    SqlBindInt(sql, "@entrance_dist", ED_ENTRANCE_DISTANCE);
    SqlBindInt(sql, "@exit_dist", ED_EXIT_DISTANCE);
    SqlBindInt(sql, "@path_dist",  ED_PATH_DISTANCE);
    SqlBindInt(sql, "@group_tile", ED_GROUP_TILE);

    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void ED_SpawnDeer(object oArea, location locSpawn)
{
    AIMan_SpawnCreature("nw_deer", locSpawn, AIB_BEHAVIOR_WANDERFLEE);
}

// @MESSAGEBUS[EP_EVENT_AREA_POST_PROCESS_FINISHED]
void ED_OnAreaPostProcessed()
{
    object oArea = OBJECT_SELF;
    string sAreaID = GetTag(oArea);
    int nCount, nMax = ED_GetNumSpawnTiles(sAreaID);

    int nLimit = nMax / 10;

    LogInfo("Spawning Deer for Area: " + sAreaID + " -> Tiles: " + IntToString(nMax) + ", Spawning: " + IntToString(nLimit));

    if (!nLimit)
        return;

    string sQuery = "SELECT tile_x, tile_y FROM " + EP_GetTilesTable() +
                    "WHERE area_id=@area_id AND entrance_dist >= @entrance_dist AND exit_dist >= @exit_dist AND path_dist >= @path_dist AND group_tile = @group_tile " +
                    "ORDER BY RANDOM() LIMIT @limit;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@area_id", sAreaID);
    SqlBindInt(sql, "@entrance_dist", ED_ENTRANCE_DISTANCE);
    SqlBindInt(sql, "@exit_dist", ED_EXIT_DISTANCE);
    SqlBindInt(sql, "@path_dist",  ED_PATH_DISTANCE);
    SqlBindInt(sql, "@group_tile", ED_GROUP_TILE);
    SqlBindInt(sql, "@limit", nLimit);

    while (SqlStep(sql))
    {
        location locTile = Location(oArea, GetTilePosition(SqlGetInt(sql, 0), SqlGetInt(sql, 1)), IntToFloat(Random(360)));
        DelayCommand(ED_SPAWN_DELAY * nCount++, ED_SpawnDeer(oArea, locTile));
    }
}
