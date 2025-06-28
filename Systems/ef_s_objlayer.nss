/*
    Script: ef_s_objlayer
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "nwnx_objectlayer"

// @CORE[CORE_SYSTEM_INIT]
void ObjLayer_Init()
{
    return;
    int nNth = 0;
    object oObject;
    while ((oObject = GetObjectByTag("LAYER_1", nNth++)) != OBJECT_INVALID)
    {
       NWNX_ObjectLayer_SetObjectLayer(GetArea(oObject), oObject, 1, TRUE);
       NWNX_ObjectLayer_SetLayerVisible(GetArea(oObject), oObject, 0, FALSE);
    }
    nNth = 0;
    while ((oObject = GetObjectByTag("LAYER_2", nNth++)) != OBJECT_INVALID)
    {
       NWNX_ObjectLayer_SetObjectLayer(GetArea(oObject), oObject, 2, TRUE);
       NWNX_ObjectLayer_SetLayerVisible(GetArea(oObject), oObject, 0, FALSE);
    }
}

// @CONSOLE[SetObjectLayer::]
void ObjLayer_SetObjectLayer(int nLayer, int bModifyVisibleLayer = 1)
{
    object oObject = OBJECT_SELF;
    object oArea = GetArea(oObject);
    NWNX_ObjectLayer_SetObjectLayer(oArea, oObject, nLayer, bModifyVisibleLayer);
}

// @CONSOLE[SetLayerVisible::]
void ObjLayer_SetLayerVisible(int nLayer, int bVisible = 1)
{
    object oObject = OBJECT_SELF;
    object oArea = GetArea(oObject);
    NWNX_ObjectLayer_SetLayerVisible(oArea, oObject, nLayer, bVisible);
}
