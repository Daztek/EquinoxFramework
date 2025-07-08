/*
    Script: ef_s_objecttag
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"

const string OBJECTTAG_SCRIPT_NAME  = "ef_s_objecttag";

int ObjectTag_IsTaggable(object oObject);
void ObjectTag_Add(object oObject, string sTag);
void ObjectTag_Remove(object oObject, string sTag);
int ObjectTag_Count(object oObject);
int ObjectTag_HasTag(object oObject, string sTag);
json ObjectTag_GetTags(object oObject);
void ObjectTag_UpdateAreaAndPosition(object oObject, object oArea, vector vPosition);

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
    if (!ObjectTag_IsTaggable(oObject) || !ObjectTag_HasTag(oObject, sTag))
        return;

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
