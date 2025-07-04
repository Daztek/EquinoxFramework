/*
    Script: ef_s_musicman
    Author: Daz

    @MUSICEVENT[Event:Priority:FadeTime]
*/

#include "ef_i_include"
#include "ef_c_annotations"
#include "ef_c_log"
#include "ef_c_profiler"
#include "ef_s_session"

const string MUSMAN_SCRIPT_NAME                         = "ef_s_musicman";
const string MUSMAN_AMBIENT_MUSIC_2DA                   = "ambientmusic";
const string MUSMAN_PLAYER_VOLUME_MODIFIER              = "PlayerVolumeModifier";
const string MUSMAN_CHANNEL_FADING                      = "ChannelFading_";
const float MUSMAN_DEFAULT_FADE_TIME                    = 2.0f;
const int MUSMAN_NUM_MUSIC_CHANNELS                     = 3;
const int MUSMAN_STINGER_CHANNEL                        = MUSMAN_NUM_MUSIC_CHANNELS;

struct MusMan_AmbientMusic
{
    int nTrackId;
    string sName;
    string sResource;
    string sStinger1;
    string sStinger2;
    string sStinger3;
    int nLength;
};

struct MusMan_MusicEvent
{
    string sEvent;
    string sSystem;
    int nPriority;
    float fFadeTime;
    int nCurrentTime;
    json jTrack;
};

struct MusMan_MusicEventTrack
{
    int nTrackId;
    string sName;
    string sResource;
    string sStinger1;
    string sStinger2;
    string sStinger3;
    int nLength;
    int nStartTime;
    int bLooping;
    float fVolume;
    int bPlayStinger;
};

struct MusMan_PlayerData
{
    object oPlayer;
    object oArea;
    string sEvent;
    int nTrackId;
    string sStinger;
    int nChannel;
    float fVolume;
    float fFadeTime;
};

string MusMan_GetAmbientMusic2DATable();
void MusMan_LoadAmbientMusic2DA();
struct MusMan_AmbientMusic MusMan_GetAmbientMusicData(int nTrackId);
string MusMan_GetMusicEventsTable();
void MusMan_InitializeMusicEventsTable();
struct MusMan_MusicEventTrack MusMan_GetMusicEventTrackData(json jTrack);
struct MusMan_MusicEvent MusMan_GetMusicEvent(object oPlayer);
json MusMan_JsonTrack(int nTrackId, int nStartTime = 0, int bPlayStinger = FALSE, int bLooping = TRUE, float fVolume = 1.0f);
float MusMan_GetSeekOffset(int nCurrentTime, int nStartTime, int nLength);
string MusMan_GetPlayerDataTable();
void MusMan_InitializePlayerDataTable();
void MusMan_UpdatePlayerData(object oPlayer, string sEvent, int nTrackId, string sStinger, int nChannel, float fVolume, float fFadeTime);
struct MusMan_PlayerData MusMan_GetPlayerData(object oPlayer);
void MusMan_DeletePlayerData(object oPlayer);
void MusMan_SetPlayerVolumeModifier(object oPlayer, float fVolume);
float MusMan_GetPlayerVolumeModifier(object oPlayer);
void MusMan_DeletePlayerVolumeModifier(object oPlayer);
void MusMan_StartChannel(object oPlayer, int nChannel, string sResRef, int bLooping = FALSE, float fFadeTime = 0.0f, float fSeekOffset = -1.0f, float fVolume = 1.0f);
void MusMan_StopChannel(object oPlayer, int nChannel, float fFadeTime = 0.0f);
void MusMan_StopOtherChannels(object oPlayer, int nCurrentChannel, int nNextChannel);
void MusMan_SetChannelVolume(object oPlayer, int nChannel, float fVolume, float fFadeTime = 0.0f);
void MusMan_SetCurrentChannelVolume(object oPlayer, float fVolume, float fFadeTime = 0.0f);
void MusMan_RefreshCurrentChannelVolume(object oPlayer, float fFadeTime = 0.0f);
void MusMan_UpdatePlayerMusic(object oPlayer);
void MusMan_UpdatePlayerMusicByEvent(string sEvent, object oArea = OBJECT_INVALID);

// @CORE[CORE_SYSTEM_INIT]
void MusMan_Init()
{
    MusMan_LoadAmbientMusic2DA();
    MusMan_InitializeMusicEventsTable();
    MusMan_InitializePlayerDataTable();
}

// @PAD[MUSICEVENT]
void MusMan_RegisterMusicEvent(struct AnnotationData str)
{
    if (str.sReturnType != NSS_RETURN_TYPE_JSON)
    {
        LogError("Music event track function '" + str.sSystem + ":" + str.sFunction + "' has non-json return value!");
        return;
    }

    string sEvent = GetAnnotationString(str, 0);
    int nPriority = GetAnnotationInt(str, 1);
    float fFadeTime = GetAnnotationFloat(str, 2);
    sqlquery sql = SqlPrepareQueryModule("INSERT INTO " + MusMan_GetMusicEventsTable() + "(event, system, priority, fadetime, track_function) " +
                                         "VALUES(@event, @system, @priority, @fadetime, @track_function);");
    SqlBindString(sql, "@event", sEvent);
    SqlBindString(sql, "@system", str.sSystem);
    SqlBindInt(sql, "@priority", nPriority);
    SqlBindFloat(sql, "@fadetime", fFadeTime);
    SqlBindString(sql, "@track_function", nssFunction(str.sFunction));
    SqlStep(sql);

    LogInfo("System '" + str.sSystem + "' registered music event '" + sEvent + "' with priority '" +
            IntToString(nPriority) + "' and fadetime '" + FloatToString(fFadeTime, 0, 2) + "'");
}

// @GUIEVENT[GUIEVENT_AREA_LOADSCREEN_FINISHED]
void MusMan_AreaLoadScreenFinished()
{
    MusMan_UpdatePlayerMusic(GetLastGuiEventPlayer());
}

// @EVENT[EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT::]
void MusMan_OnClientExit()
{
    MusMan_DeletePlayerData(GetExitingObject());
}

string MusMan_GetAmbientMusic2DATable()
{
    return MUSMAN_SCRIPT_NAME + "_ambientmusic2da";
}

void MusMan_LoadAmbientMusic2DA()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + MusMan_GetAmbientMusic2DATable() + "(" +
                    "trackid INTEGER NOT NULL PRIMARY KEY, " +
                    "name TEXT NOT NULL, " +
                    "resource TEXT NOT NULL, " +
                    "stinger1 TEXT NOT NULL, " +
                    "stinger2 TEXT NOT NULL, " +
                    "stinger3 TEXT NOT NULL, " +
                    "duration INTEGER NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));

    SqlBeginTransactionModule();

    sQuery = "INSERT INTO " + MusMan_GetAmbientMusic2DATable() + "(trackid, name, resource, stinger1, stinger2, stinger3, duration) " +
             "VALUES(@trackid, @name, @resource, @stinger1, @stinger2, @stinger3, @duration);";
    sqlquery sql = SqlPrepareQueryModule(sQuery);

    int nRow, nNumRows = Get2DARowCount(MUSMAN_AMBIENT_MUSIC_2DA);
    for (nRow = 0; nRow < nNumRows; nRow++)
    {
        string sTrack = Get2DAString(MUSMAN_AMBIENT_MUSIC_2DA, "Resource", nRow);

        if (sTrack != "")
        {
            int nNameStrRef = Get2DAInt(MUSMAN_AMBIENT_MUSIC_2DA, "Description", nRow);
            string sName = nNameStrRef == EF_UNSET_INTEGER_VALUE ? Get2DAString(MUSMAN_AMBIENT_MUSIC_2DA, "DisplayName", nRow) : GetStringByStrRef(nNameStrRef);
            int nDuration = Get2DAInt(MUSMAN_AMBIENT_MUSIC_2DA, "Duration", nRow);

            SqlBindInt(sql, "@trackid", nRow);
            SqlBindString(sql, "@name", sName);
            SqlBindString(sql, "@resource", sTrack);
            SqlBindString(sql, "@stinger1", Get2DAString(MUSMAN_AMBIENT_MUSIC_2DA, "Stinger1", nRow));
            SqlBindString(sql, "@stinger2", Get2DAString(MUSMAN_AMBIENT_MUSIC_2DA, "Stinger2", nRow));
            SqlBindString(sql, "@stinger3", Get2DAString(MUSMAN_AMBIENT_MUSIC_2DA, "Stinger3", nRow));
            SqlBindInt(sql, "@duration", nDuration == EF_UNSET_INTEGER_VALUE ? 0 : nDuration);
            SqlStepAndReset(sql);
        }
    }

    SqlCommitTransactionModule();
}

struct MusMan_AmbientMusic MusMan_GetAmbientMusicData(int nTrackId)
{
    struct MusMan_AmbientMusic strAmbientMusic;
    sqlquery sql = SqlPrepareQueryModule("SELECT name, resource, stinger1, stinger2, stinger3, duration FROM " + MusMan_GetAmbientMusic2DATable() + " WHERE trackid = @trackid;");
    SqlBindInt(sql, "@trackid", nTrackId);

    if (SqlStep(sql))
    {
        int nIndex;
        strAmbientMusic.nTrackId = nTrackId;
        strAmbientMusic.sName = SqlGetString(sql, nIndex++);
        strAmbientMusic.sResource = SqlGetString(sql, nIndex++);
        strAmbientMusic.sStinger1 = SqlGetString(sql, nIndex++);
        strAmbientMusic.sStinger2 = SqlGetString(sql, nIndex++);
        strAmbientMusic.sStinger3 = SqlGetString(sql, nIndex++);
        strAmbientMusic.nLength = SqlGetInt(sql, nIndex++);
    }

    return strAmbientMusic;
}

string MusMan_GetMusicEventsTable()
{
    return MUSMAN_SCRIPT_NAME + "_musicevents";
}

void MusMan_InitializeMusicEventsTable()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + MusMan_GetMusicEventsTable() + "(" +
                    "event TEXT NOT NULL, " +
                    "system TEXT NOT NULL, " +
                    "priority INTEGER NOT NULL, " +
                    "fadetime REAL NOT NULL, " +
                    "track_function TEXT NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

struct MusMan_MusicEvent MusMan_GetMusicEvent(object oPlayer)
{
    struct MusMan_MusicEvent strMusicEvent;
    sqlquery sql = SqlPrepareQueryModule("SELECT track_function, system, event, priority, fadetime, UNIXEPOCH() FROM " + MusMan_GetMusicEventsTable() + " ORDER BY priority DESC;");
    while (SqlStep(sql))
    {
        int nIndex;
        string sTrackFunction = SqlGetString(sql, nIndex++);
        string sSystem = SqlGetString(sql, nIndex++);
        json jTrack = ExecuteScriptChunkAndReturnJson(sSystem, sTrackFunction, oPlayer);

        if (JsonGetType(jTrack) == JSON_TYPE_OBJECT)
        {
            strMusicEvent.sEvent = SqlGetString(sql, nIndex++);
            strMusicEvent.sSystem = sSystem;
            strMusicEvent.nPriority = SqlGetInt(sql, nIndex++);
            strMusicEvent.fFadeTime = SqlGetFloat(sql, nIndex++);
            strMusicEvent.nCurrentTime = SqlGetInt(sql, nIndex++);
            strMusicEvent.jTrack = jTrack;
            return strMusicEvent;
        }
    }

    return strMusicEvent;
}

struct MusMan_MusicEventTrack MusMan_GetMusicEventTrackData(json jTrack)
{
    struct MusMan_MusicEventTrack strTrack;
    strTrack.nTrackId = JsonObjectGetInt(jTrack, "trackid");
    strTrack.nStartTime = JsonObjectGetInt(jTrack, "starttime");
    strTrack.bPlayStinger = JsonObjectGetInt(jTrack, "playstinger");
    strTrack.bLooping = JsonObjectGetInt(jTrack, "looping");
    strTrack.fVolume = JsonObjectGetFloat(jTrack, "volume");
    struct MusMan_AmbientMusic strAmbientMusic = MusMan_GetAmbientMusicData(strTrack.nTrackId);
    strTrack.sName = strAmbientMusic.sName;
    strTrack.sResource = strAmbientMusic.sResource;
    strTrack.sStinger1 = strTrack.bPlayStinger ? strAmbientMusic.sStinger1 : "";
    strTrack.nLength = strAmbientMusic.nLength;

    return strTrack;
}

json MusMan_JsonTrack(int nTrackId, int nStartTime = 0, int bPlayStinger = FALSE, int bLooping = TRUE, float fVolume = 1.0f)
{
    json jTrack = JsonObject();
         JsonObjectSetIntInplace(jTrack, "trackid", nTrackId);
         JsonObjectSetIntInplace(jTrack, "starttime", nStartTime);
         JsonObjectSetIntInplace(jTrack, "playstinger", bPlayStinger);
         JsonObjectSetIntInplace(jTrack, "looping", bLooping);
         JsonObjectSetFloatInplace(jTrack, "volume", fVolume);
    return jTrack;
}

float MusMan_GetSeekOffset(int nCurrentTime, int nStartTime, int nLength)
{
    return !nStartTime ? -1.0f : IntToFloat((nCurrentTime - nStartTime) % nLength);
}

string MusMan_GetPlayerDataTable()
{
    return MUSMAN_SCRIPT_NAME + "_playerdata";
}

void MusMan_InitializePlayerDataTable()
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + MusMan_GetPlayerDataTable() + "(" +
                    "oidplayer INTEGER NOT NULL PRIMARY KEY, " +
                    "oidarea INTEGER NOT NULL, " +
                    "event TEXT NOT NULL, " +
                    "trackid INTEGER NOT NULL, " +
                    "stinger TEXT NOT NULL, " +
                    "channel INTEGER NOT NULL, " +
                    "volume REAL NOT NULL, " +
                    "fadetime REAL NOT NULL);";
    SqlStep(SqlPrepareQueryModule(sQuery));
}

void MusMan_UpdatePlayerData(object oPlayer, string sEvent, int nTrackId, string sStinger, int nChannel, float fVolume, float fFadeTime)
{
    string sQuery = "INSERT INTO " + MusMan_GetPlayerDataTable() + "(oidplayer, oidarea, event, trackid, stinger, channel, volume, fadetime) " +
                    "VALUES(@oidplayer, @oidarea, @event, @trackid, @stinger, @channel, @volume, @fadetime) " +
                    "ON CONFLICT (oidplayer) DO UPDATE SET oidarea = @oidarea, event = @event, trackid = @trackid, stinger = @stinger, " +
                    "channel = @channel, volume = @volume, fadetime = @fadetime;";
    sqlquery sql = SqlPrepareQueryModule(sQuery);
    SqlBindObjectRef(sql, "@oidplayer", oPlayer);
    SqlBindObjectRef(sql, "@oidarea", GetArea(oPlayer));
    SqlBindString(sql, "@event", sEvent);
    SqlBindInt(sql, "@trackid", nTrackId);
    SqlBindString(sql, "@stinger", sStinger);
    SqlBindInt(sql, "@channel", nChannel);
    SqlBindFloat(sql, "@volume", fVolume);
    SqlBindFloat(sql, "@fadetime", fFadeTime);
    SqlStep(sql);
}

struct MusMan_PlayerData MusMan_GetPlayerData(object oPlayer)
{
    struct MusMan_PlayerData strPlayerData;
    strPlayerData.oPlayer = oPlayer;
    sqlquery sql = SqlPrepareQueryModule("SELECT oidarea, event, trackid, stinger, channel, volume, fadetime FROM " + MusMan_GetPlayerDataTable() + " WHERE oidplayer = @oidplayer;");
    SqlBindObjectRef(sql, "@oidplayer", oPlayer);
    if (SqlStep(sql))
    {
        int nIndex;
        strPlayerData.oArea = SqlGetObjectRef(sql, nIndex++);
        strPlayerData.sEvent = SqlGetString(sql, nIndex++);
        strPlayerData.nTrackId = SqlGetInt(sql, nIndex++);
        strPlayerData.sStinger = SqlGetString(sql, nIndex++);
        strPlayerData.nChannel = SqlGetInt(sql, nIndex++);
        strPlayerData.fVolume = SqlGetFloat(sql, nIndex++);
        strPlayerData.fFadeTime = SqlGetFloat(sql, nIndex++);
    }
    return strPlayerData;
}

void MusMan_DeletePlayerData(object oPlayer)
{
    sqlquery sql = SqlPrepareQueryModule("DELETE FROM " + MusMan_GetPlayerDataTable() + " WHERE oidplayer = @oidplayer;");
    SqlBindObjectRef(sql, "@oidplayer", oPlayer);
    SqlStep(sql);
}

void MusMan_SetPlayerVolumeModifier(object oPlayer, float fVolume)
{
    Session_SetJson(oPlayer, MUSMAN_SCRIPT_NAME, MUSMAN_PLAYER_VOLUME_MODIFIER, JsonFloat(clampf(fVolume, 0.0f, 1.0f)));
}

float MusMan_GetPlayerVolumeModifier(object oPlayer)
{
    json jVolume = Session_GetJson(oPlayer, MUSMAN_SCRIPT_NAME, MUSMAN_PLAYER_VOLUME_MODIFIER);
    return !JsonGetType(jVolume) ? 1.0f : JsonGetFloat(jVolume);
}

void MusMan_DeletePlayerVolumeModifier(object oPlayer)
{
    Session_DeleteJson(oPlayer, MUSMAN_SCRIPT_NAME, MUSMAN_PLAYER_VOLUME_MODIFIER);
}

void MusMan_StartChannel(object oPlayer, int nChannel, string sResRef, int bLooping = FALSE, float fFadeTime = 0.0f, float fSeekOffset = -1.0f, float fVolume = 1.0f)
{
    if (fFadeTime > 0.0f)
    {
        object oSDO = Session_GetDataObject(oPlayer);
        string sVarName = MUSMAN_CHANNEL_FADING + IntToString(nChannel);
        Session_SetInt(oPlayer, MUSMAN_SCRIPT_NAME, sVarName, TRUE, oSDO);
        DelayCommand(fFadeTime, Session_DeleteInt(oPlayer, MUSMAN_SCRIPT_NAME, sVarName, oSDO));
    }

    StartAudioStream(oPlayer, nChannel, sResRef, bLooping, fFadeTime, fSeekOffset, fVolume);
}

void MusMan_StopChannel(object oPlayer, int nChannel, float fFadeTime = 0.0f)
{
    if (fFadeTime > 0.0f)
    {
        object oSDO = Session_GetDataObject(oPlayer);
        string sVarName = MUSMAN_CHANNEL_FADING + IntToString(nChannel);
        if (Session_GetInt(oPlayer, MUSMAN_SCRIPT_NAME, sVarName, oSDO))
        {
            fFadeTime = 0.0f;
            Session_DeleteInt(oPlayer, MUSMAN_SCRIPT_NAME, sVarName, oSDO);
        }
    }

    StopAudioStream(oPlayer, nChannel, fFadeTime);
}

void MusMan_StopOtherChannels(object oPlayer, int nCurrentChannel, int nNextChannel)
{
    int nChannel;
    for (nChannel = 0; nChannel < MUSMAN_NUM_MUSIC_CHANNELS; nChannel++)
    {
        if (nChannel != nCurrentChannel && nChannel != nNextChannel)
            MusMan_StopChannel(oPlayer, nChannel);
    }
}

void MusMan_SetChannelVolume(object oPlayer, int nChannel, float fVolume, float fFadeTime = 0.0f)
{
    SetAudioStreamVolume(oPlayer, nChannel, clampf(MusMan_GetPlayerVolumeModifier(oPlayer) * fVolume, 0.0f, 1.0f), fFadeTime);
}

void MusMan_SetCurrentChannelVolume(object oPlayer, float fVolume, float fFadeTime = 0.0f)
{
    MusMan_SetChannelVolume(oPlayer, MusMan_GetPlayerData(oPlayer).nChannel, fVolume, fFadeTime);
}

void MusMan_RefreshCurrentChannelVolume(object oPlayer, float fFadeTime = 0.0f)
{
    struct MusMan_PlayerData strPlayerData = MusMan_GetPlayerData(oPlayer);
    MusMan_SetChannelVolume(oPlayer, strPlayerData.nChannel, strPlayerData.fVolume, fFadeTime);
}

void MusMan_UpdatePlayerMusic(object oPlayer)
{
    struct MusMan_PlayerData strPlayerData = MusMan_GetPlayerData(oPlayer);
    struct MusMan_MusicEvent strMusicEvent = MusMan_GetMusicEvent(oPlayer);

    if (strPlayerData.sEvent != strMusicEvent.sEvent || strPlayerData.nTrackId != JsonObjectGetInt(strMusicEvent.jTrack, "trackid"))
    {
        struct MusMan_MusicEventTrack strMusicEventTrack = MusMan_GetMusicEventTrackData(strMusicEvent.jTrack);
        int nCurrentChannel = strPlayerData.nChannel;
        int nNextChannel = (nCurrentChannel + 1) % MUSMAN_NUM_MUSIC_CHANNELS;
        float fVolume = clampf(MusMan_GetPlayerVolumeModifier(oPlayer) * strMusicEventTrack.fVolume, 0.0f, 1.0f);

        MusMan_StopOtherChannels(oPlayer, nCurrentChannel, nNextChannel);

        if (strPlayerData.nTrackId)
            MusMan_StopChannel(oPlayer, nCurrentChannel, strPlayerData.fFadeTime);

        if (strPlayerData.sStinger != "")
            MusMan_StartChannel(oPlayer, MUSMAN_STINGER_CHANNEL, strPlayerData.sStinger, FALSE, 0.0f, -1.0f, fVolume);

        if (strMusicEventTrack.nTrackId)
        {
            float fSeekOffset = MusMan_GetSeekOffset(strMusicEvent.nCurrentTime, strMusicEventTrack.nStartTime, strMusicEventTrack.nLength);
            MusMan_StartChannel(oPlayer, nNextChannel, strMusicEventTrack.sResource, strMusicEventTrack.bLooping, strMusicEvent.fFadeTime, fSeekOffset, fVolume);
        }

        MusMan_UpdatePlayerData(oPlayer, strMusicEvent.sEvent, strMusicEventTrack.nTrackId, strMusicEventTrack.sStinger1, nNextChannel, strMusicEventTrack.fVolume, strMusicEvent.fFadeTime);
    }
}

void MusMan_UpdatePlayerMusicByEvent(string sEvent, object oArea = OBJECT_INVALID)
{
    sqlquery sql;
    if (GetIsObjectValid(oArea))
    {
        sql = SqlPrepareQueryModule("SELECT oidplayer FROM " + MusMan_GetPlayerDataTable() + " WHERE event = @event AND oidarea = @oidarea;");
        SqlBindString(sql, "@event", sEvent);
        SqlBindObjectRef(sql, "@oidarea", oArea);
    }
    else
    {
        sql = SqlPrepareQueryModule("SELECT oidplayer FROM " + MusMan_GetPlayerDataTable() + " WHERE event = @event;");
        SqlBindString(sql, "@event", sEvent);
    }

    while (SqlStep(sql))
    {
        object oPlayer = SqlGetObjectRef(sql, 0);
        if (GetIsObjectValid(oPlayer))
            DelayCommand((Random(10) + 1) * 0.01f, MusMan_UpdatePlayerMusic(oPlayer));
    }
}
