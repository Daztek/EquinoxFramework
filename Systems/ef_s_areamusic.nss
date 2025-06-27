/*
    Script: ef_s_areamusic
    Author: Daz
*/

#include "ef_i_include"
#include "ef_c_log"
#include "ef_c_profiler"
#include "ef_s_musicman"
#include "ef_s_eventman"

const string AREAMUSIC_SCRIPT_NAME                              = "ef_s_areamusic";

const string AREAMUSIC_AREA_TRACKLIST_NAME                      = "AreaTrackList_";
const string AREAMUSIC_TRACKLIST_MUSIC_TRACK                    = "TrackListMusicTrack_";
const string AREAMUSIC_AREA_BATTLE_MUSIC_TRACK                  = "AreaBattleMusicTrack_";

const string AREAMUSIC_AREA_TOOLSET_TRACKLIST_NAME              = "AreaToolsetTrackList_";

const string AREAMUSIC_AREA_MUSIC_EVENT                         = "AreaMusic";
const int AREAMUSIC_AREA_MUSIC_EVENT_PRIORITY                   = 5;
const float AREAMUSIC_UPDATE_TIMER                              = 600.0f;

const int AREAMUSIC_MUSIC_TYPE_DAY                              = 1;
const int AREAMUSIC_MUSIC_TYPE_NIGHT                            = 2;
const int AREAMUSIC_MUSIC_TYPE_BATTLE_DAY                       = 4;
const int AREAMUSIC_MUSIC_TYPE_BATTLE_NIGHT                     = 8;

const int AREAMUSIC_MUSIC_TYPE_DAY_OR_NIGHT                     = 3;
const int AREAMUSIC_MUSIC_TYPE_BATTLE_DAY_OR_NIGHT              = 12;
const int AREAMUSIC_MUSIC_TYPE_ALL                              = 15;

string AreaMusic_GetTrackListsTable();
void AreaMusic_InitializeTrackListsTable();
void AreaMusic_AddTrackToTrackList(string sTrackList, int nTrackId, int nMusicType = AREAMUSIC_MUSIC_TYPE_ALL);
int AreaMusic_GetTrackFromTrackList(string sTrackList, int nMusicType = AREAMUSIC_MUSIC_TYPE_ALL, int nTrackId = 0);
void AreaMusic_SetAreaTrackList(object oArea, string sTrackList);
string AreaMusic_GetAreaTrackList(object oArea, object oDataObject = OBJECT_INVALID);
int AreaMusic_GetAreaHasTrackList(object oArea, object oDataObject = OBJECT_INVALID);
void AreaMusic_SetTrackListMusicTrack(string sTrackList, int nTrackId, int nStartTime);
json AreaMusic_GetTrackListMusicTrack(string sTrackList, object oDataObject = OBJECT_INVALID);
void AreaMusic_SetAreaBattleMusicTrack(object oArea, int nTrackId, int nStartTime);
json AreaMusic_GetAreaBattleMusicTrack(object oArea, object oDataObject = OBJECT_INVALID);
void AreaMusic_DeleteAreaBattleMusicTrack(object oArea);
void AreaMusic_InitializeToolsetTrackLists();
void AreaMusic_UpdateTrackLists();
void AreaMusic_UpdateTrackListsTimer();

// @CORE[EF_SYSTEM_INIT]
void AreaMusic_Init()
{
    AreaMusic_InitializeTrackListsTable();
}

// @CORE[EF_SYSTEM_POST]
void AreaMusic_Post()
{
    AreaMusic_InitializeToolsetTrackLists();
    AreaMusic_UpdateTrackListsTimer();
}

// @MUSICEVENT[AREAMUSIC_AREA_MUSIC_EVENT:AREAMUSIC_AREA_MUSIC_EVENT_PRIORITY:MUSMAN_DEFAULT_FADE_TIME]
json AreaMusic_GetAreaMusicTrack()
{
    object oDataObject = GetDataObject(AREAMUSIC_SCRIPT_NAME);
    object oArea = GetArea(OBJECT_SELF);
    string sTrackList = AreaMusic_GetAreaTrackList(oArea, oDataObject);
    if (sTrackList != "")
    {
        json jTrack = AreaMusic_GetAreaBattleMusicTrack(oArea, oDataObject);
        return !JsonGetType(jTrack) ? AreaMusic_GetTrackListMusicTrack(sTrackList, oDataObject) : jTrack;
    }
    else
        return JsonNull();
}

// @NWNX[NWNX_ON_AREA_PLAY_BATTLE_MUSIC_BEFORE:DL]
void AreaMusic_OnPlayBattleMusic()
{
    object oArea = OBJECT_SELF;

    if (EM_NWNXGetInt("PLAY"))
    {
        int nType = (GetIsDay() || GetIsDawn()) ? AREAMUSIC_MUSIC_TYPE_BATTLE_DAY : AREAMUSIC_MUSIC_TYPE_BATTLE_NIGHT;
        int nTrackId = AreaMusic_GetTrackFromTrackList(AreaMusic_GetAreaTrackList(oArea), nType);

        if (nTrackId)
        {
            AreaMusic_SetAreaBattleMusicTrack(oArea, nTrackId, SqlGetUnixEpoch());
            MusMan_UpdatePlayerMusicByEvent(AREAMUSIC_AREA_MUSIC_EVENT, oArea);
        }
    }
    else
    {
        if (JsonGetType(AreaMusic_GetAreaBattleMusicTrack(oArea)) == JSON_TYPE_OBJECT)
        {
            AreaMusic_DeleteAreaBattleMusicTrack(oArea);
            MusMan_UpdatePlayerMusicByEvent(AREAMUSIC_AREA_MUSIC_EVENT, oArea);
        }
    }
}

// @CONSOLE[UpdateAreaMusicTrackLists::]
void AreaMusic_UpdateTrackListsConsoleCommand()
{
    AreaMusic_UpdateTrackLists();
}

string AreaMusic_GetTrackListsTable()
{
    return AREAMUSIC_SCRIPT_NAME + "_tracklists";
}

void AreaMusic_InitializeTrackListsTable()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + AreaMusic_GetTrackListsTable() + "(" +
                    "tracklist TEXT NOT NULL, " +
                    "trackid INTEGER NOT NULL, " +
                    "type INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

void AreaMusic_AddTrackToTrackList(string sTrackList, int nTrackId, int nMusicType = AREAMUSIC_MUSIC_TYPE_ALL)
{
    string sQuery = "INSERT INTO " + AreaMusic_GetTrackListsTable() + "(tracklist, trackid, type) VALUES(@tracklist, @trackid, @type);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@tracklist", sTrackList);
    SqlBindInt(sql, "@trackid", nTrackId);
    SqlBindInt(sql, "@type", nMusicType);
    SqlStep(sql);
}

int AreaMusic_GetTrackFromTrackList(string sTrackList, int nMusicType = AREAMUSIC_MUSIC_TYPE_ALL, int nTrackId = 0)
{
    if (sTrackList == "")
        return 0;

    string sQuery = "SELECT trackid FROM " + AreaMusic_GetTrackListsTable() +
                    " WHERE tracklist = @tracklist AND trackid != @trackid AND (type & @type) = @type ORDER BY RANDOM() LIMIT 1;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindString(sql, "@tracklist", sTrackList);
    SqlBindInt(sql, "@trackid", nTrackId);
    SqlBindInt(sql, "@type", nMusicType);
    return SqlStep(sql) ? SqlGetInt(sql, 0) : 0;
}

void AreaMusic_SetAreaTrackList(object oArea, string sTrackList)
{
    int bHasTrackList = AreaMusic_GetAreaTrackList(oArea) != "";
    SetLocalString(GetDataObject(AREAMUSIC_SCRIPT_NAME), AREAMUSIC_AREA_TRACKLIST_NAME + ObjectToString(oArea), sTrackList);
    if (!bHasTrackList && sTrackList != "")
        EM_NWNXDispatchListInsert(oArea, AREAMUSIC_SCRIPT_NAME, "NWNX_ON_AREA_PLAY_BATTLE_MUSIC_BEFORE");
    else if (bHasTrackList && sTrackList == "")
        EM_NWNXDispatchListRemove(oArea, AREAMUSIC_SCRIPT_NAME, "NWNX_ON_AREA_PLAY_BATTLE_MUSIC_BEFORE");
}

string AreaMusic_GetAreaTrackList(object oArea, object oDataObject = OBJECT_INVALID)
{
    if (oDataObject == OBJECT_INVALID) oDataObject = GetDataObject(AREAMUSIC_SCRIPT_NAME);
    return GetLocalString(oDataObject, AREAMUSIC_AREA_TRACKLIST_NAME + ObjectToString(oArea));
}

int AreaMusic_GetAreaHasTrackList(object oArea, object oDataObject = OBJECT_INVALID)
{
    return AreaMusic_GetAreaTrackList(oArea, oDataObject) != "";
}

void AreaMusic_SetTrackListMusicTrack(string sTrackList, int nTrackId, int nStartTime)
{
    SetLocalJson(GetDataObject(AREAMUSIC_SCRIPT_NAME), AREAMUSIC_TRACKLIST_MUSIC_TRACK + sTrackList, MusMan_JsonTrack(nTrackId, nStartTime));
}

json AreaMusic_GetTrackListMusicTrack(string sTrackList, object oDataObject = OBJECT_INVALID)
{
    if (oDataObject == OBJECT_INVALID) oDataObject = GetDataObject(AREAMUSIC_SCRIPT_NAME);
    return GetLocalJson(oDataObject, AREAMUSIC_TRACKLIST_MUSIC_TRACK + sTrackList);
}

void AreaMusic_SetAreaBattleMusicTrack(object oArea, int nTrackId, int nStartTime)
{
    SetLocalJson(GetDataObject(AREAMUSIC_SCRIPT_NAME), AREAMUSIC_AREA_BATTLE_MUSIC_TRACK + ObjectToString(oArea), MusMan_JsonTrack(nTrackId, nStartTime, TRUE));
}

json AreaMusic_GetAreaBattleMusicTrack(object oArea, object oDataObject = OBJECT_INVALID)
{
    if (oDataObject == OBJECT_INVALID) oDataObject = GetDataObject(AREAMUSIC_SCRIPT_NAME);
    return GetLocalJson(oDataObject, AREAMUSIC_AREA_BATTLE_MUSIC_TRACK + ObjectToString(oArea));
}

void AreaMusic_DeleteAreaBattleMusicTrack(object oArea)
{
    DeleteLocalJson(GetDataObject(AREAMUSIC_SCRIPT_NAME), AREAMUSIC_AREA_BATTLE_MUSIC_TRACK + ObjectToString(oArea));
}

void AreaMusic_InitializeToolsetTrackLists()
{
    object oDataObject = GetDataObject(AREAMUSIC_SCRIPT_NAME);
    object oArea = GetFirstArea();
    while (oArea != OBJECT_INVALID)
    {
        if (!AreaMusic_GetAreaHasTrackList(oArea, oDataObject))
        {
            int nTrackCount = 0;
            string sTrackList = AREAMUSIC_AREA_TOOLSET_TRACKLIST_NAME + ObjectToString(oArea);

            int nDayMusicTrack = MusicBackgroundGetDayTrack(oArea);
            int nNightMusicTrack = MusicBackgroundGetNightTrack(oArea);
            if ((nDayMusicTrack && nNightMusicTrack) && (nDayMusicTrack == nNightMusicTrack))
            {
                AreaMusic_AddTrackToTrackList(sTrackList, nDayMusicTrack, AREAMUSIC_MUSIC_TYPE_DAY_OR_NIGHT);
                MusicBackgroundChangeDay(oArea, 0);
                MusicBackgroundChangeNight(oArea, 0);
                nTrackCount++;
            }
            else
            {
                if (nDayMusicTrack)
                {
                    AreaMusic_AddTrackToTrackList(sTrackList, nDayMusicTrack, AREAMUSIC_MUSIC_TYPE_DAY);
                    MusicBackgroundChangeDay(oArea, 0);
                    nTrackCount++;
                }

                int nNightMusicTrack = MusicBackgroundGetNightTrack(oArea);
                if (nNightMusicTrack)
                {
                    AreaMusic_AddTrackToTrackList(sTrackList, nNightMusicTrack, AREAMUSIC_MUSIC_TYPE_NIGHT);
                    MusicBackgroundChangeNight(oArea, 0);
                    nTrackCount++;
                }
            }

            int nBattleMusicTrack = MusicBackgroundGetBattleTrack(oArea);
            if (nBattleMusicTrack)
            {
                AreaMusic_AddTrackToTrackList(sTrackList, nBattleMusicTrack, AREAMUSIC_MUSIC_TYPE_BATTLE_DAY_OR_NIGHT);
                MusicBattleChange(oArea, 0);
                nTrackCount++;
            }

            if (nTrackCount)
                AreaMusic_SetAreaTrackList(oArea, sTrackList);
        }

        oArea = GetNextArea();
    }
}

void AreaMusic_UpdateTrackLists()
{
    object oDataObject = GetDataObject(AREAMUSIC_SCRIPT_NAME);
    int nMusicType = (GetIsDay() || GetIsDawn()) ? AREAMUSIC_MUSIC_TYPE_DAY : AREAMUSIC_MUSIC_TYPE_NIGHT;
    int nUnixEpoch = SqlGetUnixEpoch();
    sqlquery sql = SqlPrepareQueryModule("SELECT DISTINCT tracklist FROM " + AreaMusic_GetTrackListsTable() + ";");
    while (SqlStep(sql))
    {
        string sTrackList = SqlGetString(sql, 0);
        int nTrackId = AreaMusic_GetTrackFromTrackList(sTrackList, nMusicType, JsonObjectGetInt(AreaMusic_GetTrackListMusicTrack(sTrackList, oDataObject), "trackid"));

        if (nTrackId > 0)
            AreaMusic_SetTrackListMusicTrack(sTrackList, nTrackId, nUnixEpoch);
    }

    MusMan_UpdatePlayerMusicByEvent(AREAMUSIC_AREA_MUSIC_EVENT);
}

void AreaMusic_UpdateTrackListsTimer()
{
    AreaMusic_UpdateTrackLists();
    DelayCommand(AREAMUSIC_UPDATE_TIMER, AreaMusic_UpdateTrackListsTimer());
}
