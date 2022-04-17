/*
    Script: ef_s_welcomebear
    Author: Daz
*/

//void main() {}

#include "ef_i_core"
#include "ef_s_endlesspath"

const string WB_LOG_TAG         = "WelcomeBear";
const string WB_SCRIPT_NAME     = "ef_s_welcomebear";

// @EVENT[EP_AREA_POST_PROCESS_FINISHED]
void WB_OnAreaPostProcessed()
{
    object oArea = OBJECT_SELF;
    string sAreaID = GetTag(oArea);

    if (Random(100))
        return;

    string sQuery = "SELECT tile_x, tile_y FROM " + EP_GetTilesTable() +
                    "WHERE area_id=@area_id AND entrance_dist > 0 AND entrance_dist < 3 AND path_dist > 0;" +
                    "ORDER BY RANDOM() LIMIT 1;";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlBindString(sql, "@area_id", sAreaID);

    if (SqlStep(sql))
    {
        WriteLog(WB_LOG_TAG, "* Spawning a friendly welcome bear! :D");

        location locTile = Location(oArea, GetTilePosition(SqlGetInt(sql, 0), SqlGetInt(sql, 1)), IntToFloat(Random(360)));
        object oCreature = CreateObject(OBJECT_TYPE_CREATURE, "nw_bearbrwn", locTile);
        AssignCommand(oCreature, ActionRandomWalk());
    }
}

