/*
    Script: ef_s_welcomebear
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_endlesspath"

const string WB_SCRIPT_NAME     = "ef_s_welcomebear";
const int WB_SPAWN_CHANCE       = 1;

// @MESSAGEBUS[EP_EVENT_AREA_POST_PROCESS_FINISHED]
void WB_OnAreaPostProcessed()
{
    if (Random(100) < WB_SPAWN_CHANCE)
    {
        object oArea = OBJECT_SELF;
        string sAreaID = GetTag(oArea);

        string sQuery = "SELECT tile_x, tile_y FROM " + EP_GetTilesTable() +
                        "WHERE area_id=@area_id AND entrance_dist > 0 AND entrance_dist < 3 AND path_dist > 0 " +
                        "ORDER BY RANDOM() LIMIT 1;";
        sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
        SqlBindString(sql, "@area_id", sAreaID);

        if (SqlStep(sql))
        {
            LogInfo("Spawning a friendly welcome bear! :D");

            location locTile = Location(oArea, GetTilePosition(SqlGetInt(sql, 0), SqlGetInt(sql, 1)), IntToFloat(Random(360)));
            object oBear = CreateObject(OBJECT_TYPE_CREATURE, "nw_bearbrwn", locTile);
            AssignCommand(oBear, ActionRandomWalk());
        }
        else
        {
            LogInfo("No suitable tile for a friendly welcome bear! :(");
        }
    }
}
