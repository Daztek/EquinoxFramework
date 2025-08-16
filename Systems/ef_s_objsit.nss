/*
    Script: ef_s_objsit
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_c_mediator"
#include "ef_s_eventman"
#include "ef_s_gfftools"
#include "ef_s_objecttag"

const string OBJSIT_SCRIPT_NAME         = "ef_s_objsit";

const string OBJSIT_SINGLE_SPAWN_TAG    = "OBJSIT_SEAT_1";
const string OBJSIT_SINGLE_TAG          = "OBJSIT_SINGLE_CHAIR";

const string OBJSIT_DOUBLE_SPAWN_TAG    = "OBJSIT_SEAT_2";
const string OBJSIT_DOUBLE_TAG          = "OBJSIT_DOUBLE_BENCH";

const string OBJSIT_SEAT_OBJECT_TAG     = "SEAT";

// @CORE[CORE_SYSTEM_LOAD]
void ObjSit_Load()
{
    int nObjectDispatchListId = EM_GetObjectDispatchListId(OBJSIT_SCRIPT_NAME, EVENT_SCRIPT_PLACEABLE_ON_USED);

    struct GffTools_PlaceableData pdSingle;
    pdSingle.nModel = 179;
    pdSingle.sTag = OBJSIT_SINGLE_TAG;
    pdSingle.sName = "Chair";
    pdSingle.sDescription = "It is a simple chair but the grace of its lines speaks to the quality of its craftmanship.";
    pdSingle.bPlot = TRUE;
    pdSingle.bUseable = TRUE;
    pdSingle.scriptOnUsed = TRUE;
    pdSingle.fFacingAdjustment = 180.0f;
    json jChair = GffTools_GeneratePlaceable(pdSingle);

    struct GffTools_PlaceableData pdDouble;
    pdDouble.nModel = 178;
    pdDouble.sTag = OBJSIT_DOUBLE_TAG;
    pdDouble.sName = "Bench";
    pdDouble.sDescription = "The stout planks of this bench have been worn smooth by years of use.";
    pdDouble.bPlot = TRUE;
    pdDouble.bUseable = TRUE;
    pdDouble.scriptOnUsed = TRUE;
    pdDouble.fFacingAdjustment = 180.0f;
    json jBench = GffTools_GeneratePlaceable(pdDouble);

    object oBench;
    string capclsCreateSeat = CapturedClosure(
    "{ object oArea = GetArea(oBench); vector vPosition = GetPosition(oBench); float fFacing = GetFacing(oBench);" +
    "  location locSpawn = Location(oArea, vPosition + (AngleToVector(fFacing + (arg1 ? 90.0f : -90.0f)) / 2.0f), fFacing);" +
    "  object oSeat = CreateObject(OBJECT_TYPE_PLACEABLE, GFFTOOLS_INVISIBLE_OBJECT_PLC_RESREF, locSpawn);" +
    "  SetPlotFlag(oSeat, TRUE); SetLocalObject(oBench, \"SEAT_\" + (arg1 ? \"1\" : \"2\"), oSeat); return oSeat; }",
    "&oBench", "i", "o", "ef_s_objsit");

    string sQuery = "SELECT oid, tag FROM gameobjects WHERE type = @type AND (tag = @tag1 OR tag = @tag2);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindInt(sql, "@type", OBJECT_TYPE_INTERNAL_WAYPOINT);
    SqlBindString(sql, "@tag1", OBJSIT_SINGLE_SPAWN_TAG);
    SqlBindString(sql, "@tag2", OBJSIT_DOUBLE_SPAWN_TAG);

    int nSingle = 0;
    int nDouble = 0;

    while (SqlStep(sql))
    {
        object oSpawnpoint = SqlGetObjectRef(sql, 0);
        string sTag = SqlGetString(sql, 1);

         if (sTag == OBJSIT_SINGLE_SPAWN_TAG)
        {
            object oSeat = GffTools_CreatePlaceable(jChair, GetLocation(oSpawnpoint));
            ObjectTag_Add(oSeat, OBJSIT_SEAT_OBJECT_TAG);
            EM_ObjectDispatchListInsert(oSeat, nObjectDispatchListId);
            nSingle++;
        }
        else if (sTag == OBJSIT_DOUBLE_SPAWN_TAG)
        {
            oBench = GffTools_CreatePlaceable(jBench, GetLocation(oSpawnpoint));
            ObjectTag_Add(RetObject(Call(capclsCreateSeat, IntArg(TRUE))), OBJSIT_SEAT_OBJECT_TAG);
            ObjectTag_Add(RetObject(Call(capclsCreateSeat, IntArg(FALSE))), OBJSIT_SEAT_OBJECT_TAG);
            EM_ObjectDispatchListInsert(oBench, nObjectDispatchListId);
            nDouble++;
        }
    }

    LogInfo("Created '" + IntToString(nSingle) + "' Single Sitting Objects");
    LogInfo("Created '" + IntToString(nDouble) + "' Double Sitting Objects");
}

// @EVENT[EVENT_SCRIPT_PLACEABLE_ON_USED:DL]
void ObjSit_OnPlaceableUsed()
{
    object oPlayer = GetLastUsedBy();
    object oSelf = OBJECT_SELF;

    if (GetTag(oSelf) == OBJSIT_SINGLE_TAG)
    {
        if (!GetIsObjectValid(GetSittingCreature(oSelf)))
            AssignCommand(oPlayer, ActionSit(oSelf));
    }
    else if (GetTag(oSelf) == OBJSIT_DOUBLE_TAG)
    {
        object oSeat1 = GetLocalObject(oSelf, "SEAT_1");
        object oSeat2 = GetLocalObject(oSelf, "SEAT_2");
        if (GetDistanceBetween(oPlayer, oSeat1) < GetDistanceBetween(oPlayer, oSeat2))
        {
            if (!GetIsObjectValid(GetSittingCreature(oSeat1)))
                AssignCommand(oPlayer, ActionSit(oSeat1));
            else if (!GetIsObjectValid(GetSittingCreature(oSeat2)))
                AssignCommand(oPlayer, ActionSit(oSeat2));
        }
        else
        {
            if (!GetIsObjectValid(GetSittingCreature(oSeat2)))
                AssignCommand(oPlayer, ActionSit(oSeat2));
            else if (!GetIsObjectValid(GetSittingCreature(oSeat1)))
                AssignCommand(oPlayer, ActionSit(oSeat1));
        }
    }
}
