/*
    Script: ef_s_objsit
    Author: Daz

    Description:
*/

#include "ef_i_core"
#include "ef_s_eventman"
#include "ef_s_gfftools"

const string OBJSIT_SCRIPT_NAME         = "ef_s_objsit";

const string OBJSIT_SINGLE_SPAWN_TAG    = "OBJSIT_SINGLE";
const string OBJSIT_SINGLE_TAG          = "OBJSIT_SINGLE_CHAIR";

const string OBJSIT_DOUBLE_SPAWN_TAG    = "OBJSIT_DOUBLE";
const string OBJSIT_DOUBLE_TAG          = "OBJSIT_DOUBLE_BENCH";

// @CORE[EF_SYSTEM_LOAD]
void ObjSit_Load()
{
    object oSpawnpoint;
    int nObjectDispatchListId = EM_GetObjectDispatchListId(OBJSIT_SCRIPT_NAME, EVENT_SCRIPT_PLACEABLE_ON_USED);
    int nNth;

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
    nNth = 0;
    while ((oSpawnpoint = GetObjectByTag(OBJSIT_SINGLE_SPAWN_TAG, nNth++)) != OBJECT_INVALID)
    {
        object oChair = GffTools_CreatePlaceable(jChair, GetLocation(oSpawnpoint));
        EM_ObjectDispatchListInsert(oChair, nObjectDispatchListId);
    }
    LogInfo("Created '" + IntToString(--nNth) + "' Single Sitting Objects");

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
    nNth = 0;
    while ((oSpawnpoint = GetObjectByTag(OBJSIT_DOUBLE_SPAWN_TAG, nNth++)) != OBJECT_INVALID)
    {
        object oBench = GffTools_CreatePlaceable(jBench, GetLocation(oSpawnpoint));
        EM_ObjectDispatchListInsert(oBench, nObjectDispatchListId);
    }
    LogInfo("Created '" + IntToString(--nNth) + "' Double Sitting Objects");
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

        if (!GetIsObjectValid(oSeat1) || !GetIsObjectValid(oSeat2))
        {
            object oArea = GetArea(oSelf);
            vector vPosition = GetPosition(oSelf);
            float fFacing = GetFacing(oSelf);
            location locSeat1 = Location(oArea, vPosition + (AngleToVector(fFacing + 90.0f) / 2.0f), fFacing);
            location locSeat2 = Location(oArea, vPosition + (AngleToVector(fFacing - 90.0f) / 2.0f), fFacing);
            oSeat1 = CreateObject(OBJECT_TYPE_PLACEABLE, GFFTOOLS_INVISIBLE_OBJECT_PLC_RESREF, locSeat1);
            oSeat2 = CreateObject(OBJECT_TYPE_PLACEABLE, GFFTOOLS_INVISIBLE_OBJECT_PLC_RESREF, locSeat2);
            SetPlotFlag(oSeat1, TRUE);
            SetPlotFlag(oSeat2, TRUE);
            SetLocalObject(oSelf, "SEAT_1", oSeat1);
            SetLocalObject(oSelf, "SEAT_2", oSeat2);
        }

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
