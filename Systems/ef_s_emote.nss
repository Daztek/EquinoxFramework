/*
    Script: ef_s_emote
    Author: Daz

    Description: A system that adds a PlayerMenu button that allows players to emote.
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_s_nuibuilder"
#include "ef_s_nuiwinman"

const string EMOTE_SCRIPT_NAME          = "ef_s_emote";

const string EMOTE_WINDOW_ID            = "EMOTES";
const string EMOTE_BIND_EMOTE_BUTTON    = "btn_emote";

const string EMOTE_NAME_ARRAY           = "EmoteName";
const string EMOTE_ID_ARRAY             = "EmoteId";
const float EMOTE_DURATION_LOOPING      = 3600.0f;

void Emote_AddEmote(string sEmoteName, int nEmoteId)
{
    object oDataObject = GetDataObject(EMOTE_SCRIPT_NAME);
    InsertStringToLocalJsonArray(oDataObject, EMOTE_NAME_ARRAY, sEmoteName);
    InsertIntToLocalJsonArray(oDataObject, EMOTE_ID_ARRAY, nEmoteId);
}

// @CORE[EF_SYSTEM_INIT]
void Emote_Init()
{
    Emote_AddEmote("Bow", ANIMATION_FIREFORGET_BOW);
    Emote_AddEmote("Duck", ANIMATION_FIREFORGET_DODGE_DUCK);
    Emote_AddEmote("Dodge", ANIMATION_FIREFORGET_DODGE_SIDE);
    Emote_AddEmote("Drink", ANIMATION_FIREFORGET_DRINK);
    Emote_AddEmote("Greet", ANIMATION_FIREFORGET_GREETING);
    Emote_AddEmote("Bored", ANIMATION_FIREFORGET_PAUSE_BORED);
    Emote_AddEmote("Scratch", ANIMATION_FIREFORGET_PAUSE_SCRATCH_HEAD);
    Emote_AddEmote("Read", ANIMATION_FIREFORGET_READ);
    Emote_AddEmote("Salute", ANIMATION_FIREFORGET_SALUTE);
    Emote_AddEmote("Steal", ANIMATION_FIREFORGET_STEAL);
    Emote_AddEmote("Taunt", ANIMATION_FIREFORGET_TAUNT);
    Emote_AddEmote("Victory - 1", ANIMATION_FIREFORGET_VICTORY1);
    Emote_AddEmote("Victory - 2", ANIMATION_FIREFORGET_VICTORY2);
    Emote_AddEmote("Victory - 3", ANIMATION_FIREFORGET_VICTORY3);
    Emote_AddEmote("Conjure - 1", ANIMATION_LOOPING_CONJURE1);
    Emote_AddEmote("Conjure - 2", ANIMATION_LOOPING_CONJURE2);
    Emote_AddEmote("Dead Back", ANIMATION_LOOPING_DEAD_BACK);
    Emote_AddEmote("Dead Front", ANIMATION_LOOPING_DEAD_FRONT);
    Emote_AddEmote("Get Low", ANIMATION_LOOPING_GET_LOW);
    Emote_AddEmote("Get Mid", ANIMATION_LOOPING_GET_MID);
    Emote_AddEmote("Meditate", ANIMATION_LOOPING_MEDITATE);
    Emote_AddEmote("Drunk", ANIMATION_LOOPING_PAUSE_DRUNK);
    Emote_AddEmote("Tired", ANIMATION_LOOPING_PAUSE_TIRED);
    Emote_AddEmote("Sit", ANIMATION_LOOPING_SIT_CROSS);
    Emote_AddEmote("Spasm", ANIMATION_LOOPING_SPASM);
    Emote_AddEmote("Talk - Forceful", ANIMATION_LOOPING_TALK_FORCEFUL);
    Emote_AddEmote("Talk - Laughing", ANIMATION_LOOPING_TALK_LAUGHING);
    Emote_AddEmote("Talk - Normal", ANIMATION_LOOPING_TALK_NORMAL);
    Emote_AddEmote("Talk - Pleading", ANIMATION_LOOPING_TALK_PLEADING);
    Emote_AddEmote("Worship", ANIMATION_LOOPING_WORSHIP);
}

// @NWMWINDOW[EMOTE_WINDOW_ID]
json Emote_CreateWindow()
{
    NB_InitializeWindow(NuiRect(-1.0f, -1.0f, 200.0f, 400.0f));
    NB_SetWindowTitle(JsonString("Emote Menu"));
     NB_StartColumn();
      NB_StartRow();
       NB_StartList(NuiBind("buttons"), 24.0f, TRUE);
        NB_StartListTemplateCell(140.0f, FALSE);
         NB_StartElement(NuiButton(NuiBind("buttons")));
          NB_SetId(EMOTE_BIND_EMOTE_BUTTON);
          NB_SetDimensions(140.0f, 24.0f);
         NB_End();
        NB_End();
       NB_End();
      NB_End();
     NB_End();
    return NB_FinalizeWindow();
}

// @NWMEVENT[EMOTE_WINDOW_ID:NUI_EVENT_CLICK:EMOTE_BIND_EMOTE_BUTTON]
void Emote_ClickEmoteButton()
{
    object oPlayer = OBJECT_SELF;
    int nEmote = GetIntFromLocalJsonArray(GetDataObject(EMOTE_SCRIPT_NAME), EMOTE_ID_ARRAY, NuiGetEventArrayIndex());

    if (nEmote)
    {
        ClearAllActions();
        ActionPlayAnimation(nEmote, 1.0, EMOTE_DURATION_LOOPING);
    }
}

// @PMBUTTON[Emote Menu:Perform an emote]
void Emote_ToggleWindow()
{
    object oPlayer = OBJECT_SELF;
    if (NWM_ToggleWindow(oPlayer, EMOTE_WINDOW_ID))
        NWM_SetBind("buttons", GetLocalJsonArray(GetDataObject(EMOTE_SCRIPT_NAME), EMOTE_NAME_ARRAY));
}
