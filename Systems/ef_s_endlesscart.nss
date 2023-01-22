/*
    Script: ef_s_endlesscart
    Author: Daz
*/

#include "ef_i_core"
#include "ef_s_endlesspath"

const string EC_SCRIPT_NAME     = "ef_s_endlesscart";

// @NWNX[EP_EVENT_AREA_POST_PROCESS_FINISHED]
void EC_OnAreaPostProcessed()
{
    object oArea = OBJECT_SELF;
    string sAreaID = GetTag(oArea);

    string sQuery = "SELECT tile_id, tile_x, tile_y FROM " + EP_GetTilesTable() +
                    "WHERE area_id=@area_id AND tile_id = 71;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@area_id", sAreaID);

    while (SqlStep(sql))
    {
        int nTileID = SqlGetInt(sql, 0);
        int nTileX = SqlGetInt(sql, 1);
        int nTileY = SqlGetInt(sql, 2);
        LogInfo("Found Cart @ " + IntToString(nTileX) + "," + IntToString(nTileY) + " in area: " + sAreaID);
    }
}
