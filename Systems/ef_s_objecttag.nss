/*
    Script: ef_s_objecttag
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_c_profiler"

const string OBJECTTAG_SCRIPT_NAME  = "ef_s_objecttag";

int ObjectTag_IsTaggable(object oObject);
void ObjectTag_Add(object oObject, string sTag);
void ObjectTag_Remove(object oObject, string sTag);
int ObjectTag_Count(object oObject);
int ObjectTag_HasTag(object oObject, string sTag);
json ObjectTag_GetTags(object oObject);
void ObjectTag_UpdateAreaAndPosition(object oObject, object oArea, vector vPosition);
object ObjectTag_GetNearestObjectWithTag(object oOrigin, string sTag);
json ObjectTag_GetObjectsWithTag(object oOrigin, string sTag);
int ObjectTag_GetNumberOfObjectsWithTag(string sTag, object oArea = OBJECT_INVALID);

// @CORE[CORE_SYSTEM_INIT]
void ObjectTag_Init()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + OBJECTTAG_SCRIPT_NAME + " (" +
                    "object INTEGER NOT NULL, " +
                    "tag TEXT NOT NULL, " +
                    "area INTEGER NOT NULL, " +
                    "pos_x REAL NOT NULL, " +
                    "pos_y REAL NOT NULL, " +
                    "pos_z REAL NOT NULL, " +
                    "PRIMARY KEY(object, tag));";
    SqlStep(SqlPrepareQueryModule(sQuery));
    SqlStep(SqlPrepareQueryModule("CREATE INDEX idx_area_tag ON " + OBJECTTAG_SCRIPT_NAME + " (area, tag);"));
}

// @CONSOLE[ObjectTag_GetNearestObjectWithTag::]
string ObjectTag_TestNearest(string sTag = "SEAT")
{
    Profiler_Start("ObjectTag_GetNearestObjectWithTag");
    object oObject = ObjectTag_GetNearestObjectWithTag(OBJECT_SELF, sTag);
    string s = Profiler_Stop();
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_KNOCK), oObject);
    return s;
}

// @CONSOLE[ObjectTag_GetObjectsWithTag::]
string ObjectTag_TestObjects(string sTag = "SEAT")
{
    Profiler_Start("ObjectTag_GetObjectsWithTag");
    json jObjects = ObjectTag_GetObjectsWithTag(OBJECT_SELF, sTag);
    string s = Profiler_Stop();

    return s + "\n\n" + JsonDump(jObjects, 0);
}

int ObjectTag_IsTaggable(object oObject)
{
    return GetIsObjectValid(oObject) &&
           (GetObjectType(oObject) == OBJECT_TYPE_PLACEABLE ||
            GetObjectType(oObject) == OBJECT_TYPE_WAYPOINT ||
            GetObjectType(oObject) == OBJECT_TYPE_DOOR);
}

void ObjectTag_Add(object oObject, string sTag)
{
    if (!ObjectTag_IsTaggable(oObject) || ObjectTag_HasTag(oObject, sTag))
        return;

    sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + OBJECTTAG_SCRIPT_NAME + "(object, tag, area, pos_x, pos_y, pos_z) " +
                                         "VALUES(@object, @tag, @area, @pos_x, @pos_y, @pos_z);");
    SqlBindObjectRef(sql, "@object", oObject);
    SqlBindString(sql, "@tag", sTag);
    SqlBindObjectRef(sql, "@area", GetArea(oObject));
    SqlBindVectorAsFloats(sql, "pos_", GetPosition(oObject));
    SqlStep(sql);
}

void ObjectTag_Remove(object oObject, string sTag)
{
    sqlquery sql = SqlPrepareQueryModule("DELETE FROM " + OBJECTTAG_SCRIPT_NAME + " WHERE object = @object AND tag = @tag;");
    SqlBindObjectRef(sql, "@object", oObject);
    SqlBindString(sql, "@tag", sTag);
    SqlStep(sql);
}

int ObjectTag_Count(object oObject)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT COUNT(object) FROM " + OBJECTTAG_SCRIPT_NAME + " WHERE object = @object;");
    SqlBindObjectRef(sql, "@object", oObject);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

int ObjectTag_HasTag(object oObject, string sTag)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT object FROM " + OBJECTTAG_SCRIPT_NAME + " WHERE object = @object AND tag = @tag;");
    SqlBindObjectRef(sql, "@object", oObject);
    SqlBindString(sql, "@tag", sTag);
    return SqlStep(sql) ? SqlGetObjectRef(sql, 0) == oObject : FALSE;
}

json ObjectTag_GetTags(object oObject)
{
    json jArray = JsonArray();
    sqlquery sql = SqlPrepareQueryModule("SELECT tag FROM " + OBJECTTAG_SCRIPT_NAME + " WHERE object = @object;");
    SqlBindObjectRef(sql, "@object", oObject);

    while (SqlStep(sql))
    {
        JsonArrayInsertStringInplace(jArray, SqlGetString(sql, 0));
    }

    return jArray;
}

void ObjectTag_UpdateAreaAndPosition(object oObject, object oArea, vector vPosition)
{
    sqlquery sql = SqlPrepareQueryModule("UPDATE " + OBJECTTAG_SCRIPT_NAME + " SET area = @area, pos_x = @pos_x, pos_y = @pos_y, pos_z = @pos_z WHERE object = @object;");
    SqlBindObjectRef(sql, "@object", oObject);
    SqlBindObjectRef(sql, "@area", oArea);
    SqlBindVectorAsFloats(sql, "pos_", vPosition);
}

object ObjectTag_GetNearestObjectWithTag(object oOrigin, string sTag)
{
    if (!GetIsObjectValid(oOrigin))
        return OBJECT_INVALID;

    sqlquery sql = SqlPrepareQueryModule("SELECT object, " +
                                        "((pos_x - @origin_x) * (pos_x - @origin_x) + " +
                                         "(pos_y - @origin_y) * (pos_y - @origin_y) + " +
                                         "(pos_z - @origin_z) * (pos_z - @origin_z)) AS distance " +
                                        "FROM " + OBJECTTAG_SCRIPT_NAME + " " +
                                        "WHERE area = @area AND tag = @tag " +
                                        "ORDER BY distance LIMIT 1;");
    SqlBindString(sql, "@tag", sTag);
    SqlBindObjectRef(sql, "@area", GetArea(oOrigin));
    SqlBindVectorAsFloats(sql, "origin_", GetPosition(oOrigin));
    return SqlStep(sql) ? SqlGetObjectRef(sql, 0) : OBJECT_INVALID;
}

json ObjectTag_GetObjectsWithTag(object oOrigin, string sTag)
{
    json jArray = JsonArray();
    if (!GetIsObjectValid(oOrigin))
        return jArray;

    sqlquery sql = SqlPrepareQueryModule("SELECT object, " +
                                        "((pos_x - @origin_x) * (pos_x - @origin_x) + " +
                                         "(pos_y - @origin_y) * (pos_y - @origin_y) + " +
                                         "(pos_z - @origin_z) * (pos_z - @origin_z)) AS distance " +
                                        "FROM " + OBJECTTAG_SCRIPT_NAME + " " +
                                        "WHERE area = @area AND tag = @tag " +
                                        "ORDER BY distance;");
    SqlBindString(sql, "@tag", sTag);
    SqlBindObjectRef(sql, "@area", GetArea(oOrigin));
    SqlBindVectorAsFloats(sql, "origin_", GetPosition(oOrigin));

    while (SqlStep(sql))
    {
        json jObject = JsonArray();
        JsonArrayInsertStringInplace(jObject, IntToHexString(SqlGetInt(sql, 0)));
        JsonArrayInsertFloatInplace(jObject, SqlGetFloat(sql, 1));
        JsonArrayInsertInplace(jArray, jObject);
    }

    return jArray;
}

int ObjectTag_GetNumberOfObjectsWithTag(string sTag, object oArea = OBJECT_INVALID)
{
    sqlquery sql = SqlPrepareQueryModule("SELECT COUNT(object) FROM " + OBJECTTAG_SCRIPT_NAME +
        " WHERE tag = @tag" + (oArea != OBJECT_INVALID ? " AND area = @area" : "") + ";");
    SqlBindString(sql, "@tag", sTag);
    if (oArea != OBJECT_INVALID)
        SqlBindObjectRef(sql, "@area", oArea);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}
