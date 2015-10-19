#pragma semicolon 1
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define FLASH 0

#define FragColor 	{255,75,75,255}
#define FlashColor 	{255,255,255,255}

new BeamSprite, g_beamsprite, g_halosprite;

new	Handle:h_greneffects_flash_light_distance, Float:f_flash_light_distance,
	Handle:h_greneffects_flash_light_duration, Float:f_flash_light_duration;

new String:ZombieName[4][64] = {
	"npc_nmrih_shamblerzombie",
	"npc_nmrih_turnedzombie",
	"npc_nmrih_kidzombie",
	"npc_nmrih_runnerzombie"
};

public Plugin:myinfo = 
{
	name = "[NMRiH] Grenade Effects",
	author = "Mr.Halt",
	description = "Adds Grenades Special Effects.",
	version = PLUGIN_VERSION,
	url = "http://blog.naver.com/pine0113"
}

public OnPluginStart()
{
	CreateConVar("nmrih_greneffect_version", PLUGIN_VERSION, "The plugin's version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);

	h_greneffects_flash_light_distance = CreateConVar("zr_greneffect_flash_light_distance", "1024", "The light distance", 0, true, 100.0);
	h_greneffects_flash_light_duration = CreateConVar("zr_greneffect_flash_light_duration", "600.0", "The light duration in seconds", 0, true, 1.0);

	f_flash_light_distance = GetConVarFloat(h_greneffects_flash_light_distance);
	f_flash_light_duration = GetConVarFloat(h_greneffects_flash_light_duration);

	HookConVarChange(h_greneffects_flash_light_distance, OnConVarChanged);
	HookConVarChange(h_greneffects_flash_light_duration, OnConVarChanged);
	
	AutoExecConfig(true, "nmrih_grenade_effects");
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == h_greneffects_flash_light_distance)
	{
		f_flash_light_distance = StringToFloat(newValue);
	}
	else if (convar == h_greneffects_flash_light_duration)
	{
		f_flash_light_duration = StringToFloat(newValue);
	}
}

public OnMapStart() 
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public OnEntityCreated(entity, const String:classname[])
{
	if(IsZombie(entity)) SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamageHookZombie);
	
	if (!strcmp(classname, "tnt_projectile"))
	{
		BeamFollowCreate(entity, FragColor);
		IgniteEntity(entity, 2.0);
		CreateTimer(3.0, EntityFunction_OnTNT, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (!strcmp(classname, "grenade_projectile"))
	{
		CreateTimer(1.3, DoFlashLight, entity, TIMER_FLAG_NO_MAPCHANGE);
		BeamFollowCreate(entity, FlashColor);
	}
}

public OnEntityDestroyed(Entity)
{
	if(IsZombie(Entity)) SDKUnhook(Entity, SDKHook_OnTakeDamagePost, OnTakeDamageHookZombie);
}

public OnTakeDamageHookZombie(Entity, Client, inflictor, Float:damage, damagetype)
{
	if(Client > MaxClients)
		return;

	if(IsZombie(Entity))
	{
		new String:WeaponName[64];
		GetEntityClassname(inflictor, WeaponName, sizeof(WeaponName));
		if(StrContains(WeaponName, "tnt_projectile", false) != -1)
		{
			AcceptEntityInput(Entity, "Ignite", _, Client);
		}
	}
}

public Action:EntityFunction_OnTNT(Handle:timer, any:Entity)
{
	if(IsValidEntity(Entity))
	{
		new String:sWeapon[64];
		GetEntityClassname(Entity, sWeapon, sizeof(sWeapon));
		if(StrContains(sWeapon, "tnt_projectile", false) != -1)
		{
			new Float:origin[3];
			GetEntPropVector(Entity, Prop_Send, "m_vecOrigin", origin);

			TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_beamsprite, g_halosprite, 1, 1, 0.2, 100.0, 1.0, FragColor, 0, 0);
			TE_SendToAll();
		}
	}
}

public bool:FilterTarget(entity, contentsMask, any:data)
{
	return (data == entity);
}

public Action:DoFlashLight(Handle:timer, any:entity)
{
	if (!IsValidEdict(entity))
	{
		return Plugin_Stop;
	}
		
	decl String:g_szClassname[64];
	GetEdictClassname(entity, g_szClassname, sizeof(g_szClassname));
	if (!strcmp(g_szClassname, "grenade_projectile", false))
	{
		decl Float:origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		origin[2] += 50.0;
		LightCreate(FLASH, origin);
		AcceptEntityInput(entity, "kill");
	}
	
	return Plugin_Stop;
}

BeamFollowCreate(entity, color[4])
{
	TE_SetupBeamFollow(entity, BeamSprite,	0, 1.0, 10.0, 10.0, 5, color);
	TE_SendToAll();	
}

LightCreate(grenade, Float:pos[3])   
{  
	new iEntity = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	switch(grenade)
	{
		case FLASH : 
		{
			DispatchKeyValue(iEntity, "_light", "255 255 255 255");
			DispatchKeyValueFloat(iEntity, "distance", f_flash_light_distance);
			EmitSoundToAll("weapons/tools/zippo/zippo_strike_success_01.wav", iEntity, SNDCHAN_WEAPON);
			CreateTimer(f_flash_light_duration, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
}

public Action:Delete(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "kill");
	}
}

stock bool:IsZombie(Entity)
{
	if(IsValidEntity(Entity))
	{
		new String:EntityName[128];
		GetEntityClassname(Entity, EntityName, sizeof(EntityName));
		for(new i=0; i<=3; i++)
		{
			if(StrEqual(EntityName, ZombieName[i], false)) return true;
		}
	}
	
	return false;
}