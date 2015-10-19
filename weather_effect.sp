#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <soundlib>

#define PLUGIN_VERSION	"1.3"

#define SOUNDLIB_AVAILABLE()		(GetFeatureStatus(FeatureType_Native, "OpenSoundFile") == FeatureStatus_Available)

new bool:b_late;

new String:g_szMapname[33], String:g_szMappath[64], String:g_szMapPrefix[12];

new Handle:g_hWeatherType, i_weathertype,
	Handle:g_hDensity, i_density,
	Handle:g_hLightstyle, String:s_lightstyle[32],
	Handle:g_hSkybox, String:s_skybox[32],
	Handle:g_hSoundEffect, String:s_soundeffect[PLATFORM_MAX_PATH],
	Handle:g_hSoundVolume, Float:f_soundvolume;

new Handle:soundtimer;

new i_entity;

public Plugin:myinfo = 
{
	name = "Weather effect",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Adds weather effect with a background sound",
	version = PLUGIN_VERSION,
	url = "www.hlmod.ru"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("OpenSoundFile");
	MarkNativeAsOptional("GetSoundLength");
	b_late = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_weathereffect_version", PLUGIN_VERSION, "The plugin's version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	g_hWeatherType = CreateConVar("sm_weathereffect_type", "-1.0", "Which weather effect to add. -1-Disable|0-Rain|1-Snow|2-Ash|3-Snowfall|4-Particle Rain|5-Particle Ash|6-Particle Rain Storm", FCVAR_PLUGIN, true, -1.0, true, 6.0);
	g_hDensity = CreateConVar("sm_weathereffect_density", "75.0", "The level of density", FCVAR_PLUGIN, true, 10.0, true, 100.0);
	g_hLightstyle = CreateConVar("sm_weathereffect_lightstyle", "", "Sets a lightstyle. Leave empty to disable. m-normal|a-the most darkness|z-the most brightness", FCVAR_PLUGIN);
	g_hSkybox = CreateConVar("sm_weathereffect_skybox", "", "Sets a skybox relative to the materials/skybox folder. Leave it empty to disable", FCVAR_PLUGIN);
	g_hSoundEffect = CreateConVar("sm_weathereffect_sound", "", "Path to the background sound. Leave it empty to disable", FCVAR_PLUGIN);
	g_hSoundVolume = CreateConVar("sm_weathereffect_volume", "0.8", "Changes the sound volume", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	i_weathertype = GetConVarInt(g_hWeatherType);
	i_density = GetConVarInt(g_hDensity);
	GetConVarString(g_hLightstyle, s_lightstyle, sizeof(s_lightstyle));
	GetConVarString(g_hSkybox, s_skybox, sizeof(s_skybox));
	GetConVarString(g_hSoundEffect, s_soundeffect, sizeof(s_soundeffect));
	f_soundvolume = GetConVarFloat(g_hSoundVolume);
	
	HookConVarChange(g_hWeatherType, OnConVarChanged);
	HookConVarChange(g_hDensity, OnConVarChanged);
	HookConVarChange(g_hLightstyle, OnConVarChanged);
	HookConVarChange(g_hSkybox, OnConVarChanged);
	HookConVarChange(g_hSoundEffect, OnConVarChanged);
	HookConVarChange(g_hSoundVolume, OnConVarChanged);
	
	HookEvent("round_start", OnRoundStart);
	
	if (b_late)
	{
		b_late = false;
		OnMapStart();
	}
	
	AutoExecConfig(true, "weather_effect");
}

public OnMapStart()
{
	i_entity = -1;
	GetCurrentMap(g_szMapname, sizeof(g_szMapname));
	
	Format(g_szMappath, sizeof(g_szMappath), "maps/%s.bsp ", g_szMapname);
	PrecacheModel(g_szMappath, true);
	
	g_szMapPrefix[0] = '\0';
	
	new pos = -1;
	if ((pos = FindCharInString(g_szMapname, '_')) != -1)
		strcopy(g_szMapPrefix, pos+2,  g_szMapname);
}

public OnMapEnd()
{
	soundtimer = INVALID_HANDLE;
}

public OnConfigsExecuted()
{
	decl String:configpath[PLATFORM_MAX_PATH];
	Format(configpath, sizeof(configpath), "cfg/sourcemod/weather_effect/%s.cfg", g_szMapPrefix);
	if (FileExists(configpath))
		ExecCfg(configpath);
	
	Format(configpath, sizeof(configpath), "cfg/sourcemod/weather_effect/%s.cfg", g_szMapname);
	if (FileExists(configpath))
		ExecCfg(configpath);
	
	CreateTimer(0.01, DelayedConfigsExecuted);
}

public Action:DelayedConfigsExecuted(Handle:timer)
{
	if (s_lightstyle[0])
		SetLightStyle(0, s_lightstyle);
	if (s_skybox[0])
		SetSkybox(s_skybox);
	return Plugin_Stop;
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
		TriggerSound();
}

TriggerSound()
{
	if (soundtimer != INVALID_HANDLE)
		TriggerTimer(soundtimer, true);
}

LoadSoundEffect()
{
	if (soundtimer != INVALID_HANDLE)
	{
		CloseHandle(soundtimer);
		soundtimer = INVALID_HANDLE;
	}
	if (s_soundeffect[0] && IsSoundFile(s_soundeffect) && SOUNDLIB_AVAILABLE())
	{
		new Handle:soundhandle = OpenSoundFile(s_soundeffect);
		if (soundhandle == INVALID_HANDLE)
			ThrowError("Couldn't open sound file %s", s_soundeffect);
			
		PrecacheSound(s_soundeffect);
		
		decl String:g_szSoundPath[PLATFORM_MAX_PATH];
		Format(g_szSoundPath, sizeof(g_szSoundPath), "sound/%s", s_soundeffect);
		AddFileToDownloadsTable(g_szSoundPath);
		
		new Float:timetoplay = float(GetSoundLength(soundhandle));
		soundtimer = CreateTimer(timetoplay, OnSoundEffect, timetoplay, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CloseHandle(soundhandle);
		TriggerSound();
	}
}

public Action:OnSoundEffect(Handle:timer, any:timetoplay)
{
	EmitSoundToAll(s_soundeffect, _, SNDCHAN_STATIC, _, SND_CHANGEVOL|SND_STOP, f_soundvolume, _, _, _, _, _, timetoplay);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearFuncPrecipitation();
	i_entity = ProccessFuncPrecipitation(i_weathertype, i_density);
}

ProccessFuncPrecipitation(preciptype, density)
{
	if (i_weathertype == -1 || i_entity != -1)
		return -1;
	
	new entity = CreateEntityByName("func_precipitation");
	decl String:buffer[12];
	IntToString(preciptype, buffer, sizeof(buffer));
	DispatchKeyValue(entity, "preciptype", buffer);
	
	IntToString(density, buffer, sizeof(buffer));
	DispatchKeyValue(entity, "density", buffer);
	DispatchSpawn(entity);
	
	new Float:m_WorldMins[3], Float:m_WorldMaxs[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMins", m_WorldMins); GetEntPropVector(0, Prop_Data, "m_WorldMaxs", m_WorldMaxs);
	SetEntPropVector(entity, Prop_Send, "m_vecMins", m_WorldMins); SetEntPropVector(entity, Prop_Send, "m_vecMaxs", m_WorldMaxs);
	
	new Float:m_vecOrigin[3];
	AddVectors(m_WorldMins, m_WorldMaxs, m_vecOrigin);
	m_vecOrigin[0] /= 2;
	m_vecOrigin[1] /= 2;
	m_vecOrigin[2] /= 2;
	TeleportEntity(entity, m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	LoadSoundEffect();
	
	return entity;
}

ClearFuncPrecipitation()
{
	if (i_entity != -1 && IsValidEdict(i_entity))
		AcceptEntityInput(i_entity, "kill");
	i_entity = -1;
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hWeatherType)
		i_weathertype = StringToInt(newValue);
	else if (convar == g_hDensity)
		i_density = StringToInt(newValue);
	else if (convar == g_hLightstyle)
	{
		strcopy(s_lightstyle, sizeof(s_lightstyle), newValue);
		return;
	}
	else if (convar == g_hSkybox)
	{
		strcopy(s_skybox, sizeof(s_skybox), newValue);
		return;
	}
	else if (convar == g_hSoundEffect)
	{
		strcopy(s_soundeffect, sizeof(s_soundeffect), newValue);
		LoadSoundEffect();
		return;
	}
	else if (convar == g_hSoundVolume)
	{
		f_soundvolume = StringToFloat(newValue);
		TriggerSound();
		return;
	}
		
	ClearFuncPrecipitation();
	i_entity = ProccessFuncPrecipitation(i_weathertype, i_density);
}

stock ExecCfg(const String:configpath[])
{
	new pos = StrContains(configpath, "cfg/", false) == 0 ? 4 : 0;
	ServerCommand("exec %s", configpath[pos]);
}

stock SetSkybox(const String:skyname[])
{
	ServerCommand("sv_skyname %s", skyname);
}

stock bool:IsSoundFile(const String:Sound[])
{
	decl String:buf[4];
	GetExtension(Sound, buf, sizeof(buf));
	return (!strcmp(buf, "mp3", false) || !strcmp(buf, "wav", false));
}

stock GetExtension(const String:path[], String:buffer[], size)
{
	new extpos = FindCharInString(path, '.', true);
	
	if (extpos == -1)
	{
		buffer[0] = '\0';
		return;
	}

	strcopy(buffer, size, path[++extpos]);
}