/*
    Script: ef_s_endlesscamp
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_endlesspath"

const string EC_LOG_TAG         = "EndlessCamp";
const string EC_SCRIPT_NAME     = "ef_s_endlesscamp";

// @NWNX[EP_EVENT_AREA_POST_PROCESS_FINISHED]
void EC_OnAreaPostProcessed()
{
    object oArea = OBJECT_SELF;
    string sAreaID = GetTag(oArea);

    string sQuery = "SELECT tile_id, tile_x, tile_y FROM " + EP_GetTilesTable() +
                    "WHERE area_id=@area_id AND ((tile_id >= 1220 AND tile_id <= 1223) OR tile_id = 1215);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@area_id", sAreaID);

    // TODO: TileID 1215 - Camp Full

    while (SqlStep(sql))
    {
        int nTileID = SqlGetInt(sql, 0);
        int nTileX = SqlGetInt(sql, 1);
        int nTileY = SqlGetInt(sql, 2);
        WriteLog(EC_LOG_TAG, "* Found Campsite Type '" + IntToString(nTileID) + "' @ " + IntToString(nTileX) + "," + IntToString(nTileY) + " in area: " + sAreaID);
    }
}
